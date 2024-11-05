local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local ElementPickerView = require('ui/settings/pickers/ElementPickerView')
local JobAbilitiesSettingsMenuItem = require('ui/settings/menus/buffs/JobAbilitiesSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local NukeSettingsEditor = require('ui/settings/NukeSettingsEditor')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local NukeSettingsMenuItem = setmetatable({}, {__index = MenuItem })
NukeSettingsMenuItem.__index = NukeSettingsMenuItem

function NukeSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, addonSettings, jobNameShort)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Abilities', 18),
        ButtonItem.default('Blacklist', 18),
        ButtonItem.default('Config', 18),
        ButtonItem.default('Modes', 18),
        ButtonItem.default('Help', 18),
    }, {}, function()
        local nukeSettingsView = NukeSettingsEditor.new(trustSettings, trustSettingsMode, addonSettings:getSettings().help.wiki_base_url..'/Nuker')
        nukeSettingsView:setShouldRequestFocus(true)
        return nukeSettingsView
    end, "Nukes", "Choose which nukes to use when magic bursting or free nuking."), NukeSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.jobNameShort = jobNameShort
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function NukeSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function NukeSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Edit", self:getNukesMenuItem())
    self:setChildMenuItem("Abilities", self:getAbilitiesMenuItem())
    self:setChildMenuItem("Blacklist", self:getBlacklistMenuItem())
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function NukeSettingsMenuItem:getNukesMenuItem()
    local chooseNukesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
        function(args)
            local spellSettings = args['spells']

            local jobId = res.jobs:with('ens', self.jobNameShort).id
            local allSpells = spell_util.get_spells(function(spell)
                return spell.levels[jobId] ~= nil and S{'BlackMagic','WhiteMagic','Ninjutsu'}:contains(spell.type) and S{ 'Enemy' }:intersection(S(spell.targets)):length() > 0
            end):map(function(spell) return spell.en end):sort()

            local sortSpells = function(spells)
                spell_util.sort_by_element(spells, true)
            end

            local chooseSpellsView = SpellPickerView.new(self.trustSettings, spellSettings, allSpells, L{}, true, sortSpells)
            return chooseSpellsView
        end, "Nukes", "Choose which nukes to use when magic bursting or free nuking.")
    return chooseNukesMenuItem
end

function NukeSettingsMenuItem:getAbilitiesMenuItem()
    local jobAbilitiesMenuItem = JobAbilitiesSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, 'NukeSettings')
    jobAbilitiesMenuItem.titleText = "Nukes"
    jobAbilitiesMenuItem.descriptionText = "Choose abilities to use before a magic burst or free nuke."
    return jobAbilitiesMenuItem
end

function NukeSettingsMenuItem:getBlacklistMenuItem()
    local nukeElementBlacklistMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
        function()
            local nukeSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].NukeSettings
            if not nukeSettings.Blacklist then
                nukeSettings.Blacklist = L{}
            end
            local blacklistPickerView = ElementPickerView.new(self.trustSettings, nukeSettings.Blacklist)
            blacklistPickerView:setShouldRequestFocus(true)
            return blacklistPickerView
        end, "Blacklist", "Choose elements to avoid when magic bursting or free nuking.")
    return nukeElementBlacklistMenuItem
end

function NukeSettingsMenuItem:getConfigMenuItem()
    local nukeConfigMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
        function()
            local allSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value]

            local nukeSettings = T{
                Delay = allSettings.NukeSettings.Delay,
                MinManaPointsPercent = allSettings.NukeSettings.MinManaPointsPercent,
                MinNumMobsToCleave = allSettings.NukeSettings.MinNumMobsToCleave,
                GearswapCommand = allSettings.NukeSettings.GearswapCommand or 'gs c set MagicBurstMode Single',
            }

            local configItems = L{
                ConfigItem.new('Delay', 0, 60, 1, function(value) return value.."s" end, "Delay Between Nukes"),
                ConfigItem.new('MinManaPointsPercent', 0, 100, 1, function(value) return value.." %" end, "Min MP %"),
                ConfigItem.new('MinNumMobsToCleave', 0, 30, 1, function(value) return value.."" end, "Min Number Mobs to Cleave"),
                TextInputConfigItem.new('GearswapCommand', nukeSettings.GearswapCommand, 'Gearswap Command', function(_) return true  end, 225)
            }

            local nukeConfigEditor = ConfigEditor.new(self.trustSettings, nukeSettings, configItems)

            nukeConfigEditor:setShouldRequestFocus(true)

            self.dispose_bag:add(nukeConfigEditor:onConfigChanged():addAction(function(newSettings, _)
                allSettings.NukeSettings.Delay = newSettings.Delay
                allSettings.NukeSettings.MinManaPointsPercent = newSettings.MinManaPointsPercent
                allSettings.NukeSettings.MinNumMobsToCleave = newSettings.MinNumMobsToCleave
                allSettings.NukeSettings.GearswapCommand = (newSettings.GearswapCommand or 'gs c set MagicBurstMode Single'):gsub("^%u", string.lower)

                self.trustSettings:saveSettings(true)
            end), nukeConfigEditor:onConfigChanged())

            return nukeConfigEditor
        end, "Config", "Configure general nuke settings.")
    return nukeConfigMenuItem
end

function NukeSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for nuking and magic bursting.",
            L{'AutoMagicBurstMode', 'AutoNukeMode', 'MagicBurstTargetMode'})
end

return NukeSettingsMenuItem
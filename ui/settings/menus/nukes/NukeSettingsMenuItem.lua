local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local element_util = require('cylibs/util/element_util')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local JobAbilitiesSettingsMenuItem = require('ui/settings/menus/buffs/JobAbilitiesSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local NukeSettingsEditor = require('ui/settings/NukeSettingsEditor')
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
        local nukeSettingsView = NukeSettingsEditor.new(trust, trustSettings, trustSettingsMode, addonSettings:getSettings().help.wiki_base_url..'/Nuker')
        nukeSettingsView:setShouldRequestFocus(true)
        return nukeSettingsView
    end, "Nukes", "Choose which nukes to use when magic bursting or free nuking."), NukeSettingsMenuItem)

    self.trust = trust
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
            local selectedSpells = args['spells']

            local allSpells = self.trust:get_job():get_spells(function(spell_id)
                local spell = res.spells[spell_id]
                return spell and S{ 'BlackMagic','WhiteMagic','Ninjutsu' }:contains(spell.type) and S{ 'Enemy' }:intersection(S(spell.targets)):length() > 0 and spell.element ~= 15
            end):map(function(spell_id)
                return Spell.new(res.spells[spell_id].en)
            end):compact_map()

            local sortSpells = function(spells)
                spell_util.sort_by_element(spells, true)
            end

            local configItem = MultiPickerConfigItem.new("Nukes", selectedSpells, allSpells, function(spell)
                return spell:get_localized_name()
            end, "Nukes", nil, function(spell)
                return AssetManager.imageItemForSpell(spell:get_name())
            end)

            local chooseSpellsView = FFXIPickerView.withConfig(configItem, true)

            self.dispose_bag:add(chooseSpellsView:on_pick_items():addAction(function(_, newSpells)
                selectedSpells:clear()

                for spell in newSpells:it() do
                    selectedSpells:append(Spell.new(spell:get_name()))
                end

                sortSpells(selectedSpells)

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my list of nukes!")
            end), chooseSpellsView:on_pick_items())

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
        ButtonItem.default('Clear All', 18),
    }, {},
        function()
            local nukeSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].NukeSettings
            if not nukeSettings.Blacklist then
                nukeSettings.Blacklist = L{}
            end

            local allElements = L{
                element_util.Light,
                element_util.Fire,
                element_util.Lightning,
                element_util.Wind,
                element_util.Dark,
                element_util.Earth,
                element_util.Water,
                element_util.Ice,
            }

            local configItem = MultiPickerConfigItem.new("Elements", nukeSettings.Blacklist, allElements, function(element)
                return element:get_localized_name()
            end, "Elements", nil, function(element)
                return AssetManager.imageItemForElement(res.elements:with('en', element:get_name()).id)
            end)

            local blacklistPickerView = FFXIPickerView.withConfig(configItem, true)

            blacklistPickerView:getDisposeBag():add(blacklistPickerView:on_pick_items():addAction(function(_, selectedElements)
                nukeSettings.Blacklist:clear()
                for element in selectedElements:it() do
                    nukeSettings.Blacklist:append(Element.new(element:get_name()))
                end
                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I won't use nukes of these elements!")
            end), blacklistPickerView:on_pick_items())

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
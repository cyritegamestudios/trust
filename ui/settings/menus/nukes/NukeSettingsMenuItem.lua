local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local ElementPickerView = require('ui/settings/pickers/ElementPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local NukeSettingsEditor = require('ui/settings/NukeSettingsEditor')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')

local NukeSettingsMenuItem = setmetatable({}, {__index = MenuItem })
NukeSettingsMenuItem.__index = NukeSettingsMenuItem

function NukeSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, addonSettings, jobNameShort, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Blacklist', 18),
        ButtonItem.default('Config', 18),
        ButtonItem.default('Modes', 18),
        ButtonItem.default('Help', 18),
    }, {}, function()
        local nukeSettingsView = viewFactory(NukeSettingsEditor.new(trustSettings, trustSettingsMode, addonSettings:getSettings().help.wiki_base_url..'/Nuker'))
        nukeSettingsView:setShouldRequestFocus(true)
        return nukeSettingsView
    end, "Nukes", "Choose which nukes to use when magic bursting or free nuking."), NukeSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.jobNameShort = jobNameShort
    self.viewFactory = viewFactory
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
                return spell.levels[jobId] ~= nil and S{'BlackMagic','WhiteMagic'}:contains(spell.type) and S{ 'Enemy' }:intersection(S(spell.targets)):length() > 0
            end):map(function(spell) return spell.en end):sort()

            local sortSpells = function(spells)
                spell_util.sort_by_element(spells, true)
            end

            local chooseSpellsView = self.viewFactory(SpellPickerView.new(self.trustSettings, spellSettings, allSpells, L{}, true, sortSpells))
            chooseSpellsView:setTitle("Choose spells to nuke with.")
            return chooseSpellsView
        end, "Nukes", "Choose which nukes to use when magic bursting or free nuking.")
    return chooseNukesMenuItem
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
            local blacklistPickerView = self.viewFactory(ElementPickerView.new(self.trustSettings, nukeSettings.Blacklist))
            blacklistPickerView:setTitle('Choose elements to avoid when magic bursting or free nuking.')
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
            local nukeSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].NukeSettings

            local configItems = L{
                ConfigItem.new('Delay', 0, 60, 1, function(value) return value.."s" end),
                ConfigItem.new('MinManaPointsPercent', 0, 100, 1, function(value) return value.." %" end),
                ConfigItem.new('MinNumMobsToCleave', 0, 30, 1, function(value) return value.."" end)
            }

            local nukeConfigEditor = self.viewFactory(ConfigEditor.new(self.trustSettings, nukeSettings, configItems))
            nukeConfigEditor:setTitle('Configure general nuke settings.')
            nukeConfigEditor:setShouldRequestFocus(true)
            return nukeConfigEditor
        end, "Config", "Configure general nuke settings.")
    return nukeConfigMenuItem
end

function NukeSettingsMenuItem:getModesMenuItem()
    local nukeModesMenuItem = MenuItem.new(L{}, L{}, function(_)
        local modesView = self.viewFactory(ModesView.new(L{'AutoMagicBurstMode', 'AutoNukeMode', 'MagicBurstTargetMode'}))
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for nuking and magic bursting.")
        return modesView
    end, "Modes", "Change nuking and magic bursting behavior.")
    return nukeModesMenuItem
end

return NukeSettingsMenuItem
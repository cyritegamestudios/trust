local BuffSettingsEditor = require('ui/settings/BuffSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionsSettingsEditor = require('ui/settings/editors/ConditionsSettingsEditor')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')

local BuffSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuffSettingsMenuItem.__index = BuffSettingsMenuItem

function BuffSettingsMenuItem.new(trustSettings, trustSettingsMode, settingsKey, targets, jobNameShort, descriptionText, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
    }, {}, function(menuArgs)
        local buffs = T(trustSettings:getSettings())[trustSettingsMode.value][settingsKey]

        local buffSettingsView = viewFactory(BuffSettingsEditor.new(trustSettings, buffs, targets))
        buffSettingsView:setShouldRequestFocus(true)
        buffSettingsView:setTitle(descriptionText)
        return buffSettingsView
    end, "Buffs", descriptionText), BuffSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsKey = settingsKey
    self.jobNameShort = jobNameShort
    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function BuffSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function BuffSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddBuffMenuItem())
    self:setChildMenuItem("Edit", self:getEditBuffMenuItem())
    self:setChildMenuItem("Conditions", self:getConditionsMenuItem())
end

function BuffSettingsMenuItem:getAddBuffMenuItem()
    local addBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function(args)
            local spellSettings = args['spells']
            local targets = args['targets']
            local defaultJobNames = L{}
            if targets:contains('Party') then
                defaultJobNames = job_util.all_jobs()
            end

            local jobId = res.jobs:with('ens', self.jobNameShort).id
            local allBuffs = spell_util.get_spells(function(spell)
                return spell.levels[jobId] ~= nil and spell.status ~= nil and spell.skill ~= 44 and targets:intersection(S(spell.targets)):length() > 0
            end):map(function(spell) return spell.en end)

            local chooseSpellsView = self.viewFactory(SpellPickerView.new(self.trustSettings, spellSettings, allBuffs, defaultJobNames, false))
            chooseSpellsView:setTitle("Choose buffs to add.")
            chooseSpellsView:setScrollEnabled(true)
        return chooseSpellsView
    end, "Buffs", "Add a new buff.")
    return addBuffMenuItem
end

function BuffSettingsMenuItem:getEditBuffMenuItem()
    local editBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
    function(args)
        local spell = args['spell']
        local editSpellView = self.viewFactory(SpellSettingsEditor.new(self.trustSettings, spell))
        editSpellView:setTitle("Edit buff.")
        editSpellView:setShouldRequestFocus(true)
        return editSpellView
    end, "Buffs", "Edit buff settings.")
    return editBuffMenuItem
end

function BuffSettingsMenuItem:getConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, L{}, self.viewFactory)
    --[[local editConditionsMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
    function(args)
        local spell = args['spell']
        local editSpellView = self.viewFactory(ConditionsSettingsEditor.new(self.trustSettings, spell:get_conditions()))
        editSpellView:setTitle("Edit buff conditions.")
        editSpellView:setShouldRequestFocus(true)
        return editSpellView
    end, "Conditions", "Choose when to use this buff.")
    return editConditionsMenuItem]]
end

return BuffSettingsMenuItem
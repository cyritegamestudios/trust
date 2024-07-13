local BuffSettingsMenuItem = require('ui/settings/menus/buffs/BuffSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FoodSettingsMenuItem = require('ui/settings/menus/buffs/FoodSettingsMenuItem')
local JobAbilityPickerView = require('ui/settings/pickers/JobAbilityPickerView')
local JobAbilitiesSettingsEditor = require('ui/settings/JobAbilitiesSettingsEditor')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')

local BufferSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BufferSettingsMenuItem.__index = BufferSettingsMenuItem

function BufferSettingsMenuItem.new(trustSettings, trustSettingsMode, jobNameShort, settingsPrefix)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Self', 18),
        ButtonItem.default('Party', 18),
        ButtonItem.default('Abilities', 18),
        ButtonItem.default('Food', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Buffs", "Choose buffs to use."), BufferSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.jobNameShort = jobNameShort
    self.settingsPrefix = settingsPrefix
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function BufferSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function BufferSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Self", self:getSelfBuffsMenuItem())
    self:setChildMenuItem("Party", self:getPartyBuffsMenuItem())
    self:setChildMenuItem("Abilities", self:getJobAbilitiesMenuItem())
    self:setChildMenuItem("Food", self:getFoodMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function BufferSettingsMenuItem:getSelfBuffsMenuItem()
    local selfBuffSettingsItem = BuffSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self.settingsPrefix, 'SelfBuffs', S{'Self','Enemy'}, self.jobNameShort, "Edit buffs to use on the player.", false)
    return selfBuffSettingsItem
end

function BufferSettingsMenuItem:getPartyBuffsMenuItem()
    local partyBuffSettingsItem = BuffSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self.settingsPrefix, 'PartyBuffs', S{'Party'}, self.jobNameShort, "Edit buffs to use on party members.", true)
    return partyBuffSettingsItem
end

function BufferSettingsMenuItem:getJobAbilitiesMenuItem()
    local chooseJobAbilitiesItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
        function()
            local jobId = res.jobs:with('ens', self.jobNameShort).id
            local allJobAbilities = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId] end):filter(function(jobAbility)
                return jobAbility.status ~= nil and S{'Self'}:intersection(S(jobAbility.targets)):length() > 0
            end):map(function(jobAbility) return jobAbility.en end)

            local jobAbilities
            if self.settingsPrefix then
                jobAbilities = T(self.trustSettings:getSettings())[self.trustSettingsMode.value][self.settingsPrefix].JobAbilities
            else
                jobAbilities = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].JobAbilities
            end

            local chooseJobAbilitiesView = JobAbilityPickerView.new(self.trustSettings, jobAbilities, allJobAbilities)
            chooseJobAbilitiesView:setTitle("Choose job abilities to add.")
            return chooseJobAbilitiesView
        end, "Job Abilities", "Add a new job ability buff.")

    local jobAbilitiesSettingsItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Conditions', 18),
    }, {
        Add = chooseJobAbilitiesItem,
        Conditions = ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, L{}),
    },
        function(_, infoView)
            local jobAbilitiesSettingsView = JobAbilitiesSettingsEditor.new(self.trustSettings, self.trustSettingsMode, self.settingsPrefix)
            self.dispose_bag:add(jobAbilitiesSettingsView:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
                local jobAbility = jobAbilitiesSettingsView.jobAbilities[indexPath.row]
                if jobAbility then
                    local description = jobAbility:get_conditions():map(function(condition)
                        return condition:tostring()
                    end)
                    infoView:setDescription("Use when: "..localization_util.commas(description))
                end
            end, jobAbilitiesSettingsView:getDelegate():didMoveCursorToItemAtIndexPath()))
            return jobAbilitiesSettingsView
        end, "Job Abilities", "Choose job ability buffs.")
    return jobAbilitiesSettingsItem
end

function BufferSettingsMenuItem:getFoodMenuItem()
    local foodSettingsMenuItem = FoodSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode)
    return foodSettingsMenuItem
end

function BufferSettingsMenuItem:getModesMenuItem()
    local buffModesMenuItem = MenuItem.new(L{}, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoBarSpellMode', 'AutoBuffMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Change buffing behavior.")
    return buffModesMenuItem
end

function BufferSettingsMenuItem:getEditBuffMenuItem()
    local editBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
            function(args)
                local spell = args['spell']
                if spell then
                    local editSpellView = SpellSettingsEditor.new(self.trustSettings, spell, not self.showJobs)
                    editSpellView:setTitle("Edit buff.")
                    editSpellView:setShouldRequestFocus(true)
                    return editSpellView
                end
                return nil
            end, "Buffs", "Edit buff settings.")
    return editBuffMenuItem
end

return BufferSettingsMenuItem
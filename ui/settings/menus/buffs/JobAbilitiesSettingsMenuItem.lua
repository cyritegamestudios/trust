local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local JobAbilityPickerView = require('ui/settings/pickers/JobAbilityPickerView')
local JobAbilitiesSettingsEditor = require('ui/settings/JobAbilitiesSettingsEditor')

local JobAbilitiesSettingsMenuItem = setmetatable({}, {__index = MenuItem })
JobAbilitiesSettingsMenuItem.__index = JobAbilitiesSettingsMenuItem

function JobAbilitiesSettingsMenuItem.new(trustSettings, trustSettingsMode, settingsPrefix)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Conditions', 18),
        ButtonItem.default('Toggle', 18),
        ButtonItem.default('Reset', 18),
    }, {
        Confirm = MenuItem.action(function()
            trustSettings:saveSettings(true)
            addon_system_message("Your settings have been updated.")
        end, "Job Abilities", "Save current settings to profile.")
    },
    nil, "Job Abilities", "Choose job ability buffs."), JobAbilitiesSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsPrefix = settingsPrefix
    self.conditionSettingsMenuItem = ConditionSettingsMenuItem.new(trustSettings, trustSettingsMode, nil, S{ Condition.TargetType.Self }, function()
        return self.buffs and self.buffs:length() > 0
    end)
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local jobAbilities
        if self.settingsPrefix then
            jobAbilities = T(self.trustSettings:getSettings())[self.trustSettingsMode.value][self.settingsPrefix].JobAbilities
        else
            jobAbilities = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].JobAbilities
        end
        self.buffs = jobAbilities

        local jobAbilitiesSettingsView = JobAbilitiesSettingsEditor.new(self.trustSettings, self.trustSettingsMode, self.settingsPrefix)
        jobAbilitiesSettingsView:setShouldRequestFocus(self.buffs and self.buffs:length() > 0)

        self.dispose_bag:add(jobAbilitiesSettingsView:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local item = jobAbilitiesSettingsView:getDataSource():itemAtIndexPath(indexPath)
            if item and not item:getTextItem():getEnabled() then
                infoView:setDescription("Unavailable on current job or settings.")
            else
                local jobAbility = jobAbilitiesSettingsView.jobAbilities[indexPath.row]
                if jobAbility then
                    self.conditionSettingsMenuItem:setConditions(jobAbility.conditions)

                    local description = jobAbility:get_conditions():map(function(condition)
                        return condition:tostring()
                    end)
                    infoView:setDescription("Use when: "..localization_util.commas(description))
                end
            end
        end, jobAbilitiesSettingsView:getDelegate():didMoveCursorToItemAtIndexPath()))

        self.jobAbilitiesSettingsView = jobAbilitiesSettingsView

        return jobAbilitiesSettingsView
    end

    self:reloadSettings()

    return self
end

function JobAbilitiesSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function JobAbilitiesSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    self:setChildMenuItem("Toggle", self:getToggleAbilityMenuItem())
    self:setChildMenuItem("Conditions", self.conditionSettingsMenuItem)
    self:setChildMenuItem("Reset", self:getResetMenuItem())
end

function JobAbilitiesSettingsMenuItem:getAddAbilityMenuItem()
    local chooseJobAbilitiesItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Clear', 18),
    }, {},
    function()
        local allJobAbilities = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId] end):filter(function(jobAbility)
            return buff_util.buff_for_job_ability(jobAbility.id) ~= nil and S{'Self'}:intersection(S(jobAbility.targets)):length() > 0
        end):map(function(jobAbility) return jobAbility.en end)

        local jobAbilities
        if self.settingsPrefix then
            jobAbilities = T(self.trustSettings:getSettings())[self.trustSettingsMode.value][self.settingsPrefix].JobAbilities
        else
            jobAbilities = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].JobAbilities
        end
        self.buffs = jobAbilities

        local chooseJobAbilitiesView = JobAbilityPickerView.new(self.trustSettings, jobAbilities, allJobAbilities, true)
        chooseJobAbilitiesView:setTitle("Choose job abilities to add.")
        return chooseJobAbilitiesView
    end, "Job Abilities", "Add a new job ability buff.")
    return chooseJobAbilitiesItem
end

function JobAbilitiesSettingsMenuItem:getToggleAbilityMenuItem()
    return MenuItem.action(function(menu)
        local selectedIndexPath = self.jobAbilitiesSettingsView:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.jobAbilitiesSettingsView:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                local buff = self.buffs[selectedIndexPath.row]
                buff:setEnabled(not buff:isEnabled())

                self.jobAbilitiesSettingsView:reloadBuffAtIndexPath(selectedIndexPath)
            end
        end
    end, "Job Abilities", "Temporarily enable or disable the selected job ability until the addon reloads.", false, function()
        return self.buffs and self.buffs:length() > 0
    end)
end

function JobAbilitiesSettingsMenuItem:getResetMenuItem()
    return MenuItem.action(function(menu)
        local defaultSettings = T(self.trustSettings:getDefaultSettings()):clone().Default

        local currentSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value]
        if self.settingsPrefix then
            currentSettings[self.settingsPrefix].JobAbilities = defaultSettings[self.settingsPrefix].JobAbilities
        else
            currentSettings.JobAbilities = defaultSettings.JobAbilities
        end
        self.trustSettings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've forgotten any custom settings!")

        menu:showMenu(self)
    end, "Reset", "Reset to default settings. WARNING: your settings will be overriden.")
end

return JobAbilitiesSettingsMenuItem
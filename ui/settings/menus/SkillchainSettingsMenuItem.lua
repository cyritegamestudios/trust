local BuildSkillchainSettingsMenuItem = require('ui/settings/menus/skillchains/BuildSkillchainSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local JobAbilitiesSettingsMenuItem = require('ui/settings/menus/buffs/JobAbilitiesSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ShortcutMenuItem = require('ui/settings/menus/ShortcutMenuItem')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local SkillchainSettingsEditor = require('ui/settings/SkillchainSettingsEditor')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')
local SkillchainStepSettingsEditor = require('ui/settings/editors/SkillchainStepSettingsEditor')

local SkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SkillchainSettingsMenuItem.__index = SkillchainSettingsMenuItem

function SkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        --ButtonItem.default('Conditions', 18),
        ButtonItem.default('Abilities', 18),
        ButtonItem.default('Skip', 18),
        ButtonItem.default('Clear', 18),
        ButtonItem.default('Clear All', 18),
        ButtonItem.default('Find', 18),
    }, {
        Skip = MenuItem.action(nil, "Skillchains", "Wait for party members to use a weapon skill for the selected step."),
        Clear = MenuItem.action(nil, "Skillchains", "Automatically determine a weapon skill to use for the selected step."),
        Find = BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer),
    },
    nil, "Skillchains", "Edit or create a new skillchain."), SkillchainSettingsMenuItem)

    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettingsMode = weaponSkillSettingsMode
    self.skillchainBuilder = SkillchainBuilder.new(skillchainer.skillchain_builder.abilities)
    self.skillchainer = skillchainer
    self.conditionSettingsMenuItem = ConditionSettingsMenuItem.new(self.weaponSkillSettings, self.weaponSkillSettingsMode, nil, S{ Condition.TargetType.Self })
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local currentSettings = weaponSkillSettings:getSettings()[weaponSkillSettingsMode.value]

        local abilities = currentSettings.Skillchain

        local createSkillchainView = SkillchainSettingsEditor.new(weaponSkillSettings, abilities)
        createSkillchainView:setShouldRequestFocus(true)

        self.selectedAbility = abilities[1]

        self.conditionSettingsMenuItem:setConditions(self.selectedAbility.conditions) -- get_conditions() makes a copy

        self.disposeBag:add(createSkillchainView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedAbility = abilities[indexPath.section]
            self.selectedIndex = indexPath.section

            self.conditionSettingsMenuItem:setConditions(self.selectedAbility.conditions) -- get_conditions() makes a copy

            if self.selectedAbility then
                if self.selectedAbility:get_conditions():empty() then
                    infoView:setDescription("Edit which weapon skill to use for the selected step.")
                else
                    local description = self.selectedAbility:get_conditions():map(function(condition)
                        return condition:tostring()
                    end)
                    description = "Use when: "..localization_util.commas(description)
                    if currentSettings.JobAbilities:length() > 0 then
                        description = description..", Use with: "..localization_util.commas(currentSettings.JobAbilities:map(function(j) return j:get_name() end), 'and')
                    end
                    infoView:setDescription(description)
                end
            end
        end, createSkillchainView:getDelegate():didSelectItemAtIndexPath()))

        return createSkillchainView
    end

    self:reloadSettings()

    return self
end

function SkillchainSettingsMenuItem:reloadSettings()
    self:setChildMenuItem('Edit', self:getEditSkillchainStepMenuItem())
    self:setChildMenuItem('Abilities', self:getAbilitiesMenuItem())
    self:setChildMenuItem('Clear All', MenuItem.action(nil, "Skillchains", "Automatically determine weapon skills to use for all steps."))
    self:setChildMenuItem("Shortcuts", ShortcutMenuItem.new(string.format("shortcut_%s", self:getConfigKey()), "Open the skillchain editor.", false, string.format("// trust menu %s", self:getConfigKey())))
end

function SkillchainSettingsMenuItem:getEditSkillchainStepMenuItem()
    local editSkillchainStepMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Conditions', 18),
    }, {
        Conditions = self.conditionSettingsMenuItem,
    },
        function(args, infoView, showMenu)
            local currentSettings = T(self.weaponSkillSettings:getSettings())[self.weaponSkillSettingsMode.value]
            local abilities = currentSettings.Skillchain
            local stepNum = self.selectedIndex

            local currentAbilities = abilities:slice(1, math.max(stepNum - 1, 1)):map(
                function(ability)
                    if ability.__class ~= SkillchainAbility.__class then
                        return SkillchainAbility.new(ability.resource, ability:get_ability_id())
                    end
                    return ability
                end)

            local currentSkillchain = self.skillchainBuilder:reduce_skillchain(currentAbilities)

            self.skillchainBuilder:set_current_step(SkillchainStep.new(stepNum - 1, abilities[stepNum - 1], currentSkillchain))

            local nextSteps = L{}
            if currentSkillchain or stepNum == 2 then
                nextSteps = self.skillchainBuilder:get_next_steps():filter(function(step)
                    return step:get_skillchain() ~= nil
                end)
            end
            if nextSteps:empty() then
                nextSteps = L{}:extend(L(self.skillchainBuilder.abilities)):map(function(ability) return SkillchainStep.new(stepNum, ability) end)
            end

            local currentStep = nextSteps:firstWhere(function(step)
                return step:get_ability():get_name() == self.selectedAbility:get_name()
            end) or nextSteps[1]

            local currentConditions = abilities[stepNum].conditions or L{}
            if currentConditions:empty() then
                currentConditions = self:getAbility(currentStep:get_ability():get_name()):get_conditions()
            end

            local stepSettings = {
                step = currentStep,
                conditions = currentConditions
            }

            local editSkillchainStepEditor = SkillchainStepSettingsEditor.new(stepSettings, nextSteps, self.weaponSkillSettings, self.weaponSkillSettingsMode)

            self.disposeBag:add(editSkillchainStepEditor:onConfigChanged():addAction(function(newSettings, _)
                local ability = self:getAbility(newSettings.step:get_ability():get_name())
                if ability then
                    self.selectedAbility = ability
                    ability.conditions = newSettings.conditions

                    currentSettings.Skillchain[newSettings.step:get_step()] = ability
                    self.weaponSkillSettings:saveSettings(true)

                    self.conditionSettingsMenuItem:setConditions(ability.conditions)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my weapon skills!")
                end
            end), editSkillchainStepEditor:onConfigChanged())

            return editSkillchainStepEditor
        end, "Skillchains", "Edit which weapon skill to use for the selected step.")

    return editSkillchainStepMenuItem
end

function SkillchainSettingsMenuItem:getAbilitiesMenuItem()
    local jobAbilitiesMenuItem = JobAbilitiesSettingsMenuItem.new(self.weaponSkillSettings, self.weaponSkillSettingsMode)
    jobAbilitiesMenuItem.titleText = "Skillchains"
    jobAbilitiesMenuItem.descriptionText = "Choose abilities to use before each step in the skillchain."
    --jobAbilitiesMenuItem.enabled = function()
    --    return self.selectedAbility and not S{ SkillchainAbility.Auto, SkillchainAbility.Skip }:contains(self.selectedAbility:get_name())
    --end
    return jobAbilitiesMenuItem
end

function SkillchainSettingsMenuItem:getAbility(abilityName)
    for skill in self.skillchainer.active_skills:it() do
        local ability = skill:get_ability(abilityName)
        if ability then
            return ability
        end
    end
    return nil
end

function SkillchainSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function SkillchainSettingsMenuItem:getConfigKey()
    return "skillchains"
end

return SkillchainSettingsMenuItem
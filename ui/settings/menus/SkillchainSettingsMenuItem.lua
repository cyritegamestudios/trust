local BuildSkillchainSettingsMenuItem = require('ui/settings/menus/skillchains/BuildSkillchainSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local GambitConditionSettingsMenuItem = require('ui/settings/menus/gambits/GambitConditionSettingsMenuItem')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local JobAbilitiesSettingsMenuItem = require('ui/settings/menus/buffs/JobAbilitiesSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
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
    self.conditionSettingsMenuItem =  GambitConditionSettingsMenuItem.new(self.weaponSkillSettings)
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local currentSettings = weaponSkillSettings:getSettings()[weaponSkillSettingsMode.value]

        local ability_gambits = currentSettings.Skillchain

        local createSkillchainView = SkillchainSettingsEditor.new(weaponSkillSettings, ability_gambits)
        createSkillchainView:setShouldRequestFocus(true)

        self.selectedAbility = ability_gambits[1]

        self.conditionSettingsMenuItem:setConditions(self.selectedAbility.conditions) -- get_conditions() makes a copy

        self.disposeBag:add(createSkillchainView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedAbility = ability_gambits[indexPath.section]
            self.selectedIndex = indexPath.section

            self.conditionSettingsMenuItem:setConditions(self.selectedAbility.conditions) -- get_conditions() makes a copy

            if self.selectedAbility then
                if self.selectedAbility:getConditions():empty() then
                    infoView:setDescription("Edit which weapon skill to use for the selected step.")
                else
                    local description = "Use when: "..self.selectedAbility:getConditionsDescription()
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

function SkillchainSettingsMenuItem:getNextSteps(stepNum)
    local currentSettings = T(self.weaponSkillSettings:getSettings())[self.weaponSkillSettingsMode.value]

    local abilityGambits = currentSettings.Skillchain

    local abilities = abilityGambits:map(function(gambit) return gambit:getAbility() end)
    local previousAbilities = abilities:slice(1, math.max(stepNum - 1, 1)):map(
        function(ability)
            --if ability.__class ~= SkillchainAbility.__class then
            --    return SkillchainAbility.new(ability.resource, ability:get_ability_id())
            --end
            return ability
        end)

    local currentSkillchain = self.skillchainBuilder:reduce_skillchain(previousAbilities)

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

    --[[local currentStep = nextSteps:firstWhere(function(step)
        return step:get_ability():get_name() == self.selectedAbility:get_name()
    end) or nextSteps[1]

    local abilityConfigItem = PickerConfigItem.new('step', currentStep, nextSteps, function(step)
        local suffix = ''
        if step:get_skillchain() then
            suffix = ' ('..step:get_skillchain()..')'
        end
        return step:get_ability():get_localized_name()..suffix
    end, 'Ability')
    return abilityConfigItem]]
    local temp = nextSteps:map(function(step) return step:get_ability()  end)

    return temp
end

function SkillchainSettingsMenuItem:getEditSkillchainStepMenuItem() -- FIXME: use GambitSettingsMenuItem:getEditGambitMenuItem() instead
    --[[local editSkillchainStepMenuItem = MenuItem.new(L{
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

    return editSkillchainStepMenuItem]]

    local editGambitMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        --ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
    }, {}, function(_, _, showMenu)
        local abilitiesByTargetType = {
            [GambitTarget.TargetType.Enemy] = self:getNextSteps(self.selectedIndex) + L{ SkillchainAbility.auto(), SkillchainAbility.skip() }
        }


        -- 1. when SkillchainAbility gets serialized it returns nil. Need to map back to WeaponSkill (DONE, needs testing)
        -- 2. I tried updating CombatSkillSettings to return a WeaponSkill instead which seems to work--will need to do that for other skill types (DONE, needs testing)
        -- 3. Conditions don't currently update proper reference (DONE, needs testing)
        -- 4. Conditions are getting serialized on the WeaponSkill itself. Should filter out non-editable ones like spell? (DONE, needs testing)
        -- 5. Not currently displaying what skillchain the weapon skill makes. Maybe add as param to weapon skill?
        -- 6. Need to add option for Skip and Auto (DONE, needs testing)
        -- 7. Need to update default conditions on onGambitChanged similar to buffer and BuffSettingsMenuItem
        local gambitEditor = GambitSettingsEditor.new(self.selectedAbility, self.weaponSkillSettings, self.weaponSkillSettingsMode, abilitiesByTargetType, self.conditionTargets, showMenu, Gambit.Tags.AllTags)

        gambitEditor:getDisposeBag():add(gambitEditor:onGambitChanged():addAction(function(newGambit, oldGambit)
            --self:onGambitChanged():trigger(newGambit, oldGambit)
            if newGambit:getAbility() ~= oldGambit:getAbility() then
                newGambit.conditions = newGambit.conditions:filter(function(condition)
                    return condition:is_editable()
                end)
                newGambit.conditions_target = GambitTarget.TargetType.Self-- newGambit:getConditionsTarget()
                local conditions = self.skillchainer:get_default_conditions(newGambit)
                for condition in conditions:it() do
                    condition:set_editable(false)
                    newGambit:addCondition(condition)
                end
            end

            self.conditionSettingsMenuItem:setConditions(newGambit.conditions)
            --self.conditionSettingsMenuItem:setConditions(newGambit:getConditions():map(function(condition) return condition:getCondition() end)) -- FIXME
            --self.conditionSettingsMenuItem:setTargetTypes(S{ newGambit:getConditionsTarget() })
        end), gambitEditor:onGambitChanged())


        return gambitEditor
    end, self:getTitleText(), "Edit the selected skillchain step.", false, function()
        return self.selectedIndex ~= nil
    end)

    --[[local editAbilityMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {
        Confirm = MenuItem.action(function(parent)
            --parent:showMenu(editGambitMenuItem)
        end, self:getTitleText(), "Edit ability.")
    }, function(_, infoView, showMenu)
        local configItems = L{}
        if self.selectedGambit:getAbility().get_config_items then
            configItems = self.selectedGambit:getAbility():get_config_items(self.trust) or L{}
        end
        if not configItems:empty() then
            local editAbilityEditor = ConfigEditor.new(self.trustSettings, self.selectedGambit:getAbility(), configItems, infoView, nil, showMenu)

            self.disposeBag:add(editAbilityEditor:onConfigConfirm():addAction(function(newSettings, oldSettings)
                if self.selectedGambit:getAbility().on_config_changed then
                    self.selectedGambit:getAbility():on_config_changed(oldSettings)
                end
            end), editAbilityEditor:onConfigChanged())

            return editAbilityEditor
        end
        return nil
    end, self:getTitleText(), "Edit ability.", false, function()
        return self.selectedGambit ~= nil and self.selectedGambit:getAbility().get_config_items and self.selectedGambit:getAbility():get_config_items():length() > 0
    end)

    editGambitMenuItem:setChildMenuItem("Edit", editAbilityMenuItem)]]
    editGambitMenuItem:setChildMenuItem("Conditions", self.conditionSettingsMenuItem)

    return editGambitMenuItem
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
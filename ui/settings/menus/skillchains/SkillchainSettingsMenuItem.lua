local BuildSkillchainSettingsMenuItem = require('ui/settings/menus/skillchains/BuildSkillchainSettingsMenuItem')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')

local SkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SkillchainSettingsMenuItem.__index = SkillchainSettingsMenuItem

function SkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, skillchainer, trust)
    local skillchainBuilder = SkillchainBuilder.new(skillchainer.skillchain_builder.abilities)
    skillchainBuilder.include_aeonic = true

    local selectedGambit = 1
    local selectedStepNum = 1

    -- FIXME: when this is called by editor it doesn't pass an index so it can't figure out the step
    local descriptionForGambit = function(ability, stepNum)
        local allGambits = T(weaponSkillSettings:getSettings())[weaponSkillSettingsMode.value].Skillchain.Gambits
        local nextSteps = SkillchainSettingsMenuItem.getNextSteps(stepNum, allGambits, skillchainBuilder)
        local suffix = ''
        local step = nextSteps:firstWhere(function(step) return step:get_ability():get_name() == ability:get_name() end)
        if step and step:get_skillchain() then
            suffix = ' ('..step:get_skillchain()..')'
        end
        return string.format("%s%s", ability:get_localized_name(), suffix)
    end

    local editorStyle = GambitEditorStyle.new(function(gambits)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit, stepNum)
            return string.format("Step %d: %s", stepNum, descriptionForGambit(gambit:getAbility(), stepNum))
        end)
        configItem:setAllowsMultipleSelection(false)
        configItem:setNumItemsRequired(1, 1)
        return L{ configItem }
    end, FFXIClassicStyle.WindowSize.Editor.ConfigEditor, "Skillchain", "Skillchain", function(ability, indexPath)
        return descriptionForGambit(ability, selectedStepNum)
    end, function(menuItemName)
        return S{ 'Edit', 'Reset', 'Modes', 'Shortcuts', 'Find' }:contains(menuItemName)
    end)

    local skillchainSettingsItem = GambitSettingsMenuItem.new(trust, weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, 'Skillchain', S{ GambitTarget.TargetType.Enemy }, function(targets)
        local sections = L{
            skillchainBuilder:get_abilities(),
            L{ SkillchainAbility.auto(), SkillchainAbility.skip() }
        }
        return sections
    end,  L{ Condition.TargetType.Self, Condition.TargetType.Ally, Condition.TargetType.Enemy }, editorStyle, L{'AutoSkillchainMode', 'SkillchainPropertyMode', 'SkillchainDelayMode', 'SkillchainAssistantMode', 'WeaponSkillSettingsMode'}, function() return false end)

    local updatePermissions = function(gambit)
        if L{ SkillchainAbility.Auto, SkillchainAbility.Skip }:contains(gambit:getAbility():get_name()) then
            editorStyle:setEditPermissions(
                    GambitEditorStyle.Permissions.None
            )
        else
            editorStyle:setEditPermissions(
                    GambitEditorStyle.Permissions.Edit,
                    GambitEditorStyle.Permissions.Conditions
            )
        end
    end

    skillchainSettingsItem:onSelectGambit():addAction(function(gambit, index)
        updatePermissions(gambit)
        selectedStepNum = index
        selectedGambit = gambit
    end)

    skillchainSettingsItem:setChildMenuItem('Find', BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer))

    skillchainSettingsItem:setDefaultGambitTags(L{'Skillchain'})

    skillchainSettingsItem:getDisposeBag():add(skillchainSettingsItem:onGambitChanged():addAction(function(newGambit, oldGambit)
        if newGambit:getAbility() ~= oldGambit:getAbility() then
            newGambit.conditions = newGambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            newGambit.conditions_target = Condition.TargetType.Self
            local conditions = trust:role_with_type("skillchainer"):get_default_conditions(newGambit)
            for condition in conditions:it() do
                condition:set_editable(false)
                newGambit:addCondition(condition)
            end
            updatePermissions(newGambit)
        end
    end), skillchainSettingsItem:onGambitChanged())

    skillchainSettingsItem:getDisposeBag():add(skillchainSettingsItem:onGambitCreated():addAction(function(newGambit)
    end), skillchainSettingsItem:onGambitCreated())

    skillchainSettingsItem:setConfigKey("skillchains")

    return skillchainSettingsItem
end

function SkillchainSettingsMenuItem.getNextSteps(stepNum, allGambits, skillchainBuilder)
    local abilityGambits = allGambits
    if stepNum == nil then
        stepNum = 1
        print(debug.traceback())
    end
    local abilities = abilityGambits:map(function(gambit) return gambit:getAbility() end)
    local previousAbilities = abilities:slice(1, math.max(stepNum - 1, 1)):map(
            function(ability)
                return ability
            end)
    skillchainBuilder.include_aeonic = true
    local currentSkillchain = skillchainBuilder:reduce_skillchain(previousAbilities)

    skillchainBuilder:set_current_step(SkillchainStep.new(stepNum - 1, abilities[stepNum - 1], currentSkillchain))

    local nextSteps = L{}
    if currentSkillchain or stepNum == 2 then
        nextSteps = skillchainBuilder:get_next_steps():filter(function(step)
            return step:get_skillchain() ~= nil
        end)
    end
    if nextSteps:empty() then
        nextSteps = L{}:extend(L(skillchainBuilder.abilities)):map(function(ability) return SkillchainStep.new(stepNum, ability) end)
    end

    return nextSteps
end

return SkillchainSettingsMenuItem
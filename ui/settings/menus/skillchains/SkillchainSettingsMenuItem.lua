local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MenuItem = require('cylibs/ui/menu/menu_item')

local SkillchainSettingsMenuIetm = setmetatable({}, {__index = MenuItem })
SkillchainSettingsMenuIetm.__index = SkillchainSettingsMenuIetm

-- TODO: migrate weapon skill settings structure to do Skillchains with nested Gambits array so settings.Gambits works

function SkillchainSettingsMenuIetm.new(weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, skillchainer, trust)
    local skillchainSettingsItem = GambitSettingsMenuItem.compact(trust, weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, 'Skillchain', S{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Enemy }, function(targets)
        -- TODO: make this return a different list of abilities depending upon the skillchain step
        local sections = L{
            L(windower.ffxi.get_abilities().weapon_skills):filter(function(weaponSkillId)
                local weaponSkill = res.weapon_skills[weaponSkillId]
                return S(weaponSkill.targets):intersection(targets):length() > 0
            end):map(function(weaponSkillId)
                return WeaponSkill.new(res.weapon_skills[weaponSkillId].en)
            end),
            L{ SkillchainAbility.auto(), SkillchainAbility.skip() }
        }
        return sections
    end, L{ Condition.TargetType.Self, Condition.TargetType.Ally, Condition.TargetType.Enemy }, L{'AutoSkillchainMode', 'SkillchainPropertyMode'}, "Skillchain", "Skillchains", function(_)
        return false
    end, function(ability)
        -- TODO: append the current skillchain property to this
        return ability:get_localized_name()
    end, S{ 'Reaction' })
    skillchainSettingsItem:setDefaultGambitTags(L{'Skillchain'})

    skillchainSettingsItem:getDisposeBag():add(skillchainSettingsItem:onGambitChanged():addAction(function(newGambit, oldGambit)
        if newGambit:getAbility() ~= oldGambit:getAbility() then
            newGambit.conditions = newGambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            newGambit.conditions_target = newGambit:getAbilityTarget() -- FIXME: update conditions target in other gambit settings menu items
            local conditions = trust:role_with_type("skillchainer"):get_default_conditions(newGambit)
            for condition in conditions:it() do
                condition:set_editable(false)
                newGambit:addCondition(condition)
            end
        end
    end), skillchainSettingsItem:onGambitChanged())

    skillchainSettingsItem:getDisposeBag():add(skillchainSettingsItem:onGambitCreated():addAction(function(newGambit)
    end), skillchainSettingsItem:onGambitCreated())

    skillchainSettingsItem:setConfigKey("skillchains")

    return skillchainSettingsItem
end

return SkillchainSettingsMenuIetm
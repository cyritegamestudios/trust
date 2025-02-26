local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local GambitTarget = require('cylibs/gambits/gambit_target')

local DebuffSettingsMenuItem = {}
DebuffSettingsMenuItem.__index = DebuffSettingsMenuItem

function DebuffSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local SpellPickerItemMapper = require('ui/settings/pickers/mappers/SpellPickerItemMapper')

    local debuffItemMapper = SpellPickerItemMapper.new(L{})

    local debuffSettingsItem = GambitSettingsMenuItem.compact(trust, trustSettings, trustSettingsMode, trustModeSettings, 'DebuffSettings', S{ GambitTarget.TargetType.Enemy }, function(targets)
        local sections = L{
            L(trust:get_job():get_spells(function(spellId)
                local spell = res.spells[spellId]
                if spell then
                    local status = buff_util.buff_for_spell(spell.id)
                    return status ~= nil and buff_util.is_debuff(status.id) and S{ 32, 35, 36, 37, 39, 40, 41, 42 }:contains(spell.skill) and targets:intersection(S(spell.targets)):length() > 0
                end
                return false
            end):map(function(spellId)
                return debuffItemMapper:map(Spell.new(res.spells[spellId].en))
            end)):unique(function(spell)
                return spell:get_name()
            end),
            L(trust:get_job():get_job_abilities(function(jobAbilityId)
                local jobAbility = res.job_abilities[jobAbilityId]
                if jobAbility then
                    return buff_util.buff_for_job_ability(jobAbility.id) ~= nil and targets:intersection(S(jobAbility.targets)):length() > 0
                end
                return false
            end):map(function(jobAbilityId)
                return JobAbility.new(res.job_abilities[jobAbilityId].en)
            end)),
        }
        return sections
    end, L{ Condition.TargetType.Enemy }, L{'AutoDebuffMode', 'AutoDispelMode', 'AutoSilenceMode'}, "Debuff", "Debuffs", function(_)
        return false
    end, function(ability)
        local debuff = ability:get_status()
        if debuff then
            return "Inflicts: "..i18n.resource('buffs', 'en', debuff.en).."."
        end
        return nil
    end, S{ 'Reaction' })
    debuffSettingsItem:setDefaultGambitTags(L{'Debuffs'})

    debuffSettingsItem:getDisposeBag():add(debuffSettingsItem:onGambitChanged():addAction(function(newGambit, oldGambit)
        if newGambit:getAbility() ~= oldGambit:getAbility() then
            newGambit.conditions = newGambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            local conditions = trust:role_with_type("debuffer"):get_default_conditions(newGambit)
            for condition in conditions:it() do
                condition.editable = false
                newGambit:addCondition(condition)
            end
        end
    end), debuffSettingsItem:onGambitChanged())

    debuffSettingsItem:setConfigKey("debuffs")

    return debuffSettingsItem
end

return DebuffSettingsMenuItem
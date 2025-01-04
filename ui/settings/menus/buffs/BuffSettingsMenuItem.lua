local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local GambitTarget = require('cylibs/gambits/gambit_target')
local JobAbilityPickerItemMapper = require('ui/settings/pickers/mappers/JobAbilityPickerItemMapper')
local MenuItem = require('cylibs/ui/menu/menu_item')

local BuffSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuffSettingsMenuItem.__index = BuffSettingsMenuItem

function BuffSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, settingsKeys)
    local SpellPickerItemMapper = require('ui/settings/pickers/mappers/SpellPickerItemMapper')

    local buffItemMapper = SpellPickerItemMapper.new(L{})
    local jobAbilityItemMapper = JobAbilityPickerItemMapper.new()

    local buffSettingsItem = GambitSettingsMenuItem.compact(trust, trustSettings, trustSettingsMode, trustModeSettings, (settingsKeys and settingsKeys + L{ 'BuffSettings' }) or 'BuffSettings', S{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally }, function(targets)
        local sections = L{
            L(trust:get_job():get_spells(function(spellId)
                local spell = res.spells[spellId]
                if spell then
                    local valid_targets = S(spell.targets)
                    if spell.en:contains('Absorb') then
                        valid_targets = S{ 'Self' }
                    end
                    local status = buff_util.buff_for_spell(spell.id)
                    return status ~= nil and not buff_util.is_debuff(status.id) and spell.skill ~= 44 and targets:intersection(valid_targets):length() > 0
                end
                return false
            end):map(function(spellId)
                return buffItemMapper:map(Spell.new(res.spells[spellId].en))
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
                return jobAbilityItemMapper:map(JobAbility.new(res.job_abilities[jobAbilityId].en))
            end)),
        }
        return sections
    end, L{ Condition.TargetType.Self, Condition.TargetType.Ally }, L{'AutoBarSpellMode', 'AutoBuffMode'}, "Buff", "Buffs", function(_)
        return false
    end, function(ability)
        local buff = ability:get_status()
        if buff then
            return "Grants: "..i18n.resource('buffs', 'en', buff.en).."."
        end
        return nil
    end)
    buffSettingsItem:setDefaultGambitTags(L{'Buffs'})

    buffSettingsItem:getDisposeBag():add(buffSettingsItem:onGambitChanged():addAction(function(newGambit, oldGambit)
        if newGambit:getAbility() ~= oldGambit:getAbility() then
            newGambit.conditions = newGambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            local conditions = trust:role_with_type("buffer"):get_default_conditions(newGambit)
            for condition in conditions:it() do
                condition.editable = false
                newGambit:addCondition(condition)
            end
        end
    end), buffSettingsItem:onGambitChanged())

    return buffSettingsItem
end

return BuffSettingsMenuItem
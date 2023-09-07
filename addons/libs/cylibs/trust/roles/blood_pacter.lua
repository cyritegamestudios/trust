local BloodPacter = setmetatable({}, {__index = Role })
BloodPacter.__index = BloodPacter

function BloodPacter.new()
    local self = setmetatable(Role.new(action_queue), BloodPacter)

    return self
end

function BloodPacter:destroy()
    Role.destroy(self)
end

function BloodPacter:on_add()
    Role.on_add(self)
end

function BloodPacter:target_change(target_index)
    Role.target_change(self, target_index)
end

function BloodPacter:job_magic_burst(spell)
    --[[if action == 'ws' then
        player.trust.main_job:job_weapon_skill(param)
    elseif action == 'ja' then
        local job_ability = res.job_abilities:with('en', param)
        if job_ability then
            if job_ability.type == 'BloodPactRage' then
                if state.AutoAvatarMode.value ~= 'Off' and pet_util.has_pet() and pet_util.pet_name() == state.AutoAvatarMode.value and windower.ffxi.get_ability_recasts()[173] < 1 and not action_queue:contains_action_of_type('bloodpactrageaction') then
                    action_queue:push_action(BloodPactRageAction.new(0, 0, 0, param), true)
                end
            else
                action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability.en), true)
            end
        end
    elseif action == 'mb' then
        local spell = res.spells:with('en', param)
        if spell and spell.status == nil then
            local target = windower.ffxi.get_mob_by_index(player.current_target)
            if target then
                windower.send_command('gs c set MagicBurstMode Single')
                player.trust.main_job:job_magic_burst(target.id, spell)
            end
        else
            local job_ability = res.job_abilities:with('en', param)
            if job_ability then
                if job_ability.type == 'BloodPactRage' then
                    if state.AutoAvatarMode.value ~= 'Off' and pet_util.has_pet() and pet_util.pet_name() == state.AutoAvatarMode.value and windower.ffxi.get_ability_recasts()[173] < 1 and not action_queue:contains_action_of_type('bloodpactrageaction') then
                        local blood_pact_rage_action = BloodPactRageAction.new(0, 0, 0, param)
                        --blood_pact_rage_action.priority = ActionPriority.highest
                        if player_util.get_job_ability_recast('Apogee') == 0 then
                            action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Apogee'), true)
                            action_queue:push_action(WaitAction.new(0, 0, 0, 2))
                        end
                        blood_pact_rage_action.priority = ActionPriority.highest
                        action_queue:push_action(blood_pact_rage_action, true)
                    end
                end
            end
        end
    end]]
end

function BloodPacter:allows_duplicates()
    return false
end

function BloodPacter:get_type()
    return "bloodpacter"
end

return BloodPacter
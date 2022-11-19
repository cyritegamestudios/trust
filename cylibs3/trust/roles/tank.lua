local Tank = setmetatable({}, {__index = Role })
Tank.__index = Tank

function Tank.new(action_queue, job_ability_names, spells)
    local self = setmetatable(Role.new(settings, action_queue), Tank)
    self.job_ability_names = (job_ability_names or L{}):filter(function(job_ability_name) job_util.knows_job_ability(job_util.job_ability_id(job_ability_name))  end)
    self.spells = (spells or L{}):filter(function(spell) return spell_util.knows_spell(spell:get_spell().id) end)
    return self
end

function Tank:destroy()
    Role.destroy(self)

    Monster.target_change:removeAction(self.monster_target_change_id)
end

function Tank:on_add()
    Role.on_add(self)

    self.monster_target_change_id = Monster.target_change:addAction(
            function (m, monster_target_index)
                if self.target_index and m:get_mob().index == self.target_index
                        and monster_target_index ~= windower.ffxi.get_player().index then
                    self:pull_hate()
                end
            end)

    return self
end

function Tank:target_change(target_index)
    Role.target_change(self, target_index)

    if self.battle_target then
        self.battle_target:destroy()
        self.battle_target = nil
    end

    self.target_index = target_index

    if target_index then
        self.battle_target = Monster.new(windower.ffxi.get_mob_by_index(target_index).id)
        self.battle_target:monitor()
        self.battle_target:on_target_change():addAction(
                function (_, target_index)
                    if target_index ~= windower.ffxi.get_player().index then
                        self:pull_hate(target_index)
                    end
                end)
    end
end

function Tank:tic(_, _)
    if self.target_index == nil then return end
end

function Tank:pull_hate(target_index)
    for job_ability_name in self.job_ability_names:it() do
        if job_util.can_use_job_ability(job_ability_name) then
            local actions = L{
                WaitAction.new(0, 0, 0, 2),
                JobAbilityAction.new(0, 0, 0, job_ability_name, target_index)
            }
            self.action_queue:push_action(SequenceAction.new(actions, 'tank_pull_hate'), true)
            return
        end
    end
end

function Tank:allows_duplicates()
    return true
end

function Tank:get_type()
    return "tank"
end

return Tank
local logger = require('cylibs/logger/logger')

local GambitTarget = require('cylibs/gambits/gambit_target')
local Gambiter = setmetatable({}, {__index = Role })
Gambiter.__index = Gambiter
Gambiter.__class = "Gambiter"

state.AutoGambitMode = M{['description'] = 'Auto Gambit Mode', 'Off', 'Auto'}
state.AutoGambitMode:set_description('Off', "Okay, I'll ignore any gambits you've set.")
state.AutoGambitMode:set_description('Auto', "Okay, I'll customize my battle plan with gambits.")

function Gambiter.new(action_queue, gambit_settings)
    local self = setmetatable(Role.new(action_queue), Gambiter)

    self.action_queue = action_queue

    self:set_gambit_settings(gambit_settings)

    return self
end

function Gambiter:destroy()
    Role.destroy(self)
end

function Gambiter:on_add()
    Role.on_add(self)

    -- Enemy abilities
    WindowerEvents.Ability.Ready:addAction(function(target_id, ability_id)
        if not ability_id then
            return
        end
        local target = self:get_target()
        if target and target:get_id() == target_id then
            local ability = res.monster_abilities[ability_id]
            if ability then
                logger.notice(self.__class, 'ability_ready', 'check_gambits', ability.en)

                self:check_gambits(L{ target }, ability.en)
            end
        end
    end)
end

function Gambiter:target_change(target_index)
    Role.target_change(self, target_index)
end

function Gambiter:tic(new_time, old_time)
    if state.AutoGambitMode.value == 'Off' then
        return
    end
    self:check_gambits()
end

function Gambiter:check_gambits(targets, param)
    if state.AutoGambitMode.value == 'Off' then
        return
    end

    logger.notice(self.__class, 'check_gambits')

    for gambit in self.gambits:it() do
        local targets = targets or self:get_gambit_targets(gambit:getConditionsTarget()) or L{}
        for target in targets:it() do
            if gambit:isSatisfied(target, param) then
                if gambit:getAbilityTarget() == gambit:getConditionsTarget() then
                    self:perform_gambit(gambit, target)
                    return
                else
                    local ability_targets = self:get_gambit_targets(gambit:getAbilityTarget())
                    if ability_targets:length() > 0 then
                        self:perform_gambit(gambit, ability_targets[1])
                        return
                    end
                end
                break
            end
        end
    end
end

function Gambiter:get_gambit_targets(gambit_target)
    local targets = L{}
    local target_group
    if gambit_target == GambitTarget.TargetType.Self then
        target_group = self:get_player()
    elseif gambit_target == GambitTarget.TargetType.Ally then
        target_group = self:get_party()
    elseif gambit_target == GambitTarget.TargetType.Enemy then
        target_group = self:get_target()
    end
    if target_group then
        targets = L{ target_group }
        if target_group.__class == Party.__class then
            targets = target_group:get_party_members(false, 21)
        end
    end
    return targets
end

function Gambiter:perform_gambit(gambit, target)
    if target == nil or target:get_mob() == nil then
        return
    end

    logger.notice(self.__class, 'perform_gambit', gambit:tostring(), target:get_mob().name)

    local action = gambit:getAbility():to_action(target:get_mob().index, self:get_player())
    if action then
        action.priority = ActionPriority.highest
        self.action_queue:push_action(action, true)
    end
end

function Gambiter:allows_duplicates()
    return true
end

function Gambiter:get_type()
    return "gambiter"
end

function Gambiter:set_gambit_settings(gambit_settings)
    self.gambits = gambit_settings.Gambits
end

function Gambiter:tostring()
    return tostring(self.gambits)
end

return Gambiter
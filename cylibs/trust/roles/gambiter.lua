local logger = require('cylibs/logger/logger')
local Timer = require('cylibs/util/timers/timer')

local GambitTarget = require('cylibs/gambits/gambit_target')
local Gambiter = setmetatable({}, {__index = Role })
Gambiter.__index = Gambiter
Gambiter.__class = "Gambiter"

state.AutoGambitMode = M{['description'] = 'Use Gambits', 'Auto', 'Off'}
state.AutoGambitMode:set_description('Off', "Okay, I'll ignore any gambits you've set.")
state.AutoGambitMode:set_description('Auto', "Okay, I'll customize my battle plan with gambits.")

function Gambiter.new(action_queue, gambit_settings, state_var)
    local self = setmetatable(Role.new(action_queue), Gambiter)

    self.action_queue = action_queue
    self.state_var = state_var or state.AutoGambitMode
    self.timer = Timer.scheduledTimer(1)
    self.enabled = true
    self.last_gambit_time = os.time() - self:get_cooldown()

    self:set_gambit_settings(gambit_settings)

    return self
end

function Gambiter:destroy()
    Role.destroy(self)

    self.timer:destroy()
end

function Gambiter:on_add()
    Role.on_add(self)

    self.timer:onTimeChange():addAction(function(_)
        if not self:is_enabled() then
            return
        end
        self:check_gambits()
    end)

    self.timer:start()
end

function Gambiter:target_change(target_index)
    Role.target_change(self, target_index)
end

function Gambiter:get_cooldown()
    return 0
end

function Gambiter:check_gambits(targets, gambits, param, ignore_delay)
    if self.state_var.value == 'Off' or not ignore_delay and (os.time() - self.last_gambit_time) < self:get_cooldown() then
        return
    end

    logger.notice(self.__class, 'check_gambits', self:get_type(), self.state_var.value)

    if not self:allows_multiple_actions() and self.action_queue:has_action(self:get_action_identifier()) then
        logger.notice(self.__class, 'check_gambits', self:get_type(), 'duplicate')
        return
    end

    local gambits = (gambits or self:get_all_gambits()):filter(function(gambit) return gambit:isEnabled() end)
    for gambit in gambits:it() do
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

    logger.notice(self.__class, 'check_gambits', self:get_type(), 'checked', gambits:length(), 'gambits')
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
        self.last_gambit_time = os.time()

        if gambit:getTags():contains('reaction') or gambit:getTags():contains('Reaction') then
            self.action_queue:clear()
        end
        action.priority = ActionPriority.highest
        if not self:allows_multiple_actions() then
            action.identifier = self:get_action_identifier()
        end
        self.action_queue:push_action(action, true)
    end
end

function Gambiter:allows_duplicates()
    return true
end

function Gambiter:get_type()
    return "gambiter"
end

function Gambiter:allows_multiple_actions()
    return true
end

function Gambiter:get_action_identifier()
    return self:get_type()..'_action'
end

function Gambiter:set_gambit_settings(gambit_settings)
    self.gambits = (gambit_settings.Gambits or L{}):filter(function(gambit)
        return gambit:getAbility() ~= nil
    end)
    self.job_gambits = (gambit_settings.Default or L{}):filter(function(gambit)
        return gambit:getAbility() ~= nil
    end)
end

function Gambiter:get_all_gambits()
    return L{}:extend(self.gambits):extend(self.job_gambits)
end

function Gambiter:is_enabled()
    return self.state_var.value ~= 'Off' and self.enabled
end

function Gambiter:set_enabled(enabled)
    self.enabled = enabled
end

function Gambiter:tostring()
    return tostring(self:get_all_gambits())
end

return Gambiter
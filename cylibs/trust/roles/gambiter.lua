local logger = require('cylibs/logger/logger')
local Timer = require('cylibs/util/timers/timer')
local GambitTarget = require('cylibs/gambits/gambit_target')
local GambitTargetGroup = require('cylibs/gambits/gambit_target_group')

local Gambiter = setmetatable({}, {__index = Role })
Gambiter.__index = Gambiter
Gambiter.__class = "Gambiter"

state.AutoGambitMode = M{['description'] = 'Use Gambits', 'Auto', 'Off'}
state.AutoGambitMode:set_description('Auto', "Automatically use gambits.")

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

function Gambiter:check_gambits(gambits, param, ignore_delay)
    if self.state_var.value == 'Off' or not ignore_delay and (os.time() - self.last_gambit_time) < self:get_cooldown() then
        return
    end
    --  self.last_gambit_time = os.time() -- FIXME: should i really add this? Otherwise cooldown isn't respected

    logger.notice(self.__class, 'check_gambits', self:get_type(), self.state_var.value)

    if not self:allows_multiple_actions() and self.action_queue:has_action(self:get_action_identifier()) then
        logger.notice(self.__class, 'check_gambits', self:get_type(), 'duplicate')
        return
    end

    local gambits = (gambits or self:get_all_gambits()):filter(function(gambit) return gambit:isEnabled() end)
    for gambit in gambits:it() do
        local success, target = self:is_gambit_satisfied(gambit, param)
        if success then
            self:perform_gambit(gambit, target)
            break
        end
    end

    logger.notice(self.__class, 'check_gambits', self:get_type(), 'checked', gambits:length(), 'gambits')
end

function Gambiter:is_gambit_satisfied(gambit, param)
    local target_types = L{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Enemy }
    if gambit:hasConditionTarget(GambitTarget.TargetType.Ally) then
        target_types:append(GambitTarget.TargetType.Ally)
    end
    local gambit_target_group = GambitTargetGroup.new(self:get_gambit_targets(target_types))
    for targets_by_type in gambit_target_group:it() do
        local get_target_by_type = function(target_type)
            return targets_by_type[target_type]
        end
        if gambit:isSatisfied(get_target_by_type, param) then
            local target = get_target_by_type(gambit:getAbilityTarget())
            return true, target
        end
    end
    return false, nil
end

function Gambiter:get_gambit_targets(gambit_target_types)
    gambit_target_types = gambit_target_types or L(Condition.TargetType.AllTargets)
    if class(gambit_target_types) ~= 'List' then
        gambit_target_types = L{ gambit_target_types }
    end
    local targets_by_type = {}
    for gambit_target_type in gambit_target_types:it() do
        local target_group
        if gambit_target_type == GambitTarget.TargetType.Self then
            target_group = self:get_player()
        elseif gambit_target_type == GambitTarget.TargetType.Ally then
            target_group = self:get_party()
        elseif gambit_target_type == GambitTarget.TargetType.Enemy then
            target_group = self:get_target()
        end
        if target_group then
            local targets = L{}
            if target_group.__class == Party.__class then
                targets = targets + target_group:get_party_members(false, 21)
            else
                targets = targets + L{ target_group }
            end
            targets_by_type[gambit_target_type] = targets
        end
    end
    return targets_by_type
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
---------------------------
-- Action representing the player following a target until a condition is met.
-- @class module
-- @name FollowAction

local alter_ego_util = require('cylibs/util/alter_ego_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local Timer = require('cylibs/util/timers/timer')

local Action = require('cylibs/actions/action')
local FollowAction = setmetatable({}, {__index = Action })
FollowAction.__index = FollowAction

function FollowAction.new(target_index, complete_conditions)
    local conditions = L{
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), FollowAction)
    self.complete_conditions = complete_conditions or L{ MaxDistanceCondition.new(3, target_index) }
    self.dispose_bag = DisposeBag.new()
    return self
end

function FollowAction:destroy()
    self.dispose_bag:destroy()
    windower.ffxi.follow()
    Action.destroy(self)
end

function FollowAction:complete(success)
    windower.ffxi.follow()
    if self.timer then
        self.timer:cancel()
    end
    Action.complete(self, success)
end

function FollowAction:perform()
    self.start_time = os.time()

    self.timer = Timer.scheduledTimer(0.1, 0.0)

    self.dispose_bag:addAny(L{ self.timer })
    self.dispose_bag:add(self.timer:onTimeChange():addAction(function(_)
        if os.time() - self.start_time > self:get_max_duration() then
            self:complete(false)
        else
            self:check_follow()
        end
    end), self.timer:onTimeChange())

    self.timer:start()
end

function FollowAction:check_follow(retry_count)
    if Condition.check_conditions(self.complete_conditions, self.target_index) or windower.ffxi.get_mob_by_target('t') == nil then
        windower.ffxi.follow()
        self:complete(true)
        return
    end

    if Condition.check_conditions(L{ MaxDistanceCondition.new(2) }, self.target_index) then
        windower.ffxi.follow()
    else
        if not self:is_following() then
            windower.send_command('input /follow <t>')
        end
    end
end

function FollowAction:is_following()
    local player = windower.ffxi.get_player()
    return player and player.follow_index == self.target_index
end

function FollowAction:gettype()
    return "followaction"
end

function FollowAction:getrawdata()
    local res = {}

    res.followaction = {}
    res.followaction.x = self.x
    res.followaction.y = self.y
    res.followaction.z = self.z

    return res
end

function FollowAction:copy()
    return FollowAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function FollowAction:tostring()
    return "FollowAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return FollowAction




---------------------------
-- Action representing the player following a target until a condition is met.
-- @class module
-- @name FollowAction

local alter_ego_util = require('cylibs/util/alter_ego_util')

local Action = require('cylibs/actions/action')
local FollowAction = setmetatable({}, {__index = Action })
FollowAction.__index = FollowAction

function FollowAction.new(target_index, complete_conditions)
    local conditions = L{
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), FollowAction)
    self.complete_conditions = complete_conditions or L{ MaxDistanceCondition.new(3, target_index) }
    return self
end

function FollowAction:complete(success)
    windower.ffxi.follow()
    Action.complete(self, success)
end

function FollowAction:perform()
    local target = windower.ffxi.get_mob_by_target('t')
    if target then
        self:check_follow(0)
    else
        self:complete(false)
    end
end

function FollowAction:check_follow(retry_count)
    if Condition.check_conditions(self.complete_conditions, self.target_index) then
        windower.ffxi.follow()
        self:complete(true)
    elseif retry_count > 100 then
        windower.ffxi.follow()
        self:complete(false)
    else
        if not self:is_following() then
            windower.send_command('input /follow <t>')
        end

        local walk_time = 0.2

        coroutine.schedule(function()
            self:check_follow(retry_count + 1)
        end, walk_time)
    end
end

function FollowAction:is_following()
    local player = windower.ffxi.get_player()
    return player and player.follow_index == self.target_index
end

function FollowAction:gettype()
    return "runtoaction"
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




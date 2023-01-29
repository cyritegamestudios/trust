---------------------------
-- Action representing the player pulling a mob.
-- @class module
-- @name PullAction

require('coroutine')
require('vectors')
require('math')

local Action = require('cylibs/actions/action')
local PullAction = setmetatable({}, {__index = Action })
PullAction.__index = PullAction

function PullAction.new(job_ability_name, target_id)
    local self = setmetatable(Action.new(0, 0, 0), PullAction)
    self.job_ability_name = job_ability_name
    self.target_id = target_id
    return self
end

function PullAction:can_perform()
    if windower.ffxi.get_player().status ~= 0 then
        return false
    end
    local target = windower.ffxi.get_mob_by_target("bt")
    if target and target.hpp > 0 then
        return false
    end

    local job_abilities = player_util.get_job_abilities()

    if not job_abilities:contains(res.job_abilities:with('en', self.job_ability_name).id) then return false end

    local recast_id = res.job_abilities:with('en', self.job_ability_name).recast_id
    if windower.ffxi.get_ability_recasts()[recast_id] > 0 then
        return false
    end

    return true
end

function PullAction:perform()
    local target = windower.ffxi.get_mob_by_id(self.target_id)
    if target == nil or target.distance:sqrt() > 18 then
        self:complete(false)
        return
    end

    windower.chat.input('/'..self.job_ability_name..' '..target.id)

    self:complete(true)
end

function PullAction:get_job_ability_name()
    return self.job_ability_name
end

function PullAction:gettype()
    return "pullaction"
end

function PullAction:getrawdata()
    local res = {}

    res.pullaction = {}
    res.pullaction.x = self.x
    res.pullaction.y = self.y
    res.pullaction.z = self.z
    res.pullaction.command = self:get_command()

    return res
end

function PullAction:copy()
    return PullAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_job_ability_name())
end

function PullAction:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_job_ability_name() == action:get_job_ability_name()
end

function PullAction:tostring()
    return "PullAction command: %s":format(self.command)
end

return PullAction
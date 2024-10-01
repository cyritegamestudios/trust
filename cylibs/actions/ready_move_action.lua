---------------------------
-- Action representing a BST ready move.
-- @class module
-- @name ReadyMoveAction

require('coroutine')
require('vectors')
require('math')

local Action = require('cylibs/actions/action')
local ReadyMoveAction = setmetatable({}, {__index = Action })
ReadyMoveAction.__index = ReadyMoveAction

function ReadyMoveAction.new(x, y, z, ready_move_name, target_index)
    local self = setmetatable(Action.new(x, y, z), ReadyMoveAction)
    self.ready_move_name = ready_move_name
    self.target_index = target_index
    return self
end

function ReadyMoveAction:can_perform()
    local recast_id = res.job_abilities:with('en', self.ready_move_name).recast_id
    if windower.ffxi.get_ability_recasts()[recast_id] == 0 then
        return true
    end
    return false
end

function ReadyMoveAction:perform()
    if self.target_index == nil then
        windower.chat.input('/%s':format(self.ready_move_name))
    else
        local target = windower.ffxi.get_mob_by_index(self.target_index)
        if target then
            windower.chat.input('/'..self.ready_move_name..' '..target.id)
        end
    end

    coroutine.sleep(1)

    self:complete(true)
end

function ReadyMoveAction:get_ready_move_name()
    return self.ready_move_name
end

function ReadyMoveAction:gettype()
    return "readymoveaction"
end

function ReadyMoveAction:getrawdata()
    local res = {}

    res.readymoveaction = {}
    res.readymoveaction.x = self.x
    res.readymoveaction.y = self.y
    res.readymoveaction.z = self.z
    res.readymoveaction.command = self:get_command()

    return res
end

function ReadyMoveAction:getidentifier()
    return self.ready_move_name
end

function ReadyMoveAction:copy()
    return ReadyMoveAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_ready_move_name())
end

function ReadyMoveAction:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_ready_move_name() == action:get_ready_move_name()
end

-- Fixed tostring method
function ReadyMoveAction:tostring()
    return "ReadyMoveAction command: %s":format(self.ready_move_name)
end

return ReadyMoveAction

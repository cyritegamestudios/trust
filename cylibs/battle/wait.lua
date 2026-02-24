---------------------------
-- Action representing a wait.
-- @class module
-- @name Wait

local serializer_util = require('cylibs/util/serializer_util')
local WaitAction = require('cylibs/actions/wait')

local Wait = {}
Wait.__index = Wait
Wait.__class = "Wait"
Wait.__type = "Wait"

-------
-- Default initializer for a new wait.
-- @tparam number duration Duration in seconds
-- @treturn Wait A wait.
function Wait.new(duration)
    local self = setmetatable({}, Wait)

    self.duration = duration
    self.conditions = L{}

    return self
end

function Wait:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Wait:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions..
-- @treturn list List of conditions
function Wait:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function Wait:get_range()
    return 999
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Wait:get_name()
    return 'Wait'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized action name
function Wait:get_localized_name()
    return self:get_name()
end

-------
-- Returns the ability id for the action.
-- @treturn string Ability id
function Wait:get_ability_id()
    return string.format("wait_%d", self.duration)
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function Wait:to_action(target_index, player)
    return WaitAction.new(0, 0, 0, self.duration)
end

function Wait:serialize()
    return "Wait.new(" .. serializer_util.serialize_args(self.duration) .. ")"
end

function Wait:is_valid()
    return true
end

function Wait:__eq(otherItem)
    if otherItem.__type == self.__type then
        return self.duration == otherItem.duration
    end
    return false
end

return Wait
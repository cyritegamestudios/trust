---------------------------
-- Action to run a windower command.
-- @class module
-- @name Command

local serializer_util = require('cylibs/util/serializer_util')

local Command = {}
Command.__index = Command
Command.__class = "Command"

-------
-- Default initializer for a new command.
-- @treturn Command A command.
function Command.new(windower_command, conditions)
    local self = setmetatable({}, Command)
    self.windower_command = windower_command or '/jump'
    self.conditions = conditions or L{}
    return self
end

function Command:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Command:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for turning around.
-- @treturn list List of conditions
function Command:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function Command:get_range()
    return 999
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Command:get_name()
    return 'Command'
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function Command:to_action(target_index, _)
    return CommandAction.new(0, 0, 0, self.windower_command)
end

function Command:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "Command.new(" .. serializer_util.serialize_args(self.windower_command, conditions_to_serialize) .. ")"
end

return Command
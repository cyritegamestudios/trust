---------------------------
-- Action to run a script.
-- @class module
-- @name Script

local BlockAction = require('cylibs/actions/block')
local serializer_util = require('cylibs/util/serializer_util')

local Script = {}
Script.__index = Script
Script.__class = "Script"
Script.__type = "Script"

-------
-- Default initializer for a new script.
-- @treturn Script A script.
function Script.new(block, conditions, description)
    local self = setmetatable({}, Script)
    self.block = block or function() end
    self.conditions = conditions or L{}
    self.description = description
    return self
end

function Script:destroy()
end

-------
-- Adds a condition to the list of conditions.
-- @tparam Condition condition Condition to add
function Script:add_condition(condition)
    if not self:get_conditions():contains(condition) then
        self.conditions:append(condition)
    end
end

-------
-- Returns the list of conditions for turning around.
-- @treturn list List of conditions
function Script:get_conditions()
    return self.conditions
end

-------
-- Returns the maximum range in yalms.
-- @treturn number Range in yalms
function Script:get_range()
    return 999
end

-------
-- Returns the name for the action.
-- @treturn string Action name
function Script:get_name()
    return 'Script'
end

-------
-- Returns the localized name for the action.
-- @treturn string Localized name
function Script:get_localized_name()
    return 'Script'
end

function Script:get_display_name()
    return self.description or 'Script'
end

function Script:get_ability_id()
    return 0
end

function Script:__tostring()
    return self:get_display_name()
end

function Script:get_block()
    return self.block
end

function Script:get_config_items()
    return L{}
end

-------
-- Return the Action to use this action on a target.
-- @treturn Action Action to use ability
function Script:to_action(target_index, _)
    return BlockAction.new(self.block, self.description, self.description)
end

--[[function Script:serialize()
    local conditions_classes_to_serialize = Condition.defaultSerializableConditionClasses()
    local conditions_to_serialize = self.conditions:filter(function(condition)
        return conditions_classes_to_serialize:contains(condition.__class)
    end)
    return "Script.new(" .. serializer_util.serialize_args(self.windower_command, conditions_to_serialize) .. ")"
end]]

function Script:copy()
    return Script.new(self.block, self.conditions:copy(), self.description)
end

function Script:is_valid()
    return true
end

function Script:__eq(otherItem)
    if otherItem.__type == self.__type and otherItem:get_block() == self:get_block() then
        return true
    end
    return false
end

return Script
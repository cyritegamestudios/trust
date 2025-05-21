---------------------------
-- Condition checking a cooldown.
-- @class module
-- @name CooldownCondition

local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local CooldownCondition = setmetatable({}, { __index = Condition })
CooldownCondition.__index = CooldownCondition
CooldownCondition.__type = "CooldownCondition"
CooldownCondition.__class = "CooldownCondition"

local timestamps = {}

function CooldownCondition.set_timestamp(key, timestamp)
    timestamps[key] = timestamp
end

function CooldownCondition.get_timestamp(key)
    return timestamps[key]
end


function CooldownCondition.new(key, num_seconds)
    local self = setmetatable(Condition.new(), CooldownCondition)
    self.key = key
    self.num_seconds = num_seconds
    return self
end

function CooldownCondition:is_satisfied(_)
    local last_timestamp = CooldownCondition.get_timestamp(self.key) or os.time() - self.num_seconds
    return os.time() > last_timestamp + self.num_seconds
end

function CooldownCondition:get_config_items()
    return L{
        TextInputConfigItem.new('key', self.key, 'Identifier', function(_) return true  end),
        ConfigItem.new('num_seconds', 0, 500, 1, function(value) return value.."s" end, "Cooldown"),
    }
end

function CooldownCondition:tostring()
    return string.format("Cooldown of %ds for %s", self.num_seconds, self.key)
end

function CooldownCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Enemy, Condition.TargetType.Ally }
end

function CooldownCondition:serialize()
    return "CooldownCondition.new(" .. serializer_util.serialize_args(self.key, self.num_seconds) .. ")"
end

function CooldownCondition.description()
    return "Cooldown."
end

function CooldownCondition:__eq(otherItem)
    return otherItem.__class == CooldownCondition.__class
            and self.key == otherItem.key
            and self.num_seconds == otherItem.num_seconds
end

return CooldownCondition





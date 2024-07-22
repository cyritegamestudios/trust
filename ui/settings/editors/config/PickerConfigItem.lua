local PickerConfigItem = {}
PickerConfigItem.__index = PickerConfigItem
PickerConfigItem.__type = "PickerConfigItem"

---
-- Creates a new ConfigItem instance.
--
-- @tparam string key The key in the config.
-- @tparam number minValue The minimum value in the range.
-- @tparam number maxValue The maximum value in the range.
-- @tparam number interval The range interval.
-- @tparam function Formatter for current value.
-- @treturn ConfigItem The newly created ConfigItem instance.
--
function PickerConfigItem.new(key, initialValue, allValues, textFormat, description, onReload)
    local self = setmetatable({}, PickerConfigItem)

    self.key = key
    self.initialValue = initialValue
    self.allValues = allValues
    self.textFormat = textFormat or function(value)
        return tostring(value)
    end
    self.description = description or key
    self.dependencies = L{}
    self.onReload = onReload

    return self
end

---
-- Gets the config key.
--
-- @treturn string The config key.
--
function PickerConfigItem:getKey()
    return self.key
end

---
-- Gets the initial value.
--
-- @treturn number The initial value.
--
function PickerConfigItem:getInitialValue()
    return self.initialValue
end

---
-- Gets all possible values.
--
-- @treturn list All possible values.
--
function PickerConfigItem:getAllValues()
    return self.allValues
end

---
-- Sets all possible values.
--
-- @tparam list allValues All possible values.
--
function PickerConfigItem:setAllValues(allValues)
    self.allValues = allValues
    if not self.allValues:contains(self.initialValue) then
        self.initialValue = self.allValues[1]
    end
end

---
-- Gets the formatted text.
--
-- @treturn function The formatted text.
--
function PickerConfigItem:getTextFormat()
    return self.textFormat
end

---
-- Gets the description.
--
-- @treturn string The description.
--
function PickerConfigItem:getDescription()
    return self.description
end

---
-- Adds a ConfigItem dependency.  When the value of this PickerConfigItem changes, dependency
-- ConfigItems will be reloaded.
--
-- @tparam ConfigItem ConfigItem dependency.
--
function PickerConfigItem:addDependency(configItem)
    self.dependencies:append(configItem)
end

---
-- Gets the dependencies. When the value of this PickerConfigItem changes, dependency
-- ConfigItems will be reloaded.
--
-- @treturn list List of ConfigItem dependencies.
--
function PickerConfigItem:getDependencies()
    return self.dependencies
end

return PickerConfigItem
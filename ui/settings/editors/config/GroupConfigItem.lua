local GroupConfigItem = {}
GroupConfigItem.__index = GroupConfigItem
GroupConfigItem.__type = "GroupConfigItem"

---
-- Creates a new ConfigItem instance.
--
-- @tparam string key The key in the config.
-- @tparam list configItems The list of config items
-- @tparam function Formatter for current value.
-- @tparam string description Friendly description.
-- @treturn GroupConfigItem The newly created GroupConfigItem instance.
--
function GroupConfigItem.new(key, configItems, textFormat, description)
    local self = setmetatable({}, GroupConfigItem)

    self.key = key
    self.configItems = configItems
    self.textFormat = textFormat or function(value)
        return tostring(value)
    end
    self.description = description or key

    return self
end

---
-- Gets the config key.
--
-- @treturn string The config key.
--
function GroupConfigItem:getKey()
    return self.key
end

---
-- Gets the config items.
--
-- @treturn list The list of ConfigItem.
--
function GroupConfigItem:getConfigItems()
    return self.configItems
end

---
-- Gets the formatted text.
--
-- @treturn function The formatted text.
--
function GroupConfigItem:getTextFormat()
    return self.textFormat
end

---
-- Gets the description.
--
-- @treturn string The description.
--
function GroupConfigItem:getDescription()
    return self.description
end

return GroupConfigItem
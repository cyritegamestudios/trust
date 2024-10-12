local MultiPickerConfigItem = {}
MultiPickerConfigItem.__index = MultiPickerConfigItem
MultiPickerConfigItem.__type = "MultiPickerConfigItem"

---
-- Creates a new MultiPickerConfigItem instance.
--
-- @tparam string key The key in the config.
-- @tparam number minValue The minimum value in the range.
-- @tparam number maxValue The maximum value in the range.
-- @tparam number interval The range interval.
-- @tparam function Formatter for current value.
-- @treturn ConfigItem The newly created MultiPickerConfigItem instance.
--
function MultiPickerConfigItem.new(key, initialValues, allValues, textFormat, description, onReload, imageItemForText)
    local self = setmetatable({}, MultiPickerConfigItem)

    self.key = key
    self.initialValues = initialValues
    self.allValues = allValues
    self.textFormat = textFormat or function(values)
        return localization_util.commas(values, 'or')
    end
    self.description = description or key
    self.dependencies = L{}
    self.onReload = onReload
    self.imageItemForText = imageItemForText

    return self
end

---
-- Gets the config key.
--
-- @treturn string The config key.
--
function MultiPickerConfigItem:getKey()
    return self.key
end

---
-- Gets the initial value.
--
-- @treturn number The initial value.
--
function MultiPickerConfigItem:getInitialValues()
    return self.initialValues
end

function MultiPickerConfigItem:getCurrentValues()
    return self.initialValues
end

---
-- Gets all possible values.
--
-- @treturn list All possible values.
--
function MultiPickerConfigItem:getAllValues()
    return self.allValues
end

---
-- Sets all possible values.
--
-- @tparam list allValues All possible values.
--
function MultiPickerConfigItem:setAllValues(allValues)
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
function MultiPickerConfigItem:getTextFormat()
    return self.textFormat
end

function MultiPickerConfigItem:getText()
    return self:getTextFormat()(self:getInitialValues())
end

---
-- Gets the description.
--
-- @treturn string The description.
--
function MultiPickerConfigItem:getDescription()
    return self.description
end

---
-- Adds a ConfigItem dependency.  When the value of this PickerConfigItem changes, dependency
-- ConfigItems will be reloaded.
--
-- @tparam ConfigItem ConfigItem dependency.
--
function MultiPickerConfigItem:addDependency(configItem)
    self.dependencies:append(configItem)
end

---
-- Gets the dependencies. When the value of this PickerConfigItem changes, dependency
-- ConfigItems will be reloaded.
--
-- @treturn list List of ConfigItem dependencies.
--
function MultiPickerConfigItem:getDependencies()
    return self.dependencies
end

function MultiPickerConfigItem:getMenuItem()
    local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
    local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
    local MenuItem = require('cylibs/ui/menu/menu_item')
    return MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, {}, function(_, _)
        local pickerView = FFXIPickerView.withItems(self:getCurrentValues(), self:getAllValues(), true, nil, self.imageItemForText, nil, true)
        pickerView:setShouldRequestFocus(true)
        return pickerView
    end)
end

function MultiPickerConfigItem:getImageItemForText()
    return self.imageItemForText
end

---
-- Sets the picker title
--
-- @tparam string pickerTitle Sets the picker title.
--
function MultiPickerConfigItem:setPickerTitle(pickerTitle)
    self.pickerTitle = pickerTitle
end

---
-- Returns the picker title.
--
-- @treturn string The picker title.
--
function MultiPickerConfigItem:getPickerTitle()
    return self.pickerTitle
end

---
-- Sets the picker title
--
-- @tparam string pickerTitle Sets the picker title.
--
function MultiPickerConfigItem:setPickerDescription(pickerDescription)
    self.pickerDescription = pickerDescription
end

---
-- Returns the picker description.
--
-- @treturn string The picker description.
--
function MultiPickerConfigItem:getPickerDescription()
    return self.pickerDescription
end

return MultiPickerConfigItem
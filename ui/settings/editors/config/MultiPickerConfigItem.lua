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
function MultiPickerConfigItem.new(key, initialValues, allValues, textFormat, description, onReload, imageItem, itemDescription)
    local self = setmetatable({}, MultiPickerConfigItem)

    self.key = key
    self.initialValues = initialValues
    self.allValues = allValues
    self.textFormat = textFormat or function(values)
        return localization_util.commas(values, 'or')
    end
    self.imageItem = imageItem or function(_)
        return nil
    end
    self.itemDescription = itemDescription or function(_)
        return nil
    end
    self.description = description or key
    self.dependencies = L{}
    self.onReload = onReload
    self.enabled = true

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
-- Gets the formatted text for a list of items.
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
-- Gets the image item factory.
--
-- @treturn function The image item factory.
--
function MultiPickerConfigItem:getImageItem()
    return self.imageItem
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
-- Gets the item description.
--
-- @treturn string The item description.
--
function MultiPickerConfigItem:getItemDescription(value)
    return self.itemDescription(value)
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
        local configItem = MultiPickerConfigItem.new("PickerItems", L{ self:getCurrentValues() }, self:getAllValues())
        configItem.imageItem = self:getImageItem()

        local pickerView = FFXIPickerView.withConfig(configItem, true)
        pickerView:setShouldRequestFocus(true)
        return pickerView
    end)
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

---
-- Sets the picker text format.
--
-- @tparam function pickerTextFormat Sets the picker text format.
--
function MultiPickerConfigItem:setPickerTextFormat(pickerTextFormat)
    self.pickerTextFormat = pickerTextFormat
end

---
-- Returns the picker text format.
--
-- @treturn function The picker text format.
--
function MultiPickerConfigItem:getPickerTextFormat()
    return self.pickerTextFormat or function(value)
        return tostring(value)
    end
end

function MultiPickerConfigItem:setAutoSave(autoSave)
    self.autoSave = autoSave
end

function MultiPickerConfigItem:getAutoSave()
    return self.autoSave
end

function MultiPickerConfigItem:isEnabled()
    return self.enabled
end

function MultiPickerConfigItem:setEnabled(enabled)
    self.enabled = enabled
end

return MultiPickerConfigItem
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')

local TextFieldItem = setmetatable({}, {__index = ButtonItem })
TextFieldItem.__index = TextFieldItem
TextFieldItem.__type = "TextFieldItem"

function TextFieldItem.new(textItem, defaultImageItem, highlightedImageItem, selectedImageItem, validator)
    local self = setmetatable(ButtonItem.new(textItem, defaultImageItem, highlightedImageItem, selectedImageItem), TextFieldItem)
    self.validator = validator or function(_)
        return true
    end
    return self
end

function TextFieldItem:destroy()
    self.validator = nil
end

function TextFieldItem:isValid(text)
    return self.validator(text)
end

return TextFieldItem

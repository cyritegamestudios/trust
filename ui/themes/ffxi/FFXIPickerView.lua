local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local PickerItem = require('cylibs/ui/picker/picker_item')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local PickerView = require('cylibs/ui/picker/picker_view')
local FFXIPickerView = setmetatable({}, {__index = PickerView })
FFXIPickerView.__index = FFXIPickerView

function FFXIPickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem)
    local style = CollectionView.defaultStyle()
    local viewSize = style:getDefaultPickerSize()

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height), true, style)

    local self = setmetatable(PickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem), FFXIPickerView)
    self:setBackgroundImageView(backgroundView)
    self:setSize(viewSize.width, viewSize.height)

    return self
end

function FFXIPickerView.withItems(texts, selectedTexts, allowsMultipleSelection, cursorImageItem, imageForText)
    imageForText = imageForText or function(_)
        return nil
    end
    local pickerItems = texts:map(function(text)
        local imageItem = imageForText(text)
        if imageItem then
            return PickerItem.new(ImageTextItem.new(imageItem, TextItem.new(text, TextStyle.PickerView.Text)), selectedTexts:contains(text))
        end
        return PickerItem.new(TextItem.new(text, TextStyle.PickerView.Text), selectedTexts:contains(text))
    end)
    return FFXIPickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem)
end

return FFXIPickerView
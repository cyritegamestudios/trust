local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local PickerItem = require('cylibs/ui/picker/picker_item')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local PickerView = require('cylibs/ui/picker/picker_view')
local FFXIPickerView = setmetatable({}, {__index = PickerView })
FFXIPickerView.__index = FFXIPickerView

function FFXIPickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem)
    local style = CollectionView.defaultStyle()
    local viewSize = style:getDefaultSize()

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height), true, style)

    local self = setmetatable(PickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem), FFXIPickerView)
    self:setBackgroundImageView(backgroundView)

    return self
end

function FFXIPickerView.withItems(texts, selectedTexts, allowsMultipleSelection, cursorImageItem)
    local pickerItems = texts:map(function(text)
        return PickerItem.new(TextItem.new(text, TextStyle.PickerView.Text), selectedTexts:contains(text))
    end)
    return FFXIPickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem)
end

return FFXIPickerView
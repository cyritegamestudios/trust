local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local TextInputView = require('cylibs/ui/views/input/text_input_view')
local FFXITextInputView = setmetatable({}, {__index = TextInputView })
FFXITextInputView.__index = FFXITextInputView

function FFXITextInputView.new(placeholderText, descriptionText)
    local style = CollectionView.defaultStyle()
    local viewSize = style:getDefaultTextInputSize()

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height), true, style)

    local self = setmetatable(TextInputView.new(placeholderText, backgroundView), FFXITextInputView)
    self:setBackgroundImageView(backgroundView)

    if descriptionText then
        local sectionHeaderItem = SectionHeaderItem.new(
            TextItem.new(descriptionText, TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
        )
        self:getDataSource():setItemForSectionHeader(1, sectionHeaderItem)
    end

    self:setSize(viewSize.width, viewSize.height)
    self:layoutIfNeeded()

    return self
end

function FFXITextInputView:setHasFocus(hasFocus)
    TextInputView.setHasFocus(self, hasFocus)

    if hasFocus then
        self:getDelegate():deselectAllItems()
    end
end

return FFXITextInputView
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local Padding = require('cylibs/ui/style/padding')
local PickerItem = require('cylibs/ui/picker/picker_item')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local PickerView = require('cylibs/ui/picker/picker_view')
local FFXIPickerView = setmetatable({}, {__index = PickerView })
FFXIPickerView.__index = FFXIPickerView

function FFXIPickerView.setDefaultMediaPlayer(mediaPlayer)
    defaultMediaPlayer = mediaPlayer
end

function FFXIPickerView.setDefaultSoundTheme(soundTheme)
    defaultSoundTheme = soundTheme
end

function FFXIPickerView.new(pickerItems, allowsMultipleSelection, cursorImageItem, viewSize, title, mediaPlayer, soundTheme)
    local style = CollectionView.defaultStyle()
    local viewSize = viewSize or style:getDefaultPickerSize()

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height), title == nil, style)
    if title then
        backgroundView:setTitle(title, { width = 20, height = 14 })
    end

    local self = setmetatable(PickerView.new(pickerItems, allowsMultipleSelection, mediaPlayer or defaultMediaPlayer, soundTheme or defaultSoundTheme), FFXIPickerView)

    self:setBackgroundImageView(backgroundView)
    self:setSize(viewSize.width, viewSize.height)
    self:setPadding(Padding.new(8, 0, 8, 0))

    backgroundView:setNeedsLayout()
    backgroundView:layoutIfNeeded()

    return self
end

function FFXIPickerView.withItems(texts, selectedTexts, allowsMultipleSelection, cursorImageItem, imageForText, viewSize, shouldTruncateText, title)
    imageForText = imageForText or function(_)
        return nil
    end
    local pickerItems = texts:map(function(text)
        local imageItem = imageForText(text)
        if imageItem then
            return PickerItem.new(ImageTextItem.new(imageItem, TextItem.new(text, TextStyle.Picker.Text)), selectedTexts:contains(text))
        end
        local textItem = TextItem.new(text, TextStyle.Picker.Text)
        textItem:setShouldTruncateText(shouldTruncateText)
        return PickerItem.new(textItem, selectedTexts:contains(text))
    end)
    return FFXIPickerView.new(L{ pickerItems }, allowsMultipleSelection, cursorImageItem, viewSize, title)
end

function FFXIPickerView.withSections(sections, selectedTexts, allowsMultipleSelection, cursorImageItem, imageForText)
    imageForText = imageForText or function(_)
        return nil
    end

    local itemsBySection = L{}
    local sectionIndex = 1
    for sectionTexts in sections:it() do
        local pickerItems = sectionTexts:map(function(text)
            local imageItem = imageForText(text, sectionIndex)
            if imageItem then
                return PickerItem.new(ImageTextItem.new(imageItem, TextItem.new(text, TextStyle.Picker.Text)), selectedTexts:contains(text))
            end
            return PickerItem.new(TextItem.new(text, TextStyle.Picker.Text), selectedTexts:contains(text))
        end)
        if sectionTexts:length() > 0 then
            itemsBySection:append(pickerItems)
            sectionIndex = sectionIndex + 1
        end
    end
    return FFXIPickerView.new(itemsBySection, allowsMultipleSelection, cursorImageItem)
end

function FFXIPickerView:shouldRequestFocus()
    return PickerView.shouldRequestFocus(self) and self:getDataSource():numberOfItemsInSection(1) > 0
end

return FFXIPickerView
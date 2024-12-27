local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local Padding = require('cylibs/ui/style/padding')

local PickerView = require('cylibs/ui/picker/picker_view')
local FFXIPickerView = setmetatable({}, {__index = PickerView })
FFXIPickerView.__index = FFXIPickerView

function FFXIPickerView.setDefaultMediaPlayer(mediaPlayer)
    defaultMediaPlayer = mediaPlayer
end

function FFXIPickerView.setDefaultSoundTheme(soundTheme)
    defaultSoundTheme = soundTheme
end

function FFXIPickerView.setDefaultInfoView(infoView)
    defaultInfoView = infoView
end

function FFXIPickerView.new(configItems, allowsMultipleSelection, viewSize, title, mediaPlayer, soundTheme)
    local style = CollectionView.defaultStyle()
    local viewSize = viewSize or style:getDefaultPickerSize()

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height), title == nil, style)
    if title then
        backgroundView:setTitle(title, { width = 20, height = 14 })
    end

    local self = setmetatable(PickerView.new(configItems, allowsMultipleSelection, mediaPlayer or defaultMediaPlayer, soundTheme or defaultSoundTheme), FFXIPickerView)

    self:setBackgroundImageView(backgroundView)
    self:setSize(viewSize.width, viewSize.height)
    self:setPadding(Padding.new(8, 0, 8, 0))

    backgroundView:setNeedsLayout()
    backgroundView:layoutIfNeeded()

    self:getDisposeBag():add(self:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
        local configItem = self.configItems[indexPath.section]
        if configItem and configItem.getItemDescription then
            local item = self:getDataSource():itemAtIndexPath(indexPath)
            if item then
                local description = configItem:getItemDescription(item:getText())
                if description then
                    defaultInfoView:setDescription(description)
                    return
                end
            end
        end
    end), self:getDelegate():didMoveCursorToItemAtIndexPath())

    return self
end

---
-- Creates a new FFXI classic themed picker view from config items.
--
-- @tparam list configItems List of config items (e.g. MultiPickerConfigItem).
-- @tparam boolean allowsMultipleSelection Indicates if multiple selection is allowed.
-- @tparam {width: number, height: number} viewSize (optional) View size.
-- @treturn FFXIPickerView A new FFXIPickerView.
--
function FFXIPickerView.withConfig(configItems, allowsMultipleSelection, viewSize)
    if class(configItems) ~= 'List' then
        configItems = L{ configItems }
    end
    return FFXIPickerView.new(configItems, allowsMultipleSelection, viewSize)
end

function FFXIPickerView.withItems(configItems, allowsMultipleSelection, viewSize, shouldTruncateText, title)
    return FFXIPickerView.new(configItems, allowsMultipleSelection, viewSize, title)
end

function FFXIPickerView:shouldRequestFocus()
    return PickerView.shouldRequestFocus(self) and self:getDataSource():numberOfItemsInSection(1) > 0
end

return FFXIPickerView
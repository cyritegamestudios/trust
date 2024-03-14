local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ScrollBar = require('cylibs/ui/scroll_view/scroll_bar')

local HorizontalScrollBar = setmetatable({}, {__index = ScrollBar })
HorizontalScrollBar.__index = HorizontalScrollBar


function HorizontalScrollBar.new(frame, scrollTrackItem, scrollUpItem, scrollDownItem)
    local self = setmetatable(ScrollBar.new(frame, scrollTrackItem), HorizontalScrollBar)

    local scrollTrack = ImageCollectionViewCell.new(scrollTrackItem)
    self:setBackgroundImageView(scrollTrack)

    scrollTrack:setVisible(false)

    self.scrollUpButton = ImageCollectionViewCell.new(scrollUpItem)
    self.scrollDownButton = ImageCollectionViewCell.new(scrollDownItem)

    self:addSubview(self.scrollUpButton)
    self:addSubview(self.scrollDownButton)

    self:setVisible(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():addAny(L{ scrollTrack, self.scrollUpButton, self.scrollDownButton })

    return self
end

function HorizontalScrollBar:layoutIfNeeded()
    if not ScrollBar.layoutIfNeeded(self) then
        return false
    end

    self.scrollUpButton:setPosition(0, -4)
    self.scrollUpButton:layoutIfNeeded()

    self.scrollDownButton:setPosition(0, self.frame.height - 8)
    self.scrollDownButton:layoutIfNeeded()
end

return HorizontalScrollBar
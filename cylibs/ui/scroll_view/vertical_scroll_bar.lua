local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ScrollBar = require('cylibs/ui/scroll_view/scroll_bar')

local VerticalScrollBar = setmetatable({}, {__index = ScrollBar })
VerticalScrollBar.__index = VerticalScrollBar


function VerticalScrollBar.new(frame, scrollTrackItem, scrollUpItem, scrollDownItem)
    local self = setmetatable(ScrollBar.new(frame, scrollTrackItem), VerticalScrollBar)

    --self:setBackgroundImageView(ImageCollectionViewCell.new(scrollTrackItem))

    self.scrollUpButton = ImageCollectionViewCell.new(scrollUpItem)
    self.scrollDownButton = ImageCollectionViewCell.new(scrollDownItem)

    self:addSubview(self.scrollUpButton)
    self:addSubview(self.scrollDownButton)

    self:setVisible(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():addAny(L{ self.scrollUpButton, self.scrollDownButton })

    return self
end

function VerticalScrollBar:layoutIfNeeded()
    if not ScrollBar.layoutIfNeeded(self) then
        --return false
    end

    --self.backgroundImageView:setVisible(self:isVisible())
    --self.backgroundImageView:layoutIfNeeded()

    self.scrollUpButton:setPosition(0, -4)
    self.scrollUpButton:setVisible(self:isVisible())
    self.scrollUpButton:layoutIfNeeded()

    self.scrollDownButton:setVisible(self:isVisible())
    self.scrollDownButton:setPosition(0, self.frame.height)
    self.scrollDownButton:layoutIfNeeded()
end

return VerticalScrollBar
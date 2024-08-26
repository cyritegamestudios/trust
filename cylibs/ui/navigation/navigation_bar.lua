local BackgroundView = require('cylibs/ui/views/background/background_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')
local MarqueeCollectionViewCell = require('cylibs/ui/collection_view/cells/marquee_collection_view_cell')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local NavigationBar = setmetatable({}, { __index = MarqueeCollectionViewCell })
NavigationBar.__index = NavigationBar


function NavigationBar.new(frame, hideBackground, textStyle)
    textStyle = textStyle or TextStyle.Default.NavigationTitle

    local self = setmetatable(MarqueeCollectionViewCell.new(TextItem.new('', textStyle), 0.65), NavigationBar)

    self:setItemSize(frame.height)
    self:setEstimatedSize(textStyle:getFontSize() * 1.75)
    self:setPosition(frame.x, frame.y)
    self:setSize(frame.width, frame.height)
    self:setUserInteractionEnabled(false)
    self:setIsSelectable(false)

    if not hideBackground then
        local backgroundView = FFXIBackgroundView.new(frame, true)
        backgroundView:setShouldRequestFocus(false)

        self:setBackgroundImageView(backgroundView)

        backgroundView:setNeedsLayout()
        backgroundView:layoutIfNeeded()
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function NavigationBar:destroy()
    MarqueeCollectionViewCell.destroy(self)
end

function NavigationBar:setTitle(title)
    self:setItem(TextItem.new(title, self:getItem():getStyle() or TextStyle.Default.NavigationTitle))

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

return NavigationBar

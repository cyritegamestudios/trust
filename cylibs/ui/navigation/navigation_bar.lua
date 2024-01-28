local BackgroundView = require('cylibs/ui/views/background/background_view')
local Frame = require('cylibs/ui/views/frame')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local NavigationBar = setmetatable({}, { __index = TextCollectionViewCell })
NavigationBar.__index = NavigationBar


function NavigationBar.new(frame, hideBackground, textStyle)
    textStyle = textStyle or TextStyle.Default.NavigationTitle

    local self = setmetatable(TextCollectionViewCell.new(TextItem.new('', textStyle)), NavigationBar)

    self:setItemSize(frame.height)
    self:setEstimatedSize(textStyle:getFontSize() * 2)
    self:setPosition(frame.x, frame.y)
    self:setSize(frame.width, frame.height)
    self:setUserInteractionEnabled(false)
    self:setIsSelectable(false)

    if not hideBackground then
        local backgroundView = BackgroundView.new(Frame.new(0, 0, frame.width, frame.height),
                windower.addon_path..'assets/backgrounds/menu_bg_top.png',
                windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
                windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')

        self:setBackgroundImageView(backgroundView)

        backgroundView:setNeedsLayout()
        backgroundView:layoutIfNeeded()
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function NavigationBar:destroy()
    TextCollectionViewCell.destroy(self)
end

function NavigationBar:setTitle(title)
    self:setItem(TextItem.new(title, self:getItem():getStyle() or TextStyle.Default.NavigationTitle))

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

return NavigationBar

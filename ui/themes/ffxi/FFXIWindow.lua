local BackgroundView = require('cylibs/ui/views/background/background_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local View = require('cylibs/ui/views/view')
local FFXIWindow = setmetatable({}, {__index = View })
FFXIWindow.__index = FFXIWindow

function FFXIWindow.new(contentView, viewSize)
    local self = setmetatable(View.new(Frame.new(0, 0, viewSize.width, viewSize.height)), FFXIWindow)

    self.contentView = contentView

    local backgroundView = BackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height),
            windower.addon_path..'assets/backgrounds/menu_bg_top.png',
            windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
            windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')

    self:setBackgroundImageView(backgroundView)

    self:addSubview(contentView)

    return self
end

function FFXIWindow:layoutIfNeeded()
    if not View.layoutIfNeeded(self) then
        return false
    end

    self.contentView:setSize(self.frame.width, self.frame.height)
    self.contentView:setVisible(self:isVisible())
    self.contentView:layoutIfNeeded()
end

return FFXIWindow
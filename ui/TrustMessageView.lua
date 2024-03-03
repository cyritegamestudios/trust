local BackgroundView = require('cylibs/ui/views/background/background_view')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Frame = require('cylibs/ui/views/frame')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local MessageView = require('cylibs/trust/ui/message_view')
local TrustMessageView = setmetatable({}, {__index = MessageView })
TrustMessageView.__index = TrustMessageView

function TrustMessageView.new(title, header, message, footer, viewSize)
    local self = setmetatable(MessageView.new(title, header, message, footer, viewSize, true), TrustMessageView)

    self:setNavigationBar(self:createTitleView(viewSize))
    self:setSize(viewSize.width, viewSize.height)
    self:layoutIfNeeded()

    return self
end

function TrustMessageView:destroy()
    MessageView.destroy(self)

    self.onDismiss = nil

    if self.events then
        for _,event in pairs(self.events) do
            windower.unregister_event(event)
        end
    end
end

function TrustMessageView:createTitleView(viewSize)
    local titleView = NavigationBar.new(Frame.new(0, 0, viewSize.width, 35))
    return titleView
end

function TrustMessageView:setMessage(text)
    local indexPath = IndexPath.new(1, 2)
    local messageTextItem = self:getDataSource():itemAtIndexPath(indexPath)
    if messageTextItem then
        messageTextItem:setText(text)
        self:getDataSource():updateItem(messageTextItem, indexPath)
    end
end

function TrustMessageView:setDismissCallback(onDismiss)
    if self.onDismiss == nil then
        self.events = {}
        self.events.keyboard = windower.register_event('keyboard', function(key, pressed, flags, blocked)
            if L{ 1, 28 }:contains(key) and pressed and not self.isDismissed then
                self.isDismissed = true
                self.onDismiss()
            end
        end)
    end
    self.onDismiss = onDismiss
end

return TrustMessageView
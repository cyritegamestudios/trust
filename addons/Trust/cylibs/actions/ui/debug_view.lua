local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local DebugView = setmetatable({}, {__index = CollectionView })
DebugView.__index = DebugView

TextStyle.DebugView = {
    Text = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            11,
            Color.white,
            Color.green,
            2,
            0,
            0,
            false
    ),
}

function DebugView.new(actionQueue)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), DebugView)

    self.action_queue = action_queue

    self:updateActions()

    self:getDisposeBag():add(actionQueue:on_action_queued():addAction(function(_)
        self:updateActions()
    end), actionQueue:on_action_queued())
    self:getDisposeBag():add(actionQueue:on_action_start():addAction(function(_)
        self:updateActions()
    end), actionQueue:on_action_start())
    self:getDisposeBag():add(actionQueue:on_action_end():addAction(function(_)
        self:updateActions()
    end), actionQueue:on_action_end())

    return self
end

function DebugView:updateActions()
    if not self:isVisible() then
        return
    end

    self:getDataSource():removeAllItems()

    self:getDataSource():addItem(TextItem.new("Actions", TextStyle.Default.Text), IndexPath.new(1, 1))

    local actions = self.action_queue:get_actions()
    if actions:length() > 0 then
        local rowIndex = 2
        for action in actions:it() do
            if action:tostring():len() > 0 then
                local indexPath = IndexPath.new(1, rowIndex)
                local item = TextItem.new('• '..action:tostring(), TextStyle.DebugView.Text)
                self:getDataSource():addItem(item, indexPath)
                if action:is_equal(actions[1]) then
                    self:getDelegate():highlightItemAtIndexPath(item, indexPath)
                end
                rowIndex = rowIndex + 1
            end
        end
    else
        self:getDataSource():addItem(TextItem.new("• Idle", TextStyle.Default.Text), IndexPath.new(1, 2))
    end
end

return DebugView
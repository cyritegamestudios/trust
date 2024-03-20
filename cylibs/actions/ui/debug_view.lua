local Button = require('cylibs/ui/button')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local DebugView = setmetatable({}, {__index = FFXIWindow })
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
            Color.clear,
            false
    ),
}

function DebugView.new(actionQueue)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), DebugView)

    self.actionQueue = actionQueue

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

    local itemsToAdd = L{}
    local itemsToHighlight = L{}

    -- Memory
    itemsToAdd:append(IndexedItem.new(TextItem.new("Memory", TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))

    itemsToAdd:append(IndexedItem.new(TextItem.new("Actions created: "..actions_created, TextStyle.Default.TextSmall), IndexPath.new(1, 2)))
    itemsToAdd:append(IndexedItem.new(TextItem.new("Actions destroyed: "..actions_destroyed, TextStyle.Default.TextSmall), IndexPath.new(1, 3)))

    local rowIndex = 4
    for action_type, count in pairs(actions_counter) do
        itemsToAdd:append(IndexedItem.new(TextItem.new(action_type..': '..count, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end
    itemsToAdd:append(IndexedItem.new(TextItem.new('Views created: '..num_created, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
    itemsToAdd:append(IndexedItem.new(TextItem.new('Monsters created: '..num_monsters, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex + 1)))

    -- Actions
    itemsToAdd:append(IndexedItem.new(TextItem.new("Actions", TextStyle.Default.HeaderSmall), IndexPath.new(2, 1)))

    local actions = self.actionQueue:get_actions()
    if actions:length() > 0 then
        local rowIndex = 2
        for action in actions:it() do
            if action:tostring():len() > 0 then
                local indexPath = IndexPath.new(2, rowIndex)
                local item = TextItem.new('• '..action:tostring(), TextStyle.DebugView.Text)
                itemsToAdd:append(IndexedItem.new(item, indexPath))
                if action:is_equal(actions[1]) then
                    itemsToHighlight:append(indexPath)
                end
                rowIndex = rowIndex + 1
            end
        end
    else
        itemsToAdd:append(IndexedItem.new(TextItem.new("• Idle", TextStyle.DebugView.Text), IndexPath.new(2, 2)))
        self:getDelegate():deHighlightAllItems()
    end

    self:getDataSource():addItems(itemsToAdd)

    for indexPath in itemsToHighlight:it() do
        self:getDelegate():highlightItemAtIndexPath(indexPath)
    end
end

function DebugView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("View current and queued actions.")
end

function DebugView:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Clear' then
        if self.actionQueue:length() > 0 then
            self.actionQueue:clear()
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Okay, I'll reconsider what I was going to do.")
        elseif self.actionQueue.current_action ~= nil then
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."I'm in the middle of something!")
        else
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."I'm not doing anything...")
        end
    end
end

return DebugView
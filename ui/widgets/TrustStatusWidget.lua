local ButtonCollectionViewCell = require('cylibs/ui/collection_view/cells/button_collection_view_cell')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local Frame = require('cylibs/ui/views/frame')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MarqueeCollectionViewCell = require('cylibs/ui/collection_view/cells/marquee_collection_view_cell')
local Mouse = require('cylibs/ui/input/mouse')
local Padding = require('cylibs/ui/style/padding')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local TrustStatusWidget = setmetatable({}, {__index = CollectionView })
TrustStatusWidget.__index = TrustStatusWidget

TrustStatusWidget.Buttons = {}
TrustStatusWidget.Buttons.On = ImageItem.new(
        windower.addon_path..'assets/buttons/toggle_button_on.png',
        17,
        14
)
TrustStatusWidget.Buttons.Off = ImageItem.new(
        windower.addon_path..'assets/buttons/toggle_button_off.png',
        23,
        14
)

TrustStatusWidget.TextSmall = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        9,
        Color.white,
        Color.lightGrey,
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        true
)
TrustStatusWidget.TextSmall2 = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        9,
        Color.new(255, 77, 186, 255),
        Color.lightGrey,
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        true
)
TrustStatusWidget.Subheadline = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        8,
        Color.white,
        Color.yellow,
        0,
        0.5,
        Color.black,
        true,
        Color.red
)

function TrustStatusWidget.new(frame, addonSettings, addonEnabled, actionQueue, mainJobName, subJobName)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if indexPath.section == 1 then
            if item.__type == TextItem.__type then
                local cell = TextCollectionViewCell.new(item)
                cell:setItemSize(14)
                cell:setUserInteractionEnabled(false)
                return cell
            else
                local cell = ButtonCollectionViewCell.new(item)
                cell:setItemSize(14)
                cell:setUserInteractionEnabled(true)
                return cell
            end
        else
            local cell = MarqueeCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(false)
            return cell
        end
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 4)), TrustStatusWidget)

    self.addonSettings = addonSettings
    self.mainJobName = mainJobName
    self.subJobName = subJobName

    self:setVisible(false)
    self:setScrollEnabled(false)
    self:setUserInteractionEnabled(true)

    local backgroundView = FFXIBackgroundView.new(frame)
    self:setBackgroundImageView(backgroundView)

    self:setJobs(mainJobName, subJobName)

    self:getDataSource():addItem(TextItem.new('', TrustStatusWidget.Subheadline), IndexPath.new(2, 1))

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():add(actionQueue:on_action_start():addAction(function(_, s)
        self:setAction(s:tostring() or '')
    end), actionQueue:on_action_start())

    self:getDisposeBag():add(actionQueue:on_action_end():addAction(function(_, s)
        self:setAction('')
    end), actionQueue:on_action_end())

    self:getDisposeBag():add(Mouse.input():onMouseEvent():addAction(function(type, x, y, delta, blocked)
        if type == Mouse.Event.Click then
            if self:hitTest(x, y) then
                local startPosition = self:getAbsolutePosition()
                self.dragging = { x = startPosition.x, y = startPosition.y, dragX = x, dragY = y }
                Mouse.input().blockEvent = true
            end
        elseif type == Mouse.Event.Move then
            if self.dragging then
                Mouse.input().blockEvent = true

                local newX = self.dragging.x + (x - self.dragging.dragX)
                local newY = self.dragging.y + (y - self.dragging.dragY)

                self:setPosition(newX, newY)
                self:layoutIfNeeded()
            end
            return true
        elseif type == Mouse.Event.ClickRelease then
            if self.dragging then
                self.dragging = nil
                Mouse.input().blockEvent = true
                coroutine.schedule(function()
                    Mouse.input().blockEvent = false
                end, 0.1)
            end
        else
            self.dragging = nil
            Mouse.input().blockEvent = false
        end
        return false
    end), Mouse.input():onMouseEvent())

    --[[self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        addonEnabled:setValue(true)
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self:getDelegate():didDeselectItemAtIndexPath():addAction(function(indexPath)
        addonEnabled:setValue(false)
    end), self:getDelegate():didDeselectItemAtIndexPath())]]

    self:getDisposeBag():add(addonEnabled:onValueChanged():addAction(function(_, isEnabled)
        if isEnabled then
            self:setAction('')
        else
            self:setAction('OFF')
        end
    end), addonEnabled:onValueChanged())

    if not addonEnabled:getValue() then
        self:setAction('OFF')
    end

    return self
end

function TrustStatusWidget:setTitle(title)
    self.backgroundImageView:setTitle(title)
    self.backgroundImageView:layoutIfNeeded()
end

function TrustStatusWidget:setJobs(mainJobName, subJobName)
    local rowIndex = 0

    local itemsToUpdate = L{
        TextItem.new("Lv"..windower.ffxi.get_player().main_job_level.." "..mainJobName, TrustStatusWidget.TextSmall2),
        TextItem.new("Lv"..windower.ffxi.get_player().sub_job_level.." "..subJobName, TrustStatusWidget.TextSmall)
    }:map(function(item)
        rowIndex = rowIndex + 1
        return IndexedItem.new(item, IndexPath.new(1, rowIndex))
    end)

    self:getDataSource():updateItems(itemsToUpdate)
end

function TrustStatusWidget:setAction(text)
    if text == nil or text:empty() then
        text = 'Idle'
    end

    local actionItem = TextItem.new(text, TrustStatusWidget.Subheadline), IndexPath.new(2, 1)

    self:getDataSource():updateItem(actionItem, IndexPath.new(2, 1))

    self:layoutIfNeeded()
end

function TrustStatusWidget:setVisible(visible)
    visible = visible and settings.hud.visible
    CollectionView.setVisible(self, visible)
end

---
-- Sets the position of the view.
--
-- @tparam number x The x-coordinate to set.
-- @tparam number y The y-coordinate to set.
--
function TrustStatusWidget:setPosition(x, y)
    if self.frame.x == x and self.frame.y == y then
        return
    end
    CollectionView.setPosition(self, x, y)

    self.addonSettings:getSettings().hud.position.x = x
    self.addonSettings:getSettings().hud.position.y = y
    self.addonSettings:saveSettings(true)
end


return TrustStatusWidget
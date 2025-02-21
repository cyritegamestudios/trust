local AutomatonSettingsMenuItem = require('ui/settings/menus/attachments/AutomatonSettingsMenuItem')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local PathWidget = setmetatable({}, {__index = Widget })
PathWidget.__index = PathWidget


PathWidget.TextSmall = TextStyle.new(
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
PathWidget.TextSmall3 = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        8,
        Color.white,
        Color.lightGrey,
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        false
)
PathWidget.Subheadline = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        8,
        Color.white,
        Color.lightGrey,
        0,
        0.5,
        Color.black,
        true,
        Color.red
)

PathWidget.hasMp = true

function PathWidget.new(frame, player, trust)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(14)
        cell:setUserInteractionEnabled(indexPath.row == 2)
        return cell
    end)

    local self = setmetatable(Widget.new(frame, "Path", dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 10, true), PathWidget)

    self.id = player:get_id()
    self.pather = trust:role_with_type("pather")

    self:getDataSource():addItem(TextItem.new("Recording", PathWidget.TextSmall), IndexPath.new(1, 1))
    self:getDataSource():addItem(TextItem.new("Stop", PathWidget.Subheadline), IndexPath.new(1, 2))

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)

        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if not item then
            return
        end

        local modeItem = self:getDataSource():itemAtIndexPath(IndexPath.new(1, 1))
        if modeItem then
            if modeItem:getText():contains("Recording") then
                if item:getText() == "Stop" then
                    self.pather:get_path_recorder():stop_recording()
                end
            elseif modeItem:getText():contains("Replaying") then
                if item:getText() == "Stop" then
                    self.pather:stop()
                end
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self.pather:get_path_recorder():on_path_record_start():addAction(function(r)
        windower.trust.ui.get_hud():closeAllMenus()

        self:setStatus("Recording...")

        self:setVisible(true)
        self:layoutIfNeeded()
    end), self.pather:get_path_recorder():on_path_record_start())

    self:getDisposeBag():add(self.pather:get_path_recorder():on_path_record_stop():addAction(function(r)
        self:setVisible(false)
        self:layoutIfNeeded()
    end), self.pather:get_path_recorder():on_path_record_stop())

    self:getDisposeBag():add(self.pather:on_path_replay_start():addAction(function(p, path)
        windower.trust.ui.get_hud():closeAllMenus()

        self:setStatus("Replaying...")

        self:setVisible(true)
        self:layoutIfNeeded()
    end), self.pather:on_path_replay_start())

    self:getDisposeBag():add(self.pather:on_path_replay_stop():addAction(function(r)
        self:setVisible(false)
        self:layoutIfNeeded()
    end), self.pather:on_path_replay_stop())

    self:setVisible(false)
    self:setShouldRequestFocus(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function PathWidget:destroy()
    Widget.destroy(self)
end

function PathWidget:getSettings(addonSettings)
    return addonSettings:getSettings().path_widget
end

function PathWidget:setVisible(visible)
    if not (self.pather:get_path_recorder():is_recording() or self.pather:is_enabled()) then
        visible = false
    end

    --if visible then
    --    self:getDataSource():updateItem(TextItem.new(pup_util.get_pet_mode(), AutomatonStatusWidget.TextSmall3), IndexPath.new(1, 4))
    --end

    Widget.setVisible(self, visible)
end

function PathWidget:setStatus(status)
    self:getDataSource():updateItem(TextItem.new(status, PathWidget.TextSmall), IndexPath.new(1, 1))
end

function PathWidget:setAction(action)
    self:getDataSource():updateItem(TextItem.new(action, PathWidget.Subheadline), IndexPath.new(1, 2))
end

return PathWidget
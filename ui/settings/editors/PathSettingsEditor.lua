local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local PathSettingsEditor = setmetatable({}, {__index = FFXIWindow })
PathSettingsEditor.__index = PathSettingsEditor

-- Event called when a path is selected.
function PathSettingsEditor:onSelectPath()
    return self.spell_finish_no_effect
end

function PathSettingsEditor.new(pathsDir)
    local dataSource = CollectionViewDataSource.new(function(item, _)
        local cell = TextCollectionViewCell.new(item)
        cell:setClipsToBounds(true)
        cell:setItemSize(16)
        return cell
    end)

    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(0, FFXIClassicStyle.Padding.CollectionView.Default), nil, false, FFXIClassicStyle.WindowSize.Editor.Default), PathSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)

    self.pathsDir = pathsDir

    self:reloadSettings()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function PathSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function PathSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function PathSettingsEditor:listFiles()
    local directoryPath = windower.addon_path..self.pathsDir

    local command = "dir \"" .. directoryPath .. "\" /b"

    local handle = io.popen(command)
    if handle then
        local result = handle:read("*a")
        handle:close()

        local fileNames = L{}
        for fileName in result:gmatch("[^\r\n]+") do
            fileNames:append(fileName)
        end
        return fileNames
    else
        logger.error("Unable to load paths.")
    end
    return L{}
end

function PathSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local fileNames = self:listFiles()

    local items = L{}

    local rowIndex = 1
    for fileName in fileNames:it() do
        items:append(IndexedItem.new(TextItem.new(fileName, TextStyle.Default.TextSmall), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end
end

function PathSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Delete' then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local item = self:getDataSource():itemAtIndexPath(cursorIndexPath)
            if item then
                self:getDataSource():removeItem(cursorIndexPath)
            end
        end
    end
end

return PathSettingsEditor
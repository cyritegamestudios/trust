local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local HelpView = setmetatable({}, {__index = FFXIWindow })
HelpView.__index = HelpView

function HelpView.new(main_job_name_short, helpUrl)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

<<<<<<< HEAD
    local self = setmetatable(FFXIWindow.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), HelpView)
=======
    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), HelpView)
>>>>>>> main

    self.helpUrl = helpUrl
    self:setScrollDelta(20)

    local itemsToAdd = L{}

    itemsToAdd:append(IndexedItem.new(TextItem.new("Wiki", TextStyle.Default.HeaderSmall), IndexPath.new(1, 1)))
    itemsToAdd:append(IndexedItem.new(TextItem.new("• "..main_job_name_short, TextStyle.Default.TextSmall), IndexPath.new(1, 2)))
    itemsToAdd:append(IndexedItem.new(TextItem.new("• Commands", TextStyle.Default.TextSmall), IndexPath.new(1, 3)))
    itemsToAdd:append(IndexedItem.new(TextItem.new("• Shortcuts", TextStyle.Default.TextSmall), IndexPath.new(1, 4)))
    itemsToAdd:append(IndexedItem.new(TextItem.new("", TextStyle.Default.Text), IndexPath.new(1, 5)))
    itemsToAdd:append(IndexedItem.new(TextItem.new("Discord", TextStyle.Default.HeaderSmall), IndexPath.new(2, 1)))
    itemsToAdd:append(IndexedItem.new(TextItem.new("• Join the Discord", TextStyle.Default.TextSmall), IndexPath.new(2, 2)))

    dataSource:addItems(itemsToAdd)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local row = indexPath.row
        if indexPath.section == 1 then
            if row == 2 then
                local urlSuffix = self:getJobWikiPageSuffix(main_job_name_short)
                self:openUrl(urlSuffix)
            elseif row == 3 then
                self:openUrl('Commands')
            elseif row == 4 then
                self:openUrl('Shortcuts')
            end
        elseif indexPath.section == 2 then
            if row == 2 then
                self:openUrl('#support')
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 2))

    return self
end

function HelpView:openUrl(url_suffix)
    windower.open_url(self.helpUrl..'/'..url_suffix)
end

function HelpView:getJobWikiPageSuffix(job_name_short)
    local job = res.jobs:with('ens', job_name_short)
    if job then
        local url_suffix = job.en:gsub(" ", "-")
        return url_suffix
    end
    return 'Trusts'
end

function HelpView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("Learn more about how to use Trust.")
end

return HelpView
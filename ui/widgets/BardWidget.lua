local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local SongSetsMenuItem = require('ui/settings/menus/songs/SongSetsMenuItem')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local BardWidget = setmetatable({}, {__index = Widget })
BardWidget.__index = BardWidget


BardWidget.TextSmall3 = TextStyle.new(
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
BardWidget.TextSmall4 = TextStyle.new(
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
        true
)

function BardWidget.new(frame, trust, trustHud, trustSettings, trustSettingsMode, trustModeSettings)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == ImageTextItem.__type then
            local cell = ImageTextCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(indexPath.row == 1)
            cell:setIsSelectable(true)
            cell:setItemSize(16)
            return cell
        elseif item.__type == TextItem.__type then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(16)
            cell:setUserInteractionEnabled(true)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Bard", dataSource, VerticalFlowLayout.new(2, Padding.new(6, 4, 0, 0), 3), 12, true, 'job'), BardWidget)

    self.trust = trust
    self.timer = Timer.scheduledTimer(1)
    self.timer:onTimeChange():addAction(function()
        self:updateTimer()
    end)

    self:getDisposeBag():addAny(L{ self.timer })

    local singer = trust:role_with_type("singer")

    self:setSongSet(state.SongSet.value, singer:get_is_singing())

    local text_item = TextItem.new(string.format("00:01:25"), BardWidget.TextSmall4)
    local image_item = ImageTextItem.new(ImageItem.new(windower.addon_path..'assets/icons/icon_timer.png', 14, 14), text_item, 2, { x = 0, y = 0 })

    self:getDataSource():updateItem(image_item, IndexPath.new(1, 2))

    self:getDisposeBag():add(state.SongSet:on_state_change():addAction(function(_, new_value, _)
        self:setSongSet(new_value, singer:get_is_singing())
    end), state.SongSet:on_state_change())

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)
        coroutine.schedule(function()
            self:resignFocus()
            trustHud:openMenu(SongSetsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, trust))
        end, 0.2)
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(singer:on_songs_begin():addAction(function(_, _)
        self:setSongSet(state.SongSet.value, true)
    end, singer:on_songs_begin()))

    self:getDisposeBag():add(singer:on_songs_end():addAction(function(_, _)
        self:setSongSet(state.SongSet.value, false)
    end, singer:on_songs_end()))

    self:updateTimer()

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self.timestamp = os.time() + 120

    self.timer:start()

    return self
end

function BardWidget:getSinger()
    return self.trust:role_with_type("singer")
end

function BardWidget:setSongSet(_, isSinging)
    local text_item = TextItem.new(string.format(state.SongSet.value), BardWidget.TextSmall3)
    text_item:setOffset(0, 2)

    local image_item = ImageTextItem.new(ImageItem.new(windower.addon_path..'assets/icons/icon_singing_light.png', 14, 14), text_item, 2, { x = 0, y = 1 })

    if isSinging then
        image_item:getImageItem():setAlpha(255)
    else
        image_item:getImageItem():setAlpha(100)
    end

    self:getDataSource():updateItem(image_item, IndexPath.new(1, 1))
end

function BardWidget:updateTimer()
    local songs = player.party:get_player():get_songs():sort(function(song_record_1, song_record_2)
        return song_record_1:get_expire_time() < song_record_2:get_expire_time()
    end)
    local timestamp = os.time()
    if songs:length() > 0 then
        timestamp = songs[1]:get_expire_time() - self:getSinger().song_tracker.expiring_duration
    end
   
    local textItem = TextItem.new(string.format(localization_util.time_format(timestamp)), BardWidget.TextSmall4)

    local imageItem = ImageTextItem.new(ImageItem.new(windower.addon_path..'assets/icons/icon_timer.png', 14, 14), textItem, 2, { x = 0, y = 0 })
    self:getDataSource():updateItem(imageItem, IndexPath.new(1, 2))
end


return BardWidget
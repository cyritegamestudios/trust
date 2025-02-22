local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local ImageTextCollectionViewCell = require('cylibs/ui/collection_view/cells/image_text_collection_view_cell')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
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

function BardWidget.new(frame, trust)
    local dataSource = CollectionViewDataSource.new(function(item, _)
        if item.__type == ImageTextItem.__type then
            local cell = ImageTextCollectionViewCell.new(item)
            cell:setUserInteractionEnabled(false)
            cell:setIsSelectable(false)
            cell:setItemSize(16)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Bard", dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 12, true, 'job'), BardWidget)

    self.trust = trust

    self:getDisposeBag():addAny(L{ self.strategemTimer })

    local singer = trust:role_with_type("singer")

    self:getDisposeBag():add(singer:on_songs_begin():addAction(function(_, _)
        self:setIsSinging(true)
    end, singer:on_songs_begin()))

    self:getDisposeBag():add(singer:on_songs_end():addAction(function(_, _)
        self:setIsSinging(false)
    end, singer:on_songs_end()))

    self:setIsSinging(singer:get_is_singing())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function BardWidget:setIsSinging(isSinging)
    if isSinging then
        self:setVisible(true)

        local text_item = TextItem.new(string.format("Singing..."), BardWidget.TextSmall3)
        text_item:setOffset(0, 2)
        local image_item = ImageTextItem.new(ImageItem.new(windower.addon_path..'assets/icons/icon_singing_light.png', 14, 14), text_item)
        self:getDataSource():updateItem(image_item, IndexPath.new(1, 1))
    else
        self:setVisible(false)
    end
    self:layoutIfNeeded()
end

return BardWidget
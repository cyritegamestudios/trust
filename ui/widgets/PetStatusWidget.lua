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
local Keyboard = require('cylibs/ui/input/keyboard')
local MarqueeCollectionViewCell = require('cylibs/ui/collection_view/cells/marquee_collection_view_cell')
local Mouse = require('cylibs/ui/input/mouse')
local Padding = require('cylibs/ui/style/padding')
local ResizableImageItem = require('cylibs/ui/collection_view/items/resizable_image_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local PetStatusWidget = setmetatable({}, {__index = Widget })
PetStatusWidget.__index = PetStatusWidget

PetStatusWidget.Buttons = {}
PetStatusWidget.Buttons.On = ImageItem.new(
        windower.addon_path..'assets/buttons/toggle_button_on.png',
        windower.addon_path..'assets/buttons/toggle_button_on.png',
        17,
        14
)
PetStatusWidget.Buttons.Off = ImageItem.new(
        windower.addon_path..'assets/buttons/toggle_button_off.png',
        23,
        14
)

PetStatusWidget.TextSmall = TextStyle.new(
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
PetStatusWidget.TextSmall2 = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        9,
        Color.new(255, 77, 186, 255),
        Color.new(255, 65, 155, 200),
        0,
        0,
        Color.clear,
        false,
        Color.yellow,
        true
)
PetStatusWidget.TextSmall3 = TextStyle.new(
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
PetStatusWidget.Subheadline = TextStyle.new(
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

function PetStatusWidget.new(frame, player)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if indexPath.section == 1 then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(14)
            cell:setUserInteractionEnabled(true)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Pet", dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 20), PetStatusWidget)

    self.addonSettings = addonSettings
    self.id = player:get_id()

    self:getDataSource():addItem(TextItem.new(state.TrustMode.value, PetStatusWidget.TextSmall3), IndexPath.new(1, 1))
    self:getDataSource():addItem(TextItem.new(state.TrustMode.value, PetStatusWidget.TextSmall3), IndexPath.new(1, 2))
    self:getDataSource():addItem(TextItem.new(state.TrustMode.value, PetStatusWidget.TextSmall3), IndexPath.new(1, 3))

    self:getDisposeBag():add(WindowerEvents.PetUpdate:addAction(function(owner_id, pet_id, pet_index, pet_name, pet_hpp, pet_mpp, pet_tp)
        if owner_id == self.id then
            if pet_id and windower.ffxi.get_mob_by_id(pet_id) then
                self:setVitals(pet_hpp, pet_mpp, pet_tp)
                self:setVisible(true)
            else
                self:setVisible(false)
            end
            self:layoutIfNeeded()
        end
    end), WindowerEvents.PetUpdate)

    local pet = windower.ffxi.get_mob_by_target('pet')
    if pet then
        self:setVitals(pet.hpp or 100, pet.mpp or 0, pet.tp or 0)
        self:setVisible(true)
    else
        self:setVisible(false)
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function PetStatusWidget:destroy()
    Widget.destroy(self)
end

function PetStatusWidget:setVisible(visible)
    if windower.ffxi.get_mob_by_target('pet') == nil then
        visible = false
    end
    Widget.setVisible(self, visible)
end

-- For hp and mp see: https://github.com/Windower/Lua/blob/2ddbf1e9110a1da3d95130b71464aec35f5cd719/addons/PetTP/PetTP.lua#L229
function PetStatusWidget:setVitals(hpp, mpp, tp)
    local itemsToUpdate = L{}

    if hpp then
        itemsToUpdate:append(IndexedItem.new(TextItem.new("HP "..hpp.."%", PetStatusWidget.TextSmall3), IndexPath.new(1, 1)))
    end
    if mpp then
        itemsToUpdate:append(IndexedItem.new(TextItem.new("MP "..mpp.."%", PetStatusWidget.TextSmall3), IndexPath.new(1, 2)))
    end
    if tp then
        itemsToUpdate:append(IndexedItem.new(TextItem.new("TP "..tp, PetStatusWidget.TextSmall3), IndexPath.new(1, 3)))
    end

    self:getDataSource():updateItems(itemsToUpdate)
end

return PetStatusWidget
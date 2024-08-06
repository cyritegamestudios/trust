local AutomatonSettingsMenuItem = require('ui/settings/menus/attachments/AutomatonSettingsMenuItem')
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

local AutomatonStatusWidget = setmetatable({}, {__index = Widget })
AutomatonStatusWidget.__index = AutomatonStatusWidget

AutomatonStatusWidget.Buttons = {}
AutomatonStatusWidget.Buttons.On = ImageItem.new(
        windower.addon_path..'assets/buttons/toggle_button_on.png',
        windower.addon_path..'assets/buttons/toggle_button_on.png',
        17,
        14
)
AutomatonStatusWidget.Buttons.Off = ImageItem.new(
        windower.addon_path..'assets/buttons/toggle_button_off.png',
        23,
        14
)

AutomatonStatusWidget.TextSmall = TextStyle.new(
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
AutomatonStatusWidget.TextSmall2 = TextStyle.new(
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
AutomatonStatusWidget.TextSmall3 = TextStyle.new(
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
AutomatonStatusWidget.Subheadline = TextStyle.new(
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

function AutomatonStatusWidget.new(frame, addonSettings, player, trustHud, trustSettings, trustSettingsMode)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if indexPath.section == 1 then
            local cell = TextCollectionViewCell.new(item)
            cell:setItemSize(13)
            cell:setUserInteractionEnabled(indexPath.row == 4)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Pet", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 10, true), AutomatonStatusWidget)

    self.addonSettings = addonSettings
    self.id = player:get_id()

    self:getDataSource():addItem(TextItem.new("HP", AutomatonStatusWidget.TextSmall), IndexPath.new(1, 1))
    self:getDataSource():addItem(TextItem.new("MP", AutomatonStatusWidget.TextSmall), IndexPath.new(1, 2))
    self:getDataSource():addItem(TextItem.new("TP", AutomatonStatusWidget.TextSmall), IndexPath.new(1, 3))
    self:getDataSource():addItem(TextItem.new(pup_util.get_pet_mode(), AutomatonStatusWidget.TextSmall3), IndexPath.new(1, 4))

    self:getDisposeBag():add(WindowerEvents.PetUpdate:addAction(function(owner_id, pet_id, pet_index, pet_name, pet_hpp, pet_mpp, pet_tp)
        if owner_id == self.id then
            if pet_id and windower.ffxi.get_mob_by_id(pet_id) then
                if pet_tp then
                    self:setTp(pet_tp)
                    self:setVisible(true)
                end
            else
                self:setVisible(false)
            end
            self:layoutIfNeeded()
        end
    end), WindowerEvents.PetUpdate)

    self:getDisposeBag():add(WindowerEvents.AutomatonUpdate:addAction(function(pet_id, pet_name, current_hp, max_hp, current_mp, max_mp)
        if pet_id and windower.ffxi.get_mob_by_id(pet_id) then
            self.isInitialized = true

            self:setHp(current_hp, max_hp)
            self:setMp(current_mp, max_mp)
            self:setVisible(true)
        else
            self:setVisible(false)
        end
        self:layoutIfNeeded()
    end), WindowerEvents.AutomatonUpdate)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)

        trustHud:openMenu(AutomatonSettingsMenuItem.new(trustSettings, trustSettingsMode))
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:setTp(0)

    self:setVisible(false)
    self:setShouldRequestFocus(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function AutomatonStatusWidget:destroy()
    Widget.destroy(self)
end

function AutomatonStatusWidget:getSettings(addonSettings)
    return addonSettings:getSettings().pet_widget
end

function AutomatonStatusWidget:setVisible(visible)
    if windower.ffxi.get_mob_by_target('pet') == nil or not self.isInitialized then
        visible = false
    end
    Widget.setVisible(self, visible)
end

function AutomatonStatusWidget:setHp(hp, maxHp)
    self:getDataSource():updateItem(TextItem.new("HP  "..hp.."/"..maxHp, AutomatonStatusWidget.TextSmall), IndexPath.new(1, 1))
end

function AutomatonStatusWidget:setMp(mp, maxMp)
    self:getDataSource():updateItem(TextItem.new("MP  "..mp.."/"..maxMp, AutomatonStatusWidget.TextSmall), IndexPath.new(1, 2))
end

function AutomatonStatusWidget:setTp(tp)
    self:getDataSource():updateItem(TextItem.new("TP  "..tp, AutomatonStatusWidget.TextSmall), IndexPath.new(1, 3))
end

return AutomatonStatusWidget
local Avatar = require('cylibs/entity/avatar')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local AvatarStatusWidget = setmetatable({}, {__index = Widget })
AvatarStatusWidget.__index = AvatarStatusWidget


AvatarStatusWidget.TextSmall = TextStyle.new(
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
AvatarStatusWidget.TextSmall3 = TextStyle.new(
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
AvatarStatusWidget.Subheadline = TextStyle.new(
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

function AvatarStatusWidget.new(frame, player, trustHud, trustSettings, trustSettingsMode)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if indexPath.section == 1 then
            local cell = TextCollectionViewCell.new(item)
            local itemSize = 13
            cell:setItemSize(itemSize)
            cell:setUserInteractionEnabled(indexPath.row == 3)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Pet", dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 10, true), AvatarStatusWidget)

    self.id = player:get_id()
    self.actionDisposeBag = DisposeBag.new()

    self:getDataSource():addItem(TextItem.new("HP", AvatarStatusWidget.TextSmall), IndexPath.new(1, 1))
    self:getDataSource():addItem(TextItem.new("TP", AvatarStatusWidget.TextSmall), IndexPath.new(1, 2))
    self:getDataSource():addItem(TextItem.new(state.AutoAvatarMode.value, AvatarStatusWidget.TextSmall3), IndexPath.new(1, 3))
    self:getDataSource():addItem(TextItem.new('Idle', AvatarStatusWidget.Subheadline), IndexPath.new(1, 4))

    self:getDisposeBag():add(player:on_pet_change():addAction(
            function (_, pet_id, pet_name)
                self:updateAvatar(pet_id, pet_name)
            end), player:on_pet_change())

    self:getDisposeBag():add(WindowerEvents.PetUpdate:addAction(function(owner_id, pet_id, pet_index, pet_name, pet_hpp, pet_mpp, pet_tp)
        if owner_id == self.id then
            if pet_name and pet_id and windower.ffxi.get_mob_by_id(pet_id) then
                self.isInitialized = true
                self:setHpp(pet_hpp)
                if pet_tp then
                    self:setTp(pet_tp)
                end
                self:setVisible(true)
            else
                self:setVisible(false)
            end
            self:layoutIfNeeded()
        end
    end), WindowerEvents.PetUpdate)

    self:getDisposeBag():add(WindowerEvents.ZoneRequest:addAction(function(player_id, _, _, _)
        if player_id == self.id then
            self:setVisible(false)
            self:layoutIfNeeded()
        end
    end), WindowerEvents.ZoneRequest)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)

        handle_cycle('AutoAvatarMode')

        self:getDataSource():updateItem(TextItem.new(state.AutoAvatarMode.value, AvatarStatusWidget.TextSmall3), IndexPath.new(1, 3))

        self:layoutIfNeeded()

        --trustHud:openMenu(AutomatonSettingsMenuItem.new(trustSettings, trustSettingsMode))
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:setAction('Idle')
    self:setTp(0)

    if pet_util.has_pet() then
        self:updateAvatar(pet_util.get_pet().id, pet_util.get_pet().name)
    end

    self:setVisible(false)
    self:setShouldRequestFocus(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():addAny(L{ self.actionDisposeBag })

    return self
end

function AvatarStatusWidget:destroy()
    Widget.destroy(self)
end

function AvatarStatusWidget:setVisible(visible)
    if windower.ffxi.get_mob_by_target('pet') == nil or not self.isInitialized then
        visible = false
    end

    if visible then
        self:getDataSource():updateItem(TextItem.new(state.AutoAvatarMode.value, AvatarStatusWidget.TextSmall3), IndexPath.new(1, 3))
    end

    Widget.setVisible(self, visible)
end

function AvatarStatusWidget:updateAvatar(petId, petName)
    if self.avatar then
        self.avatar:destroy()
        self.avatar = nil
    end

    if petId then
        self.avatar = Avatar.new(petId, self.action_queue)
        self.avatar:monitor()

        --[[self:getDisposeBag():add(self.avatar:on_job_ability_finish():addAction(function(_, abilityName)
            self.actionDisposeBag:destroy()

            self:setAction(abilityName)

            self.actionTimer = Timer.scheduledTimer(3, 3)

            self.actionDisposeBag:add(self.actionTimer:onTimeChange():addAction(function(_)
                self:setAction('Idle')
            end), self.actionTimer:onTimeChange())

            self.actionTimer:start()

            self.actionDisposeBag:addAny(L{ self.actionTimer })
        end), self.avatar:on_job_ability_finish())]]
    end
end

function AvatarStatusWidget:setHpp(hpp)
    self:getDataSource():updateItem(TextItem.new("HP  "..hpp.."%", AvatarStatusWidget.TextSmall), IndexPath.new(1, 1))
end

function AvatarStatusWidget:setTp(tp)
    self:getDataSource():updateItem(TextItem.new("TP  "..tp, AvatarStatusWidget.TextSmall), IndexPath.new(1, 2))
end

function AvatarStatusWidget:setAction(abilityName)
    self:getDataSource():updateItem(TextItem.new(abilityName, AvatarStatusWidget.Subheadline), IndexPath.new(1, 4))
end

return AvatarStatusWidget
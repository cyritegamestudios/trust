local AutomatonSettingsMenuItem = require('ui/settings/menus/attachments/AutomatonSettingsMenuItem')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local pup_util = require('cylibs/util/pup_util')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local AutomatonStatusWidget = setmetatable({}, {__index = Widget })
AutomatonStatusWidget.__index = AutomatonStatusWidget


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

AutomatonStatusWidget.hasMp = true

function AutomatonStatusWidget.new(frame, player, trustHud, trustSettings, trustSettingsMode, trustModeSettings)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if indexPath.section == 1 then
            local cell = TextCollectionViewCell.new(item)
            local itemSize = 13
            if indexPath.row == 2 then
                if not AutomatonStatusWidget.hasMp then
                    itemSize = 0
                end
            end
            cell:setItemSize(itemSize)
            cell:setUserInteractionEnabled(indexPath.row == 4)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Pet", dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 10, true), AutomatonStatusWidget)

    self.id = player:get_id()
    self.actionDisposeBag = DisposeBag.new()

    self:getDataSource():addItem(TextItem.new("HP", AutomatonStatusWidget.TextSmall), IndexPath.new(1, 1))
    self:getDataSource():addItem(TextItem.new("MP", AutomatonStatusWidget.TextSmall), IndexPath.new(1, 2))
    self:getDataSource():addItem(TextItem.new("TP", AutomatonStatusWidget.TextSmall), IndexPath.new(1, 3))
    self:getDataSource():addItem(TextItem.new(pup_util.get_pet_mode(), AutomatonStatusWidget.TextSmall3), IndexPath.new(1, 4))
    self:getDataSource():addItem(TextItem.new('Idle', AutomatonStatusWidget.Subheadline), IndexPath.new(1, 5))

    self:getDisposeBag():add(player:on_pet_change():addAction(
        function (_, pet_id, pet_name)
            self:updateAutomaton(pet_id, pet_name)
        end), player:on_pet_change())

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

    self:getDisposeBag():add(WindowerEvents.ZoneRequest:addAction(function(player_id, _, _, _)
        if player_id == self.id then
            self:setVisible(false)
            self:layoutIfNeeded()
        end
    end), WindowerEvents.ZoneRequest)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self:getDelegate():deselectItemAtIndexPath(indexPath)

        trustHud:openMenu(AutomatonSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings))
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:setAction('Idle')
    self:setTp(0)

    if pet_util.has_pet() then
        self:updateAutomaton(pet_util.get_pet().id, pet_util.get_pet().name)
    end

    self:setVisible(false)
    self:setShouldRequestFocus(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():addAny(L{ self.actionDisposeBag })

    return self
end

function AutomatonStatusWidget:destroy()
    Widget.destroy(self)
end

function AutomatonStatusWidget:setVisible(visible)
    if windower.ffxi.get_mob_by_target('pet') == nil or not self.isInitialized then
        visible = false
    end

    if visible then
        self:getDataSource():updateItem(TextItem.new(pup_util.get_pet_mode(), AutomatonStatusWidget.TextSmall3), IndexPath.new(1, 4))
    end

    Widget.setVisible(self, visible)
end

function AutomatonStatusWidget:updateAutomaton(petId, petName)
    if self.automaton then
        self.automaton:destroy()
        self.automaton = nil
    end

    if petId then
        self.automaton = Automaton.new(petId, self.action_queue)
        self.automaton:monitor()

        self:getDisposeBag():add(self.automaton:on_job_ability_finish():addAction(function(_, abilityName)
            self.actionDisposeBag:destroy()

            self:setAction(abilityName)

            self.actionTimer = Timer.scheduledTimer(3, 3)

            self.actionDisposeBag:add(self.actionTimer:onTimeChange():addAction(function(_)
                self:setAction('Idle')
            end), self.actionTimer:onTimeChange())

            self.actionTimer:start()

            self.actionDisposeBag:addAny(L{ self.actionTimer })
        end), self.automaton:on_job_ability_finish())
    end
end

function AutomatonStatusWidget:setHp(hp, maxHp)
    self:getDataSource():updateItem(TextItem.new("HP  "..hp.." / "..maxHp, AutomatonStatusWidget.TextSmall), IndexPath.new(1, 1))
end

function AutomatonStatusWidget:setMp(mp, maxMp)
    --AutomatonStatusWidget.hasMp = maxMp and maxMp > 0
    if AutomatonStatusWidget.hasMp then
        self:getDataSource():updateItem(TextItem.new("MP  "..mp.." / "..maxMp, AutomatonStatusWidget.TextSmall), IndexPath.new(1, 2))
    else
        self:getDataSource():updateItem(TextItem.new("", AutomatonStatusWidget.TextSmall), IndexPath.new(1, 2))
    end
    self:setSize(self:getSize().width, self:getContentSize().height)

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function AutomatonStatusWidget:setTp(tp)
    self:getDataSource():updateItem(TextItem.new("TP  "..tp, AutomatonStatusWidget.TextSmall), IndexPath.new(1, 3))
end

function AutomatonStatusWidget:setAction(abilityName)
    self:getDataSource():updateItem(TextItem.new(abilityName, AutomatonStatusWidget.Subheadline), IndexPath.new(1, 5))
end

return AutomatonStatusWidget
local Avatar = require('cylibs/entity/avatar')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local PickerCollectionViewCell = require('cylibs/ui/collection_view/cells/picker_collection_view_cell')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local PickerItem = require('cylibs/ui/collection_view/items/picker_item')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Timer = require('cylibs/util/timers/timer')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local Widget = require('ui/widgets/Widget')

local ScholarWidget = setmetatable({}, {__index = Widget })
ScholarWidget.__index = ScholarWidget


ScholarWidget.TextSmall = TextStyle.new(
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
ScholarWidget.TextSmall3 = TextStyle.new(
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
ScholarWidget.Subheadline = TextStyle.new(
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

function ScholarWidget.new(frame, addonSettings, player, trust, trustHud, trustSettings, trustSettingsMode)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        if item.__type == PickerItem.__type then
            local cell = PickerCollectionViewCell.new(item, ScholarWidget.TextSmall3)
            cell:setUserInteractionEnabled(true)
            cell:setIsSelectable(true)
            cell:setItemSize(13)
            return cell
        end
    end)

    local self = setmetatable(Widget.new(frame, "Scholar", addonSettings, dataSource, VerticalFlowLayout.new(0, Padding.new(6, 4, 0, 0), 3), 10, true), ScholarWidget)

    self.addonSettings = addonSettings
    self.id = player:get_id()

    self:setUserInteractionEnabled(true)

    self:getDataSource():addItem(PickerItem.new("Firestorm II", trust:get_job():get_all_storm_names(), function(name) return name end), IndexPath.new(1, 1))


    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        --self:getDelegate():deselectItemAtIndexPath(indexPath)
        print('select')
        if not self:hasFocus() then
            self:requestFocus()
        end
        for key in L{'up','down','left','right','enter','numpadenter'}:it() do
            windower.send_command('bind %s block':format(key))
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(self:getDelegate():didDeselectItemAtIndexPath():addAction(function(indexPath)
        print('deselect')
        for key in L{'up','down','left','right','enter','numpadenter'}:it() do
            windower.send_command('unbind %s':format(key))
        end
        self:requestFocus()
    end), self:getDelegate():didDeselectItemAtIndexPath())

    self:setVisible(false)
    self:setShouldRequestFocus(false)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ScholarWidget:getSettings(addonSettings)
    return addonSettings:getSettings().scholar_widget
end

function ScholarWidget:setHasFocus(hasFocus)
    Widget.setHasFocus(self, hasFocus)
    print('focus')
    if hasFocus then
        self:getDelegate():deselectItemsInSections(L{ 1 })
    end
end

function ScholarWidget:onKeyboardEvent(key, pressed, flags, blocked)
    Widget.onKeyboardEvent(self, key, flags, blocked)
    print(key)

end

return ScholarWidget
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local Puppetmaster = require('cylibs/entity/jobs/PUP')

local ManeuverSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ManeuverSettingsMenuItem.__index = ManeuverSettingsMenuItem

function ManeuverSettingsMenuItem.new(trustSettings, trustSettingsMode, settingsKeyName, descriptionText)
    local self = setmetatable(MenuItem.new(L{
        --ButtonItem.default('Confirm', 18),
    }, {}, nil, "Maneuvers", descriptionText, false), ManeuverSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsKeyName = settingsKeyName
    self.job = Puppetmaster.new()
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local maneuverSets = trustSettings:getSettings()[trustSettingsMode.value].AutomatonSettings.ManeuverSettings[settingsKeyName]

        local configItem = MultiPickerConfigItem.new("ManeuverSets", L{}, L(T(maneuverSets):keyset()):sort(), function(maneuverSetName)
            return tostring(maneuverSetName)
        end)

        local maneuverSettingsEditor = FFXIPickerView.withConfig(configItem, L{})
        maneuverSettingsEditor:setAllowsCursorSelection(true)

        maneuverSettingsEditor:setNeedsLayout()
        maneuverSettingsEditor:layoutIfNeeded()

        self.disposeBag:add(maneuverSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = maneuverSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            if item then
                self.selectedSet = maneuverSets[item:getText()]
                self.selectedSetName = item:getText()

                infoView:setDescription(self.selectedSet:tostring())
            end
        end), maneuverSettingsEditor:getDelegate():didSelectItemAtIndexPath())

        if maneuverSets:length() > 0 then
            maneuverSettingsEditor:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
        end

        return maneuverSettingsEditor
    end

    self:reloadSettings()

    return self
end

function ManeuverSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function ManeuverSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Edit", self:getEditSetMenuItem())
end

function ManeuverSettingsMenuItem:getConfirmMenuItem()
    return MenuItem.action(function()
        if self.selectedSetName then
            state.ManeuverMode:set(self.selectedSetName)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Okay, I'll use the "..self.selectedSetName.." maneuver set now!")
        end
    end)
end

function ManeuverSettingsMenuItem:getEditSetMenuItem()
    local editSetMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(_)
        local configItems = L{}
        for element in L{ 'Fire', 'Earth', 'Water', 'Wind', 'Ice', 'Thunder', 'Light', 'Dark' }:it() do
            configItems:append(PickerConfigItem.new(element, self.selectedSet:getNumManeuvers(element), L{ 0, 1, 2, 3 }, nil, element.." Maneuver"))
        end

        local configEditor = ConfigEditor.new(self.trustSettings, self.selectedSet.maneuvers, configItems, nil, function(newSettings)
            local count = 0
            for _, numManeuvers in pairs(newSettings) do
                count = count + numManeuvers
            end
            if count < 3 then
                if count == 0 then
                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."No can do. You didn't select any maneuvers!")
                else
                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."No can do? You only selected "..count.." maneuvers!")
                end
                return false
            end
            return true
        end)
        return configEditor
    end, "Maneuvers", "Edit maneuvers for this set.")
    return editSetMenuItem
end

return ManeuverSettingsMenuItem
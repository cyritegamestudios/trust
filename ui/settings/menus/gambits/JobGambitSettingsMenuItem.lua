local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local job_util = require('cylibs/util/job_util')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local JobGambitSettingsMenuItem = setmetatable({}, {__index = MenuItem })
JobGambitSettingsMenuItem.__index = JobGambitSettingsMenuItem

function JobGambitSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Toggle', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Gambits", "Toggle default behaviors.", false), JobGambitSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Default or L{}

        local gambitSettingsEditor = FFXIPickerView.withItems(currentGambits:map(function(gambit)
            return gambit:tostring()
        end), L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge, true)
        gambitSettingsEditor:setAllowsCursorSelection(true)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        local itemsToUpdate = L{}
        for rowIndex = 1, gambitSettingsEditor:getDataSource():numberOfItemsInSection(1) do
            local indexPath = IndexPath.new(1, rowIndex)
            local item = gambitSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            item:setEnabled(currentGambits[rowIndex]:isEnabled())
            itemsToUpdate:append(IndexedItem.new(item, indexPath))
        end

        gambitSettingsEditor:getDataSource():updateItems(itemsToUpdate)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        if currentGambits:length() > 0 then
            gambitSettingsEditor:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
        end

        self.gambitSettingsEditor = gambitSettingsEditor

        self.gambitSettingsEditor:getDisposeBag():add(self.gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            if item then
                infoView:setDescription(item:getText())
            end
        end), self.gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath())

        self.gambitSettingsEditor:getDisposeBag():add(gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            if selectedGambit then
                infoView:setDescription(selectedGambit:tostring())
            end
        end), gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        return gambitSettingsEditor
    end

    self:reloadSettings()

    return self
end

function JobGambitSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function JobGambitSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Toggle", self:getToggleMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function JobGambitSettingsMenuItem:getToggleMenuItem()
    return MenuItem.action(function(menu)
        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                item:setEnabled(not item:getEnabled())
                self.gambitSettingsEditor:getDataSource():updateItem(item, selectedIndexPath)

                local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Default
                currentGambits[selectedIndexPath.row]:setEnabled(not currentGambits[selectedIndexPath.row]:isEnabled())
            end
        end
    end, "Gambits", "Temporarily enable or disable the selected Gambit until the addon reloads.")
end


function JobGambitSettingsMenuItem:getModesMenuItem()
    local gambitModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoGambitMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Change Gambit behavior.")
    return gambitModesMenuItem
end

return JobGambitSettingsMenuItem
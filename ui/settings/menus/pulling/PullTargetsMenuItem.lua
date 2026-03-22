local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local PullTargetsMenuItem = setmetatable({}, {__index = MenuItem })
PullTargetsMenuItem.__index = PullTargetsMenuItem

function PullTargetsMenuItem.new(trust_settings, trust_settings_mode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Move Up', 18),
        ButtonItem.default('Move Down', 18),
    }, {}, nil, "Targets", "Choose which enemies to pull."), PullTargetsMenuItem)

    self.trust_settings = trust_settings
    self.trust_settings_mode = trust_settings_mode
    self.dispose_bag = DisposeBag.new()
    self.targetsEditor = nil

    self:setChildMenuItem("Add", self:getAddMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveMenuItem())
    self:setChildMenuItem("Move Up", self:getMoveUpMenuItem())
    self:setChildMenuItem("Move Down", self:getMoveDownMenuItem())

    self.contentViewConstructor = function()
        local currentTargets = self:getTargets()

        local configItem = MultiPickerConfigItem.new("Targets", L{}, currentTargets, function(targetName)
            return targetName
        end)

        self.targetsEditor = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor)
        self.targetsEditor:setAllowsCursorSelection(true)

        return self.targetsEditor
    end

    return self
end

function PullTargetsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function PullTargetsMenuItem:getTargets()
    return self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings.Targets
end

function PullTargetsMenuItem:getAddMenuItem()
    local chooseTargetsMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Clear All', 18),
    }, {
        Clear = MenuItem.action(nil, "Targets", "Clear selected targets."),
    },
    function()
        local allMobs = S{}
        local nearbyMobs = windower.ffxi.get_mob_array()
        for _, mob in pairs(nearbyMobs) do
            if mob.valid_target and mob.spawn_type == 16 then
                allMobs:add(mob.name)
            end
        end

        local configItem = MultiPickerConfigItem.new("Targets", L{}, L(allMobs), function(mobName)
            return mobName
        end)

        local targetPickerView = FFXIPickerView.withConfig(configItem, true)

        self.dispose_bag:add(targetPickerView:on_pick_items():addAction(function(_, newTargetNames)
            targetPickerView:getDelegate():deselectAllItems()

            if newTargetNames:length() > 0 then
                local pullSettings = self.trust_settings:getSettings()[self.trust_settings_mode.value].PullSettings
                pullSettings.Targets = L(S(pullSettings.Targets + newTargetNames))

                self.trust_settings:saveSettings(true)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my list of enemies to pull!")
            end
        end), targetPickerView:on_pick_items())

        return targetPickerView
    end, "Targets", "Choose which enemies to pull.")

    chooseTargetsMenuItem:setChildMenuItem("Confirm", MenuItem.action(function(menu)
        menu:showMenu(self)
    end, "Targets", "Confirm enemies to pull."))

    return chooseTargetsMenuItem
end

function PullTargetsMenuItem:getRemoveMenuItem()
    return MenuItem.action(function()
        if self.targetsEditor then
            local cursorIndexPath = self.targetsEditor:getDelegate():getCursorIndexPath()
            if cursorIndexPath then
                local currentTargets = self:getTargets()
                currentTargets:remove(cursorIndexPath.row)

                self.targetsEditor:getDataSource():removeItem(cursorIndexPath)

                self.trust_settings:saveSettings(true)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I won't pull this enemy anymore!")
            end
        end
    end, "Targets", "Remove selected target from list of enemies to pull.", false, function()
        return self:getTargets():length() > 0
    end)
end

function PullTargetsMenuItem:getMoveUpMenuItem()
    return MenuItem.action(function()
        if self.targetsEditor then
            local selectedIndexPath = self.targetsEditor:getDelegate():getCursorIndexPath()
            if selectedIndexPath and selectedIndexPath.row > 1 then
                local currentTargets = self:getTargets()
                local row = selectedIndexPath.row
                local newIndexPath = IndexPath.new(selectedIndexPath.section, row - 1)

                local item1 = self.targetsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
                local item2 = self.targetsEditor:getDataSource():itemAtIndexPath(newIndexPath)
                if item1 and item2 then
                    currentTargets[row], currentTargets[row - 1] = currentTargets[row - 1], currentTargets[row]

                    self.targetsEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
                    self.targetsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)

                    self.trust_settings:saveSettings(true)
                end
            end
        end
    end, "Targets", "Move selected target up in priority.", false, function()
        if not self.targetsEditor then return false end
        local cursorIndexPath = self.targetsEditor:getDelegate():getCursorIndexPath()
        return cursorIndexPath and cursorIndexPath.row > 1
    end)
end

function PullTargetsMenuItem:getMoveDownMenuItem()
    return MenuItem.action(function()
        if self.targetsEditor then
            local selectedIndexPath = self.targetsEditor:getDelegate():getCursorIndexPath()
            local currentTargets = self:getTargets()
            if selectedIndexPath and selectedIndexPath.row < currentTargets:length() then
                local row = selectedIndexPath.row
                local newIndexPath = IndexPath.new(selectedIndexPath.section, row + 1)

                local item1 = self.targetsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
                local item2 = self.targetsEditor:getDataSource():itemAtIndexPath(newIndexPath)
                if item1 and item2 then
                    currentTargets[row], currentTargets[row + 1] = currentTargets[row + 1], currentTargets[row]

                    self.targetsEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
                    self.targetsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)

                    self.trust_settings:saveSettings(true)
                end
            end
        end
    end, "Targets", "Move selected target down in priority.", false, function()
        if not self.targetsEditor then return false end
        local cursorIndexPath = self.targetsEditor:getDelegate():getCursorIndexPath()
        local currentTargets = self:getTargets()
        return cursorIndexPath and cursorIndexPath.row < currentTargets:length()
    end)
end

return PullTargetsMenuItem

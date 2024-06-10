local config = require('config')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')

local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local TargetsPickerView = setmetatable({}, {__index = FFXIPickerView })
TargetsPickerView.__index = TargetsPickerView

function TargetsPickerView.new(addonSettings, puller)
    local allMobs = S{}
    local nearbyMobs = windower.ffxi.get_mob_array()
    for _, mob in pairs(nearbyMobs) do
        if mob.valid_target and mob.spawn_type == 16 then
            allMobs:add(mob.name)
        end
    end

    local self = setmetatable(FFXIPickerView.withItems(allMobs, L{}, true), TargetsPickerView)

    self.addonSettings = addonSettings
    self.puller = puller

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    return self
end

function TargetsPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    local targets = S(self.addonSettings:getSettings().battle.targets)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            for selectedIndexPath in selectedIndexPaths:it() do
                local item = self:getDataSource():itemAtIndexPath(selectedIndexPath)
                if item then
                    targets:add(item:getText())
                end
            end
            self:getDelegate():deselectAllItems()

            self.addonSettings:getSettings().battle.targets = L(targets)
            self.addonSettings:saveSettings()

            if self.puller then
                self.puller:set_target_names(targets)
            end

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated the list of mobs to pull.")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
    end
end

function TargetsPickerView:shouldRequestFocus()
    return FFXIPickerView.shouldRequestFocus(self) and self:getDataSource():numberOfItemsInSection(1) > 0
end

return TargetsPickerView
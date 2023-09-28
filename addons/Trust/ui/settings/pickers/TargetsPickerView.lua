local config = require('config')
local PickerView = require('cylibs/ui/picker/picker_view')

local TargetsPickerView = setmetatable({}, {__index = PickerView })
TargetsPickerView.__index = TargetsPickerView

function TargetsPickerView.new(settings, trust)
    local allMobs = S{}
    local nearbyMobs = windower.ffxi.get_mob_array()
    for _, mob in pairs(nearbyMobs) do
        if mob.valid_target and mob.spawn_type == 16 then
            allMobs:add(mob.name)
        end
    end

    local self = setmetatable(PickerView.withItems(allMobs, L{}, true), TargetsPickerView)

    self.settings = settings
    self.puller = trust:role_with_type("puller")

    return self
end

function TargetsPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    local targets = S(settings.battle.targets)
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

            settings.battle.targets = L(targets)

            config.save(settings)

            if self.puller then
                self.puller:set_target_names(targets)
            end

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated the list of mobs to pull.")
        end
    elseif textItem:getText() == 'Clear' then
        self:getDelegate():deselectAllItems()
    end
end

return TargetsPickerView
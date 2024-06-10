local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PartyTargetView = require('ui/views/PartyTargetView')

local PartyTargetsMenuItem = setmetatable({}, {__index = MenuItem })
PartyTargetsMenuItem.__index = PartyTargetsMenuItem

function PartyTargetsMenuItem.new(party, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Debuffs', 18),
    }, {},
            function()
                local targetsView = viewFactory(PartyTargetView.new(party.target_tracker))
                targetsView:setShouldRequestFocus(true)
                return targetsView
            end, "Targets", "View info for enemies the party is fighting."), PartyTargetsMenuItem)

    self.target_tracker = party.target_tracker
    self.viewFactory = viewFactory
    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function PartyTargetsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function PartyTargetsMenuItem:reloadSettings()
    self:setChildMenuItem("Debuffs", self:getTargetDebuffsMenuItem())
end

function PartyTargetsMenuItem:getTargetDebuffsMenuItem()
    local targetDebuffsMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear All', 18),
    }, {},
            function(args)
                local target = args['selected_target']
                if target then
                    local activeDebuffs = target.debuff_tracker:get_debuff_ids():map(function(debuff_id) return buff_util.buff_name(debuff_id) end)
                    local targetDebuffsView = self.viewFactory(FFXIPickerView.withItems(activeDebuffs, L{}))
                    targetDebuffsView:setShouldRequestFocus(false)
                    targetDebuffsView:setTitle("View debuffs on the "..target:get_name()..".")
                    return targetDebuffsView
                end
                return nil
            end, "Targets", "View debuffs on the target.")
    return targetDebuffsMenuItem
end

return PartyTargetsMenuItem
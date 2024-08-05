local inventory_util = require('cylibs/util/inventory_util')
local packets = require('packets')

local Action = require('cylibs/actions/action')
local TradeNpcAction = setmetatable({}, { __index = Action })
TradeNpcAction.__index = TradeNpcAction
TradeNpcAction.__class = "TradeNpcAction"

function TradeNpcAction.new(target_index, item_id, item_count, item_index, num_items, wait_for_response)
    local conditions = L{
        ValidTargetCondition.new()
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), TradeNpcAction)
    self.item_id = item_id
    self.item_count = item_count
    self.item_index = item_index
    self.num_items = num_items
    self.wait_for_response = wait_for_response
    self.events = {}
    return self
end

function TradeNpcAction:destroy()
    Action.destroy(self)

    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end
end

function TradeNpcAction:can_perform()
    if not Action.can_perform(self) then
        return false
    end
    return inventory_util.get_inventory_index(self.item_id) ~= nil
end

function TradeNpcAction:perform()
    local target = windower.ffxi.get_mob_by_index(self.target_index)

    local request = {}

    request['Target'] = target.id
    request['Item Count 1'] = self.item_count
    request['Item Index 1'] = self.item_index
    request['Target Index'] = target.index
    request['Number of Items'] = self.num_items

    local p = packets.new('outgoing', 0x036, request)
    packets.inject(p)

    if not self.wait_for_response then
        self:complete(true)
    end
end

function TradeNpcAction:on_incoming_chunk(id, data, modified, injected, blocked)
    if id == 0x052 then
        self:complete(false)
        return true
    elseif id == 0x032 or id == 0x034 then
        self:complete(true)
        return true
    end
    return false
end

function TradeNpcAction:gettype()
    return "tradenpcaction"
end

function TradeNpcAction:is_equal(action)
    if action == nil or action.__class ~= TradeNpcAction.__class then
        return false
    end
    return self:gettype() == action:gettype()
            and self:get_target_index() == action:get_target_index()
            and self.item_id == action.item_id
            and self.item_count == action.item_count
            and self.item_index == action.item_index
end

function TradeNpcAction:tostring()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    return 'Trade '..res.items[self.item_id].en..' → '..target.name
end

function TradeNpcAction:debug_string()
    return "TradeOfferAction item: %d":format(self.item_id)
end

return TradeNpcAction




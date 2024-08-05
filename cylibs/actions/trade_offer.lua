local inventory_util = require('cylibs/util/inventory_util')
local packets = require('packets')

local Action = require('cylibs/actions/action')
local TradeOfferAction = setmetatable({}, { __index = Action })
TradeOfferAction.__index = TradeOfferAction
TradeOfferAction.__class = "TradeOfferAction"

function TradeOfferAction.new(target_index, item_id, item_count)
    local conditions = L{
        ValidTargetCondition.new()
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), TradeOfferAction)
    self.item_id = item_id
    self.item_count = item_count
    self.events = {}
    return self
end

function TradeOfferAction:destroy()
    Action.destroy(self)

    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end
end

function TradeOfferAction:can_perform()
    if not Action.can_perform(self) then
        return false
    end
    return inventory_util.get_inventory_index(self.item_id) ~= nil
end

function TradeOfferAction:perform()
    local request = {}

    request['Count'] = self.item_count
    request['Item'] = self.item_id
    request['Inventory Index'] = inventory_util.get_inventory_index(self.item_id)
    request['Slot'] = 1

    self.events.incoming_chunk = windower.register_event('incoming chunk', function(id, data)
        if id == 0x025 then
            local response = packets.parse('incoming', data)
            if self:validate_response(request, response) then
                self:complete(true)
            else
                self:complete(false)
            end
        end
    end)

    local p = packets.new('outgoing', 0x034, request)
    packets.inject(p)
end

function TradeOfferAction:validate_response(request, response)
    for key in L{ 'Count', 'Item', 'Inventory Index', 'Slot' }:it() do
        if request[key] ~= response[key] then
            return false
        end
    end
    return true
end

function TradeOfferAction:gettype()
    return "tradeofferaction"
end

function TradeOfferAction:copy()
    return TradeOfferAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_target_index(), self.item_id, self.item_count)
end

function TradeOfferAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:get_target_index() == action:get_target_index()
            and self.item_id == action.item_id and self.item_count == action.item_count
end

function TradeOfferAction:tostring()
    return 'Trade Offer → '..res.items[self.item_id].name
end

function TradeOfferAction:debug_string()
    return "TradeOfferAction item: %d":format(self.item_id)
end

return TradeOfferAction




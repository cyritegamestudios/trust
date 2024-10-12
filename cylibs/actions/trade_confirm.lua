local packets = require('packets')

local Action = require('cylibs/actions/action')
local TradeConfirmAction = setmetatable({}, { __index = Action })
TradeConfirmAction.__index = TradeConfirmAction
TradeConfirmAction.__class = "TradeConfirmAction"

function TradeConfirmAction.new(target_index, wait_for_confirm, is_recipient)
    local conditions = L{
        ValidTargetCondition.new()
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), TradeConfirmAction)
    self.events = {}
    self.wait_for_confirm = wait_for_confirm
    self.is_recipient = is_recipient
    return self
end

function TradeConfirmAction:destroy()
    Action.destroy(self)

    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end
end

function TradeConfirmAction:get_trade_count()
    if self.is_recipient then
        local data = windower.packets.last_incoming(0x023)
        if data then
            local packet = packets.parse('incoming', data)
            return packet['Trade Count'] or 0
        end
    end
    return 0
end

function TradeConfirmAction:perform()
    local send_request = function()
        local request = {}

        request['Type'] = 2 -- Confirm Trade
        request['Trade Count'] = self:get_trade_count()

        local p = packets.new('outgoing', 0x033, request)
        packets.inject(p)

        print('sending request')
    end

    if self.wait_for_confirm then
        self.events.incoming_chunk = windower.register_event('incoming chunk', function(id, data)
            if id == 0x022 then
                local response = packets.parse('incoming', data)
                if response['Index'] == self:get_target_index() then
                    if L{ 2, 9 }:contains(response['Type']) then
                        self:complete(true)
                    else
                        self:complete(false)
                    end
                else
                    self:complete(false)
                end
            end
        end)
        send_request()
    else
        send_request()
        self:complete(true)
    end
end

function TradeConfirmAction:gettype()
    return "tradeconfirmaction"
end

function TradeConfirmAction:get_max_duration()
    return 20
end

function TradeConfirmAction:copy()
    return TradeConfirmAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_target_index())
end

function TradeConfirmAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:get_target_index() == action:get_target_index()
end

function TradeConfirmAction:tostring()
    local target = windower.ffxi.get_mob_by_index(self:get_target_index())
    return 'Trade Confirm → '..target.name
end

function TradeConfirmAction:debug_string()
    return "TradeConfirmAction target: %d":format(self:get_target_index())
end

return TradeConfirmAction





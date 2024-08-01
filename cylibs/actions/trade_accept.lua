local packets = require('packets')

local Action = require('cylibs/actions/action')
local TradeAcceptAction = setmetatable({}, { __index = Action })
TradeAcceptAction.__index = TradeAcceptAction
TradeAcceptAction.__class = "TradeAcceptAction"

function TradeAcceptAction.new(is_recipient)
    local self = setmetatable(Action.new(0, 0, 0), TradeAcceptAction)
    self.is_recipient = is_recipient
    return self
end

function TradeAcceptAction:get_trade_count()
    if self.is_recipient then
        local data = windower.packets.last_incoming(0x023)
        if data then
            local packet = packets.parse('incoming', data)
            return packet['Trade Count'] or 0
        end
    end
    return 0
end

function TradeAcceptAction:perform()
    local data = {}

    data['Type'] = 0 -- Accept Trade
    data['Trade Count'] = self:get_trade_count()

    local p = packets.new('outgoing', 0x033, data)
    packets.inject(p)

    self:complete(true)
end

function TradeAcceptAction:gettype()
    return "tradeacceptaction"
end

function TradeAcceptAction:copy()
    return TradeAcceptAction.new()
end

function TradeAcceptAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype()
end

function TradeAcceptAction:tostring()
    return 'Trade Accept'
end

function TradeAcceptAction:debug_string()
    return 'TradeAcceptAction'
end

return TradeAcceptAction





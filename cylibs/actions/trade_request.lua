local packets = require('packets')

local Action = require('cylibs/actions/action')
local TradeRequestAction = setmetatable({}, { __index = Action })
TradeRequestAction.__index = TradeRequestAction
TradeRequestAction.__class = "TradeRequestAction"

function TradeRequestAction.new(target_index, wait_for_accept)
    local conditions = L{
        ValidTargetCondition.new()
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), TradeRequestAction)
    self.events = {}
    self.wait_for_accept = wait_for_accept
    return self
end

function TradeRequestAction:destroy()
    Action.destroy(self)

    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end
end

function TradeRequestAction:perform()
    local target = windower.ffxi.get_mob_by_index(self:get_target_index())

    local data = {}

    data['Target'] = target.id
    data['Target Index'] = target.index

    local p = packets.new('outgoing', 0x032, data)
    packets.inject(p)

    if self.wait_for_accept then
        self.events.incoming_chunk = windower.register_event('incoming chunk', function(id, data)
            if id == 0x022 then
                local response = packets.parse('incoming', data)
                if response['Index'] == self:get_target_index() then
                    if response['Type'] == 0 then
                        self:complete(true)
                    else
                        self:complete(false)
                    end
                else
                    self:complete(false)
                end
            end
        end)
    else
        self:complete(true)
    end
end

function TradeRequestAction:gettype()
    return "traderequestaction"
end

function TradeRequestAction:copy()
    return TradeRequestAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_target_index())
end

function TradeRequestAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:get_target_index() == action:get_target_index()
end

function TradeRequestAction:tostring()
    local target = windower.ffxi.get_mob_by_index(self:get_target_index())
    return 'Trade Request → '..target.name
end

function TradeRequestAction:debug_string()
    return "TradeRequestAction target: %d":format(self:get_target_index())
end

return TradeRequestAction




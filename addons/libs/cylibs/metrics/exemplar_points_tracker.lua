---------------------------
-- Tracks exemplar points.
-- @class module
-- @name ExemplarPointsTracker

local ExemplarPointsTracker = {}
ExemplarPointsTracker.__index = ExemplarPointsTracker

-------
-- Default initializer for an ExemplarPointsTracker.
-- @treturn ExemplarPointsTracker An exemplar points tracker
function ExemplarPointsTracker.new()
    local self = setmetatable({
        action_events = {};
        total_ep_earned = 0;
    }, ExemplarPointsTracker)
    return self
end


-------
-- Stops tracking the player's exemplar points and disposes of all registered event handlers.
function ExemplarPointsTracker:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

-------
-- Starts tracking the player's exemplar points. Exemplar points will not be tracked until this is called.
function ExemplarPointsTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.action_events.incoming_chunk = windower.register_event('incoming chunk',function(id, original, _, _, _)
        if id == 0x2D then
            local message_id = original:unpack('H',0x19) % 1024
            if L{809,810}:contains(message_id) then
                local exemplar_points = original:unpack('I', 0x11)
                self.total_ep_earned = self.total_ep_earned + exemplar_points
            end
        end
    end)
end


-------
-- Returns the total number of exemplar points earned this session.
-- @treturn number Exemplar points earned
function ExemplarPointsTracker:get_total_ep_earned()
    return self.total_ep_earned
end

-------
-- Returns the number of exemplar points earned per hour.
-- @treturn number Exemplar points earned per hour
function ExemplarPointsTracker:get_ep_per_hour()
    return windower.ffxi.get_mob_by_id(self.id)
end

return ExemplarPointsTracker
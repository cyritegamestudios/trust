---------------------------
-- Tracks distance between two party members.
-- @class module
-- @name DistanceTracker

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local DistanceTracker = {}
DistanceTracker.__index = DistanceTracker
DistanceTracker.__class = 'DistanceTracker'

-- Event called when the target gains a daze
function DistanceTracker:on_distance_changed()
    return self.distance_changed
end

-------
-- Default initializer for a new party member distance tracker.
-- @treturn DistanceTracker A distance tracker
function DistanceTracker.new(party_member_1, party_member_2)
    local self = setmetatable({}, DistanceTracker)

    self.party_member_1 = party_member_1
    self.party_member_2 = party_member_2
    self.dispose_bag = DisposeBag.new()

    self.distance_changed = Event.newEvent()

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function DistanceTracker:destroy()
    self.dispose_bag:destroy()

    self.distance_changed:removeAllActions()
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before steps will be tracked.
function DistanceTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    local party_members = L{ self.party_member_1, self.party_member_2 }
    for party_member_1 in party_members:it() do
        self.dispose_bag:add(party_member_1:on_position_change():addAction(function(_, x, y, z)
            local party_member_2 = party_members:firstWhere(function(party_member_2)
                return party_member_2:get_id() ~= party_member_1:get_id()
            end)
            if party_member_2 then
                self:on_distance_changed():trigger(party_member_1, party_member_2, party_member_2.dist:sqrt())
            end
        end), party_member_1:on_position_change())
    end
end

return DistanceTracker
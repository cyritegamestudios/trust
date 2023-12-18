---------------------------
-- Tracks statistics for a Healer role.
-- @class module
-- @name HealerTracker

local DisposeBag = require('cylibs/events/dispose_bag')

local HealerTracker = {}
HealerTracker.__index = HealerTracker
HealerTracker.__class = "HealerTracker"

local TimeToHeal = require('cylibs/analytics/trackers/metrics/healer/time_to_heal')

-------
-- Default initializer for a new healer tracker.
-- @tparam Healer healer Healer role
-- @treturn HealerTracker A healer tracker
function HealerTracker.new(healer)
    local self = setmetatable({
        healer = healer;
        start_time = os.time();
        metrics = L{};
        dispose_bag = DisposeBag.new();
    }, HealerTracker)

    return self
end

function HealerTracker:destroy()
    self.dispose_bag:destroy()
end

-------
-- Starts tracking healer stats.
function HealerTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.start_time = os.time()

    self.metrics = L{
        TimeToHeal.new(self.healer)
    }
    self.dispose_bag:addAny(self.metrics)

    for metric in self.metrics:it() do
        metric:monitor()
    end
end

-------
-- Resets the tracker.
function HealerTracker:reset()
    self.start_time = os.time()

    for metric in self.metrics:it() do
        metric:reset()
    end
end

-------
-- Reports to trust chat.
function HealerTracker:report()
    for metric in self.metrics:it() do
        metric:report()
    end
end

return HealerTracker
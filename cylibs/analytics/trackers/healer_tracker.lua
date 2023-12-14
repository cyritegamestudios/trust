---------------------------
-- Tracks statistics for a Healer role.
-- @class module
-- @name HealerTracker

local DisposeBag = require('cylibs/events/dispose_bag')

local HealerTracker = {}
HealerTracker.__index = HealerTracker
HealerTracker.__class = "HealerTracker"

-------
-- Default initializer for a new healer tracker.
-- @tparam Healer healer Healer role
-- @treturn HealerTracker A healer tracker
function HealerTracker.new(healer)
    local self = setmetatable({
        action_events = {};
        healer = healer;
        critical_hpp_start_time = {}; -- time when party member went below hpp threshold
        critical_hpp_sum = {}; -- number of seconds spent under hpp threshold
        critical_hpp_ttr_average = {}; -- average number of seconds to bring above hpp threshold, stored as {count, average}
        start_time = os.time();
        dispose_bag = DisposeBag.new();
    }, HealerTracker)

    return self
end

function HealerTracker:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
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

    local on_party_member_added = function(p)
        self.critical_hpp_sum[p:get_id()] = 0
        self.critical_hpp_ttr_average[p:get_id()] = { count = 0, average = 0.0 }

        self.dispose_bag:add(p:on_hp_change():addAction(function(p, hpp, max_hp)
            self:report_hpp_change(p, hpp, max_hp)
        end), p:on_hp_change())
    end

    self.dispose_bag:add(self.healer:get_party():on_party_member_added():addAction(on_party_member_added), self.healer:get_party():on_party_member_added())

    for party_member in self.healer:get_party():get_party_members(true):it() do
        on_party_member_added(party_member)
    end
end

function HealerTracker:report_hpp_change(p, hpp, max_hp)
    local hpp_threshold = self.healer:get_job():get_cure_threshold(state.AutoHealMode == 'Emergency')
    if hpp <= hpp_threshold then
        if not self.critical_hpp_start_time[p:get_id()] then
            self.critical_hpp_start_time[p:get_id()] = self.critical_hpp_start_time[p:get_id()] or os.time()

            logger.notice(self.__class, 'report_hpp_change', p:get_name(), 'start', hpp, hpp_threshold)
        end
    else
        local start_time = self.critical_hpp_start_time[p:get_id()]
        if start_time then
            self.critical_hpp_start_time[p:get_id()] = nil

            local delta = os.time() - start_time
            self.critical_hpp_sum[p:get_id()] = (self.critical_hpp_sum[p:get_id()] or 0) + delta

            local ttr = self.critical_hpp_ttr_average[p:get_id()]

            ttr.count = ttr.count + 1
            ttr.average = (ttr.average + delta) / ttr.count

            self.critical_hpp_ttr_average[p:get_id()] = ttr

            logger.notice(self.__class, 'report_hpp_change', p:get_name(), 'logging', delta, 'seconds')
        end
    end
end

-------
-- Resets the tracker.
function HealerTracker:reset()
    self.start_time = os.time()
end

-------
-- Reports to trust chat.
function HealerTracker:report()
    local time_elapsed = os.time() - self.start_time
    local result = self.__class..' Report:\nTime spent below HPP threshold'
    local average = 0.0
    local num_reporting = 0
    for party_member_id, total_time in pairs(self.critical_hpp_sum) do
        average = average + 1.0 * total_time / time_elapsed
        num_reporting = num_reporting + 1
        result = "%s\n[%s] %ds (%ds) ttr %.2fs":format(result, self.healer:get_party():get_party_member(party_member_id):get_name(), total_time, time_elapsed, self.critical_hpp_ttr_average[party_member_id].average)
    end
    average = 1.0 - average / num_reporting
    result = "%s\nScore: %d/%d":format(result, average * 100, 100)
    self.healer:get_party():add_to_chat(self.healer:get_party():get_player(), result)
end

return HealerTracker
---------------------------
-- Tracks statistics for a Healer role.
-- @class module
-- @name HealerTracker

local DisposeBag = require('cylibs/events/dispose_bag')

local TimeToHealMetric = {}
TimeToHealMetric.__index = TimeToHealMetric
TimeToHealMetric.__class = "TimeToHealMetric"

-------
-- Default initializer for a new healer tracker.
-- @tparam Healer healer Healer role
-- @treturn HealerTracker A healer tracker
function TimeToHealMetric.new(healer)
    local self = setmetatable({
        action_events = {};
        healer = healer;
        time_to_heal_summary = {}; -- time to heal above hp threshold {total, average, count, last_start_time}
        start_time = os.time();
        dispose_bag = DisposeBag.new();
    }, TimeToHealMetric)

    return self
end

function TimeToHealMetric:destroy()
    self.dispose_bag:destroy()
end

-------
-- Starts tracking healer stats.
function TimeToHealMetric:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.start_time = os.time()

    local on_party_member_added = function(p)
        self.time_to_heal_summary[p:get_id()] = { total = 0, average = 0.0, count = 0, last_start_time = nil }

        self.dispose_bag:add(p:on_hp_change():addAction(function(p, hpp, max_hp)
            self:report_hpp_change(p, hpp, max_hp)
        end), p:on_hp_change())
    end

    self.dispose_bag:add(self.healer:get_party():on_party_member_added():addAction(on_party_member_added), self.healer:get_party():on_party_member_added())

    for party_member in self.healer:get_party():get_party_members(true):it() do
        on_party_member_added(party_member)
    end
end

function TimeToHealMetric:report_hpp_change(p, hpp, max_hp)
    local hpp_threshold = 72 --self.healer:get_job():get_cure_threshold(state.AutoHealMode == 'Emergency')
    if hpp <= hpp_threshold then
        if not self.time_to_heal_summary[p:get_id()].last_start_time then
            self.time_to_heal_summary[p:get_id()].last_start_time = os.time()

            logger.notice(self.__class, 'report_hpp_change', p:get_name(), 'start', hpp, hpp_threshold)
        end
    else
        local start_time = self.time_to_heal_summary[p:get_id()].last_start_time
        if start_time then
            self.time_to_heal_summary[p:get_id()].last_start_time = nil

            local delta = os.time() - start_time
            self.time_to_heal_summary[p:get_id()].total = self.time_to_heal_summary[p:get_id()].total + delta

            local ttr = self.time_to_heal_summary[p:get_id()]

            ttr.count = ttr.count + 1
            ttr.average = (ttr.average + delta) / ttr.count
            
            self.time_to_heal_summary[p:get_id()] = ttr

            logger.notice(self.__class, 'report_hpp_change', p:get_name(), 'logging', delta, 'seconds')
        end
    end
end

-------
-- Resets the tracker.
function TimeToHealMetric:reset()
    self.start_time = os.time()

    self.time_to_heal_summary = {}
    for party_member in self.healer:get_party():get_party_members(true):it() do
        self.time_to_heal_summary[party_member:get_id()] = { total = 0, average = 0.0, count = 0, last_start_time = nil }
    end
end

-------
-- Reports to trust chat.
function TimeToHealMetric:report()
    local time_elapsed = os.time() - self.start_time
    local result = self.__class..' Report:\n'..self:description()..' ('..time_elapsed..'s)'
    local average = 0.0
    local num_reporting = T(self.time_to_heal_summary):keyset():length()
    for party_member_id, time_to_heal in pairs(self.time_to_heal_summary) do
        average = average + 1.0 * time_to_heal.total / time_elapsed
        local party_member = self.healer:get_party():get_party_member(party_member_id)
        if party_member then
            result = "%s\n[%s] %ds (avg %.2fs)":format(result, party_member:get_name(), time_to_heal.total, time_to_heal.average)
        end
    end
    average = 1.0 - average / num_reporting
    result = "%s\nScore: %d/%d":format(result, average * 100, 100)
    self.healer:get_party():add_to_chat(self.healer:get_party():get_player(), result)
end

function TimeToHealMetric:description()
    return 'Time spent below HPP threshold'
end

return TimeToHealMetric
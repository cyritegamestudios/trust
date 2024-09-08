local monster_util = require('cylibs/util/monster_util')
local SleepTracker = require('cylibs/battle/sleep_tracker')
local spell_util = require('cylibs/util/spell_util')

local Sleeper = setmetatable({}, {__index = Role })
Sleeper.__index = Sleeper

state.AutoSleepMode = M{['description'] = 'Auto Sleep Mode', 'Off', 'Auto'}
state.AutoSleepMode:set_description('Auto', "Okay, I'll automatically try to sleep large groups of monsters.")

function Sleeper.new(action_queue, sleep_spells, min_mobs_to_sleep)
    local self = setmetatable(Role.new(action_queue), Sleeper)

    self:set_sleep_spells(sleep_spells)

    self.last_sleep_time = os.time()
    self.min_mobs_to_sleep = min_mobs_to_sleep or 2

    return self
end

function Sleeper:destroy()
    Role.destroy(self)

    self.sleep_tracker:destroy()
end

function Sleeper:on_add()
    Role.on_add(self)

    self.sleep_tracker = SleepTracker.new()
    self.sleep_tracker:monitor()
end

function Sleeper:target_change(target_index)
    Role.target_change(self, target_index)
end

function Sleeper:tic(new_time, old_time)
    if state.AutoSleepMode.value == 'Off' or (os.time() - self.last_sleep_time) < 6 or self:get_player():is_moving() then
        return
    end
    self:check_sleep()
end

function Sleeper:check_sleep()
    local mobs_to_sleep = L{}

    local nearby_mobs = windower.ffxi.get_mob_array()
    for _, target in pairs(nearby_mobs) do
        if target and target.hpp > 0 and target.distance:sqrt() <= 12 then
            if monster_util.immune_to_debuff(target.name, 'sleep') then
                self:get_party():add_to_chat(self:get_party():get_player(), "I can't sleep because the "..target.name.." is in the way.", "sleeper_immune_sleep", 15)
                return
            end
        end
        if target and target.hpp > 0 and L{0, 1}:contains(target.status) and target.distance:sqrt() <= 12 and target.valid_target and target.spawn_type == 16 then
            if not self.sleep_tracker:is_sleeping(target.id) then
                mobs_to_sleep:append(target)
            end
        end
    end

    if mobs_to_sleep:length() >= self.min_mobs_to_sleep then
        for sleep_spell in self.sleep_spells:it() do
            if not spell_util.is_spell_on_cooldown(sleep_spell:get_spell().id) then
                self:cast_spell(sleep_spell, mobs_to_sleep[1].index)
                return
            end
        end
    end
end

function Sleeper:cast_spell(spell, target_index)
    if spell_util.can_cast_spell(spell:get_spell().id) then
        self.last_sleep_time = os.time()

        self:get_party():add_to_chat(self:get_party():get_player(), "Nighty night!", "sleeper_cast_spell", 30)

        local actions = L{}

        actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, target_index, self:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 2))

        local sleep_action = SequenceAction.new(actions, 'sleeper_'..spell:get_spell().en)
        sleep_action.priority = ActionPriority.highest

        self.action_queue:push_action(sleep_action, true)
    end
end

function Sleeper:set_sleep_spells(sleep_spells)
    self.sleep_spells = (sleep_spells or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
end

function Sleeper:allows_duplicates()
    return true
end

function Sleeper:get_type()
    return "sleeper"
end

function Sleeper:tostring()
    local result = ""

    result = result.."Spells:\n"
    if self.debuff_spells:length() > 0 then
        for spell in self.sleep_spells:it() do
            result = result..'• '..spell:description()..'\n'
        end
    else
        result = result..'N/A'..'\n'
    end

    return result
end

return Sleeper

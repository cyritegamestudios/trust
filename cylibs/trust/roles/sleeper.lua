local DisposeBag = require('cylibs/events/dispose_bag')
local MobFilter = require('cylibs/battle/monsters/mob_filter')
local monster_util = require('cylibs/util/monster_util')
local spell_util = require('cylibs/util/spell_util')

local Sleeper = setmetatable({}, {__index = Role })
Sleeper.__index = Sleeper

state.AutoSleepMode = M{['description'] = 'Auto Sleep Mode', 'Off', 'Auto'}
state.AutoSleepMode:set_description('Auto', "Okay, I'll automatically try to sleep large groups of monsters.")

function Sleeper.new(action_queue, sleep_spells, min_mobs_to_sleep)
    local self = setmetatable(Role.new(action_queue), Sleeper)

    self:set_sleep_spells(sleep_spells)

    self.dispose_bag = DisposeBag.new()
    self.last_sleep_time = os.time()
    self.min_mobs_to_sleep = min_mobs_to_sleep or 2

    return self
end

function Sleeper:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Sleeper:on_add()
    Role.on_add(self)

<<<<<<< HEAD
    self.mob_filter = MobFilter.new(self:get_alliance(), 15)
=======
    self.mob_filter = MobFilter.new(self:get_alliance(), 20)
>>>>>>> main

    self.dispose_bag:addAny(L{ self.mob_filter })
end

function Sleeper:tic(new_time, old_time)
    if state.AutoSleepMode.value == 'Off' or (os.time() - self.last_sleep_time) < 2 or self:get_player():is_moving() then
        return
    end
    self:check_sleep()
end

function Sleeper:check_sleep()
    local conditions = L{
        NotCondition.new(L{ HasDebuffCondition.new('sleep') })
    }

    local targets = self.mob_filter:get_nearby_mobs(L{ MobFilter.Type.Aggroed, MobFilter.Type.Unclaimed }):filter(function(mob)
        local monster = self:get_alliance():get_target_by_index(mob.index)
        if monster then
            return Condition.check_conditions(conditions, mob.index)
                    and not monster_util.immune_to_debuff(mob.name, 'sleep')
        end
        return false
    end)

    if targets:length() >= self.min_mobs_to_sleep then
        for sleep_spell in self.sleep_spells:it() do
            if Condition.check_conditions(sleep_spell:get_conditions(), windower.ffxi.get_player().index) then
                self:cast_spell(sleep_spell, targets[1].index)
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

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasRollCondition = require('cylibs/conditions/has_roll')
local HealerTracker = require('cylibs/analytics/trackers/healer_tracker')
local TargetNamesCondition = require('cylibs/conditions/target_names')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Roller = setmetatable({}, {__index = Gambiter })
Roller.__index = Roller

state.AutoRollMode = M{['description'] = 'Use Phantom Roll', 'Manual', 'Auto', 'Safe', 'Off'}
state.AutoRollMode:set_description('Manual', "Automatically double up after manually using a roll.")
state.AutoRollMode:set_description('Auto', "Automatically roll until an 11 or lucky roll.")
state.AutoRollMode:set_description('Safe', "Automatically roll and prioritize not busting over an 11 or lucky roll.")

-- Event called when rolls begin
function Roller:on_rolls_begin()
    return self.rolls_begin
end

-- Event called when rolls end
function Roller:on_rolls_end()
    return self.rolls_end
end

-------
-- Default initializer for a nuker role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam T roll_settings Roll settings
-- @treturn Healer A healer role
function Roller.new(action_queue, roll_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoRollMode }), Roller)

    self.job = job
    self.roll1_current = 0
    self.roll2_current = 0
    self.rolls_begin = Event.newEvent()
    self.rolls_end = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    self:set_roll_settings(roll_settings)

    return self
end

function Roller:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()

    self:on_rolls_begin():removeAllActions()
    self:on_rolls_end():removeAllActions()
end

function Roller:on_add()
    Gambiter.on_add(self)

    self.dispose_bag:add(self:get_player():on_job_ability_used():addAction(
        function(_, job_ability_id, targets)
            if self.job:is_roll(job_ability_id) then
                coroutine.schedule(function()
                    self:on_roll_used(job_ability_id, targets)
                end, 1)
            end
        end), self:get_player():on_job_ability_used())
end

function Roller:get_cooldown()
    return 4
end


-- FIXME: this can actually work--just need to set priority of main vs sub job heals
function Roller:allows_duplicates()
    return false
end

function Roller:get_type()
    return "roller"
end

function Roller:allows_multiple_actions()
    return false
end

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function Roller:set_roll_settings(roll_settings)
    self.roll_settings = roll_settings
    self.roll1 = roll_settings.Roll1
    self.roll2 = roll_settings.Roll2
    self.max_double_up_num = roll_settings.DoubleUpThreshold
    self.num_party_members_nearby = roll_settings.NumRequiredPartyMembers

    -- 1. If bust -> fold
    -- 2. If double up active and current roll == lucky roll - 1 -> snake eye

    -- For each roll (only add gambits for ones that match roll 1 and roll 2, don't add if COR is sub job):
    -- 1. Not has roll 1 -> phantom roll (roll 1, optionally use crooked cards)
    -- 2. Has roll 1 and double up is active and unlucky roll -> double up
    -- 3. Has roll 1 and double up is active and not is lucky roll and current roll < max double up threshold -> double up

    local gambit_settings = {
        Gambits = L{},
        Roll1 = L{},
        Roll2 = L{},
    }

    gambit_settings.Gambits = L{
        Gambit.new(GambitTarget.TargetType.Self, L{
            GambitCondition.new(HasBuffCondition.new('Bust'), GambitTarget.TargetType.Self),
        }, JobAbility.new('Fold'), Condition.TargetType.Self),
    }

    for roll in L{ self.roll1, self.roll2 }:it() do
        gambit_settings.Gambits = gambit_settings.Gambits + L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(HasBuffCondition.new('Double-Up Chance'), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new('Snake Eye') }), GambitTarget.TargetType.Self),
                HasRollCondition.new(roll:get_roll_name(), self.job:get_lucky_roll(roll:get_roll_name()) - 1, Condition.Operator.Equals)
            }, JobAbility.new('Snake Eye'), Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new(roll:get_roll_name()) }), GambitTarget.TargetType.Self),
            }, JobAbility.new(roll:get_roll_name()), Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                HasBuffsCondition.new(L{ roll:get_roll_name(), 'Double-Up Chance' }, 2),
                HasRollCondition.new(roll:get_roll_name(), self.job:get_unlucky_roll(roll:get_roll_name()), Condition.Operator.Equals)
            }, JobAbility.new('Double-Up'), GambitTarget.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                HasBuffsCondition.new(L{ roll:get_roll_name(), 'Double-Up Chance' }, 2),
                NotCondition.new(L{ HasRollCondition.new(roll:get_roll_name(), self.job:get_lucky_roll(roll:get_roll_name()), Condition.Operator.Equals)}),
                HasRollCondition.new(roll:get_roll_name(), self.max_double_up_num, Condition.Operator.LessThanOrEqualTo),
            }, JobAbility.new('Double-Up'), GambitTarget.TargetType.Self),
        }
    end

    roller_gambits = gambit_settings.Gambits

    for gambit in gambit_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    self:set_gambit_settings(gambit_settings)
end

function Roller:get_default_conditions(gambit)
    local conditions = L{
    }

    local ability_conditions = (L{} + self.job:get_conditions_for_ability(gambit:getAbility()))

    return conditions + ability_conditions:map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Roller:get_tracker()
    return self.healer_tracker
end

function Roller:get_roll_num(roll_name)
    if self.roll_settings.Roll1:get_roll_name() == roll_name then
        return self.roll1_current
    end
    if self.roll_settings.Roll2:get_roll_name() == roll_name then
        return self.roll2_current
    end
    return nil
end

function Roller:get_is_rolling()
    return self.is_rolling
end

function Roller:set_is_rolling(is_rolling)
    if self.is_rolling == is_rolling then
        return
    end
    self.is_rolling = is_rolling
    if self.is_rolling then
        self:on_rolls_begin():trigger(self)
    else
        self:on_rolls_end():trigger(self)
    end
end

function Roller:on_roll_used(roll_id, targets)
    self.should_double_up = false

    local roll_num = targets[1].actions[1].param

    local roll = res.job_abilities:with('id', roll_id)
    if roll.en == self.roll1:get_roll_name() or state.AutoRollMode.value == 'Manual' then
        self.roll1_current = roll_num
        if self.job:can_snake_eye() and self.job:should_snake_eye(roll.id, roll_num) then
            self.job:snake_eye()
        else
            self.should_double_up = self.job:should_double_up(roll.id, roll_num)
            if not self.should_double_up then
                self:set_is_rolling(false)
            end
        end
    elseif roll.en == self.roll2:get_roll_name() then
        self.roll2_current = roll_num
        if self.job:can_snake_eye() and self.job:should_snake_eye(roll.id, roll_num) then
            self.job:snake_eye()
        else
            self.should_double_up = self.job:should_double_up(roll.id, roll_num)
            if not self.should_double_up then
                self:set_is_rolling(false)
            end
        end
    end
end

return Roller
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local GambitTarget = require('cylibs/gambits/gambit_target')
local HasRollCondition = require('cylibs/conditions/has_roll')
local PartyMemberCountCondition = require('cylibs/conditions/party_member_count')
local PhantomRoll = require('cylibs/battle/abilities/phantom_roll')
local Sequence = require('cylibs/battle/sequence')
local serializer_util = require('cylibs/util/serializer_util')
local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local IsRollingCondition = setmetatable({}, { __index = Condition })
IsRollingCondition.__index = IsRollingCondition
IsRollingCondition.__type = "IsRollingCondition"
IsRollingCondition.__class = "IsRollingCondition"

function IsRollingCondition.new(roll_name)
    local self = setmetatable(Condition.new(), IsRollingCondition)
    self.roll_name = roll_name
    return self
end

function IsRollingCondition:is_satisfied(_)
    for trust in L{ player.trust.main_job, player.trust.sub_job }:compact_map():it() do
        local roller = trust:role_with_type("roller")
        if roller and roller:get_current_roll_id() then
            local roll = res.job_abilities[roller:get_current_roll_id()]
            return roll and roll.en == self.roll_name
        end
    end
    return false
end

function IsRollingCondition:get_config_items()
    return L{
        PickerConfigItem.new('roll_name', self.roll_name, res.job_abilities:with('type', 'CorsairRoll'):map(function(roll) return roll.en end), function(roll_name)
            return i18n.resource('job_abilities', 'en', roll_name)
        end, "Roll Name"),
    }
end

function IsRollingCondition:tostring()
    return string.format("Is Rolling %s", self.roll_name)
end

function IsRollingCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function IsRollingCondition:serialize()
    return "IsRollingCondition.new(" .. serializer_util.serialize_args(self.roll_name) .. ")"
end

function IsRollingCondition.description()
    return "Is rolling."
end

function IsRollingCondition:__eq(otherItem)
    return otherItem.__class == HasRollCondition.__class
            and self.roll_name == otherItem.roll_name
end

local Gambiter = require('cylibs/trust/roles/gambiter')
local Roller = setmetatable({}, {__index = Gambiter })
Roller.__index = Roller

state.AutoRollMode = M{['description'] = 'Use Phantom Roll', 'Auto', 'Off'}
state.AutoRollMode:set_description('Auto', "Automatically roll until an 11 or lucky roll.")

function Roller:on_rolls_changed()
    return self.rolls_changed
end

-------
-- Default initializer for a nuker role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam T roll_settings Roll settings
-- @treturn Roller A roller role
function Roller.new(action_queue, roll_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.AutoRollMode }), Roller)

    self.job = job
    self.roll_tracker = {}
    self.rolls_changed = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    self:set_roll_settings(roll_settings)

    return self
end

function Roller:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()

    self:on_rolls_changed():removeAllActions()
end

function Roller:on_add()
    Gambiter.on_add(self)

    self.dispose_bag:add(self:on_active_changed():addAction(function(_, is_rolling)
        if not is_rolling then
            self:check_gambits(nil, nil, true)
        end
    end), self:on_active_changed())

    self.dispose_bag:add(self:get_player():on_job_ability_used():addAction(
        function(_, job_ability_id, targets)
            if self.job:is_roll(job_ability_id) then
                coroutine.schedule(function()
                    self:on_roll_used(job_ability_id, targets)
                end, 1)
            end
        end), self:get_player():on_job_ability_used())

    self.dispose_bag:add(self:get_party():get_player():on_lose_buff():addAction(function(_, buff_id)
        if buff_id == 308 then
            self.current_roll_id = nil
        end
        self:validate_rolls()

        self:on_rolls_changed():trigger(self.roll1:get_roll_name(), self.roll_tracker[self.roll1:get_roll_id()], self.roll2:get_roll_name(), self.roll_tracker[self.roll2:get_roll_id()])
    end), self:get_party():get_player():on_lose_buff())
end

function Roller:get_cooldown()
    return 4
end

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
-- Sets the roll settings.
-- @tparam T roll_settings Roll settings
function Roller:set_roll_settings(roll_settings)
    self.roll_settings = roll_settings
    self.roll1 = roll_settings.Roll1
    self.roll2 = roll_settings.Roll2
    self.max_double_up_num = roll_settings.DoubleUpThreshold
    self.num_party_members_nearby = roll_settings.NumRequiredPartyMembers
    self.prioritize_elevens = roll_settings.PrioritizeElevens
    self.max_bust_count = self.job:isMainJob() and 2 or 1

    self:validate_rolls()

    self:on_rolls_changed():trigger(self.roll1:get_roll_name(), self.roll_tracker[self.roll1:get_roll_id()], self.roll2:get_roll_name(), self.roll_tracker[self.roll2:get_roll_id()])

    local gambit_settings = {
        Gambits = L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(HasBuffCondition.new('Bust'), GambitTarget.TargetType.Self),
            }, JobAbility.new('Fold'), Condition.TargetType.Self),
        },
    }

    local rolls = self.job:isMainJob() and L{ self.roll1, self.roll2 } or L{ self.roll1 }
    for roll in rolls:it() do
        local rollGambits = L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(IsRollingCondition.new(roll:get_roll_name()), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasRollCondition.new(roll:get_roll_name(), self.job:get_lucky_roll(roll:get_roll_name()), Condition.Operator.Equals)}), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasRollCondition.new(roll:get_roll_name(), 11, Condition.Operator.Equals)}), GambitTarget.TargetType.Self),
                GambitCondition.new(HasBuffCondition.new('Snake Eye'), GambitTarget.TargetType.Self),
            }, JobAbility.new('Double-Up'), Condition.TargetType.Self),
        }

        -- Snake Eye
        for rollNum in L{ self.job:get_lucky_roll(roll:get_roll_name()) - 1, 10 }:it() do
            rollGambits:append(
                Gambit.new(GambitTarget.TargetType.Self, L {
                    GambitCondition.new(IsRollingCondition.new(roll:get_roll_name()), GambitTarget.TargetType.Self),
                    GambitCondition.new(HasBuffCondition.new('Double-Up Chance'), GambitTarget.TargetType.Self),
                    GambitCondition.new(NotCondition.new(L { HasBuffCondition.new('Snake Eye') }), GambitTarget.TargetType.Self),
                    GambitCondition.new(HasRollCondition.new(roll:get_roll_name(), rollNum, Condition.Operator.Equals), GambitTarget.TargetType.Self),
                }, Sequence.new(L{ JobAbility.new('Snake Eye'), JobAbility.new('Double-Up') }), Condition.TargetType.Self)
            )
        end

        -- Crooked Cards + Phantom Roll
        if roll:should_use_crooked_cards() then
            rollGambits:append(
                Gambit.new(GambitTarget.TargetType.Self, L{
                    GambitCondition.new(HasBuffsCondition.count(L{ 'Crooked Cards', roll:get_roll_name() }, 0, Condition.Operator.Equals), GambitTarget.TargetType.Self),
                }, Sequence.new(L{
                    JobAbility.new('Crooked Cards'),
                    PhantomRoll.new(roll:get_roll_name()),
                }), Condition.TargetType.Self)
            )
        end

        rollGambits = rollGambits + L{
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(NotCondition.new(L{ HasBuffCondition.new(roll:get_roll_name()) }), GambitTarget.TargetType.Self),
            }, PhantomRoll.new(roll:get_roll_name()), Condition.TargetType.Self),
            Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(HasBuffsCondition.new(L{ roll:get_roll_name(), 'Double-Up Chance' }, 2), GambitTarget.TargetType.Self),
                GambitCondition.new(HasRollCondition.new(roll:get_roll_name(), self.job:get_unlucky_roll(roll:get_roll_name()), Condition.Operator.Equals), GambitTarget.TargetType.Self),
            }, Sequence.new(L{ JobAbility.new('Snake Eye'), JobAbility.new('Double-Up') }) , GambitTarget.TargetType.Self),
        }
        if self.job:isMainJob() and self.prioritize_elevens then
            rollGambits:append(Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(IsRollingCondition.new(roll:get_roll_name()), GambitTarget.TargetType.Self),
                GambitCondition.new(HasBuffsCondition.new(L{ roll:get_roll_name(), 'Double-Up Chance' }, 2), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasRollCondition.new(roll:get_roll_name(), self.job:get_lucky_roll(roll:get_roll_name()), Condition.Operator.Equals)}), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasRollCondition.new(roll:get_roll_name(), 11, Condition.Operator.Equals)}), GambitTarget.TargetType.Self),
                GambitCondition.new(ConditionalCondition.new(L{
                    HasRollCondition.new(roll:get_roll_name(), self.max_double_up_num, Condition.Operator.LessThanOrEqualTo),
                    HasRollCondition.new(rolls:firstWhere(function(r) return r:get_roll_name() ~= roll:get_roll_name() end):get_roll_name(), 11, Condition.Operator.Equals),
                }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Self),
            }, JobAbility.new('Double-Up'), GambitTarget.TargetType.Self))
        else
            rollGambits:append(Gambit.new(GambitTarget.TargetType.Self, L{
                GambitCondition.new(IsRollingCondition.new(roll:get_roll_name()), GambitTarget.TargetType.Self),
                GambitCondition.new(HasBuffsCondition.new(L{ roll:get_roll_name(), 'Double-Up Chance' }, 2), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasRollCondition.new(roll:get_roll_name(), self.job:get_lucky_roll(roll:get_roll_name()), Condition.Operator.Equals)}), GambitTarget.TargetType.Self),
                GambitCondition.new(NotCondition.new(L{ HasRollCondition.new(roll:get_roll_name(), 11, Condition.Operator.Equals)}), GambitTarget.TargetType.Self),
                GambitCondition.new(HasRollCondition.new(roll:get_roll_name(), self.max_double_up_num, Condition.Operator.LessThanOrEqualTo), GambitTarget.TargetType.Self),
            }, JobAbility.new('Double-Up'), GambitTarget.TargetType.Self))
        end

        gambit_settings.Gambits = gambit_settings.Gambits + rollGambits
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
        PartyMemberCountCondition.new(self.num_party_members_nearby or 1, Condition.Operator.GreaterThanOrEqualTo, 16)
    }

    local ability_conditions = (L{} + self.job:get_conditions_for_ability(gambit:getAbility()))

    return conditions + ability_conditions:map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Roller:on_roll_used(roll_id, targets)
    self.current_roll_id = roll_id

    local roll_num = targets[1].actions[1].param
    self.last_roll_num = roll_num

    self.roll_tracker[roll_id] = roll_num

    self:validate_rolls()

    self:on_rolls_changed():trigger(self.roll1:get_roll_name(), self.roll_tracker[self.roll1:get_roll_id()], self.roll2:get_roll_name(), self.roll_tracker[self.roll2:get_roll_id()])
end

function Roller:get_roll_num(roll_name)
    local roll = res.job_abilities:with('en', roll_name)
    if roll then
        return self.roll_tracker[roll.id]
    end
    return nil
end

function Roller:validate_rolls()
    for roll_id, _ in pairs(self.roll_tracker) do
        if not self:get_party():get_player():has_buff(res.job_abilities[roll_id].status) then
            self.roll_tracker[roll_id] = 0
        end
    end
end

function Roller:get_current_roll_id()
    return self.current_roll_id
end

return Roller
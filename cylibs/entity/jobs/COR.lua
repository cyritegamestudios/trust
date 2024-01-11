---------------------------
-- Job file for Corsair.
-- @class module
-- @name Corsair

local JobAbilityAction = require('cylibs/actions/job_ability')
local job_util = require('cylibs/util/job_util')
local buff_util = require('cylibs/util/buff_util')
local SequenceAction = require('cylibs/actions/sequence')
local WaitAction = require('cylibs/actions/wait')

local Job = require('cylibs/entity/jobs/job')
local Corsair = setmetatable({}, {__index = Job })
Corsair.__index = Corsair

local rolls = {}
rolls["Corsair's Roll"] = {}
rolls["Corsair's Roll"].Lucky = 5
rolls["Corsair's Roll"].Unlucky = 9
rolls["Ninja's Roll"] = {}
rolls["Ninja's Roll"].Lucky = 4
rolls["Ninja's Roll"].Unlucky = 8
rolls["Hunter's Roll"] = {}
rolls["Hunter's Roll"].Lucky = 4
rolls["Hunter's Roll"].Unlucky = 8
rolls["Chaos Roll"] = {}
rolls["Chaos Roll"].Lucky = 4
rolls["Chaos Roll"].Unlucky = 8
rolls["Magus's Roll"] = {}
rolls["Magus's Roll"].Lucky = 2
rolls["Magus's Roll"].Unlucky = 6
rolls["Healer's Roll"] = {}
rolls["Healer's Roll"].Lucky = 3
rolls["Healer's Roll"].Unlucky = 7
rolls["Drachen Roll"] = {}
rolls["Drachen Roll"].Lucky = 4
rolls["Drachen Roll"].Unlucky = 8
rolls["Choral Roll"] = {}
rolls["Choral Roll"].Lucky = 2
rolls["Choral Roll"].Unlucky = 6
rolls["Monk's Roll"] = {}
rolls["Monk's Roll"].Lucky = 3
rolls["Monk's Roll"].Unlucky = 7
rolls["Beast Roll"] = {}
rolls["Beast Roll"].Lucky = 4
rolls["Beast Roll"].Unlucky = 8
rolls["Samurai Roll"] = {}
rolls["Samurai Roll"].Lucky = 2
rolls["Samurai Roll"].Unlucky = 6
rolls["Evoker's Roll"] = {}
rolls["Evoker's Roll"].Lucky = 5
rolls["Evoker's Roll"].Unlucky = 9
rolls["Rogue's Roll"] = {}
rolls["Rogue's Roll"].Lucky = 5
rolls["Rogue's Roll"].Unlucky = 9
rolls["Warlock's Roll"] = {}
rolls["Warlock's Roll"].Lucky = 4
rolls["Warlock's Roll"].Unlucky = 8
rolls["Fighter's Roll"] = {}
rolls["Fighter's Roll"].Lucky = 5
rolls["Fighter's Roll"].Unlucky = 9
rolls["Puppet Roll"] = {}
rolls["Puppet Roll"].Lucky = 3
rolls["Puppet Roll"].Unlucky = 7
rolls["Gallant's Roll"] = {}
rolls["Gallant's Roll"].Lucky = 3
rolls["Gallant's Roll"].Unlucky = 7
rolls["Wizard's Roll"] = {}
rolls["Wizard's Roll"].Lucky = 5
rolls["Wizard's Roll"].Unlucky = 9
rolls["Dancer's Roll"] = {}
rolls["Dancer's Roll"].Lucky = 3
rolls["Dancer's Roll"].Unlucky = 7
rolls["Scholar's Roll"] = {}
rolls["Scholar's Roll"].Lucky = 2
rolls["Scholar's Roll"].Unlucky = 6
rolls["Naturalist's Roll"] = {}
rolls["Naturalist's Roll"].Lucky = 3
rolls["Naturalist's Roll"].Unlucky = 7
rolls["Runeist's Roll"] = {}
rolls["Runeist's Roll"].Lucky = 4
rolls["Runeist's Roll"].Unlucky = 8
rolls["Bolter's Roll"] = {}
rolls["Bolter's Roll"].Lucky = 3
rolls["Bolter's Roll"].Unlucky = 9
rolls["Caster's Roll"] = {}
rolls["Caster's Roll"].Lucky = 2
rolls["Caster's Roll"].Unlucky = 7
rolls["Courser's Roll"] = {}
rolls["Courser's Roll"].Lucky = 3
rolls["Courser's Roll"].Unlucky = 9
rolls["Blitzer's Roll"] = {}
rolls["Blitzer's Roll"].Lucky = 4
rolls["Blitzer's Roll"].Unlucky = 9
rolls["Tactician's Roll"] = {}
rolls["Tactician's Roll"].Lucky = 5
rolls["Tactician's Roll"].Unlucky = 8
rolls["Allies' Roll"] = {}
rolls["Allies' Roll"].Lucky = 3
rolls["Allies' Roll"].Unlucky = 10
rolls["Miser's Roll"] = {}
rolls["Miser's Roll"].Lucky = 5
rolls["Miser's Roll"].Unlucky = 7
rolls["Companion's Roll"] = {}
rolls["Companion's Roll"].Lucky = 2
rolls["Companion's Roll"].Unlucky = 10
rolls["Avenger's Roll"] = {}
rolls["Avenger's Roll"].Lucky = 4
rolls["Avenger's Roll"].Unlucky = 8

-------
-- Default initializer for a new Corsair.
-- @treturn COR A Corsair
function Corsair.new(action_queue)
    local self = setmetatable(Job.new(), Corsair)
    self.action_queue = action_queue
    return self
end

-------
-- Returns whether a job ablility is a roll
-- @tparam number job_ability_id Job ability id (see job_abilities.lua)
-- @treturn Boolean True if the job ability is a roll
function Corsair:is_roll(job_ability_id)
    local roll = res.job_abilities:with('id', job_ability_id)
    return roll ~= nil and rolls[roll.en] ~= nil
end

-------
-- Returns whether a roll is a lucky roll.
-- @tparam number roll_id Job ability id (see job_abilities.lua)
-- @tparam number roll_num Roll number
-- @treturn Boolean True if the roll is a lucky roll
function Corsair:is_lucky_roll(roll_id, roll_num)
    local roll = res.job_abilities:with('id', roll_id)
    if roll and rolls[roll.en] then
        return roll_num == rolls[roll.en].Lucky
    end
    return false
end

-------
-- Returns whether a roll is an unlucky roll.
-- @tparam number roll_id Job ability id (see job_abilities.lua)
-- @tparam number roll_num Roll number
-- @treturn Boolean True if the roll is a lucky roll
function Corsair:is_unlucky_roll(roll_id, roll_num)
    local roll = res.job_abilities:with('id', roll_id)
    if roll and rolls[roll.en] then
        return roll_num == rolls[roll.en].Unlucky
    end
    return false
end

-------
-- Returns true if double up can be used.
-- @treturn Boolean True if double up can be used
function Corsair:can_double_up()
    return buff_util.is_buff_active(308)
end

-------
-- Returns whether a the roll should be doubled up.
-- @tparam number roll_id Job ability id (see job_abilities.lua)
-- @tparam number roll_num Roll number
-- @treturn Boolean True if the roll should be doubled up
function Corsair:should_double_up(roll_id, roll_num)
    if roll_num == 11 then
        return false
    end
    if self:is_snake_eye_active() then
        return true
    end
    if self:is_lucky_roll(roll_id, roll_num) then
        return false
    end
    if self:is_unlucky_roll(roll_id, roll_num) then
        return true
    end
    if roll_num > 5 and not self:can_fold() then
        return false
    end
    return true
end

function Corsair:can_fold()
    return job_util.knows_job_ability(job_util.job_ability_id('Fold')) == true
        and job_util.can_use_job_ability('Fold')
end

-------
-- Doubles up, if double up can be used
function Corsair:double_up()
    if self:can_double_up() then
        local double_up_action = SequenceAction.new(L{
            JobAbilityAction.new(0, 0, 0, 'Double-Up'),
            WaitAction.new(0, 0, 0, 1)
        }, 'double_up')
        double_up_action.priority = ActionPriority.High
        self.action_queue:push_action(double_up_action, true)
    end
end

-------
-- Returns true if snake eye is active.
-- @treturn Boolean True if snake eye is active
function Corsair:is_snake_eye_active()
    return buff_util.is_buff_active(357)
end

-------
-- Returns true if snake eye can be used.
-- @treturn Boolean True if snake eye can be used
function Corsair:can_snake_eye()
    return job_util.knows_job_ability(job_util.job_ability_id('Snake Eye')) == true
            and job_util.can_use_job_ability('Snake Eye')
end

-------
-- Returns whether snake eye should be used.
-- @tparam number roll_id Job ability id (see job_abilities.lua)
-- @tparam number roll_num Roll number
-- @treturn Boolean True if snake eye should be used
function Corsair:should_snake_eye(roll_id, roll_num)
    if self:is_lucky_roll(roll_id, roll_num) then
        return false
    end
    if self:is_lucky_roll(roll_id, roll_num + 1) then
        return true
    end
    if self:is_unlucky_roll(roll_id, roll_num) then
        return true
    end
    if roll_num == 10 then
        return true
    end
    return false
end

-------
-- Uses snake eye, if snake eye can be used.
function Corsair:snake_eye()
    if self:can_snake_eye() then
        local snake_eye_action = SequenceAction.new(L{
            JobAbilityAction.new(0, 0, 0, 'Snake Eye'),
            WaitAction.new(0, 0, 0, 1)
        }, 'snake_eye')
        snake_eye_action.priority = ActionPriority.High
        self.action_queue:push_action(snake_eye_action, true)
    end
end

-------
-- Returns true if crooked cards can be used.
-- @treturn Boolean True if crooked cards can be used
function Corsair:can_crooked_cards()
    return job_util.knows_job_ability(job_util.job_ability_id('Crooked Cards')) == true
            and job_util.can_use_job_ability('Crooked Cards') and not buff_util.is_buff_active(buff_util.buff_id('Crooked Cards'))
end

-------
-- Uses crooked cards, if crooked cards can be used.
function Corsair:crooked_cards()
    if self:can_crooked_cards() then
        local crooked_cards_action = SequenceAction.new(L{
            JobAbilityAction.new(0, 0, 0, 'Crooked Cards'),
            WaitAction.new(0, 0, 0, 1)
        }, 'crooked_cards')
        crooked_cards_action.priority = ActionPriority.High
        self.action_queue:push_action(crooked_cards_action, true)
    end
end

-------
-- Returns whether bust is active.
-- @treturn Boolean True if bust is active
function Corsair:busted()
    return buff_util.is_buff_active(buff_util.buff_id('Bust'))
end

-------
-- Uses fold, if bust is active and fold can be used.
function Corsair:fold()
    if self:busted() then
        local fold_action = SequenceAction.new(L{
            JobAbilityAction.new(0, 0, 0, 'Fold'),
            WaitAction.new(0, 0, 0, 1)
        }, 'fold')
        fold_action.priority = ActionPriority.High
        self.action_queue:push_action(fold_action, true)
    end
end

-------
-- Returns whether a roll is active.
-- @tparam number roll_id Job ability id (see job_abilities.lua)
-- @treturn Boolean True if the given roll is active
function Corsair:has_roll(roll_id)
    local roll = res.job_abilities:with('id', roll_id)
    if roll and roll.status and buff_util.is_buff_active(roll.status) then
        return true
    end
    return false
end

-------
-- Returns whether phantom roll can be used.
-- @treturn Boolean True if the given roll is active
function Corsair:can_roll()
    return job_util.can_use_job_ability('Phantom Roll')
end

-------
-- Uses a roll, optionally using crooked cards first.
-- @tparam Boolean should_use_crooked_cards Whether crooked cards should be used first
-- @tparam number roll_id Job ability id (see job_abilities.lua)
function Corsair:roll(roll_id, should_use_crooked_cards)
    local roll = res.job_abilities:with('id', roll_id)
    if roll and job_util.can_use_job_ability('Phantom Roll') then
        local actions = L{}
        if should_use_crooked_cards and self:can_crooked_cards() then
            actions:append(JobAbilityAction.new(0, 0, 0, 'Crooked Cards'))
            actions:append(WaitAction.new(0, 0, 0, 1.5))
        end
        actions:append(JobAbilityAction.new(0, 0, 0, roll.en))
        actions:append(WaitAction.new(0, 0, 0, 1))

        local roll_action = SequenceAction.new(actions, 'roll')
        roll_action.priority = ActionPriority.High
        self.action_queue:push_action(roll_action, true)
    end
end

return Corsair
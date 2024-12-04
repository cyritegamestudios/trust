local buff_util = require('cylibs/util/buff_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local party_util = require('cylibs/util/party_util')
local job_util = require('cylibs/util/job_util')
local monster_util = require('cylibs/util/monster_util')
local JobAbilityAction = require('cylibs/actions/job_ability')
local StrategemAction = require('cylibs/actions/strategem')
local WaitAction = require('cylibs/actions/wait')
local SequenceAction = require('cylibs/actions/sequence')
local SpellAction = require('cylibs/actions/spell')

local Dispeler = setmetatable({}, {__index = Role })
Dispeler.__index = Dispeler

state.AutoDispelMode = M{['description'] = 'Dispel Enemies', 'Auto', 'Off'}
state.AutoDispelMode:set_description('Auto', "Okay, I'll try to dispel monster buffs.")

-------
-- Default initializer for a dispeler role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam List spells List of Spell that can dispel
-- @tparam List job_abilities List of JobAbility that can dispel
-- @tparam boolean should_retry If true, will attempt to retry dispel on tic
-- @treturn Dispeler A dispeler role
function Dispeler.new(action_queue, spells, job_abilities, should_retry)
    local self = setmetatable(Role.new(action_queue), Dispeler)

    self.spells = (spells or L{}):map(function(spell)
        spell:get_conditions():append(SpellRecastReadyCondition.new(spell:get_spell().id))
        return spell
    end)

    self.job_abilities = (job_abilities or L{}):map(function(job_ability)
        job_ability:add_condition(JobAbilityRecastReadyCondition.new(job_ability:get_job_ability_name()))
        return job_ability
    end)

    self.should_retry = should_retry
    self.check_buffs_cooldown = 6
    self.last_check_buffs_time = os.time()
    self.battle_target_dispose_bag = DisposeBag.new()

    return self
end

function Dispeler:destroy()
    Role.destroy(self)

    self.battle_target_dispose_bag:destroy()
end

function Dispeler:on_add()
    Role.on_add(self)
end

function Dispeler:target_change(target_index)
    Role.target_change(self, target_index)

    self.battle_target_dispose_bag:destroy()

    if target_index then
        self.battle_target = self:get_party():get_target(monster_util.id_for_index(target_index))
        if self.battle_target then
            self.battle_target_dispose_bag:add(self.battle_target:on_gain_buff():addAction(
                    function (_, target_index, _)
                        if state.AutoDispelMode.value ~= 'Off' then
                            self.last_check_buffs_time = os.time()
                            self:dispel(target_index)
                        end
                    end), self.battle_target:on_gain_buff())
        end
    end
end

function Dispeler:tic(_, _)
    if state.AutoDispelMode.value == 'Off' or not self.should_retry
            or (os.time() - self.last_check_buffs_time) < self.check_buffs_cooldown
            or self.battle_target == nil or self.battle_target:get_mob() == nil then
        return
    end
    self.last_check_buffs_time = os.time()

    self:check_buffs()
end

function Dispeler:check_buffs()
    logger.notice("Checking", self.battle_target:get_name(), "for buffs")

    local buff_ids = self.battle_target:get_buff_ids()
    if buff_ids:length() > 0 then
        self:dispel(self.battle_target:get_mob().index)
    end
end

function Dispeler:dispel(target_index)
    logger.notice("Dispelling", self.battle_target:get_name())

    if not self.battle_target:is_claimed_by(self:get_alliance()) then
        return
    end

    local check_conditions = function(conditions, target_index)
        for condition in conditions:it() do
            if not condition:is_satisfied(condition:get_target_index() or target_index) then
                return false
            end
        end
        return true
    end

    -- Spells
    for spell in self.spells:it() do
        if check_conditions(spell:get_conditions(), target_index) and self.battle_target:get_resist_tracker():numResists(spell:get_spell().id) < 3 then
            self:cast_spell(spell, target_index)
            return
        end
    end

    -- Job abilities
    for job_ability in self.job_abilities:it() do
        if check_conditions(job_ability:get_conditions(), target_index) then
            local target = job_ability:get_target()
            if target then
                target_index = target.index
            end
            self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, job_ability:get_job_ability_name(), target_index), true)
            return
        end
    end
end

function Dispeler:cast_spell(spell, target_index)
    local actions = L{ WaitAction.new(0, 0, 0, 1.5) }

    local can_cast_spell = true
    for job_ability_name in spell:get_job_abilities():it() do
        local job_ability = res.job_abilities:with('en', job_ability_name)
        if can_cast_spell and job_ability and not buff_util.is_buff_active(job_ability.status) then
            if job_ability.type == 'Scholar' then
                actions:append(StrategemAction.new(job_ability_name))
                actions:append(WaitAction.new(0, 0, 0, 1))
            else
                if not job_util.can_use_job_ability(job_ability_name) then
                    can_cast_spell = false
                else
                    actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
                    actions:append(WaitAction.new(0, 0, 0, 1))
                end
            end
        end
    end
    if can_cast_spell then
        self.last_buff_time = os.time()

        actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, target_index, self:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 2))

        local dispel_action = SequenceAction.new(actions, 'dispeler'..spell:get_spell().en)
        dispel_action.priority = ActionPriority.high

        self.action_queue:push_action(dispel_action, true)

        return
    end
end

function Dispeler:get_type()
    return "dispeler"
end

return Dispeler
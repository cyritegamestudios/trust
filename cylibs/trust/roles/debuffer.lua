local DisposeBag = require('cylibs/events/dispose_bag')
local buff_util = require('cylibs/util/buff_util')
local spell_util = require('cylibs/util/spell_util')

local Debuffer = setmetatable({}, {__index = Role })
Debuffer.__index = Debuffer
Debuffer.__class = "Debuffer"

state.AutoDebuffMode = M{['description'] = 'Debuff Enemies', 'Off', 'Auto'}
state.AutoDebuffMode:set_description('Auto', "Okay, I'll debuff the monster.")

state.AutoSilenceMode = M{['description'] = 'Silence Casters', 'Off', 'Auto'}
state.AutoSilenceMode:set_description('Auto', "Okay, I'll try to silence monsters that cast spells.")

function Debuffer.new(action_queue, debuff_spells)
    local self = setmetatable(Role.new(action_queue), Debuffer)

    self:set_debuff_spells(debuff_spells)

    self.dispose_bag = DisposeBag.new()
    self.last_debuff_time = os.time()

    return self
end

function Debuffer:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Debuffer:on_add()
    Role.on_add(self)
end

function Debuffer:target_change(target_index)
    Role.target_change(self, target_index)

    logger.notice(self.__class, 'target_change', target_index)

    self.dispose_bag:dispose()

    if self:get_target() then
        self.last_debuff_time = os.time()

        self.dispose_bag:add(self:get_target():on_spell_finish():addAction(
            function (m, target_index, spell_id)
                if self.target_index then
                    local spell = res.spells:with('id', spell_id)
                    if spell then
                        if state.AutoSilenceMode.value ~= 'Off' then
                            self:cast_spell(Spell.new('Silence'), self.target_index)
                        end
                    end
                end
            end), self:get_target():on_spell_finish())
    end
end

function Debuffer:tic(_, _)
    if self:get_player():is_moving() then
        return
    end

    self:check_debuffs()
end

function Debuffer:conditions_check(spell, target)
    if target == nil then
        return false
    end
    for condition in (spell:get_conditions() + L{ NumResistsCondition.new(spell:get_name(), Condition.Operator.LessThan, 4) }):it() do
        if not condition:is_satisfied(target:get_mob().index) then
            return false
        end
    end
    return true
end

function Debuffer:check_debuffs()
    if state.AutoDebuffMode.value == 'Off' or (os.time() - self.last_debuff_time) < 8 then
        return
    end

    local battle_target = self:get_target()
    if battle_target and battle_target:is_claimed_by(self:get_alliance()) then
        logger.notice(self.__class, 'check_debuffs', battle_target:get_name())
        for spell in self.debuff_spells:it() do
            local debuff = buff_util.debuff_for_spell(spell:get_spell().id)
            if debuff and spell:isEnabled() and not battle_target:has_debuff(debuff.id) and not battle_target:get_resist_tracker():isImmune(spell:get_spell().id)
                    and self:conditions_check(spell, battle_target) then
                if self:cast_spell(spell, battle_target:get_mob().index) then
                    return
                end
            end
        end
    end
end

function Debuffer:cast_spell(spell, target_index)
    local can_cast_spell = false
    if spell_util.can_cast_spell(spell:get_spell().id) then
        logger.notice(self.__class, 'cast_spell', spell:get_spell().en, target_index)

        local actions = L{}

        can_cast_spell = true
        for job_ability_name in spell:get_job_abilities():it() do
            local job_ability = res.job_abilities:with('en', job_ability_name)
            if job_ability and not buff_util.is_buff_active(job_ability.status) then
                if job_ability.type == 'Scholar' then
                    if player_util.get_current_strategem_count() >= spell:get_job_abilities():length() then
                        actions:append(StrategemAction.new(job_ability_name))
                        actions:append(WaitAction.new(0, 0, 0, 1))
                    else
                        can_cast_spell = false
                    end
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
            self.last_debuff_time = os.time()

            actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, target_index, self:get_player()))
            actions:append(WaitAction.new(0, 0, 0, 2))

            local debuff_action = SequenceAction.new(actions, 'debuffer_'..spell:get_spell().en)
            debuff_action.priority = ActionPriority.low

            self.action_queue:push_action(debuff_action, true)
        end
    end
    return can_cast_spell
end

function Debuffer:set_debuff_spells(debuff_spells)
    self.debuff_spells = (debuff_spells or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
end

function Debuffer:get_debuff_spells()
    return self.debuff_spells
end

function Debuffer:allows_duplicates()
    return true
end

function Debuffer:get_type()
    return "debuffer"
end

function Debuffer:tostring()
    local result = ""

    result = result.."Spells:\n"
    if self.debuff_spells:length() > 0 then
        for spell in self.debuff_spells:it() do
            result = result..'• '..spell:description()..'\n'
        end
    else
        result = result..'N/A'..'\n'
    end

    return result
end

return Debuffer
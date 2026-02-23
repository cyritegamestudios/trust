local GambitTarget = require('cylibs/gambits/gambit_target')
local HasAlterEgoCondition = require('cylibs/conditions/has_alter_ego')
local HasKeyItemsCondition = require('cylibs/conditions/has_key_items')
local PartyLeaderCondition = require('cylibs/conditions/party_leader')
local PartyMemberCountCondition = require('cylibs/conditions/party_member_count')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Truster = setmetatable({}, {__index = Gambiter })
Truster.__index = Truster
Truster.__class = "Truster"

state.AutoTrustsMode = M{['description'] = 'Call Alter Egos', 'Off', 'Auto'}
state.AutoTrustsMode:set_description('Auto', "Automatically summon alter egos before pulling.")

function Truster.new(action_queue, trusts)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, state.AutoTrustsMode), Truster)

    self:set_trusts(trusts)

    return self
end

function Truster:get_default_conditions(gambit)
    local conditions = L{
        PartyLeaderCondition.new(),
        PartyMemberCountCondition.new(6, Condition.Operator.LessThan),
        NotCondition.new(L{ HasAlterEgoCondition.new(gambit:getAbility():get_name()) }),
        NotCondition.new(L{ InTownCondition.new() }),
        IdleCondition.new(),
    }:map(function(condition)
        if condition.__type ~= GambitCondition.__type then
            return GambitCondition.new(condition, GambitTarget.TargetType.Self)
        end
        return condition
    end)
    return conditions
end

function Truster:set_trusts(trusts)
    local unknown_trusts = L{}

    local gambits = trusts:map(function(trust_name)
        return Gambit.new(GambitTarget.TargetType.Self, L{}, Spell.new(trust_name), Condition.TargetType.Self, L{"AlterEgo"})
    end)
    for i, gambit in ipairs(gambits) do
        if not spell_util.knows_spell(spell_util.spell_id(gambit:getAbility():get_name())) then
            unknown_trusts:append(gambit:getAbility():get_name())
        end
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        if i > 4 then
            conditions:append(GambitCondition.new(HasKeyItemsCondition.new(L{ "\"Rhapsody in Crimson\"" }, 1, Condition.Operator.Equals), GambitTarget.TargetType.Self))
        elseif i > 3 then
            conditions:append(GambitCondition.new(HasKeyItemsCondition.new(L{ "\"Rhapsody in White\"" }, 1, Condition.Operator.Equals), GambitTarget.TargetType.Self))
        end
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    if unknown_trusts:length() > 0 then
        addon_system_error(string.format("Unknown alter egos: %s. Pulling will be disabled until you update your alter egos under Settings > Alter Egos.", unknown_trusts:tostring()))
    end

    self:set_gambit_settings({ Gambits = gambits })
end

function Truster:get_trusts()
    return self.trusts
end

function Truster:get_type()
    return "truster"
end

function Truster:get_cooldown()
    return 8
end

function Truster:allows_duplicates()
    return false
end

function Truster:allows_multiple_actions()
    return false
end

function Truster:get_max_num_alter_egos()
    if Condition.check_conditions(L{ HasKeyItemsCondition.new(L{ "\"Rhapsody in Crimson\"" }, 1, Condition.Operator.Equals) }) then
        return 5
    elseif Condition.check_conditions(L{ HasKeyItemsCondition.new(L{ "\"Rhapsody in White\"" }, 1, Condition.Operator.Equals) }) then
        return 4
    end
    return 3
end

return Truster
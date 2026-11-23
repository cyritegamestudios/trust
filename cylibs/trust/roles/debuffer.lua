local ClaimedCondition = require('cylibs/conditions/claimed')
local GambitTarget = require('cylibs/gambits/gambit_target')
local ImmuneCondition = require('cylibs/conditions/immune')
local MinHitPointsPercentCondition = require('cylibs/conditions/min_hpp')
local CoreAIDebuffHoldCondition = require('cylibs/conditions/core_ai_debuff_hold')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Debuffer = setmetatable({}, {__index = Gambiter })
Debuffer.__index = Debuffer
Debuffer.__class = "Debuffer"

state.AutoDebuffMode = M{['description'] = 'Debuff Enemies', 'Off', 'Auto'}
state.AutoDebuffMode:set_description('Auto', "Automatically debuff a mob.")

state.AutoSilenceMode = M{['description'] = 'Silence Casters', 'Off', 'Auto'}
state.AutoSilenceMode:set_description('Auto', "Automatically silence mobs after they cast a spell.")

function Debuffer.new(action_queue, debuff_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, {}, state.AutoDebuffMode), Debuffer)
    self.job = job
    self:set_debuff_settings(debuff_settings)
    return self
end

function Debuffer:set_debuff_settings(debuff_settings)
    for gambit in debuff_settings.Gambits:it() do
        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition:set_editable(condition.__type == NumResistsCondition.__type)
            gambit:addCondition(condition)
        end
    end
    self:set_gambit_settings(debuff_settings)
end

function Debuffer:get_default_conditions(gambit)
    local conditions = L{
        ClaimedCondition.new(),
        NotCondition.new(L{ HasDebuffCondition.new(gambit:getAbility():get_status().en) }),
        NotCondition.new(L{ ImmuneCondition.new(gambit:getAbility():get_name()) }),
        NumResistsCondition.new(gambit:getAbility():get_name(), Condition.Operator.LessThan, 4),
        -- Do not waste a debuff cast on a mob that is about to
        -- die; a 2s Requiem on a mob at 5% HP lands just as
        -- melee finishes it.
        MinHitPointsPercentCondition.new(5),
    }
    -- CoreAI debuff hold: every debuff waits while the player's TP
    -- is at or above the debuff_hold module's threshold (500),
    -- until the weaponskill has been used. Set by the debuff_hold
    -- extension module; satisfied otherwise.
    conditions:append(CoreAIDebuffHoldCondition.new())
    return conditions + self.job:get_conditions_for_ability(gambit:getAbility()):map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

function Debuffer:allows_duplicates()
    return true
end

function Debuffer:get_type()
    return "debuffer"
end

function Debuffer:get_cooldown()
    return 6
end

function Debuffer:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

return Debuffer
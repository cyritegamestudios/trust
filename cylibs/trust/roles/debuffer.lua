local ClaimedCondition = require('cylibs/conditions/claimed')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local ImmuneCondition = require('cylibs/conditions/immune')
local spell_util = require('cylibs/util/spell_util')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Debuffer = setmetatable({}, {__index = Gambiter })
Debuffer.__index = Debuffer
Debuffer.__class = "Debuffer"

state.AutoDebuffMode = M{['description'] = 'Debuff Enemies', 'Off', 'Auto'}
state.AutoDebuffMode:set_description('Auto', "Okay, I'll debuff the monster.")

state.AutoSilenceMode = M{['description'] = 'Silence Casters', 'Off', 'Auto'}
state.AutoSilenceMode:set_description('Auto', "Okay, I'll try to silence monsters that cast spells.")

function Debuffer.new(action_queue, debuff_settings)
    local self = setmetatable(Gambiter.new(action_queue, {}, nil, state.AutoDebuffMode, true), Debuffer)

    self:set_debuff_settings(debuff_settings)

    self.last_debuff_time = os.time()

    return self
end

function Debuffer:set_debuff_settings(debuff_settings)
    for gambit in debuff_settings.Gambits:it() do
        local conditions = L{
            --SpellRecastReadyCondition.new(gambit:getAbility():get_spell().id),
            ClaimedCondition.new(),
            NotCondition.new(L{ HasDebuffCondition.new(gambit:getAbility():get_status().en) }),
            NotCondition.new(L{ ImmuneCondition.new(gambit:getAbility():get_name()) }),
            NumResistsCondition.new(gambit:getAbility():get_name(), Condition.Operator.LessThan, 4),
        }
        for condition in conditions:it() do
            gambit:addCondition(condition)
        end
    end


    --[[local debuff_spells = (debuff_spells or L{}):filter(function(gambit)
        return gambit:getAbility() ~= nil and spell_util.knows_spell(gambit:getAbility():get_spell().id) and gambit:getAbility():get_status() ~= nil
    end)
    local gambit_settings = {
        Gambits = debuff_spells:map(function(gambit)
            local conditions = L{
                SpellRecastReadyCondition.new(gambit:getAbility():get_spell().id),
                ClaimedCondition.new(),
                NotCondition.new(L{ HasDebuffCondition.new(gambit:getAbility():get_status().en) }),
                NotCondition.new(L{ ImmuneCondition.new(gambit:getAbility():get_name()) }),
                NumResistsCondition.new(gambit:getAbility():get_name(), Condition.Operator.LessThan, 4),
            }
            return Gambit.new(GambitTarget.TargetType.Enemy, conditions, gambit:getAbility(), "Enemy")
        end)
    }]]
    self:set_gambit_settings(debuff_settings)
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
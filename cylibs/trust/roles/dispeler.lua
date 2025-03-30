local action_message_util = require('cylibs/util/action_message_util')
local ClaimedCondition = require('cylibs/conditions/claimed')
local DisposeBag = require('cylibs/events/dispose_bag')
local GambitTarget = require('cylibs/gambits/gambit_target')
local monster_abilities_ext = require('cylibs/res/monster_abilities')
local NumBuffsCondition = require('cylibs/conditions/num_buffs')

local Gambiter = require('cylibs/trust/roles/gambiter')
local Dispeler = setmetatable({}, {__index = Gambiter })
Dispeler.__index = Dispeler

state.AutoDispelMode = M{['description'] = 'Dispel Enemies', 'Auto', 'Off'}
state.AutoDispelMode:set_description('Auto', "Dispel buffs on a mob.")

-------
-- Default initializer for a dispeler role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam List spells List of Spell that can dispel
-- @tparam List job_abilities List of JobAbility that can dispel
-- @tparam boolean should_retry If true, will attempt to retry dispel on tic
-- @treturn Dispeler A dispeler role
function Dispeler.new(action_queue, spells, job_abilities, should_retry)
    local self = setmetatable(Gambiter.new(action_queue, {}, state.AutoDispelMode), Dispeler)

    local gambit_settings = {
        Gambits = (spells + job_abilities):map(function(ability)
            return Gambit.new(GambitTarget.TargetType.Enemy, L{
                NumBuffsCondition.new(1, Condition.Operator.GreaterThanOrEqualTo),
                ClaimedCondition.new()
            }, ability, Condition.TargetType.Enemy)
        end)
    }
    self:set_gambit_settings(gambit_settings)
    self:set_enabled(should_retry)

    self.dispose_bag = DisposeBag.new()

    return self
end

function Dispeler:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function Dispeler:on_add()
    Gambiter.on_add(self)

    self.dispose_bag:add(WindowerEvents.Ability.Finish:addAction(function(target_id, ability_id)
        if self:get_target() == nil or self:get_target():get_id() ~= target_id or not ability_id then
            return
        end
        local ability = monster_abilities_ext[ability_id]
        if ability then
            self:check_gambits(self.gambits)
        end
    end), WindowerEvents.Ability.Finish)

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(act)
        if self:get_target() == nil then
            return
        end
        if act.actor_id == self:get_target():get_id() then
            if action_message_util.is_finish_action_category(act.category) then
                local action = act.targets[1].actions[1]
                if action_message_util.is_monster_gain_buff(action.message, action.param) then
                    self:check_gambits(self.gambits)
                end
            end
        end
    end), WindowerEvents.Action)
end

function Dispeler:get_cooldown()
    return 6
end

function Dispeler:allows_multiple_actions()
    return false
end

function Dispeler:get_type()
    return "dispeler"
end

function Dispeler:allows_duplicates()
    return true
end

return Dispeler
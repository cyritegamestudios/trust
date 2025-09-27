local BlockAction = require('cylibs/actions/block')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local DistanceCondition = require('cylibs/conditions/distance')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IsAssistTargetCondition = require('cylibs/conditions/is_assist_target')
local RunAwayAction = require('cylibs/actions/runaway')
local RunToAction = require('cylibs/actions/runto')
local RunToLocationAction = require('cylibs/actions/runtolocation')
local battle_util = require('cylibs/util/battle_util')
local party_util = require('cylibs/util/party_util')
local player_util = require('cylibs/util/player_util')
local flanking_util = require("cylibs/util/flanking_util")

local Gambiter = require('cylibs/trust/roles/gambiter')
local CombatMode = setmetatable({}, {__index = Gambiter })
CombatMode.__index = CombatMode
CombatMode.__class = "CombatMode"

state.AutoFaceMobMode = M{['description'] = 'Auto Face Mob Mode', 'Auto', 'Away', 'Off'}
state.AutoFaceMobMode:set_description('Auto', "Automatically turn to face the mob.")
state.AutoFaceMobMode:set_description('Away', "Automatically face away from the mob.")

state.CombatMode = M{['description'] = 'Combat Mode', 'Off', 'Auto', 'Mirror'}
state.CombatMode:set_description('Auto', "Maintain a specified distance from the target.")
state.CombatMode:set_description('Mirror', "Mirror the position of the party member you are assisting.")

state.FlankMode = M{['description'] = 'Flanking Mode', 'Off', 'Back', 'Left', 'Right'}
state.FlankMode:set_description('Back', "Stand behind the mob.")
state.FlankMode:set_description('Left', "Stand on the left side of the mob.")
state.FlankMode:set_description('Right', "Stand on the right side of the mob.")

function CombatMode.new(action_queue, combat_settings, addon_enabled)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, L{ state.CombatMode }), CombatMode)

    self.action_queue = action_queue
    self.addon_enabled = addon_enabled

    self:set_combat_settings(combat_settings)

    self.dispose_bag = DisposeBag.new()

    return self
end

function CombatMode:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function CombatMode:on_add()
    Gambiter.on_add(self)

    self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
        -- Unable to see ${target}
        if message_id == 5 then
            self:check_gambits()
        end
    end), WindowerEvents.ActionMessage)

    self.timer:onTimeChange():addAction(function(_)
        if not self:is_enabled() or not self.addon_enabled:getValue()
                or self:get_target() == nil then
            return
        end
        self:face_target(self:get_target():get_mob())
    end, self:get_priority() or ActionPriority.default, self:get_type())
end

function CombatMode:face_target(target)
    if not self.addon_enabled:getValue() then
        return
    end
    -- NOTE: this specifically does not go into the action queue because it occurs too
    -- frequently and would delay other actions.
    if state.AutoFaceMobMode.value == 'Auto' then
        player_util.face(target)
    elseif state.AutoFaceMobMode.value == 'Away' then
        player_util.face_away(target)
    end
end

function CombatMode:allows_duplicates()
    return false
end

function CombatMode:get_type()
    return "combatmode"
end

function CombatMode:set_combat_settings(combat_settings)
    self.distance = combat_settings.Distance
    self.mirror_distance = combat_settings.MirrorDistance

    local gambit_settings = {
        Gambits = L{
            Gambit.new(GambitTarget.TargetType.Ally, L{
                GambitCondition.new(ModeCondition.new('CombatMode', 'Mirror'), GambitTarget.TargetType.Self),
                GambitCondition.new(IsAssistTargetCondition.new(), GambitTarget.TargetType.Ally),
                GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Ally),
                GambitCondition.new(DistanceCondition.new(self.mirror_distance, Condition.Operator.GreaterThan), GambitTarget.TargetType.Ally),
            }, RunTo.new(self.mirror_distance), GambitTarget.TargetType.Enemy),
            Gambit.new(GambitTarget.TargetType.Enemy, L{
                GambitCondition.new(ModeCondition.new('CombatMode', 'Auto'), GambitTarget.TargetType.Self),
                GambitCondition.new(StatusCondition.new('Engaged'), GambitTarget.TargetType.Self),
                GambitCondition.new(ConditionalCondition.new(L{ DistanceCondition.new(self.distance + 0.2, Condition.Operator.GreaterThan), DistanceCondition.new(self.distance - 0.2, Condition.Operator.LessThan) }, Condition.LogicalOperator.Or), GambitTarget.TargetType.Enemy),
            }, RunTo.new(self.distance), GambitTarget.TargetType.Enemy),
        }
    }

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

function CombatMode:get_default_conditions(gambit)
    local conditions = L{
        GambitCondition.new(ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()), GambitTarget.TargetType.Enemy),
    }
    return conditions:map(function(condition)
        if condition.__type ~= GambitCondition.__type then
            return GambitCondition.new(condition, GambitTarget.TargetType.Self)
        end
        return condition
    end)
end

function CombatMode:get_cooldown()
    return 2
end

function CombatMode:allows_multiple_actions()
    return false
end

function CombatMode:get_type()
    return "combatmode"
end

function CombatMode:allows_duplicates()
    return false
end

--[[

if not L{'Off'}:contains(state.FlankMode.value) then
                -- If we have a relative location, use that
                local target_location = flanking_util.get_relative_location_for_target(target.id, flanking_util[state.FlankMode.value], self.distance - 2)
                local distance = player_util.distance(player_util.get_player_position(), target_location)
                if target_location then
                    -- TODO(Aldros): Ensure that we only do this if the mob isn't targeting us
                    if distance > self.distance then
                        -- TODO(Aldros): Double check if this face target should have a check or not in front of it
                        self.action_queue:push_action(RunToLocationAction.new(target_location[1], target_location[2], target_location[3], 1), true)
                        self.action_queue:push_action(BlockAction.new(function() player_util.face(target) end))
                    else
                        self.action_queue:push_action(BlockAction.new(function() player_util.face(target) end))
                    end
                end
            else

]]

return CombatMode
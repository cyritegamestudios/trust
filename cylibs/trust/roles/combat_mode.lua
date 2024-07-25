local BlockAction = require('cylibs/actions/block')
local DisposeBag = require('cylibs/events/dispose_bag')
local RunAwayAction = require('cylibs/actions/runaway')
local RunToAction = require('cylibs/actions/runto')
local RunToLocationAction = require('cylibs/actions/runtolocation')
local battle_util = require('cylibs/util/battle_util')
local party_util = require('cylibs/util/party_util')
local player_util = require('cylibs/util/player_util')
local flanking_util = require("cylibs/util/flanking_util")

local CombatMode = setmetatable({}, {__index = Role })
CombatMode.__index = CombatMode

state.AutoFaceMobMode = M{['description'] = 'Auto Face Mob Mode', 'Auto', 'Away', 'Off'}
state.AutoFaceMobMode:set_description('Auto', "Okay, I'll make sure to look the monster straight in the eyes.")
state.AutoFaceMobMode:set_description('Away', "Okay, I'll avoid looking at the monster.")

state.CombatMode = M{['description'] = 'Combat Mode', 'Off', 'Melee', 'Ranged', 'Mirror'}
state.CombatMode:set_description('Melee', "Okay, I'll fight on the front lines.")
state.CombatMode:set_description('Ranged', "Okay, I'll stand back in battle.")
state.CombatMode:set_description('Mirror', "Okay, I'll stand where the party member I'm assisting is standing.")

state.FlankMode = M{['description'] = 'Flanking Mode', 'Off', 'Back', 'Left', 'Right'}
state.FlankMode:set_description('Back', "Ok, I'll flank from the back in battle.")
state.FlankMode:set_description('Left', "Ok, I'll flank from the left in battle.")
state.FlankMode:set_description('Right', "Ok, I'll flank from the right in battle.")

function CombatMode.new(action_queue, melee_distance, range_distance)
    local self = setmetatable(Role.new(action_queue), CombatMode)

    self.action_queue = action_queue
    self.melee_distance = melee_distance
    self.range_distance = range_distance
    self.dispose_bag = DisposeBag.new()

    return self
end

function CombatMode:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function CombatMode:on_add()
    self.dispose_bag:add(state.CombatMode:on_state_change():addAction(function(_, new_value)
        if new_value == 'Mirror' then
            local assist_target = self:get_party():get_assist_target()
            if not assist_target or assist_target:get_id() == self:get_party():get_player():get_id() then
                self:get_party():add_to_chat(self:get_party():get_player(), "I need to be assisting someone first in order to mirror their combat movements!")
            end
        end
    end), state.CombatMode:on_state_change())

    self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
        -- Unable to see ${target}
        if message_id == 5 then
            self:check_distance()
        end
    end), WindowerEvents.ActionMessage)
end

function CombatMode:target_change(target_index)
    Role.target_change(self, target_index)

    self.target_index = target_index
end

function CombatMode:tic(new_time, old_time)
    if self.target_index == nil then return end

    self:check_distance()
end

function CombatMode:check_distance()
    if self.target_index == nil then
        return
    end

    local target = windower.ffxi.get_mob_by_index(self.target_index)
    local self_mob = windower.ffxi.get_mob_by_target('me')
    if target == nil or not battle_util.is_valid_target(target.id) then return end

    if party_util.party_claimed(target.id) then
        if L{'Ranged'}:contains(state.CombatMode.value) then
            if target.distance:sqrt() < self.range_distance then
                self.action_queue:push_action(RunAwayAction.new(target.index, self.range_distance), true)
            elseif target.distance:sqrt() > (self.range_distance + 0.5) then
                player_util.face(target)
                self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end))
                self.action_queue:push_action(RunToAction.new(target.index, self.range_distance), true)
            else
                self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end))
            end
        elseif L{'Melee'}:contains(state.CombatMode.value) then
            -- Handle FlankMode for melee
            if not L{'Off'}:contains(state.FlankMode.value) then
                -- If we have a relative location, use that
                local target_location = flanking_util.get_relative_location_for_target(target.id, flanking_util[state.FlankMode.value], self.melee_distance - 2)
                local distance = player_util.distance(player_util.get_player_position(), target_location)
                if target_location then
                    -- TODO(Aldros): Ensure that we only do this if the mob isn't targeting us
                    if distance > self.melee_distance then
                        -- TODO(Aldros): Double check if this face target should have a check or not in front of it
                        self.action_queue:push_action(RunToLocationAction.new(target_location[1], target_location[2], target_location[3], 1), true)
                        self.action_queue:push_action(BlockAction.new(function() player_util.face(target) end))
                    else
                        self.action_queue:push_action(BlockAction.new(function() player_util.face(target) end))
                    end
                end
            else
                if target.distance:sqrt() > self.melee_distance + self_mob.model_size + target.model_size - 0.1 then
                    self.action_queue:push_action(BlockAction.new(function() player_util.face(target) end))
                    self.action_queue:push_action(
                        RunToAction.new(target.index, self.melee_distance + self_mob.model_size + target.model_size - 0.1),
                        true)
                else
                    self.action_queue:push_action(BlockAction.new(function() player_util.face(target) end))
                end
            end
        elseif L{'Mirror'}:contains(state.CombatMode.value) then
            local assist_target = self:get_party():get_assist_target()
            if assist_target then
                local dist = player_util.distance(self:get_party():get_player():get_position(), assist_target:get_position())
                if dist > 2 then
                    self.action_queue:push_action(RunToAction.new(assist_target:get_mob().index, 1), true)
                    return
                end
            end
            self:face_target(target)
        else
            self:face_target(target)
        end
    else
        self:face_target(target)
    end
end

function CombatMode:face_target(target)
    if state.AutoFaceMobMode.value == 'Auto' then
        self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end, "face target"))
    elseif state.AutoFaceMobMode.value == 'Away' then
        self.action_queue:push_action(BlockAction.new(function() player_util.face_away(target) end, "face away from target"))
    end
end

function CombatMode:allows_duplicates()
    return false
end

function CombatMode:get_type()
    return "combatmode"
end

return CombatMode
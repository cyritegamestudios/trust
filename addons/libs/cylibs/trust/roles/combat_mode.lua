local BlockAction = require('cylibs/actions/block')
local RunAwayAction = require('cylibs/actions/runaway')
local RunToAction = require('cylibs/actions/runto')
local battle_util = require('cylibs/util/battle_util')
local party_util = require('cylibs/util/party_util')
local player_util = require('cylibs/util/player_util')
local flanking_util = require("cylibs/util/flanking_util")

local CombatMode = setmetatable({}, {__index = Role })
CombatMode.__index = CombatMode

state.AutoFaceMobMode = M{['description'] = 'Auto Face Mob Mode', 'Auto', 'Off'}
state.AutoFaceMobMode:set_description('Auto', "Okay, I'll make sure to look the monster straight in the eyes.")

state.CombatMode = M{['description'] = 'Combat Mode', 'Off', 'Melee', 'Ranged'}
state.CombatMode:set_description('Melee', "Okay, I'll fight on the front lines.")
state.CombatMode:set_description('Ranged', "Okay, I'll stand back in battle.")

state.FlankMode = M{['description'] = 'Flanking Mode', 'Off', 'Back', 'Left', 'Right'}
state.FlankMode:set_description('Back', "Ok, I'll flank from the back in battle.")
state.FlankMode:set_description('Left', "Ok, I'll flank from the left in battle.")
state.FlankMode:set_description('Right', "Ok, I'll flank from the right in battle.")

function CombatMode.new(action_queue, melee_distance, range_distance)
    local self = setmetatable(Role.new(action_queue), CombatMode)
    self.action_queue = action_queue
    self.melee_distance = melee_distance
    self.range_distance = range_distance
    return self
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
    local target = windower.ffxi.get_mob_by_index(self.target_index)
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
                if target.distance:sqrt() > self.melee_distance then
                    self.action_queue:push_action(BlockAction.new(function() player_util.face(target) end))
                    self.action_queue:push_action(RunToAction.new(target.index, self.melee_distance), true)
                else
                    self.action_queue:push_action(BlockAction.new(function() player_util.face(target) end))
                end
            end
        else
            self:face_target(target)
        end
    else
        self:face_target(target)
    end
end

function CombatMode:face_target(target)
    if state.AutoFaceMobMode.value ~= 'Off' then
        self.action_queue:push_action(BlockAction.new(function() player_util.face(target)  end, "face target"))
    end
end

function CombatMode:allows_duplicates()
    return false
end

function CombatMode:get_type()
    return "combatmode"
end

return CombatMode
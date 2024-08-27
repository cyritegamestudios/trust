---------------------------
-- Wrapper class around a player.
-- @class module
-- @name Player

local battle_util = require('cylibs/util/battle_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local ffxi_util = require('cylibs/util/ffxi_util')
local packets = require('packets')
local res = require('resources')

local Player = setmetatable({}, {__index = Entity })
Player.__index = Player
Player.__class = "Player"

-- Event called when the player's target changes.
function Player:on_target_change()
    return self.target_change
end

-- Event called when the player's pet changes.
function Player:on_pet_change()
    return self.pet_change
end

-- Event called when the player's ranged attack begins.
function Player:on_ranged_attack_begin()
    return self.ranged_attack_begin
end

-- Event called when the player's ranged attack is interrutped.
function Player:on_ranged_attack_interrupted()
    return self.ranged_attack_interrupted
end

-- Event called when the player's ranged attack ends.
function Player:on_ranged_attack_end()
    return self.ranged_attack_end
end

-- Event called when the player's weapn skill finishes.
function Player:on_weapon_skill_finish()
    return self.weapon_skill_finish
end

-- Event called when a player's spell begins casting.
function Player:on_spell_begin()
    return self.spell_begin
end

-- Event called when a player's spell finishes casting.
function Player:on_spell_finish()
    return self.spell_finish
end

-- Event called when a player's spell finishes casting and there is no effect.
function Player:on_spell_finish_no_effect()
    return self.spell_finish_no_effect
end

-- Event called when a player's spell casting is interrupted.
function Player:on_spell_interrupted()
    return self.spell_interrupted
end

-- Event called when a player is unable to cast spells.
function Player:on_unable_to_cast()
    return self.unable_to_cast
end

-- Event called when a job ability is used.
function Player:on_job_ability_used()
    return self.job_ability_used
end

-------
-- Default initializer for a Player.
-- @tparam number id Mob id
-- @treturn Player A player
function Player.new(id)
    local self = setmetatable(Entity.new(id), Player)
    self.id = id
    self.action_events = {}
    self.target_index = nil
    self.pet_id = nil
    self.is_monitoring = false
    self.pet_id = nil
    self.last_position = V{0, 0, 0}
    
    self.target_change = Event.newEvent()
    self.ranged_attack_begin = Event.newEvent()
    self.ranged_attack_interrupted = Event.newEvent()
    self.ranged_attack_end = Event.newEvent()
    self.weapon_skill_finish = Event.newEvent()
    self.spell_begin = Event.newEvent()
    self.spell_finish = Event.newEvent()
    self.spell_finish_no_effect = Event.newEvent()
    self.spell_interrupted = Event.newEvent()
    self.pet_change = Event.newEvent()
    self.unable_to_cast = Event.newEvent()
    self.job_ability_used = Event.newEvent()
    self.dispose_bag = DisposeBag.new()

    local pet = windower.ffxi.get_mob_by_target('pet')
    if pet then
        self:update_pet(pet.index)
    end

    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Player:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    if self.main_job then
        self.main_job:destroy()
    end
    if self.sub_job then
        self.sub_job:destroy()
    end

    self.dispose_bag:destroy()

    self.target_change:removeAllActions()
    self.ranged_attack_begin:removeAllActions()
    self.ranged_attack_interrupted:removeAllActions()
    self.ranged_attack_end:removeAllActions()
    self.weapon_skill_finish:removeAllActions()
    self.spell_begin:removeAllActions()
    self.spell_finish:removeAllActions()
    self.spell_finish_no_effect:removeAllActions()
    self.spell_interrupted:removeAllActions()
    self.pet_change:removeAllActions()
    self.unable_to_cast:removeAllActions()
    self.job_ability_used:removeAllActions()
end

function Player:update_target(target_index)
    if self.target_index ~= target_index then
        if target_index and target_index ~= 0 and battle_util.is_valid_monster_target(ffxi_util.mob_id_for_index(target_index)) then
            local target = windower.ffxi.get_mob_by_index(target_index)
            if target and battle_util.is_valid_monster_target(target.id) then
                self.target_index = target.index
            end
        else
            self.target_index = nil
        end
        self:on_target_change():trigger(self, self.target_index)
    end
end

function Player:update_pet(pet_index)
    local old_pet_id = self.pet_id
    local new_pet_id
    local new_pet_name
    if pet_index and pet_index ~= 0 then
        local pet = windower.ffxi.get_mob_by_index(pet_index)
        if pet then
            new_pet_id = pet.id
            new_pet_name = pet.name
        end
    end
    if new_pet_id ~= old_pet_id then
        self.pet_id = new_pet_id
        logger.notice(self.__class, 'pet change', 'old pet id', old_pet_id or 'none', 'new_pet_id', new_pet_id or 'none', new_pet_name or 'none')
        self:on_pet_change():trigger(self, new_pet_id, new_pet_name)
    end
end

-------
-- Starts monitoring the player's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Player:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.dispose_bag:add(WindowerEvents.PetUpdate:addAction(function(owner_id, pet_id, pet_index, pet_name, pet_hpp, pet_mpp, pet_tp)
        if owner_id == self.id then
            logger.notice(self.__class, "pet update", pet_name, pet_index, pet_hpp, pet_mpp, pet_tp)
            self:update_pet(pet_index)
        end
    end), WindowerEvents.PetUpdate)

    if windower.ffxi.get_player().id == self.id then
        self.action_events.outgoing = windower.register_event('outgoing chunk', function(id, original, _, _, _)
            -- Notify target changes
            if id == 0x015 then
                local p = packets.parse('outgoing', original)
                local current_position = ffxi_util.get_player_position()
                if ffxi_util.distance(self.last_position, current_position) > 0.01 then
                    self.is_moving = true
                else
                    self.is_moving = false
                end
                self.last_position = current_position
                self:update_target(p['Target Index'])
            end
        end)
        self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function(actor_id, target_id, actor_index, target_index, message_id, param_1, param_2, param_3)
            if actor_id ~= windower.ffxi.get_player().id then return end

            if L{17, 18, 48, 49, 313}:contains(message_id) then
                self:on_unable_to_cast():trigger(self, target_index, message_id, param_1)
            end

            if L{12}:contains(message_id) then
                --self:update_target(nil, true)
            end
        end), WindowerEvents.ActionMessage)
    end

    -- Notify actions
    self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
        if action.actor_id ~= self.id then return end

        if action.category == 12 then
            if action.param == 28787 then
                self:on_ranged_attack_interrupted():trigger(self, action.targets[1])
            else
                self:on_ranged_attack_begin():trigger(self, action.targets[1])
            end
        elseif action.category == 2 then
            self:on_ranged_attack_end():trigger(self, action.targets[1])
        elseif action.category == 3 then
            self:on_weapon_skill_finish():trigger(self, action.targets[1], action.param)
        elseif action.category == 4 then
            self:on_spell_finish():trigger(self, action.param, action.targets)
        elseif action.category == 6 then
            self:on_job_ability_used():trigger(self, action.param, action.targets)
        elseif action.category == 8 then
            if action.param == 28787 then
                self:on_spell_interrupted():trigger(self, action.targets[1].actions[1].param)
            else
                self:on_spell_begin():trigger(self, action.targets[1].actions[1].param)
            end
        end
    end), WindowerEvents.Action)
end

-------
-- Returns the player's name
-- @treturn string Player's name
function Player:get_name()
    return windower.ffxi.get_mob_by_id(self.id).name
end

function Player:get_main_weapon()
    return self.main_weapon
end

-------
-- Returns whether the player is currently moving.
-- @treturn boolean True if the player is moving, false otherwise.
function Player:is_moving()
    return self.moving
end

-------
-- Returns whether the player is currently engaged.
-- @treturn boolean True if the player is engaged, false otherwise.
function Player:is_engaged()
    return res.statuses[windower.ffxi.get_player().status].en == 'Engaged'
end

return Player
---------------------------
-- Base class for an geocolure.
-- @class module
-- @name Geocolure

local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local packets = require('packets')
local res = require('resources')

local Geocolure = setmetatable({}, {__index = Entity })
Geocolure.__index = Geocolure

---- Geocolure events
-- @table Geocolure
-- @tfield string Event triggered when the geocolure's hpp changes
Geocolure.hpp_change = Event.newEvent()

-------
-- Default initializer for a new Geocolure.
-- @tparam number luopan_id Mob id of the luopan
-- @tparam ActionQueue action_queue Action queue
-- @treturn Geocolure An geocolure
function Geocolure.new(luopan_id, action_queue)
    local self = setmetatable(Entity.new(luopan_id), Geocolure)
    self.action_queue = action_queue
    self.action_events = {}
    self.hpp = 0
    self.is_ecliptic_attrition_active = false
    self.is_lasting_emanation_active = false
    self.is_dematerialize_active = false
    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Geocolure:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
    Geocolure.job_ability_finish:removeAllActions()
end

function Geocolure:reset()
    self.is_ecliptic_attrition_active = false
    self.is_lasting_emanation_active = false
    self.is_dematerialize_active = false
end

-------
-- Starts monitoring the automaton's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Geocolure:monitor()
    self.action_events.incoming_chunk = windower.register_event('incoming chunk', function(id, original, _, _, _)
        if id == 0x067 then
            local p = packets.parse('incoming', original)

            local owner_index = p['Owner Index']
            if owner_index == windower.ffxi.get_player().index then
                local pet_hpp = p['Current HP%']
                if self.hpp ~= pet_hpp then
                    self.hpp = pet_hpp
                    if self.hpp == 0 then
                        self:reset()
                    end
                    Geocolure.hpp_change:trigger(self, self.hpp)
                end
            end
        end
    end)
end

function Geocolure:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
    Geocolure.hpp_change:removeAllActions()
end

function Geocolure:is_alive()
    return pet_util.has_pet() and pet_util.get_pet().name == 'Luopan'
end

function Geocolure:is_in_range(target)
    local luopan = self:get_mob()
    if luopan then
        local target_mob = windower.ffxi.get_mob_by_target(target)
        if target_mob then
            return geometry_util.distance(target_mob, luopan) <= 10
        else
            return true
        end
    end
    return true
end

function Geocolure:ecliptic_attrition()
    if self.is_ecliptic_attrition_active then
        return
    end
    self.is_ecliptic_attrition_active = true
    self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Ecliptic Attrition'), true)
end

function Geocolure:life_cycle()
    if job_util.can_use_job_ability('Life Cycle') then
        self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Life Cycle'), true)
    end
end

return Geocolure
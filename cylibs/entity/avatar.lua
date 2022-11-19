---------------------------
-- Base class for an avatar.
-- @class module
-- @name Avatar

local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local res = require('resources')

local Avatar = setmetatable({}, {__index = Entity })
Avatar.__index = Avatar

---- Avatar events
-- @table Avatar
-- @tfield string Event Triggered when the avatar uses a blood pact
Avatar.blood_pact_finish = Event.newEvent()

-------
-- Default initializer for a new Avatar.
-- @tparam number avatar_id Mob id of the avatar
-- @tparam ActionQueue action_queue Action queue
-- @treturn Avatar An avatar
function Avatar.new(avatar_id, action_queue)
    local self = setmetatable(Entity.new(avatar_id), Automaton)
    self.action_queue = action_queue
    self.action_events = {}
    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Avatar:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
    Avatar.blood_pact_finish:removeAllActions()
end

-------
-- Starts monitoring the automaton's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Avatar:monitor()
end

-------
-- Returns true if the automaton is currently not engaged.
-- @treturn Boolean True if the pet is idle, and false otherwise.
function Avatar:is_idle()
    return self:get_mob().status == 0
end

-------
-- Returns the Automaton's vitals.
-- @treturn T Automaton's hpp and mpp
function Avatar:get_vitals()
    local vitals = {}
    local mjob_data = windower.ffxi.get_mjob_data()
    if mjob_data then
        vitals.hpp = 100 * (mjob_data.hp / mjob_data.max_hp)
        vitals.mpp = 100 * (mjob_data.mp / mjob_data.max_mp)
    else
        vitals.hpp = 0
        vitals.mpp = 0
    end
    return vitals
end

-------
-- Deactivates the automaton.
function Avatar:release()
    self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Release'), true)
end

return Avatar
---------------------------
-- Base class for a familiar.
-- @class module
-- @name Familiar

local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')

local Familiar = setmetatable({}, {__index = Entity })
Familiar.__index = Familiar

---- Familiar events
-- @table Familiar
-- @tfield string Event Triggered when the familiar finishes a ready move
Familiar.ready_move_finish = Event.newEvent()

-------
-- Default initializer for a new Avatar.
-- @tparam number familiar_id Mob id of the familiar
-- @tparam ActionQueue action_queue Action queue
-- @treturn Familiar A familiar
function Familiar.new(familiar_id, action_queue)
    local self = setmetatable(Entity.new(familiar_id), Familiar)
    self.action_queue = action_queue
    self.action_events = {}
    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Familiar:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
    Familiar.ready_move_finish:removeAllActions()
end

-------
-- Starts monitoring the automaton's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Familiar:monitor()
end

-------
-- Returns true if the familiar is currently not engaged.
-- @treturn Boolean True if the pet is idle, and false otherwise.
function Familiar:is_idle()
    return self:get_mob().status == 0
end

-------
-- Returns true if the familiar is currently engaged.
-- @treturn Boolean True if the pet is engaged, and false otherwise.
function Familiar:is_engaged()
    return self:get_mob().status == 1
end

-------
-- Releases the familiar.
function Familiar:leave()
    self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Leave'), true)
end

return Familiar
---------------------------
-- Base class for an automaton.
-- @class module
-- @name Automaton

local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')
local pup_util = require('cylibs/util/pup_util')
local res = require('resources')

local Automaton = setmetatable({}, {__index = Entity })
Automaton.__index = Automaton

-- Event called when the automaton uses a job ability (e.g. Strobe, Flash, Regulator)
function Automaton:on_job_ability_finish()
    return self.job_ability_finish
end

-------
-- Default initializer for a new Automaton.
-- @tparam number automaton_id Mob id of the automaton
-- @tparam ActionQueue action_queue Action queue
-- @treturn Automaton An automaton
function Automaton.new(automaton_id, action_queue)
    local self = setmetatable(Entity.new(automaton_id), Automaton)
    self.action_queue = action_queue
    self.action_events = {}
    self.ability_ready_times = {}
    self.pet_mode = pup_util.get_pet_mode()
    self.job_ability_finish = Event.newEvent()
    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function Automaton:destroy()
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.job_ability_finish:removeAllActions()
end

-------
-- Starts monitoring the automaton's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function Automaton:monitor()
    self.action_events.action = windower.register_event('action', function(action)
        if action.actor_id == self:get_id() then
            if action.category == 11 then
                local job_ability = res.monster_abilities:with('id', action.param)
                if job_ability.name == 'Provoke' then
                    self.ability_ready_times['Provoke'] = os.time() + 23
                elseif job_ability.name == 'Flashbulb' then
                    self.ability_ready_times['Flashbulb'] = os.time() + 38
                end
                self:on_job_ability_finish():trigger(self, job_ability.name)
            end
        end
    end)
end

-------
-- Returns true if the automaton is currently not engaged.
-- @treturn Boolean True if the pet is idle, and false otherwise.
function Automaton:is_idle()
    return self:get_mob().status == 0
end

-------
-- Returns whether the pet is a mage (can cast magic).
-- @treturn Boolean True if the pet is a mage, and false otherwise.
function Automaton:is_mage()
    return L{'Magic','Nuke','Heal'}:contains(self.pet_mode)
end

-------
-- Returns the recast timer for Strobe.
-- @treturn number Recast in seconds, or MAX_NUM if a Strobe attachment is not equipped
function Automaton:get_provoke_recast()
    if not pup_util.get_attachments():contains('strobe', 'strobe ii') then
        return 9999
    end
    if self.ability_ready_times['Provoke'] then
        return math.max(self.ability_ready_times['Provoke'] - os.time(), 0)
    end
    return 0
end

-------
-- Returns the recast timer for Flashbulb.
-- @treturn number Recast in seconds, or MAX_NUM if the Flashbulb attachment is not equipped
function Automaton:get_flash_recast()
    if not pup_util.get_attachments():contains('flashbulb') then
        return 9999
    end
    if self.ability_ready_times['Flashbulb'] then
        return math.max(self.ability_ready_times['Flashbulb'] - os.time(), 0)
    end
    return 0
end

-------
-- Returns whether the Automaton has an attachment.
-- @treturn Boolean True if the Automaton has the attachment
function Automaton:has_attachment(attachment_name)
    return pup_util.get_attachments():contains(attachment_name)
end

-------
-- Returns the pet mode based on the current head and frame.
-- @treturn string Pet mode (HybridRanged, Ranged, Tank, LightTank, Melee, Magic, Nuke, Heal).
function Automaton:get_pet_mode()
    return self.pet_mode
end

-------
-- Returns the Automaton's vitals.
-- @treturn T Automaton's hpp and mpp
function Automaton:get_vitals()
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
-- Returns the Automaton's mpp.
-- @treturn number Automaton's mpp
function Automaton:get_mpp()
    local mjob_data = windower.ffxi.get_mjob_data()
    if mjob_data then
        return mjob_data.mp / mjob_data.max_mp
    end
    return 0
end

-------
-- Uses repair.
function Automaton:repair()
    self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Repair'), true)
end

-------
-- Deactivates the automaton.
function Automaton:deactivate()
    self.action_queue:push_action(JobAbilityAction.new(0, 0, 0, 'Deactivate'), true)
end

return Automaton
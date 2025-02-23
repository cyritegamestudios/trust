---------------------------
-- Utility functions for Puppetmaster.
-- @class module
-- @name PupUtil

_libs = _libs or {}

require('lists')

local Item = require('resources/resources').Item

local pup_util = {}

_raw = _raw or {}

_libs.pup_util = pup_util

-------
-- Returns a list of attachments that are currently equipped by the player.
-- @treturn list Localized names for the player's attachments (e.g. Strobe, Attuner, etc.)
function pup_util.get_attachments()
    local current = L{}
    local atts = Item:where({ category = "Automaton" }, true)
    local mjob_data = windower.ffxi.get_mjob_data()
    if not mjob_data then return current end

    local tmpTable = mjob_data.attachments
    if not tmpTable then return L{} end
    for i = 1, 12 do
        local t = ''
        if tmpTable[i] then
            if i < 10 then
                t = '0'
            end
            current:append(atts[tmpTable[i]].name:lower())
        end
    end
    return current
end

-------
-- Returns the pet mode based on the current head and frame.
-- @treturn string Pet mode (HybridRanged, Ranged, Tank, LightTank, Melee, Magic, Nuke, Heal)
function pup_util.get_pet_mode()
    local mjob_data = windower.ffxi.get_mjob_data()

    local pet = {}

    pet.frame = Item:get({ id = mjob_data.frame }).en
    pet.head = Item:get({ id = mjob_data.head }).en

    if pet.frame == 'Sharpshot Frame' then
        if pet.head == 'Valoredge Head' or pet.head == 'Harlequin Head' then
            return 'HybridRanged'
        else
            return 'Ranged'
        end
    elseif pet.frame == 'Valoredge Frame' then
        if pet.head == 'Soulsoother Head' then
            return 'Tank'
        else
            return 'Melee'
        end
    elseif pet.head == 'Sharpshot Head' or pet.head == 'Stormwaker Head' then
        return 'Magic'
    elseif pet.head == 'Spiritreaver Head' then
        return 'Nuke'
    elseif pet.frame == 'Harlequin Frame' then
        if pet.head == 'Harlequin Head' then
            return 'Melee'
        else
            return 'LightTank'
        end
    else
        if pet.head == 'Soulsoother Head' then
            return 'Heal'
        elseif pet.head == 'Valoredge Head' then
            return 'Melee'
        else
            return 'Magic'
        end
    end
end

-------
-- Determines if the player's automaton is able to dispel (e.g. Dispel, Regulator, Disruptor).
-- @treturn Boolean True if the player's automaton can dispel and false otherwise.
function pup_util.can_dispel()
    return pup_util.get_attachments():contains('regulator', 'disruptor')
end

return pup_util
---------------------------
-- Job file for Puppetmaster.
-- @class module
-- @name Puppetmaster

local buff_util = require('cylibs/util/buff_util')
local EquipAttachmentAction = require('cylibs/actions/equip_attachment')
local job_util = require('cylibs/util/job_util')
local zone_util = require('cylibs/util/zone_util')
local res = require('resources')
local attachments = require('cylibs/res/attachments')

local Job = require('cylibs/entity/jobs/job')
local Puppetmaster = setmetatable({}, {__index = Job })
Puppetmaster.__index = Puppetmaster

-------
-- Default initializer for a new Puppetmaster.
-- @treturn PUP A Puppetmaster
function Puppetmaster.new()
    local self = setmetatable(Job.new(), Puppetmaster)
    return self
end

-------
-- Destroy function for a Puppetmaster.
function Puppetmaster:destroy()
    Job.destroy(self)
end

-------
-- Returns whether or not the Puppetmaster is currently overloaded.
-- @treturn Boolean True if the Puppetmaster is overloaded, and false otherwise.
function Puppetmaster:is_overloaded()
    return buff_util.is_buff_active(buff_util.buff_id('Overload'))
end

-------
-- Returns whether or not the Puppetmaster can use repair.
-- @treturn Boolean True if the Puppetmaster can use repair, and false otherwise.
function Puppetmaster:can_repair()
    if not job_util.can_use_job_ability('Repair') then
        return false
    end
    local item_id = windower.ffxi.get_items().equipment['ammo']
    if item_id and item_id ~= 0 then
        local item = res.items:with('id', item_id)
        if item then
            return item.en == 'Automat. Oil +3'
        end
    end
    return false
end

---
-- Checks whether the Puppetmaster can use activate.
--
-- @return (boolean) True if the Puppetmaster can use activate, false otherwise.
---
function Puppetmaster:can_activate()
    if not job_util.can_use_job_ability('Activate') then
        return false
    end
    local info = windower.ffxi.get_info()
    if zone_util.is_city(info.zone) then
        return false
    end
    return true
end

-------
-- Returns the Puppetmaster's active maneuvers, if any.
-- @treturn list Localized names of current maneuvers
function Puppetmaster:get_maneuvers()
    return L(windower.ffxi.get_player().buffs):map(function(buff_id)
        return res.buffs:with('id', buff_id).en
    end):filter(function(buff_name)
        return buff_name:contains('Maneuver')
    end)
end

-------
-- Returns the Puppetmaster's attachments.
-- @treturn list List of localized attachment names
function Puppetmaster:get_attachments()
    return pup_util.get_attachments()
end

-------
-- Removes all equipped attachments.
function Puppetmaster:remove_all_attachments()
    windower.ffxi.reset_attachments()
end

function Puppetmaster:create_attachment_set()
    local mjob_data = windower.ffxi.get_mjob_data()
    if mjob_data == nil or mjob_data.attachments == nil then
        return
    end

    local frame_id = mjob_data.frame
    local head_id = mjob_data.head

    local attachment_ids = L{}
    for _, attachment_id in pairs(mjob_data.attachments) do
        attachment_ids:append(attachment_id)
    end

    local attachment_names = attachment_ids:map(function(attachment_id)
        return attachments[attachment_id].en
    end)

    local attachment_set = AttachmentSet.new(attachments[frame_id].en, attachments[head_id].en, attachment_names)
    return attachment_set
end

function Puppetmaster:equip_attachment_set(head_name, frame_name, attachment_names, action_queue, auto_deactivate)
    if attachment_names:empty() then
        return
    end

    local actions = L{}

    if pet_util.has_pet() then
        if not auto_deactivate then
            return
        else
            if not job_util.can_use_job_ability('Deactivate') then
                return
            end
            actions:append(JobAbilityAction.new(0, 0, 0, 'Deactivate'))
            actions:append(WaitAction.new(0, 0, 0, 0.5))
        end
    end

    actions:append(BlockAction.new(function()
        self:remove_all_attachments()
    end), 'equip_remove_all_attachments')
    actions:append(WaitAction.new(0, 0, 0, 1.0))

    local attachment_ids = attachment_names:map(function(attachment_name)
        return attachments:with('en', attachment_name).id
    end):compact_map()

    local head_id = attachments:with('en', head_name).id
    local frame_id = attachments:with('en', frame_name).id

    actions:append(EquipAttachmentAction.new(head_id))
    actions:append(EquipAttachmentAction.new(frame_id))

    local slot_num = 1
    for attachment_id in attachment_ids:it() do
        actions:append(EquipAttachmentAction.new(attachment_id, slot_num))
        slot_num = slot_num + 1
    end

    actions:append(BlockAction.new(function()
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, done!")
    end), 'equip_attachments_done')

    local equip_action = SequenceAction.new(actions, 'equip_attachment_set', true)
    equip_action.priority = ActionPriority.highest
    equip_action.max_duration = 15

    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Give me a sec, I'm updating my attachments...")

    action_queue:push_action(equip_action, true)
end

return Puppetmaster
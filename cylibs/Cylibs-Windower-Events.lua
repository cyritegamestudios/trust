local AllianceMember = require('cylibs/entity/alliance/alliance_member')
local BuffRecord = require('cylibs/battle/buff_record')
local Event = require('cylibs/events/Luvent')
local DisposeBag = require('cylibs/events/dispose_bag')
local EquipmentChangedMessage = require('cylibs/messages/equipment_changed_message')
local GainDebuffMessage = require('cylibs/messages/gain_buff_message')
local inventory_util = require('cylibs/util/inventory_util')
local IpcRelay = require('cylibs/messages/ipc/ipc_relay')
local logger = require('cylibs/logger/logger')
local LoseDebuffMessage = require('cylibs/messages/lose_buff_message')
local MobUpdateMessage = require('cylibs/messages/mob_update_message')
local packets = require('packets')
local Timer = require('cylibs/util/timers/timer')
local ZoneMessage = require('cylibs/messages/zone_message')


---------------------------
-- Windower global event handler. Requiring this in your addon will automatically create a global
-- event handler that registers a series of Windower event handlers that dispatch events to
-- the rest of the addon
-- @class module
-- @name WindowerEvents

local WindowerEvents = {}

WindowerEvents.DisposeBag = DisposeBag.new()

-- Global list of handlers for all Windower events. Listen to events here.
WindowerEvents.Action = Event.newEvent("Action")
WindowerEvents.ActionMessage = Event.newEvent("ActionMessage")
WindowerEvents.CharacterUpdate = Event.newEvent()
WindowerEvents.MobUpdate = Event.newEvent()
WindowerEvents.MobKO = Event.newEvent()
WindowerEvents.PositionChanged = Event.newEvent()
WindowerEvents.TargetIndexChanged = Event.newEvent("TargetIndexChanged")
WindowerEvents.ZoneUpdate = Event.newEvent()
WindowerEvents.ZoneRequest = Event.newEvent()
WindowerEvents.BuffsChanged = Event.newEvent()
WindowerEvents.DebuffsChanged = Event.newEvent()
WindowerEvents.BuffDurationChanged = Event.newEvent()
WindowerEvents.GainDebuff = Event.newEvent()
WindowerEvents.LoseDebuff = Event.newEvent()
WindowerEvents.AllianceMemberListUpdate = Event.newEvent()
WindowerEvents.PetUpdate = Event.newEvent()
WindowerEvents.AutomatonUpdate = Event.newEvent()
WindowerEvents.Equipment = {}
WindowerEvents.Equipment.MainWeaponChanged = Event.newEvent()
WindowerEvents.Equipment.RangedWeaponChanged = Event.newEvent()
WindowerEvents.BlueMagic = {}
WindowerEvents.BlueMagic.SpellsChanged = Event.newEvent()
WindowerEvents.Ability = {}
WindowerEvents.Ability.Ready = Event.newEvent()
WindowerEvents.Ability.Finish = Event.newEvent()
WindowerEvents.Spell = {}
WindowerEvents.Spell.Begin = Event.newEvent()
WindowerEvents.Spell.Finish = Event.newEvent()

local main_weapon_id
local ranged_weapon_id

local time = os.time()
local vana_time = time - 1009810800

local bufftime_offset = math.floor(time - (vana_time * 60 % 0x100000000) / 60)

local incoming_event_ids = S{
    0x028, -- data.incoming[0x028] = {name='Action',              description='Packet sent when an NPC is attacking.'}
    0x029, -- data.incoming[0x029] = {name='Action Message',      description='Packet sent for simple battle-related messages.'}
    0x0DD, -- data.incoming[0x0DD] = {name='Party member update', description='Packet sent on party member join, leave, zone, etc.'}
    0x0DF,
    0x00D,
    0x00E,
    0x076,
    0x0C8,
    0x037,
    0x044,
    0x050,
    0x068,
    0x063,
}

local outgoing_event_ids = S{
    0x015,
    0x05E,
    0x102,
}

-- Jump table with a mapping of message_id to handler for that message_id
local incoming_event_dispatcher = {
    [0x028] = function(data)
        local act = windower.packets.parse_action(data)
        act.size = data:byte(5)
        WindowerEvents.Action:trigger(act)

        if act.category == 4 then
            if act.param and res.spells[act.param] then
                WindowerEvents.Spell.Finish:trigger(act.actor_id, act.param)
            end
        elseif act.category == 7 then
            if res.monster_abilities[act.targets[1].actions[1].param] then
                WindowerEvents.Ability.Ready:trigger(act.actor_id, act.targets[1].actions[1].param)
            end
        elseif act.category == 11 then
            if res.monster_abilities[act.param] then
                WindowerEvents.Ability.Finish:trigger(act.actor_id, act.param)
            end
        end

        for _, target in pairs(act.targets) do
            local action = target.actions[1]
            if action then
                if action_message_util.is_gain_debuff_message(action.message) and act.param and not L{260, 360}:contains(act.param) then
                    local debuff = buff_util.debuff_for_spell(act.param)
                    if debuff then
                        WindowerEvents.GainDebuff:trigger(target.id, debuff.id)
                    end
                end
            end
        end
    end,

    [0x029] = function(data)
        local packet = packets.parse('incoming', data)
        -- remap parameters
        local actor_id = packet['Actor']
        local target_id = packet['Target']
        local actor_index = packet['Actor Index']
        local target_index = packet['Target Index']
        local message_id = packet['Message']
        local param_1 = packet['Param 1']
        local param_2 = packet['Param 2']
        local param_3 = packet['_unknown1']
        WindowerEvents.ActionMessage:trigger(actor_id, target_id, actor_index,
            target_index, message_id, param_1, param_2, param_3)

        if action_message_util.is_lose_debuff_message(message_id) and param_1 then
            if buff_util.is_debuff(param_1) then
                WindowerEvents.LoseDebuff:trigger(target_id, param_1)
                -- NOTE: this causes a memory leak
                --IpcRelay.shared():send_message(LoseDebuffMessage.new(target_id, param_1))
            end
        end

        if L{ 43, 326, 675 }:contains(message_id) then
            WindowerEvents.Ability.Ready:trigger(target_id, param_1)
        end
    end,

    -- Party member update, only sent on join/leave and maybe some other rare circumstances?
    -- Also called when zoning
    -- Not sent by alter egos
    [0x0DD] = function(data)
        local packet = packets.parse('incoming', data)

        local mob_id = packet['ID']
        local name = packet['Name']
        local hp = packet['HP']
        local hpp = packet['HP%']
        local mp = packet['MP']
        local mpp = packet['MP%']
        local tp = packet['TP']
        local main_job_id = packet['Main job']
        local sub_job_id = packet['Sub job']
        local zone = packet['Zone'] or windower.ffxi.get_info().zone

        WindowerEvents.CharacterUpdate:trigger(mob_id, name, hp, hpp, mp, mpp, tp, main_job_id, sub_job_id)
        if zone ~= 0 then
            WindowerEvents.ZoneUpdate:trigger(mob_id, zone)
        end
    end,

    -- 0x0DF
    -- Updates hpp, hp, mpp, mp, tp but only when they change
    -- Seems to return sane values for everything
    -- Works for other players and player and alter egos
    [0x0DF] = function(data)
        local packet = packets.parse('incoming', data)

        local mob_id = packet['ID']
        if mob_id == nil then
            return
        end

        local mob = windower.ffxi.get_mob_by_id(mob_id)
        if not mob then
            return
        end
        local name = windower.ffxi.get_mob_by_id(mob_id).name
        local hp = packet['HP']
        local hpp = packet['HPP']
        local mp = packet['MP']
        local mpp = packet['MPP']
        local tp = packet['TP']
        local main_job_id = packet['Main job']
        local sub_job_id = packet['Sub job']

        WindowerEvents.CharacterUpdate:trigger(mob_id, name, hp, hpp, mp, mpp, tp, main_job_id, sub_job_id)
    end,

    -- 0x00D
    -- Character update for PCs who are not the player
    -- Updates (x, y, z) and target_index but only when they change
    -- Defaults back to (0, 0, 0) and 0 when there are no changes
    -- Only works for other players, does not work for player for either of these
    -- {ctype='boolbit',           label='Update Position'},                       -- 0A:0 Position, Rotation, Target, Speed
    --    {ctype='boolbit',           label='Update Status'},                         -- 1A:1 Not used for 0x00D
    --    {ctype='boolbit',           label='Update Vitals'},                         -- 0A:2 HP%, Status, Flags, LS color, "Face Flags"
    --    {ctype='boolbit',           label='Update Name'},                           -- 0A:3 Name
    [0x00D] = function(data)
        local packet = packets.parse('incoming', data)

        local target_id = packet['Player']

        if packet['Update Position'] then
            local target = windower.ffxi.get_mob_by_id(target_id)
            if target and not IpcRelay.shared():is_connected(target.name) then
                WindowerEvents.PositionChanged:trigger(target_id, packet['X'], packet['Y'], packet['Z'])
            end
            WindowerEvents.TargetIndexChanged:trigger(target_id, packet['Target Index'])
        end
    end,

    -- 0x00E
    -- NPC Update
    [0x00E] = function(data)
        local packet = packets.parse('incoming', data)

        local mob_id = packet['NPC']
        local mob = windower.ffxi.get_mob_by_id(mob_id)
        if not mob then
            return
        end

        local name = mob.name
        local status = packet['Status']
        local type = packet['Mask']

        if type == 7 then
            local hpp = packet['HP %']
            WindowerEvents.MobUpdate:trigger(mob_id, name, hpp)
        end

        if L{ 2, 3 }:contains(status) then
            WindowerEvents.MobKO:trigger(mob_id, name)
        end
    end,

    [0x076] = function(data)
        for party_member in party_util.get_party_members(true):it() do
            local buff_ids = party_util.get_buffs(party_member.id)
            WindowerEvents.BuffsChanged:trigger(party_member.id, L(buff_util.buffs_for_buff_ids(buff_ids)))
            WindowerEvents.DebuffsChanged:trigger(party_member.id, L(buff_util.debuffs_for_buff_ids(buff_ids)))
        end
    end,

    [0x0C8] = function(data)
        local packet = packets.parse('incoming', data)

        local alliance_members = L{}
        for i = 1, 18 do
            local id = packet['ID '..i]
            if id and id ~= 0 then
                alliance_members:append(AllianceMember.new(id, packet['Index '..i], packet['Zone '..i], math.ceil(i / 6)))
            end
        end
        WindowerEvents.AllianceMemberListUpdate:trigger(alliance_members)

        -- NOTE: this might actually be incorrect if some parties are half full
        local alliance_index = 1
        for alliance_member in alliance_members:it() do
            local party_member_info = party_util.get_party_member_from_alliance_index(alliance_index)
            if party_member_info then
                WindowerEvents.CharacterUpdate:trigger(alliance_member:get_id(), party_member_info.name, party_member_info.hp, party_member_info.hpp,
                        party_member_info.mp, party_member_info.mpp, party_member_info.tp, nil, nil)
            end
            WindowerEvents.ZoneUpdate:trigger(alliance_member:get_id(), alliance_member:get_zone_id())

            alliance_index = alliance_index + 1
        end
    end,

    [0x037] = function(data)
        local packet = packets.parse('incoming', data)

        local pet_index = packet['Pet Index']
        if pet_index and pet_index ~= 0 then
            local mob = windower.ffxi.get_mob_by_index(pet_index)
            if mob then
                WindowerEvents.PetUpdate:trigger(windower.ffxi.get_player().id, mob.id, mob.index, mob.name, mob.hpp, mob.mpp, mob.tp)
            end
        end
    end,

    [0x044] = function(data)
        if data:unpack('C', 0x05) == 0x12 then    -- puppet update
            local pet_name = data:unpack('z', 0x59)
            local current_hp, max_hp, current_mp, max_mp = data:unpack('HHHH', 0x069)

            local pet = windower.ffxi.get_mob_by_target("pet")
            if pet and pet.name == pet_name then
                WindowerEvents.AutomatonUpdate:trigger(pet.id, pet_name, current_hp, max_hp, current_mp, max_mp)
            end
        end
    end,

    [0x050] = function(data)
        -- Main weapon
        if data:byte(6) == 0 then
            main_weapon_id = windower.ffxi.get_items(data:byte(7), data:byte(5)).id
            if main_weapon_id == 65535 then
                main_weapon_id = nil
            end
            local weapons = require('cylibs/res/weapons')
            if main_weapon_id == nil or weapons[main_weapon_id] == nil then
                return
            end
            coroutine.schedule(function()
                WindowerEvents.Equipment.MainWeaponChanged:trigger(windower.ffxi.get_player().id, main_weapon_id)
                IpcRelay.shared():send_message(EquipmentChangedMessage.new(windower.ffxi.get_player().id, main_weapon_id, ranged_weapon_id))
            end, 1)
        -- Ranged weapon
        elseif data:byte(6) == 2 then
            ranged_weapon_id = windower.ffxi.get_items(data:byte(7), data:byte(5)).id
            if ranged_weapon_id == 65535 then
                ranged_weapon_id = nil
            end
            local weapons = require('cylibs/res/weapons')
            if ranged_weapon_id == nil or weapons[ranged_weapon_id] == nil then
                return
            end
            coroutine.schedule(function()
                WindowerEvents.Equipment.RangedWeaponChanged:trigger(windower.ffxi.get_player().id, ranged_weapon_id)
                IpcRelay.shared():send_message(EquipmentChangedMessage.new(windower.ffxi.get_player().id, main_weapon_id, ranged_weapon_id))
            end, 1)
        end
    end,

    [0x068] = function(data)
        local packet = packets.parse('incoming', data)

        local owner_id = packet['Owner ID']
        local pet_index = packet['Pet Index']
        local pet_hpp = packet['Current HP%']
        local pet_mpp = packet['Current MP%']
        local pet_tp = packet['Pet TP']
        local pet_name = packet['Pet Name']

        if owner_id == windower.ffxi.get_player().id then
            local mob = windower.ffxi.get_mob_by_index(pet_index)
            if mob and mob.name == pet_name then
                WindowerEvents.PetUpdate:trigger(owner_id, tonumber(mob.id or 0), tonumber(pet_index or 0), pet_name, pet_hpp, pet_mpp, pet_tp)
            else
                WindowerEvents.PetUpdate:trigger(owner_id, nil, pet_index, pet_name, pet_hpp, pet_mpp, pet_tp)
            end
        end

    end,

    [0x063] = function(data)
        local buff_records = L{}

        for n=1,32 do
            local buff_id = data:unpack('H', n*2+7)
            local buff_ts = data:unpack('I', n*4+69)

            if buff_ts == 0 then
                break
            elseif buff_id ~= 255 and buff_ts ~= nil then
                local duration = math.floor(buff_ts / 60 + bufftime_offset) - os.time()
                buff_records:append(BuffRecord.new(buff_id, duration))
            end
        end

        if buff_records:length() > 0 then
            WindowerEvents.BuffDurationChanged:trigger(windower.ffxi.get_player().id, buff_records)
        end
    end

}

-- Jump table with a mapping of message_id to handler for that message_id
local outgoing_event_dispatcher = {

    -- 0x015
    -- Updates (x, y, z) and target_index and gets sent very rapidly
    -- Very reliable values
    -- Only works for player
    [0x015] = function(data)
        local packet = packets.parse('outgoing', data)

        local target_id = windower.ffxi.get_player().id
        local x = packet['X']
        local y = packet['Y']
        local z = packet['Z']

        WindowerEvents.PositionChanged:trigger(target_id, x, y, z)
        WindowerEvents.TargetIndexChanged:trigger(target_id, packet['Target Index'])

        IpcRelay.shared():send_message(MobUpdateMessage.new(windower.ffxi.get_player().name, x, y, z))
    end,

    [0x05E] = function(data)
        local packet = packets.parse('outgoing', data)

        local player = windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id)

        local x = player.x
        local y = player.y
        local z = player.z
        local zone_id = windower.ffxi.get_info().zone
        local zone_line = packet['Zone Line']
        local zone_type = packet['Zone Type']

        WindowerEvents.ZoneRequest:trigger(player.id, zone_id, zone_line, zone_type)

        IpcRelay.shared():send_message(ZoneMessage.new(player.name, player.id, zone_id, zone_line, zone_type, x, y, z))
    end,

    [0x102] = function(data)
        local packet = packets.parse('outgoing', data)

        local main_job = packet['Main Job']
        local sub_job = packet['Sub Job']

        if main_job == 16 or sub_job == 16 then
            WindowerEvents.BlueMagic.SpellsChanged:trigger()
        end
    end

}

--[[
    number id -- message ID
    string original -- original packet data (only used param right now, called data)
    string modified -- modified packet data, from other addons?
    bool injected -- was_injected?
    bool blocked -- was_blocked?
]]--
local function incoming_chunk_handler(id, data)
    if not incoming_event_ids[id] or not data then return end -- if we don't care about the incoming_event_id, just return

    -- Check our dispatcher table for a function to handle this event_id
    local dispatch = incoming_event_dispatcher[id]
    -- If found, call handler to dispatch events
    if dispatch then
        -- call dispatch function from table (jump table implementation)
        dispatch(data)
    else
        return
    end
end

--[[
    number id -- message ID
    string original -- original packet data (only used param right now, called data)
    string modified -- modified packet data, from other addons?
    bool injected -- was_injected?
    bool blocked -- was_blocked?
]]--
local function outgoing_chunk_handler(id, data)
    if not outgoing_event_ids[id] or not data then return end -- if we don't care about the outgoing_event_id, just return

    -- Check our dispatcher table for a function to handle this event_id
    local dispatch = outgoing_event_dispatcher[id]
    -- If found, call handler to dispatch events
    if dispatch then
        -- call dispatch function from table (jump table implementation)
        dispatch(data)
    else
        return
    end

end

local IncomingChunkHandler = windower.register_event('incoming chunk', incoming_chunk_handler)
local OutgoingChunkHandler = windower.register_event('outgoing chunk', outgoing_chunk_handler)

local EventToPackets = {
    [WindowerEvents.AllianceMemberListUpdate] = L{ 0x0C8 },
    [WindowerEvents.CharacterUpdate] = L{ 0x0DD, 0x0DF },
    [WindowerEvents.BuffDurationChanged] = L{ 0x063 },
}

-- Replay necessary packets
function WindowerEvents.replay_last_events(events)
    for event in events:it() do
        if event == WindowerEvents.AllianceMemberListUpdate then
            incoming_chunk_handler(0x0C8, windower.packets.last_incoming(0x0C8))
        elseif event == WindowerEvents.CharacterUpdate then
            incoming_chunk_handler(0x0DD, windower.packets.last_incoming(0x0DD))
            incoming_chunk_handler(0x0DF, windower.packets.last_incoming(0x0DF))
        elseif event == WindowerEvents.BuffDurationChanged then
            incoming_chunk_handler(0x063, windower.packets.last_incoming(0x063))
        end
    end
end

function WindowerEvents.can_replay_last_event(event)
    if event == WindowerEvents.BuffDurationChanged then
        return windower.packets.last_incoming(0x063) ~= nil
    end
    return false
end

function WindowerEvents.replay_last_event(event)
    WindowerEvents.replay_last_events(L{ event })
end

WindowerEvents.Events = {}

WindowerEvents.Events.GainBuff = windower.register_event('gain buff', function(_)
    local target_id = windower.ffxi.get_player().id

    local buff_ids = party_util.get_buffs(target_id)
    WindowerEvents.BuffsChanged:trigger(target_id, L(buff_util.buffs_for_buff_ids(buff_ids)))
    WindowerEvents.DebuffsChanged:trigger(target_id, L(buff_util.debuffs_for_buff_ids(buff_ids)))
end)

WindowerEvents.Events.LoseBuff = windower.register_event('lose buff', function(_)
    local target_id = windower.ffxi.get_player().id

    local buff_ids = party_util.get_buffs(target_id)
    WindowerEvents.BuffsChanged:trigger(target_id, L(buff_util.buffs_for_buff_ids(buff_ids)))
    WindowerEvents.DebuffsChanged:trigger(target_id, L(buff_util.debuffs_for_buff_ids(buff_ids)))
end)

local init_timer = Timer.scheduledTimer(5, 1)

WindowerEvents.DisposeBag:add(init_timer:onTimeChange():addAction(function(_)
    -- Create weapons
    main_weapon_id = inventory_util.get_main_weapon_id()
    if main_weapon_id and main_weapon_id ~= 0 then
        init_timer:destroy()
        WindowerEvents.Equipment.MainWeaponChanged:trigger(windower.ffxi.get_player().id, main_weapon_id)
    end
end), init_timer:onTimeChange())

WindowerEvents.DisposeBag:add(IpcRelay.shared():on_message_received():addAction(function(ipc_message)
    if ipc_message.__class == MobUpdateMessage.__class then
        local mob = windower.ffxi.get_mob_by_name(ipc_message:get_mob_name())
        if mob == nil then
            local follower = player.trust.main_job:role_with_type("follower")
            if follower and follower:get_follow_target() and follower:get_follow_target():get_name() == ipc_message:get_mob_name() then
                mob = follower:get_follow_target()
            end
        end
        if mob then
            WindowerEvents.PositionChanged:trigger(mob.id, ipc_message:get_position()[1], ipc_message:get_position()[2], ipc_message:get_position()[3])
        end
    elseif ipc_message.__class == ZoneMessage.__class then
        WindowerEvents.ZoneRequest:trigger(ipc_message:get_mob_id(), ipc_message:get_zone_id(), ipc_message:get_zone_line(), ipc_message:get_zone_type())
    elseif ipc_message.__class == EquipmentChangedMessage.__class then
        WindowerEvents.Equipment.MainWeaponChanged:trigger(ipc_message:get_mob_id(), ipc_message:get_main_weapon_id())
        WindowerEvents.Equipment.RangedWeaponChanged:trigger(ipc_message:get_mob_id(), ipc_message:get_ranged_weapon_id())
    end
end), IpcRelay.shared():on_message_received())

init_timer:start()

return WindowerEvents
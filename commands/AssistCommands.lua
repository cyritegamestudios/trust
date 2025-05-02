local CommandMessage = require('cylibs/messages/command_message')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TargetLock = require('cylibs/entity/party/target_lock')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local AssistTrustCommands = setmetatable({}, {__index = TrustCommands })
AssistTrustCommands.__index = AssistTrustCommands
AssistTrustCommands.__class = "AssistTrustCommands"

function AssistTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), AssistTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    local party_member_names = trust:get_party():get_party_members(true):map(function(p) return p:get_name() end)

    self:add_command('default', self.handle_assist_player, 'Assist a party or alliance member', L{
        PickerConfigItem.new('party_member_name', party_member_names[1], party_member_names, nil, "Party Member Name"),
        PickerConfigItem.new('mirror', "true", L{ "true", "false" }, nil, "Mirror Combat Position")
    })
    self:add_command('me', self.handle_assist_me, 'Make all players assist me')
    self:add_command('clear', self.handle_clear_assist, 'Clear assist target')
    self:add_command('lock', self.handle_lock_target, 'Locks your target on the party\'s current battle target until it dies (use for Aminon only)')

    trust:get_party():on_party_members_changed():addAction(function(party_members)
        local party_member_names = party_members:map(function(p) return p:get_name() end)

        self:add_command('default', self.handle_assist_player, 'Assist a party or alliance member', L{
            PickerConfigItem.new('party_member_name', party_member_names[1], party_member_names, nil, "Party Member Name"),
            PickerConfigItem.new('mirror', "true", L{ "true", "false" }, nil, "Mirror Combat Position")
        })
    end)

    return self
end

function AssistTrustCommands:get_command_name()
    return 'assist'
end

-- // trust assist player_name [mirror]
function AssistTrustCommands:handle_assist_player(party_member_name, mirror)
    local success
    local message

    party_member_name = party_member_name:gsub("^%l", string.upper)

    local alliance_member = self.trust:get_alliance():get_alliance_member_named(party_member_name)
    if alliance_member then
        success = true
        message = "Now assisting "..party_member_name

        self.trust:get_party():set_assist_target(alliance_member)

        if mirror then
            for mode_name in L{ 'CombatMode' }:it() do
                handle_set(mode_name, 'Mirror')
            end
            message = message.." (mirroring combat distance)"
        end

        if state.AutoPullMode and state.AutoPullMode.value ~= 'Off' then
            if party_member_name ~= windower.ffxi.get_player().name then
                state.AutoPullMode:set('Off')
                self.trust:get_party():add_to_chat(self.trust:get_party():get_player(), "I can't pull when I'm assisting someone else, so I'm going to stop pulling.")
            end
        end
    else
        success = false
        message = (party_member_name or 'nil')..' is not a valid party member'
    end

    return success, message
end

-- // trust assist me
function AssistTrustCommands:handle_assist_me()
    local success
    local message

    if L{'All', 'Send'}:contains(state.IpcMode.value) then
        IpcRelay.shared():send_message(CommandMessage.new('trust assist '..windower.ffxi.get_player().name))
        success = true
        message = 'Assist set to me on everyone else'
    else
        success = false
        message = 'IpcMode must be set to All or Send to use this command'
    end

    return success, message
end

-- // trust assist clear
function AssistTrustCommands:handle_clear_assist()
    if self.target_lock then
        self.target_lock:destroy()
        self.target_lock = nil
    end

    return self:handle_assist_player(windower.ffxi.get_player().name)
end

-- // trust assist party
function AssistTrustCommands:handle_lock_target()
    local success
    local message

    local battle_target = windower.ffxi.get_mob_by_target('bt')
    if battle_target then
        self:handle_clear_assist()

        self.target_lock = TargetLock.new(battle_target.index)
        self.target_lock:monitor()

        self.target_lock:on_target_ko():addAction(function(_, _)
            self:handle_clear_assist()
        end)

        self.trust:get_party():set_assist_target(self.target_lock)

        success = true
        message = 'Target locked to '..battle_target.name
    else
        success = false
        message = 'The party must be fighting something to lock onto a target'
    end

    return success, message
end

return AssistTrustCommands
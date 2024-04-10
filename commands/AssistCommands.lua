local TrustCommands = require('cylibs/trust/commands/trust_commands')
local AssistTrustCommands = setmetatable({}, {__index = TrustCommands })
AssistTrustCommands.__index = AssistTrustCommands
AssistTrustCommands.__class = "AssistTrustCommands"

function AssistTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), AssistTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('default', self.handle_assist_player, 'Assist a party or alliance member, // trust assist player_name')
    self:add_command('me', self.handle_assist_me, 'Make all players assist me')
    self:add_command('clear', self.handle_clear_assist, 'Clear assist target')

    return self
end

function AssistTrustCommands:get_command_name()
    return 'assist'
end

-- // trust assist player_name
function AssistTrustCommands:handle_assist_player(party_member_name)
    local success
    local message

    local alliance_member = self.trust:get_alliance():get_alliance_member_named(party_member_name)
    if alliance_member then
        success = true
        message = "Now assisting "..party_member_name

        self.trust:get_party():set_assist_target(alliance_member)

        if state.AutoPullMode and state.AutoPullMode.value ~= 'Off' then
            state.AutoPullMode:set('Off')
            self.trust:get_party():add_to_chat(self.trust:get_party():get_player(), "I can't pull when I'm assisting someone else, so I'm going to stop pulling.")
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
    return self:handle_assist_player(windower.ffxi.get_player().name)
end

return AssistTrustCommands
function handle_shortcut(cmd, ...)
    -- Skillchains
    if cmd == 'sc' then
        local mode_var = arg[1]
        if mode_var == 'auto' then
            toggle_mode('AutoSkillchainMode', 'Auto', 'Off')
        elseif mode_var == 'spam' then
            toggle_mode('AutoSkillchainMode', 'Spam', 'Off')
        elseif mode_var == 'cleave' then
            toggle_mode('AutoSkillchainMode', 'Cleave', 'Off')
        elseif mode_var == 'am' then
            toggle_mode('AutoAftermathMode', 'Auto', 'Off')
        elseif mode_var == 'partner' then
            toggle_mode('SkillchainPartnerMode', 'Auto', 'Off')
        elseif mode_var == 'open' then
            toggle_mode('SkillchainPartnerMode', 'Open', 'Off')
        elseif mode_var == 'close' then
            toggle_mode('SkillchainPartnerMode', 'Close', 'Off')
        elseif mode_var == 'prefer' then
            toggle_mode('SkillchainPriorityMode', 'Prefer', 'Off')
        elseif mode_var == 'strict' then
            toggle_mode('SkillchainPriorityMode', 'Strict', 'Off')
        end
    -- Pulling
    elseif cmd == 'pull' then
        local mode_var = arg[1]
        if mode_var == 'auto' then
            toggle_mode('AutoPullMode', 'Auto', 'Off')
        elseif mode_var == 'multi' then
            toggle_mode('AutoPullMode', 'Multi', 'Off')
        elseif mode_var == 'target' then
            toggle_mode('AutoPullMode', 'Target', 'Off')
        end
    -- Engaging
    elseif cmd == 'engage' then
        local mode_var = arg[1]
        if mode_var == 'always' then
            toggle_mode('AutoEngageMode', 'Always', 'Off')
        elseif mode_var == 'assist' then
            toggle_mode('AutoEngageMode', 'Assist', 'Off')
        end
    -- Send
    elseif cmd == 'sendall' then
        local windower_command = ''
        for _, token in ipairs(arg) do
            if token == 'me' then
                token = windower.ffxi.get_player().name
            end
            windower_command = windower_command..token..' '
        end
        if #windower_command > 0 then
            if L{'All', 'Send'}:contains(state.IpcMode.value) then
                IpcRelay.shared():send_message(CommandMessage.new(windower_command))
            else
                error('IpcMode must be set to All or Send to use this command')
            end
        end
    elseif cmd == 'send' then
        local target_name = arg[1]

        local windower_command = ''
        for i, token in ipairs(arg) do
            if i > 1 then
                if token == 'me' then
                    token = windower.ffxi.get_player().name
                end
                windower_command = windower_command..token..' '
            end
        end
        if #windower_command > 0 then
            if L{'All', 'Send'}:contains(state.IpcMode.value) then
                IpcRelay.shared():send_message(CommandMessage.new(windower_command, target_name))
            else
                error('IpcMode must be set to All or Send to use this command')
            end
        end
    elseif cmd == 'assist' then
        local param = arg[1]
        local party_member = player.party:get_party_member_named(param)
        if party_member then
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Okay, I'll assist "..param.." in battle.")
            player.party:set_assist_target(party_member)
        end
    -- Following
    elseif cmd == 'follow' then
        local trust = player.trust.main_job
        local follower = trust:role_with_type("follower")
        if follower then
            local param = arg[1]
            if param == 'me' then
                if L{'All', 'Send'}:contains(state.IpcMode.value) then
                    follower:set_follow_target(nil)
                    IpcRelay.shared():send_message(CommandMessage.new('trust follow '..windower.ffxi.get_player().name))
                else
                    error('IpcMode must be set to All or Send to use this command')
                end
            elseif param == 'stopall' then
                if L{'All', 'Send'}:contains(state.IpcMode.value) then
                    IpcRelay.shared():send_message(CommandMessage.new('trust set AutoFollowMode Off'))
                else
                    error('IpcMode must be set to All or Send to use this command')
                end
            elseif param:match("^%d+$") then
                local distance = tonumber(param)
                follower:set_distance(distance)
                addon_message(207, 'Follow distance set to '..distance)
            else
                if follower:is_valid_target(param) then
                    handle_set('AutoFollowMode', 'Always')
                    local error_message = follower:follow_target_named(param)
                    if error_message then
                        error(error_message)
                    end
                end
            end
        end
    end
end

function toggle_mode(mode_var_name, on_value, off_value)
    local mode_var = get_state(mode_var_name)
    if mode_var.value == on_value then
        handle_set(mode_var_name, off_value)
    else
        handle_set(mode_var_name, on_value)
    end
end

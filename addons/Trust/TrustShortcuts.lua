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
    end
    --[[local command = ''
    for _,v in ipairs(arg) do
        command = command..' '..tostring(v)
    end
    if not command:empty() then
        windower.send_command('@input '..command:trim())
        --action_queue:push_action(CommandAction.new(0, 0, 0, command:trim()), true)
    end]]
end

function toggle_mode(mode_var_name, on_value, off_value)
    local mode_var = get_state(mode_var_name)
    if mode_var.value == on_value then
        handle_set(mode_var_name, off_value)
    else
        handle_set(mode_var_name, on_value)
    end
end

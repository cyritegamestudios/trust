function handle_shortcut(cmd, ...)
    -- Skillchains
    if cmd == 'sc' then
        local mode_var = arg[1]
        if mode_var == 'auto' then
            if state.AutoSkillchainMode.value == 'Off' then
                handle_set('AutoSkillchainMode', 'Auto')
            else
                handle_set('AutoSkillchainMode', 'Off')
            end
        elseif mode_var == 'spam' then
            handle_set('AutoSkillchainMode', 'Spam')
        elseif mode_var == 'cleave' then
            handle_set('AutoSkillchainMode', 'Cleave')
        elseif mode_var == 'am' then
            handle_cycle('AutoAftermathMode')
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
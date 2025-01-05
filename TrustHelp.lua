local registered_state_names = T{}
local is_help_text_enabled = false

function register_help_text(state_name, state_var)
    if registered_state_names[state_name] then
        return
    end

    registered_state_names[state_name] = state_var:on_state_change():addAction(function(m, new_value, hide_help_text)
        local description = m:get_description(new_value)
        if description and not hide_help_text then
            display_help_text(description)
        end
    end)
end

function unregister_help_text(state_name, state_var)
    if registered_state_names[state_name] then
        state_var:on_state_change():removeAction(registered_state_names[state_name])
    end
    registered_state_names[state_name] = nil
end

function display_help_text(text)
    if not is_help_text_enabled or player.party == nil then
        return
    end
    player.party:add_to_chat(player.party:get_player(), text)
end

function set_help_text_enabled(enabled)
    is_help_text_enabled = enabled
end
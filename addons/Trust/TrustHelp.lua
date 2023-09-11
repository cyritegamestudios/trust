local registered_state_names = T{}
local is_help_text_enabled = false

function register_help_text(state_name, state_var)
    if registered_state_names[state_name] then
        return
    end

    registered_state_names[state_name] = state_var:on_state_change():addAction(function(m, new_value)
        local description = m:get_description(new_value)
        if description then
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
    if not is_help_text_enabled then
        return
    end
    addon_message(260, '('..windower.ffxi.get_player().name..') '..text)
end

function set_help_text_enabled(enabled)
    is_help_text_enabled = enabled
end

function handle_help()
    if player.main_job_name_short then
        local job = res.jobs:with('ens', player.main_job_name_short)
        if job then
            local url_suffix = job.name:gsub(" ", "-")
            windower.open_url(settings.help.wiki_base_url..'/'..url_suffix)
            return
        end
    end
    windower.open_url(settings.help.wiki_base_url)
end
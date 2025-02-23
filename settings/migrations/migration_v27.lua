---------------------------
-- Migrates remote commands whitelist to database.
-- @class module
-- @name Migration_v27

local Migration = require('settings/migrations/migration')
local Migration_v27 = setmetatable({}, { __index = Migration })
Migration_v27.__index = Migration_v27
Migration_v27.__class = "Migration_v27"

function Migration_v27.new()
    local self = setmetatable(Migration.new(), Migration_v27)
    return self
end

function Migration_v27:shouldPerform(_, addonSettings, _)
    return addonSettings:getSettings().remote_commands and addonSettings:getSettings().remote_commands.whitelist
            and not L(addonSettings:getSettings().remote_commands.whitelist):empty()
end

function Migration_v27:perform(_, addonSettings, _)
    local User = require('settings/settings').Whitelist

    local whitelist = L(addonSettings:getSettings().remote_commands.whitelist)
    for name in whitelist:it() do
        local user = User({
            id = name
        })
        user:save()
    end
    addonSettings:getSettings().remote_commands.whitelist = L{}
    addonSettings:saveSettings(true)
end

function Migration_v27:getDescription()
    return "Migrating remote commands whitelist."
end

return Migration_v27





local Migration = {}
Migration.__index = Migration

function Migration.new()
    local self = setmetatable({}, Migration)
    return self
end

function Migration:shouldPerform(trustSettings, addonSettings, weaponSkillSettings)
    return false
end

function Migration:shouldRepeat()
    return false
end

function Migration:perform(trustSettings, addonSettings, weaponSkillSettings)
end

function Migration:getDescription()
    return ""
end

function Migration:getMigrationCode()
    return tostring(self.__class)
end

return Migration
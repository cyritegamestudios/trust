local Migration = {}
Migration.__index = Migration

function Migration.new()
    local self = setmetatable({}, Migration)
    return self
end

function Migration:perform(trustSettings, addonSettings, weaponSkillSettings)
end

function Migration:getMigrationCode()
    return tostring(self.__class)
end

return Migration
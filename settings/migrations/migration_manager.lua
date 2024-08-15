local Migration_v1 = require('settings/migrations/migration_v1')

local MigrationManager = {}
MigrationManager.__index = MigrationManager

function MigrationManager.new(trustSettings, addonSettings, weaponSkillSettings)
    local self = setmetatable({}, MigrationManager)

    self.trustSettings = trustSettings
    self.addonSettings = addonSettings
    self.weaponSkillSettings = weaponSkillSettings
    self.migrations = L{
        Migration_v1.new()
    }

    return self
end

function MigrationManager:perform()
    local currentMigrations = S(self.trustSettings:getSettings().Migrations or L{})
    local shouldSaveSettings = false

    for migration in self.migrations:it() do
        if not currentMigrations:contains(migration:getMigrationCode()) and migration:shouldPerform(self.trustSettings, self.addonSettings, self.weaponSkillSettings) then
            shouldSaveSettings = true
            migration:perform(self.trustSettings, self.addonSettings, self.weaponSkillSettings)
            currentMigrations:add(migration:getMigrationCode())
        end
    end

    if shouldSaveSettings then
        self.trustSettings:getSettings().Migrations = L(currentMigrations)
        self.trustSettings:saveSettings(true)
    end
end

return MigrationManager
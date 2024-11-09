local Migration_v1 = require('settings/migrations/migration_v1')
local Migration_v2 = require('settings/migrations/migration_v2')
local Migration_v3 = require('settings/migrations/migration_v3')
local Migration_v4 = require('settings/migrations/migration_v4')
local Migration_v5 = require('settings/migrations/migration_v5')
local Migration_v6 = require('settings/migrations/migration_v6')
local Migration_v7 = require('settings/migrations/migration_v7')
local Migration_v8 = require('settings/migrations/migration_v8')
local Migration_v9 = require('settings/migrations/migration_v9')
local Migration_v10 = require('settings/migrations/migration_v10')
local Migration_v11 = require('settings/migrations/migration_v11')
local UpdateDefaultGambits = require('settings/migrations/update_default_gambits')

local MigrationManager = {}
MigrationManager.__index = MigrationManager

function MigrationManager.new(trustSettings, addonSettings, weaponSkillSettings)
    local self = setmetatable({}, MigrationManager)

    self.trustSettings = trustSettings
    self.addonSettings = addonSettings
    self.weaponSkillSettings = weaponSkillSettings
    self.migrations = L{
        Migration_v1.new(),
        Migration_v2.new(),
        Migration_v3.new(),
        Migration_v4.new(),
        Migration_v5.new(),
        Migration_v6.new(),
        Migration_v7.new(),
        Migration_v8.new(),
        Migration_v9.new(),
        Migration_v10.new(),
        Migration_v11.new(),
        UpdateDefaultGambits.new(),
    }
    return self
end

function MigrationManager:perform()
    local currentMigrations = S(self.trustSettings:getSettings().Migrations or L{})

    addon_system_message("Checking for updates on "..self.trustSettings.jobNameShort.."...")

    local migrationsToRun = self.migrations:filter(function(migration)
        local shouldPerform = migration:shouldPerform(self.trustSettings, self.addonSettings, self.weaponSkillSettings)
        if shouldPerform then
            return migration:shouldRepeat() or not currentMigrations:contains(migration:getMigrationCode())
        end
        return false
    end)

    local migrationStep = 1

    for migration in migrationsToRun:it() do
        migration:perform(self.trustSettings, self.addonSettings, self.weaponSkillSettings)
        currentMigrations:add(migration:getMigrationCode())
        addon_system_message("("..migrationStep.."/"..migrationsToRun:length()..") "..migration:getDescription())
        migrationStep = migrationStep + 1
    end

    if migrationsToRun:length() > 0 then
        self.trustSettings:getSettings().Migrations = L(currentMigrations)
        self.trustSettings:saveSettings(true)

        if self.weaponSkillSettings then
            self.weaponSkillSettings:saveSettings(true)
        end
    end
end

return MigrationManager
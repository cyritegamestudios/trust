local M = require('settings/migrations/Migrations-Include')

local UpdateDefaultGambits = require('settings/migrations/update_default_gambits')

local MigrationManager = {}
MigrationManager.__index = MigrationManager

function MigrationManager.new(trustSettings, addonSettings, weaponSkillSettings)
    local self = setmetatable({}, MigrationManager)

    self.trustSettings = trustSettings
    self.addonSettings = addonSettings
    self.weaponSkillSettings = weaponSkillSettings
    self.migrations = L{
        M.Migration_v1.new(),
        M.Migration_v2.new(),
        M.Migration_v3.new(),
        M.Migration_v4.new(),
        M.Migration_v5.new(),
        M.Migration_v6.new(),
        M.Migration_v8.new(),
        M.Migration_v9.new(),
        M.Migration_v10.new(),
        M.Migration_v11.new(),
        M.Migration_v12.new(),
        M.Migration_v13.new(),
        M.Migration_v14.new(),
        M.Migration_v15.new(),
        M.Migration_v16.new(),
        M.Migration_v18.new(),
        M.Migration_v19.new(),
        M.Migration_v20.new(),
        M.Migration_v21.new(),
        M.Migration_v22.new(),
        M.Migration_v23.new(),
        M.Migration_v24.new(),
        M.Migration_v25.new(),
        M.Migration_v26.new(),
        M.Migration_v27.new(),
        M.Migration_v28.new(),
        M.Migration_v29.new(),
        M.Migration_v30.new(),
        M.Migration_v31.new(),
        M.Migration_v32.new(),
        M.Migration_v33.new(),
        M.Migration_v34.new(),
        UpdateDefaultGambits.new(),
    }
    return self
end

function MigrationManager:perform()
    if self.trustSettings.isFirstLoad then
        self.trustSettings:getSettings().Migrations = self:getAllMigrationCodes()
    end

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

    if migrationsToRun:length() > 0 or self.trustSettings.isFirstLoad then
        self.trustSettings:getSettings().Migrations = L(currentMigrations)
        self.trustSettings:saveSettings(true)

        if self.weaponSkillSettings then
            self.weaponSkillSettings:saveSettings(true)
        end
    end
end

function MigrationManager:getAllMigrationCodes()
    return self.migrations:map(function(migration)
        return migration:getMigrationCode()
    end):filter(function(code)
        return code ~= UpdateDefaultGambits.__class
    end)
end

return MigrationManager
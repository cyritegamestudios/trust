local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')

local ImportProfileMenuItem = setmetatable({}, {__index = MenuItem })
ImportProfileMenuItem.__index = ImportProfileMenuItem

function ImportProfileMenuItem.new(trustModeSettings, jobSettings, weaponSkillSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Discord', 18),
    }, {
        Discord = MenuItem.action(function(menu, infoView)
            windower.open_url('https://discord.com/channels/1069136494616399883/1290049758530113588')
        end, "Profiles", "Find profiles shared by other Trusters on Discord.")
    }, nil, "Profiles", "Import a profile from "..windower.addon_path.."data/export/profiles."), ImportProfileMenuItem)

    self.trustModeSettings = trustModeSettings
    self.jobSettings = jobSettings
    self.weaponSkillSettings = weaponSkillSettings
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_)
        local profileListPicker = FFXIPickerView.withItems(self:listFiles(), L{}, false, nil, nil, nil, true)

        profileListPicker:setTitle("Choose a profile to import.")
        profileListPicker:setShouldRequestFocus(true)
        profileListPicker:setAllowsCursorSelection(true)

        self.dispose_bag:add(profileListPicker:on_pick_items():addAction(function(_, selectedItems)
            if selectedItems:length() > 0 then
                local fileName = selectedItems[1]:getText()
                self:loadFile(fileName)
            end
        end), profileListPicker:on_pick_items())

        return profileListPicker
    end

    return self
end

function ImportProfileMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function ImportProfileMenuItem:loadFile(fileName)
    local filePath = windower.addon_path..'data/export/profiles/'..fileName
    local loadProfileSettings, err = loadfile(filePath)
    if err then
        addon_system_error(err)
    else
        local profileSettings = loadProfileSettings()

        local success, message = self:validateProfile(profileSettings)
        if not success then
            addon_system_error(message)
            return
        end

        if profileSettings.SetName == 'Default' then
            addon_system_error("You cannot override the default set.")
            return
        end

        local setName = profileSettings.SetName

        self.jobSettings:createSettings(setName, T(profileSettings.JobSettings))
        self.weaponSkillSettings:createSettings(setName, profileSettings.WeaponSkillSettings)
        self.trustModeSettings:saveSettings(setName, T(profileSettings.ModeSettings), true)

        addon_system_message("Imported profile with name "..setName..".")
    end
end

function ImportProfileMenuItem:validateProfile(profileSettings)
    local trustVersion = profileSettings.TrustVersion
    if trustVersion > _addon.version then
        return false, "You must be running Trust v"..profileSettings.TrustVersion.." or later to import this profile."
    end

    local jobNameShort = profileSettings.JobNameShort
    if jobNameShort ~= player.main_job_name_short then
        return false, "The selected profile is not compatible with the current job."
    end

    local defaultJobSettings = T(self.jobSettings:getDefaultSettings().Default)

    local missingKeys = S(defaultJobSettings:keyset()):diff(T(profileSettings.JobSettings):keyset())
    if missingKeys:length() > 0 then
        return false, "The selected profile is not valid. Missing settings keys: "..localization_util.commas(L(missingKeys)).."."
    end

    return true
end

function ImportProfileMenuItem:listFiles()
    local directoryPath = windower.addon_path..'data/export/profiles/'

    local command = "dir \"" .. directoryPath .. "\" /b"

    local handle = io.popen(command)
    if handle then
        local result = handle:read("*a")
        handle:close()

        local fileNames = L{}
        for fileName in result:gmatch("[^\r\n]+") do
            fileNames:append(fileName)
        end
        return fileNames
    else
        logger.error("Unable to load profiles.")
    end
    return L{}
end

return ImportProfileMenuItem
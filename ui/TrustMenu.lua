
local TrustMenu = {}
TrustMenu.__index = TrustMenu


function TrustMenu.new(addonSettings, actionQueue, addonEnabled, trust, mediaPlayer, soundTheme)
    local self = setmetatable({}, TrustMenu)

    self.addonSettings = addonSettings
    self.actionQueue = actionQueue
    self.addonEnabled = addonEnabled
    self.mediaPlayer = mediaPlayer
    self.soundTheme = soundTheme
    self.trust = trust

    self:init()

    return self
end

function TrustMenu:init()

end

function TrustMenu:getMainMenuItem()
    if self.mainMenuItem then
        return self.mainMenuItem
    end

    local mainMenuItem = MenuItem.new(L{
        ButtonItem.localized(player.main_job_name, i18n.resource('jobs', 'en', player.main_job_name)),
        ButtonItem.localized(player.sub_job_name, i18n.resource('jobs', 'en', player.sub_job_name)),
        ButtonItem.localized('Profiles', i18n.translate('Button_Profiles')),
        ButtonItem.default('Commands', 18),
        ButtonItem.default('Config', 18),
    }, {
        Profiles = LoadSettingsMenuItem.new(self.addon_settings, self.trustModeSettings, main_trust_settings, weapon_skill_settings, sub_trust_settings),
        Config = ConfigSettingsMenuItem.new(self.addon_settings, main_trust_settings, state.MainTrustSettingsMode, self.mediaPlayer, self.widgetManager),
    }, nil, "Jobs")

    self.mainMenuItem = mainMenuItem

    self:reloadJobMenuItems()

    if self.commandsMenuItem then
        self.mainMenuItem:setChildMenuItem("Commands", self.commandsMenuItem)
    end

    return self.mainMenuItem
end

function TrustHud:reloadMainMenuItem()
    local showMenu = self.trustMenu:isVisible()

    self.trustMenu:closeAll()
    self.mainMenuItem:destroy()
    self.mainMenuItem = nil

    self:getMainMenuItem()

    if showMenu then
        self.trustMenu:showMenu(self.mainMenuItem)
    end
end

return TrustMenu
local Event = require('cylibs/events/Luvent')

local TrustAddonSettings = {}
TrustAddonSettings.__index = TrustAddonSettings
TrustAddonSettings.__class = "TrustAddonSettings"

local default = {
    verbose=true
}

default.battle = {}
default.battle.melee_distance = 3
default.battle.range_distance = 21
default.battle.targets = L{'Locus Colibri','Locus Dire Bat','Locus Thousand Eyes','Locus Spartoi Warrior','Locus Spartoi Sorcerer','Locus Hati','Locus Ghost Crab'}
default.battle.trusts = L{'Monberaux','Sylvie (UC)','Koru-Moru','Qultada','Brygid'}
default.chat = {}
default.chat.ipc_enabled = true
default.donate = {}
default.donate.url = 'https://www.buymeacoffee.com/cyrite'
default.follow = {}
default.follow.distance = 1
default.help = {}
default.help.mode_text_enabled = true
default.help.wiki_base_url = 'https://github.com/cyritegamestudios/trust/wiki'
default.hud = {}
default.hud.trust = {}
default.hud.trust.position = {}
default.hud.trust.position.x = 8
default.hud.trust.position.y = 140
default.hud.trust.visible = true
default.hud.auto_hide = false
default.hud.party = {}
default.hud.party.position = {}
default.hud.party.position.x = 8
default.hud.party.position.y = 200
default.hud.party.visible = true
default.hud.target = {}
default.hud.target.position = {}
default.hud.target.position.x = 8
default.hud.target.position.y = 260
default.hud.target.visible = true
default.logging = {}
default.logging.enabled = false
default.logging.logtofile = false
default.menu_key = '%^numpad+'
default.remote_commands = {}
default.remote_commands.whitelist = S{}
default.flags = {}
default.flags.show_death_warning = true
default.flags.check_files = true
default.version = '1.0.0'

function TrustAddonSettings:onSettingsChanged()
    return self.settingsChanged
end

function TrustAddonSettings.new()
    local self = setmetatable({}, TrustAddonSettings)
    self.settingsChanged = Event.newEvent()
    self.settings = {}
    return self
end

function TrustAddonSettings:loadSettings()
    self.settings = config.load(default)
    self:onSettingsChanged():trigger(self.settings)
    return self.settings
end

function TrustAddonSettings:reloadSettings()
    return self:loadSettings(false)
end

function TrustAddonSettings:saveSettings(saveToFile)
    config.save(self.settings)
    self:onSettingsChanged():trigger(self.settings)
end

function TrustAddonSettings:getSettings()
    return self.settings
end

return TrustAddonSettings
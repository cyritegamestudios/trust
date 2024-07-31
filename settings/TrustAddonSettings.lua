local Event = require('cylibs/events/Luvent')

local TrustAddonSettings = {}
TrustAddonSettings.__index = TrustAddonSettings
TrustAddonSettings.__class = "TrustAddonSettings"

local default = {}

default.battle = {}
default.battle.melee_distance = 2
default.battle.range_distance = 21
default.battle.targets = L{'Locus Colibri','Locus Dire Bat','Locus Thousand Eyes','Locus Spartoi Warrior','Locus Spartoi Sorcerer','Locus Hati','Locus Ghost Crab'}
default.battle.trusts = L{'Monberaux','Sylvie (UC)','Koru-Moru','Qultada','Brygid'}
default.chat = {}
default.chat.ipc_enabled = true
default.discord = {}
default.discord.url = 'https://discord.gg/CfPxDy759J'
default.discord.channels = {}
default.discord.channels.support = 'https://discord.com/channels/1069136494616399883/1242295505334173716'
default.donate = {}
default.donate.url = 'https://www.buymeacoffee.com/cyrite'
default.follow = {}
default.follow.distance = 1
default.flags = {}
default.flags.show_death_warning = true
default.flags.check_files = true
default.help = {}
default.help.mode_text_enabled = true
default.help.wiki_base_url = 'https://github.com/cyritegamestudios/trust/wiki'
default.logging = {}
default.logging.enabled = false
default.logging.logtofile = false
default.menu_key = '%^numpad+'
default.party_widget = {}
default.party_widget.x = 4
default.party_widget.y = 373
default.party_widget.visible = true
default.remote_commands = {}
default.remote_commands.whitelist = S{}
default.settings_widget = {}
default.settings_widget.x = 8
default.settings_widget.y = 140
default.settings_widget.visible = true
default.target_widget = {}
default.target_widget.x = 4
default.target_widget.y = 472
default.target_widget.visible = true
default.target_widget.detailed = true
default.trust_widget = {}
default.trust_widget.x = 4
default.trust_widget.y = 300
default.trust_widget.visible = true
default.verbose = true
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
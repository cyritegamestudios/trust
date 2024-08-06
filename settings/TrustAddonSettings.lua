local Event = require('cylibs/events/Luvent')

local TrustAddonSettings = {}
TrustAddonSettings.__index = TrustAddonSettings
TrustAddonSettings.__class = "TrustAddonSettings"

local default = {}

default.battle = {}
default.battle.melee_distance = 2
default.battle.range_distance = 21
default.battle.targets = L{'Apex Bats','Apex Crab','Apex Jagil','Apex Knight Lugcrawler','Apex Rumble Lugcrawler','Apex Toad','Locus Armet Beetle','Locus Colibri','Locus Dire Bat','Locus Ghost Crab'}
default.battle.trusts = L{'Kupipi','Joachim','Koru-Moru','Qultada','Kupofried'}
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
default.party_widget.y = 397
default.party_widget.visible = true
default.remote_commands = {}
default.remote_commands.whitelist = S{}
default.settings_widget = {}
default.settings_widget.x = 8
default.settings_widget.y = 140
default.settings_widget.visible = true
default.target_widget = {}
default.target_widget.x = 4
default.target_widget.y = 496
default.target_widget.visible = true
default.target_widget.detailed = true
default.trust_widget = {}
default.trust_widget.x = 4
default.trust_widget.y = 324
default.trust_widget.visible = true
default.pet_widget = {}
default.pet_widget.x = 4
default.pet_widget.y = 258
default.pet_widget.visible = true
default.verbose = true
default.version = '1.0.0'
default.shortcuts = {}
default.shortcuts.menus = {}
default.shortcuts.menus.modes = {}
default.shortcuts.menus.modes.enabled = false
default.shortcuts.menus.modes.key = "M"
default.shortcuts.menus.modes.flags = 1
default.shortcuts.menus.gambits = {}
default.shortcuts.menus.gambits.enabled = false
default.shortcuts.menus.gambits.key = "G"
default.shortcuts.menus.gambits.flags = 1
default.shortcuts.menus.skillchains = {}
default.shortcuts.menus.skillchains.enabled = false
default.shortcuts.menus.skillchains.key = "S"
default.shortcuts.menus.skillchains.flags = 1
default.shortcuts.widgets = {}
default.shortcuts.widgets.trust = {}
default.shortcuts.widgets.trust.enabled = false
default.shortcuts.widgets.trust.key = "T"
default.shortcuts.widgets.trust.flags = 1
default.shortcuts.widgets.party = {}
default.shortcuts.widgets.party.enabled = false
default.shortcuts.widgets.party.key = "P"
default.shortcuts.widgets.party.flags = 1



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
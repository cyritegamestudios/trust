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
default.updater = {}
default.updater.manifest_url = 'https://raw.githubusercontent.com/cyritegamestudios/trust/main/manifest.json'
default.follow = {}
default.follow.distance = 1
default.follow.auto_pause = false
default.flags = {}
default.flags.show_death_warning = true
default.flags.check_files = true
default.help = {}
default.help.mode_text_enabled = true
default.help.wiki_base_url = 'https://github.com/cyritegamestudios/trust/wiki'
default.logging = {}
default.logging.enabled = false
default.logging.logtofile = false
default.logging.filter_pattern = ''
default.menu_key = '%^numpad+'
default.autocomplete = {}
default.autocomplete.visible = true
default.remote_commands = {} -- can't get rid of because of migration_v27
default.remote_commands.whitelist = S{}
default.verbose = true
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
default.locales = {}
default.locales.font_names = {}
default.locales.font_names.english = "Arial"
default.locales.font_names.japanese = "MS Gothic"
default.locales.actions = {}
default.locales.default = ""
default.sounds = {}
default.sounds.sound_effects = {}
default.sounds.sound_effects.disabled = false
default.gearswap = {}


function TrustAddonSettings:onSettingsChanged()
    return self.settingsChanged
end

function TrustAddonSettings.new()
    local self = setmetatable({}, TrustAddonSettings)

    self.settingsChanged = Event.newEvent()
    self.settings = {}

    return self
end

function TrustAddonSettings:loadFile()
    return coroutine.create(function()
        local settings = config.load(default)
        coroutine.yield(settings)
    end)
end

function TrustAddonSettings:loadSettings()
    local _, settings = coroutine.resume(self:loadFile())
    self.settings = settings
    self:onSettingsChanged():trigger(self.settings)
    return self.settings
end

function TrustAddonSettings:reloadSettings()
    return self:loadSettings()
end

function TrustAddonSettings:saveSettings(saveToFile)
    config.save(self.settings)
    self:onSettingsChanged():trigger(self.settings)
end

function TrustAddonSettings:getSettings()
    return self.settings
end

return TrustAddonSettings
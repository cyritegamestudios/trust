local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local JobGambitSettingsMenuItem = require('ui/settings/menus/gambits/JobGambitSettingsMenuItem')
local TargetSettingsMenuItem = require('ui/settings/menus/TargetSettingsMenuItem')
local BackgroundView = require('cylibs/ui/views/background/background_view')
local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigSettingsMenuItem = require('ui/settings/menus/ConfigSettingsMenuItem')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local Frame = require('cylibs/ui/views/frame')
local GameInfo = require('cylibs/util/ffxi/game_info')
local Keyboard = require('cylibs/ui/input/keyboard')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local ReactionSettingsMenuItem = require('ui/settings/menus/gambits/react/ReactSettingsMenuItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local TrustInfoBar = require('ui/TrustInfoBar')
local Menu = require('cylibs/ui/menu/menu')
local ViewStack = require('cylibs/ui/views/view_stack')
local View = require('cylibs/ui/views/view')

local TrustHud = setmetatable({}, {__index = View })
TrustHud.__index = TrustHud

function TrustHud:onEnabledClick()
    return self.enabledClick
end

function TrustHud.new(player, action_queue, addon_settings, trustModeSettings, addon_enabled, menu_width, menu_height, mediaPlayer, soundTheme)
    local self = setmetatable(View.new(), TrustHud)

    FFXIWindow.setDefaultMediaPlayer(mediaPlayer)
    FFXIWindow.setDefaultSoundTheme(soundTheme)
    FFXIPickerView.setDefaultMediaPlayer(mediaPlayer)
    FFXIPickerView.setDefaultSoundTheme(soundTheme)

    self.mediaPlayer = mediaPlayer
    self.soundTheme = soundTheme
    self.menuSize = Frame.new(0, 0, menu_width, menu_height)
    self.viewStack = ViewStack.new(Frame.new(16, 48, 0, 0))
    self.actionQueue = action_queue
    self.addon_settings = addon_settings
    self.trustModeSettings = trustModeSettings
    self.player = player
    self.party = player.party
    self.gameInfo = GameInfo.new()
    self.menuViewStack = ViewStack.new(Frame.new(windower.get_windower_settings().ui_x_res - 128, 52, 0, 0))
    self.menuViewStack.name = "menu stack"
    --self.mainMenuItem = self:getMainMenuItem()

    self.infoViewContainer = View.new(Frame.new(17, 17, windower.get_windower_settings().ui_x_res - 18, 27))
    self.infoBar = TrustInfoBar.new(Frame.new(0, 0, windower.get_windower_settings().ui_x_res - 18, 27))
    self.infoBar:setVisible(false)

    FFXIPickerView.setDefaultInfoView(self.infoBar)

    self.infoViewContainer:addSubview(self.infoBar)

    self.infoViewContainer:setNeedsLayout()
    self.infoViewContainer:layoutIfNeeded()

    self.trustMenu = Menu.new(self.viewStack, self.menuViewStack, self.infoBar, self.mediaPlayer, self.soundTheme)

    self.backgroundImageView = self:getBackgroundImageView()

    for mode in L{ state.MainTrustSettingsMode, state.SubTrustSettingsMode }:it() do
        self:getDisposeBag():add(mode:on_state_change():addAction(function(m, new_value, old_value)
            if old_value == new_value then
                return
            end
            self:reloadJobMenuItems()
        end), mode:on_state_change())
    end

    self:getDisposeBag():add(i18n.onLocaleChanged():addAction(function(_)
        self:reloadMainMenuItem()
    end), i18n.onLocaleChanged())

    -- To initialize it
    local Mouse = require('cylibs/ui/input/mouse')
    Mouse.input()

    return self
end

function TrustHud:destroy()
    if self.events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
    self.viewStack:dismissAll()
    self.viewStack:destroy()
    self.click:removeAllEvents()
    self.layout:destroy()

    for _, itemView in pairs(self.itemViews) do
        itemView:destroy()
    end
end

function TrustHud:getMenuItem(configKey)
    if configKey then
        if self.mainMenuItem == nil then
            self.mainMenuItem = self:getMainMenuItem()
        end
        local stack = L{ self.mainMenuItem:getChildMenuItem(player.main_job_name) }
        while stack:length() > 0 do
            local menuItem = stack:remove(1)
            if menuItem:getConfigKey() == configKey then
                return menuItem
            end
            stack = stack + menuItem:getChildMenuItems()
        end
    end
    return nil
end

function TrustHud:layoutIfNeeded()
    View.layoutIfNeeded(self)

    self.infoBar:setNeedsLayout()
    self.infoBar:layoutIfNeeded()
end

function TrustHud:getViewStack()
    return self.viewStack
end

function TrustHud:toggleMenu()
    self.trustMenu:closeAll()

    if self.mainMenuItem == nil then
        self.mainMenuItem = self:getMainMenuItem()
    end

    self.trustMenu:showMenu(self.mainMenuItem)
end

function TrustHud:closeAllMenus()
    self.trustMenu:closeAll()
end

function TrustHud:openMenu(menuItem)
    if not self.trustMenu:isVisible() and menuItem then
        self.trustMenu:closeAll()
        self.trustMenu:showMenu(menuItem)
    end
end

function TrustHud:getBackgroundImageView()
    return BackgroundView.new(Frame.new(0, 0, self.menuSize.width, self.menuSize.height),
            windower.addon_path..'assets/backgrounds/menu_bg_top.png',
            windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
            windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')
end

function TrustHud:reloadJobMenuItems()
    if self.mainMenuItem == nil then
        return
    end

    local oldMainJobItem = self.mainMenuItem:getChildMenuItem(player.main_job_name)
    if oldMainJobItem then
        oldMainJobItem:destroy()
    end

    local oldSubJobItem = self.mainMenuItem:getChildMenuItem(player.sub_job_name)
    if oldSubJobItem then
        oldSubJobItem:destroy()
    end

    local mainJobItem = self:getMenuItems(player.trust.main_job, main_trust_settings, state.MainTrustSettingsMode, weapon_skill_settings, state.WeaponSkillSettingsMode, trust_mode_settings, player.main_job_name_short, player.main_job_name)
    local subJobItem = self:getMenuItems(player.trust.sub_job, sub_trust_settings, state.SubTrustSettingsMode, nil, nil, trust_mode_settings, player.sub_job_name_short, player.sub_job_name)

    local statusMenuItem = self:getStatusMenuItem(player.trust.main_job)

    mainJobItem:setChildMenuItem("Status", statusMenuItem)
    subJobItem:setChildMenuItem("Status", statusMenuItem)

    if mainJobItem:getChildMenuItem('Settings'):getChildMenuItem('Pulling') == nil then
        local pullerMenuItem = subJobItem:getChildMenuItem('Settings'):getChildMenuItem('Pulling')
        if pullerMenuItem then
            mainJobItem:getChildMenuItem('Settings'):setChildMenuItem('Pulling', pullerMenuItem)
        end
    end

    self.mainMenuItem:setChildMenuItem(player.main_job_name, mainJobItem)

    if player.sub_job_name ~= 'None' then
        self.mainMenuItem:setChildMenuItem(player.sub_job_name, subJobItem)
    end
end

function TrustHud:setCommands(commands)
    self.commands = commands
end

function TrustHud:getMainMenuItem()
    if self.mainMenuItem then
        return self.mainMenuItem
    end

    local LoadSettingsMenuItem = require('ui/settings/menus/loading/LoadSettingsMenuItem')

    local mainMenuItem = MenuItem.new(L{
        ButtonItem.localized(player.main_job_name, i18n.resource('jobs', 'en', player.main_job_name)),
        ButtonItem.localized(player.sub_job_name, i18n.resource('jobs', 'en', player.sub_job_name)),
        ButtonItem.localized('Profiles', i18n.translate('Button_Profiles')),
        ButtonItem.default('Commands', 18),
        ButtonItem.default('Config', 18),
    }, {
        Profiles = LoadSettingsMenuItem.new(self.addon_settings, self.trustModeSettings, main_trust_settings, weapon_skill_settings, sub_trust_settings),
        Config = ConfigSettingsMenuItem.new(self.addon_settings, main_trust_settings, state.MainTrustSettingsMode, self.mediaPlayer),
    }, nil, "Jobs")

    self.mainMenuItem = mainMenuItem

    self:reloadJobMenuItems()

    local CommandsMenuItem = require('ui/settings/menus/commands/CommandsMenuItem')
    self.mainMenuItem:setChildMenuItem('Commands', CommandsMenuItem.new(self.commands))

    return self.mainMenuItem
end

function TrustHud:reloadMainMenuItem()
    local showMenu = self.trustMenu:isVisible()

    self.trustMenu:closeAll()
    if self.mainMenuItem then
        self.mainMenuItem:destroy()
        self.mainMenuItem = nil
    end

    if showMenu then
        self.trustMenu:showMenu(self:getMainMenuItem())
    end
end

local function setupView(view, viewSize, hideBackground)
    if not hideBackground then
        --view:setBackgroundImageView(createBackgroundView(viewSize.width, viewSize.height))
    end
    --view:setNavigationBar(createTitleView(viewSize))
    view:setSize(viewSize.width, viewSize.height)
    return view
end

function TrustHud:getSettingsMenuItem(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, jobNameShort)
    local viewSize = Frame.new(0, 0, 500, 500)

    local DebuffSettingsMenuItem = require('ui/settings/menus/debuffs/DebuffSettingsMenuItem')

    local debuffSettingsItem = DebuffSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)

    -- Modes
    local modesMenuItem = ModesMenuItem.new(self.trustModeSettings, "View and change Trust modes.", L(T(state):keyset()):sort(), true, "modes")

    -- Settings
    local menuItems = L{
        ButtonItem.localized('Modes', i18n.translate('Button_Modes')),
    }
    local childMenuItems = {
        Modes = modesMenuItem,
        Debuffs = debuffSettingsItem,
    }

    if jobNameShort == 'GEO' then
        menuItems:append(ButtonItem.default('Geomancy', 18))
        local GeomancySettingsMenuItem = require('ui/settings/menus/buffs/GeomancySettingsMenuItem')
        childMenuItems.Geomancy = GeomancySettingsMenuItem.new(trust, trustSettings, trustSettingsMode, self.trustModeSettings, trustSettings:getSettings()[trustSettingsMode.value].Geomancy, trustSettings:getSettings()[trustSettingsMode.value].PartyBuffs, function(view)
            return setupView(view, viewSize)
        end)
    end

    if jobNameShort == 'SMN' then
        menuItems:append(ButtonItem.default('Blood Pacts', 18))
        local BloodPactSettingsMenuItem = require('ui/settings/menus/buffs/BloodPactSettingsMenuItem')
        childMenuItems['Blood Pacts'] = BloodPactSettingsMenuItem.new(trustSettings, trust, trustSettings:getSettings()[trustSettingsMode.value].PartyBuffs, self.trustModeSettings)
    end

    if jobNameShort == 'COR' then
        menuItems:append(ButtonItem.default('Rolls', 18))
        local RollSettingsMenuItem = require('ui/settings/menus/rolls/RollSettingsMenuItem')
        childMenuItems['Rolls'] = RollSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, trust)
    end

    if jobNameShort == 'PUP' then
        menuItems:append(ButtonItem.default('Automaton', 18))
        local AutomatonSettingsMenuItem = require('ui/settings/menus/attachments/AutomatonSettingsMenuItem')
        childMenuItems['Automaton'] = AutomatonSettingsMenuItem.new(trustSettings, trustSettingsMode, self.trustModeSettings)
    end

    if jobNameShort == 'BLU' then
        menuItems:append(ButtonItem.default('Blue Magic', 18))
        local BlueMagicSettingsMenuItem = require('ui/settings/menus/bluemagic/BlueMagicSettingsMenuItem')
        childMenuItems['Blue Magic'] = BlueMagicSettingsMenuItem.new(trustSettings, trustSettingsMode, true)
    end

    -- Add menu items only if the Trust has the appropriate role
    if trust:role_with_type("buffer") then
        menuItems:append(ButtonItem.localized('Buffs', i18n.translate('Button_Buffs')))
        childMenuItems.Buffs = self:getMenuItemForRole(trust:role_with_type("buffer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    local debuffer = trust:role_with_type("debuffer")
    if debuffer then
        menuItems:append(ButtonItem.localized('Debuffs', i18n.translate('Button_Debuffs')))
    end

    if trust:role_with_type("singer") then
        menuItems:append(ButtonItem.default('Songs', 18))
        childMenuItems.Songs = self:getMenuItemForRole(trust:role_with_type("singer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    if trust:role_with_type("healer") then
        menuItems:append(ButtonItem.default('Healing', 18))
        childMenuItems.Healing = self:getMenuItemForRole(trust:role_with_type("healer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    menuItems:append(ButtonItem.localized('Pulling', i18n.translate('Button_Pulling')))
    if trust:role_with_type("puller") then
        childMenuItems.Pulling = self:getMenuItemForRole(trust:role_with_type("puller"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    else
        local PullSettingsMenuItem = require('ui/settings/menus/pulling/PullSettingsMenuItem')
        childMenuItems.Pulling = PullSettingsMenuItem.disabled("Configure pull settings from the other job's menu.")
    end

    if trust:role_with_type("shooter") then
        menuItems:append(ButtonItem.default('Shooting', 18))
        childMenuItems.Shooting = self:getMenuItemForRole(trust:role_with_type("shooter"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    if trust:role_with_type("nuker") or trust:role_with_type("magicburster") then
        childMenuItems.Nukes = self:getMenuItemForRole(trust:role_with_type("nuker") or trust:role_with_type("magicburster"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
        menuItems:append(ButtonItem.localized('Nukes', i18n.translate('Button_Nukes')))
    end

    if trust:role_with_type("skillchainer") then
        menuItems:append(ButtonItem.localized('Weaponskills', i18n.translate('Button_Weaponskills')))
        childMenuItems.Weaponskills = self:getMenuItemForRole(trust:role_with_type("skillchainer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    if trust:role_with_type("follower") then
        menuItems:append(ButtonItem.localized('Following', i18n.translate('Button_Following')))
        childMenuItems.Following = self:getMenuItemForRole(trust:role_with_type("follower"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    menuItems:append(ButtonItem.localized('Food', i18n.translate('Button_Food')))
    local FoodSettingsMenuItem = require('ui/settings/menus/buffs/FoodSettingsMenuItem')
    childMenuItems.Food = FoodSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings)

    if trust:role_with_type("truster") then
        menuItems:append(ButtonItem.localized('Alter Egos', i18n.translate('Button_Alter_Egos')))
        childMenuItems['Alter Egos'] = self:getMenuItemForRole(trust:role_with_type("truster"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize)
    end

    if trust:role_with_type("pather") then
        menuItems:append(ButtonItem.localized('Paths', i18n.translate('Button_Paths')))
        childMenuItems.Paths = self:getMenuItemForRole(trust:role_with_type("pather"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize)
    end

    local EquipSetMenuItem = require('ui/views/inventory/equipment/EquipSetMenuItem')
    local EquipSet = require('cylibs/inventory/equipment/equip_set')
    local EquipmentSettingsMenuItem = require('ui/views/inventory/equipment/EquipmentSettingsMenuItem')

    --menuItems:append(ButtonItem.default('Equipment', 18))
    --childMenuItems.Equipment = EquipSetMenuItem.new(EquipSet.named('test_set') or player.party:get_player():get_current_equip_set())
    --childMenuItems.Equipment = EquipmentSettingsMenuItem.new()

    local jobName = res.jobs:with('ens', jobNameShort).en

    menuItems:append(ButtonItem.localized('Gambits', i18n.translate('Button_Gambits')))

    local customGambitsMenuItem = GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, self.trustModeSettings, 'GambitSettings')
    customGambitsMenuItem:setConfigKey("gambits")

    childMenuItems.Gambits = MenuItem.new(L{
        ButtonItem.default('Custom', 18),
        ButtonItem.default(jobName, 18),
        ButtonItem.default('Reactions', 18),
    }, {
        Custom = customGambitsMenuItem,
        [jobName] = JobGambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, self.trustModeSettings),
        Reactions = ReactionSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, self.trustModeSettings),
    }, nil, "Gambits", "Configure Trust behavior.")

    local settingsMenuItem = MenuItem.new(menuItems, childMenuItems, nil, "Settings", "Configure Trust settings for skillchains, buffs, debuffs and more.")
    return settingsMenuItem
end

function TrustHud:getMenuItemForRole(role, weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    if role == nil then
        return nil
    end
    if role:get_type() == "buffer" then
        return self:getBufferMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode, trustModeSettings)
    end
    if role:get_type() == "healer" then
        return self:getHealerMenuItem(trust, trustSettings, trustSettingsMode, trustModeSettings)
    end
    if role:get_type() == "skillchainer" then
        return self:getSkillchainerMenuItem(weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, trust)
    end
    if role:get_type() == "puller" then
        return self:getPullerMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode, trustModeSettings)
    end
    if role:get_type() == "singer" then
        return self:getSingerMenuItem(trust, trustSettings, trustSettingsMode, viewSize)
    end
    if role:get_type() == "nuker" or role:get_type() == "magicburster" then
        return self:getNukerMenuItem(trust, trustSettings, trustSettingsMode, trustModeSettings, jobNameShort)
    end
    if role:get_type() == "shooter" then
        return self:getShooterMenuItem(trust, trustSettings, trustSettingsMode)
    end
    if role:get_type() == "follower" then
        return self:getFollowerMenuItem(role, trustModeSettings)
    end
    if role:get_type() == "pather" then
        return self:getPatherMenuItem(role, trust:role_with_type("follower"), viewSize)
    end
    if role:get_type() == "truster" then
        return self:getTrusterMenuItem(role)
    end
    return nil
end

function TrustHud:getBufferMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode, trustModeSettings)
    local BuffSettingsMenuItem = require('ui/settings/menus/buffs/BuffSettingsMenuItem')
    local bufferSettingsMenuItem = BuffSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    return bufferSettingsMenuItem
end

function TrustHud:getHealerMenuItem(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local HealerSettingsMenuItem = require('ui/settings/menus/healing/HealerSettingsMenuItem')
    local healerSettingsMenuItem = HealerSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    return healerSettingsMenuItem
end

function TrustHud:getSkillchainerMenuItem(weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, trust)
    local WeaponSkillSettingsMenuItem = require('ui/settings/menus/WeaponSkillSettingsMenuItem')
    local weaponSkillsSettingsMenuItem = WeaponSkillSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, trust)
    return weaponSkillsSettingsMenuItem
end

function TrustHud:getPullerMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode, trustModeSettings)
    local PullSettingsMenuItem = require('ui/settings/menus/pulling/PullSettingsMenuItem')
    local pullerSettingsMenuItem = PullSettingsMenuItem.new(L{}, trust, jobNameShort, trustSettings, trustSettingsMode, trustModeSettings)
    return pullerSettingsMenuItem
end

function TrustHud:getShooterMenuItem(trust, trustSettings, trustSettingsMode)
    local ShooterSettingsMenuItem = require('ui/settings/menus/ShooterSettingsMenuItem')
    local shooterSettingsMenuItem = ShooterSettingsMenuItem.new(trustSettings, trustSettingsMode, self.trustModeSettings, trust:role_with_type("shooter"))
    return shooterSettingsMenuItem
end

function TrustHud:getSingerMenuItem(trust, trustSettings, trustSettingsMode)
    local SongSetsMenuItem = require('ui/settings/menus/songs/SongSetsMenuItem')
    local singerSettingsMenuItem = SongSetsMenuItem.new(trustSettings, trustSettingsMode, self.trustModeSettings, trust)
    return singerSettingsMenuItem
end

function TrustHud:getNukerMenuItem(trust, trustSettings, trustSettingsMode, trustModeSettings, jobNameShort)
    local NukeSettingsMenuItem = require('ui/settings/menus/nukes/NukeSettingsMenuItem')
    local nukerSettingsMenuItem = NukeSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, self.addon_settings, jobNameShort)
    return nukerSettingsMenuItem
end

function TrustHud:getFollowerMenuItem(role, trustModeSettings)
    local FollowSettingsMenuItem = require('ui/settings/menus/FollowSettingsMenuItem')
    return FollowSettingsMenuItem.new(role, trustModeSettings, self.addon_settings)
end

function TrustHud:getPatherMenuItem(role, follower)
    local PathSettingsMenuItem = require('ui/settings/menus/misc/PathSettingsMenuItem')
    return PathSettingsMenuItem.new(role, follower)
end

function TrustHud:getTrusterMenuItem(role)
    local AlterEgoSettingsMenuItem = require('ui/settings/menus/AlterEgoSettingsMenuItem')
    return AlterEgoSettingsMenuItem.new(role, self.trustModeSettings, self.addon_settings)
end

function TrustHud:getStatusMenuItem(trust)
    local statusMenuButtons = L{
        ButtonItem.default('Alliance', 18),
        ButtonItem.default('Targets', 18)
    }

    local AllianceSettingsMenuItem = require('ui/settings/menus/party/AllianceSettingsMenuItem')
    local PartyTargetsMenuItem = require('ui/settings/menus/PartyTargetsMenuItem')
    local targetsMenuItem = PartyTargetsMenuItem.new(self.party, function(view)
        return view
    end)
    targetsMenuItem.enabled = function()
        return self.party:get_targets():length() > 0, "No targets found."
    end

    local statusMenuItem = MenuItem.new(statusMenuButtons, {
        Alliance = AllianceSettingsMenuItem.new(player.alliance, trust),
        Targets = targetsMenuItem,
    }, nil, "Status", "View status of party members and enemies.")

    if trust.job.jobNameShort == 'BRD' then
        -- Bard
        local singerMenuItem = MenuItem.new(L{}, {},
        function()
            local SongStatusView = require('ui/views/SongStatusView')
            local singer = trust:role_with_type("singer")
            local singerView = SongStatusView.new(singer)
            return singerView
        end, "Songs", "View current songs on the player and party.")
        statusMenuItem:setChildMenuItem("Songs", singerMenuItem)
    end

    return statusMenuItem
end

function TrustHud:getMenuItems(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, jobNameShort, jobName)
    local settingsMenuItem = self:getSettingsMenuItem(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, jobNameShort)

    -- Debug
    local debugMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear', 18)
    }, {},
    function()
        local DebugView = require('cylibs/actions/ui/debug_view')
        local debugView = DebugView.new(self.actionQueue)
        debugView:setShouldRequestFocus(false)
        return debugView
    end, "Debug", "View debug info.")

    -- Help
    local helpMenuItem = MenuItem.new(L{
        ButtonItem.default('Wiki', 18),
        ButtonItem.default('Commands', 18),
        ButtonItem.default('Multi-Boxing', 18),
        ButtonItem.default('Support', 18),
        ButtonItem.default('Debug', 18),
    }, {
        Wiki = MenuItem.action(function()
            windower.open_url(self.addon_settings:getSettings().help.wiki_base_url)
        end, "Wiki", "Learn more about Trust."),
        Commands = MenuItem.action(function()
            windower.open_url(self.addon_settings:getSettings().help.wiki_base_url..'/Commands')
            windower.send_command('trust commands')
        end, "Commands", "See a list of Trust commands."),
        ['Multi-Boxing'] = MenuItem.action(function()
            windower.open_url(self.addon_settings:getSettings().help.wiki_base_url..'/Multi-Boxing')
        end, "Multi-Boxing", "Learn more about multi-boxing with Trust."),
        Support = MenuItem.action(function()
            windower.open_url(self.addon_settings:getSettings().discord.channels.support)
        end, "Support", "Get help on Discord."),
        Debug = debugMenuItem,
    },
    nil, "Help", "Get help using Trust.")

    -- Main
    local mainMenuItem = MenuItem.new(L{
        ButtonItem.default('Status', 18),
        ButtonItem.default('Settings', 18),
        ButtonItem.default('Help', 18),
        ButtonItem.default('Donate', 18),
        ButtonItem.default('Discord', 18),
    }, {
        Settings = settingsMenuItem,
        Help = helpMenuItem,
        Donate = MenuItem.action(function()
            windower.open_url(self.addon_settings:getSettings().donate.url)
        end, "Donate", "Enjoying Trust? Show your support!"),
        Discord = MenuItem.action(function()
            windower.open_url(self.addon_settings:getSettings().discord.url)
        end, "Discord", "Need help? Join the Discord!")
    }, nil, jobName, "Settings for "..jobName..". Use the up, down, left, right, enter and escape keys to navigate the menu.")

    return mainMenuItem
end

function TrustHud:hitTest(x, y)
    return true
end

return TrustHud

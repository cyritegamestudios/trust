local AlterEgoSettingsMenuItem = require('ui/settings/menus/AlterEgoSettingsMenuItem')
local BackgroundView = require('cylibs/ui/views/background/background_view')
local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CommandsMenuItem = require('ui/settings/menus/commands/CommandsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigSettingsMenuItem = require('ui/settings/menus/ConfigSettingsMenuItem')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local FFXISoundTheme = require('sounds/FFXISoundTheme')
local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local FollowSettingsMenuItem = require('ui/settings/menus/FollowSettingsMenuItem')
local FoodSettingsMenuItem = require('ui/settings/menus/buffs/FoodSettingsMenuItem')
local Frame = require('cylibs/ui/views/frame')
local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local GameInfo = require('cylibs/util/ffxi/game_info')
local JobGambitSettingsMenuItem = require('ui/settings/menus/gambits/JobGambitSettingsMenuItem')
local Keyboard = require('cylibs/ui/input/keyboard')
local MediaPlayer = require('cylibs/sounds/media_player')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local PullSettingsMenuItem = require('ui/settings/menus/pulling/PullSettingsMenuItem')
local LoadSettingsMenuItem = require('ui/settings/menus/loading/LoadSettingsMenuItem')
local PartyStatusWidget = require('ui/widgets/PartyStatusWidget')
local PartyTargetsMenuItem = require('ui/settings/menus/PartyTargetsMenuItem')
local PathSettingsMenuItem = require('ui/settings/menus/misc/PathSettingsMenuItem')
local PathWidget = require('ui/widgets/PathWidget')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local ReactSettingsMenuItem = require('ui/settings/menus/gambits/react/ReactSettingsMenuItem')
local TargetWidget = require('ui/widgets/TargetWidget')
local TrustInfoBar = require('ui/TrustInfoBar')
local TrustStatusWidget = require('ui/widgets/TrustStatusWidget')
local Menu = require('cylibs/ui/menu/menu')
local TargetSettingsMenuItem = require('ui/settings/menus/TargetSettingsMenuItem')
local ViewStack = require('cylibs/ui/views/view_stack')
local WeaponSkillSettingsMenuItem = require('ui/settings/menus/WeaponSkillSettingsMenuItem')
local View = require('cylibs/ui/views/view')
local WidgetManager = require('ui/widgets/WidgetManager')

local TrustHud = setmetatable({}, {__index = View })
TrustHud.__index = TrustHud

function TrustHud:onEnabledClick()
    return self.enabledClick
end

function TrustHud.new(player, action_queue, addon_settings, trustModeSettings, addon_enabled, menu_width, menu_height)
    local self = setmetatable(View.new(), TrustHud)

    CollectionView.setDefaultStyle(FFXIClassicStyle.default())
    CollectionView.setDefaultBackgroundStyle(FFXIClassicStyle.background())

    self.mediaPlayer = MediaPlayer.new(windower.addon_path..'sounds')
    self.mediaPlayer:setEnabled(not addon_settings:getSettings().sounds.sound_effects.disabled)
    self.soundTheme = FFXISoundTheme.default()

    FFXIWindow.setDefaultMediaPlayer(self.mediaPlayer)
    FFXIWindow.setDefaultSoundTheme(self.soundTheme)
    FFXIPickerView.setDefaultMediaPlayer(self.mediaPlayer)
    FFXIPickerView.setDefaultSoundTheme(self.soundTheme)

    self.lastMenuToggle = os.time()
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
    self.mainMenuItem = self:getMainMenuItem()
    self.widgetManager = WidgetManager.new(addon_settings)

    self.infoViewContainer = View.new(Frame.new(17, 17, windower.get_windower_settings().ui_x_res - 18, 27))
    self.infoBar = TrustInfoBar.new(Frame.new(0, 0, windower.get_windower_settings().ui_x_res - 18, 27))
    self.infoBar:setVisible(false)

    FFXIPickerView.setDefaultInfoView(self.infoBar)

    self.infoViewContainer:addSubview(self.infoBar)

    self.infoViewContainer:setNeedsLayout()
    self.infoViewContainer:layoutIfNeeded()

    self:createWidgets(addon_settings, addon_enabled, action_queue, player.party, player.trust.main_job)

    self.trustMenu = Menu.new(self.viewStack, self.menuViewStack, self.infoBar, self.mediaPlayer, self.soundTheme)

    self.tabbed_view = nil
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

    self:registerShortcuts()

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
    self.widgetManager:destroy()
    self.viewStack:dismissAll()
    self.viewStack:destroy()
    self.click:removeAllEvents()
    self.layout:destroy()

    for _, itemView in pairs(self.itemViews) do
        itemView:destroy()
    end
end

function TrustHud:registerShortcuts()
    local stack = L{ self.mainMenuItem:getChildMenuItem(player.main_job_name) }
    while stack:length() > 0 do
        local menuItem = stack:remove(1)
        if menuItem:getConfigKey() then
            local shortcutsMenuItem = MenuItem.new(L{
                ButtonItem.default('Save', 18),
            }, {},
                function(_, _)
                    local shortcutSettings = self.addon_settings:getSettings().shortcuts.menus[menuItem:getConfigKey()]

                    local configItems = L{
                        BooleanConfigItem.new('enabled', "Keyboard Shortcut"),
                        PickerConfigItem.new('key', shortcutSettings.key or Keyboard.allKeys()[1], Keyboard.allKeys(), function(keyName)
                            return keyName
                        end, "Key"),
                        PickerConfigItem.new('flags', shortcutSettings.flags or Keyboard.allFlags()[1], Keyboard.allFlags(), function(flag)
                            return Keyboard.input():getFlag(flag)
                        end, "Secondary Key"),
                    }

                    local shortcutsEditor = ConfigEditor.new(self.addon_settings, shortcutSettings, configItems)

                    self.disposeBag:add(shortcutsEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
                        if oldSettings.key and oldSettings.flags then
                            Keyboard.input():unregisterKeybind(oldSettings.key, oldSettings.flags)
                        end
                        if newSettings.enabled and newSettings.key and newSettings.flags then
                            Keyboard.input():registerKeybind(newSettings.key, newSettings.flags, function(keybind, pressed)
                                self:openMenu(menuItem)
                            end)
                        end
                    end), shortcutsEditor:onConfigChanged())

                    return shortcutsEditor
                end, menuItem:getTitleText(), "Configure keyboard shortcuts to show this menu.")
            menuItem:setChildMenuItem('Shortcuts', shortcutsMenuItem)

            local shortcutSettings = self.addon_settings:getSettings().shortcuts.menus[menuItem:getConfigKey()]
            if shortcutSettings and shortcutSettings.enabled and shortcutSettings.key and shortcutSettings.flags then
                Keyboard.input():registerKeybind(shortcutSettings.key, shortcutSettings.flags, function(keybind, pressed)
                    self:openMenu(menuItem)
                end)
            end
        end
        stack = stack:extend(menuItem:getChildMenuItems())
    end
end

function TrustHud:layoutIfNeeded()
    View.layoutIfNeeded(self)

    self.infoBar:setNeedsLayout()
    self.infoBar:layoutIfNeeded()
end

function TrustHud:getViewStack()
    return self.viewStack
end

function TrustHud:createWidgets(addon_settings, addon_enabled, action_queue, party, trust)
    local loadWidgets = coroutine.create(function()
        local trustStatusWidget = TrustStatusWidget.new(Frame.new(0, 0, 125, 69), addon_settings, addon_enabled, action_queue, player.main_job_name, player.sub_job_name, party:get_player())
        self.widgetManager:addWidget(trustStatusWidget, "trust")

        local targetWidget = TargetWidget.new(Frame.new(0, 0, 125, 40), addon_settings, party, trust)
        self.widgetManager:addWidget(targetWidget, "target")

        local partyStatusWidget = PartyStatusWidget.new(Frame.new(0, 0, 125, 55), addon_settings, player.alliance, party, trust, self.mediaPlayer, self.soundTheme)
        self.widgetManager:addWidget(partyStatusWidget, "party")

        local pathWidget = PathWidget.new(Frame.new(0, 0, 125, 57), addon_settings, party:get_player(), self, main_trust_settings, state.MainTrustSettingsMode, trust)
        self.widgetManager:addWidget(pathWidget, "path")

        if player.main_job_name_short == 'PUP' then
            local AutomatonStatusWidget = require('ui/widgets/AutomatonStatusWidget')
            local petStatusWidget = AutomatonStatusWidget.new(Frame.new(0, 0, 125, 57), addon_settings, party:get_player(), self, main_trust_settings, state.MainTrustSettingsMode, self.trustModeSettings)
            self.widgetManager:addWidget(petStatusWidget, "pet")
        end

        if player.main_job_name_short == 'SMN' then
            local AvatarStatusWidget = require('ui/widgets/AvatarStatusWidget')
            local petStatusWidget = AvatarStatusWidget.new(Frame.new(0, 0, 125, 57), addon_settings, party:get_player(), self, main_trust_settings, state.MainTrustSettingsMode)
            self.widgetManager:addWidget(petStatusWidget, "pet")
        end

        if player.main_job_name_short == 'BLM' then
            local BlackMageWidget = require('ui/widgets/BlackMageWidget')
            local blackMageWidget = BlackMageWidget.new(Frame.new(0, 0, 125, 57), addon_settings, party:get_player(), trust)
            self.widgetManager:addWidget(blackMageWidget, "black_mage")
        end

        if player.main_job_name_short == 'RUN' then
            local RuneFencerWidget = require('ui/widgets/RuneFencerWidget')
            local runeFencerWidget = RuneFencerWidget.new(Frame.new(0, 0, 125, 57), addon_settings, trust)
            self.widgetManager:addWidget(runeFencerWidget, "rune_fencer")
        end

        --if player.main_job_name_short == 'SCH' then
        --    local scholarWidget = ScholarWidget.new(Frame.new(0, 0, 125, 57), addon_settings, party:get_player(), trust)
        --    self.widgetManager:addWidget(scholarWidget, "scholar")
        --end

        for widget in self.widgetManager:getAllWidgets():it() do
            self:addSubview(widget)
        end
        coroutine.yield()
    end)

    coroutine.resume(loadWidgets)
end

function TrustHud:toggleMenu()
    self.trustMenu:closeAll()

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
    if self.mainMenuItem then
        self.mainMenuItem:setChildMenuItem('Commands', CommandsMenuItem.new(commands))
    end
end

function TrustHud:getMainMenuItem()
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

    local debuffSettingsItem = DebuffSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, addon_settings)

    -- Modes
    local modesMenuItem = ModesMenuItem.new(self.trustModeSettings, "View and change Trust modes.", L(T(state):keyset()):sort(), true, "modes")

    -- Settings
    local menuItems = L{
        ButtonItem.localized("Modes", i18n.translate("Modes"))
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
        menuItems:append(ButtonItem.default('Buffs', 18))
        childMenuItems.Buffs = self:getMenuItemForRole(trust:role_with_type("buffer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    local debuffer = trust:role_with_type("debuffer")
    if debuffer then
        menuItems:append(ButtonItem.default('Debuffs', 18))
    end

    if trust:role_with_type("singer") then
        menuItems:append(ButtonItem.default('Songs', 18))
        childMenuItems.Songs = self:getMenuItemForRole(trust:role_with_type("singer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    if trust:role_with_type("healer") then
        menuItems:append(ButtonItem.default('Healing', 18))
        childMenuItems.Healing = self:getMenuItemForRole(trust:role_with_type("healer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    menuItems:append(ButtonItem.default('Pulling', 18))
    if trust:role_with_type("puller") then
        childMenuItems.Pulling = self:getMenuItemForRole(trust:role_with_type("puller"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    else
        childMenuItems.Pulling = PullSettingsMenuItem.disabled("Configure pull settings from the other job's menu.")
    end

    if trust:role_with_type("targeter") then
        menuItems:append(ButtonItem.localized('Targeting', i18n.translate('Button_Targeting')))
        childMenuItems.Targeting = TargetSettingsMenuItem.new(trustSettings, trustSettingsMode)
    end

    if trust:role_with_type("shooter") then
        menuItems:append(ButtonItem.default('Shooting', 18))
        childMenuItems.Shooting = self:getMenuItemForRole(trust:role_with_type("shooter"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    if trust:role_with_type("nuker") then
        childMenuItems.Nukes = self:getMenuItemForRole(trust:role_with_type("nuker"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
        menuItems:append(ButtonItem.default('Nukes', 18))
    end

    if trust:role_with_type("skillchainer") then
        menuItems:append(ButtonItem.default('Weaponskills', 18))
        childMenuItems.Weaponskills = self:getMenuItemForRole(trust:role_with_type("skillchainer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    if trust:role_with_type("follower") then
        menuItems:append(ButtonItem.default('Following', 18))
        childMenuItems.Following = self:getMenuItemForRole(trust:role_with_type("follower"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode, trustModeSettings)
    end

    menuItems:append(ButtonItem.default('Food', 18))
    childMenuItems.Food = FoodSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings)

    if trust:role_with_type("truster") then
        menuItems:append(ButtonItem.default('Alter Egos', 18))
        childMenuItems['Alter Egos'] = self:getMenuItemForRole(trust:role_with_type("truster"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize)
    end

    if trust:role_with_type("pather") then
        menuItems:append(ButtonItem.default('Paths', 18))
        childMenuItems.Paths = self:getMenuItemForRole(trust:role_with_type("pather"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize)
    end

    local jobName = res.jobs:with('ens', jobNameShort).en

    menuItems:append(ButtonItem.default('Gambits', 18))
    childMenuItems.Gambits = MenuItem.new(L{
        ButtonItem.default('Custom', 18),
        ButtonItem.default(jobName, 18),
        ButtonItem.default('Reactions', 18),
    }, {
        Custom = GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, self.trustModeSettings, 'GambitSettings'),
        [jobName] = JobGambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, self.trustModeSettings),
        Reactions = ReactSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, self.trustModeSettings),
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
    if role:get_type() == "nuker" then
        return self:getNukerMenuItem(trust, trustSettings, trustSettingsMode, trustModeSettings, jobNameShort)
    end
    if role:get_type() == "shooter" then
        return self:getShooterMenuItem(trust, trustSettings, trustSettingsMode)
    end
    if role:get_type() == "follower" then
        return self:getFollowerMenuItem(role, trustModeSettings)
    end
    if role:get_type() == "pather" then
        return self:getPatherMenuItem(role, viewSize)
    end
    if role:get_type() == "truster" then
        return self:getTrusterMenuItem(role)
    end
    return nil
end

function TrustHud:getBufferMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode, trustModeSettings)
    local BufferSettingsMenuItem = require('ui/settings/menus/buffs/BufferSettingsMenuItem')
    if jobNameShort ~= 'SCH' then
        local bufferSettingsMenuItem = BufferSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, jobNameShort)
        return bufferSettingsMenuItem
    else
        local childMenuItems = {}

        childMenuItems["Light Arts"] = BufferSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, jobNameShort, 'LightArts')
        childMenuItems["Dark Arts"] = BufferSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, jobNameShort, 'DarkArts')

        local artsSettingsMenuItem = MenuItem.new(L{
            ButtonItem.default('Light Arts', 18),
            ButtonItem.default('Dark Arts', 18),
        }, childMenuItems, nil, "Buffs", "Choose buffs to use.")

        return artsSettingsMenuItem
    end
end

function TrustHud:getHealerMenuItem(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local HealerSettingsMenuItem = require('ui/settings/menus/healing/HealerSettingsMenuItem')
    local healerSettingsMenuItem = HealerSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    return healerSettingsMenuItem
end

function TrustHud:getSkillchainerMenuItem(weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, trust)
    local weaponSkillsSettingsMenuItem = WeaponSkillSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, trust)
    return weaponSkillsSettingsMenuItem
end

function TrustHud:getPullerMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode, trustModeSettings)
    local pullerSettingsMenuItem = PullSettingsMenuItem.new(L{}, trust, jobNameShort, trustSettings, trustSettingsMode, trustModeSettings)
    return pullerSettingsMenuItem
end

function TrustHud:getShooterMenuItem(trust, trustSettings, trustSettingsMode)
    local ShooterSettingsMenuItem = require('ui/settings/menus/ShooterSettingsMenuItem')
    local shooterSettingsMenuItem = ShooterSettingsMenuItem.new(trustSettings, trustSettingsMode, self.trustModeSettings, trust:role_with_type("shooter"))
    return shooterSettingsMenuItem
end

function TrustHud:getSingerMenuItem(trust, trustSettings, trustSettingsMode, viewSize)
    local SongSettingsMenuItem = require('ui/settings/menus/songs/SongSettingsMenuItem')
    local singerSettingsMenuItem = SongSettingsMenuItem.new(self.addon_settings, trustSettings, trustSettingsMode, self.trustModeSettings, trust)
    return singerSettingsMenuItem
end

function TrustHud:getNukerMenuItem(trust, trustSettings, trustSettingsMode, trustModeSettings, jobNameShort)
    local NukeSettingsMenuItem = require('ui/settings/menus/nukes/NukeSettingsMenuItem')
    local nukerSettingsMenuItem = NukeSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, self.addon_settings, jobNameShort)
    return nukerSettingsMenuItem
end

function TrustHud:getFollowerMenuItem(role, trustModeSettings)
    return FollowSettingsMenuItem.new(role, trustModeSettings, self.addon_settings)
end

function TrustHud:getPatherMenuItem(role, viewSize)
    return PathSettingsMenuItem.new(role)
end

function TrustHud:getTrusterMenuItem(role)
    return AlterEgoSettingsMenuItem.new(role, self.trustModeSettings, self.addon_settings)
end

function TrustHud:getMenuItems(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, jobNameShort, jobName)
    local viewSize = Frame.new(0, 0, 500, 500)

    local settingsMenuItem = self:getSettingsMenuItem(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, trustModeSettings, jobNameShort)

    -- Debug
    local debugMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear', 18)
    }, {},
    function()
        local DebugView = require('cylibs/actions/ui/debug_view')
        local debugView = setupView(DebugView.new(self.actionQueue), viewSize)
        debugView:setShouldRequestFocus(false)
        return debugView
    end, "Debug", "View debug info.")

    local partyMenuItem = MenuItem.new(L{}, {},
    function()
        local truster =  trust:role_with_type("truster")
        local PartyMemberView = require('cylibs/entity/party/ui/party_member_view')
        local partyMemberView = PartyMemberView.new(self.party, self.player.player, self.actionQueue, truster and truster.trusts or L{})
        partyMemberView:setShouldRequestFocus(false)
        return partyMemberView
    end, "Party", "View party status.")

    local targetsMenuItem = PartyTargetsMenuItem.new(self.party, function(view)
        return setupView(view, viewSize)
    end)
    targetsMenuItem.enabled = function()
        return self.party:get_targets():length() > 0
    end

    -- Bard
    local singerMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear All', 18),
    }, {},
        function()
            local SingerView = require('ui/views/SingerView')
            local singer = trust:role_with_type("singer")
            local singerView = setupView(SingerView.new(singer), viewSize)
            singerView:setShouldRequestFocus(true)
            return singerView
        end, "Songs", "View current songs on the player and party.")

    -- Status
    local statusMenuButtons = L{
        ButtonItem.default('Party', 18),
        ButtonItem.default('Targets', 18)
    }
    if jobNameShort == 'BRD' then
        statusMenuButtons:insert(2, ButtonItem.default('Songs', 18))
    end

    local statusMenuItem = MenuItem.new(statusMenuButtons, {
        Party = partyMenuItem,
        Targets = targetsMenuItem,
        Songs = singerMenuItem,
    }, nil, "Status", "View status of party members and enemies.")

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
        Status = statusMenuItem,
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

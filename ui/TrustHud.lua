local AlterEgoSettingsMenuItem = require('ui/settings/menus/AlterEgoSettingsMenuItem')
local AutomatonSettingsMenuItem = require('ui/settings/menus/attachments/AutomatonSettingsMenuItem')
local BackgroundView = require('cylibs/ui/views/background/background_view')
local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local BufferView = require('ui/views/BufferView')
local BufferSettingsMenuItem = require('ui/settings/menus/buffs/BufferSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local Color = require('cylibs/ui/views/color')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigSettingsMenuItem = require('ui/settings/menus/ConfigSettingsMenuItem')
local HealerSettingsMenuItem = require('ui/settings/menus/healing/HealerSettingsMenuItem')
local DebufferView = require('ui/views/DebufferView')
local DebuffSettingsEditor = require('ui/settings/DebuffSettingsEditor')
local DebugView = require('cylibs/actions/ui/debug_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FollowSettingsMenuItem = require('ui/settings/menus/FollowSettingsMenuItem')
local Frame = require('cylibs/ui/views/frame')
local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local GameInfo = require('cylibs/util/ffxi/game_info')
local HelpView = require('cylibs/trust/ui/help_view')
local JobGambitSettingsMenuItem = require('ui/settings/menus/gambits/JobGambitSettingsMenuItem')
local Keybind = require('cylibs/ui/input/keybind')
local Keyboard = require('cylibs/ui/input/keyboard')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local PullSettingsMenuItem = require('ui/settings/menus/pulling/PullSettingsMenuItem')
local LoadSettingsMenuItem = require('ui/settings/menus/loading/LoadSettingsMenuItem')
local NukeSettingsMenuItem = require('ui/settings/menus/nukes/NukeSettingsMenuItem')
local PartyMemberView = require('cylibs/entity/party/ui/party_member_view')
local PartyStatusWidget = require('ui/widgets/PartyStatusWidget')
local PartyTargetsMenuItem = require('ui/settings/menus/PartyTargetsMenuItem')
local PathSettingsMenuItem = require('ui/settings/menus/misc/PathSettingsMenuItem')
local PathWidget = require('ui/widgets/PathWidget')
local AutomatonStatusWidget = require('ui/widgets/AutomatonStatusWidget')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local ReactSettingsMenuItem = require('ui/settings/menus/gambits/react/ReactSettingsMenuItem')
local SingerView = require('ui/views/SingerView')
local SongSettingsMenuItem = require('ui/settings/menus/songs/SongSettingsMenuItem')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')
local spell_util = require('cylibs/util/spell_util')
local TargetWidget = require('ui/widgets/TargetWidget')
local TextStyle = require('cylibs/ui/style/text_style')
local TrustInfoBar = require('ui/TrustInfoBar')
local TrustStatusWidget = require('ui/widgets/TrustStatusWidget')
local Menu = require('cylibs/ui/menu/menu')
local ViewStack = require('cylibs/ui/views/view_stack')
local WeaponSkillSettingsMenuItem = require('ui/settings/menus/WeaponSkillSettingsMenuItem')
local GeomancySettingsMenuItem = require('ui/settings/menus/buffs/GeomancySettingsMenuItem')
local BloodPactSettingsMenuItem = require('ui/settings/menus/buffs/BloodPactSettingsMenuItem')
local RollSettingsMenuItem = require('ui/settings/menus/rolls/RollSettingsMenuItem')
local View = require('cylibs/ui/views/view')
local WidgetManager = require('ui/widgets/WidgetManager')

local TrustHud = setmetatable({}, {__index = View })
TrustHud.__index = TrustHud

function TrustHud:onEnabledClick()
    return self.enabledClick
end

TextStyle.TargetView = TextStyle.new(
        Color.clear,
        Color.clear,
        "Arial",
        12,
        Color.white,
        Color.red,
        2,
        1,
        Color.black,
        true
)

function TrustHud.new(player, action_queue, addon_settings, trustModeSettings, addon_enabled, menu_width, menu_height)
    local self = setmetatable(View.new(), TrustHud)

    CollectionView.setDefaultStyle(FFXIClassicStyle.default())

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

    self.infoViewContainer:addSubview(self.infoBar)

    self.infoViewContainer:setNeedsLayout()
    self.infoViewContainer:layoutIfNeeded()

    self:createWidgets(addon_settings, addon_enabled, action_queue, player.party, player.trust.main_job)

    self.trustMenu = Menu.new(self.viewStack, self.menuViewStack, self.infoBar)

    self.tabbed_view = nil
    self.backgroundImageView = self:getBackgroundImageView()

    for mode in L{ state.MainTrustSettingsMode, state.SubTrustSettingsMode }:it() do
        self:getDisposeBag():add(mode:on_state_change():addAction(function(m, new_value, old_value)
            if old_value == new_value then
                return
            end
            local showMenu = self.trustMenu:isVisible()

            self.trustMenu:closeAll()
            self.mainMenuItem:destroy()

            self:getMainMenuItem()

            if showMenu then
                self.trustMenu:showMenu(self.mainMenuItem)
            end
        end), mode:on_state_change())
    end

    self:getDisposeBag():add(self.gameInfo:onMenuChange():addAction(function(_, isMenuOpen)
        if isMenuOpen then
            --if self.addon_settings:getSettings().hud.auto_hide then
            --    self.trustMenu:closeAll()
            --end
        end
    end), self.gameInfo:onMenuChange())

    self:registerShortcuts()

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
    local trustStatusWidget = TrustStatusWidget.new(Frame.new(0, 0, 125, 69), addon_settings, addon_enabled, action_queue, player.main_job_name, player.sub_job_name, party:get_player())
    self.widgetManager:addWidget(trustStatusWidget, "trust")

    local targetWidget = TargetWidget.new(Frame.new(0, 0, 125, 40), addon_settings, party, trust)
    self.widgetManager:addWidget(targetWidget, "target")

    local partyStatusWidget = PartyStatusWidget.new(Frame.new(0, 0, 125, 55), addon_settings, party)
    self.widgetManager:addWidget(partyStatusWidget, "party")

    local pathWidget = PathWidget.new(Frame.new(0, 0, 125, 57), addon_settings, party:get_player(), self, main_trust_settings, state.MainTrustSettingsMode, trust)
    self.widgetManager:addWidget(pathWidget, "path")

    if player.main_job_name_short == 'PUP' then
        local petStatusWidget = AutomatonStatusWidget.new(Frame.new(0, 0, 125, 57), addon_settings, party:get_player(), self, main_trust_settings, state.MainTrustSettingsMode)
        self.widgetManager:addWidget(petStatusWidget, "pet")
    end

    --local settingsWidget = SettingsWidget.new(Frame.new(0, 0, 125, 40), addon_settings, state.TrustMode, state.MainTrustSettingsMode)
    --self.widgetManager:addWidget(settingsWidget, "settings")
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

function TrustHud:getMainMenuItem()
    if self.mainMenuItem then
        return self.mainMenuItem
    end

    local mainJobItem = self:getMenuItems(player.trust.main_job, main_trust_settings, state.MainTrustSettingsMode, weapon_skill_settings, state.WeaponSkillSettingsMode, player.main_job_name_short, player.main_job_name)
    local subJobItem = self:getMenuItems(player.trust.sub_job, sub_trust_settings, state.SubTrustSettingsMode, nil, nil, player.sub_job_name_short, player.sub_job_name)

    local mainMenuItem = MenuItem.new(L{
        ButtonItem.default(player.main_job_name, 18),
        ButtonItem.default(player.sub_job_name, 18),
    }, {
        [player.main_job_name] = mainJobItem,
    }, nil, "Jobs")

    if player.sub_job_name ~= 'None' then
        mainMenuItem:setChildMenuItem(player.sub_job_name, subJobItem)
    end

    self.mainMenuItem = mainMenuItem

    return self.mainMenuItem
end

local function createBackgroundView(width, height)
    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, width, height), true)
    --[[local backgroundView = BackgroundView.new(Frame.new(0, 0, width, height),
            windower.addon_path..'assets/backgrounds/menu_bg_top.png',
            windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
            windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')]]
    return backgroundView
end

local function createTitleView(viewSize)
    local titleView = NavigationBar.new(Frame.new(0, 0, viewSize.width, 35))
    return titleView
end

local function setupView(view, viewSize, hideBackground)
    if not hideBackground then
        --view:setBackgroundImageView(createBackgroundView(viewSize.width, viewSize.height))
    end
    --view:setNavigationBar(createTitleView(viewSize))
    view:setSize(viewSize.width, viewSize.height)
    return view
end

function TrustHud:getSettingsMenuItem(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, jobNameShort)
    local viewSize = Frame.new(0, 0, 500, 500)

    local chooseDebuffsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function()
                local jobId = res.jobs:with('ens', jobNameShort).id
                local allDebuffs = spell_util.get_spells(function(spell)
                    return spell.levels[jobId] ~= nil and spell.status ~= nil and L{32, 35, 36, 39, 40, 41, 42}:contains(spell.skill) and spell.targets:contains('Enemy')
                end):map(function(spell) return spell.en end):sort()

                local chooseSpellsView = SpellPickerView.new(trustSettings, L(T(trustSettings:getSettings())[trustSettingsMode.value].Debuffs), allDebuffs, L{}, false)
                return chooseSpellsView
            end, "Debuffs", "Add a new debuff.")

    local debuffModesMenuItem = MenuItem.new(L{}, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoDebuffMode', 'AutoDispelMode', 'AutoSilenceMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Change debuffing behavior.")

    local debuffSettingsItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Modes', 18),
        ButtonItem.default('Help', 18)
    }, {
        Add = chooseDebuffsItem,
        Modes = debuffModesMenuItem,
    },
    function()
        local debuffSettingsView = DebuffSettingsEditor.new(trustSettings, trustSettingsMode, self.addon_settings:getSettings().help.wiki_base_url..'/Debuffer')
        return debuffSettingsView
    end, "Debuffs", "Choose debuffs to use on enemies.")

    -- Modes
    local modesMenuItem = ModesMenuItem.new(trustSettings)

    -- Settings
    local menuItems = L{
        ButtonItem.default('Modes', 18)
    }
    local childMenuItems = {
        Modes = modesMenuItem,
        Debuffs = debuffSettingsItem,
    }

    if jobNameShort == 'GEO' then
        menuItems:append(ButtonItem.default('Geomancy', 18))
        childMenuItems.Geomancy = GeomancySettingsMenuItem.new(trustSettings, trust, trustSettings:getSettings()[trustSettingsMode.value].Geomancy, trustSettings:getSettings()[trustSettingsMode.value].PartyBuffs, function(view)
            return setupView(view, viewSize)
        end)
    end

    if jobNameShort == 'SMN' then
        menuItems:append(ButtonItem.default('Blood Pacts', 18))
        childMenuItems['Blood Pacts'] = BloodPactSettingsMenuItem.new(trustSettings, trust, trustSettings:getSettings()[trustSettingsMode.value].PartyBuffs, function(view)
            return setupView(view, viewSize)
        end)
    end

    if jobNameShort == 'COR' then
        menuItems:append(ButtonItem.default('Rolls', 18))
        childMenuItems['Rolls'] = RollSettingsMenuItem.new(trustSettings, trustSettingsMode, trust)
    end

    if jobNameShort == 'PUP' then
        menuItems:append(ButtonItem.default('Automaton', 18))
        childMenuItems['Automaton'] = AutomatonSettingsMenuItem.new(trustSettings, trustSettingsMode)
    end

    -- Add menu items only if the Trust has the appropriate role
    if trust:role_with_type("buffer") then
        menuItems:append(ButtonItem.default('Buffs', 18))
        childMenuItems.Buffs = self:getMenuItemForRole(trust:role_with_type("buffer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode)
    end

    local debuffer = trust:role_with_type("debuffer")
    if debuffer then
        menuItems:append(ButtonItem.default('Debuffs', 18))
    end

    if trust:role_with_type("singer") then
        menuItems:append(ButtonItem.default('Songs', 18))
        childMenuItems.Songs = self:getMenuItemForRole(trust:role_with_type("singer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode)
    end

    if trust:role_with_type("healer") then
        menuItems:append(ButtonItem.default('Healing', 18))
        childMenuItems.Healing = self:getMenuItemForRole(trust:role_with_type("healer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode)
    end

    if trust:role_with_type("puller") then
        menuItems:append(ButtonItem.default('Pulling', 18))
        childMenuItems.Pulling = self:getMenuItemForRole(trust:role_with_type("puller"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode)
    end

    if trust:role_with_type("nuker") then
        childMenuItems.Nukes = self:getMenuItemForRole(trust:role_with_type("nuker"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode)
        menuItems:append(ButtonItem.default('Nukes', 18))
    end

    if trust:role_with_type("skillchainer") then
        menuItems:append(ButtonItem.default('Weaponskills', 18))
        childMenuItems.Weaponskills = self:getMenuItemForRole(trust:role_with_type("skillchainer"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize)
    end

    if trust:role_with_type("follower") then
        menuItems:append(ButtonItem.default('Following', 18))
        childMenuItems.Following = self:getMenuItemForRole(trust:role_with_type("follower"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize)
    end

    if trust:role_with_type("pather") then
        menuItems:append(ButtonItem.default('Paths', 18))
        childMenuItems.Paths = self:getMenuItemForRole(trust:role_with_type("pather"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize)
    end

    if trust:role_with_type("truster") then
        menuItems:append(ButtonItem.default('Alter Egos', 18))
        childMenuItems['Alter Egos'] = self:getMenuItemForRole(trust:role_with_type("truster"), weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize)
    end

    local jobName = res.jobs:with('ens', jobNameShort).en

    menuItems:append(ButtonItem.default('Gambits', 18))
    childMenuItems.Gambits = MenuItem.new(L{
        ButtonItem.default('Custom', 18),
        ButtonItem.default(jobName, 18),
        ButtonItem.default('Reactions', 18),
    }, {
        Custom = GambitSettingsMenuItem.new(trustSettings, trustSettingsMode),
        [jobName] = JobGambitSettingsMenuItem.new(trustSettings, trustSettingsMode),
        Reactions = ReactSettingsMenuItem.new(trustSettings, trustSettingsMode),
    }, nil, "Gambits", "Configure Trust behavior.")

    local settingsMenuItem = MenuItem.new(menuItems, childMenuItems, nil, "Settings", "Configure Trust settings for skillchains, buffs, debuffs and more.")
    return settingsMenuItem
end

function TrustHud:getMenuItemForRole(role, weaponSkillSettings, weaponSkillSettingsMode, trust, jobNameShort, viewSize, trustSettings, trustSettingsMode)
    if role == nil then
        return nil
    end
    if role:get_type() == "buffer" then
        return self:getBufferMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode)
    end
    if role:get_type() == "healer" then
        return self:getHealerMenuItem(trust, trustSettings, trustSettingsMode, viewSize)
    end
    if role:get_type() == "skillchainer" then
        return self:getSkillchainerMenuItem(weaponSkillSettings, weaponSkillSettingsMode, trust, viewSize)
    end
    if role:get_type() == "puller" then
        return self:getPullerMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode, viewSize)
    end
    if role:get_type() == "singer" then
        return self:getSingerMenuItem(trust, trustSettings, trustSettingsMode, viewSize)
    end
    if role:get_type() == "nuker" then
        return self:getNukerMenuItem(trust, trustSettings, trustSettingsMode, jobNameShort, viewSize)
    end
    if role:get_type() == "follower" then
        return self:getFollowerMenuItem(role)
    end
    if role:get_type() == "pather" then
        return self:getPatherMenuItem(role, viewSize)
    end
    if role:get_type() == "truster" then
        return self:getTrusterMenuItem(role)
    end
    return nil
end

function TrustHud:getBufferMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode)
    if jobNameShort ~= 'SCH' then
        local bufferSettingsMenuItem = BufferSettingsMenuItem.new(trustSettings, trustSettingsMode, jobNameShort)
        return bufferSettingsMenuItem
    else
        local childMenuItems = {}

        childMenuItems["Light Arts"] = BufferSettingsMenuItem.new(trustSettings, trustSettingsMode, jobNameShort, 'LightArts')
        childMenuItems["Dark Arts"] = BufferSettingsMenuItem.new(trustSettings, trustSettingsMode, jobNameShort, 'DarkArts')

        local artsSettingsMenuItem = MenuItem.new(L{
            ButtonItem.default('Light Arts', 18),
            ButtonItem.default('Dark Arts', 18),
        }, childMenuItems, nil, "Buffs", "Choose buffs to use.")

        return artsSettingsMenuItem
    end
end

function TrustHud:getHealerMenuItem(trust, trustSettings, trustSettingsMode, viewSize)
    local healerSettingsMenuItem = HealerSettingsMenuItem.new(trust, trustSettings, trustSettingsMode)
    return healerSettingsMenuItem
end

function TrustHud:getSkillchainerMenuItem(weaponSkillSettings, weaponSkillSettingsMode, trust, viewSize)
    local weaponSkillsSettingsMenuItem = WeaponSkillSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trust, function(view)
        return setupView(view, viewSize)
    end)
    return weaponSkillsSettingsMenuItem
end

function TrustHud:getPullerMenuItem(trust, jobNameShort, trustSettings, trustSettingsMode, viewSize)
    local pullerSettingsMenuItem = PullSettingsMenuItem.new(L{}, trust, jobNameShort, self.addon_settings, self.addon_settings:getSettings().battle.targets, trustSettings, trustSettingsMode)
    return pullerSettingsMenuItem
end

function TrustHud:getSingerMenuItem(trust, trustSettings, trustSettingsMode, viewSize)
    local singerSettingsMenuItem = SongSettingsMenuItem.new(self.addon_settings, trustSettings, trustSettingsMode, trust)
    return singerSettingsMenuItem
end

function TrustHud:getNukerMenuItem(trust, trustSettings, trustSettingsMode, jobNameShort, viewSize)
    local nukerSettingsMenuItem = NukeSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, self.addon_settings, jobNameShort, function(view)
        return setupView(view, viewSize)
    end)
    return nukerSettingsMenuItem
end

function TrustHud:getFollowerMenuItem(role)
    return FollowSettingsMenuItem.new(role, self.addon_settings)
end

function TrustHud:getPatherMenuItem(role, viewSize)
    return PathSettingsMenuItem.new(role)
end

function TrustHud:getTrusterMenuItem(role)
    return AlterEgoSettingsMenuItem.new(role, self.addon_settings)
end

function TrustHud:getTrusterMenuItem(role)
    return AlterEgoSettingsMenuItem.new(role, self.addon_settings)
end

function TrustHud:getMenuItems(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, jobNameShort, jobName)
    local viewSize = Frame.new(0, 0, 500, 500)

    local settingsMenuItem = self:getSettingsMenuItem(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, jobNameShort)

    -- Debug
    local debugMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear', 18)
    }, {},
    function()
        local debugView = setupView(DebugView.new(self.actionQueue), viewSize)
        debugView:setShouldRequestFocus(false)
        return debugView
    end, "Debug", "View debug info.")

    local partyMenuItem = MenuItem.new(L{}, {},
    function()
        local truster =  trust:role_with_type("truster")
        local partyMemberView = setupView(PartyMemberView.new(self.party, self.player.player, self.actionQueue, truster and truster.trusts or L{}), viewSize)
        partyMemberView:setShouldRequestFocus(false)
        return partyMemberView
    end, "Party", "View party status.")

    -- Buffs
    local buffsMenuItem = MenuItem.new(L{}, {},
    function()
        local buffer = trust:role_with_type("buffer")
        if buffer then
            return setupView(BufferView.new(buffer), viewSize)
        end
        return nil
    end,"Buffs", "View buffs on the player and party.")

    -- Debuffs
    local debuffsMenuItem = MenuItem.new(L{}, {},
    function()
        local debuffer = trust:role_with_type("debuffer")
        if debuffer then
            local debufferView = setupView(DebufferView.new(debuffer, debuffer:get_target()), viewSize)
            debufferView:setShouldRequestFocus(false)
            return debufferView
        end
        return nil
    end, "Debuffs", "View debuffs on enemies.")

    local targetsMenuItem = PartyTargetsMenuItem.new(self.party, function(view)
        return setupView(view, viewSize)
    end)

    -- Bard
    local singerMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear All', 18),
    }, {},
        function()
            local singer = trust:role_with_type("singer")
            local singerView = setupView(SingerView.new(singer), viewSize)
            singerView:setShouldRequestFocus(true)
            return singerView
        end, "Songs", "View current songs on the player and party.")

    -- Status
    local statusMenuButtons = L{
        ButtonItem.default('Party', 18),
        ButtonItem.default('Buffs', 18),
        ButtonItem.default('Targets', 18)
    }
    if jobNameShort == 'BRD' then
        statusMenuButtons:insert(2, ButtonItem.default('Songs', 18))
    end

    if trust:role_with_type("debuffer") then
        statusMenuButtons:insert(3, ButtonItem.default('Debuffs', 18))
    end

    local statusMenuItem = MenuItem.new(statusMenuButtons, {
        Party = partyMenuItem,
        Buffs = buffsMenuItem,
        Debuffs = debuffsMenuItem,
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

    -- Mode settings

    -- Load
    local loadSettingsItem = LoadSettingsMenuItem.new(self.addon_settings, self.trustModeSettings, trustSettings, function(view)
        return setupView(view, viewSize)
    end)

    -- Config
    local configSettingsItem = ConfigSettingsMenuItem.new(self.addon_settings, function(view)
        return setupView(view, viewSize)
    end)

    -- Main
    local mainMenuItem = MenuItem.new(L{
        ButtonItem.default('Status', 18),
        ButtonItem.default('Settings', 18),
        ButtonItem.default('Load', 18),
        ButtonItem.default('Config', 18),
        ButtonItem.default('Help', 18),
        ButtonItem.default('Donate', 18),
        ButtonItem.default('Discord', 18),
    }, {
        Status = statusMenuItem,
        Settings = settingsMenuItem,
        Load = loadSettingsItem,
        Config = configSettingsItem,
        Help = helpMenuItem,
        Donate = MenuItem.action(function()
            windower.open_url(self.addon_settings:getSettings().donate.url)
        end, "Donate", "Enjoying Trust? Show your support!"),
        Discord = MenuItem.action(function()
            windower.open_url(self.addon_settings:getSettings().discord.url)
        end, "Discord", "Need help? Join the Discord!")
    }, nil, jobName, "Settings for "..jobName..".")

    return mainMenuItem
end

return TrustHud

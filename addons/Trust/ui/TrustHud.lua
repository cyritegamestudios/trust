local AutomatonView = require('cylibs/entity/automaton/ui/automaton_view')
local BackgroundView = require('cylibs/ui/views/background/background_view')
local BufferView = require('cylibs/trust/roles/ui/buffer_view')
local BuffSettingsEditor = require('ui/settings/BuffSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DebufferView = require('cylibs/trust/roles/ui/debuffer_view')
local DebuffSettingsEditor = require('ui/settings/DebuffSettingsEditor')
local DebugView = require('cylibs/actions/ui/debug_view')
local Frame = require('cylibs/ui/views/frame')
local HelpView = require('cylibs/trust/ui/help_view')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local JobAbilitiesSettingsEditor = require('ui/settings/JobAbilitiesSettingsEditor')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MenuView = require('cylibs/ui/menu/menu_view')
local ModesAssistantView = require('cylibs/modes/ui/modes_assistant_view')
local ModesView = require('cylibs/modes/ui/modes_view')
local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local PullSettingsEditor = require('ui/settings/PullSettingsEditor')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local JobAbilityPickerView = require('ui/settings/pickers/JobAbilityPickerView')
local job_util = require('cylibs/util/job_util')
local LoadSettingsView = require('ui/settings/LoadSettingsView')
local Mouse = require('cylibs/ui/input/mouse')
local PartyMemberView = require('cylibs/entity/party/ui/party_member_view')
local party_util = require('cylibs/util/party_util')
local PickerView = require('cylibs/ui/picker/picker_view')
local SingerView = require('cylibs/trust/roles/ui/singer_view')
local SkillchainsView = require('cylibs/battle/skillchains/ui/skillchains_view')
local SongPickerView = require('ui/settings/pickers/SongPickerView')
local SongSettingsEditor = require('ui/settings/SongSettingsEditor')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')
local spell_util = require('cylibs/util/spell_util')
local StatusRemovalPickerView = require('ui/settings/pickers/StatusRemovalPickerView')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TargetsPickerView = require('ui/settings/pickers/TargetsPickerView')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Menu = require('cylibs/ui/menu/menu')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local ViewStack = require('cylibs/ui/views/view_stack')
local WeaponSkillPickerView = require('ui/settings/pickers/WeaponSkillPickerView')
local WeaponSkillsSettingsEditor = require('ui/settings/WeaponSkillSettingsEditor')

local TrustActionHud = require('cylibs/actions/ui/action_hud')
local View = require('cylibs/ui/views/view')

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
        255,
        true
)

function TrustHud.new(player, action_queue, addon_enabled, menu_width, menu_height)
    local self = setmetatable(View.new(), TrustHud)

    self.lastMenuToggle = os.time()
    self.menuSize = Frame.new(0, 0, menu_width, menu_height)
    self.viewStack = ViewStack.new()
    self.actionView = TrustActionHud.new(action_queue)
    self.actionQueue = action_queue
    self.player = player
    self.party = player.party
    self.menuViewStack = ViewStack.new(Frame.new(windower.get_windower_settings().ui_x_res - 128, 50, 0, 0))
    self.mainMenuItem = self:getMainMenuItem()
    self.trustMenu = Menu.new(self.viewStack, self.menuViewStack)

    self:addSubview(self.actionView)

    self.tabbed_view = nil
    self.backgroundImageView = self:getBackgroundImageView()

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        local cellSize = 60
        if indexPath.row == 1 then
            cellSize = 250
        else
            if indexPath.row == 2 then
                cellSize = 120
            end
            cell:setUserInteractionEnabled(true)
        end
        cell:setItemSize(cellSize)
        return cell
    end)

    self.listView = CollectionView.new(dataSource, HorizontalFlowLayout.new(5))
    self.listView.frame.height = 25

    self:addSubview(self.listView)

    dataSource:addItem(TextItem.new('', TextStyle.TargetView), IndexPath.new(1, 1))
    dataSource:addItem(TextItem.new(player.main_job_name_short..' / '..player.sub_job_name_short, TextStyle.Default.Button), IndexPath.new(1, 2))
    dataSource:addItem(TextItem.new('ON', TextStyle.Default.Button, "Trust: ${text}"), IndexPath.new(1, 3))

    self:getDisposeBag():add(self.listView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self.listView:getDelegate():deselectItemAtIndexPath(indexPath)
        if indexPath.row == 2 then
            self:toggleMenu()
        elseif indexPath.row == 3 then
            addon_enabled:setValue(not addon_enabled:getValue())
        end
    end), self.listView:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(addon_enabled:onValueChanged():addAction(function(_, isEnabled)
        local indexPath = IndexPath.new(1, 3)
        local item = self.listView:getDataSource():itemAtIndexPath(indexPath)
        local newText = ''
        if isEnabled then
            newText = 'ON'
        else
            newText = 'OFF'
        end
        self.listView:getDataSource():updateItem(TextItem.new(newText, item:getStyle(), item:getPattern()), indexPath)
    end), addon_enabled:onValueChanged())

    self:getDisposeBag():add(player.party:on_party_target_change():addAction(function(_, target_index)
        local indexPath = IndexPath.new(1, 1)
        local item = self.listView:getDataSource():itemAtIndexPath(indexPath)

        local newItemDataText = ''
        local isClaimed = false
        if target_index == nil then
            newItemDataText = ''
        else
            local target = windower.ffxi.get_mob_by_index(target_index)
            newItemDataText = target.name
            if party_util.party_claimed(target.id) then
                isClaimed = true
            end
        end
        local cell = self.listView:getDataSource():cellForItemAtIndexPath(indexPath)
        if newItemDataText ~= item:getText() or (cell and cell:isHighlighted() ~= isClaimed) then
            self.listView:getDataSource():updateItem(TextItem.new(newItemDataText, item:getStyle(), item:getPattern()), indexPath)
            if isClaimed then
                self.listView:getDelegate():highlightItemAtIndexPath(indexPath)
            end
        end
    end), player.party:on_party_target_change())

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

function TrustHud:layoutIfNeeded()
    View.layoutIfNeeded(self)

    self.listView:setNeedsLayout()
    self.listView:layoutIfNeeded()

    self.actionView:setPosition(250 + 5, self.listView:getSize().height + 5)
    self.actionView:setNeedsLayout()
    self.actionView:layoutIfNeeded()
end

function TrustHud:toggleMenu()
    self.trustMenu:closeAll()

    self.trustMenu:showMenu(self.mainMenuItem)
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

    local mainJobItem = self:getMenuItems(player.trust.main_job, main_trust_settings, state.MainTrustSettingsMode, player.main_job_name_short)
    local subJobItem = self:getMenuItems(player.trust.sub_job, sub_trust_settings, state.SubTrustSettingsMode, player.sub_job_name_short)

    local mainMenuItem = MenuItem.new(L{
        ButtonItem.default(player.main_job_name, 18),
        ButtonItem.default(player.sub_job_name, 18),
    }, {
        [player.main_job_name] = mainJobItem,
        [player.sub_job_name] = subJobItem,
    })

    self.mainMenuItem = mainMenuItem

    return self.mainMenuItem
end

local function createBackgroundView(width, height)
    local backgroundView = BackgroundView.new(Frame.new(0, 0, width, height),
            windower.addon_path..'assets/backgrounds/menu_bg_top.png',
            windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
            windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')
    return backgroundView
end

local function createTitleView(viewSize)
    local titleView = NavigationBar.new(Frame.new(0, 0, viewSize.width, 35))
    return titleView
end

local function setupView(view, viewSize)
    view:setBackgroundImageView(createBackgroundView(viewSize.width, viewSize.height))
    view:setNavigationBar(createTitleView(viewSize))
    view:setSize(viewSize.width, viewSize.height)
    return view
end

function TrustHud:getSettingsMenuItem(trust, trustSettings, trustSettingsMode, jobNameShort)
    local viewSize = Frame.new(0, 0, 500, 500)

    local editSpellItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {
    },
            function(args)
                local spell = args['spell']
                local editSpellView = setupView(SpellSettingsEditor.new(trustSettings, spell), viewSize)
                editSpellView:setTitle("Edit buff.")
                editSpellView:setShouldRequestFocus(false)
                return editSpellView
            end)

    local chooseSpellsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function(args)
                local spellSettings = args['spells']
                local targets = args['targets']

                local jobId = res.jobs:with('ens', jobNameShort).id
                local allBuffs = spell_util.get_spells(function(spell)
                    return spell.levels[jobId] ~= nil and spell.status ~= nil and targets:intersection(S(spell.targets)):length() > 0
                end):map(function(spell) return spell.name end)

                local chooseSpellsView = setupView(SpellPickerView.new(trustSettings, spellSettings, allBuffs), viewSize)
                chooseSpellsView:setTitle("Choose buffs to add.")
                chooseSpellsView:setShouldRequestFocus(false)
                return chooseSpellsView
            end)

    local buffSettingsItem = MenuItem.new(L{
        --ButtonItem.default('Save', 18),
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Edit', 18),
    }, {
        Add = chooseSpellsItem,
        Edit = editSpellItem
    },
            function()
                local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
                local buffSettingsView = BuffSettingsEditor.new(trustSettings, trustSettingsMode, viewSize.width)
                buffSettingsView:setBackgroundImageView(backgroundImageView)
                buffSettingsView:setNavigationBar(createTitleView(viewSize))
                buffSettingsView:setSize(viewSize.width, viewSize.height)
                buffSettingsView:setShouldRequestFocus(false)
                return buffSettingsView
            end)

    local chooseDebuffsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function()
                local jobId = res.jobs:with('ens', jobNameShort).id
                local allDebuffs = spell_util.get_spells(function(spell)
                    return spell.levels[jobId] ~= nil and spell.status ~= nil and L{32, 35, 36, 39, 40, 41, 42}:contains(spell.skill) and spell.targets:contains('Enemy')
                end):map(function(spell) return spell.name end)

                local chooseSpellsView = setupView(SpellPickerView.new(trustSettings, L(T(trustSettings:getSettings())[trustSettingsMode.value].Debuffs), allDebuffs), viewSize)
                chooseSpellsView:setTitle("Choose debuffs to add.")
                chooseSpellsView:setShouldRequestFocus(false)
                return chooseSpellsView
            end)

    local debuffSettingsItem = MenuItem.new(L{
        --ButtonItem.default('Save', 18),
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
    }, {
        Add = chooseDebuffsItem
    },
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local debuffSettingsView = DebuffSettingsEditor.new(trustSettings, trustSettingsMode, viewSize.width)
        debuffSettingsView:setBackgroundImageView(backgroundImageView)
        debuffSettingsView:setNavigationBar(createTitleView(viewSize))
        debuffSettingsView:setSize(viewSize.width, viewSize.height)
        debuffSettingsView:setShouldRequestFocus(false)
        return debuffSettingsView
    end)

    local chooseJobAbilitiesItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function()
                local jobId = res.jobs:with('ens', jobNameShort).id
                local allJobAbilities = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId] end):filter(function(jobAbility)
                    return jobAbility.status ~= nil and S{'Self'}:intersection(S(jobAbility.targets)):length() > 0
                end):map(function(jobAbility) return jobAbility.name end)

                local chooseJobAbilitiesView = setupView(JobAbilityPickerView.new(trustSettings, T(trustSettings:getSettings())[trustSettingsMode.value].JobAbilities, allJobAbilities), viewSize)
                chooseJobAbilitiesView:setTitle("Choose job abilities to add.")
                chooseJobAbilitiesView:setShouldRequestFocus(false)
                return chooseJobAbilitiesView
            end)

    local jobAbilitiesSettingsItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
    }, {
        Add = chooseJobAbilitiesItem,
    },
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local jobAbilitiesSettingsView = JobAbilitiesSettingsEditor.new(trustSettings, trustSettingsMode, viewSize.width)
        jobAbilitiesSettingsView:setBackgroundImageView(backgroundImageView)
        jobAbilitiesSettingsView:setNavigationBar(createTitleView(viewSize))
        jobAbilitiesSettingsView:setSize(viewSize.width, viewSize.height)
        jobAbilitiesSettingsView:setShouldRequestFocus(false)
        return jobAbilitiesSettingsView
    end)

    local chooseTargetsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function()
        local chooseTargetsView = setupView(TargetsPickerView.new(settings, trust), viewSize)
        chooseTargetsView:setTitle("Choose mobs to pull from nearby targets.")
        chooseTargetsView:setShouldRequestFocus(false)
        return chooseTargetsView
    end)

    local pullerSettingsItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
    }, {
        Add = chooseTargetsItem
    },
    function()
        local pullSettingsView = setupView(PullSettingsEditor.new(settings, trust), viewSize)
        pullSettingsView:setShouldRequestFocus(false)
        return pullSettingsView
    end)

    local function createWeaponSkillsItem(skill)
        local chooseWeaponSkillsItem = MenuItem.new(L{
            ButtonItem.default('Confirm', 18),
            ButtonItem.default('Clear', 18),
        }, {},
        function(args)
            local weaponSkills = args['weapon_skills']

            local allWeaponSkills = res.weapon_skills:filter(function(weaponSkill) return weaponSkill.skill == skill end):map(function(weaponSkill) return weaponSkill.name end)

            local chooseWeaponSkillsView = setupView(WeaponSkillPickerView.new(trustSettings, weaponSkills, allWeaponSkills), viewSize)
            chooseWeaponSkillsView:setTitle("Choose weapon skills to add.")
            chooseWeaponSkillsView:setShouldRequestFocus(false)
            return chooseWeaponSkillsView
        end)
        return chooseWeaponSkillsItem
    end

    -- Status Removal
    local statusRemovalMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function()
                local statusRemovalSettings = T(trustSettings:getSettings())[trustSettingsMode.value].CureSettings
                if not statusRemovalSettings.StatusRemovals or not statusRemovalSettings.StatusRemovals.Blacklist then
                    statusRemovalSettings.StatusRemovals = {}
                    statusRemovalSettings.StatusRemovals.Blacklist = L{}
                end
                local blacklistPickerView = setupView(StatusRemovalPickerView.new(trustSettings, statusRemovalSettings.StatusRemovals.Blacklist), viewSize)
                blacklistPickerView:setTitle('Choose status effects to ignore.')
                blacklistPickerView:setShouldRequestFocus(false)
                return blacklistPickerView
            end)

    local healerMenuItem = MenuItem.new(L{
        ButtonItem.default('Blacklist', 18),
    }, {
        ['Blacklist'] = statusRemovalMenuItem
    })

    -- Songs
    local chooseSongsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
            function(args)
                local songs = args['songs']

                local allSongs = spell_util.get_spells(function(spell)
                    return spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
                end):map(function(spell) return spell.name  end)

                local chooseSongsView = setupView(SongPickerView.new(trustSettings, songs, allSongs, args['validator']), viewSize)
                chooseSongsView:setTitle(args['help_text'])
                chooseSongsView:setShouldRequestFocus(false)
                return chooseSongsView
            end)

    local songsSettingsItem = MenuItem.new(L{
        ButtonItem.default('Edit', 18),
    }, {
        Edit = chooseSongsItem
    },
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local songSettingsView = SongSettingsEditor.new(trustSettings, trustSettingsMode, viewSize.width)
        songSettingsView:setBackgroundImageView(backgroundImageView)
        songSettingsView:setNavigationBar(createTitleView(viewSize))
        songSettingsView:setSize(viewSize.width, viewSize.height)
        songSettingsView:setShouldRequestFocus(false)

        return songSettingsView
    end)

    local chooseWeaponSkillsItem = MenuItem.new(L{
        ButtonItem.default('H2H', 18),
        ButtonItem.default('Dagger', 18),
        ButtonItem.default('Sword', 18),
        ButtonItem.default('GreatSword', 18),
        ButtonItem.default('Axe', 18),
        ButtonItem.default('GreatAxe', 18),
        ButtonItem.default('Scythe', 18),
        ButtonItem.default('Polearm', 18),
        ButtonItem.default('Katana', 18),
        ButtonItem.default('GreatKatana', 18),
        ButtonItem.default('Club', 18),
        ButtonItem.default('Staff', 18),
        ButtonItem.default('Archery', 18),
        ButtonItem.default('Marksmanship', 18),
    }, {
        H2H = createWeaponSkillsItem(1),
        Dagger = createWeaponSkillsItem(2),
        Sword = createWeaponSkillsItem(3),
        GreatSword = createWeaponSkillsItem(4),
        Axe = createWeaponSkillsItem(5),
        GreatAxe = createWeaponSkillsItem(6),
        Scythe = createWeaponSkillsItem(7),
        Polearm = createWeaponSkillsItem(8),
        Katana = createWeaponSkillsItem(9),
        GreatKatana = createWeaponSkillsItem(10),
        Club = createWeaponSkillsItem(11),
        Staff = createWeaponSkillsItem(12),
        Archery = createWeaponSkillsItem(25),
        Marksmanship = createWeaponSkillsItem(26)
    })

    local weaponItems = L{
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Move Up', 18),
        ButtonItem.default('Move Down', 18),
    }
    local childMenuItems = {}
    
    local combatSkills = L(job_util.get_skills_for_job(res.jobs:with('ens', jobNameShort).id))
    for combatSkillId in combatSkills:it() do
        weaponItems:append(ButtonItem.default(res.skills[combatSkillId].name, 18))
        childMenuItems[res.skills[combatSkillId].name] = createWeaponSkillsItem(combatSkillId)
    end

    local weaponSkillsSettingsItem = MenuItem.new(weaponItems, childMenuItems,
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local weaponSkillsSettingsView = WeaponSkillsSettingsEditor.new(trustSettings, trustSettingsMode, viewSize.width)
        weaponSkillsSettingsView:setBackgroundImageView(backgroundImageView)
        weaponSkillsSettingsView:setNavigationBar(createTitleView(viewSize))
        weaponSkillsSettingsView:setSize(viewSize.width, viewSize.height)
        weaponSkillsSettingsView:setShouldRequestFocus(false)
        return weaponSkillsSettingsView
    end)

    -- Settings
    local menuItems = L{}

    local buffer = trust:role_with_type("buffer")
    if buffer then
        menuItems:append(ButtonItem.default('Abilities', 18))
        menuItems:append(ButtonItem.default('Buffs', 18))
    end

    -- Add menu items only if the Trust has the appropriate role
    local debuffer = trust:role_with_type("debuffer")
    if debuffer then
        menuItems:append(ButtonItem.default('Debuffs', 18))
    end

    if trust:role_with_type("healer") then
        menuItems:append(ButtonItem.default('Healing', 18))
    end

    if trust:role_with_type("puller") then
        menuItems:append(ButtonItem.default('Pulling', 18))
    end

    if trust:role_with_type("singer") then
        menuItems:append(ButtonItem.default('Songs', 18))
    end

    menuItems:append(ButtonItem.default('Weaponskills', 18))

    local settingsMenuItem = MenuItem.new(menuItems, {
        Abilities = jobAbilitiesSettingsItem,
        Buffs = buffSettingsItem,
        Debuffs = debuffSettingsItem,
        Healing = healerMenuItem,
        Pulling = pullerSettingsItem,
        Songs = songsSettingsItem,
        Weaponskills = weaponSkillsSettingsItem
    })
    return settingsMenuItem
end

function TrustHud:getMenuItems(trust, trustSettings, trustSettingsMode, jobNameShort)
    local viewSize = Frame.new(0, 0, 500, 500)

    -- Modes Assistant
    local modesAssistantMenuItem = MenuItem.new(L{}, {},
    function()
        local modesAssistantView = setupView(ModesAssistantView.new(trust), viewSize)
        return modesAssistantView
    end)

    -- Modes
    local modesMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Assistant', 18),
    }, {
        Assistant = modesAssistantMenuItem
    },
    function()
        local modesView = setupView(ModesView.new(L(T(state):keyset()):sort()), viewSize)
        modesView:setShouldRequestFocus(false)
        return modesView
    end)

    local settingsMenuItem = self:getSettingsMenuItem(trust, trustSettings, trustSettingsMode, jobNameShort)

    -- Debug
    local debugMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear', 18)
    }, {},
    function()
        local debugView = setupView(DebugView.new(self.actionQueue), viewSize)
        debugView:setShouldRequestFocus(false)
        return debugView
    end)

    local partyMenuItem = MenuItem.new(L{}, {},
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local truster =  trust:role_with_type("truster")
        local partyMemberView = PartyMemberView.new(self.party, self.player.player, self.actionQueue, truster and truster.trusts or L{})
        partyMemberView:setBackgroundImageView(backgroundImageView)
        partyMemberView:setNavigationBar(createTitleView(viewSize))
        partyMemberView:setSize(viewSize.width, viewSize.height)
        return partyMemberView
    end)

    -- Buffs
    local buffsMenuItem = MenuItem.new(L{}, {},
    function()
        local buffer = trust:role_with_type("buffer")
        if buffer then
            return setupView(BufferView.new(buffer), viewSize)
        end
        return nil
    end)

    -- Debuffs
    local debuffsMenuItem = MenuItem.new(L{}, {},
    function()
        local debuffer = trust:role_with_type("debuffer")
        if debuffer then
            return setupView(DebufferView.new(debuffer, debuffer:get_battle_target()), viewSize)
        end
        return nil
    end)

    -- Puppetmaster
    local automatonMenuItem = MenuItem.new(L{}, {},
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local automatonView = AutomatonView.new(trustSettings, trustSettingsMode)
        automatonView:setBackgroundImageView(backgroundImageView)
        automatonView:setNavigationBar(createTitleView(viewSize))
        automatonView:setSize(viewSize.width, viewSize.height)
        return automatonView
    end)

    -- Bard
    local singerMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear All', 18),
    }, {},
        function()
            local singer = trust:role_with_type("singer")
            local singerView = setupView(SingerView.new(singer), viewSize)
            singerView:setShouldRequestFocus(false)
            return singerView
        end)

    -- Status
    local statusMenuButtons = L{
        ButtonItem.default('Party', 18),
        ButtonItem.default('Buffs', 18),
        ButtonItem.default('Debuffs', 18),
        ButtonItem.default('Modes', 18),
    }
    if jobNameShort == 'PUP' then
        statusMenuButtons:insert(2, ButtonItem.default('Automaton', 18))
    elseif jobNameShort == 'BRD' then
        statusMenuButtons:insert(2, ButtonItem.default('Songs', 18))
    end

    local statusMenuItem = MenuItem.new(statusMenuButtons, {
        Party = partyMenuItem,
        Automaton = automatonMenuItem,
        Buffs = buffsMenuItem,
        Debuffs = debuffsMenuItem,
        Modes = modesMenuItem,
        Songs = singerMenuItem,
    })

    -- Help
    local helpMenuItem = MenuItem.new(L{
        ButtonItem.default('Debug', 18),
    }, {
        Debug = debugMenuItem,
    },
    function()
        local helpView = setupView(HelpView.new(jobNameShort), viewSize)
        helpView:setShouldRequestFocus(false)
        return helpView
    end)

    -- Load
    local loadSettingsItem = MenuItem.new(L{}, {},
    function()
        local helpView = setupView(LoadSettingsView.new(trustSettingsMode), viewSize)
        return helpView
    end)

    -- Main
    local mainMenuItem = MenuItem.new(L{
        ButtonItem.default('Status', 18),
        ButtonItem.default('Settings', 18),
        ButtonItem.default('Load', 18),
        ButtonItem.default('Help', 18),
    }, {
        Status = statusMenuItem,
        Settings = settingsMenuItem,
        Load = loadSettingsItem,
        Help = helpMenuItem
    })

    return mainMenuItem
end

return TrustHud

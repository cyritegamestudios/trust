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
local ElementPickerView = require('ui/settings/pickers/ElementPickerView')
local Frame = require('cylibs/ui/views/frame')
local GameInfo = require('cylibs/util/ffxi/game_info')
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
local NukeSettingsEditor = require('ui/settings/NukeSettingsEditor')
local PartyMemberView = require('cylibs/entity/party/ui/party_member_view')
local PartyTargetView = require('cylibs/entity/party/ui/party_target_view')
local party_util = require('cylibs/util/party_util')
local PickerView = require('cylibs/ui/picker/picker_view')
local SingerView = require('cylibs/trust/roles/ui/singer_view')
local skillchain_util = require('cylibs/util/skillchain_util')
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
local TrustInfoBar = require('ui/TrustInfoBar')
local Menu = require('cylibs/ui/menu/menu')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local ViewStack = require('cylibs/ui/views/view_stack')
local WeaponSkillPickerView = require('ui/settings/pickers/WeaponSkillPickerView')
local WeaponSkillsSettingsEditor = require('ui/settings/WeaponSkillSettingsEditor')
local WeaponSkillSettingsMenuItem = require('ui/settings/menus/WeaponSkillSettingsMenuItem')

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
    self.targetActionQueue = ActionQueue.new(nil, false, 5, false, true)
    self.targetActionView = TrustActionHud.new(self.targetActionQueue)
    self.actionQueue = action_queue
    self.player = player
    self.party = player.party
    self.gameInfo = GameInfo.new()
    self.menuViewStack = ViewStack.new(Frame.new(windower.get_windower_settings().ui_x_res - 128, 50, 0, 0))
    self.menuViewStack.name = "menu stack"
    self.mainMenuItem = self:getMainMenuItem()

    self.infoViewContainer = View.new(Frame.new(17, 17, windower.get_windower_settings().ui_x_res - 18, 30))
    self.infoBar = TrustInfoBar.new(Frame.new(0, 0, windower.get_windower_settings().ui_x_res - 18, 30))
    self.infoBar:setVisible(false)

    self.infoViewContainer:addSubview(self.infoBar)

    self.infoViewContainer:setNeedsLayout()
    self.infoViewContainer:layoutIfNeeded()

    self.trustMenu = Menu.new(self.viewStack, self.menuViewStack, self.infoBar)

    self:addSubview(self.actionView)
    self:addSubview(self.targetActionView)

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

    self:getDisposeBag():add(player.party:on_party_target_change():addAction(function(_, target_index, _)
        local indexPath = IndexPath.new(1, 1)
        local item = self.listView:getDataSource():itemAtIndexPath(indexPath)

        local newItemDataText = ''
        local isClaimed = false
        if target_index == nil or target_index == 0 then
            newItemDataText = ''
        else
            local target = windower.ffxi.get_mob_by_index(target_index)
            if target then
                newItemDataText = target.name
                if party_util.party_claimed(target.id) then
                    isClaimed = true
                end
            end
        end
        local cell = self.listView:getDataSource():cellForItemAtIndexPath(indexPath)
        if newItemDataText ~= item:getText() or (cell and cell:isHighlighted() ~= isClaimed) then
            self.listView:getDataSource():updateItem(TextItem.new(newItemDataText, item:getStyle(), item:getPattern()), indexPath)
            if isClaimed then
                self.listView:getDelegate():highlightItemAtIndexPath(indexPath)
            else
                self.listView:getDelegate():deHighlightItemAtIndexPath(indexPath)
            end
        end
    end), player.party:on_party_target_change())

    local skillchainer = player.trust.main_job:role_with_type("skillchainer")
    self:getDisposeBag():add(skillchainer:on_skillchain():addAction(function(target_id, step)
        self.targetActionQueue:clear()
        if skillchainer:get_target() and skillchainer:get_target():get_id() == target_id then
            local element = step:get_skillchain():get_name()
            local text = "Step %d: %s%s\\cr":format(step:get_step(), skillchain_util.color_for_element(element), element)
            local skillchain_step_action = BlockAction.new(function()
                coroutine.sleep(math.max(1, step:get_time_remaining()))
            end, element..step:get_step(), text)
            self.targetActionQueue:push_action(skillchain_step_action, true)
        end
    end), skillchainer:on_skillchain())

    self:getDisposeBag():add(skillchainer:on_skillchain_ended():addAction(function(target_id)
        if skillchainer:get_target() and skillchainer:get_target():get_id() == target_id then
            self.targetActionQueue:clear()
        end
    end), skillchainer:on_skillchain_ended())

    self:getDisposeBag():add(self.gameInfo:onMenuChange():addAction(function(_, isMenuOpen)
        if isMenuOpen then
            self.trustMenu:closeAll()
        end
    end), self.gameInfo:onMenuChange())

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

    self.targetActionView:setPosition(0, self.listView:getSize().height + 5)
    self.targetActionView:setNeedsLayout()
    self.targetActionView:layoutIfNeeded()

    self.actionView:setPosition(250 + 5, self.listView:getSize().height + 5)
    self.actionView:setNeedsLayout()
    self.actionView:layoutIfNeeded()

    self.infoBar:setNeedsLayout()
    self.infoBar:layoutIfNeeded()
end

function TrustHud:getViewStack()
    return self.viewStack
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

    local mainJobItem = self:getMenuItems(player.trust.main_job, main_trust_settings, state.MainTrustSettingsMode, weapon_skill_settings, state.WeaponSkillSettingsMode, player.main_job_name_short, player.main_job_name)
    local subJobItem = self:getMenuItems(player.trust.sub_job, sub_trust_settings, state.SubTrustSettingsMode, nil, nil, player.sub_job_name_short, player.sub_job_name)

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

function TrustHud:getSettingsMenuItem(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, jobNameShort)
    local viewSize = Frame.new(0, 0, 500, 500)

    local editSpellItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
    function(args)
        local spell = args['spell']
        local editSpellView = setupView(SpellSettingsEditor.new(trustSettings, spell), viewSize)
        editSpellView:setTitle("Edit buff.")
        editSpellView:setShouldRequestFocus(true)
        return editSpellView
    end)

    local chooseSpellsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function(args)
        local spellSettings = args['spells']
        local targets = args['targets']
        local defaultJobNames = L{}
        if targets:contains('Party') then
            defaultJobNames = job_util.all_jobs()
        end

        local jobId = res.jobs:with('ens', jobNameShort).id
        local allBuffs = spell_util.get_spells(function(spell)
            return spell.levels[jobId] ~= nil and spell.status ~= nil and targets:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.en end)

        local chooseSpellsView = setupView(SpellPickerView.new(trustSettings, spellSettings, allBuffs, defaultJobNames, false), viewSize)
        chooseSpellsView:setTitle("Choose buffs to add.")
        return chooseSpellsView
    end)

    local selfBuffSettingsItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Edit', 18),
    }, {
        Add = chooseSpellsItem,
        Edit = editSpellItem
    },
    function()
        local buffs = T(trustSettings:getSettings())[trustSettingsMode.value].SelfBuffs

        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local buffSettingsView = BuffSettingsEditor.new(trustSettings, buffs, S{'Self'})
        buffSettingsView:setBackgroundImageView(backgroundImageView)
        buffSettingsView:setNavigationBar(createTitleView(viewSize))
        buffSettingsView:setSize(viewSize.width, viewSize.height)
        buffSettingsView:setShouldRequestFocus(true)
        buffSettingsView:setTitle("Edit buffs on the player.")
        return buffSettingsView
    end, "Buffs", "Edit buffs to use on the player.")

    local partyBuffSettingsItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Edit', 18),
    }, {
        Add = chooseSpellsItem,
        Edit = editSpellItem
    },
            function()
                local buffs = T(trustSettings:getSettings())[trustSettingsMode.value].PartyBuffs

                local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
                local buffSettingsView = BuffSettingsEditor.new(trustSettings, buffs, S{'Party'})
                buffSettingsView:setBackgroundImageView(backgroundImageView)
                buffSettingsView:setNavigationBar(createTitleView(viewSize))
                buffSettingsView:setSize(viewSize.width, viewSize.height)
                buffSettingsView:setShouldRequestFocus(true)
                buffSettingsView:setTitle("Edit buffs on the party.")
                return buffSettingsView
            end, "Buffs", "Edit buffs to use on party members.")

    local buffSettingsItem = MenuItem.new(L{
        ButtonItem.default('Self', 18),
        ButtonItem.default('Party', 18),
    }, {
        Self = selfBuffSettingsItem,
        Party = partyBuffSettingsItem
    }, nil, "Buffs", "Choose buffs to use.")

    local chooseDebuffsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function()
                local jobId = res.jobs:with('ens', jobNameShort).id
                local allDebuffs = spell_util.get_spells(function(spell)
                    return spell.levels[jobId] ~= nil and spell.status ~= nil and L{32, 35, 36, 39, 40, 41, 42}:contains(spell.skill) and spell.targets:contains('Enemy')
                end):map(function(spell) return spell.en end)

                local chooseSpellsView = setupView(SpellPickerView.new(trustSettings, L(T(trustSettings:getSettings())[trustSettingsMode.value].Debuffs), allDebuffs, L{}, false), viewSize)
                chooseSpellsView:setTitle("Choose debuffs to add.")
                return chooseSpellsView
            end)

    local debuffSettingsItem = MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Help', 18)
    }, {
        Add = chooseDebuffsItem
    },
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local debuffSettingsView = DebuffSettingsEditor.new(trustSettings, trustSettingsMode, viewSize.width)
        debuffSettingsView:setBackgroundImageView(backgroundImageView)
        debuffSettingsView:setNavigationBar(createTitleView(viewSize))
        debuffSettingsView:setSize(viewSize.width, viewSize.height)
        return debuffSettingsView
    end, "Debuffs", "Choose debuffs to use on enemies.")

    local chooseJobAbilitiesItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function()
                local jobId = res.jobs:with('ens', jobNameShort).id
                local allJobAbilities = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId] end):filter(function(jobAbility)
                    return jobAbility.status ~= nil and S{'Self'}:intersection(S(jobAbility.targets)):length() > 0
                end):map(function(jobAbility) return jobAbility.en end)

                local chooseJobAbilitiesView = setupView(JobAbilityPickerView.new(trustSettings, T(trustSettings:getSettings())[trustSettingsMode.value].JobAbilities, allJobAbilities), viewSize)
                chooseJobAbilitiesView:setTitle("Choose job abilities to add.")
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
        return jobAbilitiesSettingsView
    end, "Job Abilities", "Choose job abilities to use.")

    local chooseTargetsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function()
        local chooseTargetsView = setupView(TargetsPickerView.new(settings, trust), viewSize)
        chooseTargetsView:setTitle("Choose mobs to pull from nearby targets.")
        chooseTargetsView:setShouldRequestFocus(true)
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
        pullSettingsView:setShouldRequestFocus(true)
        return pullSettingsView
    end, "Pulling", "Choose which enemies to pull.")

    local function createWeaponSkillsItem(skill, weapon_skill_settings_key)
        local chooseWeaponSkillsItem = MenuItem.new(L{
            ButtonItem.default('Confirm', 18),
            ButtonItem.default('Clear', 18),
        }, {},
        function(args)
            local weaponSkills = T(trustSettings:getSettings())[trustSettingsMode.value].Skillchains[weapon_skill_settings_key]
            local allWeaponSkills = res.weapon_skills:filter(function(weaponSkill) return weaponSkill.skill == skill and not weaponSkills:contains(weaponSkill.en) end):map(function(weaponSkill) return weaponSkill.en end)

            local chooseWeaponSkillsView = setupView(WeaponSkillPickerView.new(trustSettings, weaponSkills, allWeaponSkills), viewSize)
            chooseWeaponSkillsView:setTitle("Choose weapon skills to add.")
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
                blacklistPickerView:setShouldRequestFocus(true)
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
                end):map(function(spell) return spell.en  end)

                local chooseSongsView = setupView(SongPickerView.new(trustSettings, songs, allSongs, args['validator']), viewSize)
                chooseSongsView:setTitle(args['help_text'])
                chooseSongsView:setShouldRequestFocus(true)
                return chooseSongsView
            end)

    local songsSettingsItem = MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Help', 18),
    }, {
        Edit = chooseSongsItem,
    },
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local songSettingsView = SongSettingsEditor.new(trustSettings, trustSettingsMode, viewSize.width)
        songSettingsView:setBackgroundImageView(backgroundImageView)
        songSettingsView:setNavigationBar(createTitleView(viewSize))
        songSettingsView:setSize(viewSize.width, viewSize.height)
        songSettingsView:setShouldRequestFocus(true)

        return songSettingsView
    end)

    local function createAddWeaponSkillsSettingsItem(weapon_skill_settings_key)
        local weaponItems = L{}
        local childMenuItems = {}

        local combatSkills = L(job_util.get_skills_for_job(res.jobs:with('ens', jobNameShort).id))
        for combatSkillId in combatSkills:it() do
            weaponItems:append(ButtonItem.default(res.skills[combatSkillId].en, 18))
            childMenuItems[res.skills[combatSkillId].en] = createWeaponSkillsItem(combatSkillId, weapon_skill_settings_key)
        end
        weaponItems:append(ButtonItem.default('Help', 18))

        return MenuItem.new(weaponItems, childMenuItems)
    end

    local function createWeaponSkillsSettingsItem(weapon_skill_settings_key, help_text)
        local chooseWeaponSkillsItem = MenuItem.new(L{
            ButtonItem.default('Add', 18),
            ButtonItem.default('Remove', 18),
            ButtonItem.default('Move Up', 18),
            ButtonItem.default('Move Down', 18),
        }, {
            Add = createAddWeaponSkillsSettingsItem(weapon_skill_settings_key)
        },
        function(args)
            local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
            local weaponSkills = T(trustSettings:getSettings())[trustSettingsMode.value].Skillchains[weapon_skill_settings_key]

            local weaponSkillsSettingsView = WeaponSkillsSettingsEditor.new(weaponSkills, trustSettings)
            weaponSkillsSettingsView:setBackgroundImageView(backgroundImageView)
            weaponSkillsSettingsView:setNavigationBar(createTitleView(viewSize))
            weaponSkillsSettingsView:setSize(viewSize.width, viewSize.height)
            weaponSkillsSettingsView:setTitle(help_text)
            return weaponSkillsSettingsView
        end)
        return chooseWeaponSkillsItem
    end

    -- Nukes
    local chooseNukesItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
            function(args)
                local spellSettings = args['spells']

                local jobId = res.jobs:with('ens', jobNameShort).id
                local allSpells = spell_util.get_spells(function(spell)
                    return spell.levels[jobId] ~= nil and spell.type == 'BlackMagic' and S{ 'Enemy' }:intersection(S(spell.targets)):length() > 0
                end):map(function(spell) return spell.en end):sort()

                local sortSpells = function(spells)
                    spell_util.sort_by_element(spells, true)
                end

                local chooseSpellsView = setupView(SpellPickerView.new(trustSettings, spellSettings, allSpells, L{}, true, sortSpells), viewSize)
                chooseSpellsView:setTitle("Choose spells to nuke with.")
                return chooseSpellsView
            end)

    local nukeElementBlacklistItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
            function()
                local nukeSettings = T(trustSettings:getSettings())[trustSettingsMode.value].NukeSettings
                if not nukeSettings.Blacklist then
                    nukeSettings.Blacklist = L{}
                end
                local blacklistPickerView = setupView(ElementPickerView.new(trustSettings, nukeSettings.Blacklist), viewSize)
                blacklistPickerView:setTitle('Choose elements to avoid when magic bursting or free nuking.')
                blacklistPickerView:setShouldRequestFocus(true)
                return blacklistPickerView
            end)

    local nukeSettingsItem = MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Blacklist', 18),
        ButtonItem.default('Help', 18),
    }, {
        Edit = chooseNukesItem,
        Blacklist = nukeElementBlacklistItem,
    },
    function()
        local nukeSettingsView = setupView(NukeSettingsEditor.new(trustSettings, trustSettingsMode), viewSize)
        nukeSettingsView:setShouldRequestFocus(true)
        return nukeSettingsView
    end)

    -- Settings
    local menuItems = L{}
    local childMenuItems = {
        Abilities = jobAbilitiesSettingsItem,
        Buffs = buffSettingsItem,
        Debuffs = debuffSettingsItem,
        Healing = healerMenuItem,
        Pulling = pullerSettingsItem,
        Songs = songsSettingsItem,
        Nukes = nukeSettingsItem,
    }

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

    if trust:role_with_type("healer") and trust:role_with_type("statusremover") then
        menuItems:append(ButtonItem.default('Healing', 18))
    end

    if trust:role_with_type("puller") then
        menuItems:append(ButtonItem.default('Pulling', 18))
    end

    if trust:role_with_type("singer") then
        menuItems:append(ButtonItem.default('Songs', 18))
    end

    if trust:role_with_type("nuker") then
        menuItems:append(ButtonItem.default('Nukes', 18))
    end

    if trust:role_with_type("skillchainer") then
        menuItems:append(ButtonItem.default('Weaponskills', 18))
        childMenuItems.Weaponskills = self:getMenuItemForRole(trust:role_with_type("skillchainer"), weaponSkillSettings, weaponSkillSettingsMode, trust, viewSize)
    end

    local settingsMenuItem = MenuItem.new(menuItems, childMenuItems, nil, "Settings", "Configure Trust settings for skillchains, buffs, debuffs and more.")
    return settingsMenuItem
end

function TrustHud:getMenuItemForRole(role, weaponSkillSettings, weaponSkillSettingsMode, trust, viewSize)
    if role == nil then
        return nil
    end
    if role:get_type() == "skillchainer" then
        return self:getSkillchainerMenuItem(weaponSkillSettings, weaponSkillSettingsMode, trust, viewSize)
    end
    return nil
end

function TrustHud:getSkillchainerMenuItem(weaponSkillSettings, weaponSkillSettingsMode, trust, viewSize)
    local weaponSkillsSettingsMenuItem = WeaponSkillSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, trust, function(view)
        return setupView(view, viewSize)
    end)
    return weaponSkillsSettingsMenuItem
end

function TrustHud:getMenuItems(trust, trustSettings, trustSettingsMode, weaponSkillSettings, weaponSkillSettingsMode, jobNameShort, jobName)
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
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "View and change Trust modes.")

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
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local truster =  trust:role_with_type("truster")
        local partyMemberView = PartyMemberView.new(self.party, self.player.player, self.actionQueue, truster and truster.trusts or L{})
        partyMemberView:setBackgroundImageView(backgroundImageView)
        partyMemberView:setNavigationBar(createTitleView(viewSize))
        partyMemberView:setSize(viewSize.width, viewSize.height)
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
            return setupView(DebufferView.new(debuffer, debuffer:get_target()), viewSize)
        end
        return nil
    end, "Debuffs", "View debuffs on enemies.")

    local targetsMenuItem = MenuItem.new(L{}, {},
    function(args)
        local targetsView = setupView(PartyTargetView.new(self.party.target_tracker), viewSize)
        targetsView:setShouldRequestFocus(false)
        return targetsView
    end, "Targets", "View info for enemies the party is fighting.")

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
        ButtonItem.default('Targets', 18)
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
        Targets = targetsMenuItem,
        Songs = singerMenuItem,
    }, nil, "Status", "View status of party members and enemies.")

    -- Help
    local helpMenuItem = MenuItem.new(L{
        ButtonItem.default('Debug', 18),
    }, {
        Debug = debugMenuItem,
    },
    function()
        local helpView = setupView(HelpView.new(jobNameShort), viewSize)
        return helpView
    end, "Help", "Get help using Trust.")

    -- Load
    local loadSettingsItem = MenuItem.new(L{}, {},
    function()
        local loadSettingsView = setupView(LoadSettingsView.new(trustSettingsMode), viewSize)
        loadSettingsView:setShouldRequestFocus(true)
        return loadSettingsView
    end, "Load Settings", "Load saved mode and job settings.")

    -- Main
    local mainMenuItem = MenuItem.new(L{
        ButtonItem.default('Status', 18),
        ButtonItem.default('Settings', 18),
        ButtonItem.default('Load', 18),
        ButtonItem.default('Help', 18),
        ButtonItem.default('Donate', 18),
    }, {
        Status = statusMenuItem,
        Settings = settingsMenuItem,
        Load = loadSettingsItem,
        Help = helpMenuItem,
        Donate = MenuItem.action(function()
            windower.open_url(settings.donate.url)
        end, "Donate", "Enjoying Trust? Show your support!")
    }, nil, jobName, "Settings for "..jobName..".")

    return mainMenuItem
end

return TrustHud

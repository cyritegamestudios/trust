local BackgroundView = require('cylibs/ui/views/background/background_view')
local BufferView = require('cylibs/trust/roles/ui/buffer_view')
local BuffSettingsEditor = require('ui/settings/BuffSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local DebufferView = require('cylibs/trust/roles/ui/debuffer_view')
local DebugView = require('cylibs/actions/ui/debug_view')
local Frame = require('cylibs/ui/views/frame')
local HelpView = require('cylibs/trust/ui/help_view')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MenuView = require('cylibs/ui/menu/menu_view')
local ModesAssistantView = require('cylibs/modes/ui/modes_assistant_view')
local ModesView = require('cylibs/modes/ui/modes_view')
local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local HorizontalFlowLayout = require('cylibs/ui/collection_view/layouts/horizontal_flow_layout')
local ImageCollectionViewCell = require('cylibs/ui/collection_view/cells/image_collection_view_cell')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local Mouse = require('cylibs/ui/input/mouse')
local PartyMemberView = require('cylibs/entity/party/ui/party_member_view')
local party_util = require('cylibs/util/party_util')
local PickerView = require('cylibs/ui/picker/picker_view')
local SkillchainsView = require('cylibs/battle/skillchains/ui/skillchains_view')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')
local spell_util = require('cylibs/util/spell_util')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Menu = require('cylibs/ui/menu/menu')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')
local ViewStack = require('cylibs/ui/views/view_stack')

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

--[[TrustHud.Menus = {
    Default = L{
        ButtonItem.default('Modes', 18),
        --ButtonItem.default('Party', 18),
        ButtonItem.default('Debug', 18),
        ButtonItem.default('Settings', 18),
    },
    Settings = L{
        ButtonItem.default('Buffs', 18),
        ButtonItem.default('Debuffs', 18),
        ButtonItem.default('Skillchains', 18),
    },
    Modes = L{
        ButtonItem.default('Save', 18),
    },
    Debug = L{
        ButtonItem.default('Clear', 18),
    },
    Buffs = L{
        ButtonItem.default('Edit', 18),
    },
    Debuffs = L{
        ButtonItem.default('Edit', 18),
    },
    Edit = L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Delete', 18),
    }
}]]

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
    --[[self.trustMenu = Menu.new(self.viewStack, self.menuViewStack, function(textItem)
        local viewSize = Frame.new(0, 0, 500, 500)

        local function createBackgroundView(width, height)
            local backgroundView = BackgroundView.new(Frame.new(0, 0, width, height),
                    windower.addon_path..'assets/backgrounds/menu_bg_top.png',
                    windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
                    windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')
            return backgroundView
        end

        local function createTitleView()
            local titleView = NavigationBar.new(Frame.new(0, 0, viewSize.width, 35))
            return titleView
        end

        if textItem:getText() == 'Modes' then
            local modesView = ModesView.new(L(T(state):keyset()):sort(), self.menuViewStack)
            modesView:setBackgroundImageView(createBackgroundView(viewSize.width, viewSize.height))
            modesView:setNavigationBar(createTitleView())
            modesView:setSize(viewSize.width, viewSize.height)
            return modesView
        elseif textItem:getText() == 'Debug' then
            local debugView = DebugView.new(action_queue)
            debugView:setBackgroundImageView(createBackgroundView(viewSize.width, viewSize.height))
            debugView:setNavigationBar(createTitleView())
            debugView:setSize(viewSize.width, viewSize.height)
            return debugView
        elseif textItem:getText() == 'Buffs' then
            local buffer = player.trust.main_job:role_with_type("buffer")
            if buffer then
                local bufferView = BufferView.new(buffer)
                bufferView:setBackgroundImageView(createBackgroundView(viewSize.width, viewSize.height))
                bufferView:setNavigationBar(createTitleView())
                bufferView:setSize(viewSize.width, viewSize.height)
                return bufferView
            end
        elseif textItem:getText() == 'Edit' then
            local currentView = self.viewStack:getCurrentView()
            if currentView then
                if currentView.__type == 'BufferView' then
                    local bufferEditor = BuffSettingsEditor.new(main_trust_settings, state.MainTrustSettingsMode, viewSize.width, self.menuViewStack)
                    bufferEditor:setBackgroundImageView(createBackgroundView(viewSize.width, viewSize.height))
                    bufferEditor:setNavigationBar(createTitleView())
                    bufferEditor:setSize(viewSize.width, viewSize.height)
                    return bufferEditor
                end
            end
        end
        return nil
    end, TrustHud.Menus)]]

    self:addSubview(self.actionView)

    self.tabbed_view = nil
    self.backgroundImageView = self:getBackgroundImageView()

    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        local cellSize = 60
        if indexPath.row == 1 then
            cellSize = 250
        else
            cell:setUserInteractionEnabled(true)
        end
        cell:setItemSize(cellSize)
        return cell
    end)

    self.listView = CollectionView.new(dataSource, HorizontalFlowLayout.new(5))
    self.listView.frame.height = 25

    self:addSubview(self.listView)

    dataSource:addItem(TextItem.new('', TextStyle.TargetView), IndexPath.new(1, 1))
    dataSource:addItem(TextItem.new(player.main_job_name_short, TextStyle.Default.Button), IndexPath.new(1, 2))
    dataSource:addItem(TextItem.new(player.sub_job_name_short, TextStyle.Default.Button), IndexPath.new(1, 3))
    dataSource:addItem(TextItem.new('ON', TextStyle.Default.Button, "Trust: ${text}"), IndexPath.new(1, 4))

    self:getDisposeBag():add(self.listView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        self.listView:getDelegate():deselectItemAtIndexPath(indexPath)
        if indexPath.row == 2 then
            self:toggleMenu()
        elseif indexPath.row == 3 then
            self:toggleMenu()
        elseif indexPath.row == 4 then
            addon_enabled:setValue(not addon_enabled:getValue())
        end
    end), self.listView:getDelegate():didSelectItemAtIndexPath())

    self:getDisposeBag():add(addon_enabled:onValueChanged():addAction(function(_, isEnabled)
        local indexPath = IndexPath.new(1, 4)
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

function TrustHud:getMenuItems(trust, trustSettings, trustSettingsMode, jobNameShort)
    local viewSize = Frame.new(0, 0, 500, 500)

    local function createBackgroundView(width, height)
        local backgroundView = BackgroundView.new(Frame.new(0, 0, width, height),
                windower.addon_path..'assets/backgrounds/menu_bg_top.png',
                windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
                windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')
        return backgroundView
    end

    local function createTitleView()
        local titleView = NavigationBar.new(Frame.new(0, 0, viewSize.width, 35))
        return titleView
    end

    local function setupView(view)
        view:setBackgroundImageView(createBackgroundView(viewSize.width, viewSize.height))
        view:setNavigationBar(createTitleView())
        view:setSize(viewSize.width, viewSize.height)
        return view
    end

    -- Modes Assistant
    local modesAssistantMenuItem = MenuItem.new(L{}, {},
    function()
        local modesAssistantView = setupView(ModesAssistantView.new())
        --modesAssistantView:setShouldRequestFocus(false)
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
        local modesView = setupView(ModesView.new(L(T(state):keyset()):sort()))
        modesView:setShouldRequestFocus(false)
        return modesView
    end)

    -- Buffs
    local buffsMenuItem = MenuItem.new(L{}, {},
    function()
        local buffer = trust:role_with_type("buffer")
        if buffer then
            return setupView(BufferView.new(buffer))
        end
        return nil
    end)

    -- Debuffs
    local debuffsMenuItem = MenuItem.new(L{}, {},
    function()
        local debuffer = trust:role_with_type("debuffer")
        if debuffer then
            return setupView(DebufferView.new(debuffer, debuffer:get_battle_target()))
        end
        return nil
    end)

    local chooseSpellsItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function()

        local allBuffs = spell_util.get_spells(function(spell)
            return spell.status ~= nil and S{'Self', 'Party'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.name end)

        local chooseSpellsView = setupView(SpellPickerView.new(trustSettings, L(T(trustSettings:getSettings())[trustSettingsMode.value].SelfBuffs)))
        chooseSpellsView:setTitle("Choose buffs to add.")
        chooseSpellsView:setShouldRequestFocus(false)
        return chooseSpellsView
    end)

    local buffSettingsItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
    }, {
        Add = chooseSpellsItem
    },
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local buffSettingsView = BuffSettingsEditor.new(trustSettings, trustSettingsMode, viewSize.width)
        buffSettingsView:setBackgroundImageView(backgroundImageView)
        buffSettingsView:setNavigationBar(createTitleView())
        buffSettingsView:setSize(viewSize.width, viewSize.height)
        buffSettingsView:setShouldRequestFocus(false)
        return buffSettingsView
    end)

    -- Settings
    local settingsMenuItem = MenuItem.new(L{
        ButtonItem.default('Buffs', 18),
    }, {
        Buffs = buffSettingsItem,
    })

    -- Debug
    local debugMenuItem = MenuItem.new(L{
        ButtonItem.default('Clear', 18)
    }, {},
    function()
        local debugView = setupView(DebugView.new(self.actionQueue))
        debugView:setShouldRequestFocus(false)
        return debugView
    end)

    local partyMenuItem = MenuItem.new(L{}, {},
    function()
        local backgroundImageView = createBackgroundView(viewSize.width, viewSize.height)
        local truster =  trust:role_with_type("truster")
        local partyMemberView = PartyMemberView.new(self.party, self.player.player, self.actionQueue, truster and truster.trusts or L{})
        partyMemberView:setBackgroundImageView(backgroundImageView)
        partyMemberView:setNavigationBar(createTitleView())
        partyMemberView:setSize(viewSize.width, viewSize.height)
        return partyMemberView
    end)

    -- Status
    local statusMenuItem = MenuItem.new(L{
        ButtonItem.default('Party', 18),
        ButtonItem.default('Buffs', 18),
        ButtonItem.default('Debuffs', 18),
        ButtonItem.default('Modes', 18),
    }, {
        Party = partyMenuItem,
        Buffs = buffsMenuItem,
        Debuffs = debuffsMenuItem,
        Modes = modesMenuItem,
    })

    -- Help
    local helpMenuItem = MenuItem.new(L{
        ButtonItem.default('Debug', 18),
    }, {
        Debug = debugMenuItem,
    },
    function()
        local helpView = setupView(HelpView.new(jobNameShort))
        helpView:setShouldRequestFocus(false)
        return helpView
    end)

    -- Main
    local mainMenuItem = MenuItem.new(L{
        ButtonItem.default('Status', 18),
        ButtonItem.default('Settings', 18),
        ButtonItem.default('Help', 18),
    }, {
        Status = statusMenuItem,
        Settings = settingsMenuItem,
        Help = helpMenuItem
    })

    return mainMenuItem
end

return TrustHud

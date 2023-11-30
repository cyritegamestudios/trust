local BackgroundView = require('cylibs/ui/views/background/background_view')
local BuffSettingsEditor = require('ui/settings/BuffSettingsEditor')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local Frame = require('cylibs/ui/views/frame')
local ListView = require('cylibs/ui/list_view/list_view')
local NavigationBar = require('cylibs/ui/navigation/navigation_bar')
local Padding = require('cylibs/ui/style/padding')
local PickerItem = require('cylibs/ui/picker/picker_item')
local PickerView = require('cylibs/ui/picker/picker_view')
local TabbedView = require('cylibs/ui/tabs/tabbed_view')
local TextStyle = require('cylibs/ui/style/text_style')
local TrustSettingsLoader = require('TrustSettings')
local View = require('cylibs/ui/views/view')

local TrustSettingsEditor = setmetatable({}, {__index = TabbedView })
TrustSettingsEditor.__index = TrustSettingsEditor


function TrustSettingsEditor.new(frame, trustSettings, settingsMode)
    local backgroundView = BackgroundView.new(Frame.new(0, 0, frame.width, frame.height),
            windower.addon_path..'assets/backgrounds/menu_bg_top.png',
            windower.addon_path..'assets/backgrounds/menu_bg_mid.png',
            windower.addon_path..'assets/backgrounds/menu_bg_bottom.png')

    local self = setmetatable(TabbedView.new(frame), TrustSettingsEditor)

    self.trustSettings = trustSettings

    self.navigationBar = NavigationBar.new(Frame.new(0, -38, frame.width, 35), "Settings Editor")
    self:addSubview(self.navigationBar)

    self.actionMenu = PickerView.withItems(L{}, L{}, false, 100, 80)
    self:addSubview(self.actionMenu)

    self:addTab(BuffSettingsEditor.new(trustSettings, settingsMode, self.actionMenu, frame.width), string.upper("self buffs"))
    self:addTab(View.new(Frame.zero()), string.upper("party buffs"))
    self:addTab(View.new(Frame.zero()), string.upper("cures"))
    self:addTab(View.new(Frame.zero()), string.upper("job abilities"))
    self:addTab(View.new(Frame.zero()), string.upper("debuffs"))
    self:addTab(View.new(Frame.zero()), string.upper("skillchains"))

    for _, view in pairs(self.views) do
        view:setNavigationBar(self.navigationBar)
    end

    self:setBackgroundImageView(backgroundView)

    self.navigationBar:setNeedsLayout()
    self.navigationBar:layoutIfNeeded()

    backgroundView:setNeedsLayout()
    backgroundView:layoutIfNeeded()

    self:selectTab(1)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():addAny(L{ self.navigationBar })

    return self
end

function TrustSettingsEditor:destroy()
    TabbedView.destroy(self)
end

function TrustSettingsEditor:layoutIfNeeded()
    TabbedView.layoutIfNeeded(self)

    self.actionMenu:setPosition(self:getSize().width + 5, 0)
end

function TrustSettingsEditor:selectTab(index)
    -- this doesn't appear to actually remove items because data source removeAllItems doesn't work, it just leaves it as is
    self.actionMenu:getDataSource():removeAllItems()

    self.actionMenu:setNeedsLayout()
    self.actionMenu:layoutIfNeeded()

    TabbedView.selectTab(self, index)
end


return TrustSettingsEditor
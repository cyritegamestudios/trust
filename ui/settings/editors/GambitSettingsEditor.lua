local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local GambitTarget = require('cylibs/gambits/gambit_target')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local skillchain_util = require('cylibs/util/skillchain_util')

local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local GambitSettingsEditor = setmetatable({}, {__index = ConfigEditor })
GambitSettingsEditor.__index = GambitSettingsEditor


function GambitSettingsEditor.new(gambit, trustSettings, trustSettingsMode)
    local configItems = L{
        PickerConfigItem.new('target', gambit.target or GambitTarget.TargetType.Self, L(GambitTarget.TargetType:keyset()), nil, "Action target"),
        PickerConfigItem.new('conditions_target', gambit.conditions_target or GambitTarget.TargetType.Self, L(GambitTarget.TargetType:keyset()), nil, "Conditions target"),
    }

    local self = setmetatable(ConfigEditor.new(trustSettings, gambit, configItems), GambitSettingsEditor)

    self.gambit = gambit
    self.menuArgs = {}

    local abilitySectionHeaderItem = SectionHeaderItem.new(
            TextItem.new("Ability", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
    )
    self:getDataSource():setItemForSectionHeader(3, abilitySectionHeaderItem)

    local conditionsSectionHeaderItem = SectionHeaderItem.new(
            TextItem.new("Conditions", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
    )
    self:getDataSource():setItemForSectionHeader(4, conditionsSectionHeaderItem)

    self:reloadSettings()

    return self
end

function GambitSettingsEditor:reloadSettings()
    ConfigEditor.reloadSettings(self)

    self:getDataSource():removeItemsInSection(3)
    self:getDataSource():removeItemsInSection(4)

    local itemsToAdd = L{}

    local abilityItem = IndexedItem.new(TextItem.new(self.gambit:getAbility():get_name(), TextStyle.Default.TextSmall), IndexPath.new(3, 1))
    itemsToAdd:append(abilityItem)

    local conditionsItems = IndexedItem.fromItems(self.gambit:getConditions():map(function(condition)
        return TextItem.new(condition:tostring(), TextStyle.Default.TextSmall)
    end), 4)

    itemsToAdd = itemsToAdd:extend(conditionsItems)

    self:getDataSource():addItems(itemsToAdd)

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
end

function GambitSettingsEditor:setVisible(visible)
    ConfigEditor.setVisible(self, visible)

    self:reloadSettings()
end

function GambitSettingsEditor:getMenuArgs()
    return self.menuArgs
end

return GambitSettingsEditor
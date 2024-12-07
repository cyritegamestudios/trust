local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local SkillchainStepSettingsEditor = setmetatable({}, {__index = ConfigEditor })
SkillchainStepSettingsEditor.__index = SkillchainStepSettingsEditor
SkillchainStepSettingsEditor.__type = "SkillchainStepSettingsEditor"

function SkillchainStepSettingsEditor.new(stepSettings, nextSteps)
    local configItems = L{
        PickerConfigItem.new('step', stepSettings.step, nextSteps, function(step)
            local suffix = ''
            if step:get_skillchain() then
                suffix = ' ('..step:get_skillchain()..')'
            end
            return step:get_ability():get_localized_name()..suffix
        end, 'Ability')
    }

    local self = setmetatable(ConfigEditor.new(nil, stepSettings, configItems, nil, nil, nil), SkillchainStepSettingsEditor)

    self.stepSettings = stepSettings
    self.conditions = stepSettings.conditions
    self.menuArgs = {}
    self.menuArgs.conditions = self.conditions

    local conditionsSectionHeaderItem = SectionHeaderItem.new(
            TextItem.new("Conditions", TextStyle.Default.SectionHeader),
            ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
            16
    )
    self:getDataSource():setItemForSectionHeader(2, conditionsSectionHeaderItem)

    return self
end

function SkillchainStepSettingsEditor:reloadSettings()
    ConfigEditor.reloadSettings(self)

    local conditionsItems = IndexedItem.fromItems(self.conditions:map(function(condition)
        return TextItem.new(condition:tostring(), TextStyle.Default.TextSmall)
    end), 2)

    self:getDataSource():addItems(conditionsItems)

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))

    self:setNeedsLayout()
    self:layoutIfNeeded()
end

function SkillchainStepSettingsEditor:setVisible(visible)
    ConfigEditor.setVisible(self, visible)

    self:reloadSettings()
end

function SkillchainStepSettingsEditor:getMenuArgs()
    return self.menuArgs
end

function SkillchainStepSettingsEditor:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Conditions' then
        self.menuArgs['conditions'] = self.conditions
    end

    ConfigEditor.onSelectMenuItemAtIndexPath(self, textItem, indexPath)
end

return SkillchainStepSettingsEditor
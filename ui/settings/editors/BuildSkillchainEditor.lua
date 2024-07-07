local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local skillchain_util = require('cylibs/util/skillchain_util')

local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local BuildSkillchainEditor = setmetatable({}, {__index = ConfigEditor })
BuildSkillchainEditor.__index = BuildSkillchainEditor


function BuildSkillchainEditor.new(builderSettings, skillchainer, selectedCombatSkillIds)
    local configItems = L{
        ConfigItem.new('NumSteps', 2, 6, 1, function(value) return value.."" end),
        PickerConfigItem.new('Property', 'Light Lv.4', skillchain_util.all_skillchain_properties()),
    }

    local self = setmetatable(ConfigEditor.new(nil, builderSettings, configItems), BuildSkillchainEditor)

    self.builderSettings = builderSettings
    self.skillchainer = skillchainer
    self.selectedCombatSkillIds = selectedCombatSkillIds

    self:setScrollDelta(16)
    self:setShouldRequestFocus(true)

    local sectionHeaderItem = SectionHeaderItem.new(
        TextItem.new("Skills", TextStyle.Default.SectionHeader),
        ImageItem.new(windower.addon_path..'assets/icons/icon_bullet.png', 8, 8),
        16
    )
    self:getDataSource():setItemForSectionHeader(3, sectionHeaderItem)

    self:reloadSettings()

    self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        if indexPath.section == 3 then
            local item = self:getDataSource():itemAtIndexPath(indexPath)
            if item then
                local combatSkill = res.skills:with('en', item:getText())
                if combatSkill then
                    builderSettings.CombatSkills:add(combatSkill.id)
                end
            end
        end
    end)

    self:getDelegate():didDeselectItemAtIndexPath():addAction(function(indexPath)
        if indexPath.section == 3 then
            local item = self:getDataSource():itemAtIndexPath(indexPath)
            if item then
                local combatSkill = res.skills:with('en', item:getText())
                if combatSkill then
                    builderSettings.CombatSkills:remove(combatSkill.id)
                end
            end
        end
    end)

    return self
end

function BuildSkillchainEditor:reloadSettings()
    ConfigEditor.reloadSettings(self)

    if self.skillchainer == nil then
        return
    end

    local combatSkillIds = L{1,2,3,4,5,6,7,8,9,10,11,12,25,26}
    local combatSkillItems = IndexedItem.fromItems(combatSkillIds:map(function(combatSkillId)
        return TextItem.new(res.skills[combatSkillId].en, TextStyle.Default.TextSmall)
    end), 3)

    self:getDataSource():addItems(combatSkillItems)

    local activeCombatSkillIds = self.skillchainer:get_party():get_player():get_combat_skill_ids()
    for activeCombatSkillId in activeCombatSkillIds:it() do
        self.builderSettings.CombatSkills:add(activeCombatSkillId)
    end

    local selectedIndexPaths = L{}
    for combatSkillItem in combatSkillItems:it() do
        local combatSkillId = res.skills:with('en', combatSkillItem:getItem():getText()).id
        if activeCombatSkillIds:contains(combatSkillId) or self.builderSettings.CombatSkills:contains(combatSkillId) then
            selectedIndexPaths:append(combatSkillItem:getIndexPath())
        end
    end

    for selectedIndexPath in selectedIndexPaths:it() do
        self:getDelegate():selectItemAtIndexPath(selectedIndexPath)
    end

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
end

function BuildSkillchainEditor:setVisible(visible)
    ConfigEditor.setVisible(self, visible)

    self:reloadSettings()
end

return BuildSkillchainEditor
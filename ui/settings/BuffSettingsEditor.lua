local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local ImageTextItem = require('cylibs/ui/collection_view/items/image_text_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local FFXIWindow = require('ui/themes/ffxi/FFXIWindow')
local BuffSettingsEditor = setmetatable({}, {__index = FFXIWindow })
BuffSettingsEditor.__index = BuffSettingsEditor


function BuffSettingsEditor.new(trustSettings, buffs, targets)
    local imageItemForBuff = function(abilityName)
        if res.spells:with('en', abilityName) then
            return AssetManager.imageItemForSpell(abilityName)
        elseif res.job_abilities:with('en', abilityName) then
            return AssetManager.imageItemForJobAbility(abilityName)
        else
            return nil
        end
    end

    local self = setmetatable(FFXIPickerView.withItems(buffs:map(function(b) return b:get_name() end), L{}, false, nil, imageItemForBuff), BuffSettingsEditor)

    self:setAllowsCursorSelection(true)
    self:setScrollDelta(16)
    self:setScrollEnabled(true)

    self.trustSettings = trustSettings
    self.buffs = buffs or L{}
    self.targets = targets
    self.menuArgs = {}

    self:reloadSettings()

    return self
end

function BuffSettingsEditor:destroy()
    CollectionView.destroy(self)
end

function BuffSettingsEditor:setVisible(visible)
    CollectionView.setVisible(self, visible)
    if visible then
        self:reloadSettings()
    end
end

function BuffSettingsEditor:reloadSettings()
    self:getDataSource():removeAllItems()

    local imageItemForBuff = function(abilityName)
        if res.spells:with('en', abilityName) then
            return AssetManager.imageItemForSpell(abilityName)
        elseif res.job_abilities:with('en', abilityName) then
            return AssetManager.imageItemForJobAbility(abilityName)
        else
            return nil
        end
    end

    local items = L{}

    local rowIndex = 1
    
    for buff in self.buffs:it() do
        local imageItem = imageItemForBuff(buff:get_name())
        local textItem = TextItem.new(buff:get_name(), TextStyle.Default.PickerItem)
        textItem:setLocalizedText(buff:get_localized_name())
        textItem:setEnabled(self:checkJob(buff) and buff:isEnabled())
        items:append(IndexedItem.new(ImageTextItem.new(imageItem, textItem), IndexPath.new(1, rowIndex)))
        rowIndex = rowIndex + 1
    end

    self:getDataSource():addItems(items)

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    self:layoutIfNeeded()
end

function BuffSettingsEditor:reloadBuffAtIndexPath(indexPath)
    local item = self:getDataSource():itemAtIndexPath(indexPath)
    if item then
        local buff = self.buffs[indexPath.row]
        if buff then
            item:setEnabled(self:checkJob(buff) and buff:isEnabled())
            self:getDataSource():updateItem(item, indexPath)
        end
    end
end

function BuffSettingsEditor:checkJob(buff)
    if not buff:is_valid() then
        return false
    end
    local job_conditions = buff:get_conditions():filter(function(condition)
        return condition.__class == MainJobCondition.__class
    end) or L{}
    return job_conditions:empty() or Condition.check_conditions(job_conditions, windower.ffxi.get_player().index)
end

function BuffSettingsEditor:getMenuArgs()
    return self.menuArgs
end

return BuffSettingsEditor
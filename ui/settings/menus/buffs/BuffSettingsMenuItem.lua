local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local BuffSettingsEditor = require('ui/settings/BuffSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local JobAbilityPickerItemMapper = require('ui/settings/pickers/mappers/JobAbilityPickerItemMapper')
local SpellPickerItemMapper = require('ui/settings/pickers/mappers/SpellPickerItemMapper')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')

local BuffSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuffSettingsMenuItem.__index = BuffSettingsMenuItem

function BuffSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, settingsPrefix, settingsKey, targets, jobNameShort, descriptionText, showJobs)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
        ButtonItem.default('Toggle', 18),
        ButtonItem.default('Reset', 18),
    }, {}, nil, "Buffs", descriptionText), BuffSettingsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.settingsKey = settingsKey
    self.targets = targets
    self.jobNameShort = jobNameShort
    self.showJobs = showJobs
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local buffs
        if settingsPrefix then
            buffs = T(trustSettings:getSettings())[trustSettingsMode.value][settingsPrefix][settingsKey]
        else
            buffs = T(trustSettings:getSettings())[trustSettingsMode.value][settingsKey]
        end
        self.buffs = buffs

        local buffSettingsEditor = BuffSettingsEditor.new(trustSettings, buffs, targets)

        self.dispose_bag:add(buffSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local item = buffSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            if item and not item:getTextItem():getEnabled() then
                infoView:setDescription("Unavailable on current job or settings.")
            else
                local buff = buffs[indexPath.row]
                if buff then
                    local description = buff:get_conditions():map(function(condition)
                        return condition:tostring()
                    end)
                    infoView:setDescription("Use when: "..localization_util.commas(description))
                end
            end
        end, buffSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath()))

        self.buffSettingsEditor = buffSettingsEditor

        return buffSettingsEditor
    end

    self:reloadSettings()

    self.dispose_bag:add(trustSettings:onSettingsChanged():addAction(function(_)
        if self.buffSettingsEditor then
            self.buffSettingsEditor:setShouldRequestFocus(self.buffs:length() > 0)
        end
    end), trustSettings:onSettingsChanged())

    return self
end

function BuffSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function BuffSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddBuffMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveBuffMenuItem())
    self:setChildMenuItem("Edit", self:getEditBuffMenuItem())
    self:setChildMenuItem("Toggle", self:getToggleBuffMenuItem())
    self:setChildMenuItem("Conditions", self:getConditionsMenuItem())
    self:setChildMenuItem("Reset", self:getResetMenuItem())
end

function BuffSettingsMenuItem:getAllBuffs()
    local sections = L{
        L(self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            if spell then
                local status = buff_util.buff_for_spell(spell.id)
                return status ~= nil and not buff_util.is_debuff(status.id) and spell.skill ~= 44 and self.targets:intersection(S(spell.targets)):length() > 0
            end
            return false
        end):map(function(spellId)
            return res.spells[spellId].en
        end)):sort(),
        L(self.trust:get_job():get_job_abilities(function(jobAbilityId)
            local jobAbility = res.job_abilities[jobAbilityId]
            if jobAbility then
                return buff_util.buff_for_job_ability(jobAbility.id) ~= nil and self.targets:intersection(S(jobAbility.targets)):length() > 0
            end
            return false
        end):map(function(jobAbilityId)
            return res.job_abilities[jobAbilityId].en
        end)):sort()
    }
    return sections
end

function BuffSettingsMenuItem:getAddBuffMenuItem()
    local addBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function(_, _)
        local imageItemForAbility = function(abilityName, sectionIndex)
            if sectionIndex == 1 then
                return AssetManager.imageItemForSpell(abilityName)
            elseif sectionIndex == 2 then
                return AssetManager.imageItemForJobAbility(abilityName)
            else
                return nil
            end
        end

        local chooseBuffView = FFXIPickerView.withSections(self:getAllBuffs(), L{}, true, nil, imageItemForAbility)
        chooseBuffView:on_pick_items():addAction(function(pickerView, selectedItems)
            pickerView:getDelegate():deselectAllItems()

            local defaultJobNames = L{}
            if self.targets:contains('Party') then
                defaultJobNames = job_util.all_jobs()
            end

            local itemMappers = L{
                SpellPickerItemMapper.new(defaultJobNames),
                JobAbilityPickerItemMapper.new(),
            }

            local buffs = selectedItems:map(function(pickerItem)
                for mapper in itemMappers:it() do
                    if mapper:canMap(pickerItem) then
                        return mapper:map(pickerItem)
                    end
                end
                return nil
            end):compact_map()

            for buff in buffs:it() do
                self.buffs:append(buff)
            end

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my buffs!")
        end)

        return chooseBuffView
    end, "Buffs", "Add a new buff.")
    return addBuffMenuItem
end

function BuffSettingsMenuItem:getRemoveBuffMenuItem()
    return MenuItem.action(function()
        local cursorIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local item = self.buffSettingsEditor:getDataSource():itemAtIndexPath(cursorIndexPath)
            if item then
                self.buffs:remove(cursorIndexPath.row)
                self.buffSettingsEditor:getDataSource():removeItem(cursorIndexPath)

                self.trustSettings:saveSettings(true)
            end
        end
    end, "Buffs", "Remove the selected buff.")
end

function BuffSettingsMenuItem:getEditBuffMenuItem()
    local editBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
    function(_)
        local cursorIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local buff = self.buffs[cursorIndexPath.row]
            if buff then
                local editSpellView = SpellSettingsEditor.new(self.trustSettings, buff, not self.showJobs)
                editSpellView:setTitle("Edit buff.")
                editSpellView:setShouldRequestFocus(true)
                return editSpellView
            end
        end
        return nil
    end, "Buffs", "Edit buff settings.", false, function()
                return self.buffs and self.buffs:length() > 0
            end)
    return editBuffMenuItem
end

function BuffSettingsMenuItem:getToggleBuffMenuItem()
    return MenuItem.action(function(menu)
        local selectedIndexPath = self.buffSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.buffSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                local buff = self.buffs[selectedIndexPath.row]
                buff:setEnabled(not buff:isEnabled())

                self.buffSettingsEditor:reloadBuffAtIndexPath(selectedIndexPath)
            end
        end
    end, "Gambits", "Temporarily enable or disable the selected spell until the addon reloads.")
end

function BuffSettingsMenuItem:getConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, nil, nil, function()
        return self.buffs and self.buffs:length() > 0
    end)
end

function BuffSettingsMenuItem:getResetMenuItem()
    return MenuItem.action(function(menu)
        local defaultSettings = T(self.trustSettings:getDefaultSettings()):clone().Default

        local currentSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value]
        if self.settingsPrefix then
            currentSettings[self.settingsPrefix][self.settingsKey] = defaultSettings[self.settingsPrefix][self.settingsKey]
        else
            currentSettings[self.settingsKey] = defaultSettings[self.settingsKey]
        end
        self.trustSettings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've forgotten any custom settings!")

        menu:showMenu(self)
    end, "Reset", "Reset to default settings. WARNING: your settings will be overriden.")
end

return BuffSettingsMenuItem
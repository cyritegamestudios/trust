local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local job_util = require('cylibs/util/job_util')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local GambitSettingsMenuItem = setmetatable({}, {__index = MenuItem })
GambitSettingsMenuItem.__index = GambitSettingsMenuItem

function GambitSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Move Up', 18),
        ButtonItem.default('Move Down', 18),
        ButtonItem.default('Copy', 18),
        ButtonItem.default('Toggle', 18),
        ButtonItem.default('Reset', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Gambits", "Add custom behaviors.", false), GambitSettingsMenuItem)  -- changed keep views to false

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits

        local gambitSettingsEditor = FFXIPickerView.withItems(currentGambits:map(function(gambit)
            return gambit:tostring()
        end), L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge, true)
        gambitSettingsEditor:setAllowsCursorSelection(true)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        local itemsToUpdate = L{}
        for rowIndex = 1, gambitSettingsEditor:getDataSource():numberOfItemsInSection(1) do
            local indexPath = IndexPath.new(1, rowIndex)
            local item = gambitSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            item:setEnabled(currentGambits[rowIndex]:isEnabled())
            itemsToUpdate:append(IndexedItem.new(item, indexPath))
        end

        gambitSettingsEditor:getDataSource():updateItems(itemsToUpdate)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        self.disposeBag:add(gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            self.selectedGambit = selectedGambit

            gambitSettingsEditor.menuArgs['conditions'] = selectedGambit.conditions
            gambitSettingsEditor.menuArgs['targetTypes'] = S{ selectedGambit:getConditionsTarget() }
        end, gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath()))

        self.disposeBag:add(gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            if selectedGambit then
                infoView:setDescription(selectedGambit:tostring())
            end
        end), gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        if currentGambits:length() > 0 then
            gambitSettingsEditor:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
        end

        self.gambitSettingsEditor = gambitSettingsEditor

        return gambitSettingsEditor
    end

    self:reloadSettings()

    return self
end

function GambitSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function GambitSettingsMenuItem:getConfigKey()
    return "gambits"
end

function GambitSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    self:setChildMenuItem("Edit", self:getEditGambitMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveAbilityMenuItem())
    self:setChildMenuItem("Copy", self:getCopyGambitMenuItem())
    self:setChildMenuItem("Move Up", self:getMoveUpGambitMenuItem())
    self:setChildMenuItem("Move Down", self:getMoveDownGambitMenuItem())
    self:setChildMenuItem("Toggle", self:getToggleMenuItem())
    self:setChildMenuItem("Reset", self:getResetGambitsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function GambitSettingsMenuItem:getAbilities(gambitTarget, flatten)
    local gambitTargetMap = T{
        [GambitTarget.TargetType.Self] = S{'Self'},
        [GambitTarget.TargetType.Ally] = S{'Party', 'Corpse'},
        [GambitTarget.TargetType.Enemy] = S{'Enemy'}
    }
    local targets = gambitTargetMap[gambitTarget]
    local sections = L{
        spell_util.get_spells(function(spell)
            local spellTargets = L(spell.targets)
            if spell.type == 'Geomancy' and spellTargets:length() == 1 and spellTargets[1] == 'Self' then
                spellTargets:append('Party')
            end
            return spell.type ~= 'Trust' and S(spellTargets):intersection(targets):length() > 0
        end):map(function(spell)
            return spell.en
        end):sort(),
        player_util.get_job_abilities():filter(function(jobAbilityId)
            local jobAbility = res.job_abilities[jobAbilityId]
            return S(jobAbility.targets):intersection(targets):length() > 0
        end):map(function(jobAbilityId)
            return res.job_abilities[jobAbilityId].en
        end):sort(),
        L(windower.ffxi.get_abilities().weapon_skills):filter(function(weaponSkillId)
            local weaponSkill = res.weapon_skills[weaponSkillId]
            return S(weaponSkill.targets):intersection(targets):length() > 0
        end):map(function(weaponSkillId)
            return res.weapon_skills[weaponSkillId].en
        end):sort(),
        L{ 'Approach', 'Ranged Attack', 'Turn Around', 'Turn to Face', 'Run Away', 'Run To' }:filter(function(_)
            return targets:contains('Enemy')
        end),
        L{ 'Use Item', 'Command' }:filter(function(_)
            return targets:contains('Self')
        end),
    }
    if flatten then
        sections = sections:flatten()
    end
    return sections
end

function GambitSettingsMenuItem:getAbilitiesByTargetType()
    local abilitiesByTargetType = T{}

    abilitiesByTargetType[GambitTarget.TargetType.Self] = self:getAbilities(GambitTarget.TargetType.Self, true):map(function(abilityName) return job_util.getAbility(abilityName)  end):compact_map()
    abilitiesByTargetType[GambitTarget.TargetType.Ally] = self:getAbilities(GambitTarget.TargetType.Ally, true):map(function(abilityName) return job_util.getAbility(abilityName)  end):compact_map()
    abilitiesByTargetType[GambitTarget.TargetType.Enemy] = self:getAbilities(GambitTarget.TargetType.Enemy, true):map(function(abilityName) return job_util.getAbility(abilityName)  end):compact_map()

    return abilitiesByTargetType
end

function GambitSettingsMenuItem:getAddAbilityMenuItem()
    return MenuItem.action(function(menu)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()

        local newGambit = Gambit.new(GambitTarget.TargetType.Self, L{}, abilitiesByTargetType[GambitTarget.TargetType.Self][1], GambitTarget.TargetType.Self)

        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits
        currentGambits:append(newGambit)

        self.trustSettings:saveSettings(true)

        menu:showMenu(self)

        self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, currentGambits:length()))

    end, "Gambits", "Add a new Gambit.")
end

function GambitSettingsMenuItem:getEditGambitMenuItem()
    local editGambitMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
    }, {
    }, function(menuArgs, infoView)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()
        local gambitEditor = GambitSettingsEditor.new(self.selectedGambit, self.trustSettings, self.trustSettingsMode, abilitiesByTargetType)
        return gambitEditor
    end, "Gambits", "Edit the selected Gambit.", false, function()
        return self.selectedGambit ~= nil
    end)

    local editAbilityMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
    }, {
        Confirm = MenuItem.action(function(parent)
            parent:showMenu(editGambitMenuItem)
        end, "Gambits", "Edit ability.")
    }, function(_, _)
        if self.selectedGambit then
            local configItems = L{}
            if self.selectedGambit:getAbility().get_config_items then
                configItems = self.selectedGambit:getAbility():get_config_items() or L{}
            end
            if not configItems:empty() then
                local editAbilityEditor = ConfigEditor.new(nil, self.selectedGambit:getAbility(), configItems)
                return editAbilityEditor
            end
            return nil
        end
    end, "Gambits", "Edit ability.", false, function()
        return self.selectedGambit:getAbility().get_config_items and self.selectedGambit:getAbility():get_config_items():length() > 0
    end)

    editGambitMenuItem:setChildMenuItem("Edit", editAbilityMenuItem)
    editGambitMenuItem:setChildMenuItem("Conditions", ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode))

    return editGambitMenuItem
end

function GambitSettingsMenuItem:getRemoveAbilityMenuItem()
    return MenuItem.action(function()
        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                local indexPath = selectedIndexPath
                local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits
                currentGambits:remove(indexPath.row)

                self.gambitSettingsEditor:getDataSource():removeItem(indexPath)
                --self.gambitSettingsEditor:removeItem(item:getText(), indexPath.section)

                self.selectedGambit = nil
                self.trustSettings:saveSettings(true)

                if self.gambitSettingsEditor:getDataSource():numberOfItemsInSection(1) > 0 then
                    self.selectedGambit = currentGambits[1]
                    self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
                end
            end
        end
    end, "Gambits", "Remove the selected Gambit.")
end

function GambitSettingsMenuItem:getCopyGambitMenuItem()
    return MenuItem.action(function(menu)
        if self.selectedGambit then
            local newGambit = self.selectedGambit:copy()

            local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits
            currentGambits:append(newGambit)

            self.trustSettings:saveSettings(true)

            menu:showMenu(self)
        end
    end, "Gambits", "Copy the selected Gambit.")
end

function GambitSettingsMenuItem:getToggleMenuItem()
    return MenuItem.action(function(menu)
        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                item:setEnabled(not item:getEnabled())
                self.gambitSettingsEditor:getDataSource():updateItem(item, selectedIndexPath)

                local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits
                currentGambits[selectedIndexPath.row]:setEnabled(not currentGambits[selectedIndexPath.row]:isEnabled())
            end
        end
    end, "Gambits", "Temporarily enable or disable the selected Gambit until the addon reloads.")
end

function GambitSettingsMenuItem:getMoveUpGambitMenuItem()
    return MenuItem.action(function(menu)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits

        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath and selectedIndexPath.row > 1 then

            local newIndexPath = self.gambitSettingsEditor:getDataSource():getPreviousIndexPath(selectedIndexPath)
            local item1 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            local item2 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self.gambitSettingsEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)

                local temp = currentGambits[selectedIndexPath.row - 1]
                currentGambits[selectedIndexPath.row - 1] = currentGambits[selectedIndexPath.row]
                currentGambits[selectedIndexPath.row] = temp

                self.trustSettings:saveSettings(true)

                --menu:showMenu(self)

                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(selectedIndexPath.section, selectedIndexPath.row - 1))
            end
        end
    end, "Gambits", "Move the selected Gambit up. Gambits get evaluated in order.")
end

function GambitSettingsMenuItem:getMoveDownGambitMenuItem()
    return MenuItem.action(function(menu)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits

        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath and selectedIndexPath.row < currentGambits:length() then

            local newIndexPath = self.gambitSettingsEditor:getDataSource():getNextIndexPath(selectedIndexPath)-- IndexPath.new(indexPath.section, indexPath.row + 1)
            local item1 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            local item2 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self.gambitSettingsEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)

                local temp = currentGambits[selectedIndexPath.row + 1]
                currentGambits[selectedIndexPath.row + 1] = currentGambits[selectedIndexPath.row]
                currentGambits[selectedIndexPath.row] = temp

                self.trustSettings:saveSettings(true)

                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(selectedIndexPath.section, selectedIndexPath.row + 1))
            end
        end
    end, "Gambits", "Move the selected Gambit down. Gambits get evaluated in order.")
end

function GambitSettingsMenuItem:getEditConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self)
end

function GambitSettingsMenuItem:getResetGambitsMenuItem()
    return MenuItem.action(function(menu)
        local defaultGambitSettings = self.trustSettings:getDefaultSettings().Default.GambitSettings
        if defaultGambitSettings and defaultGambitSettings.Gambits then
            local currentGambitSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings
            currentGambitSettings.Gambits:clear()
            for gambit in defaultGambitSettings.Gambits:it() do
                currentGambitSettings.Gambits:append(gambit:copy())
            end

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've reset my Gambits to their factory settings!")

            menu:showMenu(self)
        end
    end, "Gambits", "Reset to default Gambits.")
end

function GambitSettingsMenuItem:getModesMenuItem()
    local gambitModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoGambitMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Change Gambit behavior.")
    return gambitModesMenuItem
end

return GambitSettingsMenuItem
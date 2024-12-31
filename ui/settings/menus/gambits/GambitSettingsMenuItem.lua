local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitLibraryMenuItem = require('ui/settings/menus/gambits/GambitLibraryMenuItem')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local GambitSettingsMenuItem = setmetatable({}, {__index = MenuItem })
GambitSettingsMenuItem.__index = GambitSettingsMenuItem


function GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, settingsKey, abilityTargets, abilitiesForTargets, conditionTargets)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Move Up', 18),
        ButtonItem.default('Move Down', 18),
        ButtonItem.default('Copy', 18),
        ButtonItem.default('Toggle', 18),
        ButtonItem.default('Reset', 18),
        ButtonItem.localized('Modes', i18n.translate('Button_Modes')),
    }, {}, nil, "Gambits", "Add custom behaviors.", false), GambitSettingsMenuItem)  -- changed keep views to false

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.settingsKey = settingsKey
    self.abilityTargets = abilityTargets or S(GambitTarget.TargetType:keyset())
    self.abilityTargets = S{ GambitTarget.TargetType.Enemy }
    self.abilitiesForTargets = abilitiesForTargets or function(targets)
        return self:getAbilitiesForTargets(targets)
    end
    self.conditionTargets = conditionTargets or L(Condition.TargetType.AllTargets)
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][settingsKey].Gambits

        local configItem = MultiPickerConfigItem.new("Gambits", L{}, currentGambits, function(gambit)
            return gambit:tostring()
        end)

        local gambitSettingsEditor = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge)
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

function GambitSettingsMenuItem:getAbilitiesForTargets(targets)
    local sections = L{
        self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            if spell then
                local spellTargets = L(spell.targets)
                if spell.type == 'Geomancy' and spellTargets:length() == 1 and spellTargets[1] == 'Self' then
                    spellTargets:append('Party')
                end
                return not S{ 'Trust', 'BardSong' }:contains(spell.type) and S(spellTargets):intersection(targets):length() > 0
            end
            return false
        end):map(function(spellId)
            return Spell.new(res.spells[spellId].en)
        end),
        L(player_util.get_job_abilities()):filter(function(jobAbilityId)
            local jobAbility = res.job_abilities[jobAbilityId]
            return S(jobAbility.targets):intersection(targets):length() > 0
        end):map(function(jobAbilityId)
            return JobAbility.new(res.job_abilities[jobAbilityId].en)
        end),
        L(windower.ffxi.get_abilities().weapon_skills):filter(function(weaponSkillId)
            local weaponSkill = res.weapon_skills[weaponSkillId]
            return S(weaponSkill.targets):intersection(targets):length() > 0
        end):map(function(weaponSkillId)
            return WeaponSkill.new(res.weapon_skills[weaponSkillId].en)
        end),
        L{ Approach.new(), RangedAttack.new(), TurnAround.new(), TurnToFace.new(), RunAway.new(), RunTo.new(), Engage.new() }:filter(function(_)
            return targets:contains('Enemy')
        end),
        L{ UseItem.new(), Command.new() }:filter(function(_)
            return targets:contains('Self')
        end),
    }
    return sections
end

function GambitSettingsMenuItem:getAbilities(gambitTarget, flatten)
    local gambitTargetMap = T{
        [GambitTarget.TargetType.Self] = S{'Self'},
        [GambitTarget.TargetType.Ally] = S{'Party', 'Corpse'},
        [GambitTarget.TargetType.Enemy] = S{'Enemy'}
    }
    local targets = gambitTargetMap[gambitTarget]

    local sections = self.abilitiesForTargets(targets)
    if flatten then
        sections = sections:flatten(false)
    end
    return sections
end

function GambitSettingsMenuItem:getAbilitiesByTargetType()
    local abilitiesByTargetType = T{}
    for abilityTarget in L(GambitTarget.TargetType:keyset()):it() do
        if self.abilityTargets:contains(abilityTarget) then
            abilitiesByTargetType[abilityTarget] = self:getAbilities(abilityTarget, true):compact_map()
        else
            abilitiesByTargetType[abilityTarget] = L{}
        end
    end
    return abilitiesByTargetType
end

function GambitSettingsMenuItem:getAddAbilityMenuItem()
    local blankGambitMenuItem = MenuItem.action(function(menu)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()
        local defaultTarget = L(self.abilityTargets)[1]

        local newGambit = Gambit.new(defaultTarget, L{}, abilitiesByTargetType[defaultTarget][1], defaultTarget)

        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey].Gambits
        currentGambits:append(newGambit)

        self.trustSettings:saveSettings(true)

        menu:showMenu(self)

        self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, currentGambits:length()))

    end, "Gambits", "Add a new Gambit.")

    local addGambitMenuItem = MenuItem.new(L{
        ButtonItem.default('New', 18),
        ButtonItem.default('Browse', 18),
    }, {
        New = blankGambitMenuItem,
        Browse = self:getGambitLibraryMenuItem()
    }, nil, "Gambits", "Add a new gambit.")

    return addGambitMenuItem
end

function GambitSettingsMenuItem:getEditGambitMenuItem()
    local editGambitMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
    }, {
    }, function(menuArgs, infoView)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()
        local gambitEditor = GambitSettingsEditor.new(self.selectedGambit, self.trustSettings, self.trustSettingsMode, abilitiesByTargetType, self.conditionTargets)
        return gambitEditor
    end, "Gambits", "Edit the selected gambit.", false, function()
        return self.selectedGambit ~= nil
    end)

    local editAbilityMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
    }, {
        Confirm = MenuItem.action(function(parent)
            parent:showMenu(editGambitMenuItem)
        end, "Gambits", "Edit ability.")
    }, function(_, infoView, showMenu)
        if self.selectedGambit then
            local configItems = L{}
            if self.selectedGambit:getAbility().get_config_items then
                configItems = self.selectedGambit:getAbility():get_config_items(self.trust) or L{}
            end
            if not configItems:empty() then
                local editAbilityEditor = ConfigEditor.new(nil, self.selectedGambit:getAbility(), configItems, infoView, nil, showMenu)

                self.disposeBag:add(editAbilityEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
                    if self.selectedGambit:getAbility().on_config_changed then
                        self.selectedGambit:getAbility():on_config_changed(oldSettings)
                    end
                end), editAbilityEditor:onConfigChanged())

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
                local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey].Gambits
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
    end, "Gambits", "Remove the selected gambit.")
end

function GambitSettingsMenuItem:getCopyGambitMenuItem()
    return MenuItem.action(function(menu)
        if self.selectedGambit then
            local newGambit = self.selectedGambit:copy()

            local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey].Gambits
            currentGambits:append(newGambit)

            self.trustSettings:saveSettings(true)

            menu:showMenu(self)
        end
    end, "Gambits", "Copy the selected gambit.")
end

function GambitSettingsMenuItem:getToggleMenuItem()
    return MenuItem.action(function(menu)
        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                item:setEnabled(not item:getEnabled())
                self.gambitSettingsEditor:getDataSource():updateItem(item, selectedIndexPath)

                local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey].Gambits
                currentGambits[selectedIndexPath.row]:setEnabled(not currentGambits[selectedIndexPath.row]:isEnabled())
            end
        end
    end, "Gambits", "Temporarily enable or disable the selected gambit until the addon reloads.")
end

function GambitSettingsMenuItem:getMoveUpGambitMenuItem()
    return MenuItem.action(function(menu)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey].Gambits

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
    end, "Gambits", "Move the selected gambit up. Gambits get evaluated in order.")
end

function GambitSettingsMenuItem:getMoveDownGambitMenuItem()
    return MenuItem.action(function(menu)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey].Gambits

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
    end, "Gambits", "Move the selected gambit down. Gambits get evaluated in order.")
end

function GambitSettingsMenuItem:getEditConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self)
end

function GambitSettingsMenuItem:getResetGambitsMenuItem()
    return MenuItem.action(function(menu)
        local defaultGambitSettings = self.trustSettings:getDefaultSettings().Default[self.settingsKey]
        if defaultGambitSettings and defaultGambitSettings.Gambits then
            local currentGambitSettings = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey]
            currentGambitSettings.Gambits:clear()
            for gambit in defaultGambitSettings.Gambits:it() do
                currentGambitSettings.Gambits:append(gambit:copy())
            end

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've reset my gambits to their factory settings!")

            menu:showMenu(self)
        end
    end, "Gambits", "Reset to default gambits.")
end

function GambitSettingsMenuItem:getGambitLibraryMenuItem()
    return GambitLibraryMenuItem.new(self.trustSettings, self.trustSettingsMode, self)
end

function GambitSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for gambits.",
            L{'AutoGambitMode'})
end

return GambitSettingsMenuItem
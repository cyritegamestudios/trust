local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')

local GambitSettingsMenuItem = setmetatable({}, {__index = MenuItem })
GambitSettingsMenuItem.__index = GambitSettingsMenuItem

function GambitSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Conditions', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Gambits", "Add custom behaviors.", true), GambitSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, _)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits

        local gambitSettingsEditor = FFXIPickerView.withItems(currentGambits:map(function(gambit)
            return gambit:tostring()
        end), L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge, true)
        gambitSettingsEditor:setAllowsCursorSelection(true)

        self.disposeBag:add(gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            gambitSettingsEditor.menuArgs['conditions'] = selectedGambit.conditions
        end, gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath()))

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

    self.dispose_bag:destroy()
end

function GambitSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveAbilityMenuItem())
    self:setChildMenuItem("Conditions", self:getEditConditionsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function GambitSettingsMenuItem:getAbilities(gambitTarget)
    local gambitTargetMap = T{
        [GambitTarget.TargetType.Self] = S{'Self'},
        [GambitTarget.TargetType.Ally] = S{'Party'},
        [GambitTarget.TargetType.Enemy] = S{'Enemy'}
    }
    local targets = gambitTargetMap[gambitTarget]
    local sections = L{
        spell_util.get_spells(function(spell)
            return spell.type ~= 'Trust' and S(spell.targets):intersection(targets):length() > 0
        end):map(function(spell)
            return spell.en
        end),
        player_util.get_job_abilities():filter(function(jobAbilityId)
            local jobAbility = res.job_abilities[jobAbilityId]
            return S(jobAbility.targets):intersection(targets):length() > 0
        end):map(function(jobAbilityId)
            return res.job_abilities[jobAbilityId].en
        end),
        L(windower.ffxi.get_abilities().weapon_skills):filter(function(weaponSkillId)
            local weaponSkill = res.weapon_skills[weaponSkillId]
            return S(weaponSkill.targets):intersection(targets):length() > 0
        end):map(function(weaponSkillId)
            return res.weapon_skills[weaponSkillId].en
        end),
        L{ 'Approach', 'Ranged Attack' }:filter(function(_)
            return targets:contains('Enemy')
        end)
    }
    return sections
end

function GambitSettingsMenuItem:getAbility(abilityName)
    if res.spells:with('en', abilityName) then
        return Spell.new(abilityName, L{}, L{})
    elseif res.job_abilities:with('en', abilityName) then
        return JobAbility.new(abilityName, L{}, L{})
    elseif res.weapon_skills:with('en', abilityName) then
        return WeaponSkill.new(abilityName, L{})
    elseif abilityName == 'Approach' then
        return Approach.new()
    elseif abilityName == 'Ranged Attack' then
        return RangedAttack.new()
    else
        return nil
    end
end

function GambitSettingsMenuItem:getAddAbilityMenuItem()
    local createAddAbilityMenuItem = function(target)
        local addAbilityMenuItem = MenuItem.new(L{
            ButtonItem.default('Confirm', 18),
            ButtonItem.default('Clear', 18),
        }, {
            Confirm = MenuItem.action(function(menu)
                menu:showMenu(self)
            end, "Confirm", "Create an empty Gambit")
        },
            function(_, _)
                local imageItemForAbility = function(abilityName, sectionIndex)
                    --[[if sectionIndex == 1 then
                        return AssetManager.imageItemForSpell(abilityName)
                    elseif sectionIndex == 2 then
                        return AssetManager.imageItemForJobAbility(abilityName)
                    else
                        return nil
                    end]]
                    return nil
                end

                local chooseAbilitiesView = FFXIPickerView.withSections(self:getAbilities(target), L{}, false, nil, imageItemForAbility)
                chooseAbilitiesView:on_pick_items():addAction(function(pickerView, selectedItems)
                    pickerView:getDelegate():deselectAllItems()

                    local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits

                    selectedItems = selectedItems:map(function(item) return item:getText() end)
                    for selectedItem in selectedItems:it() do
                        local ability = self:getAbility(selectedItem)

                        local newGambit = Gambit.new(target, L{}, ability)
                        currentGambits:append(newGambit)

                        chooseAbilitiesView.menuArgs['conditions'] = newGambit.conditions
                    end

                    self.trustSettings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've added an empty Gambit for "..localization_util.commas(selectedItems).."!")
                end)

                return chooseAbilitiesView
            end, "Gambits", "Add a new Gambit.")
        return addAbilityMenuItem
    end

    local targetMenuItem = MenuItem.new(L{
        ButtonItem.default('Self', 18),
        ButtonItem.default('Ally', 18),
        ButtonItem.default('Enemy', 18),
    }, {
        Self = createAddAbilityMenuItem(GambitTarget.TargetType.Self),
        Ally = createAddAbilityMenuItem(GambitTarget.TargetType.Ally),
        Enemy = createAddAbilityMenuItem(GambitTarget.TargetType.Enemy),
    }, nil, "Gambits", "Add a new Gambit.")

    return targetMenuItem
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
                self.trustSettings:saveSettings(true)
            end
        end
    end, "Gambits", "Remove the selected Gambit.")
end

function GambitSettingsMenuItem:getEditConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self)
end

function GambitSettingsMenuItem:getModesMenuItem()
    local gambitModesMenuItem = MenuItem.new(L{}, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoGambitMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Change gambit behavior.")
    return gambitModesMenuItem
end

return GambitSettingsMenuItem
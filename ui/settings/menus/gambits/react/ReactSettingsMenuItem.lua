local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local ReactSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ReactSettingsMenuItem.__index = ReactSettingsMenuItem

function ReactSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.localized('Modes', i18n.translate('Button_Modes')),
    }, {}, nil, "Reactions", "Add reactions to actions taken by enemies or party members."), ReactSettingsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits:filter(function(g)
            return g:getTags():contains('reaction') or g:getTags():contains('Reaction')
        end)

        local configItem = MultiPickerConfigItem.new("Reactions", L{}, currentGambits, function(gambit)
            return gambit:tostring()
        end)

        local gambitSettingsEditor = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge)
        gambitSettingsEditor:setAllowsCursorSelection(true)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        self.disposeBag:add(gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            self.selectedGambit = selectedGambit
            gambitSettingsEditor.menuArgs['conditions'] = selectedGambit.conditions
            gambitSettingsEditor.menuArgs['targetTypes'] = S{ selectedGambit:getConditionsTarget() }
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

function ReactSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function ReactSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    self:setChildMenuItem("Edit", self:getEditGambitMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveAbilityMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function ReactSettingsMenuItem:getAbilities(gambitTarget, flatten)
    local gambitTargetMap = T{
        [GambitTarget.TargetType.Self] = S{'Self'},
        [GambitTarget.TargetType.Ally] = S{'Party', 'Corpse'},
        [GambitTarget.TargetType.Enemy] = S{'Enemy'}
    }
    local targets = gambitTargetMap[gambitTarget]
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
    if flatten then
        sections = sections:flatten(false)
    end
    return sections
end

function ReactSettingsMenuItem:getAbilitiesByTargetType()
    local abilitiesByTargetType = T{}

    abilitiesByTargetType[GambitTarget.TargetType.Self] = self:getAbilities(GambitTarget.TargetType.Self, true):compact_map()
    abilitiesByTargetType[GambitTarget.TargetType.Ally] = self:getAbilities(GambitTarget.TargetType.Ally, true):compact_map()
    abilitiesByTargetType[GambitTarget.TargetType.Enemy] = self:getAbilities(GambitTarget.TargetType.Enemy, true):compact_map()

    return abilitiesByTargetType
end

function ReactSettingsMenuItem:getAddAbilityMenuItem()
    return MenuItem.action(function(menu)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()

        local newGambit = Gambit.new(GambitTarget.TargetType.Enemy, L{ReadyAbilityCondition.new('Just Desserts')}, abilitiesByTargetType[GambitTarget.TargetType.Enemy][1], GambitTarget.TargetType.Enemy, L{ 'reaction' })

        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits
        currentGambits:append(newGambit)

        self.trustSettings:saveSettings(true)

        menu:showMenu(self)

        self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, currentGambits:filter(function(g) return g:getTags():contains('reaction') end):length()))

    end, "Reactions", "Add a new reaction.")
end

function ReactSettingsMenuItem:getEditGambitMenuItem()
    local editGambitMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
    }, {
    }, function(menuArgs, infoView)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()
        local gambitEditor = GambitSettingsEditor.new(self.selectedGambit, self.trustSettings, self.trustSettingsMode, abilitiesByTargetType)
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
    }, function(_, infoView)
        if self.selectedGambit then
            local configItems = L{}
            if self.selectedGambit:getAbility().get_config_items then
                configItems = self.selectedGambit:getAbility():get_config_items() or L{}
            end
            if not configItems:empty() then
                local editAbilityEditor = ConfigEditor.new(nil, self.selectedGambit:getAbility(), configItems, infoView)

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

function ReactSettingsMenuItem:getRemoveAbilityMenuItem()
    return MenuItem.action(function()
        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                local indexPath = selectedIndexPath
                local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits
                for i = 1, currentGambits:length() do
                    if currentGambits[i] == self.selectedGambit then
                        currentGambits:remove(i)
                        break
                    end
                end

                self.gambitSettingsEditor:getDataSource():removeItem(indexPath)

                self.selectedGambit = nil
                self.trustSettings:saveSettings(true)

                if self.gambitSettingsEditor:getDataSource():numberOfItemsInSection(1) > 0 then
                    self.selectedGambit = currentGambits:filter(function(g) return g:getTags():contains('reaction') end)[1]
                    self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
                end
            end
        end
    end, "Reactions", "Remove the selected reaction.")
end

function ReactSettingsMenuItem:getEditConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self)
end

function ReactSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for reaction gambits.",
            L{'AutoGambitMode'})
end

return ReactSettingsMenuItem
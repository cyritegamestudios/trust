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

local ReactSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ReactSettingsMenuItem.__index = ReactSettingsMenuItem

function ReactSettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Reactions", "Add reactions to actions taken by enemies or party members."), ReactSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits:filter(function(g)
            return g:getTags():contains('reaction') or g:getTags():contains('Reaction')
        end)

        local gambitSettingsEditor = FFXIPickerView.withItems(currentGambits:map(function(gambit)
            return gambit:tostring()
        end), L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge, true)
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
        [GambitTarget.TargetType.Ally] = S{'Party'},
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
        L{ 'Approach', 'Ranged Attack', 'Turn Around', 'Turn to Face', 'Run Away', 'Run To', 'Engage' }:filter(function(_)
            return targets:contains('Enemy')
        end),
    }
    if flatten then
        sections = sections:flatten()
    end
    return sections
end

function ReactSettingsMenuItem:getAbilitiesByTargetType()
    local abilitiesByTargetType = T{}

    abilitiesByTargetType[GambitTarget.TargetType.Self] = self:getAbilities(GambitTarget.TargetType.Self, true):map(function(abilityName) return job_util.getAbility(abilityName)  end):compact_map()
    abilitiesByTargetType[GambitTarget.TargetType.Ally] = self:getAbilities(GambitTarget.TargetType.Ally, true):map(function(abilityName) return job_util.getAbility(abilityName)  end):compact_map()
    abilitiesByTargetType[GambitTarget.TargetType.Enemy] = self:getAbilities(GambitTarget.TargetType.Enemy, true):map(function(abilityName) return job_util.getAbility(abilityName)  end):compact_map()

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
        ButtonItem.default('Conditions', 18),
    }, {}, function(menuArgs, infoView)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()

        local gambitEditor = GambitSettingsEditor.new(self.selectedGambit, self.trustSettings, self.trustSettingsMode, abilitiesByTargetType)
        return gambitEditor
    end, "Reactions", "Edit the selected reaction.", false, function()
        return self.selectedGambit ~= nil
    end)

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
    local gambitModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoGambitMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        return modesView
    end, "Modes", "Change reaction behavior.")
    return gambitModesMenuItem
end

return ReactSettingsMenuItem
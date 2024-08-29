local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
local Gambit = require('cylibs/gambits/gambit')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local job_util = require('cylibs/util/job_util')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local BlueMage = require('cylibs/entity/jobs/BLU')

local BlueMagicSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BlueMagicSettingsMenuItem.__index = BlueMagicSettingsMenuItem

function BlueMagicSettingsMenuItem.new(trustSettings, trustSettingsMode, isEditable)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('View', 18),
        ButtonItem.default('Equip', 18),
    }, {}, nil, "Blue Magic", "Equip or save spell sets.", false), BlueMagicSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.isEditable = isEditable
    self.job = BlueMage.new()
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView)
        local spellSets = trustSettings:getSettings()[trustSettingsMode.value].BlueMagicSettings.SpellSets

        local blueMagicSettingsEditor = FFXIPickerView.withItems(L(T(spellSets):keyset()):sort(), L{})
        blueMagicSettingsEditor:setAllowsCursorSelection(true)

        blueMagicSettingsEditor:setNeedsLayout()
        blueMagicSettingsEditor:layoutIfNeeded()

        self.disposeBag:add(blueMagicSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local item = blueMagicSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            if item then
                self.selectedSet = spellSets[item:getText()]
                self.selectedSetName = item:getText()
            end
        end), blueMagicSettingsEditor:getDelegate():didSelectItemAtIndexPath())

        if spellSets:length() > 0 then
            blueMagicSettingsEditor:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
        end

        return blueMagicSettingsEditor
    end

    self:reloadSettings()

    return self
end

function BlueMagicSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function BlueMagicSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("View", self:getViewSetMenuItem())
    self:setChildMenuItem("Equip", self:getEquipSetMenuItem())
    if self.isEditable then
        self:setChildMenuItem("Save As", self:getCreateSetMenuItem())
        self:setChildMenuItem("Delete", self:getDeleteSetMenuItem())
    end
end

function BlueMagicSettingsMenuItem:getEquipSetMenuItem()
    return MenuItem.action(function()
        if self.selectedSet then
            self.job:equip_spells(self.selectedSet:getSpells())
        end
    end, "Spells", "Equip the selected spell set.")
end

function BlueMagicSettingsMenuItem:getViewSetMenuItem()
    return MenuItem.new(L{}, {}, function(menuArgs, infoView)
        local spellListEditor = FFXIPickerView.withItems(self.selectedSet:getSpells(), L{}, true)
        return spellListEditor
    end, "Spells", "View blue magic in the set.")
end

function BlueMagicSettingsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {
        Confirm = MenuItem.action(function(menu)
            menu:showMenu(self)
        end)
    }, function(_)
        local createSetView = FFXITextInputView.new('Set', "Spell set name")
        createSetView:setTitle("Choose a name for the spell set.")
        createSetView:setShouldRequestFocus(true)
        createSetView:onTextChanged():addAction(function(_, newSetName)
            if newSetName:length() > 1 then
                local newSet = self.job:create_spell_set()
                if newSet then
                    local spellSets = self.trustSettings:getSettings()[self.trustSettingsMode.value].BlueMagicSettings.SpellSets
                    spellSets[newSetName] = newSet

                    self.trustSettings:saveSettings(true)

                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've saved a new spell set called "..newSetName.."!")
                end
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."That name is too short, pick something else?")
            end
        end)
        return createSetView
    end, "Spells", "Save a new spell set.")
    return createSetMenuItem
end

function BlueMagicSettingsMenuItem:getDeleteSetMenuItem()
    return MenuItem.action(function(menu)
        if self.selectedSetName then
            local spellSets = self.trustSettings:getSettings()[self.trustSettingsMode.value].BlueMagicSettings.SpellSets
            if L(T(spellSets):keyset()):length() <= 1 then
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't delete my last set!")
                return
            end

            spellSets[self.selectedSetName] = nil

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, "..self.selectedSetName.." is no more!")

            menu:showMenu(self)
        end
    end, "Spells", "Delete the selected spell set.")
end

return BlueMagicSettingsMenuItem
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')

local AlterEgoSettingsMenuItem = setmetatable({}, {__index = MenuItem })
AlterEgoSettingsMenuItem.__index = AlterEgoSettingsMenuItem

function AlterEgoSettingsMenuItem.new(truster, addonSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Alter Egos", "Choose Alter Egos to summon."), AlterEgoSettingsMenuItem)

    self.truster = truster
    self.addonSettings = addonSettings

    self:reloadSettings()

    return self
end

function AlterEgoSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Edit", self:getEditMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function AlterEgoSettingsMenuItem:getEditMenuItem()
    local editMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(_)
        local allAlterEgos = res.spells:with_all('type', 'Trust'):map(function(alterEgo) return alterEgo.en end)
            :filter(function(alterEgo) return spell_util.knows_spell(spell_util.spell_id(alterEgo))  end)
            :sort()

        local chooseAlterEgosView = FFXIPickerView.withItems(allAlterEgos, self.truster:get_trusts(), true)
        chooseAlterEgosView:setTitle("Choose Alter Egos to summon.")
        chooseAlterEgosView:on_pick_items():addAction(function(_, selectedItems)
            local alterEgos = selectedItems:map(function(item) return item:getText() end):compact_map()
            self.truster:set_trusts(alterEgos)

            self.addonSettings:getSettings().battle.trusts = alterEgos
            self.addonSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my list of Alter Egos to summon!")
        end)
        return chooseAlterEgosView
    end, "Alter Egos", "Choose Alter Egos to summon.")
    return editMenuItem
end

function AlterEgoSettingsMenuItem:getModesMenuItem()
    local curesModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm')
    }, L{}, function(_, infoView)
        local modesView = ModesView.new(L{'AutoTrustsMode'}, infoView)
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for summoning alter egos.")
        return modesView
    end, "Modes", "Set modes for summoning alter egos.")
    return curesModesMenuItem
end

return AlterEgoSettingsMenuItem
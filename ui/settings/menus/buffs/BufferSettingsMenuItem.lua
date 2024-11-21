local BuffSettingsMenuItem = require('ui/settings/menus/buffs/BuffSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FoodSettingsMenuItem = require('ui/settings/menus/buffs/FoodSettingsMenuItem')
local JobAbilitiesSettingsMenuItem = require('ui/settings/menus/buffs/JobAbilitiesSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local SpellSettingsEditor = require('ui/settings/SpellSettingsEditor')

local BufferSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BufferSettingsMenuItem.__index = BufferSettingsMenuItem

function BufferSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, jobNameShort, settingsPrefix)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Self', 18),
        ButtonItem.default('Party', 18),
        ButtonItem.default('Food', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Buffs", "Choose buffs to use."), BufferSettingsMenuItem)
    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.jobNameShort = jobNameShort
    self.settingsPrefix = settingsPrefix
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function BufferSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function BufferSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Self", self:getSelfBuffsMenuItem())
    self:setChildMenuItem("Party", self:getPartyBuffsMenuItem())
    self:setChildMenuItem("Food", self:getFoodMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function BufferSettingsMenuItem:getSelfBuffsMenuItem()
    local selfBuffSettingsItem = BuffSettingsMenuItem.new(self.trust, self.trustSettings, self.trustSettingsMode, self.settingsPrefix, 'SelfBuffs', S{'Self','Enemy'}, self.jobNameShort, "Edit buffs to use on the player.", false)
    return selfBuffSettingsItem
end

function BufferSettingsMenuItem:getPartyBuffsMenuItem()
    local partyBuffSettingsItem = BuffSettingsMenuItem.new(self.trust, self.trustSettings, self.trustSettingsMode, self.settingsPrefix, 'PartyBuffs', S{'Party'}, self.jobNameShort, "Edit buffs to use on party members.", true)
    partyBuffSettingsItem.enabled = function()
        return not S{ 'BLU','BST','COR','DNC','DRG','DRK','GEO','MNK','PUP','SAM','THF','NIN','WAR' }:contains(self.trust:get_job().jobNameShort)
    end
    return partyBuffSettingsItem
end

function BufferSettingsMenuItem:getJobAbilitiesMenuItem()
    return JobAbilitiesSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self.settingsPrefix)
end

function BufferSettingsMenuItem:getFoodMenuItem()
    local foodSettingsMenuItem = FoodSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self.trustModeSettings)
    return foodSettingsMenuItem
end

function BufferSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Change buffing behavior.",
            L{'AutoBarSpellMode', 'AutoBuffMode'})
end

function BufferSettingsMenuItem:getEditBuffMenuItem()
    local editBuffMenuItem = MenuItem.new(L{
        ButtonItem.default('Save', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
            function(args)
                local spell = args['spell']
                if spell then
                    local editSpellView = SpellSettingsEditor.new(self.trustSettings, spell, not self.showJobs)
                    editSpellView:setTitle("Edit buff.")
                    editSpellView:setShouldRequestFocus(true)
                    return editSpellView
                end
                return nil
            end, "Buffs", "Edit buff settings.")
    return editBuffMenuItem
end

return BufferSettingsMenuItem
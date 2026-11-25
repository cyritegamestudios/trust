local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')

local CombatModeSettingsMenuItem = setmetatable({}, {__index = MenuItem })
CombatModeSettingsMenuItem.__index = CombatModeSettingsMenuItem

function CombatModeSettingsMenuItem.new(trustSettings, trustSettingsMode, trustModeSettings, combat_mode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Config', 18),
        ButtonItem.localized("Modes", i18n.translate("Modes")),
    }, {}, nil, "Combat", "Configure combat settings."), CombatModeSettingsMenuItem)

    self.disposeBag = DisposeBag.new()
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.combat_mode = combat_mode

    self:reloadSettings()

    return self
end

function CombatModeSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function CombatModeSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function CombatModeSettingsMenuItem:getConfigMenuItem()
    local configMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        ButtonItem.default('Reset', 18),
    }, L{}, function(_, infoView)
        local combatSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].CombatSettings

        if combatSettings.WeaponSkillSaveHPP == nil then
            combatSettings.WeaponSkillSaveHPP = 3
        end
        if combatSettings.WeaponSkillHoldWhileSinging == nil then
            combatSettings.WeaponSkillHoldWhileSinging = true
        end
        if combatSettings.WeaponSkillHoldForDistance == nil then
            combatSettings.WeaponSkillHoldForDistance = true
        end

        local configItems = L{
            ConfigItem.new('Distance', 1.0, 30.0, 0.1, function(value) return value.." yalms" end, "Combat Distance"),
            ConfigItem.new('EngageDistance', 5, 30, 1, function(value) return value.." yalms" end, "Engage Distance"),
            ConfigItem.new('MirrorDistance', 0.2, 10, 0.1, function(value) return value.." yalms" end, "Mirror Distance"),
            ConfigItem.new('WeaponSkillSaveHPP', 0, 25, 1, function(value) return value.."%" end, "Save Weaponskill Under HP"),
            BooleanConfigItem.new('WeaponSkillHoldWhileSinging', "Hold Weaponskill While Singing"),
            BooleanConfigItem.new('WeaponSkillHoldForDistance', "Hold Weaponskill For Distance"),
        }
        local configEditor = ConfigEditor.new(self.trustSettings, combatSettings, configItems)

        self.disposeBag:add(configEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            if indexPath.section == 1 then
                infoView:setDescription("Distance from enemy when engaged and CombatMode is Auto.")
            elseif indexPath.section == 2 then
                infoView:setDescription("Maximum distance to engage enemy when AutoEngageMode is set to Always.")
            elseif indexPath.section == 3 then
                infoView:setDescription("Distance from party member when assisting and CombatMode is Mirror.")
            elseif indexPath.section == 4 then
                infoView:setDescription("Save the weaponskill when the target is under this much HP: it would die to melee anyway, so the TP is kept for the next mob. The right cutoff depends on the mob, since a stronger mob still has plenty of HP left at the same percent. 0% turns the save off.")
            elseif indexPath.section == 5 then
                infoView:setDescription("Hold weaponskills while the Bard is singing, so a weaponskill never delays the next song in the burst.")
            elseif indexPath.section == 6 then
                infoView:setDescription("Hold weaponskills until you reach this fight's rolled combat distance, so a weaponskill is not fired from out of position.")
            end
        end), configEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        return configEditor
    end, "Combat", "Configure combat settings.")
    
    return configMenuItem
end

function CombatModeSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for combat.",
            L{'CombatMode', 'AutoEngageMode'})
end

return CombatModeSettingsMenuItem
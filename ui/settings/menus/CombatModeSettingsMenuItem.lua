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
        if combatSettings.SongHoldTP == nil then
            combatSettings.SongHoldTP = 700
        end
        if combatSettings.DebuffHoldTP == nil then
            combatSettings.DebuffHoldTP = 500
        end
        if combatSettings.PullEngageTP == nil then
            combatSettings.PullEngageTP = 500
        end
        if combatSettings.AttackHoldTP == nil then
            combatSettings.AttackHoldTP = 500
        end

        local configItems = L{
            ConfigItem.new('Distance', 1.0, 30.0, 0.1, function(value) return value.." yalms" end, "Combat Distance"),
            ConfigItem.new('EngageDistance', 5, 30, 1, function(value) return value.." yalms" end, "Engage Distance"),
            ConfigItem.new('MirrorDistance', 0.2, 10, 0.1, function(value) return value.." yalms" end, "Mirror Distance"),
            ConfigItem.new('WeaponSkillSaveHPP', 0, 25, 1, function(value) return value.."%" end, "Save Weaponskill Under HP"),
            BooleanConfigItem.new('WeaponSkillHoldWhileSinging', "Hold Weaponskill While Singing"),
            BooleanConfigItem.new('WeaponSkillHoldForDistance', "Hold Weaponskill While Walking In"),
            ConfigItem.new('SongHoldTP', 0, 1000, 25, function(value) return value.." TP" end, "Hold Songs Above TP"),
            ConfigItem.new('DebuffHoldTP', 0, 1000, 25, function(value) return value.." TP" end, "Hold Debuffs Above TP"),
            ConfigItem.new('PullEngageTP', 0, 1000, 25, function(value) return value.." TP" end, "Pull by Engaging Above TP"),
            ConfigItem.new('AttackHoldTP', 0, 1000, 25, function(value) return value.." TP" end, "Engage Goes First Above TP"),
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
                infoView:setDescription("Distance means how far you stand from the mob to fight it: CombatMode walks you to a spot just inside your Combat Distance (the top setting) at the start of each fight. When a mob is claimed with TP already banked, this holds the weaponskill until you arrive, so it isn't fired while you're still walking in. Once you're in position it changes nothing for the rest of the fight.")
            elseif indexPath.section == 7 then
                infoView:setDescription("At or above this much TP, songs wait so the weaponskill goes first — singing first would swap your gear and can strand the TP you saved up. Nitro combos only start below this line, so Nitro still gets its window to lead a burst while TP is building. A burst that already started always sings through to the end.")
            elseif indexPath.section == 8 then
                infoView:setDescription("At or above this much TP, debuffs (Foe Requiem, Carnage Elegy and the rest) wait until the weaponskill has been used, so a debuff cast never delays the weaponskill the TP is being saved for.")
            elseif indexPath.section == 9 then
                infoView:setDescription("How the next mob gets pulled changes at this much TP. Below it, the puller casts the pull spell as normal. At or above it, the puller runs up and engages the mob to claim it instead — casting the pull spell would swap weapons and throw away the TP you are saving for a weaponskill.")
            elseif indexPath.section == 10 then
                infoView:setDescription("This one works the other way around. While a song burst is still going out, you do not engage a new mob yet — the songs finish first. That wait ends at this much TP: at or above it, engaging and the weaponskill go first and the songs wait instead.")
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
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local HealerSettingsMenuItem = setmetatable({}, {__index = GambitSettingsMenuItem })
HealerSettingsMenuItem.__index = HealerSettingsMenuItem


function HealerSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local editorStyle = GambitEditorStyle.new(function(gambits)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit, _)
            return gambit:tostring(), gambit:isEnabled() and gambit:isValid()
        end, "Gambits", nil, nil, function(gambit, _)
            if not gambit:isValid() then
                return "Unavailable on current job or settings."
            else
                return gambit:tostring()
            end
        end)
        configItem:setNumItemsRequired(1, 1)
        return L{ configItem }
    end, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge, "Heal", "Heals", nil, function(menuItemName)
        return L{ 'Add', 'Remove', 'Edit', 'Move Up', 'Move Down', 'Reset', 'Modes', 'Shortcuts', 'Blacklist' }:contains(menuItemName)
    end)
    editorStyle:setEditPermissions(
        GambitEditorStyle.Permissions.Edit,
        GambitEditorStyle.Permissions.Conditions
    )

    local self = setmetatable(GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, 'CureSettings', S{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally }, function(targets)
        return L{}
    end, L{ Condition.TargetType.Self, Condition.TargetType.Ally }, editorStyle, L{'AutoHealMode', 'AutoStatusRemovalMode', 'AutoDetectAuraMode'}, function(category)
        return L{ "Heals" }:contains(category:getName())
    end), HealerSettingsMenuItem)

    self:setDefaultGambitTags(L{'Heals'})

    self:getDisposeBag():add(self:onGambitChanged():addAction(function(newGambit, oldGambit)
        if newGambit:getAbility() ~= oldGambit:getAbility() then
            newGambit.conditions = newGambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            newGambit.conditions_target = newGambit:getAbilityTarget()
            local conditions = trust:role_with_type("healer"):get_default_conditions(newGambit)
            for condition in conditions:it() do
                condition:set_editable(false)
                newGambit:addCondition(condition)
            end
        end
    end), self:onGambitChanged())

    self:setConfigKey("heals")

    return self
end

return HealerSettingsMenuItem
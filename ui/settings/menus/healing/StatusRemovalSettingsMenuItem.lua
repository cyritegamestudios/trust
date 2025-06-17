local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local StatusRemovalSettingsMenuItem = setmetatable({}, {__index = GambitSettingsMenuItem })
StatusRemovalSettingsMenuItem.__index = StatusRemovalSettingsMenuItem

--FFXIClassicStyle.WindowSize.Editor.Conf
function StatusRemovalSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local editorStyle = GambitEditorStyle.new(function(gambits)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit, _)
            --[[local debuffCondition = gambit:getConditions():firstWhere(function(condition)
                return condition:getCondition().__type == HasBuffsCondition.__type
            end)
            if debuffCondition then
                local buffNames = debuffCondition:getCondition().buff_names:map(function(buffName)
                    return buffName:gsub("^%l", string.upper)
                end)
                return localization_util.commas(buffNames), gambit:isEnabled() and gambit:isValid()
            end]]
            return string.format("%s: %s", gambit:getAbilityTarget(), gambit:getAbility():get_name()), gambit:isEnabled() and gambit:isValid()
        end, "Gambits", nil, nil, function(gambit, _)
            if not gambit:isValid() then
                return "Unavailable on current job or settings."
            else
                return gambit:tostring()
            end
        end)
        configItem:setNumItemsRequired(1, 1)
        return L{ configItem }
    end, nil, "Status Cure", "Status Cures", nil, function(menuItemName)
        return L{ 'Add', 'Remove', 'Edit', 'Move Up', 'Move Down', 'Toggle', 'Reset', 'Modes', 'Shortcuts', 'Blacklist' }:contains(menuItemName)
    end)
    editorStyle:setEditPermissions(
            GambitEditorStyle.Permissions.Edit,
            GambitEditorStyle.Permissions.Conditions
    )

    local self = setmetatable(GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, 'StatusRemovalSettings', S{ GambitTarget.TargetType.Self, GambitTarget.TargetType.Ally }, function(targets)
        return L{}
    end, L{ Condition.TargetType.Self, Condition.TargetType.Ally }, editorStyle, L{'AutoStatusRemovalMode', 'AutoDetectAuraMode'}, function(category)
        return L{ "StatusRemoval" }:contains(category:getName())
    end), StatusRemovalSettingsMenuItem)

    self:setDefaultGambitTags(L{'StatusRemoval'})

    self:getDisposeBag():add(self:onGambitChanged():addAction(function(newGambit, oldGambit)
        if newGambit:getAbility() ~= oldGambit:getAbility() then
            newGambit.conditions = newGambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            newGambit.conditions_target = newGambit:getAbilityTarget()
            local conditions = trust:role_with_type("statusremover"):get_default_conditions(newGambit)
            for condition in conditions:it() do
                condition:set_editable(false)
                newGambit:addCondition(condition)
            end
        end
    end), self:onGambitChanged())

    self:setConfigKey("statusremoval")

    return self
end

return StatusRemovalSettingsMenuItem
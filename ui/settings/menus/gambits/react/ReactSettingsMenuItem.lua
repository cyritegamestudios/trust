local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')

local ReactSettingsMenuItem = setmetatable({}, {__index = MenuItem })
ReactSettingsMenuItem.__index = ReactSettingsMenuItem

function ReactSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local reactionConditionTypes = S{
        GainDebuffCondition.__type,
        ReadyAbilityCondition.__type,
        FinishAbilityCondition.__type,
        BeginCastCondition.__type,
        TargetNameCondition.__type,
        ZoneChangeCondition.__type,
        SkillchainPropertyCondition.__type,
        ActionCondition.__type,
        PetTacticalPointsCondition.__type,
    }
    local conditionTypeFilter = function(conditionType)
        return reactionConditionTypes:contains(conditionType)
    end
    local reactSettingsMenuItem = GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, 'ReactionSettings', nil, nil, nil, GambitEditorStyle.named('Reaction', 'Reactions'), L{ 'AutoReactMode' }, function(category)
        return category:getName() == 'Enemies'
    end, nil, conditionTypeFilter)
    reactSettingsMenuItem:setDefaultGambitTags(L{ 'Reaction' })
    return reactSettingsMenuItem
end

return ReactSettingsMenuItem
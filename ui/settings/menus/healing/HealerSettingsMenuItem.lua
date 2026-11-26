local BooleanConfigItem = require('ui/settings/editors/config/BooleanConfigItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local HealerSettingsMenuItem = setmetatable({}, {__index = GambitSettingsMenuItem })
HealerSettingsMenuItem.__index = HealerSettingsMenuItem


function HealerSettingsMenuItem.descriptionForGambit(gambit)
    local hppRangeCondition = gambit:getConditions():firstWhere(function(condition)
        if condition:getCondition().__type == HitPointsPercentRangeCondition.__type then
            return true
        end
        return false
    end)
    --if hppRangeCondition then
    --    return string.format("%s: %s (%s)", gambit:getAbilityTarget(), gambit:getAbility():get_name(), hppRangeCondition:tostring())
    --else
        return string.format("%s: %s", gambit:getAbilityTarget(), gambit:getAbility():get_name())
    --end
end

function HealerSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings)
    local editorStyle = GambitEditorStyle.new(function(gambits)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit, _)
            return HealerSettingsMenuItem.descriptionForGambit(gambit), gambit:isEnabled() and gambit:isValid()
        end, "Gambits", nil, nil, function(gambit, _)
            if not gambit:isValid() then
                return "Unavailable on current job or settings."
            else
                return gambit:tostring()
            end
        end)
        configItem:setNumItemsRequired(1, 1)
        return L{ configItem }
    end, FFXIClassicStyle.WindowSize.Picker.Wide, "Heal", "Heals", nil, function(menuItemName)
        return L{ 'Add', 'Remove', 'Edit', 'Move Up', 'Move Down', 'Reset', 'Modes', 'Shortcuts', 'Blacklist', 'Config' }:contains(menuItemName)
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
    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Blacklist", self:getBlacklistMenuItem())

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

function HealerSettingsMenuItem:getConfigMenuItem()
    return MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {}, function(_, infoView)
        local cureSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].CureSettings
        cureSettings.IncludeAlliance = cureSettings.IncludeAlliance or false

        local configItems = L{
            BooleanConfigItem.new('IncludeAlliance', 'Include Alliance'),
        }

        local configEditor = ConfigEditor.new(self.trustSettings, cureSettings, configItems, infoView)

        self:getDisposeBag():add(configEditor:onConfigChanged():addAction(function(newSettings, _)
            cureSettings.IncludeAlliance = newSettings.IncludeAlliance
            self.trustSettings:saveSettings(true)
        end), configEditor:onConfigChanged())

        return configEditor
    end, "Config", "Configure healing settings.")
end

function HealerSettingsMenuItem:getBlacklistMenuItem()
    return MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {}, function(_, infoView, showMenu)
        local cureSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].CureSettings
        cureSettings.Blacklist = cureSettings.Blacklist or L{}

        local partyMemberNames = self.trust:get_alliance():get_alliance_members(true):map(function(allianceMember)
            return allianceMember:get_name()
        end):unique()

        local blacklistConfigItem = MultiPickerConfigItem.new('Blacklist', cureSettings.Blacklist, partyMemberNames, function(partyMemberNames)
            if partyMemberNames:empty() then
                return 'None'
            end
            return localization_util.commas(partyMemberNames, 'and')
        end, 'Blacklist')
        blacklistConfigItem:setPickerTitle('Blacklist')
        blacklistConfigItem:setPickerDescription('Choose party or alliance members to ignore when healing.')
        blacklistConfigItem:setNumItemsRequired(0)

        local blacklistEditor = ConfigEditor.new(self.trustSettings, cureSettings, L{ blacklistConfigItem }, infoView, nil, showMenu)

        self:getDisposeBag():add(blacklistEditor:onConfigConfirm():addAction(function(newSettings, _)
            cureSettings.Blacklist = newSettings.Blacklist or L{}

            local healer = self.trust:role_with_type("healer")
            if healer then
                healer:set_party_member_blacklist(cureSettings.Blacklist)
            end

            self.trustSettings:saveSettings(true)
        end), blacklistEditor:onConfigConfirm())

        return blacklistEditor
    end, "Blacklist", "Choose party and alliance members to ignore when healing.")
end

return HealerSettingsMenuItem

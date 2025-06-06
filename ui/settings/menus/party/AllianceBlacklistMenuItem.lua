local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local IpcRelay = require('cylibs/messages/ipc/ipc_relay')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local Whitelist = require('settings/settings').Whitelist

local AllianceBlacklistMenuItem = setmetatable({}, {__index = MenuItem })
AllianceBlacklistMenuItem.__index = AllianceBlacklistMenuItem

function AllianceBlacklistMenuItem.new(alliance)
    local allRoles = L{}:extend(L(player.trust.main_job:get_roles())):extend(L(player.trust.sub_job:get_roles()))

    local roles = L(allRoles:filter(function(role)
        return role.get_party_member_blacklist ~= nil
    end))

    local menuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm'))
    }, {}, function(_, infoView, showMenu)
        local allianceMemberNames = alliance:get_alliance_members(true):map(function(alliance_member)
            return alliance_member:get_name()
        end)

        local roleSettings = {}
        local roleConfigItems = L{}

        for role in roles:it() do
            local key = role:get_type()
            roleSettings[key] = role:get_party_member_blacklist() or L{}

            local roleConfigItem = MultiPickerConfigItem.new(key, roleSettings[key], allianceMemberNames, function(partyMemberNames)
                if partyMemberNames:empty() then return
                'None'
                end
                return localization_util.commas(partyMemberNames, 'and')
            end, role:get_localized_name())

            roleConfigItem:setPickerTitle(role:get_localized_name())
            roleConfigItem:setPickerDescription("Choose party or alliance members to ignore.")
            roleConfigItem:setNumItemsRequired(0)

            roleConfigItems:append(roleConfigItem)
        end

        local roleSettingsEditor = ConfigEditor.new(nil, roleSettings, roleConfigItems, infoView, nil, showMenu)
        return roleSettingsEditor
    end, "Blacklist", "Choose party and alliance members to ignore.", false, function()
        return roles:length() > 0, "There are no roles that can be configured."
    end)

    local self = setmetatable(menuItem, AllianceBlacklistMenuItem)

    return self
end

return AllianceBlacklistMenuItem
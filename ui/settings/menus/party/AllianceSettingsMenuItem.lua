local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PartyMemberMenuItem = require('ui/settings/menus/party/PartyMemberMenuItem')
local PlayerMenuItem = require('ui/settings/menus/party/PlayerMenuItem')


local AllianceSettingsMenuItem = setmetatable({}, {__index = MenuItem })
AllianceSettingsMenuItem.__index = AllianceSettingsMenuItem

function AllianceSettingsMenuItem.new(alliance, trust)

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized('Edit', i18n.translate('Button_Edit')),
    }, {}, nil, "Alliance", "See status and configure alliance members."), AllianceSettingsMenuItem)

    self.alliance = alliance

    self.contentViewConstructor = function(_, infoView, _)
        local allianceMembers = alliance:get_alliance_members()

        local configItem = MultiPickerConfigItem.new('AllianceMembers', L{ allianceMembers[1] }, allianceMembers, function(allianceMember)
            return allianceMember:get_name()
        end)

        self.allianceSettingsEditor = FFXIPickerView.new(L{ configItem }, false)
        self.allianceSettingsEditor:setAllowsCursorSelection(true)

        local reloadSettings = function(allianceMember)
            if allianceMember:is_player() then
                self:setChildMenuItem("Edit", PlayerMenuItem.new(allianceMember, player.party, player.alliance, trust))
            else
                self:setChildMenuItem("Edit", PartyMemberMenuItem.new(allianceMember, player.party, trust))
            end
            infoView:setTitle(allianceMember:get_name())
            infoView:setDescription("See status and configure alliance members.")
        end

        self.allianceSettingsEditor:getDisposeBag():add(self.allianceSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local allianceMember = allianceMembers[indexPath.row]
            reloadSettings(allianceMember)
        end), self.allianceSettingsEditor:getDelegate():didSelectItemAtIndexPath())

        reloadSettings(alliance:get_alliance_member_named(windower.ffxi.get_player().name))

        return self.allianceSettingsEditor
    end

    return self
end

return AllianceSettingsMenuItem
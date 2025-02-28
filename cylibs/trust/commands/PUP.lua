local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local PuppetmasterTrustCommands = setmetatable({}, {__index = TrustCommands })
PuppetmasterTrustCommands.__index = PuppetmasterTrustCommands
PuppetmasterTrustCommands.__class = "PuppetmasterTrustCommands"

function PuppetmasterTrustCommands.new(trust, action_queue, trust_settings, weapon_skill_settings)
    local self = setmetatable(TrustCommands.new(), PuppetmasterTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
    self.weapon_skill_settings = weapon_skill_settings
    self.action_queue = action_queue

    local update_attachment_sets = function(trust_settings)
        local set_names = L(self:get_attachment_sets():keyset())
        self:add_command('equip', self.handle_equip_set, 'Equips an attachment set', L{
            PickerConfigItem.new('set_name', set_names[1], set_names, nil, "Attachment Set Name"),
        })
    end

    trust:on_trust_settings_changed():addAction(function(_, new_trust_settings)
        update_attachment_sets(new_trust_settings)
    end)
    update_attachment_sets(trust:get_trust_settings())

    return self
end

function PuppetmasterTrustCommands:get_command_name()
    return 'pup'
end

function PuppetmasterTrustCommands:get_localized_command_name()
    return 'Puppetmaster'
end

function PuppetmasterTrustCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

function PuppetmasterTrustCommands:get_attachment_sets()
    local attachment_settings = self:get_settings().AutomatonSettings.AttachmentSettings

    local attachment_sets = T{}
    for set_type in L{ 'Default', 'Custom' }:it() do
        for attachment_set_name, attachment_set in pairs(attachment_settings[set_type]) do
            attachment_sets[attachment_set_name] = attachment_set
        end
    end
    return attachment_sets
end

function PuppetmasterTrustCommands:get_job()
    return self.trust:get_job()
end

-- // trust pup equip set_name
function PuppetmasterTrustCommands:handle_equip_set(_, set_name)
    local success
    local message

    for attachment_set_name, attachment_set in pairs(self:get_attachment_sets()) do
        if attachment_set_name:lower() == set_name:lower() then
            self:get_job():equip_attachment_set(attachment_set:getHeadName(), attachment_set:getFrameName(), attachment_set:getAttachments(), true)
            success = true
            message = string.format("Equipping %s", attachment_set_name)
            break
        end
    end

    if not success then
        message = string.format("Invalid set %s", set_name or 'nil')
    end

    return success, message
end

function PuppetmasterTrustCommands:get_all_commands()
    local result = TrustCommands.get_all_commands(self)

    local set_names = T(self:get_attachment_sets()):keyset()
    for set_name in set_names:it() do
        result:append(string.format('// trust pup equip %s', set_name))
    end

    return result
end

return PuppetmasterTrustCommands
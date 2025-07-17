local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local BlueMageTrustCommands = setmetatable({}, {__index = TrustCommands })
BlueMageTrustCommands.__index = BlueMageTrustCommands
BlueMageTrustCommands.__class = "BlueMageTrustCommands"

function BlueMageTrustCommands.new(trust, action_queue, trust_settings, weapon_skill_settings)
    local self = setmetatable(TrustCommands.new(), BlueMageTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
    self.weapon_skill_settings = weapon_skill_settings
    self.action_queue = action_queue

    local update_spell_sets = function(trust_settings)
        local set_names = L(self:get_spell_sets():keyset())
        self:add_command('equip', self.handle_equip_set, 'Equips a spell set', L{
            PickerConfigItem.new('set_name', set_names[1], set_names, nil, "Spell Set Name"),
        })
    end

    trust:on_trust_settings_changed():addAction(function(_, new_trust_settings)
        update_spell_sets(new_trust_settings)
    end)
    update_spell_sets(trust:get_trust_settings())

    return self
end

function BlueMageTrustCommands:get_command_name()
    return 'blu'
end

function BlueMageTrustCommands:get_localized_command_name()
    return 'Blue Mage'
end

function BlueMageTrustCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

function BlueMageTrustCommands:get_spell_sets()
    return T(self:get_settings().BlueMagicSettings.SpellSets)
end

function BlueMageTrustCommands:get_job()
    return self.trust:get_job()
end

-- // trust blu equip set_name
function BlueMageTrustCommands:handle_equip_set(_, set_name)
    local success
    local message

    for spell_set_name, spell_set in pairs(self:get_spell_sets()) do
        if spell_set_name:lower() == set_name:lower() then
            self:get_job():equip_spells(spell_set:getSpells())
            success = true
            message = string.format("Equipping %s", spell_set_name)
            break
        end
    end

    if not success then
        message = string.format("Invalid set %s", set_name or 'nil')
    end

    return success, message
end

function BlueMageTrustCommands:get_all_commands()
    local result = TrustCommands.get_all_commands(self)

    local set_names = T(self:get_spell_sets()):keyset()
    for set_name in set_names:it() do
        result:append(string.format('// trust blu equip %s', set_name))
    end

    return result
end

return BlueMageTrustCommands
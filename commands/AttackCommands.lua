local TrustCommands = require('cylibs/trust/commands/trust_commands')
local AttackTrustCommands = setmetatable({}, {__index = TrustCommands })
AttackTrustCommands.__index = AttackTrustCommands
AttackTrustCommands.__class = "AttackTrustCommands"

function AttackTrustCommands.new(trust, trust_settings, action_queue)
    local self = setmetatable(TrustCommands.new(), AttackTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
    self.action_queue = action_queue

    -- AutoEngageMode
    self:add_command('default', function(_) return self:handle_toggle_mode('AutoEngageMode', 'Always', 'Off')  end, 'Toggle engaging mobs')
    self:add_command('off', function(_) return self:handle_set_mode('AutoEngageMode', 'Off')  end, 'Disable engaging')
    self:add_command('engage', function(_) return self:handle_set_mode('AutoEngageMode', 'Always')  end, 'Automatically engage mobs party is fighting')
    self:add_command('mirror', function(_) return self:handle_set_mode('AutoEngageMode', 'Mirror')  end, 'Automatically engage only if assist target is fighting')
    self:add_command('distance', self.handle_set_combat_distance, 'Set the combat distance', L{ ConfigItem.new('distance', 1.0, 30.0, 0.1, function(value) return value.." yalms" end, "Combat Distance"), })

    return self
end

function AttackTrustCommands:get_command_name()
    return 'attack'
end

-- // trust attack [engage, mirror, assist]
function AttackTrustCommands:handle_toggle_mode(mode_var_name, on_value, off_value)
    local success = true
    local message

    local mode_var = get_state(mode_var_name)
    if mode_var.value == on_value then
        handle_set(mode_var_name, off_value)
    else
        handle_set(mode_var_name, on_value)
    end

    return success, message
end

-- // trust attack distance number
function AttackTrustCommands:handle_set_combat_distance(_, distance)
    local success
    local message

    if distance:match("^%d+%.?%d*$") then
        distance = math.min(math.max(tonumber(distance), 1), 30)
        local current_settings = self.trust_settings:getSettings()[state.MainTrustSettingsMode.value].CombatSettings
        current_settings.Distance = distance

        self.trust_settings:saveSettings(true)

        success = true
        message = 'Combat distance set to '..distance
    else
        success = false
        message = 'Invalid distance '..distance
    end

    return success, message
end

return AttackTrustCommands
local TrustCommands = require('cylibs/trust/commands/trust_commands')
local TargetCommands = setmetatable({}, {__index = TrustCommands })
TargetCommands.__index = TargetCommands
TargetCommands.__class = "TargetCommands"

function TargetCommands.new(trustSettings, trustSettingsMode, party, actionQueue, puller)
    local self = setmetatable(TrustCommands.new(), TargetCommands)

    self.trust_settings = trustSettings
    self.trust_settings_mode = trustSettingsMode
    self.party = party
    self.puller = puller
    self.actionQueue = actionQueue

    self:add_command('auto', function(_) return self:handle_set_mode('PullActionMode', 'Target')  end, 'Automatically target aggroed monsters after defeating one')
    self:add_command('off', function(_) return self:handle_set_mode('PullActionMode', 'Auto')  end, 'Disable auto target')
    self:add_command('cycle', self.handle_cycle_target, 'Cycle between party targets')
    self:add_command('clear', self.handle_clear_target, 'Clears the current target in the target widget')

    return self
end

function TargetCommands:get_command_name()
    return 'target'
end

function TargetCommands:handle_cycle_target(_)
    local success = false
    local message = "There are not enough targets"

    local targets = self.party.target_tracker:get_targets():sort(function(t1, t2)
        return t1:get_distance() < t2:get_distance()
    end)
    if targets:length() > 1 then
        local target_index = windower.ffxi.get_player().target_index
        if target_index and target_index ~= 0 then
            local current_target_index = 1
            for index, target in ipairs(targets) do
                if windower.ffxi.get_player().target_index == target:get_mob().index then
                    current_target_index = index
                end
            end
            local next_target_index = current_target_index + 1
            if next_target_index > targets:length() then
                next_target_index = 1
            end
            local next_target = targets[next_target_index]
            if next_target then
                local SwitchTargetAction = require('cylibs/actions/switch_target')
                self.actionQueue:clear()
                self.actionQueue:push_action(SwitchTargetAction.new(next_target:get_mob().index, 3), true)
                success = true
                message = "Targeting "..next_target:get_name()
            end
        end
    else
        success = false
        message = "There are not enough targets"
    end

    return success, message
end

function TargetCommands:handle_clear_target(_)
    local success = true
    local message = "Target has been cleared"

    self.puller:set_pull_target(nil)

    return success, message
end

return TargetCommands
local TrustScenarios = require('scenarios/TrustScenarios')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local ScenarioTrustCommands = setmetatable({}, {__index = TrustCommands })
ScenarioTrustCommands.__index = ScenarioTrustCommands
ScenarioTrustCommands.__class = "ScenarioTrustCommands"

function ScenarioTrustCommands.new(trust, action_queue, party)
    local self = setmetatable(TrustCommands.new(), ScenarioTrustCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.scenarios = TrustScenarios.new(action_queue, party, trust)

    self:add_command('start', self.handle_start_scenario, 'Start a scenario')
    self:add_command('stop', self.handle_stop_scenario, 'Stop an active scenario')

    return self
end

function ScenarioTrustCommands:destroy()
    self.scenarios:destroy()
end

function ScenarioTrustCommands:get_command_name()
    return 'scenario'
end

-- // trust scenario start scenario_name
function ScenarioTrustCommands:handle_start_scenario(_, scenario_name)
    local success = true
    local message

    if not self.scenarios:has_scenario(scenario_name) then
        self.scenarios:add_scenario(scenario_name)
        success = true
        message = 'Started scenario: '..scenario_name
    else
        success = false
        message = 'Scenario '..scenario_name..' is already active'
    end

    return success, message
end

-- // trust scenario stop scenario_name
function ScenarioTrustCommands:handle_stop_scenario(_, scenario_name)
    local success = true
    local message

    if self.scenarios:has_scenario(scenario_name) then
        self.scenarios:remove_scenario(scenario_name)
        success = true
        message = 'Stopped scenario: '..scenario_name
    else
        success = false
        message = 'Invalid scenario: '..scenario_name
    end

    return success, message
end

return ScenarioTrustCommands
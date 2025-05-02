local TrustScenarios = require('scenarios/TrustScenarios')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local ScenarioTrustCommands = setmetatable({}, {__index = TrustCommands })
ScenarioTrustCommands.__index = ScenarioTrustCommands
ScenarioTrustCommands.__class = "ScenarioTrustCommands"

function ScenarioTrustCommands.new(trust, action_queue, party, addon_settings)
    local self = setmetatable(TrustCommands.new(), ScenarioTrustCommands)

    self.trust = trust
    self.party = party
    self.action_queue = action_queue
    self.addon_settings = addon_settings
    self.scenarios = TrustScenarios.new(action_queue, addon_settings, party, trust)

    self:add_command('start', self.handle_start_scenario, 'Start a scenario')
    self:add_command('restart', self.handle_restart_scenario, 'Restart a scenario')
    self:add_command('stop', self.handle_stop_scenario, 'Stop an active scenario')
    self:add_command('exp', self.handle_exp_party, 'Set up the party for experience points farming')
    self:add_command('cp', self.handle_exp_party, 'Set up the party for capacity points farming')
    self:add_command('ep', self.handle_exp_party, 'Set up the party for exemplar points farming')

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

-- // trust scenario restart scenario_name
function ScenarioTrustCommands:handle_restart_scenario(_, scenario_name)
    local success, message = self:handle_stop_scenario(_, scenario_name)
    success, message = self:handle_start_scenario(_, scenario_name)

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

-- // trust scenario [exp|cp|ep]
function ScenarioTrustCommands:handle_exp_party(_)
    local success = true
    local message

    -- 1. Set up primary puller
    self:handle_set_mode('AutoPullMode', 'Auto', true)
    self:handle_set_mode('PullActionMode', 'Auto', true)
    self:handle_set_mode('AutoEngageMode', 'Always', true)

    -- 2. Clear assist on all
    windower.send_command('trust sendall trust assist clear')
    windower.send_command('trust sendall trust pull aggroed')
    windower.send_command('trust sendall trust pull action target')
    windower.send_command('trust sendall trust attack engage')

    local party_members = self.party:get_party_members()
    if party_members:length() == 0 then
        addon_system_message(string.format("%s will now pull mobs for the party.", self.party:get_player():get_name()))
    else
        addon_system_message(string.format("%s will now pull mobs for the party and %s will assist and engage.", self.party:get_player():get_name(), localization_util.commas(self.party:get_party_members():map(function(p) return p:get_name() end))))
    end

    return success, message
end

return ScenarioTrustCommands
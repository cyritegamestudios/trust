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

    self:add_command('exp', self.handle_exp_party, 'Set up the party for experience points farming and makes this player the puller')
    self:add_command('cp', self.handle_exp_party, 'Set up the party for capacity points farming and makes this player the puller')
    self:add_command('ep', self.handle_exp_party, 'Set up the party for exemplar points and makes this player the puller')

    return self
end

function ScenarioTrustCommands:get_command_name()
    return 'scenario'
end

-- // trust scenario [exp|cp|ep]
function ScenarioTrustCommands:handle_exp_party(_, assist_target_name)
    local success = true
    local message

    if assist_target_name then
        windower.send_command('trust assist clear')
        windower.send_command('trust pull aggroed')
        windower.send_command('trust pull action target')
        windower.send_command('trust follow '..assist_target_name)
        windower.send_command('trust attack engage 10')
        windower.send_command('trust attack distance 2')
        windower.send_command('trust set CombatMode Auto')
    else
        -- 1. Set up primary puller
        self:handle_set_mode('AutoPullMode', 'Auto', true)
        self:handle_set_mode('PullActionMode', 'Auto', true)
        self:handle_set_mode('AutoEngageMode', 'Always', true)

        windower.send_command('trust pull camp')
        windower.send_command('trust follow clear')

        -- 2. Set up party members
        windower.send_command('trust sendall trust scenario exp '..windower.ffxi.get_player().name)

        local party_members = self.party:get_party_members()
        if party_members:length() == 0 then
            addon_system_message(string.format("%s will now pull mobs for the party.", self.party:get_player():get_name()))
        else
            addon_system_message(string.format("%s will now pull mobs for the party and %s will assist and engage.", self.party:get_player():get_name(), localization_util.commas(self.party:get_party_members():map(function(p) return p:get_name() end))))
        end
    end

    return success, message
end

return ScenarioTrustCommands
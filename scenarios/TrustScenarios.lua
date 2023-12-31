local DisposeBag = require('cylibs/events/dispose_bag')

local TrustScenarios = {}
TrustScenarios.__index = TrustScenarios

function TrustScenarios.new(action_queue, party, trust)
    local self = setmetatable({
        action_queue = action_queue;
        party = party;
        trust = trust;
        scenarios = S{};
        dispose_bag = DisposeBag.new();
    }, TrustScenarios)

    self:on_init()

    self.dispose_bag:addAny(self.scenarios)

    return self
end

function TrustScenarios:on_init()
end

function TrustScenarios:destroy()
    self.dispose_bag:destroy()
end

function TrustScenarios:has_scenario(name)
    for scenario in self.scenarios:it() do
        if scenario:get_name() == name then
            return true
        end
    end
    return false
end

function TrustScenarios:add_scenario(name)
    if not self:has_scenario(name) then
        if name == 'di' then
            local DomainInvasion = require('cylibs/scenarios/domain_invasion/domain_invasion')
            local scenario = DomainInvasion.new(self.action_queue)
            self.scenarios:add(scenario)
            self:start_scenario(scenario)
        elseif name == 'einherjar' then
            local Einherjar = require('scenarios/einherjar/einherjar')
            local scenario = Einherjar.new(self.action_queue, self.party, self.trust)
            self.scenarios:add(scenario)
            self:start_scenario(scenario)
        end
    end
end

function TrustScenarios:start_scenario(scenario)
    scenario:on_scenario_complete():addAction(function(s, success)
        if s == scenario then
            self:remove_scenario(s:get_name())
            if success and s:should_repeat() then
                windower.add_to_chat(122, "Restarting scenario: "..scenario:get_name())
                self:add_scenario(s:get_name())
            end
        end
    end)
    scenario:start()
end

function TrustScenarios:remove_scenario(name)
    local scenarios = L(self.scenarios:filter(function(scenario)
        return scenario:get_name() == name end))
    if scenarios:length() > 0 then
        local scenario = scenarios[1]
        scenario:stop()
        scenario:destroy()
        self.scenarios:remove(scenario)
    end
end

return TrustScenarios




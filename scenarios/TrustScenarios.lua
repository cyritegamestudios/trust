local TrustScenarios = {}
TrustScenarios.__index = TrustScenarios

function TrustScenarios.new(action_queue)
    local self = setmetatable({
        action_queue = action_queue;
        scenarios = S{};
    }, TrustScenarios)

    self:on_init()

    return self
end

function TrustScenarios:on_init()
end

function TrustScenarios:destroy()
    for scenario in self.scenarios:it() do
        scenario:destroy()
    end
    self.scenarios = nil
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
            scenario:start()
            self.scenarios:add(scenario)
        elseif name == 'einherjar' then
            local Einherjar = require('cylibs/scenarios/einherjar/einherjar')
            local scenario = Einherjar.new(self.action_queue)
            scenario:start()
            self.scenarios:add(scenario)
        end
    end
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




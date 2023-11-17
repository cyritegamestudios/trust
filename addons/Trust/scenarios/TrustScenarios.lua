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
        end
    end
end

function TrustScenarios:remove_scenario(name)
end

function TrustScenarios:handle_command(cmd, arg1)
    if cmd == 'load' then
        self:add_scenario(arg1)
    elseif L{'stop'}:contains(cmd) then
        self:remove_scenario(arg1)
    else
        error('Unknown scenario command', cmd)
    end
end

return TrustScenarios




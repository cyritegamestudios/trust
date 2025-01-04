local Action = require('cylibs/actions/action')
local LoadDependenciesAction = setmetatable({}, { __index = Action })
LoadDependenciesAction.__index = LoadDependenciesAction

function LoadDependenciesAction.new()
    local self = setmetatable(Action.new(0, 0, 0), LoadDependenciesAction)
    return self
end

function LoadDependenciesAction:load_dependendies()
    return coroutine.create(function()
        require('Trust-Include')
        coroutine.yield(true)
    end)
end

function LoadDependenciesAction:perform()
    local success = coroutine.resume(self:load_dependendies())

    self:complete(success)
end

function LoadDependenciesAction:gettype()
    return "loaddependenciesaction"
end

function LoadDependenciesAction:is_equal(action)
    return self:gettype() == action:gettype() and self:get_command() == action:get_command()
end

function LoadDependenciesAction:tostring()
    return "Loading dependencies"
end

return LoadDependenciesAction





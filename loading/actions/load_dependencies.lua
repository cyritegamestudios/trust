local ImportAction = require('cylibs/actions/import_action')
local LoadDependenciesAction = setmetatable({}, { __index = ImportAction })
LoadDependenciesAction.__index = LoadDependenciesAction

function LoadDependenciesAction.new()
    local paths = L{

    }

    local self = setmetatable(ImportAction.new(paths), LoadDependenciesAction)
    return self
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





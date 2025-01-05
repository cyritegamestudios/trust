local Action = require('cylibs/actions/action')
local ImportAction = setmetatable({}, { __index = Action })
ImportAction.__index = ImportAction

function ImportAction.new(import_paths, identifier, description)
    local self = setmetatable(Action.new(0, 0, 0), ImportAction)
    self.import_paths = import_paths
    self.identifier = identifier or os.time()
    self.description = description
    return self
end

function ImportAction:gettype()
    return "importaction"
end

function ImportAction:perform()
    local num_imports = 0
    for import_path in self.import_paths:it() do
        coroutine.schedule(function()
            require(import_path)
            num_imports = num_imports + 1
            if num_imports == self.import_paths:length() then
                self:complete(true)
            end
        end, 0.0)
    end
end

function ImportAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:getidentifier() == action:getidentifier()
end

return ImportAction





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
    local index = 1

    local function load_next()
        local import_path = self.import_paths[index]
        if import_path == nil then
            self:complete(true)
            return
        end

        coroutine.schedule(function()
            require(import_path)

            index = index + 1
            load_next()
        end, 0.0)
    end

    load_next()
end

function ImportAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:getidentifier() == action:getidentifier()
end

return ImportAction





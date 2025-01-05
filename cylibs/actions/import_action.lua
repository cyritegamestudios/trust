local AsyncAction = require('cylibs/actions/async_action')
local ImportAction = setmetatable({}, { __index = AsyncAction })
ImportAction.__index = ImportAction

function ImportAction.new(import_paths, identifier, description)
    local work = coroutine.create(function()
        for i=1, import_paths:length() do
            print('importing', import_paths[i], os.clock())
            require(import_paths[i])
            coroutine.yield(i >= 23)
        end
        print('done importing')
    end)

    local self = setmetatable(AsyncAction.new(work, 0.01, identifier, description), ImportAction)
    return self
end

function ImportAction:gettype()
    return "importaction"
end

function ImportAction:is_equal(action)
    if action == nil then
        return false
    end
    return self:gettype() == action:gettype() and self:getidentifier() == action:getidentifier()
end

return ImportAction





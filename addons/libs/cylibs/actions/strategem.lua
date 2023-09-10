---------------------------
-- Action representing the player using a strategem.
-- @class module
-- @name Strategem

require('coroutine')
require('vectors')
require('math')

local Action = require('cylibs/actions/action')
local Strategem = setmetatable({}, {__index = Action })
Strategem.__index = Strategem

function Strategem.new(strategem_name, target_index)
    local self = setmetatable(Action.new(0, 0, 0), Strategem)
    self.strategem_name = strategem_name
    self.target_index = target_index
    return self
end

function Strategem:can_perform()
    if player_util.get_current_strategem_count() > 0 then
        return true
    end
    return false
end

function Strategem:perform()
    if self.target_index == nil then
        windower.chat.input('/%s':format(self.strategem_name))
    else
        local target = windower.ffxi.get_mob_by_index(self.target_index)
        if target then
            windower.chat.input('/'..self.strategem_name..' '..target.id)
        end
    end

    coroutine.sleep(1)

    self:complete(true)
end

function Strategem:get_strategem_name()
    return self.strategem_name
end

function Strategem:gettype()
    return "strategemaction"
end

function Strategem:getrawdata()
    local res = {}

    res.strategem = {}
    res.strategem.x = self.x
    res.strategem.y = self.y
    res.strategem.z = self.z
    res.strategem.command = self:get_command()

    return res
end

function Strategem:copy()
    return Strategem.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_strategem_name())
end

function Strategem:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_strategem_name() == action:get_strategem_name()
end

function Strategem:tostring()
    return "Strategem command: %s":format(self.command)
end

return Strategem
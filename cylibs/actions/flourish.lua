---------------------------
-- Action representing a flourish
-- @class module
-- @name Flourish

local JobAbility = require('cylibs/actions/job_ability')
local Flourish = setmetatable({}, {__index = JobAbility })
Flourish.__index = Flourish
Flourish.__class = "Flourish"

function Flourish.new(flourish_name, target_index)
    local self = setmetatable(JobAbility.new(0, 0, 0, flourish_name, target_index), Flourish)

    self.conditions:append(HasBuffsCondition.new(L{ "Finishing Move 1", "Finishing Move 2", "Finishing Move 3", "Finishing Move 4", "Finishing Move 5", "Finishing Move (6+)" }, 1))
    self.conditions:append(ValidTargetCondition.new())

    return self
end

function Flourish:destroy()
    JobAbility.destroy(self)
end

function Flourish:perform()
    if self.target_index == nil then
        windower.chat.input('/%s':format(self.job_ability_name))
    else
        local target = windower.ffxi.get_mob_by_index(self.target_index)
        if target then
            windower.chat.input('/'..self.job_ability_name..' '..target.id)
        end
    end

    self:complete(true)
end

function Flourish:gettype()
    return "flourishaction"
end

function Flourish:debug_string()
    return "Flourish: %s":format(self:get_job_ability_name())
end

return Flourish
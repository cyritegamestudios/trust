---------------------------
-- Action representing a Blood Pack: Ward
-- @class module
-- @name BloodPactWard

local JobAbilityCommand = require('cylibs/ui/input/chat/commands/job_ability')

local Action = require('cylibs/actions/action')
local BloodPactWard = setmetatable({}, {__index = Action })
BloodPactWard.__index = BloodPactWard

function BloodPactWard.new(x, y, z, blood_pact_name)
    local self = setmetatable(Action.new(x, y, z), BloodPactWard)
    self.blood_pact_name = blood_pact_name
    return self
end

function BloodPactWard:can_perform()
    local recast_id = res.job_abilities:with('en', "Blood Pact: Ward").recast_id
    if windower.ffxi.get_ability_recasts()[recast_id] == 0 then
        return true
    end
    return false
end

function BloodPactWard:perform()
    local target = windower.ffxi.get_player()

    local command = JobAbilityCommand.new(self.blood_pact_name, target.id)
    command:run(true)

    coroutine.sleep(5)

    self:complete(true)
end

function BloodPactWard:get_blood_pact_name()
    return self.blood_pact_name
end

function BloodPactWard:gettype()
    return "bloodpactwardaction"
end

function BloodPactWard:getrawdata()
    local res = {}

    res.bloodpactward = {}
    res.bloodpactward.x = self.x
    res.bloodpactward.y = self.y
    res.bloodpactward.z = self.z
    res.bloodpactward.blood_pact_name = self:get_blood_pact_name()

    return res
end

function BloodPactWard:getidentifier()
    return self.blood_pact_name
end

function BloodPactWard:copy()
    return BloodPactWard.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_blood_pact_name())
end

function BloodPactWard:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_blood_pact_name() == action:get_blood_pact_name()
end

function BloodPactWard:tostring()
    return self.blood_pact_name
end

return BloodPactWard
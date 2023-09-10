---------------------------
-- Action representing a blood pact rage.
-- @class module
-- @name BloodPactRage

require('coroutine')
require('vectors')
require('math')

local Action = require('cylibs/actions/action')
local BloodPactRage = setmetatable({}, {__index = Action })
BloodPactRage.__index = BloodPactRage

function BloodPactRage.new(x, y, z, blood_pact_name)
    local self = setmetatable(Action.new(x, y, z), BloodPactRage)
    self.blood_pact_name = blood_pact_name
    return self
end

function BloodPactRage:can_perform()
    local recast_id = res.job_abilities:with('en', "Blood Pact: Rage").recast_id
    if windower.ffxi.get_ability_recasts()[recast_id] == 0 then
        return true
    end
    return false
end

function BloodPactRage:perform()
    windower.chat.input('/%s <bt>':format(self.blood_pact_name))

    coroutine.sleep(2)

    self:complete(true)
end

function BloodPactRage:get_blood_pact_name()
    return self.blood_pact_name
end

function BloodPactRage:gettype()
    return "bloodpactrageaction"
end

function BloodPactRage:getrawdata()
    local res = {}

    res.bloodpactrage = {}
    res.bloodpactrage.x = self.x
    res.bloodpactrage.y = self.y
    res.bloodpactrage.z = self.z
    res.bloodpactrage.command = self:get_command()

    return res
end

function BloodPactRage:getidentifier()
    return self.blood_pact_name
end

function BloodPactRage:copy()
    return BloodPactRage.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_command())
end

function BloodPactRage:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_blood_pact_name() == action:get_blood_pact_name()
end

function BloodPactRage:tostring()
    return "BloodPactRage command: %s":format(self.command)
end

return BloodPactRage
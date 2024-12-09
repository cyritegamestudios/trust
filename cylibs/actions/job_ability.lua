---------------------------
-- Action representing a job ability
-- @class module
-- @name JobAbility

local Action = require('cylibs/actions/action')
local JobAbilityCommand = require('cylibs/ui/input/chat/commands/job_ability')
local JobAbility = setmetatable({}, {__index = Action })
JobAbility.__index = JobAbility
JobAbility.__eq = JobAbility.is_equal
JobAbility.__class = "JobAbility"

function JobAbility.new(x, y, z, job_ability_name, target_index)
    local conditions = L{
        NotCondition.new(L{InMogHouseCondition.new()}),
        NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'amnesia','Invisible'}, 1)}, windower.ffxi.get_player().index),
        JobAbilityRecastReadyCondition.new(job_ability_name)
    }

    local self = setmetatable(Action.new(x, y, z, target_index, conditions), JobAbility)

    self.job_ability_name = job_ability_name
    self.debug_log_type = self:gettype()

    self:debug_log_create(self.debug_log_type)

    return self
end

function JobAbility:destroy()
    self:debug_log_destroy(self.debug_log_type)

    Action.destroy(self)
end

function JobAbility:perform()
    logger.notice(self.__class, 'perform', self.job_ability_name)

    local target = windower.ffxi.get_mob_by_index(self.target_index or windower.ffxi.get_player().index)

    local command = JobAbilityCommand.new(self.job_ability_name, target.id)
    command:run(true)

    --windower.chat.input(self:localize())

    coroutine.sleep(1)

    self:complete(true)
end

function JobAbility:localize()
    local job_ability = res.job_abilities[self.job_ability_name]
    local prefix = job_ability and job_ability.prefix or '/ja'
    local target_id

    if self.target_index then
        local target = windower.ffxi.get_mob_by_index(self.target_index)
        target_id = target.id
    end

    local job_ability = res.job_abilities:with('en', self.job_ability_name)
    if job_ability then
        local job_ability_name = job_ability.en
        if localization_util.should_use_client_locale() then
            job_ability_name = localization_util.encode(job_ability.name, windower.ffxi.get_info().language:lower())
        end
        if windower.ffxi.get_info().language:lower() == 'japanese' then
            if target_id == nil then
                return "%s %s <me>":format(prefix, job_ability_name)
            else
                return "%s %s ":format(prefix, job_ability_name)..target_id
            end
        else
            if target_id == nil then
                return '%s "%s" <me>':format(prefix, job_ability_name)
            else
                return '%s "%s" ':format(prefix, job_ability_name)..target_id
            end
        end
    end
    return ""
end

function JobAbility:get_job_ability_name()
    return self.job_ability_name
end

function JobAbility:gettype()
    return "jobabilityaction"
end

function JobAbility:getidentifier()
    return self.job_ability_name
end

function JobAbility:getrawdata()
    local res = {}

    res.jobability = {}
    res.jobability.x = self.x
    res.jobability.y = self.y
    res.jobability.z = self.z
    res.jobability.job_ability_name = self:get_job_ability_name()

    return res
end

function JobAbility:copy()
    return JobAbility.new(self:get_position()[1], self:get_position()[2], self:get_position()[3], self:get_job_ability_name())
end

function JobAbility:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self:get_job_ability_name() == action:get_job_ability_name()
end

function JobAbility:tostring()
    local target = windower.ffxi.get_mob_by_index(self.target_index or windower.ffxi.get_player().index)
    if target.name == windower.ffxi.get_player().name then
       return self:get_job_ability_name()
    end
    return i18n.resource('job_abilities', 'en', self:get_job_ability_name()) or self:get_job_ability_name()..' → '..target.name
end

function JobAbility:debug_string()
    return "JobAbility: %s":format(self:get_job_ability_name())
end

return JobAbility
---------------------------
-- Action representing a job ability
-- @class module
-- @name JobAbility

local Action = require('cylibs/actions/action')
local DisposeBag = require('cylibs/events/dispose_bag')
local IsStandingCondition = require('cylibs/conditions/is_standing')
local JobAbilityCommand = require('cylibs/ui/input/chat/commands/job_ability')
local JobAbility = setmetatable({}, {__index = Action })
JobAbility.__index = JobAbility
JobAbility.__eq = JobAbility.is_equal
JobAbility.__class = "JobAbility"
JobAbility.__type = "JobAbility"

function JobAbility.new(x, y, z, job_ability_name, target_index, conditions)
    local conditions = (conditions or L{}) + L{
        IsStandingCondition.new(0.5, ">="),
        NotCondition.new(L{ StatusCondition.new("Mount") }),
        NotCondition.new(L{InMogHouseCondition.new()}),
        JobAbilityRecastReadyCondition.new(job_ability_name),
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
    }

    local self = setmetatable(Action.new(x, y, z, target_index, conditions), JobAbility)

    self.job_ability_name = job_ability_name
    self.identifier = self.job_ability_name
    self.retry_count = 0
    self.dispose_bag = DisposeBag.new()
    self.debug_log_type = self:gettype()

    self:debug_log_create(self.debug_log_type)

    return self
end

function JobAbility:destroy()
    self:debug_log_destroy(self.debug_log_type)

    self.dispose_bag:destroy()

    Action.destroy(self)
end

function JobAbility:perform()
    logger.notice(self.__class, 'perform', self.job_ability_name)

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
        if action.actor_id ~= windower.ffxi.get_player().id then return end

        if S{ 6, 14 }:contains(action.category) then
            self:complete(true)
        end
    end), WindowerEvents.Action)

    self.dispose_bag:add(WindowerEvents.ActionMessage:addAction(function(actor_id, _, _, _, message_id, _, _, _)
        if actor_id ~= windower.ffxi.get_player().id then return end

        if L{ 87, 88 }:contains(message_id) then
            self.retry_count = self.retry_count + 1
            self:use_job_ability(self.retry_count)
        elseif L{ 523 }:contains(message_id) then
            self:complete(false)
        end
    end), WindowerEvents.ActionMessage)

    self:use_job_ability(self.retry_count)
end

function JobAbility:use_job_ability(retry_count)
    local target = windower.ffxi.get_mob_by_index(self.target_index or windower.ffxi.get_player().index)

    if target == nil or retry_count > 1 then
        self:complete(false)
        return
    end

    local command = JobAbilityCommand.new(self.job_ability_name, target.id)
    command:run(true)
end

function JobAbility:get_job_ability_name()
    return self.job_ability_name
end

function JobAbility:gettype()
    return "jobabilityaction"
end

function JobAbility:getidentifier()
    return self.identifier
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
    if target and target.name == windower.ffxi.get_player().name then
        return self:get_job_ability_name()
    end
    return i18n.resource('job_abilities', 'en', self:get_job_ability_name()) or self:get_job_ability_name()..' → '..(target.name or '')
end

function JobAbility:debug_string()
    return "JobAbility: %s":format(self:get_job_ability_name())
end

return JobAbility
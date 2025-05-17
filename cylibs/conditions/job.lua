---------------------------
-- Condition checking whether the target's main job is any of the given jobs.
-- @class module
-- @name JobCondition
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local list_ext = require('cylibs/util/extensions/lists')
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local JobCondition = setmetatable({}, { __index = Condition })
JobCondition.__index = JobCondition
JobCondition.__type = "JobCondition"
JobCondition.__class = "JobCondition"

function JobCondition.new(job_name_shorts)
    local self = setmetatable(Condition.new(), JobCondition)
    self.job_name_shorts = job_name_shorts or job_util.all_jobs()
    return self
end

function JobCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party_member = player.party:get_party_member(target.id)
        if party_member then
            return self.job_name_shorts:contains(party_member:get_main_job_short())
        end
    end
    return false
end

function JobCondition:get_config_items()
    local all_job_name_shorts = L{}
    for i = 1, 22 do
        all_job_name_shorts:append(res.jobs[i].ens)
    end
    local jobPickerConfigItem = MultiPickerConfigItem.new('job_name_shorts', self.job_name_shorts, all_job_name_shorts, function(job_names)
        return localization_util.commas(job_names:map(function(job_name_short) return i18n.resource('jobs', 'ens', job_name_short) end), 'or')
    end, "Target's Job")
    jobPickerConfigItem:setPickerTitle("Jobs")
    jobPickerConfigItem:setPickerDescription("Choose one or more jobs.")
    jobPickerConfigItem:setPickerTextFormat(function(job_name_short)
        return i18n.resource('jobs', 'ens', job_name_short)
    end)
    return L{
        jobPickerConfigItem
    }
end

function JobCondition:tostring()
    if self.job_name_shorts:equals(job_util.all_jobs()) then
        return "Target job is any job"
    else
        if self.job_name_shorts:length() > 15 then
            local excluded_job_name_shorts = list.diff(self.job_name_shorts, job_util.all_jobs())
            return "Target is any job except "..localization_util.commas(excluded_job_name_shorts:map(function(job_name_short)
                return i18n.resource('jobs', 'ens', job_name_short)
            end), 'or')
        end
        return "Target job is "..localization_util.commas(self.job_name_shorts:map(function(job_name_short)
            return i18n.resource('jobs', 'ens', job_name_short)
        end), 'or')
    end
end

function JobCondition.description()
    return "Target job is any of X."
end

function JobCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function JobCondition:serialize()
    return "JobCondition.new(" .. serializer_util.serialize_args(self.job_name_shorts) .. ")"
end

return JobCondition





---------------------------
-- Condition checking whether the player has a specific main job.
-- @class module
-- @name PartyHasMainJobCondition
local serializer_util = require('cylibs/util/serializer_util')
local party_util = require('cylibs/util/party_util')

local Condition = require('cylibs/conditions/condition')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PartyHasMainJobCondition = setmetatable({}, { __index = Condition })
PartyHasMainJobCondition.__index = PartyHasMainJobCondition
PartyHasMainJobCondition.__type = "PartyHasMainJobCondition"
PartyHasMainJobCondition.__class = "PartyHasMainJobCondition"

function PartyHasMainJobCondition.new(job_name_shorts)
    local self = setmetatable(Condition.new(), PartyHasMainJobCondition)
    -- self.job_name_short = job_name_short or res.jobs[windower.ffxi.get_player().main_job_id].ens
    self.job_name_shorts = job_name_shorts or job_util.all_jobs()
    return self
end

function PartyHasMainJobCondition:is_satisfied(target_index)
    local party = player.party
    if party then
        for party_member in party:get_party_members(true):it() do
            if party_member:get_main_job_short() == self.job_name_shorts then
                return true
            end
        end
    end
    return false
end

function PartyHasMainJobCondition:get_config_items()
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

function PartyHasMainJobCondition:tostring()
    if self.job_name_shorts:equals(job_util.all_jobs()) then
        return "Party has any main job"
    else
        if self.job_name_shorts:length() > 15 then
            local excluded_job_name_shorts = list.diff(self.job_name_shorts, job_util.all_jobs())
            return "Party has any main job except "..localization_util.commas(excluded_job_name_shorts:map(function(job_name_short)
                return i18n.resource('jobs', 'ens', job_name_short)
            end), 'or')
        end
        return "Party has main job "..localization_util.commas(self.job_name_shorts:map(function(job_name_short)
            return i18n.resource('jobs', 'ens', job_name_short)
        end), 'or')
    end
end

function PartyHasMainJobCondition.description()
    return "Party has any main job of X."
end

function PartyHasMainJobCondition.valid_targets()
    return S{ Condition.TargetType.Ally, Condition.TargetType.Self }
end

function PartyHasMainJobCondition:serialize()
    return "PartyHasMainJobCondition.new(" .. serializer_util.serialize_args(self.job_name_shorts) .. ")"
end

return PartyHasMainJobCondition





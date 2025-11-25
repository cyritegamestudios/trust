---------------------------
-- Condition checking whether the player has a specific sub job.
-- @class module
-- @name SubJobCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SubJobCondition = setmetatable({}, { __index = Condition })
SubJobCondition.__index = SubJobCondition
SubJobCondition.__type = "SubJobCondition"
SubJobCondition.__class = "SubJobCondition"

function SubJobCondition.new(job_name_short)
    local self = setmetatable(Condition.new(), SubJobCondition)
    self.job_name_short = job_name_short or res.jobs[windower.ffxi.get_player().sub_job_id].ens
    return self
end

function SubJobCondition:is_satisfied(target_index)
    local target = windower.ffxi.get_mob_by_index(target_index)
    if target then
        local party = player.party
        if party then
            local party_member = party:get_party_member(target.id)
            if party_member then
                return party_member:get_sub_job_short() == self.job_name_short
            end
        end
    end
    return false
end

function SubJobCondition:get_config_items()
    local all_job_name_shorts = L{}
    for i = 1, 22 do
        all_job_name_shorts:append(res.jobs[i].ens)
    end
    return L{
        PickerConfigItem.new('job_name_short', self.job_name_short, all_job_name_shorts, function(job_name_short)
            return i18n.resource('jobs', 'ens', job_name_short)
        end, "Sub Job")
    }
end

function SubJobCondition:tostring()
    return "Sub job is "..res.jobs:with('ens', self.job_name_short).en
end

function SubJobCondition.description()
    return "Sub job is X."
end

function SubJobCondition.valid_targets()
    return S{ Condition.TargetType.Self, Condition.TargetType.Ally }
end

function SubJobCondition:serialize()
    return "SubJobCondition.new(" .. serializer_util.serialize_args(self.job_name_short) .. ")"
end

return SubJobCondition





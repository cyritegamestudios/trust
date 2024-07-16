---------------------------
-- Condition checking whether the player's main job is equal to job_id.
-- @class module
-- @name MainJobCondition
local serializer_util = require('cylibs/util/serializer_util')

local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local MainJobCondition = setmetatable({}, { __index = Condition })
MainJobCondition.__index = MainJobCondition
MainJobCondition.__type = "MainJobCondition"
MainJobCondition.__class = "MainJobCondition"

function MainJobCondition.new(job_name_short)
    local self = setmetatable(Condition.new(), MainJobCondition)
    self.job_name_short = job_name_short or res.jobs[windower.ffxi.get_player().main_job_id].ens
    return self
end

function MainJobCondition:is_satisfied(target_index)
    local main_job_id = windower.ffxi.get_player().main_job_id
    return res.jobs[main_job_id].ens == self.job_name_short
end

function MainJobCondition:get_config_items()
    local all_job_name_shorts = L{}
    for i = 1, 22 do
        all_job_name_shorts:append(res.jobs[i].ens)
    end
    return L{
        PickerConfigItem.new('job_name_short', self.job_name_short, all_job_name_shorts, function(job_name_short)
            return res.jobs:with('ens', job_name_short).en
        end, "Main Job")
    }
end

function MainJobCondition:tostring()
    return "Main job is "..res.jobs:with('ens', self.job_name_short).en
end

function MainJobCondition:serialize()
    return "MainJobCondition.new(" .. serializer_util.serialize_args(self.job_name_short) .. ")"
end

return MainJobCondition




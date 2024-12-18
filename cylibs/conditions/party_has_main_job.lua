---------------------------
-- Condition checking whether the player has a specific main job.
-- @class module
-- @name PartyHasMainJobCondition
local serializer_util = require('cylibs/util/serializer_util')
local party_util = require('cylibs/util/party_util')

local Condition = require('cylibs/conditions/condition')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local PartyHasMainJobCondition = setmetatable({}, { __index = Condition })
PartyHasMainJobCondition.__index = PartyHasMainJobCondition
PartyHasMainJobCondition.__type = "PartyHasMainJobCondition"
PartyHasMainJobCondition.__class = "PartyHasMainJobCondition"

function PartyHasMainJobCondition.new(job_name_short)
    local self = setmetatable(Condition.new(), PartyHasMainJobCondition)
    self.job_name_short = job_name_short or res.jobs[windower.ffxi.get_player().main_job_id].ens
    return self
end

function PartyHasMainJobCondition:is_satisfied(target_index)
    local party = player.party
    if party then
        for party_member in party:get_party_members(true):it() do
            if party_member:get_main_job_short() == self.job_name_short then
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
    return L{
        PickerConfigItem.new('job_name_short', self.job_name_short, all_job_name_shorts, function(job_name_short)
            return i18n.resource('jobs', 'ens', job_name_short)
        end, "Main Job")
    }
end

function PartyHasMainJobCondition:tostring()
    return "Party contains player with main job "..i18n.resource('jobs', 'ens', self.job_name_short)
end

function PartyHasMainJobCondition.description()
    return "Party contains player with main job X."
end

function PartyHasMainJobCondition.valid_targets()
    return S{ Condition.TargetType.Ally }
end

function PartyHasMainJobCondition:serialize()
    return "PartyHasMainJobCondition.new(" .. serializer_util.serialize_args(self.job_name_short) .. ")"
end

return PartyHasMainJobCondition





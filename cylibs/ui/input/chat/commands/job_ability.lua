local GameCommand = require('cylibs/ui/input/chat/commands/game_command')

local JobAbilityCommand = setmetatable({}, {__index = GameCommand })
JobAbilityCommand.__index = JobAbilityCommand
JobAbilityCommand.__type = "JobAbilityCommand"

function JobAbilityCommand.new(jobAbilityName, targetId)
    local jobAbility = res.job_abilities:with('en', jobAbilityName)

    local self = setmetatable(GameCommand.new(jobAbility.prefix, targetId), JobAbilityCommand)

    self.jobAbilityId = jobAbility.id
    self.jobAbilityName = jobAbilityName

    return self
end

function JobAbilityCommand:run(sendInChat)
    local targetId, targetIndex = self:getTargetInfo()
    if targetId == nil or targetIndex == nil then
        return
    end
    if not sendInChat then
        local packets = require('packets')

        local p = packets.new('outgoing', 0x01A)

        p['Target'] = targetId
        p['Target Index'] = targetIndex
        p['Category'] = 0x09
        p['Param'] = self.jobAbilityId
        p['X Offset'] = 0
        p['Z Offset'] = 0
        p['Y Offset'] = 0

        packets.inject(p)
    else
        local jobAbility = res.job_abilities:with('en', self.jobAbilityName)

        local inputText = self:getInputText(jobAbility.prefix, i18n.resource('job_abilities', 'en', self.jobAbilityName, i18n.current_gearswap_locale()), targetId)
        windower.chat.input(inputText)
    end
end

return JobAbilityCommand
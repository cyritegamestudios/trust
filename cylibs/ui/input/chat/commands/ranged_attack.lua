local GameCommand = require('cylibs/ui/input/chat/commands/game_command')

local RangedAttackCommand = setmetatable({}, {__index = GameCommand })
RangedAttackCommand.__index = RangedAttackCommand
RangedAttackCommand.__type = "RangedAttackCommand"

function RangedAttackCommand.new(prefix, targetId)
    local self = setmetatable(GameCommand.new(prefix or '/ra', targetId), RangedAttackCommand)
    return self
end

function RangedAttackCommand:run(sendInChat)
    local targetId, targetIndex = self:getTargetInfo()
    if targetId == nil or targetIndex == nil then
        return
    end
    if not sendInChat then
        local packets = require('packets')

        local p = packets.new('outgoing', 0x01A)

        p['Target'] = targetId
        p['Target Index'] = targetIndex
        p['Category'] = 16
        p['Param'] = 0
        p['X Offset'] = 0
        p['Z Offset'] = 0
        p['Y Offset'] = 0

        packets.inject(p)
    else
        local inputText = self:getInputText(self.prefix, nil, targetId)
        windower.chat.input(inputText)
    end
end

return RangedAttackCommand
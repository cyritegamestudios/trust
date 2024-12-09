local GameCommand = require('cylibs/ui/input/chat/commands/game_command')

local UseItemCommand = setmetatable({}, {__index = GameCommand })
UseItemCommand.__index = UseItemCommand
UseItemCommand.__type = "UseItemCommand"

function UseItemCommand.new(itemName, targetId)
    local self = setmetatable(GameCommand.new('/item', targetId), UseItemCommand)
    self.itemName = itemName
    return self
end

function UseItemCommand:run(sendInChat)
    local targetId, targetIndex = self:getTargetInfo()
    if targetId == nil or targetIndex == nil then
        return
    end
    if not sendInChat then
        --[[local packets = require('packets')

        local p = packets.new('outgoing', 0x01A)

        p['Target'] = targetId
        p['Target Index'] = targetIndex
        p['Category'] = 0x09
        p['Param'] = self.jobAbilityId
        p['X Offset'] = 0
        p['Z Offset'] = 0
        p['Y Offset'] = 0

        packets.inject(p)]]
    else
        local inputText
        if i18n.current_locale() == i18n.Locale.Japanese then
            inputText = windower.to_shift_jis(string.format("/item %s <me>", self.itemName))
        else
            inputText = string.format("/item \"%s\" <me>", self.itemName)
        end
        windower.chat.input(inputText)
    end
end

return UseItemCommand
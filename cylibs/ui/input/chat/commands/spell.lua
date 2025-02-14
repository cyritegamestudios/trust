local GameCommand = require('cylibs/ui/input/chat/commands/game_command')

local SpellCommand = setmetatable({}, {__index = GameCommand })
SpellCommand.__index = SpellCommand
SpellCommand.__type = "SpellCommand"

function SpellCommand.new(spellName, targetId)
    local spell = res.spells:with('en', spellName)

    local self = setmetatable(GameCommand.new(spell.prefix, targetId), SpellCommand)
    self.spellId = spell.id
    self.spellName = spellName
    return self
end

function SpellCommand:run(sendInChat)
    local targetId, targetIndex = self:getTargetInfo()
    if targetId == nil or targetIndex == nil then
        return
    end
    if not sendInChat then
        local packets = require('packets')

        local p = packets.new('outgoing', 0x01A)

        p['Target'] = targetId
        p['Target Index'] = targetIndex
        p['Category'] = 0x03
        p['Param'] = self.spellId
        p['X Offset'] = 0
        p['Z Offset'] = 0
        p['Y Offset'] = 0

        packets.inject(p)
    else
        local spell = res.spells:with('en', self.spellName)

        local inputText = self:getInputText(spell.prefix, i18n.resource('spells', 'en', self.spellName), targetId)
        windower.chat.input(inputText)
    end
end

return SpellCommand
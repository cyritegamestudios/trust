local GameCommand = require('cylibs/ui/input/chat/commands/game_command')

local WeaponSkillCommand = setmetatable({}, {__index = GameCommand })
WeaponSkillCommand.__index = WeaponSkillCommand
WeaponSkillCommand.__type = "WeaponSkillCommand"

function WeaponSkillCommand.new(weaponSkillName, targetId)
    local weaponSkill = res.weapon_skills:with('en', weaponSkillName)

    local self = setmetatable(GameCommand.new(weaponSkill.prefix, targetId), WeaponSkillCommand)

    self.weaponSkillId = weaponSkill.id
    self.weaponSkillName = weaponSkillName

    return self
end

function WeaponSkillCommand:run(sendInChat)
    local targetId, targetIndex = self:getTargetInfo()
    if targetId == nil or targetIndex == nil then
        return
    end
    if not sendInChat then
        local packets = require('packets')

        local p = packets.new('outgoing', 0x01A)

        p['Target'] = targetId
        p['Target Index'] = targetIndex
        p['Category'] = 0x07
        p['Param'] = self.weaponSkillId
        p['X Offset'] = 0
        p['Z Offset'] = 0
        p['Y Offset'] = 0

        packets.inject(p)
    else
        local weaponSkill = res.weapon_skills:with('en', self.weaponSkillName)

        local inputText = self:getInputText(weaponSkill.prefix, i18n.resource('weapon_skills', 'en', self.weaponSkillName), targetId)
        windower.chat.input(inputText)
    end
end

return WeaponSkillCommand
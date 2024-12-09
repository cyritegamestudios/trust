local JobAbilityCommand = require('cylibs/ui/input/chat/commands/job_ability')
local SpellCommand = require('cylibs/ui/input/chat/commands/spell')
local WeaponSkillCommand = require('cylibs/ui/input/chat/commands/weapon_skill')

local ChatInput = {}
ChatInput.__index = ChatInput
ChatInput.__type = "ChatInput"
ChatInput.__class = "ChatInput"

function ChatInput.new()
    local self = setmetatable({}, ChatInput)

    self.handlers = {}
    self.hasShownWarning = false

    local buildRegex = function(prefix)
        return "("..prefix..") (\"?["..i18n.get_regex_character_set()..":%p%s]+\"?) (%d+)"
    end

    self:registerHandler(L{ buildRegex("/ma"), buildRegex("/magic") }, function(inputText, regex)
        local _, spellName, targetId = string.match(inputText, regex)

        local command = SpellCommand.new(spellName:gsub("\"", ""), targetId)
        command:run()
    end)

    self:registerHandler(L{ buildRegex("/ja"), buildRegex("/jobability") }, function(inputText, regex)
        local _, jobAbilityName, targetId = string.match(inputText, regex)

        local command = JobAbilityCommand.new(jobAbilityName:gsub("\"", ""), targetId)
        command:run()
    end)

    self:registerHandler(L{ buildRegex("/ws"), buildRegex("/weaponskill") }, function(inputText, regex)
        local _, weaponSkillName, targetId = string.match(inputText, regex)

        local command = WeaponSkillCommand.new(weaponSkillName:gsub("\"", ""), targetId)
        command:run()
    end)

    self.events = windower.register_event('outgoing text',function(original, modified, blocked, ffxi, extra_stuff, extra2)
        if blocked then
            return
        end
        for regex, handler in pairs(self.handlers) do
            local matches = string.match(original, regex)
            if matches and matches:length() > 0 then
                handler(original, regex)
                if not self.hasShownWarning then
                    self.hasShownWarning = true
                    addon_system_error("---== WARNING ==---- GearSwap is not loaded.")
                end
                return true
            end
        end
        return false
    end)

    return self
end

function ChatInput:destroy()
    self.handlers = {}
end

function ChatInput:registerHandler(regexes, handler)
    for regex in regexes:it() do
        self.handlers[regex] = handler
    end
end

return ChatInput
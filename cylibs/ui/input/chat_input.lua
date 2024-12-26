local JobAbilityCommand = require('cylibs/ui/input/chat/commands/job_ability')
local RangedAttackCommand = require('cylibs/ui/input/chat/commands/ranged_attack')
local SpellCommand = require('cylibs/ui/input/chat/commands/spell')
local WeaponSkillCommand = require('cylibs/ui/input/chat/commands/weapon_skill')

local ChatInput = {}
ChatInput.__index = ChatInput
ChatInput.__type = "ChatInput"
ChatInput.__class = "ChatInput"

function ChatInput.new(trustSettings, trustSettingsMode)
    local self = setmetatable({}, ChatInput)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.events = {}
    self.handlers = {}
    self.hasShownWarning = false

    local buildRegex = function(prefix, skip_ability)
        if skip_ability then
            return "("..prefix..") (%d+)"
        else
            return "("..prefix..") (\"?["..i18n.get_regex_character_set()..":%p%s]+\"?) (%d+)"
        end
    end

    self:registerHandler(L{ buildRegex("/song"), buildRegex("/ma"), buildRegex("/magic"), buildRegex("/ninjutsu") }, function(inputText, regex)
        local _, spellName, targetId = string.match(inputText, regex)

        local command = SpellCommand.new(spellName:gsub("\"", ""), targetId)
        command:run()
    end)

    self:registerHandler(L{ buildRegex("/ja"), buildRegex("/jobability"), buildRegex("/pet") }, function(inputText, regex)
        local _, jobAbilityName, targetId = string.match(inputText, regex)

        local command = JobAbilityCommand.new(jobAbilityName:gsub("\"", ""), targetId)
        command:run()
    end)

    self:registerHandler(L{ buildRegex("/ws"), buildRegex("/weaponskill") }, function(inputText, regex)
        local _, weaponSkillName, targetId = string.match(inputText, regex)

        local command = WeaponSkillCommand.new(weaponSkillName:gsub("\"", ""), targetId)
        command:run()
    end)

    self:registerHandler(L{ buildRegex("/ra", true), buildRegex("/rangedattack", true), buildRegex("/shoot", true) }, function(inputText, regex)
        local prefix, targetId = string.match(inputText, regex)

        local command = RangedAttackCommand.new(prefix, targetId)
        command:run()
    end)

    self.events.incoming_text = windower.register_event('incoming text', function(original, modified)
        if not original:startswith(">> ") then
            return
        end
        local command = original:slice(4)
        for regex, _ in pairs(self.handlers) do
            local matches = string.match(command, regex)
            if matches and matches:length() > 0 then
                addon_system_error("---== WARNING ==---- GearSwap not detected. To use Trust without GearSwap, set Is GearSwap Enabled to OFF under Config > GearSwap.")
                return false
            end
        end
        return false
    end)

    self.events.outgoing_text = windower.register_event('outgoing text',function(original, modified, blocked, ffxi, extra_stuff, extra2)
        -- ffxi = 1 (came from chat), ffxi = 3 (came from upstream addon)
        if blocked or ffxi ~= 1 then
            return
        end

        local gearSwapSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].GearSwapSettings
        if gearSwapSettings.Enabled then
            return
        end

        for regex, handler in pairs(self.handlers) do
            local matches = string.match(original, regex)
            if matches and matches:length() > 0 then
                handler(original, regex)
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
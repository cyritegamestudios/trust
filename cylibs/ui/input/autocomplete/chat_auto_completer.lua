local CommandTrie = require('cylibs/ui/input/autocomplete/command_trie')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local Keyboard = require('cylibs/ui/input/keyboard')

local ChatAutoCompleter = {}
ChatAutoCompleter.__index = ChatAutoCompleter

function ChatAutoCompleter:onAutoCompleteListChange()
    return self.autoCompleteListChange
end

function ChatAutoCompleter.new(commands)
    local self = setmetatable({}, ChatAutoCompleter)

    self.allCommands = commands
    self.commandTrie = CommandTrie.new()
    for command in commands:it() do
        self.commandTrie:addCommand(command)
    end

    self.disposeBag = DisposeBag.new()

    self.disposeBag:add(Keyboard.input():on_key_pressed():addAction(function(key, pressed, flags, blocked)
        self:onKeyboardEvent(key, pressed, flags, blocked)
    end), Keyboard.input():on_key_pressed())

    self.disposeBag:addAny(L{ self.commandTrie })

    self.autoCompleteListChange = Event.newEvent()

    return self
end

function ChatAutoCompleter:destroy()
    self.disposeBag:destroy()

    self.autoCompleteListChange:removeAllActions()
end

function ChatAutoCompleter:getAllCommands()
    return self.allCommands
end

function ChatAutoCompleter:onKeyboardEvent(key, pressed, flags, blocked)
    if windower.ffxi.get_info().chat_open then
        if not pressed then
            local chatText = windower.chat.get_input()
            if chatText and chatText:contains("// trust") then
                local result = self.commandTrie:getCommands(chatText)
                self:onAutoCompleteListChange():trigger(self, result)
            else
                self:onAutoCompleteListChange():trigger(self, L{})
            end
        end
    else
        self:onAutoCompleteListChange():trigger(self, L{})
    end
end

return ChatAutoCompleter

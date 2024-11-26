local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Keyboard = require('cylibs/ui/input/keyboard')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local CommandWidget = setmetatable({}, {__index = FFXIPickerView })
CommandWidget.__index = CommandWidget


function CommandWidget.new()
    local configItem = MultiPickerConfigItem.new("Commands", L{}, L{})

    local self = setmetatable(FFXIPickerView.new(L{ configItem }, true, FFXIClassicStyle.WindowSize.Picker.Wide), CommandWidget)

    self.disposeBag = DisposeBag.new()
    self.keybindDisposeBag = DisposeBag.new()

    self.disposeBag:add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            windower.chat.set_input("// trust "..item:getText())
            coroutine.schedule(function()
                self:resignFocus()
            end, 0.1)
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    return self
end

function CommandWidget:setVisible(visible)
    FFXIPickerView.setVisible(self, visible)

    local keys = L{ '^up' }
    for key in keys:it() do
        if visible then
            windower.send_command('bind %s block':format(key))
        else
            windower.send_command('unbind %s':format(key))
        end
    end

    if not visible then
        self.keybindDisposeBag:dispose()
        if self:hasFocus() then
            self:resignFocus()
        end
    else
        self.keybindDisposeBag:add(Keyboard.input():on_key_pressed():addAction(function(key, pressed, flags, blocked)
            if not self:isVisible() then
                return
            end
            key = Keyboard.input():getKey(key)
            if key == 'Escape' then
                if self:hasFocus() then
                    self:resignFocus()
                end
            elseif key == 'Up' then
                if flags == 36 and not self:hasFocus() then
                    self:requestFocus()
                end
            end
        end), Keyboard.input():on_key_pressed())
    end
end

function CommandWidget:setHasFocus(hasFocus)
    FFXIPickerView.setHasFocus(self, hasFocus)

    local keys = L{ 'escape', 'enter'}
    for key in keys:it() do
        if hasFocus then
            windower.send_command('bind %s block':format(key))
        else
            windower.send_command('unbind %s':format(key))
        end
    end
end

return CommandWidget
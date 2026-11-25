local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Keyboard = require('cylibs/ui/input/keyboard')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerView = require('cylibs/ui/picker/picker_view')

local CommandWidget = setmetatable({}, {__index = FFXIPickerView })
CommandWidget.__index = CommandWidget


function CommandWidget.new()
    local configItem = MultiPickerConfigItem.new("Commands", L{}, L{})

    local self = setmetatable(FFXIPickerView.new(L{ configItem }, true, FFXIClassicStyle.WindowSize.Picker.Wide), CommandWidget)

    -- NOTE: do NOT replace self.disposeBag here. The parent chain
    -- (CollectionView/PickerView/FFXIPickerView) already registered the
    -- delegate, data source, layout, content view and several actions in
    -- the bag View.new created; replacing it orphans those registrations,
    -- so the delegate/data source are never destroyed and their actions
    -- (including the didHighlight action load_trust_commands registers)
    -- survive destroy(). The bag View.new made is the one to use.
    self.keybindDisposeBag = DisposeBag.new()

    self.disposeBag:add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            windower.chat.set_input("// trust "..item:getText())
            coroutine.schedule(function()
                if self.is_destroyed then
                    return
                end
                self:resignFocus()
            end, 0.1)
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    return self
end

function CommandWidget:destroy()
    -- View.destroy (via PickerView) sets `destroyed`, not `is_destroyed`,
    -- but the select coroutine above guards on `is_destroyed` -- set it
    -- here so a command picked just before unload cannot resignFocus a
    -- destroyed picker.
    self.is_destroyed = true
    -- View.destroy (via PickerView) handles the picker prims and the main
    -- dispose bag, but keybindDisposeBag is a separate bag that is only
    -- disposed when the widget is hidden — destroy it here so the keyboard
    -- handler cannot survive an unload while the widget is visible.
    self.keybindDisposeBag:destroy()
    PickerView.destroy(self)
end

function CommandWidget:setVisible(visible)
    local was_visible = self:isVisible()
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
        if not was_visible then
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
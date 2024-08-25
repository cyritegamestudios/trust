local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
local JobSettingsView = require('ui/settings/JobSettingsView')
local MenuItem = require('cylibs/ui/menu/menu_item')

local JobSettingsMenuItem = setmetatable({}, {__index = MenuItem })
JobSettingsMenuItem.__index = JobSettingsMenuItem

function JobSettingsMenuItem.new(jobSettingsMode, jobSettings, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Save As', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Backup', 18),
        ButtonItem.default('Reset', 18),
    }, {}, function(args)
        local loadSettingsView = JobSettingsView.new(jobSettingsMode, jobSettings)
        loadSettingsView:setShouldRequestFocus(true)
        return loadSettingsView
    end, "Settings", "Load saved modes and job settings."), JobSettingsMenuItem)

    self.jobSettingsMode = jobSettingsMode
    self.jobSettings = jobSettings
    self.viewFactory = viewFactory
    self.disposeBag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function JobSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()

    self.viewFactory = nil
end

function JobSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Save As", self:getCreateSetMenuItem())
    self:setChildMenuItem("Edit", self:getEditMenuItem())
    self:setChildMenuItem("Backup", self:getBackupMenuItem())
    self:setChildMenuItem("Reset", self:getResetMenuItem())
end

function JobSettingsMenuItem:getEditMenuItem()
    local editMenuItem = MenuItem.new(L{
        ButtonItem.default('Delete', 18),
    }, L{}, nil, "Settings", "Edit saved sets.", true)
    return editMenuItem
end

function JobSettingsMenuItem:getCreateSetMenuItem()
    local createSetMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(_)
        local createSetView = FFXITextInputView.new('Set', 'Job settings set name')
        createSetView:setTitle("Choose a name for the job settings set.")
        createSetView:setShouldRequestFocus(true)
        createSetView:onTextChanged():addAction(function(_, newSetName)
            if newSetName:length() > 1 then
                self.jobSettings:createSettings(newSetName)

                self.jobSettingsMode:set(newSetName)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll remember what to do for "..newSetName.." now!")
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."That name is too short, pick something else?")
            end
        end)
        return createSetView
    end, "Settings", "Save a new job settings set.")
    return createSetMenuItem
end

function JobSettingsMenuItem:getBackupMenuItem()
    return MenuItem.action(function()
        self.jobSettings:backupSettings()
    end, "Settings", "Backup job settings file.")
end

function JobSettingsMenuItem:getResetMenuItem()
    local resetMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
    }, {
        Confirm = MenuItem.action(function()
            local defaultSettings = T(self.jobSettings:getDefaultSettings()):clone().Default

            self.jobSettings:getSettings()[self.jobSettingsMode.value] = defaultSettings
            self.jobSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..") Alright, I've reset "..self.jobSettingsMode.value.." to the default job settings!")
        end, "Settings", "Reset to default job settings. WARNING: your settings will be overriden.")
    }, nil, "Settings", "Reset to default job settings. WARNING: your settings will be overriden.", true)
    return resetMenuItem
end

return JobSettingsMenuItem
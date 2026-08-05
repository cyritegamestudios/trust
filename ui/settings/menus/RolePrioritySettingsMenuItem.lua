local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local Role = require('cylibs/trust/roles/role')

local RolePrioritySettingsMenuItem = setmetatable({}, {__index = MenuItem })
RolePrioritySettingsMenuItem.__index = RolePrioritySettingsMenuItem

function RolePrioritySettingsMenuItem.new(trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Move Up', 18),
        ButtonItem.default('Move Down', 18),
        ButtonItem.default('Reset', 18),
    }, {}, nil, 'Priorities', 'Choose the order in which Trust roles are prioritized.'), RolePrioritySettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.priorityEditor = nil

    self:setChildMenuItem('Move Up', self:getMoveUpMenuItem())
    self:setChildMenuItem('Move Down', self:getMoveDownMenuItem())
    self:setChildMenuItem('Reset', self:getResetMenuItem())

    self.contentViewConstructor = function()
        local configItem = MultiPickerConfigItem.new('Priorities', L{}, self:getPriorities(), function(roleName)
            return Role.get_display_name_for_type(roleName)
        end)

        self.priorityEditor = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditor)
        self.priorityEditor:setAllowsCursorSelection(true)

        return self.priorityEditor
    end

    return self
end

function RolePrioritySettingsMenuItem:destroy()
    MenuItem.destroy(self)
    self.priorityEditor = nil
end

function RolePrioritySettingsMenuItem:getRoleSettings()
    local settings = self.trustSettings:getSettings()[self.trustSettingsMode.value]
    settings.RoleSettings = settings.RoleSettings or {}
    settings.RoleSettings.Priority = settings.RoleSettings.Priority or L{}
    return settings.RoleSettings
end

function RolePrioritySettingsMenuItem:getPriorities()
    return self:getRoleSettings().Priority
end

function RolePrioritySettingsMenuItem:canMove(offset)
    if not self.priorityEditor then return false end

    local selectedIndexPath = self.priorityEditor:getDelegate():getCursorIndexPath()
    if not selectedIndexPath then return false end

    local newRow = selectedIndexPath.row + offset
    return newRow >= 1 and newRow <= self:getPriorities():length()
end

function RolePrioritySettingsMenuItem:movePriority(offset)
    if not self:canMove(offset) then return end

    local selectedIndexPath = self.priorityEditor:getDelegate():getCursorIndexPath()
    local newIndexPath = IndexPath.new(selectedIndexPath.section, selectedIndexPath.row + offset)
    local item1 = self.priorityEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
    local item2 = self.priorityEditor:getDataSource():itemAtIndexPath(newIndexPath)
    if not item1 or not item2 then return end

    local priorities = self:getPriorities()
    priorities[selectedIndexPath.row], priorities[newIndexPath.row] = priorities[newIndexPath.row], priorities[selectedIndexPath.row]
    self.priorityEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
    self.priorityEditor:getDelegate():selectItemAtIndexPath(newIndexPath)
    self.trustSettings:saveSettings(true)
end

function RolePrioritySettingsMenuItem:getMoveUpMenuItem()
    return MenuItem.action(function()
        self:movePriority(-1)
    end, 'Priorities', 'Move the selected role up in priority.', false, function()
        return self:canMove(-1)
    end)
end

function RolePrioritySettingsMenuItem:getMoveDownMenuItem()
    return MenuItem.action(function()
        self:movePriority(1)
    end, 'Priorities', 'Move the selected role down in priority.', false, function()
        return self:canMove(1)
    end)
end

function RolePrioritySettingsMenuItem:getResetMenuItem()
    return MenuItem.action(function(menu)
        local defaultSettings = T(self.trustSettings:getDefaultSettings().Default):clone()
        if defaultSettings.RoleSettings and defaultSettings.RoleSettings.Priority then
            self:getRoleSettings().Priority = defaultSettings.RoleSettings.Priority
            self.trustSettings:saveSettings(true)
            menu:showMenu(self)
        end
    end, 'Priorities', 'Reset role priorities to their default order.')
end

return RolePrioritySettingsMenuItem

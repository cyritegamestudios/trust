local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local FileIO = require('files')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local PathSettingsMenuItem = setmetatable({}, {__index = MenuItem })
PathSettingsMenuItem.__index = PathSettingsMenuItem

function PathSettingsMenuItem.new(pather, follower)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Replay', 18),
        ButtonItem.default('Stop', 18),
        ButtonItem.default('Record', 18),
        ButtonItem.default('Edit', 18),
    }, {}, nil, "Paths", "Start, stop or record a new path."), PathSettingsMenuItem)

    self.pather = pather
    self.follower = follower
    self.path_recorder = self.pather:get_path_recorder()
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_)
        local configItem = MultiPickerConfigItem.new("Paths", L{}, self:listFiles(), function(fileName)
            return fileName
        end)

        local pathSettingsEditor = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Picker.ExtraLarge)
        pathSettingsEditor:setAllowsCursorSelection(true)

        self.dispose_bag:add(pathSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local pathName = pathSettingsEditor:getDataSource():itemAtIndexPath(indexPath):getText()
            self.selectedPath = pathName
        end, pathSettingsEditor:getDelegate():didSelectItemAtIndexPath()))

        return pathSettingsEditor
    end

    self:reloadSettings()

    return self
end

function PathSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function PathSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Replay", self:getReplayPathMenuItem())
    self:setChildMenuItem("Stop", self:getStopPathMenuItem())
    self:setChildMenuItem("Record", self:getRecordPathMenuItem())
    self:setChildMenuItem("Edit", self:getEditPathMenuItem())
end

function PathSettingsMenuItem:getReplayPathMenuItem()
    return MenuItem.new(L{
        ButtonItem.default('Once', 18),
        ButtonItem.default('Repeat', 18),
    }, {
        Once = MenuItem.action(function()
            if self.selectedPath then
                self.pather:set_path_with_name(self.selectedPath, false)
                self.pather:start()
            end
        end, "Paths", "Replay the selected path once."),
        Repeat = MenuItem.action(function()
            if self.selectedPath then
                self.pather:set_path_with_name(self.selectedPath, true)
                self.pather:start()
            end
        end, "Paths", "Replay the selected path on repeat.")
    }, function(_, _)
    end, "Paths", "Replay the selected path.", true)
end

function PathSettingsMenuItem:getStartPathMenuItem()
    return MenuItem.action(function()
        if self.selectedPath then
            self.pather:set_path_with_name(self.selectedPath)
            self.pather:start()
        end
    end, "Paths", "Replay the selected path.")
end

function PathSettingsMenuItem:getStopPathMenuItem()
    return MenuItem.action(function()
        self.pather:stop(true)
    end, "Paths", "Cancel any active path.")
end

function PathSettingsMenuItem:getEditPathMenuItem()
    return MenuItem.new(L{
        ButtonItem.default("Rename", 18),
        ButtonItem.default("Delete", 18),
    }, L{
        Rename = self:getRenamePathMenuItem(),
        Delete = self:getDeletePathMenuItem()
    }, nil,"Record", "Record a new path.", true)
end

function PathSettingsMenuItem:getRenamePathMenuItem()
    local renamePathMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, L{}, function(_)
        local configItems = L{
            TextInputConfigItem.new('PathName', 'New Path Name', 'Path Name', function(_) return true  end)
        }
        local pathNameConfigEditor = ConfigEditor.new(nil, { PathName = '' }, configItems, nil, function(newSettings)
            return newSettings.PathName and newSettings.PathName:length() > 3
        end)

        self.dispose_bag:add(pathNameConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            self:renamePath(self.selectedPath, newSettings.PathName)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I renamed the path to "..newSettings.PathName.."!")
        end), pathNameConfigEditor:onConfigChanged())

        self.dispose_bag:add(pathNameConfigEditor:onConfigValidationError():addAction(function()
            addon_system_error("Invalid path name.")
        end), pathNameConfigEditor:onConfigValidationError())

        return pathNameConfigEditor
    end, "Paths", "Rename the path.")
    return renamePathMenuItem
end

function PathSettingsMenuItem:getDeletePathMenuItem()
    return MenuItem.action(function()
        if self.selectedPath then
            local filePath = windower.addon_path..self.pather:get_path_dir()..self.selectedPath
            local success, _ = os.remove(filePath)
            if success then
                self.pather:get_party():add_to_chat(self.pather:get_party():get_player(), "Poof! "..self.selectedPath.." is no more!")
            else
                self.pather:get_party():add_to_chat(self.pather:get_party():get_player(), "Sorry, I was unable to delete "..self.selectedPath..".")
            end
        end
    end, "Paths", "Delete the selected path.")
end

function PathSettingsMenuItem:getRecordPathMenuItem()
    return MenuItem.new(L{
        ButtonItem.default("Start", 18),
        ButtonItem.default("Save", 18),
        ButtonItem.default("Discard", 18),
    }, L{
        Start = MenuItem.action(function()
            local party = self.pather:get_party()
            if self.path_recorder:is_recording() then
                party:add_to_chat(party:get_player(), "I'm in the middle of recording a path!")
            else
                self.path_recorder:start_recording()
            end
        end, "Start", "Start recording a new path."),
        Save = MenuItem.action(function()
            local party = self.pather:get_party()
            if self.path_recorder:is_recording() then
                local filePath = self.path_recorder:stop_recording()
                if filePath then
                    party:add_to_chat(party:get_player(), "Alright, I've saved a new path to "..filePath)
                end
            else
                party:add_to_chat(party:get_player(), "I'm not currently recording a path.")
            end
        end, "Save", "Save the path being recorded to file."),
        Discard = MenuItem.action(function()
            self.path_recorder:stop_recording()
            addon_system_error("Discarded current path.")
        end, "Discard", "Discard the path currently being recorded.", false, function()
            return self.path_recorder:is_recording()
        end)
    }, nil,"Record", "Record a new path.")
end

function PathSettingsMenuItem:listFiles()
    local directoryPath = windower.addon_path..self.pather:get_path_dir()

    local command = "dir \"" .. directoryPath .. "\" /b"

    local handle = io.popen(command)
    if handle then
        local result = handle:read("*a")
        handle:close()

        local fileNames = L{}
        for fileName in result:gmatch("[^\r\n]+") do
            fileNames:append(fileName)
        end
        return fileNames
    else
        logger.error("Unable to load paths.")
    end
    return L{}
end

function PathSettingsMenuItem:renamePath(oldPathName, newPathName)
    local filePath = self.pather:get_path_dir()..oldPathName
    local oldPath = FileIO.new(filePath)
    if oldPath:exists() then
        local newPath = FileIO.new(self.pather:get_path_dir()..newPathName..'.lua')
        newPath:write(oldPath:read())
    end
end

return PathSettingsMenuItem
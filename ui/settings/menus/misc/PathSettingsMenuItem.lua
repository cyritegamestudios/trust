local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local FFXITextInputView = require('ui/themes/ffxi/FFXITextInputView')
local FileIO = require('files')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PathRecorder = require('cylibs/paths/path_recorder')

local PathSettingsMenuItem = setmetatable({}, {__index = MenuItem })
PathSettingsMenuItem.__index = PathSettingsMenuItem

function PathSettingsMenuItem.new(pather)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Replay', 18),
        ButtonItem.default('Stop', 18),
        ButtonItem.default('Record', 18),
        ButtonItem.default('Edit', 18),
    }, {}, nil, "Paths", "Start, stop or record a new path."), PathSettingsMenuItem)

    self.pather = pather
    self.path_recorder = PathRecorder.new(self.pather:get_path_dir())
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_)
        local pathSettingsEditor = FFXIPickerView.withItems(self:listFiles(), L{}, false, nil, nil, nil, true)

        pathSettingsEditor:setTitle("Choose a path to replay.")
        pathSettingsEditor:setShouldRequestFocus(true)
        pathSettingsEditor:setAllowsCursorSelection(true)

        self.dispose_bag:add(pathSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local pathName = pathSettingsEditor:getDataSource():itemAtIndexPath(indexPath):getText()
            self.selectedPath = pathName
        end, pathSettingsEditor:getDelegate():didSelectItemAtIndexPath()))

        return pathSettingsEditor
    end

    self.dispose_bag:addAny(L{ self.path_recorder })

    self:reloadSettings()

    return self
end

function PathSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
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
        if self.pather:is_enabled() then
            self.pather:stop()
        else
            self.pather:get_party():add_to_chat(self.pather:get_party():get_player(), "I'm already standing still!")
        end
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
        ButtonItem.default('Confirm', 18),
    }, L{}, function(_)
        local createSetView = FFXITextInputView.new("New path name", 'Path name')
        createSetView:setTitle("Choose a name for the path.")
        createSetView:setShouldRequestFocus(true)
        createSetView:onTextChanged():addAction(function(_, newPathName)
            if newPathName:length() > 3 then
                self:renamePath(self.selectedPath, newPathName)

                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I renamed the path to "..newPathName.."!")
            else
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."That name is too short, pick something else?")
            end
        end)
        return createSetView
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
    }, L{
        Start = MenuItem.action(function()
            local party = self.pather:get_party()
            if self.path_recorder:is_recording() then
                party:add_to_chat(party:get_player(), "I'm in the middle of recording a path!")
            else
                self.path_recorder:start_recording()
                party:add_to_chat(party:get_player(), "Alright, I'll start remembering this path. I won't save it until you tell me to stop.")
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
        end, "Save", "Save the path being recorded to file.")
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
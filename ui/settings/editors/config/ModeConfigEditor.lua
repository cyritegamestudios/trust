local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local ModeConfigEditor = setmetatable({}, {__index = ConfigEditor })
ModeConfigEditor.__index = ModeConfigEditor


function ModeConfigEditor.new(modeNames, infoView, modes)
    modes = modes or state
    modeNames = modeNames:filter(function(modeName)
        return modes[modeName] ~= nil
    end)

    local modeSettings = {}

    local configItems = modeNames:map(function(modeName)
        if modes[modeName] then
            modeSettings[modeName:lower()] = modes[modeName].value
            return PickerConfigItem.new(modeName:lower(), modes[modeName].value, L(modes[modeName]:options()), nil, modes[modeName].description or modeName)
        end
        return nil
    end):compact_map()

    local self = setmetatable(ConfigEditor.new(nil, modeSettings, configItems, nil, function(_) return not is_modes_locked() end), ModeConfigEditor)

    self.modes = modes
    self.infoView = infoView
    self.modeNames = modeNames

    self:setScrollDelta(16)
    self:setShouldRequestFocus(true)

    self:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
        self:updateInfoBar(indexPath)
    end)

    self:onConfigChanged():addAction(function(newSettings, oldSettings)
        for modeName, value in pairs(newSettings) do
            if oldSettings[modeName] ~= value then
                for m in modeNames:it() do
                    if m:lower() == modeName then
                        handle_set(m, value)
                    end
                end
            end
        end
    end)

    self:onConfigValidationError():addAction(function()
        addon_message(123, "You cannot change modes at this time.")
    end)

    return self
end

function ModeConfigEditor:setHasFocus(focus)
    ConfigEditor.setHasFocus(self, focus)

    if focus then
        self:updateInfoBar()
    end
end

function ModeConfigEditor:updateInfoBar(indexPath)
    indexPath = indexPath or self:getDelegate():getCursorIndexPath()
    if indexPath then
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            local description = self.modes[self.modeNames[indexPath.section]]:get_description(item:getText()) or "View and change Trust modes."

            description = string.gsub(description, "^Okay, ", "")
            description = self.modeNames[indexPath.section]..': '..description:gsub("^%l", string.upper)

            self.infoView:setDescription(description)
        end
    end
end

return ModeConfigEditor
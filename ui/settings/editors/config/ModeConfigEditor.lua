local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local SectionHeaderItem = require('cylibs/ui/collection_view/items/section_header_item')
local skillchain_util = require('cylibs/util/skillchain_util')

local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')

local ModeConfigEditor = setmetatable({}, {__index = ConfigEditor })
ModeConfigEditor.__index = ModeConfigEditor


function ModeConfigEditor.new(modeNames, infoView)
    local modeSettings = {}

    local configItems = modeNames:map(function(modeName)
        if state[modeName] then
            modeSettings[modeName:lower()] = state[modeName].value
            return PickerConfigItem.new(modeName:lower(), state[modeName].value, L(state[modeName]:options()), nil, state[modeName].description or modeName)
        end
        return nil
    end):compact_map()

    local self = setmetatable(ConfigEditor.new(nil, modeSettings, configItems), ModeConfigEditor)

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
                handle_set(modeName, value)
            end
        end
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
            local description = state[self.modeNames[indexPath.section]]:get_description(item:getText()) or "View and change Trust modes."

            description = string.gsub(description, "^Okay, ", "")
            description = description:gsub("^%l", string.upper)

            self.infoView:setDescription(description)
        end
    end
end

return ModeConfigEditor
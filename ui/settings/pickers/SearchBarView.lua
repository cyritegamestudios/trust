local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local Event = require('cylibs/events/Luvent')
local Frame = require('cylibs/ui/views/frame')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local SearchBarView = setmetatable({}, {__index = ConfigEditor })
SearchBarView.__index = SearchBarView

function SearchBarView:onSearchQueryChanged()
    return self.searchQueryChanged
end

function SearchBarView.new()
    local configItems = L{
        TextInputConfigItem.new('query', '', nil, nil, 80)
    }
    local searchResults = {
        query = ''
    }

    local self = setmetatable(ConfigEditor.new(nil, searchResults, configItems, nil, nil, nil, Frame.new(0, 0, 130, 60), "Search"), SearchBarView)
    self:setTitle("Search", 30)
    self.searchQueryChanged = Event.newEvent()

    self:onConfigItemChanged():addAction(function(key, currentValue, initialValue)
        self:onSearchQueryChanged():trigger(self, currentValue, initialValue)

        --self:resignFocus()
        --self:setVisible(false)
    end)

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function SearchBarView:destroy()
    ConfigEditor.destroy(self)

    self.searchQueryChanged:removeAllActions()
end

return SearchBarView

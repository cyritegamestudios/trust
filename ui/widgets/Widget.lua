local CollectionView = require('cylibs/ui/collection_view/collection_view')
local Color = require('cylibs/ui/views/color')
local ColorView = require('cylibs/ui/views/color_view')
local Event = require('cylibs/events/Luvent')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local Frame = require('cylibs/ui/views/frame')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Keyboard = require('cylibs/ui/input/keyboard')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local Mouse = require('cylibs/ui/input/mouse')

local Widget = setmetatable({}, {__index = CollectionView })
Widget.__index = Widget
Widget.__type = "Widget"


function Widget:onSettingsChanged()
    return self.settingsChanged
end

function Widget.new(frame, title, addonSettings, dataSource, layout, titleWidth, hideCursor)
    local widgetStyle = FFXIClassicStyle.default()
    if hideCursor then
        widgetStyle.cursorItem = nil
    end

    local self = setmetatable(CollectionView.new(dataSource, layout, nil, widgetStyle), Widget)

    self.addonSettings = addonSettings
    self.expanded = true
    self.events = {}
    self.settingsChanged = Event.newEvent()
    self.title = title
    self.resignFocusKeys = L{ 1 }

    self:setVisible(false)
    self:setScrollEnabled(false)
    self:setUserInteractionEnabled(true)

    self:setSize(frame.width, frame.height)

    local backgroundView = FFXIBackgroundView.new(frame)
    self:setBackgroundImageView(backgroundView)

    local titleSize
    if titleWidth then
        titleSize = { width = titleWidth, height = 14 }
    end
    backgroundView:setTitle(title, titleSize)

    self:getDisposeBag():add(backgroundView:onSelectTitle():addAction(function(_)
        self:setExpanded(not self.expanded)
    end), backgroundView:onSelectTitle())

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():add(addonSettings:onSettingsChanged():addAction(function(settings)
        local settings = self:getSettings(self.addonSettings)

        self:setVisible(settings.visible)
        self:setPosition(settings.x, settings.y)
        self:layoutIfNeeded()

        local shortcutSettings = self.addonSettings:getSettings().shortcuts.widgets[title:lower()]
        if shortcutSettings and shortcutSettings.enabled then
            Keyboard.input():registerKeybind(shortcutSettings.key, shortcutSettings.flags, function(_, _)
                self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
                self:requestFocus()
            end)
        end
    end), addonSettings:onSettingsChanged())

    local shortcutSettings = self.addonSettings:getSettings().shortcuts.widgets[title:lower()]
    if shortcutSettings and shortcutSettings.enabled then
        Keyboard.input():registerKeybind(shortcutSettings.key, shortcutSettings.flags, function(_, _)
            self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
            self:requestFocus()
        end)
    end

    return self
end

function Widget:destroy()
    CollectionView.destroy(self)

    self.settingsChanged:removeAllActions()

    for _,event in pairs(self.events) do
        windower.unregister_event(event)
    end
end

function Widget:getSettings(addonSettings)
    return nil
end

function Widget:layoutIfNeeded()
    local settings = self:getSettings(self.addonSettings)
    if settings then
        if not settings.visible then
            self:setVisible(false)
        end
    end

    self:setSize(self.frame.width, self:getContentSize().height)

    if not CollectionView.layoutIfNeeded(self) then
        return
    end
end

---
-- Sets the position of the view.
--
-- @tparam number x The x-coordinate to set.
-- @tparam number y The y-coordinate to set.
--
function Widget:setPosition(x, y)
    if self.frame.x == x and self.frame.y == y then
        return
    end
    CollectionView.setPosition(self, x, y)

    local settings = self:getSettings(self.addonSettings)
    if settings then
        local xPos, yPos = settings.x, settings.y
        if xPos ~= x or yPos ~= y then
            self.settingsChanged:trigger(self, settings)
        end
    end
end

function Widget:isExpanded()
    return self.expanded
end

function Widget:setExpanded(expanded)
    if self.expanded == expanded then
        return false
    end
    self.expanded = expanded
    return true
end

function Widget:setEditing(editing)
    if not CollectionView.setEditing(self, editing) then
        return false
    end

    if self:isEditing() then
        self.editingOverlay = ColorView.new(Frame.new(0, 0, self:getContentView():getSize().width, self:getContentView():getSize().height), Color.white:withAlpha(25))
        self:getContentView():addSubview(self.editingOverlay)
        self.editingOverlay:layoutIfNeeded()
    else
        if self.editingOverlay then
            self.editingOverlay:destroy()
            self.editingOverlay = false
        end
    end
    return true
end

function Widget:setHasFocus(hasFocus)
    CollectionView.setHasFocus(self, hasFocus)
    if hasFocus then
        for key in L{'up','down','enter','numpadenter'}:it() do
            windower.send_command('bind %s block':format(key))
        end
    else
        for key in L{'up','down','enter','numpadenter'}:it() do
            windower.send_command('unbind %s':format(key))
        end
    end
end

function Widget:onMouseEvent(type, x, y, delta)
    if self:getDelegate():onMouseEvent(type, x, y, delta) then
        return true
    end
    if type == Mouse.Event.Click then
        if self:isExpanded() and self:hitTest(x, y) then
            if not self:hasFocus() then
                -- TODO: do I need to uncomment this?
                self:requestFocus()
            end
            local startPosition = self:getAbsolutePosition()
            self.dragging = { x = startPosition.x, y = startPosition.y, dragX = x, dragY = y }

            return true
        end
    elseif type == Mouse.Event.Move then
        if self.dragging then
            self:setEditing(true)

            local newX = self.dragging.x + (x - self.dragging.dragX)
            local newY = self.dragging.y + (y - self.dragging.dragY)

            self:setPosition(newX, newY)
            self:layoutIfNeeded()

            return true
        end
        --return true
    elseif type == Mouse.Event.ClickRelease then
        if self.dragging then
            self.dragging = nil
            self:setEditing(false)
            addon_system_message("Use // trust widget save to save positions for all widgets.")
            return true
        end
    else
        self.dragging = nil
        return false
    end
    return false
end

function Widget:hitTest(x, y)
    if not self.dragging then
        return CollectionView.hitTest(self, x, y)
    end
    return true
end

function Widget:__eq(otherItem)
    return self.title == otherItem.title
end

return Widget
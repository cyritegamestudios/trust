local CollectionView = require('cylibs/ui/collection_view/collection_view')
local Event = require('cylibs/events/Luvent')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Mouse = require('cylibs/ui/input/mouse')

local Widget = setmetatable({}, {__index = CollectionView })
Widget.__index = Widget


function Widget:onSettingsChanged()
    return self.settingsChanged
end

function Widget.new(frame, title, addonSettings, dataSource, layout, titleWidth)
    local self = setmetatable(CollectionView.new(dataSource, layout), Widget)

    self.addonSettings = addonSettings
    self.events = {}
    self.settingsChanged = Event.newEvent()
    self.title = title

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

    self:setNeedsLayout()
    self:layoutIfNeeded()

    self:getDisposeBag():add(Mouse.input():onMouseEvent():addAction(function(type, x, y, delta, blocked)
        if type == Mouse.Event.Click then
            if self:hitTest(x, y) then
                local startPosition = self:getAbsolutePosition()
                self.dragging = { x = startPosition.x, y = startPosition.y, dragX = x, dragY = y }
                self:setEditing(true)
                Mouse.input().blockEvent = true
            end
        elseif type == Mouse.Event.Move then
            if self.dragging then
                Mouse.input().blockEvent = true

                local newX = self.dragging.x + (x - self.dragging.dragX)
                local newY = self.dragging.y + (y - self.dragging.dragY)

                self:setPosition(newX, newY)
                self:layoutIfNeeded()
            end
            return true
        elseif type == Mouse.Event.ClickRelease then
            if self.dragging then
                self.dragging = nil
                Mouse.input().blockEvent = true
                self:setEditing(false)
                coroutine.schedule(function()
                    Mouse.input().blockEvent = false
                end, 0.1)
            end
        else
            self.dragging = nil
            Mouse.input().blockEvent = false
        end
        return false
    end), Mouse.input():onMouseEvent())

    self:getDisposeBag():add(addonSettings:onSettingsChanged():addAction(function(settings)
        local settings = self:getSettings(self.addonSettings)

        self:setVisible(settings.visible)
        self:layoutIfNeeded()
    end), addonSettings:onSettingsChanged())

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

    if not CollectionView.layoutIfNeeded(self) then
        return
    end
    self.backgroundImageView:setSize(self.frame.width, self:getContentSize().height)
    self.backgroundImageView:layoutIfNeeded()
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

function Widget:__eq(otherItem)
    return self.title == otherItem.title
end

return Widget
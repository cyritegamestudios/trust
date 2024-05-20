local SliderItem = {}
SliderItem.__index = SliderItem
SliderItem.__type = "SliderItem"

---
-- Creates a new SliderItem instance.
--
-- @tparam string text The text content of the item.
-- @tparam TextStyle style The style to apply to the text.
-- @tparam string pattern (optional) The pattern used for formatting the text.
-- @treturn TextItem The newly created TextItem instance.
--
function SliderItem.new(minValue, maxValue, currentValue, interval, trackItem, fillItem, textFormat)
    local self = setmetatable({}, SliderItem)

    self.minValue = minValue
    self.maxValue = maxValue
    self.currentValue = currentValue
    self.interval = interval or 1
    self.trackItem = trackItem
    self.fillItem = fillItem
    self.textFormat = textFormat or function(value)
        return tostring(value)
    end

    return self
end

---
-- Gets the text content of the item.
--
-- @treturn string The text content.
--
function SliderItem:getMinValue()
    return self.minValue
end

---
-- Gets the text content of the item.
--
-- @treturn string The text content.
--
function SliderItem:getMaxValue()
    return self.maxValue
end

---
-- Gets the text content of the item.
--
-- @treturn string The text content.
--
function SliderItem:getCurrentValue()
    return self.currentValue
end

---
-- Gets the text content of the item.
--
-- @treturn string The text content.
--
function SliderItem:getInterval()
    return self.interval
end

function SliderItem:getText()

end

---
-- Sets the text for this TextItem.
--
-- @tparam string text The new text to set.
--
function SliderItem:setCurrentValue(newValue)
    self.currentValue = math.min(math.max(newValue, self:getMinValue()), self:getMaxValue())
end

---
-- Gets the text content of the item.
--
-- @treturn string The text content.
--
function SliderItem:getTrackItem()
    return self.trackItem
end

---
-- Gets the text content of the item.
--
-- @treturn string The text content.
--
function SliderItem:getFillItem()
    return self.fillItem
end

---
-- Gets the text content of the item.
--
-- @treturn string The text content.
--
function SliderItem:getCurrentValue()
    return self.currentValue
end

function SliderItem:getText()
    return self.textFormat(self:getCurrentValue())
end

---
-- Checks if this TextItem is equal to another TextItem.
--
-- @tparam TextItem otherItem The other TextItem to compare.
-- @treturn boolean True if they are equal, false otherwise.
--
function SliderItem:__eq(otherItem)
    return otherItem.__type == SliderItem.__type
            and self.currentValue == otherItem:getCurrentValue()
end

function SliderItem:tostring()
    return self:getText()
end

return SliderItem
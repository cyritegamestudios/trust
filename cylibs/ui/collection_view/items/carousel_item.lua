local CarouselItem = {}
CarouselItem.__index = CarouselItem
CarouselItem.__type = "CarouselItem"

---
-- Creates a new CarouselItem instance.
--
-- @tparam list imageItems List of image items.
-- @treturn CarouselItem The newly created CarouselItem instance.
--
function CarouselItem.new(imageItems)
    local self = setmetatable({}, CarouselItem)
    self.imageItems = imageItems
    return self
end

---
-- Gets the image item.
--
-- @treturn list List of image items.
--
function CarouselItem:getImageItems()
    return self.imageItems
end

---
-- Checks if this CarouselItem is equal to another CarouselItem.
--
-- @tparam CarouselItem otherItem The other CarouselItem to compare.
-- @treturn boolean True if they are equal, false otherwise.
--
function CarouselItem:__eq(otherItem)
    return otherItem.__type == CarouselItem.__type
            and self:getImageItems() == otherItem:getImageItems()
end

return CarouselItem
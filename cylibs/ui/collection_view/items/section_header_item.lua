local SectionHeaderItem = {}
SectionHeaderItem.__index = SectionHeaderItem
SectionHeaderItem.__type = "SectionHeaderItem"

---
-- Creates a new SectionHeaderItem instance.
--
-- @tparam TextItem titleItem The section title.
-- @tparam ImageItem imageItem (optional) The image to display to the left of the title.
-- @tparam number sectionSize (optional) The size of the section.
-- @treturn SectionHeaderItem The newly created SectionHeaderItem instance.
--
function SectionHeaderItem.new(titleItem, imageItem, sectionSize)
    local self = setmetatable({}, SectionHeaderItem)

    self.titleItem = titleItem
    self.imageItem = imageItem
    self.sectionSize = sectionSize or 20

    return self
end

---
-- Gets the section title.
--
-- @treturn TextItem The section title.
--
function SectionHeaderItem:getTitleItem()
    return self.titleItem
end

---
-- Gets the image item.
--
-- @treturn ImageItem The image item.
--
function SectionHeaderItem:getImageItem()
    return self.imageItem
end

---
-- Gets the section size.
--
-- @treturn number The section size.
--
function SectionHeaderItem:getSectionSize()
    return self.sectionSize
end

---
-- Checks if this SectionHeaderItem is equal to another SectionHeaderItem.
--
-- @tparam SectionHeaderItem otherItem The other SectionHeaderItem to compare.
-- @treturn boolean True if they are equal, false otherwise.
--
function SectionHeaderItem:__eq(otherItem)
    return otherItem.__type == SectionHeaderItem.__type
            and self:getTitle() == otherItem:getTitle()
end

return SectionHeaderItem
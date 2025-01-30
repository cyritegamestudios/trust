local IndexPath = {}
IndexPath.__index = IndexPath
IndexPath.__class = "IndexPath"
IndexPath.__type = "IndexPath"

---
-- Creates a new IndexPath instance representing a specific section and row in a table-like structure.
--
-- @tparam number section The section index.
-- @tparam number row The row index.
-- @treturn IndexPath The newly created IndexPath instance.
--
function IndexPath.new(section, row)
    local self = setmetatable({}, IndexPath)
    self.section = section
    self.row = row
    return self
end

---
-- String description of this IndexPath.
-- @treturn string String description.
--
function IndexPath:__tostring()
    return string.format("[Section: %d, Row: %d]", self.section, self.row)
end

---
-- Compares two View instances for equality based on their UUIDs.
-- @tparam any otherItem The other object to compare.
-- @treturn bool True if the IndexPaths have the same section and row, false otherwise.
--
function IndexPath:__eq(otherItem)
    if otherItem.__type ~= IndexPath.__type then
        return false
    end
    return self.section == otherItem.section and self.row == otherItem.row
end

return IndexPath

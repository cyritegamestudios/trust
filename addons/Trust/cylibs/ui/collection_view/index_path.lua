local IndexPath = {}
IndexPath.__index = IndexPath
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
-- Compares two View instances for equality based on their UUIDs.
-- @tparam any otherItem The other object to compare.
-- @treturn bool True if the IndexPaths have the same section and row, false otherwise.
--
function IndexPath:__eq(otherItem)
    return self.section == otherItem.section and self.row == otherItem.row
end

return IndexPath

local Layout = require('cylibs/ui/layouts/layout')

local VerticalListLayout = setmetatable({}, {__index = Layout })
VerticalListLayout.__index = VerticalListLayout

function VerticalListLayout.new(layoutWidth, itemOffset)
    local self = setmetatable(Layout.new(itemOffset), VerticalListLayout)

    self.itemOffset = itemOffset

    self:setSize(layoutWidth, 0)

    return self
end

---
-- Destroys the layout, cleaning up its resources.
--
function VerticalListLayout:destroy()
    Layout.destroy(self)
end

function VerticalListLayout:layout(itemViews, items)
    local layoutWidth, _ = self:getSize()
    local xOffset, layoutHeight = self:getOffset()

    for item in items:it() do
        local itemView = itemViews[item]
        if itemView then
            local _, height = itemView:get_size()
            itemView:set_size(layoutWidth, height)
            itemView:set_pos(xOffset, layoutHeight)
            itemView:render()
            layoutHeight = layoutHeight + height + self.itemOffset
        end
    end

    self:setSize(layoutWidth, layoutHeight)
end

return VerticalListLayout

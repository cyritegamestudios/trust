local View = require('cylibs/ui/views/view')

local CollectionViewCell = setmetatable({}, {__index = View })
CollectionViewCell.__index = CollectionViewCell
CollectionViewCell.__type = "CollectionViewCell"

---
-- Creates a new CollectionViewCell.
--
-- @tparam any item The item associated with the cell.
-- @treturn CollectionViewCell The newly created cell.
--
function CollectionViewCell.new(item)
    local self = setmetatable(View.new(), CollectionViewCell)
    self.item = item
    self.itemSize = 40
    self.highlighted = false
    self.selectable = true
    self.scaleToFitParent = true
    return self
end

---
-- Returns the size of the item associated with the cell.
--
-- @treturn number The size of the item.
--
function CollectionViewCell:getItemSize()
    return self.itemSize
end

---
-- Sets the size of the item associated with the cell.
--
-- @tparam number itemSize The size of the item.
--
function CollectionViewCell:setItemSize(itemSize)
    self.itemSize = itemSize
end

---
-- Returns the estimated size of the content. If no estimated size is specified, the
-- height of the cell will be returned instead.
--
-- @treturn number The estimated size of the content.
--
function CollectionViewCell:getEstimatedSize()
    return self.estimatedSize or self:getSize().height
end

---
-- Sets the estimated size of the content. This differs from the itemSize which is fixed.
--
-- @tparam number estimatedSize The estimateed size of the item.
--
function CollectionViewCell:setEstimatedSize(estimatedSize)
    self.estimatedSize = estimatedSize
end

---
-- Returns the item associated with the cell.
--
-- @treturn any The associated item.
--
function CollectionViewCell:getItem()
    return self.item
end

---
-- Sets the item associated with the cell.
--
-- @tparam any item The item to associate with the cell.
--
function CollectionViewCell:setItem(item)
    if self.item ~= item then
        self.item = item
        self:setNeedsLayout()
    end
end

---
-- Checks if the CollectionViewCell is selected.
-- @treturn boolean True if selected, false otherwise.
--
function CollectionViewCell:isSelected()
    return self.selected
end

---
-- Sets the selection state of the CollectionViewCell.
-- @tparam boolean selected The new selection state.
--
function CollectionViewCell:setSelected(selected)
    self.selected = selected
    if type(self:getItem().getStyle) == "function" then
        if self.selected then
            self:setBackgroundColor(self:getItem():getStyle():getSelectedBackgroundColor())
        else
            self:setBackgroundColor(self:getItem():getStyle():getDefaultBackgroundColor())
        end
    end
    self:setNeedsLayout()
    self:layoutIfNeeded()
    return true
end

---
-- Checks if the CollectionViewCell can be selected.
-- @treturn boolean True if the cell can be selected selected, false otherwise.
--
function CollectionViewCell:isSelectable()
    return self.selectable
end

---
-- Sets whether the cell is selectable.
-- @tparam boolean selectable True if the cell can be selected selected
--
function CollectionViewCell:setIsSelectable(selectable)
    self.selectable = selectable
end

---
-- Checks if the CollectionViewCell is highlighted.
-- @treturn boolean True if highlighted, false otherwise.
--
function CollectionViewCell:isHighlighted()
    return self.highlighted
end

---
-- Sets the highlighted state of the CollectionViewCell.
-- @tparam boolean highlighted The new highlighted state.
--
function CollectionViewCell:setHighlighted(highlighted)
    if self.highlighted == highlighted then
        return
    end
    self.highlighted = highlighted
    for _, subview in pairs(self.subviews) do
        if subview.setHighlighted then
            subview:setHighlighted(highlighted)
        end
    end
    self:setNeedsLayout()
    self:layoutIfNeeded()
end

---
-- Checks whether the cell should scale to fit the parent view.
-- @treturn boolean True if the cell should scale to fit the parent view.
--
function CollectionViewCell:shouldScaleToFitParent()
    return self.scaleToFitParent
end

---
-- Sets whether the cell should scale to fit the parent. If `false`, the
-- cell will use the `itemSize` as width and height.
-- @tparam boolean scaleToFitParent Whether the cell should scale to fit the parent view.
--
function CollectionViewCell:setScaleToFitParent(scaleToFitParent)
    self.scaleToFitParent = scaleToFitParent
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function CollectionViewCell:layoutIfNeeded()
    if not View.layoutIfNeeded(self) then
        return false
    end
    return true
end

return CollectionViewCell
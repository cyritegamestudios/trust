local CollectionViewCell = require('cylibs/ui/collection_view/collection_view_cell')

local ContainerCollectionViewCell = setmetatable({}, {__index = CollectionViewCell })
ContainerCollectionViewCell.__index = ContainerCollectionViewCell
ContainerCollectionViewCell.__type = "ContainerCollectionViewCell"

function ContainerCollectionViewCell.new(item)
    local self = setmetatable(CollectionViewCell.new(item), ContainerCollectionViewCell)

    self.view = item:getView()

    self:addSubview(self.view)

    self:getDisposeBag():addAny(L{ self.view })

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function ContainerCollectionViewCell:destroy()
    if not self:getItem():shouldDestroyView() then
        self.view:removeFromSuperview()
    end
    CollectionViewCell.destroy(self)
end

---
-- Checks if layout updates are needed and triggers layout if necessary.
-- This function is typically called before rendering to ensure that the View's layout is up to date.
--
function ContainerCollectionViewCell:layoutIfNeeded()
    if not CollectionViewCell.layoutIfNeeded(self) then
        return false
    end

    self.view:setSize(self.frame.width, self.frame.height)

    return true
end

function ContainerCollectionViewCell:setItem(item)
    if self:getItemSize() ~= item.viewSize then
        self:setItemSize(item.viewSize)
    end
    CollectionViewCell.setItem(self, item)
end

return ContainerCollectionViewCell
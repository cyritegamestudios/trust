local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')

local FFXIWindow = setmetatable({}, {__index = CollectionView })
FFXIWindow.__index = FFXIWindow

function FFXIWindow.new(dataSource, layout, delegate, showTitle, viewSize, style)
    style = style or CollectionView.defaultStyle()
    viewSize = viewSize or style:getDefaultSize()

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height), not showTitle, style)

    local self = setmetatable(CollectionView.new(dataSource, layout, delegate, style), FFXIWindow)


    self:setBackgroundImageView(backgroundView)

    self:setSize(viewSize.width, viewSize.height)

    return self
end

function FFXIWindow.getLayoutParams(numItemsPerPage, itemSize, itemSpacing, defaultSize, defaultPadding)
    local viewHeight = numItemsPerPage * itemSize + (numItemsPerPage - 1) * itemSpacing
    local viewSize = defaultSize
    viewSize.height = viewHeight
    local padding = defaultPadding
    padding.top = itemSize / 2
    padding.bottom = itemSize / 2
    return { viewSize = viewSize, padding = padding }
end

return FFXIWindow
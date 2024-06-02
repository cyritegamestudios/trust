local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')

local FFXIWindow = setmetatable({}, {__index = CollectionView })
FFXIWindow.__index = FFXIWindow

function FFXIWindow.new(dataSource, layout, delegate, showTitle, viewSize, style)
    style = style or CollectionView.defaultStyle()
    viewSize = viewSize or style:getDefaultSize()

    local self = setmetatable(CollectionView.new(dataSource, layout, delegate, style), FFXIWindow)

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height), not showTitle, style)
    self:setBackgroundImageView(backgroundView)

    self:setSize(viewSize.width, viewSize.height)

    return self
end

return FFXIWindow
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local Frame = require('cylibs/ui/views/frame')

local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXICollectionView = setmetatable({}, {__index = CollectionView })
FFXICollectionView.__index = FFXICollectionView

function FFXICollectionView.new(viewSize, dataSource, layout, delegate)
    local self = setmetatable(CollectionView.new(dataSource, layout, delegate, FFXIClassicStyle.default()), FFXICollectionView)

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height))
    self:setBackgroundImageView(backgroundView)

    return self
end

function FFXICollectionView:getContentView()
    return self.contentView
end

function FFXICollectionView:setTitle(title)
    self.backgroundImageView:setTitle(title)
end

function FFXICollectionView:layoutIfNeeded()
    local needsLayout = View.layoutIfNeeded(self)
    if not needsLayout then
        return
    end

    self.contentView:setSize(self:getSize().width, self:getSize().height)

    self.contentView:setNeedsLayout()
    self.contentView:layoutIfNeeded()

    return needsLayout
end

return FFXICollectionView
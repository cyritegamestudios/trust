local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')

local View = require('cylibs/ui/views/view')
local FFXIWindow = setmetatable({}, {__index = View })
FFXIWindow.__index = FFXIWindow

function FFXIWindow.new(viewSize)
    local self = setmetatable(View.new(Frame.new(0, 0, viewSize.width, viewSize.height)), FFXIWindow)

    self.contentView = View.new(self.frame)
    self:addSubview(self.contentView)

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height))
    self:setBackgroundImageView(backgroundView)

    return self
end

function FFXIWindow:getContentView()
    return self.contentView
end

function FFXIWindow:setTitle(title)
    self.backgroundImageView:setTitle(title)
end

function FFXIWindow:layoutIfNeeded()
    local needsLayout = View.layoutIfNeeded(self)
    if not needsLayout then
        return
    end

    self.contentView:setSize(self:getSize().width, self:getSize().height)

    self.contentView:setNeedsLayout()
    self.contentView:layoutIfNeeded()

    return needsLayout
end

return FFXIWindow
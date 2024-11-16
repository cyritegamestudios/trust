local Image = require('images')
local View = require('cylibs/ui/views/view')

local ColorView = setmetatable({}, {__index = View })
ColorView.__index = ColorView

function ColorView.new(frame, color)
    local self = setmetatable(View.new(frame), ColorView)
    self.backgroundView = Image.new()
    self:getDisposeBag():addAny(L{ self.backgroundView })
    self:setBackgroundColor(color)
    return self
end

return ColorView
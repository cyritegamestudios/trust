local View = require('cylibs/ui/views/view')

local ColorView = setmetatable({}, {__index = View })
ColorView.__index = ColorView

function ColorView.new(frame, color)
    local self = setmetatable(View.new(frame), ColorView)
    self:setBackgroundColor(color)
    return self
end

return ColorView
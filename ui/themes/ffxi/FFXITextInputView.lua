local CollectionView = require('cylibs/ui/collection_view/collection_view')
local FFXIBackgroundView = require('ui/themes/ffxi/FFXIBackgroundView')
local Frame = require('cylibs/ui/views/frame')

local TextInputView = require('cylibs/ui/views/input/text_input_view')
local FFXITextInputView = setmetatable({}, {__index = TextInputView })
FFXITextInputView.__index = FFXITextInputView

function FFXITextInputView.new(placeholderText)
    local style = CollectionView.defaultStyle()
    local viewSize = style:getDefaultSize()

    local backgroundView = FFXIBackgroundView.new(Frame.new(0, 0, viewSize.width, viewSize.height), true, style)

    local self = setmetatable(TextInputView.new(placeholderText, backgroundView), FFXITextInputView)
    self:setBackgroundImageView(backgroundView)

    return self
end

return FFXITextInputView
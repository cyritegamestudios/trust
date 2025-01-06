local Image = require('images')
local ImageLoader = require('cylibs/util/images/image_loader')
local Renderer = require('cylibs/ui/views/render')
local View = require('cylibs/ui/views/view')

local ImageView = setmetatable({}, { __index = View })
ImageView.__index = ImageView

num_images_created = 0

---
-- Creates a new ImageView instance with an associated image path and identifier.
--
-- @tparam string imagePath The path to the image to be displayed in the ImageView.
-- @treturn ImageView The newly created ImageView instance.
--
function ImageView.new(repeatX, repeatY, alpha)
    local self = setmetatable(View.new(), ImageView)

    self.repeatX = repeatX or 1
    self.repeatY = repeatY or 1
    self.alpha = alpha or 255
    self.image = Image.new()
    self.image:fit(true)
    self.image:hide()
    self.image:draggable(false)

    self:getDisposeBag():add(Renderer.shared():onPrerender():addAction(function()
        self:setNeedsLayout()
        self:layoutIfNeeded()
    end), Renderer.shared():onPrerender())

    self:getDisposeBag():addAny(L{ self.image })

    num_images_created = num_images_created + 1

    return self
end

function ImageView:destroy()
    View.destroy(self)

    num_images_created = num_images_created - 1
end

function ImageView:loadImage(imagePath)
    if self.imagePath == imagePath then
        return
    end

    self.imagePath = imagePath

    self.image:path(imagePath)
    self.image:hide()
end

-- Handles the hover event for the ImageView.
-- @tparam number x The x-coordinate of the hover event.
-- @tparam number y The y-coordinate of the hover event.
function ImageView:hitTest(x, y)
    return self.image:hover(x, y)
end

function ImageView:layoutIfNeeded()
    if not View.layoutIfNeeded(self) then
        return false
    end

    local position = self:getAbsolutePosition()

    local isVisible = self:isVisible() and string.len(self.image:path()) > 0
    if self.superview then
        isVisible = isVisible and self.superview:isVisible()
    end

    self.image:repeat_xy(self.repeatX, self.repeatY)
    self.image:pos(position.x, position.y)
    self.image:size(self:getSize().width, self:getSize().height)
    self.image:alpha(self.alpha)
    self.image:visible(isVisible)

    return true
end

return ImageView

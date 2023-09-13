local Image = require('images')
local ImageLoader = require('cylibs/util/images/image_loader')
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
    self.imageLoader = ImageLoader.new()
    self.image = Image.new()
    self.image:fit(true)
    self.image:hide()
    self.image:draggable(false)

    self:getDisposeBag():addAny(L{ self.imageLoader, self.image })

    num_images_created = num_images_created + 1

    return self
end

function ImageView:destroy()
    View.destroy(self)

    self:stopLoading()

    num_images_created = num_images_created - 1
end

function ImageView:stopLoading()
    if self.imageLoader then
        self.imageLoader:destroy()
    end
end

function ImageView:loadImage(imagePath)
    if self.imageLoader and self.imageLoader:getImagePath() == imagePath then
        return
    end
    self:stopLoading()

    self.imageLoader = ImageLoader.new()

    self.imageLoader:onImageLoaded():addAction(function(_)
        self:setNeedsLayout()
        self:layoutIfNeeded()
    end)
    self.imageLoader:loadImage(self.image, imagePath)
end

-- Handles the hover event for the ImageView.
-- @tparam number x The x-coordinate of the hover event.
-- @tparam number y The y-coordinate of the hover event.
function ImageView:hitTest(x, y)
    local _, height = self.image:size()
    -- FIXME: (cyrite) 2023-09-07 why do I need to add the height?
    return self.image:hover(x, y + height)
end

function ImageView:layoutIfNeeded()
    View.layoutIfNeeded(self)

    local position = self:getAbsolutePosition()

    local isVisible = self:isVisible() and self.imageLoader:isLoaded() and string.len(self.image:path()) > 0
    if self.superview then
        isVisible = isVisible and self.superview:isVisible()
    end

    self.image:repeat_xy(self.repeatX, self.repeatY)
    self.image:visible(isVisible)
    self.image:pos(position.x, position.y)
    self.image:size(self:getSize().width, self:getSize().height)
    self.image:alpha(self.alpha)
end

return ImageView

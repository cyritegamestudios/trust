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
function ImageView.new()
    local self = setmetatable(View.new(), ImageView)

    self.imageLoader = ImageLoader.new()
    self.image = Image.new()
    self.image:fit(true)
    self.image:hide()

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

    self:getDisposeBag():add(self.imageLoader:onImageLoaded():addAction(function(_)
        self:setNeedsLayout()
        self:layoutIfNeeded()
    end), self.imageLoader:onImageLoaded())

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

    if not self:isVisible() then
        --self.image:hide()
    end

    self.image:visible(self:isVisible() and self.imageLoader:isLoaded() and string.len(self.image:path()) > 0)
    self.image:pos(position.x, position.y)
    self.image:size(self:getSize().width, self:getSize().height)
end

return ImageView

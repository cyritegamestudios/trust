local DisposeBag = require('cylibs/events/dispose_bag')
local Image = require('images')
local ImageLoader = require('cylibs/util/images/image_loader')
local View = require('cylibs/ui/view')

local ImageView = setmetatable({}, { __index = View })
ImageView.__index = ImageView

num_images_created = 0

---
-- Creates a new ImageView instance with an associated image path and identifier.
--
-- @tparam string imagePath The path to the image to be displayed in the ImageView.
-- @treturn ImageView The newly created ImageView instance.
--
function ImageView.new(imagePath)
    local self = setmetatable(View.new(), ImageView)

    self.disposeBag = DisposeBag.new()
    self.imageLoader = ImageLoader.new()
    self.imagePath = imagePath
    self.image = Image.new()
    self.image:fit(true)
    self.image:hide()

    self.disposeBag:add(self.imageLoader:onImageLoaded():addAction(function(imagePath)
        self:render()
    end), self.imageLoader:onImageLoaded())

    self:set_color(0, 0, 0, 0)
    num_images_created = num_images_created + 1

    return self
end

function ImageView:destroy()
    View.destroy(self)

    self.disposeBag:destroy()
    self.image:destroy()
    self.imageLoader:destroy()

    num_images_created = num_images_created - 1
end

---
-- Set the image to be displayed in the ImageView.
--
-- @tparam string imagePath The path to the image to be displayed.
--
function ImageView:setImage(imagePath)
    self.image:path(imagePath)
end

---
-- Set the size of the displayed image.
--
-- @tparam number width The width of the image.
-- @tparam number height The height of the image.
--
function ImageView:setImageSize(width, height)
    self:set_size(width, height)
end

function ImageView:render()
    View.render(self)

    if self.imageLoader:isLoaded() then
        local x, y = self:get_pos()
        local width, height = self:get_size()

        self.image:pos(x, y)
        self.image:size(width, height)
        self.image:visible(self:is_visible())
    else
        self.image:hide()
        self.imageLoader:loadImage(self.image, self.imagePath)
    end
end

return ImageView

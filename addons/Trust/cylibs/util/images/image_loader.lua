local Event = require('cylibs/events/Luvent')

local ImageLoader = { }
ImageLoader.__index = ImageLoader

function ImageLoader:onImageLoaded()
    return self.imageLoaded
end

-- Constructor for the ImageLoader class
function ImageLoader.new()
    local self = setmetatable({}, ImageLoader)
    self.loading = false
    self.loaded = false
    self.scheduler = nil
    self.imageLoaded = Event.newEvent()
    return self
end

function ImageLoader:destroy()
    self:onImageLoaded():removeAllActions()

    if self.scheduler then
        coroutine.close(self.scheduler)
    end
end

function ImageLoader:loadImage(image, imagePath)
    if self:isLoading() or self:isLoaded() then
        return
    end
    self.imagePath = imagePath

    image:hide()
    image:path(imagePath)

    if string.len(imagePath) > 0 then
        self.scheduler = coroutine.schedule(function()
            image:show()
            self:handleImageLoaded(imagePath)
        end, 0.3)
    else
        self:handleImageLoaded(imagePath)
    end
end

function ImageLoader:handleImageLoaded(imagePath)
    self.loaded = true
    self.scheduler = nil

    self:onImageLoaded():trigger(imagePath)
end

function ImageLoader:isLoading()
    return self.loading
end

function ImageLoader:isLoaded()
    return self.loaded
end

function ImageLoader:getImagePath()
    return self.imagePath
end

return ImageLoader

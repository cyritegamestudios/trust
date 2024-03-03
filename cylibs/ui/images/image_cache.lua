local ImageCache = {}
ImageCache.__index = ImageCache
ImageCache.__type = "ImageCache"

---
-- Creates a new image cache.
--
-- @treturn ImageCache The newly created ImageCache instance.
--
function ImageCache.new()
    local self = setmetatable({}, ImageCache)
    self.images = {}
    return self
end

---
-- Gets the cached image with the given key.
--
-- @treturn Image Windower image primitive (see libs/images.lua).
--
function ImageCache:getImage(key)
    return self.images[key]
end

---
-- Caches the image with the given key.
--
-- @tparam Image image Windower image primitive (see libs/images.lua)
-- @tparam string key Image key
--
function ImageCache:setImage(image, key)
    self.images[key] = image
end

return ImageCache
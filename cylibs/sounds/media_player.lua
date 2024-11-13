local MediaPlayer = {}
MediaPlayer.__index = MediaPlayer
MediaPlayer.__type = "MediaPlayer"

---
-- Creates a new MediaPlayer.
--
-- @param string mediaPath Base path to the media directory.
--
-- @treturn MenuItem The newly created MediaPlayer.
--
function MediaPlayer.new(mediaPath)
    local self = setmetatable({}, MediaPlayer)

    self.mediaPath = mediaPath
    self.enabled = true

    return self
end

function MediaPlayer:destroy()
end

---
-- Plays a sound at the given path, relative to the base media path.
--
-- @param string relativePath Relative path to sound.
--
function MediaPlayer:playSound(relativePath)
    windower.play_sound(self.mediaPath..'/'..relativePath..'.wav')
end

---
-- Gets whether the media player is enabled. If disabled, sounds will not play.
--
-- @treturn boolean Whether the media player is enabled.
--
function MediaPlayer:isEnabled()
    return self.enabled
end

---
-- Enables and disables the media player. If disabled, sounds will not play.
--
-- @param boolean enabled New value for enalbed.
--
function MediaPlayer:setEnabled(enabled)
    self.enabled = enabled
end

return MediaPlayer
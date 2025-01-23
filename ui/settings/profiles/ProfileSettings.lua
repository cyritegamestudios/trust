local DisposeBag = require('cylibs/events/dispose_bag')
local ValueRelay = require('cylibs/events/value_relay')

local ProfileSettings = {}
ProfileSettings.__index = ProfileSettings

function ProfileSettings:onSettingsChanged()
    return self.currentSettings:onValueChanged()
end

---
-- Creates a new ProfileSettings instance.
--
-- @tparam TrustSettings trustSettings The trust settings.
-- @tparam Mode trustSettingsMode The trust settings mode.
--
-- @treturn ProfileSettings The newly created ProfileSettings instance.
--
function ProfileSettings.new(trustSettings, trustSettingsMode)
    local self = setmetatable({}, ProfileSettings)

    self.currentSettings = ValueRelay.new(self:getSettings())

    self.disposeBag = DisposeBag.new()
    self.disposeBag:addAny(L{ self.currentSettings })

    self.disposeBag:add(trustSettings:onSettingsChanged():addAction(function(_)
        self.currentSettings:setValue(self:getSettings())
    end), trustSettings:onSettingsChanged())

    self.disposeBag:add(trustSettingsMode:on_state_change():addAction(function(_, _)
        self.currentSettings:setValue(self:getSettings())
    end), trustSettingsMode:on_state_change())

    return self
end

function ProfileSettings:destroy()
    self.settingsChanged:removeAllActions()
end

function ProfileSettings:getSettings()
    return self.trustSettings:getSettings()[self.trustSettingsMode.value]
end

return ProfileSettings
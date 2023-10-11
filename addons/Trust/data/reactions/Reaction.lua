local Reaction = {}
Reaction.__index = Reaction
Reaction.__type = "Reaction"

function Reaction.new()
    local self = setmetatable({}, Reaction)

    return self
end

function Reaction:onInit(settings)
    self.settings = settings

    return self
end

function Reaction:getSettings()
    return self.settings
end

return Reaction
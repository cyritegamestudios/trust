local TargetLock = {}
TargetLock.__index = TargetLock
TargetLock.__class = "TargetLock"
TargetLock.__type = "TargetLock"

function TargetLock.new(id, target_index)
    local self = setmetatable({}, TargetLock)
    self.id = id
    self.target_index = target_index
    return self
end

function TargetLock:get_target_index()
    return self.target_index
end

function TargetLock:set_target_index(target_index)
    self.target_index = target_index
end

function TargetLock:__eq(otherItem)
    return otherItem.__class == TargetLock.__class
            and self.id == otherItem.id
            and self.target_index == otherItem.target_index
end

return TargetLock
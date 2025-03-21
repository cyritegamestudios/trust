local GambitTarget = require('cylibs/gambits/gambit_target')

local GambitTargetGroup = {}
GambitTargetGroup.__index = GambitTargetGroup

function GambitTargetGroup.new(targets_by_type)
    local self = setmetatable({}, GambitTargetGroup)
    self.targets_by_type = targets_by_type
    self.targets_by_type[GambitTarget.TargetType.Ally] = self.targets_by_type[GambitTarget.TargetType.Ally] or L{}
    return self
end

function GambitTargetGroup:safe_get(target_type, key, default_value)
    if self.targets_by_type[target_type] and key <= self.targets_by_type[target_type]:length() then
        return self.targets_by_type[target_type][key]
    end
    return default_value
end

function GambitTargetGroup:it()
    local key = 0
    return function()
        key = key + 1
        local target_by_type
        if key == 1 or key <= self.targets_by_type[GambitTarget.TargetType.Ally]:length() then
            target_by_type = {
                [GambitTarget.TargetType.Self] = self:safe_get(GambitTarget.TargetType.Self, 1),
                [GambitTarget.TargetType.Enemy] = self:safe_get(GambitTarget.TargetType.Enemy, 1),
                [GambitTarget.TargetType.Ally] = self:safe_get(GambitTarget.TargetType.Ally, key),
            }
        end
        return target_by_type, key
    end
end

return GambitTargetGroup
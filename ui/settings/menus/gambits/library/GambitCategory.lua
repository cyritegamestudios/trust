local GambitCategory = {}
GambitCategory.__index = GambitCategory

function GambitCategory.new(name, description, gambits)
    local self = setmetatable({}, GambitCategory)

    self.name = name
    self.description = description or self.name
    self.gambits = gambits or L{}

    return self
end

function GambitCategory:getName()
    return self.name
end

function GambitCategory:getDescription()
    return self.description
end

function GambitCategory:getGambits()
    return self.gambits
end

return GambitCategory
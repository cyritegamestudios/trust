local serializer_util = require('cylibs/util/serializer_util')

local Skillchain = {}
Skillchain.__index = Skillchain

function Skillchain.new(name, elements, level)
    local self = setmetatable({
        name = name,
        elements = elements,
        level = level,
    }, Skillchain)

    return self
end

function Skillchain:get_elements()
    return self.elements
end

function Skillchain:get_name()
    return self.name
end

function Skillchain:get_level()
    return self.level
end

function Skillchain:serialize()
    return "Skillchain.new(" .. serializer_util.serialize_args(self.name, L(self.elements), self.level) .. ")"
end

function Skillchain.equals(obj1, obj2)
    return obj1.elements == obj2.elements and obj1.level == obj2.level
end

function Skillchain:__tostring()
    return self:get_name().." (Lv."..self:get_level()..")"
end

Skillchain.__eq = Skillchain.equals

return Skillchain
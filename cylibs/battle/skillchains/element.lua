local serializer_util = require('cylibs/util/serializer_util')

local Element = {}
Element.__index = Element

-------
-- Default initializer for an element (e.g. `Light`, `Fire`, `Water`). Use `util/element_util.lua` to create new Elements.
-- @tparam string name Element name (e.g. `Light`, `Fire`, `Water`)
-- @treturn Element An element
function Element.new(name)
    local self = setmetatable({
        name = name,
    }, Element)

    return self
end

-------
-- Returns the name of the element.
-- @treturn string Name of element (e.g. `Fire`)
function Element:get_name()
    return self.name
end

function Element:get_localized_name()
    return i18n.resource('elements', 'en', self:get_name())
end

function Element:serialize()
    return "Element.new(" .. serializer_util.serialize_args(self:get_name()) .. ")"
end

function Element:__tostring()
    return self.name
end

function Element.equals(obj1, obj2)
    return obj1.name == obj2.name
end

Element.__eq = Element.equals

return Element
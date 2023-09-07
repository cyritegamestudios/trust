---------------------------
-- Wrapper around a roll
-- @class module
-- @name Roll

local Roll = {}
Roll.__index = Roll

-------
-- Default initializer for a new roll.
-- @tparam string roll_name Localized name of the roll
-- @tparam Boolean use_crooked_cards Whether to use Crooked Cards
-- @treturn Roll A roll
function Roll.new(roll_name, use_crooked_cards)
    local self = setmetatable({
        roll_name = roll_name;
        use_crooked_cards = use_crooked_cards;
    }, Roll)
    return self
end

-------
-- Returns the name for the roll.
-- @treturn string Roll name
function Roll:get_roll_name()
    return self.roll_name
end

-------
-- Returns whether or not Crooked Cards should be used with this roll.
-- @treturn Boolean True if Crooked Cards should be used.
function Roll:should_use_crooked_cards()
    return self.use_crooked_cards
end

return Roll
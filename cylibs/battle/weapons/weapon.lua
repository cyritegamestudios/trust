local Item = require('resources/resources').Item

---------------------------
-- Wrapper around a weapon
-- @class module
-- @name Weapon
local Weapon = {}
Weapon.__index = Weapon
Weapon.__class = "Weapon"

-------
-- Default initializer for a weapon.
-- @tparam string roll_name Localized name of the roll
-- @tparam Boolean use_crooked_cards Whether to use Crooked Cards
-- @treturn Roll A roll
function Weapon.new(weapon_id)
    local weapon = Item:get({ id = weapon_id })

    local self = setmetatable({
        weapon_id = weapon_id;
        weapon_name = weapon.en;
        combat_skill = weapon.skill;
    }, Weapon)
    
    return self
end

-------
-- Returns the name of the weapon skill.
-- @treturn string Weapon skill name
function Weapon:get_name()
    return self.weapon_name
end

-------
-- Returns the combat skill id of the weapon.
-- @treturn number Combat skill id of the weapon
function Weapon:get_combat_skill()
    return self.combat_skill
end

return Weapon
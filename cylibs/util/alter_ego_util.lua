---------------------------
-- Utility functions for alter egos.
-- @class module
-- @name alter_ego_util

local alter_ego_util = {}

---
-- Returns a list of alter egos that cannot be targeted.
--
-- @param zone_id (string) The identifier of the zone to be checked.
-- @return (boolean) True if the zone is a city, false otherwise.
---
function alter_ego_util.untargetable_alter_egos()
    return S{
        'Kupofried',
        'Moogle',
        'Brygid',
        'Kuyin Hathdenna',
        'Cornelia',
        'Sakura',
        'Star Sibyl'
    }
end

return alter_ego_util
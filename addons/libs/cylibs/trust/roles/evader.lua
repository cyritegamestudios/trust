local monster_util = require('cylibs/util/monster_util')

local Evader = setmetatable({}, {__index = Role })
Evader.__index = Evader

state.AutoAvoidAggroMode = M{['description'] = 'Auto Avoid Aggro Mode', 'Auto', 'Off'}
state.AutoAvoidAggroMode:set_description('Auto', "Okay, I'll try not to aggro monsters.")

local magic_aggro_mobs = L{
    'Elemental'
}

function Evader.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Evader)

    return self
end

function Evader:destroy()
    Role.destroy(self)
end

function Evader:on_add()
    Role.on_add(self)
end

function Evader:target_change(target_index)
    Role.target_change(self, target_index)
end

function Evader:tic(new_time, old_time)
    if state.AutoAvoidAggroMode.value == 'Off' then
        return
    end

    if self:check_nearby_mobs() then
        windower.send_command('input // trust stop')
    else
        windower.send_command('input // trust start')
    end
end

function Evader:check_nearby_mobs()
    local nearby_mobs = windower.ffxi.get_mob_array()
    for _, target in pairs(nearby_mobs) do
        if target and target.distance:sqrt() < 20 and target.status == 0 and not party_util.is_party_claimed(target.id) then
            if target ~= nil and monster_util.aggroes_by_magic(target.id) then
                return true
            end
        end
    end
    return false
end

function Evader:allows_duplicates()
    return false
end

function Evader:get_type()
    return "evader"
end

return Evader
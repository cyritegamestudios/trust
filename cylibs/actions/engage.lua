---------------------------
-- Engages a target.
-- @class module
-- @name EngageAction

local alter_ego_util = require('cylibs/util/alter_ego_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local packets = require('packets')

local Action = require('cylibs/actions/action')
local EngageAction = setmetatable({}, {__index = Action })
EngageAction.__index = EngageAction

function EngageAction.new(target_index)
    local conditions = L{
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), EngageAction)
    self.dispose_bag = DisposeBag.new()
    return self
end

function EngageAction:destroy()
    self.dispose_bag:destroy()

    Action.destroy(self)
end

function EngageAction:perform()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    if not target then
        self:complete(false)
        return
    end
    if player.status == 'Engaged' then
        local p = packets.new('outgoing', 0x01A)

        p['Target'] = target.id
        p['Target Index'] = target.index
        p['Category'] = 0x0F -- Switch target
        p['Param'] = 0
        p['X Offset'] = 0
        p['Z Offset'] = 0
        p['Y Offset'] = 0

        packets.inject(p)
    else
        local p = packets.new('outgoing', 0x01A)

        p['Target'] = target.id
        p['Target Index'] = target.index
        p['Category'] = 0x02 -- Engage
        p['Param'] = 0
        p['X Offset'] = 0
        p['Z Offset'] = 0
        p['Y Offset'] = 0

        packets.inject(p)
    end

    packets.inject(packets.new('incoming', 0x058, {
        ['Player'] = windower.ffxi.get_player().id,
        ['Target'] = target.id,
        ['Player Index'] = windower.ffxi.get_player().index,
    }))

    self.dispose_bag:add(WindowerEvents.TargetIndexChanged:addAction(function(mob_id, target_index)
        if windower.ffxi.get_player().id == mob_id then
            if self.target_index == target_index then
                self:complete(true)
            end
        end
    end), WindowerEvents.TargetIndexChanged)
end

function EngageAction:gettype()
    return "engageaction"
end

function EngageAction:getrawdata()
    local res = {}
    return res
end

function EngageAction:tostring()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    return 'Engaging → '..target.name
end

function EngageAction:debug_string()
    local mob = windower.ffxi.get_mob_by_index(self.target_index)
    return "EngageAction: %s (%d)":format(mob.name, mob.id)
end

return EngageAction




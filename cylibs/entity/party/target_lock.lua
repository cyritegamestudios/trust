local DisposeBag = require('cylibs/events/dispose_bag')
local Entity = require('cylibs/entity/entity')
local Event = require('cylibs/events/Luvent')

local TargetLock = setmetatable({}, {__index = Entity })
TargetLock.__index = TargetLock
TargetLock.__class = "TargetLock"

TargetLock.Identifier = 0

-- Event called when the party member's target changes.
function TargetLock:on_target_change()
    return self.target_change
end

-- Event called when the target is KOed.
function TargetLock:on_target_ko()
    return self.target_ko
end

function TargetLock.new(target_index, party)
    local target_id = windower.ffxi.get_mob_by_index(target_index).id
    local self = setmetatable(Entity.new(target_id), TargetLock)

    party.target_tracker:add_mob_by_index(target_index)

    self.target_index = target_index
    self.target_id = windower.ffxi.get_mob_by_index(target_index).id
    self.dispose_bag = DisposeBag.new()
    self.target_change = Event.newEvent()
    self.target_ko = Event.newEvent()

    return self
end

function TargetLock:destroy()
    self.dispose_bag:destroy()

    self.target_change:removeAllActions()
    self.target_ko:removeAllActions()
end

function TargetLock:monitor()
    if self.is_monitoring then
        return false
    end
    self.is_monitoring = true

    self.dispose_bag:add(WindowerEvents.MobKO:addAction(function(mob_id, _)
        if self.target_id == mob_id then
            self:on_target_change():trigger(self, nil, self.target_index)
            self:on_target_ko():trigger(self, self.target_index)
        end
    end), WindowerEvents.MobKO)
end

function TargetLock:get_name()
    return ""
end

function TargetLock:is_valid()
    local mob = windower.ffxi.get_mob_by_index(self.target_index)
    return mob ~= nil and mob.hpp > 0
end

-------
-- Returns the index of the current target.
-- @treturn number Index of the current target, or nil if none.
function TargetLock:get_target_index()
    return self.target_index
end

return TargetLock
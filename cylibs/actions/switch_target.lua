---------------------------
-- Switch to another target.
-- @class module
-- @name SwitchTargetAction

local alter_ego_util = require('cylibs/util/alter_ego_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local packets = require('packets')
local Timer = require('cylibs/util/timers/timer')

local Action = require('cylibs/actions/action')
local SwitchTargetAction = setmetatable({}, {__index = Action })
SwitchTargetAction.__index = SwitchTargetAction

function SwitchTargetAction.new(target_index, num_retries)
    local conditions = L{
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), SwitchTargetAction)

    self.target_index = target_index
    self.num_retries = num_retries or 0
    self.retry_count = 0
    self.dispose_bag = DisposeBag.new()

    self:debug_log_create(self:gettype())

    return self
end

function SwitchTargetAction:destroy()
    self.dispose_bag:destroy()

    self:debug_log_destroy(self:gettype())

    Action.destroy(self)
end

function SwitchTargetAction:perform()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    if not target then
        self:complete(false)
        return
    end

    self.dispose_bag:add(WindowerEvents.TargetIndexChanged:addAction(function(mob_id, target_index)
        if windower.ffxi.get_player().id == mob_id then
            if self.target_index == target_index and windower.ffxi.get_mob_by_id(windower.ffxi.get_player().id).status == 'Engaged' then
                self:complete(true)
            end
        end
    end), WindowerEvents.TargetIndexChanged)

    self.retry_timer = Timer.scheduledTimer(0.5)
    self.retry_timer:onTimeChange():addAction(function(_)
        self.retry_count = self.retry_count + 1
        if self.retry_count >= self.num_retries or not self:is_valid_target() then
            self:complete(false)
            return
        end
        self:target_mob(target)
    end)

    self.dispose_bag:addAny(L{ self.retry_timer })

    self.retry_timer:start()
end

function SwitchTargetAction:is_valid_target()
    return Condition.check_conditions(L{ ValidTargetCondition.new(), MinHitPointsPercentCondition.new(1) }, self.target_index)
end

function SwitchTargetAction:target_mob(target)
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
end

function SwitchTargetAction:gettype()
    return "switchtargetaction"
end

function SwitchTargetAction:getrawdata()
    local res = {}
    return res
end

function SwitchTargetAction:tostring()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    return 'Targeting → '..target.name
end

function SwitchTargetAction:debug_string()
    local mob = windower.ffxi.get_mob_by_index(self.target_index)
    return "SwitchTargetAction: %s (%d)":format(mob.name, mob.id)
end

return SwitchTargetAction




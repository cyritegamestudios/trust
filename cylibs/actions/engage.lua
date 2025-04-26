---------------------------
-- Engages a target.
-- @class module
-- @name EngageAction

local alter_ego_util = require('cylibs/util/alter_ego_util')
local ClaimedCondition = require('cylibs/conditions/claimed')
local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local packets = require('packets')
local Timer = require('cylibs/util/timers/timer')
local UnclaimedCondition = require('cylibs/conditions/unclaimed')

local Action = require('cylibs/actions/action')
local EngageAction = setmetatable({}, {__index = Action })
EngageAction.__index = EngageAction

function EngageAction.new(target_index, use_assist_response)
    local conditions = L{
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
    }
    local alliance = player.alliance
    if alliance then
        conditions:append(ConditionalCondition.new(L{ ClaimedCondition.new(alliance:get_alliance_member_ids()), UnclaimedCondition.new() }, Condition.LogicalOperator.Or))
    end
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), EngageAction)
    self.use_assist_response = use_assist_response
    self.dispose_bag = DisposeBag.new()
    return self
end

function EngageAction:destroy()
    self.dispose_bag:destroy()

    Action.destroy(self)
end

function EngageAction:perform()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    if not target or not self:can_perform() then
        self:complete(false)
        return
    end

    if player.status == 'Engaged' then
        self:log_target(target, 'switch_target')

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
        self:log_target(target, 'engage')

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

    if self.use_assist_response then
        packets.inject(packets.new('incoming', 0x058, {
            ['Player'] = windower.ffxi.get_player().id,
            ['Target'] = target.id,
            ['Player Index'] = windower.ffxi.get_player().index,
        }))
    end

    self.dispose_bag:add(WindowerEvents.TargetIndexChanged:addAction(function(mob_id, target_index)
        if windower.ffxi.get_player().id == mob_id then
            if self.target_index == target_index then
                self:complete(true)
            end
        end
    end), WindowerEvents.TargetIndexChanged)

    self.timer = Timer.scheduledTimer(0.5)
    self.timer:onTimeChange():addAction(function(_)
        if not self:can_perform() then
            self:complete(false)
            return
        end
    end)

    self.dispose_bag:addAny(L{ self.timer })

    self.timer:start()
end

function EngageAction:log_target(target, action)
    local MobFilter = require('cylibs/battle/monsters/mob_filter')
    local PartyClaimedCondition = require('cylibs/conditions/party_claimed')

    local mob_filter = MobFilter.new(player.alliance, 25)
    local aggroed_mobs = mob_filter:get_nearby_mobs(L{ MobFilter.Type.PartyClaimed }):filter(function(mob)
        return mob.hpp > 0 and not L{ 2, 3 }:contains(mob.status) and mob.index ~= target.index
    end)

    logger.notice('EngageAction', 'perform', action, 'num_party_aggroed_mobs', aggroed_mobs:length() or 0)

    for mob in aggroed_mobs:it() do
        logger.notice('EngageAction', 'perform', action, 'party_aggroed_mobs', mob.name, mob.hpp, mob.status, mob.claim_id, mob.index, Condition.check_conditions(L{ PartyClaimedCondition.new(true) }, mob.index))
    end

    if windower.ffxi.get_player().target_index then
        local current_mob = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().target_index)
        if current_mob then
            logger.notice('EngageAction', 'perform', action, player.status, 'current', current_mob.name, current_mob.index, current_mob.hpp, current_mob.status, current_mob.claim_id or 'unclaimed', current_mob.distance:sqrt(),
                    'new', target.name, target.index, target.hpp, target.status, target.claim_id or 'unclaimed', target.distance:sqrt())
        end
        if player.status == 'Engaged' and windower.ffxi.get_player().target_index ~= self.target_index then
            logger.error('EngageAction', 'perform', action, 'engaged to', windower.ffxi.get_player().target_index or 'none', 'but trying to engage', self.target_index or 'none')
        end
    end
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




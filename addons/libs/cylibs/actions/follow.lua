require('actions')
require('vectors')
require('math')
require('logger')
require('lists')

local packets = require('packets')

local Action = require('cylibs/actions/action')
local FollowAction = setmetatable({}, {__index = Action })
FollowAction.__index = FollowAction

function FollowAction.new(target_id)
	local self = setmetatable(Action.new(0, 0, 0), FollowAction)
	self.target_id = target_id
	self.retry_count = 0
 	return self
end

function FollowAction:can_perform()
	if self:is_cancelled() then
		return false
	end
	local mob = windower.ffxi.get_mob_by_id(self:gettargetid())
	if not mob or mob.hpp <= 0 or not mob.valid_target then
		return false
	end
	if mob.claim_id ~= 0 then
		local claimed_by = windower.ffxi.get_mob_by_id(mob.claim_id)
		if claimed_by ~= nil and not (claimed_by.in_party or claimed_by.in_alliance) then
			return false
		end
	end
	return true
end

function FollowAction:perform()
	self:follow_target(self:gettargetid())
end

function FollowAction:follow_target(target_id)
	if self:is_cancelled() or self:is_completed() then
		return
	end		

	local mob = windower.ffxi.get_mob_by_id(target_id)
	
	local player = windower.ffxi.get_player()
	if player.follow_index ~= mob.index then
		windower.ffxi.follow(mob.index)
		windower.ffxi.run()
	end
	
	self:complete(true)
end

function FollowAction:gettargetid()
	return self.target_id
end

function FollowAction:gettype()
	return "followaction"
end

function FollowAction:getrawdata()
	local res = {}
	res.followaction = {}
	return res
end

function FollowAction:tostring()
	local mob = windower.ffxi.get_mob_by_id(self:gettargetid())
    return "FollowAction: %s (%d)":format(mob.name, mob.id)
end

return FollowAction




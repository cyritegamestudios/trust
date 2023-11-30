---------------------------
-- Action representing the player targeting a monster.
-- @class module
-- @name TargetAction

local monster_util = require('cylibs/util/monster_util')
local packets = require('packets')

local Action = require('cylibs/actions/action')
local TargetAction = setmetatable({}, {__index = Action })
TargetAction.__index = TargetAction

function TargetAction.new(target_id, player)
	local self = setmetatable(Action.new(0, 0, 0), TargetAction)
	self.target_id = target_id
	self.player = player
	self.user_events = {}
 	return self
end

function TargetAction:destroy()
	if self.user_events then
		for _,event in pairs(self.user_events) do
			windower.unregister_event(event)
		end
	end
	Action.destroy(self)
end

function TargetAction:can_perform()
	if self:is_cancelled() then
		return false
	end

	if not battle_util.is_valid_monster_target(self.target_id) then
		return false
	end

	--if not monster_util.is_unclaimed(self.target_id) and party_util.not_party_claimed(self.target_id) then
	--	return false
	--end

	return true
end

function TargetAction:perform()
	packets.inject(packets.new('incoming', 0x058, {
		['Player'] = self.player:get_mob().id,
		['Target'] = self.target_id,
		['Player Index'] = self.player:get_mob().index,
	}))
	self:complete(true)
end


function TargetAction:gettype()
	return "targetaction"
end

function TargetAction:getrawdata()
	local res = {}
	return res
end

function TargetAction:tostring()
	local target = windower.ffxi.get_mob_by_id(self.target_id)
	return 'Targeting → '..target.name
end

function TargetAction:debug_string()
	local mob = windower.ffxi.get_mob_by_id(self.target_id)
    return "TargetAction: %s (%d)":format(mob.name, mob.id)
end

return TargetAction




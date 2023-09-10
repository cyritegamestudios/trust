require('luau')
require('tables')
require('lists')
require('logger')

local WalkAction = require('cylibs/actions/walk')
local NpcAction = require('cylibs/actions/npc')
local WaitAction = require('cylibs/actions/wait')

local Path = {}
Path.__index = Path

function Path.new(settings)
  local self = setmetatable({
	actions = L{};
	autoreverse = settings.autoreverse;
	repeatdelay = settings.repeatdelay;
	zoneid = settings.zoneid;
	user_events = {};
  }, Path)
  if settings.zoneid == nil then
	notice('pee')
  end
  self.actions = Path.parse_actions(L{table.extract(settings.actions)})
  return self
end

function Path.parse_actions(actions)
	notice(actions)
	local result = T{}
	--for action in actions:it() do
	--	local new_action = nil
		--notice(action)
		--local index = tonumber(i)
		--if index then
		--	notice(action:tostring())
		--	result[index] = WalkAction.new(action.x, action.y, action.z)
		--end
	--end
	return result
end

function Path:get_actions()
	return self.actions
end

return Path




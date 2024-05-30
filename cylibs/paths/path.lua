local serializer_util = require('cylibs/util/serializer_util')

local Path = {}
Path.__index = Path
Path.__class = Path

function Path.new(zone_id, actions, auto_reverse, reverse_delay)
	local self = setmetatable({}, Path)

	self.zone_id = zone_id
	self.actions = actions
	self.auto_reverse = auto_reverse
	self.reverse_delay = reverse_delay

	return self
end

function Path.from_file(file_path)
	local file_path = windower.addon_path..file_path
	if not file_path:sub(-#".lua") == ".lua" then
		file_path = file_path..".lua"
	end
	if windower.file_exists(file_path) then
		local load_path, err = loadfile(file_path)
		if err then
			return nil
		end
		local path = load_path()
		return Path.new(path.zone_id, path.actions, path.auto_reverse, path.reverse_delay)
	else
		return nil
	end
end

function Path:reverse()
	local actions = self:get_actions():copy(true):reverse()
	return Path.new(self:get_zone_id(), actions, self:should_reverse(), self:get_reverse_delay())
end

function Path:should_reverse()
	return self.auto_reverse
end

function Path:get_reverse_delay()
	return self.reverse_delay
end

function Path:set_zone_id(zone_id)
	self.zone_id = zone_id
end

function Path:get_zone_id()
	return self.zone_id
end

function Path:get_actions()
	return self.actions
end

function Path:serialize()
	return "Path.new(" .. serializer_util.serialize_args(self.zone_id, self.actions, self.auto_reverse, self.reverse_delay) .. ")"
end

return Path




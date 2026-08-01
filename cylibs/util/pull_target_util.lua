---------------------------
-- Utility functions for pull targets.
--
-- Pull targets are stored in PullSettings.TargetIds as { Id = number, Name = string }.
-- The name is persisted so it can still be displayed when the mob isn't in the
-- current zone and can no longer be looked up by id.
--
-- @class module
-- @name PullTargetUtil

_libs = _libs or {}

require('lists')

local pull_target_util = {}

_raw = _raw or {}

_libs.pull_target_util = pull_target_util

-------
-- Returns the name of the mob with the given id.
-- @tparam number targetId Mob id.
-- @treturn string Mob name, or nil if the mob isn't in the current zone.
function pull_target_util.get_mob_name(targetId)
    local mob = windower.ffxi.get_mob_by_id(targetId)
    if mob and mob.name and mob.name ~= '' then
        return mob.name
    end
    return nil
end

-------
-- Creates a new pull target.
-- @tparam number targetId Mob id.
-- @tparam string targetName (optional) Mob name, resolved from the current zone if omitted.
-- @treturn table The new pull target.
function pull_target_util.new(targetId, targetName)
    return {
        Id = targetId,
        Name = targetName or pull_target_util.get_mob_name(targetId)
    }
end

-------
-- Returns the mob id of a pull target.
-- @tparam table target Pull target.
-- @treturn number Mob id.
function pull_target_util.get_id(target)
    return target.Id
end

-------
-- Returns the saved mob name of a pull target.
-- @tparam table target Pull target.
-- @treturn string Mob name, or nil if one hasn't been saved.
function pull_target_util.get_name(target)
    if target == nil then
        return nil
    end
    return target.Name
end

-------
-- Updates the saved name of a pull target if its mob is in the current zone.
-- @tparam table target Pull target.
-- @treturn boolean True if the name changed.
function pull_target_util.update_name(target)
    local mobName = pull_target_util.get_mob_name(target.Id)
    if mobName and target.Name ~= mobName then
        target.Name = mobName
        return true
    end
    return false
end

return pull_target_util

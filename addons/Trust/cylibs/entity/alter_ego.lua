---------------------------
-- Wrapper class around an alter ego.
-- @class module
-- @name AlterEgo

local buff_util = require('cylibs/util/buff_util')
local PartyMember = require('cylibs/entity/party_member')

local AlterEgo = setmetatable({}, {__index = PartyMember })
AlterEgo.__index = AlterEgo

local BuffTracker = require('cylibs/battle/buff_tracker')

-------
-- Default initializer for an AlterEgo.
-- @tparam number id Mob id
-- @treturn AlterEgo An alter ego
function AlterEgo.new(id)
    local self = setmetatable(PartyMember.new(id), AlterEgo)
    self.buff_tracker = BuffTracker.new()
    return self
end

-------
-- Stops tracking the player's actions and disposes of all registered event handlers.
function AlterEgo:destroy()
    PartyMember.destroy(self)

    self.buff_tracker:destroy()
end

-------
-- Starts monitoring the player's actions. Note that it is necessary to call this before events will start being
-- triggered. You should call destroy() to clean up listeners when you are done.
function AlterEgo:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.buff_tracker:on_gain_buff():addAction(function(target_id, buff_id)
        if target_id == self:get_id() then
            local buff_ids = self:get_buff_ids()
            buff_ids:add(buff_id)

            self:update_buffs(buff_ids)
        end
    end)

    self.buff_tracker:on_lose_buff():addAction(function(target_id, buff_id)
        if target_id == self:get_id() then
            local buff_ids = self:get_buff_ids()
            buff_ids:remove(buff_id)

            self:update_buffs(buff_ids)
        end
    end)

    self.buff_tracker:monitor()
end

-------
-- Filters a list of buffs and updates the player's cached list of buffs.
-- @tparam list List of buff ids (see buffs.lua)
function AlterEgo:update_buffs(buff_ids)
    local buff_ids = S(buff_util.buffs_for_buff_ids(buff_ids))
    local delta = set.sdiff(buff_ids, self.buff_ids)
    for buff_id in delta:it() do
        if buff_ids:contains(buff_id) then
            self:on_gain_buff():trigger(self, buff_id)
        else
            self:on_lose_buff():trigger(self, buff_id)
        end
    end
    self.buff_ids = buff_ids
end

-------
-- Returns a list of the party member's buffs.
-- @treturn List of localized buff names (see buffs.lua)
function AlterEgo:get_buffs()
    return L(self.buff_ids:map(function(buff_id)
        return res.buffs:with('id', buff_id).enl
    end))
end

-------
-- Returns true if the party member has the given buff active.
-- @tparam number buff_id Buff id (see buffs.lua)
-- @treturn boolean True if the buff is active, false otherwise
function AlterEgo:has_buff(buff_id)
    return self.buff_ids:contains(buff_id)
end

-------
-- Returns whether this party member is a trust.
-- @treturn Boolean True if the party member is a trust, and false otherwise
function AlterEgo:is_trust()
    return true
end

return AlterEgo
---------------------------
-- Wrapper class around an alter ego.
-- @class module
-- @name AlterEgo

local buff_util = require('cylibs/util/buff_util')
local logger = require('cylibs/logger/logger')
local PartyMember = require('cylibs/entity/party_member')
local trusts = require('cylibs/res/trusts')

local AlterEgo = setmetatable({}, {__index = PartyMember })
AlterEgo.__index = AlterEgo

local BuffTracker = require('cylibs/battle/buff_tracker')

-------
-- Default initializer for an AlterEgo.
-- @tparam number id Mob id
-- @tparam string name Mob name
-- @treturn AlterEgo An alter ego
function AlterEgo.new(id, name)
    local self = setmetatable(PartyMember.new(id), AlterEgo)
    self.name = name
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

    self.dispose_bag:add(WindowerEvents.CharacterUpdate:addAction(function(mob_id, name, hp, hpp, mp, mpp, tp, main_job_id, sub_job_id)
        if self:get_id() == mob_id then
            self.name = name
            self.mp = mp
            self.mpp = mpp
            self.tp = tp

            self:set_hp(hp)
            self:set_hpp(hpp)
        end
    end), WindowerEvents.CharacterUpdate)

    self.dispose_bag:add(WindowerEvents.PositionChanged:addAction(function(mob_id, x, y, z)
        if self:get_id() == mob_id then
            self:set_position(x, y, z)
        end
    end), WindowerEvents.PositionChanged)

    self.buff_tracker:on_gain_buff():addAction(function(target_id, buff_id)
        if target_id == self:get_id() then
            logger.notice(self:get_name(), "gained the effect of", res.buffs[buff_id].en)

            local new_buff_ids = self:get_buff_ids():copy(true)
            new_buff_ids:append(buff_id)

            self:update_buffs(new_buff_ids)

            -- We do not want this growing infinitely and don't rely on the
            -- actual state
            self.buff_tracker:reset()
        end
    end)

    self.buff_tracker:on_lose_buff():addAction(function(target_id, buff_id)
        if target_id == self:get_id() then
            logger.notice(self:get_name(), "lost the effect of", res.buffs[buff_id].en)

            local new_buff_ids = self:get_buff_ids():copy(true):filter(function(existing_buff_id) return existing_buff_id ~= buff_id  end)

            self:update_buffs(new_buff_ids)

            -- We do not want this growing infinitely and don't rely on the
            -- actual state
            self.buff_tracker:reset()
        end
    end)

    self.buff_tracker:monitor()
end

-------
-- Filters a list of buffs and updates the player's cached list of buffs.
-- @tparam list List of buff ids (see buffs.lua)
function AlterEgo:update_buffs(buff_ids)
    local buff_ids = L(buff_util.buffs_for_buff_ids(buff_ids))
    local old_buff_ids = self.buff_ids

    self.buff_ids = buff_ids

    local delta = list.diff(old_buff_ids, buff_ids)

    for buff_id in delta:it() do
        if buff_ids:contains(buff_id) then
            self:on_gain_buff():trigger(self, buff_id)
        else
            self:on_lose_buff():trigger(self, buff_id)
        end
    end
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

-------
-- Returns the main job short (e.g. BLU, RDM, WAR)
-- @treturn string Main job short, or nil if unknown
function AlterEgo:get_main_job_short()
    if self:get_name() == nil then
        return 'NON'
    end
    local trust = trusts:with('en', self:get_name()) or trusts:with('enl', self:get_name())
    if trust then
        return trust.main_job_short
    end
    return 'NON'
end

-------
-- Returns the sub job short (e.g. BLU, RDM, WAR)
-- @treturn string Sub job short, or nil if unknown
function AlterEgo:get_sub_job_short()
    if self:get_name() == nil then
        return 'NON'
    end
    local trust = trusts:with('en', self:get_name()) or trusts:with('enl', self:get_name())
    if trust then
        return trust.sub_job_short
    end
    return 'NON'
end

-------
-- Returns the zone id of the alter ego.
-- @treturn number Zone id (see res/zones.lua)
function AlterEgo:get_zone_id()
    return windower.ffxi.get_info().zone
end

return AlterEgo
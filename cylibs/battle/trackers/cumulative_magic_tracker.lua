---------------------------
-- Tracks cumulative magic effects on the target (e.g. Stoneja).
-- @class module
-- @name CumulativeMagicTracker

local buffs_ext = require('cylibs/res/buffs')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local Timer = require('cylibs/util/timers/timer')
local Renderer = require('cylibs/ui/views/render')
local GainDebuffMessage = require('cylibs/messages/gain_buff_message')
local LoseDebuffMessage = require('cylibs/messages/lose_buff_message')
local monster_util = require('cylibs/util/monster_util')
local weapon_skills_ext = require('cylibs/res/weapon_skills')


local CumulativeMagicEffect = {}
CumulativeMagicEffect.__index = CumulativeMagicEffect
CumulativeMagicEffect.__class = "CumulativeMagicEffect"

function CumulativeMagicEffect.new(spell_id, cumulative_effect_duration)
    local self = setmetatable({}, CumulativeMagicEffect)
    self.spell_id = spell_id
    self.level = 0
    self.expiration_time = os.time() + (cumulative_effect_duration or 60)
    return self
end

function CumulativeMagicEffect:is_same_effect(spell_id)
    return self.spell_id == spell_id
end

function CumulativeMagicEffect:get_spell_name()
    return res.spells[self.spell_id].en
end

function CumulativeMagicEffect:get_element()
    return res.elements[res.spells[self.spell_id].element].en
end

function CumulativeMagicEffect:get_level()
    return self.level
end

function CumulativeMagicEffect:set_level(level)
    self.level = level
end

function CumulativeMagicEffect:get_expiration_time()
    return self.expiration_time
end

function CumulativeMagicEffect:get_time_remaining()
    return math.max(0, self:get_expiration_time() - os.time())
end

function CumulativeMagicEffect:is_expired()
    return self:get_time_remaining() <= 0
end


local CumulativeMagicTracker = {}
CumulativeMagicTracker.__index = CumulativeMagicTracker
CumulativeMagicTracker.__class = 'CumulativeMagicTracker'


-- Event called when the target gains a cumulative effect.
function CumulativeMagicTracker:on_gain_cumulative_effect()
    return self.gain_cumulative_effect
end

-- Event called when the target loses a cumulative effect.
function CumulativeMagicTracker:on_lose_cumulative_effect()
    return self.lose_cumulative_effect
end

-------
-- Default initializer for a new cumulative magic effect tracker.
-- @treturn BuffTracker A cumulative magic tracker
function CumulativeMagicTracker.new(mob_id)
    local self = setmetatable({
        mob_id = mob_id;
        cumulative_effect_duration = 110;
        effect_dispose_bag = DisposeBag.new();
        dispose_bag = DisposeBag.new();
    }, CumulativeMagicTracker)

    self.gain_cumulative_effect = Event.newEvent()
    self.lose_cumulative_effect = Event.newEvent()

    return self
end

function CumulativeMagicTracker:destroy()
    self.dispose_bag:destroy()

    self.gain_cumulative_effect:removeAllActions()
    self.lose_cumulative_effect:removeAllActions()
end

-------
-- Starts tracking the player's actions. Note that it is necessary to call this before buffs will be tracked.
function CumulativeMagicTracker:monitor()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.dispose_bag:add(WindowerEvents.Action:addAction(function(action)
        if action.targets == nil then return end

        for _,target in pairs(action.targets) do
            if target.id == self.mob_id then
                if action.category == 4 then
                    self:update_effect(action.param)
                end
            end
        end
    end), WindowerEvents.Action)
end

function CumulativeMagicTracker:tic(_, _)
    if self.current_effect and self.current_effect:is_expired() then
        self:reset()
    end
end

-------
-- Resets the cumulative magic tracker.
function CumulativeMagicTracker:reset()
    self.effect_dispose_bag:destroy()

    if self.current_effect then
        local old_effect = self.current_effect
        self.current_effect = nil
        self:on_lose_cumulative_effect():trigger(self, old_effect)
    end
end

function CumulativeMagicTracker:update_effect(spell_id)
    if not self:is_cumulative_magic_spell(spell_id) then
        return
    end
    if self.current_effect == nil or not self.current_effect:is_same_effect(spell_id) then
        self:reset()

        self.current_effect = CumulativeMagicEffect.new(spell_id, self.cumulative_effect_duration)

        local effect_timer = Timer.scheduledTimer(self.current_effect:get_time_remaining(), 0)
        effect_timer:onTimeChange():addAction(function(_)
            self:reset()
        end)

        self.effect_dispose_bag:addAny(L{ effect_timer })

        effect_timer:start()
    end
    self.current_effect:set_level(self.current_effect:get_level() + 1)

    self:on_gain_cumulative_effect():trigger(self, self.current_effect)

    logger.notice(self.__class, 'update_effect', self.current_effect:get_spell_name(), self.current_effect:get_level(), self.current_effect:get_time_remaining())
end

function CumulativeMagicTracker:is_cumulative_magic_spell(spell_id)
    local all_spell_ids = S(L{ 'Firaja', 'Blizzaja', 'Aeroja', 'Stoneja', 'Thundaja', 'Waterja', 'Comet' }:map(function(spell_name)
        return res.spells:with('en', spell_name).id
    end))
    return all_spell_ids:contains(spell_id)
end

-------
-- Returns the current cumulative magic effect.
-- @treturn CumulativeMagicEffect Cumulative magic effect, or nil if none
function CumulativeMagicTracker:get_current_effect()
    return self.current_effect
end

return CumulativeMagicTracker
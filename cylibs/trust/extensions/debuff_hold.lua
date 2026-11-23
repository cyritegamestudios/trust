---------------------------
-- DebuffHold: while the player's TP is at or above the threshold,
-- debuffs hold off until the weaponskill has been used.
--
-- ENABLED in this build (DEBUFF_HOLD_ENABLED = true below, at the
-- user's request). With the flag set to false, this module
-- subscribes nothing, the shared CoreAI.debuff_hold flag is never
-- set, and the Debuffer casts exactly as it always has.
--
-- What it does when enabled (checked once per second on the CoreAI
-- 'tic' event): if player TP >= TP_HOLD_THRESHOLD, the hold is set
-- and NO Debuffer gambit can fire — Foe Requiem VII and any other
-- debuff alike (the Debuffer adds the condition to every debuff
-- gambit). The moment the weaponskill goes off and TP drops below
-- the threshold, the hold clears and debuffs cast as normal. The
-- puller's Carnage Elegy and the singer are untouched (they are
-- not Debuffer gambits).
--
-- (This module was first built as a Requiem-only hold and renamed
-- when it was widened to all debuffs.)
--
-- The check is exposed as DebuffHold.evaluate(ctx) so it can be
-- harness-tested without the game.
-- @class module
-- @name DebuffHold

-- Flip to true to enable the debuff TP hold.
local DEBUFF_HOLD_ENABLED = true

-- Hold debuffs at or above this much TP (500 = halfway to a
-- weaponskill). Edit to taste.
local TP_HOLD_THRESHOLD = 500

local DebuffHold = {}
DebuffHold.__class = "DebuffHold"

--- Should debuffs be held for this context?
-- @tparam table ctx CoreAI context (or a hand-built table of the
--   same shape, for testing)
-- @treturn boolean True if TP is at/above the threshold
function DebuffHold.evaluate(ctx)
    if not ctx or not ctx.player or not ctx.player.tp then
        return false
    end
    return ctx.player.tp >= TP_HOLD_THRESHOLD
end

local last_hold = false

local function log_hold_change(hold)
    local ok, w = pcall(function() return windower end)
    if ok and w and w.addon_message then
        pcall(w.addon_message, 207, '[CoreAI] Debuff hold '
            .. (hold and 'ON' or 'OFF') .. ' (tp_threshold)')
    end
end

local function set_hold(hold)
    local ok, core_ai = pcall(require, 'cylibs/trust/extensions/core_ai')
    if ok and core_ai and core_ai.set_debuff_hold then
        core_ai.set_debuff_hold(hold, hold and 'tp_threshold' or nil)
    end
end

--- Module init: subscribe to the CoreAI tic.
-- With DEBUFF_HOLD_ENABLED = false this would subscribe nothing.
-- @tparam table api CoreAI module api { on, context, decide }
function DebuffHold.init(api)
    if not DEBUFF_HOLD_ENABLED then
        return
    end
    api.on('tic', function(ctx)
        local hold = DebuffHold.evaluate(ctx)
        if hold ~= last_hold then
            last_hold = hold
            log_hold_change(hold)
        end
        set_hold(hold)
    end)
end

--- Module destroy: clear the hold so nothing outlives the module.
function DebuffHold.destroy()
    last_hold = false
    set_hold(false)
end

--- Is the behaviour enabled? (the flag at the top of this file)
-- @treturn boolean
function DebuffHold.is_enabled()
    return DEBUFF_HOLD_ENABLED
end

return DebuffHold

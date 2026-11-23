---------------------------
-- CoreAI: a small, failure-isolated extension layer for Trust.
--
-- It provides three things and nothing more:
--   1. A hook bus (CoreAI.on / CoreAI.emit) so new code can react to
--      game events without editing core files.
--   2. A defensive context snapshot (CoreAI.context) and a one-second
--      tic driver (CoreAI.tic, wired in cylibs/trust/trust.lua) that
--      derives events from polled state -- no packet hooks.
--   3. A scored decision helper (CoreAI.decide) plus a module registry
--      (CoreAI.register_module) with leak-safe teardown (CoreAI.destroy).
--
-- Design rules (learned from the Luvent/DisposeBag audit fixes):
--   - Every handler runs under pcall: one bad handler can never break
--     Trust or the other handlers.
--   - Emit iterates a snapshot and re-checks registration before each
--     call, so a handler disposed during emit does not fire.
--   - Every windower access is nil-guarded and pcall-wrapped. If the
--     game state cannot be read, context() returns what it could read
--     instead of throwing.
--   - destroy() is snapshot-first and nil-safe: one bad module cannot
--     abort the teardown of the others.
--
-- See EXTENDING.md in this folder for how to add a module.
-- @class module
-- @name CoreAI

local CoreAI = {}
CoreAI.__class = "CoreAI"

-------
-- Hook bus
-------

-- event name -> array of entries { fn = function, active = boolean }
local handlers = {}
-- every handle ever created, so destroy() can dispose all of them
local all_handles = {}
-- module name -> module table
local modules = {}
-- module name -> array of handles created through that module's api
local module_handles = {}

local function new_handle(entry)
    local handle = { _entry = entry }
    function handle.dispose()
        if entry.active then
            entry.active = false
        end
    end
    function handle.is_active()
        return entry.active == true
    end
    return handle
end

--- Subscribe to an event.
-- @tparam string event Event name (see EXTENDING.md for the list)
-- @tparam function fn Handler, called with the event's arguments
-- @treturn table Handle with dispose() and is_active()
function CoreAI.on(event, fn)
    if type(event) ~= 'string' or type(fn) ~= 'function' then
        return new_handle({ active = false })
    end
    local entry = { fn = fn, active = true }
    handlers[event] = handlers[event] or {}
    table.insert(handlers[event], entry)
    local handle = new_handle(entry)
    table.insert(all_handles, handle)
    return handle
end

--- Emit an event to all subscribed handlers.
-- Each handler runs under pcall; a throwing handler is skipped and
-- does not affect the others. Handlers disposed during this emit
-- (by an earlier handler) do not fire.
-- @tparam string event Event name
-- @param ... Arguments passed to each handler
-- @treturn number How many handlers ran without error
function CoreAI.emit(event, ...)
    local list = handlers[event]
    if not list then
        return 0
    end
    -- Snapshot first: handlers may subscribe/dispose during emit.
    local snapshot = {}
    for i = 1, #list do
        snapshot[i] = list[i]
    end
    local ran = 0
    for i = 1, #snapshot do
        local entry = snapshot[i]
        if entry.active then
            local ok = pcall(entry.fn, ...)
            if ok then
                ran = ran + 1
            end
        end
    end
    return ran
end

--- How many active handlers are subscribed to an event.
-- Diagnostic/testing helper.
-- @tparam string event Event name
-- @treturn number Count of active handlers
function CoreAI.handler_count(event)
    local list = handlers[event]
    if not list then
        return 0
    end
    local count = 0
    for i = 1, #list do
        if list[i].active then
            count = count + 1
        end
    end
    return count
end

-------
-- Context snapshot
-------

-- mob.distance is NOT reliably a number: it can be a plain table with
-- no sqrt method. Same defensive pattern as distance_magnitude() in
-- cylibs/entity/party.lua: number -> use it, table with sqrt -> pcall
-- it, anything else -> nil.
local function distance_magnitude(dist)
    if type(dist) == 'number' then
        return dist
    end
    if type(dist) ~= 'table' then
        return nil
    end
    if dist.sqrt then
        local ok, val = pcall(function() return dist:sqrt() end)
        if ok and type(val) == 'number' then
            return val
        end
    end
    return nil
end

local function get_windower()
    local ok, w = pcall(function() return windower end)
    if ok then
        return w
    end
    return nil
end

--- Build a plain-table snapshot of the current game state.
-- Defensive: any piece that cannot be read comes back nil instead of
-- throwing. Shape:
--   { time = os.time(),
--     player = { tp, hp, mp, hpp, status, buffs = { [buff_id] = true } } or nil,
--     target = { index, id, hpp, distance } or nil }
-- @treturn table Context snapshot
function CoreAI.context()
    local ctx = { time = os.time(), player = nil, target = nil }
    local w = get_windower()
    if not w or not w.ffxi then
        return ctx
    end

    if w.ffxi.get_player then
        local ok, player = pcall(w.ffxi.get_player)
        if ok and type(player) == 'table' then
            local buffs = {}
            if type(player.buffs) == 'table' then
                for i = 1, #player.buffs do
                    local id = player.buffs[i]
                    if type(id) == 'number' then
                        buffs[id] = true
                    end
                end
            end
            ctx.player = {
                tp = player.tp,
                hp = player.hp,
                mp = player.mp,
                hpp = player.hpp,
                status = player.status,
                buffs = buffs,
            }
        end
    end

    if w.ffxi.get_mob_by_target then
        local ok, target = pcall(w.ffxi.get_mob_by_target, 't')
        if ok and type(target) == 'table' then
            ctx.target = {
                index = target.index,
                id = target.id,
                hpp = target.hpp,
                distance = distance_magnitude(target.distance),
            }
        end
    end

    return ctx
end

-------
-- Scored decisions
-------

--- Pick the best rule for a context.
-- Pure: no windower calls; safe to harness-test.
-- @tparam table rules Array of { name = string,
--   score = function(ctx) -> number or nil,
--   act = function(ctx) (optional, not called by decide) }
-- @tparam table ctx Context (from CoreAI.context or hand-built)
-- @treturn table The highest-scoring rule with score > 0, or nil.
--   Ties go to the earliest rule. A score function that throws or
--   returns nil/non-number counts as no score.
function CoreAI.decide(rules, ctx)
    if type(rules) ~= 'table' then
        return nil
    end
    local best = nil
    local best_score = 0
    for i = 1, #rules do
        local rule = rules[i]
        if type(rule) == 'table' and type(rule.score) == 'function' then
            local ok, score = pcall(rule.score, ctx)
            if ok and type(score) == 'number' and score > best_score then
                best = rule
                best_score = score
            end
        end
    end
    return best
end

-------
-- Shared runtime flags
-------

-- Additional weaponskill hold, set each tic by the smart_ws module
-- (only when that module is enabled) and read by
-- cylibs/conditions/core_ai_ws_hold.lua. Additive only: when true the
-- spammer holds its WS; nothing ever forces a WS from here.
CoreAI.ws_hold = false
CoreAI.ws_hold_reason = nil

--- Set or clear the shared weaponskill hold flag.
-- @tparam boolean active True to hold weaponskills
-- @tparam string reason (optional) Why, for logging/debugging
function CoreAI.set_ws_hold(active, reason)
    CoreAI.ws_hold = active == true
    CoreAI.ws_hold_reason = CoreAI.ws_hold and reason or nil
end

-------
-- Distance provider
-------

-- Optional per-target hold-distance provider, registered by the
-- adaptive_distance module (only when that module is enabled) and
-- consulted by CombatMode when it rolls a hold distance for a new
-- target. The provider is called with the target's mob index (or
-- nil) and returns an array of absolute distances to pick from, or
-- nil for "use the built-in rolls". No provider registered = the
-- built-in rolls, exactly as before.
local distance_provider = nil

--- Register (or clear, with nil) the distance provider function.
-- @tparam function fn Provider function, or nil to clear
function CoreAI.set_distance_provider(fn)
    if fn == nil or type(fn) == 'function' then
        distance_provider = fn
    end
end

--- The registered distance provider, or nil.
-- @treturn function
function CoreAI.get_distance_provider()
    return distance_provider
end

-------
-- Pull hold
-------

-- Additional pull hold, set each tic by the smart_pull module (only
-- when that module is enabled) and read by
-- cylibs/conditions/core_ai_pull_hold.lua, which gates every pull
-- gambit in the Puller. Additive only: when true the puller waits;
-- nothing ever forces a pull from here.
CoreAI.pull_hold = false
CoreAI.pull_hold_reason = nil

--- Set or clear the shared pull hold flag.
-- @tparam boolean active True to hold pulls
-- @tparam string reason (optional) Why, for logging/debugging
function CoreAI.set_pull_hold(active, reason)
    CoreAI.pull_hold = active == true
    CoreAI.pull_hold_reason = CoreAI.pull_hold and reason or nil
end

-------
-- Debuff hold
-------

-- Additional debuff hold, set each tic by the debuff_hold module
-- (only when that module is enabled) and read by
-- cylibs/conditions/core_ai_debuff_hold.lua, which the Debuffer
-- adds to every debuff gambit. Additive only: when true debuffs
-- wait; nothing ever forces a cast from here.
CoreAI.debuff_hold = false
CoreAI.debuff_hold_reason = nil

--- Set or clear the shared debuff hold flag.
-- @tparam boolean active True to hold debuffs
-- @tparam string reason (optional) Why, for logging/debugging
function CoreAI.set_debuff_hold(active, reason)
    CoreAI.debuff_hold = active == true
    CoreAI.debuff_hold_reason = CoreAI.debuff_hold and reason or nil
end

-------
-- Module registry
-------

--- Register an extension module.
-- The module may define init(api) and destroy(). init receives an api
-- table whose on(event, fn) subscribes a hook owned by the module;
-- CoreAI.destroy() disposes those hooks and calls destroy().
-- @tparam string name Module name (unique)
-- @tparam table module Module table
-- @treturn boolean True if registered and init ran (or was absent)
function CoreAI.register_module(name, module)
    if type(name) ~= 'string' or type(module) ~= 'table' then
        return false
    end
    modules[name] = module
    module_handles[name] = module_handles[name] or {}
    if type(module.init) == 'function' then
        local api = {}
        function api.on(event, fn)
            local handle = CoreAI.on(event, fn)
            table.insert(module_handles[name], handle)
            return handle
        end
        function api.context()
            return CoreAI.context()
        end
        function api.decide(rules, ctx)
            return CoreAI.decide(rules, ctx)
        end
        local ok = pcall(module.init, api)
        return ok
    end
    return true
end

--- Is a module registered under this name?
-- @tparam string name Module name
-- @treturn boolean
function CoreAI.has_module(name)
    return modules[name] ~= nil
end

-------
-- Tic driver (called once per second from Trust:tic)
-------

local tic_state = nil

local function reset_tic_state()
    tic_state = {
        initialized = false,
        target_index = nil,
        status = nil,
        had_engaged_target = false,
    }
end
reset_tic_state()

--- One-second driver. Polls state, derives events, emits them:
--   'tic'           (ctx)                       every call
--   'target_change' (ctx, new_index, old_index) target index changed,
--                                               including to/from nil
--   'engaged'       (ctx)                       player status -> engaged
--   'disengaged'    (ctx)                       player status left engaged
--   'target_died'   (ctx)                       was engaged with a
--                                               target, target is gone
-- The first call only records state (no transition events).
function CoreAI.tic()
    local ctx = CoreAI.context()
    CoreAI.emit('tic', ctx)

    local target_index = ctx.target and ctx.target.index or nil
    local status = ctx.player and ctx.player.status or nil
    local engaged = status == 1

    if not tic_state.initialized then
        tic_state.initialized = true
        tic_state.target_index = target_index
        tic_state.status = status
        tic_state.had_engaged_target = engaged and target_index ~= nil
        return
    end

    if target_index ~= tic_state.target_index then
        local old_index = tic_state.target_index
        -- Engaged with a target last tic and it is now gone: it died
        -- (or despawned). Emit before target_change so modules can
        -- react to the death first.
        if target_index == nil and tic_state.had_engaged_target then
            CoreAI.emit('target_died', ctx)
        end
        CoreAI.emit('target_change', ctx, target_index, old_index)
        tic_state.target_index = target_index
    end

    if status ~= tic_state.status then
        if engaged and tic_state.status ~= nil then
            CoreAI.emit('engaged', ctx)
        elseif not engaged and tic_state.status == 1 then
            CoreAI.emit('disengaged', ctx)
        end
        tic_state.status = status
    end

    tic_state.had_engaged_target = engaged and target_index ~= nil
end

-------
-- Teardown
-------

--- Dispose everything: all module hooks, all handles, module
-- destroy()s, shared flags and tic state. Snapshot-first and
-- nil-safe; one bad module cannot abort the rest. Safe to call more
-- than once.
function CoreAI.destroy()
    -- Snapshot module names first; destroy()s may touch the registry.
    local names = {}
    for name in pairs(modules) do
        table.insert(names, name)
    end
    for i = 1, #names do
        local module = modules[names[i]]
        if module and type(module.destroy) == 'function' then
            pcall(module.destroy)
        end
        local owned = module_handles[names[i]]
        if owned then
            for j = 1, #owned do
                if owned[j] and owned[j].dispose then
                    pcall(owned[j].dispose)
                end
            end
        end
    end
    modules = {}
    module_handles = {}

    for i = 1, #all_handles do
        if all_handles[i] and all_handles[i].dispose then
            pcall(all_handles[i].dispose)
        end
    end
    all_handles = {}
    handlers = {}

    CoreAI.ws_hold = false
    CoreAI.ws_hold_reason = nil
    CoreAI.pull_hold = false
    CoreAI.pull_hold_reason = nil
    CoreAI.debuff_hold = false
    CoreAI.debuff_hold_reason = nil
    distance_provider = nil
    reset_tic_state()
end

return CoreAI

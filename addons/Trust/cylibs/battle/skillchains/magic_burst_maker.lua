---------------------------
-- Magic burst maker.
-- @class module
-- @name MagicBurstMaker

require('luau')
require('pack')
require('actions')

local nukes = require('cylibs/res/nukes')
local skills = require('cylibs/res/skills')
local res = require('resources')

local _static = S { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }

local Event = require('cylibs/events/Luvent')

local default = {}
default.Show = { burst = _static, pet = S { 'BST', 'SMN' }, props = _static, spell = S { 'SCH', 'BLU' }, step = _static, timer = _static, weapon = _static }
default.UpdateFrequency = 0.2
default.aeonic = false
default.color = false

local message_ids = S { 110, 185, 187, 317, 802 }
local skillchain_ids = S { 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 767, 768, 769, 770 }
local buff_dur = { [163] = 40, [164] = 30, [470] = 60 }
local info = {}
local resonating = {}
local buffs = {}
local current_frame = 0
local interval = 0.2

local sc_info = {
    Radiance = { 'Fire', 'Wind', 'Lightning', 'Light', lvl = 4 },
    Umbra = { 'Earth', 'Ice', 'Water', 'Dark', lvl = 4 },
    Light = { 'Fire', 'Wind', 'Lightning', 'Light', Light = { 4, 'Light', 'Radiance' }, lvl = 3 },
    Darkness = { 'Earth', 'Ice', 'Water', 'Dark', Darkness = { 4, 'Darkness', 'Umbra' }, lvl = 3 },
    Gravitation = { 'Earth', 'Dark', Distortion = { 3, 'Darkness' }, Fragmentation = { 2, 'Fragmentation' }, lvl = 2 },
    Fragmentation = { 'Wind', 'Lightning', Fusion = { 3, 'Light' }, Distortion = { 2, 'Distortion' }, lvl = 2 },
    Distortion = { 'Ice', 'Water', Gravitation = { 3, 'Darkness' }, Fusion = { 2, 'Fusion' }, lvl = 2 },
    Fusion = { 'Fire', 'Light', Fragmentation = { 3, 'Light' }, Gravitation = { 2, 'Gravitation' }, lvl = 2 },
    Compression = { 'Darkness', Transfixion = { 1, 'Transfixion' }, Detonation = { 1, 'Detonation' }, lvl = 1 },
    Liquefaction = { 'Fire', Impaction = { 2, 'Fusion' }, Scission = { 1, 'Scission' }, lvl = 1 },
    Induration = { 'Ice', Reverberation = { 2, 'Fragmentation' }, Compression = { 1, 'Compression' }, Impaction = { 1, 'Impaction' }, lvl = 1 },
    Reverberation = { 'Water', Induration = { 1, 'Induration' }, Impaction = { 1, 'Impaction' }, lvl = 1 },
    Transfixion = { 'Light', Scission = { 2, 'Distortion' }, Reverberation = { 1, 'Reverberation' }, Compression = { 1, 'Compression' }, lvl = 1 },
    Scission = { 'Earth', Liquefaction = { 1, 'Liquefaction' }, Reverberation = { 1, 'Reverberation' }, Detonation = { 1, 'Detonation' }, lvl = 1 },
    Detonation = { 'Wind', Compression = { 2, 'Gravitation' }, Scission = { 1, 'Scission' }, lvl = 1 },
    Impaction = { 'Lightning', Liquefaction = { 1, 'Liquefaction' }, Detonation = { 1, 'Detonation' }, lvl = 1 },
}

local chainbound = {}
chainbound[1] = L { 'Compression', 'Liquefaction', 'Induration', 'Reverberation', 'Scission' }
chainbound[2] = L { 'Gravitation', 'Fragmentation', 'Distortion' } + chainbound[1]
chainbound[3] = L { 'Light', 'Darkness' } + chainbound[2]

local colors = {}            -- Color codes by Sammeh
colors.Light =         '\\cs(255,255,255)'
colors.Dark =          '\\cs(0,0,204)'
colors.Ice =           '\\cs(0,255,255)'
colors.Water =         '\\cs(0,0,255)'
colors.Earth =         '\\cs(153,76,0)'
colors.Wind =          '\\cs(102,255,102)'
colors.Fire =          '\\cs(255,0,0)'
colors.Lightning =     '\\cs(255,0,255)'
colors.Gravitation =   '\\cs(102,51,0)'
colors.Fragmentation = '\\cs(250,156,247)'
colors.Fusion =        '\\cs(255,102,102)'
colors.Distortion =    '\\cs(51,153,255)'
colors.Darkness =      colors.Dark
colors.Umbra =         colors.Dark
colors.Compression =   colors.Dark
colors.Radiance =      colors.Light
colors.Transfixion =   colors.Light
colors.Induration =    colors.Ice
colors.Reverberation = colors.Water
colors.Scission =      colors.Earth
colors.Detonation =    colors.Wind
colors.Liquefaction =  colors.Fire
colors.Impaction =     colors.Lightning

local MagicBurstMaker = {}
MagicBurstMaker.__index = MagicBurstMaker

-- Event called when the player should perform a nuke
function MagicBurstMaker:on_perform_next_nuke()
    return self.perform_next_nuke
end

function MagicBurstMaker:on_perform_next_job_ability()
    return self.perform_next_job_ability
end

-------
-- Default initializer for a MagicBurstMaker.
-- @tparam Mode state_var Mode var for enabled state
-- @treturn Player A player
function MagicBurstMaker.new(state_var)
    local self = setmetatable({
        action_events = {};
        info = {};
        nuke_delay = 2;
        fastcast = 0.8;
        last_nuke_time = os.time();
        state_var = state_var;
    }, MagicBurstMaker)

    local player = windower.ffxi.get_player()

    info.job = player.main_job
    info.player = player.id

    local equip = windower.ffxi.get_items('equipment')
    info.main_weapon = equip.main
    info.main_bag = equip.main_bag
    info.range = equip.range
    info.range_bag = equip.range_bag
    buffs[info.player] = {}

    self.perform_next_nuke = Event.newEvent()
    self.perform_next_job_ability = Event.newEvent()

    self:varclean()

    return self
end

function MagicBurstMaker:destroy()
    info = {}
    resonating = {}
    buffs = {}

    self:on_perform_next_nuke():removeAllActions()
    self:on_perform_next_job_ability():removeAllActions()

    if self.state_var_change_id then
        self.state_var:on_state_change():removeAction(self.state_var_change_id)
    end

    for _, event in pairs(self.action_events) do
        windower.unregister_event(event)
    end
end

function MagicBurstMaker:start_monitoring()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    self.state_var_change_id = self.state_var:on_state_change():addAction(function(_, new_value)
        nukes.reset()
        self:set_auto_nuke(new_value ~= 'Off')
        if L{'Earth', 'Lightning', 'Water', 'Fire', 'Ice', 'Wind', 'Light', 'Dark'}:contains(new_value) then
            nukes.disable()
            if new_value == 'Earth' then
                Earth = 0
            elseif new_value == 'Lightning' then
                Thunder = 0
            elseif new_value == 'Water' then
                Water = 0
            elseif new_value == 'Fire' then
                Fire = 0
            elseif new_value == 'Ice' then
                Ice = 0
            elseif new_value == 'Wind' then
                Wind = 0
            elseif new_value == 'Light' then
                Lightness = 0
            elseif new_value == 'Dark' then
                Darkness = 0
            end
        end
    end)

    self.action_events.prerender = windower.register_event('prerender', function()
        self:on_prerender()
    end)

   self.action_events.job_change = windower.register_event('job change', function(job, lvl)
        job = res.jobs:with('id', job).english_short
        if job ~= info.job then
            info.job = job
            if L{'RDM','BLM','SCH','GEO','NIN'}:contains(info.job) then
                self.fastcast = 0.8
            else
                self.fastcast = 0
            end
        end
    end)

    self.action_events.zone_change = windower.register_event('zone change', function()
        self:varclean()
    end)

    ActionPacket.open_listener(function(act)
        self:action_handler(act)
    end)
end

function MagicBurstMaker:on_settings_changed(skillchain_settings)
end

function MagicBurstMaker:varclean()
    self.burst = 0
    self.disabled = 0
    self.petskill = 0
    self.petopenmp = 0
    self.autonuke = 0
    self.nuking = 0
    self.petdelay = 0
    self.sicdelay = 0
    self.bpdelay = 0
    self.ongo = 0
    self.faw = 0
    self.light = 0
    self.dark = 0
    self.w_casting = 0
    self.w_readies = 0

    self.tagtime = os.clock()

    self.automb = nil
end

function MagicBurstMaker:pet_delay()
    self.petdelay = 1
    self.pettime = os.clock()
end

function MagicBurstMaker:aeonic_prop(ability, actor)
    if ability.aeonic and (ability.weapon == info.aeonic and actor == info.player or settings.aeonic and info.player ~= actor) then
        return { ability.skillchain[1], ability.skillchain[2], ability.aeonic }
    end
    return ability.skillchain
end

function MagicBurstMaker:check_props(old, new)
    for k = 1, #old do
        local first = old[k]
        local combo = sc_info[first]
        for i = 1, #new do
            local second = new[i]
            local result = combo[second]
            if result then
                return unpack(result)
            end
            if #old > 3 and combo.lvl == sc_info[second].lvl then
                break
            end
        end
    end
end

-- FIXME:  is this just visual?
function MagicBurstMaker:add_skills(t, abilities, active, resource, AM)
    local tt = { {}, {}, {}, {} }
    for k = 1, #abilities do
        local ability_id = abilities[k]
        local skillchain = skills[resource][ability_id]
        if skillchain then
            local lv, prop, aeonic = self:check_props(active, self:aeonic_prop(skillchain, info.player))
            if prop then
                prop = AM and aeonic or prop
                tt[lv][#tt[lv]+1] = settings.color and '%-16s → Lv.%d %s%-14s\\cr':format(res[resource][ability_id].name, lv, colors[prop], prop) or '%-16s → Lv.%d %-14s':format(res[resource][ability_id].name, lv, prop)
            end
        end
    end
    for x = 4, 1, -1 do
        for k = #tt[x], 1, -1 do
            t[#t + 1] = tt[x][k]
        end
    end

    return t
end

function MagicBurstMaker:check_results(reson)
    local t = {}

    return _raw.table.concat(t, '\n')
end

local next_frame = os.clock()

function MagicBurstMaker:on_prerender()
    if not windower.ffxi.get_player() then
        return
    end

    local now = os.clock()

    if now < next_frame then
        return
    end

    next_frame = now + 0.1

    if now > current_frame + interval then
        current_frame = now

        for k, v in pairs(resonating) do
            if v.times - now + 10 < 0 then
                resonating[k] = nil
            end
        end

        local player = windower.ffxi.get_player()
        local buffs = L(player.buffs)

        if buffs:contains(2) or
                buffs:contains(7) or
                buffs:contains(10) or
                buffs:contains(14) or
                buffs:contains(16) or
                buffs:contains(17) or
                buffs:contains(19) or
                buffs:contains(28) or
                buffs:contains(156) then
            self.disabled = 1
        else
            self.disabled = 0
        end

        if self.nuking == 1 then
            if os.time() - self.last_nuke_time > self.nuke_delay then
                self.nuking = 0
            end
        end

        if self.petdelay == 1 then
            if os.clock() - self.pettime > 1.25 then
                self.petdelay = 0
            end
        end

        if player.main_job == 'BST' then
            if (windower.ffxi.get_ability_recasts()[102] > 0) then
                if (windower.ffxi.get_ability_recasts()[102] > (self.bstrecast * 2)) then
                    self.sicdelay = 3
                elseif (windower.ffxi.get_ability_recasts()[102] > (self.bstrecast * 1)) then
                    self.sicdelay = 2
                else
                    self.sicdelay = 1
                end
            else
                self.sicdelay = 0
            end
        end

        if player.main_job == 'SMN' then
            if (windower.ffxi.get_ability_recasts()[173] > 0) then
                self.bpdelay = 1
            else
                self.bpdelay = 0
            end
        end

        local targ = windower.ffxi.get_mob_by_target('t', 'bt')
        self.targ_id = targ and targ.id
        local reson = resonating[self.targ_id]
        local timer = reson and (reson.times - now) or 0
        local tname = targ and targ.name

        if targ and targ.hpp > 0 and timer > 0 then
            if not reson.closed then
                reson.disp_info = reson.disp_info or self:check_results(reson)
                self.delay = reson.delay
            else
                resonating[self.targ_id] = nil
                return
            end
            if ((timer > 0 and ((self.delay - now) < 1)) or reson.step > 1) and self.autonuke == 1 then
                self.faw = 1
            else
                self.faw = 0
            end
            reson.name = res[reson.res][reson.id].name
            reson.props = reson.props or not reson.bound and self:colorize(reson.active) or 'Chainbound Lv.%d':format(reson.bound)
            if reson.step > 1 and timer > 1.5 then
                if self.ongo == 0 then
                    if reson.props == 'Light' or reson.props == 'Radiance' then
                        self:perform_spell('lightmb')
                        self.automb = "lightmb"
                    elseif reson.props == 'Darkness' or reson.props == 'Umbra' then
                        self:perform_spell('darknessmb')
                        self.automb = "darknessmb"
                    elseif reson.props == 'Gravitation' then
                        self:perform_spell('gravmb')
                        self.automb = "gravmb"
                    elseif reson.props == 'Fragmentation' then
                        self:perform_spell('fragmb')
                        self.automb = "fragmb"
                    elseif reson.props == 'Distortion' then
                        self:perform_spell('distomb')
                        self.automb = "distomb"
                    elseif reson.props == 'Fusion' then
                        self:perform_spell('fusionmb')
                        self.automb = "fusionmb"
                    elseif reson.props == 'Compression' then
                        self:perform_spell('darkmb')
                        self.automb = "darkmb"
                    elseif reson.props == 'Liquefaction' then
                        self:perform_spell('firemb')
                        self.automb = "firemb"
                    elseif reson.props == 'Induration' then
                        self:perform_spell('blizzardmb')
                        self.automb = "blizzardmb"
                    elseif reson.props == 'Reverberation' then
                        self:perform_spell('watermb')
                        self.automb = "watermb"
                    elseif reson.props == 'Transfixion' then
                        self:perform_spell('holymb')
                        self.automb = "holymb"
                    elseif reson.props == 'Scission' then
                        self:perform_spell('stonemb')
                        self.automb = "stonemb"
                    elseif reson.props == 'Detonation' then
                        self:perform_spell('aeromb')
                        self.automb = "aeromb"
                    elseif reson.props == 'Impaction' then
                        self:perform_spell('thundermb')
                        self.automb = "thundermb"
                    end
                end
            end
        end
    end
end

function MagicBurstMaker:colorize(t)
    return _raw.table.concat(t, ',')
end

function MagicBurstMaker:check_buff(t, i)
    if t[i] == true or t[i] - os.time() > 0 then
        return true
    end
    t[i] = nil
end

function MagicBurstMaker:chain_buff(t)
    local i = t[164] and 164 or t[470] and 470
    if i and self:check_buff(t, i) then
        t[i] = nil
        return true
    end
    return t[163] and self:check_buff(t, 163)
end

function MagicBurstMaker:perform_spell(magic_burst)
    local nuke = nukes.get_nuke(magic_burst)

    if nuke ~= nil then
        if res.spells:with('en', nuke) then
            if self.autonuke == 1 and self.nuking == 0 then
                self.last_nuke_time = os.time()
                self.nuke_delay = (res.spells:with('en', nuke).cast_time * (1 - self.fastcast)) + 3.275
                --windower.send_command('input wait ' .. nukedelay .. ';input //sc nuking')
                self:on_perform_next_nuke():trigger(self, nuke)
                self.nuking = 1
            end
        elseif res.job_abilities:with('en', nuke) then
            local nukedelay = 1
            if self.autonuke == 1 and self.nuking == 0 then
                windower.send_command('input wait ' .. nukedelay .. ';input //sc nuking')
                --windower.send_command('input /ja \"' .. nuke .. '\" <t>;wait ' .. nukedelay .. ';input //sc nuking')
                self:on_perform_next_job_ability():trigger(self, nuke)
                self.nuking = 1
            end
        end
    end
end

local categories = S {
    'weaponskill_finish',
    'spell_finish',
    'job_ability',
    'mob_tp_finish',
    'avatar_tp_finish',
    'job_ability_unblinkable',
}

function MagicBurstMaker:apply_properties(target, resource, action_id, properties, delay, step, closed, bound)
    local clock = os.clock()
    resonating[target] = {
        res = resource,
        id = action_id,
        active = properties,
        delay = clock + delay,
        times = clock + delay + 8 - step,
        step = step,
        closed = closed,
        bound = bound
    }
    if target == self.targ_id then
        next_frame = clock
    end
end

function MagicBurstMaker:action_handler(act)
    local actionpacket = ActionPacket.new(act)
    local category = actionpacket:get_category_string()

    if not categories:contains(category) or act.param == 0 then
        return
    end

    local actor = actionpacket:get_id()
    local target = actionpacket:get_targets()()
    local action = target:get_actions()()
    local message_id = action:get_message_id()
    local add_effect = action:get_add_effect()
    --local basic_info = action:get_basic_info()
    local param, resource, action_id, interruption, conclusion = action:get_spell()
    local ability = skills[resource] and skills[resource][action_id]

    if add_effect and conclusion and skillchain_ids:contains(add_effect.message_id) then
        local skillchain = add_effect.animation:ucfirst()
        local level = sc_info[skillchain].lvl
        local reson = resonating[target.id]
        local delay = ability and ability.delay or 3
        local step = (reson and reson.step or 1) + 1

        if level == 3 and reson and ability then
            level = self:check_props(reson.active, self:aeonic_prop(ability, actor))
        end

        local closed = level == 4
        self:apply_properties(target.id, resource, action_id, { skillchain }, delay, step, closed)
    elseif ability and (message_ids:contains(message_id) or message_id == 2 and buffs[actor] and self:chain_buff(buffs[actor])) then
        self:apply_properties(target.id, resource, action_id, self:aeonic_prop(ability, actor), ability.delay or 3, 1)
    elseif message_id == 529 then
        self:apply_properties(target.id, resource, action_id, chainbound[param], 2, 1, false, param)
    elseif message_id == 100 and buff_dur[param] then
        buffs[actor] = buffs[actor] or {}
        buffs[actor][param] = buff_dur[param] + os.time()
    end
end

function MagicBurstMaker:set_auto_nuke(new_value)
    self.autonuke = new_value and 1 or 0
    if self.autonuke == 0 then
        self.nuking = 0
    end
end

return MagicBurstMaker



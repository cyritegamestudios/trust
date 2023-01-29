---------------------------
-- Skillchain maker.
-- @class module
-- @name SkillchainMaker

require('luau')
require('pack')
require('actions')

local skills = require('cylibs/res/skills')
local res = require('resources')

local _static = S { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }
local rangedws = S { 'Flaming Arrow', 'Piercing Arrow', 'Dulling Arrow', 'Sidewinder', 'Blast Arrow', 'Arching Arrow', 'Empyreal Arrow', 'Refulgent Arrow', 'Apex Arrow', 'Namas Arrow', 'Jishnu\'s Radiance', 'Hot Shot', 'Split Shot', 'Sniper Shot', 'Slug Shot', 'Blast Shot', 'Heavy Shot', 'Detonator', 'Numbing Shot', 'Last Stand', 'Coronach	Wildfire', 'Trueflight', 'Leaden Salute' }
local ignoretp = S { '' }

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
local visible = false


local skillchains = { 'Light', 'Darkness', 'Gravitation', 'Fragmentation', 'Distortion', 'Fusion', 'Compression', 'Liquefaction', 'Induration', 'Reverberation', 'Transfixion', 'Scission', 'Detonation', 'Impaction', 'Radiance', 'Umbra' }
local lightchains = S { 'Light', 'Fragmentation', 'Fusion', 'Liquefaction', 'Transfixion', 'Detonation', 'Impaction', 'Radiance' }
local darkchains = S { 'Darkness', 'Gravitation', 'Distortion', 'Compression', 'Induration', 'Reverberation', 'Scission', 'Umbra' }

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

local aeonic_weapon = {
    [20515] = 'Godhands',
    [20594] = 'Aeneas',
    [20695] = 'Sequence',
    [20843] = 'Chango',
    [20890] = 'Anguta',
    [20935] = 'Trishula',
    [20977] = 'Heishi Shorinken',
    [21025] = 'Dojikiri Yasutsuna',
    [21082] = 'Tishtrya',
    [21147] = 'Khatvanga',
    [21485] = 'Fomalhaut',
    [21694] = 'Lionheart',
    [21753] = 'Tri-edge',
    [22117] = 'Fail-Not',
    [22131] = 'Fail-Not',
    [22143] = 'Fomalhaut'
}

local SkillchainMaker = {}
SkillchainMaker.__index = SkillchainMaker

-- Event called when the player should perform a weapon skill.
function SkillchainMaker:on_perform_next_weapon_skill()
    return self.perform_next_weapon_skill
end

-------
-- Default initializer for a SkillchainMaker.
-- @tparam T skillchain_settings Specifies weapon skills
-- @tparam Mode state_var Mode var for enabled state
-- @tparam Mode priority_mode_var Mode var for weapon skill priority
-- @tparam Mode partner_mode_var Mode var for skillchaining with others
-- @tparam Mode aftermath_mode_var Mode var for whether to maintain aftermath
-- @treturn Player A player
function SkillchainMaker.new(skillchain_settings, state_var, priority_mode_var, partner_mode_var, aftermath_mode_var)
    local self = setmetatable({
        skillchain_settings = skillchain_settings;
        action_events = {};
        info = {};
        state_var = state_var;
        priority_mode_var = priority_mode_var;
        partner_mode_var = partner_mode_var;
        aftermath_mode_var = aftermath_mode_var;
    }, SkillchainMaker)

    local player = windower.ffxi.get_player()

    info.job = player.main_job
    info.player = player.id

    local equip = windower.ffxi.get_items('equipment')
    info.main_weapon = equip.main
    info.main_bag = equip.main_bag
    info.range = equip.range
    info.range_bag = equip.range_bag
    buffs[info.player] = {}

    self.perform_next_weapon_skill = Event.newEvent()

    self:update_weapon()
    self:varclean()

    return self
end

function SkillchainMaker:destroy()
    coroutine.close(check_weapon)
    check_weapon = nil
    info = {}
    resonating = {}
    buffs = {}

    if self.state_var_change_id then
        self.state_var:on_state_change():removeAction(self.state_var_change_id)
    end

    if self.priority_mode_var_change_id then
        self.priority_mode_var:on_state_change():removeAction(self.priority_mode_var_change_id)
    end

    if self.partner_mode_var_change_id then
        self.partner_mode_var:on_state_change():removeAction(self.partner_mode_var_change_id)
    end

    if self.aftermath_mode_var_change_id then
        self.aftermath_mode_var:on_state_change():removeAction(self.aftermath_mode_var_change_id)
    end

    for _, event in pairs(self.action_events) do
        windower.unregister_event(event)
    end
end

function SkillchainMaker:start_monitoring()
    if self.is_monitoring then
        return
    end
    self.is_monitoring = true

    local function handle_state_var_changed(new_value)
        if new_value == 'Auto' then
            self:set_auto(true)
        elseif new_value == 'Cleave' then
            self:set_cleave(true)
        elseif new_value == 'Spam' then
            self:set_spam(true)
        else
            self:set_auto(false)
        end
    end

    self.state_var_change_id = self.state_var:on_state_change():addAction(function(_, new_value)
        handle_state_var_changed(new_value)
    end)
    handle_state_var_changed(self.state_var.current)

    local function handle_priority_mode_var_changed(new_value)
        if new_value == 'Prefer' then
            self:set_prefer(true)
        elseif new_value == 'Strict' then
            self:set_strict(true)
        else
            self:set_prefer(false)
            self:set_strict(false)
        end
    end

    self.priority_mode_var_change_id = self.priority_mode_var:on_state_change():addAction(function(_, new_value)
        handle_priority_mode_var_changed(new_value)
    end)
    handle_priority_mode_var_changed(self.priority_mode_var.current)

    local function handle_partner_mode_var_changed(new_value)
        if new_value == 'Auto' then
            self:set_buddy(true)
        elseif new_value == 'Open' then
            self:set_open(true)
            self:set_buddy(false)
        elseif new_value == 'Close' then
            self:set_close(true)
            self:set_buddy(false)
        else
            self:set_buddy(false)
            self:set_open(false)
            self:set_close(false)
        end
    end

    self.partner_mode_var_change_id = self.partner_mode_var:on_state_change():addAction(function(_, new_value)
        handle_partner_mode_var_changed(new_value)
    end)
    handle_partner_mode_var_changed(self.partner_mode_var.current)

    local function handle_aftermath_mode_var_changed(new_value)
        if new_value == 'Auto' then
            self:set_aftermath(true)
        else
            self:set_aftermath(false)
        end
    end

    self.aftermath_mode_var_change_id = self.aftermath_mode_var:on_state_change():addAction(function(_, new_value)
       handle_aftermath_mode_var_changed(new_value)
    end)
    handle_aftermath_mode_var_changed(self.aftermath_mode_var.current)
    
    -- TODO add other var listeners

    self.action_events.target_change = windower.register_event('target change', function()
        self:on_target_change()
    end)

    self.action_events.prerender = windower.register_event('prerender', function()
        self:on_prerender()
    end)

    self.action_events.gain_buff = windower.register_event('gain buff', function(id)
        self:on_gain_buff(id)
    end)

    self.action_events.lose_buff = windower.register_event('lose buff', function(id)
        self:on_lose_buff(id)
    end)

    self.action_events.incoming_chunk = windower.register_event('incoming chunk', function(id, data)
        self:on_incoming_chunk(id, data)
    end)

    self.action_events.tp_change = windower.register_event('tp change', function(new, old)
        self:check_sc()
    end)

   self.action_events.job_change = windower.register_event('job change', function(job, lvl)
        job = res.jobs:with('id', job).english_short
        if job ~= info.job then
            info.job = job
        end
    end)

    self.action_events.zone_change = windower.register_event('zone change', function()
        self:varclean()
    end)

    ActionPacket.open_listener(function(act)
        self:action_handler(act)
    end)

    self:varclean()
    self:check_sc()
end

function SkillchainMaker:on_settings_changed(skillchain_settings)
    defaultws = skillchain_settings.defaultws;
    tpws = skillchain_settings.tpws;
    spamws = skillchain_settings.spamws;
    starterws = skillchain_settings.starterws;
    preferws = skillchain_settings.preferws;
    cleavews = skillchain_settings.cleavews;
    amws = skillchain_settings.amws;
    petws = skillchain_settings.petws;
end

function SkillchainMaker:varclean()
    auto = 0
    burst = 0
    disabled = 0
    am = 0
    melee = 0
    meleeskill = 0
    petskill = 0
    petopenmp = 0
    amthree = 0
    buddy = 0
    tagin = 0
    spam = 0
    strict = 0
    prefer = 0
    endless = 0
    cleave = 0
    ranged = 0
    starter = 0
    started = 0
    wsdelay = 0
    petdelay = 0
    sicdelay = 0
    bpdelay = 0
    tpdelay = 0
    trust = 0
    ongo = 0
    innin = 0
    yonin = 0
    faw = 0
    open = 0
    close = 0
    light = 0
    dark = 0
    ultimate = 0
    w_casting = 0
    w_readies = 0

    tagtime = os.clock()
    conduct = 0

    openws = nil
    petopen = nil
    initws = nil
    overws = nil
    zergws = nil
    aoews = nil
    automb = nil

    self:on_settings_changed(self.skillchain_settings)
end

function SkillchainMaker:check_sc()
    if not windower.ffxi.get_info().logged_in then
        return false
    end

    openws = nil
    petopen = nil
    initws = nil
    overws = nil
    zergws = nil
    aoews = nil
    initws = nil

    local abilities = windower.ffxi.get_abilities().weapon_skills
    local pet = windower.ffxi.get_abilities().job_abilities

    if ranged == 1 then
        for i = 1,#defaultws,+1 do
            if rangedws:contains(defaultws[i]) then
                for s = 1,#abilities,+1 do
                    if openws == nil then
                        local wsid = res.weapon_skills:with('en',defaultws[i]).id
                        local wsid = tonumber(wsid)
                        if abilities[s] == wsid then
                            openws = defaultws[i]
                        end
                    end
                end
            end
        end
        for i = 1,#tpws,+1 do
            for s = 1,#abilities,+1 do
                if overws == nil then
                    if rangedws:contains(defaultws[i]) then
                        local wsid = res.weapon_skills:with('en',tpws[i]).id
                        local wsid = tonumber(wsid)
                        if abilities[s] == wsid then
                            overws = tpws[i]
                        end
                    end
                end
            end
        end
        for i = 1,#spamws,+1 do
            if rangedws:contains(spamws[i]) then
                for s = 1,#abilities,+1 do
                    if zergws == nil then
                        local wsid =  res.weapon_skills:with('en',spamws[i]).id
                        local wsid = tonumber(wsid)
                        if abilities[s] == wsid then
                            zergws = spamws[i]
                        end
                    end
                end
            end
        end
        for i = 1,#starterws,+1 do
            if rangedws:contains(starterws[i]) then
                for s = 1,#abilities,+1 do
                    if initws == nil then
                        local wsid =  res.weapon_skills:with('en',starterws[i]).id
                        local wsid = tonumber(wsid)
                        if abilities[s] == wsid then
                            initws = starterws[i]
                        end
                    end
                end
            end
        end
    else
        for i = 1,#defaultws,+1 do
            for s = 1,#abilities,+1 do
                if openws == nil then
                    local wsid =  res.weapon_skills:with('en',defaultws[i]).id
                    local wsid = tonumber(wsid)
                    if abilities[s] == wsid then
                        openws = defaultws[i]
                    end
                end
            end
        end
        for i = 1,#tpws,+1 do
            for s = 1,#abilities,+1 do
                if overws == nil then
                    local wsid =  res.weapon_skills:with('en',tpws[i]).id
                    local wsid = tonumber(wsid)
                    if abilities[s] == wsid then
                        overws = tpws[i]
                    end
                end
            end
        end
        for i = 1,#spamws,+1 do
            for s = 1,#abilities,+1 do
                if zergws == nil then
                    local wsid =  res.weapon_skills:with('en',spamws[i]).id
                    local wsid = tonumber(wsid)
                    if abilities[s] == wsid then
                        zergws = spamws[i]
                    end
                end
            end
        end
        for i = 1,#cleavews,+1 do
            for s = 1,#abilities,+1 do
                if aoews == nil then
                    local wsid =  res.weapon_skills:with('en',cleavews[i]).id
                    local wsid = tonumber(wsid)
                    if abilities[s] == wsid then
                        aoews = cleavews[i]
                    end
                end
            end
        end
        for i = 1,#starterws,+1 do
            for s = 1,#abilities,+1 do
                if initws == nil then
                    local wsid =  res.weapon_skills:with('en',starterws[i]).id
                    local wsid = tonumber(wsid)
                    if abilities[s] == wsid then
                        initws = starterws[i]
                    end
                end
            end
        end
        if petws ~= nil then
            for i = 1,#petws,+1 do
                for p = 1,#pet,+1 do
                    if petopen == nil then
                        local wsid =  res.job_abilities:with('en',petws[i]).id
                        local wsid = tonumber(wsid)
                        if pet[p] == wsid then
                            petopen = petws[i]
                        end
                    end
                end
            end
        end
    end
end

function SkillchainMaker:ws_delay()
    wsdelay = 1
    tpdelay = 1
    wstime = os.clock()
end

function SkillchainMaker:pet_delay()
    petdelay = 1
    pettime = os.clock()
end

function SkillchainMaker:update_weapon()
    local main_weapon = windower.ffxi.get_items(info.main_bag, info.main_weapon).id
    if main_weapon ~= 0 then
        info.aeonic = aeonic_weapon[main_weapon] or info.range and aeonic_weapon[windower.ffxi.get_items(info.range_bag, info.range).id]
        return
    end
    -- FIXME:
    if not check_weapon or coroutine.status(check_weapon) ~= 'suspended' then
        check_weapon = coroutine.schedule(function()
            self:update_weapon()
        end, 10)
    end
end

function SkillchainMaker:aeonic_am(step)
    for x = 270, 272 do
        if buffs[info.player][x] then
            return 272 - x < step
        end
    end
    return false
end

function SkillchainMaker:aeonic_prop(ability, actor)
    if ability.aeonic and (ability.weapon == info.aeonic and actor == info.player or settings.aeonic and info.player ~= actor) then
        return { ability.skillchain[1], ability.skillchain[2], ability.aeonic }
    end
    return ability.skillchain
end

function SkillchainMaker:check_props(old, new)
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
function SkillchainMaker:add_skills(t, abilities, active, resource, AM)
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

function SkillchainMaker:check_results(reson)
    local t = {}
    if info.job == 'SCH' then
        t = self:add_skills(t, {0,1,2,3,4,5,6,7}, reson.active, 'elements')
    elseif info.job == 'BLU' then
        t = self:add_skills(t, windower.ffxi.get_mjob_data().spells, reson.active, 'spells')
    elseif windower.ffxi.get_mob_by_target('pet') then
        t = self:add_skills(t, windower.ffxi.get_abilities().job_abilities, reson.active, 'job_abilities')
    end
    t = self:add_skills(t, windower.ffxi.get_abilities().weapon_skills, reson.active, 'weapon_skills', info.aeonic and self:aeonic_am(reson.step))

    petsc = nil
    autosc = nil

    local player = windower.ffxi.get_player()
    local pet = windower.ffxi.get_abilities().job_abilities

    local chain = {}
    local chainonews = nil
    local chaintwows = nil
    if t[1] ~= nil then
        for i = 1,#t,+1 do
            if chaintwows == nil then
                chain[1] = t[i]:match("([%a\\'\\:%s]+)()(.+)")
                chain[2] = t[i]:match("Lv.%d")
                chain[3] = t[i]:match("%d%s%a+")
                if player.main_job == 'BST' or player.main_job == 'SMN' then
                    for p = 1,#pet,+1 do
                        local petclean = string.gsub(chain[1], '[ \t]+%f[\r\n%z]', '')
                        if petclean == res.job_abilities:with('id',pet[p]).name then
                            local petmp = res.job_abilities:with('en', petclean).mp_cost
                            if player.main_job == 'SMN' then
                                if (windower.ffxi.get_ability_recasts()[173] < 1) then
                                    petsc = petclean
                                    petskill = 1
                                else
                                    petskill = 1
                                end
                            elseif player.main_job == 'BST' then
                                if ((sicdelay + petmp) < 4) then
                                    petsc = petclean
                                    petskill = 1
                                else
                                    petskill = 1
                                end
                            end
                        else
                            petskill = 0
                        end
                    end
                end
                if petskill == 0 then
                    if melee == 1 then
                        if rangedws:contains(chain[1]) then
                            meleeskill = 1
                        else
                            meleeskill = 0
                        end
                    end
                    if meleeskill == 0 then
                        local chainoneele = string.gsub(chain[3], '%d%s', '')
                        if light == 1 then
                            if lightchains:contains(''..chainoneele..'') then
                                if chainonews == nil then
                                    chainonelvl = chain[2]
                                    chainonews = chain[1]
                                elseif chaintwows == nil then
                                    chaintwolvl = chain[2]
                                    chaintwows = chain[1]
                                end
                            end
                        elseif dark == 1 then
                            if darkchains:contains(''..chainoneele..'') then
                                if chainonews == nil then
                                    chainonelvl = chain[2]
                                    chainonews = chain[1]
                                elseif chaintwows == nil then
                                    chaintwolvl = chain[2]
                                    chaintwows = chain[1]
                                end
                            end
                        else
                            if chainonews == nil then
                                chainonelvl = chain[2]
                                chainonews = chain[1]
                            elseif chaintwows == nil then
                                chaintwolvl = chain[2]
                                chaintwows = chain[1]
                            end
                        end
                    end
                end
            end
        end
    elseif close == 0 then
        chainonews = openws
    end

    local endlesssc = nil
    if endless == 1 then
        for i = 1,#t,+1 do
            if endlesssc == nil then
                local endlesschk = {}
                endlesschk[1] = t[i]:match("([%a\\'\\:%s]+)()(.+)")
                endlesscln = string.gsub(endlesschk[1], '[ \t]+%f[\r\n%z]', '')
                endlesschk[2] = t[i]:match("Lv.%d")
                endlesslvl = endlesschk[2]
                endlesschk[3] = t[i]:match("%d%s%a+")
                local endlessele = string.gsub(endlesschk[3], '%d%s', '')
                if endlesssc == nil then
                    if endlesslvl == "Lv.2" or endlesslvl == "Lv.1" then
                        if ranged == 1 then
                            if rangedws:contains(endlesscln) then
                                if light == 1 then
                                    if lightchains:contains(''..endlessele..'') then
                                        endlesssc = endlesscln
                                    end
                                elseif dark == 1 then
                                    if darkchains:contains(''..endlessele..'') then
                                        endlesssc = endlesscln
                                    end
                                else
                                    endlesssc = endlesscln
                                end
                            end
                        else
                            if light == 1 then
                                if lightchains:contains(''..endlessele..'') then
                                    endlesssc = endlesscln
                                end
                            elseif dark == 1 then
                                if darkchains:contains(''..endlessele..'') then
                                    endlesssc = endlesscln
                                end
                            else
                                endlesssc = endlesscln
                            end
                        end
                    end
                end
            end
        end
    end

    local prefersc = nil
    if (prefer == 1 or strict == 1) and ranged == 0 then
        for p = 1,#preferws,1 do
            for i = 1,#t,1 do
                if prefersc == nil then
                    local preferchk = {}
                    preferchk[1] = t[i]:match("([%a\\'\\:%s]+)()(.+)")
                    preferchkcln = string.gsub(preferchk[1], '[ \t]+%f[\r\n%z]', '')
                    preferchk[2] = t[i]:match("Lv.%d")
                    preferlvl = preferchk[2]
                    preferchk[3] = t[i]:match("%d%s%a+")
                    preferele = string.gsub(preferchk[3], '%d%s', '')
                    if preferws[p] == preferchkcln then
                        if light == 1 then
                            if lightchains:contains(''..preferele..'') then
                                prefersc = preferchkcln
                            end
                        elseif dark == 1 then
                            if darkchains:contains(''..preferele..'') then
                                prefersc = preferchkcln
                            end
                        elseif prefersc == nil then
                            prefersc = preferchkcln
                        end
                    end
                end
            end
        end
    end

    local rangedwsone = nil
    local rangedwstwo = nil
    if ranged == 1 then
        if (prefer == 1 or strict == 1) then
            for p = 1,#preferws,+1 do
                if rangedws:contains(preferws[p]) then
                    for i = 1,#t,+1 do
                        if prefersc == nil then
                            local preferchk = {}
                            preferchk[1] = t[i]:match("([%a\\'\\:%s]+)()(.+)")
                            preferchkcln = string.gsub(preferchk[1], '[ \t]+%f[\r\n%z]', '')
                            preferchk[2] = t[i]:match("Lv.%d")
                            preferlvl = preferchk[2]
                            preferchk[3] = t[i]:match("%d%s%a+")
                            preferele = string.gsub(preferchk[3], '%d%s', '')
                            if preferws[p] == preferchkcln then
                                if light == 1 then
                                    if lightchains:contains(''..preferele..'') then
                                        prefersc = preferchkcln
                                    end
                                elseif dark == 1 then
                                    if darkchains:contains(''..preferele..'') then
                                        prefersc = preferchkcln
                                    end
                                elseif prefersc == nil then
                                    prefersc = preferchkcln
                                end
                            end
                        end
                    end
                end
            end
        end
        if prefer == 0 or prefersc == nil then
            for i = 1,#t,+1 do
                local rangedchk = {}
                rangedchk[1] = t[i]:match("([%a\\'\\:%s]+)()(.+)")
                rangedchkcln = string.gsub(rangedchk[1], '[ \t]+%f[\r\n%z]', '')
                rangedchk[2] = t[i]:match("Lv.%d")
                rangedchk[3] = t[i]:match("%d%s%a+")
                rangedele = string.gsub(rangedchk[3], '%d%s', '')
                if rangedws:contains(rangedchkcln) then
                    if rangedwsone == nil then
                        if light == 1 then
                            if lightchains:contains(''..rangedele..'') then
                                rangedwsone = rangedchkcln
                                rangedlvlone = rangedchk[2]
                            end
                        elseif dark == 1 then
                            if darkchains:contains(''..rangedele..'') then
                                rangedwsone = rangedchkcln
                                rangedlvlone = rangedchk[2]
                            end
                        else
                            rangedwsone = rangedchkcln
                            rangedlvlone = rangedchk[2]
                        end
                    elseif rangedwstwo == nil then
                        if light == 1 then
                            if lightchains:contains(''..rangedele..'') then
                                rangedwstwo = rangedchkcln
                                rangedlvltwo = rangedchk[2]
                            end
                        elseif dark == 1 then
                            if darkchains:contains(''..rangedele..'') then
                                rangedwstwo = rangedchkcln
                                rangedlvltwo = rangedchk[2]
                            end
                        else
                            rangedwstwo = rangedchkcln
                            rangedlvltwo = rangedchk[2]
                        end
                    end
                end
            end
        end
    end

    if ranged == 1 then
        if prefersc ~= nil then
            if ultimate == 1 then
                if preferlvl == "Lv.4" then
                    autosc = prefersc
                end
            else
                autosc = prefersc
            end
        elseif strict == 1 and prefersc == nil then
            autosc = nil
        elseif endlesssc ~= nil then
            autosc = endlesssc
        else
            if rangedlvlone == "Lv.4" and ultimate == 1 then
                autosc = rangedwsone
            elseif ultimate == 0 then
                if rangedwstwo == nil then
                    autosc = rangedwsone
                elseif rangedlvlone == "Lv.4" then
                    autosc = rangedwstwo
                else
                    autosc = rangedwsone
                end
            end
        end
    else
        if prefersc ~= nil then
            if ultimate == 1 then
                if preferlvl == "Lv.4" then
                    autosc = prefersc
                end
            else
                autosc = prefersc
            end
        elseif strict == 1 and prefersc == nil then
            autosc = nil
        elseif endlesssc ~= nil then
            autosc = endlesssc
        else
            if chainonelvl == "Lv.4" and ultimate == 1 then
                autosc = chainonews
            elseif ultimate == 0 then
                if chaintwows == nil then
                    autosc = chainonews
                elseif chainonelvl == "Lv.4" then
                    autosc = chaintwows
                else
                    autosc = chainonews
                end
            end
        end
    end

    return _raw.table.concat(t, '\n')
end

local next_frame = os.clock()

function SkillchainMaker:on_target_change()
    if starter == 1 then
        started = 0
    end
end

function SkillchainMaker:on_prerender()
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
        local tp = player.vitals.tp
        local status = player.status
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
            disabled = 1
        else
            disabled = 0
        end

        if am == 1 then
            if buffs:contains(272) then
                amthree = 0
            else
                amthree = 1
            end
        elseif am == 0 then
            amthree = 0
        end

        local party = windower.ffxi.get_party()
        if party.p1 ~= nil then
            player1 = windower.ffxi.get_mob_by_name(party.p1.name)
        end
        if player1 == nil or party.p1 == nil then
            p1tp = 0
            p1st = 0
        elseif player1.is_npc or ignoretp:contains(party.p1.name) then
            p1tp = 0
            p1st = 0
        else
            p1tp = party.p1.tp
            p1st = player1.status
        end
        if party.p2 ~= nil then
            player2 = windower.ffxi.get_mob_by_name(party.p2.name)
        end
        if player2 == nil or party.p2 == nil then
            p2tp = 0
            p2st = 0
        elseif player2.is_npc or ignoretp:contains(party.p2.name) then
            p2tp = 0
            p2st = 0
        else
            p2tp = party.p2.tp
            p2st = player2.status
        end
        if party.p3 ~= nil then
            player3 = windower.ffxi.get_mob_by_name(party.p3.name)
        end
        if player3 == nil or party.p3 == nil then
            p3tp = 0
            p3st = 0
        elseif player3.is_npc or ignoretp:contains(party.p3.name) then
            p3tp = 0
            p3st = 0
        else
            p3tp = party.p3.tp
            p3st = player3.status
        end
        if party.p4 ~= nil then
            player4 = windower.ffxi.get_mob_by_name(party.p4.name)
        end
        if player4 == nil or party.p4 == nil then
            p4tp = 0
            p4st = 0
        elseif player4.is_npc or ignoretp:contains(party.p4.name) then
            p4tp = 0
            p4st = 0
        else
            p4tp = party.p4.tp
            p4st = player4.status
        end
        if party.p5 ~= nil then
            player5 = windower.ffxi.get_mob_by_name(party.p5.name)
        end
        if player5 == nil or party.p5 == nil then
            p5tp = 0
            p5st = 0
        elseif player5.is_npc or ignoretp:contains(party.p5.name) then
            p5tp = 0
            p5st = 0
        else
            p5tp = party.p5.tp
            p5st = player5.status
        end

        if buddy == 1 then
            if (tp > p1tp or p1tp < 1000 or (tp == 3000 and p1tp == 3000) or p1st ~= 1) and
                    (tp > p2tp or p2tp < 1000 or (tp == 3000 and p2tp == 3000) or p2st ~= 1) and
                    (tp > p3tp or p3tp < 1000 or (tp == 3000 and p3tp == 3000) or p3st ~= 1) and
                    (tp > p4tp or p4tp < 1000 or (tp == 3000 and p4tp == 3000) or p4st ~= 1) and
                    (tp > p5tp or p5tp < 1000 or (tp == 3000 and p5tp == 3000) or p5st ~= 1) then
                if os.clock() - tagtime > tagdelay then
                    tagin = 0
                end
            else
                tagin = 1
                tagtime = os.clock()
            end
        end

        if wsdelay == 1 then
            if os.clock() - wstime > 2.75 then
                wsdelay = 0
            end
        end

        if tpdelay == 1 then
            if os.clock() - wstime > 0.5 then
                tpdelay = 0
            end
        end

        if petdelay == 1 then
            if os.clock() - pettime > 1.25 then
                petdelay = 0
            end
        end

        if player.main_job == 'BST' then
            if (windower.ffxi.get_ability_recasts()[102] > 0) then
                if (windower.ffxi.get_ability_recasts()[102] > (bstrecast * 2)) then
                    sicdelay = 3
                elseif (windower.ffxi.get_ability_recasts()[102] > (bstrecast * 1)) then
                    sicdelay = 2
                else
                    sicdelay = 1
                end
            else
                sicdelay = 0
            end
        end

        if player.main_job == 'SMN' then
            if (windower.ffxi.get_ability_recasts()[173] > 0) then
                bpdelay = 1
            else
                bpdelay = 0
            end
        end

        if autosc ~= nil and info.job ~= 'SMN' and info.job ~= 'BST' and info.job ~= 'SCH' then
            wsclean = string.gsub(autosc, '[ \t]+%f[\r\n%z]', '')
            wsrange = res.weapon_skills:with('en', wsclean).range
        elseif openws ~= nil then
            wsrange = res.weapon_skills:with('en', openws).range
        else
            wsrange = 0
        end

        if windower.ffxi.get_player().target_index ~= nil then
            local targetmob = windower.ffxi.get_mob_by_index(windower.ffxi.get_player().target_index)
            local mobsize = targetmob.model_size
            local mobscale = targetmob.model_scale
            mobdist = targetmob.distance:sqrt()
            if ranged == 1 then
                wsdist = 21
            else
                wsdist = mobsize + wsrange + (0.21 + (0.21 * mobsize))
            end
        else
            mobdist = 50
            wsdist = 0
        end

        if wsdist < 3.5 then
            wsdist = 3.5
        end

        if innin == 1 and status == 1 then
            if (mobdist < wsdist) then
                if player.main_job == 'NIN' then
                    if faw == 0 then
                        behind()
                    end
                else
                    behind()
                end
            else
                windower.send_command('setkey numpad4 up')
                windower.send_command('setkey numpad6 up')
            end
        else
            windower.send_command('setkey numpad4 up')
            windower.send_command('setkey numpad6 up')
        end

        if yonin == 1 and status == 1 then
            if (mobdist < wsdist) then
                front()
            else
                windower.send_command('setkey numpad4 up')
                windower.send_command('setkey numpad6 up')
            end
        else
            windower.send_command('setkey numpad4 up')
            windower.send_command('setkey numpad6 up')
        end

        local targ = windower.ffxi.get_mob_by_target('t', 'bt')
        targ_id = targ and targ.id
        local reson = resonating[targ_id]
        local timer = reson and (reson.times - now) or 0
        local tname = targ and targ.name

        if targ and targ.hpp > 0 and timer > 0 then
            if not reson.closed then
                reson.disp_info = reson.disp_info or self:check_results(reson)
                delay = reson.delay
                if auto == 1 and status == 1 and disabled == 0 and tagin == 0 and mobdist < wsdist and open == 0 then
                    if now > delay then
                        if burst == 0 then
                            if amthree == 0 then
                                if autosc ~= nil and tp > 999 then
                                    self:perform_ws(autosc)
                                elseif petsc ~= nil and tp < 1000 then
                                    self:perform_pet(petsc)
                                elseif close == 0 then
                                    if tp > 2000 and overws ~= nil then
                                        self:perform_ws(overws)
                                    elseif openws ~= nil and ultimate == 0 and tp > 999 then
                                        self:perform_ws(openws)
                                    elseif petopen ~= nil then
                                        self:perform_pet(petopen)
                                    end
                                end
                            elseif amthree == 1 and tp == 3000 then
                                if amws ~= nil then
                                    self:perform_ws(amws)
                                end
                            end
                        elseif burst == 1 then
                            if timer < bursttime or reson.step == 1 then
                                if amthree == 0 then
                                    if autosc ~= nil and tp > 999 then
                                        self:perform_ws(autosc)
                                    elseif petsc ~= nil and tp < 1000 then
                                        self:perform_pet(petsc)
                                    end
                                elseif amthree == 1 and tp == 3000 then
                                    if autosc ~= nil then
                                        if amws ~= nil then
                                            self:perform_ws(amws)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            else
                resonating[targ_id] = nil
                return
            end
        elseif not visible then
            petsc = nil
            autosc = nil
            automb = nil
            faw = 0
            if targ and targ.hpp > 0 and targ.hpp < 100 and auto == 1 and status == 1 and disabled == 0 and tagin == 0 and mobdist < wsdist and close == 0 then
                if amthree == 0 then
                    if starter == 0 or started == 1 then
                        if tp > 2000 and overws ~= nil then
                            self:perform_ws(overws)
                        elseif tp > 999 and openws ~= nil then
                            self:perform_ws(openws)
                        elseif petopen ~= nil then
                            self:perform_pet(petopen)
                        end
                    elseif starter == 1 and started == 0 then
                        if tp > 999 and initws ~= nil then
                            self:perform_ws(initws)
                            started = 1
                        end
                    end
                elseif tp == 3000 and amthree == 1 then
                    if amws ~= nil then
                        self:perform_ws(amws)
                    end
                end
            end
        end
        if targ and targ.hpp > 0 and targ.hpp < 100 and spam == 1 and status == 1 and disabled == 0 and mobdist < wsdist then
            if ((w_casting == 1 or w_readies == 1) and wstrigger == 0) or (w_casting == 0 and w_readies == 0) then
                if amthree == 0 then
                    if tp > 999 and cleave == 1 then
                        if aoews ~= nil then
                            self:perform_ws(aoews)
                        end
                    elseif tp > 999 and starter == 0 or started == 1 then
                        if zergws ~= nil then
                            self:perform_ws(zergws)
                            wstrigger = 1
                        end
                    elseif tp > 999 and starter == 1 and started == 0 then
                        if initws ~= nil then
                            self:perform_ws(initws)
                            started = 1
                            wstrigger = 1
                        end
                    elseif petopen ~= nil then
                        self:perform_pet(petopen)
                    end
                elseif tp == 3000 and amthree == 1 then
                    if amws ~= nil then
                        self:perform_ws(amws)
                        wstrigger = 1
                    end
                end
            end
        end
    end
end

--[[windower.register_event(
        "incoming text",
        function(original, modified, mode)

            local tmob = windower.ffxi.get_mob_by_target('t')
            local tname = tmob and tmob.name

            if tname ~= nil then
                if original:contains(tname) then
                    if w_readies == 1 then
                        if original:contains(tname .. " readies") then
                            wstrigger = 0
                        end
                    elseif w_casting == 1 then
                        if original:contains(tname .. " starts casting") then
                            wstrigger = 0
                        end
                    end
                end
            end

            local player = windower.ffxi.get_player()
            local pname = player.name

            if original:contains("conducts a rousing symphony") and conduct == 0 then
                if not original:contains(pname) then
                    windower.send_command('input /jobemote brd;wait 5;input //sc conduct')
                    conduct = 1
                else
                    windower.send_command('wait 5;input //sc conduct')
                    conduct = 1
                end
            end

            return modified, mode
        end)

windower.register_event('chat message', function(message, sender, mode, gm)

    if buddy == 1 then

        if message:contains('Aftermath Down') or message:contains('WS Disabled') then
            windower.send_command('input //sc ignore ' .. sender .. '')
        end

        if message:contains('Aftermath Up') or message:contains('WS Enabled') then
            windower.send_command('input //sc watch ' .. sender .. '')
        end

    end

end)]]

function SkillchainMaker:on_gain_buff(id)
    if buddy == 1 then
        if am == 1 then
            local buff_name = res.buffs[id].name
            if buff_name == "Aftermath: Lv.3" then
                windower.send_command('input /p Aftermath Up')
            end
        end

        if id == 2 or
                id == 7 or
                id == 10 or
                id == 14 or
                id == 16 or
                id == 17 or
                id == 19 or
                id == 28 or
                id == 156 then
            windower.send_command('input /p WS Disabled')
        end
    end
end

function SkillchainMaker:on_lose_buff(id)
    local player = windower.ffxi.get_player()
    local buffs = L(player.buffs)

    if buddy == 1 then

        if am == 1 then
            local buff_name = res.buffs[id].name
            if buff_name == "Aftermath: Lv.3" then
                windower.send_command('input /p Aftermath Down')
            end
        end

        if L { 2, 7, 10, 14, 16, 17, 19, 28, 156 }:contains(id) then
            if not buffs:contains(L { 2, 7, 10, 14, 16, 17, 19, 28, 156 }) then
                windower.send_command('input /p WS Enabled')
            end
        end

    end
end

function SkillchainMaker:check_buff(t, i)
    if t[i] == true or t[i] - os.time() > 0 then
        return true
    end
    t[i] = nil
end

function SkillchainMaker:chain_buff(t)
    local i = t[164] and 164 or t[470] and 470
    if i and self:check_buff(t, i) then
        t[i] = nil
        return true
    end
    return t[163] and self:check_buff(t, 163)
end

function SkillchainMaker:perform_pet(petws_name)
    player = windower.ffxi.get_player()
    petws_name = string.gsub(petws_name, '[ \t]+%f[\r\n%z]', '')
    petws_mp = res.job_abilities:with('en', petws_name).mp_cost
    if petdelay == 0 then
        if player.main_job == 'BST' then
            if (sicdelay + petws_mp) < 4 then
                windower.send_command('input /pet ' .. petws_name .. ' <me>')
            end
        elseif player.main_job == 'SMN' then
            if bpdelay < 1 then
                windower.send_command('input /pet ' .. petws_name .. ' <t>')
            end
        end
        self:pet_delay()
    end
end

function SkillchainMaker:perform_ws(ws_name)
    ws_name = string.gsub(ws_name, '[ \t]+%f[\r\n%z]', '')
    if tpdelay == 0 then
        self:on_perform_next_weapon_skill():trigger(self, ws_name)
        self:ws_delay()
    end
end

function SkillchainMaker:ignore_player(player_name)
    if not ignoretp:contains(player_name) and player_name then
        ignoretp:add(player_name)
        windower.add_to_chat(207, '%s: Added %s to ignore list':format(_addon.name, player_name))
    end
end

function SkillchainMaker:watch_player(player_name)
    if ignoretp:contains(player_name) and player_name then
        ignoretp:remove(player_name)
        windower.add_to_chat(207, '%s: Removed %s to ignore list':format(_addon.name, player_name))
    end
end

categories = S {
    'weaponskill_finish',
    'spell_finish',
    'job_ability',
    'mob_tp_finish',
    'avatar_tp_finish',
    'job_ability_unblinkable',
}

function SkillchainMaker:apply_properties(target, resource, action_id, properties, delay, step, closed, bound)
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
    if target == targ_id then
        next_frame = clock
    end
end

function SkillchainMaker:action_handler(act)
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

function SkillchainMaker:on_incoming_chunk(id, data)
    if id == 0x29 and data:unpack('H', 25) == 206 and data:unpack('I', 9) == info.player then
        buffs[info.player][data:unpack('H', 13)] = nil
    elseif id == 0x50 and data:byte(6) == 0 then
        info.main_weapon = data:byte(5)
        info.main_bag = data:byte(7)
        self:update_weapon()
    elseif id == 0x50 and data:byte(6) == 2 then
        info.range = data:byte(5)
        info.range_bag = data:byte(7)
        self:update_weapon()
    elseif id == 0x63 and data:byte(5) == 9 then
        local set_buff = {}
        for n = 1, 32 do
            local buff = data:unpack('H', n * 2 + 7)
            if buff_dur[buff] or buff > 269 and buff < 273 then
                set_buff[buff] = true
            end
        end
        buffs[info.player] = set_buff
    end
end

function SkillchainMaker:on_tp_change()
    self:check_sc()
end

function SkillchainMaker:set_auto(new_value)
    auto = new_value and 1 or 0
    if auto == 1 then
        spam = 0
    end
end

function SkillchainMaker:set_prefer(new_value)
    prefer = new_value and 1 or 0
    if prefer == 1 then
        self:set_auto(true)
        self:set_strict(false)
    end
end

function SkillchainMaker:set_strict(new_value)
    strict = new_value and 1 or 0
    if strict == 1 then
        self:set_auto(true)
        self:set_prefer(false)
    end
end

function SkillchainMaker:set_spam(new_value)
    spam = new_value and 1 or 0
    if spam == 1 then
        auto = 0
        open = 0
        close = 0
    end
end

function SkillchainMaker:set_cleave(new_value)
    cleave = new_value and 1 or 0
    spam = 1
    auto = 0
    open = 0
    close = 0
    cleave = 1
end

function SkillchainMaker:set_buddy(new_value)
    buddy = new_value and 1 or 0
    if buddy == 0 then
        tagin = 0
    end
end

function SkillchainMaker:set_aftermath(new_value)
    am = new_value and 1 or 0
end

function SkillchainMaker:set_open(new_value)
    open = new_value and 1 or 0
    if open == 1 then
        self:set_close(false)
    end
end

function SkillchainMaker:set_close(new_value)
    close = new_value and 1 or 0
    if close == 1 then
        self:set_open(false)
    end
end

return SkillchainMaker



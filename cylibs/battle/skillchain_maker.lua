---------------------------
-- Skillchain builder.
-- @class module
-- @name SkillchainMaker


require('luau')
require('pack')
require('actions')
nukes = require('nukes')
texts = require('texts')
skills = require('skills')
res = require('resources')

_static = S { 'WAR', 'MNK', 'WHM', 'BLM', 'RDM', 'THF', 'PLD', 'DRK', 'BST', 'BRD', 'RNG', 'SAM', 'NIN', 'DRG', 'SMN', 'BLU', 'COR', 'PUP', 'DNC', 'SCH', 'GEO', 'RUN' }
ignoretp = S { '' }
message_ids = S { 110, 185, 187, 317, 802 }
skillchain_ids = S { 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 385, 386, 387, 388, 389, 390, 391, 392, 393, 394, 395, 396, 397, 767, 768, 769, 770 }
buff_dur = { [163] = 40, [164] = 30, [470] = 60 }

skillchains = { 'Light', 'Darkness', 'Gravitation', 'Fragmentation', 'Distortion', 'Fusion', 'Compression', 'Liquefaction', 'Induration', 'Reverberation', 'Transfixion', 'Scission', 'Detonation', 'Impaction', 'Radiance', 'Umbra' }

sc_info = {
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

chainbound = {}
chainbound[1] = L { 'Compression', 'Liquefaction', 'Induration', 'Reverberation', 'Scission' }
chainbound[2] = L { 'Gravitation', 'Fragmentation', 'Distortion' } + chainbound[1]
chainbound[3] = L { 'Light', 'Darkness' } + chainbound[2]

aeonic_weapon = {
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

function SkillchainMaker.new(auto, buddy, mb, autonuke, am, prefer, endless, spam, defaultws, spamws, preferws, amws, zergws)
    local self = setmetatable({}, SkillchainMaker)

    self.auto = auto
    self.buddy = buddy
    self.mb = mb
    self.autonuke = autonuke
    self.am = am
    self.prefer = prefer
    self.endless = endless
    self.spam = spam
    self.autosc = nil
    self.defaultws = defaultws
    self.spamws = spamws
    self.preferws = preferws
    self.amws = amws
    self.bursttime = 1.5
    self.tagtime = os.clock()
    self.tagdelay = 0.5
    self.endless = 0
    self.amthree = 0
    self.resonating = {}
    self.disabled = 0
    self.tagin = 0
    self.zergws = zergws

    local equip = windower.ffxi.get_items('equipment')

    self.info = {}
    self.info.main_weapon = equip.main
    self.info.main_bag = equip.main_bag
    self.info.range = equip.range
    self.info.range_bag = equip.range_bag
    self.info.job = windower.ffxi.get_player().main_job
    self.info.player = windower.ffxi.get_player().id

    local main_weapon = windower.ffxi.get_items(info.main_bag, info.main_weapon).id
    if main_weapon ~= 0 then
        self.info.aeonic = aeonic_weapon[main_weapon] or self.info.range and aeonic_weapon[windower.ffxi.get_items(self.info.range_bag, self.info.range).id]
    end

    self.buffs = {}
    self.buffs[self.info.player] = {}

    self.defaultws = {}
    self.spamws = {}
    self.preferws = {}
    self.amws = {}

    return self
end

function SkillchainMaker:loaded()
    self.user_events = {}

    self.user_events.tp_change = windower.register_event('tp change', function(new, old)
        self:check_sc()
    end)

    self.user_events.incoming = windower.register_event('incoming chunk', function(id, data)
        if id == 0x29 and data:unpack('H', 25) == 206 and data:unpack('I', 9) == self.info.player then
            self.buffs[self.info.player][data:unpack('H', 13)] = nil
        elseif id == 0x63 and data:byte(5) == 9 then
            local set_buff = {}
            for n = 1, 32 do
                local buff = data:unpack('H', n * 2 + 7)
                if buff_dur[buff] or buff > 269 and buff < 273 then
                    set_buff[buff] = true
                end
            end
            self.buffs[self.info.player] = set_buff
        end
    end)
end

function SkillchainMaker:unloaded()

    for _,event in pairs(self.user_events) do
        windower.unregister_event(event)
    end
end

function SkillchainMaker:varclean()

    self.burst = 0

    self.nuking = 0
end

function SkillchainMaker:check_sc()

    local abilities = windower.ffxi.get_abilities().weapon_skills

    for i = 1, #defaultws,+1 do
        for s = 1, #abilities,+1 do
            if openws == nil then
                local wsid = res.weapon_skills:with('en', self.defaultws[i]).id
                local wsid = tonumber(wsid)
                if abilities[s] == wsid then
                    self.openws = self.defaultws[i]
                end
            end
        end
    end

    for i = 1, #spamws, +1 do
        for s = 1, #abilities,+1 do
            if self.zergws == nil then
                local wsid = res.weapon_skills:with('en', self.spamws[i]).id
                local wsid = tonumber(wsid)
                if abilities[s] == wsid then
                    self.zergws = self.spamws[i]
                end
            end
        end
    end
end

function SkillchainMaker:aeonic_am(step)
    for x = 270, 272 do
        if self.buffs[self.info.player][x] then
            return 272 - x < step
        end
    end
    return false
end

function SkillchainMaker:aeonic_prop(ability, actor)
    if ability.aeonic and (ability.weapon == self.info.aeonic and actor == self.info.player or --[[settings.aeonic and]] self.info.player ~= actor) then
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

function SkillchainMaker:add_skills(t, abilities, active, resource, AM)
    local tt = { {}, {}, {}, {} }
    for k = 1, #abilities do
        local ability_id = abilities[k]
        local skillchain = skills[resource][ability_id]
        if skillchain then
            local lv, prop, aeonic = self:check_props(active, aeonic_prop(skillchain, self.info.player))
            if prop then
                prop = AM and aeonic or prop
                tt[lv][#tt[lv] + 1] = settings.color and
                        '%-16s → Lv.%d %s%-14s\\cr':format
                (res[resource][ability_id].name, lv, colors[prop], prop) or
                '%-16s → Lv.%d %-14s':format(res[resource][ability_id].name, lv, prop)
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

function check_results(reson)
    self.autosc = nil
    local t = {}
    if --[[settings.Show.spell[info.job] and ]]self.info.job == 'SCH' then
        t = add_skills(t, { 0, 1, 2, 3, 4, 5, 6, 7 }, reson.active, 'elements')
    elseif --[[settings.Show.spell[info.job] and ]]self.info.job == 'BLU' then
        t = add_skills(t, windower.ffxi.get_mjob_data().spells, reson.active, 'spells')
    elseif --[[settings.Show.pet[info.job] and ]]windower.ffxi.get_mob_by_target('pet') then
        t = add_skills(t, windower.ffxi.get_abilities().job_abilities, reson.active, 'job_abilities')
    end
    --if settings.Show.weapon[info.job] then
    t = add_skills(t, windower.ffxi.get_abilities().weapon_skills, reson.active, 'weapon_skills', self.info.aeonic and aeonic_am(reson.step))
    --end

    local resonsc = nil

    autoskillone = t[1]
    autoskilltwo = t[2]

    local chainone = {}
    if autoskillone ~= nil then
        chainone[1] = autoskillone:match("([%a\\'\\:%s]+)()(.+)")
        chainone[2] = autoskillone:match("Lv.%d")
        chainonelvl = chainone[2]
        chainonews = chainone[1]
    end

    local chaintwo = {}
    if autoskilltwo ~= nil then
        chaintwo[1] = autoskilltwo:match("([%a\\'\\:%s]+)()(.+)")
        chaintwo[2] = autoskilltwo:match("Lv.%d")
        chaintwolvl = chaintwo[2]
        chaintwows = chaintwo[1]
    end

    local endlesssc = nil
    if self.endless == 1 then
        for i = 1, #t,+1 do
            if endlesssc == nil then
                local endlesschk = {}
                endlesschk[1] = t[i]:match("([%a\\'\\:%s]+)()(.+)")
                endlesschk[2] = t[i]:match("Lv.%d")
                if endlesschk[2] == "Lv.2" then
                    endlesssc = endlesschk[1]
                end
            end
        end
    end

    local prefersc = nil
    if self.prefer == 1 then
        for p = 1, #self.preferws,+1 do
            for i = 1, #t,+1 do
                local preferchk = {}
                preferchk[1] = t[i]:match("([%a\\'\\:%s]+)()(.+)")
                preferchkcln = string.gsub(preferchk[1], '[ \t]+%f[\r\n%z]', '')
                preferchk[2] = t[i]:match("Lv.%d")
                if preferws[p] == preferchkcln then
                    prefersc = preferchkcln
                    preferlvl = preferchk[2]
                end
            end
        end
    end

    if self.prefer == 1 then
        if prefersc == nil then
            if autoskilltwo == nil then
                self.autosc = chainonews
            elseif chainonelvl == "Lv.4" then
                resonsc = chaintwows
            else
                resonsc = chainonews
            end
        else
            resonsc = prefersc
        end
    elseif self.endless == 1 then
        if endlesssc == nil then
            if autoskilltwo == nil then
                resonsc = chainonews
            elseif chainonelvl == "Lv.4" then
                resonsc = chaintwows
            else
                resonsc = chainonews
            end
        else
            resonsc = endlesssc
        end
    else
        if autoskilltwo == nil then
            resonsc = chainonews
        elseif chainonelvl == "Lv.4" then
            resonsc = chaintwows
        else
            resonsc = chainonews
        end
    end

    self.autosc = resonsc

    return _raw.table.concat(t, '\n')
end

local next_frame = os.clock()

--[[windower.register_event('prerender', function()
    local now = os.clock()

    if now < next_frame then
        return
    end

    next_frame = now + 0.1

    for k, v in pairs(self.resonating) do
        if v.times - now + 10 < 0 then
            self.resonating[k] = nil
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
            buffs:contains(28) then
        self.disabled = 1
    else
        self.disabled = 0
    end

    if self.am == 1 then
        if buffs:contains(272) then
            self.amthree = 0
        else
            self.amthree = 1
        end
    elseif self.am == 0 then
        self.amthree = 0
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

    if self.buddy == 1 then
        if (tp > p1tp or (tp == 3000 and p1tp == 3000) or p1st ~= 1) and
                (tp > p2tp or (tp == 3000 and p2tp == 3000) or p2st ~= 1) and
                (tp > p3tp or (tp == 3000 and p3tp == 3000) or p3st ~= 1) and
                (tp > p4tp or (tp == 3000 and p4tp == 3000) or p4st ~= 1) and
                (tp > p5tp or (tp == 3000 and p5tp == 3000) or p5st ~= 1) then
            if os.clock() - self.tagtime > self.tagdelay then
                self.tagin = 0
            end
        else
            self.tagin = 1
            self.tagtime = os.clock()
        end
    end

    if self.autosc ~= nil and self.info.job ~= 'SMN' and self.info.job ~= 'BST' then
        wsclean = string.gsub(self.autosc, '[ \t]+%f[\r\n%z]', '')
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
        wsdist = mobsize + wsrange + (0.21 + (0.0625 * mobsize))
    else
        mobdist = 50
        wsdist = 0
    end

    if self.info.job == 'SMN' then
        if ((windower.ffxi.get_ability_recasts()[173]) < 1) then
            bpt = 0
        else
            bpt = 1
        end
    end

    local targ = windower.ffxi.get_mob_by_target('t', 'bt')
    targ_id = targ and targ.id
    local reson = self.resonating[targ_id]
    local timer = reson and (reson.times - now) or 0

    if targ and targ.hpp > 0 and timer > 0 then
        if not reson.closed then
            reson.disp_info = reson.disp_info or self:check_results(reson)
            local delay = reson.delay
            if tp > 999 and self.auto == 1 and status == 1 and self.disabled == 0 and self.tagin == 0 and mobdist < wsdist and self.nuking == 0 or self.bpt == 0 then
                if now > delay then
                    if self.burst == 0 then
                        if self.amthree == 0 then
                            if self.autosc ~= nil then
                                windower.send_command('input /ws ' .. self.autosc .. ' <t>')
                            else
                                if openws ~= nil then
                                    windower.send_command('input /ws ' .. openws .. ' <t>')
                                end
                            end
                        elseif self.amthree == 1 and tp == 3000 then
                            if self.amws ~= nil then
                                windower.send_command('input /ws ' .. self.amws .. ' <t>')
                            end
                        end
                    elseif self.burst == 1 then
                        if timer < self.bursttime or reson.step == 1 then
                            if self.amthree == 0 then
                                if self.autosc ~= nil then
                                    windower.send_command('input /ws ' .. self.autosc .. ' <t>')
                                end
                            elseif self.amthree == 1 and tp == 3000 then
                                if self.autosc ~= nil then
                                    if self.amws ~= nil then
                                        windower.send_command('input /ws ' .. self.amws .. ' <t>')
                                    end
                                end
                            end
                        end
                    end
                end
            end
            reson.timer = now < delay and
                    '\\cs(255,0,0)Wait  %.1f\\cr':format
            (delay - now) or
                    '\\cs(0,255,0)Go!   %.1f\\cr':format
            (timer)
        elseif settings.Show.burst[info.job] then
            reson.disp_info = ''
            reson.timer = 'Burst %d':format
            (timer)
            if targ and targ.hpp > 0 and targ.hpp < 100 and self.auto == 1 and self.burst == 0 and status == 1 and self.disabled == 0 and self.tagin == 0 and mobdist < wsdist and self.nuking == 0 then
                if tp > 999 and amthree == 0 then
                    if openws ~= nil then
                        windower.send_command('input /ws ' .. openws .. ' <t>')
                    end
                elseif tp == 3000 and amthree == 1 then
                    if self.amws ~= nil then
                        windower.send_command('input /ws ' .. self.amws .. ' <t>')
                    end
                end
            end
        else
            self.resonating[targ_id] = nil
            return
        end
        reson.name = res[reson.res][reson.id].name
        reson.props = reson.props or not reson.bound and colorize(reson.active) or 'Chainbound Lv.%d':format
        (reson.bound)
        reson.elements = reson.elements or reson.step > 1 and '(%s)':format
        (colorize(sc_info[reson.active[1]])) or ''
        --[[if reson.step > 1 and self.nuking == 0 and timer > 1 and self.autonuke == 1 then
            if reson.props == 'Light' or reson.props == 'Radiance' then
                windower.send_command('sc lightmb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Darkness' or reson.props == 'Umbra' then
                windower.send_command('sc darknessmb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Gravitation' then
                windower.send_command('sc gravmb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Fragmentation' then
                windower.send_command('sc fragmb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Distortion' then
                windower.send_command('sc distomb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Fusion' then
                windower.send_command('sc fusionmb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Compression' then
            elseif reson.props == 'Liquefaction' then
                windower.send_command('sc firemb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Induration' then
                windower.send_command('sc blizzardmb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Reverberation' then
                windower.send_command('sc watermb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Transfixion' then
                windower.send_command('sc darkmb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Scission' then
                windower.send_command('sc stonemb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Detonation' then
                windower.send_command('sc aeromb;wait 5.25;input //sc nuking')
            elseif reson.props == 'Impaction' then
                windower.send_command('sc thundermb;wait 5.25;input //sc nuking')
            end
            self.nuking = 1
        end
    end
    if targ and targ.hpp > 0 and targ.hpp < 100 and self.spam == 1 and status == 1 and self.disabled == 0 and mobdist < wsdist then
        if tp > 999 and self.amthree == 0 then
            if self.zergws ~= nil then
                windower.send_command('input /ws ' .. zergws .. ' <t>')
            end
        elseif tp == 3000 and amthree == 1 then
            if self.amws ~= nil then
                windower.send_command('input /ws ' .. amws .. ' <t>')
            end
        end
    end
end)]]

function SkillchainMaker:check_buff(t, i)
    if t[i] == true or t[i] - os.time() > 0 then
        return true
    end
    t[i] = nil
end

function SkillchainMaker:chain_buff(t)
    local i = t[164] and 164 or t[470] and 470
    if i and check_buff(t, i) then
        t[i] = nil
        return true
    end
    return t[163] and check_buff(t, 163)
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

function action_handler(act)
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
        local reson = self.resonating[target.id]
        local delay = ability and ability.delay or 3
        local step = (reson and reson.step or 1) + 1

        if level == 3 and reson and ability then
            level = check_props(reson.active, aeonic_prop(ability, actor))
        end

        local closed = level == 4

        self:apply_properties(target.id, resource, action_id, { skillchain }, delay, step, closed)
    elseif ability and (message_ids:contains(message_id) or message_id == 2 and self.buffs[actor] and self:chain_buff(self.buffs[actor])) then
        self:apply_properties(target.id, resource, action_id, aeonic_prop(ability, actor), ability.delay or 3, 1)
    elseif message_id == 529 then
        self:apply_properties(target.id, resource, action_id, chainbound[param], 2, 1, false, param)
    elseif message_id == 100 and buff_dur[param] then
        self.buffs[actor] = self.buffs[actor] or {}
        self.buffs[actor][param] = buff_dur[param] + os.time()
    end
end

ActionPacket.open_listener(action_handler)



return SkillchainMaker




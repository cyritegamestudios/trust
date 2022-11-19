---------------------------
-- Utility functions for all jobs.
-- @class module
-- @name JobUtil

_libs = _libs or {}

local res = require('resources')

local job_util = {}

_raw = _raw or {}

_libs.job_util = job_util

function job_util.all_jobs()
    return L{'WAR','WHM','RDM','PLD','BRD','SAM','DRG','BLU','PUP','SCH','RUN','MNK','BLM','THF','BST','RNG','NIN','SMN','COR','DNC','GEO','DRK'}
end

function job_util.melee_jobs()
    return L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','COR','DNC','DRK'}
end

-------
-- Returns a list of job abilities that reduce a player's enmity for their current main job and sub job that are not
-- on cooldown.
-- @tparam string main_job_short Main job short
-- @tparam string sub_job_short Sub job short
-- @treturn list List of localized job ability names
function job_util.get_enmity_reduction_job_abilities(main_job_short, sub_job_short)
    local main_job_abilities = {}
    main_job_abilities.PUP = S{'Ventriloquy'}

    local sub_job_abilities = {}
    sub_job_abilities.DRG = S{'High Jump', 'Super Jump'}

    local job_abilities = S{}

    if main_job_short and main_job_abilities[main_job_short] then
        job_abilities = set.union(job_abilities, main_job_abilities[main_job_short])
    end

    if sub_job_short and sub_job_abilities[sub_job_short] then
        job_abilities = set.union(job_abilities, sub_job_abilities[sub_job_short])
    end

    return job_abilities:filter(function(job_ability_name)
        return player_util.get_job_ability_recast(job_ability_name) == 0
    end)
end

-------
-- Returns whether the player knows a job ability, either from their main job or sub job.
-- @tparam number job_ability_id Job ability id (see job_abilities.lua)
-- @treturn Boolean True if the player knows the given job ability
function job_util.knows_job_ability(job_ability_id)
    local all_job_abilities = T(windower.ffxi.get_abilities().job_abilities)
    if all_job_abilities then
        for _,v in pairs(all_job_abilities) do
            if v == job_ability_id then
                return true
            end
        end
    end
    return false
end

-------
-- Returns the job ability id for the given localized job ability name.
-- @tparam string job_ability_name Localized job ability name
-- @treturn number Job ability id (see job_abilities.lua)
function job_util.job_ability_id(job_ability_name)
    local job_ability = res.job_abilities:with('en', job_ability_name)
    if job_ability then
        return job_ability.id
    end
    return nil
end

-------
-- Returns a list of spells that can dispel for for the player's current main job and sub job that are not
-- on cooldown.
-- @tparam string main_job_short Main job short
-- @tparam string sub_job_short Sub job short
-- @treturn list List of localized spell names
function job_util.get_dispel_spells(main_job_short, sub_job_short)
    local main_job_spells = {}
    main_job_spells.BRD = S{'Magic Finale'}
    main_job_spells.RDM = S{'Dispel'}
    main_job_spells.SCH = S{'Dispel'}
    main_job_spells.BLU = S{'Geist Wall','Blank Gaze'}

    local sub_job_spells = {}
    sub_job_spells.RDM = S{'Dispel'}

    local spell_names = S{}

    if main_job_spells[main_job_short] then
        spell_names = set.union(spell_names, main_job_spells[main_job_short])
    end

    if sub_job_spells[sub_job_short] then
        spell_names = set.union(spell_names, sub_job_spells[sub_job_short])
    end

    return spell_names:filter(function(spell_name)
        return spell_util.get_spell_recast(res.spells:with('en', spell_name).id) == 0
    end)
end

-------
-- Returns a list of job abilities that can dispel for for the player's current main job and sub job that are not
-- on cooldown.
-- @tparam string main_job_short Main job short
-- @tparam string sub_job_short Sub job short
-- @treturn list List of localized job ability names
function job_util.get_dispel_job_abilities(main_job_short, sub_job_short)
    local main_job_abilities = {}
    main_job_abilities.COR = S{'Dark Shot'}

    if pup_util.can_dispel() and not buff_util.is_buff_active(buff_util.buff_id('Dark Maneuver')) then
        main_job_abilities.PUP = S{'Dark Maneuver'}
    else
        main_job_abilities.PUP = S{}
    end

    local sub_job_abilities = {}

    local job_abilities = S{}

    if main_job_abilities[main_job_short] then
        job_abilities = set.union(job_abilities, main_job_abilities[main_job_short])
    end

    if sub_job_abilities[sub_job_short] then
        job_abilities = set.union(job_abilities, sub_job_abilities[sub_job_short])
    end

    return job_abilities:filter(function(job_ability_name)
        return job_util.can_use_job_ability(job_ability_name)
    end)
end

function job_util.can_use_job_ability(job_ability_name)
    local job_ability = res.job_abilities:with('en', job_ability_name)
    if job_ability.tp_cost > 0 then
        if windower.ffxi.get_player().vitals.tp  < job_ability.tp_cost then
            return false
        end
    end
    local recast_id = job_ability.recast_id
    local recast = windower.ffxi.get_ability_recasts()[recast_id]
    if not recast or recast > 0 then
        return false
    end
    return true
end

-------
-- Returns the number of job points the player has spent on a job. Excludes unspent points.
-- @tparam string job_short Job short
-- @treturn number Number of job points
function job_util.get_job_points(job_short)
    local job_data = windower.ffxi.get_player().job_points[job_short:lower()]
    if job_data then
        return job_data.jp_spent
    end
    return 0
end

return job_util
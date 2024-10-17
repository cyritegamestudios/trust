---------------------------
-- Utility functions for all jobs.
-- @class module
-- @name JobUtil

_libs = _libs or {}

local res = require('resources')
local jobs_ext = require('cylibs/res/jobs')

local job_util = {}

_raw = _raw or {}

_libs.job_util = job_util

function job_util.all_jobs()
    return L{'WAR','WHM','RDM','PLD','BRD','SAM','DRG','BLU','PUP','SCH','RUN','MNK','BLM','THF','BST','RNG','NIN','SMN','COR','DNC','GEO','DRK'}
end

function job_util.melee_jobs()
    return L{'WAR','PLD','BRD','SAM','DRG','BLU','PUP','RUN','MNK','THF','BST','NIN','DNC','DRK','GEO'}
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
-- Returns whether the player knows a weapon skill. Will only include weapon skills that show up in the weapon skill menu.
-- @tparam string weapon_skill_name Weapon skill name (see weapon_skills.lua)
-- @treturn Boolean True if the player knows the given weapon skill
function job_util.knows_weapon_skill(weapon_skill_name)
    local weapon_skill = res.weapon_skills:with('en', weapon_skill_name)
    if weapon_skill then
        local all_weapon_skills = T(windower.ffxi.get_abilities().weapon_skills)
        if all_weapon_skills then
            for _,v in pairs(all_weapon_skills) do
                if v == weapon_skill.id then
                    return true
                end
            end
        end
    end
    return false
end

-------
-- Returns the id for a weapon skill.
-- @tparam string weapon_skill_name Weapon skill name (see weapon_skills.lua)
-- @treturn number Weapon skill id, or nil if the weapon skill doesn't exist
function job_util.weapon_skill_id(weapon_skill_name)
    local weapon_skill = res.weapon_skills:with('en', weapon_skill_name)
    if weapon_skill then
        return weapon_skill.id
    end
    return nil
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

function job_util.can_use_job_ability(job_ability_name)
    local job_ability = res.job_abilities:with('en', job_ability_name)
    if job_ability.tp_cost > 0 then
        if windower.ffxi.get_player().vitals.tp < job_ability.tp_cost then
            return false
        end
    end
    if job_ability.type == 'Scholar' then
        return player_util.get_current_strategem_count() > 0
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

-------
-- Returns the skills for a job.
-- @tparam number job_id Job id
-- @treturn list List of skill ids (see skills.lua)
function job_util.get_skills_for_job(job_id)
    return jobs_ext[job_id].skills or L{}
end

function job_util.getAbility(abilityName)
    if res.spells:with('en', abilityName) then
        return Spell.new(abilityName, L{}, L{})
    elseif res.job_abilities:with('en', abilityName) then
        return JobAbility.new(abilityName, L{}, L{})
    elseif res.weapon_skills:with('en', abilityName) then
        return WeaponSkill.new(abilityName, L{})
    elseif abilityName == 'Approach' then
        return Approach.new()
    elseif abilityName == 'Ranged Attack' then
        return RangedAttack.new()
    elseif abilityName == 'Turn Around' then
        return TurnAround.new()
    elseif abilityName == 'Turn to Face' then
        return TurnToFace.new()
    elseif abilityName == 'Run Away' then
        return RunAway.new()
    elseif abilityName == 'Run To' then
        return RunTo.new()
    elseif abilityName == 'Engage' then
        return Engage.new()
    elseif abilityName == 'Command' then
        return Command.new()
    elseif abilityName == 'Use Item' then
        return UseItem.new()
    else
        return nil
    end
end

return job_util
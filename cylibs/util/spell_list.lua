local SpellList = {}
SpellList.__index = SpellList
SpellList.__type = "SpellList"

---
-- Creates a new SpellList.
--
-- @param number jobId Job id.
-- @param number jobLevel Job level.
-- @param list whitelist Whitelist of spell names.
--
-- @treturn SpellList The newly created SpellList.
--
function SpellList.new(jobId, jobLevel, whitelist)
    local self = setmetatable({}, SpellList)

    self.jobId = jobId
    self.jobLevel = jobLevel
    self.whitelist = whitelist:map(function(spellName)
        return res.spells:with('en', spellName).id
    end)

    return self
end

function SpellList:destroy()
end

---
-- Retrieves the list of spell ids known by the job.
--
-- @treturn list A list of known spells ids.
--
function SpellList:getKnownSpellIds()
    if self.knownSpellIds and self:checkHash() then
        return self.knownSpellIds
    end

    local jobPoints = job_util.get_job_points(res.jobs[self.jobId].ens)

    local allSpellIds = windower.ffxi.get_spells()
    self.knownSpellIds = L(T(allSpellIds):keyset()):filter(function(spellId)
        if allSpellIds[spellId] or self.whitelist:contains(spellId) then
            local spell = res.spells[spellId]
            if spell then
                local jobLevel = self.jobLevel
                if (spell.levels[self.jobId] or 0) > 99 then
                    if self.jobLevel >= 99 then
                        jobLevel = jobPoints
                    else
                        return false
                    end
                end
                if spell.levels[self.jobId] and jobLevel >= spell.levels[self.jobId] then
                    return true
                end
            end
        end
        return false
    end)

    self.hash = SpellList.hash(self.jobId, self.jobLevel, jobPoints)

    return self.knownSpellIds
end

function SpellList:checkHash()
    local hash = SpellList.hash(self.jobId, self.jobLevel, job_util.get_job_points(res.jobs[self.jobId].ens))
    return hash == self.hash
end

function SpellList.hash(jobId, jobLevel, jobPoints)
    return "hash-"..jobId..jobLevel..jobPoints
end

return SpellList
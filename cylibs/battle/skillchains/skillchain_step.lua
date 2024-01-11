local SkillchainStep = {}
SkillchainStep.__index = SkillchainStep
SkillchainStep.__class = "SkillchainStep"

-- Represents a step in a skillchain.
-- @tparam step number Step number of the skillchain (e.g. 1, 2, 3)
-- @tparam action [Spell|JobAbility|WeaponSkill] The action performed
-- @tparam skillchain Skillchain Skillchain associated with the step (e.g. Scission, Fragmentation, Darkness)
-- @tparam delay number Delay before the next step can be performed
-- @tparam expiration_time number Timestamp for when the skillchain window for this step ends
-- @treturn SkillchainStep instance
function SkillchainStep.new(step, ability, skillchain, delay, expiration_time)
    local self = setmetatable({
        step = step,
        ability = ability,
        skillchain = skillchain,
        delay = delay,
        expiration_time = expiration_time
    }, SkillchainStep)

    return self
end

-- Sets the skillchain.
-- @tparam Skillchain skillchain Sets the skillchain for this step (see Skillchain in skillchain_util.lua)
function SkillchainStep:set_skillchain(skillchain)
    self.skillchain = skillchain
end

-- Returns the skillchain.
-- @treturn Skillchain The skillchain for this step (see Skillchain in skillchain_util.lua)
function SkillchainStep:get_skillchain()
    return self.skillchain
end

-- Returns the step number of the skillchain.
-- @treturn number Step number (e.g. 1, 2, 3, etc.)
function SkillchainStep:get_step()
    return self.step
end

-- Returns the action performed at this step of the skillchain.
-- @treturn [Spell|JobAbility|WeaponSkill] Action performed
function SkillchainStep:get_ability()
    return self.ability
end

-- Returns the delay before the next step in the skillchain can be performed.
-- @treturn number Delay in seconds
function SkillchainStep:get_delay()
    return self.delay
end

-- Returns the timestamp for when the skillchain window for this step ends.
-- @treturn number Timestamp
function SkillchainStep:get_expiration_time()
    return self.expiration_time
end

-- Returns the number of seconds left in the skillchain window.
-- @treturn number Time remaining in seconds
function SkillchainStep:get_time_remaining()
    return math.max(self:get_expiration_time() - os.clock(), 0)
end

-- Returns whether this represents a terminal skillchain step.
-- @treturn boolean True if this is a terminal skillchain step
function SkillchainStep:is_closed()
    if self:get_skillchain() then
        return self:get_skillchain():get_level() >= 4
    end
    return false
end

-- Returns a string representation of the skillchain.
-- @treturn string String representation of the skillchain
function SkillchainStep:__tostring()
    if self:get_skillchain() then
        return "Step "..self:get_step()..": "..tostring(self:get_skillchain())
    else
        return "Step "..self:get_step()
    end
end

return SkillchainStep
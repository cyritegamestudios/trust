local res = require('resources')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')
local skillchain_util = require('cylibs/util/skillchain_util')
local skills = require('cylibs/res/skills')

local SkillchainBuilderStep = {}
SkillchainBuilderStep.__index = SkillchainBuilderStep
SkillchainBuilderStep.__class = "SkillchainBuilderStep"

function SkillchainBuilderStep.new(step)
    local self = setmetatable({
        step = step;
        next_steps = L{};
    }, SkillchainBuilderStep)
    return self
end

function SkillchainBuilderStep:add_step(step)
    self.next_steps:append(step)
end

function SkillchainBuilderStep:__tostring()
    return "Current Step: "..tostring(self.step).." Next Steps: "..self.next_steps:tostring()
end

function SkillchainBuilderStep:__eq(otherItem)
    if otherItem.__class ~= SkillchainBuilderStep.__class then
        return false
    end
    return self.step == otherItem.step and self.next_steps == otherItem.next_steps
end

local SkillchainBuilder = {}
SkillchainBuilder.__index = SkillchainBuilder
SkillchainBuilder.__class = "SkillchainBuilder"


function SkillchainBuilder.new(abilities)
    local self = setmetatable({
        abilities = abilities:filter(function(ability) return skills[ability.resource][ability.ability_id] ~= nil end);
    }, SkillchainBuilder)
    return self
end

function SkillchainBuilder:destroy()
end

function SkillchainBuilder:set_step(step)
    self.step = step
end

function SkillchainBuilder:get_next_steps()
    local steps = T{}
    if self.step and not self.step:is_closed() then
        local properties = L{}
        if self.step:get_skillchain() then
            properties:append(self.step:get_skillchain())
        else
            properties = self.step:get_ability():get_skillchain_properties()
        end
        for property1 in properties:it() do
            for ability in self.abilities:it() do
                if steps[ability:get_name()] == nil then
                    for property2 in ability:get_skillchain_properties():it() do
                        if skillchain_util[property1:get_name()][property2:get_name()] then
                            steps[ability:get_name()] = SkillchainStep.new(self.step:get_step() + 1, ability, skillchain_util[property1:get_name()][property2:get_name()]:get_name())
                            break
                        end
                    end
                end
            end
        end
    end
    return steps
end

function SkillchainBuilder:build(starter_ability)
    --[[local skillchains = L{
        SkillchainStep.new(1, starter_ability, nil)
    }
    local all_skillchain_properties = L{
        'Transfixion',
        'Liquefaction',
        'Impaction',
        'Detonation',
        'Compression',
        'Reverberation',
        'Scission',
        'Induration',
        'Fusion',
        'Fragmentation',
        'Gravitation',
        'Distortion',
        'Light',
        'Darkness',
        'LightLv4',
        'DarknessLv4',
        'Radiance',
        'Umbra'
    }

    local first_step = SkillchainBuilderStep.new(SkillchainStep.new(1, starter_ability, nil))
    local visited = L{}

    local steps = L{ first_step }
    while not steps:empty() do
        local step1 = steps:remove(1)
        if not visited:contains(step1) then
            visited:append(step1)
            local ability = step1.step:get_ability()
            for property1 in ability:get_skillchain_properties():it() do
                for property2 in all_skillchain_properties:it() do
                    if skillchain_util[property1:get_name()][property2] then
                        local abilities = self:get_abilities(skillchain_util[property2])
                        if step1.step:get_step() < 4 then
                            for ability in abilities:it() do
                                local step2 = SkillchainBuilderStep.new(SkillchainStep.new(step1.step:get_step() + 1, ability, property2))
                                step1:add_step(step2)

                                steps:append(step2)
                            end
                        end
                    end
                end
            end
        end
    end

    local logger = require('cylibs/logger/logger')

    local loop_num = 1

    local visited = L{}
    local steps = L{ first_step }

    while not steps:empty() do
        loop_num = loop_num + 1
        if loop_num > 100 then
            print('loop too long')
            break
        end
        local step = steps:remove(1)
        if not visited:contains(step) then
            visited:append(step)
            logger.notice("Step", step.step:get_step(), step.step:get_ability():get_name(), step.step:get_skillchain()  or 'none')

            for child in step.next_steps:it() do
                if not visited:contains(child) then
                    steps:append(child)
                end
            end
        end
    end]]
end

function SkillchainBuilder:set_abilities(abilities)
    self.abilities = abilities
end

function SkillchainBuilder:get_abilities(skillchain_property)
    return self.abilities:filter(function(ability) return ability:get_skillchain_properties():contains(skillchain_property) end)
end

return SkillchainBuilder
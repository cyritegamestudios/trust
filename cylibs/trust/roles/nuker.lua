local Gambiter = require('cylibs/trust/roles/gambiter')
local Nuker = setmetatable({}, {__index = Gambiter })
Nuker.__index = Nuker

local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')

state.AutoNukeMode = M{['description'] = 'Free Nuke', 'Off', 'Earth', 'Lightning', 'Water', 'Fire', 'Ice', 'Wind', 'Light', 'Dark', 'Cleave', 'Mirror'}
state.AutoNukeMode:set_description('Earth', "Okay, I'll free nuke with earth spells.")
state.AutoNukeMode:set_description('Lightning', "Okay, I'll free nuke with lightning spells.")
state.AutoNukeMode:set_description('Water', "Okay, I'll free nuke with water spells.")
state.AutoNukeMode:set_description('Fire', "Okay, I'll free nuke with fire spells.")
state.AutoNukeMode:set_description('Ice', "Okay, I'll free nuke with ice spells.")
state.AutoNukeMode:set_description('Wind', "Okay, I'll free nuke with wind spells.")
state.AutoNukeMode:set_description('Light', "Okay, I'll free nuke with light spells.")
state.AutoNukeMode:set_description('Dark', "Okay, I'll free nuke with dark spells.")
state.AutoNukeMode:set_description('Cleave', "Okay, I'll try to cleave monsters with spells of any element.")
state.AutoNukeMode:set_description('Mirror', "Okay, I'll free nuke when the person I'm assisting nukes.")

-------
-- Default initializer for a nuker role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam T nuke_settings Nuke settings (see data/JobNameShort.lua)
-- @tparam fast_cast number Fast cast modifier (0.0 - 1.0)
-- @tparam List job_ability_names List of job abilities to use with spells (e.g. Cascade, Ebullience)
-- @treturn Nuker A nuker role
function Nuker.new(action_queue, nuke_settings, fast_cast, job_ability_names, job)
    local self = setmetatable(Gambiter.new(action_queue, {}, state.AutoNukeMode, true), Nuker)

    self.fast_cast = fast_cast or 0.8
    self.job = job
    self.requires_job_abilities = false
    self.dispose_bag = DisposeBag.new()

    self:set_nuke_settings(nuke_settings)

    return self
end

function Nuker:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function Nuker:on_add()
    Gambiter.on_add(self)

    self.dispose_bag:add(WindowerEvents.Spell.Begin:addAction(function(mob_id, spell_id)
        if state.AutoNukeMode.value ~= 'Mirror' or self:get_target() == nil then
            return
        end
        local assist_target = self:get_party():get_assist_target()
        if assist_target and assist_target:get_id() == mob_id
                and assist_target ~= self:get_party():get_player() then
            local spell = res.spells[spell_id]
            if spell and S{'Enemy'}:intersection(S(spell.targets)):length() > 0 and S{'BlackMagic', 'BlueMagic'}:contains(spell.type) then
                local gambit = Gambit.new(GambitTarget.TargetType.Enemy, L{}, Spell.new(spell.en), GambitTarget.TargetType.Enemy)
                gambit.conditions = self:get_default_conditions(gambit, true)
                if not gambit:isSatisfied(self:get_target()) then
                    gambit = self.nuke_settings.Gambits:map(function(gambit)
                        return Gambit.new(gambit:getAbilityTarget(), self:get_default_conditions(gambit, true), gambit:getAbility(), gambit:getConditionsTarget())
                    end):firstWhere(function(gambit)
                        return gambit:getAbility():get_element() == spell.element and gambit:isSatisfied(self:get_target())
                    end)
                end
                if gambit then
                    self:check_gambits(self:get_gambit_targets(GambitTarget.TargetType.Enemy), L{ gambit }, nil, true)
                end
            end
        end
    end), WindowerEvents.Spell.Begin)
end

function Nuker:get_cooldown()
    return self.nuke_cooldown or 0
end

function Nuker:allows_duplicates()
    return false
end

function Nuker:get_type()
    return "nuker"
end

function Nuker:allows_multiple_actions()
    return false
end

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function Nuker:set_nuke_settings(nuke_settings)
    self.nuke_settings = nuke_settings
    self.nuke_cooldown = nuke_settings.Delay or 2
    self.nuke_mpp = nuke_settings.MinManaPointsPercent or 20
    self.min_num_mobs_to_cleave = nuke_settings.MinNumMobsToCleave or 2

    local gambits = nuke_settings.Gambits:map(function(gambit)
        return gambit:copy()
    end)
    for gambit in gambits:it() do
        gambit:getAbility():set_requires_all_job_abilities(false)

        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        for condition in conditions:it() do
            condition.editable = false
            gambit:addCondition(condition)
        end
    end
    self:set_gambit_settings({ Gambits = gambits })
end

function Nuker:get_default_conditions(gambit, exclude_mode_conditions)
    local conditions = L{
    }

    if not exclude_mode_conditions then
        conditions:append(NotCondition.new(L{ ModeCondition.new('AutoNukeMode', 'Mirror') }))

        if self.job:get_aoe_spells():contains(gambit:getAbility():get_name()) then
            conditions:append(ModeCondition.new('AutoNukeMode', 'Cleave'))
            conditions:append(EnemiesNearbyCondition.new(self.min_num_mobs_to_cleave))
        else
            conditions:append(ModeCondition.new('AutoNukeMode', res.elements[gambit:getAbility():get_element()].en))
        end
    end

    if L(gambit:getAbility():get_valid_targets()) ~= L{ 'Self' } then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
    end

    conditions:append(MinManaPointsCondition.new(gambit:getAbility():get_mp_cost(), windower.ffxi.get_player().index))
    conditions:append(MinManaPointsPercentCondition.new(self.nuke_mpp, windower.ffxi.get_player().index))

    return conditions + self.job:get_conditions_for_ability(gambit:getAbility())
end

return Nuker
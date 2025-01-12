local ConditionalCondition = require('cylibs/conditions/conditional')
local DisposeBag = require('cylibs/events/dispose_bag')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local skillchain_util = require('cylibs/util/skillchain_util')

local Gambiter = require('cylibs/trust/roles/gambiter')
local MagicBurster = setmetatable({}, {__index = Gambiter })
MagicBurster.__index = MagicBurster
MagicBurster.__class = "MagicBurster"

state.AutoMagicBurstMode = M{['description'] = 'Magic Burst', 'Off', 'Auto', 'Earth', 'Lightning', 'Water', 'Fire', 'Ice', 'Wind', 'Light', 'Dark', 'Mirror'}
state.AutoMagicBurstMode:set_description('Auto', "Okay, I'll magic burst with any element.")
state.AutoMagicBurstMode:set_description('Earth', "Okay, I'll only magic burst with earth spells.")
state.AutoMagicBurstMode:set_description('Lightning', "Okay, I'll only magic burst with lightning spells.")
state.AutoMagicBurstMode:set_description('Water', "Okay, I'll only magic burst with water spells.")
state.AutoMagicBurstMode:set_description('Fire', "Okay, I'll only magic burst with fire spells.")
state.AutoMagicBurstMode:set_description('Ice', "Okay, I'll only magic burst with ice spells.")
state.AutoMagicBurstMode:set_description('Wind', "Okay, I'll only magic burst with wind spells.")
state.AutoMagicBurstMode:set_description('Light', "Okay, I'll only magic burst with light spells.")
state.AutoMagicBurstMode:set_description('Dark', "Okay, I'll only magic burst with dark spells.")
state.AutoMagicBurstMode:set_description('Mirror', "Okay, I'll magic burst when the person I'm assisting magic bursts.")

state.MagicBurstTargetMode = M{['description'] = 'Magic Burst Target Type', 'Single', 'All'}
state.MagicBurstTargetMode:set_description('Single', "Okay, I'll only magic burst with single target spells.")
state.MagicBurstTargetMode:set_description('All', "Okay, I'll magic burst with both single target and AOE spells.")

-------
-- Default initializer for a magic burster role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam T nuke_settings Nuke settings (see data/JobNameShort.lua)
-- @tparam fast_cast number Fast cast modifier (0.0 - 1.0)
-- @tparam List default_job_ability_names List of job abilities to use with spells if none are specified in settings (e.g. Cascade, Ebullience)
-- @tparam Job job Job
-- @treturn MagicBurster A magic burster role
function MagicBurster.new(action_queue, nuke_settings, fast_cast, default_job_ability_names, job, requires_job_abilities)
    local self = setmetatable(Gambiter.new(action_queue, {}, nil, state.AutoMagicBurstMode, true), MagicBurster)

    self.fast_cast = fast_cast or 0.8
    self.job = job
    self.requires_job_abilities = requires_job_abilities
    self.dispose_bag = DisposeBag.new()

    self:set_nuke_settings(nuke_settings)

    return self
end

function MagicBurster:destroy()
    Gambiter.destroy(self)

    self.dispose_bag:destroy()
end

function MagicBurster:on_add()
    Gambiter.on_add(self)

    WindowerEvents.Skillchain.Begin:addAction(function(target_id, skillchain_step)
        local target = self:get_target()
        if target and target:get_id() == target_id then
            self:check_gambits()
        end
    end)

    self.dispose_bag:add(self.action_queue:on_action_start():addAction(function(_, a)
        if a:getidentifier() == self.action_identifier then
            if self.gearswap_command and self.gearswap_command:length() > 0 then
                windower.send_command(self.gearswap_command)
            end
        end
    end), self.action_queue:on_action_start())

    self.dispose_bag:add(WindowerEvents.Spell.Begin:addAction(function(mob_id, spell_id)
        if state.AutoMagicBurstMode.value ~= 'Mirror' or self:get_target() == nil
                or self:get_target():get_skillchain() == nil or self:get_target():get_skillchain():is_expired() then
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

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function MagicBurster:set_nuke_settings(nuke_settings)
    self.nuke_settings = nuke_settings
    self.magic_burst_cooldown = nuke_settings.Delay or 2
    self.magic_burst_mpp = nuke_settings.MinManaPointsPercent or 20
    self.element_blacklist = nuke_settings.Blacklist or L{}
    self.gearswap_command = nuke_settings.GearswapCommand or 'gs c set MagicBurstMode Single'

    local element_id_blacklist = self.element_blacklist:map(function(element) return res.elements:with('en', element:get_name()).id end)

    for gambit in nuke_settings.Gambits:it() do
        gambit:getAbility():set_requires_all_job_abilities(self.requires_job_abilities)

        gambit.conditions = gambit.conditions:filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit) + self.job:get_conditions_for_ability(gambit:getAbility())
        for condition in conditions:it() do
            condition.editable = false
            gambit:addCondition(condition)
        end

        gambit:setEnabled(not element_id_blacklist:contains(gambit:getAbility():get_element()))
    end
    self:set_gambit_settings(nuke_settings)
end

function MagicBurster:get_default_conditions(gambit, exclude_mode_conditions)
    local conditions = L{
    }

    if not exclude_mode_conditions then
        conditions:append(ConditionalCondition.new(L{
            ModeCondition.new('AutoMagicBurstMode', res.elements[gambit:getAbility():get_element()].en),
            ModeCondition.new('AutoMagicBurstMode', 'Auto'),
        }, Condition.LogicalOperator.Or))
        conditions:append(NotCondition.new(L{ ModeCondition.new('AutoMagicBurstMode', 'Mirror') }))
    end

    if self.job:get_aoe_spells():contains(gambit:getAbility():get_name()) then
        conditions:append(ModeCondition.new('MagicBurstTargetMode', 'All'))
    end

    conditions:append(SkillchainPropertyCondition.new(skillchain_util.get_skillchain_properties_for_element(gambit:getAbility():get_element())))

    if L(gambit:getAbility():get_valid_targets()) ~= L{ 'Self' } then
        conditions:append(MaxDistanceCondition.new(gambit:getAbility():get_range()))
    end

    conditions:append(SkillchainWindowCondition.new(1.25, ">="))
    conditions:append(MinManaPointsCondition.new(gambit:getAbility():get_mp_cost(), windower.ffxi.get_player().index))
    conditions:append(MinManaPointsPercentCondition.new(self.magic_burst_mpp, windower.ffxi.get_player().index))

    return conditions
end

function Gambiter:get_cooldown()
    return self.magic_burst_cooldown or 0
end

function MagicBurster:allows_duplicates()
    return false
end

function MagicBurster:allows_multiple_actions()
    return false
end

function MagicBurster:get_type()
    return "magicburster"
end

return MagicBurster
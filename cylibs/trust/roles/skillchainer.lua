local Gambiter = require('cylibs/trust/roles/gambiter')
local Skillchainer = setmetatable({}, {__index = Gambiter })
Skillchainer.__index = Skillchainer
Skillchainer.__class = "Skillchainer"

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local renderer = require('cylibs/ui/views/render')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local SkillchainPropertyCondition = require('cylibs/conditions/skillchain_property')
local SkillchainTracker = require('cylibs/battle/skillchains/skillchain_tracker')
local skillchain_util = require('cylibs/util/skillchain_util')

state.AutoSkillchainMode = M{['description'] = 'Create Skillchains', 'Off', 'Auto', 'Cleave', 'Spam'}
state.AutoSkillchainMode:set_description('Auto', "Automatically skillchain with self and party members.")

state.SkillchainPropertyMode = M{['description'] = 'Skillchain Properties', 'Off', 'Light', 'Darkness'}
state.SkillchainPropertyMode:set_description('Off', "Make skillchains of any property.")
state.SkillchainPropertyMode:set_description('Light', "Only make light skillchains unless specific weapon skills are set.")
state.SkillchainPropertyMode:set_description('Darkness', "Only make Darkness skillchains unless specific weapon skills are set.")

state.SkillchainDelayMode = M{['description'] = 'Prioritze Magic Bursts', 'Off', 'Maximum'}
state.SkillchainDelayMode:set_description('Off', "Use the next weapon skill as soon as the skillchain window opens.")
state.SkillchainDelayMode:set_description('Maximum', "Delay using weapon skills to let party members magic burst.")

state.SkillchainAssistantMode = M{['description'] = 'Show Skillchain Assistant', 'Auto', 'Off'}
state.SkillchainAssistantMode:set_description('Auto', "Suggest weapon skills that can continue skillchains.")


-- Event called when the player readies a weaponskill. Triggers before the weaponskill command is sent.
function Skillchainer:on_ready_weaponskill()
    return self.ready_weaponskill
end

-- Event called when a skillchain is made
function Skillchainer:on_skillchain()
    return self.skillchain
end

-- Event called when a skillchain ends
function Skillchainer:on_skillchain_ended()
    return self.skillchain_ended
end

-- Event called when the list of active skills have changed (e.g. Great Axe, Blood Pacts, etc.)
function Skillchainer:on_skills_changed()
    return self.skills_changed
end

-- Event called when the list of abilities have changed.
function Skillchainer:on_abilities_changed()
    return self.abilities_changed
end

function Skillchainer.new(action_queue, weapon_skill_settings, job)
    local self = setmetatable(Gambiter.new(action_queue, { Gambits = L{} }, state.AutoSkillchainMode), Skillchainer)

    self.job = job
    self.gambit_for_step = L{}
    self.weapon_skill_settings = weapon_skill_settings
    self.num_skillchain_steps = 3
    self.action_identifier = self.__class..'_perform_skillchain'
    self.active_skills = L{}
    self.skillchain_builder = SkillchainBuilder.new()
    self.last_check_skillchain_time = os.time() - 1

    self.ready_weaponskill = Event.newEvent()
    self.skillchain = Event.newEvent();
    self.skillchain_ended = Event.newEvent();
    self.skills_changed = Event.newEvent();
    self.abilities_changed = Event.newEvent();

    self.dispose_bag = DisposeBag.new()

    self:set_current_settings(weapon_skill_settings:getSettings().Default)

    return self
end

function Skillchainer:destroy()
    Role.destroy(self)

    self:on_ready_weaponskill():removeAllActions()
    self:on_skillchain():removeAllActions()
    self:on_skillchain_ended():removeAllActions()
    self:on_skills_changed():removeAllActions()
    self:on_abilities_changed():removeAllActions()

    self.dispose_bag:destroy()
end

function Skillchainer:on_add()
    Role.on_add(self)

    self:update_abilities()

    self.dispose_bag:add(self.action_queue:on_action_start():addAction(function(_, a)
        if a:getidentifier() == self.action_identifier then
            self.is_performing_ability = true
        end
    end), self.action_queue:on_action_start())

    self.dispose_bag:add(self.action_queue:on_action_end():addAction(function(a, success)
        if a:getidentifier() == self.action_identifier then
            self.is_performing_ability = false
        end
    end), self.action_queue:on_action_end())

    self.skillchain_tracker = SkillchainTracker.new(self:get_party())
    self.skillchain_tracker:on_skillchain():addAction(function(mob_id, step)
        local target = self:get_party():get_target(mob_id)
        if target then
            target:set_skillchain(step)
            if target:get_mob() and target:get_mob().index == self.target_index then
                self.skillchain_builder:set_current_step(step)

                self:show_next_skillchain_info()
                self:on_skillchain():trigger(mob_id, step)

                WindowerEvents.Skillchain.Begin:trigger(mob_id, step)
            end
        end
    end)
    self.skillchain_tracker:on_skillchain_ended():addAction(function(mob_id)
        local target = self:get_party():get_target(mob_id)
        if target then
            target:set_skillchain(nil)
            if target:get_mob() and target:get_mob().index == self.target_index then
                local step = self.skillchain_tracker:get_current_step(mob_id)
                if step == nil then
                    self.is_performing_ability = false
                end
                self.skillchain_builder:set_current_step(step)

                self:show_next_skillchain_info()
                self:on_skillchain_ended():trigger(mob_id)
            end
        end
    end)
    self.dispose_bag:addAny(L{ self.skillchain_tracker })

    self.dispose_bag:add(self:get_party():get_player():on_combat_skills_change():addAction(function(_)
        self.weapon_skill_settings:reloadSettings()
        self:update_abilities()
        self:on_skillchain_mode_changed(state.AutoSkillchainMode.value, state.AutoSkillchainMode.value)
    end), self:get_party():get_player():on_combat_skills_change())

    self.dispose_bag:add(state.AutoSkillchainMode:on_state_change():addAction(function(old_value, new_value)
        self:on_skillchain_mode_changed(old_value, new_value)
    end), state.AutoSkillchainMode:on_state_change())

    self.dispose_bag:add(renderer.shared():onPrerender():addAction(function()
        self:check_skillchain()
    end), renderer.shared():onPrerender())

    self.dispose_bag:add(state.SkillchainPropertyMode:on_state_change():addAction(function(_, new_value)
        self.skillchain_builder:remove_all_conditions()

        if new_value == 'Light' then
            self.skillchain_builder:add_condition(SkillchainPropertyCondition.new(skillchain_util.LightSkillchains))
        elseif new_value == 'Darkness' then
            self.skillchain_builder:add_condition(SkillchainPropertyCondition.new(skillchain_util.DarknessSkillchains))
        end
    end), state.SkillchainPropertyMode:on_state_change())

    self.dispose_bag:add(state.WeaponSkillSettingsMode:on_state_change():addAction(function(_, new_value)
        self:set_current_settings(self.weapon_skill_settings:getSettings()[new_value])
    end), state.WeaponSkillSettingsMode:on_state_change())
end

function Skillchainer:on_skillchain_mode_changed(_, new_value)
    local target = self:get_target()
    if target then
        self.skillchain_builder:set_current_step(self.skillchain_tracker:get_current_step(target.id))
    end
end

function Skillchainer:target_change(target_index)
    Role.target_change(self, target_index)

    self.is_performing_ability = false
end

function Skillchainer:check_skillchain()
    if state.AutoSkillchainMode.value ~= 'Auto' or self.is_performing_ability or not self:get_player():is_engaged()
            or os.time() - self.last_check_skillchain_time < 1 then
        return
    end
    self.last_check_skillchain_time = os.time()

    local target = self:get_target()
    if target == nil then
        logger.notice(self.__class, 'check_skillchain', 'target is nil')
        return
    end

    local next_ability
    local step = self.skillchain_builder:get_current_step()
    if step and not step:is_expired() and (state.SkillchainDelayMode.value ~= 'Off' or not step:is_closed()) then
        if step:is_window_open() then
            logger.notice(self.__class, 'check_skillchain', 'get_next_steps')
            if state.SkillchainDelayMode.value ~= 'Off' then
                if step:get_skillchain() and step:get_time_remaining() > 3 then
                    logger.notice(self.__class, 'check_skillchain', 'get_next_steps', 'waiting until end of window')
                    self:get_party():add_to_chat(self:get_party():get_player(), "Keep those magic bursts coming, I'll hold my TP until the end of the window!", "SkillchainDelayMode", 10)
                    return
                end
            end
            next_ability = self:get_next_ability(step)
        end
    else
        next_ability = self:get_next_ability(nil)
    end

    if next_ability then
        logger.notice(self.__class, 'check_skillchain', 'get_next_steps', 'perform', next_ability:get_name(), step and step:get_skillchain() or 'starter')
        self:perform_ability(next_ability)
    else
        logger.notice(self.__class, 'check_skillchain', 'get_next_steps', 'no ability to perform')
    end
end

function Skillchainer:validate_step(current_step)
    if current_step == nil then
        return true
    end
    local gambit = self.gambit_for_step[current_step:get_step()]
    if gambit and not L{ SkillchainAbility.Auto, SkillchainAbility.Skip }:contains(gambit:getAbility():get_name()) then
        local previous_ability = current_step:get_ability()
        if previous_ability and previous_ability:get_skillchain_properties():length() > 0 and previous_ability:get_name() ~= gambit:getAbility():get_name() then
            self:get_party():add_to_chat(self:get_party():get_player(), "I wasn't expecting "..localization_util.translate(previous_ability:get_name())..". I'm going to start the skillchain over.", self.__class..'_previous_ability', 8)
            return false
        end
    end
    return true
end

function Skillchainer:get_next_ability(current_step)
    if not self:validate_step(current_step) then
        return nil
    end
    local step_num = 1
    if current_step then
        step_num = current_step:get_step() + 1
    end
    local gambit = self.gambit_for_step[step_num]
    if gambit and gambit:getAbility():get_name() ~= SkillchainAbility.Auto then
        if gambit:getAbility():get_name() == SkillchainAbility.Skip then
            return nil
        end
        if self:is_gambit_satisfied(gambit) then
            return gambit:getAbility()
        end
    else
        if current_step == nil then
            local ability = self:get_starter_ability(self.num_skillchain_steps)
            if ability and Condition.check_conditions(ability:get_conditions(), self:get_party():get_player():get_mob().index) then
                return self:get_starter_ability(self.num_skillchain_steps)
            end
        else
            local next_steps = self.skillchain_builder:get_next_steps()
            for step in next_steps:it() do
                local ability = step:get_ability()
                if Condition.check_conditions(ability:get_conditions(), self:get_party():get_player():get_mob().index) and not ability:is_aoe() then
                    return ability
                end
            end
        end
    end
    return nil
end

function Skillchainer:get_starter_ability(num_steps)
    if self.skillchain_builder:has_ability(self.gambit_for_step[1]:getAbility():get_name()) then
        return self.gambit_for_step[1]
    end
    local default_skillchains = self:get_default_skillchains()
    for skillchain in default_skillchains:it() do
        local skillchains = self.skillchain_builder:build(skillchain:get_name(), num_steps)
        if skillchains and skillchains:length() > 0 then
            return skillchains[1][1]
        end
    end
    return self.active_skills:first():get_default_ability()
end

function Skillchainer:get_default_skillchains()
    local light_skillchains = L{
        skillchain_util.Radiance,
        skillchain_util.LightLv4,
        skillchain_util.Light
    }
    local dark_skillchains = L{
        skillchain_util.Umbra,
        skillchain_util.DarknessLv4,
        skillchain_util.Darkness
    }
    if state.SkillchainPropertyMode.value == 'Light' then
        return light_skillchains
    elseif state.SkillchainPropertyMode.value == 'Darkness' then
        return dark_skillchains
    else
        return light_skillchains:merge(dark_skillchains)
    end
end

function Skillchainer:perform_ability(ability)
    local target = self:get_target()
    if not self.action_queue.is_enabled or target == nil then
        logger.notice(self.__class, 'perform_ability', ability:get_name(), not self.action_queue.is_enabled, target ~= nil)
        return false
    end

    local ability_action = ability:to_action(target:get_mob().index, self:get_player())
    if ability_action then
        ability_action.identifier = self.action_identifier
        ability_action.max_duration = 10
        ability_action.priority = ActionPriority.highest

        logger.notice(self.__class, 'perform_ability', ability:get_name(), 'push_action')

        self.action_queue:push_action(ability_action, true)
    end
end

function Skillchainer:show_next_skillchain_info()
    if state.SkillchainAssistantMode.value == 'Off' or state.AutoSkillchainMode.value ~= 'Auto'
            or not self:get_player():is_engaged() then
        return
    end
    local steps = self.skillchain_builder:get_next_steps()
    if steps:length() > 0 then
        local message = "I can continue the skillchain with"
        for step in steps:it() do
            message = "%s %s (%s),":format(message, localization_util.translate(step:get_ability():get_name()), step:get_skillchain())
        end
        self:get_party():add_to_chat(self:get_party():get_player(), message, nil, nil, true)
    end
end

function Skillchainer:update_abilities()
    local player = self:get_party() and self:get_party():get_player()
    if player == nil then
        return
    end
    self.active_skills:clear()

    local abilities = L{}
    for skill in self.current_settings.Skills:it() do
        if skill:is_valid(player) then
            abilities = abilities:extend(skill:get_abilities()):compact_map()
            self.active_skills:append(skill)
        end
    end
    self.skillchain_builder:set_abilities(abilities)

    self:on_skills_changed():trigger(self, self.active_skills)
    self:on_abilities_changed():trigger(self, abilities)
end

function Skillchainer:allows_duplicates()
    return false
end

function Skillchainer:get_type()
    return "skillchainer"
end

function Skillchainer:get_skillchain_tracker()
    return self.skillchain_tracker
end

function Skillchainer:get_active_skills()
    return self.active_skills
end

function Skillchainer:set_current_settings(current_settings)
    self.current_settings = current_settings

    self.gambit_for_step = current_settings.Skillchain.Gambits
    for stepNum, gambit in ipairs(self.gambit_for_step) do
        gambit.conditions = (gambit.conditions or L{}):filter(function(condition)
            return condition:is_editable()
        end)
        local conditions = self:get_default_conditions(gambit)
        if stepNum > 1 then
            conditions:append(SkillchainStepCondition.new(stepNum - 1, Condition.Operator.Equals))
        end
        for condition in conditions:it() do
            condition:set_editable(false)
            gambit:addCondition(condition)
        end
    end

    self:update_abilities()
end

function Skillchainer:get_default_conditions(gambit)
    local conditions = L{}
    for skill in self.current_settings.Skills:it() do
        if skill:get_ability(gambit:getAbility():get_name()) then
            conditions = conditions + skill:get_default_conditions(gambit:getAbility():get_name())
        end
    end

    local ability_conditions = L{}--(L{} + self:get_job():get_conditions_for_ability(gambit:getAbility()))

    return conditions + ability_conditions:map(function(condition)
        return GambitCondition.new(condition, GambitTarget.TargetType.Self)
    end)
end

return Skillchainer
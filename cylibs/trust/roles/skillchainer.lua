local Skillchainer = setmetatable({}, {__index = Role })
Skillchainer.__index = Skillchainer
Skillchainer.__class = "Skillchainer"

local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local renderer = require('cylibs/ui/views/render')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local SkillchainPropertyCondition = require('cylibs/conditions/skillchain_property')
local SkillchainTracker = require('cylibs/battle/skillchains/skillchain_tracker')
local skillchain_util = require('cylibs/util/skillchain_util')

state.AutoAftermathMode = M{['description'] = 'Auto Aftermath Mode', 'Off', 'Auto'}
state.AutoAftermathMode:set_description('Auto', "Okay, I'll try to keep aftermath on.")

state.AutoSkillchainMode = M{['description'] = 'Auto Skillchain Mode', 'Off', 'Auto', 'Cleave', 'Spam'}
state.AutoSkillchainMode:set_description('Auto', "Okay, I'll try to make skillchains.")
state.AutoSkillchainMode:set_description('Cleave', "Okay, I'll try to cleave monsters.")
state.AutoSkillchainMode:set_description('Spam', "Okay, I'll use the same weapon skill as soon as I get TP.")

state.SkillchainPropertyMode = M{['description'] = 'Skillchain Property Mode', 'Off', 'Light', 'Darkness'}
state.SkillchainPropertyMode:set_description('Off', "Okay, I'll try to make skillchains of all properties.")
state.SkillchainPropertyMode:set_description('Light', "Okay, I'll only make Light skillchains.")
state.SkillchainPropertyMode:set_description('Darkness', "Okay, I'll only make Darkness skillchains.")

state.SkillchainDelayMode = M{['description'] = 'Skillchain Delay Mode', 'Off', 'Maximum'}
state.SkillchainDelayMode:set_description('Maximum', "Okay, I'll wait until the end of the skillchain window to use my next weapon skill.")


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

function Skillchainer.new(action_queue, weapon_skill_settings)
    local self = setmetatable(Role.new(action_queue), Skillchainer)

    self.ability_for_step = L{}
    self.action_queue = action_queue
    self.action_identifier = self.__class..'_perform_skillchain'
    self.active_skills = L{}
    self.job_abilities = L{}
    self.skillchain_builder = SkillchainBuilder.new()
    self.last_check_skillchain_time = os.time() - 1
    self.ready_weaponskill = Event.newEvent()
    self.skillchain = Event.newEvent();
    self.skillchain_ended = Event.newEvent();
    self.skills_changed = Event.newEvent();
    self.dispose_bag = DisposeBag.new()

    self:set_weapon_skill_settings(weapon_skill_settings)

    return self
end

function Skillchainer:destroy()
    Role.destroy(self)

    self:on_ready_weaponskill():removeAllActions()
    self:on_skillchain():removeAllActions()
    self:on_skillchain_ended():removeAllActions()
    self:on_skills_changed():removeAllActions()

    self.dispose_bag:destroy()
end

function Skillchainer:on_add()
    Role.on_add(self)

    self:update_abilities()

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
            if target:get_mob().index == self.target_index then
                if L{ 'Cleave', 'Spam' }:contains(state.AutoSkillchainMode.value) then
                    self.skillchain_builder:set_current_step(nil)
                else
                    self.skillchain_builder:set_current_step(step)
                end
                self:show_next_skillchain_info()
                self:on_skillchain():trigger(mob_id, step)
            end
        end
    end)
    self.skillchain_tracker:on_skillchain_ended():addAction(function(mob_id)
        local target = self:get_party():get_target(mob_id)
        if target then
            target:set_skillchain(nil)
            if target:get_mob().index == self.target_index then
                local step = self.skillchain_tracker:get_current_step(mob_id)
                if step == nil then
                    self.is_performing_ability = false
                end
                if L{ 'Cleave', 'Spam' }:contains(state.AutoSkillchainMode.value) then
                    self.skillchain_builder:set_current_step(nil)
                else
                    self.skillchain_builder:set_current_step(step)
                end
                self:show_next_skillchain_info()
                self:on_skillchain_ended():trigger(mob_id)
            end
        end
    end)
    self.dispose_bag:addAny(L{ self.skillchain_tracker })

    self.dispose_bag:add(self:get_party():get_player():on_equipment_change():addAction(function(_)
        self:update_abilities()
    end), self:get_party():get_player():on_equipment_change())

    self.dispose_bag:add(renderer.shared():onPrerender():addAction(function()
        self:check_skillchain()
    end), renderer.shared():onPrerender())

    self.dispose_bag:add(state.AutoSkillchainMode:on_state_change():addAction(function(_, new_value)
        if L{ 'Cleave', 'Spam' }:contains(new_value) then
            self.skillchain_builder:set_current_step(nil)
        else
            local target = self:get_target()
            if target then
                self.skillchain_builder:set_current_step(self.skillchain_tracker:get_current_step(target.id))
            end
        end
    end), state.AutoSkillchainMode:on_state_change())

    self.dispose_bag:add(state.SkillchainPropertyMode:on_state_change():addAction(function(_, new_value)
        self.skillchain_builder:remove_all_conditions()

        if new_value == 'Light' then
            self.skillchain_builder:add_condition(SkillchainPropertyCondition.new(skillchain_util.LightSkillchains))
        elseif new_value == 'Darkness' then
            self.skillchain_builder:add_condition(SkillchainPropertyCondition.new(skillchain_util.DarknessSkillchains))
        end
    end), state.SkillchainPropertyMode:on_state_change())
end

function Skillchainer:check_skillchain()
    if state.AutoSkillchainMode.value == 'Off' or self.is_performing_ability or not self:get_player():is_engaged()
            or os.time() - self.last_check_skillchain_time < 1 then
        return
    end
    self.last_check_skillchain_time = os.time()

    local target = self:get_target()
    if target == nil then
        return
    end

    local next_ability

    local step = self.skillchain_builder:get_current_step()
    if step and not step:is_expired() then
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
    end
end

function Skillchainer:get_next_ability(current_step)
    local step_num = 1
    if current_step then
        step_num = current_step:get_step() + 1
    end
    local ability = self.ability_for_step[step_num]
    if ability and ability:get_name() ~= SkillchainAbility.Auto then
        if ability:get_name() == SkillchainAbility.Skip then
            return nil
        end
        if windower.ffxi.get_player().vitals.tp >= 1000 then
            return ability
        end
    else
        if current_step == nil then
            if windower.ffxi.get_player().vitals.tp >= 1000 then
                return self:get_starter_ability(self:get_num_steps())
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

function Skillchainer:get_num_steps()
    if state.AutoSkillchainMode.value == 'Auto' then
        return 3
    elseif state.AutoSkillchainMode.value == 'Spam' then
        return 2
    else
        return 1
    end
end

function Skillchainer:get_starter_ability(num_steps)
    if L{ 'Auto', 'Spam' }:contains(state.AutoSkillchainMode.value) then
        local default_skillchains = self:get_default_skillschains()
        for skillchain in default_skillchains:it() do
            local skillchains = self.skillchain_builder:build(skillchain:get_name(), num_steps)
            if skillchains and skillchains:length() > 0 then
                return skillchains[1][1]
            end
        end
        return self.active_skills:first():get_default_ability()
    else
        local abilities = self.skillchain_builder.abilities:filter(function(ability) return ability:is_aoe() end)
        if abilities:length() > 0 then
            return abilities[1]
        end
    end
    return nil
end

function Skillchainer:get_default_skillschains()
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
        return false
    end

    local ability_action = ability:to_action(target:get_mob().index, self:get_player())
    if ability_action then
        self.is_performing_ability = true

        ability_action.identifier = self.action_identifier
        ability_action.max_duration = 10
        ability_action.priority = ActionPriority.highest

        self.action_queue:push_action(ability_action, true)
    end
end

function Skillchainer:show_next_skillchain_info()
    if not self:get_player():is_engaged() then
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
    for skill in self.weapon_skill_settings.Skills:it() do
        if skill:is_valid(player) then
            abilities = abilities:extend(skill:get_abilities()):compact_map()
            self.active_skills:append(skill)
        end
    end
    self.skillchain_builder:set_abilities(abilities)

    self:on_skills_changed():trigger(self, self.active_skills)
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

function Skillchainer:set_job_abilities(job_abilities)
    self.job_abilities = (job_abilities or L{}):filter(function(job_ability) return job_util.knows_job_ability(job_ability:get_job_ability_id()) end)
end

function Skillchainer:set_weapon_skill_settings(weapon_skill_settings)
    self.weapon_skill_settings = weapon_skill_settings
    self.ability_for_step = weapon_skill_settings.Skillchain

    self:update_abilities()
end

return Skillchainer
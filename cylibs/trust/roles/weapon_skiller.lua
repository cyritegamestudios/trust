local DisposeBag = require('cylibs/events/dispose_bag')
local Renderer = require('cylibs/ui/views/render')


local WeaponSkiller = setmetatable({}, {__index = Role })
WeaponSkiller.__index = WeaponSkiller
WeaponSkiller.__class = "WeaponSkiller"


function WeaponSkiller.new(action_queue, weapon_skill_settings, mode_value)
    local self = setmetatable(Role.new(action_queue), WeaponSkiller)

    self.action_identifier = self.__class..'_perform_skillchain'
    self.active_skills = L{}
    self.job_abilities = L{}
    self.last_check_time = os.time()
    self.mode_value = mode_value
    self.weapon_skill_settings = weapon_skill_settings

    self:set_current_settings(weapon_skill_settings:getSettings().Default)

    self.dispose_bag = DisposeBag.new()

    return self
end

function WeaponSkiller:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function WeaponSkiller:allows_duplicates()
    return false
end

function WeaponSkiller:get_type()
    return nil
end

function WeaponSkiller:on_add()
    Role.on_add(self)

    self:update_abilities()

    self.dispose_bag:add(Renderer.shared():onPrerender():addAction(function()
        self:check_abilities()
    end), Renderer.shared():onPrerender())

    self.dispose_bag:add(state.WeaponSkillSettingsMode:on_state_change():addAction(function(_, new_value)
        self:set_current_settings(self.weapon_skill_settings:getSettings()[new_value])
    end), state.WeaponSkillSettingsMode:on_state_change())
end

function WeaponSkiller:check_abilities()
    if state.AutoSkillchainMode.value ~= self.mode_value or not self:get_player():is_engaged()
            or self:get_target() == nil or os.time() - self.last_check_time < 1 then
        return
    end
    self.last_check_time = os.time()

    local next_ability = self:get_next_ability()
    if next_ability then
        logger.notice(self.__class, 'check_abilities', 'perform', next_ability:get_name())
        self:perform_ability(next_ability)
    else
        logger.notice(self.__class, 'check_abilities', 'no ability to perform')
    end
end

-------
-- Returns the next ability to perform.
-- @treturn SkillchainAbility Ability to perform
function WeaponSkiller:get_next_ability()
    local ability = self.abilities:firstWhere(function(a)
        return Condition.check_conditions(a:get_conditions(), self:get_party():get_player():get_mob().index)
    end)
    if ability then
        return ability
    end
    return nil
end

-------
-- Performs an ability.
-- @tparam SkillchainAbility ability Ability to perform
function WeaponSkiller:perform_ability(ability)
    local target = self:get_target()
    if not target then
        logger.notice(self.__class, 'perform_ability', ability:get_name(), 'no valid target')
        return
    end

    local ability_action = ability:to_action(target:get_mob().index, self:get_player(), self.job_abilities)
    if ability_action then
        ability_action.identifier = self.action_identifier
        ability_action.max_duration = 10
        ability_action.priority = ActionPriority.highest

        logger.notice(self.__class, 'perform_ability', ability:get_name(), 'push_action')

        self.action_queue:push_action(ability_action, true)
    end
end

-------
-- Updates the list of valid abilities based on active combat skills.
function WeaponSkiller:update_abilities()
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
    self.abilities = abilities
end

function WeaponSkiller:set_current_settings(current_settings)
    self.current_settings = current_settings
    self.ability_for_step = current_settings.Skillchain

    self:update_abilities()
end

function WeaponSkiller:get_active_skills()
    return self.active_skills
end

function WeaponSkiller:set_job_abilities(job_abilities)
    self.job_abilities = (job_abilities or L{}):filter(function(job_ability) return job_util.knows_job_ability(job_ability:get_job_ability_id()) end)
end

return WeaponSkiller
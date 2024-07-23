local Nuker = setmetatable({}, {__index = Role })
Nuker.__index = Nuker

local DisposeBag = require('cylibs/events/dispose_bag')
local skillchain_util = require('cylibs/util/skillchain_util')
local spell_util = require('cylibs/util/spell_util')

state.AutoNukeMode = M{['description'] = 'Auto Nuke Mode', 'Off', 'Earth', 'Lightning', 'Water', 'Fire', 'Ice', 'Wind', 'Light', 'Dark', 'Cleave'}
state.AutoNukeMode:set_description('Earth', "Okay, I'll free nuke with earth spells.")
state.AutoNukeMode:set_description('Lightning', "Okay, I'll free nuke with lightning spells.")
state.AutoNukeMode:set_description('Water', "Okay, I'll free nuke with water spells.")
state.AutoNukeMode:set_description('Fire', "Okay, I'll free nuke with fire spells.")
state.AutoNukeMode:set_description('Ice', "Okay, I'll free nuke with ice spells.")
state.AutoNukeMode:set_description('Wind', "Okay, I'll free nuke with wind spells.")
state.AutoNukeMode:set_description('Light', "Okay, I'll free nuke with light spells.")
state.AutoNukeMode:set_description('Dark', "Okay, I'll free nuke with dark spells.")
state.AutoNukeMode:set_description('Cleave', "Okay, I'll try to cleave monsters with spells of any element.")

-------
-- Default initializer for a nuker role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam T nuke_settings Nuke settings (see data/JobNameShort.lua)
-- @tparam fast_cast number Fast cast modifier (0.0 - 1.0)
-- @tparam List job_ability_names List of job abilities to use with spells (e.g. Cascade, Ebullience)
-- @treturn Nuker A nuker role
function Nuker.new(action_queue, nuke_settings, fast_cast, job_ability_names, job)
    local self = setmetatable(Role.new(action_queue), Nuker)

    self.fast_cast = fast_cast or 0.8
    self.job_ability_names = job_ability_names or L{}
    self.job = job
    self.last_nuke_time = os.time()
    self.dispose_bag = DisposeBag.new()

    self:set_nuke_settings(nuke_settings)

    return self
end

function Nuker:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Nuker:on_add()
    Role.on_add(self)
end

function Nuker:target_change(target_index)
    Role.target_change(self, target_index)
end

function Nuker:tic(_, _)
    if L{'Off', 'Auto' }:contains(state.AutoNukeMode.value) or self.target_index == nil
            or (os.time() - self.last_nuke_time) < self.nuke_cooldown then
        return
    end
    if state.AutoNukeMode.value == 'Cleave' then
        self:check_cleave()
    else
        local target = self:get_target()
        if target and target:is_claimed() then
            self:check_nukes()
        end
    end
end

function Nuker:check_cleave()
    local targets = self:get_party():get_targets(function(t)
        return t:get_mob().distance:sqrt() < 12 and t:get_status() == 'Engaged'
    end)
    if targets:length() >= self.min_num_mobs_to_cleave then
        local spell = self:get_aoe_spell()
        if spell then
            self:cast_spell(spell:get_spell().en)
        end
    else
        self:get_party():add_to_chat(self:get_party():get_player(), "I'll start cleaving after we find "..self.min_num_mobs_to_cleave - targets:length().." more mob(s).", "nuker_cleave", 10)
    end
end

function Nuker:check_nukes()
    local element = Element.new(state.AutoNukeMode.value)

    local spell = self:get_spell(element)
    if spell then
        self:cast_spell(spell:get_spell().en)
    end
end

function Nuker:cast_spell(spell_name)
    local spell = Spell.new(spell_name, L{}, L{}, nil, L{ MinManaPointsPercentCondition.new(self.nuke_mpp, windower.ffxi.get_player().index) })
    if Condition.check_conditions(spell:get_conditions(), self.target_index) then
        self.last_nuke_time = os.time()

        spell:set_job_abilities(self.job_ability_names)

        local spell_action = spell:to_action(self.target_index, self:get_player())
        spell_action.priority = ActionPriority.high

        self.action_queue:push_action(spell_action, true)
    end
end

function Nuker:allows_duplicates()
    return false
end

function Nuker:get_type()
    return "nuker"
end

-------
-- Gets the highest tier spell of a given element.
-- @tparam Element element Element (e.g. Lightning, Fire, Water)
-- @treturn Spell Spell to nuke with with, or nil if there are none
function Nuker:get_spell(element)
    local spells = self.element_to_spells[element:get_name()]:filter(function(spell)
        if state.AutoNukeMode.value ~= 'Cleave' then
            return not self.job:get_aoe_spells():contains(spell:get_name())
        end
        return true
    end)
    for spell in spells:it() do
        local conditions = L{}:extend(spell:get_conditions()):extend(L{ MinManaPointsCondition.new(spell:get_spell().mp_cost, windower.ffxi.get_player().index) })
        if Condition.check_conditions(conditions, self.target_index) then
            return spell
        end
    end
    return nil
end

-------
-- Gets the highest tier spell of a given element.
-- @tparam Element element Element (e.g. Lightning, Fire, Water)
-- @treturn Spell Spell to nuke with with, or nil if there are none
function Nuker:get_aoe_spell()
    local aoe_spells = self.spells:filter(function(spell) return self.job:get_aoe_spells():contains(spell:get_name()) end)
    for spell in aoe_spells:it() do
        local conditions = L{}:extend(spell:get_conditions()):extend(L{ MinManaPointsCondition.new(spell:get_spell().mp_cost, windower.ffxi.get_player().index) })
        if Condition.check_conditions(conditions, self.target_index) then
            return spell
        end
    end
    return nil
end

function Nuker:set_spells(spells)
    self.element_to_spells = {
        Fire = L{},
        Ice = L{},
        Wind = L{},
        Earth = L{},
        Lightning = L{},
        Water = L{},
        Light = L{},
        Dark = L{}
    }
    self.spells = (spells or L{}):filter(function(spell) return spell ~= nil and spell_util.knows_spell(spell:get_spell().id) end)
    for spell in self.spells:it() do
        local element_name = res.elements[spell:get_spell().element].en
        self.element_to_spells[element_name]:append(spell)
    end
end

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function Nuker:set_nuke_settings(nuke_settings)
    self.nuke_settings = nuke_settings
    self.nuke_cooldown = nuke_settings.Delay or 2
    self.nuke_mpp = nuke_settings.MinManaPointsPercent or 20
    self.min_num_mobs_to_cleave = nuke_settings.MinNumMobsToCleave or 2
    self:set_spells(nuke_settings.Spells)
end

return Nuker
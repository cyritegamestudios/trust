local Role = require('cylibs/trust/roles/role')
local MagicBurster = setmetatable({}, {__index = Role })
MagicBurster.__index = MagicBurster
MagicBurster.__class = "MagicBurster"

local DisposeBag = require('cylibs/events/dispose_bag')
local Timer = require('cylibs/util/timers/timer')

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
-- @treturn Nuker A nuker role
function MagicBurster.new(action_queue, nuke_settings, fast_cast, default_job_ability_names, job)
    local self = setmetatable(Role.new(action_queue), MagicBurster)

    self.fast_cast = fast_cast or 0.8
    self.default_job_abilities = default_job_ability_names:map(function(job_ability_name) return JobAbility.new(job_ability_name) end) or L{}
    self.job = job
    self.last_magic_burst_time = os.time()
    self.action_identifier = self.__class..'_cast_spell'
    self.target_dispose_bag = DisposeBag.new()
    self.dispose_bag = DisposeBag.new()

    self:set_nuke_settings(nuke_settings)

    return self
end

function MagicBurster:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
    self.target_dispose_bag:destroy()
end

function MagicBurster:on_add()
    Role.on_add(self)

    self.dispose_bag:add(self.action_queue:on_action_end():addAction(function(a, success)
        if a:getidentifier() == self.action_identifier or not self.action_queue:has_action(self.action_identifier) then
            self.is_casting = false
            if not success then
                self.last_magic_burst_time = os.time() - self.magic_burst_cooldown
            end
        end
    end), self.action_queue:on_action_end())

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
                if self.job:knows_spell(spell.id) then
                    self:cast_spell(Spell.new(spell.name))
                else
                    local spell = self:get_spell(Element.new(res.elements[spell.element].en))
                    if spell then
                        self:cast_spell(Spell.new(spell:get_name()))
                    end
                end
            end
        end
    end), WindowerEvents.Spell.Begin)

    self.timer = Timer.scheduledTimer(0.25, 0)

    self.dispose_bag:add(self.timer:onTimeChange():addAction(function(_)
        local target = self:get_target()
        if target then
            local step = target:get_skillchain()
            if step and step:get_skillchain() and not step:is_expired() and step:get_time_remaining() > 1.5 then
                self:check_magic_burst(step:get_skillchain())
            end
        end
    end), self.timer:onTimeChange())
    self.dispose_bag:addAny(L{ self.timer })

    self.timer:start()
end

function MagicBurster:target_change(target_index)
    Role.target_change(self, target_index)

    self.is_casting = false

    self.target_dispose_bag:dispose()

    local target = self:get_target()
    if target then
        self.target_dispose_bag:add(target:on_skillchain():addAction(function(_, step)
            self:check_magic_burst(step:get_skillchain())
        end), target:on_skillchain())

        self.target_dispose_bag:add(target:on_skillchain_ended():addAction(function(_)
            self.is_casting = false
        end), target:on_skillchain_ended())
    end
end

-------
-- Performs a magic burst on the given skillchain if possible.
-- @tparam Skillchain skillchain Skillchain (e.g. Light, Fragmentation, Scission)
function MagicBurster:check_magic_burst(skillchain)
    if S{ 'Off', 'Mirror' }:contains(state.AutoMagicBurstMode.value) or (os.time() - self.last_magic_burst_time) < self.magic_burst_cooldown or self.is_casting then
        return
    end
    local elements = L(skillchain:get_elements():filter(function(element)
        if state.AutoMagicBurstMode.value ~= 'Auto' then
            return element:get_name() == state.AutoMagicBurstMode.value
        end
        return not self.element_blacklist:contains(element)
    end)):sort(function(element1, element2)
        return self:get_priority(element1) > self:get_priority(element2)
    end)

    for element in elements:it() do
        local spell = self:get_spell(element)
        if spell then
            self:cast_spell(spell)
            return
        end
    end
end

-------
-- Returns the priority of a given element when magic bursting.
-- @tparam Element element Element (e.g. Lightning, Fire, Water)
-- @treturn number Priority of the element (1...8)
function MagicBurster:get_priority(element)
    local element_priority = L{
        'Dark',
        'Lightning',
        'Ice',
        'Fire',
        'Wind',
        'Water',
        'Earth',
        'Light'
    }:reverse()
    return element_priority:indexOf(element:get_name())
end

function MagicBurster:cast_spell(spell)
    if not Condition.check_conditions(L{ MinManaPointsPercentCondition.new(self.magic_burst_mpp, windower.ffxi.get_player().index) }, self.target_index) then
        return
    end
    if Condition.check_conditions(spell:get_conditions(), self.target_index) then
        self.last_magic_burst_time = os.time()

        if self.gearswap_command and self.gearswap_command:length() > 0 then
            windower.send_command(self.gearswap_command)
        end

        local player = windower.ffxi.get_player()

        local job_abilities
        local job_ability = L{}:extend(self.job_abilities):firstWhere(function(job_ability)
            return job_util.can_use_job_ability(job_ability:get_job_ability_name()) and Condition.check_conditions(job_ability:get_conditions(), player.index)
        end)
        if job_ability then
            job_abilities = L{ job_ability:get_job_ability_name() }
        end

        local spell_action = spell:to_action(self.target_index, self:get_player(), job_abilities)
        spell_action.priority = ActionPriority.high
        spell_action.identifier = self.action_identifier

        self.is_casting = true

        self.action_queue:push_action(spell_action, true)
    end
end

-------
-- Gets the highest priority spell that can magic burst with the given element.
-- @tparam Element element Element (e.g. Lightning, Fire, Water)
-- @treturn Spell Spell to magic burst with, or nil if there are none
function MagicBurster:get_spell(element)
    local spells = self.element_to_spells[element:get_name()]:filter(function(spell)
        if state.MagicBurstTargetMode.value == 'Single' then
            return not self.job:get_aoe_spells():contains(spell:get_name())
        end
        return true
    end)
    for spell in spells:it() do
        local conditions = self.job:get_conditions_for_spell(spell) + L{ MinManaPointsCondition.new(spell:get_mp_cost(), windower.ffxi.get_player().index) }
        if Condition.check_conditions(conditions, self.target_index) then
            return spell
        end
    end
    return nil
end

function MagicBurster:set_spells(spells)
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
    self.spells = (spells or L{}):filter(function(spell)
        return spell ~= nil and spell:is_valid()
    end)
    for spell in self.spells:it() do
        local element_name = res.elements[spell:get_element()].en
        self.element_to_spells[element_name]:append(spell)
    end
end

-------
-- Sets the nuke settings.
-- @tparam T nuke_settings Nuke settings
function MagicBurster:set_nuke_settings(nuke_settings)
    self.nuke_settings = nuke_settings
    self.magic_burst_cooldown = nuke_settings.Delay or 2
    self.magic_burst_mpp = nuke_settings.MinManaPointsPercent or 20
    self.element_blacklist = nuke_settings.Blacklist or L{}
    self.job_abilities = nuke_settings.JobAbilities or self.default_job_ability_names or L{}
    self.gearswap_command = nuke_settings.GearswapCommand or 'gs c set MagicBurstMode Single'
    self:set_spells(nuke_settings.Spells)
end

function MagicBurster:allows_duplicates()
    return false
end

function MagicBurster:get_type()
    return "magicburster"
end

return MagicBurster
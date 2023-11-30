local Nuker = setmetatable({}, {__index = Role })
Nuker.__index = Nuker

local DisposeBag = require('cylibs/events/dispose_bag')
local MagicBurstMaker = require('cylibs/battle/skillchains/magic_burst_maker')
local Nukes = require('cylibs/res/nukes')

state.AutoMagicBurstMode = M{['description'] = 'Auto Magic Burst Mode', 'Off', 'Auto', 'Earth', 'Lightning', 'Water', 'Fire', 'Ice', 'Wind', 'Light', 'Dark'}
state.AutoMagicBurstMode:set_description('Auto', "Okay, if you make skillchains I'll try to magic burst.")
state.AutoMagicBurstMode:set_description('Earth', "Okay, I'll only magic burst with earth spells.")
state.AutoMagicBurstMode:set_description('Lightning', "Okay, I'll only magic burst with lightning spells.")
state.AutoMagicBurstMode:set_description('Water', "Okay, I'll only magic burst with water spells.")
state.AutoMagicBurstMode:set_description('Fire', "Okay, I'll only magic burst with fire spells.")
state.AutoMagicBurstMode:set_description('Ice', "Okay, I'll only magic burst with ice spells.")
state.AutoMagicBurstMode:set_description('Wind', "Okay, I'll only magic burst with wind spells.")
state.AutoMagicBurstMode:set_description('Light', "Okay, I'll only magic burst with light spells.")
state.AutoMagicBurstMode:set_description('Dark', "Okay, I'll only magic burst with dark spells.")

state.AutoNukeMode = M{['description'] = 'Auto Nuke Mode', 'Off', 'Earth', 'Lightning', 'Water', 'Fire', 'Ice', 'Wind', 'Light', 'Dark'}
state.AutoNukeMode:set_description('Earth', "Okay, I'll free nuke with earth spells.")
state.AutoNukeMode:set_description('Lightning', "Okay, I'll free nuke with lightning spells.")
state.AutoNukeMode:set_description('Water', "Okay, I'll free nuke with water spells.")
state.AutoNukeMode:set_description('Fire', "Okay, I'll free nuke with fire spells.")
state.AutoNukeMode:set_description('Ice', "Okay, I'll free nuke with ice spells.")
state.AutoNukeMode:set_description('Wind', "Okay, I'll free nuke with wind spells.")
state.AutoNukeMode:set_description('Light', "Okay, I'll free nuke with light spells.")
state.AutoNukeMode:set_description('Dark', "Okay, I'll free nuke with dark spells.")

-------
-- Default initializer for a nuker role.
-- @tparam ActionQueue action_queue Action queue
-- @tparam number nuke_cooldown Minimum time between nukes in seconds
-- @tparam number nuke_mpp Minimum mana percentage points to nuke
-- @tparam fast_cast number Fast cast modifier (0.0 - 1.0)
-- @tparam List job_ability_names List of job abilities to use with spells (e.g. Cascade, Ebullience)
-- @treturn Nuker A nuker role
function Nuker.new(action_queue, nuke_cooldown, nuke_mpp, fast_cast, job_ability_names)
    local self = setmetatable(Role.new(action_queue), Nuker)

    self.nuke_cooldown = nuke_cooldown or 2
    self.nuke_mpp = nuke_mpp or 20
    self.fast_cast = fast_cast or 0.8
    self.job_ability_names = job_ability_names or L{}
    self.last_nuke_time = os.time()
    self.dispose_bag = DisposeBag.new()

    return self
end

function Nuker:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Nuker:on_add()
    Role.on_add(self)

    self.magic_burst_maker = MagicBurstMaker.new(state.AutoMagicBurstMode)
    self.magic_burst_maker:start_monitoring()
    self.magic_burst_maker:on_perform_next_nuke():addAction(function(_, spell_name)
        if state.AutoMagicBurstMode.value ~= 'Off' then
            local spell = res.spells:with('name', spell_name)
            if spell then
                self:cast_spell(spell.name, true)
            end
        end
    end)
    self.magic_burst_maker:set_auto_nuke(state.AutoMagicBurstMode.value == 'Auto')

    self.dispose_bag:addAny(L{ self.magic_burst_maker })
end

function Nuker:target_change(target_index)
    Role.target_change(self, target_index)
end

function Nuker:tic(_, _)
    if L{'Off', 'Auto' }:contains(state.AutoNukeMode.value) or self.target_index == nil
            or (os.time() - self.last_nuke_time) < self.nuke_cooldown then
        return
    end
    self:check_nukes()
end

function Nuker:check_nukes()
    local spell_name = Nukes.get_nuke(state.AutoNukeMode.value)
    if spell_name then
        self:cast_spell(spell_name, false)
    end
end

function Nuker:cast_spell(spell_name, is_magic_burst)
    local spell = Spell.new(spell_name, L{}, L{}, nil, L{ MinManaPointsPercentCondition.new(self.nuke_mpp) })
    if Condition.check_conditions(spell:get_conditions(), self.target_index) then
        self.last_nuke_time = os.time()

        if is_magic_burst then
            windower.send_command('gs c set MagicBurstMode Single')
        end

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

return Nuker
local Nuker = setmetatable({}, {__index = Role })
Nuker.__index = Nuker

local MagicBurstMaker = require('cylibs/battle/skillchains/magic_burst_maker')
local Nukes = require('cylibs/res/nukes')

state.AutoMagicBurstMode = M{['description'] = 'Auto Magic Burst Mode', 'Off', 'Auto'}
state.AutoMagicBurstMode:set_description('Auto', "Okay, if you make skillchains I'll try to magic burst.")

state.AutoNukeMode = M{['description'] = 'Auto Nuke Mode', 'Off', 'Earth', 'Lightning', 'Water', 'Fire', 'Ice', 'Wind', 'Light', 'Dark'}
state.AutoNukeMode:set_description('Earth', "Okay, I'll free nuke with earth spells.")
state.AutoNukeMode:set_description('Lightning', "Okay, I'll free nuke with lightning spells.")
state.AutoNukeMode:set_description('Water', "Okay, I'll free nuke with water spells.")
state.AutoNukeMode:set_description('Fire', "Okay, I'll free nuke with fire spells.")
state.AutoNukeMode:set_description('Ice', "Okay, I'll free nuke with ice spells.")
state.AutoNukeMode:set_description('Wind', "Okay, I'll free nuke with wind spells.")
state.AutoNukeMode:set_description('Light', "Okay, I'll free nuke with light spells.")
state.AutoNukeMode:set_description('Dark', "Okay, I'll free nuke with dark spells.")

function Nuker.new(action_queue, nuke_cooldown, nuke_mpp, fast_cast)
    local self = setmetatable(Role.new(action_queue), Nuker)

    self.nuke_cooldown = nuke_cooldown or 2
    self.nuke_mpp = nuke_mpp or 20
    self.fast_cast = fast_cast or 0.8
    self.last_nuke_time = os.time()

    return self
end

function Nuker:destroy()
    Role.destroy(self)

    if self.magic_burst_maker then
        self.magic_burst_maker:destroy()
    end
end

function Nuker:on_add()
    Role.on_add(self)

    self.magic_burst_maker = MagicBurstMaker.new(state.AutoMagicBurstMode)
    self.magic_burst_maker:start_monitoring()
    self.magic_burst_maker:on_perform_next_nuke():addAction(function(_, spell_name)
        if state.AutoMagicBurstMode.value == 'Auto' then
            local spell = res.spells:with('name', spell_name)
            if spell then
                self:cast_spell(spell, true)
            end
        end
    end)
    self.magic_burst_maker:set_auto_nuke(state.AutoMagicBurstMode.value == 'Auto')
end

function Nuker:target_change(target_index)
    Role.target_change(self, target_index)
end

function Nuker:tic(_, _)
    if state.AutoNukeMode.value == 'Off' or self.target_index == nil then
        return
    end
    self:check_nukes()
end

function Nuker:check_nukes()
    local spell_name = Nukes.get_nuke(state.AutoNukeMode.value)
    if spell_name then
        self:cast_spell(res.spells:with('en', spell_name), false)
    end
end

function Nuker:cast_spell(spell, is_magic_burst)
    if windower.ffxi.get_player().vitals.mpp < self.nuke_mpp
            or (os.time() - self.last_nuke_time) < self.nuke_cooldown or not spell_util.can_cast_spell(spell.id) then
        return
    end

    self.last_nuke_time = os.time()

    if is_magic_burst then
        windower.send_command('gs c set MagicBurstMode Single')
    end

    self.nuke_cooldown = spell.cast_time * (1 - self.fast_cast) + 3.275

    local spell_action = SpellAction.new(0, 0, 0, spell.id, self.target_index, self:get_player())
    spell_action.priority = ActionPriority.high

    self.action_queue:push_action(spell_action, true)
end

function Nuker:allows_duplicates()
    return false
end

function Nuker:get_type()
    return "nuker"
end

return Nuker
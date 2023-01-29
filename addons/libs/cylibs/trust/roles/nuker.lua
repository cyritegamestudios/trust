local Nuker = setmetatable({}, {__index = Role })
Nuker.__index = Nuker

local MagicBurstMaker = require('cylibs/battle/skillchains/magic_burst_maker')

state.AutoMagicBurstMode = M{['description'] = 'Auto Magic Burst Mode', 'Off', 'Auto'}

function Nuker.new(action_queue, magic_burst_cooldown, magic_burst_mpp, fast_cast)
    local self = setmetatable(Role.new(action_queue), Nuker)

    self.magic_burst_cooldown = magic_burst_cooldown or 2
    self.magic_burst_mpp = magic_burst_mpp or 20
    self.fast_cast = fast_cast or 0.8
    self.last_magic_burst_time = os.time()

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
        local spell = res.spells:with('name', spell_name)
        if spell then
            self:job_magic_burst(spell)
        end
    end)
    self.magic_burst_maker:set_auto_nuke(state.AutoMagicBurstMode.value == 'Auto')
end

function Nuker:target_change(target_index)
    Role.target_change(self, target_index)
end

function Nuker:job_magic_burst(spell)
    if state.AutoMagicBurstMode.value == 'Off' or windower.ffxi.get_player().vitals.mpp < self.magic_burst_mpp
            or (os.time() - self.last_magic_burst_time) < self.magic_burst_cooldown or not spell_util.can_cast_spell(spell.id) then
        return
    end

    self.last_magic_burst_time = os.time()

    windower.send_command('gs c set MagicBurstMode Single')

    self.magic_burst_cooldown = spell.cast_time * (1 - self.fast_cast) + 3.275

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
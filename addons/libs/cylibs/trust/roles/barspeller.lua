local DamageMemory = require('cylibs/battle/damage_memory')

local Barspeller = setmetatable({}, {__index = Role })
Barspeller.__index = Barspeller

state.AutoBarSpellMode = M{['description'] = 'Auto Barspell Mode', 'Manual', 'Off'}
state.AutoBarSpellMode:set_description('Manual', "Okay, I'll make sure to remember the last barspell you tell me to cast.")
--state.AutoBarSpellMode:set_description('Auto', "Okay, I'll try to figure out which barspell to cast on my own.")

-------
-- Default initializer for a barspeller.
-- @tparam ActionQueue action_queue Shared action queue
-- @tparam Job main_job Main job
-- @treturn Barspeller A barspeller
function Barspeller.new(action_queue, main_job)
    local self = setmetatable(Role.new(action_queue), Barspeller)

    self.action_events = {}
    self.main_job = main_job
    self.last_barspell_time = os.time()
    self.last_barspell_id = nil
    self.last_barstatus_id = nil
    self.barspell_delay = 10
    self.damage_memory = DamageMemory.new(0)
    self.damage_memory:monitor()

    return self
end

function Barspeller:destroy()
    self.is_disposed = true
    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    if self.spell_finish_id then
        self.player:on_spell_finish():removeAction(self.spell_finish_id)
    end

    self.damage_memory:destroy()
end

function Barspeller:on_add()
    self.spell_finish_id = self:get_player():on_spell_finish():addAction(
            function(p, spell_id, _)
                if p:get_mob().id == windower.ffxi.get_player().id then
                    if spell_util.is_barelement(spell_id) then
                        self.last_barspell_id = spell_id
                    elseif spell_util.is_barstatus(spell_id) then
                        self.last_barstatus_id = spell_id
                    end
                end
            end)
end

function Barspeller:target_change(target_index)
    Role.target_change(self, target_index)

    self.damage_memory:reset()
    self.damage_memory:target_change(target_index)
end

function Barspeller:tic(old_time, new_time)
    if state.AutoBarSpellMode.value == 'Off'
            or (os.time() - self.last_barspell_time) < self.barspell_delay
            or self:get_party() == nil then
        return
    end
    self.last_barspell_time = os.time()

    self:check_barelement()
    self:check_barstatus()
end

-------
-- Checks to see if a barelement spell should be cast.
function Barspeller:check_barelement()
    if state.AutoBarSpellMode.value == 'Manual' then
        local barspell = self:get_last_barelement()
        if barspell then
            local player_buff_ids = L(windower.ffxi.get_player().buffs)
            local buff = buff_util.buff_for_spell(barspell.id)
            if buff and not buff_util.is_buff_active(buff.id, player_buff_ids) and not buff_util.conflicts_with_buffs(buff.id, player_buff_ids)
                    and spell_util.can_cast_spell(barspell.id) then
                self:cast_spell(barspell.id)
            end
        end
    end
end

-------
-- Checks to see if a barstatus spell should be cast.
function Barspeller:check_barstatus()
    if state.AutoBarSpellMode.value == 'Manual' then
        local barspell = self:get_last_barstatus()
        if barspell then
            local player_buff_ids = L(windower.ffxi.get_player().buffs)
            local buff = buff_util.buff_for_spell(barspell.id)
            if buff and not buff_util.is_buff_active(buff.id, player_buff_ids) and not buff_util.conflicts_with_buffs(buff.id, player_buff_ids)
                    and spell_util.can_cast_spell(barspell.id) then
                self:cast_spell(barspell.id)
            end
        end
    end
end

function Barspeller:cast_spell(spell_id)
    self.last_barspell_time = os.time()

    local actions = L{
        SpellAction.new(0, 0, 0, spell_id, windower.ffxi.get_player().index, self:get_player()),
        WaitAction.new(0, 0, 0, 2)
    }

    self.action_queue:push_action(SequenceAction.new(actions, 'barspeller_'..spell_id), true)
end

function Barspeller:get_last_barelement()
    if self.last_barspell_id then
        return res.spells[self.last_barspell_id]
    end
    return nil
end

function Barspeller:get_last_barstatus()
    if self.last_barstatus_id then
        return res.spells[self.last_barstatus_id]
    end
    return nil
end

function Barspeller:allows_duplicates()
    return false
end

function Barspeller:get_type()
    return "barspeller"
end

return Barspeller
local spell_util = require('cylibs/util/spell_util')

local Truster = setmetatable({}, {__index = Role })
Truster.__index = Truster

state.AutoTrustsMode = M{['description'] = 'Auto Trusts Mode', 'Off', 'Auto'}
state.AutoTrustsMode:set_description('Auto', "Okay, I'll automatically summon trusts before battle.")

function Truster.new(action_queue, trusts)
    local self = setmetatable(Role.new(action_queue), Truster)

    self.action_events = {}
    self.trusts = (trusts or L{}):filter(function(trust_name) return spell_util.knows_spell(spell_util.spell_id(trust_name)) end)
    self.last_trust_time = os.time() - 10

    return self
end

function Truster:destroy()
    Role.destroy(self)

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end
end

function Truster:on_add()
    Role.on_add(self)
end

function Truster:target_change(target_index)
    Role.target_change(self, target_index)

    if target_index == nil then
        self:check_trusts()
    end
end

function Truster:tic(new_time, old_time)
    Role.tic(new_time, old_time)

    if state.AutoTrustsMode.value == 'Off' or os.time() - self.last_trust_time < 15 then
        return
    end
    self.last_trust_time = os.time()

    self:check_trusts()
end

-------
-- Summons trusts if there are fewer than 6 players in the party.
function Truster:check_trusts()
    if state.AutoTrustsMode.value == 'Off' or self:get_party():num_party_members() == 6
             or player.status ~= 'Idle' or not party_util.is_party_leader(windower.ffxi.get_player().id) then
        return
    end

    local trust_names = self.trusts:copy():filter(function(trust_name) return self:get_party():get_party_member_named(trust_name) == nil and spell_util.can_cast_spell(spell_util.spell_id(trust_name)) end)
    trust_names = trust_names:slice(1, math.min(6 - self:get_party():num_party_members(), trust_names:length()))

    for trust_name in trust_names:it() do
        self:call_trust(trust_name)
    end
end

function Truster:call_trust(trust_name)
    local trust_spell = res.spells:with('name', trust_name)
    if trust_spell then
        local actions = L{}

        actions:append(WaitAction.new(0, 0, 0, 5))
        actions:append(SpellAction.new(0, 0, 0, trust_spell.id, nil, self:get_player()))

        local trust_action = SequenceAction.new(actions, 'truster_call_trust_'..trust_name)
        trust_action.priority = ActionPriority.highest
        trust_action.max_duration = 20

        self.action_queue:push_action(trust_action, true)
    end
end

function Truster:allows_duplicates()
    return false
end

function Truster:get_type()
    return "truster"
end

return Truster
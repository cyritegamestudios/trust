local spell_util = require('cylibs/util/spell_util')
local trusts = require('cylibs/res/trusts')

local Truster = setmetatable({}, {__index = Role })
Truster.__index = Truster
Truster.__class = "Truster"

state.AutoTrustsMode = M{['description'] = 'Auto Trusts Mode', 'Off', 'Auto'}
state.AutoTrustsMode:set_description('Auto', "Okay, I'll automatically summon trusts before battle.")

function Truster.new(action_queue, trusts)
    local self = setmetatable(Role.new(action_queue), Truster)

    self.action_events = {}
    self.last_trust_time = os.time() - 10

    self:set_trusts(trusts)

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

function Truster:get_valid_trusts()
    local party_member_names = self:get_party():get_party_members():map(function(p) return p:get_name() end)

    logger.notice(self.__class, 'get_valid_trusts', 'party_member_names', party_member_names)

    local trust_names = self.trusts:copy():filter(function(trust_name)
        local sanitized_name = trust_name
        if trusts:with('enl', trust_name) then
            sanitized_name = trusts:with('enl', trust_name).en
        end
        return not party_member_names:contains(sanitized_name) and not party_member_names:contains(trust_name)
                and spell_util.can_cast_spell(spell_util.spell_id(trust_name))
    end)
    trust_names = trust_names:slice(1, math.min(6 - self:get_party():num_party_members(), trust_names:length()))

    return trust_names
end

-------
-- Summons trusts if there are fewer than 6 players in the party.
function Truster:check_trusts()
    if state.AutoTrustsMode.value == 'Off' or self:get_party():num_party_members() == 6
             or player.status ~= 'Idle' or not party_util.is_party_leader(windower.ffxi.get_player().id) then
        return
    end

    local trust_names = self:get_valid_trusts()

    logger.notice(self.__class, 'check_trusts', trust_names)

    for trust_name in trust_names:it() do
        self:call_trust(trust_name)
    end
end

function Truster:call_trust(trust_name)
    local trust_spell = res.spells:with('en', trust_name)
    if trust_spell then
        logger.notice(self.__class, 'call_trust', trust_name)

        local actions = L{}

        actions:append(WaitAction.new(0, 0, 0, 5))
        actions:append(SpellAction.new(0, 0, 0, trust_spell.id, nil, self:get_player()))

        local trust_action = SequenceAction.new(actions, 'truster_call_trust')
        trust_action.priority = ActionPriority.highest
        trust_action.max_duration = 20

        self.action_queue:push_action(trust_action, true)
    end
end

function Truster:set_trusts(trusts)
    local missing_trusts = L{}
    for trust_name in trusts:it() do
        if not spell_util.knows_spell(spell_util.spell_id(trust_name)) then
            missing_trusts:append(trust_name)
        end
    end
    if missing_trusts:length() > 0 then
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."I can't summon the following Alter Egos, which may affect my ability to pull: "..missing_trusts:tostring())
    end

    self.trusts = trusts:filter(function(trust_name) return spell_util.knows_spell(spell_util.spell_id(trust_name)) end)
end

function Truster:get_trusts()
    return self.trusts
end

function Truster:allows_duplicates()
    return false
end

function Truster:get_type()
    return "truster"
end

return Truster
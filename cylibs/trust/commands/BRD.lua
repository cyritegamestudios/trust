local TrustCommands = require('cylibs/trust/commands/trust_commands')
local BardTrustCommands = setmetatable({}, {__index = TrustCommands })
BardTrustCommands.__index = BardTrustCommands

function BardTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), BardTrustCommands)
    self.trust = trust
    self.action_queue = action_queue
    return self
end

function BardTrustCommands:handle_command(...)
    local cmd = arg[1]
    if cmd then
        if cmd == 'dummy' then
            self:sing_dummy_songs()
        elseif cmd == 'sing' then
            self:sing_songs()
        elseif cmd == 'ballad' then
            self:ballad()
        elseif cmd == 'status' then
            if arg[2] then
                self:get_songs(arg[2])
            end
        end
    end
end

function BardTrustCommands:sing_dummy_songs()
    local actions = L{}

    for spell in self.trust:get_trust_settings().DummySongs:slice(1, self.trust:get_job():get_max_num_songs()):it() do
        actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, nil, self.trust:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 2))
    end

    local song_action = SequenceAction.new(actions, 'command_singDummySongs')
    song_action.priority = ActionPriority.highest

    self.action_queue:push_action(song_action, true)
end

function BardTrustCommands:sing_songs()
    local actions = L{}

    for spell in self.trust:get_trust_settings().Songs:slice(1, self.trust:get_job():get_max_num_songs()):it() do
        actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, nil, self.trust:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 2))
    end

    local song_action = SequenceAction.new(actions, 'command_singSelfSongs')
    song_action.priority = ActionPriority.highest

    self.action_queue:push_action(song_action, true)
end

function BardTrustCommands:ballad()
    local actions = L{
        SpellAction.new(0, 0, 0, spell_util.spell_id("Mage's Ballad III"), nil, self.trust:get_player()),
        WaitAction.new(0, 0, 0, 2),
        SpellAction.new(0, 0, 0, spell_util.spell_id("Mage's Ballad II"), nil, self.trust:get_player()),
        WaitAction.new(0, 0, 0, 2),
    }

    local song_action = SequenceAction.new(actions, 'command_ballad')
    song_action.priority = ActionPriority.highest

    self.action_queue:push_action(song_action, true)
end

function BardTrustCommands:get_songs(target_name)
    local target = windower.ffxi.get_mob_by_name(target_name)
    if target then
        local singer = self.trust:role_with_type("singer")
        local songs = singer.song_tracker:get_songs(target.id):map(function(song_record) return res.spells[song_record:get_song_id()].name end)
        addon_message(207, "Songs for "..target.name.." are "..tostring(songs))
    end
end

return BardTrustCommands
local TrustCommands = require('cylibs/trust/commands/trust_commands')
local BardTrustCommands = setmetatable({}, {__index = TrustCommands })
BardTrustCommands.__index = BardTrustCommands
BardTrustCommands.__class = "BardTrustCommands"

function BardTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), BardTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('target', self.handle_set_song_target, 'Sets the song target, // trust brd song_target party_member_name')
    self:add_command('sing', self.handle_sing, 'Sings songs, optionally with nitro, // trust brd sing use_nitro')
    self:add_command('clear', self.handle_clear_songs, 'Clears the list of tracked songs')

    return self
end

function BardTrustCommands:get_command_name()
    return 'brd'
end

function BardTrustCommands:get_job()
    return self.trust:get_job()
end

function BardTrustCommands:handle_set_song_target(_, party_member_name)
    local success
    local message

    party_member_name = party_member_name or windower.ffxi.get_player().name

    local party_member = self.trust:get_party():get_party_member_named(party_member_name)
    if party_member then
        local singer = self.trust:role_with_type("singer")
        singer:set_song_target(party_member)

        success = true
        message = party_member_name.." will now be used as the target for re-singing songs."
    else
        success = false
        message = "Invalid party member "..(party_member_name or 'nil')
    end
    return success, message
end

function BardTrustCommands:handle_presing()
    local success
    local message

    local singer = self.trust:role_with_type("healer")
    singer.song_tracker:reset()

    success = true
    message = "Song tracker has been cleared"

    return success, message
end

function BardTrustCommands:handle_sing(use_nitro)
    local success
    local message

    local singer = self.trust:role_with_type("singer")
    local song_target = self.trust:get_party():get_player()

    local dummy_songs = singer:get_dummy_songs()
    local songs = singer:get_merged_songs(song_target)

    local merged_songs = L{
        songs[1],
        songs[2],
        dummy_songs[1],
        dummy_songs[2],
        songs[3],
        songs[4]
    }

    local actions = L{}
    if use_nitro and self.trust:get_job():is_nitro_ready() then
        actions:append(JobAbilityAction.new(0, 0, 0, 'Nightingale'))
        actions:append(WaitAction.new(0, 0, 0, 1.5))
        actions:append(JobAbilityAction.new(0, 0, 0, 'Troubadour'))
        actions:append(WaitAction.new(0, 0, 0, 1.5))
    end

    for song in merged_songs:it() do
        actions:append(SpellAction.new(0, 0, 0, song:get_spell().id, song_target.index, self.trust:get_player()))
        actions:append(WaitAction.new(0, 0, 0, 2))
    end

    local sing_action = SequenceAction.new(actions, self.__class..'_handle_sing', false)
    sing_action.priority = ActionPriority.highest
    sing_action.max_duration = 5 * merged_songs:length()

    self.action_queue:clear()
    self.action_queue:push_action(sing_action, true)

    success = true

    self.trust:get_party():add_to_chat(song_target, "Singing songs, hold tight.", nil, nil, true)

    return success, message
end

function BardTrustCommands:handle_clear_songs()
    local success
    local message

    local singer = self.trust:role_with_type("healer")
    singer.song_tracker:reset()

    success = true
    message = "Song tracker has been cleared"

    return success, message
end

return BardTrustCommands
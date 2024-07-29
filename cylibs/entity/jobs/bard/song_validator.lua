---------------------------
-- Wrapper around a song record.
-- @class module
-- @name SongValidator

local DisposeBag = require('cylibs/events/dispose_bag')

local SongValidator = {}
SongValidator.__index = SongValidator
SongValidator.__eq = SongValidator.equals
SongValidator.__class = "SongValidator"

-------
-- Default initializer for a new song record.
-- @tparam number song_id Song id (see spells.lua)
-- @tparam number song_duration Song duration in seconds
-- @treturn SongRecord A song record
function SongValidator.new(singer, action_queue)
    local self = setmetatable({
        singer = singer;
        action_queue = action_queue;
        current_actions = L{};
        current_action_identifiers = S{};
        dispose_bag = DisposeBag.new()
    }, SongValidator)

    self.dispose_bag:add(self.action_queue:on_action_end():addAction(function(action, success)
        if not self.current_action_identifiers:contains(action:getidentifier()) then
            return
        end

        if self.current_actions:length() > 0 then
            local next_action = self.current_actions:remove(1)

            if not Condition.check_conditions(next_action.conditions, windower.ffxi.get_player().index) then
                local song_id = next_action:getspellid()
                self.singer:get_party():add_to_chat(self.singer:get_party():get_player(), "Hmm...something went wrong before I was supposed to sing "..res.spells[song_id].en..". Check my GearSwap and song durations.")

                self.current_actions = L{}
                self.current_action_identifiers = S{}
                self.singer.song_tracker.diagnostics_enabled = false
            else
                self.action_queue:push_action(SequenceAction.new(L{ next_action, WaitAction.new(0, 0, 0, 2) }, next_action:getidentifier()), true)
            end
        else
            self.singer:get_party():add_to_chat(self.singer:get_party():get_player(), "Done! Looks like everything is working as expected!")

            self.current_actions = L{}
            self.current_action_identifiers = S{}
            self.singer.song_tracker.diagnostics_enabled = false
        end
    end), self.action_queue:on_action_end())

    return self
end

function SongValidator:destroy()
    self.dispose_bag:destroy()
end

-------
-- Returns whether a song is expired.
-- @treturn Boolean True if the song is expired
function SongValidator:validate()
    if addon_enabled:getValue() == false or self.current_actions:length() > 0 then
        return
    end

    local song_buff_ids = self.singer.brd_job:get_song_buff_ids(L(windower.ffxi.get_player().buffs))
    if song_buff_ids:length() > 0 then
        self.singer:get_party():add_to_chat(self.singer:get_party():get_player(), "I can't run diagnostics if I have any songs active. Get rid of my songs and try again.")
        return
    end

    self.singer.song_tracker.diagnostics_enabled = true

    local song_target = self.singer:get_party():get_player()
    local player = self.singer:get_player()

    local dummy_songs = self.singer:get_dummy_songs()
    local songs = self.singer:get_merged_songs(song_target)

    local song1 = SpellAction.new(0, 0, 0, songs[1]:get_spell().id, song_target.index, player)

    local song2 = SpellAction.new(0, 0, 0, songs[2]:get_spell().id, song_target.index, player)
    song2.conditions:append(HasBuffsCondition.new(L{
        buff_util.buff_for_spell(songs[1]:get_spell().id).en
    }))

    local dummy_song1 = SpellAction.new(0, 0, 0, dummy_songs[1]:get_spell().id, song_target.index, player)
    dummy_song1.conditions:append(HasBuffsCondition.new(L{
        buff_util.buff_for_spell(songs[1]:get_spell().id).en,
        buff_util.buff_for_spell(songs[2]:get_spell().id).en
    }))

    local dummy_song2 = SpellAction.new(0, 0, 0, dummy_songs[2]:get_spell().id, song_target.index, player)
    dummy_song2.conditions:append(HasBuffsCondition.new(L{
        buff_util.buff_for_spell(songs[1]:get_spell().id).en,
        buff_util.buff_for_spell(songs[2]:get_spell().id).en,
        buff_util.buff_for_spell(dummy_songs[1]:get_spell().id).en
    }))

    local song3 = SpellAction.new(0, 0, 0, songs[3]:get_spell().id, song_target.index, player)
    song3.conditions:append(HasBuffsCondition.new(L{
        buff_util.buff_for_spell(songs[1]:get_spell().id).en,
        buff_util.buff_for_spell(songs[2]:get_spell().id).en,
        buff_util.buff_for_spell(dummy_songs[1]:get_spell().id).en,
        buff_util.buff_for_spell(dummy_songs[2]:get_spell().id).en
    }))

    local song4 = SpellAction.new(0, 0, 0, songs[4]:get_spell().id, song_target.index, player)
    song4.conditions:append(HasBuffsCondition.new(L{
        buff_util.buff_for_spell(songs[1]:get_spell().id).en,
        buff_util.buff_for_spell(songs[2]:get_spell().id).en,
        buff_util.buff_for_spell(songs[3]:get_spell().id).en,
        buff_util.buff_for_spell(dummy_songs[2]:get_spell().id).en
    }))

    self.current_actions = L{
        song1,
        song2,
        dummy_song1,
        dummy_song2,
        song3,
        song4
    }
    self.current_action_identifiers = S(self.current_actions:map(function(a) return a:getidentifier() end))

    self.singer:get_party():add_to_chat(self.singer:get_party():get_player(), "Alright, let me do a dress rehearsal to ensure everything is working alright!")

    local next_action = self.current_actions:remove(1)
    self.action_queue:push_action(SequenceAction.new(L{ next_action, WaitAction.new(0, 0, 0, 2) }, next_action:getidentifier()), true)
end

-------
-- Returns the expiration time.
-- @treturn number Expiration time
function SongValidator:get_expire_time()
    return self.expire_time
end

return SongValidator
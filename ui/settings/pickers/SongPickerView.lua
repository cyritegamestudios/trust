local Buff = require('cylibs/battle/spells/buff')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local PickerView = require('cylibs/ui/picker/picker_view')
local Spell = require('cylibs/battle/spell')
local spell_util = require('cylibs/util/spell_util')


local SongPickerView = setmetatable({}, {__index = PickerView })
SongPickerView.__index = SongPickerView

function SongPickerView.new(trustSettings, songSettings, allSongs, validateSongs)
    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(PickerView.withItems(allSongs, songSettings:map(function(song) return song:get_spell().name end), true, cursorImageItem), SongPickerView)

    self.trustSettings = trustSettings
    self.songSettings = songSettings
    self.validateSongs = validateSongs

    return self
end

function SongPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local selectedIndexPaths = self:getDelegate():getSelectedIndexPaths()
        if selectedIndexPaths:length() > 0 then
            local selectedSongNames = selectedIndexPaths:map(function(indexPath) return self:getDataSource():itemAtIndexPath(indexPath):getText() end)

            local errorMessage = self.validateSongs(selectedSongNames)
            if errorMessage then
                addon_message(260, '('..windower.ffxi.get_player().name..') '..errorMessage)
                return
            end

            local newSongs = selectedSongNames:map(function(songName)
                if songName == 'Honor March' then
                    return Spell.new(songName, L{ 'Marcato' })
                else
                    return Spell.new(songName)
                end
            end)

            self.songSettings:clear()
            for song in newSongs:it() do
                self.songSettings:append(song)
            end

            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my songs!")
        end
    end
end

return SongPickerView
local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')

local EditSongSettingsMenuItem = setmetatable({}, {__index = MenuItem })
EditSongSettingsMenuItem.__index = EditSongSettingsMenuItem

function EditSongSettingsMenuItem.new(trustSettings, trustSettingsMode, songSettingsKey, title, description, settingsValidator, songFromSongName)
    settingsValidator = settingsValidator or function(_)
        return true, nil
    end
    songFromSongName = songFromSongName or function(songName)
        return Spell.new(songName)
    end

    local imageItemForText = function(text)
        return AssetManager.imageItemForSpell(text)
    end

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm'),
        ButtonItem.default('Add'),
        ButtonItem.default('Remove'),
        ButtonItem.default('Jobs'),
    }, {}, nil, title, description), EditSongSettingsMenuItem)

    self.contentViewConstructor = function(_, infoView)
        local songs = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings[songSettingsKey]

        local songPickerView = FFXIPickerView.withItems(songs:map(function(song) return song:get_spell().en end), L{}, false, nil, imageItemForText)

        songPickerView:setShouldRequestFocus(true)
        songPickerView:setAllowsCursorSelection(true)

        self.dispose_bag:add(songPickerView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedSongIndex = indexPath.row
            local song = songs[self.selectedSongIndex]
            if song then
                if song:get_job_names():length() > 0 then
                    infoView:setDescription("Use when: Ally job is "..localization_util.commas(song:get_job_names(), "or"))
                else
                    infoView:setDescription("Use when: Never (no jobs selected)")
                end
            end
        end), songPickerView:getDelegate():didSelectItemAtIndexPath())

        if songPickerView:getDataSource():numberOfItemsInSection(1) > 0 then
            songPickerView:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
        end

        return songPickerView
    end

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.songSettingsKey = songSettingsKey
    self.title = title
    self.description = description
    self.settingsValidator = settingsValidator
    self.songFromSongName = songFromSongName
    self.songSettings = T(trustSettings:getSettings())[trustSettingsMode.value].SongSettings
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function EditSongSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function EditSongSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddSongMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveSongMenuItem())
    self:setChildMenuItem("Jobs", self:getEditJobsMenuItem())
end

function EditSongSettingsMenuItem:getAddSongMenuItem()
    local addSongMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
    }, {}, function(_, _)
        local allSongs = spell_util.get_spells(function(spell)
            return spell.type == 'BardSong' and S{'Self'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spell) return spell.en end)

        local chooseSongsView = FFXIPickerView.withItems(allSongs, L{}, true, nil, imageItemForText)

        chooseSongsView:setTitle("Choose pianissimo songs.")
        chooseSongsView:setShouldRequestFocus(true)

        self.dispose_bag:add(chooseSongsView:on_pick_items():addAction(function(_, selectedItems)
            if selectedItems:length() > 0 then
                local newSongs = selectedItems:map(function(item)
                    return self.songFromSongName(item:getText())
                end):compact_map()

                local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings[self.songSettingsKey]

                local is_valid, error = self.settingsValidator(L{}:extend(newSongs):extend(songs))
                if not is_valid then
                    addon_system_error(error)
                    return
                end

                songs = songs:extend(newSongs)

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my songs!")
            end
        end), chooseSongsView:on_pick_items())

        return chooseSongsView
    end, self.title, "Add a new song.")
    return addSongMenuItem
end

function EditSongSettingsMenuItem:getRemoveSongMenuItem()
    return MenuItem.action(function(menu)
        if self.selectedSongIndex then
            local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings[self.songSettingsKey]
            songs:remove(self.selectedSongIndex)

            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my songs!")

            self.selectedSongIndex = nil

            menu:showMenu(self)
        end
    end)
end

function EditSongSettingsMenuItem:getEditJobsMenuItem()
    local editJobsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(_, _)
        local songs = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings[self.songSettingsKey]

        local jobsPickerView = FFXIPickerView.withItems(job_util.all_jobs(), songs[self.selectedSongIndex]:get_job_names(), true)

        self.dispose_bag:add(jobsPickerView:on_pick_items():addAction(function(_, selectedItems)
            if selectedItems:length() > 0 then
                local newJobNames = selectedItems:map(function(item)
                    return item:getText()
                end):compact_map()

                local song = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].SongSettings[self.songSettingsKey][self.selectedSongIndex]

                local jobNames = song:get_job_names()
                jobNames:clear()

                for jobName in newJobNames:it() do
                    jobNames:append(jobName)
                end

                self.trustSettings:saveSettings(true)
                addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll only keep this song on these jobs!")
            end
        end), jobsPickerView:on_pick_items())

        return jobsPickerView
    end, self.title, "Choose jobs to sing this song on.")
    return editJobsMenuItem
end

return EditSongSettingsMenuItem
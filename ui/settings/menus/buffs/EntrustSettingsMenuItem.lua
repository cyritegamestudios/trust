local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local localization_util = require('cylibs/util/localization_util')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local EntrustSettingsMenuItem = setmetatable({}, {__index = MenuItem })
EntrustSettingsMenuItem.__index = EntrustSettingsMenuItem

function EntrustSettingsMenuItem.new(trust, trustSettings, trustSettingsMode)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, {}, nil, "Entrust", "Choose an indicolure to entrust on party members."), EntrustSettingsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView, showMenu)
        local allSettings = T(trustSettings:getSettings())[trustSettingsMode.value].Geomancy

        local allSpells = self.trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            return spell and spell.skill == 44 and S{ 'Self' }:equals(S(spell.targets))
        end):map(function(spellId) return Spell.new(res.spells[spellId].en) end)

        local spellPickerConfigItem = PickerConfigItem.new("Spell", allSettings.Entrust, allSpells, function(spell)
            return spell:get_localized_name()
        end, "Entrust", nil, function(spell)
            return AssetManager.imageItemForSpell(spell:get_name())
        end)

        local all_job_name_shorts = L{}
        for i = 1, 22 do
            all_job_name_shorts:append(res.jobs[i].ens)
        end
        local current_job_name_shorts = allSettings.Entrust:get_conditions():firstWhere(function(condition)
            return condition.__type == JobCondition.__type
        end).job_name_shorts
        local jobPickerConfigItem = MultiPickerConfigItem.new('JobNames', current_job_name_shorts, all_job_name_shorts, function(job_names)
            return localization_util.commas(job_names:map(function(job_name_short) return i18n.resource('jobs', 'ens', job_name_short) end), 'or')
        end, "Target's Job")
        jobPickerConfigItem:setPickerTitle("Jobs")
        jobPickerConfigItem:setPickerDescription("Choose one or more jobs.")
        jobPickerConfigItem:setAutoSave(true)
        jobPickerConfigItem:setPickerTextFormat(function(job_name_short)
            return i18n.resource('jobs', 'ens', job_name_short)
        end)

        local configItems = L{
            spellPickerConfigItem,
            jobPickerConfigItem
        }

        local entrustSettings = {
            Spell = allSettings.Entrust,
            JobNames = current_job_name_shorts,
        }

        local entrustSettingsEditor = ConfigEditor.new(trustSettings, entrustSettings, configItems, infoView, function(_) return true end, showMenu)
        entrustSettingsEditor:setShouldRequestFocus(true)

        self.dispose_bag:add(entrustSettingsEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
            allSettings.Entrust = Spell.new(newSettings.Spell:get_name(), L{ "Entrust" }, L{}, nil, L{ JobCondition.new(newSettings.JobNames) })

            self.trustSettings:saveSettings(true)

            trust:get_party():add_to_chat(trust:get_party():get_player(), "I'll use "..newSettings.Spell:get_name().." with entrust now!")
        end), entrustSettingsEditor:onConfigChanged())

        self.dispose_bag:add(entrustSettingsEditor:onConfigItemChanged():addAction(function(configKey, newValue, oldValue)

        end), entrustSettingsEditor:onConfigItemChanged())

        self.entrustSettingsEditor = entrustSettingsEditor

        return entrustSettingsEditor
    end

    return self
end

function EntrustSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

return EntrustSettingsMenuItem
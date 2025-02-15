local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local BloodPactSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BloodPactSettingsMenuItem.__index = BloodPactSettingsMenuItem

function BloodPactSettingsMenuItem.new(trustSettings, trust, bloodPacts, trustModeSettings)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Summoner", "Configure Summoner settings."), BloodPactSettingsMenuItem)

    self.trustSettings = trustSettings
    self.trustModeSettings = trustModeSettings
    self.bloodPacts = bloodPacts
    self.job = trust:get_job()
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function BloodPactSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function BloodPactSettingsMenuItem:reloadSettings()
    --self:setChildMenuItem("Buffs", self:getBuffsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function BloodPactSettingsMenuItem:getBuffsMenuItem()
    local indicolureMenuItem = MenuItem.new(L{
        ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
    }, L{}, function(_)
        local allBloodPacts = self.job:get_blood_pact_wards(function(bloodPact)
            return buff_util.buff_for_job_ability(bloodPact.id) ~= nil and not S(bloodPact.targets):contains('Enemy')
        end)

        local configItem = MultiPickerConfigItem.new("BloodPacts", self.bloodPacts, allBloodPacts, function(bloodPact)
            return bloodPact:get_localized_name()
        end, "Blood Pacts", nil, function(bloodPact)
            return AssetManager.imageItemForJobAbility(bloodPact:get_name())
        end)

        local chooseBloodPactView = FFXIPickerView.withConfig(configItem, true)
        chooseBloodPactView:on_pick_items():addAction(function(_, selectedBloodPacts)
            self.bloodPacts:clear()

            local bloodPacts = selectedBloodPacts:map(function(bloodPact) return JobAbility.new(bloodPact:get_name()) end):compact_map()
            for bloodPact in bloodPacts:it() do
                self.bloodPacts:append(bloodPact)
            end

            self.trustSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my list of Blood Pact: Wards!")
        end)
        return chooseBloodPactView
    end, "Summoner", "Customize Blood Pact: Wards to use on the party.")
    return indicolureMenuItem
end

function BloodPactSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for avatar behavior.",
            L{'AutoAssaultMode', 'AutoAvatarMode', 'AutoBuffMode'})
end

return BloodPactSettingsMenuItem
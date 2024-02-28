local BloodPactSettingsEditor = require('ui/settings/editors/BloodPactSettingsEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/ModeSettingsEditor')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')

local BloodPactSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BloodPactSettingsMenuItem.__index = BloodPactSettingsMenuItem

function BloodPactSettingsMenuItem.new(trustSettings, trust, bloodPacts, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Buffs', 18),
        ButtonItem.default('Modes', 18),
    }, {}, function(_)
        local bloodPactsView = viewFactory(BloodPactSettingsEditor.new(trustSettings, bloodPacts))
        bloodPactsView:setShouldRequestFocus(true)
        return bloodPactsView
    end, "Summoner", "Configure Summoner settings."), BloodPactSettingsMenuItem)

    self.trustSettings = trustSettings
    self.bloodPacts = bloodPacts
    self.job = trust:get_job()
    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function BloodPactSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function BloodPactSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Buffs", self:getBuffsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function BloodPactSettingsMenuItem:getBuffsMenuItem()
    local indicolureMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, L{}, function(_)
        local allBloodPacts = self.job:get_blood_pact_wards(function(bloodPact)
            return buff_util.buff_for_job_ability(bloodPact.id) ~= nil and not S(bloodPact.targets):contains('Enemy')
        end):map(function(bloodPact) return bloodPact:get_name()  end)

        local chooseBloodPactView = self.viewFactory(FFXIPickerView.withItems(allBloodPacts, self.bloodPacts:map(function(bloodPact) return bloodPact:get_name()  end), true))
        chooseBloodPactView:setTitle("Choose Blood Pact: Wards.")
        chooseBloodPactView:on_pick_items():addAction(function(_, selectedItems)
            self.bloodPacts:clear()

            local bloodPacts = selectedItems:map(function(item) return JobAbility.new(item:getText()) end):compact_map()
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
    local geomancyModesMenuItem = MenuItem.new(L{}, L{}, function(_)
        local modesView = self.viewFactory(ModesView.new(L{'AutoAssaultMode', 'AutoAvatarMode', 'AutoBuffMode'}))
        modesView:setShouldRequestFocus(true)
        modesView:setTitle("Set modes for Summoner.")
        return modesView
    end, "Modes", "Change behavior of Avatars.")
    return geomancyModesMenuItem
end

return BloodPactSettingsMenuItem
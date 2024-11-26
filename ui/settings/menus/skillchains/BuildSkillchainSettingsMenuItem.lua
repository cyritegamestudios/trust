local BuildSkillchainEditor = require('ui/settings/editors/BuildSkillchainEditor')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local PartySkillchainSettingsMenuItem = require('ui/settings/menus/skillchains/PartySkillchainSettingsMenuItem')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')

local BuildSkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuildSkillchainSettingsMenuItem.__index = BuildSkillchainSettingsMenuItem

function BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer, selectPartyCombatSkillIds)
    local builderSettings = T{}
    builderSettings.NumSteps = 2
    builderSettings.Property = 'Light Lv.4'
    builderSettings.CombatSkills = S{}
    builderSettings.IncludeAeonic = false

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Search', 18),
    }, {}, function(menuArgs)
        local activeCombatSkillIds = S(skillchainer:get_party():get_player():get_combat_skill_ids())
        if selectPartyCombatSkillIds then
            for partyMember in skillchainer:get_party():get_party_members(false):it() do
                activeCombatSkillIds = activeCombatSkillIds:union(partyMember:get_combat_skill_ids())
            end
        end

        local skillchainBuilderEditor = BuildSkillchainEditor.new(builderSettings, skillchainer, activeCombatSkillIds)

        skillchainBuilderEditor:setNeedsLayout()
        skillchainBuilderEditor:layoutIfNeeded()

        return skillchainBuilderEditor
    end, "Skillchains", "Find a skillchain."), BuildSkillchainSettingsMenuItem)

    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettingsMode = weaponSkillSettingsMode
    self.builderSettings = builderSettings
    self.skillchainer = skillchainer

    self:reloadSettings()

    return self
end

function BuildSkillchainSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.chooseSkillchainView = nil
end

function BuildSkillchainSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Search", self:getConfirmMenuItem())
    self:setChildMenuItem("Reset", MenuItem.action(function()
        self:resetSettings()
    end), "Skillchains", "Reset to default settings.")
end

function BuildSkillchainSettingsMenuItem:getConfirmMenuItem()
    local setPage = function(newPage)
        if newPage > 0 and newPage ~= self.currentPage then
            local itemsPerPage = 18
            local startIndex = (newPage - 1) * itemsPerPage + 1
            if startIndex > self.skillchains:length() then
                return
            end
            self.currentPage = newPage

            local newSkillchains = L{}:extend(self.skillchains):slice(startIndex, math.min(self.skillchains:length(), startIndex + itemsPerPage))
            self.currentSkillchains = newSkillchains

            local pickerItems = L(newSkillchains:map(function(abilities)
                local abilities = L(abilities:map(function(ability) return ability:get_name() end))
                return localization_util.join(abilities, '→')
            end))
            self.chooseSkillchainView:setItems(pickerItems, L{}, true)
        end
    end

    local confirmMenuItem = MenuItem.new(L{
        --ButtonItem.default('Save', 18),
        ButtonItem.default('Select', 18),
        --ButtonItem.default('Previous', 18),
        --ButtonItem.default('Next', 18),
    }, {
        Select = PartySkillchainSettingsMenuItem.new(self.weaponSkillSettings, self.weaponSkillSettingsMode, self.skillchainer),
        --Previous = MenuItem.action(function()
        --    setPage(self.currentPage - 1)
        --end, "Skillchains", "See previous page."),
        --Next = MenuItem.action(function()
        --    setPage(self.currentPage + 1)
        --end, "Skillchains", "See next page."),
    }, function(menuArgs, infoView)
        self.currentPage = 1

        local skillchain_builder = SkillchainBuilder.with_skills(L(self.builderSettings.CombatSkills))
        skillchain_builder.include_aeonic = self.builderSettings.IncludeAeonic

        local skillchains = skillchain_builder:build(self.builderSettings.Property, self.builderSettings.NumSteps)
        self.skillchains = skillchains

        self.currentSkillchains = L{}:extend(skillchains):slice(1, math.min(skillchains:length(), 500))
        local pickerItems = L(self.currentSkillchains:map(function(abilities)
            local abilities = L(abilities:map(function(ability) return ability:get_name() end))
            return localization_util.join(abilities, '→')
        end))

        local configItem = MultiPickerConfigItem.new("Skillchains", L{}, pickerItems, function(pickerItem)
            return pickerItem
        end)

        local chooseSkillchainView = FFXIPickerView.new(L{ configItem }, false, FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge)
        --local chooseSkillchainView = FFXIPickerView.withItems(pickerItems, L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge, true)
        chooseSkillchainView.menuArgs.Skillchain = self.currentSkillchains[1]
        chooseSkillchainView:setAllowsCursorSelection(true)
        chooseSkillchainView:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            chooseSkillchainView.menuArgs.Skillchain = self.currentSkillchains[indexPath.row]
            local abilities = L(self.currentSkillchains[indexPath.row]:map(function(ability) return ability:get_name() end))
            infoView:setDescription(localization_util.join(abilities, '→'))
        end)
        self.chooseSkillchainView = chooseSkillchainView
        return chooseSkillchainView
    end, "Skillchains", "Find a skillchain.")
    return confirmMenuItem
end

function BuildSkillchainSettingsMenuItem:getPartyMenuItem()
    local partyMenuItem = MenuItem.new(L{
       ButtonItem.default('Save', 18)
    }, {

    }, function(menuArgs)

    end, "Skillchains", "Assign steps to party members.")

    return partyMenuItem
end

function BuildSkillchainSettingsMenuItem:resetSettings()
    self.builderSettings.NumSteps = 2
    self.Property = 'LightLv4'
    self.CombatSkills = S{}
end

return BuildSkillchainSettingsMenuItem
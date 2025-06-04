local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local PartySkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
PartySkillchainSettingsMenuItem.__index = PartySkillchainSettingsMenuItem

function PartySkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Save', 18),
    }, {}, nil, "Skillchains", "Choose party members for each step. Press Enter and use the Left and Right arrow keys."), PartySkillchainSettingsMenuItem)

    self.skillchainSettings = T{
        Skillchain = {}
    }

    self.contentViewConstructor = function(_)
        local skillchain = self.skillchainSettings.Skillchain

        for i = 1, skillchain:length() do
            self.skillchainSettings['Step '..i..': '..skillchain[i]:get_name()] = windower.ffxi.get_player().name
        end

        local validPartyMembers = function(ability)
            local result = L{}
            local combatSkillId = ability:get_skill_id()
            for partyMember in skillchainer:get_party():get_party_members(true):it() do
                if partyMember:get_combat_skill_ids():contains(combatSkillId) then
                    result:append(partyMember:get_name())
                end
            end
            if result:empty() then
                result:append('Skip')
            end
            return result
        end

        local configItems = L{}
        for i = 1, skillchain:length() do
            local partyMemberNames = validPartyMembers(skillchain[i])
            configItems:append(PickerConfigItem.new('Step '..i..': '..skillchain[i]:get_name(), partyMemberNames[1], partyMemberNames))
        end

        local partySkillchainEditor = ConfigEditor.new(nil, self.skillchainSettings, configItems)
        return partySkillchainEditor
    end

    self.weaponSkillSettings = weaponSkillSettings
    self.weaponSkillSettingsMode = weaponSkillSettingsMode
    self.skillchainer = skillchainer

    self:reloadSettings()

    return self
end

function PartySkillchainSettingsMenuItem:destroy()
    MenuItem.destroy(self)
end

function PartySkillchainSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Save", MenuItem.action(function()
        local participatingPartyMemberNames = S{}
        for i = 1, self.skillchainSettings.Skillchain:length() do
            local partyMemberName = self.skillchainSettings['Step '..i..': '..self.skillchainSettings.Skillchain[i]:get_name()]
            participatingPartyMemberNames:add(partyMemberName)
        end
        local partyMembers = self.skillchainer:get_party():get_party_members(false):filter(function(p)
            return participatingPartyMemberNames:contains(p:get_name())
        end)
        local currentSettings = self.weaponSkillSettings:getSettings()[self.weaponSkillSettingsMode.value]
        local abilityForCombatSkillSettings = function(abilityName)
            for combat_skill in currentSettings.Skills:it() do
                local ability = combat_skill:get_ability(abilityName)
                if ability then
                    return ability
                end
            end
            return nil
        end
        for i = 1, 6 do
            if i <= self.skillchainSettings.Skillchain:length() then
                local partyMemberName = self.skillchainSettings['Step '..i..': '..self.skillchainSettings.Skillchain[i]:get_name()]
                if partyMemberName == windower.ffxi.get_player().name then
                    local ability = abilityForCombatSkillSettings(self.skillchainSettings.Skillchain[i]:get_name()) or SkillchainAbility.auto()
                    currentSettings.Skillchain.Gambits[i] = Gambit.new(GambitTarget.TargetType.Enemy, L{}, ability, Condition.TargetType.Self, L{"Skillchain"})
                    for partyMember in partyMembers:it() do
                        windower.send_command('trust send '..partyMember:get_name()..' trust sc set '..i..' '..'Skip')
                    end
                else
                    currentSettings.Skillchain.Gambits[i] = Gambit.new(GambitTarget.TargetType.Enemy, L{}, SkillchainAbility.skip(), Condition.TargetType.Self, L{"Skillchain"})
                    windower.send_command('trust send '..partyMemberName..' trust sc set '..i..' '..self.skillchainSettings.Skillchain[i]:get_name())
                    for partyMember in partyMembers:it() do
                        if partyMember:get_name() ~= partyMemberName then
                            windower.send_command('trust send '..partyMember:get_name()..' trust sc set '..i..' '..'Skip')
                        end
                    end
                end
            else
                currentSettings.Skillchain.Gambits[i] = Gambit.new(GambitTarget.TargetType.Enemy, L{}, SkillchainAbility.skip(), Condition.TargetType.Self, L{"Skillchain"})
                for partyMember in partyMembers:it() do
                    windower.send_command('trust send '..partyMember:get_name()..' trust sc set '..i..' '..'Skip')
                end
            end

            --[[if i <= self.skillchain:length() then
                local found = false
                for combat_skill in currentSettings.Skills:it() do
                    local ability = combat_skill:get_ability(selectedSkillchain[i]:get_name())
                    if ability then
                        currentSettings.Skillchain[i] = ability
                        found = true
                    end
                end
                if not found then
                    currentSettings.Skillchain[i] = SkillchainAbility.skip()
                    local combat_skill_id = skillchain[i]:get_skill_id()
                    for partyMember in self.skillchainer:get_party():get_party_members(false):it() do
                        if partyMember:get_combat_skill_ids():contains(combat_skill_id) then
                            --windower.send_command('trust send '..partyMember:get_name()..' trust sc set '..i..' '..selectedSkillchain[i]:get_name())
                            break
                        end
                    end
                end
            else
                currentSettings.Skillchain[i] = SkillchainAbility.auto()
            end
        end]]
        end
        self.weaponSkillSettings:saveSettings(true)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my skillchain!")
    end), "Skillchains", "Choose party members for each step.")
end

function PartySkillchainSettingsMenuItem:setSkillchain(skillchain)
    self.skillchainSettings.Skillchain = skillchain
end

return PartySkillchainSettingsMenuItem
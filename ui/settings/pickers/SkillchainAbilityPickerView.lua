local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local PickerView = require('cylibs/ui/picker/picker_view')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainBuilder = require('cylibs/battle/skillchains/skillchain_builder')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')

local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local SkillchainAbilityPickerView = setmetatable({}, {__index = FFXIPickerView })
SkillchainAbilityPickerView.__index = SkillchainAbilityPickerView

function SkillchainAbilityPickerView.new(weaponSkillSettings, abilities, abilityIndex, skillchainer)
    local skillchainBuilder = SkillchainBuilder.new(skillchainer.skillchain_builder.abilities)

    local currentAbilities = abilities:slice(1, math.max(abilityIndex - 1, 1)):map(
            function(ability)
                if ability.__class ~= SkillchainAbility.__class then
                    return SkillchainAbility.new(ability.resource, ability:get_ability_id())
                end
                return ability
            end)

    local abilityNames = L{}
    if abilityIndex > 1 then
        local currentSkillchain = skillchainBuilder:reduce_skillchain(currentAbilities)
        if abilityIndex > 2 and not currentSkillchain then
            abilityNames =  L{ SkillchainAbility.skip(), SkillchainAbility.auto() }:merge(skillchainer.skillchain_builder.abilities):map(function(ability) return ability:get_name() end)
        else
            skillchainBuilder:set_current_step(SkillchainStep.new(abilityIndex - 1, abilities[abilityIndex - 1], currentSkillchain))

            local nextSteps = skillchainBuilder:get_next_steps():map(function(step)
                local result = step:get_ability():get_name()
                if step:get_skillchain() then
                    result = result..' ('..step:get_skillchain()..')'
                end
                return result
            end)
            abilityNames = nextSteps
        end
    else
        abilityNames = L(skillchainer.skillchain_builder.abilities):map(function(ability) return ability:get_name() end)
    end

    local imageItemForText = function(text)
        return AssetManager.imageItemForWeaponSkill(text)
    end

    local self = setmetatable(FFXIPickerView.withItems(abilityNames, L{}, false, nil, imageItemForText, { width = 220, height = 192 }), SkillchainAbilityPickerView)

    self.abilities = abilities
    self.abilityIndex = abilityIndex
    self.skillchainer = skillchainer
    self.allAbilities = self.skillchainer.skillchain_builder.abilities
    self.weaponSkillSettings = weaponSkillSettings

    if self:getDataSource():numberOfItemsInSection(1) > 0 then
        self:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
    end

    if skillchainBuilder:get_current_step() then
        self.titleText = "Choose an ability for step "..skillchainBuilder:get_current_step():get_step() + 1
    else
        self.titleText = "Choose an ability for step "..abilityIndex
    end

    self:setNeedsLayout()
    self:layoutIfNeeded()

    return self
end

function SkillchainAbilityPickerView:onSelectMenuItemAtIndexPath(textItem, _)
    if textItem:getText() == 'Confirm' then
        local cursorIndexPath = self:getDelegate():getCursorIndexPath()
        if cursorIndexPath then
            local item = self:getDataSource():itemAtIndexPath(cursorIndexPath)
            if item then
                local abilityName = item:getText():gsub("([^:%s]+%s*:?%s*)(%([^%)]+%)%s*", "%1"):gsub("%s+$", "")
                for skill in self.skillchainer.active_skills:it() do
                    local ability = skill:get_ability(abilityName)
                    if ability then
                        self.abilities[self.abilityIndex] = ability
                    end
                end
            end
            self:setNeedsLayout()
            self:layoutIfNeeded()
            self.weaponSkillSettings:saveSettings(true)
            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've updated my weapon skills!")
        end
    end
end

function SkillchainAbilityPickerView:layoutIfNeeded()
    if not PickerView.layoutIfNeeded(self) then
        return false
    end

    self:setTitle(self.titleText)
end

return SkillchainAbilityPickerView
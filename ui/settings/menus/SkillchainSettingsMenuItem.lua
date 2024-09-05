local BuildSkillchainSettingsMenuItem = require('ui/settings/menus/skillchains/BuildSkillchainSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local DisposeBag = require('cylibs/events/dispose_bag')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SkillchainAbilityPickerView = require('ui/settings/pickers/SkillchainAbilityPickerView')
local SkillchainSettingsEditor = require('ui/settings/SkillchainSettingsEditor')

local SkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SkillchainSettingsMenuItem.__index = SkillchainSettingsMenuItem

function SkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer)
    local skillchainStepPickerItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
            function(args)
                local settings = T(weaponSkillSettings:getSettings())[weaponSkillSettingsMode.value]

                local abilities = settings.Skillchain
                local abilityIndex = args['selected_index'] or 1

                local createSkillchainView = SkillchainAbilityPickerView.new(weaponSkillSettings, abilities, abilityIndex, skillchainer)
                createSkillchainView:setShouldRequestFocus(true)
                return createSkillchainView
            end, "Skillchains", "Edit which weapon skill to use for the selected step.")
    
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Skip', 18),
        ButtonItem.default('Clear', 18),
        ButtonItem.default('Clear All', 18),
        ButtonItem.default('Conditions', 18),
        ButtonItem.default('Find', 18),
    }, {
        Edit = skillchainStepPickerItem,
        Skip = MenuItem.action(nil, "Skillchains", "Wait for party members to use a weapon skill for the selected step."),
        Clear = MenuItem.action(nil, "Skillchains", "Automatically determine a weapon skill to use for the selected step."),
        ["Clear All"] = MenuItem.action(nil, "Skillchains", "Automatically determine weapon skills to use for all steps."),
        Conditions = ConditionSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode),
        Find = BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer),
    },
    nil, "Skillchains", "Edit or create a new skillchain."), SkillchainSettingsMenuItem)

    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, _)
        local settings = T(weaponSkillSettings:getSettings())[weaponSkillSettingsMode.value]

        local abilities = settings.Skillchain

        local createSkillchainView = SkillchainSettingsEditor.new(weaponSkillSettings, abilities)
        createSkillchainView:setShouldRequestFocus(true)

        self.disposeBag:add(createSkillchainView:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local selectedAbility = abilities[indexPath.row]
            self.selectedAbility = selectedAbility

            createSkillchainView.menuArgs['conditions'] = selectedAbility:get_conditions()
            --createSkillchainView.menuArgs['targetTypes'] = S{ selectedGambit:getConditionsTarget() }
        end, createSkillchainView:getDelegate():didSelectItemAtIndexPath()))

        return createSkillchainView
    end

    return self
end

function SkillchainSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function SkillchainSettingsMenuItem:getConfigKey()
    return "skillchains"
end

return SkillchainSettingsMenuItem
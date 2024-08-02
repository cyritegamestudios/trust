local BuildSkillchainSettingsMenuItem = require('ui/settings/menus/skillchains/BuildSkillchainSettingsMenuItem')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SkillchainAbilityPickerView = require('ui/settings/pickers/SkillchainAbilityPickerView')
local SkillchainSettingsEditor = require('ui/settings/SkillchainSettingsEditor')

local SkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
SkillchainSettingsMenuItem.__index = SkillchainSettingsMenuItem

function SkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer, viewFactory)
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

    local skillchainSetsMenuItem = MenuItem.new(L{
        ButtonItem.default('Cycle', 18),
        ButtonItem.default('Create', 18),
        ButtonItem.default('Delete', 18),
    }, L{
        Cycle = MenuItem.action(nil, "Modes", "Cycle through saved weapon skill sets."),
        Create = MenuItem.action(nil, "Modes", "Create a new weapon skill set from the Default set."),
        Delete = MenuItem.action(nil, "Modes", "Delete the current weapon skill set and switch to the default set."),
    }, nil, "Modes", "Create, delete or cycle through weapon skill settings.", true)

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Skip', 18),
        ButtonItem.default('Clear', 18),
        ButtonItem.default('Clear All', 18),
        ButtonItem.default('Find', 18),
        ButtonItem.default('Sets', 18),
    }, {
        Edit = skillchainStepPickerItem,
        Skip = MenuItem.action(nil, "Skillchains", "Wait for party members to use a weapon skill for the selected step."),
        Clear = MenuItem.action(nil, "Skillchains", "Automatically determine a weapon skill to use for the selected step."),
        ["Clear All"] = MenuItem.action(nil, "Skillchains", "Automatically determine weapon skills to use for all steps."),
        Find = BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer),
        Sets = skillchainSetsMenuItem,
    },
    function(args)
        local settings = T(weaponSkillSettings:getSettings())[weaponSkillSettingsMode.value]

        local abilities = settings.Skillchain

        local createSkillchainView = SkillchainSettingsEditor.new(weaponSkillSettings, abilities)
        createSkillchainView:setShouldRequestFocus(true)
        return createSkillchainView
    end, "Skillchains", "Edit or create a new skillchain."), SkillchainSettingsMenuItem)

    return self
end

function SkillchainSettingsMenuItem:getConfigKey()
    return "skillchains"
end

return SkillchainSettingsMenuItem
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local BuildSkillchainSettingsMenuItem = setmetatable({}, {__index = MenuItem })
BuildSkillchainSettingsMenuItem.__index = BuildSkillchainSettingsMenuItem

function BuildSkillchainSettingsMenuItem.new(weaponSkillSettings, weaponSkillSettingsMode, skillchainer)
    local builderSettings = T{}
    builderSettings.NumSteps = 2
    builderSettings.Property = 'LightLv4'

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {}, function(menuArgs)
        local configItems = L{
            ConfigItem.new('NumSteps', 2, 6, 1, function(value) return value.."" end),
            PickerConfigItem.new('Property', 'LightLv4', L{
                'LightLv4', 'DarknessLv4', 'Light', 'Darkness',
                'Distortion', 'Gravitation', 'Fusion', 'Fragmentation',
                'Induration', 'Scission', 'Reverberation', 'Compression',
                'Detonation', 'Impaction', 'Liquefaction', 'Transfixion',
            }),
        }
        local skillchainBuilderEditor = ConfigEditor.new(nil, builderSettings, configItems)
        skillchainBuilderEditor:setShouldRequestFocus(true)
        return skillchainBuilderEditor
    end, "Skillchains", "Find a skillchain."), BuildSkillchainSettingsMenuItem)

    self.builderSettings = builderSettings
    self.skillchainer = skillchainer

    self:reloadSettings()

    return self
end

function BuildSkillchainSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Confirm", MenuItem.action(function()
        windower.send_command('input // trust sc build '..self.builderSettings.Property..' '..self.builderSettings.NumSteps)
    end), "Skillchains", "Find a skillchain.")
end

return BuildSkillchainSettingsMenuItem
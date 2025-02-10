local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local ConfigItem = require('ui/settings/editors/config/ConfigItem')
local element_util = require('cylibs/util/element_util')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local GambitTarget = require('cylibs/gambits/gambit_target')
local MenuItem = require('cylibs/ui/menu/menu_item')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')
local TextInputConfigItem = require('ui/settings/editors/config/TextInputConfigItem')

local GambitSettingsMenuItem = require('ui/settings/menus/gambits/GambitSettingsMenuItem')
local NukeSettingsMenuItem = setmetatable({}, {__index = GambitSettingsMenuItem })
NukeSettingsMenuItem.__index = NukeSettingsMenuItem


function NukeSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, addonSettings, jobNameShort)
    local self = setmetatable(GambitSettingsMenuItem.compact(trust, trustSettings, trustSettingsMode, trustModeSettings, 'NukeSettings', S{ GambitTarget.TargetType.Enemy }, function(targets)
        local currentSettings = trustSettings:getSettings()[trustSettingsMode.value].NukeSettings
        local currentNukes = currentSettings.Gambits:map(function(gambit)
            return gambit:getAbility():get_name()
        end)

        local sections = L{
            L(trust:get_job():get_spells(function(spellId)
                local spell = res.spells[spellId]
                return spell and not currentNukes:contains(spell.en) and S{ 'BlackMagic', 'WhiteMagic', 'Ninjutsu', 'BlueMagic' }:contains(spell.type) and S{ 'Enemy' }:intersection(S(spell.targets)):length() > 0 and spell.element ~= 15
            end):map(function(spellId)
                return Spell.new(res.spells[spellId].en)
            end)):unique(function(spell)
                return spell:get_name()
            end),
        }
        return sections
    end, L{ Condition.TargetType.Enemy }, L{'AutoMagicBurstMode', 'AutoNukeMode', 'MagicBurstTargetMode'}, "Nuke", "Nukes", function(_)
        return false
    end, function(ability)
        --local debuff = ability:get_status()
        --if debuff then
        --    return "Inflicts: "..i18n.resource('buffs', 'en', debuff.en).."."
        --end
        --return nil
    end, S{ 'Reaction' }), NukeSettingsMenuItem)
    self:setDefaultGambitTags(L{'Nukes'})

    self:getDisposeBag():add(self:onGambitChanged():addAction(function(newGambit, oldGambit)
        if newGambit:getAbility() ~= oldGambit:getAbility() then
            newGambit.conditions = newGambit.conditions:filter(function(condition)
                return condition:is_editable()
            end)
            local conditions = trust:role_with_type("magicburster"):get_default_conditions(newGambit)
            for condition in conditions:it() do
                condition.editable = false
                newGambit:addCondition(condition)
            end
        end
    end), self:onGambitChanged())

    self:setChildMenuItem("Config", self:getConfigMenuItem())
    self:setChildMenuItem("Blacklist", self:getBlacklistMenuItem())

    return self
end

function NukeSettingsMenuItem:getBlacklistMenuItem()
    local nukeElementBlacklistMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear All', 18),
    }, {},
            function()
                local nukeSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value].NukeSettings
                if not nukeSettings.Blacklist then
                    nukeSettings.Blacklist = L{}
                end

                local allElements = L{
                    element_util.Light,
                    element_util.Fire,
                    element_util.Lightning,
                    element_util.Wind,
                    element_util.Dark,
                    element_util.Earth,
                    element_util.Water,
                    element_util.Ice,
                }

                local configItem = MultiPickerConfigItem.new("Elements", nukeSettings.Blacklist, allElements, function(element)
                    return element:get_localized_name()
                end, "Elements", nil, function(element)
                    return AssetManager.imageItemForElement(res.elements:with('en', element:get_name()).id)
                end)

                local blacklistPickerView = FFXIPickerView.withConfig(configItem, true)

                blacklistPickerView:getDisposeBag():add(blacklistPickerView:on_pick_items():addAction(function(_, selectedElements)
                    nukeSettings.Blacklist:clear()
                    for element in selectedElements:it() do
                        nukeSettings.Blacklist:append(Element.new(element:get_name()))
                    end
                    self.trustSettings:saveSettings(true)
                    addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I won't use nukes of these elements!")
                end), blacklistPickerView:on_pick_items())

                return blacklistPickerView
            end, "Blacklist", "Choose elements to avoid when magic bursting or free nuking.")
    return nukeElementBlacklistMenuItem
end

function NukeSettingsMenuItem:getConfigMenuItem()
    local nukeConfigMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
    }, {},
            function()
                local allSettings = T(self.trustSettings:getSettings())[self.trustSettingsMode.value]

                local nukeSettings = T{
                    Delay = allSettings.NukeSettings.Delay,
                    MinManaPointsPercent = allSettings.NukeSettings.MinManaPointsPercent,
                    MinNumMobsToCleave = allSettings.NukeSettings.MinNumMobsToCleave,
                    GearswapCommand = allSettings.NukeSettings.GearswapCommand or 'gs c set MagicBurstMode Single',
                }

                local configItems = L{
                    ConfigItem.new('Delay', 0, 60, 1, function(value) return value.."s" end, "Delay Between Nukes"),
                    ConfigItem.new('MinManaPointsPercent', 0, 100, 1, function(value) return value.." %" end, "Min MP %"),
                    ConfigItem.new('MinNumMobsToCleave', 0, 30, 1, function(value) return value.."" end, "Min Number Mobs to Cleave"),
                    TextInputConfigItem.new('GearswapCommand', nukeSettings.GearswapCommand, 'Gearswap Command', function(_) return true  end, 225)
                }

                local nukeConfigEditor = ConfigEditor.new(self.trustSettings, nukeSettings, configItems)

                nukeConfigEditor:setShouldRequestFocus(true)

                self:getDisposeBag():add(nukeConfigEditor:onConfigChanged():addAction(function(newSettings, _)
                    allSettings.NukeSettings.Delay = newSettings.Delay
                    allSettings.NukeSettings.MinManaPointsPercent = newSettings.MinManaPointsPercent
                    allSettings.NukeSettings.MinNumMobsToCleave = newSettings.MinNumMobsToCleave
                    allSettings.NukeSettings.GearswapCommand = (newSettings.GearswapCommand or 'gs c set MagicBurstMode Single'):gsub("^%u", string.lower)

                    self.trustSettings:saveSettings(true)
                end), nukeConfigEditor:onConfigChanged())

                return nukeConfigEditor
            end, "Config", "Configure general nuke settings.")
    return nukeConfigMenuItem
end

return NukeSettingsMenuItem
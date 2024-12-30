local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local EntrustSettingsMenuItem = require('ui/settings/menus/buffs/EntrustSettingsMenuItem')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local GeomancySettingsMenuItem = setmetatable({}, {__index = MenuItem })
GeomancySettingsMenuItem.__index = GeomancySettingsMenuItem

function GeomancySettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, geomancySettings, entrustSpells)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Entrust', 18),
        ButtonItem.default('Modes', 18),
    }, {}, nil, "Geomancy", "Configure indicolure and geocolure settings."), GeomancySettingsMenuItem)

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.geomancySettings = geomancySettings
    self.entrustSpells = entrustSpells
    self.dispose_bag = DisposeBag.new()

    self.contentViewConstructor = function(_, _)

        local allSettings = T(trustSettings:getSettings())[trustSettingsMode.value]

        local allIndiSpells = trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            return spell and spell.type == 'Geomancy' and S{ 'Self' }:equals(S(spell.targets))
        end):map(function(spellId) return res.spells[spellId].en  end):sort()

        local allGeoSpells = trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            return spell and spell.type == 'Geomancy' and S{ 'Party', 'Enemy'}:intersection(S(spell.targets)):length() > 0
        end):map(function(spellId) return res.spells[spellId].en  end):sort()

        local geomancySettings = T{
            Indicolure = allSettings.Geomancy.Indi:get_name(),
            Geocolure = allSettings.Geomancy.Geo:get_name(),
            Target = allSettings.Geomancy.Geo:get_target(),
        }

        local validTargetsForSpell = function(spell)
            return spell:get_valid_targets():map(function(target)
                if target == 'Self' then
                    return 'me'
                elseif target == 'Party' then
                    return L{ 'p0', 'p1', 'p2', 'p3', 'p4', 'p5' }
                elseif target == 'Enemy' then
                    return 'bt'
                end
                return nil
            end):compact_map():flatten(true)
        end

        local targetConfigItem = PickerConfigItem.new('Target', geomancySettings.Target, validTargetsForSpell(allSettings.Geomancy.Geo), function(target)
            local mob = windower.ffxi.get_mob_by_target(target)
            if mob then
                return target.." ("..mob.name..")"
            end
            return target
        end, "Target")

        targetConfigItem.onReload = function(key, newValue, configItem)
            return validTargetsForSpell(Spell.new(newValue))
        end

        local geocolureConfigItem = PickerConfigItem.new('Geocolure', geomancySettings.Geocolure, allGeoSpells, nil, "Geocolure")
        geocolureConfigItem:addDependency(targetConfigItem)

        local configItems = L{
            PickerConfigItem.new('Indicolure', geomancySettings.Indicolure, allIndiSpells, nil, "Indicolure"),
            geocolureConfigItem,
            targetConfigItem,
        }

        local geomancyConfigEditor = ConfigEditor.new(trustSettings, geomancySettings, configItems)
        geomancyConfigEditor:setShouldRequestFocus(true)

        self.dispose_bag:add(geomancyConfigEditor:onConfigChanged():addAction(function(newSettings, _)
            allSettings.Geomancy.Indi = Spell.new(newSettings.Indicolure)
            allSettings.Geomancy.Geo = Spell.new(newSettings.Geocolure, L{}, L{}, newSettings.Target),
            
            self.trustSettings:saveSettings(true)
        end), geomancyConfigEditor:onConfigChanged())

        return geomancyConfigEditor
    end

    self:reloadSettings()

    return self
end

function GeomancySettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()
end

function GeomancySettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Entrust", EntrustSettingsMenuItem.new(self.trust, self.trustSettings, self.trustSettingsMode))
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function GeomancySettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for geocolures and indicolures.",
            L{'AutoGeoMode', 'AutoIndiMode', 'AutoEntrustMode'})
end

return GeomancySettingsMenuItem
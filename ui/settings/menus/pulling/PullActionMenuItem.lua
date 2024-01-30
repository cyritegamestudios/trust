local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local DisposeBag = require('cylibs/events/dispose_bag')
local JobAbilityPickerView = require('ui/settings/pickers/JobAbilityPickerView')
local MenuItem = require('cylibs/ui/menu/menu_item')
local SpellPickerView = require('ui/settings/pickers/SpellPickerView')

local PullActionMenuItem = setmetatable({}, {__index = MenuItem })
PullActionMenuItem.__index = PullActionMenuItem

function PullActionMenuItem.new(puller, puller_settings, job_name_short, viewFactory)
    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Job Abilities', 18),
        ButtonItem.default('Spells', 18),
        ButtonItem.default('Other', 18),
    }, {}, nil, "Pulling", "Configure which actions to use to pull enemies."), PullActionMenuItem)

    self.puller = puller
    self.puller_settings = puller_settings
    self.job_name_short = job_name_short
    self.viewFactory = viewFactory
    self.dispose_bag = DisposeBag.new()

    self:reloadSettings()

    return self
end

function PullActionMenuItem:destroy()
    MenuItem.destroy(self)

    self.dispose_bag:destroy()

    self.viewFactory = nil
end

function PullActionMenuItem:reloadSettings()
    self:setChildMenuItem("Job Abilities", self:getJobAbilitiesMenuItem())
    self:setChildMenuItem("Spells", self:getSpellsMenuItem())
end

function PullActionMenuItem:getSpellsMenuItem()
    local chooseSpellsMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function()
        local jobId = res.jobs:with('ens', self.job_name_short).id
        local allSpells = spell_util.get_spells(function(spell)
            return spell.levels[jobId] ~= nil and spell.targets:contains('Enemy')
        end):map(function(spell) return spell.en end)

        local chooseSpellsView = self.viewFactory(SpellPickerView.new(self.puller_settings, self.puller_settings:getSettings().Spells, allSpells, L{}, true))
        chooseSpellsView:setTitle("Choose spells to pull with.")
        return chooseSpellsView
    end, "Spells", "Pull enemies with spells.")
    return chooseSpellsMenuItem
end

function PullActionMenuItem:getJobAbilitiesMenuItem()
    local chooseJobAbilitiesItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Clear', 18),
    }, {},
    function()
        local allJobAbilities = player_util.get_job_abilities():map(function(jobAbilityId) return res.job_abilities[jobAbilityId] end):filter(function(jobAbility)
            return S{'Enemy'}:intersection(S(jobAbility.targets)):length() > 0
        end):map(function(jobAbility) return jobAbility.en end)

        local chooseJobAbilitiesView = self.viewFactory(JobAbilityPickerView.new(self.puller_settings, self.puller_settings:getSettings().JobAbilities, allJobAbilities))
        chooseJobAbilitiesView:setTitle("Choose job abilities to pull with.")
        return chooseJobAbilitiesView
    end, "Job Abilities", "Pull enemies with job abilities.")
    return chooseJobAbilitiesItem
end

function PullActionMenuItem:getModesMenuItem()
    local pullModesMenuItem = MenuItem.new(L{
        ButtonItem.default('Auto', 18),
        ButtonItem.default('Multi', 18),
        ButtonItem.default('Target', 18),
        ButtonItem.default('All', 18),
        ButtonItem.default('Off', 18),
    }, L{
        Auto = MenuItem.action(function()
            handle_set('AutoPullMode', 'Auto')
        end, "Pulling", state.AutoPullMode:get_description('Auto')),
        Multi = MenuItem.action(function()
            handle_set('AutoPullMode', 'Multi')
        end, "Pulling", state.AutoPullMode:get_description('Multi')),
        Target = MenuItem.action(function()
            handle_set('AutoPullMode', 'Target')
        end, "Pulling", state.AutoPullMode:get_description('Target')),
        All = MenuItem.action(function()
            handle_set('AutoPullMode', 'All')
        end, "Pulling", state.AutoPullMode:get_description('All')),
        Off = MenuItem.action(function()
            handle_set('AutoPullMode', 'Off')
        end, "Pulling", state.AutoPullMode:get_description('Off')),
    }, nil, "Modes", "Change pulling modes.")
    return pullModesMenuItem
end

return PullActionMenuItem
local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local skillchain_util = require('cylibs/util/skillchain_util')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local ScholarTrustCommands = setmetatable({}, {__index = TrustCommands })
ScholarTrustCommands.__index = ScholarTrustCommands
ScholarTrustCommands.__class = "ScholarTrustCommands"

function ScholarTrustCommands.new(trust, action_queue, trust_settings, weapon_skill_settings)
    local self = setmetatable(TrustCommands.new(), ScholarTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
    self.weapon_skill_settings = weapon_skill_settings
    self.action_queue = action_queue

    self:add_command('sc', self.handle_skillchain, 'Make a skillchain using immanence', L{
        PickerConfigItem.new('skillchain_property', skillchain_util.all_skillchain_properties()[1], skillchain_util.all_skillchain_properties(), nil, "Skillchain Property")
    })
    self:add_command('accession', self.handle_accession, 'Cast a spell with accession, // trust sch accession spell_name')

    local storm_elements = L{ 'fire', 'ice', 'wind', 'earth', 'lightning', 'water', 'light', 'dark' }
    self:add_command('storm', self.handle_storm, 'Set storm element for self and party', L{
        PickerConfigItem.new('storm_element_name', storm_elements[1], storm_elements, function(v) return v:gsub("^%l", string.upper) end, "Storm Element"),
        PickerConfigItem.new('include_party', "false", L{ "false", "true" }, nil, "Include Party")
    })

    self:add_command('set', self.handle_set_skillchain, 'Set the skillchain using immanence', L{
        PickerConfigItem.new('skillchain_property', skillchain_util.all_skillchain_properties()[1], skillchain_util.all_skillchain_properties(), nil, "Skillchain Property")
    })

    return self
end

function ScholarTrustCommands:get_command_name()
    return 'sch'
end

function ScholarTrustCommands:get_localized_command_name()
    return 'Scholar'
end

function ScholarTrustCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

function ScholarTrustCommands:get_job()
    return self.trust:get_job()
end

function ScholarTrustCommands:get_spells(element)
    element = element:lower()
    if element == "liquefaction" then
        return "Stone", "Pyrohelix" 
    elseif element == "scission" then
        return "Fire", "Stone"
    elseif element == "reverberation" then
        return "Stone", "Hydrohelix"
    elseif element == "detonation" then
        return "Thunder", "Anemohelix"
    elseif element == "induration" then
        return "Water", "Blizzard"
    elseif element == "impaction" then
        return "Blizzard", "Ionohelix"
    elseif element == "transfixion" then
        return "Noctohelix", "Luminohelix"
    elseif element == "compression" then
        return "Blizzard", "Noctohelix"
    elseif element == "fragmentation" then
        return "Blizzard", "Water"
    elseif element == "fusion" then
        return "Fire", "Ionohelix"
    elseif element == "gravitation" then
        return "Aero", "Noctohelix"
    elseif element == "distortion" then
        return "Luminohelix", "Stone"
    else
        return nil, nil
    end
end

-- // trust sch sc [liquefaction|scission|reverberation|detontation|induration|impaction|transfixion|compression|fragmentation|fusion|gravitation|distortion]
function ScholarTrustCommands:handle_skillchain(_, element)
    local success
    local message

    element = windower.convert_auto_trans(element)

    local target_index = self.trust:get_target_index()

    local spell1, spell2 = self:get_spells(element)
    if spell2 == nil or spell2 == nil then
        success = false
        message = "No spells found to make skillchain of element "..(element or 'nil')
    elseif self:get_job():get_current_num_strategems() < 2 then
        success = false
        message = "Insufficient strategems remaining"
    else
        success = true
        local actions = L{
            BlockAction.new(function()
                self.trust:get_party():add_to_chat(self.trust:get_party():get_player(), "**[Starting]** Skillchain "..spell1.." > "..spell2.." = "..localization_util.translate(element))
            end, 'skillchain_start')
        }
        local spells = L{
            Spell.new(spell1, L{ 'Immanence' }),
            Spell.new(spell2, L{ 'Immanence' })
        }
        local step = 1
        for spell in spells:it() do
            if not Condition.check_conditions(spell:get_conditions(), target_index) then
                success = false
                message = "Unable to use spells"
                break
            else
                if step == spells:length() then
                    actions:append(BlockAction.new(function()
                        self.trust:get_party():add_to_chat(self.trust:get_party():get_player(), "**[Closing]** Skillchain "..element)
                    end, 'skillchain_'..spell:get_spell().en))
                end
                actions:append(StrategemAction.new('Immanence'))
                actions:append(WaitAction.new(0, 0, 0, 2))
                actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, target_index, self.trust:get_player()))
                actions:append(WaitAction.new(0, 0, 0, 2))
            end
            step = step +1
        end
        if success then
            local skillchain_action = SequenceAction.new(actions, 'skillchain_'..element, false)
            skillchain_action.priority = ActionPriority.highest
            skillchain_action.max_duration = 15

            for action in actions:it() do
                logger.notice(action:tostring())
            end

            self.action_queue:push_action(skillchain_action, true)

            message = "Starting skillchain "..localization_util.translate(spell1).." > "..localization_util.translate(spell2).." = "..localization_util.translate(element)
        end
    end

    return success, message
end

-- // trust sch set [liquefaction|scission|reverberation|detontation|induration|impaction|transfixion|compression|fragmentation|fusion|gravitation|distortion]
function ScholarTrustCommands:handle_set_skillchain(_, element)
    local success
    local message

    element = windower.convert_auto_trans(element)
    local spell1, spell2 = self:get_spells(element)
    if spell1 and spell2 then
        local current_settings = self.weapon_skill_settings:getSettings()[state.WeaponSkillSettingsMode.value]
        if current_settings then
            for i = 1, current_settings.Skillchain.Gambits:length() do
                current_settings.Skillchain.Gambits[i] = Gambit.new(GambitTarget.TargetType.Enemy, L{}, SkillchainAbility.skip(), Condition.TargetType.Self, L{"Skillchain"})
            end
            current_settings.Skillchain.Gambits[1] = Gambit.new(GambitTarget.TargetType.Enemy, L{ StrategemCountCondition.new(2, Condition.Operator.GreaterThanOrEqualTo) }, ElementalMagic.new(spell1), Condition.TargetType.Self)
            current_settings.Skillchain.Gambits[2] = Gambit.new(GambitTarget.TargetType.Enemy, L{ StrategemCountCondition.new(1, Condition.Operator.GreaterThanOrEqualTo) }, ElementalMagic.new(spell2), Condition.TargetType.Self)

            success = true
            message = "Setting skillchain to "..localization_util.translate(spell1).." > "..localization_util.translate(spell2)

            self.weapon_skill_settings:saveSettings(true)
        end
    else
        success = false
        message = "No spells found to make skillchain of element "..(element or 'nil')
    end

    return success, message
end

-- // trust sch accession spell_name
function ScholarTrustCommands:handle_accession(_, spell_name)
    local success
    local message

    spell_name = windower.convert_auto_trans(spell_name)

    if not self:get_job():is_light_arts_active() then
        success = false
        message = "Unable to use Accession without Light Arts active"
    else
        if res.spells:with('en', spell_name) == nil then
            success = false
            message = "Invalid spell "..(spell_name or 'nil')
        else
            local spell = Spell.new(spell_name)

            local actions = L{}

            actions:append(StrategemAction.new('Accession'))
            actions:append(WaitAction.new(0, 0, 0, 2))
            actions:append(SpellAction.new(0, 0, 0, spell:get_spell().id, windower.ffxi.get_player().index, self.trust:get_player()))

            local accession_action = SequenceAction.new(actions, 'accession_'..spell_name, false)
            if not accession_action:can_perform() then
                success = false
                message = "Unable to use spell or insufficient strategems"
            else
                success = true
                message = "Using Accession + "..localization_util.translate(spell_name)

                self.action_queue:push_action(accession_action)
            end
        end
    end

    return success, message
end

-- // trust sch storm [fire|ice|wind|earth|lightning|water|light|dark] [true|false]
function ScholarTrustCommands:handle_storm(_, element, include_party)
    if not (self:get_job():is_light_arts_active() or self:get_job():is_dark_arts_active()) then
        return false, "Light Arts or Dark Arts must be active to use this command"
    end

    local success
    local message

    include_party = include_party ~= nil and tostring(include_party) == "true"

    local storm = self.trust:get_job():get_storm(element:lower())
    if storm then
        storm = Gambit.new(GambitTarget.TargetType.Self, L{}, storm, Condition.TargetType.Self, L{"Buffs"})

        success = true
        message = "Setting storm to "..storm:getAbility():get_spell().en

        local current_settings = self:get_settings()

        local update_storm = function(storm, gambits)
            local new_buffs = L{ storm }

            for gambit in gambits:it() do
                if not gambit:getAbility():get_name():contains('storm') or gambit:getAbilityTarget() ~= storm:getAbilityTarget() then
                    new_buffs:append(gambit)
                end
            end

            gambits:clear()
            gambits = gambits:extend(new_buffs)
        end

        update_storm(storm, current_settings.BuffSettings.Gambits)

        if include_party then
            local party_storm = self.trust:get_job():get_storm(element:lower())
            party_storm = Gambit.new(GambitTarget.TargetType.Ally, L{
                JobCondition.new(L{ 'BLM', 'RDM', 'GEO' }),
                NotCondition.new(L{ IsAlterEgoCondition.new() }),
            }, party_storm, Condition.TargetType.Ally, L{"Buffs"})
            update_storm(party_storm, current_settings.BuffSettings.Gambits)
        end

        if include_party then
            message = message.." for self and party"
        end

        self.trust_settings:saveSettings(true)
    else
        success = false
        message = "Invalid element "..(element or 'nil')
    end

    return success, message
end

function ScholarTrustCommands:get_all_commands()
    local result = TrustCommands.get_all_commands(self)

    for skillchain_property in skillchain_util.all_skillchain_properties():it() do
        if not skillchain_property:contains('Light') and not skillchain_property:contains('Dark') then
            result:append('// trust sch sc '..skillchain_property:lower())
            result:append('// trust sch set '..skillchain_property:lower())
        end
    end

    for element_name in L{ 'fire', 'ice', 'wind', 'earth', 'lightning', 'water', 'light', 'dark' }:it() do
        result:append('// trust sch storm '..element_name)
    end

    return result
end

return ScholarTrustCommands
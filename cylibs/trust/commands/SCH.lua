local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')
local skillchain_util = require('cylibs/util/skillchain_util')

local TrustCommands = require('cylibs/trust/commands/trust_commands')
local ScholarTrustCommands = setmetatable({}, {__index = TrustCommands })
ScholarTrustCommands.__index = ScholarTrustCommands
ScholarTrustCommands.__class = "ScholarTrustCommands"

function ScholarTrustCommands.new(trust, action_queue, trust_settings)
    local self = setmetatable(TrustCommands.new(), ScholarTrustCommands)

    self.trust = trust
    self.trust_settings = trust_settings
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
        return "Stone", "Fire"
    elseif element == "scission" then
        return "Aero", "Stone"
    elseif element == "reverberation" then
        return "Stone", "Water"
    elseif element == "detonation" then
        return "Stone", "Aero"
    elseif element == "induration" then
        return "Water", "Blizzard"
    elseif element == "impaction" then
        return "Water", "Thunder"
    elseif element == "transfixion" then
        return "Noctohelix", "Luminohelix"
    elseif element == "compression" then
        return "Blizzard", "Noctohelix"
    elseif element == "fragmentation" then
        return "Blizzard", "Water"
    elseif element == "fusion" then
        return "Fire", "Thunder"
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
                self.trust:get_party():add_to_chat(self.trust:get_party():get_player(), "**[Starting]** Skillchain "..spell1.." > "..spell2.." = "..element)
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

            message = "Starting skillchain "..spell1.." > "..spell2.." = "..element
        end
    end

    return success, message
end

-- // trust sch accession spell_name
function ScholarTrustCommands:handle_accession(_, spell_name)
    local success
    local message

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
                message = "Using Accession + "..spell_name
            end
        end
    end

    return success, message
end

-- // trust sch storm [fire|ice|wind|earth|lightning|water|light|dark] [true|false]
function ScholarTrustCommands:handle_storm(_, element, include_party)
    local success
    local message
    print(tostring(include_party))
    include_party = include_party ~= nil and tostring(include_party) == "true"

    local storm = self.trust:get_job():get_storm(element:lower())
    if storm then
        success = true
        message = "Setting storm to "..storm:get_spell().en

        local current_settings = self:get_settings()
        for arts_name in L{ 'LightArts', 'DarkArts' }:it() do

            local update_storm = function(storm, buffs)
                local new_buffs = L{ storm }

                for buff in buffs:it() do
                    if not buff:get_spell().en:contains('storm') then
                        new_buffs:append(buff)
                    end
                end

                buffs:clear()
                buffs = buffs:extend(new_buffs)
            end

            update_storm(storm, current_settings[arts_name].SelfBuffs)

            if include_party then
                local party_storm = self.trust:get_job():get_storm(element:lower())
                party_storm:set_job_names(L{'BLM','SCH','RDM','GEO'})
                update_storm(party_storm, current_settings[arts_name].PartyBuffs)
            end
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
        end
    end

    for element_name in L{ 'fire', 'ice', 'wind', 'earth', 'lightning', 'water', 'light', 'dark' }:it() do
        result:append('// trust sch storm '..element_name)
    end

    return result
end

return ScholarTrustCommands
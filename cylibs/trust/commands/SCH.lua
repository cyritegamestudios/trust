local TrustCommands = require('cylibs/trust/commands/trust_commands')
local ScholarTrustCommands = setmetatable({}, {__index = TrustCommands })
ScholarTrustCommands.__index = ScholarTrustCommands
ScholarTrustCommands.__class = "ScholarTrustCommands"

function ScholarTrustCommands.new(trust, action_queue)
    local self = setmetatable(TrustCommands.new(), ScholarTrustCommands)

    self.trust = trust
    self.action_queue = action_queue

    self:add_command('sc', self.handle_skillchain, 'Make a skillchain using immanence, // trust sch sc fusion')
    self:add_command('accession', self.handle_accession, 'Cast a spell with accession, // trust sch accession spell_name')

    return self
end

function ScholarTrustCommands:get_command_name()
    return 'sch'
end

function ScholarTrustCommands:get_job()
    return self.trust:get_job()
end

function ScholarTrustCommands:get_spells(element)
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
                    end, 'skillchain_'..spell:get_spell().name))
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
        if res.spells:with('name', spell_name) == nil then
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

return ScholarTrustCommands
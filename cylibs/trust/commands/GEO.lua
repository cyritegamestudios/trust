local TrustCommands = require('cylibs/trust/commands/trust_commands')
local GeomancerTrustCommands = setmetatable({}, {__index = TrustCommands })
GeomancerTrustCommands.__index = GeomancerTrustCommands
GeomancerTrustCommands.__class = "GeomancerTrustCommands"

function GeomancerTrustCommands.new(trust, action_queue, trust_settings)
    local self = setmetatable(TrustCommands.new(), GeomancerTrustCommands)

    self.trust = trust
    self.action_queue = action_queue
    self.trust_settings = trust_settings

    self:add_command('indi', self.handle_set_indi, 'Sets the indicolure spell')
    self:add_command('geo', self.handle_set_geo, 'Sets the geocolure spell')
    self:add_command('entrust', self.handle_set_entrust, 'Sets the entrust spell')

    return self
end

function GeomancerTrustCommands:get_command_name()
    return 'geo'
end

function GeomancerTrustCommands:get_localized_command_name()
    return 'Geomancer'
end

function GeomancerTrustCommands:get_settings()
    return self.trust_settings:getSettings()[state.MainTrustSettingsMode.value]
end

function GeomancerTrustCommands:get_job()
    return self.trust:get_job()
end

function GeomancerTrustCommands:handle_set_indi(_, ...)
    local success
    local message

    local spell_name = table.concat({...}, " ") or ""
    spell_name = windower.convert_auto_trans(spell_name)
    if spell_name:empty() then
        self:handle_set_mode('AutoIndiMode', 'Off')
        return true, message
    end

    if res.spells:with('en', spell_name) == nil then
        return false, string.format("%s is not a valid spell", spell_name or "unknown")
    end

    local current_settings = self:get_settings()
    current_settings.Geomancy.Indi = Spell.new(spell_name)

    success = true
    message = localization_util.translate(spell_name).." will now be used"

    return success, message
end

function GeomancerTrustCommands:handle_set_geo(_, ...)
    local success
    local message

    local spell_name = table.concat({...}, " ") or ""
    spell_name = windower.convert_auto_trans(spell_name)
    if spell_name:empty() then
        self:handle_set_mode('AutoGeoMode', 'Off')
        return true, message
    end

    if res.spells:with('en', spell_name) == nil then
        return false, string.format("%s is not a valid spell", spell_name or "unknown")
    end

    local validTargetsForSpell = function(spell_name)
        local spell = Spell.new(spell_name)
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

    local current_settings = self:get_settings()
    current_settings.Geomancy.Geo = Spell.new(spell_name, L{}, L{}, validTargetsForSpell(spell_name)[1])

    success = true
    message = localization_util.translate(spell_name).." will now be used"

    return success, message
end

function GeomancerTrustCommands:handle_set_entrust(_, ...)
    local success
    local message

    local spell_name = table.concat({...}, " ") or ""
    spell_name = windower.convert_auto_trans(spell_name)
    if spell_name:empty() then
        self:handle_set_mode('AutoEntrustMode', 'Off')
        return true, message
    end

    if res.spells:with('en', spell_name) == nil then
        return false, string.format("%s is not a valid spell", spell_name or "unknown")
    end

    local current_settings = self:get_settings()
    current_settings.Geomancy.Entrust = Spell.new(spell_name, L{"Entrust"}, L{}, nil, L{JobCondition.new(L{'WAR','WHM','RDM','PLD','BRD','SAM','DRG','BLU','PUP','SCH','RUN','MNK','BLM','THF','BST','RNG','NIN','SMN','COR','DNC','GEO','DRK'})})

    success = true
    message = localization_util.translate(spell_name).." will now be used with entrust (all jobs)"

    return success, message
end

return GeomancerTrustCommands
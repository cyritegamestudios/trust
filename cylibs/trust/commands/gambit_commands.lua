local Gambit = require('cylibs/gambits/gambit')
local GambitTarget = require('cylibs/gambits/gambit_target')
local localization_util = require('cylibs/util/localization_util')

local gambit_commands = {}

local TARGET_ALIASES = {
    self = { type = GambitTarget.TargetType.Self, targets = S{ 'Self' } },
    party = { type = GambitTarget.TargetType.Ally, targets = S{ 'Party', 'Corpse' } },
    ally = { type = GambitTarget.TargetType.Ally, targets = S{ 'Party', 'Corpse' } },
    enemy = { type = GambitTarget.TargetType.Enemy, targets = S{ 'Enemy' } },
}

local function join(items, separator)
    local result = ''
    for item in L(items):it() do
        result = result == '' and tostring(item) or result..separator..tostring(item)
    end
    return result
end

local function abilities_for(trust, targets)
    local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
    local success, sections = pcall(function()
        return GambitEditorStyle.getAbilitiesForTargets(nil, targets, trust)
    end)
    if not success or sections == nil then
        return L{}
    end
    return sections:flatten(false):compact_map()
end

local function ability_matches_name(ability, name)
    return ability:get_name() == name or ability.original_spell_name == name
end

function gambit_commands.parse_name_and_index(...)
    local args = L{}
    for _, arg in ipairs({ ... }) do
        args:append(tostring(arg))
    end
    if args:length() == 0 then
        return nil, nil
    end

    local index
    local last = args[args:length()]
    if args:length() > 1 and last:match('^%d+$') then
        index = tonumber(last)
        args:remove(args:length())
    end

    local name = windower.convert_auto_trans(join(args, ' '))
    return name ~= '' and name or nil, index
end

function gambit_commands.matches(gambits, name)
    local matches = L{}
    if gambits == nil or name == nil then
        return matches
    end

    for position = 1, gambits:length() do
        local entry = gambits[position]
        local ability = entry ~= nil and entry.getAbility and entry:getAbility()
        if ability ~= nil and ability_matches_name(ability, name) then
            matches:append({ gambit = entry, position = position })
        end
    end
    return matches
end

function gambit_commands.resolve(gambits, name, index, noun)
    local matches = gambit_commands.matches(gambits, name)
    if matches:length() == 0 then
        return nil, string.format('No %s is configured for %s', noun, name)
    end

    if index ~= nil then
        local match = matches:firstWhere(function(entry)
            return entry.position == index
        end)
        if match == nil then
            return nil, string.format('There is no %s for %s at position %d', noun, name, index)
        end
        return match, nil
    end

    if matches:length() > 1 then
        local positions = matches:map(function(entry)
            return tostring(entry.position)
        end)
        return nil, string.format('%d %ss are configured for %s, at %s. Add the position, for example: %s %d',
                matches:length(), noun, name, localization_util.commas(positions, 'and'),
                name, matches[1].position)
    end

    return matches[1], nil
end

function gambit_commands.register(commands, options)
    local noun = options.noun or 'rule'
    local allowed_targets = options.targets or L{ options.default_target }

    commands:add_command('list', function(self)
        return gambit_commands.handle_list(self, options, noun)
    end, string.format('List the configured %ss', noun))

    commands:add_command('add', function(self, _, ...)
        return gambit_commands.handle_add(self, options, noun, allowed_targets, ...)
    end, string.format('Add a %s, // trust %s add <ability> [%s]', noun,
            commands:get_command_name(), join(allowed_targets, '|')))

    commands:add_command('remove', function(self, _, ...)
        return gambit_commands.handle_remove(self, options, noun, ...)
    end, string.format('Remove a %s, // trust %s remove <ability>', noun,
            commands:get_command_name()))

    commands:add_command('enable', function(self, _, ...)
        return gambit_commands.handle_set_enabled(self, options, noun, true, ...)
    end, string.format('Enable a %s gambit', noun))

    commands:add_command('disable', function(self, _, ...)
        return gambit_commands.handle_set_enabled(self, options, noun, false, ...)
    end, string.format('Disable a %s gambit', noun))
end

function gambit_commands.handle_list(self, options, noun)
    local gambits = options.gambits(self)
    if gambits == nil then
        return false, string.format('This job has no %ss', noun)
    end
    if gambits:length() == 0 then
        return true, string.format('No %ss are configured.', noun)
    end

    for position = 1, gambits:length() do
        local entry = gambits[position]
        local ability = entry.getAbility and entry:getAbility()
        local label = ability and ability:get_name()
                or (entry.tostring and entry:tostring() or '?')
        addon_system_message(string.format('  %d. %-28s %s', position, label,
                entry:isEnabled() and '' or '(off)'))
    end

    return true, nil
end

function gambit_commands.handle_add(self, options, noun, allowed_targets, ...)
    local gambits = options.gambits(self)
    if gambits == nil then
        return false, string.format('This job has no %ss', noun)
    end

    local args = L{}
    for _, arg in ipairs({ ... }) do
        args:append(tostring(arg))
    end

    local target = options.default_target
    if args:length() > 1 and TARGET_ALIASES[args[args:length()]:lower()] ~= nil then
        target = args[args:length()]:lower()
        args:remove(args:length())
    end
    if not L(allowed_targets):contains(target) then
        return false, string.format('%s cannot target %s. Try: %s', noun, target,
                localization_util.commas(L(allowed_targets), 'or'))
    end

    local name = windower.convert_auto_trans(join(args, ' '))
    if name == '' then
        return false, string.format('Usage: // trust %s add <ability> [%s]',
                self:get_command_name(), join(allowed_targets, '|'))
    end
    if gambit_commands.matches(gambits, name):length() > 0 then
        return false, string.format('A %s for %s already exists. Use enable, or remove it first',
                noun, name)
    end

    local target_alias = TARGET_ALIASES[target]
    local ability = abilities_for(options.trust, target_alias.targets):firstWhere(function(candidate)
        return candidate:get_name() == name
    end)
    if ability == nil then
        return false, string.format('%s is not an ability this job can use on a %s target',
                name, target)
    end

    gambits:append(Gambit.new(target_alias.type, L{}, ability, target_alias.type))
    options.save(self)

    return true, string.format('%s added as a %s on %s.', name, noun, target)
end

function gambit_commands.handle_remove(self, options, noun, ...)
    local gambits = options.gambits(self)
    if gambits == nil then
        return false, string.format('This job has no %ss', noun)
    end

    local name, index = gambit_commands.parse_name_and_index(...)
    if name == nil then
        return false, string.format('Usage: // trust %s remove <ability>', self:get_command_name())
    end

    local match, message = gambit_commands.resolve(gambits, name, index, noun)
    if match == nil then
        return false, message
    end

    gambits:remove(match.position)
    options.save(self)
    return true, string.format('%s removed.', name)
end

function gambit_commands.handle_set_enabled(self, options, noun, enabled, ...)
    local gambits = options.gambits(self)
    if gambits == nil then
        return false, string.format('This job has no %ss', noun)
    end

    local name, index = gambit_commands.parse_name_and_index(...)
    if name == nil then
        return false, string.format('Usage: // trust %s %s <ability>', self:get_command_name(),
                enabled and 'enable' or 'disable')
    end

    local match, message = gambit_commands.resolve(gambits, name, index, noun)
    if match == nil then
        return false, message
    end

    match.gambit:setEnabled(enabled)
    options.save(self)
    return true, string.format('%s %s.', name, enabled and 'enabled' or 'disabled')
end

return gambit_commands

local GameCommand = {}
GameCommand.__index = GameCommand
GameCommand.__type = "GameCommand"

-------
-- Default initializer for a new game command.
-- @tparam string prefix Command prefix (e.g. /ra, /magic)
-- @tparam number targetId Target of the command
-- @treturn GameCommand A game command
function GameCommand.new(prefix, targetId)
    local self = setmetatable({}, GameCommand)

    self.prefix = prefix
    self.targetId = targetId

    return self
end

-------
-- Returns the target of the command.
-- @treturn tuple Target id and index
function GameCommand:getTargetInfo()
    local target = windower.ffxi.get_mob_by_id(self.targetId)
    if target then
        return target.id, target.index
    end
    return nil, nil
end

-------
-- Returns the text to send to chat to run the command.
-- @tparam string prefix Command prefix (e.g. /ra, /magic)
-- @tparam string abilityName Name of spell, job ability, etc
-- @tparam number targetId Target of the command
-- @treturn string Localized command
function GameCommand:getInputText(prefix, abilityName, targetId)
    if abilityName then
        if i18n.current_locale() == i18n.Locale.Japanese then
            return windower.to_shift_jis(string.format("%s %s %d", prefix, abilityName, targetId))
        else
            return string.format("%s \"%s\" %d", prefix, abilityName, targetId)
        end
    else
        if i18n.current_locale() == i18n.Locale.Japanese then
            return windower.to_shift_jis(string.format("%s %d", prefix, targetId))
        else
            return string.format("%s %d", prefix, targetId)
        end
    end
end

-------
-- Runs the command. If `sendInChat` is true, the command will be run by
-- inputting the command text into the chat. If false, the packet will
-- be sent directly instead.
-- @tparam boolean sendInChat Whether to run the command in the chat
function GameCommand:run(sendInChat)
end

return GameCommand
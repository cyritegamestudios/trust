local GameCommand = {}
GameCommand.__index = GameCommand
GameCommand.__type = "GameCommand"

function GameCommand.new(prefix, targetId)
    local self = setmetatable({}, GameCommand)

    self.prefix = prefix
    self.targetId = targetId

    return self
end

function GameCommand:getTargetInfo()
    local target = windower.ffxi.get_mob_by_id(self.targetId)
    if target then
        return target.id, target.index
    end
    return nil, nil
end

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

function GameCommand:run(sendInChat)
end

return GameCommand
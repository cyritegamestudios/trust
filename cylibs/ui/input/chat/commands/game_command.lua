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

function GameCommand:run(sendInChat)
end

return GameCommand
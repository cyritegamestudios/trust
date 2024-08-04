local ModeDelta = {}
ModeDelta.__index = ModeDelta

function ModeDelta.new(newModes)
    local self = setmetatable({}, ModeDelta)

    self.newModes = newModes
    self.oldModes = {}
    self.isApplied = false

    return self
end

function ModeDelta:apply(hideHelpText)
    if self.isApplied then
        return
    end
    self.isApplied = true
    for stateName, value in pairs(self.newModes) do
        local stateVar = get_state(stateName)
        if stateVar then
            self.oldModes[stateName] = stateVar.value
            stateVar:set(value, hideHelpText)
        end
    end
end

function ModeDelta:remove(hideHelpText)
    if not self.isApplied then
        return
    end
    self.isApplied = false
    for stateName, _ in pairs(self.oldModes) do
        local stateVar = get_state(stateName)
        if stateVar and self.oldModes[stateName] then
            stateVar:set(self.oldModes[stateName], hideHelpText)
        end
    end
    self.oldModes = {}
end

function ModeDelta:destroy()
    self:remove()
end

return ModeDelta
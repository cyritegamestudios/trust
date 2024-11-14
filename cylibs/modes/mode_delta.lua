local DisposeBag = require('cylibs/events/dispose_bag')

local ModeDelta = {}
ModeDelta.__index = ModeDelta

function ModeDelta.new(newModes, errorMessage, whitelist)
    local self = setmetatable({}, ModeDelta)

    self.newModes = newModes
    self.oldModes = {}
    self.isApplied = false
    self.errorMessage = errorMessage or "You cannot change modes at this time."
    self.whitelist = whitelist or S{}
    self.disposeBag = DisposeBag.new()

    return self
end

function ModeDelta:apply(hideHelpText)
    if self.isApplied then
        return
    end
    self.isApplied = true
    --set_modes_locked(true, self.errorMessage, self.whitelist)
    for stateName, value in pairs(self.newModes) do
        local stateVar = get_state(stateName)
        if stateVar then
            self.oldModes[stateName] = stateVar.value
            stateVar:set(value, hideHelpText)
        end
    end
    self.disposeBag:dispose()
    self.disposeBag:add(on_state_changed():addAction(function(modeName, modeValue)
        self.oldModes[modeName] = modeValue
        addon_system_error(self.errorMessage)
    end), on_state_changed())
end

function ModeDelta:remove(hideHelpText)
    if not self.isApplied then
        return
    end
    self.isApplied = false
    --set_modes_locked(false)
    for stateName, _ in pairs(self.oldModes) do
        local stateVar = get_state(stateName)
        if stateVar and self.oldModes[stateName] then
            stateVar:set(self.oldModes[stateName], hideHelpText)
        end
    end
    self.oldModes = {}
    self.disposeBag:dispose()
end

function ModeDelta:destroy()
    self:remove()
end

return ModeDelta
local DisposeBag = {}
DisposeBag.__index = DisposeBag

---
-- Creates a new DisposeBag instance.
--
-- @treturn DisposeBag The newly created DisposeBag instance.
--
function DisposeBag.new()
    local self = setmetatable({}, DisposeBag)

    self.eventMap = T{}
    self.destroyables = L{}

    return self
end

---
-- Calls dispose().
--
function DisposeBag:destroy()
    self:dispose()

    for destroyable in self.destroyables:it() do
        destroyable:destroy()
    end
end

---
-- Removes all actions from Luvents added using DisposeBag:add(event, actionId).
--
function DisposeBag:dispose()
    for actionId, event in pairs(self.eventMap) do
        event:removeAction(actionId)
    end
    self.eventMap = T{}
end

---
-- Adds an actionId and an associated event to the DisposeBag.
--
-- @tparam number actionId The identifier for the action.
-- @tparam Luvent event The event or object associated with the action.
--
function DisposeBag:add(actionId, event)
    if self.eventMap[actionId] then
        return
    end
    self.eventMap[actionId] = event
end

---
-- Adds a list of destroyable items to the DisposeBag.
--
-- @param destroyables A list of destroyable items to add.
--
function DisposeBag:addAny(destroyables)
    for destroyable in destroyables:it() do
        self.destroyables:append(destroyable)
    end
end

return DisposeBag

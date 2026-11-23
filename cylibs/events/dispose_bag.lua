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

    -- Snapshot and clear before destroying: a destroyable's destroy()
    -- can re-enter this bag (directly, or by triggering an event whose
    -- handler destroys this bag again), which previously destroyed
    -- the same entries a second time. Entries added during the loop
    -- (some owners reuse the bag as a reset, adding fresh entries
    -- right after destroy()) land in the new list and survive.
    local destroyables = {}
    for destroyable in self.destroyables:it() do
        destroyables[#destroyables + 1] = destroyable
    end
    self.destroyables = L{}

    local seen = {}
    for _, destroyable in ipairs(destroyables) do
        if not seen[destroyable] then
            seen[destroyable] = true
            if destroyable.destroy then
                destroyable:destroy()
            end
        end
    end
end

---
-- Removes all actions from Luvents added using DisposeBag:add(event, actionId).
--
function DisposeBag:dispose()
    -- Clear the map before removing actions: removeAction can trigger
    -- code that re-enters this bag, and an error partway through the
    -- old loop left the remaining entries registered forever.
    local entries = {}
    for _, entry in pairs(self.eventMap) do
        entries[#entries + 1] = entry
    end
    self.eventMap = T{}

    for _, entry in ipairs(entries) do
        if entry.event and entry.actionId and entry.event.removeAction then
            entry.event:removeAction(entry.actionId)
        end
    end
end

---
-- Adds an actionId and an associated event to the DisposeBag.
--
-- @tparam number actionId The identifier for the action.
-- @tparam Luvent event The event or object associated with the action.
--
function DisposeBag:add(actionId, event)
    -- A nil actionId (addAction on an already-registered action used
    -- to return nil) or a nil event (a number of call sites pass only
    -- the actionId, the event argument having landed inside the
    -- addAction call) cannot ever be removed: storing it made
    -- dispose() error on entry.event:removeAction() and abort the
    -- owner's whole destroy cascade. Skip it instead.
    if actionId == nil or event == nil then
        return
    end
    local key = tostring(event)..":"..tostring(actionId)
    if self.eventMap[key] then
        return
    end
    self.eventMap[key] = { event = event, actionId = actionId }
end

---
-- Adds a list of destroyable items to the DisposeBag.
--
-- @param destroyables A list of destroyable items to add.
--
function DisposeBag:addAny(destroyables)
    if destroyables == nil then
        return
    end
    for destroyable in destroyables:it() do
        if destroyable ~= nil then
            self.destroyables:append(destroyable)
        end
    end
end

return DisposeBag

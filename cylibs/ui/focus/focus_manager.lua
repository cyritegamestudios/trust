local FocusManager = {}
FocusManager.__index = FocusManager
FocusManager.__type = "FocusManager"

---
-- Returns a shared focus manager.
--
-- @treturn FocusManager The shared focus manager.
--
local focusManager
function FocusManager.shared()
    if not focusManager then
        focusManager = FocusManager.new()
    end
    return focusManager
end

---
-- Creates a new FocusManager.
--
-- @treturn TextItem The newly created FocusManager instance.
--
function FocusManager.new()
    local self = setmetatable({}, FocusManager)
    self.focusStack = L{}
    return self
end

---
-- Requests focus for the given `focusable`.
--
-- @tparam table focusable The object to request focus for
--
-- @treturn boolean Whether or not the object successfully focused.
--
function FocusManager:requestFocus(focusable)
    for parentFocusable in self.focusStack:it() do
        if parentFocusable == focusable then
            return false
        end
    end

    local currentFocusable = self.focusStack:last()
    if currentFocusable then
        if not currentFocusable:shouldResignFocus() or currentFocusable == focusable then
            return false
        end
        currentFocusable:setHasFocus(false)
    end

    self.focusStack:append(focusable)
    focusable:setHasFocus(true)
    return true
end

---
-- Resigns focus from the given `focusable` to the previous focusable
-- that had focus.
--
-- @tparam table focusable The object to resign focus from
--
function FocusManager:resignFocus(focusable)
    local currentFocusable = self.focusStack:last()
    if currentFocusable == focusable and currentFocusable:shouldResignFocus() then
        self.focusStack:remove(self.focusStack:length())
        currentFocusable:setHasFocus(false)

        currentFocusable = self.focusStack:last()
        if currentFocusable then
            currentFocusable:setHasFocus(true)
        end
    end
end

function FocusManager:resignAllFocus()
    local currentFocusable = self.focusStack:last()
    while currentFocusable do
        self.focusStack:remove(self.focusStack:length())
        currentFocusable:setHasFocus(false)
        currentFocusable = self.focusStack:last()
    end
end

function FocusManager:getFocusable()
    return self.focusStack:last()
end

return FocusManager
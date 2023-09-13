local DisposeBag = require('cylibs/events/dispose_bag')
local Monster = require('cylibs/battle/monster')

local ResistTracker = {}
ResistTracker.__index = ResistTracker

function ResistTracker.new(monster)
    local self = setmetatable({}, ResistTracker)

    self.monster = monster
    self.spellResists = {}
    self.blacklist = S{} -- monster is immune to these spells
    self.disposeBag = DisposeBag.new()

    self.disposeBag:add(monster:on_spell_resisted():addAction(
            function(_, spell_name, is_complete_resist)
                local spell = res.spells:with('name', spell_name)
                if spell then
                    if is_complete_resist then
                        self.blacklist:add(spell.id)
                    else
                        local currentNumResists = self.spellResists[spell.id] or 0
                        self.spellResists[spell.id] = currentNumResists + 1
                    end
                end
            end),
    monster:on_spell_resisted())

    return self
end

function ResistTracker:destroy()
    self.disposeBag:destroy()
end

---
-- Returns the number of times a spell has been resisted. Excludes complete resists.
--
-- @tparam number spellId The ID of the spell.
-- @treturn number The number of resistances for the specified spell.
--
function ResistTracker:numResists(spellId)
    if self.blacklist:contains(spellId) then
        return 999
    end
    return self.spellResists[spellId] or 0
end

---
-- Checks if a spell is on the blacklist, indicating immunity.
--
-- @tparam number spellId The ID of the spell.
-- @treturn boolean Returns true if the spell is on the blacklist, indicating immunity.
--
function ResistTracker:isImmune(spellId)
    return self.blacklist:contains(spellId)
end

---
-- Resets the spell resist tracker, clearing all recorded resist counts and the blacklist.
--
function ResistTracker:reset()
    self.spell_resists = {}
    self.blacklist = S{}
end

return ResistTracker
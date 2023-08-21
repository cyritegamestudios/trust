---------------------------
-- Action representing a cure.
-- @class module
-- @name CureAction

require('vectors')
require('math')
require('logger')
require('lists')

local Action = require('cylibs/actions/action')
local CureAction = setmetatable({}, {__index = Action })
CureAction.__index = CureAction

function CureAction.new(x, y, z, party_member, cure_threshold, healer_job, player)
    local self = setmetatable(Action.new(x, y, z), CureAction)

    self.party_member = party_member
    self.cure_threshold = cure_threshold
    self.healer_job = healer_job
    self.player = player

    self.user_events = {}

    self:debug_log_create(self:gettype())

    return self
end

function CureAction:destroy()
    if self.user_events then
        for _,event in pairs(self.user_events) do
            windower.unregister_event(event)
        end
    end

    if self.spell_finish_id then
        self.player:on_spell_finish():removeAction(self.spell_finish_id)
    end
    if self.spell_interrupted_id then
        self.player:on_spell_interrupted():removeAction(self.spell_interrupted_id)
    end

    self.player = nil

    self:debug_log_destroy(self:gettype())

    Action.destroy(self)
end

function CureAction:can_perform()
    if not spell_util.can_cast_spells() then
        return false
    end

    local target = self.party_member:get_mob()
    if target and target.distance:sqrt() > 21 then
        return false
    end

    local spell = res.spells:with('id', self.spell_id)
    if spell and windower.ffxi.get_player().vitals.mp > spell.mp_cost then
        return true
    end

    return true
end

function CureAction:get_cure_spell()
    local hp_missing = self.party_member:get_max_hp() - self.party_member:get_hp()

    return self.healer_job:get_cure_spell(hp_missing)
end

function CureAction:perform()
    if self:is_cancelled() then
        self:complete(false)
        return
    end

    -- Party member has already been cured
    if self.party_member:get_hpp() > self.cure_threshold then
        self:complete(false)
        return
    end

    windower.ffxi.run(false)

    local cure_spell = self:get_cure_spell()
    if not cure_spell then
        self:complete(false)
        return
    end

    if not spell_util.can_cast_spell(cure_spell:get_spell().id) then
        self:complete(false)
        return
    end

    local target = self.party_member:get_mob()

    self.spell_finish_id = self.player:on_spell_finish():addAction(
            function(p, spell_id, targets)
                if p:get_mob().id == windower.ffxi.get_player().id then
                    if spell_id == cure_spell:get_spell().id then
                        self:complete(true)
                    end
                end
            end)

    self.spell_interrupted_id = self.player:on_spell_interrupted():addAction(
            function(p, spell_id)
                if p:get_mob().id == windower.ffxi.get_player().id then
                    if spell_id == cure_spell:get_spell().id then
                        self:complete(false)
                    end
                end
            end)

    windower.send_command('@input /ma "'..cure_spell:get_spell().name..'" '..target.id)
end

function CureAction:getspellid()
    return self.spell_id
end

function CureAction:gettargetindex()
    return self.target_index
end

function CureAction:gettype()
    return "cureaction"
end

function CureAction:getrawdata()
    local res = {}

    res.statusremovalaction = {}
    res.statusremovalaction.x = self.x
    res.statusremovalaction.y = self.y
    res.statusremovalaction.z = self.z

    return res
end

function CureAction:getidentifier()
    return self.spell_id
end


function CureAction:copy()
    return CureAction.new(self:get_position()[1], self:get_position()[2], self:get_position()[3])
end

function CureAction:is_equal(action)
    if action == nil then return false end
    return self:gettype() == action:gettype()
            and self:getspellid() == action:getspellid()
            and self:gettargetindex() == action:gettargetindex()
end

function CureAction:tostring()
    local cure_spell = self:get_cure_spell()
    local target = windower.ffxi.get_mob_by_id(self.party_member:get_id() or windower.ffxi.get_player().id)
    return cure_spell:get_spell().en..' → '..target.name
end

function CureAction:debug_string()
    return "CureAction: (%d, %d, %d)":format(self.x, self.y, self.z)
end

return CureAction




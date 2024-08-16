---------------------------
-- Action representing a cure.
-- @class module
-- @name CureAction

local DisposeBag = require('cylibs/events/dispose_bag')

local spell_util = require('cylibs/util/spell_util')

local Action = require('cylibs/actions/action')
local CureAction = setmetatable({}, {__index = Action })
CureAction.__index = CureAction

function CureAction.new(x, y, z, party_member, cure_threshold, mp_cost, healer_job, player, party)
    local conditions = L{
        HitPointsPercentRangeCondition.new(1, cure_threshold, party_member:get_mob().index),
        MaxDistanceCondition.new(20),
        NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror', 'mute'}, 1)}, windower.ffxi.get_player().index),
        MinManaPointsCondition.new(mp_cost, windower.ffxi.get_player().index),
        ValidTargetCondition.new(alter_ego_util.untargetable_alter_egos()),
    }

    local self = setmetatable(Action.new(x, y, z, party_member:get_mob().index, conditions), CureAction)

    self.party_member = party_member
    self.cure_threshold = cure_threshold
    self.healer_job = healer_job
    self.player = player
    self.party = party
    self.dispose_bag = DisposeBag.new()

    self:debug_log_create(self:gettype())

    return self
end

function CureAction:destroy()
    self.dispose_bag:destroy()

    self.player = nil
    self.party = nil

    self:debug_log_destroy(self:gettype())

    Action.destroy(self)
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

    windower.ffxi.run(false)

    local cure_spell = self:get_cure_spell()
    if not cure_spell then
        self:complete(false)
        return
    end

    if not spell_util.can_cast_spell(cure_spell:get_spell().id) then
        self.party:add_to_chat(self.party:get_player(), "Hold on a second, I'm having a hard time keeping up with cures.", "cure_action_no_cast", 30)
        self:complete(false)
        return
    end

    self.dispose_bag:add(self.player:on_spell_finish():addAction(
            function(p, spell_id, _)
                if p:get_mob().id == windower.ffxi.get_player().id then
                    if spell_id == cure_spell:get_spell().id then
                        self:complete(true)
                    end
                end
            end), self.player:on_spell_finish())

    self.dispose_bag:add(self.player:on_spell_interrupted():addAction(
            function(p, spell_id)
                if p:get_mob().id == windower.ffxi.get_player().id then
                    if spell_id == cure_spell:get_spell().id then
                        self:complete(false)
                    end
                end
            end), self.player:on_spell_interrupted())

    windower.chat.input(self:localize(cure_spell:get_spell().id))
end

function CureAction:localize(spell_id)
    local target = self.party_member:get_mob()

    local spell = res.spells[spell_id]
    if spell then
        local spell_name = spell.en
        if localization_util.should_use_client_locale() then
            spell_name = localization_util.encode(spell.name, windower.ffxi.get_info().language:lower())
        end
        if windower.ffxi.get_info().language:lower() == 'japanese' then
            return "/ma %s ":format(spell_name)..target.id
        else
            return '/ma "%s" ':format(spell_name)..target.id
        end
    end
    return ""
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




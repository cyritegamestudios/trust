---------------------------
-- Action representing a ranged attack
-- @class module
-- @name RangedAttack

local Action = require('cylibs/actions/action')
local RangedAttack = setmetatable({}, {__index = Action })
RangedAttack.__index = RangedAttack
RangedAttack.__eq = RangedAttack.is_equal
RangedAttack.__class = "RangedAttack"

local DisposeBag = require('cylibs/events/dispose_bag')
local packets = require('packets')

function RangedAttack.new(target_index, player)
    local conditions = L{
        NotCondition.new(L{InMogHouseCondition.new()}),
        NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror'}, 1)}, windower.ffxi.get_player().index),
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), RangedAttack)

    self.player = player
    self.dispose_bag = DisposeBag.new()

    self:debug_log_create(self:gettype())

    return self
end

function RangedAttack:destroy()
    Action.destroy(self)

    self.dispose_bag:destroy()

    self:debug_log_destroy(self:gettype())
end

function RangedAttack:perform()
    self.dispose_bag:add(self.player:on_ranged_attack_end():addAction(function()
        self:complete(true)
    end), self.player:on_ranged_attack_end())

    self.dispose_bag:add(self.player:on_ranged_attack_interrupted():addAction(function()
        self:complete(false)
    end), self.player:on_ranged_attack_interrupted())

    local target = windower.ffxi.get_mob_by_index(self.target_index)
    if target.index == windower.ffxi.get_player().target_index then
        windower.chat.input('/ra <t>')
    else
        local p = packets.new('outgoing', 0x01a, {
            ["Target"] = target.id,
            ["Target Index"] = target.index,
            ["Category"] = 16,
            ["Param"] = 0,
            ["_unknown1"] = 0,
        })
        packets.inject(p)
    end
end

function RangedAttack:gettype()
    return "rangedattackaction"
end

function RangedAttack:is_equal(action)
    if action == nil then return false end

    return self:gettype() == action:gettype() and self.target_index == action.target_index
end

function RangedAttack:tostring()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    return 'Ranged Attack → '..target.name
end

function RangedAttack:debug_string()
    local target = windower.ffxi.get_mob_by_index(self.target_index)
    return "RangedAttack: %s":format(target.name)
end

return RangedAttack
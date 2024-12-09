---------------------------
-- Action representing a ranged attack
-- @class module
-- @name RangedAttack

local DisposeBag = require('cylibs/events/dispose_bag')
local RangedAttackCommand = require('cylibs/ui/input/chat/commands/ranged_attack')

local Action = require('cylibs/actions/action')
local RangedAttack = setmetatable({}, {__index = Action })
RangedAttack.__index = RangedAttack
RangedAttack.__eq = RangedAttack.is_equal
RangedAttack.__class = "RangedAttack"

function RangedAttack.new(target_index, player, ranged_attack_duration)
    local conditions = L{
        NotCondition.new(L{InMogHouseCondition.new()}),
        NotCondition.new(L{HasBuffsCondition.new(L{'sleep', 'petrification', 'charm', 'terror'}, 1)}, windower.ffxi.get_player().index),
    }
    local self = setmetatable(Action.new(0, 0, 0, target_index, conditions), RangedAttack)

    self.ranged_attack_duration = ranged_attack_duration
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

    local target = windower.ffxi.get_mob_by_index(self.target_index) or windower.ffxi.get_mob_by_target('bt')

    local command = RangedAttackCommand.new('/ra', target.id)
    command:run(true)
end

function RangedAttack:gettype()
    return "rangedattackaction"
end

function RangedAttack:get_max_duration()
    return self.ranged_attack_duration or 5
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
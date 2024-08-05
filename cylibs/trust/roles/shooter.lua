local DisposeBag = require('cylibs/events/dispose_bag')
local Renderer = require('cylibs/ui/views/render')

local Shooter = setmetatable({}, {__index = Role })
Shooter.__index = Shooter
Shooter.__class = "Shooter"

local RangedAttackAction = require('cylibs/actions/ranged_attack')

state.AutoShootMode = M{['description'] = 'Auto Shoot Mode', 'Off', 'Auto', 'Manual'}
state.AutoShootMode:set_description('Auto', "Okay, I'll automatically shoot at the enemy.")
state.AutoShootMode:set_description('Manual', "Okay, I'll keep shooting once started until I've got TP.")

function Shooter.new(action_queue, shoot_delay)
    local self = setmetatable(Role.new(action_queue), Shooter)

    self.ranged_attack_action_identifier = self.__class..'_ranged_attack'
    self.total_shot_time = 1.5
    self.num_shots = 1
    self.ranged_attack_delay = shoot_delay or 1.3
    self.ranged_attack_max_tp = 1000
    self.last_shot = os.clock()
    self.last_shoot_time = os.clock()
    self.dispose_bag = DisposeBag.new()

    self.action_events = {}

    return self
end

function Shooter:destroy()
    Role.destroy(self)
end

function Shooter:on_add()
    Role.on_add(self)

    self.dispose_bag:add(self.action_queue:on_action_start():addAction(function(_, a)
        if a:getidentifier() == self.ranged_attack_action_identifier then
            self.is_shooting = true
            logger.notice(self.__class, 'ranged_attack_start')
        end
    end), self.action_queue:on_action_start())

    self.dispose_bag:add(self.action_queue:on_action_end():addAction(function(a, _)
        if a:getidentifier() == self.ranged_attack_action_identifier then
            self.is_shooting = false
            logger.notice(self.__class, 'ranged_attack_end')
        end
    end), self.action_queue:on_action_end())

    self.dispose_bag:add(self.player:on_ranged_attack_begin():addAction(function()
        self.last_shot = os.clock()
    end), self.player:on_ranged_attack_begin())

    self.dispose_bag:add(self.player:on_ranged_attack_end():addAction(function()
        local delta = os.clock() - self.last_shot
        self.total_shot_time = self.total_shot_time + delta
        self.num_shots = self.num_shots + 1
        self.last_shoot_time = os.clock()
    end), self.player:on_ranged_attack_end())

    self:get_player():on_weapon_skill_finish():addAction(
            function (_, _)
                self.last_shoot_time = os.clock()
                self.action_queue:push_action(WaitAction.new(0, 0, 0, 2.0), true)
            end)

    self.dispose_bag:add(Renderer.shared():onPrerender():addAction(function()
        if self:get_target() == nil then
            return
        end
        if L{ 'Auto', 'Manual' }:contains(state.AutoShootMode.value) and not self.is_shooting and (os.clock() - self.last_shoot_time) > self.ranged_attack_delay then
            if windower.ffxi.get_player().vitals.tp < self.ranged_attack_max_tp then
                logger.notice(self.__class, 'onPrerender', 'restarting', os.clock() - self.last_shoot_time)
                self:ranged_attack()
            end
        elseif self.is_shooting and os.time() - self.last_shoot_time > 8 then
            self.is_shooting = false
        end
    end), Renderer.shared():onPrerender())
end

function Shooter:ranged_attack()
    local target = self:get_target()
    if not target or not party_util.party_claimed(target:get_id()) then
        return
    end
    logger.notice(self.__class, 'ranged_attack', 'average shot time', self.total_shot_time / self.num_shots)

    self.action_queue:cleanup()

    self.last_shoot_time = os.clock()

    local actions = L{
        RangedAttackAction.new(target:get_mob().index, self:get_player()),
    }
    local ranged_attack_action = SequenceAction.new(actions, self.ranged_attack_action_identifier)
    ranged_attack_action.max_duration = 1.25 * self:get_average_shot_time()
    ranged_attack_action.display_name = "Ranged Attack"

    self.action_queue:push_action(ranged_attack_action, true)
end

function Shooter:target_change(target_index)
    Role.target_change(self, target_index)

    logger.notice(self.__class, 'target_change', 'reset')

    self.is_shooting = false
    self.total_shot_time = 2
    self.num_shots = 1
end

function Shooter:get_average_shot_time()
    return math.max(self.total_shot_time / self.num_shots, 1.05)
end

function Shooter:set_shoot_delay(delay)
    self.ranged_attack_delay = delay
end

function Shooter:allows_duplicates()
    return false
end

function Shooter:get_type()
    return "shooter"
end

return Shooter
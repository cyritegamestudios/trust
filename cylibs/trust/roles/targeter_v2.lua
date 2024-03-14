local Targeter = setmetatable({}, {__index = Role })
Targeter.__index = Targeter
Targeter.__class = "Targeter"

local DisposeBag = require('cylibs/events/dispose_bag')
local SwitchTargetAction = require('cylibs/actions/switch_target')

state.AutoTargetMode = M{['description'] = 'Auto Target Mode', 'Off', 'Auto', 'Same', 'Party'}
state.AutoTargetMode:set_description('Auto', "Okay, I'll automatically target a new monster after we defeat one.")
state.AutoTargetMode:set_description('Party', "Okay, I'll automatically target monsters on the party's hate list.")

function Targeter.new(action_queue)
    local self = setmetatable(Role.new(action_queue), Targeter)

    self.action_queue = action_queue
    self.last_checked_targets = os.time()
    self.target_dispose_bag = DisposeBag.new()

    self.dispose_bag = DisposeBag.new()
    self.dispose_bag:addAny(L{ self.target_dispose_bag })

    return self
end

function Targeter:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Targeter:on_add()
    state.AutoTargetMode:on_state_change():addAction(function(_, new_value)
        if new_value ~= 'Off' then
            windower.send_command('input /autotarget off')
        end
    end)
end

function Targeter:target_mob(target)
    self.action_queue:clear()

    local target_action = SwitchTargetAction.new(target.index, 5)
    target_action.priority = ActionPriority.high

    self.action_queue:push_action(target_action, true)

    windower.send_command('input /echo Auto targeting '..target.name..'.')
end

function Targeter:target_change(target_index)
    Role.target_change(self, target_index)

    self.target_dispose_bag:dispose()

    local target = self:get_target()
    if target then
        self.target_dispose_bag:add(target:on_ko():addAction(function(_)
            self:check_target(true)
        end), target:on_ko())
    end
end

function Targeter:tic(new_time, old_time)
    Role.tic(self, new_time, old_time)

    if self:should_auto_target() then
        self:check_target(player.status == 'Idle')
    end
end

function Targeter:check_target(override_current_target)
    if state.AutoTargetMode.value == 'Off' or (not override_current_target and os.time() - self.last_checked_targets < 3) then
        return
    end
    self.last_checked_targets = os.time()

    local current_target = self:get_target()
    if not override_current_target and current_target then
        return
    end

    logger.notice(self.__class, 'check_target')

    local targets = self:get_all_targets()
    if targets:length() > 0 then
        logger.notice(self.__class, 'check_target', 'found', targets[1].name, targets[1].distance:sqrt())
        local next_target = targets:firstWhere(function(target)
            return target and not party_util.party_targeted(target.id)
        end) or targets[1]
        self:target_mob(next_target)
    else
        logger.notice(self.__class, 'check_target', 'no targets')
        self:get_party():add_to_chat(self.party:get_player(), "There's nothing for me to auto target.", self.__class..'no_target', 20, true)
    end
end

function Targeter:get_all_targets()
    if state.AutoTargetMode.value == 'Auto' then
        local target = ffxi_util.find_closest_mob(L{}, L{}:extend(party_util.party_targets()))
        if target and target.distance:sqrt() < 25 then
            return L{ target }
        end
    end
    local targets = self:get_party():get_targets(function(target)
        return target:get_distance():sqrt() < 18 and target:get_mob().status == 1
    end):map(function(target) return target:get_mob() end)
    return targets
end

function Targeter:should_auto_target()
    if state.AutoTargetMode.value == 'Party' then
        return true
    end
    return false
end

function Targeter:allows_duplicates()
    return false
end

function Targeter:get_type()
    return "targeter"
end

return Targeter

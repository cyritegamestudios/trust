local DisposeBag = require('cylibs/events/dispose_bag')

local Assistant = setmetatable({}, {__index = Role })
Assistant.__index = Assistant
Assistant.__class = "Assistant"

state.AutoAssistantMode = M{['description'] = 'Assistant Mode', 'Off', 'Auto'}
state.AutoAssistantMode:set_description('Auto', "See extra information on the current mob.")

function Assistant.new(action_queue, watch_list)
    local self = setmetatable(Role.new(action_queue), Assistant)

    self.watch_list = watch_list or S{}
    self.dispose_bag = DisposeBag.new()

    return self
end

function Assistant:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Assistant:on_add()
    Role.on_add(self)

    self:add_ability_name('Uproot')
end

function Assistant:target_change(target_index)
    Role.target_change(self, target_index)

    logger.notice(self.__class, 'target_change', 'reset')

    self.dispose_bag:dispose()

    if self:get_target() then
        self.dispose_bag:add(self:get_target():on_tp_move_finish():addAction(function(m, monster_ability_name, _, _)
            if state.AutoAssistantMode.value == 'Off' then
                return
            end
            if self.watch_list:contains(monster_ability_name) then
                self:get_party():add_to_chat(self:get_party():get_player(), "Heads up, "..m:get_name().." just used "..monster_ability_name.."!")
            end
        end, self:get_target():on_tp_move_finish()))
    end
end

function Assistant:add_ability_name(ability_name)
    self.watch_list:add(ability_name)
end

function Assistant:remove_ability_name(ability_name)
    self.watch_list:remove(ability_name)
end

function Assistant:allows_duplicates()
    return false
end

function Assistant:get_type()
    return "assistant"
end

return Assistant
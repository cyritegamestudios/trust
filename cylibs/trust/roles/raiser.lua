local Raiser = setmetatable({}, {__index = Role })
Raiser.__index = Raiser
Raiser.__class = "Raiser"

local cure_util = require('cylibs/util/cure_util')
local DisposeBag = require('cylibs/events/dispose_bag')

state.AutoRaiseMode = M{['description'] = 'Auto Raise Mode', 'Off', 'Auto'}
state.AutoRaiseMode:set_description('Auto', "Okay, I'll try to raise party members who have fallen in battle.")

function Raiser.new(action_queue, job)
    local self = setmetatable(Role.new(action_queue), Raiser)

    self.action_events = {}
    self.job = job
    self.last_raise_time = os.time()
    self.last_raise_spell_id = nil
    self.ko_party_member_ids = S{}
    self.dispose_bag = DisposeBag.new()

    return self
end

function Raiser:destroy()
    Role.destroy(self)

    if self.action_events then
        for _,event in pairs(self.action_events) do
            windower.unregister_event(event)
        end
    end

    self.dispose_bag:destroy()

    if self.on_party_member_ko_id then
        self:get_party():on_party_member_ko():removeAction(self.on_party_member_ko_id)
    end
end

function Raiser:on_add()
    Role.on_add(self)

    local on_party_member_added = function(p)
        self.dispose_bag:add(p:on_ko():addAction(function(p)
            if not p:is_trust() then
                self.ko_party_member_ids:add(p:get_id())
                logger.notice(self.__class, 'on_ko', p:get_name())
            end
        end), p:on_ko())
    end

    self.dispose_bag:add(self:get_party():on_party_member_added():addAction(on_party_member_added), self:get_party():on_party_member_added())

    self.dispose_bag:add(self:get_player():on_spell_finish():addAction(
            function (_, spell_id, targets)
                if self.last_raise_spell_id and spell_id == self.last_raise_spell_id  then
                    self:prune_party_ko(spell_id, targets)
                end
            end), self:get_player():on_spell_finish())

    self.dispose_bag:add(self:get_player():on_unable_to_cast():addAction(
            function (_, target_index, message_id, spell_id)
                if L{48}:contains(message_id) and self.last_raise_spell_id and self.last_raise_spell_id == spell_id then
                    local target = windower.ffxi.get_mob_by_index(target_index)
                    if target then
                        self.ko_party_member_ids:remove(target.id)
                    end
                end

            end), self:get_player():on_unable_to_cast())

    for party_member in self:get_party():get_party_members(false):it() do
        on_party_member_added(party_member)
        if not party_member:is_alive() then
            self.ko_party_member_ids:add(party_member:get_id())
        end
    end
end

function Raiser:target_change(target_index)
    Role.target_change(self, target_index)
end

function Raiser:tic(new_time, old_time)
    Role.tic(new_time, old_time)

    if state.AutoRaiseMode.value == 'Off' or self.ko_party_member_ids:length() == 0
            or (os.time() - self.last_raise_time) < 15 then
        return
    end

    self:check_party_ko()
end

-------
-- Checks to see if any party members have been knocked out and raises them if needed.
function Raiser:check_party_ko()
    for party_member_id in self.ko_party_member_ids:it() do
        local party_member = self:get_party():get_party_member(party_member_id)
        if party_member then
            self.last_raise_time = os.time()
            self:raise_party_member(party_member)
            return
        end
    end
end

function Raiser:raise_party_member(party_member)
    if party_member:get_hp() > 0 then
        self.ko_party_member_ids:remove(party_member:get_id())
    else
        local raise_spell = self.job:get_raise_spell()
        if raise_spell and party_member and not party_member:has_buff(buff_util.buff_id('Reraise')) then
            self.last_raise_time = os.time()
            self.last_raise_spell_id = raise_spell:get_spell().id

            local actions = L{}
            for job_ability_name in raise_spell:get_job_abilities():it() do
                actions:append(JobAbilityAction.new(0, 0, 0, job_ability_name))
                actions:append(WaitAction.new(0, 0, 0, 1))
            end

            actions:append(SpellAction.new(0, 0, 0, raise_spell:get_spell().id, party_member:get_mob().index, self:get_player()))
            actions:append(WaitAction.new(0, 0, 0, 1))

            local raise_action = SequenceAction.new(actions, 'raiser_raise_'..party_member:get_mob().id)
            raise_action.priority = cure_util.get_cure_priority(0, false, false)

            self.action_queue:push_action(raise_action, true)
        end
    end
end

function Raiser:prune_party_ko(raise_spell_id, targets)
    for _, target in pairs(targets) do
        for _, action in pairs(target.actions) do
            if L{42}:contains(action.message) then
                self.ko_party_member_ids:remove(target.id)
                logger.notice(self.__class, 'prune_party_ko', target.name)
            end
        end
    end
end

function Raiser:allows_duplicates()
    return false
end

function Raiser:get_type()
    return "raiser"
end

return Raiser
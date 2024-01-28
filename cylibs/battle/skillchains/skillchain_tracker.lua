require('actions')

local action_message_util = require('cylibs/util/action_message_util')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local renderer = require('cylibs/ui/views/render')
local SkillchainAbility = require('cylibs/battle/skillchains/abilities/skillchain_ability')
local SkillchainStep = require('cylibs/battle/skillchains/skillchain_step')
local skillchain_util = require('cylibs/util/skillchain_util')

local SkillchainTracker = {}
SkillchainTracker.__index = SkillchainTracker
SkillchainTracker.__class = "SkillchainTracker"

-- Event called when a skillchain step is created (mob_id, skillchain_step)
function SkillchainTracker:on_skillchain()
    return self.skillchain
end

-- Event called when a skillchain ends (mob_id)
function SkillchainTracker:on_skillchain_ended()
    return self.skillchain_ended
end

-------
-- Default initializer for a tracker that tracks skillchains performed on mobs the party is fighting.
-- @tparam Party party Party
-- @treturn SkillchainTracker A skillchain tracker
function SkillchainTracker.new(party)
    local self = setmetatable({
        party = party;
        skillchain_actions = L{};
        steps = T{};
        skillchain = Event.newEvent();
        skillchain_ended = Event.newEvent();
        dispose_bag = DisposeBag.new();
    }, SkillchainTracker)
    self:on_add()
    return self
end

function SkillchainTracker:destroy()
    self.dispose_bag:destroy()

    if self.action_listener_id then
        ActionPacket.close_listener(self.action_listener_id)
    end

    self:on_skillchain():removeAllActions()
    self:on_skillchain_ended():removeAllActions()
end

function SkillchainTracker:on_add()
    self.action_listener_id = ActionPacket.open_listener(function(action)
        self:on_action(action)
    end)

    self.dispose_bag:add(renderer.shared():onPrerender():addAction(function()
        self:on_prerender()
    end), renderer.shared():onPrerender())
end

function SkillchainTracker:on_prerender()
    for mob_id, _ in pairs(self.steps) do
        if self:get_current_step(mob_id) and os.clock() > self:get_current_step(mob_id):get_expiration_time() then
            logger.notice(self.__class, 'on_prerender', 'skillchain window ended', mob_id or 'unknown')
            self:reset(mob_id)
        end
    end
end

-------
-- Event handler called when an action is performed. Filters by skillchain actions.
function SkillchainTracker:on_action(action)
    local action_packet = ActionPacket.new(action)
    if not action_message_util.is_skillchainable_action_category(action_packet:get_category_string()) or action.param == 0 then
        return
    end
    local actor = self.party:get_party_member(action_packet:get_id())
    if actor then
        for target in action_packet:get_targets() do
            for action in target:get_actions() do
                if action_message_util.is_weapon_skill_message(action:get_message_id()) then
                    self:apply_properties(actor, target.id, action)
                end
            end
        end
    end
end

-------
-- Creates the next skillchain step or resets the skillchain based on the action performed.
-- @tparam PartyMember party_member Party member (or party member's pet) performing the action
-- @tparam number target_id Target of the action
-- @tparam T action Action being performed
function SkillchainTracker:apply_properties(party_member, target_id, action)
    local _, resource, action_id, _, _ = action:get_spell()

    local ability = SkillchainAbility.new(resource, action_id, L{}, party_member) -- e.g. Weapon Skill, Spell, Chain Bound, etc.
    if ability then
        logger.notice(self.__class, 'apply_properties', 'checking action', ability:get_name(), target_id)

        local step_num = 1

        local skillchain = self:get_skillchain(action, target_id)
        if skillchain then
            local current_step = self:get_current_step(target_id)
            if current_step then
                step_num = current_step:get_step() + 1
            end
        else
            local conditions = ability:get_conditions()
            if not Condition.check_conditions(conditions, party_member:get_mob().index) then
                logger.notice(self.__class, 'apply_properties', party_member:get_name(), 'does not meet the requirements to skillchain with', ability:get_name())
                return
            else
                self:reset(target_id)
                logger.notice(self.__class, 'apply_properties', party_member:get_name(), 'conditions met for', ability:get_name())
            end
        end

        local next_step = SkillchainStep.new(step_num, ability, skillchain, ability:get_delay(), os.clock() + ability:get_delay() + 8 - step_num, os.clock())
        self:add_step(target_id, next_step)
    end
end

-------
-- Returns the skillchain created by the given action, if any.
-- @tparam T action Action performed
-- @tparam number target_id Target of the action
-- @treturn Skillchain Skillchain being performed, or nil if none (see util/skillchain_util.lua)
function SkillchainTracker:get_skillchain(action, target_id)
    local _, _, _, _, conclusion = action:get_spell()
    local add_effect = action:get_add_effect()
    if add_effect and action_message_util.is_skillchain_message(add_effect.message_id) and conclusion then
        local current_step = self:get_current_step(target_id)
        local skillchain = skillchain_util[add_effect.animation:ucfirst()]
        if current_step and current_step:get_skillchain() then
            skillchain = skillchain_util[current_step:get_skillchain():get_name()][skillchain:get_name()] or skillchain
        end
        return skillchain
    end
    return nil
end

-- Adds a step to the skillchain.
-- @tparam SkillchainStep Step to add
function SkillchainTracker:add_step(mob_id, step)
    logger.notice(self.__class, 'add_step', mob_id, tostring(step))

    local old_step = self:get_current_step(mob_id)
    if old_step then
        local old_properties = L{}
        if old_step:get_skillchain() then
            old_properties:append(old_step:get_skillchain())
        else
            old_properties = old_properties:extend(old_step:get_ability():get_skillchain_properties())
        end
        for old_property in old_properties:it() do
            for new_property in step:get_ability():get_skillchain_properties():it() do
                local skillchain = skillchain_util[old_property:get_name()][new_property:get_name()]
                if skillchain and skillchain:get_level() > 3 then
                    logger.notice(self.__class, 'add_step', 'upgrading', step:get_skillchain():get_name(), 'to', skillchain:get_name())
                    step:set_skillchain(skillchain)
                end
            end
        end
    end

    local steps = self.steps[mob_id] or L{}
    steps:append(step)

    self.steps[mob_id] = steps
    if step:get_skillchain() then
        self:on_skillchain():trigger(mob_id, step)
    else
        self:on_skillchain_ended():trigger(mob_id)
    end
end

-- Resets the skillchain on a target.
-- @tparam number mob_id Id of target to reset
function SkillchainTracker:reset(mob_id)
    self.steps[mob_id] = L{}
    self:on_skillchain_ended():trigger(mob_id)
end

-- Gets the current skillchain step.
-- @tparam number mob_id Mob id
-- @treturn SkillchainStep Current step
function SkillchainTracker:get_current_step(mob_id)
    local steps = self.steps[mob_id]
    if steps and steps:length() > 0 then
        return steps[steps:length()]
    end
    return nil
end

-- Returns whether the skillchain window is open on a target.
-- @tparam number mob_id Mob id
-- @treturn boolean True if skillchain window is open, false otherwise
function SkillchainTracker:is_skillchain_window_open(mob_id)
    local current_step = self:get_current_step(mob_id)
    return current_step and os.clock() < current_step:get_expiration_time()
end

return SkillchainTracker
local ActionQueue = require('cylibs/actions/action_queue')
local GambitTarget = require('cylibs/gambits/gambit_target')

local Reacter = setmetatable({}, {__index = Role })
Reacter.__index = Reacter
Reacter.__class = "Reacter"

state.AutoReactMode = M{['description'] = 'Use Reactions', 'Auto', 'Off'}
state.AutoReactMode:set_description('Off', "Okay, I'll ignore any reactions you've set.")
state.AutoReactMode:set_description('Auto', "Okay, I'll react to player, party and enemy actions.")

function Reacter.new(action_queue, gambit_settings, skillchainer, state_var)
    local self = setmetatable(Role.new(action_queue), Reacter)

    self.react_action_queue = ActionQueue.new(nil, false, 2, false, true)
    self.skillchainer = skillchainer
    self.state_var = state_var or state.AutoReactMode

    self:set_gambit_settings(gambit_settings)

    return self
end

function Reacter:destroy()
    Role.destroy(self)
end

function Reacter:on_add()
    Role.on_add(self)

    WindowerEvents.Ability.Ready:addAction(function(target_id, ability_id)
        if not ability_id then
            return
        end
        local target = self:get_target()
        if target and target:get_id() == target_id then
            local ability = res.monster_abilities[ability_id]
            if ability then
                logger.notice(self.__class, 'ability_ready', 'check_gambits', ability.en)

                local gambits = self:get_all_gambits():filter(function(gambit)
                    for condition in gambit:getConditions():it() do
                        if condition.__type == ReadyAbilityCondition.__type then
                            return true
                        end
                        return false
                    end
                end)

                self:check_gambits(L{ target }, gambits, ability.en)
            end
        end
    end)

    WindowerEvents.Ability.Finish:addAction(function(target_id, ability_id)
        if not ability_id then
            return
        end
        local target = self:get_target()
        if target and target:get_id() == target_id then
            local ability = res.monster_abilities[ability_id]
            if ability then
                logger.notice(self.__class, 'ability_finish', 'check_gambits', ability.en)

                local gambits = self:get_all_gambits():filter(function(gambit)
                    for condition in gambit:getConditions():it() do
                        if condition.__type == FinishAbilityCondition.__type then
                            return true
                        end
                        return false
                    end
                end)

                self:check_gambits(L{ target }, gambits, ability.en)
            end
        end
    end)

    WindowerEvents.Spell.Begin:addAction(function(target_id, spell_id)
        if spell_id == nil or (self:get_party():get_party_member(target_id) == nil and self:get_party():get_target(target_id) == nil) then
            return
        end

        local valid_targets = L(BeginCastCondition.valid_targets():map(function(target_type)
            return self:get_gambit_targets(target_type)
        end)):flatten(false)

        local target = valid_targets:firstWhere(function(target)
            return target:get_id() == target_id
        end)
        if target == nil then
            return
        end

        local spell = res.spells[spell_id]
        if spell then
            logger.notice(self.__class, 'spell_begin', 'check_gambits', spell.en)
            local gambits = self:get_all_gambits():filter(function(gambit)
                for condition in gambit:getConditions():it() do
                    if condition.__type == BeginCastCondition.__type then
                        return true
                    end
                    return false
                end
            end)
            self:check_gambits(L{ target }, gambits, spell.en)
        end
    end)

    WindowerEvents.GainDebuff:addAction(function(target_id, debuff_id)
        local target = self:get_target()
        if target and target:get_id() == target_id then
            local debuff = res.buffs[debuff_id]
            if debuff then
                logger.notice(self.__class, 'gain_debuff', 'check_gambits', debuff.en)

                local gambits = self:get_all_gambits():filter(function(gambit)
                    for condition in gambit:getConditions():it() do
                        if condition.__type == GainDebuffCondition.__type then
                            return true
                        end
                        return false
                    end
                end)

                self:check_gambits(L{ target }, gambits, debuff.en)
            end
        end
    end)

    WindowerEvents.PetUpdate:addAction(function(owner_id, pet_id, pet_index, pet_name, pet_hpp, pet_mpp, pet_tp)
        local target = self:get_player()
        if target and target:get_id() == owner_id then
            logger.notice(self.__class, 'on_pet_update', 'check_gambits')

            local gambits = self:get_all_gambits():filter(function(gambit)
                for condition in gambit:getConditions():it() do
                    if condition.__type == PetTacticalPointsCondition.__type then
                        return true
                    end
                    return false
                end
            end)

            self:check_gambits(L{ target }, gambits, pet_tp)
        end
    end)

    WindowerEvents.Action:addAction(function(action)
        -- Melee attacks are too spammy
        if action.category == 1 then
            return
        end

        local valid_targets = L(ActionCondition.valid_targets():map(function(target_type)
            return self:get_gambit_targets(target_type)
        end)):flatten(false):filter(function(target)
            return target:get_id() == action.actor_id
        end)
        if valid_targets:length() == 0 then
            return
        end

        logger.notice(self.__class, 'action', 'check_gambits')
        local gambits = self:get_all_gambits():filter(function(gambit)
            for condition in gambit:getConditions():it() do
                if condition.__type == ActionCondition.__type then
                    return true
                end
                return false
            end
        end)
        self:check_gambits(valid_targets, gambits, action)
    end)

    self.skillchainer:on_skillchain():addAction(function(target_id, skillchain_step)
        local target = self:get_target()
        if target and target:get_id() == target_id then
            logger.notice(self.__class, 'on_skillchain', 'check_gambits', skillchain_step:get_skillchain():get_name())

            local gambits = self:get_all_gambits():filter(function(gambit)
                for condition in gambit:getConditions():it() do
                    if condition.__type == SkillchainPropertyCondition.__type then
                        return true
                    end
                    return false
                end
            end)

            self:check_gambits(L{ target }, gambits, skillchain_step:get_skillchain():get_name())
        end
    end)

    -- Trust turns off when zoning, so even if this evaluates to true it never performs the gambit
    self:get_party():get_player():on_zone_change():addAction(function(p, new_zone_id)
        local target = self:get_player()
        if target and target:get_id() == p:get_id() then
            logger.notice(self.__class, 'on_zone_change', 'check_gambits')

            local gambits = self:get_all_gambits():filter(function(gambit)
                for condition in gambit:getConditions():it() do
                    if condition.__type == ZoneChangeCondition.__type then
                        return true
                    end
                    return false
                end
            end)

            self:check_gambits(L{ target }, gambits, new_zone_id)
        end
    end)

    self:get_party():get_player():on_target_change():addAction(function(_, new_target_index, _)
        local target = self:get_target()
        if target and target:get_index() == new_target_index then
            local gambits = self:get_all_gambits():filter(function(gambit)
                for condition in gambit:getConditions():it() do
                    if condition.__type == TargetNameCondition.__type then
                        return true
                    end
                    return false
                end
            end)

            self:check_gambits(L{ target }, gambits)
        end
    end)
end

function Reacter:check_gambits(targets, gambits, param)
    if self.state_var.value == 'Off' then
        return
    end

    logger.notice(self.__class, 'check_gambits', self:get_type(), self.state_var.value)

    if not self:allows_multiple_actions() and self.action_queue:has_action(self:get_action_identifier()) then
        logger.notice(self.__class, 'check_gambits', self:get_type(), 'duplicate')
        return
    end

    local gambits = (gambits or self:get_all_gambits()):filter(function(gambit) return gambit:isEnabled() end)
    for gambit in gambits:it() do
        local targets = targets or self:get_gambit_targets(gambit:getConditionsTarget()) or L{}
        for target in targets:it() do
            if gambit:isSatisfied(target, param) then
                if gambit:getAbilityTarget() == gambit:getConditionsTarget() then
                    self:perform_gambit(gambit, target)
                    return
                else
                    local ability_targets = self:get_gambit_targets(gambit:getAbilityTarget())
                    if ability_targets:length() > 0 then
                        self:perform_gambit(gambit, ability_targets[1])
                        return
                    end
                end
                break
            end
        end
    end

    logger.notice(self.__class, 'check_gambits', self:get_type(), 'checked', gambits:length(), 'gambits')
end

function Reacter:get_gambit_targets(gambit_target)
    local targets = L{}
    local target_group
    if gambit_target == GambitTarget.TargetType.Self then
        target_group = self:get_player()
    elseif gambit_target == GambitTarget.TargetType.Ally then
        target_group = self:get_party()
    elseif gambit_target == GambitTarget.TargetType.Enemy then
        target_group = self:get_target()
    end
    if target_group then
        targets = L{ target_group }
        if target_group.__class == Party.__class then
            targets = target_group:get_party_members(false, 21)
        end
    end
    return targets
end

function Reacter:perform_gambit(gambit, target)
    if target == nil or target:get_mob() == nil then
        return
    end

    logger.notice(self.__class, 'perform_gambit', gambit:tostring(), target:get_mob().name)

    local action = gambit:getAbility():to_action(target:get_mob().index, self:get_player())
    if action then
        self.action_queue:clear()

        action.priority = ActionPriority.highest
        action.identifier = self:get_action_identifier()

        if self:should_ignore_queue(gambit:getAbility()) then
            self.react_action_queue:push_action(action, true)
        else
            self.action_queue:push_action(action, true)
        end
    end
end

function Reacter:should_ignore_queue(ability)
    return L{ RunAway.__type, RunTo.__type, TurnAround.__type, TurnToFace.__type, Command.__type }:contains(ability.__type)
end

function Reacter:allows_duplicates()
    return true
end

function Reacter:allows_multiple_actions()
    return false
end

function Reacter:get_type()
    return "reacter"
end

function Reacter:get_cooldown()
    return 0
end

function Reacter:get_action_identifier()
    return self:get_type()..'_action'
end

function Reacter:get_localized_name()
    return "Reactions"
end

function Reacter:set_gambit_settings(gambit_settings)
    self.gambits = (gambit_settings.Gambits or L{}):filter(function(gambit)
        return gambit:getAbility() ~= nil
    end)
end

function Reacter:get_all_gambits()
    return self.gambits
end

function Reacter:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

return Reacter
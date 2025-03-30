local ActionQueue = require('cylibs/actions/action_queue')
local GambitTarget = require('cylibs/gambits/gambit_target')
local GambitTargetGroup = require('cylibs/gambits/gambit_target_group')

local Reacter = setmetatable({}, {__index = Role })
Reacter.__index = Reacter
Reacter.__class = "Reacter"

state.AutoReactMode = M{['description'] = 'Use Reactions', 'Auto', 'Off'}
state.AutoReactMode:set_description('Auto', "Enable reactions.")

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
        local has_valid_target = self:get_gambit_targets(L(ReadyAbilityCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_id() == target_id
        end)
        if not has_valid_target then
            return
        end

        local ability = res.monster_abilities[ability_id]
        if ability then
            logger.notice(self.__class, 'ability_ready', 'check_gambits', ability.en)

            local gambits = self:get_reactions_of_type(ReadyAbilityCondition.__type)
            if gambits:length() == 0 then
                return
            end
            self:check_gambits(gambits, ability.en)
        end
    end)

    WindowerEvents.Ability.Finish:addAction(function(target_id, ability_id)
        local has_valid_target = self:get_gambit_targets(L(FinishAbilityCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_id() == target_id
        end)
        if not has_valid_target then
            return
        end

        local ability = res.monster_abilities[ability_id]
        if ability then
            logger.notice(self.__class, 'ability_finish', 'check_gambits', ability.en)

            local gambits = self:get_reactions_of_type(FinishAbilityCondition.__type)
            if gambits:length() == 0 then
                return
            end
            self:check_gambits(gambits, ability.en)
        end
    end)

    WindowerEvents.Spell.Begin:addAction(function(target_id, spell_id)
        local has_valid_target = self:get_gambit_targets(L(BeginCastCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_id() == target_id
        end)
        if not has_valid_target then
            return
        end

        local spell = res.spells[spell_id]
        if spell then
            logger.notice(self.__class, 'spell_begin', 'check_gambits', spell.en)

            local gambits = self:get_reactions_of_type(BeginCastCondition.__type)
            if gambits:length() == 0 then
                return
            end
            self:check_gambits(gambits, spell.en)
        end
    end)

    WindowerEvents.GainDebuff:addAction(function(target_id, debuff_id)
        local has_valid_target = self:get_gambit_targets(L(GainDebuffCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_id() == target_id
        end)
        if not has_valid_target then
            return
        end

        local debuff = res.buffs[debuff_id]
        if debuff then
            logger.notice(self.__class, 'gain_debuff', 'check_gambits', debuff.en)

            local gambits = self:get_reactions_of_type(GainDebuffCondition.__type)
            if gambits:length() == 0 then
                return
            end
            self:check_gambits(gambits, debuff.en)
        end
    end)

    WindowerEvents.PetUpdate:addAction(function(owner_id, pet_id, pet_index, pet_name, pet_hpp, pet_mpp, pet_tp)
        local has_valid_target = self:get_gambit_targets(L(PetTacticalPointsCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_id() == owner_id
        end)
        if not has_valid_target then
            return
        end

        logger.notice(self.__class, 'on_pet_update', 'check_gambits')

        local gambits = self:get_reactions_of_type(PetTacticalPointsCondition.__type)
        if gambits:length() == 0 then
            return
        end
        self:check_gambits(gambits, pet_tp)
    end)

    WindowerEvents.Action:addAction(function(action)
        -- Melee attacks are too spammy
        if action.category == 1 then
            return
        end

        local has_valid_target = self:get_gambit_targets(L(ActionCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_id() == action.actor_id
        end)
        if not has_valid_target then
            return
        end

        logger.notice(self.__class, 'action', 'check_gambits')

        local gambits = self:get_reactions_of_type(ActionCondition.__type)
        if gambits:length() == 0 then
            return
        end
        self:check_gambits(gambits, action)
    end)

    self.skillchainer:on_skillchain():addAction(function(target_id, skillchain_step)
        local has_valid_target = self:get_gambit_targets(L(SkillchainPropertyCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_id() == target_id
        end)
        if not has_valid_target then
            return
        end

        logger.notice(self.__class, 'on_skillchain', 'check_gambits', skillchain_step:get_skillchain():get_name())

        local gambits = self:get_reactions_of_type(SkillchainPropertyCondition.__type)
        if gambits:length() == 0 then
            return
        end
        self:check_gambits(gambits, skillchain_step:get_skillchain():get_name())
    end)

    -- Trust turns off when zoning, so even if this evaluates to true it never performs the gambit
    self:get_party():get_player():on_zone_change():addAction(function(p, new_zone_id)
        local has_valid_target = self:get_gambit_targets(L(ZoneChangeCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_id() == p:get_id()
        end)
        if not has_valid_target then
            return
        end

        logger.notice(self.__class, 'on_zone_change', 'check_gambits')

        local gambits = self:get_reactions_of_type(ZoneChangeCondition.__type)
        if gambits:length() == 0 then
            return
        end
        self:check_gambits(gambits, new_zone_id)
    end)

    self:get_party():get_player():on_target_change():addAction(function(_, new_target_index, _)
        local has_valid_target = self:get_gambit_targets(L(TargetNameCondition.valid_targets()), true):firstWhere(function(target)
            return target:get_index() == new_target_index
        end)
        if not has_valid_target then
            return
        end

        logger.notice(self.__class, 'on_target_change', 'check_gambits')

        local gambits = self:get_reactions_of_type(TargetNameCondition.__type)
        if gambits:length() == 0 then
            return
        end
        self:check_gambits(gambits)
    end)
end

function Reacter:check_gambits(gambits, param)
    if self.state_var.value == 'Off' or gambits:length() == 0 then
        return
    end

    logger.notice(self.__class, 'check_gambits', self:get_type(), self.state_var.value)

    if not self:allows_multiple_actions() and self.action_queue:has_action(self:get_action_identifier()) then
        logger.notice(self.__class, 'check_gambits', self:get_type(), 'duplicate')
        return
    end

    local gambit_target_group = GambitTargetGroup.new(self:get_gambit_targets())

    -- FIXME: gambits have nil value here
    local gambits = (gambits or self:get_all_gambits()):filter(function(gambit)
        return gambit:isEnabled()
    end)
    for gambit in gambits:it() do
        for targets_by_type in gambit_target_group:it() do
            local get_target_by_type = function(target_type)
                return targets_by_type[target_type]
            end
            if gambit:isSatisfied(get_target_by_type, param) then
                local target = get_target_by_type(gambit:getAbilityTarget())
                self:perform_gambit(gambit, target)
                break
            end
        end
    end

    logger.notice(self.__class, 'check_gambits', self:get_type(), 'checked', gambits:length(), 'gambits')
end

function Reacter:get_gambit_targets(gambit_target_types, flatten)
    gambit_target_types = gambit_target_types or L(Condition.TargetType.AllTargets)
    if class(gambit_target_types) ~= 'List' then
        gambit_target_types = L{ gambit_target_types }
    end
    local targets_by_type = {}
    for gambit_target_type in gambit_target_types:it() do
        local target_group
        if gambit_target_type == GambitTarget.TargetType.Self then
            target_group = self:get_player()
        elseif gambit_target_type == GambitTarget.TargetType.Ally then
            target_group = self:get_party()
        elseif gambit_target_type == GambitTarget.TargetType.Enemy then
            target_group = self:get_target()
        end
        if target_group then
            local targets = L{}
            if target_group.__class == Party.__class then
                targets = targets + target_group:get_party_members(false, 21)
            else
                targets = targets + L{ target_group }
            end
            targets_by_type[gambit_target_type] = targets
        end
    end
    if flatten then
        local all_targets = L{}
        for _, targets in pairs(targets_by_type) do
            all_targets = all_targets + targets
        end
        return all_targets
    end
    return targets_by_type
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

function Reacter:get_reactions_of_type(condition_type)
    local gambits = self:get_all_gambits():filter(function(gambit)
        for condition in gambit:getConditions():it() do
            if condition:getCondition().__type == condition_type then
                return true
            end
            return false
        end
    end)
    return gambits
end

function Reacter:tostring()
    return localization_util.commas(self.gambits:map(function(gambit)
        return gambit:tostring()
    end), 'and')
end

return Reacter
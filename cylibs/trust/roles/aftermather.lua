local DisposeBag = require('cylibs/events/dispose_bag')
local renderer = require('cylibs/ui/views/render')

local Aftermather = setmetatable({}, {__index = Role })
Aftermather.__index = Aftermather
Aftermather.__class = "Aftermather"

state.AutoAftermathMode = M{['description'] = 'Aftermath Mode', 'Off', 'Auto', '2000', '1000'}
state.AutoAftermathMode:set_description('Off', "Okay, I won't try to keep aftermath up.")
state.AutoAftermathMode:set_description('Auto', "Okay, I'll try to keep Aftermath: Lv.3 up.")
state.AutoAftermathMode:set_description('2000', "Okay, I'll try to keep Aftermath: Lv.2 up.")
state.AutoAftermathMode:set_description('1000', "Okay, I'll try to keep Aftermath: Lv.1 up.")

local aftermath_weapon_skills = {
    -- Mythic
    ["Aymur"] = 74,
    ["Burtgang"] = 45,
    ["Carnwenhan"] = 28,
    ["Conqueror"] = 90,
    ["Death Penalty"] = 218,
    ["Epeolatry"] = 61,
    ["Gastraphetes"] = 217,
    ["Glanzfaust"] = 11,
    ["Idris"] = 175,
    ["Kogarasumaru"] = 154,
    ["Laevateinn"] = 186,
    ["Liberator"] = 106,
    ["Murgleis"] = 44,
    ["Nagi"] = 138,
    ["Nirvana"] = 187,
    ["Ryunohige"] = 122,
    ["Tizona"] = 46,
    ["Tupsimati"] = 188,
    ["Vajra"] = 27,
    ["Yagrush"] = 171,
    ["Kenkonken"] = 12,
    ["Terpsichore"] = 29,
    -- Aeonic
    ["Dojikiri Yasutsuna"] = 157,
    ["Godhands"] = 15,
    ["Aeneas"] = 225,
    ["Sequence"] = 226,
    ["Lionheart"] = 60,
    ["Tri-edge"] = 77,
    ["Chango"] = 93,
    ["Anguta"] = 109,
    ["Trishula"] = 125,
    ["Heishi Shorinken"] = 141,
    ["Tishtrya"] = 174,
    ["Khatvanga"] = 191,
    ["Fail-Not"] = 203,
    ["Fomalhaut"] = 221,
    -- Empyrean
    ["Masamune"] = 156,
    ["Verethragna"] = 14,
    ["Twashtar"] = 31,
    ["Almace"] = 225,
    ["Caladbolg"] = 59,
    ["Farsha"] = 76,
    ["Ukonvasara"] = 92,
    ["Redemption"] = 108,
    ["Rhongomiant"] = 124,
    ["Kannagi"] = 140,
    ["Gambanteinn"] = 173,
    ["Hvergelmir"] = 190,
    ["Gandiva"] = 202,
    ["Armageddon"] = 220,
    -- Prime
}

function Aftermather.new(action_queue, skillchainer)
    local self = setmetatable(Role.new(action_queue), Aftermather)

    self.skillchainer = skillchainer
    self.aftermath_buff_ids = L{ 270, 271, 272, 273 }
    self.last_aftermath_check_time = os.time()
    self.dispose_bag = DisposeBag.new()

    return self
end

function Aftermather:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function Aftermather:on_add()
    Role.on_add(self)

    self.dispose_bag:add(state.AutoAftermathMode:on_state_change():addAction(function(_, new_value)
        if new_value == 'Off' then
            if self.old_state_value and state.AutoSkillchainMode.value ~= self.old_state_value then
                state.AutoSkillchainMode:set(self.old_state_value)
                self.old_state_value = nil
            end
        end
    end), state.AutoAftermathMode:on_state_change())

    self.dispose_bag:add(self:get_party():get_player():on_equipment_change():addAction(function(_)
        self:update_weapons()
    end), self:get_party():get_player():on_equipment_change())

    self:update_weapons()

    self.dispose_bag:add(self:get_party():get_player():on_gain_buff():addAction(function(_, buff_id)
        if self.aftermath_buff_ids:contains(buff_id) then
            self:update_aftermath()
        end
    end), self:get_party():get_player():on_gain_buff())

    self.dispose_bag:add(self:get_party():get_player():on_lose_buff():addAction(function(_, buff_id)
        if self.aftermath_buff_ids:contains(buff_id) then
            self:update_aftermath()
        end
    end), self:get_party():get_player():on_lose_buff())

    self:update_aftermath()
end

function Aftermather:tic(_, _)
    if state.AutoAftermathMode.value == 'Off' or self.aftermath_weapon_skill == nil
            or os.time() - self.last_aftermath_check_time < 1 then
        return
    end
    self.last_aftermath_check_time = os.time()

    logger.notice(self.__class, 'tic', 'checking_aftermath', self.is_aftermath_active)

    if not self.is_aftermath_active then
        if state.AutoSkillchainMode.value ~= 'Off' then
            self.old_state_value = state.AutoSkillchainMode.value
            state.AutoSkillchainMode:set('Off')
        end
        if windower.ffxi.get_player().vitals.tp >= self:get_aftermath_tp() then
            logger.notice(self.__class, 'tic', 'perform_ability', self.aftermath_weapon_skill:get_name())
            self.skillchainer:perform_ability(self.aftermath_weapon_skill)
        end
    else
        if self.old_state_value and state.AutoSkillchainMode.value ~= self.old_state_value then
            state.AutoSkillchainMode:set(self.old_state_value)
            self.old_state_value = nil
        end
    end
end

function Aftermather:update_aftermath()
    self:set_is_aftermath_active(buff_util.is_any_buff_active(self:get_target_aftermath_ids(), self:get_party():get_player():get_buff_ids()))
end

function Aftermather:update_weapons()
    self:set_aftermath_weapon_skill(nil)

    local weapons = require('cylibs/res/weapons')

    local weapon_names = L{
        self:get_party():get_player():get_main_weapon_id(),
        self:get_party():get_player():get_ranged_weapon_id()
    }:compact_map():map(function(weapon_id) return weapons[weapon_id].en end)

    for weapon_name in weapon_names:it() do
        local aftermath_weapon_skill_id = aftermath_weapon_skills[weapon_name]
        if aftermath_weapon_skill_id then
            self:set_aftermath_weapon_skill(WeaponSkill.new(res.weapon_skills[aftermath_weapon_skill_id].en, L{ MinTacticalPointsCondition.new(3000) }))
        end
    end
    weapons = nil
end

function Aftermather:set_is_aftermath_active(is_aftermath_active)
    if self.is_aftermath_active == is_aftermath_active then
        return
    end
    self.is_aftermath_active = is_aftermath_active

    if self.aftermath_weapon_skill then
        if addon_enabled:getValue() then
            if not self.is_aftermath_active then
                self:get_party():add_to_chat(self:get_party():get_player(), "Hold on, getting aftermath back up.")
            else
                self:get_party():add_to_chat(self:get_party():get_player(), "Aftermath is up, good to go!")
            end
        end
    end
end

function Aftermather:set_aftermath_weapon_skill(aftermath_weapon_skill)
    logger.notice(self.__class, 'set_aftermath_weapon_skill', aftermath_weapon_skill and aftermath_weapon_skill:get_name() or 'none')

    self.aftermath_weapon_skill = aftermath_weapon_skill
    if self.aftermath_weapon_skill == nil then
        if self.old_state_value then
            state.AutoSkillchainMode:set(self.old_state_value)
            self.old_state_value = nil
        end
    end
end

function Aftermather:get_aftermath_tp()
    local mode_value = state.AutoAftermathMode.value
    if mode_value == 'Auto' then
        return 3000
    elseif L{ '2000', '1000' }:contains(mode_value) then
        return tonumber(mode_value)
    else
        return 0
    end
end

function Aftermather:get_target_aftermath_ids()
    local mode_value = state.AutoAftermathMode.value
    if mode_value == 'Auto' then
        return S{ 272 }
    elseif mode_value == '2000' then
        return S{ 271, 272 }
    else
        return S{ 271, 272, 273 }
    end
end

function Aftermather:allows_duplicates()
    return false
end

function Aftermather:get_type()
    return "aftermather"
end

return Aftermather
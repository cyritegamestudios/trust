---------------------------
-- Condition checking whether the player has the maximum number of alter egos summoned.
-- @class module
-- @name HasMaxNumAlterEgosCondition

local HasKeyItemsCondition = require('cylibs/conditions/has_key_items')
local Condition = require('cylibs/conditions/condition')

local HasMaxNumAlterEgosCondition = setmetatable({}, { __index = Condition })
HasMaxNumAlterEgosCondition.__index = HasMaxNumAlterEgosCondition
HasMaxNumAlterEgosCondition.__type = "HasMaxNumAlterEgosCondition"
HasMaxNumAlterEgosCondition.__class = "HasMaxNumAlterEgosCondition"

function HasMaxNumAlterEgosCondition.new()
    local self = setmetatable(Condition.new(), HasMaxNumAlterEgosCondition)
    return self
end

function HasMaxNumAlterEgosCondition:is_satisfied(_)
    local num_party_members = player.party:get_party_members(true):length()
    local num_alter_egos = player.party:get_party_members():filter(function(p) return p:is_trust() end):length()
    return num_alter_egos >= self:get_max_num_alter_egos() or num_party_members >= 6
end

function HasMaxNumAlterEgosCondition:get_max_num_alter_egos()
    -- Aim for the number of alter egos the player selected in
    -- Settings > Alter Egos. The Rhapsody key-item check below was
    -- returning 3 even for a player with Rhapsody in Crimson, so the
    -- Truster stopped after 3 trusts and the singer/puller waited
    -- forever for 5 that were never summoned. The configured list
    -- length is the source of truth; fall back to key items only if
    -- the list cannot be read (e.g. before Trust finishes loading).
    local list_len = 0
    local wt = windower and windower.trust
    if wt and wt.settings and wt.settings.get_addon_settings then
        local addon_settings = wt.settings.get_addon_settings()
        if addon_settings and addon_settings.getSettings then
            local settings = addon_settings:getSettings()
            local trusts = settings and settings.battle and settings.battle.trusts
            if trusts then
                if type(trusts.length) == "function" then
                    list_len = trusts:length()
                elseif type(trusts) == "table" then
                    list_len = #trusts
                end
            end
        end
    end
    local max_num = 3
    if list_len > 0 then
        max_num = math.min(list_len, 5)
    elseif Condition.check_conditions(L{ HasKeyItemsCondition.new(L{ "Rhapsody in Crimson" }, 1, Condition.Operator.Equals) }) then
        max_num = 5
    elseif Condition.check_conditions(L{ HasKeyItemsCondition.new(L{ "Rhapsody in White" }, 1, Condition.Operator.Equals) }) then
        max_num = 4
    end
    local zone = res.zones[windower.ffxi.get_info().zone or 0]
    if zone and L{ 'Apollyon', 'Temenos' }:contains(zone.en) then
        return math.min(max_num, 3)
    end
    return max_num
end

function HasMaxNumAlterEgosCondition:get_config_items()
    return L{}
end

function HasMaxNumAlterEgosCondition.valid_targets()
    return S{ Condition.TargetType.Self }
end

function HasMaxNumAlterEgosCondition:serialize()
    return "HasMaxNumAlterEgosCondition.new()"
end

function HasMaxNumAlterEgosCondition:tostring()
    return "Has"..' '..self:get_max_num_alter_egos()..' Alter Egos.'
end

function HasMaxNumAlterEgosCondition.description()
    return "Has max Alter Egos."
end

function HasMaxNumAlterEgosCondition:__eq(otherItem)
    return otherItem.__class == HasMaxNumAlterEgosCondition.__class
end

return HasMaxNumAlterEgosCondition





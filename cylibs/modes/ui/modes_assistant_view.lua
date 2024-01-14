local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local ImageItem = require('cylibs/ui/collection_view/items/image_item')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local ModesAssistantView = setmetatable({}, {__index = CollectionView })
ModesAssistantView.__index = ModesAssistantView

local sections = {
    ["Healing"] = {
        ["Roles"] = L{
            "healer",
        },
        ["Items"] = L{
            "I want to be the main healer.",
            "I want to be the backup healer.",
            "I want to stop healing.",
        }
    },
    ["Status Removal"] = {
        ["Roles"] = L{
            "statusremover",
        },
        ["Items"] = L{
            "I want to remove ailments from my party.",
            "I want to stop removing ailments.",
        }
    },
    ["Combat"] = L{
        ["Roles"] = L{
            "attacker",
            "combatmode",
        },
        ["Items"] = L{
            "I'd like to engage and stay in combat range.",
            "I'd like to stay on the back line."
        }
    },
    ["Skillchains"] = L{
        ["Roles"] = L{
            "skillchainer",
        },
        ["Items"] = L{
            "I want to make skillchains with my party.",
            "I want to repeat the same weapon skill.",
            "I want to cleave monsters.",
            "I want to let my party magic burst.",
        }
    },
    ["Targeting"] = L{
        ["Roles"] = L{
            "targeter",
        },
        ["Items"] = L{
            "I want to auto target mobs my party is fighting.",
        }
    },
    ["Pulling"] = L{
        ["Roles"] = L{
            "puller",
        },
        ["Items"] = L{
            "I want to pull mobs for my party.",
            "I want my party to fight multiple mobs at once.",
            "I want to stop pulling.",
        }
    },
}

local itemToAction = {
    -- Healing
    ["I want to be the main healer."] = function()
        handle_set('AutoHealMode', 'Auto')
    end,
    ["I want to be the backup healer."] = function()
        handle_set('AutoHealMode', 'Emergency')
    end,
    ["I want to stop healing."] = function()
        handle_set('AutoHealMode', 'Off')
    end,
    -- Status Removal
    ["I want to remove ailments from my party."] = function()
        handle_set('AutoStatusRemovalMode', 'Auto')
    end,
    ["I want to stop removing ailments."] = function()
        handle_set('AutoStatusRemovalMode', 'Off')
    end,
    -- Combat
    ["I'd like to engage and stay in combat range."] = function()
        handle_set('AutoEngageMode', 'Always')
        handle_set('CombatMode', 'Melee')
    end,
    ["I'd like to stay on the back line."] = function()
        handle_set('AutoEngageMode', 'Off')
        handle_set('CombatMode', 'Ranged')
    end,
    -- Skillchains
    ["I want to repeat the same weapon skill."] = function()
        handle_set('AutoSkillchainMode', 'Spam')
    end,
    ["I want to cleave monsters."] = function()
        handle_set('AutoSkillchainMode', 'Cleave')
    end,
    ["I want to let my party magic burst."] = function()
        handle_set('AutoSkillchainMode', 'Auto')
        handle_set('SkillchainDelayMode', 'Maximum')
    end,
    -- Targeting
    ["I want to auto target mobs my party is fighting."] = function()
        handle_set('AutoTargetMode', 'Auto')
    end,
    -- Pulling
    ["I want to pull mobs for my party."] = function()
        handle_set('AutoPullMode', 'Auto')
    end,
    ["I want my party to fight multiple mobs at once."] = function()
        handle_set('AutoPullMode', 'Multi')
    end,
    ["I want to stop pulling."] = function()
        handle_set('AutoPullMode', 'Off')
    end,
}

function ModesAssistantView.new(trust)
    local dataSource = CollectionViewDataSource.new(function(item, indexPath)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        cell:setUserInteractionEnabled(true)
        return cell
    end)

    local cursorImageItem = ImageItem.new(windower.addon_path..'assets/backgrounds/menu_selection_bg.png', 37, 24)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0)), nil, cursorImageItem), ModesAssistantView)

    self:setScrollDelta(20)

    local itemsToAdd = self:getAssistantItems(trust)

    dataSource:addItems(itemsToAdd)

    self:getDisposeBag():add(self:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
        local item = self:getDataSource():itemAtIndexPath(indexPath)
        if item then
            local action = itemToAction[item:getText()]
            if action then
                action()
            end
        end
    end), self:getDelegate():didSelectItemAtIndexPath())

    self:getDelegate():setCursorIndexPath(IndexPath.new(1, 2))

    return self
end

function ModesAssistantView:layoutIfNeeded()
    CollectionView.layoutIfNeeded(self)

    self:setTitle("Choose a task.")
end

function ModesAssistantView:getAssistantItems(trust)
    local itemsToAdd = L{}

    local sectionNum = 1
    local rowIndex = 1

    for sectionName, sectionSettings in pairs(sections) do
        rowIndex = 1

        -- Check for required roles
        local hasRequiredRoles = true
        for roleType in sectionSettings.Roles:it() do
            if not trust:role_with_type(roleType) then
                hasRequiredRoles = false
            end
        end

        if hasRequiredRoles then
            itemsToAdd:append(IndexedItem.new(TextItem.new(string.gsub(sectionName, "^%l", string.upper), TextStyle.Default.HeaderSmall), IndexPath.new(sectionNum, rowIndex)))
            rowIndex = rowIndex + 1

            for item in sectionSettings.Items:it() do
                itemsToAdd:append(IndexedItem.new(TextItem.new(item, TextStyle.Default.TextSmall), IndexPath.new(sectionNum, rowIndex)))
                rowIndex = rowIndex + 1
            end
        end
    end
    return itemsToAdd
end

function ModesAssistantView:onSelectMenuItemAtIndexPath(textItem, indexPath)
    if textItem:getText() == 'Save' then
        windower.send_command('trust save '..state.TrustMode.value)
        addon_message(260, '('..windower.ffxi.get_player().name..') '.."You got it! I'll remember what to do.")
    end
end

return ModesAssistantView
local Bag = {}
Bag.__index = Bag
Bag.__type = "Bag"

Bag.AllBags = L{
    'safe',
    'locker',
    'sack',
    'satchel',
    'case',
    'inventory',
    'temporary',
    'wardrobe',
    'wardrobe2',
    'wardrobe3',
    'wardrobe4',
    'wardrobe5',
    'wardrobe6',
    'wardrobe7',
    'wardrobe8',
}

function Bag.new(name)
    local self = setmetatable({}, Bag)
    self.name = name
    return self
end

function Bag:getMaxCapacity()
    return windower.ffxi.get_items('max_'..self.name) or 0
end

function Bag:getItemCount(itemId)
    if itemId == nil then
        return windower.ffxi.get_items('count_'..self.name)
    end
    local count = 0
    for item in self:getItems():it() do
        if item.id == itemId then
            count = count + item.count
        end
    end
    return count
end

function Bag:findItem(itemId)
    for i, item in ipairs(self:getItems()) do
        if item.id == itemId then
            return i
        end
    end
    return -1
end

function Bag:getItems()
    return L(windower.ffxi.get_items(self.name))
end

function Bag:isEnabled()
    return windower.ffxi.get_items('enabled_'..self.name) == 1
end

function Bag:getName()
    return localization_util.firstUpper(self.name)
end

return Bag


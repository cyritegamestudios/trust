---------------------------
-- Extension on list.
-- @class module
-- @name ListExtension

require('lists')

function list.from_range(start_value, end_value)
    local result = L{}
    for i = start_value, end_value do
        result:append(i)
    end
    return result
end

---
--- Returns items in l2 but not in l1
function list.diff(l1, l2)
    local result = L{}

    -- Create tables to count occurrences of elements in each list
    local count1 = {}
    local count2 = {}

    -- Count occurrences in list1
    for item in l1:it() do
        count1[item] = (count1[item] or 0) + 1
    end

    -- Count occurrences in list2
    for item in l2:it() do
        count2[item] = (count2[item] or 0) + 1
    end

    -- Check for elements in list1 that are not in list2
    for item, count in pairs(count1) do
        if not count2[item] or count > count2[item] then
            for _ = 1, count - (count2[item] or 0) do
                result:append(item)
            end
        end
    end

    -- Check for elements in list2 that are not in list1
    for item, count in pairs(count2) do
        if not count1[item] or count > count1[item] then
            for _ = 1, count - (count1[item] or 0) do
                result:append(item)
            end
        end
    end

    return result
end

---
--- Returns items in l1 that are not in l2
function list.subtract(l1, l2)
    local result = L{}
    for ele in l1:it() do
        if not l2:contains(ele) then
            result:append(ele)
        end
    end
    return result
end

---
--- Returns the index of the element in the list, or -1 if the element is not in the list
function list.indexOf(l, el)
    for key = 1, l.n do
        if rawget(l, key) == el then
            return key
        end
    end
    return -1
end

function list.merge(l1, l2)
    local result = L{}
    for el in l1:it() do
        result:append(el)
    end
    for el in l2:it() do
        result:append(el)
    end
    return result
end

function list.combo_helper(lists, currentIndex, currentCombination, combinations)
    if currentIndex > lists:length() then
        combinations:append(currentCombination)
        return
    end

    local currentList = lists[currentIndex]
    for element in currentList:it() do
        local newCombination = L{}
        for item in currentCombination:it() do
            newCombination:append(item)
        end
        newCombination:append(element)
        list.combo_helper(lists, currentIndex + 1, newCombination, combinations)
    end
end

function list.combos(lists)
    local combinations = L{}
    list.combo_helper(lists, 1, L{}, combinations)
    return combinations
end

function list.combine(lists)
    local result = L{}
    for list in lists:it() do
        result = result:extend(list)
    end
    return result
end

---
--- Returns a list containing the non-nil elements of the list
function list.compact_map(l)
    return l:filter(function(el) return el ~= nil end)
end

---
--- Returns the first element matching the given filter function.
function list.firstWhere(l, filter)
    for el in l:it() do
        if filter(el) then
            return el
        end
    end
    return nil
end

---
--- Returns the last element matching the given filter function.
function list.lastWhere(l, filter)
    return list.firstWhere(l:reverse(), filter)
end

function list.unique(l, getKey)
    if getKey == nil then
        return L(S(l))
    end
    local result = L{}
    local keys = {}
    for el in l:it() do
        local key = getKey(el)
        if not keys[key] then
            result:append(el)
            keys[key] = true
        end
    end
    return result
end

function list.random(l)
    local index = math.random(1, l:length())
    return l[index]
end
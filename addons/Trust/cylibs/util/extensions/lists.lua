---------------------------
-- Extension on list.
-- @class module
-- @name ListExtension

require('lists')

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
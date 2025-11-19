if GetResourceState('ox_inventory') ~= "started" then
    return
end

local inv = exports.ox_inventory

GetItemCount = function(source, item)
    local count = inv:GetItem(source, item, nil, true)
    return count or 0
end

AddItem = function(source, item, count)
    return inv:AddItem(source, item, count)
end

RemoveItem = function(source, item, count)
    return inv:RemoveItem(source, item, count)
end
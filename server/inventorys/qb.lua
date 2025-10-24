if GetResourceState('qb-inventory') and GetResourceState('qb-core') ~= "started" then
    return
end

local QBCore = exports['qb-core']:GetCoreObject()
local inv = exports['qb-inventory']

GetItemCount = function(source, item)
    local count = inv:GetItemCount(source, item)
    return count
end

AddItem = function(source, item, count)
    inv:AddItem(source, item, count, false, false, 'ec-quest')
end

RemoveItem = function(source, item, count)
    inv:RemoveItem(source, item, count, false, 'ec-quest')
end


QBCore.Functions.CreateUseableItem("quest_tablet", function(source, item)
    TriggerClientEvent('ec-quests:qb-useitem', source)
end)

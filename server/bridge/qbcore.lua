-- QBCore/Qbox Fallback Bridge
if GetResourceState('qb-core') ~= "started" then
    return
end

local QBCore = exports['qb-core']:GetCoreObject()

-- Get player identifier
GetPlayerIdentifier = function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return nil end
    return Player.PlayerData.citizenid
end

-- Get player name
GetPlayerNameCustom = function(source)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return "Unknown" end
    return Player.PlayerData.charinfo.firstname .. " " .. Player.PlayerData.charinfo.lastname
end

-- Add money to player
AddMoney = function(source, amount)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    Player.Functions.AddMoney('cash', amount, 'quest-reward')
    return true
end

-- Check if player has admin permission
HasAdminPermission = function(source)
    return QBCore.Functions.HasPermission(source, 'admin') or IsPlayerAceAllowed(source, "group.admin")
end

-- Create useable item if using QB inventory
if GetResourceState('qb-inventory') == "started" then
    QBCore.Functions.CreateUseableItem("quest_tablet", function(source, item)
        TriggerClientEvent('ec-quests:qb-useitem', source)
    end)
end
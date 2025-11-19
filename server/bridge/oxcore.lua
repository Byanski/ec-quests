-- OX Core Bridge for Quest System
if GetResourceState('ox_core') ~= "started" then
    return
end

local Ox = require '@ox_core.lib.init'

-- Get player identifier
GetPlayerIdentifier = function(source)
    local player = Ox.GetPlayer(source)
    if not player then return nil end
    return player.stateId
end

-- Get player name
GetPlayerNameCustom = function(source)
    local player = Ox.GetPlayer(source)
    if not player then return "Unknown" end
    return ('%s %s'):format(player.get('firstName') or '', player.get('lastName') or ''):match("^%s*(.-)%s*$")
end

-- Add money to player
AddMoney = function(source, amount)
    local player = Ox.GetPlayer(source)
    if not player then return false end
    
    local account = player.getAccount('money')
    if account then
        account.add(amount)
        return true
    end
    return false
end

-- Check if player has admin permission
HasAdminPermission = function(source)
    local player = Ox.GetPlayer(source)
    if not player then return false end
    
    -- Check for admin group
    local groups = player.getGroups()
    if groups and (groups['admin'] or groups['superadmin'] or groups['god']) then
        return true
    end
    
    -- Fallback to ACE permissions
    return IsPlayerAceAllowed(source, "group.admin")
end
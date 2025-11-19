local refreshTime
local leaderboard = {}
local activeQuest = {}

-- Ensure bridge functions exist (fallback)
GetPlayerIdentifier = GetPlayerIdentifier or function(source)
    return GetPlayerIdentifierByType(source, 'license') or GetPlayerIdentifierByType(source, 'license2')
end

GetPlayerNameCustom = GetPlayerNameCustom or function(source)
    return GetPlayerName(source)
end

AddMoney = AddMoney or function(source, amount)
    -- Fallback - you'll need to implement this based on your framework
    print(('Player %s should receive $%d'):format(source, amount))
    return true
end

HasAdminPermission = HasAdminPermission or function(source)
    return IsPlayerAceAllowed(source, "group.admin")
end

-- Player registry functions
local function addPlayerToRegistry(identifier)
    local data = GetResourceKvpString('questPlayers')
    local players = data and json.decode(data) or {}
    if not players[identifier] then
        players[identifier] = true
        SetResourceKvp('questPlayers', json.encode(players))
    end
end

local function markQuestCompleted(source, questId)
    local identifier = GetPlayerIdentifier(source)
    if not identifier then
        print(('Failed to get identifier for player %s'):format(source))
        return
    end

    addPlayerToRegistry(identifier)

    local key = ('quests:%s'):format(identifier)
    local data = GetResourceKvpString(key)
    local completed = data and json.decode(data) or {}
    completed[questId] = true
    SetResourceKvp(key, json.encode(completed))
end

local function resetAllQuests()
    local data = GetResourceKvpString('questPlayers')
    local players = data and json.decode(data) or {}

    for identifier, _ in pairs(players) do
        local key = ('quests:%s'):format(identifier)
        SetResourceKvp(key, json.encode({}))
    end

    print('[EC-Quests] All player quest completions reset!')
end

local function getPlayerCompleted(source)
    local identifier = GetPlayerIdentifier(source)
    if not identifier then
        return {}
    end

    local key = ('quests:%s'):format(identifier)
    local data = GetResourceKvpString(key)
    local completed = data and json.decode(data) or {}
    return completed
end

-- Utility functions
local function Roll(chance)
    local roll = math.random(100)
    return roll <= chance
end

local function shuffle(tbl)
    local shuffled = {}
    for i = 1, #tbl do
        shuffled[i] = tbl[i]
    end
    for i = #shuffled, 2, -1 do
        local j = math.random(i)
        shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
    end
    return shuffled
end

local function loadQuest()
    activeQuest = {}
    local keys = {}
    for k in pairs(Config.Quests) do
        keys[#keys + 1] = k
    end

    local shuffledKeys = shuffle(keys)

    for _, k in ipairs(shuffledKeys) do
        local max = tonumber(Config.MaxQuest)
        if max and #activeQuest >= max then
            break
        end
        local quest = Config.Quests[k]
        if Roll(quest.chance) then
            quest["id"] = k
            activeQuest[#activeQuest + 1] = quest
        end
    end

    SetResourceKvp('activeQuest', json.encode(activeQuest))
    resetAllQuests()
    print(('[EC-Quests] Loaded %d active quests'):format(#activeQuest))
    return activeQuest
end

-- XP and leveling functions
local function getXP(source)
    local identifier = GetPlayerIdentifier(source)
    if not identifier then
        print(('Player %s has no valid identifier!'):format(source))
        return nil
    end

    local result = MySQL.query.await('SELECT player, level, xp, name FROM enhanced_quests_levels WHERE player = ?',
        {identifier})
    
    if result and result[1] then
        return result[1]
    end
    
    -- Create new player entry
    local playerName = GetPlayerNameCustom(source)
    MySQL.insert('INSERT INTO `enhanced_quests_levels` (player, level, xp, name) VALUES (?, ?, ?, ?)',
        {identifier, 1, 0, playerName})
    
    return {
        player = identifier,
        level = 1,
        xp = 0,
        name = playerName
    }
end

local function calculateXPForLevel(level)
    if level == 1 then
        return Config.XpToStart
    end
    return math.ceil(Config.XpToStart * (Config.XPmultiplier ^ (level - 1)))
end

local function processLevelUp(playerXP, xpGained)
    local totalXP = playerXP.xp + xpGained
    local currentLevel = playerXP.level
    
    while true do
        local xpNeeded = calculateXPForLevel(currentLevel)
        if totalXP < xpNeeded then
            break
        end
        totalXP = totalXP - xpNeeded
        currentLevel = currentLevel + 1
    end
    
    return currentLevel, totalXP
end

-- Resource lifecycle
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    -- Load refresh time
    local savedTime = GetResourceKvpString('refreshTime')
    refreshTime = tonumber(savedTime) or (Config.RefreshTime * 60 * 60)
    
    -- Load or generate quests
    local savedQuests = GetResourceKvpString('activeQuest')
    if savedQuests then
        activeQuest = json.decode(savedQuests) or {}
    end
    
    if not activeQuest or #activeQuest == 0 then
        activeQuest = loadQuest()
    end
    
    print(('[EC-Quests] Resource started, refresh time: %d seconds'):format(refreshTime))
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    SetResourceKvp('refreshTime', tostring(refreshTime))
end)

-- Quest refresh timer
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        refreshTime = refreshTime - 1
        if refreshTime <= 0 then
            refreshTime = Config.RefreshTime * 60 * 60
            SetResourceKvp('refreshTime', tostring(refreshTime))
            loadQuest()
        end
    end
end)

-- Callbacks
lib.callback.register('ec-quests:refreshTime', function(source)
    return refreshTime
end)

lib.callback.register('ec-quests:getXP', function(source)
    local player = getXP(source)
    if not player then
        return {1, 0, Config.XpToStart}
    end
    
    local xpToNext = calculateXPForLevel(player.level)
    return {player.level, player.xp, xpToNext}
end)

lib.callback.register('ec-quests:claimReward', function(source, ID)
    local Quest = Config.Quests[ID]
    if not Quest then
        print(('Invalid quest ID: %s'):format(ID))
        return false
    end

    -- Check if quest is already completed
    local completed = getPlayerCompleted(source)
    if completed[ID] then
        TriggerClientEvent('ox_lib:notify', source, {
            title = 'Quests',
            description = 'Quest already completed',
            type = 'error'
        })
        return false
    end

    -- Check if player has required items
    for _, v in ipairs(Quest.items) do
        local count = GetItemCount(source, v.name)
        if count < v.count then
            TriggerClientEvent('ox_lib:notify', source, {
                title = 'Quests',
                description = 'Missing required items',
                type = 'error'
            })
            return false
        end
    end

    -- Remove items
    for _, v in ipairs(Quest.items) do
        RemoveItem(source, v.name, v.count)
    end

    -- Process XP and level up
    local playerXP = getXP(source)
    if not playerXP then
        return false
    end

    local newLevel, newXP = processLevelUp(playerXP, Quest.xp)
    
    -- Mark quest as completed
    markQuestCompleted(source, ID)
    
    -- Update database
    local identifier = GetPlayerIdentifier(source)
    MySQL.update('UPDATE enhanced_quests_levels SET xp = ?, level = ? WHERE player = ?',
        {newXP, newLevel, identifier})
    
    -- Calculate and give reward
    local rewardAmount = math.floor(Quest.reward * (Config.RewardMultiplierPerLevel ^ (newLevel - 1)))
    AddMoney(source, rewardAmount)
    
    -- Notify player
    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Quest Completed!',
        description = ('Received $%d and %d XP'):format(rewardAmount, Quest.xp),
        type = 'success'
    })
    
    return true
end)

lib.callback.register('ec-quests:getQuest', function(source)
    local completed = getPlayerCompleted(source)
    local quests = {}
    
    for _, quest in ipairs(activeQuest) do
        local questCopy = {}
        for k, v in pairs(quest) do
            questCopy[k] = v
        end
        questCopy.claimed = completed[quest.id] == true
        quests[#quests + 1] = questCopy
    end

    return quests
end)

lib.callback.register('ec-quests:getLeaderboard', function(source)
    leaderboard = MySQL.query.await(
        'SELECT player, level, xp, name FROM enhanced_quests_levels ORDER BY level DESC, xp DESC LIMIT 100') or {}
    return leaderboard
end)

-- Commands
RegisterCommand('RefreshQuest', function(source)
    local src = source
    
    -- Server console
    if not src or src == 0 then
        print('[EC-Quests] Quests have been refreshed.')
        refreshTime = Config.RefreshTime * 60 * 60
        SetResourceKvp('refreshTime', tostring(refreshTime))
        loadQuest()
        return
    end
    
    -- Player command
    if HasAdminPermission(src) or debug.mode then
        refreshTime = Config.RefreshTime * 60 * 60
        SetResourceKvp('refreshTime', tostring(refreshTime))
        loadQuest()
        TriggerClientEvent('chat:addMessage', src, {
            args = {'^2[EC-Quests]', 'Quests have been refreshed.'}
        })
    else
        TriggerClientEvent('chat:addMessage', src, {
            args = {'^1[EC-Quests]', 'You do not have permission to use this command.'}
        })
    end
end, false)
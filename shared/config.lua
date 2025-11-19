Config = {}

-- UI Settings
Config.PrimaryColor = 'grape' -- UI theme color
Config.language = 'en' -- Default language (en, da)

-- Quest Settings
Config.UseItem = true -- Require quest_tablet item to open menu
Config.RefreshTime = 48 -- Time in hours to refresh quests (0.1 for testing)
Config.MaxQuest = 3 -- Max active quests (number or false for unlimited)

-- Progression Settings
Config.XpToStart = 500 -- XP required to reach level 2
Config.XPmultiplier = 1.1 -- XP multiplier per level (1.1 = 10% increase)
Config.RewardMultiplierPerLevel = 1.05 -- Money reward multiplier per level (1.05 = 5% increase)

-- Quest Definitions
Config.Quests = {
    {
        name = "The First Water",
        reward = 5000,
        xp = 750,
        items = {
            {name = "water", count = 5}
        },
        chance = 100
    },
    {
        name = "Magnus Lost Items",
        reward = 5000,
        xp = 750,
        items = {
            {name = "panties", count = 2},
            {name = "burger", count = 1}
        },
        chance = 100
    },
    {
        name = "Taco's Lost Items",
        reward = 7500,
        xp = 1000,
        items = {
            {name = "panties", count = 5},
            {name = "burger", count = 2}
        },
        chance = 80
    },
    {
        name = "Taco's Secret",
        reward = 50000,
        xp = 2500,
        items = {}, -- No items required
        chance = 20
    },
    {
        name = "Who Stole My Car",
        reward = 10000,
        xp = 6000,
        items = {}, -- No items required
        chance = 5
    }
}
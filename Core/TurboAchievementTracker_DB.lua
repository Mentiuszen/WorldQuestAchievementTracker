local addonName, TAT = ...
TAT.db = {}

local defaultSettings = {
    showLoginReminder = true,
    filterPetBattle = true,
    filterPvP = false,
    filterProfession = false,
    filterNormal = true,
    filterExpansions = {
        ["Legion"] = true,
        ["BfA"] = true,
        ["Shadowlands"] = true,
        ["Dragonflight"] = true,
        ["TheWarWithin"] = true,
        ["Midnight"] = true,
    },
    blacklist = {
        categories = {
            ["dungeons & raids"] = true,
            ["feats of strength"] = true,
            ["legacy"] = true,
            ["warsong gulch"] = true,
            ["arathi basin"] = true,
            ["eye of the storm"] = true,
            ["alterac valley"] = true,
            ["ashran"] = true,
            ["isle of conquest"] = true,
            ["wintergrasp"] = true,
            ["battle for gilneas"] = true,
            ["twin peaks"] = true,
            ["silvershard mines"] = true,
            ["temple of kotmogu"] = true,
            ["seething shore"] = true,
            ["deepwind gorge"] = true,
            ["deephaul ravine"] = true,
            ["rated battleground"] = true,
            ["arena"] = true,
            ["battlegrounds"] = true,
        },
        achievementNames = {
            ["resilient keystone"] = true,
        },
        achievementIDs = {
            [12089] = true,
            [12091] = true,
            [12092] = true,
            [12093] = true,
            [12094] = true,
            [12095] = true,
            [12096] = true,
            [12097] = true,
            [12098] = true,
            [12099] = true,
        }
    },
    minimap = {
        hide = false,
        minimapPos = 220,
    },
    ui = {
        scale = 1.0,
        x = 0,
        y = 0,
        point = "CENTER",
        relativePoint = "CENTER",
    }
}

-- db copy helper
local function CopyDefaults(src, dest)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if dest[k] == nil then
                dest[k] = {}
            end
            CopyDefaults(v, dest[k])
        else
            if dest[k] == nil then
                dest[k] = v
            end
        end
    end
end

-- Initialize DB
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then return end
    
    if not _G.TurboAchievementTracker_DB then
        _G.TurboAchievementTracker_DB = {}
    end
    
    TAT.db = _G.TurboAchievementTracker_DB
    
    -- Load defaults
    CopyDefaults(defaultSettings, TAT.db)
    
    -- Broadcast that database is loaded
    if TAT.OnDatabaseLoaded then
        TAT:OnDatabaseLoaded()
    end
    
    self:UnregisterEvent("ADDON_LOADED")
end)
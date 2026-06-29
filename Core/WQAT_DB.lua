local addonName, WQAT = ...
WQAT.db = {}

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

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, loadedAddonName)
    if loadedAddonName ~= addonName then return end
    
    if not _G.WQAT_DB then
        _G.WQAT_DB = {}
    end
    
    -- Migrate settings from legacy WorldQuestAchievementTracker_DB if present
    if _G.WorldQuestAchievementTracker_DB then
        CopyDefaults(_G.WorldQuestAchievementTracker_DB, _G.WQAT_DB)
        _G.WorldQuestAchievementTracker_DB = nil
    end
    
    -- Migrate settings from legacy TurboAchievementTracker_DB if present
    if _G.TurboAchievementTracker_DB then
        CopyDefaults(_G.TurboAchievementTracker_DB, _G.WQAT_DB)
        _G.TurboAchievementTracker_DB = nil
    end
    
    WQAT.db = _G.WQAT_DB
    CopyDefaults(defaultSettings, WQAT.db)
    
    if WQAT.OnDatabaseLoaded then
        WQAT:OnDatabaseLoaded()
    end
    
    self:UnregisterEvent("ADDON_LOADED")
end)

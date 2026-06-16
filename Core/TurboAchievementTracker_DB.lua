local addonName, TAT = ...
TAT.db = {}

local defaultSettings = {
    showLoginReminder = true,
    enableDebug = false,
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
    for k, v in pairs(defaultSettings) do
        if TAT.db[k] == nil then
            if type(v) == "table" then
                TAT.db[k] = {}
                for subK, subV in pairs(v) do
                    TAT.db[k][subK] = subV
                end
            else
                TAT.db[k] = v
            end
        else
            -- Ensure sub-tables are filled too
            if type(v) == "table" then
                for subK, subV in pairs(v) do
                    if TAT.db[k][subK] == nil then
                        TAT.db[k][subK] = subV
                    end
                end
            end
        end
    end
    
    -- Broadcast that database is loaded
    if TAT.OnDatabaseLoaded then
        TAT:OnDatabaseLoaded()
    end
    
    self:UnregisterEvent("ADDON_LOADED")
end)

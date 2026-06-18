local addonName, WQAT = ...

local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

if LDB and LDBIcon then
    local launcher = LDB:NewDataObject("WorldQuestAchievementTracker", {
        type = "launcher",
        text = "World Quest Achievement Tracker",
        icon = "Interface\\Icons\\ACHIEVEMENT_GUILD_DOCTORISIN",
        OnTooltipShow = function(tooltip)
            tooltip:ClearLines()
            tooltip:AddLine("|cffFFD100World Quest Achievement Tracker|r")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cff00ff00Left-click|r: Open window")
        end,
        OnClick = function(_, button)
            if button == "LeftButton" then
                WQAT:ToggleUI()
            end
        end,
    })

    function WQAT:InitializeMinimapButton()
        if not WQAT.db or not WQAT.db.minimap then return end
        LDBIcon:Register("WorldQuestAchievementTracker", launcher, WQAT.db.minimap)
        if WQAT.db.minimap.hide then
            LDBIcon:Hide("WorldQuestAchievementTracker")
        else
            LDBIcon:Show("WorldQuestAchievementTracker")
        end
    end

    function WQAT:UpdateMinimapButtonVisibility()
        if not WQAT.db or not WQAT.db.minimap then return end
        if WQAT.db.minimap.hide then
            LDBIcon:Hide("WorldQuestAchievementTracker")
        else
            LDBIcon:Show("WorldQuestAchievementTracker")
        end
    end
else
    function WQAT:InitializeMinimapButton()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[World Quest Achievement Tracker]:|r LibDBIcon-1.0 or LibDataBroker-1.1 not found. Minimap button disabled.")
    end
    function WQAT:UpdateMinimapButtonVisibility()
    end
end

local dbHook = WQAT.OnDatabaseLoaded
function WQAT:OnDatabaseLoaded()
    if dbHook then dbHook(self) end
    WQAT:InitializeMinimapButton()
end
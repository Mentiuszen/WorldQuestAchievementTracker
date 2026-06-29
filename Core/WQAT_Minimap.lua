local addonName, WQAT = ...

local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
local LDBIcon = LibStub and LibStub("LibDBIcon-1.0", true)

if LDB and LDBIcon then
    local launcher = LDB:NewDataObject("WQAT", {
        type = "launcher",
        text = "WQAT",
        icon = "Interface\\Icons\\ACHIEVEMENT_GUILD_DOCTORISIN",
        OnTooltipShow = function(tooltip)
            tooltip:ClearLines()
            tooltip:AddLine("|cffFFD100WQAT|r")
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
        LDBIcon:Register("WQAT", launcher, WQAT.db.minimap)
        if WQAT.db.minimap.hide then
            LDBIcon:Hide("WQAT")
        else
            LDBIcon:Show("WQAT")
        end
    end

    function WQAT:UpdateMinimapButtonVisibility()
        if not WQAT.db or not WQAT.db.minimap then return end
        if WQAT.db.minimap.hide then
            LDBIcon:Hide("WQAT")
        else
            LDBIcon:Show("WQAT")
        end
    end
else
    function WQAT:InitializeMinimapButton()
        DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[WQAT]:|r LibDBIcon-1.0 or LibDataBroker-1.1 not found. Minimap button disabled.")
    end
    function WQAT:UpdateMinimapButtonVisibility()
    end
end

local dbHook = WQAT.OnDatabaseLoaded
function WQAT:OnDatabaseLoaded()
    if dbHook then dbHook(self) end
    WQAT:InitializeMinimapButton()
end

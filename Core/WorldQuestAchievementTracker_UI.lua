local addonName, WQAT = ...
WQAT.UI = {}

local activeTab = "achievements"
local mainFrame
local framePool = {}

local COLOR_BG = {0.05, 0.05, 0.05, 0.95}
local COLOR_TITLE = {0.08, 0.08, 0.08, 1}
local COLOR_SIDEBAR = {0.04, 0.04, 0.04, 1}
local COLOR_BORDER = {0.2, 0.2, 0.2, 1}
local COLOR_CARD = {0.1, 0.1, 0.1, 0.9}
local COLOR_CARD_HOVER = {0.15, 0.15, 0.15, 1}

local function UpdateAchievementsPage()
    local page = mainFrame.achievementsPage
    if not page then return end
    
    if not page.filtersFrame then
        local ff = CreateFrame("Frame", nil, page)
        ff:SetSize(590, 60)
        ff:SetPoint("TOPLEFT", 10, -5)
        page.filtersFrame = ff
        
        ff.cbPet = mQoL_Styles.CreateCustomCheckbox(ff, "Pet Battle")
        ff.cbPet:SetPoint("TOPLEFT", 15, -5)
        ff.cbPet.OnValueChanged = function(_, checked)
            WQAT.db.filterPetBattle = checked
            WQAT:RefreshUI()
        end
        
        ff.cbPvP = mQoL_Styles.CreateCustomCheckbox(ff, "PvP")
        ff.cbPvP:SetPoint("TOPLEFT", 160, -5)
        ff.cbPvP.OnValueChanged = function(_, checked)
            WQAT.db.filterPvP = checked
            WQAT:RefreshUI()
        end
        
        ff.cbProf = mQoL_Styles.CreateCustomCheckbox(ff, "Profession")
        ff.cbProf:SetPoint("TOPLEFT", 260, -5)
        ff.cbProf.OnValueChanged = function(_, checked)
            WQAT.db.filterProfession = checked
            WQAT:RefreshUI()
        end
        
        ff.cbNorm = mQoL_Styles.CreateCustomCheckbox(ff, "Normal")
        ff.cbNorm:SetPoint("TOPLEFT", 400, -5)
        ff.cbNorm.OnValueChanged = function(_, checked)
            WQAT.db.filterNormal = checked
            WQAT:RefreshUI()
        end
        
        ff.cbLegion = mQoL_Styles.CreateCustomCheckbox(ff, "Legion")
        ff.cbLegion:SetPoint("TOPLEFT", 15, -30)
        ff.cbLegion.OnValueChanged = function(_, checked)
            WQAT.db.filterExpansions["Legion"] = checked
            WQAT:RefreshUI()
        end
        
        ff.cbBfA = mQoL_Styles.CreateCustomCheckbox(ff, "BfA")
        ff.cbBfA:SetPoint("TOPLEFT", 90, -30)
        ff.cbBfA.OnValueChanged = function(_, checked)
            WQAT.db.filterExpansions["BfA"] = checked
            WQAT:RefreshUI()
        end
        
        ff.cbSL = mQoL_Styles.CreateCustomCheckbox(ff, "Shadowlands")
        ff.cbSL:SetPoint("TOPLEFT", 150, -30)
        ff.cbSL.OnValueChanged = function(_, checked)
            WQAT.db.filterExpansions["Shadowlands"] = checked
            WQAT:RefreshUI()
        end
        
        ff.cbDF = mQoL_Styles.CreateCustomCheckbox(ff, "Dragonflight")
        ff.cbDF:SetPoint("TOPLEFT", 265, -30)
        ff.cbDF.OnValueChanged = function(_, checked)
            WQAT.db.filterExpansions["Dragonflight"] = checked
            WQAT:RefreshUI()
        end
        
        ff.cbTWW = mQoL_Styles.CreateCustomCheckbox(ff, "The War Within")
        ff.cbTWW:SetPoint("TOPLEFT", 380, -30)
        ff.cbTWW.OnValueChanged = function(_, checked)
            WQAT.db.filterExpansions["TheWarWithin"] = checked
            WQAT:RefreshUI()
        end
        
        ff.cbMidnight = mQoL_Styles.CreateCustomCheckbox(ff, "Midnight")
        ff.cbMidnight:SetPoint("TOPLEFT", 510, -30)
        ff.cbMidnight.OnValueChanged = function(_, checked)
            WQAT.db.filterExpansions["Midnight"] = checked
            WQAT:RefreshUI()
        end
        
        local sep = ff:CreateTexture(nil, "ARTWORK")
        sep:SetColorTexture(0.25, 0.25, 0.25, 1)
        sep:SetHeight(1)
        sep:SetPoint("TOPLEFT", 5, -55)
        sep:SetPoint("TOPRIGHT", -5, -55)
    end
    
    page.filtersFrame.cbPet:SetValue(WQAT.db.filterPetBattle)
    page.filtersFrame.cbPvP:SetValue(WQAT.db.filterPvP)
    page.filtersFrame.cbProf:SetValue(WQAT.db.filterProfession)
    page.filtersFrame.cbNorm:SetValue(WQAT.db.filterNormal)
    page.filtersFrame.cbLegion:SetValue(WQAT.db.filterExpansions["Legion"])
    page.filtersFrame.cbBfA:SetValue(WQAT.db.filterExpansions["BfA"])
    page.filtersFrame.cbSL:SetValue(WQAT.db.filterExpansions["Shadowlands"])
    page.filtersFrame.cbDF:SetValue(WQAT.db.filterExpansions["Dragonflight"])
    page.filtersFrame.cbTWW:SetValue(WQAT.db.filterExpansions["TheWarWithin"])
    page.filtersFrame.cbMidnight:SetValue(WQAT.db.filterExpansions["Midnight"])
    
    if not page.scrollFrame then
        local sf, child = mQoL_Templates.CreateScrollPanel(page, {
            width = 590,
            height = 360,
        })
        sf:ClearAllPoints()
        sf:SetPoint("TOPLEFT", 10, -70)
        page.scrollFrame = sf
        page.scrollChild = child
    end
    
    if page.rows then
        for _, row in ipairs(page.rows) do
            row:Hide()
            row:ClearAllPoints()
            table.insert(framePool, row)
        end
        wipe(page.rows)
    else
        page.rows = {}
    end
    
    local filteredQuests = WQAT:GetFilteredQuests()
    local progressableList = {}
    local achievementsMap = {}
    
    for _, q in ipairs(filteredQuests) do
        if not achievementsMap[q.achievementID] then
            achievementsMap[q.achievementID] = {
                id = q.achievementID,
                name = q.achievementName,
                quests = {}
            }
            table.insert(progressableList, achievementsMap[q.achievementID])
        end
        table.insert(achievementsMap[q.achievementID].quests, q)
    end
    
    for _, ach in ipairs(progressableList) do
        local numCriteria = GetAchievementNumCriteria(ach.id)
        local completedCount = 0
        for i = 1, numCriteria do
            local _, _, completed = GetAchievementCriteriaInfo(ach.id, i)
            if completed then completedCount = completedCount + 1 end
        end
        ach.completedCount = completedCount
        ach.numCriteria = numCriteria
    end
    
    table.sort(progressableList, function(a, b)
        if a.completedCount ~= b.completedCount then
            return a.completedCount > b.completedCount
        elseif a.numCriteria ~= b.numCriteria then
            return a.numCriteria > b.numCriteria
        else
            return a.name < b.name
        end
    end)
    
    if #progressableList == 0 then
        local noAch = CreateFrame("Frame", nil, page.scrollChild)
        noAch:SetSize(570, 100)
        noAch:SetPoint("TOPLEFT", 5, 0)
        table.insert(page.rows, noAch)
        
        local txt = noAch:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        txt:SetPoint("CENTER", 0, 0)
        txt:SetWidth(550)
        txt:SetJustifyH("CENTER")
        txt:SetText("No progressable achievements found.\n\nAll achievements matching active World Quests are either completed or filtered out.")
        txt:SetTextColor(0.6, 0.6, 0.6)
        
        page.scrollChild:SetHeight(100)
        if page.scrollFrame.scrollbar and page.scrollFrame.scrollbar.UpdateScrollbar then
            page.scrollFrame.scrollbar:UpdateScrollbar()
        end
        return
    end
    
    local yOffset = 10
    for _, ach in ipairs(progressableList) do
        local countText = string.format("(%d/%d criteria completed)", ach.completedCount, ach.numCriteria)
        local rowHeight = 36 + (#ach.quests * 48)
        
        local row = CreateFrame("Frame", nil, page.scrollChild)
        row:SetSize(550, rowHeight)
        row:SetPoint("TOPLEFT", 10, -yOffset)
        mQoL_Templates.SetBackdrop(row, {
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        }, COLOR_CARD, COLOR_BORDER)
        table.insert(page.rows, row)
        
        row:SetScript("OnEnter", function(self)
            self.mQoL_bg:SetColorTexture(unpack(COLOR_CARD_HOVER))
        end)
        row:SetScript("OnLeave", function(self)
            self.mQoL_bg:SetColorTexture(unpack(COLOR_CARD))
        end)
        
        local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 12, -8)
        title:SetText(string.format("%s  |cff888888%s|r", ach.name, countText))
        title:SetTextColor(1, 0.82, 0)
        
        local subY = -30
        for _, q in ipairs(ach.quests) do
            local subRow = CreateFrame("Frame", nil, row)
            subRow:SetSize(530, 42)
            subRow:SetPoint("TOPLEFT", 10, subY)
            mQoL_Templates.SetBackdrop(subRow, {
                edgeFile = "Interface\\Buttons\\WHITE8x8",
                edgeSize = 1,
            }, {0.07, 0.07, 0.07, 1}, COLOR_BORDER)
            
            local qTitle = subRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            qTitle:SetPoint("TOPLEFT", 8, -5)
            qTitle:SetText(string.format("%s (%s — %s)", q.title, q.zoneName, q.expansion or "Other"))
            
            local quantity, reqQuantity
            if q.criteriaIndex then
                local _, _, _, qQuantity, qReqQuantity = GetAchievementCriteriaInfo(q.achievementID, q.criteriaIndex)
                quantity = qQuantity
                reqQuantity = qReqQuantity
            end
            
            local critText = q.criteriaString
            if reqQuantity and reqQuantity > 1 then
                if not string.find(q.criteriaString, "%d+/%d+") then
                    critText = string.format("%s (%d/%d)", q.criteriaString, quantity or 0, reqQuantity)
                end
            end
            local qCriteria = subRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            qCriteria:SetPoint("BOTTOMLEFT", 8, 5)
            qCriteria:SetText(string.format("|cff888888Needs criteria:|r |cff00ff00%s|r", critText))
            
            local trackBtn = mQoL_Styles.CreateCustomButton(subRow, "Track", 75, 22)
            trackBtn:SetScript("OnClick", function()
                C_SuperTrack.SetSuperTrackedQuestID(q.questID)
                if C_ContentTracking and C_ContentTracking.StartTracking then
                    C_ContentTracking.StartTracking(Enum.ContentTrackingType.Achievement, q.achievementID)
                elseif AddTrackedAchievement then
                    AddTrackedAchievement(q.achievementID)
                end
                UIFrameFadeOut(mainFrame, 0.15, 1, 0)
                C_Timer.After(0.15, function()
                    mainFrame:Hide()
                end)
                print(string.format("|cff00ff00[World Quest Achievement Tracker]:|r Tracking set to |cffffff00%s|r!", q.title))
            end)
            trackBtn:SetPoint("RIGHT", -6, 0)
            
            subY = subY - 48
        end
        
        yOffset = yOffset + rowHeight + 10
    end
    
    page.scrollChild:SetHeight(yOffset + 10)
    if page.scrollFrame.scrollbar and page.scrollFrame.scrollbar.UpdateScrollbar then
        page.scrollFrame.scrollbar:UpdateScrollbar()
    end
end

local function AddOptionRow(parent, yOffset, name, controlType, controlParams, extra, applyFunc)
    local leftMargin = 15
    local labelWidth = 280
    local spacing = 10
    local rightMargin = 15
    local rowWidth = 550
    local rowHeight = 30
    local sliderInputSpacing = 8
    
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(rowWidth, rowHeight)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -yOffset)
    
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", row, "LEFT", leftMargin, 0)
    label:SetSize(labelWidth, rowHeight)
    label:SetJustifyH("LEFT")
    label:SetJustifyV("MIDDLE")
    label:SetText(name)
    label:SetTextColor(1, 0.82, 0)
    
    local uiAreaWidth = rowWidth - leftMargin - labelWidth - spacing - rightMargin
    if extra and #extra > 0 then
        for _, frame in ipairs(extra) do
            uiAreaWidth = uiAreaWidth - frame:GetWidth() - sliderInputSpacing
        end
    end
    if applyFunc then
        local btnWidth = controlParams.applyWidth or 50
        uiAreaWidth = uiAreaWidth - btnWidth - sliderInputSpacing
    end
    
    local uiArea = CreateFrame("Frame", nil, row)
    uiArea:SetPoint("LEFT", label, "RIGHT", spacing, 0)
    uiArea:SetSize(uiAreaWidth, rowHeight)
    
    local control
    local contentOffset = 0
    
    if controlType == "checkbox" then
        control = mQoL_Styles.CreateCustomCheckbox(uiArea, "")
        control:SetSize(20, 20)
        control:SetPoint("LEFT", uiArea, "LEFT", 0, 0)
        if controlParams.value ~= nil then
            control:SetValue(controlParams.value)
        end
        if controlParams.onValueChanged then
            control.OnValueChanged = controlParams.onValueChanged
        end
        
    elseif controlType == "slider" then
        local sliderRowHeight = 45
        row:SetHeight(sliderRowHeight)
        uiArea:SetHeight(sliderRowHeight)
        contentOffset = (sliderRowHeight - rowHeight) / 2
        
        label:ClearAllPoints()
        label:SetPoint("LEFT", row, "LEFT", leftMargin, contentOffset)
        
        control = mQoL_Styles.CreateCustomSlider(
            uiArea,
            "",
            controlParams.min,
            controlParams.max,
            controlParams.step,
            uiAreaWidth,
            5
        )
        control:SetPoint("LEFT", uiArea, "LEFT", 0, 0)
        
        if controlParams.value then
            control:SetValue(controlParams.value)
        end
        
        if controlParams.onValueChanged then
            control:SetScript("OnValueChanged", function(self)
                self:UpdateThumb()
                local val = self:GetValue()
                controlParams.onValueChanged(self, val)
            end)
        end
        
        if extra then
            local prev = control
            for _, frame in ipairs(extra) do
                frame:SetParent(uiArea)
                frame:ClearAllPoints()
                frame:SetPoint("LEFT", prev, "RIGHT", sliderInputSpacing, 0)
                prev = frame
            end
        end
    end
    
    if applyFunc then
        local customLabel = controlParams.applyLabel or "Apply"
        local customWidth = controlParams.applyWidth or 50
        
        local applyBtn = mQoL_Styles.CreateCustomButton(row, customLabel)
        applyBtn:SetSize(customWidth, 20)
        applyBtn:SetPoint("RIGHT", row, "RIGHT", -rightMargin, contentOffset)
        
        applyBtn:SetScript("OnClick", function()
            applyFunc()
        end)
        row.applyBtn = applyBtn
    end
    
    return row, control
end

local function UpdateSettingsPage()
    local page = mainFrame.settingsPage
    if not page then return end
    
    if not page.scrollFrame then
        local sf, child = mQoL_Templates.CreateScrollPanel(page, {
            width = 590,
            height = 420,
        })
        sf:ClearAllPoints()
        sf:SetPoint("TOPLEFT", 10, -10)
        page.scrollFrame = sf
        page.scrollChild = child
        
        local yOffset = 15
        
        local generalLabel = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        generalLabel:SetPoint("TOPLEFT", 15, -yOffset)
        generalLabel:SetText("General Settings")
        generalLabel:SetTextColor(1, 0.82, 0)
        
        yOffset = yOffset + 25
        
        local rowMinimap, cbMinimap = AddOptionRow(child, yOffset, "Hide Minimap Button", "checkbox", {
            value = WQAT.db.minimap.hide,
            onValueChanged = function(_, checked)
                WQAT.db.minimap.hide = checked
                WQAT:UpdateMinimapButtonVisibility()
            end
        })
        page.cbMinimap = cbMinimap
        yOffset = yOffset + rowMinimap:GetHeight() + 15
        
        local rowReminder, cbReminder = AddOptionRow(child, yOffset, "Show login chat reminder of needed quests", "checkbox", {
            value = WQAT.db.showLoginReminder,
            onValueChanged = function(_, checked)
                WQAT.db.showLoginReminder = checked
            end
        })
        page.cbReminder = cbReminder
        yOffset = yOffset + rowReminder:GetHeight() + 15
        
        local scaleEditBox = mQoL_Styles.CreateCustomInputBox(child, 40, 20)
        scaleEditBox.bg = scaleEditBox:CreateTexture(nil, "BACKGROUND")
        scaleEditBox.bg:SetAllPoints()
        scaleEditBox.bg:SetColorTexture(0.15, 0.15, 0.15, 1)
        scaleEditBox.border = mQoL_Templates.CreateFrameBorder(scaleEditBox, 1, {0.25, 0.25, 0.25, 1})
        
        scaleEditBox:SetScript("OnTextChanged", function(self)
            local text = self:GetText()
            local cleanText = text:gsub("[^0-9.]", "")
            local firstDot = cleanText:find("%.")
            if firstDot then
                local before = cleanText:sub(1, firstDot)
                local after = cleanText:sub(firstDot + 1):gsub("%.", "")
                cleanText = before .. after
            end
            if cleanText ~= text then
                self:SetText(cleanText)
            end
        end)
        
        local scaleSlider
        local function ApplyScaleValue(val)
            val = tonumber(val)
            if val then
                val = math.max(0.7, math.min(1.5, val))
                val = math.floor(val / 0.05 + 0.5) * 0.05
                WQAT.db.ui.scale = val
                scaleSlider:SetValue(val)
                scaleSlider:UpdateThumb()
                scaleEditBox:SetText(string.format("%.2f", val))
                mainFrame:SetScale(val)
            else
                scaleEditBox:SetText(string.format("%.2f", WQAT.db.ui.scale))
            end
        end
        
        scaleEditBox:SetScript("OnEnterPressed", function(self)
            ApplyScaleValue(self:GetText())
            self:ClearFocus()
        end)
        
        local rowScale, slider = AddOptionRow(child, yOffset, "UI Scale", "slider", {
            value = WQAT.db.ui.scale,
            min = 0.7,
            max = 1.5,
            step = 0.05,
            applyLabel = "Apply",
            applyWidth = 50,
            onValueChanged = function(_, value)
                scaleEditBox:SetText(string.format("%.2f", value))
            end
        }, {scaleEditBox}, function()
            ApplyScaleValue(scaleEditBox:GetText())
        end)
        
        scaleSlider = slider
        page.scaleSlider = slider
        page.scaleEditBox = scaleEditBox
        
        yOffset = yOffset + rowScale:GetHeight() + 25
        
        local scanBtn = mQoL_Styles.CreateCustomButton(child, "Run Manual Scan", 200, 30)
        scanBtn:SetPoint("TOPLEFT", child, "TOPLEFT", 25, -yOffset)
        scanBtn:SetScript("OnClick", function()
            WQAT:RunScan(true)
            print("|cff00ff00[World Quest Achievement Tracker]:|r Manual scan completed successfully.")
        end)
        page.scanBtn = scanBtn
        
        yOffset = yOffset + 45
        child:SetHeight(yOffset)
    end
    
    page.cbMinimap:SetValue(WQAT.db.minimap.hide)
    page.cbReminder:SetValue(WQAT.db.showLoginReminder)
    page.scaleSlider:SetValue(WQAT.db.ui.scale)
    page.scaleSlider:UpdateThumb()
    page.scaleEditBox:SetText(string.format("%.2f", WQAT.db.ui.scale))
    
    if page.scrollFrame.scrollbar and page.scrollFrame.scrollbar.UpdateScrollbar then
        page.scrollFrame.scrollbar:UpdateScrollbar()
    end
end

local function SelectTab(tab)
    activeTab = tab
    WQAT:RefreshUI()
end

function WQAT:RefreshUI()
    if not mainFrame or not mainFrame:IsShown() then return end
    
    mainFrame.achievementsPage:Hide()
    mainFrame.settingsPage:Hide()
    
    if activeTab == "achievements" then
        mQoL_Templates.SetBackdrop(mainFrame.btnAchievements, {
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        }, {0.18, 0.18, 0.18, 1}, {1, 0.82, 0, 1})
        
        mQoL_Templates.SetBackdrop(mainFrame.btnSettings, {
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        }, {0.1, 0.1, 0.1, 1}, COLOR_BORDER)
        
        mainFrame.btnAchievements.text:SetTextColor(1, 0.82, 0)
        mainFrame.btnSettings.text:SetTextColor(0.7, 0.7, 0.7)
        
        mainFrame.achievementsPage:Show()
        UpdateAchievementsPage()
    elseif activeTab == "settings" then
        mQoL_Templates.SetBackdrop(mainFrame.btnAchievements, {
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        }, {0.1, 0.1, 0.1, 1}, COLOR_BORDER)
        
        mQoL_Templates.SetBackdrop(mainFrame.btnSettings, {
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        }, {0.18, 0.18, 0.18, 1}, {1, 0.82, 0, 1})
        
        mainFrame.btnAchievements.text:SetTextColor(0.7, 0.7, 0.7)
        mainFrame.btnSettings.text:SetTextColor(1, 0.82, 0)
        
        mainFrame.settingsPage:Show()
        UpdateSettingsPage()
    end
end

function WQAT:UpdateUI()
    if mainFrame and mainFrame:IsShown() then
        WQAT:RefreshUI()
    end
end

function WQAT:ToggleUI()
    if not mainFrame then
        WQAT:CreateMainFrame()
    end
    
    if mainFrame:IsShown() then
        UIFrameFadeOut(mainFrame, 0.15, 1, 0)
        C_Timer.After(0.15, function()
            mainFrame:Hide()
        end)
    else
        mainFrame:SetAlpha(0)
        mainFrame:Show()
        UIFrameFadeIn(mainFrame, 0.15, 0, 1)
        WQAT:RefreshUI()
    end
end

function WQAT:CreateMainFrame()
    local f = CreateFrame("Frame", "WQAT_MainFrame", UIParent)
    mainFrame = f
    
    table.insert(UISpecialFrames, "WQAT_MainFrame")
    
    f:SetScale(WQAT.db.ui.scale or 1.0)
    f:SetSize(800, 480)
    f:SetPoint(WQAT.db.ui.point, UIParent, WQAT.db.ui.relativePoint, WQAT.db.ui.x, WQAT.db.ui.y)
    
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")
    f:Hide()
    
    mQoL_Templates.SetBackdrop(f, {
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    }, COLOR_BG, COLOR_BORDER)
    
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(30)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    mQoL_Templates.SetBackdrop(titleBar, {
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    }, COLOR_TITLE, COLOR_BORDER)
    
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        WQAT.db.ui.point = point
        WQAT.db.ui.relativePoint = relativePoint
        WQAT.db.ui.x = x
        WQAT.db.ui.y = y
    end)
    
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText("World Quest Achievement Tracker")
    titleText:SetTextColor(1, 0.82, 0)
    
    local closeBtn = mQoL_Templates.CreateCloseButton(titleBar, 20, function()
        UIFrameFadeOut(f, 0.15, 1, 0)
        C_Timer.After(0.15, function()
            f:Hide()
        end)
    end)
    closeBtn:SetPoint("RIGHT", -8, 0)
    
    local sidebar = CreateFrame("Frame", "WQAT_Sidebar", f)
    sidebar:SetSize(180, 450)
    sidebar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    mQoL_Templates.SetBackdrop(sidebar, {
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    }, COLOR_SIDEBAR, COLOR_BORDER)
    f.sidebar = sidebar
    
    local function CreateNavButton(label, yOffset, tabName)
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(160, 32)
        btn:SetPoint("TOP", 0, yOffset)
        mQoL_Templates.SetBackdrop(btn, {
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        }, {0.1, 0.1, 0.1, 1}, COLOR_BORDER)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btn.text:SetPoint("LEFT", 12, 0)
        btn.text:SetText(label)
        
        btn:SetScript("OnClick", function() SelectTab(tabName) end)
        btn:SetScript("OnEnter", function(self)
            if activeTab ~= tabName then
                self.mQoL_bg:SetColorTexture(0.15, 0.15, 0.15, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeTab ~= tabName then
                self.mQoL_bg:SetColorTexture(0.1, 0.1, 0.1, 1)
            end
        end)
        
        return btn
    end
    
    f.btnAchievements = CreateNavButton("Achievements", -20, "achievements")
    f.btnSettings = CreateNavButton("Settings", -60, "settings")
    
    local verText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    verText:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMLEFT", 12, 10)
    local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version")
        or GetAddOnMetadata and GetAddOnMetadata(addonName, "Version")
        or "1.0.0"
    verText:SetText("v" .. version)
    
    local authText = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    authText:SetPoint("BOTTOMRIGHT", sidebar, "BOTTOMRIGHT", -12, 10)
    authText:SetText("by Mentiuszen")
    
    local pageContainer = CreateFrame("Frame", nil, f)
    pageContainer:SetSize(610, 440)
    pageContainer:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, -10)
    f.pageContainer = pageContainer
    
    f.achievementsPage = CreateFrame("Frame", nil, pageContainer)
    f.achievementsPage:SetAllPoints()
    f.achievementsPage:Hide()
    
    f.settingsPage = CreateFrame("Frame", nil, pageContainer)
    f.settingsPage:SetAllPoints()
    f.settingsPage:Hide()
end

SLASH_WQAT1 = "/wqat"
SlashCmdList["WQAT"] = function(msg)
    local cmd = string.lower(strtrim(msg or ""))
    if cmd == "scan" then
        WQAT:RunScan(true)
        DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[World Quest Achievement Tracker]:|r Manual scan completed.")
    else
        WQAT:ToggleUI()
    end
end
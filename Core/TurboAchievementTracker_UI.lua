local addonName, TAT = ...
TAT.UI = {}

local activeTab = "quests"
local mainFrame

-- UI Styling Constants
local COLOR_BG = {0.05, 0.05, 0.05, 0.95}
local COLOR_TITLE = {0.08, 0.08, 0.08, 1}
local COLOR_SIDEBAR = {0.04, 0.04, 0.04, 1}
local COLOR_BORDER = {0.2, 0.2, 0.2, 1}
local COLOR_CARD = {0.1, 0.1, 0.1, 0.9}
local COLOR_CARD_HOVER = {0.15, 0.15, 0.15, 1}

-- Helper: Set solid color backdrop with a thin border
local function ApplyFlatStyle(frame, bgColor, borderColor)
    if not frame.tatBg then
        frame.tatBg = frame:CreateTexture(nil, "BACKGROUND")
        frame.tatBg:SetAllPoints()
    end
    frame.tatBg:SetColorTexture(unpack(bgColor))
    
    if borderColor then
        if not frame.tatBorder then
            frame.tatBorder = CreateFrame("Frame", nil, frame)
            frame.tatBorder:SetAllPoints()
            
            frame.tatBorder.top = frame.tatBorder:CreateTexture(nil, "OVERLAY")
            frame.tatBorder.top:SetHeight(1)
            frame.tatBorder.top:SetPoint("TOPLEFT", 0, 0)
            frame.tatBorder.top:SetPoint("TOPRIGHT", 0, 0)
            
            frame.tatBorder.bottom = frame.tatBorder:CreateTexture(nil, "OVERLAY")
            frame.tatBorder.bottom:SetHeight(1)
            frame.tatBorder.bottom:SetPoint("BOTTOMLEFT", 0, 0)
            frame.tatBorder.bottom:SetPoint("BOTTOMRIGHT", 0, 0)
            
            frame.tatBorder.left = frame.tatBorder:CreateTexture(nil, "OVERLAY")
            frame.tatBorder.left:SetWidth(1)
            frame.tatBorder.left:SetPoint("TOPLEFT", 0, 0)
            frame.tatBorder.left:SetPoint("BOTTOMLEFT", 0, 0)
            
            frame.tatBorder.right = frame.tatBorder:CreateTexture(nil, "OVERLAY")
            frame.tatBorder.right:SetWidth(1)
            frame.tatBorder.right:SetPoint("TOPRIGHT", 0, 0)
            frame.tatBorder.right:SetPoint("BOTTOMRIGHT", 0, 0)
        end
        
        frame.tatBorder.top:SetColorTexture(unpack(borderColor))
        frame.tatBorder.bottom:SetColorTexture(unpack(borderColor))
        frame.tatBorder.left:SetColorTexture(unpack(borderColor))
        frame.tatBorder.right:SetColorTexture(unpack(borderColor))
    end
end

-- Custom Button Factory (mQoL style)
local function CreateTATButton(parent, text, width, height, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 100, height or 24)
    
    ApplyFlatStyle(btn, {0.15, 0.15, 0.15, 1}, COLOR_BORDER)
    
    btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    btn.text:SetPoint("CENTER")
    btn.text:SetText(text or "Button")
    btn.text:SetTextColor(0.9, 0.9, 0.9)
    
    btn:SetScript("OnEnter", function(self)
        self.tatBg:SetColorTexture(0.25, 0.25, 0.25, 1)
        self.text:SetTextColor(1, 1, 1)
    end)
    
    btn:SetScript("OnLeave", function(self)
        self.tatBg:SetColorTexture(0.15, 0.15, 0.15, 1)
        self.text:SetTextColor(0.9, 0.9, 0.9)
    end)
    
    if onClick then
        btn:SetScript("OnClick", onClick)
    end
    
    return btn
end

-- Checkbox Factory utilizing UICheckButtonTemplate
local function CreateTATCheckbox(parent, text, initialValue, onClick)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetChecked(initialValue)
    
    if cb.Text then
        cb.Text:SetFontObject("GameFontHighlight")
        cb.Text:SetText(text)
        cb.Text:SetTextColor(0.9, 0.9, 0.9)
        cb.Text:ClearAllPoints()
        cb.Text:SetPoint("LEFT", cb, "RIGHT", 6, 0)
    end
    
    cb:SetScript("OnClick", function(self)
        if onClick then
            onClick(self:GetChecked())
        end
    end)
    
    return cb
end

-- Scroll Frame Factory
local function CreateTATScrollFrame(parent, width, height)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    sf:SetSize(width, height)
    
    local child = CreateFrame("Frame", nil, sf)
    child:SetSize(width - 20, 1)
    sf:SetScrollChild(child)
    
    local sb = CreateFrame("Slider", nil, sf)
    sb:SetWidth(8)
    sb:SetPoint("TOPRIGHT", sf, "TOPRIGHT", -2, 0)
    sb:SetPoint("BOTTOMRIGHT", sf, "BOTTOMRIGHT", -2, 0)
    sb:SetOrientation("VERTICAL")
    
    sb.bg = sb:CreateTexture(nil, "BACKGROUND")
    sb.bg:SetAllPoints()
    sb.bg:SetColorTexture(0.08, 0.08, 0.08, 1)
    
    sb.thumb = sb:CreateTexture(nil, "OVERLAY")
    sb.thumb:SetSize(8, 30)
    sb.thumb:SetColorTexture(0.4, 0.4, 0.4, 0.8)
    sb:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local tt = sb:GetThumbTexture()
    tt:SetAllPoints(sb.thumb)
    
    sb:SetMinMaxValues(0, 0)
    sb:SetValue(0)
    
    sb:SetScript("OnValueChanged", function(self, value)
        sf:SetVerticalScroll(value)
    end)
    
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local minVal, maxVal = sb:GetMinMaxValues()
        local cur = sb:GetValue()
        local nextVal = cur - delta * 25
        sb:SetValue(math.max(minVal, math.min(maxVal, nextVal)))
    end)
    
    sf.sb = sb
    sf.child = child
    
    function sf:UpdateScrollHeight(contentHeight)
        local frameHeight = sf:GetHeight()
        local scrollMax = math.max(0, contentHeight - frameHeight)
        sb:SetMinMaxValues(0, scrollMax)
        
        local thumbHeight = frameHeight
        if contentHeight > frameHeight then
            thumbHeight = (frameHeight / contentHeight) * frameHeight
            sb.thumb:SetHeight(math.max(15, thumbHeight))
            sb:Show()
        else
            sb:Hide()
        end
        
        child:SetHeight(contentHeight)
    end
    
    return sf, child
end

-- Render Needed Quests Tab content
local function RenderQuests(parent)
    local sf, child = CreateTATScrollFrame(parent, 590, 420)
    sf:SetPoint("TOPLEFT", 10, -10)
    
    local yOffset = 0
    
    if #TAT.activeNeededQuests == 0 then
        local noQuests = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        noQuests:SetPoint("TOPLEFT", 15, -40)
        noQuests:SetPoint("TOPRIGHT", -15, -40)
        noQuests:SetJustifyH("CENTER")
        noQuests:SetText("No active needed World Quests found.\n\nMake sure your filters in the Settings tab are configured correctly.")
        noQuests:SetTextColor(0.6, 0.6, 0.6)
        sf:UpdateScrollHeight(100)
        return sf
    end
    
    for i, q in ipairs(TAT.activeNeededQuests) do
        local card = CreateFrame("Frame", nil, child)
        card:SetSize(570, 72)
        card:SetPoint("TOPLEFT", 5, -yOffset)
        ApplyFlatStyle(card, COLOR_CARD, COLOR_BORDER)
        
        -- Title
        local title = card:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 12, -8)
        title:SetText(q.title)
        title:SetTextColor(1, 0.82, 0)
        
        -- Details (Zone & Time)
        local hours = math.floor(q.timeLeft / 60)
        local mins = q.timeLeft % 60
        local timeStr = hours > 0 and string.format("%dh %dm remaining", hours, mins) or string.format("%dm remaining", mins)
        
        local details = card:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        details:SetPoint("TOPLEFT", 12, -26)
        details:SetText(string.format("%s  •  %s", q.zoneName, timeStr))
        details:SetTextColor(0.7, 0.7, 0.7)
        
        -- Associated Achievement / Criteria details
        local neededFor = card:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        neededFor:SetPoint("TOPLEFT", 12, -46)
        neededFor:SetText(string.format("Needed for: |cffffffff%s|r (|cff00ff00%s|r)", q.achievementName, q.criteriaString))
        neededFor:SetTextColor(0.4, 0.8, 1)
        
        -- Supertrack button
        local trackBtn = CreateTATButton(card, "Supertrack", 90, 24, function()
            C_SuperTrack.SetSuperTrackedQuestID(q.questID)
            UIFrameFadeOut(TAT_MainFrame, 0.15, 1, 0)
            C_Timer.After(0.15, function()
                TAT_MainFrame:Hide()
            end)
            print(string.format("|cff00ff00[TurboAchievementTracker]:|r Supertracking set to |cffffff00%s|r!", q.title))
        end)
        trackBtn:SetPoint("RIGHT", -12, 0)
        
        card:SetScript("OnEnter", function(self)
            self.tatBg:SetColorTexture(unpack(COLOR_CARD_HOVER))
        end)
        card:SetScript("OnLeave", function(self)
            self.tatBg:SetColorTexture(unpack(COLOR_CARD))
        end)
        
        yOffset = yOffset + 78
    end
    
    sf:UpdateScrollHeight(yOffset + 10)
    return sf
end

-- Render Achievements Tab content
local function RenderAchievements(parent)
    local sf, child = CreateTATScrollFrame(parent, 590, 420)
    sf:SetPoint("TOPLEFT", 10, -10)
    
    local yOffset = 0
    
    -- Filter out and build achievements list
    local progressableList = {}
    for id, data in pairs(TAT.progressableAchievements) do
        table.insert(progressableList, data)
    end
    
    -- Sort by achievement name
    table.sort(progressableList, function(a, b)
        return a.name < b.name
    end)
    
    if #progressableList == 0 then
        local noAch = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        noAch:SetPoint("TOPLEFT", 15, -40)
        noAch:SetPoint("TOPRIGHT", -15, -40)
        noAch:SetJustifyH("CENTER")
        noAch:SetText("No progressable achievements found.\n\nAll achievements matching active World Quests are either completed or filtered out.")
        noAch:SetTextColor(0.6, 0.6, 0.6)
        sf:UpdateScrollHeight(100)
        return sf
    end
    
    for _, ach in ipairs(progressableList) do
        -- Calculate num criteria
        local numCriteria = GetAchievementNumCriteria(ach.id)
        local completedCount = 0
        for i = 1, numCriteria do
            local _, _, completed = GetAchievementCriteriaInfo(ach.id, i)
            if completed then completedCount = completedCount + 1 end
        end
        
        local countText = string.format("(%d/%d criteria completed)", completedCount, numCriteria)
        
        local rowHeight = 36 + (#ach.quests * 30)
        
        local row = CreateFrame("Frame", nil, child)
        row:SetSize(570, rowHeight)
        row:SetPoint("TOPLEFT", 5, -yOffset)
        ApplyFlatStyle(row, COLOR_CARD, COLOR_BORDER)
        
        local title = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 12, -8)
        title:SetText(string.format("%s  |cff888888%s|r", ach.name, countText))
        title:SetTextColor(1, 0.82, 0)
        
        -- Draw quest headers underneath this achievement
        local subY = -30
        for _, q in ipairs(ach.quests) do
            local subRow = CreateFrame("Frame", nil, row)
            subRow:SetSize(550, 26)
            subRow:SetPoint("TOPLEFT", 10, subY)
            ApplyFlatStyle(subRow, {0.07, 0.07, 0.07, 1}, COLOR_BORDER)
            
            local qTitle = subRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            qTitle:SetPoint("LEFT", 8, 0)
            qTitle:SetText(string.format("%s (%s) — Needs criteria: |cff00ff00%s|r", q.title, q.zoneName, q.criteriaString))
            
            local trackBtn = CreateTATButton(subRow, "Supertrack", 75, 18, function()
                C_SuperTrack.SetSuperTrackedQuestID(q.questID)
                UIFrameFadeOut(TAT_MainFrame, 0.15, 1, 0)
                C_Timer.After(0.15, function()
                    TAT_MainFrame:Hide()
                end)
                print(string.format("|cff00ff00[TurboAchievementTracker]:|r Supertracking set to |cffffff00%s|r!", q.title))
            end)
            trackBtn:SetPoint("RIGHT", -6, 0)
            
            subY = subY - 30
        end
        
        yOffset = yOffset + rowHeight + 10
    end
    
    sf:UpdateScrollHeight(yOffset + 10)
    return sf
end

-- Render Settings & Filters Tab content
local function RenderSettings(parent)
    local sf, child = CreateTATScrollFrame(parent, 590, 420)
    sf:SetPoint("TOPLEFT", 10, -10)
    
    local yOffset = 10
    
    -- Group 1: General Settings
    local generalLabel = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    generalLabel:SetPoint("TOPLEFT", 15, -yOffset)
    generalLabel:SetText("General Settings")
    generalLabel:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset + 25
    
    local cbReminder = CreateTATCheckbox(child, "Show login chat reminder of available needed quests", TAT.db.showLoginReminder, function(checked)
        TAT.db.showLoginReminder = checked
    end)
    cbReminder:SetPoint("TOPLEFT", 25, -yOffset)
    
    yOffset = yOffset + 25
    
    local cbDebug = CreateTATCheckbox(child, "Enable debug print to chat on scan", TAT.db.enableDebug, function(checked)
        TAT.db.enableDebug = checked
        TAT:RunScan()
    end)
    cbDebug:SetPoint("TOPLEFT", 25, -yOffset)
    
    yOffset = yOffset + 30
    
    -- Window scale slider
    local scaleLabel = child:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    scaleLabel:SetPoint("TOPLEFT", 25, -yOffset)
    scaleLabel:SetText("UI Scale:")
    
    local slider = CreateFrame("Slider", "TAT_ScaleSlider", child, "UISliderTemplateWithLabels")
    slider:SetPoint("LEFT", scaleLabel, "RIGHT", 15, 0)
    slider:SetWidth(150)
    slider:SetMinMaxValues(0.7, 1.5)
    slider:SetValueStep(0.05)
    slider:SetValue(TAT.db.ui.scale)
    
    if slider.Low then
        slider.Low:SetText("0.7")
    elseif _G["TAT_ScaleSliderLow"] then
        _G["TAT_ScaleSliderLow"]:SetText("0.7")
    end
    
    if slider.High then
        slider.High:SetText("1.5")
    elseif _G["TAT_ScaleSliderHigh"] then
        _G["TAT_ScaleSliderHigh"]:SetText("1.5")
    end
    
    slider:SetScript("OnValueChanged", function(self, value)
        TAT.db.ui.scale = value
        mainFrame:SetScale(value)
    end)
    
    yOffset = yOffset + 45
    
    -- Group 2: World Quest Type Filters
    local typeLabel = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    typeLabel:SetPoint("TOPLEFT", 15, -yOffset)
    typeLabel:SetText("Quest Type Filters")
    typeLabel:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset + 25
    
    local cbPet = CreateTATCheckbox(child, "Enable Pet Battle World Quests", TAT.db.filterPetBattle, function(checked)
        TAT.db.filterPetBattle = checked
        TAT:RunScan()
    end)
    cbPet:SetPoint("TOPLEFT", 25, -yOffset)
    
    yOffset = yOffset + 25
    
    local cbPvP = CreateTATCheckbox(child, "Enable PvP World Quests", TAT.db.filterPvP, function(checked)
        TAT.db.filterPvP = checked
        TAT:RunScan()
    end)
    cbPvP:SetPoint("TOPLEFT", 25, -yOffset)
    
    yOffset = yOffset + 25
    
    local cbProf = CreateTATCheckbox(child, "Enable Profession World Quests", TAT.db.filterProfession, function(checked)
        TAT.db.filterProfession = checked
        TAT:RunScan()
    end)
    cbProf:SetPoint("TOPLEFT", 25, -yOffset)
    
    yOffset = yOffset + 25
    
    local cbNorm = CreateTATCheckbox(child, "Enable Normal World Quests", TAT.db.filterNormal, function(checked)
        TAT.db.filterNormal = checked
        TAT:RunScan()
    end)
    cbNorm:SetPoint("TOPLEFT", 25, -yOffset)
    
    yOffset = yOffset + 45
    
    -- Group 3: Expansion Filters
    local expLabel = child:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    expLabel:SetPoint("TOPLEFT", 15, -yOffset)
    expLabel:SetText("Expansion Filters")
    expLabel:SetTextColor(1, 0.82, 0)
    
    yOffset = yOffset + 25
    
    local expansions = {"Legion", "BfA", "Shadowlands", "Dragonflight", "The War Within"}
    local expKeys = {["Legion"]="Legion", ["BfA"]="BfA", ["Shadowlands"]="Shadowlands", ["Dragonflight"]="Dragonflight", ["The War Within"]="TheWarWithin"}
    
    for _, expName in ipairs(expansions) do
        local key = expKeys[expName]
        local cbExp = CreateTATCheckbox(child, "Scan " .. expName .. " Zones", TAT.db.filterExpansions[key], function(checked)
            TAT.db.filterExpansions[key] = checked
            TAT:RunScan()
        end)
        cbExp:SetPoint("TOPLEFT", 25, -yOffset)
        yOffset = yOffset + 25
    end
    
    yOffset = yOffset + 20
    
    local scanBtn = CreateTATButton(child, "Run Manual Scan", 200, 30, function()
        TAT:RunScan(true)
        print("|cff00ff00[TurboAchievementTracker]:|r Manual scan completed successfully.")
    end)
    scanBtn:SetPoint("TOPLEFT", 20, -yOffset)
    
    yOffset = yOffset + 50
    
    sf:UpdateScrollHeight(yOffset)
    return sf
end

-- Toggle active tab
local function SelectTab(tab)
    activeTab = tab
    TAT:RefreshUI()
end

-- Refreshes the active content area
function TAT:RefreshUI()
    if not mainFrame or not mainFrame:IsShown() then return end
    
    if mainFrame.contentArea then
        mainFrame.contentArea:Hide()
        mainFrame.contentArea:SetParent(nil)
    end
    
    local contentArea = CreateFrame("Frame", nil, mainFrame)
    contentArea:SetSize(610, 440)
    contentArea:SetPoint("TOPLEFT", mainFrame.sidebar, "TOPRIGHT", 10, -10)
    mainFrame.contentArea = contentArea
    
    mainFrame.btnQuests.tatBg:SetColorTexture(unpack(activeTab == "quests" and {0.2, 0.2, 0.2, 1} or {0.1, 0.1, 0.1, 1}))
    mainFrame.btnAchievements.tatBg:SetColorTexture(unpack(activeTab == "achievements" and {0.2, 0.2, 0.2, 1} or {0.1, 0.1, 0.1, 1}))
    mainFrame.btnSettings.tatBg:SetColorTexture(unpack(activeTab == "settings" and {0.2, 0.2, 0.2, 1} or {0.1, 0.1, 0.1, 1}))
    
    if activeTab == "quests" then
        RenderQuests(contentArea)
    elseif activeTab == "achievements" then
        RenderAchievements(contentArea)
    elseif activeTab == "settings" then
        RenderSettings(contentArea)
    end
end

function TAT:UpdateUI()
    if mainFrame and mainFrame:IsShown() then
        TAT:RefreshUI()
    end
end

-- Toggles main window visibility
function TAT:ToggleUI()
    if not mainFrame then
        TAT:CreateMainFrame()
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
        TAT:RefreshUI()
    end
end

function TAT:CreateMainFrame()
    local f = CreateFrame("Frame", "TAT_MainFrame", UIParent)
    mainFrame = f
    
    table.insert(UISpecialFrames, "TAT_MainFrame")
    
    f:SetScale(TAT.db.ui.scale or 1.0)
    f:SetSize(800, 480)
    f:SetPoint(TAT.db.ui.point, UIParent, TAT.db.ui.relativePoint, TAT.db.ui.x, TAT.db.ui.y)
    
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("DIALOG")
    f:Hide()
    
    ApplyFlatStyle(f, COLOR_BG, COLOR_BORDER)
    
    -- Title Bar
    local titleBar = CreateFrame("Frame", nil, f)
    titleBar:SetHeight(30)
    titleBar:SetPoint("TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", 0, 0)
    ApplyFlatStyle(titleBar, COLOR_TITLE, COLOR_BORDER)
    
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() f:StartMoving() end)
    titleBar:SetScript("OnDragStop", function()
        f:StopMovingOrSizing()
        local point, _, relativePoint, x, y = f:GetPoint()
        TAT.db.ui.point = point
        TAT.db.ui.relativePoint = relativePoint
        TAT.db.ui.x = x
        TAT.db.ui.y = y
    end)
    
    local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    titleText:SetPoint("LEFT", 12, 0)
    titleText:SetText("Turbo Achievement Tracker")
    titleText:SetTextColor(1, 0.82, 0)
    
    -- Close button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(20, 20)
    closeBtn:SetPoint("RIGHT", -8, 0)
    
    closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    closeBtn.text:SetPoint("CENTER")
    closeBtn.text:SetText("X")
    closeBtn.text:SetTextColor(1, 0.2, 0.2)
    
    closeBtn:SetScript("OnEnter", function(self) self.text:SetTextColor(1, 0.5, 0.5) end)
    closeBtn:SetScript("OnLeave", function(self) self.text:SetTextColor(1, 0.2, 0.2) end)
    closeBtn:SetScript("OnClick", function()
        UIFrameFadeOut(f, 0.15, 1, 0)
        C_Timer.After(0.15, function()
            f:Hide()
        end)
    end)
    
    -- Sidebar
    local sidebar = CreateFrame("Frame", "TAT_Sidebar", f)
    sidebar:SetSize(180, 450)
    sidebar:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, 0)
    ApplyFlatStyle(sidebar, COLOR_SIDEBAR, COLOR_BORDER)
    f.sidebar = sidebar
    
    -- Sidebar navigation buttons
    local function CreateNavButton(label, yOffset, tabName)
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(160, 32)
        btn:SetPoint("TOP", 0, yOffset)
        ApplyFlatStyle(btn, {0.1, 0.1, 0.1, 1}, COLOR_BORDER)
        
        btn.text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        btn.text:SetPoint("LEFT", 12, 0)
        btn.text:SetText(label)
        
        btn:SetScript("OnClick", function() SelectTab(tabName) end)
        btn:SetScript("OnEnter", function(self)
            if activeTab ~= tabName then
                self.tatBg:SetColorTexture(0.15, 0.15, 0.15, 1)
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if activeTab ~= tabName then
                self.tatBg:SetColorTexture(0.1, 0.1, 0.1, 1)
            end
        end)
        
        return btn
    end
    
    f.btnQuests = CreateNavButton("Needed Quests", -20, "quests")
    f.btnAchievements = CreateNavButton("Achievements", -60, "achievements")
    f.btnSettings = CreateNavButton("Filters & Settings", -100, "settings")
    
    -- Footer/Credits
    local credits = sidebar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    credits:SetPoint("BOTTOM", 0, 10)
    credits:SetText("v1.1.0 Mainline\nby Antigravity")
end

-- Slash commands
SLASH_TAT1 = "/tat"
SlashCmdList["TAT"] = function(msg)
    local cmd = string.lower(strtrim(msg or ""))
    if cmd == "debug" then
        local colorPrefix = "|cff00ff00[TAT Debug Command]:|r "
        DEFAULT_CHAT_FRAME:AddMessage(colorPrefix .. "Starting diagnostics...")
        
        -- 1. Check database settings
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%sDebug Mode: %s, Login Reminder: %s", colorPrefix, tostring(TAT.db.enableDebug), tostring(TAT.db.showLoginReminder)))
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%sFilters - Pet: %s, PvP: %s, Prof: %s, Normal: %s", colorPrefix, tostring(TAT.db.filterPetBattle), tostring(TAT.db.filterPvP), tostring(TAT.db.filterProfession), tostring(TAT.db.filterNormal)))
        
        -- 2. Check achievement categories
        local categories = GetCategoryList()
        local catCount = categories and #categories or 0
        DEFAULT_CHAT_FRAME:AddMessage(string.format("%sGetCategoryList returned %d categories.", colorPrefix, catCount))
        
        -- Print a few categories
        if catCount > 0 then
            local names = {}
            for i = 1, math.min(5, catCount) do
                local name = GetCategoryInfo(categories[i])
                table.insert(names, string.format("%d:%s", categories[i], name or "nil"))
            end
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%sFirst 5 categories: %s", colorPrefix, table.concat(names, ", ")))
        end
        
        -- 3. Check "Battle in the Shadowlands" achievement (ID 14625)
        local id, name, points, completed, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(14625)
        if id then
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%sAchievement 14625: '%s' (Points: %d, Completed: %s, EarnedByMe: %s)", colorPrefix, name, points, tostring(completed), tostring(wasEarnedByMe)))
            local catID = GetAchievementCategory(14625)
            if catID then
                local catName = GetCategoryInfo(catID)
                local total = GetCategoryNumAchievements(catID)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("%sCategory %d: '%s' (Total achievements in category: %d)", colorPrefix, catID, catName or "nil", total))
                
                local foundByIndex = false
                for i = 1, total do
                    local tempId, tempName = GetAchievementInfo(catID, i)
                    if tempId == 14625 then
                        foundByIndex = true
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Found by index %d: ID %s, Name '%s'", i, tostring(tempId), tostring(tempName)))
                    elseif tempId and (i <= 3 or i == total) then
                        DEFAULT_CHAT_FRAME:AddMessage(string.format("  Index %d: ID %s, Name '%s'", i, tostring(tempId), tostring(tempName)))
                    end
                end
                if not foundByIndex then
                    DEFAULT_CHAT_FRAME:AddMessage(colorPrefix .. "Achievement was NOT found in its category by index!")
                end
            end
            
            local numCriteria = GetAchievementNumCriteria(14625)
            DEFAULT_CHAT_FRAME:AddMessage(string.format("%sNum Criteria: %d", colorPrefix, numCriteria))
            for i = 1, numCriteria do
                local criteriaString, criteriaType, criteriaCompleted = GetAchievementCriteriaInfo(14625, i)
                DEFAULT_CHAT_FRAME:AddMessage(string.format("  Crit %d: '%s' (Completed: %s)", i, criteriaString or "nil", tostring(criteriaCompleted)))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage(colorPrefix .. "Achievement 14625 (Battle in the Shadowlands) NOT found via GetAchievementInfo!")
        end
        
        -- 4. Check if 14625 is in our criteria lookup
        local foundInLookup = false
        for cleanKey, critInfo in pairs(TAT.criteriaLookup) do
            if critInfo.achievementID == 14625 then
                foundInLookup = true
                DEFAULT_CHAT_FRAME:AddMessage(string.format("%sFound in criteriaLookup: '%s' -> '%s' (Index %d)", colorPrefix, cleanKey, critInfo.criteriaString, critInfo.criteriaIndex))
            end
        end
        if not foundInLookup then
            DEFAULT_CHAT_FRAME:AddMessage(colorPrefix .. "Achievement 14625 is NOT in TAT.criteriaLookup!")
        end
        
        -- 5. Force a scan and print the output
        TAT:RunScan()
    else
        TAT:ToggleUI()
    end
end

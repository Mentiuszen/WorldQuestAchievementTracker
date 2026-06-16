local addonName, TAT = ...
TAT.zoneMapIDs = {}
TAT.criteriaLookup = {}
TAT.activeNeededQuests = {}
TAT.progressableAchievements = {}

local eventFrame = CreateFrame("Frame")

-- Parent Map IDs mapped to Expansion Names
local parentToExpansion = {
    [619] = "Legion", [903] = "Legion",
    [875] = "BfA", [876] = "BfA",
    [1550] = "Shadowlands",
    [1978] = "Dragonflight",
    [2274] = "The War Within"
}

local mapExpansionCache = {}

-- Recursive helper to resolve expansion of a map ID (cached)
local function GetMapExpansion(mapID)
    if mapExpansionCache[mapID] then
        return mapExpansionCache[mapID]
    end
    
    local curID = mapID
    for depth = 1, 10 do
        if not curID or curID == 0 then break end
        if parentToExpansion[curID] then
            mapExpansionCache[mapID] = parentToExpansion[curID]
            return parentToExpansion[curID]
        end
        local mapInfo = C_Map.GetMapInfo(curID)
        if not mapInfo then break end
        curID = mapInfo.parentMapID
    end
    
    mapExpansionCache[mapID] = "Other"
    return "Other"
end

-- Builds a cache of all Zone map IDs in the client
function TAT:BuildMapCache()
    wipe(TAT.zoneMapIDs)
    for i = 1, 3500 do
        local mapInfo = C_Map.GetMapInfo(i)
        if mapInfo and (mapInfo.mapType == Enum.UIMapType.Zone or mapInfo.mapType == Enum.UIMapType.Orphan) then
            table.insert(TAT.zoneMapIDs, i)
        end
    end
end

-- Case-insensitive trimmed fuzzy match
local function IsMatch(wqTitle, criteriaName)
    local wq = strtrim(wqTitle:lower())
    local crit = strtrim(criteriaName:lower())
    if wq == crit then return true end
    
    if #wq >= 4 and #crit >= 4 then
        if string.find(wq, crit, 1, true) or string.find(crit, wq, 1, true) then
            return true
        end
    end
    return false
end

-- Recursive achievement scanner to extract leaf criteria strings
local function ScanAchievement(achievementID, criteriaList)
    local id, name, _, completed, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(achievementID)
    if not id then return end
    if completed and wasEarnedByMe then return end -- Skip completed achievements

    local numCriteria = GetAchievementNumCriteria(achievementID)
    for i = 1, numCriteria do
        local criteriaString, criteriaType, criteriaCompleted, _, _, _, _, assetID = GetAchievementCriteriaInfo(achievementID, i)
        
        -- Check if criterion is a sub-achievement (meta-achievement case)
        local isSubAchievement = false
        if assetID and assetID > 0 then
            local subId, subName, _, subCompleted, _, _, _, _, _, _, _, _, subEarned = GetAchievementInfo(assetID)
            if subId then
                isSubAchievement = true
                if not (subCompleted and subEarned) then
                    ScanAchievement(assetID, criteriaList)
                end
            end
        end

        if not isSubAchievement and not criteriaCompleted and criteriaString and criteriaString ~= "" then
            local cleanKey = strtrim(criteriaString:lower())
            criteriaList[cleanKey] = {
                achievementID = achievementID,
                achievementName = name,
                criteriaString = criteriaString,
                criteriaIndex = i
            }
        end
    end
end

TAT.criteriaLookupBuilt = false

-- Builds the global criteria lookup table from all incomplete achievements
-- Returns true if database is loaded, false if it is not ready yet
function TAT:RebuildCriteriaLookup(force)
    if not force and TAT.criteriaLookupBuilt then
        return true
    end

    wipe(TAT.criteriaLookup)
    
    local categories = GetCategoryList()
    if not categories or #categories == 0 then
        TAT.lastScanStats = { achievements = 0, criteria = 0 }
        return false
    end
    
    local totalAchievementsInGame = 0
    local scannedAchievementsCount = 0
    for _, catID in ipairs(categories) do
        local name, parentID = GetCategoryInfo(catID)
        local total = GetCategoryNumAchievements(catID)
        totalAchievementsInGame = totalAchievementsInGame + total
        for i = 1, total do
            local id, achName, _, achCompleted, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(catID, i)
            if id and not (achCompleted and wasEarnedByMe) then
                scannedAchievementsCount = scannedAchievementsCount + 1
                ScanAchievement(id, TAT.criteriaLookup)
            end
        end
    end
    
    -- If no achievements were successfully scanned, the database is not loaded yet
    if scannedAchievementsCount == 0 then
        TAT.lastScanStats = { achievements = 0, criteria = 0 }
        return false
    end
    
    local criteriaCount = 0
    for _ in pairs(TAT.criteriaLookup) do
        criteriaCount = criteriaCount + 1
    end
    
    TAT.lastScanStats = {
        achievements = scannedAchievementsCount,
        criteria = criteriaCount
    }
    
    TAT.criteriaLookupBuilt = true
    return true
end

local hasEnteredWorld = false
local hasPrintedReminder = false

-- Main scanner execution
function TAT:RunScan(force)
    if not TAT.db then return end
    
    -- Ensure map cache is prepared
    if #TAT.zoneMapIDs == 0 then
        TAT:BuildMapCache()
    end
    
    -- Rebuild criteria lookup of incomplete achievements if forced or not built yet
    local success = TAT:RebuildCriteriaLookup(force)
    if not success then
        -- Achievements database is not loaded yet, schedule a retry
        if not TAT.achRetryCount then TAT.achRetryCount = 0 end
        if TAT.achRetryCount < 10 then
            TAT.achRetryCount = TAT.achRetryCount + 1
            if TAT.db.enableDebug then
                DEFAULT_CHAT_FRAME:AddMessage("|cff8855ff[TAT Debug]:|r Achievement data not ready. Retrying scan in 2s...")
            end
            if TAT.achRetryTimer then TAT.achRetryTimer:Cancel() end
            TAT.achRetryTimer = C_Timer.NewTimer(2.0, function()
                TAT:RunScan(force)
            end)
            return
        end
    else
        TAT.achRetryCount = 0
        TAT.initialScanDone = true
        if eventFrame then
            eventFrame:UnregisterEvent("RECEIVED_ACHIEVEMENT_LIST")
        end
    end

    wipe(TAT.activeNeededQuests)
    wipe(TAT.progressableAchievements)
    
    local needsRetry = false
    local processedQuests = {}
    local mapsScannedCount = 0
    local questsFoundCount = 0

    local getQuests = C_TaskQuest.GetQuestsOnMap or C_TaskQuest.GetQuestsForPlayerByMapID

    -- Map list to scan: Zone cache + current zone
    local mapsToScan = {}
    for _, mapID in ipairs(TAT.zoneMapIDs) do
        mapsToScan[mapID] = true
    end
    local currentMap = C_Map.GetBestMapForUnit("player")
    if currentMap then
        mapsToScan[currentMap] = true
    end

    for mapID in pairs(mapsToScan) do
        local expansion = GetMapExpansion(mapID)
        
        -- Filter by expansion selection (skip legacy zones classified as "Other" which don't have WQs)
        if expansion ~= "Other" and TAT.db.filterExpansions[expansion] then
            mapsScannedCount = mapsScannedCount + 1
            local quests = getQuests(mapID)
            if quests then
                for _, questInfo in ipairs(quests) do
                    local questID = questInfo.questID or questInfo.questId
                    if questID and not processedQuests[questID] then
                        processedQuests[questID] = true
                        questsFoundCount = questsFoundCount + 1
                        
                        local title = C_QuestLog.GetTitleForQuestID(questID)
                        if not title or title == "" then
                            C_QuestLog.RequestLoadQuestByID(questID)
                            needsRetry = true
                        else
                            -- Query quest types
                            local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
                            local isPetBattle = tagInfo and tagInfo.worldQuestType == Enum.QuestTagType.PetBattle
                            local isPvP = tagInfo and tagInfo.worldQuestType == Enum.QuestTagType.PvP
                            local isProfession = tagInfo and tagInfo.worldQuestType == Enum.QuestTagType.Professions
                            local isNormal = not isPetBattle and not isPvP and not isProfession
                            
                            -- Evaluate filter rules
                            local passFilter = false
                            if TAT.db.filterPetBattle and isPetBattle then passFilter = true end
                            if TAT.db.filterPvP and isPvP then passFilter = true end
                            if TAT.db.filterProfession and isProfession then passFilter = true end
                            if TAT.db.filterNormal and isNormal then passFilter = true end
                            
                            if passFilter then
                                -- Compare quest title against missing criteria
                                for critLower, critInfo in pairs(TAT.criteriaLookup) do
                                    if IsMatch(title, critInfo.criteriaString) then
                                        local timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes(questID) or 0
                                        local mapInfo = C_Map.GetMapInfo(mapID)
                                        local zoneName = mapInfo and mapInfo.name or "Unknown Zone"
                                        
                                        local questData = {
                                            questID = questID,
                                            title = title,
                                            zoneName = zoneName,
                                            mapID = mapID,
                                            timeLeft = timeLeft,
                                            achievementID = critInfo.achievementID,
                                            achievementName = critInfo.achievementName,
                                            criteriaString = critInfo.criteriaString,
                                            isPetBattle = isPetBattle
                                        }
                                        
                                        table.insert(TAT.activeNeededQuests, questData)
                                        
                                        -- Track achievements progressable right now
                                        if not TAT.progressableAchievements[critInfo.achievementID] then
                                            TAT.progressableAchievements[critInfo.achievementID] = {
                                                id = critInfo.achievementID,
                                                name = critInfo.achievementName,
                                                quests = {}
                                            }
                                        end
                                        table.insert(TAT.progressableAchievements[critInfo.achievementID].quests, questData)
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Trigger UI updates
    if TAT.UpdateUI then
        TAT:UpdateUI()
    end

    -- Print debug information to chat if enabled
    if TAT.db.enableDebug then
        local colorPrefix = "|cff8855ff[TAT Debug]:|r "
        local msg = string.format(
            "%sScanned %d achievements (%d criteria lookup). Scanned %d zones, found %d active WQs. Matched %d needed WQs!",
            colorPrefix,
            TAT.lastScanStats and TAT.lastScanStats.achievements or 0,
            TAT.lastScanStats and TAT.lastScanStats.criteria or 0,
            mapsScannedCount,
            questsFoundCount,
            #TAT.activeNeededQuests
        )
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end

    -- Print reminder on the first successful scan of the session (after player fully enters world)
    if hasEnteredWorld and TAT.db.showLoginReminder and not hasPrintedReminder then
        hasPrintedReminder = true
        local neededCount = #TAT.activeNeededQuests
        local colorPrefix = "|cff00ff00[TurboAchievementTracker]:|r "
        local msg
        if neededCount > 0 then
            msg = string.format("%sYou have |cffff0000%d|r needed World Quests available right now! (Scanned %d achievements, %d criteria, %d active WQs) Type /tat to open the window.", colorPrefix, neededCount, TAT.lastScanStats.achievements, TAT.lastScanStats.criteria, questsFoundCount)
        else
            msg = string.format("%sScan completed! No needed World Quests are active right now. (Scanned %d achievements, %d criteria, %d active WQs)", colorPrefix, TAT.lastScanStats.achievements, TAT.lastScanStats.criteria, questsFoundCount)
        end
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end

    -- Handle retry if any quest titles needed to be loaded from database
    if needsRetry then
        if not TAT.titleRetryCount then TAT.titleRetryCount = 0 end
        if TAT.titleRetryCount < 5 then
            TAT.titleRetryCount = TAT.titleRetryCount + 1
            if TAT.retryTimer then
                TAT.retryTimer:Cancel()
            end
            TAT.retryTimer = C_Timer.NewTimer(1.5, function()
                TAT:RunScan()
            end)
        end
    else
        TAT.titleRetryCount = 0
    end
end

-- Hook database loaded
function TAT:OnDatabaseLoaded()
    TAT:RunScan()
end

-- Main event tracking frame setup (only for initial login scan)
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("RECEIVED_ACHIEVEMENT_LIST")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        hasEnteredWorld = true
        if not TAT.initialScanDone then
            TAT:RunScan()
        end
    elseif event == "RECEIVED_ACHIEVEMENT_LIST" then
        if not TAT.initialScanDone then
            -- Cancel any pending achievement retry timers and scan immediately
            if TAT.achRetryTimer then
                TAT.achRetryTimer:Cancel()
                TAT.achRetryTimer = nil
            end
            TAT:RunScan()
        end
    end
end)

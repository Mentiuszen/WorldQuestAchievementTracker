local addonName, WQAT = ...
WQAT.zoneMapIDs = {}
WQAT.criteriaLookup = {}
WQAT.scannedNeededQuests = {}

local eventFrame = CreateFrame("Frame")

local parentToExpansion = {
    -- Legion
    [619] = "Legion",     -- Broken Isles
    [905] = "Legion",     -- Argus
    [627] = "Legion",     -- Dalaran
    [630] = "Legion",     -- Azsuna
    [634] = "Legion",     -- Stormheim
    [641] = "Legion",     -- Val'sharah
    [646] = "Legion",     -- Broken Shore
    [650] = "Legion",     -- Highmountain
    [680] = "Legion",     -- Suramar
    [790] = "Legion",     -- Eye of Azshara
    [830] = "Legion",     -- Krokuun
    [882] = "Legion",     -- Mac'Aree / Eredath
    [885] = "Legion",     -- Antoran Wastes

    -- Battle for Azeroth
    [875] = "BfA",        -- Zandalar
    [876] = "BfA",        -- Kul Tiras
    [1309] = "BfA",       -- Darkshore
    [1244] = "BfA",       -- Arathi Highlands
    [895] = "BfA",        -- Tiragarde Sound
    [896] = "BfA",        -- Drustvar
    [942] = "BfA",        -- Stormsong Valley
    [859] = "BfA",        -- Zuldazar
    [862] = "BfA",        -- Nazmir
    [863] = "BfA",        -- Vol'dun
    [1161] = "BfA",       -- Boralus
    [1165] = "BfA",       -- Dazar'alor
    [1355] = "BfA",       -- Nazjatar
    [1462] = "BfA",       -- Mechagon Island
    [1527] = "BfA",       -- Uldum
    [1530] = "BfA",       -- Vale of Eternal Blossoms

    -- Shadowlands
    [1550] = "Shadowlands", -- The Shadowlands
    [1670] = "Shadowlands", -- Oribos
    [1533] = "Shadowlands", -- Bastion
    [1536] = "Shadowlands", -- Maldraxxus
    [1565] = "Shadowlands", -- Ardenweald
    [1525] = "Shadowlands", -- Revendreth
    [1543] = "Shadowlands", -- The Maw
    [1961] = "Shadowlands", -- Korthia
    [1970] = "Shadowlands", -- Zereth Mortis

    -- Dragonflight
    [1978] = "Dragonflight", -- Dragon Isles
    [2022] = "Dragonflight", -- The Waking Shores
    [2023] = "Dragonflight", -- Ohn'ahran Plains
    [2024] = "Dragonflight", -- The Azure Span
    [2025] = "Dragonflight", -- Thaldraszus
    [2112] = "Dragonflight", -- Valdrakken
    [2133] = "Dragonflight", -- Zaralek Cavern
    [2151] = "Dragonflight", -- The Forbidden Reach
    [2200] = "Dragonflight", -- Emerald Dream

    -- The War Within
    [2274] = "The War Within", -- Khaz Algar
    [2248] = "The War Within", -- Isle of Dorn
    [2214] = "The War Within", -- The Ringing Reeps
    [2215] = "The War Within", -- Hallowfall
    [2255] = "The War Within", -- Azj-Kahet
    [2346] = "The War Within", -- Undermine
    [2369] = "The War Within", -- Siren Isle
    [2371] = "The War Within", -- K'aresh

    -- Midnight
    [2537] = "Midnight",     -- Quel'Thalas
    [2393] = "Midnight",     -- Silvermoon City
    [2395] = "Midnight",     -- Eversong Woods
    [2405] = "Midnight",     -- Voidstorm
    [2413] = "Midnight",     -- Harandar
    [2424] = "Midnight",     -- Isle of Quel'Danas
    [2437] = "Midnight",     -- Zul'Aman
}

local mapExpansionCache = {}

local function GetMapExpansion(mapID)
    if mapExpansionCache[mapID] then
        return mapExpansionCache[mapID]
    end
    
    local curID = mapID
    for depth = 1, 20 do
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

function WQAT:BuildMapCache()
    wipe(WQAT.zoneMapIDs)
    for i = 1, 3500 do
        local mapInfo = C_Map.GetMapInfo(i)
        if mapInfo and (mapInfo.mapType == Enum.UIMapType.Zone or mapInfo.mapType == Enum.UIMapType.Orphan) then
            table.insert(WQAT.zoneMapIDs, i)
        end
    end
end

local function IsMatch(wqTitle, criteriaName)
    return strtrim(wqTitle:lower()) == strtrim(criteriaName:lower())
end

local function ScanAchievement(achievementID, criteriaList)
    local id, name, _, completed, _, _, _, _, _, _, _, _, wasEarnedByMe = GetAchievementInfo(achievementID)
    if not id or (completed and wasEarnedByMe) then return end

    if WQAT.db and WQAT.db.blacklist then
        if WQAT.db.blacklist.achievementIDs and WQAT.db.blacklist.achievementIDs[achievementID] then
            return
        end
        
        if name and WQAT.db.blacklist.achievementNames then
            local nameLower = name:lower()
            for pattern, enabled in pairs(WQAT.db.blacklist.achievementNames) do
                if enabled and string.find(nameLower, pattern, 1, true) then
                    return
                end
            end
        end
    end

    local numCriteria = GetAchievementNumCriteria(achievementID)
    for i = 1, numCriteria do
        local criteriaString, criteriaType, criteriaCompleted, _, _, _, _, assetID = GetAchievementCriteriaInfo(achievementID, i)
        
        local isSubAchievement = false
        if criteriaType == 8 and assetID and assetID > 0 then
            local subId, subName, _, subCompleted, _, _, _, _, _, _, _, _, subEarned = GetAchievementInfo(assetID)
            if subId then
                isSubAchievement = true
                if not (subCompleted and subEarned) then
                    ScanAchievement(assetID, criteriaList)
                end
            end
        end

        if not isSubAchievement and not criteriaCompleted then
            local info = {
                achievementID = achievementID,
                achievementName = name,
                criteriaString = criteriaString or "",
                criteriaIndex = i,
                criteriaType = criteriaType
            }
            if criteriaType == 27 and assetID and assetID > 0 then
                criteriaList[assetID] = criteriaList[assetID] or {}
                table.insert(criteriaList[assetID], info)
            elseif criteriaString and criteriaString ~= "" then
                local cleanKey = strtrim(criteriaString:lower())
                criteriaList[cleanKey] = criteriaList[cleanKey] or {}
                table.insert(criteriaList[cleanKey], info)
            end
        end
    end
end

local function IsExcludedCategory(catID)
    if not WQAT.db or not WQAT.db.blacklist or not WQAT.db.blacklist.categories then
        return false
    end
    
    local name, parentID = GetCategoryInfo(catID)
    if not name then return false end
    
    if WQAT.db.blacklist.categories[name:lower()] then
        return true
    end
    
    local currentID = parentID
    for i = 1, 10 do
        if not currentID or currentID == -1 then break end
        local pName, nextParent = GetCategoryInfo(currentID)
        if pName then
            if WQAT.db.blacklist.categories[pName:lower()] then
                return true
            end
        end
        currentID = nextParent
    end
    
    return false
end

local function IsAchievementInCategory(achievementID, targetCategoryLower)
    local catID = GetAchievementCategory(achievementID)
    if not catID then return false end
    
    local currentID = catID
    for i = 1, 10 do
        if not currentID or currentID == -1 then break end
        local name, parentID = GetCategoryInfo(currentID)
        if name then
            local nameLower = name:lower()
            if nameLower == targetCategoryLower or 
               (targetCategoryLower == "professions" and nameLower == "profession") or
               (targetCategoryLower == "player vs. player" and nameLower == "pvp") or
               (targetCategoryLower == "pet battles" and nameLower == "pet battle") then
                return true
            end
        end
        currentID = parentID
    end
    
    return false
end

WQAT.criteriaLookupBuilt = false

function WQAT:RebuildCriteriaLookup(force)
    if not force and WQAT.criteriaLookupBuilt then
        return true
    end

    wipe(WQAT.criteriaLookup)
    
    local categories = GetCategoryList()
    if not categories or #categories == 0 then
        WQAT.lastScanStats = { achievements = 0, criteria = 0 }
        return false
    end
    
    local totalAchievementsInGame = 0
    local scannedAchievementsCount = 0
    for _, catID in ipairs(categories) do
        if not IsExcludedCategory(catID) then
            local total = GetCategoryNumAchievements(catID)
            totalAchievementsInGame = totalAchievementsInGame + total
            for i = 1, total do
                local ok, id, achName, _, achCompleted, _, _, _, _, _, _, _, _, wasEarnedByMe = pcall(GetAchievementInfo, catID, i)
                if ok and id and not (achCompleted and wasEarnedByMe) then
                    scannedAchievementsCount = scannedAchievementsCount + 1
                    ScanAchievement(id, WQAT.criteriaLookup)
                end
            end
        end
    end
    
    if totalAchievementsInGame == 0 then
        WQAT.lastScanStats = { achievements = 0, criteria = 0 }
        return false
    end
    
    local criteriaCount = 0
    for _, infoList in pairs(WQAT.criteriaLookup) do
        criteriaCount = criteriaCount + #infoList
    end
    
    WQAT.lastScanStats = {
        achievements = scannedAchievementsCount,
        criteria = criteriaCount
    }
    
    if scannedAchievementsCount > 100 and criteriaCount < 200 then
        WQAT.criteriaLookupBuilt = false
        return false
    end
    
    WQAT.criteriaLookupBuilt = true
    return true
end

local hasEnteredWorld = false
local hasPrintedReminder = false

function WQAT:RunScan(force)
    if not WQAT.db then return end
    
    if #WQAT.zoneMapIDs == 0 then
        WQAT:BuildMapCache()
    end
    
    local success = WQAT:RebuildCriteriaLookup(force)
    if not success then
        if not WQAT.achRetryCount then WQAT.achRetryCount = 0 end
        if WQAT.achRetryCount < 8 then
            WQAT.achRetryCount = WQAT.achRetryCount + 1
            if WQAT.achRetryTimer then
                WQAT.achRetryTimer:Cancel()
            end
            WQAT.achRetryTimer = C_Timer.NewTimer(2.0, function()
                WQAT:RunScan()
            end)
        end
        return
    else
        WQAT.achRetryCount = 0
        if hasEnteredWorld then
            WQAT.initialScanDone = true
        end
    end

    wipe(WQAT.scannedNeededQuests)
    
    local needsRetry = false
    local processedQuests = {}
    local mapsScannedCount = 0
    local questsFoundCount = 0

    local getQuests = C_TaskQuest.GetQuestsOnMap or C_TaskQuest.GetQuestsForPlayerByMapID

    local mapsToScan = {}
    for _, mapID in ipairs(WQAT.zoneMapIDs) do
        mapsToScan[mapID] = true
    end
    local currentMap = C_Map.GetBestMapForUnit("player")
    if currentMap then
        mapsToScan[currentMap] = true
    end

    for mapID in pairs(mapsToScan) do
        local expansion = GetMapExpansion(mapID)
        
        if expansion ~= "Other" then
            mapsScannedCount = mapsScannedCount + 1
            local quests = getQuests(mapID)
            if quests then
                for _, questInfo in ipairs(quests) do
                    local questID = questInfo.questID or questInfo.questId
                    if questID and not processedQuests[questID] then
                        processedQuests[questID] = true
                        
                        if C_QuestLog.IsWorldQuest(questID) then
                            questsFoundCount = questsFoundCount + 1
                            
                            local title = C_QuestLog.GetTitleForQuestID(questID)
                            if not title or title == "" or (HaveQuestData and not HaveQuestData(questID)) then
                                C_QuestLog.RequestLoadQuestByID(questID)
                                needsRetry = true
                            else
                                local tagInfo = C_QuestLog.GetQuestTagInfo(questID)
                                local wqType = tagInfo and tagInfo.worldQuestType
                                local QTT = Enum and Enum.QuestTagType
                                local isPetBattle = wqType and QTT and wqType == QTT.PetBattle
                                local isPvP = wqType and QTT and wqType == QTT.PvP
                                local isProfession = (wqType and QTT and QTT.Profession and wqType == QTT.Profession) or (tagInfo and tagInfo.tradeskillLineID and tagInfo.tradeskillLineID > 0)
                                
                                local matchedInfos = {}
                                local addedAchievements = {}
                                
                                local idMatches = WQAT.criteriaLookup[questID]
                                if idMatches then
                                    for _, info in ipairs(idMatches) do
                                        if not addedAchievements[info.achievementID] then
                                            addedAchievements[info.achievementID] = true
                                            table.insert(matchedInfos, info)
                                        end
                                    end
                                end
                                
                                for key, infoList in pairs(WQAT.criteriaLookup) do
                                    if type(key) == "string" then
                                        for _, info in ipairs(infoList) do
                                            if not addedAchievements[info.achievementID] then
                                                if IsMatch(title, info.criteriaString) then
                                                    local isCompatible = true
                                                    
                                                    local achIsPetBattle = IsAchievementInCategory(info.achievementID, "pet battles")
                                                    local achIsPvP = IsAchievementInCategory(info.achievementID, "player vs. player")
                                                    local achIsProfession = IsAchievementInCategory(info.achievementID, "professions")
                                                    
                                                    if isPetBattle and not achIsPetBattle then
                                                        isCompatible = false
                                                    end
                                                    if isPvP and not achIsPvP then
                                                        isCompatible = false
                                                    end
                                                    if isProfession and not achIsProfession then
                                                        isCompatible = false
                                                    end
                                                    if achIsPetBattle and not isPetBattle then
                                                        isCompatible = false
                                                    end
                                                    
                                                    if isCompatible then
                                                        addedAchievements[info.achievementID] = true
                                                        table.insert(matchedInfos, info)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                for _, critInfo in ipairs(matchedInfos) do
                                    local timeLeft = C_TaskQuest.GetQuestTimeLeftMinutes(questID) or 0
                                    local mapInfo = C_Map.GetMapInfo(mapID)
                                    local zoneName = mapInfo and mapInfo.name or "Unknown Zone"
                                    
                                    local finalIsPetBattle = isPetBattle or IsAchievementInCategory(critInfo.achievementID, "pet battles")
                                    local finalIsPvP = isPvP or IsAchievementInCategory(critInfo.achievementID, "player vs. player")
                                    local finalIsProfession = isProfession or IsAchievementInCategory(critInfo.achievementID, "professions")
                                    local finalIsNormal = not finalIsPetBattle and not finalIsPvP and not finalIsProfession
                                    
                                    local questData = {
                                        questID = questID,
                                        title = title,
                                        zoneName = zoneName,
                                        mapID = mapID,
                                        timeLeft = timeLeft,
                                        achievementID = critInfo.achievementID,
                                        achievementName = critInfo.achievementName,
                                        criteriaString = critInfo.criteriaString,
                                        criteriaIndex = critInfo.criteriaIndex,
                                        isPetBattle = finalIsPetBattle,
                                        isPvP = finalIsPvP,
                                        isProfession = finalIsProfession,
                                        isNormal = finalIsNormal,
                                        expansion = expansion
                                    }
                                    
                                    table.insert(WQAT.scannedNeededQuests, questData)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if WQAT.UpdateUI then
        WQAT:UpdateUI()
    end

    if hasEnteredWorld and WQAT.db.showLoginReminder and not hasPrintedReminder and WQAT.criteriaLookupBuilt then
        hasPrintedReminder = true
        local filteredQuests = WQAT:GetFilteredQuests()
        local uniqueQuests = {}
        for _, q in ipairs(filteredQuests) do
            uniqueQuests[q.questID] = true
        end
        local neededCount = 0
        for _ in pairs(uniqueQuests) do
            neededCount = neededCount + 1
        end
        local colorPrefix = "|cff00ff00[WQAT]:|r "
        local msg
        if neededCount > 0 then
            msg = string.format("%sYou have |cffff0000%d|r needed World Quests available! (Scanned %d achievements, %d criteria, %d active WQs) Type /wqat to open window.", colorPrefix, neededCount, WQAT.lastScanStats.achievements, WQAT.lastScanStats.criteria, questsFoundCount)
        else
            msg = string.format("%sScan completed. No needed World Quests are active. (Scanned %d achievements, %d criteria, %d active WQs)", colorPrefix, WQAT.lastScanStats.achievements, WQAT.lastScanStats.criteria, questsFoundCount)
        end
        DEFAULT_CHAT_FRAME:AddMessage(msg)
    end

    if needsRetry then
        if not WQAT.titleRetryCount then WQAT.titleRetryCount = 0 end
        if WQAT.titleRetryCount < 5 then
            WQAT.titleRetryCount = WQAT.titleRetryCount + 1
            if WQAT.retryTimer then
                WQAT.retryTimer:Cancel()
            end
            WQAT.retryTimer = C_Timer.NewTimer(1.5, function()
                WQAT:RunScan()
            end)
        end
    else
        WQAT.titleRetryCount = 0
    end
end

function WQAT:GetFilteredQuests()
    local filtered = {}
    if not WQAT.scannedNeededQuests then return filtered end
    for _, q in ipairs(WQAT.scannedNeededQuests) do
        local passType = false
        if WQAT.db.filterPetBattle and q.isPetBattle then passType = true end
        if WQAT.db.filterPvP and q.isPvP then passType = true end
        if WQAT.db.filterProfession and q.isProfession then passType = true end
        if WQAT.db.filterNormal and q.isNormal then passType = true end
        
        local passExp = false
        local expansion = q.mapID and GetMapExpansion(q.mapID) or "Other"
        local filterKey = expansion:gsub("%s+", "")
        if expansion == "Other" or WQAT.db.filterExpansions[filterKey] then
            passExp = true
        end
        
        if passType and passExp then
            table.insert(filtered, q)
        end
    end
    return filtered
end

function WQAT:OnDatabaseLoaded()
    WQAT:RunScan()
end

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("RECEIVED_ACHIEVEMENT_LIST")
eventFrame:RegisterEvent("QUEST_TURNED_IN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        hasEnteredWorld = true
        if not WQAT.initialScanDone then
            if WQAT.loginTimer then
                WQAT.loginTimer:Cancel()
            end
            WQAT.loginTimer = C_Timer.NewTimer(1.5, function()
                WQAT:RunScan()
            end)
        end
    elseif event == "RECEIVED_ACHIEVEMENT_LIST" then
        if not WQAT.initialScanDone then
            if WQAT.achRetryTimer then
                WQAT.achRetryTimer:Cancel()
                WQAT.achRetryTimer = nil
            end
            if WQAT.loginTimer then
                WQAT.loginTimer:Cancel()
            end
            WQAT.loginTimer = C_Timer.NewTimer(1.5, function()
                WQAT:RunScan(true)
            end)
        end
    elseif event == "QUEST_TURNED_IN" then
        local questID = ...
        if questID and WQAT.scannedNeededQuests then
            local removed = false
            for i = #WQAT.scannedNeededQuests, 1, -1 do
                if WQAT.scannedNeededQuests[i].questID == questID then
                     table.remove(WQAT.scannedNeededQuests, i)
                     removed = true
                end
            end
            if removed and WQAT.UpdateUI then
                WQAT:UpdateUI()
            end
        end
    end
end)

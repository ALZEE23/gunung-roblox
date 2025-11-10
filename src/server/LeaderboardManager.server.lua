local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local LeaderboardManager = {}

-- 💾 DataStore untuk leaderboard
local leaderboardStore = DataStoreService:GetDataStore("PlayerLeaderboard")

-- 📊 Create leaderstats untuk player dengan saved data
local function createLeaderstats(player)
    -- 🔍 Load saved data dulu
    local savedData = nil
    local success, err = pcall(function()
        savedData = leaderboardStore:GetAsync(player.UserId)
    end)
    
    if not success then
        warn("[Leaderboard] Failed to load data for", player.Name, ":", err)
        savedData = nil
    end
    
    -- Default values atau dari saved data
    local defaultData = {
        score = 0,
        trashed = 0,
        collected = 0
    }
    
    local data = savedData or defaultData
    
    -- Create leaderstats folder
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    leaderstats.Parent = player
    
    -- 💰 Score
    local score = Instance.new("IntValue")
    score.Name = "💰 Score"
    score.Value = data.score or 0
    score.Parent = leaderstats
    
    -- 🗑️ Items Trashed  
    local trashed = Instance.new("IntValue")
    trashed.Name = "🗑️ Trashed"
    trashed.Value = data.trashed or 0
    trashed.Parent = leaderstats
    
    -- 📦 Items Collected
    local collected = Instance.new("IntValue")
    collected.Name = "📦 Collected"
    collected.Value = data.collected or 0
    collected.Parent = leaderstats
    
    print("[Leaderboard] Created leaderstats for", player.Name, "- Score:", data.score, "Collected:", data.collected, "Trashed:", data.trashed)
end

-- 💾 Save leaderboard data
local function saveLeaderboardData(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local data = {
        score = leaderstats:FindFirstChild("💰 Score") and leaderstats["💰 Score"].Value or 0,
        trashed = leaderstats:FindFirstChild("🗑️ Trashed") and leaderstats["🗑️ Trashed"].Value or 0,
        collected = leaderstats:FindFirstChild("📦 Collected") and leaderstats["📦 Collected"].Value or 0
    }
    
    local success, err = pcall(function()
        leaderboardStore:SetAsync(player.UserId, data)
    end)
    
    if success then
        print("[Leaderboard] Saved data for", player.Name, "- Score:", data.score, "Collected:", data.collected)
    else
        warn("[Leaderboard] Failed to save data for", player.Name, ":", err)
    end
end

-- 🏆 3D LEADERBOARD INTEGRATION
local OrderedLeaderboardStore = DataStoreService:GetOrderedDataStore("PlayerLeaderboard_Ordered")

-- 💾 Save to OrderedDataStore for 3D leaderboard
local function saveToOrderedStore(player)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return end
    
    local score = leaderstats:FindFirstChild("💰 Score")
    if not score then return end
    
    -- Convert score untuk OrderedDataStore (logarithmic compression)
    local storedValue = score.Value ~= 0 and math.floor(math.log(score.Value) / math.log(1.0000001)) or 0
    
    local success, err = pcall(function()
        OrderedLeaderboardStore:SetAsync(player.Name, storedValue)
    end)
    
    if success then
        print("[Leaderboard] Saved", player.Name, "to OrderedDataStore - Score:", score.Value)
    else
        warn("[Leaderboard] Failed to save to OrderedDataStore:", err)
    end
end

-- 📊 Get top players for 3D leaderboard
function LeaderboardManager.getTopPlayers(count)
    count = count or 100
    
    local success, result = pcall(function()
        return OrderedLeaderboardStore:GetSortedAsync(false, count)
    end)
    
    if success then
        local page = result:GetCurrentPage()
        local topPlayers = {}
        
        for rank, data in ipairs(page) do
            local retrievedValue = data.value ~= 0 and (1.0000001 ^ data.value) or 0
            table.insert(topPlayers, {
                rank = rank,
                name = data.key,
                score = retrievedValue
            })
        end
        
        return topPlayers
    else
        warn("[Leaderboard] Failed to get top players:", result)
        return {}
    end
end

-- Save to OrderedDataStore when player leaves
local originalPlayerRemoving = Players.PlayerRemoving:Connect(function() end)
originalPlayerRemoving:Disconnect()

Players.PlayerRemoving:Connect(function(player)
    saveLeaderboardData(player)
    saveToOrderedStore(player)
end)


-- 🎯 Update player score
function LeaderboardManager.updateScore(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local score = leaderstats:FindFirstChild("💰 Score")
        if score then
            score.Value = score.Value + amount
            print("[Leaderboard] Updated", player.Name, "score to:", score.Value, "(+" .. amount .. ")")
            
            -- 🔧 Auto-save to OrderedDataStore
            saveToOrderedStore(player)
        else
            warn("[Leaderboard] Score stat not found for", player.Name)
        end
    else
        warn("[Leaderboard] Leaderstats not found for", player.Name)
    end
end

-- 🗑️ Update trash count
function LeaderboardManager.updateTrashed(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local trashed = leaderstats:FindFirstChild("🗑️ Trashed")
        if trashed then
            trashed.Value = trashed.Value + (amount or 1)
            print("[Leaderboard] Updated", player.Name, "trashed to:", trashed.Value, "(+" .. (amount or 1) .. ")")
        else
            warn("[Leaderboard] Trashed stat not found for", player.Name)
        end
    else
        warn("[Leaderboard] Leaderstats not found for", player.Name)
    end
end

-- 📦 Update collected count
function LeaderboardManager.updateCollected(player, amount)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local collected = leaderstats:FindFirstChild("📦 Collected")
        if collected then
            collected.Value = collected.Value + (amount or 1)
            print("[Leaderboard] Updated", player.Name, "collected to:", collected.Value, "(+" .. (amount or 1) .. ")")
        else
            warn("[Leaderboard] Collected stat not found for", player.Name)
        end
    else
        warn("[Leaderboard] Leaderstats not found for", player.Name)
    end
end

-- 🔄 Auto-save every 30 seconds
local function startAutoSave()
    while true do
        wait(30)
        for _, player in pairs(Players:GetPlayers()) do
            saveLeaderboardData(player)
        end
        print("[Leaderboard] Auto-saved all player data")
    end
end

-- Player events
Players.PlayerAdded:Connect(createLeaderstats)
Players.PlayerRemoving:Connect(saveLeaderboardData)

-- Start auto-save
spawn(startAutoSave)

-- 🔧 Export to global untuk script lain
_G.LeaderboardManager = LeaderboardManager

print("[LeaderboardManager] Leaderboard system with DataStore initialized!")
print("[LeaderboardManager] 3D Leaderboard integration added!")
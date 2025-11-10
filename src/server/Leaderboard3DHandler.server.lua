local dss = game:GetService("DataStoreService")
local ds = dss:GetOrderedDataStore("PlayerLeaderboard_Ordered")
local resetTime = 30 -- Update every 30 seconds

-- 🔍 Find leaderboard model - FIXED PATH
local lbModel = workspace:FindFirstChild("LeaderboardModel") -- Change to your model name
if not lbModel then
    warn("[Leaderboard3D] LeaderboardModel not found in Workspace!")
    return
end

-- ✅ FIXED: Dummies are direct children of LeaderboardModel
local dummy1 = lbModel:FindFirstChild("Dummy1")
local dummy2 = lbModel:FindFirstChild("Dummy2")
local dummy3 = lbModel:FindFirstChild("Dummy3")

if not dummy1 or not dummy2 or not dummy3 then
    warn("[Leaderboard3D] One or more dummies not found!")
    warn("Dummy1:", dummy1, "Dummy2:", dummy2, "Dummy3:", dummy3)
    return
end

local dum1Hum = dummy1:WaitForChild("Humanoid")
local dum2Hum = dummy2:WaitForChild("Humanoid")
local dum3Hum = dummy3:WaitForChild("Humanoid")

-- ✅ FIXED: Board is inside Model folder
local modelFolder = lbModel:FindFirstChild("Model")
if not modelFolder then
    warn("[Leaderboard3D] Model folder not found!")
    return
end

local board = modelFolder:FindFirstChild("Board")
if not board then
    warn("[Leaderboard3D] Board not found in Model folder!")
    return
end

-- ✅ FIXED: Path to GlobalLBGui and List
local globalLBGui = board:FindFirstChild("GlobalLBGui")
if not globalLBGui then
    warn("[Leaderboard3D] GlobalLBGui not found on Board!")
    return
end

local listFrame = globalLBGui:FindFirstChild("List")
if not listFrame then
    warn("[Leaderboard3D] List frame not found in GlobalLBGui!")
    return
end

local template = listFrame:FindFirstChild("Template")
if not template then
    warn("[Leaderboard3D] Template not found in List!")
    -- Create a basic template if missing
    template = Instance.new("Frame")
    template.Name = "Template"
    template.Size = UDim2.new(1, 0, 0, 40)
    template.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    template.BorderSizePixel = 0
    template.Visible = false
    
    local rank = Instance.new("TextLabel")
    rank.Name = "Rank"
    rank.Size = UDim2.new(0.2, 0, 1, 0)
    rank.BackgroundTransparency = 1
    rank.TextColor3 = Color3.fromRGB(255, 255, 255)
    rank.Font = Enum.Font.SourceSansBold
    rank.TextScaled = true
    rank.Parent = template
    
    local plrName = Instance.new("TextLabel")
    plrName.Name = "PlrName"
    plrName.Size = UDim2.new(0.5, 0, 1, 0)
    plrName.Position = UDim2.new(0.2, 0, 0, 0)
    plrName.BackgroundTransparency = 1
    plrName.TextColor3 = Color3.fromRGB(255, 255, 255)
    plrName.Font = Enum.Font.SourceSans
    plrName.TextScaled = true
    plrName.TextXAlignment = Enum.TextXAlignment.Left
    plrName.Parent = template
    
    local score = Instance.new("TextLabel")
    score.Name = "Score"
    score.Size = UDim2.new(0.3, 0, 1, 0)
    score.Position = UDim2.new(0.7, 0, 0, 0)
    score.BackgroundTransparency = 1
    score.TextColor3 = Color3.fromRGB(255, 255, 0)
    score.Font = Enum.Font.SourceSansBold
    score.TextScaled = true
    score.TextXAlignment = Enum.TextXAlignment.Right
    score.Parent = template
    
    template.Parent = listFrame
    print("[Leaderboard3D] Created basic template")
end

print("[Leaderboard3D] ✅ All components found successfully!")
print("[Leaderboard3D]   - LeaderboardModel:", lbModel.Name)
print("[Leaderboard3D]   - Dummies: Dummy1, Dummy2, Dummy3")
print("[Leaderboard3D]   - Board path: Model/Board/GlobalLBGui/List")

-- 💰 Use Score from LeaderboardManager
local storedValueName = "💰 Score"

-- 📊 Number formatting
local suffixes = {'','K','M','B','T','Qd','Qn','sx','Sp','O','N','de','Ud','DD','tdD','qdD','QnD','sxD','SpD','OcD','NvD','Vgn','UVg','DVg','TVg','qtV','QnV','SeV','SPG','OVG','NVG','TGN','UTG','DTG','tsTG','qtTG','QnTG','ssTG','SpTG','OcTG','NoAG','UnAG','DuAG','TeAG','QdAG','QnAG','SxAG','SpAG','OcAG','NvAG','CT'}
local function format(val)
    for i=1, #suffixes do
        if tonumber(val) < 10^(i*3) then
            return math.floor(val/((10^((i-1)*3))/100))/(100)..suffixes[i]
        end
    end
end

-- 👤 Cache for user IDs
local cache = {}
function getUserIdFromUsername(name)
    if cache[name] then return cache[name] end
    local player = game.Players:FindFirstChild(name)
    if player then
        cache[name] = player.UserId
        return player.UserId
    end 
    local id
    local success, err = pcall(function()
        id = game.Players:GetUserIdFromNameAsync(name)
    end)
    cache[name] = id
    return id
end

-- 🎨 Cache for character appearances
local characterAppearances = {}
function getCharacterApperance(userID)
    if characterAppearances[userID] then
        return characterAppearances[userID]
    end
    local humanoiddesc

    local success, err = pcall(function()
        humanoiddesc = game.Players:GetHumanoidDescriptionFromUserId(userID)
    end)
    if not success then
        warn(err)
        wait(3)
        return getCharacterApperance(userID) -- Retry
    end
    characterAppearances[userID] = humanoiddesc
    return humanoiddesc
end

-- 🏅 Rank badges
function removeRank(char)
    local head = char:WaitForChild("Head")
    local gui = head:FindFirstChild("LeaderboardRanks")

    if not gui then
        local rankGui = game.ReplicatedStorage:FindFirstChild("LeaderboardRanks")
        if rankGui then
            gui = rankGui:Clone()
            gui.Parent = head
        else
            return
        end
    end

    local badge = gui:FindFirstChild("CoinGod") or gui:FindFirstChild("Badge")
    if badge then
        badge.Visible = false
    end
end

function giveRank(char, place)
    local head = char:WaitForChild("Head")
    local gui = head:FindFirstChild("LeaderboardRanks")

    if not gui then
        local rankGui = game.ReplicatedStorage:FindFirstChild("LeaderboardRanks")
        if rankGui then
            gui = rankGui:Clone()
            gui.Parent = head
        else
            return
        end
    end

    local badge = gui:FindFirstChild("CoinGod") or gui:FindFirstChild("Badge")
    if badge then
        badge.Visible = true
        badge.Text = "Top ".. place .." 🎯"
    end
end

-- 🎭 Play animations for top 3 dummies
function playEmoteForDummies()
    for i = 1, 3 do
        local dummy = lbModel:FindFirstChild("Dummy".. i)
        if dummy then
            -- Setup physics
            for _, v in pairs(dummy:GetChildren()) do
                if v:IsA("BasePart") then
                    if v ~= dummy.PrimaryPart then
                        v.CanCollide = false
                        v.Anchored = false
                    else
                        local bodyV = Instance.new("BodyPosition", v)
                        bodyV.Position = v.Position
                        bodyV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
                        
                        local bodyG = Instance.new("BodyGyro", v)
                        bodyG.CFrame = v.CFrame
                        bodyG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
                        
                        v.CanCollide = true
                        v.Anchored = false
                    end
                end
            end
            
            -- Play animation
            local animation = Instance.new("Animation", dummy:WaitForChild("Humanoid"))
            if i == 1 then
                animation.AnimationId = 'rbxassetid://3337994105' 
            elseif i == 2 then
                animation.AnimationId = 'rbxassetid://4841405708'
            elseif i == 3 then
                animation.AnimationId = 'rbxassetid://3333499508'
            end

            local animationTrack = dummy:WaitForChild("Humanoid"):LoadAnimation(animation)
            animationTrack:Play()
        end
    end
end

playEmoteForDummies()

-- 🔄 Update leaderboard display
local function UpdateLeaderboard()
    local Success, Err = pcall(function()
        local Data = ds:GetSortedAsync(false, 100)
        local Page = Data:GetCurrentPage()
                
        local names = {}
        
        for Rank, Data in ipairs(Page) do
            local Name = Data.key
            local Amount = Data.value
            
            -- Create entry in list
            if template then
                local NewObj = template:Clone()
                NewObj.Name = "Rank" .. Rank
                NewObj.PlrName.Text = Name
                local retrievedValue = Data.value ~= 0 and (1.0000001 ^ Data.value) or 0
                
                -- Color based on rank
                if Rank == 1 then
                    NewObj.Rank.TextColor3 = Color3.fromRGB(255, 255, 0) -- Gold
                    local userID = getUserIdFromUsername(Name)
                    if userID then
                        local humanoiddesc = getCharacterApperance(userID)
                        if humanoiddesc then
                            dum1Hum:ApplyDescription(humanoiddesc)
                            dum1Hum.DisplayName = Name
                        end
                    end
                elseif Rank == 2 then
                    NewObj.Rank.TextColor3 = Color3.fromRGB(192, 192, 192) -- Silver
                    local userID = getUserIdFromUsername(Name)
                    if userID then
                        local humanoiddesc = getCharacterApperance(userID)
                        if humanoiddesc then
                            dum2Hum:ApplyDescription(humanoiddesc)
                            dum2Hum.DisplayName = Name
                        end
                    end
                elseif Rank == 3 then
                    NewObj.Rank.TextColor3 = Color3.fromRGB(205, 127, 50) -- Bronze
                    local userID = getUserIdFromUsername(Name)
                    if userID then
                        local humanoiddesc = getCharacterApperance(userID)
                        if humanoiddesc then
                            dum3Hum:ApplyDescription(humanoiddesc)
                            dum3Hum.DisplayName = Name
                        end
                    end
                end
                
                if game.Players:FindFirstChild(Name) then
                    names[Name] = Rank
                end
                
                NewObj.Score.Text = format(retrievedValue)
                NewObj.Rank.Text = "#"..Rank
                NewObj.Visible = true
                NewObj.Parent = listFrame
            end
        end
        
        -- Give ranks to online players
        for _, player in pairs(game.Players:GetPlayers()) do
            if names[player.Name] then
                local char = player.Character or player.CharacterAdded:Wait()
                giveRank(char, names[player.Name])
            else
                if player.Character then
                    removeRank(player.Character)
                end
            end
        end
    end)
    
    if not Success then
        warn("[Leaderboard3D] Error updating leaderboard:", Err)
    end
end

-- 🔄 Auto-update loop
local timeUntilReset = resetTime

spawn(function()
    while wait(1) do
        timeUntilReset = timeUntilReset - 1

        if timeUntilReset == 0 then
            timeUntilReset = resetTime
            
            -- Clear old entries
            for _, v in pairs(listFrame:GetChildren()) do
                if v:IsA("Frame") and v.Name ~= "Template" then
                    v:Destroy()
                end
            end
            
            -- Update display
            UpdateLeaderboard()
            
            print("[Leaderboard3D] Updated leaderboard display")
        end
    end
end)

-- Initial update
UpdateLeaderboard()

print("[Leaderboard3D] 3D Leaderboard handler initialized!")
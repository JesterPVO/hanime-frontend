-- // Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)

-- // Overpowered Configuration
local Config = {
    Range = 100,                  -- Massive target detection sphere
    MaxTargetsPerFrame = 15,     -- Hits up to 15 targets EVERY FRAME
    ToggleKey = Enum.KeyCode.K,
    AutoTeleport = true,          -- Instantly locks onto targets spatially
    TeleportOffset = Vector3.new(0, 0, 3), -- Positioned directly behind target
    PacketMultiplier = 3,         -- Replicates remote calls per frame to force hit registration
    ToggleKey = Enum.KeyCode.K
}

-- // Remote Resolution Engine
local Remote = nil
pcall(function()
    Remote = ReplicatedStorage:WaitForChild("Systems"):WaitForChild("ActionsSystem"):WaitForChild("Network"):WaitForChild("Attack")
end)

-- // Global State
local enabled = false
local attackIndex = 1
local whitelistRegistry = {}

-- // High-Performance Target Retrieval
local function getValidTargets()
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return {} end
    
    local myPos = myChar.HumanoidRootPart.Position
    local targets = {}

    local function processEntity(entity)
        if not entity or entity == myChar then return end
        local hum = entity:FindFirstChildOfClass("Humanoid")
        local root = entity:FindFirstChild("HumanoidRootPart") or entity:FindFirstChild("Head")
        
        if hum and root and hum.Health > 0 then
            local dist = (root.Position - myPos).Magnitude
            if dist <= Config.Range then
                table.insert(targets, {
                    Character = entity,
                    Root = root,
                    Humanoid = hum,
                    Distance = dist
                })
            end
        end
    end

    -- Process Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not whitelistRegistry[player.Name] then
            processEntity(player.Character)
        end
    end

    -- Process Mobs / Entities Across Dynamic Directories
    local targetFolders = {workspace:FindFirstChild("Entities"), workspace:FindFirstChild("Mobs"), workspace:FindFirstChild("Monsters")}
    for _, folder in ipairs(targetFolders) do
        if folder then
            for _, mob in ipairs(folder:GetChildren()) do
                processEntity(mob)
            end
        end
    end

    -- Sort Nearest First
    table.sort(targets, function(a, b) return a.Distance < b.Distance end)
    return targets
end

-- // Network Packet Injector
local function fireRemotePacket(targetChar, targetPos)
    if not Remote then return end
    
    for _ = 1, Config.PacketMultiplier do
        task.spawn(function()
            pcall(function()
                if Remote:IsA("RemoteFunction") then
                    Remote:InvokeServer(targetChar, attackIndex, targetPos)
                elseif Remote:IsA("RemoteEvent") then
                    Remote:FireServer(targetChar, attackIndex, targetPos)
                end
            end)
        end)
    end
end

-- // Main Execution Loop (Engine Frequency)
RunService.RenderStepped:Connect(function()
    if not enabled then return end

    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return end
    local myRoot = myChar.HumanoidRootPart

    local targets = getValidTargets()
    local processedCount = 0

    for _, targetData in ipairs(targets) do
        if processedCount >= Config.MaxTargetsPerFrame then break end

        local targetChar = targetData.Character
        local targetRoot = targetData.Root

        -- Auto Teleport behind primary target
        if Config.AutoTeleport and processedCount == 0 then
            myRoot.CFrame = targetRoot.CFrame * CFrame.new(Config.TeleportOffset)
        end

        -- Look directly at target position
        myRoot.CFrame = CFrame.new(myRoot.Position, Vector3.new(targetRoot.Position.X, myRoot.Position.Y, targetRoot.Position.Z))

        -- Dispatch Attack Threads
        fireRemotePacket(targetChar, targetRoot.Position)

        attackIndex = (attackIndex % 5) + 1
        processedCount = processedCount + 1
    end
end)

-- // UI Construction
local oldGui = PlayerGui:FindFirstChild("EnhancedKillAura")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EnhancedKillAura"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 99999
screenGui.Parent = PlayerGui

-- Toggle UI Component
local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 100, 0, 100)
mainFrame.Position = UDim2.new(0.85, 0, 0.65, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new("UIStroke", mainFrame)
mainStroke.Color = Color3.fromRGB(255, 0, 50)
mainStroke.Thickness = 2.5

local toggleButton = Instance.new("TextButton", mainFrame)
toggleButton.Size = UDim2.new(0.84, 0, 0.84, 0)
toggleButton.Position = UDim2.new(0.08, 0, 0.08, 0)
toggleButton.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
toggleButton.BorderSizePixel = 0
toggleButton.Font = Enum.Font.GothamBold
toggleButton.Text = "DESTROY: OFF"
toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleButton.TextSize = 11
toggleButton.TextWrapped = true
Instance.new("UICorner", toggleButton).CornerRadius = UDim.new(0, 12)

-- Whitelist Frame
local wlFrame = Instance.new("Frame", screenGui)
wlFrame.Size = UDim2.new(0, 160, 0, 220)
wlFrame.Position = UDim2.new(0.85, -175, 0.65, 0)
wlFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
wlFrame.BorderSizePixel = 0
wlFrame.Active = true
wlFrame.Draggable = true
Instance.new("UICorner", wlFrame).CornerRadius = UDim.new(0, 12)

local wlStroke = Instance.new("UIStroke", wlFrame)
wlStroke.Color = Color3.fromRGB(40, 40, 40)
wlStroke.Thickness = 1.5

local wlTitle = Instance.new("TextLabel", wlFrame)
wlTitle.Size = UDim2.new(1, 0, 0, 30)
wlTitle.BackgroundTransparency = 1
wlTitle.Font = Enum.Font.GothamBold
wlTitle.Text = "WHITELIST"
wlTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
wlTitle.TextSize = 12

local wlScroll = Instance.new("ScrollingFrame", wlFrame)
wlScroll.Size = UDim2.new(0.9, 0, 0.78, 0)
wlScroll.Position = UDim2.new(0.05, 0, 0.2, 0)
wlScroll.BackgroundTransparency = 1
wlScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
wlScroll.ScrollBarThickness = 2

local wlLayout = Instance.new("UIListLayout", wlScroll)
wlLayout.Padding = UDim.new(0, 5)

wlLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    wlScroll.CanvasSize = UDim2.new(0, 0, 0, wlLayout.AbsoluteContentSize.Y + 10)
end)

-- Whitelist Logic
local function addWhitelistEntry(player)
    if player == LocalPlayer then return end
    local name = player.Name
    if whitelistRegistry[name] == nil then whitelistRegistry[name] = false end

    local pBtn = Instance.new("TextButton")
    pBtn.Name = name
    pBtn.Size = UDim2.new(1, 0, 0, 24)
    pBtn.BorderSizePixel = 0
    pBtn.Font = Enum.Font.GothamMedium
    pBtn.Text = name
    pBtn.TextSize = 11
    pBtn.TextColor3 = Color3.fromRGB(240, 240, 240)
    pBtn.Parent = wlScroll
    Instance.new("UICorner", pBtn).CornerRadius = UDim.new(0, 6)

    local function updateVisual()
        pBtn.BackgroundColor3 = whitelistRegistry[name] and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(30, 30, 30)
    end
    
    updateVisual()

    pBtn.Activated:Connect(function()
        whitelistRegistry[name] = not whitelistRegistry[name]
        updateVisual()
    end)
end

local function removeWhitelistEntry(player)
    whitelistRegistry[player.Name] = nil
    local existingBtn = wlScroll:FindFirstChild(player.Name)
    if existingBtn then existingBtn:Destroy() end
end

for _, player in ipairs(Players:GetPlayers()) do addWhitelistEntry(player) end
Players.PlayerAdded:Connect(addWhitelistEntry)
Players.PlayerRemoving:Connect(removeWhitelistEntry)

-- Toggle Action
local function toggleScript()
    enabled = not enabled
    local targetColor = enabled and Color3.fromRGB(0, 200, 80) or Color3.fromRGB(150, 0, 0)
    local targetText = enabled and "DESTROY: ON" or "DESTROY: OFF"
    
    TweenService:Create(toggleButton, TweenInfo.new(0.15), {BackgroundColor3 = targetColor}):Play()
    toggleButton.Text = targetText
end

toggleButton.Activated:Connect(toggleScript)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Config.ToggleKey then
        toggleScript()
    end
end)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 15)

-- Configuration Settings
local ATTACK_RANGE = 150 -- Expanded from 32 to 150 studs

-- Fetch Remote Safely
local Remote = nil
pcall(function()
    Remote = ReplicatedStorage.Systems.ActionsSystem.Network.Attack
end)

-- State Variables
local enabled = false
local attackIndex = 1
local conn = nil
local whitelistRegistry = {}

-- Utility Functions
local function valid(character)
    if not character then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    return hum and hrp and hum.Health > 0
end

local function getNearestTarget()
    local myChar = LocalPlayer.Character
    if not valid(myChar) then return nil end
    
    local myPos = myChar.HumanoidRootPart.Position
    local bestTarget, maxDistance = nil, ATTACK_RANGE

    -- Check Players
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and not whitelistRegistry[player.Name] then
            local char = player.Character
            if valid(char) then
                local dist = (char.HumanoidRootPart.Position - myPos).Magnitude
                if dist < maxDistance then
                    bestTarget = char
                    maxDistance = dist
                end
            end
        end
    end

    -- Check Mobs / Entities
    local entitiesFolder = workspace:FindFirstChild("Entities") or workspace:FindFirstChild("Mobs")
    if entitiesFolder then
        for _, entity in ipairs(entitiesFolder:GetChildren()) do
            if valid(entity) then
                local dist = (entity.HumanoidRootPart.Position - myPos).Magnitude
                if dist < maxDistance then
                    bestTarget = entity
                    maxDistance = dist
                end
            end
        end
    end

    return bestTarget
end

local function executeAttack(target)
    if not Remote then return end
    pcall(function() 
        Remote:InvokeServer(target, attackIndex) 
    end)
    attackIndex = (attackIndex == 1) and 2 or 1
end

-- UI Setup & Logic
local oldGui = PlayerGui:FindFirstChild("KillauraUI")
if oldGui then oldGui:Destroy() end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "KillauraUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 99999
screenGui.Parent = PlayerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 100, 0, 50)
frame.Position = UDim2.new(0.85, 0, 0.7, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -10, 1, -10)
toggleBtn.Position = UDim2.new(0, 5, 0, 5)
toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
toggleBtn.Text = "KILLAURA: OFF"
toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleBtn.TextSize = 11
toggleBtn.Font = Enum.Font.SourceSansBold
toggleBtn.Parent = frame

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 6)
btnCorner.Parent = toggleBtn

-- Dragging Logic
local dragging, dragInput, dragStart, startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

-- Main Toggle System
local function toggleScript()
    enabled = not enabled

    if enabled then
        toggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 100)
        toggleBtn.Text = "KILLAURA: MAX"
        
        -- Runs at frame-rate speed (no artificially introduced delays)
        conn = RunService.Heartbeat:Connect(function()
            local target = getNearestTarget()
            if target then
                task.spawn(executeAttack, target)
            end
        end)
    else
        toggleBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
        toggleBtn.Text = "KILLAURA: OFF"
        
        if conn then
            conn:Disconnect()
            conn = nil
        end
    end
end

toggleBtn.MouseButton1Click:Connect(toggleScript)
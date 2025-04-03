local plrs = game:GetService("Players")
local repl = game:GetService("ReplicatedStorage")
local threading = game:GetService("RunService")
local input = game:GetService("UserInputService")
local starterGui = game:GetService("StarterGui")
local camera = workspace.CurrentCamera
local me = plrs.LocalPlayer

-- Camera bypass
for _, con in next, getconnections(workspace.CurrentCamera.Changed) do
    task.wait()
    con:Disable()
end
for _, con in next, getconnections(workspace.CurrentCamera:GetPropertyChangedSignal("CFrame")) do
    task.wait()
    con:Disable()
end

local target = nil
local stompLoop
local isAutoStompActive = false
local movementKeys = {
    [Enum.KeyCode.W] = false,
    [Enum.KeyCode.A] = false,
    [Enum.KeyCode.S] = false,
    [Enum.KeyCode.D] = false
}

getgenv().Multiplier = 1  
local cframeEnabled = false
local espEnabled = true
local espFolder = Instance.new("Folder", game.CoreGui)
espFolder.Name = "ESP"

-- Weapon icons dictionary
local weaponIcons = {
    ["Double Barrel"] = "rbxassetid://7733715400",  -- Double Barrel Shotgun icon
    ["Revolver"] = "rbxassetid://7733718500",       -- Revolver icon
    ["SMG"] = "rbxassetid://7733712000",            -- SMG icon
    ["Knife"] = "rbxassetid://7733710000"           -- Knife icon
}

local ESP = {
    Boxes = {},
    Names = {},
    Distances = {},
    HealthBars = {},
    WeaponIcons = {}
}

local autoShootEnabled = false
local shootLoop = nil

local BulletTracers = {}
local tracerDuration = 0.1

local function mouse()
    if input.TouchEnabled then
        local viewportSize = camera.ViewportSize
        return Vector2.new(viewportSize.X/2, viewportSize.Y/2)
    else
        return input:GetMouseLocation()
    end
end

local function get_closet()
    if not me or not me.Character then return end
    local closest_player
    local max_distance = math.huge
    local mouse_pos = mouse()
    
    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= me and player.Character and player.Character:FindFirstChild("Head") then
            local screen_pos, on_screen = camera:WorldToViewportPoint(player.Character.Head.Position)
            if on_screen then
                local distance = (Vector2.new(screen_pos.X, screen_pos.Y) - mouse_pos).Magnitude
                if distance < max_distance then
                    max_distance = distance
                    closest_player = player
                end
            end
        end
    end
    target = closest_player
end

local function shoot()
    if target and target.Character and target.Character:FindFirstChild("Head") then
        local Headd = target.Character.Head
        local Root = me.Character:WaitForChild("HumanoidRootPart")
        
        local args = {
            [1] = "Shoot",
            [2] = {
                [1] = {
                    [1] = {
                        ["Instance"] = Headd,
                        ["Normal"] = Root.CFrame.LookVector.unit,
                        ["Position"] = Root.Position
                    }
                },
                [2] = {
                    [1] = {
                        ["thePart"] = Headd,
                        ["theOffset"] = CFrame.new(Root.CFrame.LookVector.unit * 0.5)
                    }
                },
                [3] = Root.Position + Root.CFrame.LookVector * 10,
                [4] = Root.Position,
                [5] = os.clock()
            }
        }
        repl.MainEvent:FireServer(unpack(args))
    end
end

-- Connect to all current tools
for _, tool in pairs(me.Backpack:GetChildren()) do
    if tool:IsA("Tool") then
        tool.Equipped:Connect(function()
            tool.Activated:Connect(shoot)
        end)
    end
end

-- Connect to future tools
me.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        child.Equipped:Connect(function()
            child.Activated:Connect(shoot)
        end)
    end
end)

-- Connect to current character's tool
if me.Character then
    local tool = me.Character:FindFirstChildOfClass("Tool")
    if tool then
        tool.Activated:Connect(shoot)
    end
end

-- Connect to future character's tools
me.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Activated:Connect(shoot)
        end
    end)
end)

local Loop
local loopFunction = function()
    game:GetService("ReplicatedStorage").MainEvent:FireServer("Stomp")
end

local Start = function()
    Loop = game:GetService("RunService").Heartbeat:Connect(loopFunction)
    starterGui:SetCore("SendNotification", {
        Title = "Auto-Stomp",
        Text = "Enabled",
        Duration = 2
    })
end

local Pause = function()
    if Loop then
        Loop:Disconnect()
        Loop = nil
    end
    starterGui:SetCore("SendNotification", {
        Title = "Auto-Stomp",
        Text = "Disabled",
        Duration = 2
    })
end

local function startAutoShoot()
    if shootLoop then return end
    shootLoop = threading.Heartbeat:Connect(function()
        shoot()
    end)
end

local function stopAutoShoot()
    if shootLoop then
        shootLoop:Disconnect()
        shootLoop = nil
    end
end

input.InputBegan:Connect(function(key, gameProcessed)
    if gameProcessed then return end
    if key.KeyCode == Enum.KeyCode.H then
        isAutoStompActive = not isAutoStompActive
        if isAutoStompActive then
            Start()
        else
            Pause()
        end
    elseif movementKeys[key.KeyCode] ~= nil then
        movementKeys[key.KeyCode] = true
    elseif key.KeyCode == Enum.KeyCode.V then
        cframeEnabled = not cframeEnabled
        if cframeEnabled then
            repeat
                if me.Character and me.Character:FindFirstChild("HumanoidRootPart") then
                    me.Character.HumanoidRootPart.CFrame = me.Character.HumanoidRootPart.CFrame + me.Character.Humanoid.MoveDirection * getgenv().Multiplier
                end
                threading.Stepped:Wait()
            until not cframeEnabled
        end
    elseif key.KeyCode == Enum.KeyCode.F then
        autoShootEnabled = not autoShootEnabled
        if autoShootEnabled then
            startAutoShoot()
            starterGui:SetCore("SendNotification", {
                Title = "Auto-Shoot",
                Text = "Enabled",
                Duration = 2
            })
        else
            stopAutoShoot()
            starterGui:SetCore("SendNotification", {
                Title = "Auto-Shoot",
                Text = "Disabled",
                Duration = 2
            })
        end
    end
end)

input.InputEnded:Connect(function(key)
    if movementKeys[key.KeyCode] ~= nil then
        movementKeys[key.KeyCode] = false
    end
end)

local function createESP(player)
    if player == me then return end
    
    -- Create box outline
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = Color3.new(1, 1, 1)
    box.Thickness = 1
    box.Transparency = 1
    box.Filled = false
    
    -- Create name text
    local name = Drawing.new("Text")
    name.Visible = false
    name.Color = Color3.new(1, 1, 1)
    name.Size = 16
    name.Center = true
    name.Outline = true
    name.Text = player.Name

    -- Create distance text
    local distance = Drawing.new("Text")
    distance.Visible = false
    distance.Color = Color3.new(1, 1, 1)
    distance.Size = 14
    distance.Center = true
    distance.Outline = true

    -- Create health bar
    local healthBar = {
        outline = Drawing.new("Square"),
        fill = Drawing.new("Square")
    }
    healthBar.outline.Visible = false
    healthBar.outline.Color = Color3.new(0, 0, 0)
    healthBar.outline.Thickness = 1
    healthBar.outline.Filled = false
    
    healthBar.fill.Visible = false
    healthBar.fill.Color = Color3.new(0, 1, 0)
    healthBar.fill.Thickness = 1
    healthBar.fill.Filled = true
    
    -- Create weapon icon
    local weaponIcon = Drawing.new("Image")
    weaponIcon.Visible = false
    weaponIcon.Size = Vector2.new(20, 20)
    weaponIcon.Transparency = 1
    
    -- Store ESP elements
    ESP.Boxes[player] = box
    ESP.Names[player] = name
    ESP.Distances[player] = distance
    ESP.HealthBars[player] = healthBar
    ESP.WeaponIcons[player] = weaponIcon
    
    local function updateESP()
        if player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = player.Character.HumanoidRootPart
            local head = player.Character.Head
            local humanoid = player.Character:FindFirstChild("Humanoid")
            
            -- Calculate distance
            local magnitude = (me.Character and me.Character:FindFirstChild("HumanoidRootPart")) and 
                (me.Character.HumanoidRootPart.Position - humanoidRootPart.Position).Magnitude or 0
            local distanceText = string.format("%.0fm", magnitude)
            
            -- Calculate top and bottom positions
            local topPos = head.Position + Vector3.new(0, 1, 0)
            local bottomPos = humanoidRootPart.Position - Vector3.new(0, 3, 0)
            
            local top, onScreenTop = camera:WorldToViewportPoint(topPos)
            local bottom, onScreenBottom = camera:WorldToViewportPoint(bottomPos)
            
            if onScreenTop and onScreenBottom then
                -- Update box
                local boxSize = Vector2.new(math.abs(top.Y - bottom.Y) / 2, math.abs(top.Y - bottom.Y))
                local boxPosition = Vector2.new(bottom.X - boxSize.X / 2, bottom.Y - boxSize.Y)
                
                box.Size = boxSize
                box.Position = boxPosition
                box.Visible = true
                
                -- Update name and distance
                name.Position = Vector2.new(bottom.X, boxPosition.Y - 25)
                name.Visible = true
                
                distance.Text = distanceText
                distance.Position = Vector2.new(bottom.X, boxPosition.Y - 40)
                distance.Visible = true

                -- Update health bar
                if humanoid then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barHeight = boxSize.Y
                    local barWidth = 3
                    local barX = boxPosition.X - 5
                    local barY = boxPosition.Y
                    
                    -- Update health bar outline
                    healthBar.outline.Size = Vector2.new(barWidth, barHeight)
                    healthBar.outline.Position = Vector2.new(barX, barY)
                    healthBar.outline.Visible = true
                    
                    -- Update health bar fill
                    local fillHeight = barHeight * healthPercent
                    healthBar.fill.Size = Vector2.new(barWidth, fillHeight)
                    healthBar.fill.Position = Vector2.new(barX, barY + (barHeight - fillHeight))
                    healthBar.fill.Visible = true
                    
                    -- Update health bar color based on health percentage
                    healthBar.fill.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                end

                -- Update weapon icon
                local tool = player.Character:FindFirstChildOfClass("Tool")
                if tool and weaponIcons[tool.Name] then
                    weaponIcon.Data = weaponIcons[tool.Name]
                    weaponIcon.Position = Vector2.new(bottom.X - 10, boxPosition.Y + boxSize.Y + 5)
                    weaponIcon.Visible = true
                else
                    weaponIcon.Visible = false
                end
            else
                box.Visible = false
                name.Visible = false
                distance.Visible = false
                healthBar.outline.Visible = false
                healthBar.fill.Visible = false
                weaponIcon.Visible = false
            end
        else
            box.Visible = false
            name.Visible = false
            distance.Visible = false
            healthBar.outline.Visible = false
            healthBar.fill.Visible = false
            weaponIcon.Visible = false
        end
    end
    
    -- Connect update function
    local connection = threading.RenderStepped:Connect(function()
        updateESP()
    end)
    
    -- Cleanup when player leaves
    player.CharacterRemoving:Connect(function()
        box.Visible = false
        name.Visible = false
        distance.Visible = false
        healthBar.outline.Visible = false
        healthBar.fill.Visible = false
        weaponIcon.Visible = false
    end)
    
    player.CharacterAdded:Connect(function()
        box.Visible = false
        name.Visible = false
        distance.Visible = false
        healthBar.outline.Visible = false
        healthBar.fill.Visible = false
        weaponIcon.Visible = false
        task.wait(1)
        updateESP()
    end)
end

local function refreshESP()
    for player, box in pairs(ESP.Boxes) do
        if not plrs:FindFirstChild(player.Name) then
            box:Remove()
            ESP.Boxes[player] = nil
            ESP.Names[player]:Remove()
            ESP.Names[player] = nil
            ESP.Distances[player]:Remove()
            ESP.Distances[player] = nil
            ESP.HealthBars[player].outline:Remove()
            ESP.HealthBars[player].fill:Remove()
            ESP.HealthBars[player] = nil
            ESP.WeaponIcons[player]:Remove()
            ESP.WeaponIcons[player] = nil
        end
    end
    
    for _, player in pairs(plrs:GetPlayers()) do
        if player ~= me and not ESP.Boxes[player] then
            createESP(player)
        end
    end
end

threading.RenderStepped:Connect(function()
    get_closet()
    task.wait(0.1)  -- Wait 0.1 seconds between refreshes
    refreshESP()
end)

local screenGui = Instance.new("ScreenGui", game.CoreGui)
local frame = Instance.new("Frame", screenGui)
frame.Size = UDim2.new(0, 200, 0, 100)
frame.Position = UDim2.new(0, 10, 0.5, -50)
frame.BackgroundTransparency = 0.5
frame.BackgroundColor3 = Color3.new(0, 0, 0)

local keybindsText = Instance.new("TextLabel", frame)
keybindsText.Size = UDim2.new(1, 0, 1, 0)
keybindsText.Text = [[Keybinds:
H - Auto Stomp
V - CFrame Speed
F - Auto Shoot]]

keybindsText.TextColor3 = Color3.new(1, 1, 1)
keybindsText.BackgroundTransparency = 1
keybindsText.TextSize = 14
keybindsText.TextXAlignment = Enum.TextXAlignment.Left
keybindsText.Position = UDim2.new(0, 10, 0, 0)

-- Add cleanup when script ends
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child == espFolder then
        for _, box in pairs(ESP.Boxes) do
            box:Remove()
        end
        for _, name in pairs(ESP.Names) do
            name:Remove()
        end
        for _, distance in pairs(ESP.Distances) do
            distance:Remove()
        end
        for _, healthBar in pairs(ESP.HealthBars) do
            healthBar.outline:Remove()
            healthBar.fill:Remove()
        end
        for _, weaponIcon in pairs(ESP.WeaponIcons) do
            weaponIcon:Remove()
        end
        ESP.Boxes = {}
        ESP.Names = {}
        ESP.Distances = {}
        ESP.HealthBars = {}
        ESP.WeaponIcons = {}
    end
end)

-- Add hit marker functionality
local function createHitMarker(hitPart, hitPlayer)
    local hitMarker = Drawing.new("Text")
    hitMarker.Text = "HIT"
    hitMarker.Size = 20
    hitMarker.Color = Color3.new(1, 0, 0)
    hitMarker.Center = true
    hitMarker.Outline = true
    
    local hitPos = hitPart.Position
    local screenPos, onScreen = camera:WorldToViewportPoint(hitPos)
    
    if onScreen then
        hitMarker.Position = Vector2.new(screenPos.X, screenPos.Y)
        hitMarker.Visible = true
        
        -- Animate and remove hit marker
        task.spawn(function()
            for i = 1, 20 do
                hitMarker.Position = hitMarker.Position + Vector2.new(0, -1)
                task.wait(0.01)
            end
            hitMarker:Remove()
        end)
    end
end

-- Add bullet tracer functionality
local function createBulletTracer(startPos, endPos)
    local tracer = Drawing.new("Line")
    tracer.Visible = true
    tracer.Color = Color3.new(1, 0, 0)
    tracer.Thickness = 1
    tracer.Transparency = 1
    
    local startScreen, startOnScreen = camera:WorldToViewportPoint(startPos)
    local endScreen, endOnScreen = camera:WorldToViewportPoint(endPos)
    
    if startOnScreen and endOnScreen then
        tracer.From = Vector2.new(startScreen.X, startScreen.Y)
        tracer.To = Vector2.new(endScreen.X, endScreen.Y)
        table.insert(BulletTracers, tracer)
        
        task.delay(tracerDuration, function()
            tracer:Remove()
            table.remove(BulletTracers, table.find(BulletTracers, tracer))
        end)
    end
end


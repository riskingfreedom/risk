local plrs = game:GetService("Players")
local repl = game:GetService("ReplicatedStorage")
local threading = game:GetService("RunService")
local input = game:GetService("UserInputService")
local starterGui = game:GetService("StarterGui")
local camera = workspace.CurrentCamera
local me = plrs.LocalPlayer

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

local ESP = {
    Boxes = {},
    Names = {},
    Distances = {}
}

local autoShootEnabled = false
local shootLoop = nil

local function mouse()
    if input.TouchEnabled then
        local viewportSize = camera.ViewportSize
        return Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
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

me.Backpack.ChildAdded:Connect(function(child)
    if child:IsA("Tool") then
        child.Equipped:Connect(function()
            child.Activated:Connect(shoot)
        end)
    end
end)

for _, tool in pairs(me.Backpack:GetChildren()) do
    if tool:IsA("Tool") then
        tool.Equipped:Connect(function()
            tool.Activated:Connect(shoot)
        end)
    end
end

if me.Character then
    local tool = me.Character:FindFirstChildOfClass("Tool")
    if tool then
        tool.Activated:Connect(shoot)
    end
end

me.CharacterAdded:Connect(function(character)
    character.ChildAdded:Connect(function(child)
        if child:IsA("Tool") then
            child.Activated:Connect(shoot)
        end
    end)
    task.wait(1)  -- Wait for humanoid to load
    removeJumpCooldown()
end)

local function removeJumpCooldown()
    if me.Character and me.Character:FindFirstChild("Humanoid") then
        local humanoid = me.Character.Humanoid
        if humanoid.UseJumpPower then
            humanoid.UseJumpPower = false
        end
        humanoid.JumpPower = 50
    end
end

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
    
    -- Store ESP elements
    ESP.Boxes[player] = box
    ESP.Names[player] = name
    ESP.Distances[player] = distance
    
    local function updateESP()
        if player.Character and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("HumanoidRootPart") then
            local humanoidRootPart = player.Character.HumanoidRootPart
            local head = player.Character.Head
            
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
            else
                box.Visible = false
                name.Visible = false
                distance.Visible = false
            end
        else
            box.Visible = false
            name.Visible = false
            distance.Visible = false
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
    end)
    
    player.CharacterAdded:Connect(function()
        box.Visible = false
        name.Visible = false
        distance.Visible = false
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
    removeJumpCooldown()  -- Remove jump cooldown every frame
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
        ESP.Boxes = {}
        ESP.Names = {}
        ESP.Distances = {}
    end
end)

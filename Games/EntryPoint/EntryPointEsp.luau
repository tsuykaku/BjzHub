local AIFolder = game:GetService("Workspace").Level.Actors
local camFolder = game:GetService("Workspace").Level

local camera = workspace.CurrentCamera
local players = game:GetService("Players")
local localplayerhumanoid = players.LocalPlayer.Character.Humanoid

local HeadOff = Vector3.new(0, 0.5, 0)
local LegOff = Vector3.new(0,3.5,0)
local BoxDown = Vector3.new(0,5,0)

function getDistance(part)
    return (part.Position - camera.CFrame.Position).Magnitude
end

function UpdateHealth(humanoid)
    return humanoid.Health
end

function esp(Enemy)
    local EnemyHumanoid = Enemy:WaitForChild("Humanoid")
    local EnemyHRP = Enemy:WaitForChild("HumanoidRootPart")
    
    local NameText = Drawing.new("Text")
    NameText.Visible = false
    NameText.Center = true
    NameText.Outline = true
    NameText.Font = 3
    NameText.Color = Color3.fromRGB(255, 0, 0)
    NameText.Size = 20
    NameText.Transparency = 0.4
    
    local Line = Drawing.new("Line")
    Line.Visible = false
    Line.From = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 1.3)
    Line.To = Vector2.new(0,0)
    Line.Color = Color3.fromRGB(255,0,0)
    Line.Thickness = 0.1
    Line.Transparency = 0.3
    
    local healthText = Drawing.new("Text")
    healthText.Visible = false
    healthText.Center = true
    healthText.Outline = true
    healthText.Font = 3
    healthText.Color = Color3.fromRGB(255,255,255)
    healthText.Size = 15

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255,255,255)
    Box.Thickness = 1
    Box.Transparency = 1
    Box.Filled = false

    local HealthBar = Drawing.new("Square")
    HealthBar.Visible = false
    HealthBar.Color = Color3.new(0,1,0)
    HealthBar.Thickness = 1
    HealthBar.Transparency = 1
    HealthBar.Filled = false
    

    local renderstepped
    renderstepped = game:GetService("RunService").RenderStepped:Connect(function()
        if Enemy:IsA("Model") and EnemyHumanoid ~= nil and
        EnemyHumanoid.Health > 0 and 
        localplayerhumanoid.Health > 0 then
            
            local Pos, Onscreen = camera:WorldToViewportPoint(EnemyHRP.Position - BoxDown)

            local TorsoPosition = camera:WorldToViewportPoint(EnemyHRP.Position)
            local HeadPosition = camera:WorldToViewportPoint(Enemy.Head.Position + HeadOff)
            local LegPosition = camera:WorldToViewportPoint(EnemyHRP.Position - LegOff)
            
            if Onscreen then

                --[Line
                Line.To = Vector2.new(Pos.X, Pos.Y)
                Line.Visible = true
                --Line]
                
                --[Text
                NameText.Position = Vector2.new(Pos.X, Pos.Y)
                NameText.Visible = true
                NameText.Text = Enemy.Name
                
                healthText.Position = Vector2.new(NameText.Position.X, NameText.Position.Y + 15)
                healthText.Visible = true
                healthText.Text = "[" .. math.floor(UpdateHealth(EnemyHumanoid)) .. "/" .. math.floor(EnemyHumanoid.MaxHealth) .. "]" .. "[" .. math.floor(getDistance(EnemyHRP)) .. "]"
                --Text]
                
                Box.Size = Vector2.new(1500 / TorsoPosition.Z, HeadPosition.Y - LegPosition.Y)
                Box.Position = Vector2.new(TorsoPosition.X - Box.Size.X / 2, TorsoPosition.Y - Box.Size.Y / 2)
                Box.Visible = true

                HealthBar.Size = Vector2.new(2, (HeadPosition.Y - LegPosition.Y) / (EnemyHumanoid.MaxHealth / math.clamp(EnemyHumanoid.Health, 0, EnemyHumanoid.MaxHealth)))
                HealthBar.Position = Vector2.new(Box.Position.X - 6, Box.Position.Y + (1 / HealthBar.Size.Y))
                HealthBar.Visible = true
            else
                Line.Visible = false
                
                NameText.Visible = false
                
                Box.Visible = false
                
                healthText.Visible = false
                
                HealthBar.Visible = false
            end
        else
            Line.Visible = false
            Line:Remove()
            
            NameText.Visible = false
            NameText:Remove()
            
            HealthBar.Visible = false
            HealthBar:Remove()
            
            Box.Visible = false
            Box:Remove()
            
            healthText.Visible = false
            healthText:Remove()
            
            renderstepped:Disconnect()
        end
    end)
end

function camESP(Item)
    

    local camera = workspace.CurrentCamera

    local ItemHeadOff = Vector3.new(0, 0.5, 0)
    local ItemLegOff = Vector3.new(0,1,0)
    local ItemBoxDown = Vector3.new(0,3,0)

    local camBody = Item:WaitForChild("Body")
    
    local ItemNameText = Drawing.new("Text")
    ItemNameText.Visible = false
    ItemNameText.Center = true
    ItemNameText.Outline = true
    ItemNameText.Color = Color3.fromRGB(255, 255, 0)
    ItemNameText.Font = 3
    ItemNameText.Size = 20
    ItemNameText.ZIndex = 0
    ItemNameText.Transparency = 0.7

    local Box = Drawing.new("Square")
    Box.Visible = false
    Box.Color = Color3.fromRGB(255, 255, 0)
    Box.Thickness = 1
    Box.Transparency = 1
    Box.Filled = false
    

    local renderstepped
    renderstepped = game:GetService("RunService").RenderStepped:Connect(function()
        if Item:FindFirstChild("Body") then
            
            local ItemPos, ItemOnscreen = camera:WorldToViewportPoint(camBody.Position - ItemBoxDown)

            local TorsoPosition = camera:WorldToViewportPoint(camBody.Position)
            local HeadPosition = camera:WorldToViewportPoint(camBody.Position + ItemHeadOff)
            local LegPosition = camera:WorldToViewportPoint(camBody.Position - ItemLegOff)

            if ItemOnscreen then

                ItemNameText.Position = Vector2.new(ItemPos.X, ItemPos.Y)
                ItemNameText.Visible = true
                ItemNameText.Text = Item.Name .. "[" .. math.floor(getDistance(camBody)) .. "]"
                
                Box.Size = Vector2.new(1500 / TorsoPosition.Z, HeadPosition.Y - LegPosition.Y)
                Box.Position = Vector2.new(TorsoPosition.X - Box.Size.X / 2, TorsoPosition.Y - Box.Size.Y / 2)
                Box.Visible = true
            else
                Box.Visible = false
                ItemNameText.Visible = false
            end
        else
            Box.Visible = false
            Box:Remove()
            
            ItemNameText.Visible = false
            ItemNameText:Remove()
            
            renderstepped:Disconnect()
        end
    end)
end

-- game:GetService("Workspace").Level
-- game:GetService("Workspace").Level.Glass.ExteriorCam

for i,cam in next, camFolder:GetDescendants() do
    if cam.Name == "ExteriorCam" then
        camESP(cam)
    end
end

camFolder.DescendantAdded:Connect(function(Added)
    if Added.Name == "ExteriorCam" then
        camESP(Added)
    end
end)





for i,Enemy in next, game:GetService("Workspace").Level.Actors:GetChildren() do
    Enemy = Enemy:WaitForChild("Character")
    if Enemy:IsA("Model") then
        EnemyHumanoid = Enemy:WaitForChild("Humanoid")
        EnemyHRP = Enemy:WaitForChild("HumanoidRootPart")
    end
    if Enemy:IsA("Model") and EnemyHumanoid ~= nil and EnemyHumanoid.Health > 0 and EnemyHRP ~= nil then
        esp(Enemy)
    end
end

AIFolder.ChildAdded:Connect(function(AddedChild)
    AddedChild = AddedChild:WaitForChild("Character")
    esp(AddedChild)
end)

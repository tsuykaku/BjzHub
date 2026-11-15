local RunService = game:GetService'RunService'
local Players = game:GetService'Players'
local UserInputService = game:GetService'UserInputService'
local TweenService = game:GetService'TweenService'
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera


local Holding = false
local PATH = game:GetService("Workspace").ClientZambies


getgenv().Settings = {
    NameTextEnable = true,
    NameTextColor = Color3.fromRGB(255, 0, 0),
    NameTextFont = 3,
    NameTextSize = 20,
    NameTextTransparency = 0.4,

    HealthTextEnable = false,
    HealthTextColor = Color3.fromRGB(255,255,255),
    HealthTextFont = 3,
    HealthTextSize = 15,
    HealthTextTransparency = 1,

    BoxEnable = true,
    BoxColor = Color3.fromRGB(255, 0, 0),
    BoxTransparency = 1,
    
    HealthBarEnable = false,
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    HealthBarTransparency = 1,
}

function ESP()
    local function addESP(Instance)
        

        --local InstanceHumanoid = Instance:WaitForChild("Humanoid")
        local HeadOff = Vector3.new(0, 0.5, 0)
        local LegOff = Vector3.new(0,3.5,0)
        local BoxDown = Vector3.new(0,5,0)


        -- 本地函式
        local function getDistance(part)
            return (part.Position - Camera.CFrame.Position).Magnitude
        end

        local function UpdateHealth(humanoid)
            return humanoid.Health
        end

        -- 繪製透視

        local NameText = Drawing.new("Text")
        NameText.Color = getgenv().Settings.NameTextColor
        NameText.Font = getgenv().Settings.NameTextFont
        NameText.Size = getgenv().Settings.NameTextSize
        NameText.Transparency = getgenv().Settings.NameTextTransparency
        NameText.Visible = false
        NameText.Center = true
        NameText.Outline = true

        local HealthText = Drawing.new("Text")
        HealthText.Color = getgenv().Settings.HealthTextColor
        HealthText.Font = getgenv().Settings.HealthTextFont
        HealthText.Size = getgenv().Settings.HealthTextSize
        HealthText.Transparency = getgenv().Settings.HealthTextTransparency
        HealthText.Visible = false
        HealthText.Center = true
        HealthText.Outline = true

        local Box = Drawing.new("Square")
        Box.Color = getgenv().Settings.BoxColor
        Box.Transparency = getgenv().Settings.BoxTransparency
        Box.Visible = false
        Box.Filled = false
        Box.Thickness = 1


        local HealthBar = Drawing.new("Square")
        HealthBar.Color = getgenv().Settings.HealthBarColor
        HealthBar.Transparency = getgenv().Settings.HealthBarTransparency
        HealthBar.Visible = false
        HealthBar.Thickness = 1
        HealthBar.Filled = false

        -- 渲染透視
        local RenderStepped
        RenderStepped = RunService.RenderStepped:Connect(function()
            if Instance and Instance:FindFirstChild("UpperTorso") and --[[InstanceHumanoid.Health > 0 and]] LocalPlayer.Character.Humanoid.Health > 0 then

                local Position, InstanceOnScreen = Camera:WorldToViewportPoint(Instance:WaitForChild("Head").Position - BoxDown)

                local TorsoPosition = Camera:WorldToViewportPoint(Instance.UpperTorso.Position)
                local HeadPosition = Camera:WorldToViewportPoint(Instance.Head.Position + HeadOff)
                local LegPosition = Camera:WorldToViewportPoint(Instance.UpperTorso.Position - LegOff)

                if InstanceOnScreen then

                    NameText.Position = Vector2.new(Position.X, Position.Y)
                    NameText.Visible = getgenv().Settings.NameTextEnable
                    NameText.Text = "Zombie"

                    --HealthText.Position = Vector2.new(NameText.Position.X, NameText.Position.Y + 15)
                    --HealthText.Visible = getgenv().Settings.HealthTextEnable
                    --HealthText.Text = "[" .. math.floor(UpdateHealth(InstanceHumanoid)) .. "/" .. math.floor(InstanceHumanoid.MaxHealth) .. "]" .. "[" .. math.floor(getDistance(Instance.Head)) .. "]"
                    
                    Box.Size = Vector2.new(1500 / TorsoPosition.Z, HeadPosition.Y - LegPosition.Y)
                    Box.Position = Vector2.new(TorsoPosition.X - Box.Size.X / 2, TorsoPosition.Y - Box.Size.Y / 2)
                    Box.Visible = getgenv().Settings.BoxEnable

                    --HealthBar.Size = Vector2.new(2, (HeadPosition.Y - LegPosition.Y) / (InstanceHumanoid.MaxHealth / math.clamp(InstanceHumanoid.Health, 0, InstanceHumanoid.MaxHealth)))
                    --HealthBar.Position = Vector2.new(Box.Position.X - 6, Box.Position.Y + (1 / HealthBar.Size.Y))
                    --HealthBar.Visible = getgenv().Settings.HealthBarEnable
                else
                    NameText.Visible = false

                    HealthBar.Visible = false

                    Box.Visible = false

                    HealthText.Visible = false
                end
            else
                NameText.Visible = false
                NameText:Remove()

                HealthBar.Visible = false
                HealthBar:Remove()

                Box.Visible = false
                Box:Remove()

                HealthText.Visible = false
                HealthText:Remove()

                RenderStepped:Disconnect()
            end
        end)
    end

    for _,v in next, PATH:GetChildren() do
        v = v
        addESP(v)
    end
    
    PATH.ChildAdded:Connect(function(Added)
        Added = Added
        addESP(Added)
    end)
    
end

ESP()




----------------------------------------------------------------------------------------------------

_G.AimbotEnabled = true
_G.TeamCheck = true
_G.AimPart = "Head"
_G.Sensitivity = 0

----------

_G.CircleNumSides = 64
_G.CircleColor = Color3.fromRGB(255,255,255)
_G.CircleTransparency = 0.7
_G.CircleRadius = 80
_G.CircleFilled = false
_G.CircleVisible = true
_G.CircleThickness = 0

local FOVCircle = Drawing.new("Circle")

FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.NumSides = _G.CircleNumSides
FOVCircle.Color = _G.CircleColor
FOVCircle.Transparency = _G.CircleTransparency
FOVCircle.Radius = _G.CircleRadius
FOVCircle.Filled = _G.CircleFilled
FOVCircle.Visible = _G.CircleVisible
FOVCircle.Thickness =_G.CircleThickness


local function GetClosestInstance()
    local MaximumDistance = _G.CircleRadius
    local Target = nil
    
    for _,v in next, PATH:GetChildren() do
        --if v.Name ~= LocalPlayer.Name then
            if _G.TeamCheck == true then
                --if v.Team ~= LocalPlayer.Team then
                    if v:FindFirstChild("UpperTorso") ~= nil then
                        --if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
                            local ScreenPoint = Camera:WorldToScreenPoint(v:WaitForChild("UpperTorso", math.huge).Position)
                            local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude

                            if VectorDistance < MaximumDistance then
                                Target = v
                            end
                        --end
                    end
                --end
            else
                if v ~= nil then
                    if v:FindFirstChild("UpperTorso") ~= nil then
                        --if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
                            local ScreenPoint = Camera:WorldToScreenPoint(v:WaitForChild("UpperTorso", math.huge).Position)
                            local VectorDistance = (Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y) - Vector2.new(ScreenPoint.X, ScreenPoint.Y)).Magnitude

                            if VectorDistance < MaximumDistance then
                                Target = v
                            end

                        --end
                    end
                end
            end
        --end
    end
    return Target
end


UserInputService.InputBegan:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(Input)
    if Input.UserInputType == Enum.UserInputType.MouseButton2 then
        Holding = false
    end
end)

RunService.RenderStepped:Connect(function()
    FOVCircle.Position = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
    FOVCircle.NumSides = _G.CircleNumSides
    FOVCircle.Color = _G.CircleColor
    FOVCircle.Transparency = _G.CircleTransparency
    FOVCircle.Radius = _G.CircleRadius
    FOVCircle.Filled = _G.CircleFilled
    FOVCircle.Visible = _G.CircleVisible
    FOVCircle.Thickness =_G.CircleThickness

    if Holding == true and _G.AimbotEnabled == true then
        TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, GetClosestInstance()[_G.AimPart].Position)}):Play()
    end
end)

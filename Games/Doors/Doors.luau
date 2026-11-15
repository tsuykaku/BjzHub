--[[簡短路徑]]
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local CurrentRoomsFolder = game:GetService("Workspace").CurrentRooms
local localplayerHRP = Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")


--[[函式]]
function flashText(textPath)
    for a = 0, 6 do
        textPath.Visible = true
        wait(0.1)
        textPath.Visible = false
        wait(0.1)
        textPath.Visible = true
    end
end

function createESP(parentPath, itemName, color, guiMaxDistance)
    local espGUI = Instance.new("BillboardGui", parentPath)
    local espTextLabel = Instance.new("TextLabel", espGUI)
    local espFrame = Instance.new("Frame", espGUI)
    local espUICorner = Instance.new("UICorner", espFrame)
    

    -- espGUI
    espGUI.AlwaysOnTop = true
    espGUI.Size = UDim2.new(1,0,1,0)
    espGUI.MaxDistance = guiMaxDistance or 99999999

    -- espFrame
    espFrame.BackgroundColor3 = color or Color3.fromRGB(255, 0, 255)
    espFrame.BackgroundTransparency = 0.65
    espFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    espFrame.Size = UDim2.new(1, 0, 1, 0)

    -- espUICorner
    espUICorner.CornerRadius = UDim.new(1, 0)

    -- espTextLabel
    espTextLabel.AnchorPoint = Vector2.new(0.4, 0)
    espTextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    espTextLabel.BackgroundTransparency = 1
    espTextLabel.Position = UDim2.new(0, 0, 0.9, 0)
    espTextLabel.Size = UDim2.new(5, 0, 1, 0)
    espTextLabel.Font = Enum.Font.SourceSans
    espTextLabel.Text = itemName
    espTextLabel.TextColor3 = color or Color3.fromRGB(255, 0, 255)
    espTextLabel.TextScaled = true
    espTextLabel.TextSize = 16
    espTextLabel.TextStrokeTransparency = 0
    espTextLabel.TextWrapped = true
end

function monsterESP(parentPath, monsterName)
    local espGUI = Instance.new("BillboardGui", parentPath)
    local espTextLabel = Instance.new("TextLabel", espGUI)
    local espFrame = Instance.new("Frame", espGUI)
    local espUICorner = Instance.new("UICorner", espFrame)
    

    -- espGUI
    espGUI.AlwaysOnTop = true
    espGUI.Size = UDim2.new(2, 0, 2, 0)
    espGUI.MaxDistance = 99999999

    -- espFrame
    espFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    espFrame.BackgroundTransparency = 0.65
    espFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
    espFrame.Size = UDim2.new(2, 0, 2, 0)

    -- espUICorner
    espUICorner.CornerRadius = UDim.new(1, 0)

    -- espTextLabel
    espTextLabel.AnchorPoint = Vector2.new(0.4, 0)
    espTextLabel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    espTextLabel.BackgroundTransparency = 1
    espTextLabel.Position = UDim2.new(0, 0, 0.9, 0)
    espTextLabel.Size = UDim2.new(5, 0, 1, 0)
    espTextLabel.Font = Enum.Font.SourceSans
    espTextLabel.Text = monsterName
    espTextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
    espTextLabel.TextScaled = true
    espTextLabel.TextSize = 16
    espTextLabel.TextStrokeTransparency = 0
    espTextLabel.TextWrapped = true
end


--[[創建實體]]
local alertGUI = Instance.new("ScreenGui", CoreGui) 
local frame = Instance.new("Frame", alertGUI)
local rushMonsterText = Instance.new("TextLabel" , frame)
local seekMovingMonsterText = Instance.new("TextLabel" , frame)
local screechMonsterText = Instance.new("TextLabel" , frame)
local shadeMonsterText = Instance.new("TextLabel" , frame)

-- alertGUI
alertGUI.Name = "alertGUI"

-- frame
frame.Size = UDim2.new(1,0,1,0)
frame.BackgroundTransparency = 1

-- rushMonsterText
rushMonsterText.BackgroundTransparency = 1
rushMonsterText.Position = UDim2.new(0.5,0,0.5,0)
rushMonsterText.TextSize = 70
rushMonsterText.TextScaled = false
rushMonsterText.TextWrapped = false
rushMonsterText.Visible = false
rushMonsterText.Text = "躲櫃子！！！"
rushMonsterText.TextColor3 = Color3.new(255,0,0)
rushMonsterText.TextStrokeTransparency = 0

-- seekMovingMonsterText
seekMovingMonsterText.BackgroundTransparency = 1
seekMovingMonsterText.Position = UDim2.new(0.5,0,0.7,0)
seekMovingMonsterText.TextSize = 70
seekMovingMonsterText.TextScaled = false
seekMovingMonsterText.TextWrapped = false
seekMovingMonsterText.Visible = false
seekMovingMonsterText.Text = "眼睛怪準備追你！！！"
seekMovingMonsterText.TextColor3 = Color3.new(255,0,0)
seekMovingMonsterText.TextStrokeTransparency = 0

-- screechMonsterText
screechMonsterText.BackgroundTransparency = 1
screechMonsterText.Position = UDim2.new(0.5,0,0.7,0)
screechMonsterText.TextSize = 70
screechMonsterText.TextScaled = false
screechMonsterText.TextWrapped = false
screechMonsterText.Visible = false
screechMonsterText.Text = "尖叫怪在你旁邊\n快看他！！"
screechMonsterText.TextColor3 = Color3.new(255,0,0)
screechMonsterText.TextStrokeTransparency = 0

-- shadeMonsterText
shadeMonsterText.BackgroundTransparency = 1
shadeMonsterText.Position = UDim2.new(0.5,0,0.5,0)
shadeMonsterText.TextSize = 70
shadeMonsterText.TextScaled = false
shadeMonsterText.TextWrapped = false
shadeMonsterText.Visible = false
shadeMonsterText.Text = "回頭！！！"
shadeMonsterText.TextColor3 = Color3.new(255,0,0)
shadeMonsterText.TextStrokeTransparency = 0


--[[Connect Function]]
game:GetService("Workspace").ChildAdded:Connect(function(child)
    if child:IsA("Model") and child.Name == "AmbushMoving" or child.Name == "RushMoving" then
        flashText(rushMonsterText)
    elseif child:IsA("Model") and child.Name == "SeekMoving" then
        flashText(seekMovingMonsterText)
        monsterESP(child, "眼睛怪")
    elseif child:IsA("Model") and child.Name == "Lookman" then
        monsterESP(child, "！！不要看！！")
    end
end)

game:GetService("Workspace").ChildRemoved:Connect(function(child)
    if child:IsA("Model") and child.Name == "AmbushMoving" or child.Name == "RushMoving" then
        rushMonsterText.Visible = false
    elseif child:IsA("Model") and child.Name == "SeekMoving" then
        seekMovingMonsterText.Visible = false
    end
end)



CurrentRoomsFolder.ChildAdded:Connect(function(child)
    wait(2.5)
    for _,v in next, child:GetDescendants() do
        -- 粉
        if v.Name == "KeyObtain" then
            createESP(v, "鑰匙")
        elseif v.Name == "Lockpick" then
            createESP(v, "撬鎖器")
        elseif v.Name == "GoldPile" then
            createESP(v, "金幣")
        elseif v.Name == "Lighter" and v:IsA("Model") then
            createESP(v, "打火機")

        -- 黃
        elseif v.Name == "Wardrobe" then
            createESP(v, "櫃子", Color3.fromRGB(255, 255, 0), 200)
        elseif v.Name == "Bed" then
            createESP(v, "床", Color3.fromRGB(255, 255, 0), 200)
        elseif v.Name == "Double_Bed" then
            createESP(v, "雙人床", Color3.fromRGB(255, 255, 0), 200)

        -- 藍
        elseif v.Name == "Lock" then
            createESP(v, "鎖", Color3.fromRGB(0, 255, 255), 200)
        elseif v.Name == "LeverForGate" then
            createESP(v, "閘門拉桿", Color3.fromRGB(0, 255, 255), 200)
        elseif v.Name == "VentGrate" then
            createESP(v, "通風柵", Color3.fromRGB(0, 255, 255), 200)

        -- 綠
        elseif v.Name == "Door" and v:IsA("Model") then
            createESP(v, "門", Color3.fromRGB(0, 255, 0), 200)
        end
    end
end)


for _,v in next, CurrentRoomsFolder:GetDescendants() do
    -- 粉
    if v.Name == "KeyObtain" then
        createESP(v, "鑰匙")
    elseif v.Name == "Lockpick" then
        createESP(v, "撬鎖器")
    elseif v.Name == "GoldPile" then
        createESP(v, "金幣")
    elseif v.Name == "Lighter" and v:IsA("Model") then
        createESP(v, "打火機")

    -- 黃
    elseif v.Name == "Wardrobe" then
        createESP(v, "櫃子", Color3.fromRGB(255, 255, 0), 200)
    elseif v.Name == "Bed" then
        createESP(v, "床", Color3.fromRGB(255, 255, 0), 200)
    elseif v.Name == "Double_Bed" then
        createESP(v, "雙人床", Color3.fromRGB(255, 255, 0), 200)

    -- 藍
    elseif v.Name == "Lock" then
        createESP(v, "鎖", Color3.fromRGB(0, 255, 255), 200)
    elseif v.Name == "LeverForGate" then
        createESP(v, "閘門拉桿", Color3.fromRGB(0, 255, 255), 200)
    elseif v.Name == "VentGrate" then
        createESP(v, "通風柵", Color3.fromRGB(0, 255, 255), 200)
        
    -- 綠
    elseif v.Name == "Door" and v:IsA("Model") then
        createESP(v, "門", Color3.fromRGB(0, 255, 0), 200)
    end
end


-- 自動 Fire ProximityPrompt
spawn(function()
    while wait(1) do
        -- fireproximityprompt(<ProximityPrompt> Prompt, <number> Distance)
        for _,v in next, CurrentRoomsFolder:GetDescendants() do
            if v:IsA("ProximityPrompt") and
            v.Parent.Name ~= "Slot" and
            v.Parent.Name ~= "Wardrobe" and
            v.Parent.Name ~= "Bed" and
            v.Parent.Name ~= "RolltopContainer" and
            v.Parent.Name ~= "Typewriter" and
            v.Parent.Name ~= "Painting_Small" and
            v.Parent.Name ~= "Painting_Big" and
            v.Parent.Name ~= "Painting_VeryBig" and
            v.Parent.Parent.Name ~= "Double_Bed" and
            v.Parent.Parent.Name ~= "DrawerContainer" then
                fireproximityprompt(v, 200)
            end
        end
    end
end)

-- 自動 Fire TouchInterest
spawn(function()
    --firetouchinterest(<Instance> Part, <BasePart> ToTouch, <uint> Toggle)
    while wait(1) do
        for _,v in next, CurrentRoomsFolder:GetDescendants() do
            if v.Name == "TouchInterest" and v.Parent.Parent == "Door" then
                firetouchinterest(localplayerHRP, v.Parent, 0)
                wait(0.01)
                firetouchinterest(localplayerHRP, v.Parent, 1)
            end
        end
    end
end)

-- 點亮
spawn(function()
    loadstring(game:HttpGet("https://pastebin.com/raw/06iG6YkU", true))()
end)


-- 尖叫怪
spawn(function()
    workspace.Camera.ChildAdded:Connect(function(child)
        if child.Name == "Screech" then
            flashText(screechMonsterText)
        end
    end)

    workspace.Camera.ChildRemoved:Connect(function(child)
        if child.Name == "Screech" then
            screechMonsterText.Visible = false
        end
    end)
end)

Players.LocalPlayer.PlayerGui.MainUI["Jumpscare_Shade"].Changed:Connect(function(visible)
	if visible == true then
        shadeMonsterText.Visible = true
    else
        wait(1)
        shadeMonsterText.Visible = false
    end
end)


Players.LocalPlayer.Character.Humanoid:SetAttribute("SpeedBoost", 10)


print("DOORS腳本已載入")

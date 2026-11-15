repeat
	wait()
until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character
	or (game.placeId == 10098525303 and game:IsLoaded())
if game.GameId ~= 1116949753 then
	return
end

getgenv().Settings = {
	ItemESP = false,
	FuseESP = false,
	EnemyESP = false,
	ItemESPDistance = 5000,
	WalkSpeed = 16,
}

--[變數]--[變數]--[變數]--[變數]--[變數]--[變數]--[變數]--

--[服務]：
local players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[簡寫]：
local guiName = "Isle GUI v0.1"
local settingdata = "houkei_gui/Isle.json"
local localplayer = players.LocalPlayer
local PlayerGui = localplayer.PlayerGui
--[空變數]：
local OldSettings
local uuid
local UnitName
local RecordFileName
--[布林值]：
local FirstDiscordAlert = true
--[空陣列]：
local RecordFile = {}

--[變數]--[變數]--[變數]--[變數]--[變數]--[變數]--[變數]--

function CheckData(DataName)
	if OldSettings[DataName] == nil then
		print(DataName .. "值:缺失")
		OldSettings[DataName] = getgenv().Settings[DataName]
		print(DataName .. "值:已補上")
	else
		print(DataName .. "值:存在")
	end
end

print("[檢查「Isle GUI」設定檔完整性...]")

--[檢查資料夾
if isfolder("houkei_gui") then --有houkei資料夾
	print("houkei資料夾:存在")
else
	makefolder("houkei_gui")
end
--檢查資料夾]

if isfile(settingdata) then --有Isle.json
	print("Isle.json:存在")
	--[導入OldSettings
	OldSettings = HttpService:JSONDecode(readfile(settingdata))
	--導入OldSettings]
	--[檢查Isle.json完整性

	CheckData("ItemESP")

	CheckData("FuseESP")

	CheckData("EnemyESP")

	CheckData("ItemESPDistance")

	CheckData("WalkSpeed")

	--檢查Isle.json完整性]
	--[導入OldSettings到getgenv().Settings
	getgenv().Settings = OldSettings
	print("設定檔導入成功！")
	print("[檢查「盜版全明星塔防GUI」設定檔完整性:完成]")
	--導入OldSettings到getgenv().Settings]
else
	writefile(settingdata, HttpService:JSONEncode(getgenv().Settings))
end

--[檢查完檔案後才能跑 GUI library
local library =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Library/BjzGui.lua"))()
--檢查完檔案後才能跑 GUI library]

--------------------------------------[函數

function ItemESP()
	local ItemFolder = workspace.Map.Ignore.Tools

	local camera = workspace.CurrentCamera

	local ItemHeadOff = Vector3.new(0, 0.5, 0)
	local ItemLegOff = Vector3.new(0, 1, 0)
	local ItemBoxDown = Vector3.new(0, 3, 0)

	function getDistance(part)
		return (part.Position - camera.CFrame.Position).Magnitude
	end

	function esp(Item)
		local ItemHandle = Item:WaitForChild("Handle")
		local ItemNameText = Drawing.new("Text")
		ItemNameText.Visible = false
		ItemNameText.Center = true
		ItemNameText.Outline = true
		ItemNameText.Color = Color3.fromRGB(255, 255, 255)
		ItemNameText.Font = 3
		ItemNameText.Size = 20
		ItemNameText.ZIndex = 0
		ItemNameText.Transparency = 0.7

		local Box = Drawing.new("Square")
		Box.Visible = false
		Box.Color = Color3.fromRGB(255, 255, 255)
		Box.Thickness = 1
		Box.Transparency = 1
		Box.Filled = false

		local renderstepped
		renderstepped = game:GetService("RunService").RenderStepped:Connect(function()
			if Item:FindFirstChild("Handle") and getgenv().Settings.ItemESP == true then
				local ItemPos, ItemOnscreen = camera:WorldToViewportPoint(ItemHandle.Position - ItemBoxDown)

				local TorsoPosition = camera:WorldToViewportPoint(ItemHandle.Position)
				local HeadPosition = camera:WorldToViewportPoint(ItemHandle.Position + ItemHeadOff)
				local LegPosition = camera:WorldToViewportPoint(ItemHandle.Position - ItemLegOff)

				if ItemOnscreen and getDistance(ItemHandle) < getgenv().Settings.ItemESPDistance then
					ItemNameText.Position = Vector2.new(ItemPos.X, ItemPos.Y)
					ItemNameText.Visible = true
					ItemNameText.Text = string.gsub(Item.Name, "%p%d+", "")
						.. "["
						.. math.floor(getDistance(ItemHandle))
						.. "]"

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

	for i, Item in next, ItemFolder:GetChildren() do
		local ItemHandle = Item:WaitForChild("Handle")
		if Item ~= nil and ItemHandle ~= nil and getgenv().Settings.ItemESP == true then
			esp(Item)
		end
	end

	ItemFolder.ChildAdded:Connect(function(AddedChild)
		if getgenv().Settings.ItemESP == true then
			esp(AddedChild)
		end
	end)
end

function FuseESP(Item)
	local FuseFolder = game:GetService("Workspace").Map.Main

	local camera = workspace.CurrentCamera

	local ItemHeadOff = Vector3.new(0, 0.5, 0)
	local ItemLegOff = Vector3.new(0, 1, 0)
	local ItemBoxDown = Vector3.new(0, 3, 0)

	function getDistance(part)
		return (part.Position - camera.CFrame.Position).Magnitude
	end

	function esp(Item)
		local FuseTube = Item:WaitForChild("Tube")

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
			if Item:FindFirstChild("Tube") and getgenv().Settings.FuseESP == true then
				local ItemPos, ItemOnscreen = camera:WorldToViewportPoint(FuseTube.Position - ItemBoxDown)

				local TorsoPosition = camera:WorldToViewportPoint(FuseTube.Position)
				local HeadPosition = camera:WorldToViewportPoint(FuseTube.Position + ItemHeadOff)
				local LegPosition = camera:WorldToViewportPoint(FuseTube.Position - ItemLegOff)

				if ItemOnscreen and getDistance(FuseTube) < getgenv().Settings.ItemESPDistance then
					ItemNameText.Position = Vector2.new(ItemPos.X, ItemPos.Y)
					ItemNameText.Visible = true
					ItemNameText.Text = Item.Name .. "[" .. math.floor(getDistance(FuseTube)) .. "]"

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

	for i, Fuse in next, FuseFolder:GetChildren() do
		if (Fuse:IsA("Model") and Fuse.Name == "Fuse") or (Fuse:IsA("Model") and Fuse.Name == "PeanutBox") then
			--local FuseHandle = Fuse:WaitForChild("Tube")
			if getgenv().Settings.FuseESP == true then
				esp(Fuse)
			end
		end
	end

	FuseFolder.ChildAdded:Connect(function(AddedChild)
		if getgenv().Settings.FuseESP == true and AddedChild.Name == "Fuse" then
			esp(AddedChild)
		end
	end)
end

function EnemyESP()
	local AIFolder = game:GetService("Workspace").AIHunter
	local agentPath

	local camera = workspace.CurrentCamera
	local players = game:GetService("Players")
	local localplayerhumanoid = players.LocalPlayer.Character.Humanoid

	local HeadOff = Vector3.new(0, 0.5, 0)
	local LegOff = Vector3.new(0, 3.5, 0)
	local BoxDown = Vector3.new(0, 5, 0)

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
		Line.To = Vector2.new(0, 0)
		Line.Color = Color3.fromRGB(255, 0, 0)
		Line.Thickness = 0.1
		Line.Transparency = 0.3

		local healthText = Drawing.new("Text")
		healthText.Visible = false
		healthText.Center = true
		healthText.Outline = true
		healthText.Font = 3
		healthText.Color = Color3.fromRGB(255, 255, 255)
		healthText.Size = 15

		local Box = Drawing.new("Square")
		Box.Visible = false
		Box.Color = Color3.fromRGB(255, 255, 255)
		Box.Thickness = 1
		Box.Transparency = 1
		Box.Filled = false

		local HealthBar = Drawing.new("Square")
		HealthBar.Visible = false
		HealthBar.Color = Color3.new(0, 1, 0)
		HealthBar.Thickness = 1
		HealthBar.Transparency = 1
		HealthBar.Filled = false

		local renderstepped
		renderstepped = game:GetService("RunService").RenderStepped:Connect(function()
			if
				Enemy:IsA("Model")
				and EnemyHumanoid ~= nil
				and EnemyHumanoid.Health > 0
				and localplayerhumanoid.Health > 0
				and getgenv().Settings.EnemyESP == true
			then
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
					healthText.Text = "["
						.. math.floor(UpdateHealth(EnemyHumanoid))
						.. "/"
						.. math.floor(EnemyHumanoid.MaxHealth)
						.. "]"
						.. "["
						.. math.floor(getDistance(EnemyHRP))
						.. "]"
					--Text]

					Box.Size = Vector2.new(1500 / TorsoPosition.Z, HeadPosition.Y - LegPosition.Y)
					Box.Position = Vector2.new(TorsoPosition.X - Box.Size.X / 2, TorsoPosition.Y - Box.Size.Y / 2)
					Box.Visible = true

					HealthBar.Size = Vector2.new(
						2,
						(HeadPosition.Y - LegPosition.Y)
							/ (EnemyHumanoid.MaxHealth / math.clamp(EnemyHumanoid.Health, 0, EnemyHumanoid.MaxHealth))
					)
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

	function agentESP(Enemy)
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
		Line.To = Vector2.new(0, 0)
		Line.Color = Color3.fromRGB(255, 0, 0)
		Line.Thickness = 0.1
		Line.Transparency = 0.3

		local healthText = Drawing.new("Text")
		healthText.Visible = false
		healthText.Center = true
		healthText.Outline = true
		healthText.Font = 3
		healthText.Color = Color3.fromRGB(255, 255, 255)
		healthText.Size = 15

		local Box = Drawing.new("Square")
		Box.Visible = false
		Box.Color = Color3.fromRGB(255, 255, 255)
		Box.Thickness = 1
		Box.Transparency = 1
		Box.Filled = false

		local HealthBar = Drawing.new("Square")
		HealthBar.Visible = false
		HealthBar.Color = Color3.new(0, 1, 0)
		HealthBar.Thickness = 1
		HealthBar.Transparency = 1
		HealthBar.Filled = false

		local renderstepped
		renderstepped = game:GetService("RunService").RenderStepped:Connect(function()
			if
				Enemy:IsA("Model")
				and EnemyHumanoid ~= nil
				and EnemyHumanoid.Health > 0
				and localplayerhumanoid.Health > 0
				and getgenv().Settings.EnemyESP == true
			then
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
					healthText.Text = "["
						.. math.floor(UpdateHealth(EnemyHumanoid))
						.. "/"
						.. math.floor(EnemyHumanoid.MaxHealth)
						.. "]"
						.. "["
						.. math.floor(getDistance(EnemyHRP))
						.. "]"
					--Text]

					Box.Size = Vector2.new(1500 / TorsoPosition.Z, HeadPosition.Y - LegPosition.Y)
					Box.Position = Vector2.new(TorsoPosition.X - Box.Size.X / 2, TorsoPosition.Y - Box.Size.Y / 2)
					Box.Visible = true

					HealthBar.Size = Vector2.new(
						2,
						(HeadPosition.Y - LegPosition.Y)
							/ (EnemyHumanoid.MaxHealth / math.clamp(EnemyHumanoid.Health, 0, EnemyHumanoid.MaxHealth))
					)
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

	for i, Enemy in next, AIFolder:GetChildren() do
		local EnemyHumanoid
		local EnemyHRP
		if
			Enemy:IsA("Model")
			and Enemy.Name ~= "Dummy1"
			and Enemy.Name ~= "Dummy2"
			and Enemy.Name ~= "Dummy3"
			and Enemy.Name ~= "Helicopter"
		then
			EnemyHumanoid = Enemy:WaitForChild("Humanoid")
			EnemyHRP = Enemy:WaitForChild("HumanoidRootPart")
		end
		if
			Enemy:IsA("Model")
			and EnemyHumanoid ~= nil
			and EnemyHumanoid.Health > 0
			and EnemyHRP ~= nil
			and getgenv().Settings.EnemyESP == true
		then
			esp(Enemy)
		end
	end

	AIFolder.ChildAdded:Connect(function(AddedChild)
		if
			AddedChild.Name ~= "Dummy1"
			and AddedChild.Name ~= "Dummy2"
			and AddedChild.Name ~= "Dummy3"
			and getgenv().Settings.EnemyESP == true
		then
			esp(AddedChild)
		end
	end)

	spawn(function()
		repeat
			game:GetService("Workspace").Threats:WaitForChild("Agent B6")
		until game:GetService("Workspace").Threats:FindFirstChild("Agent B6")
		agentPath = game:GetService("Workspace").Threats:FindFirstChild("Agent B6")

		--ExecuteAgentESP

		for i, Enemy in next, agentPath:GetChildren() do
			local EnemyHumanoid
			local EnemyHRP
			if Enemy:IsA("Model") and Enemy.Name ~= "Helicopter" then
				EnemyHumanoid = Enemy:WaitForChild("Humanoid")
				EnemyHRP = Enemy:WaitForChild("HumanoidRootPart")
			end
			if
				Enemy:IsA("Model")
				and EnemyHumanoid ~= nil
				and EnemyHumanoid.Health > 0
				and EnemyHRP ~= nil
				and getgenv().Settings.EnemyESP == true
			then
				agentESP(Enemy)
			end
		end

		agentPath.Parent.ChildAdded:Connect(function(AddedChild)
			if getgenv().Settings.EnemyESP == true then
				agentESP(AddedChild)
			end
		end)
	end)
end

function antiAFK()
	repeat
		wait()
	until game:IsLoaded()
	spawn(function()
		while wait(60) do
			game:GetService("VirtualUser"):ClickButton2(Vector2.new())
		end
	end)
	print("反AFK測試腳本已載入")
end

function WalkSpeed()
	if not getgenv().MTAPIMutex then
		loadstring(
			game:HttpGet("https://raw.githubusercontent.com/KikoTheDon/MT-Api-v2/main/__source/mt-api%20v2.lua", true)
		)()
	end
	local players = game:GetService("Players")
	local humanoid = players.LocalPlayer.Character.Humanoid
	humanoid:AddPropertyEmulator("WalkSpeed")

	humanoid.WalkSpeed = getgenv().Settings.WalkSpeed
end

--------------------------------------函數]

local Main = library:MainFrame(guiName)

local ESPTab = Main:Tab("透視")

local CilentTab = Main:Tab("客戶端")

local OtherTab = Main:Tab("其他")

Main:ZoomWindow(function(bool)
	getgenv().Settings.ZoomWindow = bool
	writefile(settingdata, HttpService:JSONEncode(getgenv().Settings))
end):Set(getgenv().Settings.ZoomWindow)

ESPTab:Toggle("物品透視", function(bool)
	getgenv().Settings.ItemESP = bool
	writefile(settingdata, HttpService:JSONEncode(getgenv().Settings))
	if getgenv().Settings.ItemESP then
		spawn(ItemESP)
	end
end):Set(getgenv().Settings.ItemESP)

ESPTab:Toggle("保險絲透視", function(bool)
	getgenv().Settings.FuseESP = bool
	writefile(settingdata, HttpService:JSONEncode(getgenv().Settings))
	if getgenv().Settings.FuseESP then
		spawn(FuseESP)
	end
end):Set(getgenv().Settings.FuseESP)

ESPTab:Slider("物品透視距離", 1, 5000, function(arg)
	getgenv().Settings.ItemESPDistance = arg
	writefile(settingdata, HttpService:JSONEncode(getgenv().Settings))
end):Set(getgenv().Settings.ItemESPDistance)

ESPTab:Toggle("敵人透視", function(bool)
	getgenv().Settings.EnemyESP = bool
	writefile(settingdata, HttpService:JSONEncode(getgenv().Settings))
	if getgenv().Settings.EnemyESP then
		spawn(EnemyESP)
	end
end):Set(getgenv().Settings.EnemyESP)

--[[---------------------------------]]
ESPTab:Line()--[[---------------------------------]]
ESPTab:Button("Unnamed 透視", function()
	--透視
	loadstring(game:HttpGet("https://raw.githubusercontent.com/ic3w0lf22/Unnamed-ESP/master/UnnamedESP.lua"))()
end)

----

CilentTab:Slider("跑速", 1, 250, function(arg)
	getgenv().Settings.WalkSpeed = arg
	writefile(settingdata, HttpService:JSONEncode(getgenv().Settings))
	WalkSpeed()
end):Set(getgenv().Settings.WalkSpeed)

OtherTab:Button("其他GUI", function()
	loadstring(
		game:HttpGet(
			"https://gist.githubusercontent.com/w-a-e/cf38dd10d3ab3b5171f37841b380466a/raw/3c38a06dfc28e8537d309476037660537378dfbe/gistfile1.txt"
		)
	)()
end)

-- ---------------------------------------------------------------------------------------------

-- lobbyTab:Tag("傳送")

-- lobbyTab:ToggleDropdown("傳送關卡",levelListCN,
-- function(SelectedLevel)
--     getgenv().Settings.SelectedLevel = SelectedLevel
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
--     if getgenv().Settings.TPLevel then
--         spawn(TPLevel)
--     end
-- end,
-- function(bool)
--     getgenv().Settings.TPLevel = bool
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
--     if getgenv().Settings.TPLevel then
--         spawn(TPLevel)
--     end
-- end):Set(getgenv().Settings.SelectedLevel,getgenv().Settings.TPLevel)

-- performanceTab:Tag("降低CPU使用率")

-- performanceTab:Toggle("關閉3D渲染",function(bool)
--     getgenv().Settings.WindowFocus = bool
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
--     if getgenv().Settings.WindowFocus then
--         -- local RENDER = true
--         -- local UserInputService = game:GetService("UserInputService")
--         local RunService = game:GetService("RunService")
--         RunService:Set3dRenderingEnabled(false)
--     else
--         local RunService = game:GetService("RunService")
--         RunService:Set3dRenderingEnabled(true)
--         -- WindowFocused = UserInputService.WindowFocused:Connect(function()
--         --     if RENDER then
--         --         RunService:Set3dRenderingEnabled(true)
--         --     end
--         -- end)

--         -- WindowFocusReleased = UserInputService.WindowFocusReleased:Connect(function()
--         --     if RENDER then
--         --         RunService:Set3dRenderingEnabled(false)
--         --     end
--         -- end)
--     end
-- end):Set(getgenv().Settings.WindowFocus)

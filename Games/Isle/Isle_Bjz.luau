--[[
    Isle / BjzUi 介面版 4.0
    相容本次指定的 BjzUiLibrary_2.0.lua（內部版本 2.1.x）。
    請放入 Delta workspace/ 或 workspace/BjzUi/；優先本機，失敗才使用 GitHub。
    本版直接使用 CreateWindow → CreateTab → CreateSection，不加入舊名稱轉接入口。
    .luau／3.x 的 b 前綴 API 為另一版，載入錯版時會明確指出原因。

    導覽：透視、物品、玩家、傳送、介面設定；地點／玩家傳送使用原生子分頁。
    物品、地點與玩家使用可搜尋下拉欄，選取後再按操作按鈕。
    視窗支援八方向縮放、響應式佈局與可拖曳最小化按鈕；RightShift 顯示／隱藏。
    介面設定：workspace/BjzUi/UiConfig.json，ConfigId 依遊戲與玩家分組。
    功能開關、拾取及傳送不由設定檔自動執行；原本不可用的拾取上限開關仍停用。
    關閉或重跑會清理事件、計時器、透視與指引線，並還原本次變動的角色參數。
    已使用實際 Library 執行模擬測試；尚未在 Delta / Isle 實機驗證。
]]
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local W = workspace
local Me = Players.LocalPlayer
if not Me then
	return warn("請進入遊戲後再執行。")
end

--[[
    只載入指定 .lua 檔的 BjzUi 2.1.x；來源依序為本機及 GitHub 網址。
    本機舊版或損壞檔案不會阻擋後續來源；全部失敗時，錯誤會列出來源與原因。
    載入模組不建立視窗，且不提供舊 API 別名。
    @return 已驗證版本與 CreateWindow 的 Library。
    @return 實際載入的原始碼，供呼叫端辨識載入內容。

    使用範例：
    ```lua
    local Library = _LoadBjzUi()
    local Window = Library:CreateWindow({ Name = "控制中心", Resizable = true })
    Window:Destroy()
    ```
]]
local function _LoadBjzUi()
	local Env = (type(getgenv) == "function" and getgenv()) or _G
	local ReadFile = type(Env.readfile) == "function" and Env.readfile or readfile
	local Compile = type(Env.loadstring) == "function" and Env.loadstring or loadstring
	local Errors = {}
	assert(type(Compile) == "function", "目前執行環境沒有 loadstring，無法載入 BjzUi。")

	--[[
        編譯並初始化一份來源，驗證成功後才將其交給呼叫端。
        @param Source UI 原始碼；空白或非字串會略過。
        @param Origin 顯示在編譯錯誤與版本錯誤中的來源名稱。
        @return 通過 2.1.x API 檢查的模組；nil 表示來源不可用。
        @return 通過檢查的原始碼；失敗時不提供。
    ]]
	local function _TrySource(Source, Origin: string)
		if type(Source) ~= "string" or not Source:find("%S") then
			return nil, nil
		end
		local Chunk, CompileError = Compile(Source, "@" .. Origin)
		if not Chunk then
			Errors[#Errors + 1] = Origin .. "：" .. tostring(CompileError)
			return nil, nil
		end
		local bLoaded, Library = pcall(Chunk)
		if not bLoaded then
			Errors[#Errors + 1] = Origin .. "：" .. tostring(Library)
			return nil, nil
		end
		if
			type(Library) ~= "table"
			or type(Library.CreateWindow) ~= "function"
			or type(Library.Version) ~= "string"
			or not Library.Version:match("^2%.1%.")
		then
			local Version = type(Library) == "table" and tostring(Library.Version) or "未知"
			Errors[#Errors + 1] = Origin .. "：版本 " .. Version .. "，需要 BjzUi 2.1.x API。"
			return nil, nil
		end
		return Library, Source
	end

	if type(ReadFile) == "function" then
		for _, Path in ipairs({ "BjzUiLibrary_2.0.lua", "BjzUi/BjzUiLibrary_2.0.lua" }) do
			local bRead, Source = pcall(ReadFile, Path)
			if bRead then
				local Library, AcceptedSource = _TrySource(Source, Path)
				if Library then
					return Library, AcceptedSource
				end
			end
		end
	end
	--[[
        本機來源不可用時嘗試同專案的 GitHub 檔案；回傳內容仍須通過版本檢查。
        @return GitHub 回傳的 UI 原始碼。
    ]]
	local bFetched, RemoteSource = pcall(function()
		return game:HttpGet(
			"https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Library/BjzUiLibrary_2.0.luau"
		)
	end)
	if bFetched then
		local Library, AcceptedSource = _TrySource(RemoteSource, "BjzUiLibrary_2.0.lua (GitHub)")
		if Library then
			return Library, AcceptedSource
		end
	else
		Errors[#Errors + 1] = "GitHub：" .. tostring(RemoteSource)
	end
	error(
		"無法載入 BjzUi 2.1.x。請將最新版 BjzUiLibrary_2.0.lua 放入 Delta workspace/ 或 workspace/BjzUi/。\n"
			.. table.concat(Errors, "\n"),
		0
	)
end

local BjzUi = loadstring(game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Library/BjzUiLibrary_2.0.luau"))()
local CEspEngine = loadstring(game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/EspEngine.luau"))()
assert(type(CEspEngine) == "table" and type(CEspEngine.new) == "function", "ESP 引擎載入失敗。")
local Window = BjzUi:CreateWindow({
	Name = "ISLE",
	LoadingSubtitle = "透視 · 物品 · 玩家 · 傳送",
	ConfigId = "Isle_" .. tostring(game.GameId) .. "_" .. tostring(Me.UserId),
	ConfigurationSaving = { Enabled = true },
	ToggleKey = Enum.KeyCode.RightShift,
	Width = 1000,
	Height = 700,
	MinWidth = 360,
	MinHeight = 300,
	Resizable = true,
	DisplayOrder = 999,
})
local Gui = Window.ScreenGui
local Theme = Window.Theme
Window.Mini.Text = "IS"
Window.Main.ZIndex = 10
-- 卸載同一份原始獨立介面時，也讓其原本的 Destroying 清理處理舊效果。
for _, Parent in ipairs({ Gui.Parent, game:GetService("CoreGui"), Me:FindFirstChild("PlayerGui") }) do
	for _, Object in ipairs(Parent:GetChildren()) do
		if Object:IsA("ScreenGui") and Object.Name == "IslandESP_Delta" and Object:FindFirstChild("MainPanel") then
			Object:Destroy()
		end
	end
end

local Config = {
	RefreshInterval = 0.6,
	MaxMarkers = 160,
	PickupTimeout = 10,
	FuseNames = {
		fuse = true,
		electricfuse = true,
		electricalfuse = true,
		powerfuse = true,
		["保險絲"] = true,
	},
	EnemyRoots = { "Monster", "Bots", "AIHunter", "Threats" },
}
local Groups = {
	Fuse = { Title = "保險絲透視", Color = Color3.fromRGB(255, 202, 80), Enabled = false },
	Enemy = { Title = "敵人透視", Color = Color3.fromRGB(255, 100, 115), Enabled = false },
	Player = { Title = "玩家透視", Color = Color3.fromRGB(100, 185, 255), Enabled = false },
	Item = { Title = "物品透視", Color = Color3.fromRGB(100, 235, 175), Enabled = false },
}
local Order = { "Fuse", "Enemy", "Player", "Item" }
local Priority = { Player = 1, Enemy = 2, Fuse = 3, Item = 4 }
local Alive, Dirty = true, true
local Connections, Candidates = {}, {}
local ActivePage, ShowLabels, ShowTracers, MaxDistance = "ESP", true, false, math.huge
local CurrentPickup
local TeleportBusy = false
local RefreshItems, RefreshPlayers, UpdatePlayerReadout
local SpeedDesired, SpeedConnection, SpeedHumanoid
local SpeedLocked, ApplyingSpeed = true, false
local Originals = setmetatable({}, { __mode = "k" })
local NoclipEnabled = false
local NoclipCharacter, NoclipAddedConnection
local CollisionOriginals = setmetatable({}, { __mode = "k" })

local function New(class, props, parent)
	local object = Instance.new(class)
	for key, value in pairs(props or {}) do
		object[key] = value
	end
	object.Parent = parent
	return object
end
local function Connect(signal, callback)
	local connection = signal:Connect(function(...)
		if Alive then
			callback(...)
		end
	end)
	table.insert(Connections, connection)
	return connection
end
local function Label(parent, text, position, size, textSize, color)
	return New("TextLabel", {
		BackgroundTransparency = 1,
		Position = position,
		Size = size,
		Text = text,
		TextColor3 = color or Theme.Text,
		TextSize = textSize or 14,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Left,
	}, parent)
end
local function GetHumanoid()
	local character = Me.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end
local function SaveOriginal(humanoid)
	if not Originals[humanoid] then
		Originals[humanoid] = {
			WalkSpeed = humanoid.WalkSpeed,
			JumpHeight = humanoid.JumpHeight,
			JumpPower = humanoid.JumpPower,
			UseJumpPower = humanoid.UseJumpPower,
		}
	end
end
local function RestoreOriginal(humanoid)
	local original = Originals[humanoid]
	if original and humanoid.Parent then
		pcall(function()
			humanoid.WalkSpeed = original.WalkSpeed
			humanoid.JumpHeight = original.JumpHeight
			humanoid.JumpPower = original.JumpPower
			humanoid.UseJumpPower = original.UseJumpPower
		end)
	end
	Originals[humanoid] = nil
end
local function Anchor(object)
	if object:IsA("BasePart") then
		return object
	end
	if object:IsA("Model") and object.PrimaryPart then
		return object.PrimaryPart
	end
	local part = object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Handle")
	if part and part:IsA("BasePart") then
		return part
	end
	return object:FindFirstChildWhichIsA("BasePart", true)
end
local function CleanName(object)
	return (object.Name:gsub("#%d+$", ""))
end
local function IsFuse(object)
	local name = object.Name:lower():gsub("#%d+$", ""):gsub("[%s_%-]", "")
	return Config.FuseNames[name] == true
end
local function IgnoreFolder()
	local map = W:FindFirstChild("Map")
	return map and map:FindFirstChild("Ignore")
end
local function GroundTools()
	local ignore = IgnoreFolder()
	return ignore and ignore:FindFirstChild("Tools")
end
local function DistanceFromMe(part)
	local character = Me.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return root and (part.Position - root.Position).Magnitude or nil
end

-- 控制項以外的延遲工作由腳本擁有；卸載時一起取消。
local Tasks, Status, NoticeTask = {}, nil, nil
local function _CancelTask(Thread)
	if not Thread then
		return
	end
	Tasks[Thread] = nil
	if Thread ~= coroutine.running() then
		pcall(task.cancel, Thread)
	end
end
--[[
    排程可取消的工作；回呼開始、yield 及完成期間皆受卸載清理管理。
    @param Seconds 等待秒數；0 表示讓出目前事件後執行。
    @param Callback 視窗仍存活時執行的無參數工作。
    @return 可取消的排程執行緒。
]]
local function _Later(Seconds, Callback)
	local Thread
	Thread = task.delay(Seconds, function()
		if Alive then
			local bOk, Reason = pcall(Callback)
			if not bOk then
				warn("[Isle] " .. tostring(Reason))
			end
		end
		Tasks[Thread] = nil
	end)
	Tasks[Thread] = true
	return Thread
end
--[[
    此視窗專用的共用 ESP 實例；分類由 Isle 提供，視覺物件由引擎持有。
    關閉視窗時由 Cleanup 卸載，RenderStepped 與 Heartbeat 由現有連線管理。
]]
local EspEngine = CEspEngine.new(Window.Surface, W)
local function Notify(Message)
	if not Alive then
		return
	end
	_CancelTask(NoticeTask)
	if Status then
		Status:Set("目前狀態", tostring(Message))
	end
	NoticeTask = _Later(6, function()
		if Status then
			Status:Set("目前狀態", "準備完成")
		end
	end)
end
-- Noclip: preserve each part's original CanCollide, including false values.
local function RestoreNoclip()
	if NoclipAddedConnection then
		NoclipAddedConnection:Disconnect()
		NoclipAddedConnection = nil
	end
	NoclipCharacter = nil
	for part, original in pairs(CollisionOriginals) do
		if part.Parent then
			pcall(function()
				part.CanCollide = original
			end)
		end
		CollisionOriginals[part] = nil
	end
end
local function DisablePartCollision(part)
	if not part:IsA("BasePart") then
		return
	end
	if CollisionOriginals[part] == nil then
		CollisionOriginals[part] = part.CanCollide
	end
	part.CanCollide = false
end
local function UpdateNoclip()
	if not Alive or not NoclipEnabled then
		return
	end
	local character = Me.Character
	if character ~= NoclipCharacter then
		RestoreNoclip()
		NoclipCharacter = character
		if character then
			NoclipAddedConnection = character.DescendantAdded:Connect(function(part)
				if Alive and NoclipEnabled and Me.Character == character then
					DisablePartCollision(part)
				end
			end)
			for _, part in ipairs(character:GetDescendants()) do
				DisablePartCollision(part)
			end
		end
	end
	for part, original in pairs(CollisionOriginals) do
		if character and part:IsDescendantOf(character) then
			if part.CanCollide then
				part.CanCollide = false
			end
		else
			if part.Parent then
				pcall(function()
					part.CanCollide = original
				end)
			end
			CollisionOriginals[part] = nil
		end
	end
end

-- Speed lock: property-change listener plus a throttled fallback; no remote spoofing.
local function EnforceSpeed()
	local humanoid = SpeedHumanoid
	if
		not Alive
		or not SpeedLocked
		or SpeedDesired == nil
		or ApplyingSpeed
		or not humanoid
		or not humanoid.Parent
		or humanoid.Health <= 0
	then
		return
	end
	if humanoid.WalkSpeed == SpeedDesired then
		return
	end
	ApplyingSpeed = true
	local ok, err = pcall(function()
		SaveOriginal(humanoid)
		humanoid.WalkSpeed = SpeedDesired
	end)
	ApplyingSpeed = false
	if not ok then
		warn("[Island Speed] " .. tostring(err))
	end
end
local function BindSpeed()
	local humanoid = GetHumanoid()
	if humanoid ~= SpeedHumanoid then
		if SpeedConnection then
			SpeedConnection:Disconnect()
			SpeedConnection = nil
		end
		SpeedHumanoid = humanoid
		if humanoid then
			SpeedConnection = humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(EnforceSpeed)
		end
	end
	EnforceSpeed()
end

-- Idempotent return used by success, failure, timeout and GUI unload.
local function ReturnPickup(transaction)
	if not transaction.Moved or transaction.Returned then
		return true
	end
	if Me.Character ~= transaction.Character or not transaction.Root.Parent then
		return false
	end
	local humanoid = transaction.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.SeatPart then
		return false
	end
	local ok = pcall(function()
		transaction.Character:PivotTo(transaction.Origin)
		transaction.Root.AssemblyLinearVelocity = Vector3.zero
		transaction.Root.AssemblyAngularVelocity = Vector3.zero
	end)
	if ok then
		transaction.Returned = true
	end
	return ok
end
local function CancelPickup()
	local transaction = CurrentPickup
	if not transaction then
		return
	end
	CurrentPickup = nil
	_CancelTask(transaction.Timeout)
	ReturnPickup(transaction)
	if transaction.Thread and coroutine.status(transaction.Thread) ~= "dead" then
		_CancelTask(transaction.Thread)
	end
end

local function _RequestItem(object)
	if CurrentPickup then
		return Notify("已有拾取請求處理中。")
	end
	if TeleportBusy then
		return Notify("請等待地點傳送完成。")
	end
	local folder = GroundTools()
	if not folder or object.Parent ~= folder then
		return Notify("物品已被拾取或移除。")
	end
	local character = Me.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = GetHumanoid()
	local part = Anchor(object)
	if not root or not humanoid or humanoid.Health <= 0 then
		return Notify("角色尚未準備好。")
	end
	if humanoid.SeatPart then
		return Notify("請先離開座位。")
	end
	if not part then
		return Notify("無法取得物品位置。")
	end
	local services = W:FindFirstChild("Services")
	local remote = services and services:FindFirstChild("PickupTool")
	if not remote or not remote:IsA("RemoteFunction") then
		return Notify("找不到 PickupTool 介面。")
	end
	local transaction =
		{ Character = character, Root = root, Origin = character:GetPivot(), Moved = false, Returned = false }
	CurrentPickup = transaction
	local name, objectName = CleanName(object), object.Name
	local function Finish(message)
		if not Alive or CurrentPickup ~= transaction then
			return
		end
		local returned = ReturnPickup(transaction)
		CurrentPickup = nil
		_CancelTask(transaction.Timeout)
		if not returned then
			message = message .. "；角色狀態改變，未能返回。"
		elseif transaction.Moved then
			message = message .. "；已在本機返回原位。"
		end
		Notify(message)
		if ActivePage == "Item" then
			RefreshItems()
		end
	end
	transaction.Timeout = _Later(Config.PickupTimeout, function()
		if Alive and CurrentPickup == transaction then
			if transaction.Thread and coroutine.status(transaction.Thread) ~= "dead" then
				_CancelTask(transaction.Thread)
			end
			Finish("拾取逾時，結果未知，請檢查背包")
		end
	end)
	transaction.Thread = _Later(0, function()
		local ok, result = pcall(function()
			if (root.Position - part.Position).Magnitude > 6 then
				Notify("正在前往：" .. name)
				transaction.Moved = true
				character:PivotTo(CFrame.new(part.Position + Vector3.new(3, 2, 0)))
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero
				task.wait(0.5)
			end
			if not Alive or CurrentPickup ~= transaction then
				return
			end
			if Me.Character ~= character or not root.Parent or humanoid.Health <= 0 then
				return "角色已變更，取消拾取"
			end
			if object.Parent ~= folder or not part.Parent then
				return "物品已被拾取或移除"
			end
			if (root.Position - part.Position).Magnitude > 6 then
				return "未能接近物品，位置可能被伺服器還原"
			end
			Notify("正在取得：" .. name)
			return remote:InvokeServer("#*@" .. Me.UserId .. game.GameId, objectName)
		end)
		if not Alive or CurrentPickup ~= transaction then
			return
		end
		if not ok then
			warn("[Island Item] " .. tostring(result))
			Finish("取得發生錯誤")
		elseif type(result) == "string" then
			Finish(result)
		elseif result then
			Finish("伺服器回報拾取成功：" .. name)
		else
			Finish("伺服器未確認取得，請檢查背包與拾取條件")
		end
	end)
end
local Tabs = {
	ESP = Window:CreateTab("透視", "eye"),
	Item = Window:CreateTab("物品", "file"),
	Player = Window:CreateTab("玩家", "settings"),
	TP = Window:CreateTab("傳送", "crosshair", { "地點", "玩家" }),
}
local StatusSection = Tabs.ESP:CreateSection({ Name = "執行狀態", Side = "full" })
Status = StatusSection:CreateParagraph({ Title = "目前狀態", Content = "準備完成" })
local GroupSection = Tabs.ESP:CreateSection({ Name = "分類標記", Side = "left" })
for _, Key in ipairs(Order) do
	local Group = Groups[Key]
	GroupSection:CreateToggle({
		Name = Group.Title,
		CurrentValue = false,
		Save = false,
		Flag = "isle_esp_" .. Key,
		Callback = function(bEnabled)
			Group.Enabled = bEnabled
			Dirty = true
		end,
	})
	Group.Counter = GroupSection:CreateLabel({ Name = "已辨識 0 個" })
end
local DisplaySection = Tabs.ESP:CreateSection({ Name = "顯示方式", Side = "right" })
DisplaySection:CreateToggle({
	Name = "名稱／距離",
	CurrentValue = true,
	Save = false,
	Flag = "isle_labels",
	Callback = function(bEnabled)
		ShowLabels = bEnabled
		Dirty = true
	end,
})
DisplaySection:CreateToggle({
	Name = "方向指引線",
	CurrentValue = false,
	Save = false,
	Flag = "isle_tracers",
	Callback = function(bEnabled)
		ShowTracers = bEnabled
		EspEngine:SetTracersEnabled(bEnabled)
	end,
})
DisplaySection:CreateSlider({
	Name = "顯示範圍",
	Description = "0 代表不限距離",
	Range = { 0, 5000 },
	Increment = 25,
	CurrentValue = 0,
	Suffix = " studs",
	Save = false,
	Flag = "isle_distance",
	Callback = function(Value)
		MaxDistance = Value == 0 and math.huge or Value
		Dirty = true
	end,
})
DisplaySection:CreateParagraph({
	Title = "方向指引",
	Content = "指引線從畫面下方連至目標；畫面外目標顯示邊緣箭頭。",
})

local ItemSection = Tabs.Item:CreateSection({ Name = "地面物品", Side = "full" })
ItemSection:CreateParagraph({
	Title = "取得物品",
	Content = "先在下拉欄選擇物品，再按「取得選取物品」；完成請求後返回原位。",
})
ItemSection:CreateToggle({
	Name = "無視拾取數量限制（不可用）",
	CurrentValue = false,
	Enabled = false,
	Save = false,
	Description = "目前不可用：尚未找到可解除上限的介面",
	Flag = "isle_capacity",
})
local ItemInfo = ItemSection:CreateLabel({ Name = "正在讀取地面物品…" })
local ItemIds = setmetatable({}, { __mode = "k" })
local ItemById, NextItemId = {}, 0
local ItemDropdown = ItemSection:CreateDropdown({
	Name = "選擇物品",
	Options = {},
	Searchable = true,
	Save = false,
	Flag = "isle_item",
})
local ItemButton = ItemSection:CreateButton({
	Name = "取得選取物品",
	Enabled = false,
	Callback = function()
		local Object = ItemById[ItemDropdown:Get()]
		if Object then
			_RequestItem(Object)
		else
			Notify("物品已變更，請重新選擇。")
		end
	end,
})
RefreshItems = function()
	if not Alive then
		return
	end
	local Folder = GroundTools()
	local Objects, Options = {}, {}
	ItemById = {}
	if Folder then
		for _, Object in ipairs(Folder:GetChildren()) do
			local Part = Anchor(Object)
			if Part then
				Objects[#Objects + 1] = { Object = Object, Distance = DistanceFromMe(Part) }
			end
		end
	end
	table.sort(Objects, function(First, Second)
		return (First.Distance or math.huge) < (Second.Distance or math.huge)
	end)
	for _, Entry in ipairs(Objects) do
		local Object = Entry.Object
		if not ItemIds[Object] then
			NextItemId = NextItemId + 1
			ItemIds[Object] = "item_" .. NextItemId
		end
		local Id = ItemIds[Object]
		ItemById[Id] = Object
		Options[#Options + 1] = {
			Name = CleanName(Object)
				.. (Entry.Distance and (" · " .. math.floor(Entry.Distance) .. " studs") or " · 等待角色"),
			Value = Id,
		}
	end
	ItemDropdown:Refresh(Options, true, true)
	ItemDropdown:SetEnabled(#Options > 0)
	ItemButton:SetEnabled(#Options > 0)
	ItemInfo:Set(
		Folder and ("可選物品：" .. #Options .. " 個；可在下拉欄中搜尋。")
			or "目前找不到地面物品容器。"
	)
end
ItemSection:CreateButton({
	Name = "重新整理物品",
	Style = "outline",
	Callback = function()
		RefreshItems()
	end,
})

local Movement = Tabs.Player:CreateSection({ Name = "角色參數", Side = "left" })
local PlayerInfo = Tabs.Player:CreateSection({ Name = "狀態與還原", Side = "right" })
Movement:CreateToggle({
	Name = "Noclip／穿牆",
	CurrentValue = false,
	Save = false,
	Flag = "isle_noclip",
	Callback = function(bEnabled)
		NoclipEnabled = bEnabled
		if bEnabled then
			UpdateNoclip()
		else
			RestoreNoclip()
		end
		Notify(bEnabled and "已開啟 Noclip。" or "已關閉 Noclip，還原角色碰撞設定。")
	end,
})
local Humanoid = GetHumanoid()
local SpeedControl = Movement:CreateSlider({
	Name = "WalkSpeed",
	Range = { 0, 100 },
	Increment = 1,
	CurrentValue = Humanoid and Humanoid.WalkSpeed or 16,
	Save = false,
	Flag = "isle_speed",
	Callback = function(Value)
		local Current = GetHumanoid()
		if not Current then
			return Notify("目前沒有可用角色。")
		end
		SaveOriginal(Current)
		SpeedDesired = Value
		Current.WalkSpeed = Value
		BindSpeed()
		Notify("WalkSpeed 設定為 " .. Value)
	end,
})
Movement:CreateToggle({
	Name = "鎖定 WalkSpeed",
	CurrentValue = true,
	Save = false,
	Flag = "isle_speed_lock",
	Callback = function(bEnabled)
		SpeedLocked = bEnabled
		if bEnabled then
			BindSpeed()
		end
		Notify(bEnabled and "已開啟速度鎖定。" or "已關閉速度鎖定。")
	end,
})
local JumpControl = Movement:CreateSlider({
	Name = "JumpHeight",
	Range = { 0, 500 },
	Increment = 0.1,
	CurrentValue = Humanoid and Humanoid.JumpHeight or 7.2,
	Save = false,
	Flag = "isle_jump",
	Callback = function(Value)
		local Current = GetHumanoid()
		if not Current then
			return Notify("目前沒有可用角色。")
		end
		SaveOriginal(Current)
		Current.UseJumpPower = false
		Current.JumpHeight = Value
		Notify("JumpHeight 設定為 " .. string.format("%.1f", Value))
	end,
})
local Readout = PlayerInfo:CreateParagraph({ Title = "角色狀態", Content = "等待角色資料…" })
PlayerInfo:CreateButton({
	Name = "還原本次修改前的參數",
	Style = "outline",
	Callback = function()
		SpeedDesired = nil
		local Current = GetHumanoid()
		if not Current then
			return Notify("已清除速度鎖定目標；等待角色。")
		end
		RestoreOriginal(Current)
		SpeedControl:Set(Current.WalkSpeed, true)
		JumpControl:Set(Current.JumpHeight, true)
		Notify("已還原參數並清除速度鎖定目標。")
	end,
})
PlayerInfo:CreateButton({
	Name = "同步 Slider 與目前角色",
	Style = "secondary",
	Callback = function()
		local Current = GetHumanoid()
		if Current then
			SpeedControl:Set(Current.WalkSpeed, true)
			JumpControl:Set(Current.JumpHeight, true)
			Notify("已同步；速度鎖定目標未變更。")
		end
	end,
})
PlayerInfo:CreateParagraph({
	Title = "速度鎖定",
	Content = "設定目標後會重新套用被草叢等效果改動的速度；重生後保留目標，卸載時解除並還原本次修改。",
})
UpdatePlayerReadout = function()
	local Current = GetHumanoid()
	if not Current then
		Readout:Set("角色狀態", "等待角色資料…")
		return
	end
	local Jump = Current.UseJumpPower and ("JumpPower " .. string.format("%.1f", Current.JumpPower))
		or ("JumpHeight " .. string.format("%.1f", Current.JumpHeight))
	Readout:Set(
		"角色狀態",
		string.format(
			"目前 WalkSpeed：%.1f\n速度鎖定目標：%s\n目前跳躍：%s",
			Current.WalkSpeed,
			SpeedDesired ~= nil and tostring(SpeedDesired) or "尚未設定",
			Jump
		)
	)
end

-- Coordinates are extracted from ReplicatedStorage.Markers in the supplied place.
-- At runtime, marker labels/positions override these snapshot fallbacks.
-- Marker labels (not the repeated internal name "NoGo") identify hidden areas.
local LandmarkSnapshot = {
	{
		Name = "Bridge",
		Chinese = "橋樑",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(102.261253, 66.352699, -1410.821777),
	},
	{
		Name = "Impact Zone",
		Chinese = "撞擊區／出生海岸",
		Group = "地面地標",
		Aliases = "Shipwreck Prisoner Ship 沉船 囚犯船 出生點",
		Position = Vector3.new(-313.710297, 32.750572, 820.874634),
	},
	{
		Name = "Cursed Path",
		Chinese = "詛咒小徑",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-725.294006, 7.317334, 332.866669),
	},
	{
		Name = "Warehouses",
		Chinese = "倉庫區",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-934.166809, 57.420853, -537.721375),
	},
	{
		Name = "Villa Front",
		Chinese = "別墅前庭",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(147.502365, 3.448289, 308.711578),
	},
	{
		Name = "Plane Shed",
		Chinese = "飛機棚屋",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1926.209717, 183.209946, -598.886169),
	},
	{
		Name = "Radio Tower",
		Chinese = "無線電塔",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1050.116211, 526.712341, -1416.967285),
	},
	{
		Name = "Archipelago",
		Chinese = "群島",
		Group = "海域／岩島",
		Aliases = "",
		Position = Vector3.new(-1563.589844, -7.000000, 680.860107),
	},
	{
		Name = "Rock B",
		Chinese = "岩島 B",
		Group = "海域／岩島",
		Aliases = "The Balloon 熱氣球",
		Position = Vector3.new(-1053.120605, 324.245392, -3404.830322),
	},
	{
		Name = "Jungle",
		Chinese = "叢林",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-203.607819, 40.948921, 276.399658),
	},
	{
		Name = "Generator Shore",
		Chinese = "發電站海岸",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(470.909058, -5.000000, -250.686279),
	},
	{
		Name = "Impact Coastline",
		Chinese = "撞擊海岸線",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(219.935486, 12.764188, 763.910217),
	},
	{
		Name = "Spider's Perch",
		Chinese = "蜘蛛棲地",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-267.738770, 52.812584, 1237.513062),
	},
	{
		Name = "Cove",
		Chinese = "海灣",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-763.546936, 55.968567, 1041.421875),
	},
	{
		Name = "Cliff Runway",
		Chinese = "懸崖跑道",
		Group = "地面地標",
		Aliases = "The Air 飛機逃生",
		Position = Vector3.new(-2163.137695, 204.043289, -293.546204),
	},
	{
		Name = "Campsite B",
		Chinese = "營地 B",
		Group = "海域／岩島",
		Aliases = "",
		Position = Vector3.new(-96.747147, 270.110291, -2639.263428),
	},
	{
		Name = "Grand Lake",
		Chinese = "大湖",
		Group = "海域／岩島",
		Aliases = "",
		Position = Vector3.new(-413.149994, -7.000000, -418.076263),
	},
	{
		Name = "Mountain Cave Entrance",
		Chinese = "山洞入口",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-210.194275, 63.158314, -1479.681641),
	},
	{
		Name = "Watchtower",
		Chinese = "瞭望塔",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-684.029419, 96.203293, -297.445557),
	},
	{
		Name = "Generators",
		Chinese = "發電站",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(486.986938, -5.498597, -560.585693),
	},
	{
		Name = "Grass Crossings",
		Chinese = "草地交叉路口",
		Group = "地面地標",
		Aliases = "Grass Crossing 草地路口",
		Position = Vector3.new(-1735.115112, 188.722763, -1055.386353),
	},
	{
		Name = "Lighthouse",
		Chinese = "燈塔",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1526.593994, 117.090668, -227.049118),
	},
	{
		Name = "Docks",
		Chinese = "碼頭",
		Group = "地面地標",
		Aliases = "The Sea 海上逃生",
		Position = Vector3.new(-2066.951904, -0.428797, -1573.983887),
	},
	{
		Name = "Plane Crash",
		Chinese = "墜機地點",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-662.373413, 313.183472, -1799.437256),
	},
	{
		Name = "Campsite A",
		Chinese = "營地 A",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-875.928650, 322.133484, -1175.790161),
	},
	{
		Name = "Ravine",
		Chinese = "峽谷",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1637.764404, 104.381020, -1914.342163),
	},
	{
		Name = "Stone Ruins",
		Chinese = "石造遺跡",
		Group = "海域／岩島",
		Aliases = "",
		Position = Vector3.new(-691.300049, 253.000000, -2743.100098),
	},
	{
		Name = "Arches",
		Chinese = "石拱區",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-2276.874023, 98.647552, -2247.281738),
	},
	{
		Name = "Rock A",
		Chinese = "岩島 A",
		Group = "海域／岩島",
		Aliases = "",
		Position = Vector3.new(33.931644, 269.364471, -2924.832520),
	},
	{
		Name = "Ruined Falls",
		Chinese = "荒廢瀑布",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-614.769043, 212.053802, -1087.116211),
	},
	{
		Name = "Rock Pools",
		Chinese = "岩池",
		Group = "海域／岩島",
		Aliases = "",
		Position = Vector3.new(-53.922546, -1.210388, -1935.955688),
	},
	{
		Name = "Dome",
		Chinese = "圓頂建築",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-698.268433, 388.381836, -1237.476318),
	},
	{
		Name = "Observatory",
		Chinese = "天文台",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(400.124268, 130.266800, -1176.066528),
	},
	{
		Name = "Observatory Hill",
		Chinese = "天文台山丘",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(259.921753, 76.326202, -1260.289673),
	},
	{
		Name = "Bunker",
		Chinese = "碉堡",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1535.037842, 295.940155, -1494.651489),
	},
	{
		Name = "Military Camp",
		Chinese = "軍事營地",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1053.747437, 331.650452, -1844.175659),
	},
	{
		Name = "Bungalows",
		Chinese = "平房區",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-297.169983, -4.127823, -2439.528320),
	},
	{
		Name = "Greenhouse",
		Chinese = "溫室",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1353.506714, 354.008881, -1152.656860),
	},
	{
		Name = "Mine Entrance",
		Chinese = "礦坑入口",
		Group = "地面地標",
		Aliases = "Mineshaft 礦井",
		Position = Vector3.new(-1394.857300, 208.251495, -774.659668),
	},
	{
		Name = "East Enchanted Woods",
		Chinese = "東方魔法森林",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-960.886475, 191.814575, -2057.792969),
	},
	{
		Name = "North Enchanted Woods",
		Chinese = "北方魔法森林",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1419.135620, 239.242386, -1406.273560),
	},
	{
		Name = "Hangar",
		Chinese = "機庫",
		Group = "地面地標",
		Aliases = "The Hangar 機庫逃生",
		Position = Vector3.new(-1594.128418, 24.753750, -2266.460449),
	},
	{
		Name = "Facility",
		Chinese = "地下設施",
		Group = "地下／特殊",
		Aliases = "The Facility 研究設施 實驗室",
		Position = Vector3.new(-1784.156006, -193.904419, -1416.711670),
	},
	{
		Name = "Lair",
		Chinese = "巢穴",
		Group = "地下／特殊",
		Aliases = "",
		Position = Vector3.new(-1799.672852, -45.979416, -618.189087),
	},
	{
		Name = "Dragon",
		Chinese = "巨龍／猿城區域",
		Group = "地下／特殊",
		Aliases = "Ape City 猿城",
		Position = Vector3.new(-1247.683350, -51.311798, -1008.929321),
	},
	{
		Name = "Monkeyland",
		Chinese = "猴子樂園",
		Group = "地下／特殊",
		Aliases = "",
		Position = Vector3.new(-1251.510742, -489.244873, -1681.060059),
	},
	{
		Name = "Central Reservoir",
		Chinese = "中央水庫",
		Group = "地下／特殊",
		Aliases = "Reservoir 水庫",
		Position = Vector3.new(-777.245117, 29.116081, -1511.276123),
	},
	{
		Name = "Mirror World",
		Chinese = "鏡像世界",
		Group = "地下／特殊",
		Aliases = "",
		Position = Vector3.new(-1546.498047, -764.264282, -484.717957),
	},
	{
		Name = "[ REDACTED ]",
		Chinese = "保密區域",
		Group = "地面地標",
		Aliases = "Redacted",
		Position = Vector3.new(43.768753, 13.894410, -1779.074341),
	},
	{
		Name = "Cargo Ship",
		Chinese = "貨船",
		Group = "地面地標",
		Aliases = "貨輪",
		Position = Vector3.new(-1816.591675, 40.746376, -38.162884),
	},
	{
		Name = "Volcano",
		Chinese = "火山區",
		Group = "海域／岩島",
		Aliases = "",
		Position = Vector3.new(1330.889893, 21.643135, -1961.362671),
	},
	{
		Name = "East Hangar",
		Chinese = "機庫東側",
		Group = "地面地標",
		Aliases = "",
		Position = Vector3.new(-1184.905884, 28.428345, -2981.912354),
	},
	{
		Name = "The Depths",
		Chinese = "深淵區",
		Group = "海域／岩島",
		Aliases = "",
		Position = Vector3.new(-1702.200195, -7.000000, -3369.400146),
	},
}

local function LandmarkKey(name)
	return name:lower():gsub("[%s_%-]", "")
end
local function CollectLandmarks()
	local entries, index = {}, {}
	for _, saved in ipairs(LandmarkSnapshot) do
		local entry = {}
		for key, value in pairs(saved) do
			entry[key] = value
		end
		entry.Source = "地圖檔座標"
		table.insert(entries, entry)
		index[LandmarkKey(entry.Name)] = entry
	end
	local folder = game:GetService("ReplicatedStorage"):FindFirstChild("Markers")
	if folder then
		for _, marker in ipairs(folder:GetDescendants()) do
			if marker:IsA("BasePart") then
				local label = marker:FindFirstChildWhichIsA("TextLabel", true)
				local name = label and label.Text or marker.Name
				name = name:gsub("<[^>]+>", ""):match("^%s*(.-)%s*$")
				if name ~= "" and name ~= "NoGo" then
					local key = LandmarkKey(name)
					local entry = index[key]
					if not entry then
						entry = {
							Name = name,
							Chinese = name,
							Aliases = "",
							Group = marker:GetAttribute("Underground") and "地下／特殊" or "地面地標",
						}
						table.insert(entries, entry)
						index[key] = entry
					end
					entry.Position = marker.Position
					entry.Source = "本局地點標記"
				end
			end
		end
	end
	table.sort(entries, function(a, b)
		if a.Group ~= b.Group then
			return a.Group < b.Group
		end
		return a.Name:lower() < b.Name:lower()
	end)
	return entries
end
local function LandmarkLanding(position)
	local map = W:FindFirstChild("Map")
	local include = {}
	if map then
		table.insert(include, map)
	end
	local terrain = W:FindFirstChildOfClass("Terrain")
	if terrain then
		table.insert(include, terrain)
	end
	if #include > 0 then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = include
		params.RespectCanCollide = true
		params.IgnoreWater = false
		local offsets = {
			Vector3.zero,
			Vector3.new(6, 0, 0),
			Vector3.new(-6, 0, 0),
			Vector3.new(0, 0, 6),
			Vector3.new(0, 0, -6),
		}
		for _, offset in ipairs(offsets) do
			local hit = W:Raycast(position + offset + Vector3.new(0, 10, 0), Vector3.new(0, -40, 0), params)
			if hit and hit.Normal.Y >= 0.45 then
				return hit.Position + Vector3.new(0, 4, 0), true
			end
		end
	end
	-- Snapshot markers are points of interest, not guaranteed spawn pads.
	return position + Vector3.new(0, 4, 0), false
end

local function _Teleport(provider, title, isLocation)
	if CurrentPickup then
		return Notify("請等待拾取與返回完成。")
	end
	if TeleportBusy then
		return Notify("傳送處理中，請稍候。")
	end
	local character = Me.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = GetHumanoid()
	if not root or not humanoid or humanoid.Health <= 0 then
		return Notify("自己的角色尚未準備好。")
	end
	if humanoid.SeatPart then
		return Notify("請先離開座位。")
	end
	TeleportBusy = true
	Notify("正在前往：" .. title)
	_Later(0, function()
		local note
		local ok, err = pcall(function()
			local cf = provider()
			if not cf then
				error("目的地目前不可用。", 0)
			end
			if isLocation and W.StreamingEnabled then
				pcall(function()
					Me:RequestStreamAroundAsync(cf.Position, 2)
				end)
			end
			if not Alive then
				return
			end
			if Me.Character ~= character or not root.Parent or humanoid.Health <= 0 then
				error("角色已變更。", 0)
			end
			if humanoid.SeatPart then
				error("請先離開座位。", 0)
			end
			-- Refresh player destinations after streaming/yields.
			cf = provider()
			if not cf then
				error("目的地已失效。", 0)
			end
			if isLocation then
				local point, groundFound = LandmarkLanding(cf.Position)
				cf = CFrame.new(point)
				if not groundFound then
					note = "使用標記座標，請留意落點。"
				end
			end
			character:PivotTo(cf)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end)
		TeleportBusy = false
		if not Alive then
			return
		end
		if ok then
			Notify("已在本機移動至 " .. title .. (note and ("；" .. note) or "。"))
		else
			Notify("傳送失敗：" .. tostring(err))
		end
	end)
end

local LocationSection = Tabs.TP:CreateSection({ Name = "地點傳送", Side = "full", Subtab = "地點" })
local LocationById, PlayerById = {}, {}
local LocationDetails = LocationSection:CreateParagraph({ Title = "地點資訊", Content = "正在讀取地點…" })
local LocationDropdown
local function _DescribeLocation()
	local Entry = LocationById[LocationDropdown:Get()]
	if not Entry then
		LocationDetails:Set("地點資訊", "沒有可選地點。")
		return
	end
	local Distance = DistanceFromMe({ Position = Entry.Position })
	LocationDetails:Set(
		Entry.Chinese .. " / " .. Entry.Name,
		Entry.Group
			.. " · "
			.. Entry.Source
			.. (Distance and ("\n距離：" .. math.floor(Distance) .. " studs") or "")
	)
end
LocationDropdown = LocationSection:CreateDropdown({
	Name = "選擇地點",
	Options = {},
	Searchable = true,
	Save = false,
	Flag = "isle_location",
	Callback = function()
		_DescribeLocation()
	end,
})
local LocationButton = LocationSection:CreateButton({
	Name = "傳送至選取地點",
	Callback = function()
		local Id = LocationDropdown:Get()
		local Entry = LocationById[Id]
		if not Entry then
			return Notify("請先選擇地點。")
		end
		_Teleport(function()
			for _, Current in ipairs(CollectLandmarks()) do
				if LandmarkKey(Current.Name) == Id then
					return CFrame.new(Current.Position)
				end
			end
		end, Entry.Chinese, true)
	end,
})
local function _RefreshLocations()
	local Options = {}
	LocationById = {}
	for _, Entry in ipairs(CollectLandmarks()) do
		local Id = LandmarkKey(Entry.Name)
		LocationById[Id] = Entry
		Options[#Options + 1] = {
			Name = Entry.Chinese
				.. " / "
				.. Entry.Name
				.. " · "
				.. Entry.Group
				.. (Entry.Aliases ~= "" and (" · " .. Entry.Aliases) or ""),
			Value = Id,
		}
	end
	LocationDropdown:Refresh(Options, true, true)
	LocationDropdown:SetEnabled(#Options > 0)
	LocationButton:SetEnabled(#Options > 0)
	_DescribeLocation()
end
LocationSection:CreateButton({ Name = "重新整理地點", Style = "outline", Callback = _RefreshLocations })
LocationSection:CreateParagraph({
	Title = "地點資料",
	Content = "保留原腳本的全部地標，優先採用本局標記；下拉欄支援中文、英文與別名搜尋。",
})

local PlayerSection = Tabs.TP:CreateSection({ Name = "玩家傳送", Side = "full", Subtab = "玩家" })
local OtherInfo = PlayerSection:CreateLabel({ Name = "正在讀取玩家…" })
local PlayerDropdown = PlayerSection:CreateDropdown({
	Name = "選擇玩家",
	Options = {},
	Searchable = true,
	Save = false,
	Flag = "isle_target_player",
})
local PlayerButton = PlayerSection:CreateButton({
	Name = "傳送至選取玩家",
	Enabled = false,
	Callback = function()
		local Other = PlayerById[PlayerDropdown:Get()]
		if not Other then
			return Notify("玩家已離開，請重新整理。")
		end
		_Teleport(function()
			if Other.Parent ~= Players then
				return nil
			end
			local Character = Other.Character
			local Destination = Character and Character:FindFirstChild("HumanoidRootPart")
			local Human = Character and Character:FindFirstChildOfClass("Humanoid")
			if not Destination or (Human and Human.Health <= 0) then
				return nil
			end
			return Destination.CFrame * CFrame.new(3, 0, 3)
		end, Other.DisplayName, false)
	end,
})
local function _RefreshOtherPlayers()
	local Others, Options = {}, {}
	PlayerById = {}
	for _, Other in ipairs(Players:GetPlayers()) do
		if Other ~= Me then
			Others[#Others + 1] = Other
		end
	end
	table.sort(Others, function(First, Second)
		return First.Name:lower() < Second.Name:lower()
	end)
	local bAvailable = false
	for _, Other in ipairs(Others) do
		local Character = Other.Character
		local Root = Character and Character:FindFirstChild("HumanoidRootPart")
		local Human = Character and Character:FindFirstChildOfClass("Humanoid")
		local bDisabled = not Root or (Human and Human.Health <= 0) or false
		local Distance = Root and DistanceFromMe(Root)
		PlayerById[Other.UserId] = Other
		Options[#Options + 1] = {
			Name = Other.DisplayName
				.. " (@"
				.. Other.Name
				.. ")"
				.. (Distance and (" · " .. math.floor(Distance) .. " studs") or " · 未生成"),
			Value = Other.UserId,
			Disabled = bDisabled,
		}
		bAvailable = bAvailable or not bDisabled
	end
	PlayerDropdown:Refresh(Options, true, true)
	PlayerDropdown:SetEnabled(bAvailable)
	PlayerButton:SetEnabled(bAvailable)
	OtherInfo:Set("其他玩家：" .. #Others .. " 位；先選擇，再按下傳送按鈕。")
end
PlayerSection:CreateButton({ Name = "重新整理玩家", Style = "outline", Callback = _RefreshOtherPlayers })
RefreshPlayers = function()
	if not Alive then
		return
	end
	if Tabs.TP.ActivePage.Name == "地點" then
		_RefreshLocations()
	else
		_RefreshOtherPlayers()
	end
end
_RefreshLocations()
_RefreshOtherPlayers()

local SettingsTab = Window:CreateTab("介面設定", "settings")
local Appearance = SettingsTab:CreateSection({ Name = "外觀", Side = "left" })
local AccentControl = Appearance:CreateColorPicker({
	Name = "主題顏色",
	Color = Window.Theme.Accent,
	Save = false,
	Callback = function(Color)
		Window:SetAccent(Color)
	end,
})
local ScaleControl = Appearance:CreateSlider({
	Name = "介面縮放",
	Range = { 65, 150 },
	Increment = 5,
	CurrentValue = Window.Scale * 100,
	Suffix = "%",
	Save = false,
	Callback = function(Value)
		Window:SetScale(Value / 100)
	end,
})
local AnimationControl = Appearance:CreateToggle({
	Name = "介面動畫",
	CurrentValue = Window.Animations,
	Save = false,
	Callback = function(bEnabled)
		Window:SetAnimations(bEnabled)
	end,
})
local ConfigSection = SettingsTab:CreateSection({ Name = "設定與視窗", Side = "right" })
ConfigSection:CreateParagraph({
	Title = "設定檔",
	Content = "workspace/BjzUi/UiConfig.json\n保存視窗位置、尺寸與外觀；功能開關及角色數值維持本次執行狀態。",
})
ConfigSection:CreateButton({
	Name = "儲存介面設定",
	Callback = function()
		local bSaved, Reason = Window:SaveConfiguration()
		Notify(bSaved and "介面設定已儲存。" or tostring(Reason))
	end,
})
ConfigSection:CreateButton({
	Name = "讀取介面設定",
	Style = "outline",
	Callback = function()
		local bLoaded, Reason = Window:LoadConfiguration(true)
		if bLoaded then
			AccentControl:Set(Window.Theme.Accent, true)
			ScaleControl:Set(Window.Scale * 100, true)
			AnimationControl:Set(Window.Animations, true)
		end
		Notify(bLoaded and "已套用介面設定。" or tostring(Reason))
	end,
})
ConfigSection:CreateButton({
	Name = "最小化",
	Style = "secondary",
	Callback = function()
		Window:Minimize()
	end,
})
ConfigSection:CreateButton({
	Name = "停止並關閉",
	Style = "outline",
	Callback = function()
		Window:Destroy()
	end,
})
local function _UpdateActivePage()
	ActivePage = nil
	for Key, Tab in pairs(Tabs) do
		if Window.ActiveTab == Tab then
			ActivePage = Key
			break
		end
	end
	if ActivePage == "Item" then
		RefreshItems()
	elseif ActivePage == "TP" then
		RefreshPlayers()
	elseif ActivePage == "Player" then
		UpdatePlayerReadout()
	end
end
for _, Tab in pairs(Tabs) do
	Connect(Tab.Frame:GetPropertyChangedSignal("Visible"), _UpdateActivePage)
end
Connect(SettingsTab.Frame:GetPropertyChangedSignal("Visible"), _UpdateActivePage)
for _, Page in ipairs(Tabs.TP.Pages) do
	Connect(Page.Frame:GetPropertyChangedSignal("Visible"), function()
		if Page.Frame.Visible then
			RefreshPlayers()
		end
	end)
end
RefreshItems()
UpdatePlayerReadout()
_UpdateActivePage()

-- ESP discovery and lifecycle.
local function Track(object)
	if object:IsA("Model") or object:IsA("Tool") or object:IsA("BasePart") then
		if IsFuse(object) or Groups[object:GetAttribute("ESPCategory")] then
			Candidates[object] = true
		end
	elseif object.Name == "#Pickup" and object.Parent then
		Candidates[object.Parent] = true
	end
end
Connect(W.DescendantAdded, Track)
Connect(W.DescendantRemoving, function(object)
	Candidates[object] = nil
end)
local function Cleanup()
	if not Alive then
		return
	end
	Alive = false
	for Thread in pairs(Tasks) do
		_CancelTask(Thread)
	end
	table.clear(Tasks)
	CancelPickup()
	NoclipEnabled = false
	RestoreNoclip()
	SpeedDesired = nil
	SpeedLocked = false
	if SpeedConnection then
		SpeedConnection:Disconnect()
		SpeedConnection = nil
	end
	for _, connection in ipairs(Connections) do
		connection:Disconnect()
	end
	local humanoids = {}
	for humanoid in pairs(Originals) do
		table.insert(humanoids, humanoid)
	end
	for _, humanoid in ipairs(humanoids) do
		RestoreOriginal(humanoid)
	end
	EspEngine:Destroy()
	table.clear(Candidates)
end
Connect(Gui.Destroying, Cleanup)
local DestroyWindow = Window.Destroy
--[[
    關閉視窗前解除腳本持有的事件、排程與角色變動。
    @param self 此腳本建立的視窗，由冒號呼叫傳入。
]]
function Window.Destroy(self: typeof(Window))
	Cleanup()
	DestroyWindow(self)
end
for _, Child in ipairs(Window.Body:GetChildren()) do
	if Child:IsA("TextButton") and Child.Text == "×" then
		Connect(Child.Activated, function()
			Window:Destroy()
		end)
		break
	end
end
for _, object in ipairs(W:GetDescendants()) do
	Track(object)
end

--[[
    發現 Isle 目標、解決分類衝突與巢狀重複，再將啟用的目標快照交給共用引擎。
    更新各分類的辨識數量；距離限制、數量限制與視覺更新由引擎負責。
]]
local function RefreshESP()
	local camera = W.CurrentCamera
	if not camera then
		return
	end
	local targets, characters = {}, {}
	for _, other in ipairs(Players:GetPlayers()) do
		if other.Character then
			characters[other.Character] = other
		end
	end
	local function Add(object, key, title)
		if not object:IsDescendantOf(W) then
			return
		end
		if not (object:IsA("Model") or object:IsA("Tool") or object:IsA("BasePart")) then
			return
		end
		local ancestor = object
		while ancestor and ancestor ~= W do
			local owner = characters[ancestor]
			if owner then
				if key ~= "Player" or owner == Me then
					return
				end
				break
			end
			ancestor = ancestor.Parent
		end
		local humanoid = object:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			return
		end
		if key == "Item" and IsFuse(object) then
			key = "Fuse"
		end
		local existing = targets[object]
		if existing and Priority[existing.Key] <= Priority[key] then
			return
		end
		local part = Anchor(object)
		if not part then
			return
		end
		targets[object] = {
			Object = object,
			Part = part,
			Key = key,
			Title = title or CleanName(object),
		}
	end
	for character, other in pairs(characters) do
		if other ~= Me then
			Add(character, "Player", other.DisplayName .. " (@" .. other.Name .. ")")
		end
	end
	for _, name in ipairs(Config.EnemyRoots) do
		local root = W:FindFirstChild(name)
		if root then
			for _, object in ipairs(root:GetDescendants()) do
				if object:IsA("Humanoid") and object.Parent then
					Add(object.Parent, "Enemy")
				end
			end
		end
	end
	local ignore = IgnoreFolder()
	if ignore then
		for _, name in ipairs({ "Tools", "SpecialPickup", "Collectibles" }) do
			local folder = ignore:FindFirstChild(name)
			if folder then
				for _, object in ipairs(folder:GetChildren()) do
					Add(object, "Item")
				end
			end
		end
	end
	for object in pairs(Candidates) do
		if object:IsDescendantOf(W) then
			local category = object:GetAttribute("ESPCategory")
			if IsFuse(object) then
				Add(object, "Fuse")
			elseif Groups[category] then
				Add(object, category)
			elseif object:FindFirstChild("#Pickup") then
				Add(object, "Item")
			end
		else
			Candidates[object] = nil
		end
	end
	for _, key in ipairs(Order) do
		for _, object in ipairs(CollectionService:GetTagged("ESP" .. key)) do
			Add(object, key)
		end
	end
	local nested = {}
	for object in pairs(targets) do
		local parent = object.Parent
		while parent and parent ~= W do
			if targets[parent] then
				nested[object] = true
				break
			end
			parent = parent.Parent
		end
	end
	for object in pairs(nested) do
		targets[object] = nil
	end
	local Counts, Targets = { Fuse = 0, Enemy = 0, Player = 0, Item = 0 }, {}
	for _, Target in pairs(targets) do
		Counts[Target.Key] = Counts[Target.Key] + 1
		local Group = Groups[Target.Key]
		if Group.Enabled then
			table.insert(Targets, {
				Object = Target.Object,
				Part = Target.Part,
				Title = Target.Title,
				Color = Group.Color,
				Priority = Priority[Target.Key],
			})
		end
	end
	EspEngine:Refresh(Targets, {
		bShowLabels = ShowLabels,
		bShowTracers = ShowTracers,
		MaxDistance = MaxDistance,
		MaxMarkers = Config.MaxMarkers,
	})
	for _, key in ipairs(Order) do
		Groups[key].Counter:Set("已辨識 " .. Counts[key] .. " 個")
	end
end

--[[
    視窗存活時，每幀更新共用引擎的追蹤線與離屏箭頭。
]]
Connect(RunService.RenderStepped, function()
	EspEngine:Render()
end)
-- Stepped runs before physics; catches collision resets and new characters.
Connect(RunService.Stepped, UpdateNoclip)
local elapsed, listElapsed, speedElapsed, lastError = 0, 0, 0, -math.huge
Connect(RunService.Heartbeat, function(dt)
	if not Alive then
		return
	end
	elapsed = elapsed + dt
	listElapsed = listElapsed + dt
	speedElapsed = speedElapsed + dt
	if speedElapsed >= 0.15 then
		speedElapsed = 0
		BindSpeed()
	end
	if not Dirty and elapsed < Config.RefreshInterval then
		return
	end
	elapsed = 0
	Dirty = false
	local ok, err = pcall(function()
		RefreshESP()
		if (Window.Visible and not Window.Minimized) and ActivePage == "Player" then
			UpdatePlayerReadout()
		end
		if listElapsed >= 3 then
			listElapsed = 0
			if Window.Visible and not Window.Minimized then
				if ActivePage == "Item" then
					RefreshItems()
				elseif ActivePage == "TP" then
					RefreshPlayers()
				end
			end
		end
	end)
	if not ok and os.clock() - lastError > 5 then
		lastError = os.clock()
		Notify("更新發生錯誤，請查看執行器輸出。")
		warn("[Island Panel] " .. tostring(err))
	end
end)
BindSpeed()
Notify("已載入：透視 / 物品 / 玩家 / 傳送")

return Window

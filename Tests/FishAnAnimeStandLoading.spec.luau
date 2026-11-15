local Fs, Luau, Rbx = require("@lune/fs"), require("@lune/luau"), require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local Runtime = { bAlive = true, HomeReservations = { bReady = true }, CharacterPlan = { Sentinel = true } }
local Controller = { bAutoCharacters = true }
local Now, Calls, Status = 0, {}, ""
local Attributes, Globals, Character = { Rebirths = 11, Sacrifices = 0 }, {}, {}
local OnWait, OnTeleport = nil, nil
local Root = { CFrame = Rbx.CFrame.new(), Parent = Character }
local Player = { UserId = 42, Character = Character }
local Gui, Main, Overlay = Rbx.Instance.new("Folder"), Rbx.Instance.new("Folder"), Rbx.Instance.new("Frame")
Main.Name, Main.Parent, Overlay.Name, Overlay.Parent, Overlay.Visible = "MainGui", Gui, "TeleportingGUI", Main, false
local Remote, bRemoteAvailable = {}, true
--[[
	核對原生 Remote 類別。
	@param self 遠端替身。
	@param Name 要求的類別。
	@return 是否為 RemoteEvent。
]]
function Remote.IsA(self, Name) return Name == "RemoteEvent" end
--[[
	記錄原生封包；實際移動與複寫交由伺服器替身。
	@param self 遠端替身。
	@param Destination 必須為 Plot。
]]
function Remote.FireServer(self, Destination)
	assert(Destination == "Plot")
	table.insert(Calls, "Remote")
	if OnTeleport then OnTeleport() end
end
--[[
	讀取轉生狀態。
	@param self 玩家替身。
	@param Name 屬性名稱。
	@return 屬性值。
]]
function Player.GetAttribute(self, Name) return Attributes[Name] end
--[[
	取得傳送畫面。
	@param self 玩家替身。
	@param Name 子物件名稱。
	@return PlayerGui 或 nil。
]]
function Player.FindFirstChild(self, Name) return if Name == "PlayerGui" then Gui else nil end
local Functions = { "local _CharacterPairs = {}" }
for _, Name in { "StandIndex", "UnloadedStand", "LoadStand", "ReadPlot", "Prompt" } do
	table.insert(Functions, assert(Source:match("(function _CharacterPairs%." .. Name .. ".-\nend)")))
end
local Engine = Luau.load(table.concat(Functions, "\n") .. "\nreturn _CharacterPairs", { environment = {
	_Runtime = Runtime, Controller = Controller, LocalPlayer = Player, _G = Globals,
	Constants = { Characters = { Current = { CPS = 10 } }, TypeSystem = { Multipliers = {} },
		--[[
			提供固定的收益曲線。
			@param Level 角色等級。
			@return 固定倍率。
		]]
		GetCpsCurveMultiplier = function(Level) return 1 end },
	--[[
		取得可用的原生 Remote。
		@param self 遠端容器。
		@param Name 遠端名稱。
		@return 回家 Remote；缺少時為 nil。
	]]
	Remotes = { FindFirstChild = function(self, Name) return if bRemoteAvailable and Name == "TeleportRequest" then Remote else nil end },
	--[[
		讀取測試時鐘。
		@return 現在秒數。
	]]
	os = { clock = function() return Now end },
	--[[
		取得存活角色。
		@return 角色根部。
	]]
	_Character = function() return Root end,
	--[[
		只取得移動權，不計算回家座標。
		@param Key 工作鍵。
		@param CharacterRoot 角色根部。
		@param Target 必須為當前位置。
		@return true 表示取得位移權。
	]]
	_Travel = function(Key, CharacterRoot, Target)
		assert(Target == CharacterRoot.CFrame, "目的地必須交由原生傳送決定")
		Runtime.Move = { Key = Key, Original = CharacterRoot.CFrame }
		table.insert(Calls, "AcquireMove")
		return true
	end,
	--[[
		原生回家只釋放位移權，不覆寫伺服器位置。
		@param Key 持有位移的工作鍵。
	]]
	_RestoreMove = function(Key)
		if Runtime.Move then
			assert(Runtime.Move.Key == Key)
			if not Runtime.Move.bNativeTeleport then Root.CFrame = Runtime.Move.Original end
			Runtime.Move = nil
		end
	end,
	--[[
		記錄裝備狀態。
		@param Key 功能鍵。
		@param Text 狀態文字。
	]]
	_Status = function(Key, Text) Status = Text end,
	--[[
		推進傳送動畫與場景複寫。
		@param Seconds 等待秒數。
	]]
	task = { wait = function(Seconds) Now += Seconds if OnWait then OnWait() end end },
} })()
local Plot, Purchases, Stand, Platform = Rbx.Instance.new("Folder"), Rbx.Instance.new("Folder"), Rbx.Instance.new("Folder"), Rbx.Instance.new("Part")
Plot:SetAttribute("OwnerUserId", 42)
Purchases.Name, Purchases.Parent, Stand.Name, Stand.Parent = "Purchases", Plot, "7", Purchases
Stand:SetAttribute("HasCharacter", true)
Stand:SetAttribute("CharacterName", "")
Stand:SetAttribute("Level", 10)
Platform.Name, Platform.CFrame = "Platform", Rbx.CFrame.new(600, 20, 100)
local HomePose, SentAt = Rbx.CFrame.new(610, 24, 105), 0
--[[
	模擬原生回家，先播放畫面再延遲載入展台。
]]
OnTeleport = function() SentAt = Now Root.CFrame, Overlay.Visible = HomePose, true end
--[[
	畫面結束後仍須等待零件與屬性載入。
]]
OnWait = function()
	if Now - SentAt >= 0.8 then Overlay.Visible = false end
	if Now - SentAt >= 2 then Platform.Parent = Stand Stand:SetAttribute("CharacterName", "Current") end
end
assert(Engine.UnloadedStand(Plot) == "7" and next(Runtime.StandAnchors.Positions) == nil)
Engine.LoadStand(Plot, "7", "展台與 Home 都未載入")
assert(#Calls == 2 and Calls[1] == "AcquireMove" and Calls[2] == "Remote", "無座標仍可使用原生回家")
assert(Now >= SentAt + 2.4 and Now < SentAt + 12.5 and Status:find("載入已完成", 1, true), "必須等畫面結束、展台資料穩定")
assert(Root.CFrame == HomePose and Runtime.Move == nil and Runtime.CharacterPlan.Sentinel and not Runtime.HomeReservations.bReady)
assert(Engine.UnloadedStand(Plot) == nil)
Engine.LoadStand(Plot, "7", "重複呼叫")
assert(#Calls == 2, "冷卻期間不重複發送")
Platform.Parent = nil
assert(Engine.UnloadedStand(Plot) == "7")
Stand.Parent = nil
assert(Engine.UnloadedStand(Plot) == "7")
Stand.Parent, Platform.Parent = Purchases, Stand
Stand:SetAttribute("PaidLocked", true)
assert(Engine.UnloadedStand(Plot) == nil)
Stand:SetAttribute("PaidLocked", false)
Engine.UnloadedStand(Plot)
Stand.Parent = nil
Attributes.Sacrifices += 1
assert(Engine.UnloadedStand(Plot) == "" and next(Runtime.StandAnchors.Positions) == nil)
Stand.Parent, Platform.Parent = Purchases, Stand

-- 永不載入：只送一次回家請求，期限到後保留配置且不留下位移鎖。
Now += 6
Stand:SetAttribute("CharacterName", "")
OnWait = nil
local Before, Started = #Calls, Now
Engine.LoadStand(Plot, "7", "伺服器未同步")
assert(Now - Started >= 12 and Now - Started < 12.5 and #Calls == Before + 2)
assert(Status:find("仍未載入完成", 1, true) and Runtime.CharacterPlan.Sentinel and Runtime.Move == nil)
Stand:SetAttribute("CharacterName", "Current")
Overlay.Visible = false

-- 原生函數優先，且不重複發送 Remote。
Now += 6
OnTeleport = nil
--[[
	模擬遊戲公開的原生回家函數。
	@param Destination 必須為 Plot。
]]
Globals.__TeleportPlayFn = function(Destination) assert(Destination == "Plot") table.insert(Calls, "Native") end
Before = #Calls
Engine.LoadStand(Plot, "7", "確認函數入口")
assert(#Calls == Before + 2 and Calls[#Calls] == "Native")
--[[
	原生函數無法呼叫時使用 Remote 後備。
	@param Destination 原生目的地。
]]
Globals.__TeleportPlayFn = function(Destination) error("native unavailable") end
Now += 6
Before = #Calls
Engine.LoadStand(Plot, "7", "後備入口")
assert(#Calls == Before + 2 and Calls[#Calls] == "Remote")

-- 停用、缺少入口與所有權改變均不可留下位移鎖或繼續傳送。
Globals.__TeleportPlayFn = nil
Now += 6
Stand:SetAttribute("CharacterName", "")
--[[
	載入等待期間關閉功能。
]]
OnWait = function() Controller.bAutoCharacters = false end
Engine.LoadStand(Plot, "7", "取消測試")
assert(Runtime.Move == nil)
Controller.bAutoCharacters, OnWait, bRemoteAvailable = true, nil, false
Now += 6
Before = #Calls
Engine.LoadStand(Plot, "7", "缺少入口")
assert(#Calls == Before and Status:find("缺少原生", 1, true) and Runtime.CharacterPlan.Sentinel)
Plot:SetAttribute("OwnerUserId", 99)
Engine.LoadStand(Plot, "7", "所有權改變")
assert(#Calls == Before)
Plot:Destroy()
Gui:Destroy()
print("FishAnAnimeStandLoading: all assertions passed (native home, overlay, stable data, bounded wait, cleanup)")

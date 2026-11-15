--!nonstrict
-- 離線整合：真實 Rbx 資料物件；伺服器、Delta、UI 及排程使用替身。
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
Luau.compile(Source)

--[[
	測試期間可控的時鐘、遠端紀錄、待執行工作與控制項。
]]
local _Now, _Calls, _Tasks, _Controls, _Environment, _Labels = 0, {}, {}, {}, {}, {}
--[[
	模擬伺服器調整過的餵食費用，與舊 Constants 的估算分離。
]]
local _FeedCostOverrides = {}
--[[
	控制地面是否已載入，並記錄場景參考的取得與釋放。
]]
local _bGround, _StreamCalls = true, {}
--[[
	UI 設定 API 的記憶體替身；只驗證入口接合，不代表 Delta 真實檔案讀寫。
]]
local _ConfigDatabase, _SaveCount, _bConfigReadError, _bConfigWriteError = {}, 0, false, false
--[[
	建立並掛入實際 Rbx 物件。
	@param ClassName 物件類別。
	@param Name 物件名稱。
	@param Parent 父物件，nil 表示不掛入。
	@return 新物件。
]]
local function _Object(ClassName, Name, Parent)
	local Object = Rbx.Instance.new(ClassName)
	Object.Name, Object.Parent = Name, Parent
	return Object
end
local World = _Object("Workspace", "Workspace")
local HiddenUI = _Object("Folder", "HiddenUI")
local Backpack = _Object("Backpack", "Backpack")
local NativePlayerGui = _Object("PlayerGui", "PlayerGui")
local NativeMainGui = _Object("ScreenGui", "MainGui", NativePlayerGui)
local NativeFishAction = _Object("Frame", "FishAction", NativeMainGui)
local NativeAutoButton = _Object("TextButton", "AutoFish", NativeFishAction)
local NativeAutoOn = _Object("UIGradient", "Enabled", NativeAutoButton)
local NativeAutoOff = _Object("UIGradient", "Disabled", NativeAutoButton)
local NativePurchase = _Object("TextButton", "Purchase", NativeAutoButton)
local NativeRobux = _Object("TextButton", "Robux", NativeAutoButton)
NativeAutoOn.Enabled, NativeAutoOff.Enabled = false, true
local NativeAutoSignal = {}
--[[
	模擬原生按鈕首輪尚未接好處理器，確認後續輪次會重試。
]]
local _bIgnoreNativeToggle = false
--[[
	模擬按鈕畫面延遲，以及一般觸發無效但原生回呼可正常運作的執行器。
]]
local _NativeToggleDelay, _PendingNativeToggle, _bNativeConnectionsAvailable, _bIgnoreNativeCallback = 0, nil, false, false
--[[
	提供原生按鈕訊號替身，驗證確實觸發按鈕而非改寫 UI 狀態。
	@param Button 按鈕實例。
	@return 訊號替身。
]]
Rbx.implementProperty("TextButton", "MouseButton1Click", function(Button) return NativeAutoSignal end)
local Character = _Object("Model", "Character", World)
local Root = _Object("Part", "HumanoidRootPart", Character)
Root.CFrame, Root.AssemblyLinearVelocity, Root.AssemblyAngularVelocity = Rbx.CFrame.new(), Rbx.Vector3.zero, Rbx.Vector3.zero
Root.Size = Rbx.Vector3.new(2, 2, 1)
local Particle = _Object("ParticleEmitter", "Particles", Root)
Particle.Enabled = true
local DisabledParticle = _Object("ParticleEmitter", "DisabledParticles", Root)
DisabledParticle.Enabled = false
local Visuals = { Particle, DisabledParticle }
for _, ClassName in { "Trail", "Beam", "Smoke", "Fire", "Sparkles" } do
	local Visual = _Object(ClassName, ClassName, Root)
	Visual.Enabled = true
	table.insert(Visuals, Visual)
end
local OutsidePart = _Object("Part", "OutsideWorkspace")
local OutsideParticle = _Object("ParticleEmitter", "OutsideParticles", OutsidePart)
OutsideParticle.Enabled = true
--[[
	記錄原生 Clear 的呼叫；不模擬 GPU 粒子或宣稱實測效能。
	@param Object 粒子或拖尾。
]]
local function _ClearVisual(Object) Object:SetAttribute("TestClearCount", (Object:GetAttribute("TestClearCount") or 0) + 1) end
Rbx.implementMethod("ParticleEmitter", "Clear", _ClearVisual)
Rbx.implementMethod("Trail", "Clear", _ClearVisual)
--[[
	新增事件替身與連線清單；新增物件時由測試明確發送事件。
]]
local _EffectSignal, _EffectConnections = {}, {}
--[[
	模擬 Workspace.DescendantAdded 訂閱。
	@param self 訊號替身。
	@param Callback 新增物件的回呼。
	@return 可解除的連線。
]]
function _EffectSignal.Connect(self, Callback)
	local Connection = { Callback = Callback, bConnected = true }
	--[[
		解除這個特效監聽器。
		@param self 連線。
	]]
	function Connection.Disconnect(self) self.bConnected = false end
	table.insert(_EffectConnections, Connection)
	return Connection
end
--[[
	提供 Lune 未實作的 Workspace 新增事件。
	@param WorldObject Workspace 實例。
	@return 測試事件替身。
]]
Rbx.implementProperty("Workspace", "DescendantAdded", function(WorldObject) return _EffectSignal end)
local Humanoid = _Object("Humanoid", "Humanoid", Character)
Humanoid.Health = 100
Humanoid.HipHeight = 2
--[[
	以水平地面替身驗證有地面才移動，正式腳本保留原生 Raycast。
	@param self Workspace。
	@param Origin 光線起點。
	@param Direction 含偵測長度的方向。
	@param Params 排除角色與目標的查詢參數。
	@return 水平地面命中；模擬未載入時為 nil。
]]
Rbx.implementMethod("Workspace", "Raycast", function(self, Origin, Direction, Params)
	assert(Params.IgnoreWater and Params.RespectCanCollide and #Params.FilterDescendantsInstances == 2)
	return if _bGround then { Position = Rbx.Vector3.new(Origin.X, 0, Origin.Z), Normal = Rbx.Vector3.yAxis } else nil
end)
local PlayerData = _Object("Folder", "PlayerData")
PlayerData:SetAttribute("CashNumber", 1000)
PlayerData:SetAttribute("GemsNumber", 1000)
PlayerData:SetAttribute("FoodNumber", 1000)
local Player = { UserId = 42, Character = Character }
_Environment.NativePlayerScripts = _Object("Folder", "PlayerScripts")
do
	local Folder = _Object("Folder", "Player", _Environment.NativePlayerScripts)
	_Environment.AutoRejoinScript = _Object("LocalScript", "AutoRejoinClient", Folder)
	_Environment.AntiIdleScript = _Object("LocalScript", "AntiIdleClient", NativePlayerGui)
	_Environment.AutoRejoinScript.Enabled, _Environment.AntiIdleScript.Enabled = true, true
end
--[[
	讀取測試玩家屬性。
	@param self 玩家替身。
	@param Name 屬性名稱。
	@return 屬性值，未設定時為 nil。
]]
function Player.GetAttribute(self, Name) return PlayerData:GetAttribute(Name) end
--[[ @param self 玩家替身。 @return 原始玩家屬性供收入診斷篩選。 ]]
function Player.GetAttributes(self) return PlayerData:GetAttributes() end
--[[
	回傳背包；測試不提供既有釣魚 UI。
	@param self 玩家替身。
	@param Name 要查找的容器。
	@return Backpack 或 nil。
]]
function Player.FindFirstChild(self, Name)
	return if Name == "Backpack" then Backpack elseif Name == "PlayerGui" then NativePlayerGui
		elseif Name == "PlayerScripts" then _Environment.NativePlayerScripts else nil
end
--[[
	模擬原生裝備工具的搬移語意。
	@param self Humanoid。
	@param Tool 要裝備的 Tool。
]]
Rbx.implementMethod("Humanoid", "EquipTool", function(self, Tool)
	for _, Child in Character:GetChildren() do if Child:IsA("Tool") then Child.Parent = Backpack end end
	Tool.Parent = Character
end)
--[[
	模擬原生解除工具。
	@param self Humanoid。
]]
Rbx.implementMethod("Humanoid", "UnequipTools", function(self)
	for _, Child in Character:GetChildren() do if Child:IsA("Tool") then Child.Parent = Backpack end end
end)
local WeakRod = _Object("Tool", "WeakRod", Character)
WeakRod:SetAttribute("IsFishingRod", true)
WeakRod:SetAttribute("RodStrength", 1)
local BestRod = _Object("Tool", "BestRod", Backpack)
BestRod:SetAttribute("IsFishingRod", true)
BestRod:SetAttribute("RodStrength", 100)
local Potion = _Object("Tool", "Cash Potion Lvl. 1", Backpack)
Potion:SetAttribute("PotionKey", "Cash_L1")
local Pond = _Object("Part", "PONDAREA1", World)
Pond.CFrame, Pond.Size = Rbx.CFrame.new(900, -1, -5), Rbx.Vector3.new(20, 2, 20)
local LockedPond = _Object("Part", "PONDAREA2", World)
LockedPond.CFrame, LockedPond.Size = Rbx.CFrame.new(0, -1, -5), Rbx.Vector3.new(20, 2, 20)
local Plots = _Object("Folder", "PlayerPlots", World)
local OwnPlot = _Object("Model", "OwnPlot", Plots)
OwnPlot:SetAttribute("OwnerUserId", 42)
local OtherPlot = _Object("Model", "OtherPlot", Plots)
OtherPlot:SetAttribute("OwnerUserId", 99)
local OwnPart = _Object("Part", "Stand", OwnPlot)
OwnPart.CFrame = Rbx.CFrame.new()
local OwnPrompt = _Object("ProximityPrompt", "LevelUpPrompt", OwnPart)
OwnPrompt:SetAttribute("PromptType", "LevelUp")
OwnPrompt:SetAttribute("StandId", "1")
OwnPrompt:SetAttribute("ServerEnabled", true)
OwnPrompt.MaxActivationDistance = 10
local OwnModel = _Object("Model", "WeakCharacter", OwnPlot)
OwnModel:SetAttribute("IsPlacedCharacter", true)
OwnModel:SetAttribute("StandId", "1")
OwnModel:SetAttribute("CharacterName", "HomeWeak")
OwnModel:SetAttribute("CharacterType", "")
OwnModel:SetAttribute("CPS", 10)
OwnModel:SetAttribute("Rarity", "Common")
OwnModel:SetAttribute("Level", 1)
local SecondPart = _Object("Part", "SecondStand", OwnPlot)
SecondPart.CFrame = Rbx.CFrame.new(20, 0, 0)
local SecondPrompt = _Object("ProximityPrompt", "LevelUpPrompt", SecondPart)
SecondPrompt:SetAttribute("PromptType", "LevelUp")
SecondPrompt:SetAttribute("StandId", "2")
SecondPrompt:SetAttribute("ServerEnabled", true)
local SecondModel = _Object("Model", "StrongCharacter", OwnPlot)
SecondModel:SetAttribute("IsPlacedCharacter", true)
SecondModel:SetAttribute("StandId", "2")
SecondModel:SetAttribute("CharacterName", "HomeStrong")
SecondModel:SetAttribute("CharacterType", "")
SecondModel:SetAttribute("CPS", 100)
SecondModel:SetAttribute("Rarity", "Rare")
SecondModel:SetAttribute("Level", 1)
local OwnMaxPrompt = _Object("ProximityPrompt", "MaxLevelUpPrompt", OwnPart)
OwnMaxPrompt:SetAttribute("PromptType", "MaxLevelUp")
OwnMaxPrompt:SetAttribute("StandId", "1")
OwnMaxPrompt:SetAttribute("ServerEnabled", true)
local SecondMaxPrompt = _Object("ProximityPrompt", "MaxLevelUpPrompt", SecondPart)
SecondMaxPrompt:SetAttribute("PromptType", "MaxLevelUp")
SecondMaxPrompt:SetAttribute("StandId", "2")
SecondMaxPrompt:SetAttribute("ServerEnabled", true)
local Garden = _Object("Model", "Garden1", OwnPlot)
local Food = _Object("Model", "Food", Garden)
Food:SetAttribute("FoodValue", 100)
local FoodPart = _Object("Part", "PROMPT", Food)
FoodPart.CFrame = Rbx.CFrame.new(1000, 0, 0)
local FoodPrompt = _Object("ProximityPrompt", "Pickup", FoodPart)
FoodPrompt:SetAttribute("OwnerUserId", 42)
local OtherPart = _Object("Part", "Stand", OtherPlot)
local OtherPrompt = _Object("ProximityPrompt", "LevelUpPrompt", OtherPart)
OtherPrompt:SetAttribute("PromptType", "LevelUp")
local BuildButtons = _Object("Folder", "UnlockButtons", OwnPlot)
local OtherBuildButtons = _Object("Folder", "UnlockButtons", OtherPlot)
--[[
	建立與快照相同的原生建築購買按鈕欄位。
	@param Name 按鈕名稱。
	@param Cost 原始費用字串。
	@param Parent 地塊的 UnlockButtons。
	@return 建築按鈕模型。
]]
local function _BuildButton(Name, Cost, Parent)
	local Button = _Object("Model", Name, Parent)
	for Key, Value in { Cost = Cost, CostType = "Cash", DevID = "", PurchaseStructure = Name, StructureDepend = "" } do
		_Object("StringValue", Key, Button).Value = Value
	end
	_Object("BoolValue", "IsPaid", Button).Value = false
	_Object("BoolValue", "RebirthNeeded", Button).Value = false
	_Object("StringValue", "RebirthCost", Button).Value = "0"
	_Object("BoolValue", "TimeNeeded", Button).Value = false
	local DisplayTimer = _Object("Part", "DisplayTimer", Button)
	_Object("BillboardGui", "BillboardGui", DisplayTimer).Enabled = false
	local Touch = _Object("Part", "Touch", Button)
	Touch.CFrame, Touch.CanTouch, Touch.Transparency = Rbx.CFrame.new(300, 0, 0), true, 0
	return Button
end
local CheapBuilding = _BuildButton("CheapBuilding", "10", BuildButtons)
local ExpensiveBuilding = _BuildButton("ExpensiveBuilding", "1K", BuildButtons)
local PaidBuilding = _BuildButton("PaidBuilding", "0", BuildButtons)
PaidBuilding.IsPaid.Value = true
local DevBuilding = _BuildButton("DevBuilding", "0", BuildButtons)
DevBuilding.DevID.Value = "3558763342"
local GemBuilding = _BuildButton("GemBuilding", "0", BuildButtons)
GemBuilding.CostType.Value = "Gems"
local UnknownBuilding = _BuildButton("UnknownBuilding", "1UNKNOWN", BuildButtons)
local HiddenBuilding = _BuildButton("HiddenBuilding", "0", BuildButtons)
HiddenBuilding.Touch.Transparency = 1
local OtherBuilding = _BuildButton("OtherBuilding", "0", OtherBuildButtons)
local ConstructingBuilding = _BuildButton("ConstructingBuilding", "0", BuildButtons)
ConstructingBuilding.DisplayTimer.BillboardGui.Enabled = true
local RebirthBuilding = _BuildButton("RebirthBuilding", "0", BuildButtons)
RebirthBuilding.RebirthNeeded.Value, RebirthBuilding.RebirthCost.Value = true, "150"
local _bBuildAccept, _bBuildTouchError = true, false
local WorkerPurchases = _Object("Folder", "Purchases", OwnPlot)
local WorkerSites, WorkerPrompts, WorkerStates, WorkerTools = {}, {}, {}, {}
local _WorkerHoldDelay, _bWorkerHoldAccept, _WorkerPendingHold = 0, true, nil
--[[
	回歸模式下依真正的第一個手持 Tool 更新提示，模擬原生裝備同步。
]]
local _bWorkerPromptTracksTool = false
local WorkerRates = { ["C|WorkerA|"] = 100, ["C|WorkerB|"] = 300, ["C|WorkerC|"] = 50 }
for _, Name in { "Lemon Stand", "Strawberry Stand", "Fishing Dock", "Garden1" } do
	local Building = if Name == "Garden1" then Garden else _Object("Folder", Name)
	local Anchor = if Name == "Garden1" then _Object("Part", "PROMPT", Building) else _Object("Part", "Torso", _Object("Model", "CharacterPlace", Building))
	Anchor.CFrame = Rbx.CFrame.new(400, 0, 0)
	local Prompt = _Object("ProximityPrompt", "ProximityPrompt", Anchor)
	Prompt.ActionText, Prompt.Enabled = "Place", true
	Prompt:SetAttribute("OwnerUserId", 99)
	WorkerSites[Name], WorkerPrompts[Name], WorkerStates[Name] = Building, Prompt, {}
end
local Worlds = _Object("Folder", "WorldsFolder", World)
local Research = _Object("Model", "Research", Worlds)
local Nodes = _Object("Folder", "Nodes", Research)
local ResearchA = _Object("Part", "A", Nodes)
ResearchA.CFrame = Rbx.CFrame.new(-500, 0, 0)
ResearchA:SetAttribute("CostCash", 10)
local ResearchB = _Object("Part", "B", Nodes)
ResearchB.CFrame = Rbx.CFrame.new(-520, 0, 0)
ResearchB:SetAttribute("Requires", "A")
ResearchB:SetAttribute("CostCash", 1)
--[[
	研究資料替身獨立於 WorldsFolder 串流場景，僅在對應回歸情境啟用。
]]
local _bResearchMetadata, _ResearchCallback = false, nil
local WorldNodeInfo = _Object("Folder", "WorldNodeInfo")
local ResearchDefinitions = _Object("Folder", "Research", WorldNodeInfo)
for _, Record in { { "Center", "Start Research", 0 }, { "B1", "Rich", 10 }, { "A1", "Potion Shop Luck", 1 }, { "B2", "Auto Spin", 20 } } do
	local Definition = _Object("Configuration", Record[1], ResearchDefinitions)
	Definition:SetAttribute("DisplayName", Record[2])
	Definition:SetAttribute("CostCash", Record[3])
	Definition:SetAttribute("CostGems", 0)
	if Record[1] ~= "Center" then Definition:SetAttribute("SnapTo", "Center") end
end
--[[
	可調整的伺服器回應，測試資源限制與狀態變化。
]]
local _RodState = { owned = { BestRod = true }, rebirths = 11, sacrifices = 0,
	unlock = { Material = { cash = 100, ready = false, materials = { { need = 2, deposited = 0, have = 0 } } } } }
local _Responses = {
	FishingStoreGetState = { _RodState }, FishingStorePurchase = { true },
	RebirthPurchase = { true }, BoostsStoreGetState = { { stock = { Offer1 = 2, Offer2 = 2 } } },
	SecretStoreGetState = { { despawnAt = 0, serverTime = 100, offers = {} } }, SecretStorePurchase = { true },
	SecretStore2GetState = { { despawnAt = 0, serverTime = 100, offers = {} } }, SecretStore2Purchase = { true },
	SecretStore3GetState = { { active = false, timed = true, despawnAt = 0, serverTime = 100, offers = {} } }, SecretStore3Purchase = { true },
	SecretStore4GetState = { { active = false, timed = true, despawnAt = 0, serverTime = 100, offers = {} } }, SecretStore4Purchase = { true },
	RebirthGetState = { { currentRankName = "Rank11", nextRankName = "Rank12", nextCostText = "1000" } },
	BoostsStorePurchase = { true }, PotionGetState = { { serverTime = 100, potions = {} } }, PotionUse = { true },
	ResearchGetData = { { owned = {}, active = {}, slots = 1 } }, ResearchStart = { { ok = true } },
	UpgradesStoreGetState = { { levels = { Expensive = 0, Cheap = 0 } } }, UpgradesStorePurchase = { true },
	BackpackSellRarityRequest = { { ok = true, sold = 2 } },
	BackpackCharSummaryGet = { {
		["C|Eligible||L3"] = { n = "Eligible", ra = "Common", c = 1 },
		["C|Favorite|"] = { n = "Favorite", ra = "Common", c = 1 },
		["C|Equipped|"] = { n = "Equipped", ra = "Common", c = 1 },
		["C|Unselected|"] = { n = "Unselected", ra = "God", c = 1 },
		["T|Rod"] = { n = "Rod", ra = "Common", c = 1 },
	} },
	BackpackGetFavorites = { { ["C|Favorite|"] = true } },
	BackpackGetEquippedState = { { equipped = { { key = "C|Equipped|" } } } },
	BackpackSellSelectedRequest = { { ok = true } },
	QuestGetState = { { claimableCount = 0 } }, QuestClaimAll = { { ok = true } },
	IndexGetData = { { unlockedKeys = {}, claimedKeys = {} } }, IndexClaimAllRewards = { { ok = true } },
	GetDailyRewardsState = { { totalDays = 7, unlockedDay = 0, claimedMask = 0 } }, ClaimDailyReward = { { ok = true } },
	GetPlaytimeRewardsState = { { totalRewards = 3, rewardStates = {} } }, ClaimPlaytimeReward = { { ok = true } },
	InboxGet = { { ready = true, list = {} } }, InboxClaim = { { got = {}, owned = {}, failed = 0 } },
	MedalQuestGet = { { eligible = false } }, MedalQuestClaim = { { ok = true } },
	NpcQuestGetState = { { claimed = false, locked = false, progress = {}, deposits = {} } },
	NpcQuestClaim = { { claimed = true } },
	GetWelcomeOfflineState = { { totalBase = 0, hasAny = false } }, FinalizeWelcomeOffline = { true },
	LeaveOfferState = { { claimed = true } }, LeaveOfferClaim = { { ok = true } },
	CaseSummaryGet = { {} }, CaseOpenRequest = { { ok = true } },
	LemonGetStandState = { WorkerStates["Lemon Stand"] }, StrawberryGetStandState = { WorkerStates["Strawberry Stand"] },
	FishingDockGetState = { WorkerStates["Fishing Dock"] }, GardenGetFarmingState = { { Garden1 = WorkerStates.Garden1 } },
}
local Constants = {
	Crates = { CaseItems = { BatchSize = 5 } },
	SecretStore = { Offers = {} },
	NumberSuffixes = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx" },
	RarityOrder = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythical", "Cosmic", "Secret", "Rainbow",
		"Ascended", "Divine", "Supreme", "Celestial", "Ancient", "God", "Omniscient", "Apex", "Transcendent", "Exclusive" },
	Rarities = { Common = {}, Exclusive = {} },
	Fishing = { Ponds = { PONDAREA1 = { RequiredStrength = 0 }, PONDAREA2 = { RequiredStrength = 1000 } }, Distances = { MaxStartDistance = 50 },
		Rods = { BestRod = { Strength = 100 }, Weak = { Strength = 50 }, Medium = { Strength = 150 }, Good = { Strength = 200 },
			Expensive = { Strength = 300 }, Locked = { Strength = 500 }, Material = { Strength = 600 }, Sacrifice = { Strength = 700 }, Held = { Strength = 900 } } },
	FishingStore = { Offers = {
		Weak = { RodName = "Weak", CashCost = 1 }, Medium = { RodName = "Medium", CashCost = 900 },
		Good = { RodName = "Good", CashCost = 500 }, Expensive = { RodName = "Expensive", CashCost = 2000 },
		Locked = { RodName = "Locked", CashCost = 100, RebirthRequired = 99 },
		Material = { RodName = "Material", CashCost = 100, Materials = { { Key = "Ore", Amount = 2 } } },
		Sacrifice = { RodName = "Sacrifice", CashCost = 100, SacrificeRequired = 2 }, Held = { RodName = "Held", CashCost = 10 },
	} },
	Potions = { Definitions = { Cash_L1 = { ToolName = Potion.Name }, Luck_L1 = { ToolName = "Luck" } } },
	BoostsStore = { Offers = {
		Offer1 = { PotionKey = "Cash_L1", Currency = "Cash", CashCost = 10 },
		Offer2 = { PotionKey = "Luck_L1", Currency = "Gems", GemsCost = 10 },
	} },
	UpgradesStore = { Offers = {
		Expensive = { MaxLevels = 10, CostBase = 100, CostScale = 2 },
		Cheap = { MaxLevels = 2, Costs = { 5, 15 } },
	} },
}
--[[
	提供遊戲原生需求查詢替身，驗證入口沿用其獻祭相關判斷。
	@param Offer 魚竿商品設定。
	@param Sacrifices 目前獻祭次數。
	@return 該商品所需轉生次數。
]]
function Constants.GetRodRebirthRequired(Offer, Sacrifices)
	assert(type(Sacrifices) == "number")
	return tonumber(Offer.RebirthRequired) or 0
end
--[[
	遠端替身的集合，FishingState 額外保存事件回呼。
]]
local _Remotes, _FishingCallback, _Connection = {}, nil, { bConnected = true }
--[[
	提供角色下一級成本替身。
	@param Rarity 角色品質。
	@param Level 目前等級。
	@return 該角色升一級成本。
]]
function Constants.GetLevelUpCost(Rarity, Level)
	assert(type(Level) == "number")
	return if Rarity == "Common" then 10 else 20
end
--[[
	提供已確認的原生攤位變異倍率替身。
	@param TypeName 變異名稱。
	@return Gems 倍率。
]]
function Constants.GetTypeGemMultiplier(TypeName) return if TypeName == "Gold" then 2 else 1 end
--[[
	解除測試事件。
	@param self 連線替身。
]]
function _Connection.Disconnect(self) self.bConnected = false end
for _, Name in { "FishingState", "FishingRequestStart", "FishingClick", "FishingCancel", "BackpackEquipBest",
	"SecretStoreGetState", "SecretStorePurchase",
	"SecretStore2GetState", "SecretStore2Purchase", "SecretStore3GetState", "SecretStore3Purchase", "SecretStore4GetState", "SecretStore4Purchase",
	"RebirthPurchase", "RebirthGetState", "BoostsStoreGetState", "BoostsStorePurchase", "PotionGetState", "PotionUse",
	"ResearchGetData", "ResearchStart", "ResearchUpdate", "UpgradesStoreGetState", "UpgradesStorePurchase", "BackpackSellRarityRequest",
	"BackpackCharSummaryGet", "BackpackGetFavorites", "BackpackGetEquippedState", "BackpackSellSelectedRequest",
	"FishingStoreGetState", "FishingStorePurchase", "QuestGetState", "QuestClaimAll", "IndexGetData", "IndexClaimAllRewards",
	"GetDailyRewardsState", "ClaimDailyReward", "GetPlaytimeRewardsState", "ClaimPlaytimeReward", "InboxGet", "InboxClaim",
	"MedalQuestGet", "MedalQuestClaim", "NpcQuestGetState", "NpcQuestClaim", "GetWelcomeOfflineState", "FinalizeWelcomeOffline",
	"LeaveOfferState", "LeaveOfferClaim", "CaseSummaryGet", "CaseOpenRequest", "BackpackEquipCharacter", "BackpackHoldCharacter",
	"LemonGetStandState", "StrawberryGetStandState", "FishingDockGetState", "GardenGetFarmingState",
	"LemonUnequipChar", "FishingDockUnequipChar", "GardenUnequipChar" } do
	local Remote = { Name = Name }
	--[[
		檢查遠端類別。
		@param self 遠端替身。
		@param ClassName 期望類別。
		@return true 類別符合；false 不符合。
	]]
	function Remote.IsA(self, ClassName) return ClassName == (if _Responses[self.Name] then "RemoteFunction" else "RemoteEvent") end
	--[[
		保存遠端發送的實際參數。
		@param self 遠端替身。
		@param ... 封包參數。
	]]
	function Remote.FireServer(self, ...) table.insert(_Calls, { Name = self.Name, Args = table.pack(...), Position = Root.CFrame.Position }) end
	--[[
		保存 RPC 並提供可調整回應。
		@param self 遠端替身。
		@param ... 封包參數。
		@return 預先設定的多回傳值。
	]]
	function Remote.InvokeServer(self, ...)
		self:FireServer(...)
		return table.unpack(_Responses[self.Name])
	end
	_Remotes[Name] = Remote
end
--[[
	模擬原生拿起角色；展台裝備 Remote 不會產生手持工具。
	@param self 拿起 RemoteEvent。
	@param Key 原始角色鍵。
]]
function _Remotes.BackpackHoldCharacter.FireServer(self, Key)
	table.insert(_Calls, { Name = self.Name, Args = table.pack(Key) })
	if Key == "" then _WorkerPendingHold = nil return end
	assert(WorkerTools[Key], "測試缺少角色工具")
	if not _bWorkerHoldAccept then return end
	if _WorkerHoldDelay > 0 then _WorkerPendingHold = { Key = Key, At = _Now + _WorkerHoldDelay }
	else Humanoid:EquipTool(WorkerTools[Key]) end
end
--[[
	卸下工作角色並更新原生狀態替身。
	@param Name 工作建築名稱。
]]
local function _UnequipWorker(Name)
	table.clear(WorkerStates[Name])
	WorkerPrompts[Name].ActionText = "Place"
end
--[[
	記錄攤位卸下的 standKey。
	@param self 遠端。
	@param Key 原生 standKey。
]]
function _Remotes.LemonUnequipChar.FireServer(self, Key)
	table.insert(_Calls, { Name = self.Name, Args = table.pack(Key) })
	_UnequipWorker(if Key == "LemonStand" then "Lemon Stand" else "Strawberry Stand")
end
--[[
	記錄無參數 Dock 卸下。
	@param self 遠端。
]]
function _Remotes.FishingDockUnequipChar.FireServer(self)
	table.insert(_Calls, { Name = self.Name, Args = table.pack() })
	_UnequipWorker("Fishing Dock")
end
--[[
	記錄菜園卸下的 gardenKey。
	@param self 遠端。
	@param Key 菜園鍵。
]]
function _Remotes.GardenUnequipChar.FireServer(self, Key)
	table.insert(_Calls, { Name = self.Name, Args = table.pack(Key) })
	_UnequipWorker(Key)
end
_Remotes.FishingState.OnClientEvent = {}
--[[
	記錄事件回呼。
	@param self 訊號替身。
	@param Callback 釣魚事件處理器。
	@return 連線替身。
]]
function _Remotes.FishingState.OnClientEvent.Connect(self, Callback) _FishingCallback = Callback; return _Connection end
_Remotes.ResearchUpdate.OnClientEvent = {}
--[[
	保留個人研究更新事件處理器。
	@param self 研究更新訊號。
	@param Callback 原生研究資料回呼。
	@return 由卸載清理的連線替身。
]]
function _Remotes.ResearchUpdate.OnClientEvent.Connect(self, Callback) _ResearchCallback = Callback; return _Connection end
local Remotes = {}
--[[
	查找遠端替身。
	@param self 遠端容器。
	@param Name 遠端名稱。
	@return 對應遠端或 nil。
]]
function Remotes.FindFirstChild(self, Name) return _Remotes[Name] end
local Storage = {}
local Module = _Object("ModuleScript", "Constants")
local Modules = _Object("Folder", "Modules")
local StreamModule = _Object("ModuleScript", "WorldStream", Modules)
local UpdateGateModule = _Object("ModuleScript", "UpdateGate", Modules)
local NpcQuestsModule = _Object("ModuleScript", "NpcQuests", Modules)
local NpcQuests = { Quests = {
	A = { Tasks = { { Id = "Feed", Goal = 10 } }, Characters = { { Name = "Goka", Count = 2 } }, GemCost = 0 },
	B = { Tasks = { { Id = "Feed", Goal = 20 } }, GemCost = 0 },
	C = { Tasks = { { Id = "Feed", Goal = 1 } }, GemCost = 0 },
	D = { Tasks = { { Id = "Feed", Goal = 1 } }, GemCost = 0 },
	Paid = { Tasks = {}, GemCost = 10 },
	Evolution = { Tasks = {}, Evolution = "Evolved Goka", GemCost = 0 },
} }
local _HeldOffers = { Held = true }
local UpdateGate = {}
--[[
	模擬遊戲依版本暫停商品販售。
	@param Store 商品所屬商店。
	@param Key 商品鍵。
	@return true 不可購買；false 已開放。
]]
function UpdateGate.IsOfferHeld(Store, Key) assert(Store == "FishingStore" or Store == "SecretStore"); return _HeldOffers[Key] == true end
local WorldStream = {}
--[[
	記錄遊戲場景保留參考。
	@param Name 場景名稱。
	@param Owner 本腳本專屬參考名稱。
]]
function WorldStream.Acquire(Name, Owner) table.insert(_StreamCalls, { "Acquire", Name, Owner }) end
--[[
	記錄釋放自己的場景參考。
	@param Name 場景名稱。
	@param Owner 本腳本專屬參考名稱。
]]
function WorldStream.Release(Name, Owner) table.insert(_StreamCalls, { "Release", Name, Owner }) end
--[[
	提供遊戲模組容器。
	@param self 服務替身。
	@param Name 容器名稱。
	@return Modules 或 nil。
]]
function Storage.FindFirstChild(self, Name)
	return if Name == "Modules" then Modules elseif Name == "WorldNodeInfo" and _bResearchMetadata then WorldNodeInfo else nil
end
--[[
	提供入口的已載入相依物件。
	@param self 儲存服務替身。
	@param Name 子物件名稱。
	@param Timeout 原本等待秒數，本替身不等待。
	@return 遠端容器或 Constants ModuleScript。
]]
function Storage.WaitForChild(self, Name, Timeout) return if Name == "Remotes" then Remotes else Module end
local Window = { ScreenGui = _Object("ScreenGui", "TestUI", HiddenUI) }
--[[
	記錄原生 NavigationBar 分頁歸屬，供既有 UI 接合驗證使用。
	@param self 視窗。
	@param Name 分頁名稱。
	@param Icon 圖示名稱。
	@return 有獨立區塊清單的分頁替身。
]]
function Window.CreateTab(self, Name, Icon)
	assert(self == Window, "CreateTab 必須由 Window 呼叫")
	local Tab = setmetatable({ Name = Name, Icon = Icon, Kind = "Tab", Sections = {} }, { __index = Window })
	table.insert(Window.Tabs, Tab)
	return Tab
end
--[[
	保留 Section Card 的分頁、標題與控制項歸屬。
	@param self 所屬分頁。
	@param Options 區塊設定。
	@return Card 替身。
]]
function Window.CreateSection(self, Options)
	assert(self.Kind == "Tab", "CreateSection 必須由 Tab 呼叫")
	local Section = setmetatable({ Name = Options.Name, Tab = self, Side = Options.Side, CardControls = {} }, { __index = Window })
	table.insert(self.Sections, Section)
	return Section
end
--[[
	保存控制項回呼及顯示值。
	@param self UI 容器。
	@param Options 控制項設定或標籤字串。
	@return 可更新值的控制項。
]]
local function _Control(self, Options)
	local Value = if type(Options) == "string" then Options else Options.CurrentOption
	if type(Options) == "table" and Options.CurrentValue ~= nil then Value = Options.CurrentValue end
	if type(Options) == "table" and Options.bCurrentValue ~= nil then Value = Options.bCurrentValue end
	local Flag = type(Options) == "table" and Options.Flag or nil
	if Flag and Window.SavedFlags and Window.SavedFlags[Flag] ~= nil then Value = Window.SavedFlags[Flag] end
	if type(Value) == "table" then Value = table.clone(Value) end
	local Apply = type(Options) == "table" and Options.Callback or nil
	local Control = { Options = Options, Value = Value, Flag = Flag, Section = self,
		Frame = _Object("Frame", "Control", Window.ScreenGui) }
	assert(self.CardControls, "控制項必須建立在 Card 內")
	table.insert(self.CardControls, Control)
	if type(Options) == "string" then table.insert(_Labels, Control) end
	--[[
		更新顯示值，不隱含觸發回呼。
		@param self 控制項。
		@param Value 新值。
		@param bSilent true 不呼叫設定回呼。
	]]
	function Control.Set(self, Value, bSilent)
		self.Value = if type(Value) == "table" then table.clone(Value) else Value
		if self.Flag and not Window.bLoading then Window.SaveAt = _Now + 1.5 end
		if not bSilent and Apply then Apply(self.Value) end
	end
	--[[
		取得靜默恢復後的值。
		@param self 控制項。
		@return 控制項值；多選回傳副本。
	]]
	function Control.Get(self) return if type(self.Value) == "table" then table.clone(self.Value) else self.Value end
	--[[ @param self 控制項。 @param bEnabled 邊界按鈕是否可操作。 ]]
	function Control.SetEnabled(self, bEnabled) self.bEnabled = bEnabled return self end
	if type(Options) == "table" then
		Options.Control = Control
		_Controls[Options.Name or Options.Title] = Options
		if Apply then
			--[[
				模擬使用者改值時先提交元件、再呼叫回呼的 UI 順序。
				@param NewValue 使用者設定的新值。
			]]
			Options.Callback = function(NewValue) Control:Set(NewValue) end
		end
	end
	if Flag then Window.Controls[Flag] = Control end
	return Control
end
Window.CreateToggle, Window.CreateLabel, Window.CreateParagraph, Window.CreateButton = _Control, _Control, _Control, _Control
Window.CreateDropdown = _Control
Window.CreateInput = _Control
--[[ @param self Card。 @param Options 按鈕設定。 @return 改名不觸發點擊回呼的原生按鈕替身。 ]]
function Window.CreateButton(self, Options)
	local Callback = Options.Callback
	local Control = _Control(self, Options)
	--[[ @param self 按鈕。 @param Value 僅更新按鈕文字。 ]]
	function Control.Set(self, Value) self.Value = Value end
	Options.Callback = Callback
	return Control
end
Window.CreateSlider = _Control
--[[
	保留段落雙參數 Set 的正式語意，讓多研究倒數內文可被驗證。
	@param self UI 卡片。
	@param Options 段落標題與內文。
	@return 段落替身。
]]
function Window.CreateParagraph(self, Options)
	local Control = _Control(self, Options)
	Control.Content = Options.Content
	--[[
		同步段落標題與內文。
		@param self 段落替身。
		@param Title 新標題。
		@param Body 新內文。
	]]
	function Control.Set(self, Title, Body) self.Value, self.Content = Title, Body end
	return Control
end
--[[
	模擬共用 UI 的合併保存 API，保留未知 Flag 及其他分組。
	@param self 視窗。
	@return true 已保存；false 停用或模擬讀寫失敗。
	@return 保存路徑或具體錯誤。
]]
function Window.SaveConfiguration(self)
	self.SaveAt = nil
	if not self.bConfigEnabled then return false, "disabled" end
	if _bConfigReadError or _bConfigWriteError then
		self.LastConfigError = if _bConfigReadError then "corrupt configuration" else "write failed"
		return false, self.LastConfigError
	end
	local Values = table.clone(self.SavedFlags or {})
	for Flag, Control in self.Controls do Values[Flag] = Control:Get() end
	_ConfigDatabase[self.ConfigId] = { Flags = Values }
	self.LastConfigError = nil
	_SaveCount += 1
	return true, "BjzUi/FishAnAnimeRng/FishAnAnimeRng_74729868188364.json"
end
--[[
	模擬靜默載入已保存的 Flag；不發送回呼或啟動任何遊戲工作。
	@param self 視窗。
	@param bSilent true 靜默恢復。
	@return true 找到設定；false 沒有設定或讀取失敗。
	@return 失敗原因；成功時為 nil。
]]
function Window.LoadConfiguration(self, bSilent)
	assert(bSilent == true, "入口必須先靜默載入再統一同步狀態")
	if _bConfigReadError then return false, "corrupt configuration" end
	local Saved = _ConfigDatabase[self.ConfigId]
	if not Saved then return false, "找不到此 ConfigId 的設定。" end
	self.bLoading = true
	for Flag, Value in Saved.Flags do if self.Controls[Flag] then self.Controls[Flag]:Set(Value, true) end end
	self.bLoading = false
	return true, nil
end
--[[
	模擬可重複呼叫的視窗卸載。
	@param self 視窗。
]]
function Window.Unload(self)
	if self.bDestroyed then return end
	self:SaveConfiguration()
	self.bDestroyed = true
	self.OnUnload()
	self.ScreenGui:Destroy()
end
local Library = { ConfigurationVersion = 2 }
--[[
	保存視窗卸載回呼。
	@param self UI 函式庫。
	@param Options 視窗設定。
	@return 視窗替身。
]]
function Library.CreateWindow(self, Options)
	assert(Options.GameName == "FishAnAnimeRng" and Options.GameId == 74729868188364)
	assert(Options.DefaultFlags.bAutoFish and Options.DefaultFlags.bAutoRebirth and Options.DefaultUI.Tab)
	-- 此整合測試自行控制開關；正式預設值的還原流程由 BjzUiConfiguration 測試驗證。
	Window.Tabs = {}
	Window.OnUnload, Window.ConfigId = Options.OnUnload, Options.ConfigId
	Window.bConfigEnabled, Window.Controls, Window.SaveAt = Options.ConfigurationSaving.bEnabled, {}, nil
	Window.LastConfigError = if _bConfigReadError then "corrupt configuration" else nil
	Window.SavedFlags = if not _bConfigReadError and _ConfigDatabase[Options.ConfigId] then _ConfigDatabase[Options.ConfigId].Flags else {}
	return Window
end
local Game = { PlaceId = 74729868188364 }
--[[
	提供遊戲服務替身。
	@param self 遊戲。
	@param Name 服務名稱。
	@return 玩家服務或儲存服務。
]]
function Game.GetService(self, Name)
	if Name == "RunService" then return _Environment.RenderingService end
	if Name == "HttpService" then
		return {
			--[[ @param self 編碼服務替身。 @param Value 原始診斷欄位。 @return JSON 文字。 ]]
			JSONEncode = function(self, Value) return require("@lune/serde").encode("json", Value) end,
		}
	end
	if Name == "CollectionService" then
		return {
			--[[ @param self 標記服務。 @param Tag 標記名稱。 @return 測試可調整的標記物件。 ]]
			GetTagged = function(self, Tag) return (_Environment.PickupTags or {})[Tag] or {} end,
			--[[ @param self 標記服務。 @param Object 物件。 @param Tag 標記名稱。 @return 是否仍具標記。 ]]
			HasTag = function(self, Object, Tag) return table.find((_Environment.PickupTags or {})[Tag] or {}, Object) ~= nil end,
		}
	end
	return if Name == "Players" then { LocalPlayer = Player } else Storage
end
--[[
	保留 URL 以驗證外部載入方式，不存取網路。
	@param self 遊戲。
	@param Url 模組網址。
	@return 同一網址。
]]
function Game.HttpGet(self, Url) return Url end
_Environment.RenderingService = { bEnabled = true, bFail = false, EngineCalls = 0 }
--[[ @param self 渲染服務。 @return 實際成功的狀態。 ]]
function _Environment.RenderingService.Is3dRenderingEnabled(self) return self.bEnabled end
--[[ @param self 渲染服務。 @param bEnabled 目標狀態；失敗不修改值。 ]]
function _Environment.RenderingService.Set3dRenderingEnabled(self, bEnabled)
	assert(not self.bFail, "模擬渲染權限不足")
	self.bEnabled = bEnabled
end
local TestEnvironment = setmetatable({ game = Game, workspace = World, Vector3 = Rbx.Vector3, CFrame = Rbx.CFrame,
	Enum = Rbx.Enum, Instance = Rbx.Instance, UDim2 = Rbx.UDim2, UDim = Rbx.UDim, RaycastParams = {} }, { __index = getfenv() })
--[[ 入口整合只記錄引擎生命週期；正式引擎行為由 PerformanceEngine.spec 驗證。 ]]
_Environment.PerformanceMock = { SafeModeVersion = 1, Starts = 0, Stops = 0 }
--[[ @param Options 引擎初始化選項。 @return 無遊戲副作用的控制器替身。 ]]
function _Environment.PerformanceMock.new(Options)
	assert(Options.bPreserveUi and Options.bDeleteVisuals == false and type(Options.bRenderingEnabled) == "boolean")
	assert(not Options.bDeleteCoreGui and not Options.bDeleteGetHui and Options.ProtectedRoots[1] == Window.ScreenGui)
	local bStopped = false
	local bOriginal = _Environment.RenderingService.bEnabled
	return {
		--[[ @param bEnabled 3D 渲染目標。 @return 是否成功。 @return 失敗原因。 ]]
		SetRenderingEnabled = function(bEnabled)
			_Environment.RenderingService.EngineCalls += 1
			return pcall(_Environment.RenderingService.Set3dRenderingEnabled, _Environment.RenderingService, bEnabled)
		end,
		--[[ 記錄一次啟動。 ]]
		Start = function()
			_Environment.PerformanceMock.Starts += 1
			assert(not _Environment.PerformanceStartError, "模擬效能引擎部分初始化失敗")
			_Environment.RenderingService.bEnabled = Options.bRenderingEnabled
		end,
		--[[ 記錄一次有效卸載。 ]]
		Destroy = function()
			if not bStopped then
				bStopped = true
				_Environment.RenderingService.bEnabled = bOriginal
				_Environment.PerformanceMock.Stops += 1
			end
		end,
	}
end
--[[
	提供可寫入的光線參數替身。
	@return 空白參數表。
]]
function TestEnvironment.RaycastParams.new() return {} end
--[[
	提供執行器共用環境。
	@return 環境表。
]]
function TestEnvironment.getgenv() return _Environment end
--[[
	提供 UI 根容器。
	@return 隱藏容器替身。
]]
function TestEnvironment.gethui() return HiddenUI end
--[[
	模擬原生 Auto Fish 的本地按鈕處理器。
	@param Signal 按鈕訊號。
	@param ... 不應傳入額外參數。
]]
function TestEnvironment.firesignal(Signal, ...)
	assert(Signal == NativeAutoSignal and select("#", ...) == 0)
	table.insert(_Calls, { Name = "NativeAutoFishToggle" })
	if _bIgnoreNativeToggle then return end
	if _NativeToggleDelay > 0 then
		_PendingNativeToggle = { At = _Now + _NativeToggleDelay, bEnabled = not NativeAutoOn.Enabled }
		return
	end
	NativeAutoOn.Enabled = not NativeAutoOn.Enabled
	NativeAutoOff.Enabled = not NativeAutoOn.Enabled
end
--[[
	模擬單一原生 Luau 按鈕處理器，不透過 firesignal 再次觸發其他連線。
]]
local function _NativeButtonCallback()
	table.insert(_Calls, { Name = "NativeAutoFishCallback" })
	if _bIgnoreNativeCallback then return end
	NativeAutoOn.Enabled = not NativeAutoOn.Enabled
	NativeAutoOff.Enabled = not NativeAutoOn.Enabled
end
--[[
	記錄不應被呼叫的連線，用來檢查跳過停用／外部連線及關閉後不再切換。
]]
local function _UnexpectedNativeCallback()
	table.insert(_Calls, { Name = "UnexpectedNativeCallback" })
	error("unexpected native callback")
end
--[[
	提供 sUNC 連線欄位替身，預設不提供可用回呼。
	@param Signal 應為原生 Auto Fish 按鈕訊號。
	@return 目前可用的 Luau／停用／外部連線。
]]
function TestEnvironment.getconnections(Signal)
	assert(Signal == NativeAutoSignal)
	if not _bNativeConnectionsAvailable then return {} end
	return {
		{ Enabled = false, LuaConnection = true, ForeignState = false, Function = _UnexpectedNativeCallback },
		{ Enabled = true, LuaConnection = false, ForeignState = true, Function = _UnexpectedNativeCallback },
		{ Enabled = true, LuaConnection = true, ForeignState = false, Function = _NativeButtonCallback },
		{ Enabled = true, LuaConnection = true, ForeignState = false, Function = _UnexpectedNativeCallback },
	}
end
--[[
	提供檔案能力入口存在性替身；實際保存由上述 UI 記憶體替身模擬。
	@param ... 原始檔案能力參數，此處不執行 I/O。
]]
local function _FileCapability(...) end
TestEnvironment.readfile, TestEnvironment.writefile, TestEnvironment.isfile = _FileCapability, _FileCapability, _FileCapability
TestEnvironment.isfolder, TestEnvironment.makefolder = _FileCapability, _FileCapability
--[[
	回傳遊戲設定，不使用 Executor 的 script 或相對 require。
	@param Value 模組物件。
	@return 遊戲設定表。
]]
function TestEnvironment.require(Value)
	if Value == StreamModule then return WorldStream end
	if Value == UpdateGateModule then return UpdateGate end
	if Value == NpcQuestsModule then return NpcQuests end
	assert(Value == Module)
	return Constants
end
--[[
	回傳 UI 初始化函數。
	@param Url 原始碼網址。
	@return UI 模組工廠。
]]
function TestEnvironment.loadstring(Url)
	if Url:find("Core/Features/PerformanceEngine.luau", 1, true) then
		_Environment.PerformanceLoads = (_Environment.PerformanceLoads or 0) + 1
		--[[ @return 相容且不刪除遊戲物件的引擎替身。 ]]
		return function() return _Environment.PerformanceMock end
	end
	assert(Url:find("raw.githubusercontent.com/tsuykaku/BjzHub/main/Library/BjzUiLibrary_2.0.luau", 1, true))
	--[[
		回傳 UI 替身。
		@return UI 模組。
	]]
	return function() return Library end
end
--[[
	記錄提示觸發，不模擬伺服器接受。
	@param Prompt 實際 ProximityPrompt。
]]
function TestEnvironment.fireproximityprompt(Prompt)
	if _Environment.PairPromptCallback then return _Environment.PairPromptCallback(Prompt) end
	for Name, WorkerPrompt in WorkerPrompts do
		if Prompt == WorkerPrompt then
			local Tool = Character:FindFirstChildOfClass("Tool")
			local Key = nil
			for Candidate, WorkerTool in WorkerTools do if WorkerTool == Tool then Key = Candidate break end end
			assert(Key and Prompt.ActionText == "Place", "只可使用已確認角色工具放置，不可誤觸 Pick Up")
			local State = WorkerStates[Name]
			State.charName, State.charType, State.rarity = Tool:GetAttribute("CharacterName"), Tool:GetAttribute("CharacterType"), Tool:GetAttribute("Rarity")
			State.groupKey, State.standKey = Key, Name:gsub("%s", "")
			if Name == "Garden1" then Garden:SetAttribute("CurrentFoodPerSecond", WorkerRates[Key]) end
			Tool.Parent, Prompt.ActionText = Backpack, "Pick Up"
			table.insert(_Calls, { Name = "WorkerPlace", Args = { Name, Key } })
			return
		end
	end
	table.insert(_Calls, { Name = if Prompt == FoodPrompt then "CollectFood" else "Feed", Args = { Prompt }, Position = Root.CFrame.Position })
	if Prompt == FoodPrompt then
		PlayerData:SetAttribute("FoodNumber", (PlayerData:GetAttribute("FoodNumber") or 0) + 100)
		Food:SetAttribute("FoodPromptParked", true)
	elseif Prompt == OwnPrompt or Prompt == SecondPrompt or Prompt == OwnMaxPrompt or Prompt == SecondMaxPrompt then
		local Cost = _FeedCostOverrides[Prompt] or (if Prompt == OwnPrompt or Prompt == OwnMaxPrompt then 10 else 20)
		local Available = PlayerData:GetAttribute("FoodNumber")
		local Levels = if Prompt:GetAttribute("PromptType") == "MaxLevelUp" then math.floor(Available / Cost) else 1
		assert(Available >= Cost, "不可餵食負擔不起的角色")
		PlayerData:SetAttribute("FoodNumber", Available - Levels * Cost)
	end
end
--[[
	記錄觸碰配對並模擬伺服器移除已購建築按鈕；不代表真實伺服器接受。
	@param Part1 角色根部。
	@param Part2 按鈕 Touch。
	@param State 0 開始；1 結束。
]]
function TestEnvironment.firetouchinterest(Part1, Part2, State)
	if _Environment.MapTouchCallback then return _Environment.MapTouchCallback(Part1, Part2, State) end
	assert(Part1 == Root and Part2.Name == "Touch")
	table.insert(_Calls, { Name = "BuildTouch", Args = { Part1, Part2, State }, Position = Root.CFrame.Position })
	if State == 0 then
		assert(Part2.Parent.Parent == BuildButtons, "不能操作其他玩家的建築")
		if _bBuildTouchError then error("test touch error") end
		if _bBuildAccept then Part2.Parent.Parent = nil end
	end
end
TestEnvironment.os = table.clone(os)
--[[
	提供可控時鐘。
	@return 測試秒數。
]]
function TestEnvironment.os.clock() return _Now end
--[[
	提供可控的原生 Unix 時鐘，驗證 active[].e 倒數而不等待實際時間。
	@return 模擬 Unix 秒數。
]]
function TestEnvironment.os.time() return 1000000 + math.floor(_Now) end
TestEnvironment.task = {}
--[[
	建立可手動推進的 deferred coroutine。
	@param Callback 工作回呼。
	@return 新工作。
]]
function TestEnvironment.task.defer(Callback)
	local Thread = coroutine.create(Callback)
	table.insert(_Tasks, Thread)
	return Thread
end
--[[
	暫停當前工作。
	@param Seconds 原本等待秒數。
]]
function TestEnvironment.task.wait(Seconds)
	if _PendingNativeToggle and _Now >= _PendingNativeToggle.At then
		NativeAutoOn.Enabled, NativeAutoOff.Enabled = _PendingNativeToggle.bEnabled, not _PendingNativeToggle.bEnabled
		_PendingNativeToggle = nil
	end
	if _bWorkerPromptTracksTool and not WorkerStates["Lemon Stand"].charName then
		local Held = Character:FindFirstChildOfClass("Tool")
		WorkerPrompts["Lemon Stand"].ActionText = if Held and Held:GetAttribute("IsCharacterTool") == true then "Place" else "Equip Character First!"
	end
	if _WorkerPendingHold and _Now >= _WorkerPendingHold.At then
		Humanoid:EquipTool(WorkerTools[_WorkerPendingHold.Key])
		_WorkerPendingHold = nil
	end
	-- 模擬原生 StandPromptController：遠處提示停用，到角色旁才啟用。
	for _, Prompt in { OwnPrompt, SecondPrompt, OwnMaxPrompt, SecondMaxPrompt } do
		Prompt.Enabled = Prompt:GetAttribute("ServerEnabled") == true
			and (Root.CFrame.Position - Prompt.Parent.CFrame.Position).Magnitude <= 6
	end
	coroutine.yield()
end
--[[
	取消並關閉等待中的 coroutine。
	@param Thread 工作。
]]
function TestEnvironment.task.cancel(Thread) coroutine.close(Thread) end
--[[
	Lune 沒有 BasePart.Position 的原生衍生 getter，且既有屬性不能覆寫。
	測試僅把兩種位置讀取投影成等價的 CFrame.Position；正式原始碼已單獨編譯。
]]
local TestSource = Source:gsub("Root%.Position", "Root.CFrame.Position"):gsub("Parent%.Position", "Parent.CFrame.Position"):gsub("Object%.Position", "Object.CFrame.Position")
local Controller = Luau.load(TestSource, { environment = TestEnvironment })()
assert(Controller.FeedAction == "全部餵食" and _Controls["餵食方式"].Control:Get() == "全部餵食", "新設定預設全部餵食")
_Controls["餵食方式"].Callback("一個一個餵")
local Scheduler = _Tasks[1]
--[[
	推進排程器與本輪可執行工作一次。
	@param Seconds 前進的模擬秒數。
]]
local function _Step(Seconds)
	_Now += Seconds
	local bOk, Reason = coroutine.resume(Scheduler)
	assert(bOk, tostring(Reason))
	for Index = 2, #_Tasks do
		local Thread = _Tasks[Index]
		if coroutine.status(Thread) == "suspended" then
			local bPassed, Error = coroutine.resume(Thread)
			assert(bPassed, tostring(Error))
		end
	end
	if Window.SaveAt and _Now >= Window.SaveAt and Window.bConfigEnabled then Window:SaveConfiguration() end
end
--[[
	找出最後一次指定操作。
	@param Name 操作名稱。
	@return 操作紀錄，未呼叫時為 nil。
]]
local function _Last(Name)
	for Index = #_Calls, 1, -1 do if _Calls[Index].Name == Name then return _Calls[Index] end end
	return nil
end
--[[
	觸發 UI 開關。
	@param Name 控制項名稱。
	@param bValue 新值。
]]
local function _Toggle(Name, bValue) _Controls[Name].Callback(bValue) end

_Step(0)
assert(#_Calls == 0, "所有功能應預設關閉")
assert(Controller.CharacterPriority == nil and not Window.Controls.CharacterPriority and not _Controls["裝備優先條件"], "固定金錢收益優先，移除裝備品質條件")
assert(not Window.Controls.bQualityEquipAndFeed, "不可再建立額外連動 Toggle")
assert(Controller.bResearchAllowGems and not Controller.bAllowGems and Window.Controls.bResearchAllowGems:Get(),
	"研究預設允許 Gems，不能因此開啟買藥的 Gems 許可")
local IntervalKeys = {}
for Key, Seconds in Controller.Intervals do
	local Slider = Window.Controls[Key .. "_Interval"]
	assert(Slider and Slider:Get() == Seconds and Window.Controls[Key], "每個自動功能都必須有獨立保存 Flag 的間隔滑桿")
	assert(Slider.Options.Range[1] == 0.1 and Slider.Options.Range[2] == 300 and Slider.Options.Increment == 0.01,
		"間隔範圍與精度必須一致")
	table.insert(IntervalKeys, Key)
end
assert(#IntervalKeys == 33 and Controller.Intervals.bAutoFish == 0.72 and Controller.Intervals.bAutoQuestRewards == 15,
	"33 個間隔須完整，舊設定沿用原本預設值")
assert(Controller.Intervals.bDeleteUiEffects == 60)
assert(Controller.Intervals.bAutoMapPickup == 60 and Window.Controls.bAutoMapPickup_Interval:Get() == 60, "地圖拾取新設定預設為60秒")
assert(not _Controls["自動開啟 Auto Fish"] and not Window.Controls.bAutoNativeFish,
	"Auto Fish 不應再有獨立開關或保存控制項")
assert(#Window.Tabs == 7, "功能應分類為七個 NavigationBar 分頁")
local NavigationIcons = { "Home", "People", "Zap", "Potion", "Coin", "TreasureChest", "Settings" }
for Index, Tab in Window.Tabs do
	assert(Tab.Icon == NavigationIcons[Index], "每個導覽 Item 必須使用對應的已收錄圖示")
end
local FeatureCards = {}
for Index, Label in _Labels do
	if Index > 33 then break end
	local Card = Label.Section
	assert(not FeatureCards[Card], "每個自動功能必須有自己的 Card")
	FeatureCards[Card] = true
end
for _, Key in IntervalKeys do
	local Toggle, Slider = Window.Controls[Key], Window.Controls[Key .. "_Interval"]
	assert(Toggle.Section == Slider.Section and FeatureCards[Toggle.Section], "功能開關、間隔、狀態須放在同一張 Card")
end
assert(Window.Controls.FeedMode.Section == Window.Controls.bAutoFeed.Section
	and Window.Controls.FeedAction.Section == Window.Controls.bAutoFeed.Section, "餵食設定須與餵食開關同卡")
assert(Window.Controls.SellRarities.Section == Window.Controls.bAutoSellCharacters.Section, "出售品質須與出售功能同卡")
do
	local Test = { First = Window.Controls.UpgradePriority_1, Second = Window.Controls.UpgradePriority_2 }
	assert(Test.First and Test.Second and Test.First.Section == Window.Controls.bAutoUpgrade.Section
		and Test.Second.Section == Window.Controls.bAutoUpgrade.Section, "每個升級順位都應放在原本的自動升級 Card")
	assert(Test.First.Options.bVisible == false and not _Controls["升級優先順序 1"], "排序不再建立下拉選單，舊 Flag 僅以隱藏設定值承接")
	_Controls["升級項目 2"].Callback()
	_Controls["上調順序"].Callback()
	assert(Controller.UpgradePriorityOrder[1] == "Expensive" and Controller.UpgradePriorityOrder[2] == "Cheap"
		and Test.First:Get() == "Expensive" and Test.Second:Get() == "Cheap", "修改第一順位應交換原位置並同步兩個控制項")
	_Controls["下調順序"].Callback()
end
assert(Window.Controls.Potion_Cash_L1.Section.Tab == Window.Controls.bAutoBuyPotions.Section.Tab
	and Window.Controls.Potion_Cash_L1.Section.Tab == Window.Controls.bAutoDrinkPotions.Section.Tab, "藥水白名單須與買藥及喝藥位於同一分頁")
table.sort(IntervalKeys)
local IntervalSlider = _Controls["自動領取任務獎勵間隔"]
IntervalSlider.Callback(4)
assert(not Controller.bAutoQuestRewards, "只改間隔不能開啟功能")
_Toggle("自動領取任務獎勵", true)
_Step(1)
assert(_Last("QuestGetState"), "首次開啟仍可立即執行")
table.clear(_Calls)
_Step(3.9)
assert(not _Last("QuestGetState"), "輪次完成後尚未到間隔不能重啟")
_Step(0.11)
assert(_Last("QuestGetState"), "達到設定間隔後應重啟")
table.clear(_Calls)
IntervalSlider.Callback(10)
_Step(5)
assert(not _Last("QuestGetState"), "閒置時延長間隔應重新安排下一輪")
IntervalSlider.Callback(2)
_Step(0)
assert(_Last("QuestGetState"), "縮短間隔後若已超過等待時間應可執行")
local OriginalIntervalGet = _Remotes.QuestGetState.InvokeServer
local bIntervalReleased = false
--[[
	模擬執行中的查詢，驗證調整間隔不會取消或產生第二份工作。
	@param self 遠端。
	@return 任務狀態。
]]
function _Remotes.QuestGetState.InvokeServer(self)
	self:FireServer()
	while not bIntervalReleased do coroutine.yield() end
	return { claimableCount = 0 }
end
IntervalSlider.Callback(1)
table.clear(_Calls)
_Step(1.1)
assert(_Last("QuestGetState"), "開始等待中的原始工作")
IntervalSlider.Callback(5)
_Step(2)
local IntervalQueryCount = 0
for _, Call in _Calls do if Call.Name == "QuestGetState" then IntervalQueryCount += 1 end end
assert(IntervalQueryCount == 1, "工作執行中調整間隔不能重複啟動")
bIntervalReleased = true
_Step(0)
table.clear(_Calls)
_Step(4.9)
assert(not _Last("QuestGetState"), "執行中變更須從完成時間開始等待新間隔")
_Step(0.11)
assert(_Last("QuestGetState"), "原工作完成後使用最新間隔")
_Toggle("自動領取任務獎勵", false)
_Remotes.QuestGetState.InvokeServer = OriginalIntervalGet
IntervalSlider.Callback(-100)
assert(Controller.Intervals.bAutoQuestRewards == 0.1, "過小間隔限制在下限")
IntervalSlider.Callback(10000)
assert(Controller.Intervals.bAutoQuestRewards == 300, "過大間隔限制在上限")
IntervalSlider.Callback(0 / 0)
IntervalSlider.Callback(math.huge)
assert(Controller.Intervals.bAutoQuestRewards == 300, "非有限間隔不得破壞排程")
IntervalSlider.Callback(15)
table.clear(_Calls)
local RewardFeatures = {
	{ "自動領取任務獎勵", "bAutoQuestRewards", "QuestClaimAll" },
	{ "自動領取索引獎勵", "bAutoIndexRewards", "IndexClaimAllRewards" },
	{ "自動領取每日獎勵", "bAutoDailyRewards", "ClaimDailyReward" },
	{ "自動領取遊玩時間獎勵", "bAutoPlaytimeRewards", "ClaimPlaytimeReward" },
	{ "自動領取信箱獎勵", "bAutoInboxRewards", "InboxClaim" },
	{ "自動領取 Medal 獎勵", "bAutoMedalRewards", "MedalQuestClaim" },
	{ "自動領取 NPC 與活動任務獎勵", "bAutoNpcRewards", "NpcQuestClaim" },
	{ "自動領取離線獎勵（一般領取）", "bAutoOfflineRewards", "FinalizeWelcomeOffline" },
	{ "自動領取離開提示贈禮", "bAutoLeaveRewards", "LeaveOfferClaim" },
}
local NpcStates = {
	A = { claimed = false, locked = false, progress = { Feed = 10 }, deposits = { Goka = 1 } },
	B = { claimed = false, locked = false, progress = { Feed = 10 }, deposits = {} },
	C = { claimed = true, locked = false, progress = { Feed = 100 }, deposits = {} },
	D = { claimed = false, locked = true, progress = { Feed = 100 }, deposits = {} },
}
--[[
	提供不同 NPC 任務進度，驗證不交付角色、不付費且只領完成任務。
	@param self 遠端替身。
	@param Id 原生任務鍵。
	@return 指定任務的原始進度。
]]
function _Remotes.NpcQuestGetState.InvokeServer(self, Id)
	self:FireServer(Id)
	assert(NpcStates[Id], "不可查詢付費或進化任務")
	return NpcStates[Id]
end
for _, Feature in RewardFeatures do
	assert(Controller[Feature[2]] == false, "舊設定沒有領獎欄位時應保持關閉")
	_Toggle(Feature[1], true)
end
_Step(1)
for _, Feature in RewardFeatures do assert(not _Last(Feature[3]), "沒有可領獎資料時不得發送 " .. Feature[3]) end
local NpcQueries = 0
for _, Call in _Calls do if Call.Name == "NpcQuestGetState" then NpcQueries += 1 end end
assert(NpcQueries == 3, "NPC 每輪最多查詢三個，避免一次查遍所有任務")
_Responses.QuestGetState = { { claimableCount = 2 } }
_Responses.IndexGetData = { { unlockedKeys = { "A", "B" }, claimedKeys = { "A" } } }
_Responses.GetDailyRewardsState = { { totalDays = 7, unlockedDay = 3, claimedMask = 1 } }
_Responses.GetPlaytimeRewardsState = { { totalRewards = 3, rewardStates = {
	{ claimed = true, ready = true }, { claimed = false, ready = false, remaining = 0 }, { claimed = false, ready = true },
} } }
_Responses.InboxGet = { { ready = true, list = { { id = "Gift" } } } }
_Responses.InboxClaim = { { got = { "Gift" }, owned = { "Owned" }, failed = 1, reason = "ON_HOLD" } }
_Responses.MedalQuestGet = { { eligible = true } }
_Responses.GetWelcomeOfflineState = { { totalBase = 0, hasAny = true, extras = { "Gift" } } }
_Responses.LeaveOfferState = { { claimed = false } }
table.clear(_Calls)
_Step(31)
assert(_Last("QuestClaimAll").Args.n == 0 and _Last("IndexClaimAllRewards").Args.n == 0,
	"任務與索引必須採用原生無參數全部領取")
assert(_Last("ClaimDailyReward").Args[1] == 2 and _Last("ClaimDailyReward").Args.n == 1,
	"每日只能領已解鎖、遮罩尚未領取的最早天數")
assert(_Last("ClaimPlaytimeReward").Args[1] == 3, "只能領取伺服器 ready 且未 claimed 的遊玩時間獎勵")
assert(_Last("InboxClaim").Args[1] == "all" and tostring(_Labels[17].Value):find("ON_HOLD", 1, true),
	"信箱使用原生 all，部分失敗原因必須保留")
assert(_Last("MedalQuestClaim").Args.n == 0, "Medal 只有 eligible 才能呼叫領獎")
assert(_Last("FinalizeWelcomeOffline").Args[1] == "close", "離線獎勵只用一般 close，不呼叫付費 triple")
assert(_Last("LeaveOfferClaim").Args.n == 0, "離開贈禮沿用無參數領取，不觸發離開遊戲")
assert(not _Last("NpcQuestClaim"), "NPC 未交齊角色、未完成、鎖定與已領取任務都不可領取")
NpcStates.A.deposits.Goka = 2
table.clear(_Calls)
_Step(16)
assert(_Last("NpcQuestClaim").Args[1] == "A" and _Last("NpcQuestClaim").Args.n == 1,
	"輪詢必須涵蓋下一批 NPC 任務，條件已完成後僅傳入任務鍵")
NpcStates.A.claimed = true
NpcStates.B.progress.Feed, NpcStates.B.deposits = 20, nil
table.clear(_Calls)
_Step(31)
assert(_Last("NpcQuestClaim").Args[1] == "B", "沒有交付需求的已完成任務須相容原生省略 deposits 的狀態")
NpcStates.B.claimed = true
assert(Root.CFrame.Position == Rbx.Vector3.zero and WeakRod.Parent == Character, "領獎不應傳送或切換裝備")
for _, Feature in RewardFeatures do _Toggle(Feature[1], false) end
-- 狀態已領取／未載入時，不可因先前可領資料繼續操作。
_Responses.QuestGetState = { { claimableCount = 0 } }
_Responses.IndexGetData = { { unlockedKeys = { "A" }, claimedKeys = { "A" } } }
_Responses.GetDailyRewardsState = { { totalDays = 7, unlockedDay = 3, claimedMask = 7 } }
_Responses.GetPlaytimeRewardsState = { { totalRewards = 1, rewardStates = { { claimed = true, ready = true } } } }
_Responses.InboxGet = { { ready = false, list = { "StaleGift" } } }
_Responses.MedalQuestGet = { { eligible = false } }
NpcStates.A.claimed = true
_Responses.GetWelcomeOfflineState = { { totalBase = 0, hasAny = false } }
_Responses.LeaveOfferState = { { claimed = true } }
table.clear(_Calls)
for _, Feature in RewardFeatures do _Toggle(Feature[1], true) end
_Step(31)
for _, Feature in RewardFeatures do assert(not _Last(Feature[3]), "已領取或未載入時不可再次領取") end
for _, Feature in RewardFeatures do _Toggle(Feature[1], false) end
_Responses.QuestGetState = { false }
_Toggle("自動領取任務獎勵", true)
table.clear(_Calls)
_Step(16)
assert(not _Last("QuestClaimAll") and tostring(_Labels[13].Value):find("格式已變更", 1, true), "領獎資料讀取失敗應停止該輪")
_Responses.QuestGetState = { { claimableCount = 1 } }
_Responses.QuestClaimAll = { { ok = false, reason = "BUSY" } }
_Step(16)
assert(tostring(_Labels[13].Value):find("BUSY", 1, true), "拒絕領獎必須顯示原始原因")
_Toggle("自動領取任務獎勵", false)
local QuestGetInvoker = _Remotes.QuestGetState.InvokeServer
--[[
	模擬查詢等待，測試關閉開關後不送領獎。
	@param self 遠端替身。
	@return 查詢結果。
]]
function _Remotes.QuestGetState.InvokeServer(self)
	self:FireServer()
	coroutine.yield()
	return { claimableCount = 1 }
end
_Toggle("自動領取任務獎勵", true)
table.clear(_Calls)
_Step(16)
assert(_Last("QuestGetState") and not _Last("QuestClaimAll"), "應先查詢再領獎")
_Toggle("自動領取任務獎勵", false)
_Step(1)
assert(not _Last("QuestClaimAll"), "等待時關閉應取消領獎")
_Remotes.QuestGetState.InvokeServer = QuestGetInvoker
_Responses.QuestGetState, _Responses.QuestClaimAll = { { claimableCount = 0 } }, { { ok = true } }
table.clear(_Calls)
assert(Controller.bAutoBuild == false, "自動蓋家預設關閉")
_Toggle("自動蓋家（購買建築）", true)
_Step(1)
assert(Root.CFrame.Position.X == 300 and not _Last("BuildTouch"), "購買前應先傳送到自己建築按鈕")
_Step(0.5)
assert(_Last("BuildTouch").Args[2] == CheapBuilding.Touch and _Last("BuildTouch").Args[3] == 0,
	"應優先購買可負擔低價建築，略過付費、未知價格、鑽石與隱藏按鈕")
_Step(0.5)
assert(_Last("BuildTouch").Args[3] == 1 and CheapBuilding.Parent == nil
	and Root.CFrame.Position == Rbx.Vector3.zero, "購買後結束觸碰並返回起點")
_bBuildAccept = false
table.clear(_Calls)
_Step(16)
_Step(0.5)
assert(_Last("BuildTouch").Args[2] == ExpensiveBuilding.Touch, "應依原生千進位字尾解析 1K 費用")
_Toggle("自動蓋家（購買建築）", false)
assert(_Last("BuildTouch").Args[3] == 1 and Root.CFrame.Position == Rbx.Vector3.zero,
	"觸碰期間停用應立即結束觸碰並還原位置")
table.clear(_Calls)
_Toggle("自動蓋家（購買建築）", true)
_Step(16)
ExpensiveBuilding.IsPaid.Value = true
_Step(0.5)
assert(not _Last("BuildTouch") and Root.CFrame.Position == Rbx.Vector3.zero,
	"移動期間按鈕變成付費商品時不得觸碰")
_Toggle("自動蓋家（購買建築）", false)
ExpensiveBuilding.IsPaid.Value = false
PlayerData:SetAttribute("CashNumber", 0)
_Toggle("自動蓋家（購買建築）", true)
_Step(16)
assert(not _Last("BuildTouch"), "資金不足時不得購買建築")
_Toggle("允許自動花費鑽石", true)
_Step(3)
_Step(0.5)
assert(not _Last("BuildTouch"), "建築只支援已確認的 Cash，其他貨幣不可因全域鑽石開關而放行")
_Toggle("自動蓋家（購買建築）", false)
_Toggle("允許自動花費鑽石", false)
GemBuilding.Parent = nil
PlayerData:SetAttribute("CashNumber", 1000)
PlayerData:SetAttribute("Rebirths", 11)
_bBuildTouchError = true
_Toggle("自動蓋家（購買建築）", true)
_Step(16)
_Step(0.5)
assert(_Last("BuildTouch").Args[3] == 1 and Root.CFrame.Position == Rbx.Vector3.zero
	and tostring(_Labels[22].Value):find("test touch error", 1, true), "觸碰失敗也應結束觸碰並還原")
_Toggle("自動蓋家（購買建築）", false)
_bBuildTouchError = false
-- 建造或轉生門檻變化後，候選資格必須重新判斷。
ConstructingBuilding.DisplayTimer.BillboardGui.Enabled = false
table.clear(_Calls)
_Toggle("自動蓋家（購買建築）", true)
_Step(16)
_Step(0.5)
assert(_Last("BuildTouch").Args[2] == ConstructingBuilding.Touch, "倒數關閉後才能恢復購買該建築")
_Toggle("自動蓋家（購買建築）", false)
ConstructingBuilding.DisplayTimer.BillboardGui.Enabled = true
PlayerData:SetAttribute("Rebirths", 150)
table.clear(_Calls)
_Toggle("自動蓋家（購買建築）", true)
_Step(16)
_Step(0.5)
assert(_Last("BuildTouch").Args[2] == RebirthBuilding.Touch, "轉生次數達標後應恢復候選資格")
_Toggle("自動蓋家（購買建築）", false)
PlayerData:SetAttribute("Rebirths", 11)
_Object("BoolValue", "SacrificeSkipsRebirths", RebirthBuilding).Value = true
PlayerData:SetAttribute("Sacrifices", 1)
table.clear(_Calls)
_Toggle("自動蓋家（購買建築）", true)
_Step(16)
_Step(0.5)
assert(_Last("BuildTouch").Args[2] == RebirthBuilding.Touch, "原生明確允許獻祭略過轉生門檻時仍可購買")
_Toggle("自動蓋家（購買建築）", false)
PlayerData:SetAttribute("Sacrifices", 0)
table.clear(_Calls)
_Toggle("自動蓋家（購買建築）", true)
_Step(16)
ExpensiveBuilding.DisplayTimer.BillboardGui.Enabled = true
_Step(0.5)
assert(not _Last("BuildTouch") and Root.CFrame.Position == Rbx.Vector3.zero, "途中開始建造時也不可觸碰")
_Toggle("自動蓋家（購買建築）", false)
ExpensiveBuilding.DisplayTimer.BillboardGui.Enabled = false
local OriginalWorkerSummary, OriginalWorkerEquipped = _Responses.BackpackCharSummaryGet, _Responses.BackpackGetEquippedState
local WorkInventory = {
	["C|Protected|"] = { n = "Protected", ra = "Transcendent", c = 1 },
	["C|CashRich|"] = { n = "CashRich", ra = "Common", c = 1, bc = 1e20 },
	["C|RarePlain|"] = { n = "RarePlain", ra = "Rare", c = 1 },
	["C|RareGold|Gold"] = { n = "RareGold", ra = "Rare", ty = "Gold", c = 1 },
}
--[[
	為測試背包摘要建立原生屬性的實體角色工具。
	@param Inventory 原始角色鍵對應摘要。
]]
local function _WorkerInventory(Inventory)
	for Key, Record in Inventory do
		local Tool = _Object("Tool", Record.n, Backpack)
		Tool:SetAttribute("IsCharacterTool", true)
		Tool:SetAttribute("Owned", true)
		Tool:SetAttribute("CharacterName", Record.n)
		Tool:SetAttribute("CharacterType", Record.ty or "")
		Tool:SetAttribute("Rarity", Record.ra)
		Tool:SetAttribute("Level", 1)
		WorkerTools[Key] = Tool
	end
end
--[[
	推進一輪派工及其移動、卸下、放置與回報等待。
]]
local function _WorkerRound() _Step(7); _Step(0.5); _Step(0.5); _Step(0.5) end
_WorkerInventory(WorkInventory)
_Responses.BackpackCharSummaryGet = { WorkInventory }
_Responses.BackpackGetEquippedState = { { equipped = { { key = "C|Protected|" } } } }
assert(not Controller.bAutoWorkers and not Controller.bAutoBoxes, "派工與 Box 新開關預設關閉")
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
assert(not _Last("BackpackCharSummaryGet") and not _Last("BackpackHoldCharacter"), "沒有自己的工作建築時不可派工")
_Toggle("自動派遣適任角色（建築／Garden）", false)
WorkerSites["Lemon Stand"].Parent = WorkerPurchases
WorkerPrompts["Lemon Stand"]:SetAttribute("OwnerUserId", 42)
OwnModel:SetAttribute("CharacterName", "Protected")
_Responses.BackpackGetEquippedState = { { equipped = {} } }
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_WorkerRound()
assert(_Last("WorkerPlace").Args[1] == "Lemon Stand" and _Last("WorkerPlace").Args[2] == "C|RareGold|Gold",
	"攤位用品質及同品質 Gems 變異挑選閒置角色，不抽走已裝備角色或只看 Cash")
assert(not _Last("BackpackEquipCharacter"), "派工不可使用展台裝備 Remote 拿起角色")
OwnModel:SetAttribute("CharacterName", "HomeWeak")
_Responses.BackpackGetEquippedState = { { equipped = { { key = "C|Protected|" } } } }
assert(Root.CFrame.Position == Rbx.Vector3.zero and WeakRod.Parent == Character, "派工完成應還原位置與原工具")
do
	-- 名稱、等級與產錢值不同，但攤位效果相同時不能拿起或卸下角色。
	WorkInventory["C|RarePeer|Gold|L900"] = { n = "RarePeer", ra = "Rare", ty = "Gold", c = 1, bc = 1e30 }
	table.clear(_Calls)
	_WorkerRound()
	assert(not _Last("BackpackHoldCharacter") and not _Last("LemonUnequipChar") and not _Last("WorkerPlace")
		and Root.CFrame.Position == Rbx.Vector3.zero, "同品質與 Gems 倍率者即使等級／CPS 更高，也應原地跳過")
	assert(tostring(_Controls["派工同步狀態"].Control.Content):find("本輪跳過", 1, true), "無提升也要同步派工詳細狀態")
	WorkInventory["C|RarePeer|Gold|L900"] = nil
end
-- 派工移動途中角色被放回家中時，拿起前的第二次檢查仍必須保護它。
_Toggle("自動派遣適任角色（建築／Garden）", false)
table.clear(WorkerStates["Lemon Stand"])
WorkerPrompts["Lemon Stand"].ActionText = "Place"
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
OwnModel:SetAttribute("CharacterName", "RareGold")
OwnModel:SetAttribute("CharacterType", "Gold")
_Step(0.5)
assert(not _Last("BackpackHoldCharacter"), "移動後候選已部署在家中時不得拿起")
OwnModel:SetAttribute("CharacterName", "HomeWeak")
OwnModel:SetAttribute("CharacterType", "")
_WorkerRound()
assert(WorkerStates["Lemon Stand"].groupKey == "C|RareGold|Gold", "恢復閒置候選後仍可正常派工")
table.clear(_Calls)
_WorkerRound()
assert(not _Last("BackpackHoldCharacter"), "已是最佳攤位角色時不可重複卸下與放置")
WorkerSites["Fishing Dock"].Parent = WorkerPurchases
WorkerPrompts["Fishing Dock"]:SetAttribute("OwnerUserId", 42)
_WorkerRound()
assert(_Last("WorkerPlace").Args[1] == "Fishing Dock" and _Last("WorkerPlace").Args[2] == "C|RarePlain|",
	"Dock 選最高品質閒置者，不能抽走已在攤位工作的 RareGold")
do
	WorkInventory["C|DockPeer|Gold|L900"] = { n = "DockPeer", ra = "Rare", ty = "Gold", c = 1, bc = 1e30 }
	table.clear(_Calls)
	for _ = 1, 2 do _WorkerRound() end
	assert(not _Last("BackpackHoldCharacter") and not _Last("FishingDockUnequipChar") and not _Last("WorkerPlace"),
		"Dock 同品質時變異、等級與 CPS 都不構成提升，不得換人")
	WorkInventory["C|DockPeer|Gold|L900"] = nil
end
local FoodInventory = {
	["C|WorkerA|"] = { n = "WorkerA", ra = "Common", c = 1 },
	["C|WorkerB|"] = { n = "WorkerB", ra = "Rare", c = 1 },
}
_WorkerInventory(FoodInventory)
_Responses.BackpackCharSummaryGet = { FoodInventory }
WorkerPrompts.Garden1:SetAttribute("OwnerUserId", 42)
WorkerStates.Garden1.charName, WorkerStates.Garden1.rarity, WorkerStates.Garden1.groupKey = "WorkerA", "Common", "C|WorkerA|"
WorkerPrompts.Garden1.ActionText = "Pick Up"
Garden:SetAttribute("CurrentFoodPerSecond", 100)
_WorkerRound()
assert(_Last("WorkerPlace").Args[1] == "Garden1" and _Last("WorkerPlace").Args[2] == "C|WorkerB|",
	"已購菜園應試用閒置角色並依伺服器產量比較")
table.clear(_Calls)
for _ = 1, 3 do _WorkerRound() end
assert(not _Last("WorkerPlace") and WorkerStates.Garden1.groupKey == "C|WorkerB|", "Garden 保留實際食物產量較高角色")
FoodInventory["C|WorkerC|"] = { n = "WorkerC", ra = "Common", c = 1 }
_WorkerInventory({ ["C|WorkerC|"] = FoodInventory["C|WorkerC|"] })
for _ = 1, 3 do _WorkerRound() end
assert(WorkerStates.Garden1.groupKey == "C|WorkerC|", "新閒置角色應逐次試工，取得真實產量")
for _ = 1, 3 do _WorkerRound() end
assert(WorkerStates.Garden1.groupKey == "C|WorkerB|", "試工產量較差後應恢復已量測最佳角色")
do
	FoodInventory["C|WorkerD|"] = { n = "WorkerD", ra = "Common", c = 1 }
	WorkerRates["C|WorkerD|"] = 300
	_WorkerInventory({ ["C|WorkerD|"] = FoodInventory["C|WorkerD|"] })
	for _ = 1, 3 do _WorkerRound() end
	assert(WorkerStates.Garden1.groupKey == "C|WorkerD|", "未知的 Garden 產量仍須實測，不能僅憑品質猜測效果相同")
	for _ = 1, 3 do _WorkerRound() end
	table.clear(_Calls)
	for _ = 1, 3 do _WorkerRound() end
	assert(not _Last("BackpackHoldCharacter") and not _Last("GardenUnequipChar") and not _Last("WorkerPlace"),
		"已量測相同 Garden 產量後不得反覆交換 WorkerB／WorkerD")
	FoodInventory["C|WorkerD|"], WorkerRates["C|WorkerD|"] = nil, nil
end
_Toggle("自動派遣適任角色（建築／Garden）", false)
-- 距離等待時關閉派工，不可在之後裝備或放置。
table.clear(WorkerStates["Lemon Stand"])
WorkerPrompts["Lemon Stand"].ActionText = "Place"
_Toggle("自動派遣適任角色（建築／Garden）", true)
table.clear(_Calls)
_Step(7)
_Toggle("自動派遣適任角色（建築／Garden）", false)
_Step(0.5)
assert(not _Last("BackpackHoldCharacter") and not _Last("WorkerPlace") and Root.CFrame.Position == Rbx.Vector3.zero,
	"停用派工應取消移動，不繼續裝備或放置")
-- 真實回歸：展台裝備不產生手持工具，拿起工具可能延遲超過原先 2 秒。
WorkerSites["Fishing Dock"].Parent = nil
WorkerPrompts.Garden1:SetAttribute("OwnerUserId", 99)
_Responses.BackpackCharSummaryGet = { WorkInventory }
-- 提示同步慢於兩秒：候選已拿起仍須等待原生 Place，不可報錯或點到其他操作。
local LemonPrompt = WorkerPrompts["Lemon Stand"]
table.clear(WorkerStates["Lemon Stand"])
LemonPrompt.ActionText = "Equip Character First!"
_WorkerHoldDelay = 0
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
_Step(0.5)
_Step(2.1)
assert(not _Last("WorkerPlace") and Root.CFrame.Position ~= Rbx.Vector3.zero,
	"工具已拿起但提示未同步時應等待超過兩秒，不可提早報錯或觸發")
LemonPrompt.ActionText = "Place"
_Step(0.1)
_Step(0.5)
assert(_Last("WorkerPlace") and Root.CFrame.Position == Rbx.Vector3.zero, "提示延遲同步後仍應完成派工並返回")
_Toggle("自動派遣適任角色（建築／Garden）", false)
-- 等待期間提示被遊戲重建，應重新取得同建築的新提示。
table.clear(WorkerStates["Lemon Stand"])
LemonPrompt.ActionText = "Equip Character First!"
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
_Step(0.5)
local LemonAnchor = LemonPrompt.Parent
LemonPrompt.Parent = nil
local RebuiltPrompt = _Object("ProximityPrompt", "ProximityPrompt", LemonAnchor)
RebuiltPrompt.ActionText, RebuiltPrompt.Enabled, RebuiltPrompt.MaxActivationDistance = "Place", true, 5
RebuiltPrompt:SetAttribute("OwnerUserId", 42)
WorkerPrompts["Lemon Stand"] = RebuiltPrompt
_Step(0.5)
_Step(0.5)
assert(_Last("WorkerPlace") and Root.CFrame.Position == Rbx.Vector3.zero, "重建後應操作新的原生提示")
_Toggle("自動派遣適任角色（建築／Garden）", false)
RebuiltPrompt:Destroy()
LemonPrompt.Parent, WorkerPrompts["Lemon Stand"] = LemonAnchor, LemonPrompt
-- Character 內已有候選 Tool 但第一個 Tool 仍為魚竿，遠端拿起未產生新物件。
table.clear(WorkerStates["Lemon Stand"])
WorkerTools["C|RareGold|Gold"].Parent = Character
LemonPrompt.ActionText = "Equip Character First!"
_bWorkerHoldAccept, _bWorkerPromptTracksTool = false, true
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
_Step(0.5)
_Step(0.5)
_Step(0.5)
assert(_Last("WorkerPlace") and WeakRod.Parent == Character and Root.CFrame.Position == Rbx.Vector3.zero,
	"既有候選 Tool 也必須真正裝備並排除其他手持工具，才能出現 Place")
_Toggle("自動派遣適任角色（建築／Garden）", false)
_bWorkerHoldAccept, _bWorkerPromptTracksTool = true, false
-- Place 永遠未出現：只顯示具體狀態並還原，不偽造放置成功。
table.clear(WorkerStates["Lemon Stand"])
LemonPrompt.ActionText = "Equip Character First!"
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
_Step(0.5)
for _ = 1, 13 do _Step(0.5) end
assert(not _Last("WorkerPlace") and Root.CFrame.Position == Rbx.Vector3.zero and WeakRod.Parent == Character,
	"提示同步逾時必須還原工具與位置且不觸發放置")
assert(tostring(_Controls["派工同步狀態"].Control.Content):find("Equip Character First!", 1, true)
	and not tostring(_Labels[23].Value):find("錯誤：", 1, true), "卡片應完整顯示實際提示，而不是泛用 Place 斷言錯誤")
_Toggle("自動派遣適任角色（建築／Garden）", false)
local LemonState = WorkerStates["Lemon Stand"]
LemonState.charName, LemonState.rarity, LemonState.groupKey, LemonState.charType, LemonState.standKey = "RarePlain", "Rare", "C|RarePlain|", "", "LemonStand"
WorkerPrompts["Lemon Stand"].ActionText = "Pick Up"
WorkerTools["C|RareGold|Gold"].Parent = nil
_WorkerHoldDelay = 3
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
_Step(0.5)
_Step(2.1)
assert(_Last("BackpackHoldCharacter").Args[1] == "C|RareGold|Gold" and not _Last("LemonUnequipChar")
	and LemonState.groupKey == "C|RarePlain|", "等待拿起期間應保留原員工，不能先卸下")
for _ = 1, 8 do _Step(0.5) end
assert(_Last("WorkerPlace") and _Last("WorkerPlace").Args[2] == "C|RareGold|Gold"
	and not _Last("BackpackEquipCharacter") and Root.CFrame.Position == Rbx.Vector3.zero,
	"拿起工具超過 2 秒才出現仍應完成派工，且不使用展台裝備協定")
_Toggle("自動派遣適任角色（建築／Garden）", false)
LemonState.charName, LemonState.rarity, LemonState.groupKey, LemonState.charType = "RarePlain", "Rare", "C|RarePlain|", ""
WorkerPrompts["Lemon Stand"].ActionText = "Pick Up"
WorkerTools["C|RareGold|Gold"].Parent = nil
_bWorkerHoldAccept, _WorkerHoldDelay = false, 0
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
_Step(0.5)
for _ = 1, 18 do _Step(0.5) end
assert(not _Last("WorkerPlace") and not _Last("LemonUnequipChar") and LemonState.groupKey == "C|RarePlain|"
	and Root.CFrame.Position == Rbx.Vector3.zero and WeakRod.Parent == Character,
	"拿起失敗不可清空原職位，必須還原位置與原工具")
assert(tostring(_Labels[23].Value):find("BackpackHoldCharacter", 1, true)
	and _Last("BackpackHoldCharacter").Args[1] == "", "拿起逾時要顯示協定與目標，並清除自己的待處理拿起狀態")
_Toggle("自動派遣適任角色（建築／Garden）", false)
_bWorkerHoldAccept, _WorkerHoldDelay = true, 3
table.clear(_Calls)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Step(7)
_Step(0.5)
_Toggle("自動派遣適任角色（建築／Garden）", false)
_Step(4)
assert(not _WorkerPendingHold and not _Last("WorkerPlace") and not _Last("LemonUnequipChar")
	and Root.CFrame.Position == Rbx.Vector3.zero and WeakRod.Parent == Character,
	"等待拿起期間關閉應取消自己的持有請求，原工作角色保留")
_WorkerHoldDelay = 0
WorkerTools["C|RareGold|Gold"].Parent = Backpack
WorkerSites["Lemon Stand"].Parent = nil
_Responses.BackpackCharSummaryGet, _Responses.BackpackGetEquippedState = OriginalWorkerSummary, OriginalWorkerEquipped
_Responses.CaseSummaryGet = { { Empty = { q = 0 }, BoxA = { q = 8 }, BoxB = { q = 2 } } }
table.clear(_Calls)
_Toggle("自動開 Box", true)
_Step(1)
assert(_Last("CaseOpenRequest").Args[1] == "BoxA" and _Last("CaseOpenRequest").Args[2] == 5
	and _Last("CaseOpenRequest").Args.n == 2, "Box 必須傳原始鍵與批次上限數量")
_Step(6)
assert(_Last("CaseOpenRequest").Args[1] == "BoxB" and _Last("CaseOpenRequest").Args[2] == 2, "Box 輪替且不超過持有數量")
PlayerData:SetAttribute("CaseOpening", true)
table.clear(_Calls)
_Step(6)
assert(not _Last("CaseSummaryGet") and not _Last("CaseOpenRequest"), "開 Box 動畫期間等待")
PlayerData:SetAttribute("CaseOpening", false)
_Responses.CaseSummaryGet = { false }
_Step(6)
assert(not _Last("CaseOpenRequest") and tostring(_Labels[24].Value):find("格式已變更", 1, true), "Box 資料失敗不可送開啟")
_Responses.CaseSummaryGet = { { BoxA = { q = 1 } } }
_Responses.CaseOpenRequest = { { ok = false, err = "BUSY" } }
_Step(6)
assert(tostring(_Labels[24].Value):find("BUSY", 1, true), "Box 拒絕原因應保留")
_Toggle("自動開 Box", false)
local CaseGetInvoker = _Remotes.CaseSummaryGet.InvokeServer
--[[
	模擬 Box 查詢等待。
	@param self 遠端。
	@return 原始 Box 數量資料。
]]
function _Remotes.CaseSummaryGet.InvokeServer(self)
	self:FireServer()
	coroutine.yield()
	return { BoxA = { q = 1 } }
end
table.clear(_Calls)
_Toggle("自動開 Box", true)
_Step(6)
_Toggle("自動開 Box", false)
_Step(1)
assert(not _Last("CaseOpenRequest"), "等待摘要期間關閉不可繼續開 Box")
_Remotes.CaseSummaryGet.InvokeServer = CaseGetInvoker
_Responses.CaseOpenRequest = { { ok = true } }
_Responses.CaseSummaryGet = { {} }
table.clear(_Calls)
_Toggle("自動換最強裝備（魚竿）", true)
_Step(1)
assert(BestRod.Parent == Character and WeakRod.Parent == Backpack, "應裝備最強魚竿")
_Toggle("自動釣魚", true)
_bGround = false
_Step(1)
assert(not _Last("FishingRequestStart") and Root.CFrame.Position == Rbx.Vector3.zero, "岸邊未載入不得移動或拋竿")
_bGround = true
_Step(1)
assert(not _Last("FishingRequestStart") and Root.CFrame.Position.X > 800, "應先傳送到遠處岸邊再拋竿")
_Step(0.5)
assert(_Last("FishingRequestStart"), tostring(_Labels[2].Value))
assert(_Last("FishingRequestStart").Args[1] == Pond, "拋竿應傳魚池 Instance")
assert(typeof(_Last("FishingRequestStart").Args[2]) == "Vector3", "拋竿第二參數必須是 Vector3")
assert(not _Last("FishingClick"), "Hooked 前不得點擊")
_FishingCallback({ kind = "Started" })
_Step(1)
assert(not _Last("FishingClick"), "Started 後仍應等待 Hooked")
_FishingCallback({ kind = "Hooked" })
_Step(1)
assert(_Last("FishingClick") and _Last("FishingClick").Args.n == 0, "Hooked 後發送無參數點擊")
_FishingCallback({ kind = "Completed" })
PlayerData:SetAttribute("BPCatchLock", true)
table.clear(_Calls)
_Step(1)
assert(not _Last("FishingRequestStart"), "完成回合後需等揭曉鎖解除")
PlayerData:SetAttribute("BPCatchLock", false)
_Step(1)
assert(_Last("FishingRequestStart"), "釣完應接續拋竿，不固定等待八秒")
_FishingCallback({ kind = "Started" })
-- 有可操作的食物目標時先保留移動權、取消自己的回合，再等伺服器確認。
local ShoreBeforeCollect = Root.CFrame
table.clear(_Calls)
_Toggle("自動收集食物", true)
_Toggle("自動撿取地圖上的物品", true)
_Step(1)
assert(_Last("FishingCancel") and Root.CFrame == ShoreBeforeCollect and not _Last("CollectFood"),
	"收集有目標時應先取消釣魚且等待確認，不直接傳走")
_FishingCallback({ kind = "Stopped", reason = "CANCELED" })
_Step(0.1)
assert(Root.CFrame.Position.X == 1000 and not _Last("FishingRequestStart"), "取消確認後才前往菜園，釣魚保持暫停")
_Step(0.5)
assert(_Last("CollectFood") and not _Last("FishingRequestStart"), "收集期間不得插入拋竿")
_Step(0.4)
assert(Root.CFrame == ShoreBeforeCollect, "操作完成應返回魚池岸邊")
_Toggle("自動收集食物", false)
_Step(1)
assert(_Last("FishingRequestStart"), "操作完成後應恢復連續釣魚")
_FishingCallback({ kind = "Started" })
table.clear(_Calls)
_Toggle("自動收集食物", true)
_Step(3)
assert(not _Last("FishingCancel"), "沒有新食物目標時不能僅因排程到期就中斷釣魚")
Food:SetAttribute("FoodPromptParked", false)
_Step(3)
assert(_Last("FishingCancel"), "有新目標才要求暫停釣魚")
_Step(3.1)
assert(Root.CFrame == ShoreBeforeCollect and not _Last("CollectFood"), "取消確認逾時不可傳送或拾取")
_Toggle("自動收集食物", false)
_Toggle("自動釣魚", false)
assert(_Last("FishingCancel"), "關閉應取消自己的釣魚")
_FishingCallback({ kind = "Stopped", reason = "CANCELED" })
-- 原生 Auto Fish 隨自動釣魚回合維持開啟，不需要額外開關。
PlayerData:SetAttribute("AutoFishOwned", true)
NativePurchase.Visible, NativeRobux.Visible = false, false
table.clear(_Calls)
-- 快照的 AutoFish 沒有 Purchase／Robux；可選子按鈕缺席不應阻擋開啟與關閉。
NativePurchase.Parent, NativeRobux.Parent = nil, nil
_Step(1)
assert(not NativeAutoOn.Enabled and not _Last("NativeAutoFishToggle"), "自動釣魚關閉時不得啟用原生開關")
_Toggle("自動釣魚", true)
_FishingCallback({ kind = "Started" })
_Step(0.5)
assert(NativeAutoOn.Enabled and _Last("NativeAutoFishToggle"), "快照缺少可選購買子按鈕時仍須啟用")
_Toggle("自動釣魚", false)
assert(not NativeAutoOn.Enabled, "缺少可選購買子按鈕也須能還原關閉")
_FishingCallback({ kind = "Stopped" })
NativePurchase.Parent, NativeRobux.Parent = NativeAutoButton, NativeAutoButton
table.clear(_Calls)
_bIgnoreNativeToggle = true
_Toggle("自動釣魚", true)
_FishingCallback({ kind = "Started" })
_Controls["自動釣魚間隔"].Callback(60)
_Step(1)
assert(not NativeAutoOn.Enabled and _Last("NativeAutoFishToggle"), "首次觸發無效不能假裝已啟用")
_bIgnoreNativeToggle = false
_Step(0.5)
assert(NativeAutoOn.Enabled, "釣魚期間自動開啟，不受六十秒釣魚間隔影響")
NativeAutoOn.Enabled, NativeAutoOff.Enabled = false, true
table.clear(_Calls)
_Step(0.49)
assert(not _Last("NativeAutoFishToggle"), "半秒內不應反覆觸發")
_Step(0.02)
assert(NativeAutoOn.Enabled, "原生開關意外關閉後應自動補開")
_Controls["自動釣魚間隔"].Callback(0.72)
table.clear(_Calls)
_FishingCallback({ kind = "Hooked" })
_Step(1)
assert(not _Last("NativeAutoFishToggle") and not _Last("FishingClick"), "已開啟不得反覆切換或重複腳本點擊")
Food:SetAttribute("FoodPromptParked", false)
table.clear(_Calls)
NativePurchase.Parent, NativeRobux.Parent = nil, nil
_Toggle("自動收集食物", true)
_Step(3)
assert(not NativeAutoOn.Enabled and _Last("FishingCancel"), "前往操作前應暫停原生 Auto Fish，避免它自行重拋")
_FishingCallback({ kind = "Stopped", reason = "CANCELED" })
_Step(0.1)
_Step(0.5)
assert(not NativeAutoOn.Enabled and _Last("CollectFood"), "原生維持開關不能在收集期間重新開啟")
_Step(0.4)
assert(NativeAutoOn.Enabled, "返回後應恢復暫停前的原生 Auto Fish")
NativePurchase.Parent, NativeRobux.Parent = NativeAutoButton, NativeAutoButton
_Toggle("自動收集食物", false)
Food:SetAttribute("FoodPromptParked", false)
_FishingCallback({ kind = "Started" })
_FishingCallback({ kind = "GodSequenceStarting" })
NativeAutoOn.Enabled, NativeAutoOff.Enabled = false, true
table.clear(_Calls)
_Step(1)
assert(not _Last("NativeAutoFishToggle"), "特殊揭曉主動關閉時不得強制重開")
_FishingCallback({ kind = "Started" })
_Step(1)
assert(NativeAutoOn.Enabled, "特殊揭曉結束的新回合應恢復維持")
_Toggle("自動釣魚", false)
assert(not NativeAutoOn.Enabled and NativeAutoOff.Enabled, "停止時應關閉由腳本啟用的 Auto Fish")
_FishingCallback({ kind = "Stopped" })
-- 使用者原本開啟的設定須保留。
NativeAutoOn.Enabled, NativeAutoOff.Enabled = true, false
table.clear(_Calls)
_Toggle("自動釣魚", true)
_FishingCallback({ kind = "Started" })
_Step(1)
_Toggle("自動釣魚", false)
assert(NativeAutoOn.Enabled and not _Last("NativeAutoFishToggle"), "不得關閉使用者原本開啟的 Auto Fish")
_FishingCallback({ kind = "Stopped" })
NativeAutoOn.Enabled, NativeAutoOff.Enabled = false, true
-- 屬性已同步但購買介面仍未同步時，不能觸發可能導致購買提示的按鈕。
NativePurchase.Visible, NativeRobux.Visible = true, true
table.clear(_Calls)
_Toggle("自動釣魚", true)
_FishingCallback({ kind = "Started" })
_FishingCallback({ kind = "Hooked" })
_Step(3)
assert(not _Last("NativeAutoFishToggle") and _Last("FishingClick"), "解鎖 UI 未同步時應保留腳本點擊")
PlayerData:SetAttribute("AutoFishOwned", false)
NativePurchase.Visible, NativeRobux.Visible = false, false
table.clear(_Calls)
_Step(3)
assert(not _Last("NativeAutoFishToggle") and _Last("FishingClick"), "尚未解鎖不可觸發購買")
_Toggle("自動釣魚", false)
_FishingCallback({ kind = "Stopped" })
NativePurchase.Visible, NativeRobux.Visible = true, true
Root.CFrame = Rbx.CFrame.new()
PlayerData:SetAttribute("FoodNumber", 0)
_Toggle("自動轉生", true)
_Toggle("自動裝備最強角色", true)
_Toggle("自動升級商店", true)
_Step(1)
assert(_Last("RebirthPurchase").Args[1] == "Cash", "轉生只用 Cash")
assert(_Last("RebirthGetState").Args[1] == true, "應沿用原生介面的狀態刷新參數")
PlayerData:SetAttribute("Rebirths", 11)
_Responses.RebirthPurchase = { false, "CLOSED" }
table.clear(_Calls)
_Step(6)
local RebirthCalls = {}
for _, Call in _Calls do
	if Call.Name == "RebirthGetState" or Call.Name == "RebirthPurchase" then table.insert(RebirthCalls, Call.Name) end
end
assert(table.concat(RebirthCalls, ",") == "RebirthGetState,RebirthPurchase,RebirthGetState",
	"必須先刷新再轉生、最後刷新；CLOSED 不可造成同輪重複購買")
assert(tostring(_Labels[1].Value):find("轉生請求未接受：CLOSED", 1, true)
	and not tostring(_Labels[1].Value):find("等待轉生條件", 1, true), "保留 CLOSED，不能臆測為玩家條件不足")
assert(Controller.RebirthStatus.Rebirths == 11 and Controller.RebirthStatus.Reason == "CLOSED"
	and Controller.RebirthStatus.BeforeState.currentRankName == "Rank11", "應保留原始轉生狀態與拒絕碼")
_Responses.RebirthGetState = { false, "CLOSED" }
table.clear(_Calls)
_Step(6)
assert(not _Last("RebirthPurchase") and Controller.RebirthStatus.Stage == "StateUnavailable",
	"狀態刷新未取得有效資料時不得繼續轉生")
_Responses.RebirthGetState = { { currentRankName = "Rank11" } }
_Responses.RebirthPurchase = { false, "NO_MONEY" }
_Step(6)
assert(tostring(_Labels[1].Value):find("轉生金額不足：NO_MONEY", 1, true), "只有已確認的 NO_MONEY 才解讀為金額不足")
local OriginalGetRebirthState = _Remotes.RebirthGetState.InvokeServer
local RefreshCalls = 0
--[[
	模擬轉生已接受但後續刷新失敗。
	@param self 狀態遠端替身。
	@param ... 原生狀態參數。
	@return 首次有效狀態；第二次拋出模擬錯誤。
]]
function _Remotes.RebirthGetState.InvokeServer(self, ...)
	self:FireServer(...)
	RefreshCalls += 1
	if RefreshCalls == 2 then error("refresh unavailable") end
	return { currentRankName = "Rank11" }
end
_Responses.RebirthPurchase = { true }
_Step(6)
assert(tostring(_Labels[1].Value):find("伺服器已接受轉生", 1, true)
	and Controller.RebirthStatus.RefreshError, "刷新失敗不能掩蓋已接受的轉生結果")
--[[
	模擬前置狀態 RPC 暫停，以驗證使用者關閉後不發送購買。
	@param self 狀態遠端替身。
	@param ... 原生狀態參數。
	@return 恢復後的狀態表。
]]
function _Remotes.RebirthGetState.InvokeServer(self, ...)
	self:FireServer(...)
	coroutine.yield()
	return { currentRankName = "Rank11" }
end
table.clear(_Calls)
_Step(6)
_Toggle("自動轉生", false)
_Step(1)
assert(not _Last("RebirthPurchase"), "等待狀態時停用，不得繼續送出轉生")
_Remotes.RebirthGetState.InvokeServer = OriginalGetRebirthState
_Toggle("自動轉生", true)
_Step(6)
assert(not _Last("BackpackEquipBest") and _Controls["配對收益與配置"], "最強角色須使用配對規劃並提供完整狀態，不再交給原生 Equip Best")
assert(not _Last("UpgradesStorePurchase") and tostring(_Labels[9].Value):find("轉生", 1, true), "自動轉生正在處理或目標未知時，升級必須保留資金")
_Toggle("自動轉生", false)
_Step(4)
assert(_Last("UpgradesStorePurchase").Args[1] == "Cheap" and _Last("UpgradesStorePurchase").Args[2] == 1, "關閉自動轉生後仍按順位與價格加權購買一級")
_Toggle("自動轉生", false)
PlayerData:SetAttribute("FoodNumber", 1000)
do
	local Enabled, OriginalPrompt = {}, _Environment.PairPromptCallback
	for _, Key in IntervalKeys do Enabled[Key] = Controller[Key] Window.Controls[Key]:Set(false) end
	local PreviousMode, PreviousAction = Controller.FeedMode, Controller.FeedAction
	_Controls["餵食分配模式"].Callback("只餵最強角色")
	_Controls["餵食方式"].Callback("一個一個餵")
	PlayerData:SetAttribute("FoodNumber", 123)
	--[[ @param Prompt 家中原生提示；保留 Food 不歸零，驗證不能因此延後轉生。 ]]
	_Environment.PairPromptCallback = function(Prompt)
		assert(Prompt == OwnMaxPrompt or Prompt == SecondMaxPrompt, "轉生前必須對每隻角色使用全部餵食提示")
		table.insert(_Calls, { Name = "BeforeRebirthFeed", Args = { Prompt } })
	end
	table.clear(_Calls)
	_Toggle("自動轉生", true)
	for Index = 1, 80 do _Step(0.1) if _Last("RebirthPurchase") then break end end
	assert(_Last("RebirthPurchase") and PlayerData:GetAttribute("FoodNumber") == 123, "Food 持續有剩餘仍須轉生")
	local Seen, PurchaseAt = {}, nil
	for Index, Call in _Calls do
		if Call.Name == "RebirthPurchase" then PurchaseAt = Index end
		if Call.Name == "BeforeRebirthFeed" then assert(not PurchaseAt, "全部角色餵食嘗試必須排在轉生之前") Seen[Call.Args[1]] = (Seen[Call.Args[1]] or 0) + 1 end
	end
	assert(Seen[OwnMaxPrompt] == 1 and Seen[SecondMaxPrompt] == 1, "不能只餵最高品質目標；每隻已放置角色各嘗試一次")
	assert(Controller.RebirthStatus.Food.Total == 2 and Controller.RebirthStatus.Food.Attempted == 2)
	assert(not Controller.bAutoFeed and Controller.FeedMode == "最高品質優先" and Controller.FeedAction == "一個一個餵", "轉生前餵食不可開啟或覆寫一般餵食設定")
	_Toggle("自動轉生", false)
	--[[ @param Prompt 第一隻用完食物後，仍需嘗試其他可操作的 MaxLevelUp 提示。 ]]
	_Environment.PairPromptCallback = function(Prompt)
		table.insert(_Calls, { Name = "BeforeRebirthFeed", Args = { Prompt } })
		PlayerData:SetAttribute("FoodNumber", 0)
	end
	table.clear(_Calls)
	_Toggle("自動轉生", true)
	for Index = 1, 100 do _Step(0.1) if _Last("RebirthPurchase") then break end end
	assert(_Last("RebirthPurchase") and Controller.RebirthStatus.Food.Attempted == 2 and PlayerData:GetAttribute("FoodNumber") == 0,
		"第一隻用完食物後不得漏掉其餘可操作角色的全部餵食嘗試")
	_Toggle("自動轉生", false)
	PlayerData:SetAttribute("FoodNumber", 123)
	--[[ @param Prompt 第一隻模擬提示呼叫卡住；第二隻仍須嘗試並繼續轉生。 ]]
	_Environment.PairPromptCallback = function(Prompt)
		table.insert(_Calls, { Name = "BeforeRebirthFeed", Args = { Prompt } })
		if Prompt == OwnMaxPrompt then while true do coroutine.yield() end end
	end
	table.clear(_Calls)
	_Toggle("自動轉生", true)
	for Index = 1, 100 do _Step(0.1) if _Last("RebirthPurchase") then break end end
	assert(_Last("RebirthPurchase") and Controller.RebirthStatus.Food.Items[1].State == "單格操作逾時", "單隻餵食卡住不可阻擋轉生")
	assert(_Last("BeforeRebirthFeed").Args[1] == SecondMaxPrompt, "逾時後應繼續處理其他角色")
	_Toggle("自動轉生", false)
	-- 整輪上限：更多角色的提示均卡住，仍須在30秒準備期限後繼續轉生。
	local Extra = {}
	for Index = 3, 15 do
		local Model = _Object("Model", "RebirthTest" .. Index, OwnPlot)
		Model:SetAttribute("IsPlacedCharacter", true)
		Model:SetAttribute("StandId", tostring(Index))
		local Part = _Object("Part", "PromptPart", Model)
		local Prompt = _Object("ProximityPrompt", "Max", Part)
		Prompt:SetAttribute("PromptType", "MaxLevelUp")
		Prompt:SetAttribute("StandId", tostring(Index))
		Prompt:SetAttribute("ServerEnabled", true)
		table.insert(Extra, Model)
	end
	--[[ @param Prompt 所有提示模擬永久等待。 ]]
	_Environment.PairPromptCallback = function(Prompt) while true do coroutine.yield() end end
	table.clear(_Calls)
	_Toggle("自動轉生", true)
	local Started = _Now
	for Index = 1, 150 do _Step(0.25) if _Last("RebirthPurchase") then break end end
	assert(_Last("RebirthPurchase") and _Now - Started <= 36 and Controller.RebirthStatus.Food.bTimedOut and Controller.RebirthStatus.Food.Elapsed <= 30.5,
		"整輪最多準備30秒（另保留原5秒輪次間隔），不可被通用20秒工作逾時反覆取消而永遠不轉生")
	_Toggle("自動轉生", false)
	for _, Model in Extra do Model:Destroy() end
	-- 關閉時取消父子工作，不能在下一次恢復時補送轉生。
	table.clear(_Calls)
	_Toggle("自動轉生", true)
	local BeforeCancel = Root.CFrame
	_Step(6)
	_Step(0.1)
	assert(Controller.RebirthStatus.Stage == "FeedBeforeRebirth", "取消案例須已真正進入餵食準備")
	_Toggle("自動轉生", false)
	for Index = 1, 40 do _Step(0.1) end
	assert(not _Last("RebirthPurchase") and Root.CFrame == BeforeCancel, "餵食準備中關閉應取消子工作、還原位置且不轉生")
	_Environment.PairPromptCallback = OriginalPrompt
	_Controls["餵食分配模式"].Callback(PreviousMode)
	_Controls["餵食方式"].Callback(PreviousAction)
	for Key, bValue in Enabled do Window.Controls[Key]:Set(bValue) end
	PlayerData:SetAttribute("FoodNumber", 1000)
end
_Toggle("自動買藥水", true)
do
	local Test = { Enabled = {}, Cash = PlayerData:GetAttribute("CashNumber"), Gems = PlayerData:GetAttribute("GemsNumber"), bAllowGems = Controller.bAllowGems }
	for _, Key in IntervalKeys do Test.Enabled[Key] = Controller[Key] Window.Controls[Key]:Set(false) end
	Constants.SecretStore.Offers = { A = { PotionKey = "Cash_L1", CashCost = 1000 }, B = { PotionKey = "Luck_L1", GemsCost = 25 },
		Owned = { AbilityName = "Astral Thoughts", GemsCost = 25 }, Held = { CashCost = 1 }, Hidden = { CashCost = 1 }, Robux = { DevProductId = 123 } }
	Test.State = { despawnAt = 160, serverTime = 100, offers = {
		A = { visible = true, stock = 2, cashCost = 10 }, B = { visible = true, stock = 1, gemsCost = 25 },
		Owned = { visible = true, stock = 1, owned = true }, Held = { visible = true, stock = 1 }, Hidden = { visible = false, stock = 1 }, Robux = { visible = true, stock = 1 },
	} }
	_Responses.SecretStoreGetState = { Test.State }
	PlayerData:SetAttribute("CashNumber", 100)
	PlayerData:SetAttribute("GemsNumber", 100)
	_Toggle("允許自動花費鑽石", true)
	assert(not Controller.bLimitedShopAllowGems and Window.Controls.bLimitedShopAllowGems.Section == Window.Controls.bAutoLimitedShop.Section,
		"限時商店鑽石預設禁止、同卡保存，且不能繼承一般買藥許可")
	_Toggle("自動購買限時商店物品", true)
	table.clear(_Calls)
	_Step(6)
	assert(_Last("SecretStorePurchase") and _Last("SecretStorePurchase").Args[1] == "A" and _Last("SecretStorePurchase").Args[2] == "Cash",
		"應使用動態價格，而不是以常數1000排除可買商品")
	Test.State.offers.A.stock = 0
	table.clear(_Calls)
	_Step(6)
	assert(not _Last("SecretStorePurchase"), "缺貨、已擁有、隱藏、版本暫停、Robux專屬與未允許的鑽石商品都不可購買")
	_Toggle("限時商店允許使用鑽石", true)
	_Step(6)
	assert(_Last("SecretStorePurchase").Args[1] == "B" and _Last("SecretStorePurchase").Args[2] == "Gems", "明確允許後才能用 Gems 購買限時商品")
	Test.State.offers.B.cashCost = 5
	_Step(6)
	assert(_Last("SecretStorePurchase").Args[2] == "Cash", "同商品雙貨幣可買時優先使用 Cash")
	_Responses.SecretStorePurchase = { false, "NO_CASH" }
	table.clear(_Calls)
	_Step(6)
	assert(#_Calls == 2 and tostring(_Labels[27].Value):find("NO_CASH", 1, true), "購買被拒絕時保留原因，不能觸發原生介面的 Robux 後備購買")
	_Responses.SecretStorePurchase = { true }
	Test.State.despawnAt = 99
	table.clear(_Calls)
	_Step(6)
	assert(not _Last("SecretStorePurchase") and tostring(_Labels[27].Value):find("等待 Selene", 1, true), "商店已消失時不可購買")
	Test.State.despawnAt = 160
	Test.State.offers.B.cashCost, Test.State.offers.B.gemsCost = 101, 101
	table.clear(_Calls)
	_Step(6)
	assert(not _Last("SecretStorePurchase"), "資金不足時不得發送購買或改用 Robux")
	Test.State.offers.B.gemsCost = 25
	Test.Invoker = _Remotes.SecretStoreGetState.InvokeServer
	--[[ @param self 限時商店狀態遠端。 @return 延遲提供的原生快照。 ]]
	function _Remotes.SecretStoreGetState.InvokeServer(self)
		self:FireServer()
		coroutine.yield()
		return Test.State
	end
	table.clear(_Calls)
	_Step(6)
	_Toggle("限時商店允許使用鑽石", false)
	_Step(0.1)
	assert(not _Last("SecretStorePurchase"), "查詢等待期間撤回 Gems 許可後不得購買")
	_Step(6)
	_Toggle("自動購買限時商店物品", false)
	_Step(0.1)
	assert(not _Last("SecretStorePurchase"), "查詢等待期間停用應取消工作，不再購買")
	_Remotes.SecretStoreGetState.InvokeServer = Test.Invoker
	_Responses.SecretStoreGetState = { { despawnAt = 0, serverTime = 100, offers = {} } }
	Constants.SecretStore.Offers = {}
	Constants.SecretStore2 = { Offers = { A = { CashCost = 4, PotionKey = "AngeliaPotion" } } }
	Constants.SecretStore3 = { Offers = { A = { GemsCost = 25, CashCost = 1, PotionKey = "YangPotion" } } }
	Constants.SecretStore4 = { Offers = { A = { GemsCost = 25, PotionKey = "SashaPotion" } } }
	_Responses.SecretStore2GetState = { { despawnAt = 160, serverTime = 100, offers = { A = { visible = true, stock = 1 } } } }
	_Responses.SecretStore3GetState = { { active = true, timed = true, despawnAt = 160, serverTime = 100, offers = { A = { visible = true, stock = 1 } } } }
	_Responses.SecretStore4GetState = { { active = true, timed = false, despawnAt = 0, serverTime = 100, offers = { A = { visible = true, stock = 1 } } } }
	_Toggle("自動購買限時商店物品", true)
	table.clear(_Calls)
	_Step(6)
	assert(_Last("SecretStore2Purchase") and _Last("SecretStore2Purchase").Args[2] == "Cash", "Selene 不在時仍要處理 Angelia")
	_Toggle("限時商店允許使用鑽石", true)
	_Step(6)
	assert(_Last("SecretStore3Purchase") and _Last("SecretStore3Purchase").Args[2] == "Gems", "Yang 必須使用原生已確認的 Gems 模式，不猜測 Cash 協定")
	_Step(6)
	assert(_Last("SecretStore4Purchase") and _Last("SecretStore4Purchase").Args[2] == "Gems", "Sasha 管理員常駐狀態 active=true／timed=false／despawnAt=0 仍可購買")
	Test.SecretRemote, _Remotes.SecretStoreGetState = _Remotes.SecretStoreGetState, nil
	table.clear(_Calls)
	_Step(6)
	assert(_Last("SecretStore2Purchase"), "單一商店 Remote 缺失不能阻擋其他商店")
	_Remotes.SecretStoreGetState = Test.SecretRemote
	_Responses.SecretStore2GetState[1].despawnAt = 0
	_Responses.SecretStore4GetState[1].active = false
	_Toggle("限時商店允許使用鑽石", false)
	table.clear(_Calls)
	_Step(6)
	assert(not _Last("SecretStore3Purchase") and not _Last("SecretStore4Purchase") and not _Last("SecretStore2Purchase"),
		"共用鑽石許可須保護所有商店；Yang 有 Cash 價格也不能走未確認的 Cash 按鈕")
	_Responses.SecretStore3GetState[1].active = false
	_Toggle("限時商店允許使用鑽石", true)
	_Step(6)
	assert(not _Last("SecretStore3Purchase") and not _Last("SecretStore4Purchase"), "active=false 時不能以尚未過期的時間繞過商店狀態")
	_Toggle("自動購買限時商店物品", false)
	_Toggle("限時商店允許使用鑽石", false)
	Constants.SecretStore2, Constants.SecretStore3, Constants.SecretStore4 = nil, nil, nil
	PlayerData:SetAttribute("CashNumber", Test.Cash)
	PlayerData:SetAttribute("GemsNumber", Test.Gems)
	_Toggle("允許自動花費鑽石", Test.bAllowGems)
	for Key, bValue in Test.Enabled do Window.Controls[Key]:Set(bValue) end
end
_Toggle("自動喝藥水", true)
_Step(1)
assert(not _Last("BoostsStorePurchase") and not _Last("PotionUse"), "沒有白名單不得消耗藥水")
_Toggle("Cash Potion Lvl. 1", true)
_Step(6)
assert(_Last("BoostsStorePurchase").Args[1] == "Offer1", "購買已選藥水")
assert(_Last("PotionUse").Args[1] == Potion, "PotionUse 必須接收 Tool")
_Responses.PotionGetState = { { serverTime = 100, potions = { { key = "Cash_L1", endTime = 200 } } } }
table.clear(_Calls)
_Step(6)
assert(not _Last("PotionUse"), "效果超過一分鐘時不得重喝")
_Toggle("Cash Potion Lvl. 1", false)
_Toggle("Luck", true)
table.clear(_Calls)
_Step(6)
assert(not _Last("BoostsStorePurchase"), "未允許鑽石時不可買 Gems 藥水")
_Toggle("允許自動花費鑽石", true)
_Step(6)
assert(_Last("BoostsStorePurchase").Args[2] == "Gems", "明確開啟後可使用 Gems")
_Toggle("自動研究", true)
_Toggle("自動餵食角色", true)
_Toggle("自動收集食物", true)
_FishingCallback({ kind = "Started" })
table.clear(_Calls)
_Step(1)
assert(not _Last("FishingCancel") and _Last("ResearchStart") and not _Last("CollectFood") and not _Last("Feed")
	and Root.CFrame.Position == Rbx.Vector3.zero, "研究應在原地開始，不得取消或移動手動釣魚回合")
_FishingCallback({ kind = "Stopped" })
_Toggle("自動餵食角色", false)
_Toggle("自動收集食物", false)
_Toggle("自動研究", false)
local ResearchGetInvoker = _Remotes.ResearchGetData.InvokeServer
--[[
	暫停研究查詢，驗證關閉期間不會繼續送出開始請求。
	@param self 研究查詢遠端。
	@param ... 原生查詢參數。
	@return 目前研究資料。
]]
function _Remotes.ResearchGetData.InvokeServer(self, ...)
	self:FireServer(...)
	coroutine.yield()
	return _Responses.ResearchGetData[1]
end
table.clear(_Calls)
_Toggle("自動研究", true)
_Step(6)
assert(_Last("ResearchGetData") and not _Last("ResearchStart"), "研究查詢等待期間不應提早開始")
_Toggle("自動研究", false)
_Step(0.5)
assert(not _Last("ResearchStart") and Root.CFrame.Position == Rbx.Vector3.zero, "查詢期間停用不得繼續開始研究或移動")
-- 查詢恢復時其他功能已持有位移，研究也不能搶移動或因此跳過。
Food:SetAttribute("FoodPromptParked", false)
table.clear(_Calls)
_Toggle("自動研究", true)
_Toggle("自動收集食物", true)
_Step(6)
assert(Root.CFrame.Position.X > 900 and not _Last("ResearchStart"), "收集移動應不被等待中的研究查詢影響")
_Step(0.5)
assert(_Last("ResearchStart") and _Last("ResearchStart").Position.X > 900 and Root.CFrame.Position.X > 900
	and not _Last("FishingCancel"), "研究應在其他工作的位置直接開始，不搶移動也不取消釣魚")
_Toggle("自動收集食物", false)
_Toggle("自動研究", false)
Food:SetAttribute("FoodPromptParked", false)
_Remotes.ResearchGetData.InvokeServer = ResearchGetInvoker
_Toggle("自動研究", true)
_Step(6)
assert(_Last("ResearchStart").Args[1] == "A", "不可跳過研究前置")
assert(Root.CFrame.Position == Rbx.Vector3.zero and _Last("ResearchStart").Position == Rbx.Vector3.zero,
	"研究請求應從原位置發送，全程不前往研究所")
_Responses.ResearchGetData = { { owned = { "A" }, active = {}, slots = 1 } }
_Step(6)
_Step(0.5)
assert(_Last("ResearchStart").Args[1] == "B", "前置完成後應選擇 B")
_Responses.ResearchGetData = { { owned = { "A" }, active = { { id = "B" } }, slots = 1 } }
table.clear(_Calls)
_Step(6)
assert(not _Last("ResearchStart"), "研究欄位滿時不可開始新研究")
-- 使用真實結構的 WorldNodeInfo.Configuration，研究板完全未載入也能先排序可研究項目。
_bResearchMetadata = true
Nodes.Parent = nil
StreamModule.Parent = nil
_bGround = false
local PriorityCases = { { "金錢項目優先", "B1" }, { "藥水項目優先", "A1" }, { "自動項目優先", "B2" }, { "最低費用優先", "A1" } }
for _, Case in PriorityCases do
	_Controls["研究優先條件"].Callback(Case[1])
	_Responses.ResearchGetData = { { owned = { "Center" }, active = {}, slots = 2 } }
	_Responses.ResearchStart = { { ok = true, data = { owned = { "Center" }, slots = 2, active = {
		{ id = Case[2], e = TestEnvironment.os.time() + 3661 }, { id = "C5", e = TestEnvironment.os.time() + 61 },
	} } } }
	table.clear(_Calls)
	_Step(6)
	assert(Root.CFrame.Position == Rbx.Vector3.zero and _Last("ResearchStart"), "研究板未載入時也應直接從原地研究")
	_Step(0.5)
	assert(_Last("ResearchStart").Args[1] == Case[2] and Root.CFrame.Position == Rbx.Vector3.zero,
		"研究應按使用者類別選擇，位置保持不變")
	local Progress = _Controls["進行中的研究"].Control.Content
	assert(Progress:find(Case[2], 1, true) and Progress:find("C5", 1, true) and Progress:match("剩餘 %d%d:%d%d:%d%d"),
		"UI 必須列出每個研究槽的項目與倒數")
	table.clear(_Calls)
	_Step(2)
	assert(_Controls["進行中的研究"].Control.Content ~= Progress and not _Last("ResearchGetData"),
		"倒數每秒更新，不需每秒查詢伺服器")
end
_ResearchCallback({ owned = { "Center" }, slots = 2, active = { { id = "B1", e = TestEnvironment.os.time() - 1 } } })
assert(_Controls["進行中的研究"].Control.Content:find("Rich", 1, true)
	and _Controls["進行中的研究"].Control.Content:find("等待完成同步", 1, true), "倒數歸零不能自行宣稱研究完成")
_ResearchCallback({ owned = { "Center", "B1" }, slots = 2, active = {} })
assert(_Controls["進行中的研究"].Control.Content == "目前沒有進行中的研究", "伺服器更新完成後才清除研究列")
-- 優先類別的項目無法負擔時改選其他可研究項目，不因類別卡死。
ResearchDefinitions.B2:SetAttribute("CostGems", 2000)
_Responses.ResearchGetData = { { owned = { "Center" }, active = {}, slots = 1 } }
_Responses.ResearchStart = { { ok = true } }
_Controls["研究優先條件"].Callback("自動項目優先")
table.clear(_Calls)
_Step(6)
_Step(0.5)
assert(_Last("ResearchStart").Args[1] == "A1", "優先項目資金不足時應選可負擔的其他項目")
ResearchDefinitions.B2:SetAttribute("CostGems", 1)
_Toggle("允許自動花費鑽石", false)
_Toggle("允許研究花費鑽石", false)
table.clear(_Calls)
_Step(6)
_Step(0.5)
assert(_Last("ResearchStart").Args[1] == "A1", "未允許 Gems 時不能為優先類別自行花費鑽石")
-- 七個原生已解鎖項目全都需 Gems：仍須列為已解鎖，不能誤寫成無可研究。
local AvailableResearch = {}
for Index = 1, 7 do
	local Definition = _Object("Configuration", "Available" .. Index, ResearchDefinitions)
	Definition:SetAttribute("DisplayName", "Available Research " .. Index)
	Definition:SetAttribute("SnapTo", "Center")
	Definition:SetAttribute("CostCash", 1)
	Definition:SetAttribute("CostGems", 1)
	table.insert(AvailableResearch, Definition)
end
_Responses.ResearchGetData = { { owned = { "Center", "A1", "B1", "B2" }, active = {}, slots = 1 } }
table.clear(_Calls)
_Step(6)
assert(not _Last("ResearchStart") and Controller.ResearchSelection.Unlocked == 7 and Controller.ResearchSelection.Gems == 7
	and Controller.ResearchSelection.Ready == 0 and not Controller.bResearchAllowGems, "七個已解鎖項目不得繞過研究的 Gems 許可")
assert(tostring(_Labels[8].Value):find("已解鎖 7 項", 1, true) and not tostring(_Labels[8].Value):find("無可研究", 1, true),
	"必須區分原生已解鎖與允許自動消費的項目")
local SelectionText = _Controls["研究篩選狀態"].Control.Content
assert(SelectionText:find("Available Research 7", 1, true) and SelectionText:find("未允許花費鑽石", 1, true),
	"完整列出被阻擋項目與原因，不能只有會被截斷的單行計數")
assert(Window.Controls.bResearchAllowGems.Section == Window.Controls.bAutoResearch.Section
	and Window.Controls.bAllowGems.Section == Window.Controls.bAutoBuyPotions.Section, "研究與買藥的鑽石許可應各自在對應卡片")
_Toggle("允許研究花費鑽石", true)
_Step(6)
_Step(0.5)
assert(_Last("ResearchStart").Args[1] == "Available1" and Controller.ResearchSelection.Ready == 7,
	"使用者明確允許後應正常開始研究，無需重開功能")
assert(not Controller.bAllowGems, "研究使用 Gems 時不得連動開啟買藥許可")
_Toggle("允許自動花費鑽石", true)
for _, Definition in AvailableResearch do Definition:Destroy() end
-- 原生畫面已載入時，以目前板上的條件為準，備援資料不得覆蓋更新後的費用。
Nodes.Parent = Research
local LiveResearch = _Object("Part", "B2", Nodes)
LiveResearch.CFrame = Rbx.CFrame.new(-750, 0, 0)
LiveResearch:SetAttribute("SnapTo", "Center")
LiveResearch:SetAttribute("CostCash", 20)
LiveResearch:SetAttribute("CostGems", 0)
ResearchDefinitions.B2:SetAttribute("CostGems", 2000)
_Responses.ResearchGetData = { { owned = { "Center", "A", "B" }, active = {}, slots = 1 } }
table.clear(_Calls)
_Step(6)
_Step(0.5)
assert(_Last("ResearchStart").Args[1] == "B2", "目前可研究的板上項目不能被備援資料的舊費用排除")
_Responses.ResearchStart = { { ok = false, err = "TEST_REFUSED" } }
table.clear(_Calls)
_Step(6)
assert(tostring(_Labels[8].Value):find("TEST_REFUSED", 1, true) and Root.CFrame.Position == Rbx.Vector3.zero
	and not _Last("FishingCancel"), "原地研究被拒絕時應保留原因，不能改成傳送或宣稱成功")
_Responses.ResearchStart = { { ok = true } }
LiveResearch:Destroy()
_Controls["研究優先條件"].Callback("藥水項目優先")
assert(Window.Controls.ResearchPriority.Section == Window.Controls.bAutoResearch.Section, "優先條件與研究進度必須同卡")
Nodes.Parent = Research
StreamModule.Parent = Modules
_bGround = true
_bResearchMetadata = false
_Responses.ResearchGetData = { { owned = { "A" }, active = { { id = "B" } }, slots = 1 } }
_Toggle("自動餵食角色", true)
PlayerData:SetAttribute("FoodNumber", 0)
_Step(1)
assert(not _Last("CollectFood") and not _Last("Feed") and Root.CFrame.Position == Rbx.Vector3.zero,
	"只開餵食且食物不足時不可自動前往菜園")
assert(not Controller.bAutoCollectFood, "舊設定缺少新收集開關時預設關閉")
_Toggle("自動餵食角色", false)
_Toggle("自動收集食物", true)
_Step(3)
assert(Root.CFrame.Position.X > 900 and not _Last("Feed"), "獨立收集開關應前往菜園")
_Toggle("自動餵食角色", false)
assert(Root.CFrame.Position.X > 900, "關閉餵食不能中斷收集的位移")
_Step(0.5)
assert(_Last("CollectFood") and not _Last("Feed"), "只開收集只能拾取食物，不能餵角色")
_Step(0.5)
_Step(0.5)
assert(PlayerData:GetAttribute("FoodNumber") == 100 and Root.CFrame.Position == Rbx.Vector3.zero and not _Last("Feed"),
	"獨立收集應增加食物並返回，不消耗食物餵角色")
_Toggle("自動收集食物", false)
Food:SetAttribute("FoodPromptParked", false)
table.clear(_Calls)
_Toggle("自動收集食物", true)
_Step(3)
assert(Root.CFrame.Position.X > 900, "收集前往菜園期間應持有自己的位移")
_Toggle("自動收集食物", false)
_Step(0.5)
assert(not _Last("CollectFood") and Root.CFrame.Position == Rbx.Vector3.zero,
	"取消收集應立即返回，不得在之後觸發拾取")
Food:SetAttribute("FoodPromptParked", true)
table.clear(_Calls)
_Toggle("自動餵食角色", true)
_Step(3)
local FeedingPosition = Root.CFrame.Position
_Toggle("自動收集食物", false)
assert(Root.CFrame.Position == FeedingPosition and FeedingPosition ~= Rbx.Vector3.zero,
	"關閉收集不得還原餵食持有的位移")
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == SecondPrompt and Root.CFrame.Position == Rbx.Vector3.zero and not _Last("CollectFood"),
	"獨立餵食應只用現有食物餵自己角色並返回，不收集")
_Step(3)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == SecondPrompt, "平均分配應優先高品質，不能因Common累計花費較少就改餵低品質")
OwnModel:SetAttribute("CPS", 10000)
_Controls["餵食分配模式"].Callback("只餵最強角色")
assert(Controller.FeedMode == "最高品質優先", "舊設定值必須對應新策略名稱")
local QualityOption = _Controls["餵食分配模式"].Options[2]
assert(QualityOption.Name == "最高品質優先" and QualityOption.Value == "只餵最強角色", "顯示新名稱但保留既有儲存值")
_Step(3)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == SecondPrompt, "Rare 即使 CPS 較低，也必須優先於 CPS 10000 的 Common")
OwnModel:SetAttribute("Rarity", "Rare")
PlayerData:SetAttribute("FoodNumber", 1000)
table.clear(_Calls)
_Step(3)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == OwnPrompt, "同品質應比較 CPS，優先餵較強者")
OwnModel:SetAttribute("Rarity", "Common")
SecondModel:SetAttribute("Rarity", nil)
table.clear(_Calls)
_Step(3)
assert(not _Last("Feed") and Root.CFrame.Position == Rbx.Vector3.zero, "品質資料不完整時不可猜測最高品質")
SecondModel:SetAttribute("Rarity", "Rare")
OwnModel:SetAttribute("CPS", 10)
SecondPrompt.Enabled = false
SecondPrompt:SetAttribute("ServerEnabled", false)
table.clear(_Calls)
_Step(3)
_Step(0.5)
_Step(0.5)
assert(not _Last("Feed"), "最強角色提示不可用時不可改餵較弱角色")
SecondPrompt.Enabled = true
SecondPrompt:SetAttribute("ServerEnabled", true)
_Controls["餵食分配模式"].Callback("平均分配")
_Step(3)
assert(Root.CFrame.Position ~= Rbx.Vector3.zero, "前往餵食期間持有暫時位移")
_Toggle("自動餵食角色", false)
assert(Root.CFrame.Position == Rbx.Vector3.zero, "等待時停用餵食應立即返回")
_Toggle("自動換最強裝備（魚竿）", false)
assert(WeakRod.Parent == Character, "停用應還原先前工具")
-- 使用與快照相同的遠處 Enabled=false／ServerEnabled=true，並只保留 Stand Folder 資料。
OwnModel.Parent, SecondModel.Parent = nil, nil
local StandOne = _Object("Folder", "1", OwnPlot)
StandOne:SetAttribute("HasCharacter", true)
StandOne:SetAttribute("CPS", 10)
StandOne:SetAttribute("Rarity", "Common")
StandOne:SetAttribute("Level", 1)
local StandTwo = _Object("Folder", "2", OwnPlot)
StandTwo:SetAttribute("HasCharacter", true)
StandTwo:SetAttribute("CPS", 100)
StandTwo:SetAttribute("Rarity", "Rare")
StandTwo:SetAttribute("Level", 1)
_Controls["餵食分配模式"].Callback("只餵最強角色")
Food:SetAttribute("FoodPromptParked", false)
PlayerData:SetAttribute("FoodNumber", 0)
table.clear(_Calls)
_Toggle("自動餵食角色", true)
_Toggle("自動收集食物", true)
_Step(3)
assert(not OwnPrompt.Enabled and not SecondPrompt.Enabled and Root.CFrame.Position.X > 900,
	"菜園收集時角色提示應處於遠距離停用狀態")
_Step(0.5)
assert(_Last("CollectFood") and not _Last("Feed"), "先收集後才能前往遠處角色")
_Step(0.5)
_Step(0.5)
_Step(0.5)
_Step(2)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == SecondPrompt and Root.CFrame.Position == Rbx.Vector3.zero,
	"兩個開關同時開啟時先收集，再由餵食的下輪前往角色，不依賴視覺模型已載入")
_Toggle("自動餵食角色", false)
_Toggle("自動收集食物", false)
OwnModel.Parent, SecondModel.Parent = OwnPlot, OwnPlot
StandOne:Destroy()
StandTwo:Destroy()
-- 嚴格最強模式不足就跳過；平均模式仍可選其他可負擔角色。
_Controls["餵食方式"].Callback("全部餵食")
for _, Mode in { "只餵最強角色", "平均分配" } do
	_Controls["餵食分配模式"].Callback(Mode)
	PlayerData:SetAttribute("FoodNumber", 15)
	table.clear(_Calls)
	_Toggle("自動餵食角色", true)
	_Step(3)
	_Step(0.5)
	_Step(0.5)
	if Mode == "只餵最強角色" then
		assert(not _Last("Feed") and PlayerData:GetAttribute("FoodNumber") == 15,
			"最強角色需 20 Food，只有 15 時不得改餵只需 10 的弱角色")
	else
		assert(_Last("Feed").Args[1] == OwnMaxPrompt and PlayerData:GetAttribute("FoodNumber") == 5,
			"平均模式仍可選可負擔角色並使用 MaxLevelUp")
	end
	_Toggle("自動餵食角色", false)
end
PlayerData:SetAttribute("FoodNumber", 95)
_Controls["餵食分配模式"].Callback("只餵最強角色")
table.clear(_Calls)
_Toggle("自動餵食角色", true)
_Step(3)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == SecondMaxPrompt and PlayerData:GetAttribute("FoodNumber") == 15,
	"全部餵食須讓原生 MaxLevelUp 一次消耗可用食物")
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == SecondMaxPrompt and PlayerData:GetAttribute("FoodNumber") == 15
	and Root.CFrame.Position == Rbx.Vector3.zero, "全部餵最強後有餘額也不可改餵較弱角色")
_Toggle("自動餵食角色", false)
_Controls["餵食方式"].Callback("一個一個餵")
PlayerData:SetAttribute("FoodNumber", 15)
table.clear(_Calls)
_Toggle("自動餵食角色", true)
_Step(3)
_Step(0.5)
_Step(0.5)
assert(not _Last("Feed") and PlayerData:GetAttribute("FoodNumber") == 15, "逐個餵食也不得在最強角色食物不足時換人")
PlayerData:SetAttribute("FoodNumber", 25)
_Step(3)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == SecondPrompt and PlayerData:GetAttribute("FoodNumber") == 5,
	"後續食物足夠時應恢復餵食最強角色")
_Toggle("自動餵食角色", false)
-- 原生提示報價優先：角色等級尚未同步、Constants 估算較高時仍能按原生費用餵食。
local OriginalSingleText, OriginalMaxText = SecondPrompt.ActionText, SecondMaxPrompt.ActionText
SecondModel:SetAttribute("Level", nil)
SecondPrompt.ActionText, SecondMaxPrompt.ActionText = "Level Up (16 Food)", "Max Level Up (999 Food)"
_FeedCostOverrides[SecondPrompt], _FeedCostOverrides[SecondMaxPrompt] = 16, 16
_Controls["餵食方式"].Callback("全部餵食")
PlayerData:SetAttribute("FoodNumber", 16)
table.clear(_Calls)
_Toggle("自動餵食角色", true)
_Step(3)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed").Args[1] == SecondMaxPrompt and PlayerData:GetAttribute("FoodNumber") == 0,
	"原生單次價格 16 可負擔時，不應被未知等級、公式價格或 Max 顯示總額排除")
_Toggle("自動餵食角色", false)
PlayerData:SetAttribute("FoodNumber", 15)
table.clear(_Calls)
_Toggle("自動餵食角色", true)
_Step(3)
assert(not _Last("Feed") and tostring(_Labels[5].Value):find("Food 不足", 1, true)
	and _Controls["餵食判斷"].Control.Content:find("原生提示價格", 1, true), "確實不足時保留目標，顯示原生價格與目前 Food")
_Toggle("自動餵食角色", false)
-- 縮寫的四捨五入不得造成錯誤排除，接近顯示價時仍只對原目標請遊戲確認。
SecondPrompt.ActionText = "Level Up (1.1K Food)"
_FeedCostOverrides[SecondMaxPrompt] = 1096
PlayerData:SetAttribute("FoodNumber", 1096)
table.clear(_Calls)
_Toggle("自動餵食角色", true)
_Step(3)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed") and PlayerData:GetAttribute("FoodNumber") == 0, "1096 被顯示成 1.1K 時不能誤認為必須有 1100 Food")
_Toggle("自動餵食角色", false)
SecondPrompt.ActionText = "Level Up (16Unknown Food)"
table.clear(_Calls)
_Toggle("自動餵食角色", true)
PlayerData:SetAttribute("FoodNumber", 100)
_Step(3)
assert(not _Last("Feed") and _Controls["餵食判斷"].Control.Content:find("角色等級尚未同步", 1, true),
	"未知價格字尾與缺少資料不得被當成免費餵食")
_Toggle("自動餵食角色", false)
SecondPrompt.ActionText, SecondMaxPrompt.ActionText = OriginalSingleText, OriginalMaxText
_FeedCostOverrides[SecondPrompt], _FeedCostOverrides[SecondMaxPrompt] = nil, nil
local FreshStand = _Object("Folder", "2", OwnPlot)
FreshStand:SetAttribute("HasCharacter", true)
FreshStand:SetAttribute("Rarity", "Rare")
FreshStand:SetAttribute("Level", 1)
FreshStand:SetAttribute("CPS", 100)
PlayerData:SetAttribute("FoodNumber", 20)
table.clear(_Calls)
_Toggle("自動餵食角色", true)
_Step(3)
_Step(0.5)
_Step(0.5)
assert(_Last("Feed") and PlayerData:GetAttribute("FoodNumber") == 0, "視覺角色等級缺少時應使用同展台已同步的 Stand 資料")
_Toggle("自動餵食角色", false)
FreshStand:Destroy()
SecondModel:SetAttribute("Level", 1)
_Controls["餵食方式"].Callback("一個一個餵")
-- 原生 Auto Fish 已由玩家開啟、自行續釣，沒有本腳本拋竿／開啟開關紀錄時也必須能交接。
Root.CFrame = ShoreBeforeCollect
PlayerData:SetAttribute("AutoFishOwned", true)
PlayerData:SetAttribute("FoodNumber", 25)
NativePurchase.Visible, NativeRobux.Visible = false, false
NativeAutoOn.Enabled, NativeAutoOff.Enabled = true, false
Food:SetAttribute("FoodPromptParked", false)
_Toggle("自動釣魚", true)
_FishingCallback({ kind = "Started" })
_FishingCallback({ kind = "Hooked" })
_Toggle("自動餵食角色", true)
_Toggle("自動收集食物", true)
_NativeToggleDelay = 0.5
table.clear(_Calls)
_Step(3)
assert(not _Last("FishingCancel") and NativeAutoOn.Enabled and Root.CFrame == ShoreBeforeCollect,
	"Auto Fish 尚未關閉時應保留移動權等待，不立即結束交接或取消回合")
assert(not _Environment.RenderingService.bEnabled, "等待原生 Auto Fish 關閉期間必須持續關閉 3D")
_Step(0.25)
assert(NativeAutoOn.Enabled and not _Last("FishingCancel"), "延遲更新前不能重複切換或繼續操作")
assert(not _Environment.RenderingService.bEnabled, "取消尚未送出時不得因其他工作正在等待而開啟 3D")
_Step(0.3)
_NativeToggleDelay = 0
assert(_Last("FishingCancel") and not NativeAutoOn.Enabled and WeakRod.Parent == Backpack
	and Root.CFrame == ShoreBeforeCollect, "原生自行續釣也須關閉 Auto Fish、收起魚竿並等待取消確認")
assert(not _Environment.RenderingService.bEnabled, "送出取消不代表釣魚已停止，等待伺服器確認期間仍須關閉 3D")
assert(tostring(_Labels[5].Value):find("等待", 1, true) and tostring(_Labels[25].Value):find("等待", 1, true),
	"等待交接時不得停留在前往目標的舊訊息")
_FishingCallback({ kind = "Stopped", reason = "CANCELED" })
PlayerData:SetAttribute("BPCatchLock", true)
_Step(0.1)
assert(Root.CFrame == ShoreBeforeCollect and not _Last("Feed"), "取消已確認但本地鎖未釋放時應持續等待")
assert(not _Environment.RenderingService.bEnabled, "本地釣魚鎖未解除時仍不可開啟渲染")
PlayerData:SetAttribute("BPCatchLock", false)
_Step(0.1)
assert(_Environment.RenderingService.bEnabled, "只有取消確認、釣魚鎖解除且開始餵食移動時才開啟 3D")
_Step(0.5)
_Step(0.4)
assert(_Last("Feed") and PlayerData:GetAttribute("FoodNumber") == 5 and Root.CFrame == ShoreBeforeCollect
	and WeakRod.Parent == Character and NativeAutoOn.Enabled, "先餵食完成、返回並恢復原魚竿與 Auto Fish")
assert(not _Environment.RenderingService.bEnabled, "恢復連續自動釣魚後立即維持關閉 3D")
_Toggle("自動餵食角色", false)
_FishingCallback({ kind = "Started" })
table.clear(_Calls)
_bIgnoreNativeToggle, _bNativeConnectionsAvailable = true, true
_Step(2)
assert(not _Last("FishingCancel") and NativeAutoOn.Enabled, "一般觸發無效時先等待，不能強行移動")
_Step(1.1)
_Step(0.1)
assert(_Last("NativeAutoFishCallback") and not _Last("UnexpectedNativeCallback"),
	"應跳過停用／外部連線，單一有效回呼確認關閉後不再切換")
_bIgnoreNativeToggle, _bNativeConnectionsAvailable = false, false
assert(_Last("FishingCancel") and not NativeAutoOn.Enabled, "食物不足後應由收集功能取得下一次交接")
_FishingCallback({ kind = "Stopped", reason = "CANCELED" })
_Step(0.1)
_Step(0.5)
_Step(0.4)
assert(_Last("CollectFood") and PlayerData:GetAttribute("FoodNumber") == 105 and Root.CFrame == ShoreBeforeCollect
	and WeakRod.Parent == Character and NativeAutoOn.Enabled, "原生續釣期間也應完成收集，再恢復魚竿與釣魚")
_Toggle("自動餵食角色", false)
_Toggle("自動收集食物", false)
-- 所有按鈕入口都沒有切換時必須有限等待、清理並顯示實際狀態，不能假裝已關閉。
Food:SetAttribute("FoodPromptParked", false)
_FishingCallback({ kind = "Started" })
_bIgnoreNativeToggle, _bNativeConnectionsAvailable, _bIgnoreNativeCallback = true, true, true
_Toggle("自動收集食物", true)
table.clear(_Calls)
_Step(3)
_Step(1.1)
_Step(2.1)
assert(not _Last("CollectFood") and not _Last("FishingCancel") and Root.CFrame == ShoreBeforeCollect
	and tostring(_Labels[25].Value):find("關閉確認逾時", 1, true), "按鈕未切換時要逾時還原且顯示原因")
_Toggle("自動收集食物", false)
_bIgnoreNativeToggle, _bNativeConnectionsAvailable, _bIgnoreNativeCallback = false, false, false
_Toggle("自動釣魚", false)
_FishingCallback({ kind = "Stopped", reason = "CANCELED" })
NativeAutoOn.Enabled, NativeAutoOff.Enabled = false, true
NativePurchase.Visible, NativeRobux.Visible = true, true
PlayerData:SetAttribute("AutoFishOwned", false)
Root.CFrame = Rbx.CFrame.new()
_Toggle("自動購買可買的最強魚竿", true)
table.clear(_Calls)
_Step(1)
assert(_Last("FishingStorePurchase").Args[1] == "Good" and _Last("FishingStorePurchase").Args[2] == "Cash",
	"依實際強度選最強可買魚竿，不選高價但較弱、買不起、未解鎖或未開放商品")
assert(_Last("FishingStorePurchase").Args.n == 2, "購買必須使用已確認的 OfferKey 與 Cash 協定")
_RodState.owned.Good = true
table.clear(_Calls)
_Step(6)
assert(not _Last("FishingStorePurchase"), "不能重複買已擁有魚竿或買更弱的替代品")
_RodState.unlock.Material.materials[1].have = 2
_Step(6)
assert(_Last("FishingStorePurchase").Args[1] == "Material" and _Last("FishingStorePurchase").Args[2] == "DepositAll",
	"最強候選材料足夠時應先交付，不能直接跳過解鎖")
_RodState.unlock.Material.ready = true
_Step(6)
assert(_Last("FishingStorePurchase").Args[1] == "Material" and _Last("FishingStorePurchase").Args[2] == "Unlock",
	"下一輪確認材料 ready 才送出 Unlock")
_RodState.owned.Material = true
table.clear(_Calls)
_Step(6)
assert(not _Last("FishingStorePurchase"), "材料魚竿購買完成後不能繼續買較弱商品")
_RodState.owned.Material = false
PlayerData:SetAttribute("CashNumber", 0)
_Step(6)
assert(not _Last("FishingStorePurchase"), "Cash 不足時不得交付材料或購買")
PlayerData:SetAttribute("CashNumber", 1000)
_Responses.FishingStoreGetState = { false }
_Step(6)
assert(not _Last("FishingStorePurchase") and tostring(_Labels[12].Value):find("格式已變更", 1, true),
	"商店狀態無效時應顯示原因並停止購買")
_Responses.FishingStoreGetState = { _RodState }
local OriginalStoreGet = _Remotes.FishingStoreGetState.InvokeServer
--[[
	模擬魚竿狀態查詢等待，驗證停用時不消耗材料或金錢。
	@param self 狀態 Remote。
	@param ... 原始參數。
	@return 本輪商店狀態。
]]
function _Remotes.FishingStoreGetState.InvokeServer(self, ...)
	self:FireServer(...)
	coroutine.yield()
	return _RodState
end
table.clear(_Calls)
_Step(6)
_Toggle("自動購買可買的最強魚竿", false)
_Step(1)
assert(not _Last("FishingStorePurchase"), "等待狀態時關閉不得繼續購買")
_Remotes.FishingStoreGetState.InvokeServer = OriginalStoreGet
_RodState.owned.Material = true
local WorldCountBefore = #World:GetDescendants()
_Toggle("防止閒置自動重新加入", true)
_Step(1)
assert(not _Environment.AutoRejoinScript.Enabled and _Environment.AntiIdleScript.Enabled, "只停用遊戲閒置重連，保留防閒置")
_Environment.AutoRejoinScript.Enabled = true
_Step(15)
assert(not _Environment.AutoRejoinScript.Enabled, "重連腳本重新啟用後，下一輪必須再次停用")
_Toggle("防止閒置自動重新加入", false)
assert(_Environment.AutoRejoinScript.Enabled, "關閉應恢復自己停用的腳本")
_Environment.AutoRejoinScript.Enabled = false
_Toggle("防止閒置自動重新加入", true)
_Step(15)
_Toggle("防止閒置自動重新加入", false)
assert(not _Environment.AutoRejoinScript.Enabled, "原本停用的腳本不可被恢復成啟用")
_Environment.AutoRejoinScript.Enabled = true
local RootFrameBefore, PondFrameBefore = Root.CFrame, Pond.CFrame
assert(not Controller.bLowEffects and Particle.Enabled and not DisabledParticle.Enabled, "首次使用不能默認關閉遊戲特效")
assert(Controller.bRenderingEnabled and not Controller.bDisable3dRendering and not Window.Controls.bDisable3dRendering:Get(), "關閉 3D 渲染開關預設關閉，維持 3D 顯示")
_Toggle("關閉 3D 渲染", true)
assert(not _Environment.RenderingService.bEnabled and not Controller.bRenderingEnabled, "未開低特效也可關閉 3D")
_Toggle("關閉 3D 渲染", false)
assert(_Environment.RenderingService.bEnabled and Controller.bRenderingEnabled)
_Toggle("效能模式（低特效）", true)
_Step(1)
assert(_Environment.PerformanceMock.Starts == 1, "低特效必須啟動共用引擎安全模式")
_Toggle("關閉 3D 渲染", true)
assert(not _Environment.RenderingService.bEnabled and _Environment.RenderingService.EngineCalls == 1,
	"引擎已啟動時應沿用其渲染 API")
for _, Visual in Visuals do assert(Visual.Enabled == false and Visual.Parent == Root, "僅停用六類特效，不銷毀或搬離物件") end
assert((Particle:GetAttribute("TestClearCount") or 0) > 0, "應清除已存在的粒子")
assert(OutsideParticle.Enabled, "不能影響 Workspace 外的特效")
assert(#World:GetDescendants() == WorldCountBefore and Root.CFrame == RootFrameBefore and Pond.CFrame == PondFrameBefore,
	"效能模式不能刪物件或變更角色／魚池位置")
assert(OwnPrompt.Parent == OwnPart and OwnModel.Parent == OwnPlot and ResearchA.Parent == Nodes,
	"餵食提示、角色及研究物件應保留")
local NewParticle = _Object("ParticleEmitter", "NewParticles", Root)
NewParticle.Enabled = true
local EffectConnection = _EffectConnections[#_EffectConnections]
EffectConnection.Callback(NewParticle)
assert(not NewParticle.Enabled, "模式開啟期間新增特效應立即處理")
DisabledParticle.Enabled = true
Particle.Enabled = true
_Step(3)
assert(not Particle.Enabled and not DisabledParticle.Enabled, "遊戲重新啟用的特效應在下一輪停用")
NewParticle.Parent = OutsidePart
_Step(3)
assert(NewParticle.Enabled, "移出 Workspace 的特效應還原，不持續控制其他容器")
_Toggle("效能模式（低特效）", false)
assert(_Environment.PerformanceMock.Stops == 1, "關閉效能模式必須卸載共用引擎")
assert(not _Environment.RenderingService.bEnabled, "關閉低特效不能覆寫獨立 3D 選項")
for _, Visual in Visuals do assert(Visual.Enabled, "關閉應恢復原始或最新觀察到的啟用需求") end
assert(not EffectConnection.bConnected, "關閉應解除新增事件")
DisabledParticle.Enabled = false
_Toggle("效能模式（低特效）", true)
_Toggle("防止閒置自動重新加入", true)
_Step(3)
assert(not _Environment.RenderingService.bEnabled, "重新開啟低特效不能強制打開 3D")
_Toggle("效能模式（低特效）", false)
_Toggle("關閉 3D 渲染", false)
_Environment.RenderingService.bFail = true
_Toggle("關閉 3D 渲染", true)
assert(_Environment.RenderingService.bEnabled and Controller.bRenderingEnabled and not Window.Controls.bDisable3dRendering:Get(),
	"權限不足時狀態與開關都須回到上次成功的值")
_Environment.RenderingService.bFail = false
assert(not DisabledParticle.Enabled and Particle.Enabled, "原本停用的特效必須保持停用")
_Controls["全選藥水"].Callback()
for Key in Constants.Potions.Definitions do
	assert(Controller.PotionKeys[Key] == true and _Controls[Constants.Potions.Definitions[Key].ToolName].Control:Get() == true,
		"全選必須同步全部藥水白名單及畫面")
end
_Step(2)
assert(_ConfigDatabase[Window.ConfigId].Flags.Potion_Cash_L1 and _ConfigDatabase[Window.ConfigId].Flags.Potion_Luck_L1,
	"全選結果應自動保存")
local bBuyBefore, bDrinkBefore, bGemsBefore = Controller.bAutoBuyPotions, Controller.bAutoDrinkPotions, Controller.bAllowGems
_Controls["全取消藥水"].Callback()
for Key in Constants.Potions.Definitions do assert(Controller.PotionKeys[Key] == false, "全取消不得留下已選藥水") end
assert(Controller.bAutoBuyPotions == bBuyBefore and Controller.bAutoDrinkPotions == bDrinkBefore and Controller.bAllowGems == bGemsBefore,
	"全取消只改藥水白名單")
_Step(2)
assert(_ConfigDatabase[Window.ConfigId].Flags.Potion_Cash_L1 == false and _ConfigDatabase[Window.ConfigId].Flags.Potion_Luck_L1 == false,
	"全取消結果應自動保存")
local SellPicker = _Controls["要出售的角色品質"]
assert(SellPicker.bMulti and SellPicker.bSearchable and #SellPicker.Options == 19, "全部 19 個英文品質應可多選且不重複")
assert(table.concat(SellPicker.Options, ",") == table.concat(Constants.RarityOrder, ","), "品質順序及英文拼字應符合遊戲設定")
assert(not Controller.bAutoSellCharacters and next(Controller.SellRarities) == nil, "預設不出售任何品質")
_Toggle("自動賣角色", true)
table.clear(_Calls)
_Step(3)
assert(not _Last("BackpackSellRarityRequest") and not _Last("BackpackCharSummaryGet"), "未選品質時不得讀取清單或出售")
SellPicker.Callback({ "Common", "Rare", "InvalidRarity" })
assert(not Controller.SellRarities.InvalidRarity, "不可採用遊戲未定義品質")
_Step(3)
assert(not _Last("BackpackSellRarityRequest") and _Last("BackpackSellSelectedRequest").Args[1] == "C|Eligible||L3",
	"未解鎖應從背包出售原始角色 key，保護收藏、裝備及未選品質")
assert(_Last("BackpackSellSelectedRequest").Args.n == 1, "背包出售不能把角色名稱或品質誤當完整 key")
_Responses.BackpackGetFavorites = { { ["C|Favorite|"] = true, ["C|Eligible||L3"] = true } }
table.clear(_Calls)
_Step(3)
assert(not _Last("BackpackSellSelectedRequest"), "只剩收藏／裝備角色時不得出售")
_Responses.BackpackGetFavorites = { { ["C|Favorite|"] = true } }
_Responses.BackpackSellSelectedRequest = { { ok = false, reason = "NotSellable" } }
_Step(3)
assert(tostring(_Labels[10].Value):find("NotSellable", 1, true), "背包出售拒絕應顯示原始原因")
_Responses.BackpackSellSelectedRequest = { { ok = true } }
_Responses.BackpackGetFavorites = { false }
table.clear(_Calls)
_Step(3)
assert(not _Last("BackpackSellSelectedRequest") and tostring(_Labels[10].Value):find("格式已變更", 1, true),
	"收藏保護資料讀取失敗時不能繼續出售")
_Responses.BackpackGetFavorites = { { ["C|Favorite|"] = true } }
PlayerData:SetAttribute("Rsh_B10", true)
_Step(3)
assert(_Last("BackpackSellRarityRequest").Args[1] == "Common" and _Last("BackpackSellRarityRequest").Args.n == 1, "只傳入一個原始英文品質")
_Step(3)
assert(_Last("BackpackSellRarityRequest").Args[1] == "Rare", "應輪流處理已選品質，不出售未選的 Uncommon")
SellPicker.Callback({})
table.clear(_Calls)
_Step(3)
assert(not _Last("BackpackSellRarityRequest"), "清空品質後應立即停止新出售")
SellPicker.Callback({ "God" })
_Responses.BackpackSellRarityRequest = { { ok = false, reason = "NotSellable" } }
_Step(3)
assert(tostring(_Labels[10].Value):find("NotSellable", 1, true), "遊戲拒絕出售時保留原因，不假裝成功")
SellPicker.Callback({ "Common" })
_Responses.BackpackSellRarityRequest = { { ok = false, reason = "Empty" } }
_Step(3)
assert(tostring(_Labels[10].Value):find("目前沒有", 1, true), "空背包結果應顯示等待")
--[[
	模擬出售等待伺服器回覆，驗證關閉後不再送出新請求。
	@param self 出售遠端替身。
	@param ... 原始品質參數。
]]
function _Remotes.BackpackSellRarityRequest.InvokeServer(self, ...)
	self:FireServer(...)
	while true do coroutine.yield() end
end
_Step(3)
_Toggle("自動賣角色", false)
table.clear(_Calls)
_Step(4)
assert(not _Last("BackpackSellRarityRequest"), "取消等待中的出售工作後不得繼續出售")
_Remotes.BoostsStoreGetState = nil
_Step(6)
assert(coroutine.status(Scheduler) == "suspended", "缺少 Remote 不得終止其他工作")
assert(tostring(_Labels[6].Value):find("BoostsStoreGetState", 1, true), "缺少能力應顯示具體名稱")
--[[
	模擬伺服器永不回傳，驗證二十秒逾時後取消本輪。
	@param self 遠端替身。
	@param ... 原始封包參數。
]]
function _Remotes.RebirthPurchase.InvokeServer(self, ...)
	self:FireServer(...)
	while true do coroutine.yield() end
end
PlayerData:SetAttribute("FoodNumber", 0)
_Toggle("自動轉生", true)
_Step(6)
_Step(21)
assert(tostring(_Labels[1].Value):find("逾時", 1, true), "RPC 卡住應顯示逾時且不阻塞排程")
_Controls["自動轉生間隔"].Callback(0.1)
table.clear(_Calls)
_Step(1)
assert(not _Last("RebirthPurchase"), "縮短間隔不能繞過 RPC 逾時的重試等待")
_Controls["自動轉生間隔"].Callback(5)
_Toggle("自動轉生", false)
do
	-- 配對接合：使用原生 StandId／PromptType，只有 Hold 才提供工具，Place 後才算放置。
	local Enabled = {}
	assert(Controller.CharacterPriority == nil and not _Controls["角色配置優先條件"], "固定配對後總收益最大化，不提供其他裝備策略")
	for _, Key in IntervalKeys do Enabled[Key] = Controller[Key] Window.Controls[Key]:Set(false) end
	local PreviousPairInterval = Controller.Intervals.bAutoCharacters
	_Controls["自動裝備最強角色間隔"].Callback(60)
	local PreviousSummary, PreviousDefinitions, PreviousCurve = _Responses.BackpackCharSummaryGet, Constants.Characters, Constants.GetCpsCurveMultiplier
	local PreviousPromptInvoker = TestEnvironment.fireproximityprompt
	Constants.Characters = { PairA = { CPS = 10, CombinationPartner = "PairB" }, PairB = { CPS = 9 }, Solo = { CPS = 40 } }
	--[[ @param Level 角色等級。 @return 固定倍率，餵食後仍允許重新讀取等級。 ]]
	Constants.GetCpsCurveMultiplier = function(Level) assert(Level >= 1) return 1 end
	_Responses.BackpackCharSummaryGet = { {
		["C|PairA|"] = { n = "PairA", c = 1, bc = 10 }, ["C|PairB|"] = { n = "PairB", c = 1, bc = 9 },
		["C|Solo|"] = { n = "Solo", c = 1, bc = 40 },
	} }
	local Stands = {}
	for Index = 1, 2 do
		local Stand = _Object("Folder", tostring(Index), OwnPlot)
		_Object("Part", "Platform", Stand)
		Stand:SetAttribute("HasCharacter", Index == 1)
		Stand:SetAttribute("Level", 1)
		Stand:SetAttribute("CharacterName", "Solo")
		Stand:SetAttribute("CharacterType", "")
		local Anchor = _Object("Part", "PromptPart", Stand)
		Anchor.CFrame = Rbx.CFrame.new(450 + Index * 10, 0, 0)
		for _, Kind in { "Place", "PickupOwner" } do
			local Prompt = _Object("ProximityPrompt", Kind, Anchor)
			Prompt.ActionText, Prompt.Enabled, Prompt.MaxActivationDistance = if Kind == "Place" then "Place" else "Pick Up", true, 6
			Prompt:SetAttribute("ServerEnabled", true)
			Prompt:SetAttribute("PromptType", Kind)
			Prompt:SetAttribute("StandId", Stand.Name)
		end
		Stands[Index] = Stand
	end
	-- 將第二格放入已購建築容器，驗證實際拿取／放置不只支援根目錄展台。
	_Environment.PairPurchases = OwnPlot:FindFirstChild("Purchases")
	_Environment.bCreatedPairPurchases = _Environment.PairPurchases == nil
	if not _Environment.PairPurchases then _Environment.PairPurchases = _Object("Folder", "Purchases", OwnPlot) end
	Stands[2].Parent = _Environment.PairPurchases
	for _, Name in { "PairA", "PairB" } do
		local Tool = _Object("Tool", Name, Backpack)
		Tool:SetAttribute("IsCharacterTool", true)
		Tool:SetAttribute("CharacterName", Name)
		Tool:SetAttribute("CharacterType", "")
		Tool:SetAttribute("Level", 1)
		WorkerTools["C|" .. Name .. "|"] = Tool
	end
	local Mutations, Attempts, bPairAccept = 0, 0, true
	--[[ @param Prompt 指定展台原生提示；此替身代表伺服器接受後更新。 ]]
	_Environment.PairPromptCallback = function(Prompt)
		if Prompt:GetAttribute("PromptType") == "LevelUp" and _Environment.LinkedTest then
			local Id = tostring(Prompt:GetAttribute("StandId"))
			local Stand = Stands[tonumber(Id)]
			assert(Stand, "只能餵食目前展台上的角色")
			if _Environment.LinkedTest.bCheckLowest then
				for _, Other in Stands do
					assert(Stand:GetAttribute("Level") <= Other:GetAttribute("Level"), "同品質必須餵目前等級最低者")
				end
			end
			_Environment.LinkedTest.Counts[Id] = (_Environment.LinkedTest.Counts[Id] or 0) + 1
			if _Environment.LinkedTest.Sequence then table.insert(_Environment.LinkedTest.Sequence, Id) end
			PlayerData:SetAttribute("FoodNumber", PlayerData:GetAttribute("FoodNumber") - 1)
			Stand:SetAttribute("Level", (Stand:GetAttribute("Level") or 1) + 1)
			return
		end
		local Stand = Prompt.Parent.Parent
		assert(table.find(Stands, Stand), "不可改其他展台")
		assert((Root.CFrame.Position - Prompt.Parent.CFrame.Position).Magnitude <= 6, "須先到展台旁")
		Attempts += 1
		if not bPairAccept then return end
		if Prompt:GetAttribute("PromptType") == "PickupOwner" then
			assert(Stand:GetAttribute("HasCharacter"))
			Stand:SetAttribute("HasCharacter", false)
		else
			local Held = Character:FindFirstChildOfClass("Tool")
			assert(Held and not Stand:GetAttribute("HasCharacter"))
			Stand:SetAttribute("CharacterName", Held:GetAttribute("CharacterName"))
			Stand:SetAttribute("HasCharacter", true)
			Held.Parent = Backpack
		end
		Mutations += 1
		if _Environment.PairNativeTest then
			for _, Entry in Stands do Entry:SetAttribute("_ComboMultiplier", nil) end
			if Stands[1]:GetAttribute("HasCharacter") and Stands[2]:GetAttribute("HasCharacter") then
				Stands[1]:SetAttribute("_ComboMultiplier", 3)
				Stands[2]:SetAttribute("_ComboMultiplier", 3)
			end
		end
		if _Environment.PairSyncTest then
			assert(not _Environment.PairSyncTest.Pending, "同步尚未完成時不得再操作展台")
			_Environment.PairSyncTest.Pending = { Stand = Stand, Name = Stand:GetAttribute("CharacterName"),
				bHasCharacter = Stand:GetAttribute("HasCharacter"), Ticks = 9, Attempts = Attempts }
			-- 模擬實際回報：HasCharacter 已更新，但名稱清空；延遲超過單次確認的三秒。
			Stand:SetAttribute("HasCharacter", true)
			Stand:SetAttribute("CharacterName", "")
		end
	end
	Root.CFrame = Rbx.CFrame.new()
	do
		local Test = { PreviousRemote = _Remotes.TeleportRequest, Platform = Stands[2].Platform, Requests = 0 }
		Test.Platform.Parent = nil
		Stands[2]:SetAttribute("HasCharacter", true)
		Stands[2]:SetAttribute("CharacterName", "")
		_Remotes.TeleportRequest = { Name = "TeleportRequest" }
		--[[
			核對遊戲原生回家 Remote 類別。
			@param self Remote 替身。
			@param Name 期望類別。
			@return 是否為 RemoteEvent。
		]]
		function _Remotes.TeleportRequest.IsA(self, Name) return Name == "RemoteEvent" end
		--[[
			只有原生傳送回家才能載入展台；不需要展台或 Home 的座標。
			@param self 原生回家 Remote 替身。
			@param Destination 封包必須只有 Plot。
		]]
		function _Remotes.TeleportRequest.FireServer(self, Destination)
			assert(Destination == "Plot" and _Environment.RenderingService.bEnabled, "原生回家前必須開啟渲染")
			assert(Mutations == 0, "未載入時不得配置其他角色")
			Test.Requests += 1
			Root.CFrame = Rbx.CFrame.new(460, 5, 3)
			Test.Platform.Parent = Stands[2]
			Stands[2]:SetAttribute("CharacterName", "Solo")
			Stands[2]:SetAttribute("HasCharacter", false)
		end
		_Toggle("自動裝備最強角色", true)
		_Step(0.1)
		assert(Test.Requests == 0 and Mutations == 0, "先暫停釣魚與取得移動權，不自行修改回家座標")
		_Step(0.5)
		assert(Test.Requests == 1 and Mutations == 0, "必須等待傳送與資料穩定，不能立即配置")
		_Step(1.3)
		_Step(0.5)
		assert(Test.Requests == 1 and Mutations == 0 and Root.CFrame.Position.X == 460,
			"完成回家載入後不得立刻傳送回原地，避免家中再次被卸載")
		_Toggle("自動裝備最強角色", false)
		_Remotes.TeleportRequest = Test.PreviousRemote
		Root.CFrame = Rbx.CFrame.new()
	end
	_Environment.PairSyncTest = { Restored = 0 }
	_Toggle("自動裝備最強角色", true)
	for Index = 1, 80 do
		if _Environment.PairSyncTest.Pending then
			local Pending = _Environment.PairSyncTest.Pending
			assert(Attempts == Pending.Attempts, "名稱未知時不得把角色當作空台或繼續拿取其他角色")
			Pending.Ticks -= 1
			if Pending.Ticks == 0 then
				Pending.Stand:SetAttribute("CharacterName", Pending.Name)
				Pending.Stand:SetAttribute("HasCharacter", Pending.bHasCharacter)
				_Environment.PairSyncTest.Pending = nil
				_Environment.PairSyncTest.Restored += 1
			end
		end
		_Step(0.5)
	end
	assert(_Environment.PairSyncTest.Restored == 3, "拿取及兩次放置遇到同步延遲後都應接續原配置")
	_Environment.PairSyncTest = nil
	assert(Mutations == 3 and Stands[1]:GetAttribute("HasCharacter") and Stands[2]:GetAttribute("HasCharacter"), tostring(Mutations) .. ":" .. tostring(_Labels[4].Value))
	assert(Controller.Intervals.bAutoCharacters == 60, "計算與換位應在 60 秒間隔前完成，並保留使用者間隔設定")
	assert(Stands[1]:GetAttribute("CharacterName") ~= Stands[2]:GetAttribute("CharacterName"), "配對成員應各佔相鄰一格")
	assert(tostring(_Controls["配對收益與配置"].Control.Content):find("57", 1, true), "UI 要列出配對後產量")
	assert(Root.CFrame.Position == Rbx.Vector3.zero, "換位後還原位置")
	for Index = 1, 30 do _Step(0.5) end
	assert(Mutations == 3, "相同最佳配置不得重複拿起重放")
	do
		local Test = { Before = Mutations, Interval = Controller.Intervals.bAutoCharacters }
		_Environment.PairNativeTest = true
		Stands[1]:SetAttribute("_ComboMultiplier", 3)
		Stands[2]:SetAttribute("_ComboMultiplier", nil)
		_Controls["自動裝備最強角色間隔"].Callback(0.1)
		for Index = 1, 80 do _Step(0.5) end
		assert(Mutations == Test.Before + 4, "角色鍵與位置相同但仍沿用舊配對時，須整排拿回並重放一次")
		assert(Stands[1]:GetAttribute("_ComboMultiplier") == 3 and Stands[2]:GetAttribute("_ComboMultiplier") == 3,
			"重放後兩位配對成員都應確認獲得加成")
		_Environment.PairNativeTest = nil
		for _, Entry in Stands do Entry:SetAttribute("_ComboMultiplier", nil) end
		_Controls["自動裝備最強角色間隔"].Callback(Test.Interval)
		Mutations = Test.Before
	end
	-- 家中正在重新查詢時，派遣不能搶走背包內準備供配置使用的候選。
	_Environment.ReservationSummaryInvoker = _Remotes.BackpackCharSummaryGet.InvokeServer
	_Environment.ReservationLemon = { Parent = WorkerSites["Lemon Stand"].Parent, Owner = WorkerPrompts["Lemon Stand"]:GetAttribute("OwnerUserId") }
	WorkerSites["Lemon Stand"].Parent = WorkerPurchases
	WorkerPrompts["Lemon Stand"]:SetAttribute("OwnerUserId", 42)
	--[[ @param self 尚未完成的角色查詢。 ]]
	function _Remotes.BackpackCharSummaryGet.InvokeServer(self)
		self:FireServer()
		while true do coroutine.yield() end
	end
	_Controls["自動裝備最強角色間隔"].Callback(0.1)
	_Toggle("自動派遣適任角色（建築／Garden）", true)
	table.clear(_Calls)
	_Step(1)
	_Step(7)
	assert(_Last("BackpackCharSummaryGet") and not _Last("BackpackHoldCharacter") and not _Last("WorkerPlace"), "家中查詢／規劃未完成時必須暫停所有新派遣")
	assert(tostring(_Labels[23].Value):find("優先", 1, true), "派遣等待原因必須顯示家中配置優先")
	_Toggle("自動派遣適任角色（建築／Garden）", false)
	_Toggle("自動裝備最強角色", false)
	_Remotes.BackpackCharSummaryGet.InvokeServer = _Environment.ReservationSummaryInvoker
	WorkerSites["Lemon Stand"].Parent = _Environment.ReservationLemon.Parent
	WorkerPrompts["Lemon Stand"]:SetAttribute("OwnerUserId", _Environment.ReservationLemon.Owner)
	_Controls["自動裝備最強角色間隔"].Callback(60)
	_Controls["自動裝備最強角色間隔"].Callback(PreviousPairInterval)
	do
		local Test = { Site = WorkerSites["Lemon Stand"], State = WorkerStates["Lemon Stand"], Before = Mutations,
			PreviousUnequip = _Remotes.LemonUnequipChar.FireServer, PreviousOwner = WorkerPrompts["Lemon Stand"]:GetAttribute("OwnerUserId") }
		Test.PreviousState, Test.PreviousParent = table.clone(Test.State), Test.Site.Parent
		Test.Site.Parent = WorkerPurchases
		WorkerPrompts["Lemon Stand"]:SetAttribute("OwnerUserId", 42)
		table.clear(Test.State)
		Test.State.charName, Test.State.charType, Test.State.rarity, Test.State.groupKey, Test.State.standKey = "RecalledCash", "", "Rare", "C|RecalledCash|", "LemonStand"
		Constants.Characters.RecalledCash = { CPS = 1000, Rarity = "Rare" }
		_WorkerInventory({ ["C|RecalledCash|"] = { n = "RecalledCash", ra = "Rare", c = 1 }, ["C|Solo|"] = { n = "Solo", ra = "Common", c = 1 } })
		--[[ @param self 卸任遠端。 @param Key standKey；先模擬未接受卸任。 ]]
		function _Remotes.LemonUnequipChar.FireServer(self, Key) table.insert(_Calls, { Name = self.Name, Args = { Key } }) end
		table.clear(_Calls)
		_Toggle("自動裝備最強角色", true)
		for Index = 1, 24 do _Step(0.5) end
		assert(_Last("LemonUnequipChar") and Mutations == Test.Before and Test.State.charName == "RecalledCash", "工作角色未確認卸任時不可先拿走家中角色")
		_Toggle("自動裝備最強角色", false)
		_Remotes.LemonUnequipChar.FireServer = Test.PreviousUnequip
		table.clear(_Calls)
		_Toggle("自動裝備最強角色", true)
		for Index = 1, 80 do _Step(0.5) end
		assert(_Last("LemonUnequipChar") and not Test.State.charName, "收益更高的工作角色應先解除派遣")
		assert(Stands[1]:GetAttribute("CharacterName") == "RecalledCash" or Stands[2]:GetAttribute("CharacterName") == "RecalledCash", "背包摘要未列出的工作角色仍須納入收益規劃並部署到家中")
		assert(Stands[1]:GetAttribute("HasCharacter") and Stands[2]:GetAttribute("HasCharacter"), "召回後應完成整份家中配置")
		local ReleasedAt, HeldAt
		for Index, Call in _Calls do
			if Call.Name == "LemonUnequipChar" then ReleasedAt = ReleasedAt or Index end
			if Call.Name == "BackpackHoldCharacter" and Call.Args[1] == "C|RecalledCash|" then HeldAt = HeldAt or Index end
		end
		assert(ReleasedAt and HeldAt and ReleasedAt < HeldAt, "不得在卸任確認前拿起派遣角色")
		_Toggle("自動裝備最強角色", false)
		table.clear(Test.State)
		for Key, Value in Test.PreviousState do Test.State[Key] = Value end
		Test.Site.Parent = Test.PreviousParent
		WorkerPrompts["Lemon Stand"]:SetAttribute("OwnerUserId", Test.PreviousOwner)
		WorkerTools["C|RecalledCash|"]:Destroy()
		WorkerTools["C|Solo|"]:Destroy()
		WorkerTools["C|Solo|"] = nil
		WorkerTools["C|RecalledCash|"], Constants.Characters.RecalledCash = nil, nil
		Mutations = Test.Before
	end
	Constants.Characters.Solo.CPS, _Responses.BackpackCharSummaryGet[1]["C|Solo|"].bc = 100, 100
	Stands[1]:SetAttribute("CharacterName", "Solo")
	Stands[2]:SetAttribute("CharacterName", "PairA")
	_Toggle("自動裝備最強角色", true)
	for Index = 1, 30 do _Step(0.5) end
	assert(Mutations == 3, "配對收益小於目前高產單角組合時不得換位")
	_Toggle("自動裝備最強角色", false)
	local MutationsBeforeRefusal = Mutations
	Constants.Characters.Solo.CPS, _Responses.BackpackCharSummaryGet[1]["C|Solo|"].bc = 40, 40
	Stands[1]:SetAttribute("CharacterName", "Solo")
	Stands[2]:SetAttribute("HasCharacter", false)
	bPairAccept = false
	_Toggle("自動裝備最強角色", true)
	for Index = 1, 12 do _Step(0.5) end
	assert(Attempts > 3 and Mutations == MutationsBeforeRefusal, "未確認拿起時不得繼續放置或假裝伺服器接受")
	_Toggle("自動裝備最強角色", false)
	local AttemptsAfterCancel = Attempts
	for Index = 1, 15 do _Step(0.5) end
	assert(Attempts == AttemptsAfterCancel and Root.CFrame.Position == Rbx.Vector3.zero, "取消換位須停止操作並還原位置")
	do
		-- 真實回報角色：三隻已在展台，收益模式只需重排，無須換成另一批低產角色。
		Constants.Characters = { ["Itsi Naka"] = { CPS = 10 }, ["Ichi Naka"] = { CPS = 9 }, Solo = { CPS = 100 } }
		_Responses.BackpackCharSummaryGet = { {
			["C|Itsi Naka|"] = { n = "Itsi Naka", c = 1, bc = 10 }, ["C|Ichi Naka|"] = { n = "Ichi Naka", c = 1, bc = 9 },
			["C|Solo|"] = { n = "Solo", c = 1, bc = 100 },
		} }
		for Index, Name in { "Itsi Naka", "Ichi Naka" } do
			local Tool = WorkerTools[if Index == 1 then "C|PairA|" else "C|PairB|"]
			Tool:SetAttribute("CharacterName", Name)
			WorkerTools["C|" .. Name .. "|"] = Tool
		end
		do
			local Tool = _Object("Tool", "Solo", Backpack)
			Tool:SetAttribute("IsCharacterTool", true)
			Tool:SetAttribute("CharacterName", "Solo")
			Tool:SetAttribute("CharacterType", "")
			Tool:SetAttribute("Level", 1)
			WorkerTools["C|Solo|"] = Tool
		end
		Stands[3] = Stands[2]:Clone()
		Stands[3].Name, Stands[3].Parent = "3", OwnPlot
		for _, Prompt in Stands[3]:GetDescendants() do
			if Prompt:IsA("ProximityPrompt") then Prompt:SetAttribute("StandId", "3") end
		end
		for Index, Name in { "Itsi Naka", "Solo", "Ichi Naka" } do
			Stands[Index]:SetAttribute("CharacterName", Name)
			Stands[Index]:SetAttribute("HasCharacter", true)
		end
		bPairAccept = true
		_Toggle("自動裝備最強角色", true)
		for Index = 1, 50 do _Step(0.5) end
		local Positions = {}
		for Index, Stand in Stands do
			assert(Stand:GetAttribute("HasCharacter"), tostring(_Labels[4].Value))
			Positions[Stand:GetAttribute("CharacterName")] = Index
		end
		assert(Positions["Itsi Naka"] and Positions["Ichi Naka"] and Positions.Solo and math.abs(Positions["Itsi Naka"] - Positions["Ichi Naka"]) == 1,
			"收益模式必須保留原三隻角色並實際將 Itsi Naka／Ichi Naka 放在相鄰展台")
		assert(tostring(_Controls["配對收益與配置"].Control.Content):find("已選配對：", 1, true), "須列出已辨識的角色名稱與展台位置")
		_Toggle("自動裝備最強角色", false)
		do
			--[[ @param Text 應由按鈕寫入剪貼簿的完整診斷。 ]]
			_Environment.setclipboard = function(Text) _Environment.CharacterClipboard = Text end
			table.clear(_Calls)
			_Controls["複製 Debug 資訊"].Callback()
			_Controls["複製 Debug 資訊"].Callback()
			_Step(0)
			assert(type(_Environment.CharacterClipboard) == "string", "應複製文字而非修改遊戲狀態")
			for _, Text in { "Character Debug v2", "[Search]", "[BackpackCharSummaryGet]", "[Stand 1]", "[Current reconstructed]", "[Definition Itsi Naka]", "[Pair model]", "Candidates=", "StandIds=", "DebugSource=", "END FishAnAnimeRNG Character Debug" } do
				assert(_Environment.CharacterClipboard:find(Text, 1, true), "診斷不可省略：" .. Text)
			end
			assert(#_Calls == 1 and _Calls[1].Name == "BackpackCharSummaryGet", "連按只查詢一次，不觸發裝備、移動或換位")
			assert(not _Environment.CharacterClipboard:find("OwnerUserId", 1, true), "角色診斷不需擁有者帳號資訊")
			assert(tostring(_Controls["Debug 複製狀態"].Control.Content):find("已複製", 1, true))
			Stands[1]:SetAttribute("Level", nil)
			_Controls["複製 Debug 資訊"].Callback()
			_Step(0)
			assert(_Environment.CharacterClipboard:find("Error=", 1, true) and _Environment.CharacterClipboard:find("[Pair model]", 1, true),
				"配置重建失敗時仍須保留原始展台、配對與原因")
			Stands[1]:SetAttribute("Level", 1)
			--[[ @param Text 診斷文字；模擬剪貼簿被拒絕。 ]]
			_Environment.setclipboard = function(Text) error("clipboard denied") end
			_Controls["複製 Debug 資訊"].Callback()
			_Step(0)
			assert(tostring(_Controls["Debug 複製狀態"].Control.Content):find("複製失敗", 1, true))
			_Environment.setclipboard = nil
			_Controls["複製 Debug 資訊"].Callback()
			assert(tostring(_Controls["Debug 複製狀態"].Control.Content):find("缺少", 1, true), "缺少剪貼簿能力須明確告知")
			--[[ @param Text 模擬可用剪貼簿。 ]]
			_Environment.setclipboard = function(Text) _Environment.CharacterClipboard = Text end
			_Environment.DebugSummaryInvoker = _Remotes.BackpackCharSummaryGet.InvokeServer
			--[[ @param self 暫不回傳的摘要遠端替身。 ]]
			function _Remotes.BackpackCharSummaryGet.InvokeServer(self) while true do coroutine.yield() end end
			_Controls["複製 Debug 資訊"].Callback()
			_Step(0)
			_Step(21)
			assert(tostring(_Controls["Debug 複製狀態"].Control.Content):find("逾時", 1, true), "查詢卡住須清理工作並允許重試")
			_Remotes.BackpackCharSummaryGet.InvokeServer = _Environment.DebugSummaryInvoker
			_Controls["複製 Debug 資訊"].Callback()
			_Step(0)
			assert(tostring(_Controls["Debug 複製狀態"].Control.Content):find("已複製", 1, true), "逾時後仍可重新複製")
			_Environment.setclipboard = nil
		end
		do
			_Environment.LinkedTest = { Counts = {}, PreviousFeedAction = Controller.FeedAction, PreviousFeedMode = Controller.FeedMode }
			Constants.Characters.Solo.Rarity, Constants.Characters["Itsi Naka"].Rarity, Constants.Characters["Ichi Naka"].Rarity = "Common", "Rare", "Rare"
			Constants.Characters.QualityHigh = { CPS = 1, Rarity = "God" }
			_Responses.BackpackCharSummaryGet[1]["C|QualityHigh|"] = { n = "QualityHigh", bc = 1, c = 1, ra = "God" }
			WorkerTools["C|QualityHigh|"] = _Object("Tool", "QualityHigh", Backpack)
			WorkerTools["C|QualityHigh|"]:SetAttribute("IsCharacterTool", true)
			WorkerTools["C|QualityHigh|"]:SetAttribute("CharacterName", "QualityHigh")
			WorkerTools["C|QualityHigh|"]:SetAttribute("CharacterType", "")
			WorkerTools["C|QualityHigh|"]:SetAttribute("Level", 1)
			for Index = 1, 3 do
				_Environment.LinkedTest.Prompt = _Object("ProximityPrompt", "LinkedLevelUp", Stands[Index]:FindFirstChild("PromptPart"))
				_Environment.LinkedTest.Prompt:SetAttribute("PromptType", "LevelUp")
				_Environment.LinkedTest.Prompt:SetAttribute("StandId", tostring(Index))
				_Environment.LinkedTest.Prompt:SetAttribute("ServerEnabled", true)
				_Environment.LinkedTest.Prompt.ActionText, _Environment.LinkedTest.Prompt.Enabled = "Level Up (1 Food)", true
			end
			PlayerData:SetAttribute("FoodNumber", 100)
			_Controls["自動裝備最強角色間隔"].Callback(300)
			_Controls["餵食分配模式"].Callback("平均分配")
			_Controls["餵食方式"].Callback("一個一個餵")
			_Toggle("自動裝備最強角色", true)
			for Index = 1, 50 do _Step(0.5) end
			_Toggle("自動餵食角色", true)
			for Index = 1, 100 do _Step(0.5) end
			for Index, Stand in Stands do
				assert(Stand:GetAttribute("CharacterName") ~= "QualityHigh", "不可為品質換掉高收益單角或配對角色")
				if Stand:GetAttribute("CharacterName") ~= "Solo" then
					assert((_Environment.LinkedTest.Counts[tostring(Index)] or 0) >= 2, "應優先餵最高品質角色")
				else assert((_Environment.LinkedTest.Counts[tostring(Index)] or 0) == 0, "低品質即使等級較低，也不可排在可餵食的最高品質前面") end
			end
			_Toggle("自動餵食角色", false)
			_Environment.LinkedTest.Counts, _Environment.LinkedTest.Sequence = {}, {}
			_Environment.LinkedTest.bCheckLowest = true
			for Index, Stand in Stands do
				Stand:SetAttribute("Rarity", "God")
				Stand:SetAttribute("Level", if Index == 1 then 3 elseif Index == 2 then 1 else 2)
			end
			_Toggle("自動裝備最強角色", false)
			_Environment.LinkedTest.SummaryInvoker = _Remotes.BackpackCharSummaryGet.InvokeServer
			--[[
				暫停裝備查詢，確認餵食不必等待規劃完成。
				@param self 角色摘要遠端替身。
			]]
			function _Remotes.BackpackCharSummaryGet.InvokeServer(self)
				self:FireServer()
				_Environment.LinkedTest.bSummaryWaiting = true
				while true do coroutine.yield() end
			end
			_Toggle("自動裝備最強角色", true)
			_Toggle("自動餵食角色", true)
			for Index = 1, 24 do _Step(0.5) end
			assert(_Environment.LinkedTest.bSummaryWaiting and #_Environment.LinkedTest.Sequence > 0,
				"裝備查詢尚未完成時仍須依目前已放置角色餵食，不等待連動確認")
			assert(Controller.bAutoFeed and Controller.FeedMode == "平均分配" and Controller.FeedAction == "一個一個餵",
				"切換裝備條件不可關閉或改寫餵食設定")
			_Toggle("自動裝備最強角色", false)
			_Remotes.BackpackCharSummaryGet.InvokeServer = _Environment.LinkedTest.SummaryInvoker
			for Index = 1, 76 do _Step(0.5) end
			assert(_Environment.LinkedTest.Sequence[1] == "2" and #_Environment.LinkedTest.Sequence > 3,
				"同品質時應先餵最低等級，升級後重排，不能照原本輪流順序或累計消耗排序")
			assert(math.max(Stands[1]:GetAttribute("Level"), Stands[2]:GetAttribute("Level"), (Stands[3]:GetAttribute("Level")))
				- math.min(Stands[1]:GetAttribute("Level"), Stands[2]:GetAttribute("Level"), (Stands[3]:GetAttribute("Level"))) <= 1,
				"同品質應優先補低等級，讓等級差縮小而非平均餵食次數")
			assert(PlayerData:GetAttribute("FoodNumber") > 0 and Controller.FeedAction == "一個一個餵", "裝備條件不可覆寫餵食方式")
			_Toggle("自動餵食角色", false)
			_Toggle("自動裝備最強角色", false)
			_Controls["餵食方式"].Callback(_Environment.LinkedTest.PreviousFeedAction)
			_Controls["餵食分配模式"].Callback(_Environment.LinkedTest.PreviousFeedMode)
			_Controls["自動裝備最強角色間隔"].Callback(PreviousPairInterval)
			WorkerTools["C|QualityHigh|"]:Destroy()
			WorkerTools["C|QualityHigh|"] = nil
			_Environment.LinkedTest = nil
		end
		WorkerTools["C|Solo|"]:Destroy()
		WorkerTools["C|Itsi Naka|"], WorkerTools["C|Ichi Naka|"], WorkerTools["C|Solo|"] = nil, nil, nil
	end
	_Responses.BackpackCharSummaryGet, Constants.Characters, Constants.GetCpsCurveMultiplier = PreviousSummary, PreviousDefinitions, PreviousCurve
	TestEnvironment.fireproximityprompt = PreviousPromptInvoker
	_Environment.PairPromptCallback = nil
	for _, Stand in Stands do Stand:Destroy() end
	if _Environment.bCreatedPairPurchases then _Environment.PairPurchases:Destroy() end
	_Environment.PairPurchases, _Environment.bCreatedPairPurchases = nil, nil
	for _, Name in { "PairA", "PairB" } do WorkerTools["C|" .. Name .. "|"]:Destroy() WorkerTools["C|" .. Name .. "|"] = nil end
	for Key, bEnabled in Enabled do Window.Controls[Key]:Set(bEnabled) end
end
_Toggle("自動釣魚", true)
_Toggle("自動賣角色", true)
do
	local Enabled, Items = {}, {}
	for _, Key in IntervalKeys do Enabled[Key] = Controller[Key] Window.Controls[Key]:Set(false) end
	_FishingCallback({ kind = "Stopped", reason = "CANCELED" })
	NativeAutoOn.Enabled, NativeAutoOff.Enabled = false, true
	Root.CFrame = Rbx.CFrame.new()
	for Index = 1, 12 do
		local Item = _Object("Part", "BatchGem" .. Index, World)
		Item.CFrame, Item.CanTouch, Item.LocalTransparencyModifier = Rbx.CFrame.new(700 + Index * 10, 0, 0), true, 0
		Items[Index] = Item
	end
	_Environment.PickupTags, _Environment.MapTouchCount = { EventGemHover = Items }, 0
	--[[ @param Part1 玩家根部。 @param Part2 本輪鑽石。 @param State 原生觸碰開始或結束。 ]]
	_Environment.MapTouchCallback = function(Part1, Part2, State)
		assert(Part1 == Root and table.find(Items, Part2))
		_Environment.MapTouchCount += 1
	end
	local Started = _Now
	_Toggle("自動撿取地圖上的物品", true)
	for Index = 1, 140 do
		_Step(0.5)
		if tostring(_Labels[26].Value):find("本輪已處理 12／12", 1, true) then break end
	end
	assert(_Now - Started > 20 and _Environment.MapTouchCount == 24 and tostring(_Labels[26].Value):find("本輪已處理 12／12", 1, true),
		"持續有進度的整批拾取不得被20秒工作逾時中斷：" .. tostring(_Labels[26].Value))
	assert(Root.CFrame.Position == Rbx.Vector3.zero, "整輪完成須回到最初位置")
	_Toggle("自動撿取地圖上的物品", false)
	_Environment.MapTouchCallback, _Environment.PickupTags = nil, nil
	for _, Item in Items do Item:Destroy() end
	for Key, bEnabled in Enabled do Window.Controls[Key]:Set(bEnabled) end
end
_Toggle("允許自動花費鑽石", true)
_Toggle("允許研究花費鑽石", false)
_Toggle("效能模式（低特效）", true)
_Toggle("Cash Potion Lvl. 1", true)
_Toggle("自動購買可買的最強魚竿", true)
_Toggle("Luck", false)
_Controls["餵食分配模式"].Callback("只餵最強角色")
_Controls["要出售的角色品質"].Callback({ "Common", "Rare" })
_Toggle("自動蓋家（購買建築）", true)
_Toggle("自動派遣適任角色（建築／Garden）", true)
_Toggle("自動開 Box", true)
_Toggle("自動收集食物", true)
for _, Feature in RewardFeatures do _Toggle(Feature[1], true) end
_Toggle("自動購買限時商店物品", true)
_Toggle("限時商店允許使用鑽石", true)
_Toggle("自動完成活動任務", true)
_Controls["升級項目 2"].Callback()
_Controls["上調順序"].Callback()
_Controls["轉生存錢門檻"].Callback(90)
local SavedIntervals = {}
for Index, Key in IntervalKeys do
	SavedIntervals[Key] = 60 + Index / 100
	Window.Controls[Key .. "_Interval"]:Set(SavedIntervals[Key])
end
local SaveCountBefore = _SaveCount
_Toggle("關閉 3D 渲染", true)
_Step(2)
assert(_SaveCount > SaveCountBefore, "變更設定後應由 UI 自動保存")
local ConfigId = "FishAnAnimeRng_74729868188364"
assert(Window.ConfigId == ConfigId and Window.bConfigEnabled, "設定分組只包含遊戲，不依玩家分組")
assert(_ConfigDatabase[ConfigId].Flags.FeedMode == "只餵最強角色"
	and _ConfigDatabase[ConfigId].Flags.bAllowGems == true, "新增選項必須有固定 Flag 可保存")
Controller.Unload()
Controller.Unload()
assert(_Environment.RenderingService.bEnabled, "卸載應還原載入前的 3D 狀態")
assert(_ConfigDatabase[ConfigId].Flags.bDisable3dRendering == true, "卸載還原不可改寫保存的 3D 選項")
assert(_Environment.AutoRejoinScript.Enabled and _Environment.AntiIdleScript.Enabled, "卸載必須恢復重連腳本而不影響防閒置")
assert(Particle.Enabled and not DisabledParticle.Enabled, "卸載必須還原特效狀態")
for _, Connection in _EffectConnections do assert(not Connection.bConnected, "卸載不可留下特效監聽") end
assert(#_StreamCalls == 0, "原地研究不應載入或釋放研究場景")
assert(not _Connection.bConnected and Window.bDestroyed and _Environment.FishAnAnimeRngBjz == nil, "卸載應清理事件、UI 與全域實例")
for _, Thread in _Tasks do assert(coroutine.status(Thread) == "dead", "卸載後不得留下背景工作") end
assert(_ConfigDatabase[ConfigId].Flags.bAutoFish == true and _ConfigDatabase[ConfigId].Flags.bAutoSellCharacters == true,
	"卸載清理不能把使用者原本開啟的設定保存成 false")
--[[
	模擬重新貼上執行，保留 UI 的設定資料但重建所有控制項與執行工作。
	@return 新控制器。
]]
local function _Reload()
	table.clear(_Tasks)
	table.clear(_Controls)
	table.clear(_Labels)
	Window.ScreenGui, Window.bDestroyed = _Object("ScreenGui", "ReloadUI", HiddenUI), false
	_Connection.bConnected = true
	local NewController = Luau.load(TestSource, { environment = TestEnvironment })()
	Scheduler = _Tasks[1]
	return NewController
end
table.clear(_Calls)
_ConfigDatabase[ConfigId].Flags.bQualityEquipAndFeed = true
local Reloaded = _Reload()
assert(not Reloaded.bRenderingEnabled and not _Environment.RenderingService.bEnabled and Window.Controls.bDisable3dRendering:Get(),
	"重新執行必須還原已保存的 3D 關閉狀態")
assert(Reloaded.bAutoNativeFish == nil and not Window.Controls.bAutoNativeFish,
	"重新載入也不得重建已移除的原生 Auto Fish 獨立開關")
for _, Key in IntervalKeys do
	assert(Reloaded.Intervals[Key] == SavedIntervals[Key]
		and Window.Controls[Key .. "_Interval"]:Get() == SavedIntervals[Key], "所有滑桿與排程間隔都須自動保存載入")
end
for _, Feature in RewardFeatures do
	assert(Reloaded[Feature[2]] == true and _Controls[Feature[1]].Control:Get() == true, "領獎開關應自動保存載入")
end
assert(#_Calls == 0, "介面及所有選項同步完成之前不可啟動自動工作")
assert(Reloaded.bAutoFish and Reloaded.bAutoSellCharacters and Reloaded.bAllowGems, "重新執行自動恢復功能開關與鑽石設定")
assert(Reloaded.bLowEffects and _Controls["效能模式（低特效）"].Control:Get(), "效能 Toggle 應自動保存載入")
assert(Reloaded.bAutoBuyRod and _Controls["自動購買可買的最強魚竿"].Control:Get(), "自動購買魚竿 Toggle 應自動保存載入")
assert(Reloaded.bAutoBuild and _Controls["自動蓋家（購買建築）"].Control:Get(), "自動蓋家開關應保存載入")
assert(Reloaded.CharacterPriority == nil and not Window.Controls.CharacterPriority, "不得載入已移除的品質裝備條件")
assert(Reloaded.bAutoWorkers and Reloaded.bAutoBoxes, "派工及自動開 Box 開關應保存載入")
assert(Reloaded.bAutoLimitedShop and Reloaded.bLimitedShopAllowGems and Window.Controls.bLimitedShopAllowGems:Get(), "限時商店開關與獨立鑽石許可須保存載入")
assert(Reloaded.bAutoEventQuests and Window.Controls.bAutoEventQuests:Get(), "活動任務開關應自動保存載入，間隔沿用相同玩家與遊戲分組")
assert(Reloaded.UpgradePriorityOrder[1] == "Expensive" and Reloaded.UpgradePriorityOrder[2] == "Cheap"
	and Window.Controls.UpgradePriority_1:Get() == "Expensive" and Window.Controls.UpgradePriority_2:Get() == "Cheap",
	"升級順序必須完整保存載入，不能在同步第一順位時覆蓋尚未讀取的後續順位")
assert(Reloaded.UpgradeRebirthSavePercent == 90 and Window.Controls.UpgradeRebirthSavePercent:Get() == 90,
	"轉生存錢門檻必須與排序同樣自動保存載入")
assert(Reloaded.bAutoCollectFood and not Reloaded.bAutoFeed, "收集與餵食應獨立保存載入，不連動開關")
assert(Reloaded.bAutoMapPickup and Window.Controls.bAutoMapPickup:Get(), "地圖拾取開關須獨立保存載入")
assert(not Reloaded.bQualityEquipAndFeed and not Window.Controls.bQualityEquipAndFeed, "舊連動 Toggle 不得恢復或干涉餵食")
assert(Reloaded.FeedMode == "最高品質優先" and Reloaded.PotionKeys.Cash_L1 and not Reloaded.PotionKeys.Luck_L1,
	"靜默載入後控制器仍必須恢復模式與藥水白名單")
assert(Reloaded.FeedAction == "一個一個餵", "餵食方式應自動保存及載入")
assert(Reloaded.ResearchPriority == "藥水項目優先" and Window.Controls.ResearchPriority:Get() == "藥水項目優先",
	"研究優先條件必須自動保存與載入")
assert(not Reloaded.bResearchAllowGems and not Window.Controls.bResearchAllowGems:Get(),
	"研究 Gems 預設允許，但使用者明確關閉後必須保存與載入")
_Controls["餵食方式"].Callback("全部餵食")
assert(Reloaded.SellRarities.Common and Reloaded.SellRarities.Rare and not Reloaded.SellRarities.God,
	"出售品質多選必須完整恢復且不擴大範圍")
assert(_Controls["自動釣魚"].Control:Get() == Reloaded.bAutoFish, "介面與真正啟用狀態必須一致")
--[[ @param Text 卸載前排程的複製工作，不應在卸載後被呼叫。 ]]
_Environment.setclipboard = function(Text) error("不應執行已取消的 Debug 工作") end
_Controls["複製 Debug 資訊"].Callback()
Reloaded.Unload()
assert(coroutine.status(_Tasks[#_Tasks]) == "dead", "卸載應取消尚未完成的 Debug 收集")
_Environment.setclipboard = nil
_ConfigDatabase[ConfigId].Flags.bResearchAllowGems = nil
_ConfigDatabase[ConfigId].Flags.bAllowGems = false
_ConfigDatabase[ConfigId].Flags.CharacterPriority = "品質優先"
local BulkSelected = _Reload()
assert(BulkSelected.CharacterPriority == nil and not Window.Controls.CharacterPriority,
	"舊設定排序不得恢復品質優先或改變收益策略")
assert(BulkSelected.bResearchAllowGems and not BulkSelected.bAllowGems,
	"舊設定只有關閉的共用 Gems 許可時，新版研究仍預設允許且不連動買藥")
assert(BulkSelected.FeedAction == "全部餵食", "全部餵食選項也應保存及載入")
_Controls["全選藥水"].Callback()
BulkSelected.Unload()
local BulkRestored = _Reload()
for Key, Definition in Constants.Potions.Definitions do
	assert(BulkRestored.PotionKeys[Key] == true and _Controls[Definition.ToolName].Control:Get() == true,
		"重新執行應恢復全選結果及畫面")
end
_Controls["全取消藥水"].Callback()
BulkRestored.Unload()
local BulkCleared = _Reload()
for Key, Definition in Constants.Potions.Definitions do
	assert(BulkCleared.PotionKeys[Key] == false and _Controls[Definition.ToolName].Control:Get() == false,
		"重新執行應恢復全取消結果及畫面")
end
BulkCleared.Unload()
local BuildTouchInvoker = TestEnvironment.firetouchinterest
TestEnvironment.firetouchinterest = nil
local WithoutTouch = _Reload()
_Step(1)
assert(tostring(_Labels[22].Value):find("firetouchinterest", 1, true), "缺少觸碰能力時應顯示具體原因，不影響初始化")
WithoutTouch.Unload()
TestEnvironment.firetouchinterest = BuildTouchInvoker
TestEnvironment.writefile = nil
local SavesBeforeMissing = _SaveCount
local WithoutWrite = _Reload()
assert(not Window.bConfigEnabled and tostring(_Controls["設定保存狀態"].Control:Get()):find("writefile", 1, true),
	"缺少檔案能力時應停用保存並顯示具體名稱")
WithoutWrite.Unload()
assert(_SaveCount == SavesBeforeMissing, "能力不足不得宣稱已保存")
TestEnvironment.writefile = _FileCapability
_bConfigWriteError = true
local WriteFailure = _Reload()
_Controls["餵食分配模式"].Callback("平均分配")
_Step(2)
_Step(0)
assert(tostring(_Controls["設定保存狀態"].Control:Get()):find("write failed", 1, true), "實際保存失敗應顯示於介面")
WriteFailure.Unload()
_bConfigWriteError, _bConfigReadError = false, true
local SavedBeforeCorrupt = _ConfigDatabase[ConfigId]
local CorruptConfig = _Reload()
assert(not CorruptConfig.bAutoFish and not CorruptConfig.bAutoSellCharacters, "損毀設定不可啟用舊工作")
assert(tostring(_Controls["設定保存狀態"].Control:Get()):find("corrupt configuration", 1, true), "載入失敗應顯示具體原因")
CorruptConfig.Unload()
assert(_ConfigDatabase[ConfigId] == SavedBeforeCorrupt, "讀取失敗不可覆寫原設定")
_bConfigReadError = false
do
	local State = { Starts = _Environment.PerformanceMock.Starts, Loads = _Environment.PerformanceLoads }
	_Environment.PerformanceMock.SafeModeVersion = nil
	State.Controller = _Reload()
	Window.Controls.bLowEffects_Interval:Set(0.1)
	_Step(1)
	assert(tostring(_Labels[11].Value):find("請同步更新 PerformanceEngine", 1, true))
	assert(_Environment.PerformanceMock.Starts == State.Starts, "舊引擎不支援安全模式時不可啟動")
	_Step(1)
	assert(_Environment.PerformanceLoads == State.Loads + 1, "引擎載入失敗須節流，不可每輪下載")
	State.Controller.Unload()
	_Environment.PerformanceMock.SafeModeVersion = 1
	_Environment.PerformanceStartError = true
	State.Stops = _Environment.PerformanceMock.Stops
	State.Controller = _Reload()
	_Step(1)
	assert(_Environment.PerformanceMock.Stops == State.Stops + 1, "部分初始化失敗必須 Destroy")
	assert(tostring(_Labels[11].Value):find("模擬效能引擎部分初始化失敗", 1, true))
	_Environment.PerformanceStartError = nil
	State.Controller.Unload()
end
table.clear(_Tasks)
Window.ScreenGui, Window.bDestroyed = _Object("ScreenGui", "SecondUI", HiddenUI), false
_Remotes.FishingState = nil
local bLoaded, InitializationError = pcall(Luau.load(TestSource, { environment = TestEnvironment }))
assert(not bLoaded and tostring(InitializationError):find("FishingState", 1, true), "初始化缺少事件應失敗")
assert(Window.bDestroyed and _Environment.FishAnAnimeRngBjz == nil and #_Tasks == 0, "初始化失敗應清理介面且不啟動工作")
print("FishAnAnimeRNG: offline integration passed (thirty-three features, native Auto Fish, rejoin protection, safe performance lifecycle, config, cleanup)")

local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local World = Rbx.Instance.new("Folder")
local Npc = Rbx.Instance.new("Model")
Npc.Parent = World
local Anchor = Rbx.Instance.new("Part")
Anchor.CFrame, Anchor.Parent = Rbx.CFrame.new(100, 0, 0), Npc
local Prompt = Rbx.Instance.new("ProximityPrompt")
Prompt.Name, Prompt.Parent = "SecretStorePrompt", Anchor
local Root = { Position = Rbx.Vector3.zero }
local Controller = { bAutoLimitedShop = true, bLimitedShopAllowGems = false }
local Runtime = { bAlive = true, LimitedShopLabels = {}, RodUpdateGate = {} }
local Data = { Time = 0, Calls = {}, Moves = 0, Restores = 0, Text = {}, bPresent = true, bOpen = true }
--[[ @param Scope 商店。 @param Key 商品。 @return 商品沒有被版本鎖定。 ]]
function Runtime.RodUpdateGate.IsOfferHeld(Scope, Key) return false end
local Stores = Luau.load(assert(Source:match("(local LIMITED_SHOPS = {.-\n})")) .. "\nreturn LIMITED_SHOPS")()
local Constants = {}
for _, Store in Stores do
	Constants[Store.Key] = { Offers = { A = { CashCost = 10 } } }
	--[[ @param self 狀態控制項。 @param Title 標題。 @param Text 個別商店狀態。 ]]
	Runtime.LimitedShopLabels[Store.Key] = { Set = function(self, Title, Text) Data.Text[Title] = Text end }
end
local Environment = {
	Constants = Constants, Controller = Controller, _Runtime = Runtime, LIMITED_SHOPS = Stores, workspace = World,
	CFrame = Rbx.CFrame, Vector3 = Rbx.Vector3,
	--[[ @return 當前單調時間。 ]]
	os = { clock = function() return Data.Time end },
	--[[ @param _ 遊戲。 @param Name 服務名稱。 @return NPC 標記服務。 ]]
	game = { GetService = function(_, Name)
		assert(Name == "CollectionService")
		--[[ @param _ 服務。 @param Tag 商店 NPC 標記。 @return 對應的在場模型。 ]]
		return { GetTagged = function(_, Tag) return if Tag == "SecretShopRig" and Data.bPresent then { Npc } else {} end }
	end },
	--[[ @param _ 玩家。 @param Name 貨幣屬性。 @return 玩家可用現金或鑽石。 ]]
	LocalPlayer = { GetAttribute = function(_, Name) return 100 end },
	--[[ @param Key 功能。 @param Text 狀態。 ]]
	_Status = function(Key, Text) Data.Text[Key] = Text end,
	--[[ @return 測試根部。 ]]
	_Character = function() return Root end,
	--[[ @param Value 原生商店提示。 @return 世界座標。 ]]
	_PromptPosition = function(Value) return Value.Parent.CFrame.Position end,
	--[[ @param Key 功能。 @param Part 根部。 @param Target 目的地。 @return 是否允許移動。 ]]
	_Travel = function(Key, Part, Target)
		assert(Key == "bAutoLimitedShop")
		Runtime.Move, Runtime.bMoving = { Key = Key, Original = Part.Position }, true
		Data.Moves += 1
		Part.Position = Target.Position
		if Data.bDisappear then Npc.Parent = nil end
		if Data.bCancel then Controller.bAutoLimitedShop = false end
		return not Data.bRefuse
	end,
	--[[ @param Key 只還原此功能的位移。 ]]
	_RestoreMove = function(Key)
		if Runtime.Move and Runtime.Move.Key == Key then
			Root.Position = Runtime.Move.Original
			Runtime.Move, Runtime.bMoving = nil, false
			Data.Restores += 1
		end
	end,
}
--[[
	模擬近距離查詢才開放的商店，以及查詢／購買錯誤。
	@param Name 原生遠端。
	@param ... 封包。
	@return 原始狀態或接受結果。
]]
Environment._Invoke = function(Name, ...)
	local Args = table.pack(...)
	table.insert(Data.Calls, { Name = Name, Args = Args })
	if Name:match("GetState$") then
		assert(Args.n == 0)
		if Data.bThrowQuery and Root.Position.X > 50 then error("nearby query failed") end
		local bActive = Name == "SecretStoreGetState" and Root.Position.X > 50 and Data.bOpen
		return { active = bActive, timed = true, despawnAt = if bActive then 160 else 0, serverTime = 100,
			offers = { A = { visible = true, stock = 2 } } }
	end
	assert(Name == "SecretStorePurchase" and Args.n == 2 and Args[1] == "A" and Args[2] == "Cash", "只能使用已確認的原生貨幣購買")
	assert(Root.Position.X > 50, "靠近後取得的商店狀態必須在返回前購買")
	if Data.bThrowPurchase then error("purchase failed") end
	return true
end
local Block = {}
for _, Name in { "_TryLimitedShop", "_LimitedShopNpc", "_TryNearbyLimitedShop", "_BuyLimitedShop" } do
	table.insert(Block, assert(Source:match("(local function " .. Name .. ".-\nend)")))
end
local Buy = Luau.load(table.concat(Block, "\n") .. "\nreturn _BuyLimitedShop", { environment = Environment })()
--[[ @return 本輪購買呼叫數。 ]]
local function Purchases()
	local Count = 0
	for _, Call in Data.Calls do if Call.Name:match("Purchase$") then Count += 1 end end
	return Count
end
Buy()
assert(Purchases() == 1 and Data.Moves == 1 and Data.Restores == 1 and Root.Position == Rbx.Vector3.zero,
	"原地狀態未開放、NPC 在場時，靠近重查並購買後須返回，且每輪最多一件")
assert(Data.Text["Selene 商店狀態"]:find("已接受", 1, true), "個別商店結果不能被其他三間等待狀態蓋掉")
Data.Calls, Data.bOpen = {}, false
Buy()
assert(Purchases() == 0 and Root.Position == Rbx.Vector3.zero and Data.Text["Selene 商店狀態"]:find("已找到", 1, true),
	"找到 NPC 但仍未開放時應如實顯示，不覆寫伺服器狀態或盲目購買")
Data.bPresent, Data.Calls = false, {}
local Before = Data.Moves
Buy()
assert(Data.Moves == Before and Purchases() == 0, "地圖沒有 NPC 時不猜座標傳送")
Data.bPresent, Data.bOpen, Data.bRefuse = true, true, true
Data.Calls = {}
Buy()
assert(Purchases() == 0 and Root.Position == Rbx.Vector3.zero and not Runtime.bMoving, "移動交接失敗仍還原，且不可購買")
Data.bRefuse, Data.bCancel, Data.Calls = false, true, {}
Buy()
assert(Purchases() == 0 and Root.Position == Rbx.Vector3.zero, "傳送期間關閉後不再查詢購買")
Controller.bAutoLimitedShop, Data.bCancel, Data.bDisappear, Data.Calls = true, false, true, {}
Buy()
assert(Purchases() == 0 and Root.Position == Rbx.Vector3.zero, "途中 NPC 離場後不可購買")
Npc.Parent, Data.bDisappear, Data.bThrowQuery, Data.Calls = World, false, true, {}
Buy()
assert(Purchases() == 0 and Root.Position == Rbx.Vector3.zero and not Runtime.bMoving, "靠近後查詢拋錯也須還原")
Data.bThrowQuery, Data.bThrowPurchase, Data.Calls = false, true, {}
Buy()
assert(Purchases() == 1 and Root.Position == Rbx.Vector3.zero and not Runtime.bMoving, "購買拋錯不能留下位移或重送同輪購買")
Data.bThrowPurchase = false
Runtime.bMoving, Runtime.Move, Data.Calls = true, { Key = "bAutoFeed" }, {}
Before = Data.Moves
Buy()
assert(Data.Moves == Before and Runtime.Move.Key == "bAutoFeed" and Purchases() == 0, "不得搶佔或還原其他功能的位移")
World:Destroy()
print("FishAnAnimeLimitedShop: passed (nearby retry, per-store status, rejection, cancellation, cleanup)")

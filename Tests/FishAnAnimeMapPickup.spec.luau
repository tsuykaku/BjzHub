--!nonstrict
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local Block = assert(Source:match("%-%- MAP_PICKUP_START(.-)%-%- MAP_PICKUP_END"))
-- Lune 不提供 BasePart.Position 衍生 getter，只有測試投影成原生等價 CFrame.Position。
Block = Block:gsub("Root%.Position", "Root.CFrame.Position"):gsub("Object%.Position", "Object.CFrame.Position")
local World = Rbx.Instance.new("Folder")
World.Name = "Workspace"
local Character = Rbx.Instance.new("Model")
Character.Parent = World
local Root = Rbx.Instance.new("Part")
Root.Name, Root.Parent = "HumanoidRootPart", Character
local Player = { UserId = 42, Character = Character }
local State = { Drops = {}, Retry = setmetatable({}, { __mode = "k" }), Unavailable = setmetatable({}, { __mode = "k" }), bSynced = false }
local Runtime = { bAlive = true, Connections = {} }
local Controller = { bAutoMapPickup = true }
local Data = { Time = 0, Calls = {}, Tags = {}, Text = "", bAccept = true, bRemoveTouch = true }
local Tags = {}
--[[ @param self 標記服務。 @param Tag 名稱。 @return 測試標記物件。 ]]
function Tags.GetTagged(self, Tag) return Data.Tags[Tag] or {} end
--[[ @param self 標記服務。 @param Object 物件。 @param Tag 名稱。 @return 標記是否仍存在。 ]]
function Tags.HasTag(self, Object, Tag) return table.find(Data.Tags[Tag] or {}, Object) ~= nil end
local Remote = { OnClientEvent = {} }
--[[ @param self 事件替身。 @param Callback 拾取快取回呼。 @return 可清理連線。 ]]
function Remote.OnClientEvent.Connect(self, Callback)
	Data.Callback = Callback
	return { Disconnect = function() Data.Callback = nil end }
end
--[[ @param self 遠端替身。 @param ClassName 預期類別。 @return 是否為 RemoteEvent。 ]]
function Remote.IsA(self, ClassName) return ClassName == "RemoteEvent" end
--[[ @param self 遠端替身。 @param Action 原生操作。 @param Id 原生數字 ID。 ]]
function Remote.FireServer(self, Action, Id)
	table.insert(Data.Calls, { Kind = Action, Id = Id, Point = Root.CFrame.Position })
	if Action == "sync" and Data.Sync then Data.Callback("sync", Data.Sync) end
	if Action == "pickup" then
		assert(type(Id) == "number" and (Root.CFrame.Position - State.Drops[Id].Point).Magnitude <= 3.5)
		Data.Callback(if Data.bAccept then "taken" else "deny", Id)
	end
end
local Env = { workspace = World, LocalPlayer = Player, _MapPickup = State, _Runtime = Runtime, Controller = Controller }
Env.game = { GetService = function(self, Name) assert(Name == "CollectionService") return Tags end }
Env.Remotes = { FindFirstChild = function(self, Name) return if Name == "StandDrop" and not Data.bNoRemote then Remote else nil end }
Env.CFrame, Env.Vector3 = Rbx.CFrame, Rbx.Vector3
Env.os = { clock = function() return Data.Time end }
Env.task = { wait = function(Seconds) Data.Time += Seconds or 0.1 if Data.bYield then coroutine.yield() end end }
--[[ @param Value 原生或 Lune 替身。 @return 對應 Rbx 型別名稱。 ]]
Env.typeof = function(Value)
	if type(Value) == "userdata" then
		local bOk, Kind = pcall(function() return Value.__type end)
		if bOk and Kind then return Kind end
	end
	return typeof(Value)
end
--[[ @return 測試玩家根部。 ]]
Env._Character = function() return Root end
--[[ @param Key 功能鍵。 @param Text 狀態文字。 ]]
Env._Status = function(Key, Text) assert(Key == "bAutoMapPickup") Data.Text = Text end
--[[ @param Prompt 原生提示。 @return 提示的實際世界座標。 ]]
Env._PromptPosition = function(Prompt) return Prompt.Parent.CFrame.Position end
--[[ @param Key 功能鍵。 @param Part 角色根部。 @param Target 目標位置。 @return 本輪是否仍可執行。 ]]
Env._Travel = function(Key, Part, Target)
	table.insert(Data.TravelFrom, Part.CFrame.Position)
	Runtime.Move, Runtime.bMoving = Runtime.Move or { Original = Part.CFrame }, true
	Part.CFrame = Target
	if Data.OnTravel then Data.OnTravel() end
	return Controller[Key]
end
--[[ @param Key 要還原的功能。 ]]
Env._RestoreMove = function(Key)
	Data.Restores = (Data.Restores or 0) + 1
	if Runtime.Move then Root.CFrame = Runtime.Move.Original end
	Runtime.Move, Runtime.bMoving = nil, false
end
--[[ @param Part1 玩家根部。 @param Part2 道具原生觸碰部件。 @param Toggle 0 開始、1 結束。 ]]
Env.firetouchinterest = function(Part1, Part2, Toggle)
	assert(Part1 == Root and (Root.CFrame.Position - Part2.CFrame.Position).Magnitude <= 5)
	table.insert(Data.Calls, { Kind = "Touch", Part = Part2, Toggle = Toggle })
	if Toggle == 0 and Data.bTouchError then error("touch error") end
	if Toggle == 0 and Data.bRemoveTouch then Part2.Parent = nil end
end
--[[ @param Prompt 原生拾取提示。 ]]
Env.fireproximityprompt = function(Prompt)
	assert(Prompt.Enabled and (Root.CFrame.Position - Prompt.Parent.CFrame.Position).Magnitude <= Prompt.MaxActivationDistance)
	table.insert(Data.Calls, { Kind = "Prompt", Prompt = Prompt })
	Prompt.Parent.Parent = nil
end
local Pickup = Luau.load(Block .. "\nreturn _MapPickup", { environment = Env })()
--[[ @param Name 標記物件名稱。 @param Position 地圖座標。 @return 可觸碰的原生部件。 ]]
local function Part(Name, Position)
	local Object = Rbx.Instance.new("Part")
	Object.Name, Object.CFrame, Object.Parent, Object.CanTouch = Name, Rbx.CFrame.new(Position, 0, 0), World, true
	Object.LocalTransparencyModifier = 0
	return Object
end
--[[ 清空本輪呼叫與伺服器替身，保留已連線的事件測試生命週期。 ]]
local function Reset()
	Data.Calls, Data.Tags, Data.Sync, Data.OnTravel, Data.Text = {}, {}, nil, nil, ""
	Data.bAccept, Data.bRemoveTouch, Data.bYield, Data.bTouchError = true, true, false, false
	Data.TravelFrom, Data.Restores = {}, 0
	State.Drops, State.Retry = {}, setmetatable({}, { __mode = "k" })
	State.Unavailable = setmetatable({}, { __mode = "k" })
	Controller.bAutoMapPickup = true
	Root.CFrame = Rbx.CFrame.new()
end
Reset()
do
	local Gem, Candy, Foreign = Part("Gem", 100), Part("Candy", 200), Part("Foreign", 1)
	Foreign:SetAttribute("OwnerUserId", 99)
	Data.Tags.EventGemHover, Data.Tags.HalloweenCandy = { Gem, Foreign }, { Candy }
	Pickup.Step()
	assert(#Data.Calls == 5 and Data.Calls[2].Part == Gem and Data.Calls[2].Toggle == 0 and Data.Calls[3].Toggle == 1
		and Data.Calls[4].Part == Candy and Data.Calls[5].Toggle == 1, "一輪應處理所有可用目標，不只最近的一份")
	assert(Root.CFrame.Position == Rbx.Vector3.zero and not Runtime.bMoving and not State.Touch)
	assert(Data.Text:find("遊戲已確認 0", 1, true), "只有觸碰不冒稱伺服器接受")
	assert(Data.Restores == 1 and Data.TravelFrom[2] == Rbx.Vector3.new(100, 2, 0), "整輪只返回一次，物品之間不返回起點")
	Candy:Destroy() Foreign:Destroy()
end
Reset()
do
	Data.Sync = { { id = 73, pos = Rbx.Vector3.new(500, 0, 0), life = 30, kind = "LoveEssence" } }
	State.bSynced = false
	Pickup.Step()
	assert(Data.Calls[2].Kind == "pickup" and Data.Calls[2].Id == 73 and Data.Text:find("遊戲已確認 1", 1, true))
	assert(#Runtime.Connections == 1 and Root.CFrame.Position == Rbx.Vector3.zero)
	Data.bAccept = false
	Pickup.OnDrop("add", { id = 74, pos = Rbx.Vector3.new(300, 0, 0), life = 30, kind = "SakuraLeaf" })
	Pickup.Step()
	local Calls = #Data.Calls
	Pickup.Step()
	assert(#Data.Calls == Calls and State.Drops[74], "拒絕後保留記錄並冷卻，不重複追同一掉落")
	Pickup.OnDrop("remove", 74)
	Pickup.OnDrop("add", { id = 75, pos = Rbx.Vector3.new(300, 0, 0), life = 0, kind = "LoveEssence" })
	Pickup.OnDrop("add", { id = 76, pos = Rbx.Vector3.new(300, 0, 0), life = 30, kind = "Unknown" })
	assert(not State.Drops[74] and not State.Drops[75] and not State.Drops[76])
end
Reset()
do
	local Gem = Part("Vanished", 200)
	Data.Tags.EventGemHover = { Gem }
	Data.OnTravel = function() Gem.Parent = nil end
	Pickup.Step()
	assert(#Data.Calls == 0 and Root.CFrame.Position == Rbx.Vector3.zero, "途中消失不得繼續互動")
end
Reset()
do
	local Anchor = Part("Lost Diary", 100)
	local Prompt = Rbx.Instance.new("ProximityPrompt")
	Prompt.Name, Prompt.ActionText, Prompt.ObjectText, Prompt.Parent = "AmnesiaPickupPrompt", "Pick Up", "Lost Diary", Anchor
	Prompt.Enabled, Prompt.MaxActivationDistance = true, 12
	local Shop = Part("Shop", 1)
	local Purchase = Rbx.Instance.new("ProximityPrompt")
	Purchase.Name, Purchase.ActionText, Purchase.Parent, Purchase.Enabled = "PurchasePrompt", "Buy", Shop, true
	Pickup.Step()
	assert(#Data.Calls == 1 and Data.Calls[1].Prompt == Prompt, "只操作來源已確認的拾取提示，不買商店")
	Shop:Destroy()
end
Reset()
do
	local Gem = Part("CancelGem", 500)
	Data.Tags.EventGemHover, Data.bRemoveTouch, Data.bYield = { Gem }, false, true
	local Job = coroutine.create(Pickup.Step)
	assert(coroutine.resume(Job))
	assert(State.Touch and Data.Calls[1].Toggle == 0)
	Controller.bAutoMapPickup = false
	Pickup.ReleaseTouch()
	Env._RestoreMove("bAutoMapPickup")
	coroutine.close(Job)
	Pickup.ReleaseTouch()
	assert(#Data.Calls == 2 and Data.Calls[2].Toggle == 1 and Root.CFrame.Position == Rbx.Vector3.zero)
	Gem:Destroy()
end
Reset()
do
	local Gem = Part("MissingCapability", 1)
	Data.Tags.EventGemHover = { Gem }
	local WithoutTouch = table.clone(Env)
	WithoutTouch.firetouchinterest = nil
	WithoutTouch._MapPickup = { Drops = {}, Retry = {}, Unavailable = {}, Remote = Remote, bSynced = true }
	local MissingPickup = Luau.load(Block .. "\nreturn _MapPickup", { environment = WithoutTouch })()
	MissingPickup.Step()
	assert(#Data.Calls == 0 and Data.Text:find("firetouchinterest", 1, true) and Root.CFrame.Position == Rbx.Vector3.zero,
		"能力缺少時應說明原因且不傳送，不假裝觸碰成功")
	Gem:Destroy()
end
Reset()
do
	Runtime.bMoving = true
	Pickup.Step()
	assert(#Data.Calls == 0 and Data.Text:find("等待其他移動", 1, true), "其他功能持有移動鎖時不得搶位移")
	Runtime.bMoving = false
	Pickup.OnDrop("add", { id = 80, pos = Rbx.Vector3.new(500, 0, 0), life = 1, kind = "LoveEssence" })
	Data.Time += 2
	Pickup.Step()
	assert(not State.Drops[80] and #Data.Calls == 0, "已過期掉落不得傳送或請求領取")
end
Reset()
do
	local Items = {}
	for Index = 1, 20 do Items[Index] = Part("LongRound" .. Index, 100 + Index * 10) end
	Data.Tags.EventGemHover, Data.bRemoveTouch = Items, false
	local Started = Data.Time
	Pickup.Step()
	assert(#Data.Calls == 40 and Data.Time - Started > 20, "超過20秒的一輪仍須處理完整20份物品，每份僅嘗試一次")
	assert(Data.Restores == 1 and not State.ProgressAt and Root.CFrame.Position == Rbx.Vector3.zero)
	for _, Object in Items do Object:Destroy() end
end
Reset()
do
	local First, Vanished, Last = Part("First", 100), Part("VanishedBatch", 200), Part("Last", 300)
	Data.Tags.EventGemHover = { First, Vanished, Last }
	Data.OnTravel = function()
		if Root.CFrame.Position.X == 100 then Vanished.Parent = nil end
	end
	Pickup.Step()
	assert(#Data.Calls == 4 and Data.Calls[1].Part == First and Data.Calls[3].Part == Last, "單項途中消失不能阻擋其他物品")
	assert(Data.Text:find("略過 1", 1, true))
end
Reset()
do
	local First, Last = Part("FirstError", 100), Part("AfterError", 300)
	Data.Tags.EventGemHover = { First, Last }
	Data.OnTravel = function() Data.bTouchError = Root.CFrame.Position.X == 100 end
	Pickup.Step()
	assert(#Data.Calls == 4 and Data.Calls[3].Part == Last and Data.Calls[4].Toggle == 1, "單項錯誤後仍須拾取後續物品並結束觸碰")
	First:Destroy()
end
Reset()
do
	local First = Part("CurrentRound", 100)
	Data.Tags.EventGemHover = { First }
	Data.OnTravel = function()
		table.insert(Data.Tags.EventGemHover, Part("NextRound", 300))
		Data.OnTravel = nil
	end
	Pickup.Step()
	assert(#Data.Calls == 2 and Data.Tags.EventGemHover[2].Parent == World, "途中新生成的物品留到下一輪，避免本輪永不結束")
	Data.Tags.EventGemHover[2]:Destroy()
end
Reset()
do
	local Gem = Part("ErrorGem", 500)
	Data.Tags.EventGemHover, Data.bTouchError = { Gem }, true
	assert(pcall(Pickup.Step))
	Pickup.ReleaseTouch()
	Env._RestoreMove("bAutoMapPickup")
	assert(not State.Touch and Data.Calls[2].Toggle == 1 and not Runtime.bMoving)
	assert(Data.Text:find("錯誤 1", 1, true), "單項失敗應記錄並完成本輪清理")
	Gem:Destroy()
end
Reset()
do
	local CharacterTool = Rbx.Instance.new("Tool")
	CharacterTool.Name, CharacterTool.Parent = "CharacterTool", World
	CharacterTool:SetAttribute("IsCharacterTool", true)
	local Handle = Part("Handle", 1)
	Handle.Parent = CharacterTool
	Rbx.Instance.new("TouchTransmitter").Parent = Handle
	local OrdinaryTool = Rbx.Instance.new("Tool")
	OrdinaryTool.Name, OrdinaryTool.Parent = "OrdinaryTool", World
	local OrdinaryHandle = Part("Handle", 100)
	OrdinaryHandle.Parent = OrdinaryTool
	Rbx.Instance.new("TouchTransmitter").Parent = OrdinaryHandle
	local Model = Rbx.Instance.new("Model")
	Model.Parent = World
	Model:SetAttribute("IsCharacterModel", true)
	local CharacterPart = Part("CharacterPart", 2)
	CharacterPart.Parent = Model
	local Spawns = Rbx.Instance.new("Folder")
	Spawns.Name, Spawns.Parent = "SpawnedCharacters", World
	local SpawnPart = Part("SpawnCharacter", 3)
	SpawnPart.Parent = Spawns
	local NamedCharacter = Part("NamedCharacter", 4)
	NamedCharacter:SetAttribute("CharacterName", "Itsi Naka")
	local Gem = Part("OrdinaryGem", 200)
	Data.Tags.EventGemHover = { Handle, CharacterPart, SpawnPart, NamedCharacter, Gem }
	Pickup.Step()
	assert(#Data.Calls == 4 and Data.Calls[1].Part == OrdinaryHandle and Data.Calls[3].Part == Gem,
		"即使角色更近、有可觸碰Handle或混入鑽石標記，也只拾取一般道具與鑽石")
	assert(Handle.Parent == CharacterTool and CharacterPart.Parent == Model and SpawnPart.Parent == Spawns and NamedCharacter.Parent == World)
	-- 候選生成後才複寫角色屬性，也必須在到達時重新排除。
	OrdinaryHandle.Parent = OrdinaryTool
	Data.Calls, Data.Tags, State.Retry = {}, {}, {}
	Data.OnTravel = function() OrdinaryTool:SetAttribute("IsCharacterTool", true) end
	Pickup.Step()
	assert(#Data.Calls == 0 and OrdinaryHandle.Parent == OrdinaryTool, "途中變為角色工具時不得繼續拾取")
	CharacterTool:Destroy() OrdinaryTool:Destroy() Model:Destroy() Spawns:Destroy() NamedCharacter:Destroy()
end
Reset()
do
	local Coin = Rbx.Instance.new("Tool")
	Coin.Name, Coin.Parent = "Ancient Coin", World
	local Handle = Part("Handle", 100)
	Handle.Parent = Coin
	Rbx.Instance.new("TouchTransmitter").Parent = Handle
	local Gem = Part("ValidGem", 300)
	Data.Tags.EventGemHover = { Gem }
	Data.OnTravel = function() Data.bRemoveTouch = Root.CFrame.Position.X ~= 100 end
	Pickup.Step()
	assert(#Data.Calls == 4 and State.Unavailable[Handle] == "Ancient Coin" and Handle.Parent == Coin and Gem.Parent == nil,
		"Ancient Coin 無拾取結果時須略過該實體，但繼續拾取其餘物品")
	Data.Time += 120
	Data.Calls = {}
	Pickup.Step()
	assert(#Data.Calls == 0 and Data.Text:find("Ancient Coin", 1, true), "下一輪不得反覆觸發同一 Ancient Coin 的遊戲錯誤，且須顯示物品名稱")
	local NewCoin = Coin:Clone()
	NewCoin.Parent = World
	local NewHandle = NewCoin:FindFirstChild("Handle")
	NewHandle.CFrame = Rbx.CFrame.new(500, 0, 0)
	Pickup.Step()
	assert(#Data.Calls == 2 and NewHandle.Parent == nil and Handle.Parent == Coin, "新生成同名物品不應被名稱永久封鎖")
	Data.Calls = {}
	table.clear(State.Unavailable)
	Data.OnTravel = function() Data.bRemoveTouch = true end
	Pickup.Step()
	assert(#Data.Calls == 2 and Handle.Parent == nil, "重開功能清除本輪隔離後可以重新嘗試原物件")
	Coin:Destroy() NewCoin:Destroy()
end
Reset()
do
	local Coin = Part("EventCoin", 100)
	Data.Tags.AmneticCoin = { Coin }
	Controller.bAutoMapPickup, Controller.bAutoEventQuests = false, true
	local Items = Pickup.Candidates(Tags)
	assert(#Items == 1 and Pickup.Attempt(Items[1], Root, Tags, "bAutoEventQuests") == "Unconfirmed"
		and #Data.Calls == 2, "活動開關可獨立使用原生觸碰，不依賴地圖拾取開關")
	State.Touch = { Root = Root, Part = Coin, FeatureKey = "bAutoEventQuests" }
	Pickup.ReleaseTouch("bAutoMapPickup")
	assert(State.Touch and #Data.Calls == 2, "關閉地圖拾取不得釋放活動功能持有的觸碰")
	Pickup.ReleaseTouch("bAutoEventQuests")
	assert(not State.Touch and #Data.Calls == 3, "活動取消須結束自己的觸碰且可重複清理")
	Pickup.ReleaseTouch("bAutoEventQuests")
	assert(#Data.Calls == 3)
	Env._RestoreMove("bAutoEventQuests")
	Coin:Destroy()
end
for _, Connection in Runtime.Connections do Connection:Disconnect() end
assert(not Data.Callback)
print("FishAnAnimeMapPickup: all assertions passed")

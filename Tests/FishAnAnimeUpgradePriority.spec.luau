local Fs, Luau = require("@lune/fs"), require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local Constants = { UpgradesStore = { Offers = {
	A = { Label = "Cash Multiplier", MaxLevels = 2, Costs = { 100, 180 } },
	B = { Label = "Luck Upgrade", MaxLevels = 2, Costs = { 60, 120 } },
	C = { Label = "Faster Catch Upgrade", MaxLevels = 2, Costs = { 40, 80 } },
} } }
local PlayerGui = Rbx.Instance.new("Folder")
local MainGui = Rbx.Instance.new("Folder")
MainGui.Name, MainGui.Parent = "MainGui", PlayerGui
local Shop = Rbx.Instance.new("Folder")
Shop.Name, Shop.Parent = "UpgradesStoreGUI", MainGui
local NativeCard = Rbx.Instance.new("Frame")
NativeCard.Parent = Shop
NativeCard:SetAttribute("OfferKey", "A")
local NativeTitle = Rbx.Instance.new("TextLabel")
NativeTitle.Name, NativeTitle.Parent, NativeTitle.Text = "Title", NativeCard, '<font color="rgb(0,255,0)">Cash Upgrade</font>'
local Controller = { bAutoUpgrade = true, UpgradePriorityOrder = { "A", "B", "C" } }
local Runtime = { bAlive = true, Jobs = {} }
local Priority = { Controls = {}, Rows = {} }
local Data = { State = { levels = {} }, Cash = 200, Calls = {}, Flags = {}, Text = "", Time = 0, Rebirths = 1,
	RebirthState = { nextCostText = "1,000", nextRankName = "Rank2" } }
local UiRoot = Rbx.Instance.new("Frame")
local Card = {}
--[[ @param self Card。 @param Options 空白布局宿主。 @return 有原生 Frame 的控制項。 ]]
function Card.CreateLabel(self, Options)
	local Host = { Frame = Rbx.Instance.new("Frame") }
	Host.Frame.Parent = UiRoot
	--[[ @param self 宿主。 @param Text 內文。 ]]
	function Host.Set(self, Text) self.Text = Text end
	return Host
end
--[[ @param self Card。 @param Options 設定。 @return 不允許建立排序下拉選單。 ]]
function Card.CreateDropdown(self, Options) error("排序不可使用 Dropdown") end
--[[ @param self 原生控制項 Card 替身。 @param Options 隱藏設定。 @return 有既有 Flag 的排序保存值。 ]]
function Card.CreateInput(self, Options)
	assert(Options.bVisible == false, "承接舊順位 Flag 的 Input 不可顯示成可編輯文字框")
	local Control = { Options = Options, Value = Options.CurrentValue }
	--[[ @param self 控制項。 @return 目前選項。 ]]
	function Control.Get(self) return self.Value end
	--[[ @param self 控制項。 @param Value 要保存的鍵名。 @param bSilent true 不發送回呼。 ]]
	function Control.Set(self, Value, bSilent)
		self.Value, Data.Flags[self.Options.Flag] = Value, Value
		assert(bSilent, "內部保存同步不應觸發使用者編輯")
	end
	return Control
end
--[[ @param self Card。 @param Options 按鈕設定。 @return 可點選、可停用及改文字的按鈕。 ]]
function Card.CreateButton(self, Options)
	local Button = { Options = Options, Text = Options.Name, bEnabled = Options.bEnabled ~= false, Frame = Rbx.Instance.new("Frame") }
	Button.Frame.Parent = UiRoot
	Button.Button = Rbx.Instance.new("TextButton")
	Button.Button.Parent = Button.Frame
	--[[ @param self 按鈕。 @param Text 新的順位與人類名稱。 ]]
	function Button.Set(self, Text) self.Text = Text end
	--[[ @param self 按鈕。 @param bEnabled 是否可以移動選項。 ]]
	function Button.SetEnabled(self, bEnabled) self.bEnabled = bEnabled end
	return Button
end
--[[ @param self Card。 @param Options 預覽設定。 @return 計畫預覽替身。 ]]
function Card.CreateParagraph(self, Options)
	--[[ @param _ 預覽。 @param Title 標題。 @param Text 內容。 ]]
	return { Set = function(_, Title, Text) Data.Text = Text end }
end
local Environment = { Constants = Constants, Controller = Controller, _Runtime = Runtime, _UpgradePriority = Priority,
	Instance = Rbx.Instance, UDim2 = Rbx.UDim2, UDim = Rbx.UDim, Enum = Rbx.Enum,
	--[[ @return 可控制的時間，檢查轉生狀態快取是否過期。 ]]
	os = { clock = function() return Data.Time end },
	--[[ @param _ 玩家。 @param Key 貨幣屬性。 @return 當前可用金錢。 ]]
	LocalPlayer = { GetAttribute = function(_, Key) return if Key == "Rebirths" then Data.Rebirths else Data.Cash end,
		--[[ @param _ 玩家。 @param Name 要讀取的 UI 根。 @return 原生玩家 GUI。 ]]
		FindFirstChild = function(_, Name) return if Name == "PlayerGui" then PlayerGui else nil end },
	--[[ @param Key 工作鍵。 @param Text 狀態。 ]]
	_Status = function(Key, Text) Data.Status = Text end,
}
--[[ @param Name 原生遠端名稱。 @param ... 原生參數。 @return 伺服器替身回應。 ]]
Environment._Invoke = function(Name, ...)
	table.insert(Data.Calls, { Name = Name, Args = table.pack(...) })
	if Name == "RebirthGetState" then
		assert(... == true, "沿用原生轉生費用查詢參數")
		if Data.bRebirthError then error("rebirth state unavailable") end
		if Data.OnRebirthQuery then Data.OnRebirthQuery() end
		return Data.RebirthState
	end
	if Name == "UpgradesStoreGetState" then
		if Data.OnQuery then Data.OnQuery() end
		return Data.State
	end
	assert(Name == "UpgradesStorePurchase")
	return true
end
local Upgrade = Luau.load(assert(Source:match("(local function _ReadGameAmount.-\nend)")) .. "\n"
	.. assert(Source:match("(local function _UpgradeCost.-\nend)")) .. "\n"
	.. assert(Source:match("%-%- UPGRADE_PRIORITY_START(.-)%-%- UPGRADE_PRIORITY_END")) .. "\n"
	.. assert(Source:match("(local function _Upgrade%(%).-\nend)")) .. "\nreturn _Upgrade", { environment = Environment })()
assert(Priority.Select(Data.State, 200).Key == "B", "應同時計算順序與價格：A 3/100、B 2/60、C 1/40，因此選B")
assert(Priority.Select(Data.State, 50).Key == "C", "高順位買不起時，不可阻擋低順位可負擔升級")
assert(not Priority.Select(Data.State, 0) and not Priority.Select(Data.State, 0/0), "缺錢或金錢無效時不選擇購買")
Data.State.levels.B = 1
assert(Priority.Select(Data.State, 200).Key == "A", "每輪必須依下一級實際價格重算權重")
Data.State.levels.A, Data.State.levels.B = 2, 2
assert(Priority.Select(Data.State, 200).Key == "C", "滿級項目須跳過")
Data.State.levels.C = 2
assert(not Priority.Select(Data.State, 200))
Data.State.levels = {}
Constants.UpgradesStore.Offers.A.Costs[1], Constants.UpgradesStore.Offers.B.Costs[1] = 120, 80
assert(Priority.Select(Data.State, 200).Key == "A", "相同權重依較高順位決定，而非最便宜或不穩定雜湊順序")
Constants.UpgradesStore.Offers.A.Costs[1], Constants.UpgradesStore.Offers.B.Costs[1] = 0, 0
assert(Priority.Select(Data.State, 200).Key == "A", "免費升級優先，同為免費時依順位")
Constants.UpgradesStore.Offers.A.Costs[1], Constants.UpgradesStore.Offers.B.Costs[1] = math.huge, -1
assert(Priority.Select(Data.State, 200).Key == "C", "無限大與負價格不可當成有利升級")
Constants.UpgradesStore.Offers.A.Costs[1], Constants.UpgradesStore.Offers.B.Costs[1] = 100, 60
Priority.CreateUi(Card)
assert(Priority.Scroll:IsA("ScrollingFrame") and Priority.Scroll.AutomaticCanvasSize == Rbx.Enum.AutomaticSize.Y
	and Priority.Scroll.ClipsDescendants and Priority.Scroll.Active, "項目必須放在可捲動且裁切的固定高度清單")
for _, Row in Priority.Rows do assert(Row.Frame.Parent == Priority.Scroll and Row.Frame.Size.Y.Offset == 34) end
assert(Priority.Scroll:FindFirstChildOfClass("UIPadding").PaddingLeft.Offset >= 6, "清單左側須留出邊框空間，避免裁切")
for _, Row in Priority.Rows do
	assert(Row.Button.TextXAlignment == Rbx.Enum.TextXAlignment.Left and Row.Button.TextTruncate == Rbx.Enum.TextTruncate.AtEnd,
		"長名稱應從左顯示並在右側截斷，不可置中造成左半文字被切掉")
end
assert(Priority.Up.Frame.Size == Rbx.UDim2.fromOffset(32, 32) and Priority.Down.Frame.Size == Rbx.UDim2.fromOffset(32, 32)
	and Priority.Up.Text == "↑" and Priority.Down.Text == "↓", "兩個排序按鈕必須是32像素小正方形箭頭")
assert(Priority.Up.Frame.Parent == Priority.Host.Frame and Priority.Down.Frame.Parent == Priority.Host.Frame
	and not Priority.Up.Frame:IsDescendantOf(Priority.Scroll), "排序按鈕應固定在清單旁，不跟清單捲走")
assert(Priority.Name("A") == "Cash Upgrade" and Priority.Name("B") == "Luck Upgrade", "優先顯示商店 Title，未載入卡片時使用原生 Label")
Priority.Load()
assert(Priority.Rows[1].Text:find("Cash Upgrade", 1, true) and Priority.Rows[2].Text:find("Luck Upgrade", 1, true)
	and Priority.Rows[3].Text:find("Faster Catch Upgrade", 1, true), "可點選清單使用商店人類名稱，隱藏保存值仍為原生鍵")
assert(not Priority.Up.bEnabled and not Priority.Down.bEnabled, "未選取時兩個排序按鈕都應停用")
NativeTitle.Text = "Cash Upgrade Updated"
Priority.Render()
assert(Priority.Rows[1].Text:find("Cash Upgrade Updated", 1, true))
assert(Priority.Controls[1]:Get() == "A", "標題延遲變更時刷新名稱不得改變順位")
NativeTitle.Text = "Cash Upgrade"
Priority.Rows[3].Options.Callback()
assert(Priority.SelectedKey == "C" and Priority.Up.bEnabled and not Priority.Down.bEnabled
	and table.concat(Controller.UpgradePriorityOrder, ",") == "A,B,C", "點選只選取，不直接重排；最後一項不能下調")
Priority.Move(1)
assert(table.concat(Controller.UpgradePriorityOrder, ",") == "A,B,C", "邊界即使直接呼叫也不得越界")
Priority.Up.Options.Callback()
assert(table.concat(Controller.UpgradePriorityOrder, ",") == "A,C,B" and Priority.SelectedKey == "C", "上調只移動一格且保持選取同一項目")
Priority.Up.Options.Callback()
assert(table.concat(Controller.UpgradePriorityOrder, ",") == "C,A,B"
	and Priority.Controls[1]:Get() == "C" and Data.Flags.UpgradePriority_3 == "B", "連續上調保存完整順序，不產生重複")
assert(not Priority.Up.bEnabled and Priority.Down.bEnabled and Priority.Rows[1].Text:find("▶", 1, true), "移到第一名後停用上調，並在新位置標示選取")
Priority.Down.Options.Callback()
assert(table.concat(Controller.UpgradePriorityOrder, ",") == "A,C,B" and Priority.SelectedKey == "C", "下調也只移動一格")
Runtime.bAlive = false
Priority.Move(-1)
assert(table.concat(Controller.UpgradePriorityOrder, ",") == "A,C,B", "卸載後舊回呼不得修改排序")
Runtime.bAlive = true
assert(Data.Text:find("下一級價格", 1, true) and Data.Text:find("Faster Catch Upgrade", 1, true))
Priority.Controls[1].Value, Priority.Controls[2].Value, Priority.Controls[3].Value = "B", "C", "A"
Priority.Load()
assert(table.concat(Controller.UpgradePriorityOrder, ",") == "B,C,A", "必須先讀取所有保存值，再同步控制項")
Priority.Controls[1].Value, Priority.Controls[2].Value, Priority.Controls[3].Value = "C", "Removed", "C"
Priority.Load()
assert(table.concat(Controller.UpgradePriorityOrder, ",") == "C,A,B", "舊項目已移除或重複設定時應修復成完整有效順序")
Constants.UpgradesStore.Offers.New = { MaxLevels = 1, Costs = { 1 } }
local Updated = Priority.Normalize(Controller.UpgradePriorityOrder)
assert(table.concat(Updated, ",") == "C,A,B,New" and Priority.Select(Data.State, 200).Key == "New", "新商品應追加於排序末尾並參與價格加權")
Constants.UpgradesStore.Offers.New = nil
Controller.UpgradePriorityOrder = { "A", "B", "C" }
Data.Calls = {}
Upgrade()
assert(#Data.Calls == 2 and Data.Calls[2].Args[1] == "B" and Data.Calls[2].Args[2] == 1 and Data.Calls[2].Args.n == 2,
	"單輪僅查詢及購買一級，沿用原生封包")
assert(Data.Status:find("Luck Upgrade", 1, true) and Data.Text:find("本輪選擇：Luck Upgrade", 1, true),
	"購買結果及權重預覽也要顯示商店名稱，不能只修改下拉選項")
--[[ 在查詢恢復前改變排序，這輪應使用最新偏好而不是啟動時的舊順序。 ]]
Data.OnQuery = function() Controller.UpgradePriorityOrder = { "C", "B", "A" } end
Data.Calls = {}
Upgrade()
assert(Data.Calls[2].Args[1] == "C", "查詢期間調整排序後應使用最新順序")
--[[ 查詢期間關閉工作，不能在恢復後仍購買。 ]]
Data.OnQuery = function() Controller.bAutoUpgrade = false end
Data.Calls = {}
Upgrade()
assert(#Data.Calls == 1, "查詢期間關閉後不得購買")
Data.OnQuery, Controller.bAutoUpgrade, Data.Calls = nil, true, {}
Data.State = {}
assert(not pcall(Upgrade) and #Data.Calls == 1, "無效商店回應必須停止而非推測價格並購買")
Data.State, Data.Calls = { levels = {} }, {}
Controller.bAutoRebirth, Controller.UpgradeRebirthSavePercent = true, 80
Data.Cash = 790
Upgrade()
assert(#Data.Calls == 3 and Data.Calls[3].Name == "UpgradesStorePurchase", "尚未達80%時可按權重升級，並解析千分位轉生費用")
Data.Cash, Data.Calls, Data.Time = 800, {}, 0.5
Upgrade()
assert(#Data.Calls == 1 and Data.Status:find("優先存錢轉生", 1, true), "達到門檻時不再花費，並重用同次轉生的最新快取")
Data.Cash, Data.Calls = 700, {}
Upgrade()
assert(#Data.Calls == 1, "存錢階段即使餘額因其他操作下降也不可重新花錢升級")
Data.Cash, Data.Calls = 1000, {}
Upgrade()
assert(#Data.Calls == 1 and Data.Status:find("金額已足夠", 1, true), "金錢足夠轉生時必須保留，不可先買升級")
Data.Rebirths, Data.Cash, Data.Calls = 2, 100, {}
Data.RebirthState = { nextCostText = "5000", nextRankName = "Rank3" }
Upgrade()
assert(#Data.Calls == 3 and Data.Calls[3].Name == "UpgradesStorePurchase", "轉生次數改變時應重新查費用並解除上一輪存錢狀態")
Controller.UpgradeRebirthSavePercent, Data.Cash, Data.Calls = 10, 500, {}
Upgrade()
assert(#Data.Calls == 1, "使用者可調整存錢門檻")
Controller.UpgradeRebirthSavePercent, Data.Calls = 90, {}
Upgrade()
assert(Data.Calls[#Data.Calls].Name == "UpgradesStorePurchase", "提高門檻後應立即重新評估，而非沿用舊門檻鎖定")
Controller.bAutoRebirth, Data.Calls = false, {}
Upgrade()
assert(#Data.Calls == 2 and not Priority.bSaving, "關閉自動轉生時維持原本升級方式，且不查詢轉生")
Controller.bAutoRebirth, Runtime.UpgradeRebirthCache, Data.Calls, Data.RebirthState = true, nil, {}, {}
Upgrade()
assert(#Data.Calls == 2 and Data.Status:find("尚未載入", 1, true), "未知轉生金額應明確暫緩，而非猜測目標")
Data.bRebirthError, Runtime.UpgradeRebirthCache, Data.Calls = true, nil, {}
Upgrade()
assert(#Data.Calls == 2 and Data.Status:find("無法確認", 1, true), "查詢失敗時不得花掉轉生資金")
Data.bRebirthError, Data.RebirthState, Data.Calls = false, { nextCostText = "5000" }, {}
--[[ 在轉生查詢等待期間關閉升級，恢復後不可再購買。 ]]
Data.OnRebirthQuery = function() Controller.bAutoUpgrade = false end
Upgrade()
assert(#Data.Calls == 2, "轉生查詢期間停用後不能購買升級")
Data.OnRebirthQuery, Controller.bAutoUpgrade, Data.Calls, Runtime.Jobs.bAutoRebirth = nil, true, {}, {}
Upgrade()
assert(#Data.Calls == 1, "轉生處理中不另送出查詢或升級")
PlayerGui:Destroy()
UiRoot:Destroy()
print("FishAnAnimeUpgradePriority: passed (weighted choice, affordability, levels, order swaps, persistence, cancellation)")

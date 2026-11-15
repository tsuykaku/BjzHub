--!nonstrict
--[[ 驗證原生暫停控制與平台彈窗分派；不修改真正的 CoreGui 或購買服務。 ]]
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
Luau.compile(Source)
local Start = assert(Source:find("-- CLIENT_UI_GUARDS_START", 1, true))
local Finish = assert(Source:find("-- CLIENT_UI_GUARDS_END", Start, true))
local Chunk = Source:sub(Start, Finish - 1) .. "return _ClientUi"
local State = { Mode = Rbx.Enum.StreamingIntegrityMode.MinimumRadiusPause, bNotification = true, bModeDenied = false,
	StreamRequests = 0, Installs = 0, Originals = 0, Method = "", Messages = {} }
local World = setmetatable({}, {
	--[[ @param self 場景。 @param Key 屬性。 @return 串流暫停模式。 ]]
	__index = function(self, Key) assert(Key == "StreamingIntegrityMode") return State.Mode end,
	--[[ @param self 場景。 @param Key 屬性。 @param Value 新模式。 ]]
	__newindex = function(self, Key, Value) assert(Key == "StreamingIntegrityMode" and not State.bModeDenied, "模擬串流權限不足") State.Mode = Value end,
})
local Gui = {}
--[[ @param self UI 服務。 @return 通知是否顯示。 ]]
function Gui.GetGameplayPausedNotificationEnabled(self) return State.bNotification end
--[[ @param self UI 服務。 @param bEnabled 通知目標狀態。 ]]
function Gui.SetGameplayPausedNotificationEnabled(self, bEnabled) State.bNotification = bEnabled end
local Services = { GuiService = Gui, MarketplaceService = {}, GroupService = {}, SocialService = {}, ExperienceNotificationService = {} }
local Game = {}
--[[ @param self 遊戲。 @param Name 服務名稱。 @return 對應原生服務替身。 ]]
function Game.GetService(self, Name) return assert(Services[Name], Name) end
local Root = { Position = {} }
--[[ @param self 根部。 @param ClassName 類別。 @return 是否為零件。 ]]
function Root.IsA(self, ClassName) return ClassName == "BasePart" end
local Player = { GameplayPaused = true, Character = {
	--[[ @param self 角色。 @param Name 根部名稱。 @return 玩家根部。 ]]
	FindFirstChild = function(self, Name) assert(Name == "HumanoidRootPart") return Root end,
} }
--[[ @param self 玩家。 @param Position 載入位置。 @param Timeout 最長秒數。 ]]
function Player.RequestStreamAroundAsync(self, Position, Timeout)
	assert(Position == Root.Position and Timeout == 3)
	State.StreamRequests += 1
	self.GameplayPaused = false
end
local Meta = {}
--[[ @param Self 服務或 Remote。 @param ... 原始參數。 @return 放行標記及所有原始參數。 ]]
Meta.__namecall = function(Self, ...) State.Originals += 1 return "forwarded", Self, ... end
local InitialNamecall = Meta.__namecall
local Shared = {}
--[[ @param Object 遊戲。 @param Name 元方法名稱。 @param Hook 替換函數。 @return 原本的函數。 ]]
function Shared.hookmetamethod(Object, Name, Hook)
	assert(Object == Game and Name == "__namecall")
	State.Installs += 1
	local Original = Meta[Name]
	Meta[Name] = Hook
	return Original
end
--[[ @return 目前呼叫方法名稱。 ]]
function Shared.getnamecallmethod() return State.Method end
--[[ @param Callback 分派函數。 @return 測試用可呼叫 closure。 ]]
function Shared.newcclosure(Callback) return Callback end
--[[ @param Object 遊戲。 @return 測試元方法表。 ]]
function Shared.getrawmetatable(Object) assert(Object == Game) return Meta end
local Controller = { bSuppressGameplayPause = true, bBlockPlatformPrompts = true }
local Runtime = { bAlive = true }
--[[ @return 載入正式適配程式的新控制器；共用 hook 與服務保持不變。 ]]
local function _Load()
	return Luau.load(Chunk, { environment = setmetatable({ _ClientUi = { Blocked = 0 }, _Runtime = Runtime,
		Controller = Controller, Environment = Shared, game = Game, workspace = World, LocalPlayer = Player, Enum = Rbx.Enum,
		--[[ @param Key 真正需要載入場景的功能鍵；渲染策略由獨立測試覆蓋。 ]]
		_Performance = { BeginInteraction = function(Key) assert(Key == "bSuppressGameplayPause") end },
		--[[ @param Key 功能。 @param Message 狀態訊息。 ]]
		_Status = function(Key, Message) State.Messages[Key] = Message end,
	}, { __index = getfenv() }) })()
end
local Guards = _Load()
Guards.PauseStep()
assert(not State.bNotification and State.Mode == Rbx.Enum.StreamingIntegrityMode.Disabled and State.StreamRequests == 1)
Guards.PauseStep()
Guards.RestorePause()
assert(State.bNotification and State.Mode == Rbx.Enum.StreamingIntegrityMode.MinimumRadiusPause)
Guards.PauseStep()
State.Mode = Rbx.Enum.StreamingIntegrityMode.PauseOutsideLoadedArea
Guards.RestorePause()
assert(State.Mode == Rbx.Enum.StreamingIntegrityMode.PauseOutsideLoadedArea, "不可覆寫其他程式後來設定的不同模式")
State.bModeDenied = true
Guards.PauseStep()
assert(not State.bNotification and State.Messages.bSuppressGameplayPause:find("解除暫停未確認", 1, true))
assert(State.Messages.bSuppressGameplayPause:find("串流權限不足", 1, true), "隱藏通知不能被說成已解除暫停")
State.bModeDenied = false
Guards.RestorePause()
Guards.PromptStep()
Guards.PromptStep()
assert(State.Installs == 1)
State.Method = "PromptProductPurchase"
assert(Meta.__namecall(Services.MarketplaceService, Player, 123) == nil and State.Originals == 0)
State.Method = "PromptGamePassPurchase"
assert(Meta.__namecall(Services.MarketplaceService, Player, 123) == nil)
State.Method = "PromptPurchase"
assert(Meta.__namecall(Services.MarketplaceService, Player, 123) == nil)
State.Method = "PromptJoinAsync"
assert(Meta.__namecall(Services.GroupService, 1) == Rbx.Enum.GroupMembershipStatus.None)
State.Method = "PromptRsvpToEventAsync"
assert(Meta.__namecall(Services.SocialService, "event") == Rbx.Enum.RsvpStatus.None)
State.Method = "PromptGameInvite"
assert(Meta.__namecall(Services.SocialService, Player) == nil)
State.Method = "PromptOptIn"
assert(Meta.__namecall(Services.ExperienceNotificationService) == nil)
State.Method = "GetProductInfo"
local Values = table.pack(Meta.__namecall(Services.MarketplaceService, 123, nil, 456))
assert(Values.n == 5 and Values[1] == "forwarded" and Values[2] == Services.MarketplaceService and Values[5] == 456)
State.Method = "PromptProductPurchase"
local OtherObject = {}
assert(Meta.__namecall(OtherObject, "unrelated") == "forwarded", "只依方法名稱攔截會誤傷其他物件")
Controller.bBlockPlatformPrompts = false
assert(Meta.__namecall(Services.MarketplaceService, Player, 123) == "forwarded")
Controller.bBlockPlatformPrompts = true
Runtime.bAlive = false
assert(Meta.__namecall(Services.MarketplaceService, Player, 123) == "forwarded")
Runtime.bAlive = true
Guards.StopPrompts()
Guards.StopPrompts()
assert(Meta.__namecall == InitialNamecall and Shared.__FishPlatformPromptsV1 == nil, "可證明仍持有 hook 時才還原")
Guards.PromptStep()
local InstalledBus = Shared.__FishPlatformPromptsV1
local OurHook = Meta.__namecall
--[[ @param Self 接收物件。 @param ... 其他 wrapper 完整轉送參數。 @return 原始結果。 ]]
local OuterHook = function(Self, ...) return OurHook(Self, ...) end
Meta.__namecall = OuterHook
Guards.StopPrompts()
assert(Meta.__namecall == OuterHook and InstalledBus.Owner == nil, "不可覆寫其他 wrapper")
assert(Meta.__namecall(Services.MarketplaceService, Player, 123) == "forwarded")
local NextGuards = _Load()
local Installs = State.Installs
NextGuards.PromptStep()
assert(State.Installs == Installs and Shared.__FishPlatformPromptsV1 == InstalledBus, "重跑重用單一分派器，不堆疊 hook")
assert(Meta.__namecall(Services.MarketplaceService, Player, 123) == nil)
NextGuards.StopPrompts()
local HookApi = Shared.hookmetamethod
Shared.hookmetamethod = nil
local Missing = _Load()
local bOk, Error = pcall(Missing.PromptStep)
assert(not bOk and tostring(Error):find("缺少 hookmetamethod", 1, true))
Shared.hookmetamethod = HookApi
print("FishAnAnimeClientUi: pause notification/mode, streaming request, permission failures, prompt rules, forwarding and hook ownership passed")

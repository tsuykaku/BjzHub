--!nonstrict
--[[
	Fish an Anime Rng · BjzUi 3.x
	協定來自使用者提供的 place 74729868188364 快照，來源與限制見 README。
	首次使用採用使用者提供的預設設定；重新執行優先恢復遊戲專屬設定檔。
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
assert(LocalPlayer and game.PlaceId == 74729868188364, "請在 Fish an Anime RNG 客戶端執行")
assert(
	type(getgenv) == "function" and type(gethui) == "function" and type(loadstring) == "function",
	"執行器缺少 getgenv、gethui 或 loadstring"
)
local Environment = getgenv()
local UIParent = gethui()
assert(type(Environment) == "table" and typeof(UIParent) == "Instance", "執行器環境或 gethui() 回傳值無效")
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local ConstantsModule = ReplicatedStorage:WaitForChild("Constants", 15)
assert(Remotes and ConstantsModule and ConstantsModule:IsA("ModuleScript"), "遊戲資料尚未載入")
local Constants = require(ConstantsModule)
local BjzUi =
	loadstring(game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Library/BjzUiLibrary_2.0.luau"))()
assert(
	type(Constants) == "table" and type(BjzUi) == "table" and type(BjzUi.CreateWindow) == "function",
	"模組 API 不相容"
)
if Environment.FishAnAnimeRngBjz then
	Environment.FishAnAnimeRngBjz.Unload()
end

-- GAME_DEFAULTS_START
--[[ 使用者提供的遊戲選項作為新設定檔的預設值；不含玩家識別碼或已移除功能。 ]]
local DEFAULT_GAME_SETTINGS = {
	["Flags"] = {
		["bAllowGems"] = false,
		["bAutoBoxes"] = true,
		["bAutoBoxes_Interval"] = 10,
		["bAutoBuild"] = true,
		["bAutoBuild_Interval"] = 300,
		["bAutoBuyPotions"] = true,
		["bAutoBuyPotions_Interval"] = 2.5,
		["bAutoBuyRod"] = true,
		["bAutoBuyRod_Interval"] = 60,
		["bAutoCharacters"] = true,
		["bAutoCharacters_Interval"] = 300,
		["bAutoCollectFood"] = false,
		["bAutoCollectFood_Interval"] = 15,
		["bAutoDailyRewards"] = true,
		["bAutoDailyRewards_Interval"] = 60,
		["bAutoDrinkPotions"] = true,
		["bAutoDrinkPotions_Interval"] = 2.5,
		["bAutoEventQuests"] = true,
		["bAutoEventQuests_Interval"] = 10,
		["bAutoFeed"] = true,
		["bAutoFeed_Interval"] = 15,
		["bAutoFish"] = true,
		["bAutoFish_Interval"] = 0.5,
		["bAutoGear"] = true,
		["bAutoGear_Interval"] = 60,
		["bAutoInboxRewards"] = true,
		["bAutoInboxRewards_Interval"] = 60,
		["bAutoIndexRewards"] = true,
		["bAutoIndexRewards_Interval"] = 60,
		["bAutoLeaveRewards"] = true,
		["bAutoLeaveRewards_Interval"] = 60,
		["bAutoLimitedShop"] = false,
		["bAutoLimitedShop_Interval"] = 3,
		["bAutoMapPickup"] = false,
		["bAutoMapPickup_Interval"] = 60,
		["bAutoMedalRewards"] = true,
		["bAutoMedalRewards_Interval"] = 60,
		["bAutoNpcRewards"] = true,
		["bAutoNpcRewards_Interval"] = 60,
		["bAutoOfflineRewards"] = true,
		["bAutoOfflineRewards_Interval"] = 60,
		["bAutoPlaytimeRewards"] = true,
		["bAutoPlaytimeRewards_Interval"] = 60,
		["bAutoQuestRewards"] = true,
		["bAutoQuestRewards_Interval"] = 60,
		["bAutoRebirth"] = true,
		["bAutoRebirth_Interval"] = 30,
		["bAutoResearch"] = true,
		["bAutoResearch_Interval"] = 30,
		["bAutoSellCharacters"] = true,
		["bAutoSellCharacters_Interval"] = 0.1,
		["bAutoUpgrade"] = true,
		["bAutoUpgrade_Interval"] = 180,
		["bAutoWorkers"] = true,
		["bAutoWorkers_Interval"] = 300,
		["bLimitedShopAllowGems"] = false,
		["bLowEffects"] = true,
		["bLowEffects_Interval"] = 3,
		["bDisable3dRendering"] = false,
		["bDeleteUiEffects"] = false,
		["bDeleteUiEffects_Interval"] = 60,
		["bAutoSkipTutorial"] = true,
		["bAutoSkipTutorial_Interval"] = 2,
		["bSuppressGameplayPause"] = true,
		["bSuppressGameplayPause_Interval"] = 2,
		["bBlockPlatformPrompts"] = true,
		["bBlockPlatformPrompts_Interval"] = 3,
		["bPreventAutoRejoin"] = true,
		["bPreventAutoRejoin_Interval"] = 15,
		["bResearchAllowGems"] = true,
		["FeedAction"] = "全部餵食",
		["FeedMode"] = "平均分配",
		["Potion_AbyssalGraspAbility"] = false,
		["Potion_AbyssalSurgeEffect"] = false,
		["Potion_AmethystisedEffect"] = false,
		["Potion_Amnetic"] = false,
		["Potion_AmplifiedAbility"] = false,
		["Potion_AstralThoughtsEffect"] = false,
		["Potion_BrokenEffect"] = false,
		["Potion_cash_2x"] = true,
		["Potion_cash_4x"] = true,
		["Potion_cash_8x"] = true,
		["Potion_Complex"] = false,
		["Potion_ComplexBerry"] = false,
		["Potion_ComplexManipulationEffect"] = false,
		["Potion_CorruptionEffect"] = false,
		["Potion_CyberneticGlitch"] = false,
		["Potion_DreamEffect"] = false,
		["Potion_Dreamer"] = false,
		["Potion_DullEffect"] = false,
		["Potion_EmptinessEffect"] = false,
		["Potion_EXE"] = false,
		["Potion_fastcatch_2x"] = true,
		["Potion_FastCatch_L2"] = true,
		["Potion_Food_L1"] = true,
		["Potion_Food_L2"] = true,
		["Potion_Forgotten"] = false,
		["Potion_ForgottenEffect"] = false,
		["Potion_gems_2x"] = true,
		["Potion_gems_4x"] = true,
		["Potion_gems_8x"] = true,
		["Potion_HallowPotion"] = false,
		["Potion_HeavenCollide"] = false,
		["Potion_HeavensCollideAbility"] = false,
		["Potion_HellBeastEffect"] = false,
		["Potion_Honey"] = false,
		["Potion_HoneyEffect"] = false,
		["Potion_IcedOutEffect"] = false,
		["Potion_JesterizedEffect"] = false,
		["Potion_JesterizedV2Effect"] = false,
		["Potion_JesterizedV3Effect"] = false,
		["Potion_LimerenceEffect"] = false,
		["Potion_LimerenceNovaEffect"] = false,
		["Potion_LimerenceSolarEffect"] = false,
		["Potion_LucidEffect"] = false,
		["Potion_luck_2x"] = true,
		["Potion_Luck_L2"] = true,
		["Potion_Luck_L3"] = true,
		["Potion_Luck_L4"] = true,
		["Potion_LucrativePotion"] = false,
		["Potion_Meteorite"] = false,
		["Potion_MidasTouchEffect"] = false,
		["Potion_Mutater_L1"] = true,
		["Potion_mutation_2x"] = true,
		["Potion_PartyEffect"] = false,
		["Potion_PartyPotion"] = false,
		["Potion_RadioactiveEffect"] = false,
		["Potion_RealizationEffect"] = false,
		["Potion_RebornEffect"] = false,
		["Potion_RubifiedEffect"] = false,
		["Potion_SacrificationEffect"] = false,
		["Potion_Sinister"] = false,
		["Potion_SinisterBerry"] = false,
		["Potion_TacofiedEffect"] = false,
		["Potion_WOWPotion"] = false,
		["ResearchPriority"] = "食物項目優先",
		["SellRarities"] = {
			"Common",
			"Uncommon",
		},
		["UpgradePriority_1"] = "T1O1",
		["UpgradePriority_10"] = "T5O2",
		["UpgradePriority_11"] = "T5O3",
		["UpgradePriority_12"] = "T5O4",
		["UpgradePriority_13"] = "T3O1",
		["UpgradePriority_14"] = "T4O2",
		["UpgradePriority_15"] = "T4O1",
		["UpgradePriority_2"] = "T1O2",
		["UpgradePriority_3"] = "T3O3",
		["UpgradePriority_4"] = "T4O3",
		["UpgradePriority_5"] = "T5O1",
		["UpgradePriority_6"] = "T2O3",
		["UpgradePriority_7"] = "T2O1",
		["UpgradePriority_8"] = "T2O2",
		["UpgradePriority_9"] = "T3O2",
		["UpgradeRebirthSavePercent"] = 80,
	},
	["UI"] = {
		["Accent"] = "#2DD4BF",
		["Animations"] = true,
		["Cursor"] = {
			["bEnabled"] = true,
			["bHideNative"] = true,
			["bUseAccent"] = true,
			["Color"] = "#FFFFFF",
			["Opacity"] = 1,
			["OutlineColor"] = "#0C1218",
			["Size"] = 24,
			["Style"] = "Arrow",
		},
		["Height"] = 593.1428833007812,
		["MiniX"] = 19,
		["MiniY"] = 60,
		["Scale"] = 1,
		["Subtabs"] = {
			["自動出售"] = "一般",
			["自動領獎"] = "一般",
			["角色與食物"] = "一般",
			["建築與成長"] = "一般",
			["效能與設定"] = "一般",
			["釣魚與魚竿"] = "一般",
			["藥水與 Box"] = "一般",
		},
		["Tab"] = "建築與成長",
		["ToggleKey"] = "RightShift",
		["Width"] = 983.2856979370117,
		["X"] = 64,
		["Y"] = 10,
	},
}
-- GAME_DEFAULTS_END

--[[
	公開控制器；介面完成載入後，同步玩家／遊戲分組中的設定與功能開關。
]]
local Controller = { bAllowGems = false, bLimitedShopAllowGems = false, bResearchAllowGems = true, UpgradeRebirthSavePercent = 80, FeedMode = "平均分配", FeedAction = "全部餵食", ResearchPriority = "金錢項目優先", PotionKeys = {}, SellRarities = {}, Intervals = {} }
Controller.bRenderingEnabled = true
Controller.bDisable3dRendering = false
--[[ 轉生前單輪餵食的子工作與排程互斥；不修改一般餵食設定或功能開關。 ]]
local _RebirthFood = { bActive = false }
--[[ 地圖拾取的事件快取、重試冷卻與自己持有的觸碰，卸載時一併清理。 ]]
local _MapPickup = { Drops = {}, Retry = setmetatable({}, { __mode = "k" }), Unavailable = setmetatable({}, { __mode = "k" }), Touch = nil, Remote = nil, bSynced = false }
--[[ 活動任務角色保留名單在完整查詢後更新；查詢失敗時停止該輪出售。 ]]
local _EventQuests = { Protected = {}, Entries = {}, Cursor = 0 }
--[[ 升級商店的排序控制項與順位／費用選擇；沿用原生價格公式及共用 UI 設定保存。 ]]
local _UpgradePriority = { Controls = {}, Rows = {}, Label = nil, SelectedKey = nil }
--[[ 效能引擎只在開啟低特效時載入；失敗節流重試，保留可供清理的控制器。 ]]
local _Performance = { Engine = nil, Module = nil, NextLoadAt = 0, Error = nil }
--[[ 只停用快照確認的 AutoRejoinClient；紀錄自己變更的腳本，以便關閉或卸載時恢復。 ]]
local _Rejoin = { Scripts = setmetatable({}, { __mode = "k" }) }
--[[ 教學跳過沿用原生按鈕與確認，快取查詢並等候原生結束流程，不自行修改完成狀態。 ]]
local _Tutorial = { NextStateAt = 0, WaitUntil = 0 }
--[[ 暫停提示與平台彈窗的適配狀態；只變更已確認的原生介面入口。 ]]
local _ClientUi = { Blocked = 0 }
--[[ 遊戲裝飾 UI 的已確認範圍與清理工作；不共用通用引擎的整份 UI 刪除功能。 ]]
local _UiEffects = { Queue = {}, Retry = setmetatable({}, { __mode = "k" }), Generation = 0, Deleted = 0,
	Names = { StatCollectFX = true, StarHandler = true, RotationSpinSizeFXHandler = true, SizeFXHandler = true, CollectFX = true },
	Scripts = {
		["MainGui/StatCollectFX"] = "CollectScript",
		["MainGui/ButtonsTop/LuckyBox/Rays1/RotationSpinSizeFXHandler"] = "DecorationScript",
		["MainGui/Buttons/UIButtonsRight/Offer1/Rays1/RotationSpinSizeFXHandler"] = "DecorationScript",
		["MainGui/Buttons/UIButtonsRight/Offer2/Rays1/RotationSpinSizeFXHandler"] = "DecorationScript",
		["MainGui/Buttons/UIButtonsRight/Offer2/Rays2/RotationSpinSizeFXHandler"] = "DecorationScript",
		["ResearchComponents/DoubleResearchOffer/Rays/RotationSpinSizeFXHandler"] = "DecorationScript",
		["ResearchComponents/DoubleResearchOffer/Rays2/RotationSpinSizeFXHandler"] = "DecorationScript",
		["MainGui/StoreGUI/ScrollingFrame/OfferCashStore/3/BestLabel/SizeFXHandler"] = "DecorationScript",
		["MainGui/StoreGUI/ScrollingFrame/OfferGemsStore/3/BestLabel/SizeFXHandler"] = "DecorationScript",
	},
	StarSections = { UpgradesStoreGUI = "ScrollFrame", SecretStoreGUI = "ScrollFrame", SecretStore2GUI = "ScrollFrame",
		SecretStore3GUI = "ScrollFrame", SecretStore4GUI = "ScrollFrame", BoostsStoreGUI = "ScrollFrame", StoreGUI = "ScrollingFrame" },
	ParticleClasses = { Star = "ImageLabel", Streak = "Frame", Pixel = "Frame", OrbitStar = "ImageLabel", OrbitTail = "ImageLabel", BurstStar = "ImageLabel" },
}
--[[
	本腳本持有的工作、事件與暫時狀態；自動釣魚開啟時管理目前回合，關閉時保留手動回合。
]]
local _Runtime = {
	bAlive = true,
	bFishingOwned = false,
	bPendingOwned = false,
	bMoving = false,
	FishPhase = "Idle",
	NextCastAt = 0,
	NextNativeAutoFishAt = 0,
	NativeAutoFishRecord = nil,
	NativeAutoFishLabel = nil,
	ResumeNativeAutoFish = nil,
	FishChangedAt = 0,
	Jobs = {},
	StartedAt = {},
	RetryAt = {},
	FinishedAt = {},
	RetryNotBefore = {},
	Connections = {},
	Controls = {},
	Labels = {},
	Window = nil,
	Rod = nil,
	PreviousTool = nil,
	Move = nil,
	ResearchState = nil,
	ResearchLabel = nil,
	ResearchSelectionLabel = nil,
	ResearchText = nil,
	ResearchNextUiAt = 0,
	ResearchPendingName = nil,
	FeedTimes = setmetatable({}, { __mode = "k" }),
	FeedSpent = setmetatable({}, { __mode = "k" }),
	FeedLabel = nil,
	FeedText = nil,
	SellIndex = 0,
	LastSellGroup = "",
	PotionControls = {},
	Settings = {},
	ConfigLabel = nil,
	ConfigMessage = "",
	RodUpdateGate = nil,
	FoodResearchEffects = nil,
	NpcQuests = nil,
	NpcQuestIndex = 0,
	BuildTouch = nil,
	BuildRetryAt = setmetatable({}, { __mode = "k" }),
	WorkerGear = nil,
	WorkerLabel = nil,
	WorkerText = nil,
	WorkerIndex = 0,
	WorkerFoodScores = setmetatable({}, { __mode = "k" }),
	LastBoxKey = "",
	LimitedShopLabels = {},
	Effects = setmetatable({}, { __mode = "k" }),
	EffectsConnection = nil,
	bEffectsScanned = false,
}
--[[
	自動功能的開關、顯示名稱與間隔；Step 在入口完成設定後才排程。
]]
local _Features = {
	{ Key = "bAutoRebirth", Name = "自動轉生", Interval = 5 },
	{ Key = "bAutoFish", Name = "自動釣魚", Interval = 0.72 },
	{ Key = "bAutoGear", Name = "自動換最強裝備（魚竿）", Interval = 3 },
	{ Key = "bAutoCharacters", Name = "自動裝備最強角色", Interval = 6 },
	{ Key = "bAutoFeed", Name = "自動餵食角色", Interval = 2 },
	{ Key = "bAutoBuyPotions", Name = "自動買藥水", Interval = 5 },
	{ Key = "bAutoDrinkPotions", Name = "自動喝藥水", Interval = 5 },
	{ Key = "bAutoResearch", Name = "自動研究", Interval = 5 },
	{ Key = "bAutoUpgrade", Name = "自動升級商店", Interval = 3 },
	{ Key = "bAutoSellCharacters", Name = "自動賣角色", Interval = 3 },
	{ Key = "bLowEffects", Name = "效能模式（低特效）", Interval = 3 },
	{ Key = "bAutoBuyRod", Name = "自動購買可買的最強魚竿", Interval = 5 },
	{ Key = "bAutoQuestRewards", Name = "自動領取任務獎勵", Interval = 15 },
	{ Key = "bAutoIndexRewards", Name = "自動領取索引獎勵", Interval = 15 },
	{ Key = "bAutoDailyRewards", Name = "自動領取每日獎勵", Interval = 15 },
	{ Key = "bAutoPlaytimeRewards", Name = "自動領取遊玩時間獎勵", Interval = 15 },
	{ Key = "bAutoInboxRewards", Name = "自動領取信箱獎勵", Interval = 15 },
	{ Key = "bAutoMedalRewards", Name = "自動領取 Medal 獎勵", Interval = 30 },
	{ Key = "bAutoNpcRewards", Name = "自動領取 NPC 與活動任務獎勵", Interval = 15 },
	{ Key = "bAutoOfflineRewards", Name = "自動領取離線獎勵（一般領取）", Interval = 30 },
	{ Key = "bAutoLeaveRewards", Name = "自動領取離開提示贈禮", Interval = 30 },
	{ Key = "bAutoBuild", Name = "自動蓋家（購買建築）", Interval = 3 },
	{ Key = "bAutoWorkers", Name = "自動派遣適任角色（建築／Garden）", Interval = 6 },
	{ Key = "bAutoBoxes", Name = "自動開 Box", Interval = 5 },
	{ Key = "bAutoCollectFood", Name = "自動收集食物", Interval = 2 },
	{ Key = "bAutoMapPickup", Name = "自動撿取地圖上的物品", Interval = 60 },
	{ Key = "bAutoLimitedShop", Name = "自動購買限時商店物品", Interval = 5 },
	{ Key = "bAutoEventQuests", Name = "自動完成活動任務", Interval = 5 },
	{ Key = "bPreventAutoRejoin", Name = "防止閒置自動重新加入", Interval = 15 },
	{ Key = "bDeleteUiEffects", Name = "永久刪除 UI 裝飾特效", Interval = 60 },
	{ Key = "bAutoSkipTutorial", Name = "自動跳過教學", Interval = 2 },
	{ Key = "bSuppressGameplayPause", Name = "防止 Gameplay Paused 阻擋", Interval = 2 },
	{ Key = "bBlockPlatformPrompts", Name = "阻擋平台購買與社交彈窗", Interval = 3 },
}

--[[
	NavigationBar 分類與功能歸屬；每項功能建立獨立 CreateSection Card，沿用既有 Flag。
]]
local UI_GROUPS = {
	{ Key = "Fishing", Name = "釣魚與魚竿", Icon = "Home", Features = { "bAutoFish", "bAutoGear", "bAutoBuyRod" } },
	{ Key = "Characters", Name = "角色與食物", Icon = "People", Features = { "bAutoCharacters", "bAutoFeed", "bAutoCollectFood", "bAutoWorkers" } },
	{ Key = "Growth", Name = "建築與成長", Icon = "Zap", Features = { "bAutoRebirth", "bAutoResearch", "bAutoUpgrade", "bAutoBuild" } },
	{ Key = "Items", Name = "藥水與 Box", Icon = "Potion", Features = { "bAutoBuyPotions", "bAutoDrinkPotions", "bAutoBoxes", "bAutoMapPickup", "bAutoLimitedShop" } },
	{ Key = "Selling", Name = "自動出售", Icon = "Coin", Features = { "bAutoSellCharacters" } },
	{ Key = "Rewards", Name = "自動領獎", Icon = "TreasureChest", Features = { "bAutoQuestRewards", "bAutoIndexRewards", "bAutoDailyRewards",
		"bAutoPlaytimeRewards", "bAutoInboxRewards", "bAutoMedalRewards", "bAutoNpcRewards", "bAutoOfflineRewards", "bAutoLeaveRewards", "bAutoEventQuests" } },
	{ Key = "Settings", Name = "效能與設定", Icon = "Settings", Features = { "bLowEffects", "bPreventAutoRejoin", "bDeleteUiEffects", "bAutoSkipTutorial", "bSuppressGameplayPause", "bBlockPlatformPrompts" } },
}

--[[
	已由快照及原生背包確認的工作建築與狀態／卸下協定；菜園共用狀態查詢。
]]
local WORK_SITES = {
	{ Name = "Lemon Stand", Kind = "Gems", State = "LemonGetStandState", Unequip = "LemonUnequipChar" },
	{ Name = "Strawberry Stand", Kind = "Gems", State = "StrawberryGetStandState", Unequip = "LemonUnequipChar" },
	{ Name = "Fishing Dock", Kind = "Dock", State = "FishingDockGetState", Unequip = "FishingDockUnequipChar" },
	{ Name = "Garden1", Kind = "Food" }, { Name = "Garden2", Kind = "Food" },
	{ Name = "Garden3", Kind = "Food" }, { Name = "GardenPAID", Kind = "Food" },
}

--[[ 由各 SecretStoreClient 原始碼確認的限時商店協定；Yang／Sasha 也可由管理員常駐開啟。 ]]
local LIMITED_SHOPS = {
	{ Key = "SecretStore", Name = "Selene", Tag = "SecretShopRig", bGate = true, bCash = true },
	{ Key = "SecretStore2", Name = "Angelia", Tag = "SecretShop2Rig", bCash = true },
	{ Key = "SecretStore3", Name = "Yang", Tag = "SecretShop3Rig", bActiveState = true, bCash = false },
	{ Key = "SecretStore4", Name = "Sasha", Tag = "SecretShop4Rig", bActiveState = true, bCash = false },
}

--[[
	僅處理可關閉的渲染特效，不依名稱推測模型、零件或互動物件是否可刪除。
]]
local EFFECT_CLASSES = { ParticleEmitter = true, Trail = true, Beam = true, Smoke = true, Fire = true, Sparkles = true }

--[[
	列出遊戲原始英文品質，保留 RarityOrder 順序並補齊其他已定義品質。
	@return 品質名稱清單，每個名稱只出現一次。
	@return 已知品質集合，用來驗證介面選擇。
]]
local function _GetRarityOptions(): ({ string }, { [string]: boolean })
	local Options, Known, Extra = {}, {}, {}
	for _, Name in Constants.RarityOrder or {} do
		if type(Name) == "string" and Name ~= "" and not Known[Name] then
			Known[Name] = true
			table.insert(Options, Name)
		end
	end
	for Name in Constants.Rarities or {} do
		if type(Name) == "string" and Name ~= "" and not Known[Name] then
			Known[Name] = true
			table.insert(Extra, Name)
		end
	end
	table.sort(Extra)
	for _, Name in Extra do table.insert(Options, Name) end
	return Options, Known
end

--[[
	本次載入版本的品質清單與選項驗證集合，不以中文名稱或稀有度階級猜測出售範圍。
]]
local _RarityOptions, _KnownRarities = _GetRarityOptions()

--[[
	檢查 BjzUi 自動設定所需檔案能力，實際讀寫錯誤仍由其公開 API 回報。
	@return true 表示必要入口皆存在；false 表示應停用自動保存。
	@return 缺少的能力名稱；完整時為空字串。
]]
local function _ConfigCapabilities(): (boolean, string)
	local Defaults = { readfile = readfile, writefile = writefile, isfile = isfile,
		isfolder = isfolder, makefolder = makefolder }
	local Missing = {}
	for _, Name in { "readfile", "writefile", "isfile", "isfolder", "makefolder" } do
		if type(Environment[Name] or Defaults[Name]) ~= "function" then table.insert(Missing, Name) end
	end
	return #Missing == 0, table.concat(Missing, "、")
end

--[[
	建立既有 BjzUi 控制項，記錄其回呼以在靜默載入後同步遊戲狀態。
	@param Section 所屬介面區塊。
	@param Method BjzUi 公開控制項工廠名稱。
	@param Options 含固定 Flag 與 Callback 的設定。
	@return 原生 BjzUi 控制項。
]]
local function _Setting(Section, Method: string, Options)
	local Apply = Options.Callback
	local Control = Section[Method](Section, Options)
	assert(type(Control.Get) == "function", "遠端 BjzUi 缺少設定控制項 Get API")
	table.insert(_Runtime.Settings, { Control = Control, Apply = Apply })
	return Control
end

--[[
	顯示共用 UI 保存狀態，不另外建立檔案格式或寫入迴圈。
]]
local function _ConfigStatus(): ()
	if not _Runtime.ConfigLabel then return end
	local Reason = _Runtime.Window.LastConfigError
	local Message = if Reason then "設定讀寫失敗：" .. tostring(Reason) else _Runtime.ConfigMessage
	if _Runtime.ConfigLabel:Get() ~= Message then _Runtime.ConfigLabel:Set(Message) end
end

--[[
	更新功能狀態。
	@param Key 功能開關欄位。
	@param Message 狀態文字，不將封包送出解讀為伺服器已接受。
]]
local function _Status(Key: string, Message: string): ()
	if _Runtime.Labels[Key] then
		_Runtime.Labels[Key]:Set(Message)
	end
end

--[[
	更新單一自動功能的輪次間隔，閒置工作依上次完成時間重排；執行中的工作完成後套用。
	@param Feature 本遊戲的功能定義。
	@param Value 滑桿秒數；非有限數值不採用，合法值限制在 0.1 至 300 秒、精度 0.01。
]]
local function _SetInterval(Feature, Value): ()
	local Seconds = tonumber(Value)
	if not Seconds or Seconds ~= Seconds or math.abs(Seconds) == math.huge then return end
	Seconds = math.clamp(math.floor(math.clamp(Seconds, 0.1, 300) * 100 + 0.5) / 100, 0.1, 300)
	Feature.Interval, Controller.Intervals[Feature.Key] = Seconds, Seconds
	local FinishedAt = _Runtime.FinishedAt[Feature.Key]
	if FinishedAt and not _Runtime.Jobs[Feature.Key] then
		local Delay = if Feature.Key == "bAutoCharacters" and _Runtime.bCharacterContinue then 0.1 else Seconds
		if Feature.Key == "bAutoWorkers" and _Runtime.WorkerWait then Delay = math.min(1, Seconds) end
		_Runtime.RetryAt[Feature.Key] = math.max(FinishedAt + Delay, _Runtime.RetryNotBefore[Feature.Key] or 0)
	end
end

--[[
	停用一個 Workspace 視覺特效，保留 Instance 身分與原始 Enabled 狀態。
	@param Object 新增或掃描到的物件；非支援特效直接略過。
]]
local function _SuppressEffect(Object: Instance): ()
	if not Controller.bLowEffects or not EFFECT_CLASSES[Object.ClassName] or not Object:IsDescendantOf(workspace) then return end
	local Record = _Runtime.Effects[Object]
	if not Record then
		Record = { bOriginalEnabled = Object.Enabled }
		_Runtime.Effects[Object] = Record
	elseif Object.Enabled then
		-- 遊戲重新開啟時記錄最新可觀察到的需求，停用模式後恢復。
		Record.bOriginalEnabled = true
	end
	Object.Enabled = false
	if Object:IsA("ParticleEmitter") or Object:IsA("Trail") then Object:Clear() end
end

--[[
	只還原目前仍為本模式停用值的特效；不重新建立已被遊戲銷毀的物件。
	@param Object 先前處理的特效物件。
	@param Record 原先或遊戲後續開啟時記錄的 Enabled 狀態。
]]
local function _RestoreEffect(Object: Instance, Record): ()
	if Object.Parent and Object.Enabled == false then Object.Enabled = Record.bOriginalEnabled end
end

--[[
	解除新增事件並還原仍存在的特效；可重複呼叫，供關閉、卸載及重跑使用。
]]
local function _RestoreEffects(): ()
	if _Performance.Engine then
		_Performance.Engine.Destroy()
		_Performance.Engine = nil
	end
	if _Runtime.bAlive and _Performance.bRenderingTouched then
		_Performance.SetRendering(Controller.bRenderingEnabled)
	end
	if _Runtime.EffectsConnection then
		_Runtime.EffectsConnection:Disconnect()
		_Runtime.EffectsConnection = nil
	end
	for Object, Record in _Runtime.Effects do pcall(_RestoreEffect, Object, Record) end
	table.clear(_Runtime.Effects)
	_Runtime.bEffectsScanned = false
end

--[[
	首次調整渲染前保存原始狀態；讀取能力不可用時沿用引擎的開啟預設值。
]]
function _Performance.CaptureRendering(): ()
	if _Performance.bRenderingCaptured then return end
	_Performance.RunService = game:GetService("RunService")
	--[[ @return 引擎目前的 3D 渲染狀態；執行器拒絕時由 pcall 處理。 ]]
	local bOk, bEnabled = pcall(function() return _Performance.RunService:Is3dRenderingEnabled() end)
	_Performance.bOriginalRenderingEnabled = if bOk and type(bEnabled) == "boolean" then bEnabled else true
	_Performance.bRenderingCaptured = true
end

--[[
	立即切換 3D 渲染；效能引擎存在時沿用其 API，未開低特效時可獨立操作。
	@param bEnabled true 顯示 3D，false 僅停止 3D 畫面繪製。
	@return true 表示成功；false 表示未套用。
	@return 失敗原因；成功為 nil。
]]
function _Performance.SetRendering(bEnabled: boolean): (boolean, string?)
	if not _Runtime.bAlive then return false, "腳本已卸載" end
	_Performance.CaptureRendering()
	local bOk, Reason
	if _Performance.Engine then
		local bCalled, bApplied, Error = pcall(_Performance.Engine.SetRenderingEnabled, bEnabled)
		bOk, Reason = bCalled and bApplied == true, if bCalled then Error else bApplied
	else
		--[[ 沿用效能引擎使用的原生入口，讓此開關不依賴低特效或遠端下載。 ]]
		bOk, Reason = pcall(function() _Performance.RunService:Set3dRenderingEnabled(bEnabled) end)
	end
	if bOk then _Performance.bRenderingTouched, _Performance.bLastRenderingEnabled = true, bEnabled end
	if _Performance.RenderingLabel then
		_Performance.RenderingLabel:Set("3D 渲染狀態", if bOk then (if bEnabled then "3D 渲染已開啟" else "3D 渲染已關閉；介面與自動操作繼續執行") else "切換失敗：" .. tostring(Reason))
	end
	return bOk, if bOk then nil else tostring(Reason)
end

--[[
	連續釣魚期間優先保持關閉；只有釣魚已停止、位移工作確認接手後才為互動／載入開啟。
	購買、領獎等可在背景完成的請求不打斷此狀態；其餘時間沿用保存選項。
	只在目標狀態改變時呼叫引擎；失敗後節流重試，不改寫保存的手動選項。
	@return true 表示已套用或不需變更；false 表示未能確認所需狀態。
	@return 失敗原因；成功為 nil。
]]
function _Performance.SyncRendering(): (boolean, string?)
	if not _Runtime.bAlive then return false, "腳本已卸載" end
	local bInteraction = _Runtime.bMoving or _Runtime.CharacterApplying or _Runtime.WorkerGear ~= nil
		or (_Performance.RenderingJobs ~= nil and next(_Performance.RenderingJobs) ~= nil)
	local Move = _Runtime.Move
	local bAutoFishing = Controller.bAutoFish and not (Move and Move.Key ~= "bAutoFish"
		and Move.bInteractionReady == true and _Runtime.FishPhase == "Idle" and not _Runtime.bPendingOwned)
	local bEnabled = if bAutoFishing then false elseif bInteraction then true else not Controller.bDisable3dRendering
	if _Performance.bRenderingTouched and _Performance.bLastRenderingEnabled == bEnabled then return true, nil end
	if os.clock() < (_Performance.RenderingRetryAt or 0) then return false, "等待 3D 渲染切換重試" end
	local bOk, Reason = _Performance.SetRendering(bEnabled)
	if bOk then
		Controller.bRenderingEnabled = bEnabled
		_Performance.RenderingRetryAt = nil
		if _Performance.RenderingLabel then
			_Performance.RenderingLabel:Set("3D 渲染狀態", if bAutoFishing then "自動釣魚中，持續關閉 3D 渲染"
				elseif bInteraction then "釣魚已停止，互動或載入中，已開啟 3D 渲染"
				else if bEnabled then "3D 渲染已開啟" else "依設定關閉 3D 渲染")
		end
	else _Performance.RenderingRetryAt = os.clock() + 3 end
	return bOk, Reason
end

--[[
	只在已決定執行互動時記錄渲染需求；連續釣魚仍優先保持關閉，不強制打斷。
	@param Key 實際執行互動的排程功能鍵。
]]
function _Performance.BeginInteraction(Key: string): ()
	_Performance.RenderingJobs = _Performance.RenderingJobs or {}
	_Performance.RenderingJobs[Key] = true
	local bOk, Reason = _Performance.SyncRendering()
	assert(bOk, "無法準備 3D 渲染：" .. tostring(Reason))
end

--[[
	只記錄已通過條件的操作需求；背景購買／領獎不強制開啟正在釣魚的 3D。
	保留權歸屬目前的排程工作，沿用其完成、取消及逾時清理，不建立額外計時工作。
	@param Name 已確認將送出的原生 RemoteFunction 名稱。
]]
function _Performance.BeginRequest(Name: string): ()
	if not (Name:match("Purchase$") or Name:find("Claim", 1, true) or Name == "PotionUse" or Name == "ResearchStart"
		or Name == "CaseOpenRequest" or Name == "BackpackSellSelectedRequest" or Name == "BackpackSellRarityRequest"
		or Name == "NpcQuestDeposit" or Name == "FinalizeWelcomeOffline") then return end
	local Current = coroutine.running()
	for Key, Job in _Runtime.Jobs do
		if Job == Current and Key ~= "Scheduler" then _Performance.BeginInteraction(Key) return end
	end
end

--[[
	釋放完成、失敗、取消或逾時工作的渲染保留；其他工作尚未結束時仍保持開啟。
	@param Key 排程功能鍵。
]]
function _Performance.EndInteraction(Key: string): ()
	if _Performance.RenderingJobs then _Performance.RenderingJobs[Key] = nil end
	_Performance.SyncRendering()
end

--[[ 卸載時還原本開關仍持有的渲染狀態；不改寫使用者保存的開關選項。 ]]
function _Performance.RestoreRendering(): ()
	_Performance.RenderingJobs, _Performance.RenderingRetryAt = nil, nil
	if not _Performance.bRenderingTouched then return end
	--[[ 還原時讀取與設定可能被執行器拒絕，單項失敗不阻止其餘卸載。 ]]
	pcall(function()
		--[[ @return 可用時回傳目前渲染狀態，否則沿用既有引擎的還原行為。 ]]
		local bRead, Current = pcall(function() return _Performance.RunService:Is3dRenderingEnabled() end)
		if not bRead or Current == _Performance.bLastRenderingEnabled then
			_Performance.RunService:Set3dRenderingEnabled(_Performance.bOriginalRenderingEnabled)
		end
	end)
	_Performance.bRenderingTouched = false
end

--[[
	載入共用效能引擎的相容安全模式；保留遊戲 UI 與所有 Instance，3D 依目前工作與閒置選項決定。
	下載失敗至少等待 30 秒重試，部分初始化失敗會釋放引擎資源。
]]
function _Performance.Start(): ()
	if _Performance.Engine then return end
	if not _Performance.Module then
		assert(os.clock() >= _Performance.NextLoadAt, _Performance.Error or "等待效能引擎重試")
		_Performance.NextLoadAt = os.clock() + 30
		--[[ @return 遠端原始碼回傳的效能引擎模組；錯誤由外層回報。 ]]
		local bOk, Result = pcall(function()
			return loadstring(game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/PerformanceEngine.luau"))()
		end)
		if not _Runtime.bAlive or not Controller.bLowEffects then return end
		if not bOk then _Performance.Error = "效能引擎載入失敗：" .. tostring(Result) error(_Performance.Error) end
		if type(Result) ~= "table" or type(Result.new) ~= "function" or (tonumber(Result.SafeModeVersion) or 0) < 1 then
			_Performance.Error = "請同步更新 PerformanceEngine.luau（需支援保留遊戲 UI 與可還原模式）"
			error(_Performance.Error)
		end
		_Performance.Module, _Performance.Error = Result, nil
	end
	if not _Runtime.bAlive or not Controller.bLowEffects then return end
	_Performance.CaptureRendering()
	local Engine = _Performance.Module.new({ GetHui = gethui, ProtectedRoots = { _Runtime.Window.ScreenGui },
		bRenderingEnabled = Controller.bRenderingEnabled, bPreserveUi = true, bDeleteVisuals = false,
		bDeleteCoreGui = false, bDeleteGetHui = false })
	_Performance.Engine = Engine
	local bOk, Reason = pcall(Engine.Start)
	if not bOk then Engine.Destroy() _Performance.Engine = nil error(Reason) end
end

--[[
	只還原自己停用且仍存在的自動重連腳本；原本關閉的腳本不會被啟動。
]]
function _Rejoin.Restore(): ()
	for Script, bOriginalEnabled in _Rejoin.Scripts do
		--[[ 腳本可能已由遊戲移除，單項還原失敗不妨礙其餘清理。 ]]
		pcall(function()
			if Script.Parent and Script.Enabled == false then Script.Enabled = bOriginalEnabled end
		end)
	end
	table.clear(_Rejoin.Scripts)
end

--[[
	停用快照中的 PlayerScripts.Player.AutoRejoinClient，涵蓋其 Idled 回呼及 15 秒輪詢。
	保留 AntiIdleClient 與其他腳本，不攔截傳送、轉生或任何 Remote。
]]
function _Rejoin.Step(): ()
	local Scripts = LocalPlayer:FindFirstChild("PlayerScripts")
	local Folder = Scripts and Scripts:FindFirstChild("Player")
	local Script = Folder and Folder:FindFirstChild("AutoRejoinClient")
	if not Script or not Script:IsA("LocalScript") then
		_Status("bPreventAutoRejoin", "等待遊戲的 AutoRejoinClient 載入") return
	end
	if Script.Enabled then
		if _Rejoin.Scripts[Script] == nil then _Rejoin.Scripts[Script] = true end
		Script.Enabled = false
	end
	assert(Script.Enabled == false, "執行器無法停用 AutoRejoinClient")
	_Status("bPreventAutoRejoin", "已停用遊戲閒置重連；保留原生防閒置功能")
end

-- UI_EFFECTS_START
--[[
	辨識快照確認的流星背景宿主，宿主本身的購買按鈕與內容不刪除。
	@param Host 動態粒子或 StarHandler 的宿主。
	@return true 表示已確認的純背景效果範圍。
]]
function _UiEffects.IsStarHost(Host): boolean
	local Main = _UiEffects.Root and _UiEffects.Root:FindFirstChild("MainGui")
	if not Main or not Host or not Host:IsA("GuiObject") then return false end
	if Host.Parent == Main and (Host.Name == "IntroGUI" or Host.Name == "TeleportingGUI") then return true end
	local Scroll, Section = Host.Parent, Host.Parent and Host.Parent.Parent
	return Section ~= nil and Section.Parent == Main and _UiEffects.StarSections[Section.Name] == Scroll.Name
		and Host.Name:match("^Offer") ~= nil
end

--[[
	用完整相對路徑、類別與宿主辨識裝飾；不依特效關鍵字刪除其他 UI。
	@param Object 候選物件。
	@return 已確認的效果類別；nil 表示保留。
]]
function _UiEffects.Classify(Object): string?
	local Root = _UiEffects.Root
	if not Root or not Object.Parent or not Object:IsDescendantOf(Root) then return nil end
	local Panel = _Runtime.Window and _Runtime.Window.ScreenGui
	if Panel and (Object == Panel or Object:IsDescendantOf(Panel)) then return nil end
	if Object:IsA("LocalScript") then
		if Object.Name == "StarHandler" and _UiEffects.IsStarHost(Object.Parent) then return "StarScript" end
		if Object.Name ~= "StatCollectFX" and Object.Name ~= "RotationSpinSizeFXHandler" and Object.Name ~= "SizeFXHandler" then return nil end
		local Parts, Current = {}, Object
		while Current and Current ~= Root do table.insert(Parts, 1, Current.Name) Current = Current.Parent end
		return _UiEffects.Scripts[table.concat(Parts, "/")]
	end
	local Main = Root:FindFirstChild("MainGui")
	local Stats = Main and Main:FindFirstChild("Stats")
	if Object.Name == "CollectFX" and Object:IsA("ImageLabel") and Object.Parent == Stats then return "CollectParticle" end
	local Folder = Object.Parent
	if Folder:IsA("Folder") and Folder.Name == "ShootingStarsFX" and _UiEffects.IsStarHost(Folder.Parent)
		and Object.ClassName == _UiEffects.ParticleClasses[Object.Name] then return "StarParticle" end
	return nil
end

--[[
	刪除已確認的純裝飾物件；先停止流星註冊，避免共享控制器持續產生粒子。
	@param Object 初掃或新增事件取得的候選。
]]
function _UiEffects.Process(Object): ()
	if not _Runtime.bAlive or not Controller.bDeleteUiEffects then return end
	local Kind = _UiEffects.Classify(Object)
	if not Kind then return end
	if Kind == "StarScript" then
		if not _UiEffects.StarController then
			local Modules = ReplicatedStorage:FindFirstChild("Modules")
			local Module = Modules and Modules:FindFirstChild("SharedStarFxController")
			assert(Module and Module:IsA("ModuleScript"), "等待 SharedStarFxController，保留尚未停止的背景效果")
			_UiEffects.StarController = require(Module)
		end
		assert(type(_UiEffects.StarController) == "table" and type(_UiEffects.StarController.Stop) == "function", "背景效果 Stop API 已改變，保留該效果")
		if not _Runtime.bAlive or not Controller.bDeleteUiEffects or _UiEffects.Classify(Object) ~= Kind then return end
		_UiEffects.StarController.Stop(Object)
	end
	if Object:IsA("LocalScript") then Object.Enabled = false end
	Object:Destroy()
	_UiEffects.Retry[Object] = nil
	_UiEffects.Deleted += 1
end

--[[ 更新累計刪除數與原生介面保留狀態。 ]]
function _UiEffects.Report(): ()
	local Failed = 0
	for Object in _UiEffects.Retry do if Object.Parent then Failed += 1 else _UiEffects.Retry[Object] = nil end end
	_Status("bDeleteUiEffects", string.format("已永久刪除 %d 個裝飾物件；保留按鈕、數值、提示與釣魚 UI%s", _UiEffects.Deleted,
		if Failed > 0 then "；待重試 " .. Failed .. " 個：" .. tostring(_UiEffects.LastError) else ""))
end

--[[
	合併新增事件為一個延後工作；避免在 DescendantAdded 派送時同步刪除。
	@param Object 新增物件。
]]
function _UiEffects.Enqueue(Object): ()
	if not _Runtime.bAlive or not Controller.bDeleteUiEffects then return end
	if not _UiEffects.Names[Object.Name] and not _UiEffects.ParticleClasses[Object.Name] then return end
	_UiEffects.Queue[Object] = true
	if _UiEffects.Job then return end
	local Generation = _UiEffects.Generation
	--[[ 分批清理新增物件；關閉、換 PlayerGui 或卸載後不繼續刪除。 ]]
	_UiEffects.Job = task.defer(function()
		local Count = 0
		while _Runtime.bAlive and Controller.bDeleteUiEffects and Generation == _UiEffects.Generation do
			local Object = next(_UiEffects.Queue)
			if not Object then break end
			_UiEffects.Queue[Object] = nil
			local bOk, Reason = pcall(_UiEffects.Process, Object)
			if not bOk then _UiEffects.Retry[Object], _UiEffects.LastError = true, tostring(Reason) end
			Count += 1
			if Count % 200 == 0 then task.wait() end
		end
		if Generation == _UiEffects.Generation then _UiEffects.Job = nil _UiEffects.Report() end
	end)
end

--[[ 停止監聽及排程，不重建已永久刪除的遊戲裝飾。 ]]
function _UiEffects.Stop(): ()
	_UiEffects.Generation += 1
	if _UiEffects.Connection then _UiEffects.Connection:Disconnect() _UiEffects.Connection = nil end
	if _UiEffects.Job then pcall(task.cancel, _UiEffects.Job) _UiEffects.Job = nil end
	_UiEffects.Root, _UiEffects.bScanned = nil, false
	table.clear(_UiEffects.Queue)
	table.clear(_UiEffects.Retry)
end

--[[ 首次掃描玩家 UI，之後只處理新增與失敗項目；PlayerGui 替換時重新綁定。 ]]
function _UiEffects.Step(): ()
	local Root = LocalPlayer:FindFirstChild("PlayerGui")
	if not Root then _UiEffects.Stop() _Status("bDeleteUiEffects", "等待 PlayerGui 載入") return end
	if _UiEffects.Root ~= Root then
		_UiEffects.Stop()
		_UiEffects.Root = Root
		_UiEffects.Connection = Root.DescendantAdded:Connect(_UiEffects.Enqueue)
	end
	if not _UiEffects.bScanned then
		for Index, Object in Root:GetDescendants() do
			if not _Runtime.bAlive or not Controller.bDeleteUiEffects then return end
			_UiEffects.Enqueue(Object)
			if Index % 250 == 0 then task.wait() end
		end
		_UiEffects.bScanned = true
	end
	for Object in _UiEffects.Retry do _UiEffects.Enqueue(Object) end
	_UiEffects.Report()
end
-- UI_EFFECTS_END

-- CLIENT_UI_GUARDS_START
--[[
	隱藏內建暫停通知並嘗試解除串流完整性暫停；仍暫停時要求載入玩家附近場景。
	保留原值供關閉與卸載還原，權限不足時明確區分隱藏通知與解除暫停的結果。
]]
function _ClientUi.PauseStep(): ()
	local Gui = _ClientUi.Gui or game:GetService("GuiService")
	_ClientUi.Gui = Gui
	local Errors = {}
	--[[ 保存並停用原生通知，讀寫失敗不阻止獨立的串流處理。 ]]
	local bUi, UiError = pcall(function()
		local Current = Gui:GetGameplayPausedNotificationEnabled()
		assert(type(Current) == "boolean", "無法讀取原始通知狀態")
		Gui:SetGameplayPausedNotificationEnabled(false)
		if not _ClientUi.bNotificationTouched then _ClientUi.OriginalNotification = Current end
		_ClientUi.bNotificationTouched = true
	end)
	if not bUi then table.insert(Errors, "通知：" .. tostring(UiError)) end
	--[[ 只修改完整性暫停模式，不修改唯讀 GameplayPaused 或停用場景串流。 ]]
	local bMode, ModeError = pcall(function()
		local Current = workspace.StreamingIntegrityMode
		workspace.StreamingIntegrityMode = Enum.StreamingIntegrityMode.Disabled
		assert(workspace.StreamingIntegrityMode == Enum.StreamingIntegrityMode.Disabled, "模式未生效")
		if not _ClientUi.bModeTouched then _ClientUi.OriginalMode = Current end
		_ClientUi.bModeTouched = true
	end)
	if not bMode then table.insert(Errors, "串流暫停模式：" .. tostring(ModeError)) end
	--[[ 請求目前角色附近的資料，避免只隱藏通知而留下未載入區域。 ]]
	local bStream, StreamError = pcall(function()
		if LocalPlayer.GameplayPaused then
			local Character = LocalPlayer.Character
			local Root = Character and Character:FindFirstChild("HumanoidRootPart")
			if Root and Root:IsA("BasePart") then
				_Performance.BeginInteraction("bSuppressGameplayPause")
				LocalPlayer:RequestStreamAroundAsync(Root.Position, 3)
			end
		end
	end)
	if not bStream then table.insert(Errors, "載入附近場景：" .. tostring(StreamError)) end
	if not _Runtime.bAlive or not Controller.bSuppressGameplayPause then return end
	_Status("bSuppressGameplayPause", (if bUi then "已隱藏 Gameplay Paused 通知" else "未隱藏暫停通知")
		.. (if bMode then "；已停用串流完整性暫停" else "；解除暫停未確認")
		.. (if #Errors > 0 then "\n" .. table.concat(Errors, "\n") else ""))
end

--[[ 關閉保護後只還原仍等於自己套用值的通知及串流模式。 ]]
function _ClientUi.RestorePause(): ()
	--[[ 單項還原失敗不阻止其餘卸載。 ]]
	pcall(function()
		if _ClientUi.bNotificationTouched and _ClientUi.Gui:GetGameplayPausedNotificationEnabled() == false then
			_ClientUi.Gui:SetGameplayPausedNotificationEnabled(_ClientUi.OriginalNotification)
		end
	end)
	--[[ 保留其他腳本後來設定的不同模式。 ]]
	pcall(function()
		if _ClientUi.bModeTouched and workspace.StreamingIntegrityMode == Enum.StreamingIntegrityMode.Disabled then
			workspace.StreamingIntegrityMode = _ClientUi.OriginalMode
		end
	end)
	_ClientUi.OriginalNotification, _ClientUi.OriginalMode = nil, nil
	_ClientUi.bNotificationTouched, _ClientUi.bModeTouched = false, false
end

--[[
	攔截快照確認的平台彈窗方法，其他查詢、Remote 與遊戲 UI 原樣放行。
	只接管用戶端 namecall，不刪除 CoreGui，也不假裝已購買或已加入社群。
]]
function _ClientUi.PromptStep(): ()
	if not _ClientUi.Bus then
		local Hook = Environment.hookmetamethod or hookmetamethod
		local Method = Environment.getnamecallmethod or getnamecallmethod
		local Closure = Environment.newcclosure or newcclosure
		assert(type(Hook) == "function" and type(Method) == "function" and type(Closure) == "function",
			"缺少 hookmetamethod／getnamecallmethod／newcclosure，平台彈窗阻擋未啟用")
		_ClientUi.Services = {}
		for Name, Rules in {
			MarketplaceService = { PromptProductPurchase = "Void", PromptGamePassPurchase = "Void", PromptPurchase = "Void" },
			GroupService = { PromptJoinAsync = "Group" },
			SocialService = { PromptRsvpToEventAsync = "Rsvp", PromptGameInvite = "Void" },
			ExperienceNotificationService = { PromptOptIn = "Void" },
		} do
			local Service = game:GetService(Name)
			_ClientUi.Services[Service] = Rules
		end
		local Bus = Environment.__FishPlatformPromptsV1
		if type(Bus) ~= "table" or not Bus.bReady then
			Bus = { bReady = false, Method = Method, Install = Hook }
			--[[
				分派給當前控制器；失去擁有者時為不改行為的原始呼叫轉送。
				@param Self 實際接收方法的服務物件。
				@param ... 原始參數，未攔截時完整轉送。
				@return 原始方法回傳值，或原生取消對應的結果。
			]]
			Bus.Hook = Closure(function(Self, ...)
				local Owner = Bus.Owner
				if Owner and Owner.Runtime.bAlive and Owner.Controller.bBlockPlatformPrompts then
					local Rules = Owner.Services[Self]
					local Result = Rules and Rules[Bus.Method()]
					if Result then
						Owner.Blocked += 1
						if Result == "Group" then return Enum.GroupMembershipStatus.None end
						if Result == "Rsvp" then return Enum.RsvpStatus.None end
						return
					end
				end
				return Bus.Original(Self, ...)
			end)
			local bOk, Original = pcall(Hook, game, "__namecall", Bus.Hook)
			assert(bOk and type(Original) == "function", "彈窗攔截安裝失敗：" .. tostring(Original))
			Bus.Original, Bus.bReady = Original, true
			Environment.__FishPlatformPromptsV1 = Bus
		end
		_ClientUi.Runtime, _ClientUi.Controller = _Runtime, Controller
		_ClientUi.Bus, Bus.Owner = Bus, _ClientUi
	end
	_Status("bBlockPlatformPrompts", "已阻擋遊戲發起的 Robux 購買、加入社群、活動／通知與邀請彈窗；累計 " .. _ClientUi.Blocked .. " 次")
end

--[[ 解除攔截擁有權；只在確認仍持有最外層 hook 時還原，否則保留單一停用分派器供重跑重用。 ]]
function _ClientUi.StopPrompts(): ()
	local Bus = _ClientUi.Bus
	if not Bus or Bus.Owner ~= _ClientUi then return end
	Bus.Owner, _ClientUi.Bus = nil, nil
	local Raw = Environment.getrawmetatable or getrawmetatable
	if type(Raw) ~= "function" then return end
	--[[ 其他 wrapper 可能已覆蓋最外層，不得以舊方法蓋掉它。 ]]
	pcall(function()
		local Meta = Raw(game)
		if Meta and Meta.__namecall == Bus.Hook then
			Bus.Install(game, "__namecall", Bus.Original)
			Bus.bReady = false
			if Environment.__FishPlatformPromptsV1 == Bus then Environment.__FishPlatformPromptsV1 = nil end
		end
	end)
end
-- CLIENT_UI_GUARDS_END

-- TUTORIAL_SKIP_START
--[[
	沿用原生 Activated 回呼；Defer 無可觀察進展時，重試以獨立工作執行原生 Function。
	原生結束回呼一旦開始便交還遊戲完成，關閉功能只取消尚未派送的回呼。
	@param Button 快照確認的跳過教學或其專用確認按鈕。
	@return true 代表已嘗試觸發，不代表教學已完成。
	@return 未觸發時的具體原因；成功為 nil。
]]
function _Tutorial.Activate(Button): (boolean, string?)
	if not _Runtime.bAlive or not Controller.bAutoSkipTutorial then return false, "功能已停止" end
	if not Button or not Button:IsA("GuiButton") then return false, "等待原生教學按鈕" end
	local Object = Button
	while Object do
		if (Object:IsA("GuiObject") and not Object.Visible) or (Object:IsA("ScreenGui") and not Object.Enabled) then
			return false, "等待原生教學按鈕可見"
		end
		Object = Object.Parent
	end
	_Tutorial.Attempts = _Tutorial.Attempts or setmetatable({}, { __mode = "k" })
	_Tutorial.LastDispatch = _Tutorial.LastDispatch or setmetatable({}, { __mode = "k" })
	_Tutorial.Pending = _Tutorial.Pending or {}
	if os.clock() - (_Tutorial.LastDispatch[Button] or -math.huge) < 0.5 then return false, "等待原生按鈕回呼" end
	_Tutorial.LastDispatch[Button] = os.clock()
	_Tutorial.Attempts[Button] = (_Tutorial.Attempts[Button] or 0) + 1
	local LastError
	if type(getconnections) == "function" then
		local bRead, Connections = pcall(getconnections, Button.Activated)
		if bRead and type(Connections) == "table" then
			local bAttempted = false
			for _, Connection in Connections do
				if Connection.Enabled ~= false and Connection.LuaConnection ~= false and Connection.ForeignState ~= true
					and type(Connection.Function) == "function" then
					_Performance.BeginInteraction("bAutoSkipTutorial")
					local bOk, Reason
					if type(Connection.Defer) == "function" and _Tutorial.Attempts[Button] == 1 then
						bOk, Reason = pcall(Connection.Defer, Connection)
					else
						local Callback, Record = Connection.Function, {}
						_Tutorial.Pending[Record] = true
						--[[ 延後執行原生教學回呼；已開始的結束流程不隨功能工作取消。 ]]
						Record.Job = task.defer(function()
							if not _Runtime.bAlive or not Controller.bAutoSkipTutorial or not Button.Parent then _Tutorial.Pending[Record] = nil return end
							Record.bStarted = true
							local bNative, NativeError = pcall(Callback)
							if not bNative then _Tutorial.NativeError = tostring(NativeError) end
							_Tutorial.Pending[Record] = nil
						end)
						bOk = true
					end
					if bOk then bAttempted = true else LastError = tostring(Reason) end
				end
			end
			if bAttempted then return true end
		else LastError = tostring(Connections) end
	end
	if type(firesignal) == "function" then
		_Performance.BeginInteraction("bAutoSkipTutorial")
		local bOk, Reason = pcall(firesignal, Button.Activated)
		if bOk then return true end
		LastError = tostring(Reason)
	end
	return false, LastError or "缺少可用的 getconnections／firesignal，無法觸發教學按鈕"
end

--[[ 取消尚未執行的教學回呼，保留已開始且負責相機／UI 還原的原生流程。 ]]
function _Tutorial.Stop(): ()
	for Record in _Tutorial.Pending or {} do
		if not Record.bStarted then
			if Record.Job then pcall(task.cancel, Record.Job) end
			_Tutorial.Pending[Record] = nil
		end
	end
	_Tutorial.State, _Tutorial.NextStateAt, _Tutorial.WaitUntil, _Tutorial.Attempts = nil, 0, 0, nil
	_Tutorial.LastDispatch = nil
end

--[[
	按原生 SkipTutorial → Skip Tutorial?／Yes 流程跳過教學，保留結束動畫與相機／介面還原。
	只接受伺服器 completed 或玩家 TutorialCompleted 的完成確認，不直接呼叫完成 Remote。
]]
function _Tutorial.Step(): ()
	local Key = "bAutoSkipTutorial"
	if not _Runtime.bAlive or not Controller[Key] then return end
	if LocalPlayer:GetAttribute("TutorialCompleted") == true then _Status(Key, "教學已完成，無需跳過") return end
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local Main = PlayerGui and PlayerGui:FindFirstChild("MainGui")
	if not Main then _Status(Key, "等待教學介面載入") return end
	local Confirmation = Main:FindFirstChild("ConfirmationGUI")
	local UI = Confirmation and Confirmation:FindFirstChild("UI")
	local Title = UI and UI:FindFirstChild("Title0")
	local bOpen = Confirmation and Confirmation:IsA("GuiObject") and Confirmation.Visible and UI and (not UI:IsA("GuiObject") or UI.Visible)
	local bSkipDialog = bOpen and Title and Title:IsA("TextLabel") and Title.Text == "Skip Tutorial?"
	if os.clock() < _Tutorial.WaitUntil and not bSkipDialog then _Status(Key, "已確認跳過，等待遊戲完成教學結束流程") return end
	if bOpen then
		if not Title or not Title:IsA("TextLabel") or Title.Text ~= "Skip Tutorial?" then
			_Status(Key, "等待其他確認視窗關閉") return
		end
		local bOk, Reason = _Tutorial.Activate(UI:FindFirstChild("Yes"))
		if bOk then _Tutorial.WaitUntil, _Tutorial.NextStateAt = os.clock() + 10, 0 end
		_Status(Key, if bOk then "已嘗試確認跳過，等待原生教學結束" else tostring(Reason))
		return
	end
	local Buttons = Main:FindFirstChild("Buttons")
	local Skip = Buttons and Buttons:FindFirstChild("SkipTutorial")
	if Skip and Skip:IsA("GuiButton") then
		local bOk, Reason = _Tutorial.Activate(Skip)
		_Status(Key, (if bOk then "已嘗試原生跳過；未開啟確認框時下輪改用原生回呼" else tostring(Reason))
			.. (if _Tutorial.NativeError then "；" .. _Tutorial.NativeError else ""))
		return
	end
	if not _Tutorial.State or os.clock() >= _Tutorial.NextStateAt then
		local Remote = Remotes:FindFirstChild("GetTutorialState")
		assert(Remote and Remote:IsA("RemoteFunction"), "等待 GetTutorialState 載入")
		local State = Remote:InvokeServer()
		if not _Runtime.bAlive or not Controller[Key] then return end
		assert(type(State) == "table", "教學狀態格式已改變")
		_Tutorial.State, _Tutorial.NextStateAt = State, os.clock() + 15
	end
	_Status(Key, if _Tutorial.State.completed == true then "教學已完成，無需跳過"
		elseif _Tutorial.State.ready ~= true then "等待教學資料就緒" else "等待原生跳過按鈕載入")
end
-- TUTORIAL_SKIP_END

--[[
	處理後續串流或遊戲新建的視覺特效；單一物件失敗不阻斷其他自動功能。
	@param Object Workspace 新增的後代物件。
]]
local function _OnEffectAdded(Object: Instance): ()
	if not _Runtime.bAlive or not Controller.bLowEffects then return end
	local bOk, Reason = pcall(_SuppressEffect, Object)
	if not bOk then _Status("bLowEffects", "特效處理失敗：" .. tostring(Reason)) end
end

--[[
	首次分批掃描 Workspace，後續只追蹤已知及新增特效，依設定間隔清除殘留粒子。
	不銷毀 Instance，不變更地形、碰撞、腳本、角色或遊戲互動物件。
	使用範例：
	```lua
	-- 在自動功能頁開啟「效能模式（低特效）」。
	-- 關閉或卸載會還原 Enabled；已清除的歷史粒子不重新生成。
	```
]]
local function _LowEffects(): ()
	if not _Runtime.EffectsConnection then
		_Runtime.EffectsConnection = workspace.DescendantAdded:Connect(_OnEffectAdded)
	end
	if not _Runtime.bEffectsScanned then
		for Index, Object in workspace:GetDescendants() do
			if not Controller.bLowEffects or not _Runtime.bAlive then return end
			if EFFECT_CLASSES[Object.ClassName] then _OnEffectAdded(Object) end
			if Index % 250 == 0 then task.wait() end
		end
		_Runtime.bEffectsScanned = true
	end
	local Count, Failed = 0, 0
	for Object, Record in _Runtime.Effects do
		if Object:IsDescendantOf(workspace) then
			local bOk = pcall(_SuppressEffect, Object)
			if bOk then Count += 1 else Failed += 1 end
		else
			pcall(_RestoreEffect, Object, Record)
			_Runtime.Effects[Object] = nil
		end
	end
	_Performance.Start()
	_Status("bLowEffects", "共用效能引擎已啟用；已處理 " .. Count .. " 個視覺特效；保留遊戲 UI 與互動物件，3D 依獨立開關設定" .. (if Failed > 0 then "；失敗 " .. Failed .. " 個" else ""))
end

--[[
	取得已確認名稱與類別的 Remote，找不到時拋出具體錯誤。
	@param Name 原始協定的 Remote 名稱。
	@param ClassName 預期類別。
	@return 符合類別的 Remote。
]]
local function _Remote(Name: string, ClassName: string): Instance
	assert(_Runtime.bAlive, "腳本已卸載")
	local Remote = Remotes:FindFirstChild(Name)
	assert(Remote and Remote:IsA(ClassName), "缺少 " .. ClassName .. "：" .. Name)
	return Remote
end

--[[
	呼叫遊戲 RemoteFunction；會 yield，錯誤交由工作邊界處理。
	@param Name 快照中已確認的名稱。
	@param ... 遊戲指定的參數。
	@return 伺服器原始回傳值，可能有多個值。
]]
local function _Invoke(Name: string, ...)
	local Remote = _Remote(Name, "RemoteFunction")
	_Performance.BeginRequest(Name)
	return Remote:InvokeServer(...)
end

--[[
	定位原生 Auto Fish 按鈕及狀態漸層，僅讀取遊戲 UI，不自行改寫啟用狀態。
	@return 已確認的 GuiButton；未載入時為 nil。
	@return 原生 Enabled UIGradient；未載入時為 nil。
	@return 原生 Disabled UIGradient；未載入時為 nil。
]]
local function _NativeAutoFishUi()
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local MainGui = PlayerGui and PlayerGui:FindFirstChild("MainGui")
	local Action = MainGui and MainGui:FindFirstChild("FishAction")
	local Button = Action and Action:FindFirstChild("AutoFish")
	local On, Off = Button and Button:FindFirstChild("Enabled"), Button and Button:FindFirstChild("Disabled")
	if not Button or not Button:IsA("GuiButton") or not On or not On:IsA("UIGradient") or not Off or not Off:IsA("UIGradient") then return nil end
	return Button, On, Off
end

--[[
	沿用原生 owned UI 的可選購買按鈕判斷；場景快照中兩個子按鈕均不存在，不能列為必要物件。
	@param Button 已定位的原生 Auto Fish 按鈕。
	@return true 已解鎖且沒有顯示中的原生購買按鈕；false 等待解鎖或介面同步。
]]
local function _IsNativeAutoFishReady(Button: GuiButton): boolean
	if LocalPlayer:GetAttribute("AutoFishOwned") ~= true then return false end
	for _, Name in { "Purchase", "Robux" } do
		local Purchase = Button:FindFirstChild(Name)
		if Purchase and Purchase:IsA("GuiButton") and Purchase.Visible then return false end
	end
	return true
end

--[[
	顯示內建 Auto Fish 狀態，與拋竿／釣獲狀態分開，避免缺少能力時被其他訊息覆蓋。
	@param Message 解鎖、等待或啟用狀態。
]]
local function _NativeAutoFishStatus(Message: string): ()
	if _Runtime.NativeAutoFishLabel then _Runtime.NativeAutoFishLabel:Set("內建 Auto Fish：" .. Message) end
end

--[[
	只關閉本腳本原先從關閉狀態打開的原生 Auto Fish，既有開啟狀態與重建 UI 不覆蓋。
]]
local function _RestoreNativeAutoFish(): ()
	local Record = _Runtime.NativeAutoFishRecord
	_Runtime.NativeAutoFishRecord = nil
	if not Record or type(firesignal) ~= "function" or LocalPlayer:GetAttribute("AutoFishOwned") ~= true then return end
	local Button, On, Off = _NativeAutoFishUi()
	if Button ~= Record.Button then return end
	if _IsNativeAutoFishReady(Button) and On.Enabled and not Off.Enabled then
		local bOk, Reason = pcall(firesignal, Button.MouseButton1Click)
		if not bOk then _NativeAutoFishStatus("關閉失敗：" .. tostring(Reason))
		elseif not On.Enabled and Off.Enabled then _NativeAutoFishStatus("已還原關閉") end
	end
end

--[[
	自動釣魚期間觸發原生 Auto Fish，確認解鎖及 UI 狀態後才點擊。
	@return true 已觀察原生開啟，可交由遊戲點擊；false 沿用腳本點擊或等待 UI。
]]
local function _EnableNativeAutoFish(): boolean
	if not Controller.bAutoFish or not _Runtime.bAlive then return false end
	local Owned = LocalPlayer:GetAttribute("AutoFishOwned")
	if Owned ~= true then
		_NativeAutoFishStatus(if Owned == false then "尚未解鎖，繼續腳本自動釣魚" else "等待解鎖狀態載入，繼續腳本自動釣魚")
		return false
	end
	local Button, On, Off = _NativeAutoFishUi()
	if not Button then _NativeAutoFishStatus("等待遊戲按鈕載入") return false end
	if On.Enabled and not Off.Enabled then _NativeAutoFishStatus("已開啟") return true end
	if not _IsNativeAutoFishReady(Button) or On.Enabled or not Off.Enabled then
		_NativeAutoFishStatus("等待原生解鎖介面同步") return false
	end
	if type(firesignal) ~= "function" then _NativeAutoFishStatus("缺少 firesignal，繼續腳本自動點擊") return false end
	_Runtime.NativeAutoFishRecord = { Button = Button }
	local bOk, Reason = pcall(firesignal, Button.MouseButton1Click)
	if On.Enabled and not Off.Enabled then _NativeAutoFishStatus("已開啟") return true end
	_NativeAutoFishStatus(if bOk then "已請求開啟，等待原生介面確認" else "按鈕觸發失敗：" .. tostring(Reason))
	return false
end

--[[
	判斷原生揭曉動畫是否仍鎖住釣魚／背包，避免提早拋竿或傳送打斷獎勵動畫。
	@return true 正在揭曉；false 可依釣魚回合狀態繼續。
]]
local function _IsCatchLocked(): boolean
	return _Runtime.FishPhase == "Reveal" or (_Runtime.FishPhase == "Idle"
		and (LocalPlayer:GetAttribute("BPCatchLock") == true or (type(_G) == "table" and _G.__FishingCatchUiLocked == true)))
end

--[[
	返回岸邊且揭曉已結束後恢復暫停的原生開關；卸載時只恢復玩家原本開啟的狀態。
	若原生自行拋竿，留兩秒接收 Started，避免腳本同時重拋。未能啟用時由釣魚維持流程後續重試。
]]
local function _ResumeNativeAutoFish(): ()
	local Resume = _Runtime.ResumeNativeAutoFish
	if not Resume or _Runtime.bMoving or _IsCatchLocked() then return end
	_Runtime.ResumeNativeAutoFish = nil
	if (not _Runtime.bAlive and _Runtime.NativeAutoFishRecord) or type(firesignal) ~= "function"
		or LocalPlayer:GetAttribute("AutoFishOwned") ~= true then return end
	local Button, On, Off = _NativeAutoFishUi()
	if Button == Resume.Button and not On.Enabled and Off.Enabled and _IsNativeAutoFishReady(Button) then
		local bOk, Reason = pcall(firesignal, Button.MouseButton1Click)
		if On.Enabled then
			_Runtime.NextCastAt = os.clock() + 2
			_NativeAutoFishStatus("已恢復開啟")
		elseif not bOk then _NativeAutoFishStatus("恢復失敗：" .. tostring(Reason))
		else _NativeAutoFishStatus("恢復尚未確認，等待下一輪") end
	end
end

--[[
	自動釣魚的回合中持續確認原生 Auto Fish，每半秒最多嘗試一次，不受拋竿／點擊間隔影響。
	尚未開始回合、位移與特殊揭曉時暫停，避免重拋或干擾動畫。
]]
local function _MaintainNativeAutoFish(): ()
	if not Controller.bAutoFish or not _Runtime.bAlive or _Runtime.bMoving or _IsCatchLocked()
		or (_Runtime.FishPhase ~= "Waiting" and _Runtime.FishPhase ~= "Hooked") then return end
	if os.clock() < _Runtime.NextNativeAutoFishAt then return end
	_Runtime.NextNativeAutoFishAt = os.clock() + 0.5
	_ResumeNativeAutoFish()
	_EnableNativeAutoFish()
end

--[[
	在查詢返回後再次確認領獎開關，避免等待期間停用仍送出領取。
	@param Key 領獎功能欄位。
	@return true 可繼續領取；false 已停用或卸載。
]]
local function _CanClaimReward(Key: string): boolean
	return _Runtime.bAlive and Controller[Key] == true
end

--[[
	操作已由遊戲原始碼確認回傳 ok 的領獎介面；成功僅採用伺服器回應。
	@param Key 功能欄位。
	@param Name 原生領獎 RemoteFunction 名稱。
	@param ... 原生領獎參數。
]]
local function _ClaimReward(Key: string, Name: string, ...): ()
	if not _CanClaimReward(Key) then return end
	local Result = _Invoke(Name, ...)
	assert(type(Result) == "table", Name .. " 回應格式已變更")
	_Status(Key, if Result.ok == true then "伺服器已確認領取獎勵" else "未領取：" .. tostring(Result.reason or "伺服器未確認成功"))
end

--[[
	依任務面板的 claimableCount 呼叫原生全部領取，不自動完成任務。
]]
local function _QuestRewards(): ()
	local Key = "bAutoQuestRewards"
	local State = _Invoke("QuestGetState")
	assert(type(State) == "table" and tonumber(State.claimableCount), "QuestGetState 回應格式已變更")
	if tonumber(State.claimableCount) > 0 then _ClaimReward(Key, "QuestClaimAll")
	else _Status(Key, "目前沒有可領取的任務獎勵") end
end

--[[
	比較原生 unlockedKeys 與 claimedKeys，只在有新索引獎勵時全部領取。
]]
local function _IndexRewards(): ()
	local Key = "bAutoIndexRewards"
	local State = _Invoke("IndexGetData")
	assert(type(State) == "table" and type(State.unlockedKeys) == "table" and type(State.claimedKeys) == "table",
		"IndexGetData 回應格式已變更")
	local Claimed = {}
	for _, Id in State.claimedKeys do Claimed[Id] = true end
	for _, Id in State.unlockedKeys do
		if not Claimed[Id] then _ClaimReward(Key, "IndexClaimAllRewards") return end
	end
	_Status(Key, "目前沒有可領取的索引獎勵")
end

--[[
	依每日面板的解鎖天數及位元遮罩，每輪領取一份尚未領取的獎勵。
]]
local function _DailyRewards(): ()
	local Key = "bAutoDailyRewards"
	local State = _Invoke("GetDailyRewardsState")
	assert(type(State) == "table" and tonumber(State.totalDays) and tonumber(State.unlockedDay)
		and tonumber(State.claimedMask), "GetDailyRewardsState 回應格式已變更")
	for Day = 1, math.min(7, tonumber(State.totalDays), tonumber(State.unlockedDay)) do
		if bit32.band(tonumber(State.claimedMask), bit32.lshift(1, Day - 1)) == 0 then
			_ClaimReward(Key, "ClaimDailyReward", Day) return
		end
	end
	_Status(Key, "目前沒有可領取的每日獎勵")
end

--[[
	僅領取伺服器 ready 且未 claimed 的遊玩時間獎勵，不自行推進倒數。
]]
local function _PlaytimeRewards(): ()
	local Key = "bAutoPlaytimeRewards"
	local State = _Invoke("GetPlaytimeRewardsState")
	assert(type(State) == "table" and type(State.rewardStates) == "table" and tonumber(State.totalRewards),
		"GetPlaytimeRewardsState 回應格式已變更")
	for Index = 1, tonumber(State.totalRewards) do
		local Reward = State.rewardStates[Index]
		if type(Reward) == "table" and Reward.ready == true and not Reward.claimed then
			_ClaimReward(Key, "ClaimPlaytimeReward", Index) return
		end
	end
	_Status(Key, "目前沒有可領取的遊玩時間獎勵")
end

--[[
	依信箱原生 Claim All 領取現有郵件；保留 got、owned、failed 與 reason 的原始語意。
]]
local function _InboxRewards(): ()
	local Key = "bAutoInboxRewards"
	local State = _Invoke("InboxGet")
	assert(type(State) == "table", "InboxGet 回應格式已變更")
	if State.ready == false then _Status(Key, "信箱資料尚未載入") return end
	assert(type(State.list) == "table", "InboxGet.list 回應格式已變更")
	if #State.list == 0 then _Status(Key, "目前沒有可領取的信箱獎勵") return end
	if not _CanClaimReward(Key) then return end
	local Result = _Invoke("InboxClaim", "all")
	assert(type(Result) == "table", "InboxClaim 回應格式已變更")
	local Count = if type(Result.got) == "table" then #Result.got else 0
	local Owned = if type(Result.owned) == "table" then #Result.owned else 0
	_Status(Key, "信箱已領取 " .. Count .. " 份；已擁有 " .. Owned .. " 份；失敗 "
		.. tostring(Result.failed or 0) .. (if Result.reason then "；" .. tostring(Result.reason) else ""))
end

--[[
	僅在 Medal 伺服器確認 eligible 時領取；不替玩家進行外部連結或錄影任務。
]]
local function _MedalRewards(): ()
	local Key = "bAutoMedalRewards"
	local State = _Invoke("MedalQuestGet")
	assert(type(State) == "table", "MedalQuestGet 回應格式已變更")
	if State.eligible == true then _ClaimReward(Key, "MedalQuestClaim")
	else _Status(Key, "Medal 獎勵尚未符合領取資格") end
end

--[[
	依 NPC 原生 Tasks／Characters 與伺服器 progress／deposits 判定是否已完成。
	@param Definition NpcQuests 的單筆任務定義。
	@param State NpcQuestGetState 的原始回應。
	@return true 表示免費任務且所有條件已完成；false 表示尚未完成或需付費／進化。
]]
local function _NpcRewardReady(Definition, State): boolean
	if type(State) ~= "table" or State.claimed == true or State.locked == true or Definition.Evolution
		or (tonumber(Definition.GemCost) or 0) > 0 then return false end
	local Progress, Deposits = State.progress or {}, State.deposits or {}
	if type(Progress) ~= "table" or type(Deposits) ~= "table" then return false end
	for _, Task in Definition.Tasks or {} do
		if (tonumber(Progress[tostring(Task.Id or "")]) or 0) < math.max(1, math.floor(tonumber(Task.Goal) or 1)) then return false end
	end
	for _, Need in Definition.Characters or {} do
		if (tonumber(Deposits[Need.Name]) or 0) < math.max(1, math.floor(tonumber(Need.Count) or 1)) then return false end
	end
	return true
end

--[[
	輪詢免費 NPC 與活動任務，每輪最多查詢三個、領取一個；不自動交付角色或付費。
]]
local function _NpcRewards(): ()
	local Key = "bAutoNpcRewards"
	if not _Runtime.NpcQuests then
		local Modules = ReplicatedStorage:FindFirstChild("Modules")
		local Module = Modules and Modules:FindFirstChild("NpcQuests")
		assert(Module and Module:IsA("ModuleScript"), "缺少遊戲 NpcQuests 模組")
		_Runtime.NpcQuests = require(Module)
	end
	local Definitions = _Runtime.NpcQuests.Quests
	assert(type(Definitions) == "table", "NpcQuests.Quests 格式已變更")
	local Ids = {}
	for Id, Definition in Definitions do
		if type(Id) == "string" and type(Definition) == "table" and not Definition.Evolution
			and (tonumber(Definition.GemCost) or 0) == 0 then table.insert(Ids, Id) end
	end
	table.sort(Ids)
	for _ = 1, math.min(3, #Ids) do
		if not _CanClaimReward(Key) then return end
		_Runtime.NpcQuestIndex = _Runtime.NpcQuestIndex % #Ids + 1
		local Id = Ids[_Runtime.NpcQuestIndex]
		if Controller.bAutoEventQuests and (Definitions[Id].Chain == "Amnesia" or Definitions[Id].Chain == "Halloween") then continue end
		local State = _Invoke("NpcQuestGetState", Id)
		assert(type(State) == "table", "NpcQuestGetState 回應格式已變更")
		if _NpcRewardReady(Definitions[Id], State) then
			if not _CanClaimReward(Key) then return end
			local Result, Reason = _Invoke("NpcQuestClaim", Id)
			assert(type(Result) == "table", "NpcQuestClaim 回應格式已變更")
			_Status(Key, if Result.claimed == true then "已領取任務：" .. Id else "未領取 " .. Id .. "：" .. tostring(Reason or "伺服器未確認完成"))
			return
		end
	end
	_Status(Key, "已檢查 NPC／活動任務，等待完成條件或已交付的角色")
end

--[[
	依歡迎面板查詢離線收益，採用一般 close 領取流程；不購買 triple 倍率。
]]
local function _OfflineRewards(): ()
	local Key = "bAutoOfflineRewards"
	local State = _Invoke("GetWelcomeOfflineState")
	assert(type(State) == "table", "GetWelcomeOfflineState 回應格式已變更")
	if (tonumber(State.totalBase) or 0) <= 0 and not (State.hasAny == true and State.extras ~= nil) then
		_Status(Key, "目前沒有可領取的離線獎勵") return
	end
	if not _CanClaimReward(Key) then return end
	_Invoke("FinalizeWelcomeOffline", "close")
	_Status(Key, "已請求一般領取離線獎勵，等待遊戲同步")
end

--[[
	依離開提示的 claimed 狀態領取原生贈禮，不觸發離開遊戲或購買流程。
]]
local function _LeaveRewards(): ()
	local Key = "bAutoLeaveRewards"
	local State = _Invoke("LeaveOfferState")
	assert(type(State) == "table" and type(State.claimed) == "boolean", "LeaveOfferState 回應格式已變更")
	if State.claimed == false then _ClaimReward(Key, "LeaveOfferClaim")
	else _Status(Key, "離開提示贈禮已領取") end
end

--[[
	取得目前存活角色。
	@return 根部；重生或死亡時為 nil。
	@return Humanoid；重生或死亡時為 nil。
]]
local function _Character()
	local Character = LocalPlayer.Character
	local Root = Character and Character:FindFirstChild("HumanoidRootPart")
	local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
	if Root and Root:IsA("BasePart") and Humanoid and Humanoid.Health > 0 then
		return Root, Humanoid
	end
	return nil, nil
end

--[[
	還原自己的暫時位移；玩家已自行離開目標位置時不覆寫。
	@param Key 僅清理指定工作的位移；nil 表示卸載時清理所有位移。
]]
local function _RestoreMove(Key: string?): ()
	local Move = _Runtime.Move
	if Key and (not Move or Move.Key ~= Key) then return end
	_Runtime.Move, _Runtime.bMoving = nil, false
	if Move and not Move.bNativeTeleport and Move.Root.Parent and (Move.Root.Position - Move.Target.Position).Magnitude < 6 then
		Move.Root.CFrame = Move.Original
		Move.Root.AssemblyLinearVelocity = Move.Velocity
		Move.Root.AssemblyAngularVelocity = Move.AngularVelocity
	end
	if Move and Move.FishingTool then
		local Root, Humanoid = _Character()
		if Root == Move.Root and Humanoid and not LocalPlayer.Character:FindFirstChildOfClass("Tool")
			and Move.FishingTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
			Humanoid:EquipTool(Move.FishingTool)
		end
	end
	if Move and Move.Key ~= "bAutoFish" then
		_Runtime.NextCastAt = os.clock()
		_ResumeNativeAutoFish()
	end
	_Performance.SyncRendering()
end

--[[ 取消轉生前餵食子工作並還原本次位移，可由關閉、錯誤、逾時或卸載重複呼叫。 ]]
function _RebirthFood.Cancel(): ()
	local Job = _RebirthFood.Job
	_RebirthFood.Job, _RebirthFood.bActive, _Runtime.RebirthFoodProgressAt = nil, false, nil
	if Job then pcall(task.cancel, Job) end
	_RestoreMove("bAutoRebirth")
end

--[[
	取得提示的世界位置，供菜園拾取及角色餵食共用。
	@param Prompt 已確認的遊戲提示。
	@return 提示位置；父物件無法定位時為 nil。
]]
local function _PromptPosition(Prompt: ProximityPrompt): Vector3?
	local Parent = Prompt.Parent
	return if Parent and Parent:IsA("Attachment") then Parent.WorldPosition
		elseif Parent and Parent:IsA("BasePart") then Parent.Position else nil
end

--[[
	依遊戲 ServerEnabled 判斷餵食資格，不以距離控制的 Enabled 排除遠處角色。
	@param Prompt 角色餵食提示。
	@return true 表示伺服器允許；未提供 ServerEnabled 的舊版退回 Enabled 判斷。
]]
local function _CanFeedPrompt(Prompt: ProximityPrompt): boolean
	local bServerEnabled = Prompt:GetAttribute("ServerEnabled")
	return if bServerEnabled == nil then Prompt.Enabled == true else bServerEnabled == true
end

--[[
	依遊戲 Constants.NumberSuffixes 還原原生費用字串，供建築與餵食提示共用。
	@param Text 純數字或原生千進位字尾；不接受貨幣圖示與未知字尾。
	@return 非負有限費用；格式未知時為 nil。
]]
local function _ReadGameAmount(Text): number?
	if type(Text) ~= "string" then return nil end
	local Cost = tonumber(Text)
	if not Cost then
		local Digits, Suffix = Text:match("^%s*(%d+%.?%d*)%s*(%a+)%s*$")
		if not Digits then return nil end
		for Index, Name in Constants.NumberSuffixes or {} do
			if string.lower(tostring(Name)) == string.lower(Suffix) then Cost = tonumber(Digits) * 1000 ^ (Index - 1) break end
		end
	end
	return if Cost and Cost == Cost and Cost >= 0 and Cost < math.huge then Cost else nil
end

--[[
	優先讀取原生 LevelUp 提示的費用；缺少時沿用 WikiCalculator.stepCost 與玩家折扣估算。
	@param CharacterData 已放置角色模型或原生 Stand Folder 的資料。
	@param Prompt 同展台的單次餵食提示，缺少時可用目前 MaxLevelUp 提示。
	@param Stand 同展台的原生 Folder，存在時優先讀取其等級與品質。
	@return 下一級費用；無法讀取時為 nil。
	@return 原生價格、概算或資料缺少的具體來源。
	@return 可確定不足的最低門檻；縮寫價格保留末位四捨五入範圍，範圍內交由伺服器確認。
]]
local function _FeedCost(CharacterData: Instance, Prompt: ProximityPrompt?, Stand: Instance?): (number?, string, number?)
	local Digits, Suffix
	if Prompt and Prompt.Parent then Digits, Suffix = Prompt.ActionText:match("%((%d+%.?%d*)(%a*) Food%)%s*$") end
	if Digits then
		local Cost = _ReadGameAmount(Digits .. Suffix)
		if Cost and Cost >= 1 then
			if Suffix == "" then return Cost, "原生提示價格", Cost end
			local Fraction = Digits:match("%.(%d+)$")
			local Unit = Cost / tonumber(Digits)
			local Lower = math.max(1, Cost - Unit * 10 ^ -(Fraction and #Fraction or 0) / 2)
			return Cost, "原生縮寫價格（約值；接近時由遊戲確認）", Lower
		end
	end
	local Level = tonumber(Stand and Stand:GetAttribute("Level")) or tonumber(CharacterData:GetAttribute("Level"))
	local Rarity = (Stand and Stand:GetAttribute("Rarity")) or CharacterData:GetAttribute("Rarity")
	if not Level then return nil, "角色等級尚未同步", nil end
	if type(Rarity) ~= "string" or not _KnownRarities[Rarity] then return nil, "角色品質尚未同步", nil end
	if type(Constants.GetLevelUpCost) ~= "function" then return nil, "缺少 GetLevelUpCost，且原生提示未提供價格", nil end
	local Cost = tonumber(Constants.GetLevelUpCost(Rarity, Level))
	if not Cost or Cost ~= Cost or Cost == math.huge or Cost < 0 then return nil, "遊戲費用公式未返回有效數值", nil end
	Cost = math.max(1, math.floor(Cost))
	if LocalPlayer:GetAttribute("BoostsEnabled") ~= false then
		local Pass = LocalPlayer:GetAttribute("GP_CheaperLevelUp")
		local bPass = Pass == true or (Pass == nil and LocalPlayer:GetAttribute("GemStore_CheaperLevelUp") == true)
		if bPass then Cost = math.max(1, math.floor(Cost * 0.25 + 0.5)) end
		local Percent = math.clamp(tonumber(LocalPlayer:GetAttribute("UpgLevelDiscount")) or 0, 0, 90)
		if Percent > 0 then Cost = math.max(1, math.floor(Cost * (1 - Percent / 100) + 0.5)) end
	end
	if LocalPlayer:GetAttribute("Rsh_FoodSaver") == true then
		if not _Runtime.FoodResearchEffects then
			local Modules = ReplicatedStorage:FindFirstChild("Modules")
			local Module = Modules and Modules:FindFirstChild("ResearchEffects")
			assert(Module and Module:IsA("ModuleScript"), "缺少 ResearchEffects，無法確認食物節省折扣")
			_Runtime.FoodResearchEffects = require(Module)
		end
		local Node = (_Runtime.FoodResearchEffects.NODES or {}).FoodSaver
		assert(type(Node) == "table" and tonumber(Node.add), "FoodSaver 折扣資料已變更")
		Cost = math.max(1, math.floor(Cost * (1 - math.clamp(tonumber(Node.add), 0, 0.5)) + 0.5))
	end
	return Cost, "角色等級與折扣公式估算", Cost
end

--[[
	完整顯示餵食目標與價格來源，區分真的不足與角色資料尚未同步。
	@param Model 選中的角色模型或 Stand Folder。
	@param Stand 同展台的原生資料，可為 nil。
	@param Prompt 用於讀取下一級價格的原生提示。
	@param Food 目前食物。
	@param Cost 讀到或估算的下一級費用；未知時為 nil。
	@param Source 費用來源或資料缺少原因。
]]
local function _ShowFeedCost(Model, Stand, Prompt, Food, Cost, Source): ()
	if not _Runtime.FeedLabel then return end
	local Level = (Stand and Stand:GetAttribute("Level")) or Model:GetAttribute("Level")
	local Rarity = (Stand and Stand:GetAttribute("Rarity")) or Model:GetAttribute("Rarity")
	local Text = string.format("目標：%s\n品質：%s；等級：%s\n現有 Food：%s；下一級費用：%s\n判斷來源：%s\n原生提示：%s",
		Model.Name, tostring(Rarity or "未同步"), tostring(Level or "未同步"), tostring(Food), tostring(Cost or "未同步"), Source,
		Prompt and Prompt.ActionText or "未載入")
	if Text ~= _Runtime.FeedText then _Runtime.FeedText = Text; _Runtime.FeedLabel:Set("餵食判斷", Text) end
end

--[[
	持有移動權時暫停原生 Auto Fish，等待實際狀態更新，避免提前清理造成維持流程重新開啟。
	firesignal 未切換時僅嘗試目前按鈕的有效 Luau 回呼，觀察關閉後立即停止，最多等待三秒。
	@param Key 目前持有移動權的自動功能。
	@return true 已確認關閉；false 已停止、介面重建或確認逾時。
	@return 等待或失敗原因；成功時為已暫停。
	使用範例：
	```lua
	-- 前提：_Travel 已為 bAutoFeed 取得移動權，其他釣魚維持流程不會重新啟用開關。
	-- local bPaused, Reason = _PauseNativeAutoFish("bAutoFeed")
	-- 只有 bPaused 才接著取消回合並移動；失敗交由 _RestoreMove 清理。
	```
]]
local function _PauseNativeAutoFish(Key: string): (boolean, string)
	local Button, On, Off = _NativeAutoFishUi()
	if not Button or (not On.Enabled and Off.Enabled) then return true, "已暫停" end
	if not _IsNativeAutoFishReady(Button) then return false, "無法暫停 Auto Fish：等待解鎖介面同步" end
	if type(firesignal) ~= "function" and type(getconnections) ~= "function" then
		return false, "無法暫停 Auto Fish：缺少 firesignal 與 getconnections"
	end
	_Runtime.ResumeNativeAutoFish = { Button = Button }
	_Status(Key, "等待 Auto Fish 關閉確認")
	local Deadline, FallbackAt = os.clock() + 3, os.clock() + (if type(firesignal) == "function" then 1 else 0)
	local bFallback, LastError = false, nil
	if type(firesignal) == "function" then
		local bOk, Reason = pcall(firesignal, Button.MouseButton1Click)
		if not bOk then LastError = tostring(Reason) end
	end
	while true do
		if not _Runtime.bAlive or not Controller[Key] or not _Runtime.Move or _Runtime.Move.Key ~= Key then return false, "操作已停止" end
		local Current, CurrentOn, CurrentOff = _NativeAutoFishUi()
		if Current ~= Button then return false, "Auto Fish 介面已重建，等待下一輪" end
		if not CurrentOn.Enabled and CurrentOff.Enabled then
			_NativeAutoFishStatus("暫停，等待其他操作完成")
			return true, "已暫停"
		end
		if os.clock() >= Deadline then break end
		if not bFallback and os.clock() >= FallbackAt then
			bFallback = true
			if type(getconnections) == "function" then
				local bRead, Connections = pcall(getconnections, Button.MouseButton1Click)
				if bRead and type(Connections) == "table" then
					local Attempts = 0
					for _, Connection in Connections do
						if Connection.Enabled == false or Connection.LuaConnection == false or Connection.ForeignState == true
							or type(Connection.Function) ~= "function" then continue end
						local bOk, Reason = pcall(Connection.Function)
						if not bOk then LastError = tostring(Reason) end
						Attempts += 1
						if not On.Enabled or Off.Enabled or Attempts >= 8 then break end
					end
					if Attempts == 0 then LastError = "沒有可呼叫的原生按鈕回呼" end
				else LastError = "getconnections 讀取失敗：" .. tostring(Connections) end
			else LastError = LastError or "firesignal 未切換，且缺少 getconnections 後備能力" end
		end
		task.wait(0.1)
	end
	return false, "Auto Fish 關閉確認逾時：Enabled=" .. tostring(On.Enabled) .. "／Disabled=" .. tostring(Off.Enabled)
		.. (if LastError then "；" .. LastError else "；原生回呼尚未完成切換")
end

--[[
	找到操作目標後持有移動權，先暫停原生自動釣魚並取消自己的回合，確認停止後才傳送。
	取消確認與本地鎖釋放最多等三秒；未開啟自動釣魚的手動回合及揭曉動畫不搶移動。
	需要離開魚池時先收起魚竿，交由原生流程解除上鉤介面鎖，返回後只在空手時還原原魚竿。
	同一工作可連續拜訪目標，保留起點。
	@param Key 移動工作的開關欄位。
	@param Root 本輪角色根部。
	@param Target 本次目標位置與朝向。
	@return true 表示等待後仍持有位置且功能開啟；false 表示被其他工作或玩家移動中斷。
	使用範例：
	```lua
	-- 前提：角色存活且沒有其他工作持有位移。
	-- _Travel("bAutoFeed", Root, Target) 成功後可拾取；結束呼叫 _RestoreMove("bAutoFeed")。
	```
]]
local function _Travel(Key: string, Root: BasePart, Target: CFrame): boolean
	if _Runtime.bMoving and (not _Runtime.Move or _Runtime.Move.Key ~= Key) then
		_Status(Key, "等待其他移動操作完成") return false
	end
	if Key ~= "bAutoFish" and _IsCatchLocked() then
		_Status(Key, "等待釣獲揭曉與介面解鎖") return false
	end
	if Key ~= "bAutoFish" and _Runtime.FishPhase ~= "Idle"
		and not (Controller.bAutoFish or _Runtime.bFishingOwned or _Runtime.bPendingOwned) then
		_Status(Key, "等待手動釣魚結束；自動釣魚未開啟") return false
	end
	if not _Runtime.Move then
		_Runtime.Move = { Key = Key, Root = Root, Original = Root.CFrame, Target = Target,
			Velocity = Root.AssemblyLinearVelocity, AngularVelocity = Root.AssemblyAngularVelocity }
	end
	_Runtime.bMoving, _Runtime.Move.Target = true, Target
	if Key ~= "bAutoFish" then
		local bPaused, Reason = _PauseNativeAutoFish(Key)
		if not bPaused then _Status(Key, Reason) return false end
		if _Runtime.FishPhase ~= "Idle" then
			-- 原生釣魚流程會在魚竿解除裝備時清理上鉤介面鎖，避免只發 Cancel 後本地狀態尚未釋放。
			local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
			local _, Humanoid = _Character()
			if Humanoid and Tool and Tool:GetAttribute("IsFishingRod") == true then
				_Runtime.Move.FishingTool = Tool
				Humanoid:UnequipTools()
			end
			_Status("bAutoFish", "暫停釣魚，等待其他操作完成")
			_Status(Key, "等待暫停釣魚確認")
			local Cancel = Remotes:FindFirstChild("FishingCancel")
			if not Cancel or not Cancel:IsA("RemoteEvent") then _Status(Key, "缺少 FishingCancel，未移動") return false end
			Cancel:FireServer()
			local Deadline = os.clock() + 3
			while _Runtime.FishPhase ~= "Idle" or _IsCatchLocked() do
				if not _Runtime.bAlive or not Controller[Key] then return false end
				if os.clock() >= Deadline then
					_Status(Key, if _Runtime.FishPhase == "Idle" then "釣魚已停止，等待原生介面解鎖" else "等待取消釣魚確認逾時，稍後重試") return false
				end
				task.wait(0.1)
			end
		end
		if not _Runtime.bAlive or not Controller[Key] or _IsCatchLocked() then return false end
	end
	-- 先確認原生 Auto Fish 關閉與回合停止，再允許渲染開啟；取消失敗不會造成閃爍。
	_Runtime.Move.bInteractionReady = Key ~= "bAutoFish"
	local bRenderingReady, RenderingReason = pcall(_Performance.BeginInteraction, Key)
	if not bRenderingReady then _Status(Key, "無法準備互動渲染：" .. tostring(RenderingReason)) return false end
	_Status(Key, if Key == "bAutoFish" then "正在前往魚池岸邊" else "釣魚已讓出，正在前往操作位置")
	Root.CFrame, Root.AssemblyLinearVelocity, Root.AssemblyAngularVelocity = Target, Vector3.zero, Vector3.zero
	task.wait(0.4)
	return _Runtime.bAlive and Controller[Key] == true and Root.Parent == LocalPlayer.Character
		and _Runtime.Move ~= nil and _Runtime.Move.Key == Key and (Root.Position - Target.Position).Magnitude < 6
end

--[[
	從目標附近向下檢查可站立的地面；不使用固定地圖座標。
	@param Point 魚池岸邊或研究節點附近的候選位置。
	@param Root 角色根部，用來估算站立高度。
	@param Humanoid 存活角色的 Humanoid。
	@param Excluded 不參與地面偵測的目標物件。
	@return 根部站立位置，沒有平坦且高度合理的地面時為 nil。
]]
local function _GroundPose(Point: Vector3, Root: BasePart, Humanoid: Humanoid, Excluded: Instance): CFrame?
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = { LocalPlayer.Character, Excluded }
	Params.IgnoreWater, Params.RespectCanCollide = true, true
	local Hit = workspace:Raycast(Point + Vector3.new(0, 24, 0), Vector3.new(0, -48, 0), Params)
	if not Hit or Hit.Normal.Y < 0.65 or math.abs(Hit.Position.Y - Point.Y) > 12 then return nil end
	return CFrame.new(Hit.Position + Vector3.new(0, Humanoid.HipHeight + Root.Size.Y / 2 + 0.5, 0)) * Root.CFrame.Rotation
end

--[[
	配對結束本功能送出的觸碰，供完成、錯誤、關閉及卸載共用；可重複呼叫。
]]
local function _ReleaseBuildTouch(): ()
	local Contact = _Runtime.BuildTouch
	_Runtime.BuildTouch = nil
	if Contact and type(firetouchinterest) == "function" then
		pcall(firetouchinterest, Contact.Root, Contact.Touch, 1)
	end
end

--[[
	讀取建築按鈕原生 ValueBase 欄位，不由顯示文字猜測費用或付費狀態。
	@param Button UnlockButtons 下的按鈕模型。
	@param Name 欄位名稱。
	@param ClassName 原生欄位類別。
	@return 欄位值；未載入或類別不同時為 nil。
]]
local function _BuildValue(Button: Instance, Name: string, ClassName: string)
	local Value = Button:FindFirstChild(Name)
	return if Value and Value:IsA(ClassName) then Value.Value else nil
end

--[[
	依已載入按鈕確認自己可負擔的 Cash 建築，付費商品與未知資料一律略過。
	@param Button 自己 UnlockButtons 下的建築按鈕。
	@param Plot 自己的地塊。
	@return 原生 Touch 零件；不可操作時為 nil。
	@return 費用；不可操作時為 nil。
]]
local function _BuildCandidate(Button: Instance, Plot: Instance): (BasePart?, number?)
	if tonumber(Plot:GetAttribute("OwnerUserId")) ~= LocalPlayer.UserId then return nil, nil end
	local DisplayTimer = Button:FindFirstChild("DisplayTimer")
	local Timer = DisplayTimer and DisplayTimer:FindFirstChild("BillboardGui")
	if Timer and Timer:IsA("BillboardGui") and Timer.Enabled then return nil, nil end
	if _BuildValue(Button, "TimeNeeded", "BoolValue") == true and (not Timer or not Timer:IsA("BillboardGui")) then return nil, nil end
	local bRebirthNeeded = _BuildValue(Button, "RebirthNeeded", "BoolValue")
	if bRebirthNeeded == nil then return nil, nil end
	if bRebirthNeeded then
		local Required = tonumber(_BuildValue(Button, "RebirthCost", "StringValue"))
		local Rebirths = tonumber(LocalPlayer:GetAttribute("Rebirths"))
		local bSacrificeSkips = _BuildValue(Button, "SacrificeSkipsRebirths", "BoolValue") == true
			and (tonumber(LocalPlayer:GetAttribute("Sacrifices")) or 0) >= 1
		if not bSacrificeSkips and (not Required or Required ~= Required or Required < 0 or Required == math.huge
			or not Rebirths or Rebirths < Required) then return nil, nil end
	end
	if _BuildValue(Button, "IsPaid", "BoolValue") ~= false then return nil, nil end
	local DevId = _BuildValue(Button, "DevID", "StringValue")
	if DevId == nil or DevId:match("%S") then return nil, nil end
	local Structure = _BuildValue(Button, "PurchaseStructure", "StringValue")
	if not Structure or Structure == "" then return nil, nil end
	local Currency = _BuildValue(Button, "CostType", "StringValue")
	if Currency ~= "Cash" then return nil, nil end
	local Cost = _ReadGameAmount(_BuildValue(Button, "Cost", "StringValue"))
	if not Cost or Cost > (tonumber(LocalPlayer:GetAttribute(Currency .. "Number")) or 0) then return nil, nil end
	local Touch = Button:FindFirstChild("Touch")
	if not Touch or not Touch:IsA("BasePart") or not Touch.CanTouch or Touch.Transparency >= 1 then return nil, nil end
	return Touch, Cost
end

--[[
	每輪前往自己地塊一個可負擔的建築按鈕，沿用原生觸碰購買，最後返回起點。
	建造倒數顯示中與轉生不足的按鈕先略過；未移除按鈕會暫緩重試，避免卡住其他候選。
]]
local function _Build(): ()
	assert(type(firetouchinterest) == "function", "缺少 firetouchinterest，無法自動購買建築")
	if _Runtime.bMoving then return end
	local Root = _Character()
	local Plots = workspace:FindFirstChild("PlayerPlots")
	if not Root or not Plots then return end
	local OwnPlot = nil
	for _, Plot in Plots:GetChildren() do
		if tonumber(Plot:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then OwnPlot = Plot break end
	end
	local Buttons = OwnPlot and OwnPlot:FindFirstChild("UnlockButtons")
	if not Buttons then _Status("bAutoBuild", "等待自己的建築按鈕載入") return end
	local Best, BestTouch, BestCost = nil, nil, math.huge
	for _, Button in Buttons:GetChildren() do
		if os.clock() < (_Runtime.BuildRetryAt[Button] or 0) then continue end
		local Touch, Cost = _BuildCandidate(Button, OwnPlot)
		if Touch and (Cost < BestCost or (Cost == BestCost and (not Best or Button.Name < Best.Name))) then
			Best, BestTouch, BestCost = Button, Touch, Cost
		end
	end
	if not Best then _Status("bAutoBuild", "等待建築、金錢、解鎖條件或重試間隔") return end
	_Runtime.BuildRetryAt[Best] = os.clock() + 15
	_Status("bAutoBuild", "前往購買建築：" .. tostring(_BuildValue(Best, "PurchaseStructure", "StringValue")))
	if not _Travel("bAutoBuild", Root, CFrame.new(BestTouch.CFrame.Position + Vector3.new(0, 2, 0))) then
		_RestoreMove("bAutoBuild") return
	end
	if not Best:IsDescendantOf(Buttons) or _BuildCandidate(Best, OwnPlot) ~= BestTouch then _RestoreMove("bAutoBuild") return end
	_Runtime.BuildTouch = { Root = Root, Touch = BestTouch }
	firetouchinterest(Root, BestTouch, 0)
	task.wait(0.3)
	_ReleaseBuildTouch()
	local Deadline = os.clock() + 1.2
	while Best:IsDescendantOf(Buttons) and os.clock() < Deadline do
		if not Controller.bAutoBuild or not _Runtime.bAlive then _RestoreMove("bAutoBuild") return end
		task.wait(0.1)
	end
	local bRemoved = not Best:IsDescendantOf(Buttons)
	_RestoreMove("bAutoBuild")
	_Status("bAutoBuild", if bRemoved then "建築按鈕已移除，等待建造完成"
		else "已觸碰購買，等待遊戲確認或前置／轉生／建造條件")
end

--[[
	由原生角色屬性還原背包組鍵，只用來核對實際裝備，送出時仍使用伺服器原始鍵。
	@param Tool 實際角色工具。
	@return 角色組鍵；非擁有角色工具時為 nil。
]]
local function _WorkerToolKey(Tool: Instance): string?
	if not Tool:IsA("Tool") or Tool:GetAttribute("IsCharacterTool") ~= true or Tool:GetAttribute("Owned") == false then return nil end
	local TypeName = tostring(Tool:GetAttribute("CharacterType") or "")
	if TypeName == "nil" then TypeName = "" end
	local Level = math.max(1, math.floor(tonumber(Tool:GetAttribute("Level")) or 1))
	return "C|" .. tostring(Tool:GetAttribute("CharacterName") or Tool.Name) .. "|" .. TypeName .. (if Level >= 2 then "|L" .. Level else "")
end

--[[
	角色仍手持本腳本裝備的魚竿時，還原先前工具。
]]
local function _RestoreRod(): ()
	local Rod, PreviousTool = _Runtime.Rod, _Runtime.PreviousTool
	_Runtime.Rod, _Runtime.PreviousTool = nil, nil
	local _, Humanoid = _Character()
	if Humanoid and Rod and Rod.Parent == LocalPlayer.Character then
		Humanoid:UnequipTools()
		if PreviousTool and PreviousTool.Parent == LocalPlayer:FindFirstChild("Backpack") then
			Humanoid:EquipTool(PreviousTool)
		end
	end
end

--[[
	派工結束後只還原自己裝備的工具；不覆蓋玩家中途手動選取的其他工具。
]]
local function _RestoreWorkerGear(): ()
	local Gear = _Runtime.WorkerGear
	_Runtime.WorkerGear = nil
	if not Gear then return end
	local _, Humanoid = _Character()
	if not Humanoid then return end
	local Current = LocalPlayer.Character:FindFirstChildOfClass("Tool")
	if Current and Current ~= Gear.Tool and Current ~= Gear.Previous and _WorkerToolKey(Current) ~= Gear.Key then return end
	if Gear.bHoldRequested then
		local Remote = Remotes:FindFirstChild("BackpackHoldCharacter")
		if Remote and Remote:IsA("RemoteEvent") then pcall(Remote.FireServer, Remote, Gear.PreviousKey or "") end
	end
	if Current and Current ~= Gear.Previous then Humanoid:UnequipTools() end
	if Gear.Previous and Gear.Previous.Parent == LocalPlayer:FindFirstChild("Backpack") then Humanoid:EquipTool(Gear.Previous) end
end

--[[
	取消自己的釣魚或尚未確認的拋竿；保留 pending 標記以處理延遲 Started。
]]
local function _CancelFishing(): ()
	if _Runtime.bFishingOwned or _Runtime.bPendingOwned then
		_Runtime.bFishingOwned = false
		local Remote = Remotes:FindFirstChild("FishingCancel")
		if Remote and Remote:IsA("RemoteEvent") then
			pcall(Remote.FireServer, Remote)
		end
	end
end

--[[
	停止全部工作並還原暫時狀態，可重複呼叫；不回滾伺服器已完成的購買／轉生。
	使用範例：
	```lua
	-- 前提：入口已成功載入。
	getgenv().FishAnAnimeRngBjz.Unload()
	```
]]
function Controller.Unload(): ()
	if not _Runtime.bAlive then
		return
	end
	_Runtime.bAlive = false
	for _, Feature in _Features do
		Controller[Feature.Key] = false
	end
	for _, Job in _Runtime.Jobs do
		pcall(task.cancel, Job)
	end
	table.clear(_Runtime.Jobs)
	_CancelFishing()
	for _, Connection in _Runtime.Connections do
		Connection:Disconnect()
	end
	table.clear(_Runtime.Connections)
	_RestoreMove()
	_RestoreRod()
	_RestoreNativeAutoFish()
	_ReleaseBuildTouch()
	_MapPickup.ReleaseTouch()
	table.clear(_MapPickup.Drops)
	table.clear(_MapPickup.Retry)
	table.clear(_MapPickup.Unavailable)
	_MapPickup.Remote, _MapPickup.bSynced, _MapPickup.ProgressAt = nil, false, nil
	_RestoreWorkerGear()
	_Runtime.CharacterPlan, _Runtime.CharacterApplying = nil, nil
	_RebirthFood.Cancel()
	if _Runtime.CharacterDebugJob then pcall(task.cancel, _Runtime.CharacterDebugJob) _Runtime.CharacterDebugJob = nil end
	_Runtime.HomeReservations = nil
	_Runtime.WorkerWait = nil
	_Runtime.StandAnchors, _Runtime.StandLoadRetryAt = nil, nil
	_Runtime.CharacterDebugLast = nil
	_EventQuests.Protected, _EventQuests.Entries = {}, {}
	_Runtime.bCharacterContinue = false
	_RestoreEffects()
	_Performance.RestoreRendering()
	_Rejoin.Restore()
	_UiEffects.Stop()
	_Tutorial.Stop()
	_ClientUi.RestorePause()
	_ClientUi.StopPrompts()
	if _Runtime.Window then
		_Runtime.Window:Unload()
	end
	if Environment.FishAnAnimeRngBjz == Controller then
		Environment.FishAnAnimeRngBjz = nil
	end
end

--[[
	切換工作，關閉時取消其執行緒與暫時狀態。
	@param Key 工作開關欄位。
	@param bEnabled true 開啟；false 關閉。
]]
local function _SetEnabled(Key: string, bEnabled: boolean): ()
	Controller[Key] = bEnabled and _Runtime.bAlive
	if Key == "bAutoEventQuests" then _EventQuests.bReady = false end
	if Key == "bAutoCharacters" and Controller.bAutoCharacters then
		_Runtime.HomeReservations = nil
		_Runtime.RetryAt[Key] = math.max(os.clock(), _Runtime.RetryNotBefore[Key] or 0)
	end
	if Key == "bAutoFish" and Controller.bAutoFish and _Runtime.FishPhase ~= "Idle" then
		_Runtime.bFishingOwned = true
	end
	if not bEnabled then
		if Key == "bAutoRebirth" then
			_RebirthFood.Cancel()
			_UpgradePriority.SavingKey, _UpgradePriority.bSaving = nil, false
			_Runtime.UpgradeRebirthCache = nil
		end
		local Job = _Runtime.Jobs[Key]
		_Runtime.Jobs[Key] = nil
		if Job then
			pcall(task.cancel, Job)
		end
		if Key == "bAutoFish" then
			_Runtime.ResumeNativeAutoFish = nil
			_RestoreNativeAutoFish()
			_CancelFishing()
		end
		_RestoreMove(Key)
		if Key == "bAutoBuild" then _ReleaseBuildTouch() end
		if Key == "bAutoMapPickup" then
			_MapPickup.ReleaseTouch("bAutoMapPickup")
			_MapPickup.bSynced, _MapPickup.ProgressAt = false, nil
			table.clear(_MapPickup.Unavailable)
		end
		if Key == "bAutoEventQuests" then
			_EventQuests.Protected, _EventQuests.Entries = {}, {}
		end
		if Key == "bAutoWorkers" then _Runtime.WorkerWait = nil _RestoreWorkerGear() end
		if Key == "bAutoCharacters" then
			_Runtime.HomeReservations = nil
			_Runtime.StandAnchors, _Runtime.StandLoadRetryAt = nil, nil
			if _Runtime.WorkerGear and _Runtime.WorkerGear.Feature == Key then _RestoreWorkerGear() end
			_Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil
			_Runtime.bCharacterContinue = false
			if Controller.bAutoWorkers and _Runtime.WorkerWait == "Home" then
				_Runtime.RetryAt.bAutoWorkers = math.max(os.clock(), _Runtime.RetryNotBefore.bAutoWorkers or 0)
			end
		end
		if Key == "bLowEffects" then _RestoreEffects() end
		if Key == "bPreventAutoRejoin" then _Rejoin.Restore() end
		if Key == "bDeleteUiEffects" then _UiEffects.Stop() end
		if Key == "bAutoSkipTutorial" then _Tutorial.Stop() end
		if Key == "bSuppressGameplayPause" then _ClientUi.RestorePause() end
		if Key == "bBlockPlatformPrompts" then _ClientUi.StopPrompts() end
		if Key == "bAutoGear" then
			_RestoreRod()
		end
	end
	if not bEnabled then _Performance.EndInteraction(Key) else _Performance.SyncRendering() end
	if bEnabled and Key == "bBlockPlatformPrompts" then
		local bOk, Reason = pcall(_ClientUi.PromptStep)
		if not bOk then _Status(Key, "平台彈窗阻擋未啟用：" .. tostring(Reason)) end
		return
	end
	_Status(Key, if bEnabled then "等待下一輪" else "已關閉")
end

--[[
	選擇目前資金、轉生、獻祭及材料條件可滿足且強於已持有魚竿的商品。
	依遊戲 Rods.Strength 排序；材料充足但未交付時先 DepositAll，下輪確認 ready 才 Unlock。
	使用範例：
	```lua
	-- 開啟自動購買後，每輪先取得 FishingStoreGetState，再只對最強候選送出一個操作。
	-- 一般魚竿使用 Cash；材料竿依序 DepositAll、確認狀態、Unlock。不觸發 Robux。
	```
]]
local function _BuyBestRod(): ()
	assert(type(Constants.GetRodRebirthRequired) == "function", "遊戲缺少 GetRodRebirthRequired，無法確認魚竿解鎖條件")
	if not _Runtime.RodUpdateGate then
		local Modules = ReplicatedStorage:FindFirstChild("Modules")
		local Module = Modules and Modules:FindFirstChild("UpdateGate")
		assert(Module and Module:IsA("ModuleScript"), "缺少遊戲 UpdateGate，無法確認魚竿是否開放")
		_Runtime.RodUpdateGate = require(Module)
		assert(type(_Runtime.RodUpdateGate.IsOfferHeld) == "function", "UpdateGate API 已變更")
	end
	local State = _Invoke("FishingStoreGetState")
	assert(type(State) == "table" and type(State.owned) == "table" and tonumber(State.rebirths)
		and tonumber(State.sacrifices), "魚竿商店狀態尚未就緒或格式已變更")
	local Rods = (Constants.Fishing or {}).Rods or {}
	local BestOwned = 0
	for Name, bOwned in State.owned do
		if bOwned == true then BestOwned = math.max(BestOwned, tonumber((Rods[Name] or {}).Strength) or 0) end
	end
	for _, Container in { LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") } do
		if not Container then continue end
		for _, Tool in Container:GetChildren() do
			if Tool:IsA("Tool") and Tool:GetAttribute("IsFishingRod") == true then
				BestOwned = math.max(BestOwned, tonumber(Tool:GetAttribute("RodStrength")) or 0)
			end
		end
	end
	local Rebirths, Sacrifices = tonumber(State.rebirths), tonumber(State.sacrifices)
	local Cash = tonumber(LocalPlayer:GetAttribute("CashNumber")) or 0
	local Best, BestStrength, BestCost, Action = nil, BestOwned, math.huge, nil
	for Key, Offer in (Constants.FishingStore or {}).Offers or {} do
		if type(Offer) ~= "table" or type(Offer.RodName) ~= "string" or State.owned[Offer.RodName] == true then continue end
		if _Runtime.RodUpdateGate.IsOfferHeld("FishingStore", Key) then continue end
		local Strength = tonumber((Rods[Offer.RodName] or {}).Strength)
		if not Strength or Strength <= BestOwned then continue end
		local RequiredSacrifices = tonumber(Offer.SacrificeRequired) or 0
		local RequiredRebirths = tonumber(Constants.GetRodRebirthRequired(Offer, Sacrifices))
		if not RequiredRebirths or Sacrifices < RequiredSacrifices or Rebirths < RequiredRebirths then continue end
		local Unlock = type(State.unlock) == "table" and State.unlock[Key] or nil
		local Cost, CurrentAction = tonumber(Offer.CashCost), "Cash"
		if type(Unlock) == "table" and Unlock.once == true then continue end
		if (type(Offer.Materials) == "table" and #Offer.Materials > 0) or type(Unlock) == "table" then
			if type(Unlock) ~= "table" then continue end
			Cost = tonumber(Unlock.cash)
			if Unlock.ready == true then CurrentAction = "Unlock"
			else
				if type(Unlock.materials) ~= "table" or #Unlock.materials == 0 then continue end
				local bEnough = true
				for _, Material in Unlock.materials do
					local Need, Deposited, Have = tonumber(Material.need), tonumber(Material.deposited), tonumber(Material.have)
					if not Need or not Deposited or not Have or Deposited + Have < Need then bEnough = false break end
				end
				if not bEnough then continue end
				CurrentAction = "DepositAll"
			end
		end
		if not Cost or Cost < 0 or Cost > Cash then continue end
		if Strength > BestStrength or (Strength == BestStrength and Cost < BestCost) then
			Best, BestStrength, BestCost, Action = Key, Strength, Cost, CurrentAction
		end
	end
	if not Best then _Status("bAutoBuyRod", "沒有可負擔且強於已持有魚竿的已開放商品") return end
	if not Controller.bAutoBuyRod then return end
	local bAccepted, Reason = _Invoke("FishingStorePurchase", Best, Action)
	local Name = Constants.FishingStore.Offers[Best].RodName
	_Status("bAutoBuyRod", if bAccepted == true then
		(if Action == "DepositAll" then "已交付材料，等待下輪確認解鎖：" else "魚竿購買已接受：") .. Name
		else "魚竿操作未接受：" .. tostring(Reason or "Unknown") .. "（" .. Name .. "／" .. Action .. "）")
end

--[[
	比較已持有魚竿的 RodStrength，裝備最高者，同分保留目前工具。
]]
local function _EquipRod(): ()
	if _Runtime.bMoving or _Runtime.FishPhase ~= "Idle" then
		return
	end
	local _, Humanoid = _Character()
	if not Humanoid then
		return
	end
	local Character, Backpack = LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack")
	local Best, Strength = nil, -math.huge
	for _, Container in { Character, Backpack } do
		if not Container then
			continue
		end
		for _, Tool in Container:GetChildren() do
			if Tool:IsA("Tool") and Tool:GetAttribute("IsFishingRod") == true then
				local Value = tonumber(Tool:GetAttribute("RodStrength"))
				if Value and Value > Strength then
					Best, Strength = Tool, Value
				end
			end
		end
	end
	if not Best then
		_Status("bAutoGear", "沒有帶有有效強度資料的魚竿")
		return
	end
	if Best.Parent ~= Character then
		if not _Runtime.Rod then
			_Runtime.PreviousTool = Character:FindFirstChildOfClass("Tool")
		end
		Humanoid:EquipTool(Best)
		_Runtime.Rod = Best
	end
	_Status("bAutoGear", "最強魚竿：" .. Best.Name .. "（" .. tostring(Strength) .. "）")
end

--[[
	選擇魚竿強度足夠的已載入魚池，先傳送岸邊再依伺服器狀態拋竿及點擊。
	使用範例：
	```lua
	-- 前提：背包有魚竿且至少一個魚池與岸邊地面已載入。
	-- 開啟後先到岸邊、等待位置同步，再送拋竿；收到 Hooked 才開始 FishingClick。
	-- 伺服器拒絕時顯示 reason 並延後重試。
	```
]]
local function _Fish(): ()
	if _Runtime.bMoving or _IsCatchLocked() then
		return
	end
	_ResumeNativeAutoFish()
	local Root, Humanoid = _Character()
	if not Root then
		return
	end
	local Now = os.clock()
	if _Runtime.FishPhase ~= "Idle" then
		local NativeButton, NativeOn, NativeOff = _NativeAutoFishUi()
		local bNativeAutoFish = NativeButton ~= nil and NativeOn.Enabled and not NativeOff.Enabled
		local Timeout = if _Runtime.FishPhase == "Pending" then 10 else 120
		if Now - _Runtime.FishChangedAt > Timeout then
			_CancelFishing()
			_Runtime.FishPhase, _Runtime.NextCastAt = "Idle", Now + 5
			_Status("bAutoFish", "釣魚狀態逾時，等待重試")
		elseif _Runtime.FishPhase == "Hooked" and not bNativeAutoFish then
			_Remote("FishingClick", "RemoteEvent"):FireServer()
		end
		return
	end
	if Now < _Runtime.NextCastAt or LocalPlayer:GetAttribute("BTJester") ~= nil then
		return
	end
	local Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
	if not Tool or Tool:GetAttribute("IsFishingRod") ~= true then
		_EquipRod()
		Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
		if not Tool or Tool:GetAttribute("IsFishingRod") ~= true then
			_Status("bAutoFish", "背包沒有可裝備魚竿") return
		end
	end
	local Best, Target, Shore, Distance = nil, nil, nil, math.huge
	local Ponds = (Constants.Fishing or {}).Ponds or {}
	for _, Part in workspace:GetDescendants() do
		if
			not Part:IsA("BasePart") or not (Ponds[Part.Name] or Part.Name == "PONDAREA1" or Part.Name == "PONDAREA2")
		then
			continue
		end
		local Required = tonumber((Ponds[Part.Name] or {}).RequiredStrength) or 0
		if (tonumber(Tool:GetAttribute("RodStrength")) or 0) < Required then continue end
		local Point, Half = Part.CFrame:PointToObjectSpace(Root.Position), Part.Size / 2
		local Surface = Part.CFrame:PointToWorldSpace(
			Vector3.new(math.clamp(Point.X, -Half.X, Half.X), Half.Y, math.clamp(Point.Z, -Half.Z, Half.Z))
		)
		local Current = (Root.Position - Surface).Magnitude
		if Current >= Distance then continue end
		local Candidate, CandidateDistance = nil, math.huge
		for _, Edge in {
			Vector3.new(-Half.X - 4, Half.Y, math.clamp(Point.Z, -Half.Z, Half.Z)),
			Vector3.new(Half.X + 4, Half.Y, math.clamp(Point.Z, -Half.Z, Half.Z)),
			Vector3.new(math.clamp(Point.X, -Half.X, Half.X), Half.Y, -Half.Z - 4),
			Vector3.new(math.clamp(Point.X, -Half.X, Half.X), Half.Y, Half.Z + 4),
		} do
			local Pose = _GroundPose(Part.CFrame:PointToWorldSpace(Edge), Root, Humanoid, Part)
			if Pose and (Root.Position - Pose.Position).Magnitude < CandidateDistance then
				Candidate, CandidateDistance = Pose, (Root.Position - Pose.Position).Magnitude
			end
		end
		if Candidate then Best, Target, Shore, Distance = Part, Surface, Candidate, Current end
	end
	local MaxDistance = ((Constants.Fishing or {}).Distances or {}).MaxStartDistance or 50
	if not Best or not Shore then
		_Status("bAutoFish", "等待強度足夠的魚池與岸邊地面載入")
		return
	end
	if Distance > MaxDistance or (Root.Position - Shore.Position).Magnitude > 6 then
		_Status("bAutoFish", "傳送到魚池岸邊：" .. Best.Name)
		if not _Travel("bAutoFish", Root, Shore) then _RestoreMove("bAutoFish") return end
		-- 到岸後保留位置；只有傳送等待期間的取消會返回原位。
		_Runtime.Move, _Runtime.bMoving = nil, false
	end
	if not Best:IsDescendantOf(workspace) or _Runtime.FishPhase ~= "Idle" then return end
	local Point, Half = Best.CFrame:PointToObjectSpace(Root.Position), Best.Size / 2
	Target = Best.CFrame:PointToWorldSpace(Vector3.new(math.clamp(Point.X, -Half.X, Half.X), Half.Y, math.clamp(Point.Z, -Half.Z, Half.Z)))
	if (Root.Position - Target).Magnitude > MaxDistance then _Status("bAutoFish", "位置尚未同步到魚池旁，等待重試") return end
	_Remote("FishingRequestStart", "RemoteEvent"):FireServer(Best, Target)
	_Runtime.bPendingOwned = true
	_Runtime.FishPhase, _Runtime.FishChangedAt, _Runtime.NextCastAt = "Pending", os.clock(), os.clock() + 5
	_Status("bAutoFish", "已送出拋竿，等待伺服器確認")
end

--[[
	處理原始釣魚封包；自動釣魚開啟時管理原生自動續釣，關閉時保留手動回合與代理釣魚。
	@param Data FishingState 的資料表，保留 kind／proxy／reason 原始欄位。
]]
local function _OnFishingState(Data): ()
	if type(Data) ~= "table" or Data.proxy == true then
		return
	end
	local Kind = Data.kind
	if Kind == "Started" then
		_Runtime.bFishingOwned = _Runtime.bPendingOwned or Controller.bAutoFish
		_Runtime.bPendingOwned = false
		_Runtime.FishPhase = "Waiting"
		if not Controller.bAutoFish
			or (_Runtime.bMoving and _Runtime.Move and _Runtime.Move.Key ~= "bAutoFish") then
			_CancelFishing()
		end
	elseif Kind == "Hooked" then
		_Runtime.FishPhase = "Hooked"
	elseif Kind == "GodSequenceStarting" then
		_Runtime.FishPhase = "Reveal"
	elseif Kind == "Completed" or Kind == "GodRevealRewards" or Kind == "Stopped" or Kind == "Denied" then
		_Runtime.FishPhase, _Runtime.bFishingOwned, _Runtime.bPendingOwned = "Idle", false, false
		local bCompleted = Kind == "Completed" or Kind == "GodRevealRewards" or (Kind == "Stopped" and Data.reason == "COMPLETED")
		local Button, On, Off = _NativeAutoFishUi()
		local Delay = math.max(0, tonumber(((Constants.Fishing or {}).AutoFish or {}).RestartDelay) or 0.2)
		if bCompleted and Button and On.Enabled and not Off.Enabled then Delay = math.max(Delay, 2) end
		_Runtime.NextCastAt = os.clock() + (if bCompleted then Delay else 5)
	end
	if Kind ~= "Progress" then
		_Runtime.FishChangedAt = os.clock()
		_Status("bAutoFish", tostring(Kind) .. (Data.reason and ("：" .. tostring(Data.reason)) or ""))
	end
end

--[[
	沿用遊戲先刷新狀態、以 Cash 請求轉生、再刷新狀態的順序，每輪最多請求一次。
	購買前限時逐一嘗試家中角色的全部餵食；食物是否歸零不影響後續購買。
	保留原始拒絕碼及前後狀態供診斷，不把 CLOSED 推測為解鎖／金額／介面條件。
	使用範例：
	```lua
	-- 開啟自動轉生後先 RebirthGetState(true)，收到狀態表才送出 RebirthPurchase("Cash")。
	-- 若仍被拒絕，可讀取 getgenv().FishAnAnimeRngBjz.RebirthStatus 的 Reason 與 BeforeState。
	```
]]
local function _Rebirth(): ()
	local Diagnostic = { Stage = "GetState", Rebirths = LocalPlayer:GetAttribute("Rebirths") }
	Controller.RebirthStatus = Diagnostic
	_Status("bAutoRebirth", "正在刷新轉生狀態")
	local State, StateReason = _Invoke("RebirthGetState", true)
	Diagnostic.BeforeState, Diagnostic.StateReason = State, StateReason
	if type(State) ~= "table" then
		Diagnostic.Stage = "StateUnavailable"
		_Status("bAutoRebirth", "轉生狀態未就緒，未送出轉生：" .. tostring(StateReason or State))
		return
	end
	if not _Runtime.bAlive or not Controller.bAutoRebirth then return end
	_Runtime.UpgradeRebirthCache = { State = State, Rebirths = LocalPlayer:GetAttribute("Rebirths"), At = os.clock() }
	Diagnostic.Stage = "FeedBeforeRebirth"
	local Cost = _ReadGameAmount(State.nextCostText)
	if Cost and (tonumber(LocalPlayer:GetAttribute("CashNumber")) or 0) < Cost then
		Diagnostic.Food = { Reason = "已知轉生金額不足，未預先餵食" }
	else
		local bFed, FeedReport = pcall(_RebirthFood.Run)
		Diagnostic.Food = if bFed then FeedReport else { Error = tostring(FeedReport) }
	end
	_RebirthFood.Cancel()
	if not _Runtime.bAlive or not Controller.bAutoRebirth then return end
	Diagnostic.Stage = "Purchase"
	-- 餵食的30秒上限與購買 RPC 的20秒逾時分開計時，避免長準備後立刻取消轉生。
	_Runtime.StartedAt.bAutoRebirth = os.clock()
	local bAccepted, Reason = _Invoke("RebirthPurchase", "Cash")
	Diagnostic.bAccepted, Diagnostic.Reason = bAccepted == true, Reason
	if bAccepted == true then
		_UpgradePriority.SavingKey, _UpgradePriority.bSaving = nil, false
		_Runtime.UpgradeRebirthCache = nil
	end
	local Message = if bAccepted == true then "伺服器已接受轉生"
		elseif Reason == "NO_MONEY" then "轉生金額不足：NO_MONEY"
		else "轉生請求未接受：" .. tostring(Reason or "未提供原因") .. "（已先刷新轉生狀態）"
	if Diagnostic.Food.Total then
		Message ..= "；轉生前全部餵食已嘗試 " .. tostring(Diagnostic.Food.Attempted) .. "／" .. tostring(Diagnostic.Food.Total)
		if Diagnostic.Food.bTimedOut then Message ..= "（準備達時限，已繼續轉生）" end
	end
	_Status("bAutoRebirth", Message)
	-- 與原生按鈕一致刷新下一次轉生資訊；後續刷新失敗不能掩蓋已收到的購買結果。
	if not _Runtime.bAlive or not Controller.bAutoRebirth then return end
	Diagnostic.Stage = "RefreshState"
	local bRefreshed, AfterState = pcall(_Invoke, "RebirthGetState", true)
	if bRefreshed and type(AfterState) == "table" then
		Diagnostic.AfterState = AfterState
		_Runtime.UpgradeRebirthCache = { State = AfterState, Rebirths = LocalPlayer:GetAttribute("Rebirths"), At = os.clock() }
	else
		Diagnostic.RefreshError = AfterState
		_Status("bAutoRebirth", Message .. "；後續狀態刷新失敗：" .. tostring(AfterState))
	end
	Diagnostic.Stage = "Complete"
end

-- PAIR_PLANNER_START
--[[
	遊戲配對規劃器。只比較角色本體 CPS 與同排相鄰的 3x 加成；同一角色不重複乘 3。
	完整搜尋同排配對區塊與單角混排，合併名稱份數及裝箱等價狀態，協程分段保留進度。
	完成前不改動展台，不以節點或時間上限假裝完成。
]]
local _CharacterPairs = {}
--[[
	使用者提供的 HTML 展開 hoverwrap 後得到的全部 58 組配對，保留來源拼法。
	內嵌於入口，執行時不依賴本機 JSON 或額外網路載入。
]]
_CharacterPairs.HTML_PAIRS = {
	{ "Yin", "Yang" },
	{ "Kira Ho", "Kinja Hikari" },
	{ "Akito Nemu", "Teto" },
	{ "Akito Nemu", "Summer Mika" },
	{ "Akito Nemu", "Summer Mika II" },
	{ "Witch of Darkness", "Subara" },
	{ "Lella", "C.C" },
	{ "Girlyfang", "Serah Victoire" },
	{ "Ada Smasher", "Rebekka" },
	{ "Angelia", "Selene" },
	{ "Emeliara", "Subara" },
	{ "Ai Hoshi", "Rubie Hoshi" },
	{ "Froza", "Ferna" },
	{ "Kaneko II", "Riza" },
	{ "Kaneko II", "Touki" },
	{ "Kaneko II", "Riza II" },
	{ "Orihira", "Rukira" },
	{ "Mimio", "Sheela" },
	{ "Yoruika II", "Rukira" },
	{ "Ramilia Scarlette", "Flandra Scarlette" },
	{ "Alucardia", "Serah Victoire" },
	{ "Madoki Kaneme", "Homara Akeni" },
	{ "Summer Mika II", "Teto" },
	{ "Davida Martinez", "Rebekka" },
	{ "Davida Martinez", "Lucia" },
	{ "Remi", "Rami" },
	{ "Riza II", "Kaneko" },
	{ "Yotso Naka", "Miku Naka" },
	{ "Yotso Naka", "Itsi Naka" },
	{ "Yotso Naka", "Ichi Naka" },
	{ "Yotso Naka", "Nina Naka" },
	{ "Nina Naka", "Itsi Naka" },
	{ "Nina Naka", "Ichi Naka" },
	{ "Nina Naka", "Miku Naka" },
	{ "Miku Naka", "Ichi Naka" },
	{ "Miku Naka", "Itsi Naka" },
	{ "Itsi Naka", "Ichi Naka" },
	{ "Reia II", "Askira II" },
	{ "Lucia", "Rebekka" },
	{ "Irohia", "Ibukia" },
	{ "Megumia", "Aquella" },
	{ "Kaneko", "Touki" },
	{ "Kaneko", "Riza" },
	{ "Kyouka Hora", "Izuma Miyamira" },
	{ "Yumeka", "Mary" },
	{ "Yumeka", "Kirara" },
	{ "Sylphette", "Rudeus Chan" },
	{ "Sylphette", "Roxia" },
	{ "Teto", "Hatsuna Mika" },
	{ "Teto", "Summer Mika" },
	{ "Misa Amara", "Linnete Yagami" },
	{ "Roxia", "Rudeus Chan" },
	{ "Linnete Yagami", "Lawliete" },
	{ "Yuta Chan", "Makia" },
	{ "Rukira", "Yoruika" },
	{ "Yuura", "Chiya" },
	{ "Toxic Ivy", "Harla Quinne" },
	{ "Reia", "Askira" },
}

--[[
	HTML 與提供的遊戲 Constants 之間的明確名稱對照；只用於配對比較，不更改 Remote 原始鍵。
	對照依據含原生配對夥伴及拼法：Tetora、CeCe、AI Hoshi、兩位 Scarlette、Kirali。
]]
_CharacterPairs.NAME_ALIASES = {
	["Teto"] = "Tetora", ["C.C"] = "CeCe", ["Ai Hoshi"] = "AI Hoshi",
	["Ramilia Scarlette"] = "Rami Scarlette", ["Flandra Scarlette"] = "Flara Scarlette", ["Kirara"] = "Kirali",
}

--[[
	取得配對比較名稱；不改寫角色名稱或背包鍵。
	@param Name 原生或 HTML 名稱。
	@return 名稱對照後的比較鍵，未列對照時保留原字串。
]]
function _CharacterPairs.CanonicalName(Name: string): string
	return _CharacterPairs.NAME_ALIASES[Name] or Name
end

--[[ HTML 配對的雙向索引，避免每次評分都線性掃描 58 筆。 ]]
_CharacterPairs.HtmlPartners = {}
for _, Pair in _CharacterPairs.HTML_PAIRS do
	local Left, Right = _CharacterPairs.CanonicalName(Pair[1]), _CharacterPairs.CanonicalName(Pair[2])
	_CharacterPairs.HtmlPartners[Left] = _CharacterPairs.HtmlPartners[Left] or {}
	_CharacterPairs.HtmlPartners[Right] = _CharacterPairs.HtmlPartners[Right] or {}
	_CharacterPairs.HtmlPartners[Left][Right], _CharacterPairs.HtmlPartners[Right][Left] = true, true
end

--[[
	@param Left 左側角色資料；空格為 nil。
	@param Right 右側角色資料；空格為 nil。
	@param Definitions 遊戲目前的 Constants.Characters。
	@return HTML 配對或任一角色的原生 CombinationPartner 包含另一角色時為 true。
]]
function _CharacterPairs.IsPair(Left, Right, Definitions): boolean
	if not Left or not Right then return false end
	local LeftName, RightName = _CharacterPairs.CanonicalName(Left.Name), _CharacterPairs.CanonicalName(Right.Name)
	if (_CharacterPairs.HtmlPartners[LeftName] or {})[RightName] then return true end
	for _, Names in { { Left.Name, Right.Name }, { Right.Name, Left.Name } } do
		local Partners = (Definitions[Names[1]] or {}).CombinationPartner
		local Expected = _CharacterPairs.CanonicalName(Names[2])
		if type(Partners) == "string" and _CharacterPairs.CanonicalName(Partners) == Expected then return true end
		if type(Partners) == "table" then
			for _, Partner in Partners do
				if type(Partner) == "string" and _CharacterPairs.CanonicalName(Partner) == Expected then return true end
			end
		end
	end
	return false
end

--[[
	複製候選角色的配對資料，讓分段搜尋不會混用前後不同版本的配對規則。
	@param Candidates 已確認持有的候選角色組。
	@param Definitions 當前遊戲角色表。
	@return 本輪獨立持有的配對表，不引用遊戲的可變清單。
	@return 配對關係指紋；資料改變時即使角色持有量相同也須重新計算。
]]
function _CharacterPairs.Snapshot(Candidates, Definitions)
	local Snapshot, Names, Edges = {}, {}, {}
	for _, Character in Candidates do
		if Snapshot[Character.Name] then continue end
		local Partners = (Definitions[Character.Name] or {}).CombinationPartner
		Snapshot[Character.Name] = { CombinationPartner = if type(Partners) == "table" then table.clone(Partners) else Partners }
		table.insert(Names, Character.Name)
	end
	table.sort(Names)
	for Left = 1, #Names do
		for Right = Left, #Names do
			if _CharacterPairs.IsPair({ Name = Names[Left] }, { Name = Names[Right] }, Snapshot) then
				table.insert(Edges, Names[Left] .. "|" .. Names[Right])
			end
		end
	end
	return Snapshot, table.concat(Edges, "\n")
end

--[[
	@param Left 左格數字編號。
	@param Right 右格數字編號。
	@return 連號且同一排五格時為 true；5 與 6 不相鄰。
]]
function _CharacterPairs.IsAdjacent(Left: number, Right: number): boolean
	return Right == Left + 1 and math.ceil(Left / 5) == math.ceil(Right / 5)
end

--[[
	@param Layout 與 Slots 一一對應的角色或 false 空格。
	@param Slots 已解鎖的展台數字編號，遞增。
	@param Definitions 當前遊戲配對表。
	@param bObserved true 使用現場每格 PairMultiplier 比較現況；預設以不重疊兩人配對預估新配置。
	@return 本體 CPS 加上配對加成的總和，不包含全玩家收益倍率。
	@return 不重疊的相鄰有效配對數；每個角色只能被一組配對佔用。
	@return 生效配對的位置索引清單，供 UI 避免把已被佔用的中間角色重複列為連結。
]]
function _CharacterPairs.Score(Layout, Slots, Definitions, bObserved: boolean?)
	local Boosted, Links, Income, Pairs = {}, 0, 0, {}
	for Index = 2, #Slots do
		local Left, Right = Layout[Index - 1], Layout[Index]
		local bKnownInactive = bObserved and ((Left and Left.PairMultiplier == 1) or (Right and Right.PairMultiplier == 1))
		if not Boosted[Index - 1] and not bKnownInactive and _CharacterPairs.IsAdjacent(Slots[Index - 1], Slots[Index])
			and _CharacterPairs.IsPair(Layout[Index - 1], Layout[Index], Definitions) then
			Boosted[Index - 1], Boosted[Index], Links = true, true, Links + 1
			table.insert(Pairs, { Index - 1, Index })
		end
	end
	for Index = 1, #Slots do
		local Character = Layout[Index]
		if Character then
			local Multiplier = if bObserved then tonumber(Character.PairMultiplier) else nil
			if not Multiplier or Multiplier ~= Multiplier or Multiplier < 1 or Multiplier == math.huge then Multiplier = if Boosted[Index] then 3 else 1 end
			Income += Character.Cps * Multiplier
		end
	end
	return Income, Links, Pairs
end

--[[
	將每排配置分成不重疊的兩人配對與單角，以配對多重集合取代逐格排列。
	同名角色的配對關係相同，讓較高 CPS 的持有實例優先取得一次3x，剩餘位置填最高 CPS 單角。
	同一角色不得共享給左右兩組；以名稱份數合併，依每段連續格位的 floor(長度/2) 檢查容量。
	兩人配對優先從每排左側放入，再填單角，避免單角先佔用配對夥伴；最後回算實際格位。
	@param Candidates 角色組，含 Key、Name、Cps、Count；同組每份具有相同等級。
	@param Slots 實際已解鎖的展台編號。
	@param Definitions 遊戲目前配對表，不硬編碼過期 Wiki 名單。
	@param Current 當前配置，用作不降收益的初始基準。
	@return 配對後總收益最高的搜尋工作；同收益時偏好更多有效連結，每片讓出以維持其他功能。
	使用範例：
	```lua
	local Characters = {
	    { Key = "A", Name = "A", Cps = 10, Count = 1 },
	    { Key = "B", Name = "B", Cps = 9, Count = 1 },
	    { Key = "Solo", Name = "Solo", Cps = 100, Count = 1 },
	}
	local Work = _CharacterPairs.Start(Characters, { 1, 2, 3 }, { A = { CombinationPartner = "B" } }, { false, false, false })
	while not Work.Done do coroutine.resume(Work.Thread) end
	-- Work.Income == 157；A、B相鄰，單角保留100 CPS。
	```
]]
function _CharacterPairs.Start(Candidates, Slots, Definitions, Current)
	Definitions = _CharacterPairs.Snapshot(Candidates, Definitions)
	local Work = { Algorithm = "DisjointPairsV2", Nodes = 0, States = 0, MemoHits = 0, BlockCount = 0, Done = false, Best = table.clone(Current), bBestObserved = true, Definitions = Definitions }
	Work.Income, Work.Links = _CharacterPairs.Score(Current, Slots, Definitions, true)
	local Groups, ByName, Rows, Pool, Potential = {}, {}, {}, {}, {}
	for _, Character in Candidates do
		local Group = ByName[Character.Name]
		if not Group then Group = { Name = Character.Name, Values = {}, Neighbors = {}, Prefix = { [0] = 0 } } ByName[Character.Name] = Group table.insert(Groups, Group) end
		for _ = 1, math.min(#Slots, Character.Count) do table.insert(Group.Values, Character) end
	end
	--[[
		@param Left 左名稱組。
		@param Right 右名稱組。
		@return 穩定的名稱順序。
	]]
	table.sort(Groups, function(Left, Right)
		return Left.Name < Right.Name
	end)
	for Index, Group in Groups do
		Group.Index = Index
		--[[
			@param Left 左角色。
			@param Right 右角色。
			@return 同名角色依 CPS 再依鍵排序。
		]]
		table.sort(Group.Values, function(Left, Right)
			return Left.Cps > Right.Cps or (Left.Cps == Right.Cps and Left.Key < Right.Key)
		end)
		while #Group.Values > #Slots do table.remove(Group.Values) end
		for Rank, Character in Group.Values do
			Group.Prefix[Rank] = Group.Prefix[Rank - 1] + Character.Cps
			table.insert(Pool, { Group = Index, Rank = Rank, Character = Character })
		end
		for OtherIndex, Other in Groups do
			if _CharacterPairs.IsPair({ Name = Group.Name }, { Name = Other.Name }, Definitions)
				and (Index ~= OtherIndex or #Group.Values >= 2) then table.insert(Group.Neighbors, OtherIndex) end
		end
	end
	--[[
		@param Left 左持有實例。
		@param Right 右持有實例。
		@return 全體單角收益順序。
	]]
	table.sort(Pool, function(Left, Right)
		local A, B = Left.Character, Right.Character
		return A.Cps > B.Cps or (A.Cps == B.Cps and (A.Key < B.Key or (A.Key == B.Key and Left.Rank < Right.Rank)))
	end)
	for _, Entry in Pool do
		table.insert(Potential, { Group = Entry.Group, Rank = Entry.Rank, Cps = Entry.Character.Cps * (if #Groups[Entry.Group].Neighbors > 0 then 3 else 1) })
	end
	--[[
		@param Left 左收益上界。
		@param Right 右收益上界。
		@return 可能收益遞減。
	]]
	table.sort(Potential, function(Left, Right)
		return Left.Cps > Right.Cps
	end)
	local MaxLength, MaxLinks = 0, 0
	for Index = 1, #Slots do
		if Index == 1 or not _CharacterPairs.IsAdjacent(Slots[Index - 1], Slots[Index]) then
			table.insert(Rows, { Start = Index, Length = 1 })
		else Rows[#Rows].Length += 1 end
	end
	for _, Row in Rows do MaxLinks += math.floor(Row.Length / 2) MaxLength = math.max(MaxLength, math.min(2, Row.Length)) end
	Work.SingleIncome = 0
	for Index = 1, math.min(#Slots, #Pool) do Work.SingleIncome += Pool[Index].Character.Cps end
	local SliceStarted = os.clock()
	--[[ 在協程內建立區塊並搜尋完整解，計算量達時間片時讓出。 ]]
	Work.Thread = coroutine.create(function()
		--[[
			計算量分片；不以節點數上限截斷完整搜尋。
		]]
		local function Tick(): ()
			Work.Nodes += 1
			if Work.Nodes % 2000 == 0 or (Work.Nodes % 128 == 0 and os.clock() - SliceStarted >= 0.003) then
				coroutine.yield()
				SliceStarted = os.clock()
			end
		end
		local Blocks, SeenBlocks, Path, PathCounts = {}, {}, {}, {}
		--[[
			只列舉兩人有效配對，以名稱數量合併反向與變異排列，拒絕共享中間角色的三人鏈。
			@param GroupIndex 本步名稱索引。
			@param Length 目前路徑長度。
		]]
		local function BuildBlocks(GroupIndex, Length): ()
			Tick()
			Path[Length], PathCounts[GroupIndex] = GroupIndex, (PathCounts[GroupIndex] or 0) + 1
			if Length >= 2 then
				local Parts, Counts, Value = {}, {}, 0
				for Index, Group in Groups do
					local Count = PathCounts[Index] or 0
					if Count > 0 then Parts[#Parts + 1] = Index .. ":" .. Count Counts[Index] = Count Value += 3 * Group.Prefix[Count] end
				end
				local Key = table.concat(Parts, ";")
				if not SeenBlocks[Key] then
					SeenBlocks[Key] = true
					local Sequence = {}
					for Index = 1, Length do Sequence[Index] = Path[Index] end
					table.insert(Blocks, { Length = Length, Counts = Counts, Path = Sequence, Value = Value, Key = Key })
				end
			end
			if Length < MaxLength then
				for _, Other in Groups[GroupIndex].Neighbors do
					if (PathCounts[Other] or 0) < #Groups[Other].Values then BuildBlocks(Other, Length + 1) end
				end
			end
			PathCounts[GroupIndex] -= 1
		end
		for Index, Group in Groups do if #Group.Neighbors > 0 and #Group.Values > 0 then BuildBlocks(Index, 1) end end
		--[[
			@param Left 左配對區塊。
			@param Right 右配對區塊。
			@return 先展開高收益密度，穩定鍵打破平手。
		]]
		table.sort(Blocks, function(Left, Right)
			local A, B = Left.Value / Left.Length, Right.Value / Right.Length
			return A > B or (A == B and Left.Key < Right.Key)
		end)
		Work.BlockCount = #Blocks
		local Used, Demand, Chosen, Memo = {}, { 0, 0, 0, 0, 0 }, {}, {}
		--[[
			檢查兩人配對是否超過同排、連續格位的獨立配對容量；單角填剩餘位置。
			@return true 可以完整放入，不以角色數量取代實際跨排限制。
		]]
		local function CanPack(): boolean
			return Demand[2] <= MaxLinks
		end
		--[[
			依已選配對區塊建立合法實體格位，再用未消耗的最高收益單角填空並回算收益。
		]]
		local function Evaluate(): ()
			local Layout, Remaining, BoostRanks = {}, {}, {}
			for Index = 1, #Slots do Layout[Index] = false end
			for Index, Row in Rows do Remaining[Index] = Row.Length end
			for _, BlockIndex in Chosen do
				local Block, RowIndex = Blocks[BlockIndex], nil
				for Index, Free in Remaining do if Free >= 2 then RowIndex = Index break end end
				assert(RowIndex, "獨立配對容量檢查不一致")
				local Row = Rows[RowIndex]
				local Position = Row.Start + Row.Length - Remaining[RowIndex]
				for Offset, GroupIndex in Block.Path do
					BoostRanks[GroupIndex] = (BoostRanks[GroupIndex] or 0) + 1
					Layout[Position + Offset - 1] = Groups[GroupIndex].Values[BoostRanks[GroupIndex]]
				end
				Remaining[RowIndex] -= 2
			end
			local Position = 1
			for _, Entry in Pool do
				if Entry.Rank <= (Used[Entry.Group] or 0) then continue end
				while Position <= #Slots and Layout[Position] do Position += 1 end
				if Position > #Slots then break end
				Layout[Position], Position = Entry.Character, Position + 1
			end
			local Income, Links = _CharacterPairs.Score(Layout, Slots, Definitions)
			if Income > Work.Income or (Income == Work.Income and Links > Work.Links) then
				Work.Best, Work.Income, Work.Links, Work.bBestObserved = Layout, Income, Links, false
			end
		end
		--[[
			以非遞減區塊索引列舉多重集合，消除單角位置、整排交換與相同配對的排列重算。
			@param Start 最小可用區塊索引。
			@param Filled 已分配給配對的角色數。
			@param Income 已配對角色的收益，不重複乘三。
		]]
		local function Visit(Start, Filled, Income): ()
			Tick()
			local Parts = { tostring(Demand[2]) }
			for Index, Group in Groups do if #Group.Neighbors > 0 then Parts[#Parts + 1] = tostring(Used[Index] or 0) end end
			local Key = table.concat(Parts, ";")
			if Memo[Key] and Memo[Key] <= Start then Work.MemoHits += 1 return end
			Memo[Key] = Start
			Work.States += 1
			Evaluate()
			local Upper, Left = Income, #Slots - Filled
			for _, Entry in Potential do
				if Left == 0 then break end
				if Entry.Rank > (Used[Entry.Group] or 0) then Upper += Entry.Cps Left -= 1 end
			end
			if Upper < Work.Income or (Upper == Work.Income and MaxLinks <= Work.Links) then return end
			for Index = Start, #Blocks do
				local Block = Blocks[Index]
				if Filled + Block.Length > #Slots then continue end
				local bAvailable = true
				for GroupIndex, Count in Block.Counts do if (Used[GroupIndex] or 0) + Count > #Groups[GroupIndex].Values then bAvailable = false break end end
				if not bAvailable then continue end
				Demand[Block.Length] += 1
				if CanPack() then
					local Added = 0
					for GroupIndex, Count in Block.Counts do
						local Before = Used[GroupIndex] or 0
						Used[GroupIndex] = Before + Count
						Added += 3 * (Groups[GroupIndex].Prefix[Before + Count] - Groups[GroupIndex].Prefix[Before])
					end
					table.insert(Chosen, Index)
					Visit(Index, Filled + Block.Length, Income + Added)
					table.remove(Chosen)
					for GroupIndex, Count in Block.Counts do Used[GroupIndex] -= Count end
				end
				Demand[Block.Length] -= 1
			end
		end
		Visit(1, 0, 0)
		Work.Done = true
	end)
	return Work
end

--[[
	取得配對後總收益最高的配置。
	@param Plan 搜尋工作；完成前結果僅為目前最佳。
	@return 要採用的逐格角色配置。
	@return 該配置的配對後預估 CPS。
	@return 該配置的相鄰配對連結數。
]]
function _CharacterPairs.Select(Plan)
	return Plan.Best, Plan.Income, Plan.Links
end
-- PAIR_PLANNER_END

--[[
	使用原生 Box 摘要與批次上限，每輪開啟一種已持有 Box；動畫中等待，不購買 Box。
]]
local function _OpenBoxes(): ()
	if LocalPlayer:GetAttribute("CaseOpening") == true then _Status("bAutoBoxes", "等待開 Box 動畫完成") return end
	local Summary = _Invoke("CaseSummaryGet")
	assert(type(Summary) == "table", "CaseSummaryGet 回應格式已變更")
	local Keys = {}
	for Key, Record in Summary do
		if type(Key) == "string" and type(Record) == "table" and (tonumber(Record.q) or 0) >= 1 then table.insert(Keys, Key) end
	end
	table.sort(Keys)
	if #Keys == 0 then _Status("bAutoBoxes", "目前沒有可開啟的 Box") return end
	local Key = Keys[1]
	for _, Candidate in Keys do if Candidate > _Runtime.LastBoxKey then Key = Candidate break end end
	if not Controller.bAutoBoxes or not _Runtime.bAlive or LocalPlayer:GetAttribute("CaseOpening") == true then return end
	local Batch = math.max(2, math.floor(tonumber(((Constants.Crates or {}).CaseItems or {}).BatchSize) or 5))
	local Count = math.min(Batch, math.floor(tonumber(Summary[Key].q)))
	local Result = _Invoke("CaseOpenRequest", Key, Count)
	_Runtime.LastBoxKey = Key
	assert(type(Result) == "table", "CaseOpenRequest 回應格式已變更")
	_Status("bAutoBoxes", if Result.ok == true then "伺服器已接受開 Box：" .. Key .. " × " .. Count
		else "未開啟：" .. tostring(Result.err or "伺服器未確認"))
end

--[[
	從伺服器工作狀態取得原始角色組鍵。
	@param State 工作狀態。
	@return 原始 groupKey；空職位為空字串。
]]
local function _WorkerStateKey(State): string
	if not State.charName or State.charName == "" then return "" end
	assert(type(State.groupKey) == "string" and State.groupKey ~= "", "工作角色 groupKey 尚未載入")
	return State.groupKey
end

--[[
	依 Wiki 比較一般品質；攤位同品質比較原生變異 Gems 倍率，Dock 不看等級或 CPS。
	@param Record 背包摘要。
	@param Kind Food／Gems／Dock 工作類別；Food 只用於篩選已知角色。
	@return 品質序位；攤位／Dock 的特殊 Exclusive 或未知品質為 nil；Food 僅驗證已知品質。
	@return 同品質比較值。
]]
local function _WorkerRank(Record, Kind: string): (number?, number)
	local Definition = (Constants.Characters or {})[Record.n]
	local Rarity = if type(Record.ra) == "string" and Record.ra ~= "" then Record.ra else (Definition and Definition.Rarity)
	if Rarity == "Exclusive" then return if Kind == "Food" then 0 else nil, 1 end
	for Rank, Name in Constants.RarityOrder or {} do
		if Name == Rarity then
			local Bonus = 1
			if Kind == "Gems" then
				assert(type(Constants.GetTypeGemMultiplier) == "function", "缺少 GetTypeGemMultiplier，無法比較攤位角色")
				Bonus = tonumber(Constants.GetTypeGemMultiplier(Record.ty or "")) or 0
			end
			return Rank, Bonus
		end
	end
	return nil, 0
end

--[[
	只列出玩家地塊已存在且沒有待購買／建造按鈕的工作建築。
	@param Plot 自己的地塊。
	@return 含定義、建築與原生放置提示的清單。
]]
local function _WorkerSites(Plot: Instance)
	local Sites, Purchases, Buttons = {}, Plot:FindFirstChild("Purchases"), Plot:FindFirstChild("UnlockButtons")
	for _, Definition in WORK_SITES do
		local Building = Plot:FindFirstChild(Definition.Name) or (Purchases and Purchases:FindFirstChild(Definition.Name))
		if not Building then continue end
		local bPending = false
		for _, Button in (Buttons and Buttons:GetChildren() or {}) do
			local Structure = _BuildValue(Button, "PurchaseStructure", "StringValue")
			if Structure and Structure:gsub("%s", ""):lower() == Definition.Name:gsub("%s", ""):lower() then bPending = true break end
		end
		if bPending then continue end
		local Anchor = if Definition.Kind == "Food" then Building:FindFirstChild("PROMPT") else Building:FindFirstChild("CharacterPlace", true)
		local Prompt = Anchor and Anchor:FindFirstChildWhichIsA("ProximityPrompt", true)
		if Prompt and tonumber(Prompt:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then
			table.insert(Sites, { Definition = Definition, Building = Building, Prompt = Prompt })
		end
	end
	return Sites
end

--[[
	讀取一個工作建築目前的伺服器指派，Garden 從共用查詢中取 gardenKey。
	@param Site 已存在的工作建築。
	@return 原生指派狀態，空職位為空表。
]]
local function _WorkerState(Site)
	local State = _Invoke(if Site.Definition.Kind == "Food" then "GardenGetFarmingState" else Site.Definition.State)
	assert(type(State) == "table", "工作指派狀態回應格式已變更")
	if Site.Definition.Kind == "Food" then State = State[Site.Definition.Name] or {} end
	assert(type(State) == "table", "Garden 指派狀態格式已變更")
	return State
end

--[[
	保護家中所有已放置角色組；資料未同步時拒絕派工，不用不完整快照選角。
	@param Plot 自己的地塊。
	@return 已放置的完整角色組鍵集合。
]]
function _CharacterPairs.HomeKeys(Plot)
	local Keys = {}
	local Purchases = Plot:FindFirstChild("Purchases")
	for _, Object in Plot:GetDescendants() do
		if (Object:IsA("Folder") and (Object.Parent == Plot or Object.Parent == Purchases) and Object:GetAttribute("HasCharacter") == true)
			or (Object:IsA("Model") and Object:GetAttribute("IsPlacedCharacter") == true) then
			local Name, TypeName, Level = Object:GetAttribute("CharacterName"), Object:GetAttribute("CharacterType"), tonumber(Object:GetAttribute("Level"))
			assert(type(Name) == "string" and Name ~= "" and type(TypeName) == "string" and Level and Level >= 1 and Level < math.huge,
				"家中角色資料未同步，暫停派工以保護已部署角色")
			Keys["C|" .. Name .. "|" .. TypeName .. (if Level >= 2 then "|L" .. tostring(math.floor(Level)) else "")] = true
		end
	end
	return Keys
end

--[[
	沿用各建築已查證的卸任封包，不呼叫角色展台的拿取提示。
	@param Site 自己擁有的工作建築。
	@param State 剛讀取且仍符合預期的工作狀態。
]]
function _CharacterPairs.UnequipWorker(Site, State): ()
	if Site.Definition.Kind == "Food" then _Remote("GardenUnequipChar", "RemoteEvent"):FireServer(Site.Definition.Name)
	elseif Site.Definition.Kind == "Dock" then _Remote(Site.Definition.Unequip, "RemoteEvent"):FireServer()
	else
		assert(type(State.standKey) == "string" and State.standKey ~= "", "攤位 standKey 尚未載入")
		_Remote(Site.Definition.Unequip, "RemoteEvent"):FireServer(State.standKey)
	end
end

--[[
	建立角色摘要指紋，持有量或收益變更時讓派遣先等待家中規劃。
	@param Summary 原生角色摘要；不納入 UUID。
	@return 與順序無關的組鍵、數量與收益指紋。
]]
function _CharacterPairs.InventoryStamp(Summary): string
	local Parts = {}
	for Key, Record in Summary do
		if type(Key) == "string" and Key:sub(1, 2) == "C|" and type(Record) == "table" then
			table.insert(Parts, Key .. ":" .. tostring(Record.c) .. ":" .. tostring(Record.bc))
		end
	end
	table.sort(Parts)
	return table.concat(Parts, "\n")
end

--[[
	保留家中目標組合，換位途中也不能被派遣取用。
	@param Plot 自己的地塊。
	@param Plan 已選擇 Target 的搜尋工作。
	@param bReady true 配置已確認；false 仍在換位。
]]
function _CharacterPairs.ReserveHome(Plot, Plan, bReady: boolean): ()
	local Keys = {}
	for _, Character in Plan.Target do if Character then Keys[Character.Key] = true end end
	_Runtime.HomeReservations = { Plot = Plot, Keys = Keys, SummaryStamp = Plan.SummaryStamp, bReady = bReady }
end

--[[
	記錄尚未開始的派工等待，短暫重試而不消耗完整工作間隔；同步兩處狀態文字。
	@param Reason Home 表示等待家中配置；Busy 或 Loading 表示暫時無法開始操作。
	@param Message 提供使用者的具體等待原因。
]]
function _CharacterPairs.WaitWorkers(Reason: string, Message: string): ()
	_Runtime.WorkerWait = Reason
	_CharacterPairs.WorkerStatus(Message)
end

--[[
	同步派工摘要與詳細狀態，等待、跳過與實際操作均使用相同顯示。
	@param Message 目前派工結果或等待原因。
]]
function _CharacterPairs.WorkerStatus(Message: string): ()
	_Status("bAutoWorkers", Message)
	if _Runtime.WorkerLabel and Message ~= _Runtime.WorkerText then
		_Runtime.WorkerText = Message
		_Runtime.WorkerLabel:Set("派工同步狀態", Message)
	end
end

--[[
	比較角色對目前工作的效果，不把名稱、等級或產錢值當作攤位／Dock 的提升。
	Garden 僅以已量測的產量判斷相等，未知產量不能假裝與現任相同。
	@param Current 現任角色的品質與變異摘要。
	@param Candidate 候選角色摘要。
	@param Kind Gems／Dock／Food 工作類別。
	@param CurrentFood 現任角色已量測的食物產量；缺少表示未知。
	@param CandidateFood 候選已量測的食物產量；缺少表示未知。
	@return true 表示效果已知且相同，應保留現任並跳過此候選。
]]
function _CharacterPairs.WorkerSameEffect(Current, Candidate, Kind: string, CurrentFood: number?, CandidateFood: number?): boolean
	if Kind == "Food" then return CurrentFood ~= nil and CandidateFood ~= nil and CurrentFood == CandidateFood end
	local CurrentRank, CurrentBonus = _WorkerRank(Current, Kind)
	local Rank, Bonus = _WorkerRank(Candidate, Kind)
	return Rank ~= nil and CurrentRank ~= nil and Rank == CurrentRank and Bonus == CurrentBonus
end

--[[
	家中工作釋放執行權後喚醒等待中的派遣；保留一般派工間隔與逾時冷卻。
]]
function _CharacterPairs.WakeWorkers(): ()
	local Reservation, Plan = _Runtime.HomeReservations, _Runtime.CharacterPlan
	if not Controller.bAutoWorkers or _Runtime.WorkerWait ~= "Home" or _Runtime.Jobs.bAutoWorkers
		or _Runtime.Jobs.bAutoCharacters or _Runtime.CharacterApplying or (Plan and not Plan.Done)
		or not Reservation or not Reservation.bReady then return end
	_Runtime.RetryAt.bAutoWorkers = math.max(os.clock(), _Runtime.RetryNotBefore.bAutoWorkers or 0)
	_CharacterPairs.WaitWorkers("Home", "家中配置已確認，準備從剩餘角色派工")
end

--[[
	家中配置優先於派遣；需要重新規劃時喚醒工作，不取消正在進行的搜尋。
	@param Plot 自己的地塊。
	@param Summary 可選的最新背包摘要。
	@return true 可選派遣人選；false 先保留角色給家中。
]]
function _CharacterPairs.WorkersAllowed(Plot, Summary): boolean
	if not Controller.bAutoCharacters then return true end
	local Reservation, Plan = _Runtime.HomeReservations, _Runtime.CharacterPlan
	local bReady = Reservation and Reservation.Plot == Plot and Reservation.bReady and not _Runtime.CharacterApplying
		and not _Runtime.Jobs.bAutoCharacters and (not Plan or Plan.Done)
	if bReady and Summary and Reservation.SummaryStamp ~= _CharacterPairs.InventoryStamp(Summary) then
		Reservation.bReady, bReady = false, false
	end
	if bReady then return true end
	if not _Runtime.Jobs.bAutoCharacters then
		_Runtime.RetryAt.bAutoCharacters = math.min(_Runtime.RetryAt.bAutoCharacters or math.huge, math.max(os.clock(), _Runtime.RetryNotBefore.bAutoCharacters or 0))
	end
	_CharacterPairs.WaitWorkers("Home", "優先計算並部署家中角色，暫停派遣；保留目標角色給家中配置，稍後自動接續派工")
	return false
end

--[[
	沿用原生背包的拿起操作，等待正確角色工具及屬性複寫；不使用展台裝備 Remote。
	@param Key 伺服器摘要的原始角色組鍵。
	@param Humanoid 本輪玩家 Humanoid。
	@return 已確認拿在手上的角色工具；逾時拋錯，首次拿起失敗時不卸下現任工作角色。
]]
local function _HoldWorker(Key: string, Humanoid: Humanoid): Instance
	local Gear = _Runtime.WorkerGear
	assert(Gear and Controller[Gear.Feature or "bAutoWorkers"] and _Runtime.bAlive, "角色配置已停止")
	local Remote = _Remote("BackpackHoldCharacter", "RemoteEvent")
	local Held = LocalPlayer.Character:FindFirstChildOfClass("Tool")
	if Held and _WorkerToolKey(Held) == Key then
		Gear.Tool = Held
		Humanoid:EquipTool(Held)
		return Held
	end
	Gear.bHoldRequested = true
	Remote:FireServer(Key)
	local Deadline = os.clock() + 8
	repeat
		assert(Controller[Gear.Feature or "bAutoWorkers"] and _Runtime.bAlive, "角色配置已停止")
		for _, Container in { LocalPlayer.Character, LocalPlayer:FindFirstChild("Backpack") } do
			if Container then
				for _, Object in Container:GetChildren() do
					if _WorkerToolKey(Object) == Key then
						Gear.Tool = Object
						-- 即使已在 Character 下也要求實際裝備，避免其他 Tool 仍先被原生流程讀到。
						Humanoid:EquipTool(Object)
						if Object.Parent == LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool") == Object then return Object end
					end
				end
			end
		end
		task.wait(0.1)
	until os.clock() >= Deadline
	error("拿起派工角色逾時（BackpackHoldCharacter）：" .. Key .. "；未送出放置")
end

--[[
	等待指定建築的原生放置提示與實際手持工具同步，僅操作自己的空職位，不改寫提示。
	@param Site 目標工作建築；提示可能在卸下角色後重建，故每輪重新查找。
	@param Plot 自己地塊。
	@param Key 本輪候選角色的原始鍵。
	@param Humanoid 本輪 Humanoid，重新裝備被延遲卸下回應切走的候選工具。
	@return 已確認可放置的原生提示；等待逾時或停止時為 nil。
	@return 具體等待原因，供狀態顯示。
]]
local function _WaitWorkerPlace(Site, Plot, Key: string, Humanoid: Humanoid): (ProximityPrompt?, string)
	local Deadline = math.min(os.clock() + 6, (_Runtime.StartedAt.bAutoWorkers or os.clock()) + 18)
	local Reason = "等待原生提示載入"
	repeat
		if not Controller.bAutoWorkers or not _Runtime.bAlive then return nil, "派工已停止" end
		if not Site.Building:IsDescendantOf(Plot) or tonumber(Plot:GetAttribute("OwnerUserId")) ~= LocalPlayer.UserId then
			return nil, "工作建築或地塊所有權已變更"
		end
		local Anchor = if Site.Definition.Kind == "Food" then Site.Building:FindFirstChild("PROMPT") else Site.Building:FindFirstChild("CharacterPlace", true)
		local Prompt = Anchor and Anchor:FindFirstChildWhichIsA("ProximityPrompt", true)
		local Tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Tool")
		local Gear = _Runtime.WorkerGear
		if (not Tool or _WorkerToolKey(Tool) ~= Key) and Gear and Gear.Tool and _WorkerToolKey(Gear.Tool) == Key
			and (Gear.Tool.Parent == LocalPlayer.Character or Gear.Tool.Parent == LocalPlayer:FindFirstChild("Backpack")) then
			Humanoid:EquipTool(Gear.Tool)
			Tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
		end
		if Prompt and tonumber(Prompt:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then
			Site.Prompt = Prompt
			local Point = _PromptPosition(Prompt)
			local Root = _Character()
			local Distance = if Root and Point then (Root.Position - Point).Magnitude else math.huge
			local Limit = tonumber(Prompt:GetAttribute("ServerMaxActivationDistance")) or Prompt.MaxActivationDistance
			local bHeld = Tool ~= nil and _WorkerToolKey(Tool) == Key
			local bPlace = Prompt.ActionText:lower():match("^place%f[%W]") ~= nil or Prompt.ActionText:lower() == "place"
			if bHeld and Prompt.Enabled and bPlace and Distance <= Limit then
				if _WorkerStateKey(_WorkerState(Site)) ~= "" then return nil, Site.Definition.Name .. " 的職位仍有角色，未放置" end
				return Prompt, "已就緒"
			end
			Reason = string.format("%s：提示=%s；啟用=%s；距離=%.1f/%.1f；手持=%s",
				Site.Definition.Name, Prompt.ActionText, tostring(Prompt.Enabled), Distance, Limit, Tool and Tool.Name or "無")
		else Reason = Site.Definition.Name .. "：等待自己的原生放置提示" end
		_Status("bAutoWorkers", "等待派工同步：" .. Site.Definition.Name)
		if _Runtime.WorkerLabel and Reason ~= _Runtime.WorkerText then
			_Runtime.WorkerText = Reason
			_Runtime.WorkerLabel:Set("派工同步狀態", Reason .. "；目標=" .. Key)
		end
		task.wait(0.1)
	until os.clock() >= Deadline
	return nil, Reason .. "；本輪未放置，稍後重試"
end

--[[
	輪流處理已購建築。攤位與 Dock 依品質挑選閒置角色；Garden 逐次試工比較實際產量。
	不抽走展台或其他建築角色；裝備確認且原生提示為 Place 時才放置。
]]
local function _Workers(): ()
	_Runtime.WorkerWait = nil
	assert(type(fireproximityprompt) == "function", "缺少 fireproximityprompt，無法自動派工")
	if _Runtime.CharacterApplying or _Runtime.WorkerGear or _Runtime.bMoving or LocalPlayer:GetAttribute("CaseOpening") == true then
		_CharacterPairs.WaitWorkers("Busy", "等待角色操作或移動結束，稍後自動接續派工") return
	end
	local Root, Humanoid = _Character()
	local Plots = workspace:FindFirstChild("PlayerPlots")
	if not Root or not Plots then _CharacterPairs.WaitWorkers("Loading", "等待玩家與地塊載入後派工") return end
	local Plot = nil
	for _, Candidate in Plots:GetChildren() do if tonumber(Candidate:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then Plot = Candidate break end end
	if not Plot then _CharacterPairs.WaitWorkers("Loading", "等待自己的地塊載入後派工") return end
	local Sites = _WorkerSites(Plot)
	if #Sites == 0 then _Status("bAutoWorkers", "等待已擁有且建造完成的工作建築") return end
	if not _CharacterPairs.WorkersAllowed(Plot) then return end
	_Runtime.WorkerIndex = _Runtime.WorkerIndex % #Sites + 1
	local Site = Sites[_Runtime.WorkerIndex]
	local Summary, Equipped = _Invoke("BackpackCharSummaryGet"), _Invoke("BackpackGetEquippedState")
	assert(type(Summary) == "table" and type(Equipped) == "table" and type(Equipped.equipped) == "table", "派工背包資料未就緒")
	if not _CharacterPairs.WorkersAllowed(Plot, Summary) then return end
	local Protected, Current = {}, nil
	for Key in _CharacterPairs.HomeKeys(Plot) do Protected[Key] = true end
	if Controller.bAutoCharacters and _Runtime.HomeReservations then
		for Key in _Runtime.HomeReservations.Keys do Protected[Key] = true end
	end
	for _, Record in Equipped.equipped do
		if type(Record) == "table" then Protected[Record.key or ("C|" .. tostring(Record.n or "") .. "|" .. tostring(Record.ty or ""))] = true end
	end
	for _, Other in Sites do
		local State = _WorkerState(Other)
		local Key = _WorkerStateKey(State)
		if Other == Site then Current = State elseif Key ~= "" then Protected[Key] = true end
	end
	local CurrentKey = _WorkerStateKey(Current)
	local CurrentRecord = { n = Current and Current.charName, ra = Current and (Current.rarity or Current.charRarity), ty = Current and Current.charType }
	local Scores = _Runtime.WorkerFoodScores[Site.Building] or {}
	_Runtime.WorkerFoodScores[Site.Building] = Scores
	if Site.Definition.Kind == "Food" and CurrentKey ~= "" then
		local Rate = tonumber(Site.Building:GetAttribute("CurrentFoodPerSecond"))
		if not Rate or Rate ~= Rate or Rate < 0 or Rate == math.huge then _Status("bAutoWorkers", "等待 Garden 實際食物產量") return end
		Scores[CurrentKey] = Rate
	end
	local Best, BestRank, BestBonus, BestFood = nil, -math.huge, -math.huge, -math.huge
	if CurrentKey ~= "" then
		BestRank, BestBonus = _WorkerRank(CurrentRecord, Site.Definition.Kind)
		if not BestRank then _Status("bAutoWorkers", "現任角色為特殊或未知品質，保留原指派") return end
		Best, BestFood = CurrentKey, Scores[CurrentKey] or -math.huge
	end
	local Keys = {}
	for Key, Record in Summary do
		if type(Key) == "string" and Key:sub(1, 2) == "C|" and type(Record) == "table" and (tonumber(Record.c) or 0) > 0 and not Protected[Key] then table.insert(Keys, Key) end
	end
	table.sort(Keys)
	for _, Key in Keys do
		local Rank, Bonus = _WorkerRank(Summary[Key], Site.Definition.Kind)
		if not Rank then continue end
		if CurrentKey ~= "" and _CharacterPairs.WorkerSameEffect(CurrentRecord, Summary[Key], Site.Definition.Kind, Scores[CurrentKey], Scores[Key]) then continue end
		if Site.Definition.Kind == "Food" then
			local Rate = Scores[Key]
			if Rate == nil then Best = Key break end
			if Rate > BestFood then Best, BestFood = Key, Rate end
		elseif Rank > BestRank or (Rank == BestRank and Bonus > BestBonus) then Best, BestRank, BestBonus = Key, Rank, Bonus end
	end
	if not Best or Best == CurrentKey then
		_CharacterPairs.WorkerStatus("本輪跳過：派工效果相同或沒有更佳人選，保留現任角色") return
	end
	local Point = _PromptPosition(Site.Prompt)
	if not Point then return end
	if not _Travel("bAutoWorkers", Root, CFrame.new(Point + Vector3.new(0, 2, 2))) then _RestoreMove("bAutoWorkers") return end
	if tonumber(Plot:GetAttribute("OwnerUserId")) ~= LocalPlayer.UserId or not Site.Building:IsDescendantOf(Plot)
		or _WorkerStateKey(_WorkerState(Site)) ~= CurrentKey then _RestoreMove("bAutoWorkers") return end
	if not _CharacterPairs.WorkersAllowed(Plot) or _CharacterPairs.HomeKeys(Plot)[Best]
		or (Controller.bAutoCharacters and _Runtime.HomeReservations and _Runtime.HomeReservations.Keys[Best]) then
		_RestoreMove("bAutoWorkers")
		_Status("bAutoWorkers", "候選角色已部署在家中，保留家中角色並等待下一輪") return
	end
	_Remote("BackpackHoldCharacter", "RemoteEvent")
	if CurrentKey ~= "" then _Remote(if Site.Definition.Kind == "Food" then "GardenUnequipChar" else Site.Definition.Unequip, "RemoteEvent") end
	local Previous = LocalPlayer.Character:FindFirstChildOfClass("Tool")
	_Runtime.WorkerGear = { Previous = Previous, PreviousKey = if Previous then _WorkerToolKey(Previous) else nil, Tool = nil, Key = Best }
	local Tool = _HoldWorker(Best, Humanoid)
	-- 必須先拿到候選角色，再卸下原員工，避免拿起失敗留下空職位。
	if CurrentKey ~= "" then
		_CharacterPairs.UnequipWorker(Site, Current)
		local Deadline = math.min(os.clock() + 3, (_Runtime.StartedAt.bAutoWorkers or os.clock()) + 16)
		repeat
			task.wait(0.2)
			if not Controller.bAutoWorkers or not _Runtime.bAlive then
				_RestoreWorkerGear()
				_RestoreMove("bAutoWorkers") return
			end
			if _WorkerStateKey(_WorkerState(Site)) == "" then break end
		until os.clock() >= Deadline
		if _WorkerStateKey(_WorkerState(Site)) ~= "" then
			_RestoreWorkerGear()
			_RestoreMove("bAutoWorkers")
			_Status("bAutoWorkers", "原角色尚未卸下，保留原職位並等待下一輪") return
		end
	end
	if Tool.Parent ~= LocalPlayer.Character or _WorkerToolKey(Tool) ~= Best then Tool = _HoldWorker(Best, Humanoid) end
	local Prompt, Reason = _WaitWorkerPlace(Site, Plot, Best, Humanoid)
	if not Prompt then
		_RestoreWorkerGear()
		_RestoreMove("bAutoWorkers")
		if _Runtime.WorkerLabel then _Runtime.WorkerLabel:Set("派工同步狀態", Reason) end
		_Status("bAutoWorkers", Reason) return
	end
	fireproximityprompt(Prompt)
	task.wait(0.5)
	local bConfirmed = _WorkerStateKey(_WorkerState(Site)) == Best
	if bConfirmed and _Runtime.WorkerGear.Previous == Tool then _Runtime.WorkerGear.Previous, _Runtime.WorkerGear.PreviousKey = nil, nil end
	_RestoreWorkerGear()
	_RestoreMove("bAutoWorkers")
	if _Runtime.WorkerLabel then _Runtime.WorkerLabel:Set("派工同步狀態", if bConfirmed then "已確認派工：" .. Site.Definition.Name else "已請求放置，等待遊戲確認") end
	_Status("bAutoWorkers", if bConfirmed then "已派工：" .. Site.Definition.Name .. "；Garden 將於下輪比較實際產量"
		else "已請求放置，等待遊戲確認；暫不記錄產量")
end

--[[
	將原生展台名稱轉為同排位置；PAID 是每排第五格，實際操作仍保留原名稱。
	@param Name 原生 StandId，例如 4、5PAID、6。
	@return 數字格位；非展台或不符合已知付費格位時為 nil。
]]
function _CharacterPairs.StandIndex(Name: string): number?
	local Number = tonumber(Name:match("^(%d+)$"))
	if Number then return Number end
	Number = tonumber(Name:match("^(%d+)PAID$"))
	return if Number and Number % 5 == 0 then Number else nil
end

--[[
	記住自己展台的實際位置，找出未載入零件、角色屬性或暫時被串流移除的已知展台。
	@param Plot 自己的地塊；轉生／獻祭或更換地塊時清除位置快取。
	@return 未載入展台的原始名稱；全部已就緒時為 nil，未知位置時使用空字串。
	@return 未載入原因；全部已就緒時為 nil。
]]
function _CharacterPairs.UnloadedStand(Plot): (string?, string?)
	local Epoch = tostring(LocalPlayer:GetAttribute("Rebirths")) .. ":" .. tostring(LocalPlayer:GetAttribute("Sacrifices"))
	local Cache = _Runtime.StandAnchors
	if not Cache or Cache.Plot ~= Plot or Cache.Epoch ~= Epoch then
		Cache = { Plot = Plot, Epoch = Epoch, Positions = {} }
		_Runtime.StandAnchors = Cache
	end
	local Seen, Missing, bSawStand = {}, {}, false
	local Containers = { Plot }
	local Purchases = Plot:FindFirstChild("Purchases")
	if Purchases then table.insert(Containers, Purchases) end
	for _, Container in Containers do
		for _, Stand in Container:GetChildren() do
			if not Stand:IsA("Folder") or not _CharacterPairs.StandIndex(Stand.Name) then continue end
			bSawStand, Seen[Stand.Name] = true, true
			if Stand:GetAttribute("RebirthLocked") == true or Stand:GetAttribute("PaidLocked") == true then
				Cache.Positions[Stand.Name] = nil
				continue
			end
			local Platform = Stand:FindFirstChild("Platform")
			local Anchor = if Platform and Platform:IsA("BasePart") then Platform else Stand:FindFirstChildWhichIsA("BasePart", true)
			if Anchor then Cache.Positions[Stand.Name] = Anchor.CFrame.Position end
			local Level = tonumber(Stand:GetAttribute("Level"))
			if not Platform or (Stand:GetAttribute("HasCharacter") == true
				and (type(Stand:GetAttribute("CharacterName")) ~= "string" or Stand:GetAttribute("CharacterName") == ""
					or not Level or Level < 1 or Level == math.huge)) then
				table.insert(Missing, Stand.Name)
			end
		end
	end
	for Id in Cache.Positions do if not Seen[Id] then table.insert(Missing, Id) end end
	table.sort(Missing)
	if #Missing > 0 then return Missing[1], "展台零件或角色資料尚未載入" end
	if not bSawStand then return "", "展台尚未出現" end
	return nil, nil
end

--[[
	沿用 ButtonsTopTeleport／TutorialClientService 的原生回家入口，等傳送結束及展台資料穩定。
	不依賴 Home 或展台已載入的位置；最多等待十二秒，尚未就緒時保留配置並稍後重試。
	原生傳送不還原成傳送前座標，避免返回遠方後再次卸載家中場景。
	@param Plot 自己的地塊。
	@param Id 原始展台名稱；空字串表示展台尚未出現。
	@param Reason 展台資料或提示缺少的原因。
	@param Kind 可選的原生提示種類；指定時也必須等該提示出現。
	使用範例：
	```lua
	-- 前提：已取得自己的 Plot，UnloadedStand 回報 Id。
	-- _CharacterPairs.LoadStand(Plot, Id, Reason)
	-- 返回後保留現有配置，由下一輪重新讀取展台；不假設傳送請求等於資料就緒。
	```
]]
function _CharacterPairs.LoadStand(Plot, Id: string, Reason: string, Kind: string?): ()
	if not _Runtime.bAlive or not Controller.bAutoCharacters or tonumber(Plot:GetAttribute("OwnerUserId")) ~= LocalPlayer.UserId then return end
	_Runtime.bCharacterContinue = true
	if _Runtime.HomeReservations then _Runtime.HomeReservations.bReady = false end
	if os.clock() < (_Runtime.StandLoadRetryAt or 0) then
		_Status("bAutoCharacters", "等待展台 " .. Id .. " 載入重試；" .. Reason) return
	end
	local Root = _Character()
	if not Root then _Status("bAutoCharacters", "等待角色重生後使用原生傳送回家") return end
	local Play = _G.__TeleportPlayFn
	local Remote = Remotes:FindFirstChild("TeleportRequest")
	if type(Play) ~= "function" and not (Remote and Remote:IsA("RemoteEvent")) then
		_Status("bAutoCharacters", "缺少原生 TeleportRequest 與回家函數；保留配置，等待原生回家入口載入") return
	end
	_Runtime.StandLoadRetryAt = os.clock() + 5
	-- 只取得移動權、開啟渲染及暫停釣魚；實際目的地完全交由遊戲原生傳送處理。
	if not _Travel("bAutoCharacters", Root, Root.CFrame) then
		_RestoreMove("bAutoCharacters") return
	end
	if tonumber(Plot:GetAttribute("OwnerUserId")) ~= LocalPlayer.UserId then _RestoreMove("bAutoCharacters") return end
	_Runtime.Move.bNativeTeleport = true
	_Status("bAutoCharacters", "正在使用遊戲原生傳送回家；" .. Reason)
	local bRequested, RequestError = false, nil
	if type(Play) == "function" then bRequested, RequestError = pcall(Play, "Plot") end
	if not bRequested then
		-- 原生教學也以同一 Remote 作為回家入口的後備；封包只有字串 Plot。
		assert(Remote and Remote:IsA("RemoteEvent"), "缺少原生 TeleportRequest，無法傳送回家：" .. tostring(RequestError or "原生回家函數尚未就緒"))
		Remote:FireServer("Plot")
	end
	local StartedAt, Deadline, ReadyAt, ReadyStamp = os.clock(), os.clock() + 12, nil, nil
	local bReady = false
	while _Runtime.bAlive and Controller.bAutoCharacters and Root.Parent == LocalPlayer.Character
		and tonumber(Plot:GetAttribute("OwnerUserId")) == LocalPlayer.UserId do
		local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
		local Main = PlayerGui and PlayerGui:FindFirstChild("MainGui")
		local Overlay = Main and Main:FindFirstChild("TeleportingGUI")
		local MissingId = _CharacterPairs.UnloadedStand(Plot)
		local bRead, Stands, Slots = pcall(_CharacterPairs.ReadPlot, Plot)
		local Purchases = Plot:FindFirstChild("Purchases")
		local Loaded = Plot:FindFirstChild(Id) or (Purchases and Purchases:FindFirstChild(Id))
		local bDataReady = not MissingId and bRead and #Slots > 0
			and (Kind == nil or (Loaded ~= nil and _CharacterPairs.Prompt(Loaded, Kind) ~= nil))
		if bDataReady and (not Overlay or not Overlay.Visible) and os.clock() - StartedAt >= 1.2 then
			local Parts = {}
			for _, Entry in Stands do
				local Stand = Entry.Object
				table.insert(Parts, Stand.Name .. ":" .. tostring(Stand:GetAttribute("HasCharacter")) .. ":"
					.. tostring(Stand:GetAttribute("CharacterName")) .. ":" .. tostring(Stand:GetAttribute("CharacterType"))
					.. ":" .. tostring(Stand:GetAttribute("Level")))
			end
			local Stamp = table.concat(Parts, "|")
			if Stamp ~= ReadyStamp then ReadyAt, ReadyStamp = os.clock(), Stamp end
			if ReadyAt and os.clock() - ReadyAt >= 0.4 then bReady = true break end
		else ReadyAt, ReadyStamp = nil, nil end
		if os.clock() >= Deadline then break end
		_Status("bAutoCharacters", if Overlay and Overlay.Visible then "原生傳送回家中，等待傳送畫面結束"
			else "已請求原生回家，等待展台零件、角色資料與提示載入完成")
		task.wait(0.1)
	end
	if _Runtime.bAlive and Controller.bAutoCharacters then
		_Status("bAutoCharacters", if bReady then "原生回家與展台載入已完成，繼續核對配置"
			else "原生回家後展台仍未載入完成；保留現有配置，稍後重試")
	end
	_RestoreMove("bAutoCharacters")
	_Runtime.StandLoadRetryAt = os.clock() + 5
end

--[[
	讀取自己的直屬及已購建築展台，按實際格位排序，從原生角色定義重建配對前收益。
	@param Plot 自己的地塊；不讀取尚未購買的按鈕或其他玩家展台。
	@return 包含原生物件與數字格位的展台清單。
	@return 解鎖格位，供同排相鄰判斷使用。
	@return 逐格角色資料；空格以 false 表示，收益未知時拋錯並保留原配置。
]]
function _CharacterPairs.ReadPlot(Plot)
	local Stands, Slots, Current = {}, {}, {}
	-- 原生 StandPromptController 同時掃描地塊直屬與 Purchases；升級展台位於後者。
	local Containers = { Plot }
	local Purchases = Plot:FindFirstChild("Purchases")
	if Purchases then table.insert(Containers, Purchases) end
	for _, Container in Containers do
		for _, Stand in Container:GetChildren() do
			local Index = _CharacterPairs.StandIndex(Stand.Name)
			if not Index or not Stand:IsA("Folder") then continue end
			if Stand:GetAttribute("RebirthLocked") == true or Stand:GetAttribute("PaidLocked") == true then continue end
			assert(Stand:FindFirstChild("Platform"), "展台 " .. Stand.Name .. " 的 Platform 尚未載入")
			table.insert(Stands, { Index = Index, Object = Stand })
		end
	end
	table.sort(Stands, function(Left, Right)
		--[[ @param Left 左展台。 @param Right 右展台。 @return 實際編號遞增。 ]]
		return Left.Index < Right.Index
	end)
	for Index, Entry in Stands do
		assert(Index == 1 or Stands[Index - 1].Index ~= Entry.Index, "同一位置有重複展台，等待地塊同步：" .. Entry.Object.Name)
		Slots[Index], Current[Index] = Entry.Index, false
		local Stand = Entry.Object
		if Stand:GetAttribute("HasCharacter") ~= true then continue end
		local Name, TypeName = Stand:GetAttribute("CharacterName"), Stand:GetAttribute("CharacterType") or ""
		local Level = tonumber(Stand:GetAttribute("Level"))
		assert(type(Name) == "string" and Name ~= "" and Level and Level >= 1 and Level < math.huge,
			"展台 " .. Stand.Name .. " 的角色名稱或等級尚未同步，等待後繼續配置")
		local Base = tonumber(((Constants.Characters or {})[Name] or {}).CPS)
		assert(Base and Base > 0 and Level and type(Constants.GetCpsCurveMultiplier) == "function", "展台角色的原始收益未知，保留配置：" .. tostring(Name))
		-- CPS 可能已帶配對加成，從原生等級曲線與變異還原，避免重複乘三。
		local Multiplier = tonumber(((Constants.TypeSystem or {}).Multipliers or {})[TypeName])
		assert(TypeName == "" or Multiplier, "未知角色變異：" .. tostring(TypeName))
		local Cps = math.floor(Base * math.max(1, Multiplier or 1) * Constants.GetCpsCurveMultiplier(Level) + 0.5)
		assert(Cps == Cps and Cps > 0 and Cps < math.huge, "角色收益尚未載入")
		local Key = "C|" .. Name .. "|" .. TypeName .. (if Level >= 2 then "|L" .. tostring(math.floor(Level)) else "")
		Current[Index] = { Key = Key, Name = Name, TypeName = TypeName, Rarity = Stand:GetAttribute("Rarity"), Cps = Cps, Count = 1,
			PairMultiplier = tonumber(Stand:GetAttribute("_ComboMultiplier")) or 1 }
	end
	-- 原生特殊技能會改變整排或特定角色收益；缺少伺服器模型時不假裝可比較。
	for _, Object in Plot:GetDescendants() do
		if Object:GetAttribute("IsPlacedCharacter") == true then
			for _, Attribute in { "RowBoostMult", "LoveBoostMult", "DraculizedMult" } do
				assert((tonumber(Object:GetAttribute(Attribute)) or 1) <= 1, "特殊產錢技能生效中，暫保留原配置：" .. Attribute)
			end
			assert(Object:GetAttribute("Exefied") ~= true, "EXEFIED 角色生效中，暫保留原配置")
		end
	end
	return Stands, Slots, Current
end

--[[ @param Stand 指定的原生展台。 @param Kind 原生 PromptType。 @return 對應提示，未載入為 nil。 ]]
function _CharacterPairs.Prompt(Stand, Kind: string)
	for _, Object in Stand:GetDescendants() do
		if Object:IsA("ProximityPrompt") and Object:GetAttribute("PromptType") == Kind
			and tostring(Object:GetAttribute("StandId")) == Stand.Name then return Object end
	end
	return nil
end

--[[ @param Text 完整的計算／換位狀態，放在同張角色 Card。 ]]
function _CharacterPairs.Show(Text: string): ()
	if _Runtime.PairLabel then _Runtime.PairLabel:Set("配對收益與配置", Text) end
end

--[[
	保存不含 Instance 或協程的搜尋快照，換位完成後仍可診斷最後一次結果。
	@param Plan 當前搜尋工作。
	@return 可供 JSON 編碼的搜尋資料。
]]
function _CharacterPairs.DebugPlan(Plan)
	local Workers = {}
	for _, Assignment in Plan.Workers or {} do
		table.insert(Workers, { Site = Assignment.Site.Definition.Name, Key = Assignment.Key, Character = Assignment.Character, bReleased = Assignment.bReleased == true, bSkipped = Assignment.bSkipped == true })
	end
	return { Done = Plan.Done, Nodes = Plan.Nodes, Slots = Plan.Slots, Before = Plan.Before, BeforeLinks = Plan.BeforeLinks,
		Algorithm = Plan.Algorithm, bBestObserved = Plan.bBestObserved, States = Plan.States, BlockCount = Plan.BlockCount, MemoHits = Plan.MemoHits,
		Income = Plan.Income, Links = Plan.Links, SingleIncome = Plan.SingleIncome, UnknownCount = Plan.UnknownCount,
		Best = table.clone(Plan.Best), Target = Plan.Target and table.clone(Plan.Target), Candidates = Plan.DebugCandidates,
		Signature = Plan.Signature, Workers = Workers, CapturedAt = os.clock() }
end

--[[
	產生唯讀角色診斷文字；個別區段失敗時保留其他資料，不移動或重新計算配置。
	@return 含原始背包、展台、收益定義、配對與搜尋快照的完整文字。
	使用範例：
	```lua
	-- 僅由使用者按下複製按鈕時執行；背包查詢可能讓出。
	local Report = _CharacterPairs.DebugReport()
	```
]]
function _CharacterPairs.DebugReport(): string
	local Lines, Names = { "FishAnAnimeRNG Character Debug v2", "Time=" .. tostring(os.time()),
		"PlaceId=" .. tostring(game.PlaceId), "Model=base CPS + disjoint same-row adjacent pairs 3x; current uses observed multipliers",
		"AutoEquip=" .. tostring(Controller.bAutoCharacters), "Applying=" .. tostring(_Runtime.CharacterApplying),
		"Moving=" .. tostring(_Runtime.bMoving), "Interval=" .. tostring(Controller.Intervals.bAutoCharacters) }, {}
	local Json = game:GetService("HttpService")
	--[[
		輸出命名區段；無法編碼的欄位改記錄型別與錯誤，不省略整份報告。
		@param Title 區段標題。
		@param Values 欄位對照。
	]]
	local function Section(Title, Values)
		table.insert(Lines, "\n[" .. Title .. "]")
		local Keys = {}
		for Key in Values do table.insert(Keys, Key) end
		table.sort(Keys, function(Left, Right)
			--[[ @param Left 左欄位。 @param Right 右欄位。 @return 固定文字順序。 ]]
			return tostring(Left) < tostring(Right)
		end)
		for _, Key in Keys do
			local bOk, Encoded = pcall(Json.JSONEncode, Json, Values[Key])
			table.insert(Lines, tostring(Key) .. "=" .. (if bOk then Encoded else "<" .. typeof(Values[Key]) .. "> " .. tostring(Values[Key]) .. " (encode error: " .. tostring(Encoded) .. ")"))
		end
	end
	Section("Status", { Text = _Runtime.Labels.bAutoCharacters:Get(), FeedMode = Controller.FeedMode, FeedAction = Controller.FeedAction,
		AutoFeed = Controller.bAutoFeed, AutoWorkers = Controller.bAutoWorkers, AutoSell = Controller.bAutoSellCharacters })
	local PlayerEffects = {}
	local Reservation = _Runtime.HomeReservations
	Section("Home role reservations", { bReady = Reservation ~= nil and Reservation.bReady == true,
		Keys = Reservation and Reservation.Keys or {}, SummaryStamp = Reservation and Reservation.SummaryStamp or "" })
	for Key, Value in LocalPlayer:GetAttributes() do
		local Lower = Key:lower()
		if Key:sub(1, 4) == "Rsh_" or Lower:find("cps", 1, true) or Lower:find("cash", 1, true)
			or Lower:find("income", 1, true) or Lower:find("boost", 1, true) or Lower:find("rebirth", 1, true) then PlayerEffects[Key] = Value end
	end
	Section("Player income attributes", PlayerEffects)
	-- 在查詢讓出之前保存搜尋結果，避免完成或取消後失去當時的配置。
	local Plan = _Runtime.CharacterPlan
	Section("Search", if Plan then _CharacterPairs.DebugPlan(Plan) else _Runtime.CharacterDebugLast or { State = "No search snapshot yet" })
	local bSummary, Summary = pcall(_Invoke, "BackpackCharSummaryGet")
	Section("BackpackCharSummaryGet", if bSummary and type(Summary) == "table" then Summary else { Error = tostring(Summary) })
	if bSummary and type(Summary) == "table" then
		for _, Record in Summary do if type(Record) == "table" and type(Record.n) == "string" then Names[Record.n] = true end end
	end
	local Plot, Plots = nil, workspace:FindFirstChild("PlayerPlots")
	for _, Candidate in (Plots and Plots:GetChildren()) or {} do
		if tonumber(Candidate:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then Plot = Candidate break end
	end
	if Plot then
		for _, Object in Plot:GetDescendants() do
			if (Object:IsA("Folder") and _CharacterPairs.StandIndex(Object.Name) and Object:FindFirstChild("Platform"))
				or Object:GetAttribute("IsPlacedCharacter") == true then
				local Attributes = Object:GetAttributes()
				Attributes.OwnerUserId = nil
				if Object:IsA("Folder") then
					Attributes.DebugSource = if Object.Parent == Plot then "Plot" elseif Object.Parent == Plot:FindFirstChild("Purchases") then "Purchases" else "Other"
					Attributes.DebugSlot = _CharacterPairs.StandIndex(Object.Name)
				end
				if type(Attributes.CharacterName) == "string" then Names[Attributes.CharacterName] = true end
				Section((if Object:IsA("Folder") then "Stand " .. Object.Name else "PlacedCharacter " .. tostring(Attributes.StandId)) , Attributes)
			end
		end
		local bRead, Stands, Slots, Current = pcall(_CharacterPairs.ReadPlot, Plot)
		if bRead then
			local Placed = {}
			for _, Value in Current do if Value then table.insert(Placed, Value) end end
			local Definitions, Edges = _CharacterPairs.Snapshot(Placed, Constants.Characters or {})
			local Income, Links = _CharacterPairs.Score(Current, Slots, Definitions, true)
			local StandIds = {}
			for Index, Entry in Stands do StandIds[Index] = Entry.Object.Name end
			Section("Current reconstructed", { Slots = Slots, StandIds = StandIds, Layout = Current, Income = Income, Links = Links, PairEdges = Edges })
		else Section("Current reconstructed", { Error = tostring(Stands) }) end
	else Section("Plot", { Error = "Own plot not loaded" }) end
	for _, Container in { LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character } do
		if not Container then continue end
		for _, Tool in Container:GetChildren() do
			if not Tool:IsA("Tool") or Tool:GetAttribute("IsCharacterTool") ~= true then continue end
			local Attributes = Tool:GetAttributes()
			Attributes.OwnerUserId = nil
			if type(Attributes.CharacterName) == "string" then Names[Attributes.CharacterName] = true end
			Section("Tool " .. Tool.Name, Attributes)
		end
	end
	local Candidates = {}
	for Name in Names do
		table.insert(Candidates, { Name = Name })
		Section("Definition " .. Name, (Constants.Characters or {})[Name] or { Error = "Missing definition" })
	end
	local _, Edges = _CharacterPairs.Snapshot(Candidates, Constants.Characters or {})
	Section("Pair model", { Edges = Edges, HtmlPairs = _CharacterPairs.HTML_PAIRS, TypeMultipliers = (Constants.TypeSystem or {}).Multipliers or {} })
	table.insert(Lines, "\nEND FishAnAnimeRNG Character Debug")
	return table.concat(Lines, "\n")
end

--[[
	按需收集並複製診斷，不修改自動裝備開關或觸發換位；卸載時取消尚未完成的工作。
]]
function _CharacterPairs.CopyDebug(): ()
	if not _Runtime.bAlive or _Runtime.CharacterDebugJob then return end
	local Copy = nil
	for _, Candidate in { Environment.setclipboard, setclipboard, Environment.toclipboard, toclipboard } do
		if type(Candidate) == "function" then Copy = Candidate break end
	end
	if type(Copy) ~= "function" then _Runtime.CharacterDebugLabel:Set("Debug 複製狀態", "無法複製：Executor 缺少 setclipboard／toclipboard") return end
	_Runtime.CharacterDebugLabel:Set("Debug 複製狀態", "正在收集角色與搜尋資料…")
	_Runtime.CharacterDebugStartedAt = os.clock()
	--[[
		隔離診斷讀取與剪貼簿錯誤；成功後顯示完整文字長度。
	]]
	_Runtime.CharacterDebugJob = task.defer(function()
		local bOk, Report = pcall(_CharacterPairs.DebugReport)
		if not _Runtime.bAlive then return end
		local bCopied, Reason = false, Report
		if bOk then bCopied, Reason = pcall(Copy, Report) end
		_Runtime.CharacterDebugLabel:Set("Debug 複製狀態", if bOk and bCopied then "已複製 Debug 資訊（" .. #Report .. " bytes），請完整貼回對話" else "複製失敗：" .. tostring(Reason))
		_Runtime.CharacterDebugJob = nil
	end)
end

--[[
	更新同卡搜尋結果，不把未完成搜尋的連結數稱為已證明上限。
	@param Plan 正在計算或已完成的配對工作。
]]
function _CharacterPairs.Render(Plan): ()
	_Runtime.CharacterDebugLast = _CharacterPairs.DebugPlan(Plan)
	local Layout, Income, Links = _CharacterPairs.Select(Plan)
	local Lines = { "配置條件：配對後總收益最大化（HTML 58 組＋原生配對資料）",
		string.format("目前：%.6g CPS；採用方案：%.6g CPS；增減：%+.6g CPS", Plan.Before, Income, Income - Plan.Before),
		string.format("單角排序基準：%.6g CPS；相鄰連結：%d；搜尋%s：%d 節點", Plan.SingleIncome, Links,
			if Plan.Done then "已完成" else "中", Plan.Nodes),
		string.format("配對區塊：%d；區塊狀態：%d；等價狀態合併：%d", Plan.BlockCount or 0, Plan.States or 0, Plan.MemoHits or 0),
		"數值為角色本體＋配對預估，不含全玩家收益倍率；每隻角色只能佔用一組配對。",
		"略過未知／動態基礎收益的背包角色組：" .. tostring(Plan.UnknownCount or 0),
		"搜尋期間連續計算；間隔設定於本輪計算與配置完成後才開始等待。" }
	for Index, Character in Layout do Lines[#Lines + 1] = tostring(Plan.Slots[Index]) .. "：" .. (Character and Character.Key or "空") end
	local _, _, EffectivePairs = _CharacterPairs.Score(Layout, Plan.Slots, Plan.Definitions, Plan.bBestObserved)
	for _, Pair in EffectivePairs do
		local Left, Right = Pair[1], Pair[2]
		Lines[#Lines + 1] = string.format("已選配對：%s ↔ %s；展台 %d／%d（相鄰，獨立配對）", Layout[Left].Name, Layout[Right].Name,
			Plan.Slots[Left], Plan.Slots[Right])
	end
	_CharacterPairs.Show(table.concat(Lines, "\n"))
end

--[[
	連續推進短時間片，每片後讓出給其他功能；完成後下一次排程重新查證背包及展台。
	@param Plan 保留協程、搜尋快取與最佳解的同一份工作。
]]
function _CharacterPairs.Advance(Plan): ()
	_Runtime.bCharacterContinue = true
	for Slice = 1, 24 do
		if not Controller.bAutoCharacters or not _Runtime.bAlive then return end
		local bOk, Reason = coroutine.resume(Plan.Thread)
		assert(bOk, Reason)
		_CharacterPairs.Render(Plan)
		if Plan.Done then
			_Status("bAutoCharacters", "配對計算完成，正在重新核對背包與展台")
			return
		end
		_Status("bAutoCharacters", "正在連續計算配對收益：" .. tostring(Plan.Nodes) .. " 節點")
		task.wait(0.03)
	end
end

--[[
	依已確認的目標逐格換位；實際換位期間暫停餵食。
	@param Plot 自己地塊。
	@param Stands 已開放展台。
	@param Current 現況。
	@param Plan 已完成的配置搜尋工作，含需要召回的原生工作角色與每組數量。
]]
function _CharacterPairs.Apply(Plot, Stands, Current, Plan): ()
	local bRenderingReady, RenderingReason = _Performance.SyncRendering()
	assert(bRenderingReady, "無法準備角色配置渲染：" .. tostring(RenderingReason))
	if Plan.Observed then
		for Index = 1, #Stands do
			local Key = Current[Index] and Current[Index].Key or ""
			local Pending = Plan.Pending
			if Key ~= Plan.Observed[Index] and not (Pending and Pending.Index == Index and Key == Pending.After) then
				_Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil
				_Status("bAutoCharacters", "展台已被其他操作變更，下輪重新計算") return
			end
		end
	end
	Plan.Observed = {}
	for Index = 1, #Stands do Plan.Observed[Index] = Current[Index] and Current[Index].Key or "" end
	Plan.Pending = nil
	-- 先收回目標配置需要的工作角色，確認卸任成功後才動到家中現況。
	if not Plan.WorkerNeed then
		Plan.WorkerNeed = {}
		for _, Character in Plan.Target do if Character then Plan.WorkerNeed[Character.Key] = (Plan.WorkerNeed[Character.Key] or 0) + 1 end end
		for _, Character in Current do if Character then Plan.WorkerNeed[Character.Key] = math.max(0, (Plan.WorkerNeed[Character.Key] or 0) - 1) end end
	end
	for _, Assignment in Plan.Workers or {} do
		if Assignment.bReleased or Assignment.bSkipped then continue end
		local Needed = Plan.WorkerNeed[Assignment.Key] or 0
		if Needed == 0 then Assignment.bSkipped = true continue end
		local Site = Assignment.Site
		local State = _WorkerState(Site)
		local Key = _WorkerStateKey(State)
		if Key == "" then Assignment.bReleased = true Plan.WorkerNeed[Assignment.Key] = Needed - 1 continue end
		if Key ~= Assignment.Key or not Site.Building:IsDescendantOf(Plot) then
			_Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil
			_Status("bAutoCharacters", "工作指派已變更，下輪重新計算") return
		end
		local Root = _Character()
		local Point = _PromptPosition(Site.Prompt)
		if not Root or not Point then _Status("bAutoCharacters", "等待工作角色召回位置載入") return end
		if not _Travel("bAutoCharacters", Root, CFrame.new(Point + Vector3.new(0, 2, 2))) then _RestoreMove("bAutoCharacters") return end
		assert(tonumber(Plot:GetAttribute("OwnerUserId")) == LocalPlayer.UserId and _WorkerStateKey(_WorkerState(Site)) == Assignment.Key, "工作指派或地塊擁有者已變更")
		_CharacterPairs.UnequipWorker(Site, State)
		local Deadline = os.clock() + 3
		repeat
			task.wait(0.2)
			assert(_Runtime.bAlive and Controller.bAutoCharacters, "角色配置已停止")
			local Actual = _WorkerStateKey(_WorkerState(Site))
			if Actual == "" then Assignment.bReleased = true Plan.WorkerNeed[Assignment.Key] = Needed - 1 break end
			assert(Actual == Assignment.Key, "召回期間工作角色已變更")
		until os.clock() >= Deadline
		_RestoreMove("bAutoCharacters")
		if not Assignment.bReleased then
			_Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil
			_Status("bAutoCharacters", "工作角色未確認卸任，保留家中配置並等待下一輪")
		else _Status("bAutoCharacters", "已召回工作角色：" .. Assignment.Character.Name .. "，接續部署在家中") end
		return
	end
	-- 名稱與格位相同仍可能沿用舊夥伴；現場顯示有配對但目標成員未加成時，整排重放一次。
	if not Plan.bPairResetChecked then
		local bSame = true
		for Index = 1, #Stands do
			if (Current[Index] and Current[Index].Key or "") ~= (Plan.Target[Index] and Plan.Target[Index].Key or "") then bSame = false break end
		end
		if bSame then
			Plan.bPairResetChecked, Plan.PairReset = true, {}
			local KnownRows, ResetRows = {}, {}
			for Index, Character in Current do
				if Character and (Character.PairMultiplier or 1) > 1 then KnownRows[math.ceil(Plan.Slots[Index] / 5)] = true end
			end
			local _, _, Pairs = _CharacterPairs.Score(Plan.Target, Plan.Slots, Plan.Definitions)
			for _, Pair in Pairs do
				for _, Index in Pair do
					local Row = math.ceil(Plan.Slots[Index] / 5)
					if KnownRows[Row] and (Current[Index].PairMultiplier or 1) < 3 then ResetRows[Row] = true end
				end
			end
			for Index, Character in Current do if Character and ResetRows[math.ceil(Plan.Slots[Index] / 5)] then Plan.PairReset[Index] = true end end
		end
	end
	for Index in Plan.PairReset or {} do if not Current[Index] then Plan.PairReset[Index] = nil end end
	local Target, Kind, Desired, RemovedKey
	-- 需要的工作角色已確認召回後，才將不符目標的家中角色拿回背包並逐格放入；不出售角色。
	for Index, Entry in Stands do
		local Actual, Expected = Current[Index], Plan.Target[Index]
		if Actual and (not Expected or Actual.Key ~= Expected.Key or (Plan.PairReset and Plan.PairReset[Index])) then
			Target, Kind, RemovedKey = Entry.Object, "PickupOwner", Actual.Key break
		end
	end
	if not Target then
		for Index, Entry in Stands do
			if not Current[Index] and Plan.Target[Index] then Target, Kind, Desired = Entry.Object, "Place", Plan.Target[Index] break end
		end
	end
	if not Target then
		_Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil
		_CharacterPairs.ReserveHome(Plot, Plan, true)
		_Status("bAutoCharacters", "配置完成；已確認展台角色與相鄰位置")
		return
	end
	assert(type(fireproximityprompt) == "function", "缺少 fireproximityprompt，無法調整配對位置")
	_Remote("BackpackHoldCharacter", "RemoteEvent")
	local Root, Humanoid = _Character()
	if not Root then return end
	local Prompt = _CharacterPairs.Prompt(Target, Kind)
	local Point = Prompt and _PromptPosition(Prompt)
	if not Point then _CharacterPairs.LoadStand(Plot, Target.Name, "原生 " .. Kind .. " 提示尚未載入", Kind) return end
	if not _Travel("bAutoCharacters", Root, CFrame.new(Point + Vector3.new(0, 2, 2))) then _RestoreMove("bAutoCharacters") return end
	local Previous = LocalPlayer.Character:FindFirstChildOfClass("Tool")
	_Runtime.WorkerGear = { Feature = "bAutoCharacters", Previous = Previous,
		PreviousKey = Previous and _WorkerToolKey(Previous), Key = if Desired then Desired.Key else RemovedKey }
	local Tool
	if Desired then Tool = _HoldWorker(Desired.Key, Humanoid) end
	local Deadline, bRequested = os.clock() + 3, false
	repeat
		assert(Controller.bAutoCharacters and _Runtime.bAlive, "角色配置已停止")
		assert(Target:IsDescendantOf(Plot) and tonumber(Plot:GetAttribute("OwnerUserId")) == LocalPlayer.UserId
			and Target:GetAttribute("RebirthLocked") ~= true and Target:GetAttribute("PaidLocked") ~= true, "地塊或展台狀態已改變")
		Prompt = _CharacterPairs.Prompt(Target, Kind)
		local Position = Prompt and _PromptPosition(Prompt)
		if Prompt and Position and Prompt.Enabled and Prompt:GetAttribute("ServerEnabled") == true
			and (Root.Position - Position).Magnitude <= math.min(Prompt.MaxActivationDistance, tonumber(Prompt:GetAttribute("ServerMaxActivationDistance")) or 6)
			and ((Kind == "Place" and Target:GetAttribute("HasCharacter") ~= true and Tool
				and LocalPlayer.Character:FindFirstChildOfClass("Tool") == Tool and _WorkerToolKey(Tool) == Desired.Key
				and Prompt.ActionText:lower():match("^place%f[%W]"))
				or (Kind == "PickupOwner" and Target:GetAttribute("HasCharacter") == true)) then
			fireproximityprompt(Prompt)
			for Index, Entry in Stands do
				if Entry.Object == Target then Plan.Pending = { Index = Index, After = if Desired then Desired.Key else "" } break end
			end
			bRequested = true
			break
		end
		task.wait(0.1)
	until os.clock() >= Deadline
	if bRequested then
		Deadline = os.clock() + 3
		repeat
			task.wait(0.1)
			assert(Controller.bAutoCharacters and _Runtime.bAlive, "角色配置已停止")
			-- 屬性分批複寫時 HasCharacter 可能先於名稱／等級抵達；不能因此丟棄整份換位計畫。
			local bRead, _, _, Updated = pcall(_CharacterPairs.ReadPlot, Plot)
			if not bRead then continue end
			local bConfirmed = false
			for Index, Entry in Stands do
				if Entry.Object == Target then
					bConfirmed = if Kind == "PickupOwner" then not Updated[Index] else Updated[Index] and Updated[Index].Key == Desired.Key
					break
				end
			end
			if bConfirmed then break end
		until os.clock() >= Deadline
	end
	_RestoreWorkerGear()
	_RestoreMove("bAutoCharacters")
	_Status("bAutoCharacters", if bRequested then "等待展台同步，下一輪重新核對：" .. Target.Name else "展台提示尚未就緒，下輪重試：" .. Target.Name)
end

--[[
	以 HTML 完整配對表、原生配對資料與持有量搜尋配對後總收益最高的配置並換位。
	只完成搜尋後才換位；任何未知收益、特殊技能或資料改變時保留目前角色。
]]
local function _EquipCharacters(): ()
	_Runtime.bCharacterContinue = _Runtime.CharacterPlan ~= nil
	if _Runtime.bMoving or _Runtime.WorkerGear or LocalPlayer:GetAttribute("CaseOpening") == true then return end
	local Pending = _Runtime.CharacterPlan
	local Plots, Plot = workspace:FindFirstChild("PlayerPlots"), nil
	if not Plots then return end
	for _, Candidate in Plots:GetChildren() do if tonumber(Candidate:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then Plot = Candidate break end end
	if not Plot then _Status("bAutoCharacters", "等待自己的地塊載入") return end
	local MissingId, LoadReason = _CharacterPairs.UnloadedStand(Plot)
	if MissingId then _CharacterPairs.LoadStand(Plot, MissingId, LoadReason) return end
	if Pending and not Pending.Done then _CharacterPairs.Advance(Pending) return end
	local bRead, Stands, Slots, Current = pcall(_CharacterPairs.ReadPlot, Plot)
	if not bRead then
		-- 保留 Pending／Observed／家中角色保留名單；資料完整前不重新搜尋或操作其他格。
		_Status("bAutoCharacters", tostring(Stands))
		return
	end
	if #Slots == 0 then _Status("bAutoCharacters", "等待已解鎖展台載入") return end
	local Plan = _Runtime.CharacterPlan
	if _Runtime.CharacterApplying then
		if not Plan or Plan.Plot ~= Plot or #Plan.Slots ~= #Slots then _Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil return end
		for Index, Slot in Slots do if Slot ~= Plan.Slots[Index] then _Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil return end end
		_CharacterPairs.Apply(Plot, Stands, Current, Plan)
		_Runtime.bCharacterContinue = _Runtime.CharacterApplying == true
		return
	end
	local Summary = _Invoke("BackpackCharSummaryGet")
	assert(type(Summary) == "table", "背包角色摘要尚未就緒")
	if not Controller.bAutoCharacters then return end
	local Groups, Counts, Parts, UnknownCount = {}, {}, {}, 0
	local Workers = {}
	for _, Site in _WorkerSites(Plot) do
		local State = _WorkerState(Site)
		local Key = _WorkerStateKey(State)
		if Key == "" then continue end
		local Name, TypeName = Key:match("^C|([^|]+)|([^|]*)")
		local Level = tonumber(Key:match("|L(%d+)$")) or 1
		local Definition = Name and (Constants.Characters or {})[Name]
		local Base = Definition and tonumber(Definition.CPS)
		local Multiplier = if TypeName == "" then 1 else tonumber(((Constants.TypeSystem or {}).Multipliers or {})[TypeName])
		local Expected = Name and TypeName and ("C|" .. Name .. "|" .. TypeName .. (if Level >= 2 then "|L" .. tostring(Level) else ""))
		if Key ~= Expected or Name ~= State.charName or (State.charType ~= nil and State.charType ~= TypeName)
			or not Base or Base <= 0 or not Multiplier or type(Constants.GetCpsCurveMultiplier) ~= "function" then UnknownCount += 1 continue end
		local Cps = math.floor(Base * math.max(1, Multiplier) * Constants.GetCpsCurveMultiplier(Level) + 0.5)
		if Cps ~= Cps or Cps <= 0 or Cps == math.huge then UnknownCount += 1 continue end
		local Character = { Key = Key, Name = Name, TypeName = TypeName, Rarity = State.rarity or State.charRarity or Definition.Rarity, Cps = Cps, Count = 1 }
		table.insert(Workers, { Key = Key, Site = Site, Character = Character })
		Parts[#Parts + 1] = "Worker:" .. Site.Definition.Name .. "=" .. Key .. ":" .. tostring(Cps)
	end
	for Key, Record in Summary do
		if type(Key) ~= "string" or Key:sub(1, 2) ~= "C|" or type(Record) ~= "table" then continue end
		local Count, Cps = tonumber(Record.c), tonumber(Record.bc)
		if not Count or Count <= 0 then continue end
		local Base = tonumber(((Constants.Characters or {})[Record.n] or {}).CPS)
		if not Base or Base <= 0 then UnknownCount += 1 continue end
		assert(Cps and Cps == Cps and Cps > 0 and Cps < math.huge and type(Record.n) == "string", "背包角色收益尚未載入：" .. Key)
		Groups[Key] = { Key = Key, Name = Record.n, Rarity = if type(Record.ra) == "string" and Record.ra ~= "" then Record.ra else (Constants.Characters[Record.n] or {}).Rarity,
			Cps = Cps, Count = math.min(#Slots, math.floor(Count)) }
	end
	for Index, Character in Current do
		Parts[#Parts + 1] = tostring(Slots[Index]) .. "=" .. (Character and Character.Key or "")
		if Character then Parts[#Parts + 1] = "ObservedPair:" .. tostring(Slots[Index]) .. ":" .. tostring(Character.PairMultiplier) end
		if Character then
			Counts[Character.Key] = (Counts[Character.Key] or 0) + 1
			-- 摘要是否含已放置角色可能因版本而異，取最大已證實持有量，避免重複計數。
			if not Groups[Character.Key] then Groups[Character.Key] = table.clone(Character) end
			Groups[Character.Key].Count = math.max(Groups[Character.Key].Count, Counts[Character.Key])
			Groups[Character.Key].Cps = Character.Cps
		end
	end
	-- 摘要是否包含工作／家中角色未能由所有版本保證，至少保留所有已由位置確認的持有份數，避免重複計數。
	for _, Assignment in Workers do
		local Character = Assignment.Character
		Counts[Character.Key] = (Counts[Character.Key] or 0) + 1
		if not Groups[Character.Key] then Groups[Character.Key] = table.clone(Character) end
		Groups[Character.Key].Count = math.max(Groups[Character.Key].Count, Counts[Character.Key])
		Groups[Character.Key].Cps = Character.Cps
	end
	local Candidates = {}
	for _, Character in Groups do table.insert(Candidates, Character) end
	table.sort(Candidates, function(Left, Right)
		--[[ @param Left 左候選。 @param Right 右候選。 @return 原始鍵遞增供穩定指紋。 ]]
		return Left.Key < Right.Key
	end)
	for _, Character in Candidates do
		Parts[#Parts + 1] = Character.Key .. ":" .. tostring(Character.Cps) .. ":" .. tostring(Character.Count)
	end
	local PairDefinitions, PairSignature = _CharacterPairs.Snapshot(Candidates, Constants.Characters or {})
	Parts[#Parts + 1] = "PairDefinitions:" .. PairSignature
	local Signature = table.concat(Parts, "\n")
	if not Plan or Plan.Signature ~= Signature then
		if _Runtime.HomeReservations then _Runtime.HomeReservations.bReady = false end
		Plan = _CharacterPairs.Start(Candidates, Slots, PairDefinitions, Current)
		Plan.SummaryStamp = _CharacterPairs.InventoryStamp(Summary)
		Plan.Signature, Plan.Plot, Plan.Slots = Signature, Plot, Slots
		Plan.Before, Plan.BeforeLinks = _CharacterPairs.Score(Current, Slots, Plan.Definitions, true)
		Plan.UnknownCount = UnknownCount
		Plan.DebugCandidates = table.clone(Candidates)
		Plan.Workers = Workers
		_Runtime.CharacterPlan = Plan
	end
	Plan.SummaryStamp = _CharacterPairs.InventoryStamp(Summary)
	if not Plan.Done then _CharacterPairs.Advance(Plan) return end
	_CharacterPairs.Render(Plan)
	Plan.Target, Plan.TargetIncome, Plan.TargetLinks = _CharacterPairs.Select(Plan)
	_CharacterPairs.ReserveHome(Plot, Plan, false)
	local bBetter = Plan.TargetIncome > Plan.Before or (Plan.TargetIncome == Plan.Before and Plan.TargetLinks > Plan.BeforeLinks)
	if not bBetter then
		_CharacterPairs.ReserveHome(Plot, Plan, true)
		_Runtime.bCharacterContinue = false
		_Status("bAutoCharacters", "目前已是配對後總收益最高配置，保留原配置") return
	end
	-- 規劃前先等其他會更動角色持有量的輪次完成，才取得配置鎖。
	if _RebirthFood.bActive then _Status("bAutoCharacters", "等待轉生前全部餵食完成") return end
	if _Runtime.Jobs.bAutoSellCharacters or _Runtime.Jobs.bAutoWorkers or _Runtime.Jobs.bAutoFeed then
		_Status("bAutoCharacters", "收益計算完成，等待角色操作結束") return
	end
	_Runtime.CharacterApplying = true
	_Runtime.bCharacterContinue = true
	_CharacterPairs.Apply(Plot, Stands, Current, Plan)
	_Runtime.bCharacterContinue = _Runtime.CharacterApplying == true
end

--[[
	同步修改全部藥水控制項與白名單；靜默 Set 仍由 BjzUi 排程保存。
	@param bEnabled true 全選目前列出的藥水；false 全取消，不更動買藥／喝藥功能開關。
]]
local function _SetAllPotions(bEnabled: boolean): ()
	if not _Runtime.bAlive then return end
	for Key, Control in _Runtime.PotionControls do
		Control:Set(bEnabled, true)
		Controller.PotionKeys[Key] = bEnabled
	end
end

--[[
	從遊戲的背包摘要選出已選品質、未收藏且未裝備的角色組，送出單組出售。
	使用伺服器提供的原始 key，涵蓋沒有實體 Tool 的背包角色，不自行拼接出售鍵。
	使用範例：
	```lua
	-- 前提：未完成 Rsh_B10，且已選擇 Common。
	-- 每輪取得摘要、收藏與裝備清單後，出售一組合格的 Common。
	-- 遊戲回報 Favorited／NotSellable 等原因時保留原因，不宣稱成功。
	```
]]
local function _SellBackpackCharacters(): ()
	local Summary = _Invoke("BackpackCharSummaryGet")
	local Favorites = _Invoke("BackpackGetFavorites")
	local Equipped = _Invoke("BackpackGetEquippedState")
	assert(type(Summary) == "table" and type(Favorites) == "table" and type(Equipped) == "table"
		and type(Equipped.equipped) == "table", "背包角色、收藏或裝備資料格式已變更")
	if Controller.bAutoEventQuests and not _EventQuests.bReady then
		if _Runtime.Jobs.bAutoEventQuests then return end
		if not _EventQuests.Refresh() then return end
	end
	local Protected = {}
	for _, Record in Equipped.equipped do
		if type(Record) ~= "table" then continue end
		local Key = Record.key or ("C|" .. tostring(Record.n or "") .. "|" .. tostring(Record.ty or ""))
		Protected[tostring(Key)] = true
	end
	local Keys = {}
	for Key, Record in Summary do
		if type(Key) ~= "string" or Key:sub(1, 2) ~= "C|" or type(Record) ~= "table" then continue end
		local Definition = (Constants.Characters or {})[Record.n]
		local Rarity = if type(Record.ra) == "string" and Record.ra ~= "" then Record.ra
			else (Definition and Definition.Rarity)
		if Rarity and Controller.SellRarities[Rarity] and (tonumber(Record.c) or 0) > 0
			and Favorites[Key] ~= true and not Protected[Key]
			and not (Controller.bAutoEventQuests and (_EventQuests.Protected[Record.n]
				or _EventQuests.Protected[Key:match("^C|([^|]+)|")])) then table.insert(Keys, Key) end
	end
	if not Controller.bAutoSellCharacters then return end
	if #Keys == 0 then _Status("bAutoSellCharacters", "背包沒有符合已選品質且未收藏／未裝備的角色") return end
	table.sort(Keys)
	local Selected = Keys[1]
	for _, Key in Keys do if Key > _Runtime.LastSellGroup then Selected = Key break end end
	_Runtime.LastSellGroup = Selected
	local Result = _Invoke("BackpackSellSelectedRequest", Selected)
	assert(type(Result) == "table", "背包出售回傳格式已變更")
	_Status("bAutoSellCharacters", if Result.ok == true then "背包出售已接受：" .. Selected
		else "背包出售未接受：" .. tostring(Result.reason or "Unknown"))
end

--[[
	輪流出售已選品質的角色，沿用遊戲 Sell Rarity，預設不選取任何品質。
	未解鎖時改由背包逐組出售；不修改永久自動出售設定或繞過不可出售判定。
	使用範例：
	```lua
	-- 在「自動出售」多選 Common、Uncommon，再開啟「自動賣角色」。
	-- 有 Rsh_B10 使用按品質出售，否則讀取背包清單逐組出售。
	-- 關閉後不再送出新請求，伺服器已完成的出售無法復原。
	```
]]
local function _SellCharacters(): ()
	if _Runtime.CharacterApplying or _Runtime.WorkerGear then return end
	if Controller.bAutoEventQuests then
		if _Runtime.Jobs.bAutoEventQuests then _Status("bAutoSellCharacters", "等待活動任務更新角色保留名單") return end
		if not _EventQuests.Refresh() then _Status("bAutoSellCharacters", "等待活動任務狀態確認，暫停出售") return end
		if not Controller.bAutoSellCharacters then return end
	end
	if next(Controller.SellRarities) == nil then
		_Status("bAutoSellCharacters", "請先在「自動出售」選擇品質") return
	end
	if LocalPlayer:GetAttribute("Rsh_B10") ~= true or (Controller.bAutoEventQuests and next(_EventQuests.Protected) ~= nil) then
		_SellBackpackCharacters() return
	end
	for Offset = 1, #_RarityOptions do
		local Index = (_Runtime.SellIndex + Offset - 1) % #_RarityOptions + 1
		local Rarity = _RarityOptions[Index]
		if not Controller.SellRarities[Rarity] then continue end
		_Runtime.SellIndex = Index
		local Result = _Invoke("BackpackSellRarityRequest", Rarity)
		assert(type(Result) == "table", "按品質出售的回傳格式已變更")
		if Result.ok == true then
			_Status("bAutoSellCharacters", Rarity .. "：遊戲回報已出售 " .. tostring(tonumber(Result.sold) or 0) .. " 個角色")
		elseif Result.reason == "Empty" then
			_Status("bAutoSellCharacters", Rarity .. "：目前沒有可出售角色")
		else
			_Status("bAutoSellCharacters", Rarity .. " 出售未接受：" .. tostring(Result.reason or "Unknown"))
		end
		return
	end
end

--[[
	取得原生角色 CPS；視覺資料未載入時依 BaseCPS 與 CharacterType 倍率還原。
	@param Model 角色模型或 Stand Folder。
	@return 有效 CPS；未知時為 nil，不猜測強度。
]]
local function _FeedCps(Model: Instance): number?
	local Cps = tonumber(Model:GetAttribute("CPS"))
	if not Cps then
		local Base = tonumber(Model:GetAttribute("BaseCPS"))
		local Multiplier = ((Constants.TypeSystem or {}).Multipliers or {})[Model:GetAttribute("CharacterType")]
		if Base then Cps = Base * math.max(1, tonumber(Multiplier) or 1) end
	end
	return if Cps and Cps == Cps and Cps >= 0 and Cps < math.huge then Cps else nil
end

--[[
	獨立前往自己的菜園，每輪最多收集八份食物並返回，不餵食或升級角色。
]]
local function _CollectFood(): ()
	assert(type(fireproximityprompt) == "function", "缺少 fireproximityprompt，無法自動收集食物")
	if _Runtime.bMoving then
		_Status("bAutoCollectFood", "等待其他移動操作完成") return
	end
	local Root = _Character()
	local Plots = workspace:FindFirstChild("PlayerPlots")
	if not Root or not Plots then
		return
	end
	local OwnPlot = nil
	for _, Plot in Plots:GetChildren() do
		if tonumber(Plot:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then OwnPlot = Plot break end
	end
	if not OwnPlot then _Status("bAutoCollectFood", "自己的地塊尚未載入") return end
	local Before = tonumber(LocalPlayer:GetAttribute("FoodNumber")) or 0
	local Requested = 0
	local Purchases, FoodTargets = OwnPlot:FindFirstChild("Purchases"), {}
	for _, Name in { "Garden1", "Garden2", "Garden3", "GardenPAID" } do
		local Garden = OwnPlot:FindFirstChild(Name) or (Purchases and Purchases:FindFirstChild(Name))
		if not Garden then continue end
		for _, Food in Garden:GetChildren() do
			if not Food:IsA("Model") or (tonumber(Food:GetAttribute("FoodValue")) or 0) <= 0
				or Food:GetAttribute("FoodPromptParked") == true then continue end
			local Prompt = Food:FindFirstChildWhichIsA("ProximityPrompt", true)
			if Prompt and Prompt.Enabled and tonumber(Prompt:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then
				table.insert(FoodTargets, { Food = Food, Prompt = Prompt })
			end
		end
	end
	-- 限制每輪拾取數量，避免大量生成物件拖延研究或釣魚。
	for Index = 1, math.min(#FoodTargets, 8) do
		local Item = FoodTargets[Index]
		if not Item.Food:IsDescendantOf(OwnPlot) or Item.Food:GetAttribute("FoodPromptParked") == true then continue end
		local Point = _PromptPosition(Item.Prompt)
		if not Point then continue end
		_Status("bAutoCollectFood", "前往菜園收集食物（" .. Index .. "／" .. math.min(#FoodTargets, 8) .. "）")
		if not _Travel("bAutoCollectFood", Root, CFrame.new(Point + Vector3.new(0, 2, 2))) then _RestoreMove("bAutoCollectFood") return end
		if Item.Prompt.Parent and Item.Prompt.Enabled and tonumber(Item.Prompt:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then
			fireproximityprompt(Item.Prompt)
			Requested += 1
			task.wait(0.3)
		end
	end
	_RestoreMove("bAutoCollectFood")
	local Added = math.max(0, (tonumber(LocalPlayer:GetAttribute("FoodNumber")) or Before) - Before)
	_Status("bAutoCollectFood", if Requested == 0 then "等待自己的菜園食物生成"
		elseif Added > 0 then "收集後 Food 已增加：" .. tostring(Added) else "已請求收集食物，等待遊戲同步")
end

--[[
	只使用現有 Food 餵食角色，不前往菜園收集。最高品質優先模式先比品質、同品質再比 CPS。
	最高品質目標食物不足就等待；平均模式從可負擔角色中先比品質，同品質再選最低等級。
	依目前地塊已放置角色選擇目標，不等待裝備搜尋完成；實際換位時暫停。
	使用範例：
	```lua
	-- 可獨立開啟自動餵食；需要補充食物時另開啟自動收集食物。
	-- 全部餵食使用 MaxLevelUp，一個一個餵使用 LevelUp。
	```
]]
local function _Feed(): ()
	if _Runtime.CharacterApplying then _Status("bAutoFeed", "等待角色配對換位完成") return end
	assert(type(fireproximityprompt) == "function", "缺少 fireproximityprompt，無法自動餵食")
	if _Runtime.bMoving then _Status("bAutoFeed", "等待其他移動操作完成") return end
	if (tonumber(LocalPlayer:GetAttribute("FoodNumber")) or 0) <= 0 then
		_Status("bAutoFeed", "等待足夠 Food；可另開啟自動收集食物") return
	end
	local Root = _Character()
	local Plots = workspace:FindFirstChild("PlayerPlots")
	if not Root or not Plots then return end
	local OwnPlot = nil
	for _, Plot in Plots:GetChildren() do
		if tonumber(Plot:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then OwnPlot = Plot break end
	end
	if not OwnPlot then _Status("bAutoFeed", "自己的地塊尚未載入") return end
	local Models, Stands, SinglePrompts = {}, {}, {}
	for _, Model in OwnPlot:GetDescendants() do
		if Model:IsA("Model") and Model:GetAttribute("IsPlacedCharacter") == true and Model:GetAttribute("StandId") ~= nil then
			Models[tostring(Model:GetAttribute("StandId"))] = Model
		end
	end
	-- 原生 StandPromptController 也使用地塊 Stand Folder 的 HasCharacter；視覺模型未載入時仍可定位角色。
	for _, Stand in OwnPlot:GetDescendants() do
		if Stand:IsA("Folder") and Stand:GetAttribute("HasCharacter") == true then
			Stands[Stand.Name] = Stand
			if not Models[Stand.Name] then Models[Stand.Name] = Stand end
		elseif Stand:IsA("ProximityPrompt") and Stand:GetAttribute("PromptType") == "LevelUp"
			and Stand.ActionText:match("%(%d+%.?%d*%a* Food%)%s*$") then
			SinglePrompts[tostring(Stand:GetAttribute("StandId"))] = Stand
		end
	end
	local Tried, TotalSpent = {}, 0
	local bHighestQuality = Controller.FeedMode == "最高品質優先"
	local bAverage = Controller.FeedMode == "平均分配"
	local BestModel, BestCps, BestId, HighestRank = nil, -math.huge, "", -math.huge
	local Ranks = {}
	if bHighestQuality or bAverage then
		for Id, Model in Models do
			local Stand = Stands[Id]
			local Name = (Stand and Stand:GetAttribute("CharacterName")) or Model:GetAttribute("CharacterName")
			local Definition = Name and (Constants.Characters or {})[Name]
			local Rarity = (Stand and Stand:GetAttribute("Rarity")) or (Definition and Definition.Rarity) or Model:GetAttribute("Rarity")
			local Rank = table.find(Constants.RarityOrder or {}, Rarity)
			if not Rank then
				_Status("bAutoFeed", "等待所有角色品質載入，暫不判定最高品質") return
			end
			Ranks[Id] = Rank
			HighestRank = math.max(HighestRank, Rank)
		end
	end
	if bHighestQuality then
		for Id, Model in Models do
			if Ranks[Id] ~= HighestRank then continue end
			local Cps = (Stands[Id] and _FeedCps(Stands[Id])) or _FeedCps(Model)
			if not Cps then
				_RestoreMove("bAutoFeed")
				_Status("bAutoFeed", "等待最高品質角色強度載入，暫不比較同品質角色") return
			end
			if Cps > BestCps or (Cps == BestCps and Id < BestId) then
				BestModel, BestCps, BestId = Model, Cps, Id
			end
		end
	end
	local PromptType = if Controller.FeedAction == "一個一個餵" then "LevelUp" else "MaxLevelUp"
	local Message = if bHighestQuality then "等待最高品質角色的食物、資料或可用餵食提示" else "沒有食物足夠且提示可用的角色，等待 Food 或角色資料載入"
	for _ = 1, (if bHighestQuality then 1 else 3) do
		local Food = tonumber(LocalPlayer:GetAttribute("FoodNumber")) or 0
		local Selected, SelectedModel, Position, BestScore, Oldest = nil, nil, nil, math.huge, math.huge
		local BestRank, BestLevel, BestStandId = -math.huge, math.huge, ""
		for _, Prompt in OwnPlot:GetDescendants() do
			if not Prompt:IsA("ProximityPrompt") or Prompt:GetAttribute("PromptType") ~= PromptType or not _CanFeedPrompt(Prompt) then continue end
			local Id = tostring(Prompt:GetAttribute("StandId"))
			local Model, Stand, CostPrompt = Models[Id], Stands[Id], SinglePrompts[Id] or Prompt
			local Point = _PromptPosition(Prompt)
			if not Model or Tried[Model] or not Point then continue end
			if bHighestQuality and Model ~= BestModel then continue end
			local Cost, Source, Minimum = _FeedCost(Model, CostPrompt, Stand)
			if bHighestQuality then _ShowFeedCost(Model, Stand, CostPrompt, Food, Cost, Source) end
			if not Cost or (Minimum or Cost) > Food then
				if bHighestQuality then Message = if not Cost then "最高品質角色費用未同步：" .. Source
					else "最高品質角色 Food 不足：現有 " .. tostring(Food) .. "／費用 " .. tostring(Cost) end
				continue
			end
			local Score = _Runtime.FeedSpent[Model] or 0
			local Time = _Runtime.FeedTimes[Prompt] or 0
			local Rank, Level = Ranks[Id] or 0, (Stand and tonumber(Stand:GetAttribute("Level"))) or tonumber(Model:GetAttribute("Level"))
			if bAverage and (not Level or Level ~= Level or Level < 1 or Level == math.huge) then continue end
			local bPreferred = if bAverage then Rank > BestRank or (Rank == BestRank and (Level < BestLevel
				or (Level == BestLevel and (Time < Oldest or (Time == Oldest and (BestStandId == "" or Id < BestStandId))))))
				else Score < BestScore or (Score == BestScore and Time < Oldest)
			if bPreferred then
				Selected, SelectedModel, Position, BestScore, Oldest = Prompt, Model, Point, Score, Time
				BestRank, BestLevel, BestStandId = Rank, Level or math.huge, Id
			end
		end
		if not Selected then break end
		Tried[SelectedModel] = true
		local Id = tostring(Selected:GetAttribute("StandId"))
		local Stand, CostPrompt = Stands[Id], SinglePrompts[Id] or Selected
		local SelectedCost, SelectedSource = _FeedCost(SelectedModel, CostPrompt, Stand)
		_ShowFeedCost(SelectedModel, Stand, CostPrompt, Food, SelectedCost, SelectedSource)
		_Status("bAutoFeed", "前往餵食：" .. SelectedModel.Name .. "（" .. Controller.FeedMode .. "／" .. Controller.FeedAction .. "）")
		if not _Travel("bAutoFeed", Root, CFrame.new(Position + Vector3.new(0, 2, 2))) then _RestoreMove("bAutoFeed") return end
		local Deadline = os.clock() + 2
		while Selected:IsDescendantOf(OwnPlot) and _CanFeedPrompt(Selected) and not Selected.Enabled and os.clock() < Deadline do
			if not Controller.bAutoFeed or not _Runtime.bAlive then _RestoreMove("bAutoFeed") return end
			task.wait(0.1)
		end
		_Runtime.FeedTimes[Selected] = os.clock()
		if _Runtime.CharacterApplying then _RestoreMove("bAutoFeed") return end
		if not Selected:IsDescendantOf(OwnPlot) or not _CanFeedPrompt(Selected) or not Selected.Enabled then
			Message = if bHighestQuality then "最高品質角色餵食提示未啟用，跳過本輪" else "已抵達角色，餵食提示未啟用，改找其他符合條件角色" continue
		end
		local Before = tonumber(LocalPlayer:GetAttribute("FoodNumber")) or 0
		local Cost, Source, Minimum = _FeedCost(SelectedModel, CostPrompt, Stand)
		_ShowFeedCost(SelectedModel, Stand, CostPrompt, Before, Cost, Source)
		if not Cost or (Minimum or Cost) > Before then
			Message = if not Cost then "餵食費用未同步：" .. Source
				else "Food 已不足：現有 " .. tostring(Before) .. "／費用 " .. tostring(Cost) continue
		end
		local PreviousLevel = tonumber(SelectedModel:GetAttribute("Level")) or 0
		fireproximityprompt(Selected)
		task.wait(0.3)
		local ConfirmUntil = os.clock() + 1.2
		while (tonumber(LocalPlayer:GetAttribute("FoodNumber")) or Before) >= Before
			and (tonumber(SelectedModel:GetAttribute("Level")) or PreviousLevel) <= PreviousLevel and os.clock() < ConfirmUntil do
			if not Controller.bAutoFeed or not _Runtime.bAlive then _RestoreMove("bAutoFeed") return end
			task.wait(0.1)
		end
		local Spent = math.max(0, Before - (tonumber(LocalPlayer:GetAttribute("FoodNumber")) or Before))
		local UpdatedCost, UpdatedSource = _FeedCost(SelectedModel, CostPrompt, Stand)
		_ShowFeedCost(SelectedModel, Stand, CostPrompt, tonumber(LocalPlayer:GetAttribute("FoodNumber")) or Before, UpdatedCost, UpdatedSource)
		_Runtime.FeedSpent[SelectedModel] = (_Runtime.FeedSpent[SelectedModel] or 0) + Spent
		TotalSpent += Spent
		Message = if Spent > 0 then "餵食已消耗 Food：" .. tostring(TotalSpent) else "已請求餵食，等待遊戲確認或更多 Food"
		if PromptType == "LevelUp" then break end
	end
	_RestoreMove("bAutoFeed")
	_Status("bAutoFeed", Message)
end

--[[
	對開始準備時家中每個角色至多嘗試一次 MaxLevelUp，不要求 Food 歸零；每格3秒、整輪最多30秒。
	@return 嘗試數、略過數與逐格原因；沒有食物或必要能力時立即結束，不阻擋轉生。
	使用範例：
	```lua
	-- 由自動轉生在狀態查詢成功後呼叫，無須開啟一般自動餵食。
	local Report = _RebirthFood.Run()
	-- 回傳後繼續轉生，不依 Food 是否剩餘決定重跑。
	```
]]
function _RebirthFood.Run()
	local Report = { Attempted = 0, Skipped = 0, Total = 0, Items = {}, StartedAt = os.clock(), FoodBefore = tonumber(LocalPlayer:GetAttribute("FoodNumber")) or 0 }
	if Report.FoodBefore <= 0 then Report.Reason = "沒有食物" return Report end
	if type(fireproximityprompt) ~= "function" then Report.Reason = "缺少 fireproximityprompt" return Report end
	local Plot, Plots = nil, workspace:FindFirstChild("PlayerPlots")
	for _, Candidate in (Plots and Plots:GetChildren()) or {} do
		if tonumber(Candidate:GetAttribute("OwnerUserId")) == LocalPlayer.UserId then Plot = Candidate break end
	end
	if not Plot then Report.Reason = "家中地塊未載入" return Report end
	local Targets, Prompts, ById = {}, {}, {}
	local Purchases = Plot:FindFirstChild("Purchases")
	for _, Object in Plot:GetDescendants() do
		if Object:IsA("ProximityPrompt") and Object:GetAttribute("PromptType") == "MaxLevelUp" then
			Prompts[tostring(Object:GetAttribute("StandId"))] = Object
		elseif Object:IsA("Folder") and (Object.Parent == Plot or Object.Parent == Purchases)
			and _CharacterPairs.StandIndex(Object.Name) and Object:GetAttribute("HasCharacter") == true
			and Object:GetAttribute("RebirthLocked") ~= true and Object:GetAttribute("PaidLocked") ~= true then
			ById[Object.Name] = Object
		elseif Object:IsA("Model") and Object:GetAttribute("IsPlacedCharacter") == true then
			local Id = tostring(Object:GetAttribute("StandId"))
			if _CharacterPairs.StandIndex(Id) and not ById[Id] then ById[Id] = Object end
		end
	end
	for Id, Object in ById do table.insert(Targets, { Id = Id, Object = Object, Prompt = Prompts[Id] }) end
	table.sort(Targets, function(Left, Right)
		--[[ @param Left 左展台。 @param Right 右展台。 @return 依原生格位排序。 ]]
		return _CharacterPairs.StandIndex(Left.Id) < _CharacterPairs.StandIndex(Right.Id)
	end)
	Report.Total = #Targets
	_RebirthFood.bActive = true
	local Deadline = os.clock() + 30
	for Index, Target in Targets do
		if not _Runtime.bAlive or not Controller.bAutoRebirth then Report.bCanceled = true break end
		if os.clock() >= Deadline then Report.bTimedOut = true break end
		_Runtime.RebirthFoodProgressAt = os.clock()
		local Item = { StandId = Target.Id, State = "等待操作" }
		Report.Items[Index] = Item
		_Status("bAutoRebirth", "轉生前全部餵食：" .. Index .. "／" .. #Targets .. "（最長30秒，不等待食物歸零）")
		local bDone = false
		--[[
			隔離單格位移與提示呼叫；失敗或超時繼續下一格。
		]]
		_RebirthFood.Job = task.defer(function()
			--[[ 執行一次原生全部餵食，不依一般 FeedMode 或 FeedAction 限制角色。 ]]
			local bOk, Reason = pcall(function()
				local Root = _Character()
				local Prompt = Target.Prompt
				if not Root or not Prompt or not Prompt:IsDescendantOf(Plot) or not Target.Object:IsDescendantOf(Plot) then Item.State = "角色或全部餵食提示未載入" return end
				if not _CanFeedPrompt(Prompt) then Item.State = "食物不足或提示不可用" return end
				while _Runtime.CharacterApplying or _Runtime.Jobs.bAutoFeed or _Runtime.Jobs.bAutoWorkers or _Runtime.Jobs.bAutoCollectFood do task.wait(0.1) end
				local Position = _PromptPosition(Prompt)
				if not Position then Item.State = "提示位置未載入" return end
				while not _Travel("bAutoRebirth", Root, CFrame.new(Position + Vector3.new(0, 2, 2))) do task.wait(0.1) end
				while Prompt.Parent and _CanFeedPrompt(Prompt) and not Prompt.Enabled do task.wait(0.1) end
				if not _Runtime.bAlive or not Controller.bAutoRebirth or _Runtime.CharacterApplying or not Prompt:IsDescendantOf(Plot) or not _CanFeedPrompt(Prompt) or not Prompt.Enabled then Item.State = "角色或提示狀態已改變" return end
				Report.Attempted += 1
				Item.State = "已嘗試全部餵食"
				fireproximityprompt(Prompt)
				task.wait(0.2)
			end)
			if not bOk then Item.State = "操作失敗：" .. tostring(Reason) end
			bDone = true
		end)
		local Until = math.min(Deadline, os.clock() + 3)
		while not bDone and os.clock() < Until do task.wait(0.1) end
		if not bDone then Item.State = "單格操作逾時" end
		if _RebirthFood.Job then pcall(task.cancel, _RebirthFood.Job) _RebirthFood.Job = nil end
		_RestoreMove("bAutoRebirth")
		if Item.State ~= "已嘗試全部餵食" then Report.Skipped += 1 end
	end
	Report.FoodAfter = tonumber(LocalPlayer:GetAttribute("FoodNumber")) or 0
	Report.Elapsed = os.clock() - Report.StartedAt
	Report.bTimedOut = Report.bTimedOut or os.clock() >= Deadline
	Report.Unvisited = #Targets - #Report.Items
	_RebirthFood.Cancel()
	return Report
end

--[[ 依商店原定貨幣與庫存購買選取藥水，每輪最多一瓶。 ]]
local function _BuyPotions(): ()
	local State = _Invoke("BoostsStoreGetState")
	assert(type(State) == "table" and type(State.stock) == "table", "藥水商店回傳格式已變更")
	for OfferKey, Offer in (Constants.BoostsStore or {}).Offers or {} do
		local Currency = Offer.Currency or "Cash"
		local Cost = tonumber(if Currency == "Cash" then Offer.CashCost else Offer.GemsCost)
		if not Controller.PotionKeys[Offer.PotionKey] or (tonumber(State.stock[OfferKey]) or 0) <= 0 then
			continue
		end
		if Currency ~= "Cash" and (Currency ~= "Gems" or not Controller.bAllowGems) then
			continue
		end
		if not Cost or Cost > (tonumber(LocalPlayer:GetAttribute(Currency .. "Number")) or 0) then
			continue
		end
		local bAccepted, Reason = _Invoke("BoostsStorePurchase", OfferKey, Currency)
		_Status(
			"bAutoBuyPotions",
			if bAccepted == true then "已購買：" .. Offer.PotionKey else "未接受：" .. tostring(Reason)
		)
		return
	end
	_Status("bAutoBuyPotions", "等待選取藥水的庫存、資金或鑽石開關")
end

--[[
	依單一限時商店原生快照輪替購買可用商品，只使用已確認的 Cash／Gems 協定。
	@param Store LIMITED_SHOPS 中已查證的商店適配資料。
	@return true 已送出一次購買（不代表被接受）；false 未送出。
	@return 未送出時的等待原因；已送出時為購買結果訊息。
	@return true 表示開放狀態未確認，可在發現原生 NPC 時靠近重查；其他情況為 nil。
	使用範例：
	```lua
	-- 開啟自動購買限時商店後，預設僅使用 Cash。
	-- 商品與價格取自對應 SecretStore 的動態狀態；是否接受購買以伺服器回覆為準。
	local bAttempted, Reason = _TryLimitedShop(LIMITED_SHOPS[1])
	```
]]
local function _TryLimitedShop(Store): (boolean, string?, boolean?)
	local Definitions = (Constants[Store.Key] or {}).Offers
	if type(Definitions) ~= "table" then return false, Store.Name .. "：商品定義未載入" end
	if Store.bGate and not _Runtime.RodUpdateGate then
		local Modules = ReplicatedStorage:FindFirstChild("Modules")
		local Module = Modules and Modules:FindFirstChild("UpdateGate")
		assert(Module and Module:IsA("ModuleScript"), "缺少 UpdateGate，無法確認限時商品是否開放")
		_Runtime.RodUpdateGate = require(Module)
	end
	if Store.bGate then assert(type(_Runtime.RodUpdateGate.IsOfferHeld) == "function", "UpdateGate 缺少 IsOfferHeld") end
	local State = _Invoke(Store.Key .. "GetState")
	local ReceivedAt = os.clock()
	if not Controller.bAutoLimitedShop or not _Runtime.bAlive then return false, "已關閉" end
	assert(type(State) == "table" and type(State.offers) == "table", "限時商店狀態未就緒或格式已變更")
	if Store.bActiveState and State.active ~= true then return false, "等待 " .. Store.Name .. " 限時商店出現", true end
	local DespawnAt, ServerTime = tonumber(State.despawnAt), tonumber(State.serverTime)
	local ExpiresAt = math.huge
	if not Store.bActiveState or State.timed ~= false then
		if not DespawnAt or not ServerTime or DespawnAt ~= DespawnAt or ServerTime ~= ServerTime
			or math.abs(DespawnAt) == math.huge or math.abs(ServerTime) == math.huge or ServerTime < 0 then
			return false, Store.Name .. "：等待有效商店倒數", true
		end
		if DespawnAt <= ServerTime or DespawnAt <= 0 then return false, "等待 " .. Store.Name .. " 限時商店出現", true end
		ExpiresAt = ReceivedAt + DespawnAt - ServerTime
	end
	local Keys = {}
	for Key in Definitions do if type(Key) == "string" then table.insert(Keys, Key) end end
	table.sort(Keys)
	_Runtime.LimitedShopCursors = _Runtime.LimitedShopCursors or {}
	local Start = table.find(Keys, _Runtime.LimitedShopCursors[Store.Key]) or 0
	for Offset = 1, #Keys do
		local Key = Keys[(Start + Offset - 1) % #Keys + 1]
		local Offer, Definition = State.offers[Key], Definitions[Key]
		local Stock = type(Offer) == "table" and tonumber(Offer.stock) or nil
		if type(Offer) ~= "table" or type(Definition) ~= "table" or Offer.visible ~= true or Offer.owned == true
			or (Definition.AlwaysInStock ~= true and (not Stock or Stock ~= Stock or Stock < 1 or Stock == math.huge))
			or (Store.bGate and _Runtime.RodUpdateGate.IsOfferHeld(Store.Key, Key)) then continue end
		local Currency = nil
		for _, Kind in { "Cash", "Gems" } do
			if Kind == "Cash" and Store.bCash == false then continue end
			if Kind == "Gems" and not Controller.bLimitedShopAllowGems then continue end
			local Cost = tonumber(Offer[if Kind == "Cash" then "cashCost" else "gemsCost"])
			if not Cost then Cost = tonumber(Definition[Kind .. "Cost"]) end
			local Balance = tonumber(LocalPlayer:GetAttribute(Kind .. "Number")) or 0
			if Cost and Cost == Cost and Cost > 0 and Cost < math.huge and Cost <= Balance then Currency = Kind break end
		end
		if not Currency then continue end
		if not Controller.bAutoLimitedShop or not _Runtime.bAlive or (Currency == "Gems" and not Controller.bLimitedShopAllowGems)
			or os.clock() >= ExpiresAt then return false, "商店已關閉或許可已撤回" end
		_Runtime.LimitedShopCursors[Store.Key] = Key
		local bAccepted, Reason = _Invoke(Store.Key .. "Purchase", Key, Currency)
		local Potion = Definition.PotionKey and ((Constants.Potions or {}).Definitions or {})[Definition.PotionKey]
		local Name = Definition.AbilityName or (Potion and Potion.ToolName) or Definition.PotionKey or Key
		local Message = if bAccepted == true then "伺服器已接受 " .. Store.Name .. " 限時購買：" .. Name .. "（" .. Currency .. "）"
			else Store.Name .. " 限時購買未接受：" .. Name .. "／" .. tostring(Reason or "未提供原因")
		_Status("bAutoLimitedShop", Message)
		return true, Message
	end
	return false, Store.Name .. "：等待商品庫存、資金或鑽石許可"
end

--[[
	以 ShopPromptService 已確認的標記找到實際在場商店及原生提示位置，不以商店 UI 可見代替開放判定。
	@param Store 已查證的商店定義。
	@return 在場 NPC，未找到時為 nil。
	@return NPC 提示位置或模型位置；無可用位置時為 nil。
]]
local function _LimitedShopNpc(Store)
	for _, Object in game:GetService("CollectionService"):GetTagged(Store.Tag) do
		if not Object:IsDescendantOf(workspace) then continue end
		for _, Prompt in Object:GetDescendants() do
			if Prompt:IsA("ProximityPrompt") and Prompt.Name == Store.Key .. "Prompt" then
				local Point = _PromptPosition(Prompt)
				if Point then return Object, Point end
			end
		end
		if Object:IsA("Model") or Object:IsA("BasePart") then return Object, Object:GetPivot().Position end
	end
	return nil, nil
end

--[[
	原地查詢未開放但 NPC 已在場時，靠近後重新取得原生狀態並嘗試購買，不覆寫 active 或到期時間。
	@param Store 商店定義。
	@param Npc 本輪找到的原生 NPC；移動後重新檢查仍在地圖。
	@param Point 已確認的提示或 NPC 座標。
	@return 是否已送出購買。
	@return 購買結果或等待原因；呼叫端即使發生錯誤也必須還原位移。
]]
local function _TryNearbyLimitedShop(Store, Npc, Point)
	if _Runtime.bMoving or _Runtime.WorkerGear or _Runtime.CharacterApplying then return false, "已找到 " .. Store.Name .. " NPC，等待其他移動操作完成" end
	local Root = _Character()
	if not Root then return false, "已找到 " .. Store.Name .. " NPC，等待角色載入" end
	if not _Travel("bAutoLimitedShop", Root, CFrame.new(Point + Vector3.new(0, 2, 2))) then
		return false, "已找到 " .. Store.Name .. " NPC，等待釣魚／移動交接完成"
	end
	if not Controller.bAutoLimitedShop or not _Runtime.bAlive then return false, "已關閉" end
	if not Npc:IsDescendantOf(workspace) then return false, Store.Name .. " NPC 已離場，下輪重新查詢" end
	local bAttempted, Reason, bUnavailable = _TryLimitedShop(Store)
	if bUnavailable then return false, "已找到 " .. Store.Name .. " NPC，但靠近重查後伺服器仍未確認開放；" .. tostring(Reason) end
	return bAttempted, Reason
end

--[[ 輪替已查證的四種限時商店；單一商店缺失或失敗不阻擋其餘商店，每輪最多送出一筆購買。 ]]
local function _BuyLimitedShop(): ()
	local Reasons = {}
	local Start = _Runtime.LimitedShopIndex or 0
	for Offset = 1, #LIMITED_SHOPS do
		if not Controller.bAutoLimitedShop or not _Runtime.bAlive then return end
		local Index = (Start + Offset - 1) % #LIMITED_SHOPS + 1
		local Store = LIMITED_SHOPS[Index]
		-- 查詢若卡住而被排程器取消，下輪仍會前進至下一間，不會永遠停在同一間。
		_Runtime.LimitedShopIndex = Index
		local bOk, bAttempted, Reason, bUnavailable = pcall(_TryLimitedShop, Store)
		if bOk and not bAttempted and bUnavailable then
			local Npc, Point = _LimitedShopNpc(Store)
			if Npc and Point then
				bOk, bAttempted, Reason = pcall(_TryNearbyLimitedShop, Store, Npc, Point)
				_RestoreMove("bAutoLimitedShop")
			end
		end
		local Detail = if bOk then Reason or Store.Name .. "：等待" else Store.Name .. "：" .. tostring(bAttempted)
		if _Runtime.LimitedShopLabels[Store.Key] then _Runtime.LimitedShopLabels[Store.Key]:Set(Store.Name .. " 商店狀態", Detail) end
		if bOk and bAttempted then _Runtime.LimitedShopIndex = Index return end
		table.insert(Reasons, Detail)
	end
	_Status("bAutoLimitedShop", table.concat(Reasons, "；"))
end

--[[
	選取藥水剩餘效果不足一分鐘時補喝，每輪最多一瓶；暫停計時時不補喝。
	PotionUse 接收 Tool，保留遊戲原始協定。
]]
local function _DrinkPotions(): ()
	local State = _Invoke("PotionGetState")
	assert(type(State) == "table" and type(State.potions) == "table", "藥水狀態格式已變更")
	if State.paused == true then
		_Status("bAutoDrinkPotions", "藥水計時暫停，暫不補喝")
		return
	end
	local Active = {}
	for _, Potion in State.potions do
		if (tonumber(Potion.endTime) or 0) - (tonumber(State.serverTime) or os.time()) > 60 then
			Active[Potion.key] = true
		end
	end
	for _, Container in { LocalPlayer:FindFirstChild("Backpack"), LocalPlayer.Character } do
		if not Container then
			continue
		end
		for _, Tool in Container:GetChildren() do
			local Key = Tool:GetAttribute("PotionKey")
			if not Tool:IsA("Tool") or not Key or not Controller.PotionKeys[Key] or Active[Key] then
				continue
			end
			local bAccepted, Reason = _Invoke("PotionUse", Tool)
			_Status(
				"bAutoDrinkPotions",
				if bAccepted == true then "已喝下：" .. Key else "未接受：" .. tostring(Reason)
			)
			return
		end
	end
	_Status("bAutoDrinkPotions", "效果仍足夠，或沒有選取的藥水")
end

--[[
	研究優先類別依快照 WorldNodeInfo.Research 的名稱／說明及 ResearchEffects 定義。
	同時屬於多個類別的項目可出現在多個集合；未列項目仍可作為其他候選研究。
]]
local RESEARCH_PRIORITIES = {
	["金錢項目優先"] = { B1 = true, B6 = true, C1 = true, C7 = true, C9 = true, RebirthDiscount = true },
	["藥水項目優先"] = { A1 = true, A2 = true, A9 = true, A7 = true, C5 = true, C10 = true, Drink100 = true },
	["自動項目優先"] = { B2 = true, A7 = true },
	["食物項目優先"] = { C2 = true, C8 = true, B5 = true, FoodSaver = true },
	["角色項目優先"] = { C3 = true, C4 = true, C6 = true, B3 = true, B4 = true, B9 = true, ProdigyCatch = true },
	["建築項目優先"] = { FastBuilder1 = true, FastBuilder2 = true },
	["最低費用優先"] = {},
}

--[[
	已載入時沿用原生 UI 使用的研究板節點；研究板尚未載入才退回 WorldNodeInfo。
	避免舊版備援資料的費用／前置屬性覆蓋目前畫面中的實際研究條件。
	@return 研究設定容器；尚未取得任何資料時為 nil。
]]
local function _ResearchDefinitions(): Instance?
	local Worlds = workspace:FindFirstChild("WorldsFolder")
	local Board = Worlds and Worlds:FindFirstChild("Research")
	local Nodes = Board and Board:FindFirstChild("Nodes")
	for _, Node in (Nodes and Nodes:GetChildren()) or {} do
		if Node:IsA("BasePart") then return Nodes end
	end
	local Info = ReplicatedStorage:FindFirstChild("WorldNodeInfo")
	return Info and Info:FindFirstChild("Research")
end

--[[
	以伺服器 active[].e 完成時間繪製所有研究槽的倒數，不把預計時長當成伺服器已開研的證據。
	每秒最多更新一次，UI 段落自動增高，完成時等待伺服器同步而不自行移除研究。
]]
local function _RenderResearchProgress(): ()
	if not _Runtime.ResearchLabel or os.clock() < _Runtime.ResearchNextUiAt then return end
	_Runtime.ResearchNextUiAt = os.clock() + 1
	local State, Lines = _Runtime.ResearchState, {}
	local Definitions = _ResearchDefinitions()
	for _, Record in (State and State.active) or {} do
		if type(Record) ~= "table" or type(Record.id) ~= "string" then continue end
		local Definition = Definitions and Definitions:FindFirstChild(Record.id)
		local Name = tostring(Definition and Definition:GetAttribute("DisplayName") or Record.id)
		local Finish = tonumber(Record.e)
		local Remaining = Finish and math.max(0, math.ceil(Finish - os.time()))
		local Timer = if not Remaining then "剩餘時間尚未同步" elseif Remaining == 0 then "等待完成同步"
			else string.format("剩餘 %02d:%02d:%02d", math.floor(Remaining / 3600), math.floor(Remaining / 60) % 60, Remaining % 60)
		table.insert(Lines, Name .. "（" .. Record.id .. "） · " .. Timer)
	end
	if _Runtime.ResearchPendingName then table.insert(Lines, _Runtime.ResearchPendingName .. " · 已接受，等待研究時間同步") end
	if #Lines == 0 then table.insert(Lines, if State then "目前沒有進行中的研究" else "尚未同步研究資料") end
	local Text = table.concat(Lines, "\n")
	if Text ~= _Runtime.ResearchText then
		_Runtime.ResearchText = Text
		_Runtime.ResearchLabel:Set("進行中的研究", Text)
	end
end

--[[
	接收個人研究的查詢、開始回應或 ResearchUpdate 推播資料，保留原生完成時間。
	@param State 原生 owned／active／slots 資料；無效資料不覆蓋最後有效快照。
]]
local function _ApplyResearchState(State): ()
	if not _Runtime.bAlive or type(State) ~= "table" or State.ok == false or type(State.active) ~= "table" then return end
	_Runtime.ResearchState, _Runtime.ResearchPendingName = State, nil
	Controller.ResearchStatus = State
	_Runtime.ResearchNextUiAt = 0
	_RenderResearchProgress()
end

--[[
	依前置條件、資金與 slots 挑選個人研究，直接呼叫原生 ResearchStart，不移動或開啟研究入口。
	GetData(true) 沿用遊戲到期刷新；不更動公會研究或購買跳過時間。
	使用範例：
	```lua
	-- 開啟自動研究後篩選可用項目，依優先類別挑選，直接請求開始。
	-- 可與釣魚及其他位移工作並行；伺服器拒絕時顯示原始原因。
	```
]]
local function _Research(): ()
	local State = _Invoke("ResearchGetData", true)
	if not Controller.bAutoResearch or not _Runtime.bAlive then return end
	assert(
		type(State) == "table"
			and State.ok ~= false
			and type(State.owned) == "table"
			and type(State.active) == "table"
			and tonumber(State.slots),
		"研究資料未就緒或格式改變：" .. tostring(type(State) == "table" and State.err or State)
	)
	_ApplyResearchState(State)
	if #State.active >= tonumber(State.slots) then
		_Status("bAutoResearch", "研究欄位已滿，等待完成")
		_Runtime.ResearchSelectionLabel:Set("研究篩選狀態", "研究欄位已滿，等待進行中的項目完成")
		return
	end
	local Definitions = _ResearchDefinitions()
	if not Definitions then
		_Status("bAutoResearch", "等待研究項目資料載入")
		return
	end
	local Owned, Active = {}, {}
	for _, Id in State.owned do
		Owned[Id] = true
	end
	for _, Record in State.active do
		if type(Record) == "table" and type(Record.id) == "string" then Active[Record.id] = true end
	end
	local Best, BestCost, BestGems, BestPriority = nil, math.huge, math.huge, math.huge
	local Counts = { Total = 0, Locked = 0, Unlocked = 0, Ready = 0, Money = 0, Gems = 0 }
	local Details = {}
	local Cash = tonumber(LocalPlayer:GetAttribute("CashNumber")) or 0
	local WalletGems = tonumber(LocalPlayer:GetAttribute("GemsNumber")) or 0
	for _, Node in Definitions:GetChildren() do
		if not (Node:IsA("BasePart") or Node:IsA("Configuration")) or Owned[Node.Name] or Active[Node.Name] then
			continue
		end
		Counts.Total += 1
		local bAvailable = true
		for _, Attribute in { "Requires", "SnapTo" } do
			local Id = tostring(Node:GetAttribute(Attribute) or "")
			if Id ~= "" and Definitions:FindFirstChild(Id) and not Owned[Id] then
				bAvailable = false
			end
		end
		local Cost = math.max(0, tonumber(Node:GetAttribute("CostCash")) or 0)
		local Gems = math.max(0, tonumber(Node:GetAttribute("CostGems")) or 0)
		if not bAvailable then Counts.Locked += 1 continue end
		Counts.Unlocked += 1
		local Reasons = {}
		if Gems > 0 and not Controller.bResearchAllowGems then
			Counts.Gems += 1
			table.insert(Reasons, "未允許花費鑽石")
		end
		if Cost > Cash or Gems > WalletGems then
			Counts.Money += 1
			if Cost > Cash then table.insert(Reasons, "Cash 不足") end
			if Gems > WalletGems then table.insert(Reasons, "Gems 不足") end
		end
		table.insert(Details, string.format("%s（%s） · Cash %s／Gems %s · %s",
			tostring(Node:GetAttribute("DisplayName") or Node.Name), Node.Name, tostring(Cost), tostring(Gems),
			if #Reasons == 0 then "可開始" else table.concat(Reasons, "、")))
		if #Reasons > 0 then continue end
		Counts.Ready += 1
		local Priority = if RESEARCH_PRIORITIES[Controller.ResearchPriority][Node.Name] then 0 else 1
		if Priority < BestPriority or (Priority == BestPriority and (Cost < BestCost
			or (Cost == BestCost and (Gems < BestGems or (Gems == BestGems and (not Best or Node.Name < Best.Name)))))) then
			Best, BestCost, BestGems, BestPriority = Node, Cost, Gems, Priority
		end
	end
	table.sort(Details)
	table.insert(Details, 1, string.format("已解鎖 %d 項／可自動研究 %d 項；前置未達成 %d 項\n目前 Cash %s／Gems %s；允許花費鑽石：%s",
		Counts.Unlocked, Counts.Ready, Counts.Locked, tostring(Cash), tostring(WalletGems), if Controller.bResearchAllowGems then "已開啟（研究專用）" else "未開啟"))
	_Runtime.ResearchSelectionLabel:Set("研究篩選狀態", table.concat(Details, "\n"))
	Controller.ResearchSelection = Counts
	if not Best then
		_Status("bAutoResearch", if Counts.Unlocked > 0 then string.format("已解鎖 %d 項；可自動研究 0 項，詳見下方原因", Counts.Unlocked)
			elseif Counts.Total > 0 then "剩餘研究的前置條件尚未達成" else "已載入研究皆已完成或進行中")
		return
	end
	if not Controller.bAutoResearch or not _Runtime.bAlive then return end
	local Name = tostring(Best:GetAttribute("DisplayName") or Best.Name)
	_Status("bAutoResearch", "開始研究：" .. Name .. "（" .. Controller.ResearchPriority .. "）")
	if not Best:IsDescendantOf(Definitions) then return end
	local Result = _Invoke("ResearchStart", Best.Name)
	if type(Result) == "table" and type(Result.data) == "table" then _ApplyResearchState(Result.data)
	elseif type(Result) == "table" and Result.ok == true then _Runtime.ResearchPendingName = Name end
	assert(type(Result) == "table", "ResearchStart 回傳格式已變更")
	_Status(
		"bAutoResearch",
		if Result.ok == true then "研究已開始：" .. Name else "未接受：" .. tostring(Result.err)
	)
end

--[[
	沿用遊戲商店的費用公式，包含 CostAnchors 的指數插值。
	@param Offer Constants.UpgradesStore.Offers 中的設定。
	@param Level 要購買的下一級。
	@return 該級 Cash 費用；資料不足時為 nil，不猜測免費。
]]
local function _UpgradeCost(Offer, Level: number): number?
	if Offer.Costs and tonumber(Offer.Costs[Level]) then
		return tonumber(Offer.Costs[Level])
	end
	local Anchors = Offer.CostAnchors
	if type(Anchors) == "table" and #Anchors >= 2 then
		local Index = 1
		while Index < #Anchors - 1 and Anchors[Index + 1][1] < Level do
			Index += 1
		end
		local First, Last = Anchors[Index], Anchors[Index + 1]
		if Level == Last[1] then
			return Last[2]
		end
		if First[1] < Last[1] and First[2] > 0 then
			return math.floor(First[2] * ((Last[2] / First[2]) ^ (1 / (Last[1] - First[1]))) ^ (Level - First[1]))
		end
	end
	if Offer.CostBase and Offer.CostScale then
		return math.floor(Offer.CostBase * Offer.CostScale ^ (Level - 1))
	end
	return nil
end

-- UPGRADE_PRIORITY_START
--[[
	取得原生商店卡片顯示名稱；以 OfferKey 對應 Title，未載入時使用原生商品 Label。
	@param Key 僅用於對應與購買的原生商品鍵。
	@return 商店人類可讀名稱，移除 RichText 標記；未知名稱時不把內部鍵顯示給使用者。
]]
function _UpgradePriority.Name(Key: string): string
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local MainGui = PlayerGui and PlayerGui:FindFirstChild("MainGui")
	local Shop = MainGui and MainGui:FindFirstChild("UpgradesStoreGUI")
	if Shop then
		for _, Card in Shop:GetDescendants() do
			if Card:GetAttribute("OfferKey") == Key then
				local Title = Card:FindFirstChild("Title")
				if Title and Title:IsA("TextLabel") and Title.Text ~= "" then return (Title.Text:gsub("<[^>]*>", "")) end
			end
		end
	end
	local Label = (((Constants.UpgradesStore or {}).Offers or {})[Key] or {}).Label
	return if type(Label) == "string" and Label ~= "" then Label:gsub("<[^>]*>", "") else "名稱尚未載入"
end

--[[
	正規化升級順序，排除重複或已移除項目，新商品以鍵名排序接在尾端。
	@param Order 已保存或使用者編輯的鍵名清單；無效值使用預設順序。
	@return 當前商品的完整且不重複鍵名清單。
]]
function _UpgradePriority.Normalize(Order)
	local Offers = (Constants.UpgradesStore or {}).Offers or {}
	local Result, Seen, Missing = {}, {}, {}
	for _, Key in if type(Order) == "table" then Order else {} do
		if type(Key) == "string" and type(Offers[Key]) == "table" and not Seen[Key] then
			Seen[Key] = true table.insert(Result, Key)
		end
	end
	for Key, Offer in Offers do if type(Key) == "string" and type(Offer) == "table" and not Seen[Key] then table.insert(Missing, Key) end end
	table.sort(Missing)
	for _, Key in Missing do table.insert(Result, Key) end
	return Result
end

--[[ 將完整順序同步回隱藏的設定值控制項；靜默 Set 仍沿用既有 Flag 自動保存。 ]]
function _UpgradePriority.Sync(): ()
	local Order = Controller.UpgradePriorityOrder
	for Index, Control in _UpgradePriority.Controls do
		if Order[Index] and Control:Get() ~= Order[Index] then Control:Set(Order[Index], true) end
	end
end

--[[
	顯示完整順序、順位分數與當前選擇依據。
	@param Detail 本輪選擇或等待原因；省略時只更新排序說明。
]]
function _UpgradePriority.Render(Detail: string?): ()
	if not _UpgradePriority.Label then return end
	local Order = _UpgradePriority.Normalize(Controller.UpgradePriorityOrder)
	local Lines = { "權重＝順位分數 ÷ 下一級價格；分數由項目總數逐名遞減至1。只比較買得起且未滿級的項目，免費升級優先。" }
	for Index, Key in Order do
		local Name = _UpgradePriority.Name(Key)
		if _UpgradePriority.Rows[Index] then
			_UpgradePriority.Rows[Index]:Set((if _UpgradePriority.SelectedKey == Key then "▶ " else "")
				.. Index .. ". " .. Name .. "（" .. (#Order - Index + 1) .. "分）")
		end
	end
	local Selected = table.find(Order, _UpgradePriority.SelectedKey)
	if Selected then Lines[#Lines + 1] = "已選取：" .. _UpgradePriority.Name(_UpgradePriority.SelectedKey) .. "（第" .. Selected .. "順位）"
	else _UpgradePriority.SelectedKey = nil Lines[#Lines + 1] = "請點選項目，再按上調順序或下調順序。" end
	if _UpgradePriority.Up then _UpgradePriority.Up:SetEnabled(Selected ~= nil and Selected > 1) end
	if _UpgradePriority.Down then _UpgradePriority.Down:SetEnabled(Selected ~= nil and Selected < #Order) end
	if Detail then Lines[#Lines + 1] = Detail end
	_UpgradePriority.Label:Set("升級順序與選擇依據", table.concat(Lines, "\n"))
end

--[[
	點選目前順位的項目；選取跟隨項目鍵而非位置，移動後仍保持選取。
	@param Index 清單中的順位。
]]
function _UpgradePriority.SelectRow(Index: number): ()
	if not _Runtime.bAlive then return end
	local Order = _UpgradePriority.Normalize(Controller.UpgradePriorityOrder)
	_UpgradePriority.SelectedKey = Order[Index]
	_UpgradePriority.Render()
end

--[[
	將目前選取的項目向上或向下移動一格；未選取或已在邊界時不更動順序。
	@param Offset -1 上調，1 下調。
]]
function _UpgradePriority.Move(Offset: number): ()
	if not _Runtime.bAlive or (Offset ~= -1 and Offset ~= 1) then return end
	local Order = _UpgradePriority.Normalize(Controller.UpgradePriorityOrder)
	local Index = table.find(Order, _UpgradePriority.SelectedKey)
	if Index and Order[Index + Offset] then _UpgradePriority.SetRank(Index + Offset, _UpgradePriority.SelectedKey) end
end

--[[
	將項目移到指定順位，與原先佔位者交換，保持每個項目只有一個位置。
	@param Index 一開始算起的順位。
	@param Key 原生升級商品鍵。
]]
function _UpgradePriority.SetRank(Index: number, Key: string): ()
	if not _Runtime.bAlive then return end
	local Order = _UpgradePriority.Normalize(Controller.UpgradePriorityOrder)
	local Previous = table.find(Order, Key)
	if not Previous or not Order[Index] then return end
	Order[Index], Order[Previous] = Order[Previous], Order[Index]
	Controller.UpgradePriorityOrder = Order
	_UpgradePriority.Sync()
	_UpgradePriority.Render()
end

--[[
	先快照所有已載入設定值，再統一去重與同步，保留舊版順位 Flag 的字串格式。
]]
function _UpgradePriority.Load(): ()
	local Saved = {}
	for Index, Control in _UpgradePriority.Controls do Saved[Index] = Control:Get() end
	Controller.UpgradePriorityOrder = _UpgradePriority.Normalize(Saved)
	_UpgradePriority.Sync()
	_UpgradePriority.Render()
end

--[[
	將既有項目按鈕放進固定高度的 ScrollingFrame，兩個32像素方形操作鈕固定在右側。
	原生容器均掛在既有控制項 Frame 下，由視窗卸載統一銷毀，不新增背景工作或事件。
	@param Card 自動升級商店的既有 Card。
]]
function _UpgradePriority.Layout(Card): ()
	local Host = Card:CreateLabel({ Name = "升級排序清單", bSave = false })
	Host:Set("")
	Host.Frame.Size = UDim2.new(1, 0, 0, 240)
	_UpgradePriority.Host = Host
	local Scroll = Instance.new("ScrollingFrame")
	Scroll.Parent = Host.Frame
	Scroll.Name, Scroll.BackgroundTransparency, Scroll.BorderSizePixel = "UpgradePriorityScroll", 1, 0
	Scroll.Size = UDim2.new(1, -44, 1, 0)
	Scroll.CanvasSize, Scroll.AutomaticCanvasSize = UDim2.fromOffset(0, 0), Enum.AutomaticSize.Y
	Scroll.ScrollingDirection, Scroll.ScrollBarThickness = Enum.ScrollingDirection.Y, 4
	Scroll.ClipsDescendants, Scroll.Active = true, true
	_UpgradePriority.Scroll = Scroll
	local Layout = Instance.new("UIListLayout")
	Layout.Parent = Scroll
	Layout.SortOrder, Layout.Padding, Layout.Parent = Enum.SortOrder.LayoutOrder, UDim.new(0, 6), Scroll
	local Padding = Instance.new("UIPadding")
	Padding.Parent = Scroll
	Padding.PaddingTop, Padding.PaddingBottom, Padding.PaddingRight = UDim.new(0, 2), UDim.new(0, 2), UDim.new(0, 8)
	Padding.PaddingLeft = UDim.new(0, 6)
	Padding.Parent = Scroll
	for Index, Row in _UpgradePriority.Rows do
		Row.Frame.Parent, Row.Frame.LayoutOrder = Scroll, Index
		Row.Frame.Size = UDim2.new(1, -20, 0, 34)
		if Row.Button then
			Row.Button.TextXAlignment, Row.Button.TextTruncate = Enum.TextXAlignment.Left, Enum.TextTruncate.AtEnd
			local TextPadding = Row.Button:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding")
			TextPadding.Parent = Row.Button
			TextPadding.PaddingLeft, TextPadding.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
		end
	end
	for Index, Button in { _UpgradePriority.Up, _UpgradePriority.Down } do
		Button.Frame.Parent = Host.Frame
		Button.Frame.Size = UDim2.fromOffset(32, 32)
		Button.Frame.Position = UDim2.new(1, -32, 0, (Index - 1) * 40)
		Button:Set(if Index == 1 then "↑" else "↓")
	end
end

--[[
	用既有按鈕組成可點選清單及上／下調操作，隱藏 Input 僅承接既有順位 Flag 保存。
	@param Card 自動升級商店的既有功能 Card。
]]
function _UpgradePriority.CreateUi(Card): ()
	local Order = _UpgradePriority.Normalize({})
	Controller.UpgradePriorityOrder = Order
	for Index, Key in Order do
		_UpgradePriority.Controls[Index] = Card:CreateInput({ Name = "升級排序儲存 " .. Index,
			Flag = "UpgradePriority_" .. Index, CurrentValue = Key, bVisible = false })
		--[[ 點選此列目前所代表的項目，不直接改變順序。 ]]
		_UpgradePriority.Rows[Index] = Card:CreateButton({ Name = "升級項目 " .. Index, Style = "outline", bSave = false,
			Callback = function() _UpgradePriority.SelectRow(Index) end })
	end
	--[[ 將選取項目上調一格，邊界時停用。 ]]
	_UpgradePriority.Up = Card:CreateButton({ Name = "上調順序", bSave = false, bEnabled = false,
		Callback = function() _UpgradePriority.Move(-1) end })
	--[[ 將選取項目下調一格，邊界時停用。 ]]
	_UpgradePriority.Down = Card:CreateButton({ Name = "下調順序", bSave = false, bEnabled = false,
		Callback = function() _UpgradePriority.Move(1) end })
	_UpgradePriority.Layout(Card)
	_UpgradePriority.Label = Card:CreateParagraph({ Title = "升級順序與選擇依據", Content = "等待設定載入" })
end

--[[
	以順位分數除以下一級價格選擇本輪升級；相同權重依順位、價格、鍵名打破平手。
	@param State 原生 UpgradesStoreGetState 回應。
	@param Balance 目前可用 Cash。
	@return 最佳候選及其順位、價格、權重；無可負擔候選時為 nil。
]]
function _UpgradePriority.Select(State, Balance: number)
	if Balance ~= Balance or Balance < 0 or Balance == math.huge then return nil end
	local Order = _UpgradePriority.Normalize(Controller.UpgradePriorityOrder)
	local Best
	for Rank, Key in Order do
		local Offer = Constants.UpgradesStore.Offers[Key]
		local Level, Maximum = tonumber(State.levels[Key]) or 0, tonumber(Offer.MaxLevels)
		if not Maximum or Maximum ~= Maximum or Level ~= Level or Level < 0 or Level == math.huge then continue end
		Level = math.floor(Level)
		if Level >= Maximum then continue end
		local Cost = _UpgradeCost(Offer, Level + 1)
		if not Cost or Cost ~= Cost or Cost < 0 or Cost == math.huge or Cost > Balance then continue end
		local Weight = if Cost == 0 then math.huge else (#Order - Rank + 1) / Cost
		if not Best or Weight > Best.Weight or (Weight == Best.Weight and (Rank < Best.Rank
			or (Rank == Best.Rank and (Cost < Best.Cost or (Cost == Best.Cost and Key < Best.Key))))) then
			Best = { Key = Key, Rank = Rank, Cost = Cost, Weight = Weight }
		end
	end
	return Best
end

--[[
	自動轉生開啟時，依下一次原生轉生費用決定是否繼續花錢升級。
	達到門檻後鎖定存錢階段，直到轉生目標／次數或使用者門檻改變，避免餘額下降又重新花錢。
	@return 仍可花費的最新 Cash；準備轉生、達門檻或目標未知時為 nil。
	@return 資金分配說明，未開啟自動轉生時為 nil。
]]
function _UpgradePriority.Budget()
	if not Controller.bAutoRebirth then
		_UpgradePriority.SavingKey, _UpgradePriority.bSaving = nil, false
		return tonumber(LocalPlayer:GetAttribute("CashNumber")) or 0
	end
	if _Runtime.Jobs.bAutoRebirth then return nil, "自動轉生處理中，暫停花費升級資金" end
	local Rebirths = LocalPlayer:GetAttribute("Rebirths")
	local Cache = _Runtime.UpgradeRebirthCache
	if not Cache or Cache.Rebirths ~= Rebirths or os.clock() - Cache.At > 2 then
		local bOk, State = pcall(_Invoke, "RebirthGetState", true)
		if not bOk or type(State) ~= "table" then return nil, "無法確認轉生費用，暫緩升級並保留金錢" end
		Cache = { State = State, Rebirths = Rebirths, At = os.clock() }
		_Runtime.UpgradeRebirthCache = Cache
	end
	if not Controller.bAutoRebirth then return tonumber(LocalPlayer:GetAttribute("CashNumber")) or 0 end
	if LocalPlayer:GetAttribute("Rebirths") ~= Cache.Rebirths then return nil, "轉生次數已變更，下輪重新讀取升級與轉生費用" end
	local CostText = Cache.State.nextCostText
	if type(CostText) == "string" then CostText = CostText:gsub(",", "") end
	local Cost = _ReadGameAmount(CostText)
	if not Cost or Cost ~= Cost or Cost < 0 or Cost == math.huge then return nil, "轉生目標金額尚未載入，暫緩升級" end
	local Cash = tonumber(LocalPlayer:GetAttribute("CashNumber")) or 0
	local Percent = math.clamp(tonumber(Controller.UpgradeRebirthSavePercent) or 80, 0, 100)
	local Identity = tostring(Rebirths) .. ":" .. tostring(Cache.State.nextRankName) .. ":" .. tostring(Cost) .. ":" .. tostring(Percent)
	if Identity ~= _UpgradePriority.SavingKey then _UpgradePriority.SavingKey, _UpgradePriority.bSaving = Identity, false end
	if Cash >= Cost * Percent / 100 then _UpgradePriority.bSaving = true end
	local Progress = if Cost > 0 then math.min(100, Cash / Cost * 100) else 100
	local Detail = string.format("轉生資金：%.6g／%.6g Cash（%.1f%%）；存錢門檻 %.0f%%", Cash, Cost, Progress, Percent)
	if _UpgradePriority.bSaving then return nil, (if Cash >= Cost then "轉生金額已足夠，保留資金等待轉生；" else "優先存錢轉生，暫停升級；") .. Detail end
	return Cash, "尚未進入轉生存錢階段，按權重升級；" .. Detail
end
-- UPGRADE_PRIORITY_END

--[[ 每輪以使用者順位與原生下一級價格計算權重，只購買一級可負擔升級，下輪重查。 ]]
local function _Upgrade(): ()
	local State = _Invoke("UpgradesStoreGetState")
	assert(type(State) == "table" and type(State.levels) == "table", "升級商店回傳格式已變更")
	if not Controller.bAutoUpgrade or not _Runtime.bAlive then return end
	local Budget, Decision = _UpgradePriority.Budget()
	if not Controller.bAutoUpgrade or not _Runtime.bAlive then return end
	if Budget == nil then _Status("bAutoUpgrade", Decision) _UpgradePriority.Render(Decision) return end
	local Best = _UpgradePriority.Select(State, Budget)
	if not Best then
		_Status("bAutoUpgrade", "升級已滿或等待 Cash")
		_UpgradePriority.Render("本輪沒有買得起的未滿級項目。")
		return
	end
	local Name = _UpgradePriority.Name(Best.Key)
	local Detail = if Best.Cost == 0 then string.format("本輪選擇：%s；第%d順位；下一級免費，優先升級", Name, Best.Rank)
		else string.format("本輪選擇：%s；第%d順位；下一級價格 %.6g Cash；權重 %.6g", Name, Best.Rank, Best.Cost, Best.Weight)
	_UpgradePriority.Render((if Decision then Decision .. "\n" else "") .. Detail)
	local bAccepted, Reason = _Invoke("UpgradesStorePurchase", Best.Key, 1)
	_Status("bAutoUpgrade", if bAccepted == true then "已升級：" .. Name .. "（第" .. Best.Rank .. "順位）" else "未接受：" .. tostring(Reason))
end

-- MAP_PICKUP_START
--[[
	結束自己已開始的觸碰；重複呼叫不產生額外操作，失敗仍釋放本地紀錄。
	@param FeatureKey 限制只釋放此功能的觸碰；省略時釋放全部自己持有的觸碰。
]]
function _MapPickup.ReleaseTouch(FeatureKey: string?): ()
	local Touch = _MapPickup.Touch
	if FeatureKey and Touch and Touch.FeatureKey ~= FeatureKey then return end
	_MapPickup.Touch = nil
	if Touch and type(firetouchinterest) == "function" then pcall(firetouchinterest, Touch.Root, Touch.Part, 1) end
end

--[[
	@param Point 掉落事件提供的座標。
	@return 有限 Vector3 時為 true，拒絕缺失或無效座標。
]]
function _MapPickup.ValidPoint(Point): boolean
	return typeof(Point) == "Vector3" and Point.X == Point.X and Point.Y == Point.Y and Point.Z == Point.Z
		and math.abs(Point.X) < 1e7 and math.abs(Point.Y) < 1e7 and math.abs(Point.Z) < 1e7
end

--[[
	沿用 StandDropsClient 的事件形狀，只快取該玩家收到的有效、未過期道具。
	@param Action add／sync／taken／remove／deny。
	@param Payload 遊戲提供的單筆、清單或數字 ID。
]]
function _MapPickup.OnDrop(Action, Payload): ()
	if Action == "sync" then
		if type(Payload) == "table" then for _, Record in Payload do _MapPickup.OnDrop("add", Record) end end
		return
	end
	if Action == "add" then
		if type(Payload) ~= "table" then return end
		local Id, Life = tonumber(Payload.id), tonumber(Payload.life)
		if not Id or Id ~= Id or Id <= 0 or Id == math.huge or not Life or Life ~= Life or Life <= 0 or Life == math.huge
			or not _MapPickup.ValidPoint(Payload.pos) or (Payload.kind ~= "LoveEssence" and Payload.kind ~= "SakuraLeaf") then return end
		local Count = 0
		for Key, Record in _MapPickup.Drops do
			if Record.Expires <= os.clock() then _MapPickup.Drops[Key] = nil else Count += 1 end
		end
		if Count >= 256 and not _MapPickup.Drops[Id] then return end
		_MapPickup.Drops[Id] = { Id = Id, Point = Payload.pos, Expires = os.clock() + Life, Label = Payload.kind }
		return
	end
	local Id = tonumber(Payload)
	local Record = Id and _MapPickup.Drops[Id]
	if not Record then return end
	if Action == "taken" then Record.bTaken = true _MapPickup.Drops[Id] = nil
	elseif Action == "remove" then _MapPickup.Drops[Id] = nil
	elseif Action == "deny" then Record.bDenied = true _MapPickup.Retry[Record] = os.clock() + 5 end
end

--[[
	檢查物件與祖先的角色標記及所有權，排除地圖角色、角色工具、展台和其他玩家專屬物品。
	@param Object 原生掉落物或拾取提示。
	@return 仍在地圖且無其他玩家所有權時為 true。
]]
function _MapPickup.IsWorldItem(Object): boolean
	if not Object or not Object:IsDescendantOf(workspace) then return false end
	local Current = Object
	while Current and Current ~= workspace do
		if Current == LocalPlayer.Character or Current.Name == "PlayerPlots" or Current:FindFirstChildOfClass("Humanoid") then return false end
		if Current:GetAttribute("IsCharacterTool") == true or Current:GetAttribute("IsCharacterModel") == true
			or Current:GetAttribute("IsPlacedCharacter") == true or Current:GetAttribute("CharacterName") ~= nil then return false end
		if Current.Parent == workspace and (Current.Name == "SpawnedCharacters" or Current.Name == "CarriedCharacters"
			or Current.Name == "EquippedFollowers" or Current.Name == "ToolFollowers" or Current.Name == "JesterizedClones") then return false end
		local Owner = Current:GetAttribute("OwnerUserId")
		if Owner ~= nil and tonumber(Owner) ~= 0 and tonumber(Owner) ~= LocalPlayer.UserId then return false end
		Current = Current.Parent
	end
	return true
end

--[[
	重新取得位置與原生可拾取狀態，不改寫提示、隱藏或碰撞屬性。
	@param Item 候選記錄。
	@param Tags 原生 CollectionService。
	@return 目前可操作位置；已消失、隱藏、被停用或變成其他玩家物品時為 nil。
]]
function _MapPickup.Position(Item, Tags)
	if Item.Kind == "Drop" then
		return if _MapPickup.Drops[Item.Record.Id] == Item.Record and Item.Record.Expires > os.clock() then Item.Record.Point else nil
	end
	local Object, Origin = Item.Object, Item.Origin
	if not _MapPickup.IsWorldItem(Origin) or not _MapPickup.IsWorldItem(Object) then return nil end
	if Item.Tag and not Tags:HasTag(Origin, Item.Tag) then return nil end
	if Origin:GetAttribute("StarHiddenLocal") == true then return nil end
	if Item.Kind == "Touch" then
		if not Object:IsA("BasePart") or not Object.CanTouch or Object.LocalTransparencyModifier >= 1 then return nil end
		if Origin:IsA("Tool") and (Origin.Parent ~= workspace or Origin:FindFirstChild("Handle") ~= Object) then return nil end
		return Object.Position
	end
	if not Object:IsA("ProximityPrompt") or not Object.Enabled or Object:GetAttribute("ServerEnabled") == false then return nil end
	return _PromptPosition(Object)
end

--[[
	收集已由原生腳本確認的鑽石、活動材料、道具及任務拾取提示，不掃描購買互動。
	@param Tags 原生 CollectionService。
	@return 目前可用的候選清單。
	@return 缺少的互動能力說明，沒有缺少時為空字串。
]]
function _MapPickup.Candidates(Tags)
	local Items, Seen, Missing = {}, {}, {}
	--[[ @param Item 候選；只有座標與能力均有效時才入列。 ]]
	local function Add(Item): ()
		local Token = Item.Record or Item.Object
		if Seen[Token] or _MapPickup.Unavailable[Token] or os.clock() < (_MapPickup.Retry[Token] or 0) then return end
		if Item.Kind == "Touch" and type(firetouchinterest) ~= "function" then Missing.firetouchinterest = true return end
		if Item.Kind == "Prompt" and type(fireproximityprompt) ~= "function" then Missing.fireproximityprompt = true return end
		local Point = _MapPickup.Position(Item, Tags)
		if not _MapPickup.ValidPoint(Point) then return end
		Seen[Token], Item.Point = true, Point
		table.insert(Items, Item)
	end
	for Id, Record in _MapPickup.Drops do
		if Record.Expires <= os.clock() then _MapPickup.Drops[Id] = nil
		else Add({ Kind = "Drop", Record = Record, Label = Record.Label }) end
	end
	for _, Tag in { "EventGemHover", "AmneticCoin", "HalloweenCandy" } do
		for _, Origin in Tags:GetTagged(Tag) do
			local Part = if Origin:IsA("BasePart") and Origin.CanTouch then Origin else nil
			if not Part then for _, Child in Origin:GetDescendants() do if Child:IsA("BasePart") and Child.CanTouch then Part = Child break end end end
			if Part then Add({ Kind = "Touch", Object = Part, Origin = Origin, Tag = Tag, Label = Tag }) end
		end
	end
	for _, Origin in workspace:GetChildren() do
		if Origin:IsA("Tool") then
			local Handle = Origin:FindFirstChild("Handle")
			if Handle and Handle:IsA("BasePart") and Handle:FindFirstChildOfClass("TouchTransmitter") then
				Add({ Kind = "Touch", Object = Handle, Origin = Origin, Label = Origin.Name })
			end
		end
	end
	for _, Object in workspace:GetDescendants() do
		if not Object:IsA("ProximityPrompt") then continue end
		local Origin = Object:FindFirstAncestorWhichIsA("Model") or Object.Parent
		local bKnown = Object.Name == "AmnesiaPickupPrompt" or Object.Name == "HalloweenPickupPrompt"
		local Star = Object.Parent
		if Star and Star:IsA("Attachment") then Star = Star.Parent end
		if Star and Star.Parent == workspace and (Star.Name == "Sakura Flower" or (Star.Name == "StarPickup" and Star:GetAttribute("StarPickupId") ~= nil)) then
			bKnown, Origin = true, Star
		end
		if bKnown and Object.ActionText == "Pick Up" then
			Add({ Kind = "Prompt", Object = Object, Origin = Origin, Label = Object.ObjectText ~= "" and Object.ObjectText or Origin.Name })
		end
	end
	local Names = {}
	for Name in Missing do table.insert(Names, Name) end
	table.sort(Names)
	return Items, table.concat(Names, "／")
end

--[[
	處理本輪單一目標，不逐物品返回原位，保留本輪共用的位移紀錄。
	@param Item 本輪候選。
	@param Root 玩家根部。
	@param Tags 原生標記服務。
	@param FeatureKey 呼叫功能；省略時沿用地圖拾取，活動任務共用同一互動與確認流程。
	@return Confirmed／Denied／Unconfirmed／Unavailable／Skipped／Stop，最後者代表應停止本輪。
]]
function _MapPickup.Attempt(Item, Root, Tags, FeatureKey: string?): string
	local Key = FeatureKey or "bAutoMapPickup"
	local Point = _MapPickup.Position(Item, Tags)
	if not Point then return "Skipped" end
	local Token = Item.Record or Item.Object
	_MapPickup.Retry[Token] = os.clock() + 10
	if not _Travel(Key, Root, CFrame.new(Point + Vector3.new(0, 2, 0))) then return "Stop" end
	Point = _MapPickup.Position(Item, Tags)
	if not Controller[Key] or not _Runtime.bAlive then return "Stop" end
	if not Point or (Root.Position - Point).Magnitude > 5 then return "Skipped" end
	if Item.Kind == "Drop" then
		Item.Record.bDenied = false
		_MapPickup.Remote:FireServer("pickup", Item.Record.Id)
	elseif Item.Kind == "Touch" then
		_MapPickup.Touch = { Root = Root, Part = Item.Object, FeatureKey = Key }
		firetouchinterest(Root, Item.Object, 0)
		task.wait(0.2)
		_MapPickup.ReleaseTouch()
	else
		if (Root.Position - Point).Magnitude > Item.Object.MaxActivationDistance then
			return "Skipped"
		end
		fireproximityprompt(Item.Object)
	end
	local Deadline = os.clock() + 1.2
	repeat
		task.wait(0.1)
		if not Controller[Key] or not _Runtime.bAlive then return "Stop" end
		if (Item.Record and Item.Record.bDenied) or not _MapPickup.Position(Item, Tags) then break end
	until os.clock() >= Deadline
	_MapPickup.ReleaseTouch()
	-- 觸碰後仍可見且可拾取，沒有可觀察的成功結果；暫停重試此實體，避免反覆觸發遊戲錯誤。
	if Item.Kind == "Touch" and _MapPickup.Position(Item, Tags) then
		_MapPickup.Unavailable[Token] = Item.Label
		return "Unavailable"
	end
	return if Item.Record and Item.Record.bTaken then "Confirmed" elseif Item.Record and Item.Record.bDenied then "Denied" else "Unconfirmed"
end

--[[
	本輪依序處理開始時可用的全部掉落物，每次選當前最近者；最後才返回並接續釣魚。
	新生成物留到下一輪，避免持續重生造成永不結束；單項失敗或消失不阻擋其他項目。
]]
function _MapPickup.Step(): ()
	if _Runtime.bMoving or _Runtime.WorkerGear then _Status("bAutoMapPickup", "等待其他移動操作完成") return end
	local Root = _Character()
	if not Root then return end
	_MapPickup.ProgressAt = os.clock()
	if not _MapPickup.Remote then
		local Remote = Remotes:FindFirstChild("StandDrop")
		if Remote and Remote:IsA("RemoteEvent") then
			_MapPickup.Remote = Remote
			table.insert(_Runtime.Connections, Remote.OnClientEvent:Connect(_MapPickup.OnDrop))
		end
	end
	if _MapPickup.Remote and not _MapPickup.bSynced then
		_MapPickup.Remote:FireServer("sync")
		_MapPickup.bSynced = true
		task.wait(0.2)
	end
	if not Controller.bAutoMapPickup or not _Runtime.bAlive then _MapPickup.ProgressAt = nil return end
	local Tags = game:GetService("CollectionService")
	local Items, Missing = _MapPickup.Candidates(Tags)
	local Total = #Items
	if Total == 0 then
		_MapPickup.ProgressAt = nil
		local Blocked, Label = 0, ""
		for Object, Name in _MapPickup.Unavailable do
			if Object:IsDescendantOf(workspace) then Blocked, Label = Blocked + 1, Name end
		end
		_Status("bAutoMapPickup", if Missing ~= "" then "部分拾取停用：缺少 " .. Missing
			elseif Blocked > 0 then string.format("暫停重試 %d 份未取得拾取結果的物品（%s）；重開功能可重試", Blocked, Label)
			else "等待地圖上可拾取的鑽石或道具") return
	end
	local Counts = { Confirmed = 0, Denied = 0, Unconfirmed = 0, Unavailable = 0, Skipped = 0, Errors = 0, Done = 0 }
	while #Items > 0 and Controller.bAutoMapPickup and _Runtime.bAlive and Root.Parent == LocalPlayer.Character do
		local BestIndex, BestDistance = 1, math.huge
		for Index, Candidate in Items do
			local Point = _MapPickup.Position(Candidate, Tags)
			local Distance = if Point then (Root.Position - Point).Magnitude else math.huge
			if Distance < BestDistance then BestIndex, BestDistance = Index, Distance end
		end
		local Item = table.remove(Items, BestIndex)
		_MapPickup.ProgressAt = os.clock()
		_Status("bAutoMapPickup", string.format("本輪拾取 %d／%d：%s", Counts.Done + 1, Total, Item.Label))
		local bOk, Result = pcall(_MapPickup.Attempt, Item, Root, Tags)
		_MapPickup.ReleaseTouch()
		_MapPickup.ProgressAt = os.clock()
		if not bOk then Counts.Errors += 1 Counts.LastError = tostring(Result)
		elseif Result == "Stop" then break
		else
			Counts[Result] += 1
			if Result == "Unavailable" then Counts.LastUnavailable = Item.Label end
		end
		Counts.Done += 1
	end
	_RestoreMove("bAutoMapPickup")
	_MapPickup.ProgressAt = nil
	if not Controller.bAutoMapPickup or not _Runtime.bAlive then return end
	_Status("bAutoMapPickup", string.format("本輪已處理 %d／%d；遊戲已確認 %d／已嘗試未確認 %d／未接受 %d／略過 %d／錯誤 %d", Counts.Done, Total,
		Counts.Confirmed, Counts.Unconfirmed, Counts.Denied, Counts.Skipped, Counts.Errors)
		.. (if Counts.LastError then "；" .. Counts.LastError else "") .. (if Missing ~= "" then "；缺少 " .. Missing else "")
		.. (if Counts.LastUnavailable then string.format("；暫停重試 %d 份未取得拾取結果的物品（%s），重開功能可重試", Counts.Unavailable, Counts.LastUnavailable) else ""))
end
-- MAP_PICKUP_END

-- EVENT_QUESTS_START
--[[
	取得快照中已確認活動 NPC 或已開啟原生任務介面的存在狀態；兩者均消失時解除保留。
	@return 目前地圖存在的活動鏈名稱集合，不以暫時的天氣／釣魚事件名稱判斷。
]]
function _EventQuests.Active()
	local Tags, Active = game:GetService("CollectionService"), {}
	for Chain, Tag in { Amnesia = "AmnesiaQuestNpc", Halloween = "HalloweenQuestNpc" } do
		for _, Object in Tags:GetTagged(Tag) do
			if Object:IsDescendantOf(workspace) then Active[Chain] = true break end
		end
	end
	-- 任務介面是原生 Open 流程的另一個在場依據，避免遠處 NPC 未串流時直接忽略已開啟任務。
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local MainGui = PlayerGui and PlayerGui:FindFirstChild("MainGui")
	for Chain, Name in { Amnesia = "AmnesiaQuestGUI", Halloween = "HalloweenQuestGUI" } do
		local Frame = MainGui and MainGui:FindFirstChild(Name)
		if Frame and ((Frame:IsA("GuiObject") and Frame.Visible) or (Frame:IsA("ScreenGui") and Frame.Enabled)) then Active[Chain] = true end
	end
	return Active
end

--[[
	查詢在場活動的所有免費階段，再一次替換角色保留名單；錯誤不放行出售。
	鎖定的後續階段仍保留未交齊角色，同名角色的所有變異／等級皆受保護。
	@return 查詢後仍啟用功能時為 true；取消／卸載為 false，呼叫端不得接續提交。
]]
function _EventQuests.Refresh(): boolean
	_EventQuests.bReady = false
	if not _Runtime.NpcQuests then
		local Modules = ReplicatedStorage:FindFirstChild("Modules")
		local Module = Modules and Modules:FindFirstChild("NpcQuests")
		assert(Module and Module:IsA("ModuleScript"), "缺少遊戲 NpcQuests 模組，暫停出售以保留任務角色")
		_Runtime.NpcQuests = require(Module)
	end
	local Definitions = _Runtime.NpcQuests.Quests
	assert(type(Definitions) == "table", "活動任務定義尚未就緒，暫停出售")
	local Active, Ids, Entries, Protected = _EventQuests.Active(), {}, {}, {}
	for Id, Definition in Definitions do
		if type(Id) == "string" and type(Definition) == "table" and Active[Definition.Chain]
			and not Definition.Evolution and (tonumber(Definition.GemCost) or 0) == 0 then table.insert(Ids, Id) end
	end
	table.sort(Ids)
	for _, Id in Ids do
		if not Controller.bAutoEventQuests or not _Runtime.bAlive then return false end
		local State = _Invoke("NpcQuestGetState", Id)
		assert(type(State) == "table" and (State.claimed == nil or type(State.claimed) == "boolean")
			and (type(State.claimed) == "boolean" or type(State.progress) == "table" or type(State.deposits) == "table")
			and (State.deposits == nil or type(State.deposits) == "table")
			and (State.progress == nil or type(State.progress) == "table"), "活動任務狀態未知，暫停出售：" .. Id)
		local Definition = Definitions[Id]
		table.insert(Entries, { Id = Id, Definition = Definition, State = State })
		if State.claimed == true then continue end
		for _, Need in Definition.Characters or {} do
			assert(type(Need.Name) == "string" and Need.Name ~= "", "活動任務角色需求格式已變更")
			local Remaining = math.max(0, (tonumber(Need.Count) or 1) - (tonumber((State.deposits or {})[Need.Name]) or 0))
			if Remaining > 0 then Protected[Need.Name] = (Protected[Need.Name] or 0) + Remaining end
		end
	end
	if not Controller.bAutoEventQuests or not _Runtime.bAlive then return false end
	-- 查詢期間活動可能離場；下一輪重查，而不是用過期資料提交。
	local Latest = _EventQuests.Active()
	for Chain in Active do if not Latest[Chain] then return false end end
	_EventQuests.Entries, _EventQuests.Protected, _EventQuests.bReady = Entries, Protected, true
	return true
end

--[[
	同步活動狀態與可換行的任務進度，避免完整的缺少條件在單行標籤被截斷。
	@param Text 最新任務動作或等待條件。
]]
function _EventQuests.Show(Text: string): ()
	_Status("bAutoEventQuests", Text)
	if _Runtime.EventQuestLabel then _Runtime.EventQuestLabel:Set("活動任務進度", Text) end
end

--[[
	原地執行在場 Amnesia／Halloween 活動：領取完成階段、提交缺少角色。
	每輪最多一次角色交付／領獎；缺少任務進度或角色時列出條件，不主動拾取地圖物品。
	使用範例：
	```lua
	-- 開啟介面的「自動完成活動任務」，可同時開啟釣魚取得缺少角色。
	-- 自動出售先更新保留名單；任務鏈全部完成或 NPC 離場後解除對應保護。
	```
]]
function _EventQuests.Step(): ()
	local Key = "bAutoEventQuests"
	if not _EventQuests.Refresh() then return end
	local Entries, Waiting, OpenCount = _EventQuests.Entries, {}, 0
	local Summary
	for Offset = 1, #Entries do
		local Index = (_EventQuests.Cursor + Offset - 1) % #Entries + 1
		local Entry = Entries[Index]
		local State, Definition = Entry.State, Entry.Definition
		if State.claimed == true or State.locked == true then continue end
		OpenCount += 1
		local Missing = {}
		for _, Task in Definition.Tasks or {} do
			local Progress, Goal = tonumber((State.progress or {})[tostring(Task.Id or "")]) or 0, tonumber(Task.Goal) or 1
			if Progress < Goal then table.insert(Missing, tostring(Task.Id or "任務") .. " " .. Progress .. "／" .. Goal) end
		end
		if not Controller[Key] or not _Runtime.bAlive then return end
		if _NpcRewardReady(Definition, State) then
			_EventQuests.Cursor = Index
			local Result, Reason = _Invoke("NpcQuestClaim", Entry.Id)
			assert(type(Result) == "table", "活動任務領獎回應格式已變更")
			_EventQuests.bReady = false
			_EventQuests.Show(if Result.claimed == true then "已完成活動任務：" .. Entry.Id else "活動任務尚未確認完成：" .. tostring(Reason or Entry.Id))
			return
		end
		for _, Need in Definition.Characters or {} do
			if (tonumber((State.deposits or {})[Need.Name]) or 0) >= (tonumber(Need.Count) or 1) then continue end
			table.insert(Missing, Need.Name .. " " .. tostring((State.deposits or {})[Need.Name] or 0) .. "／" .. tostring(Need.Count or 1))
			if not Summary then Summary = _Invoke("BackpackCharSummaryGet") assert(type(Summary) == "table", "活動任務等待背包資料") end
			local bAvailable = false
			for _, Record in Summary do
				if type(Record) == "table" and Record.n == Need.Name and (tonumber(Record.c) or 0) > 0 then bAvailable = true break end
			end
			if not bAvailable then continue end
			if not Controller[Key] or not _Runtime.bAlive or not _EventQuests.Active()[Definition.Chain] then return end
			if _Runtime.CharacterApplying or _Runtime.WorkerGear then table.insert(Missing, "等待角色配置／手持角色操作完成後交付") continue end
			_EventQuests.Cursor = Index
			-- 對應角色卡原生 Add All：只指定該角色名稱，不使用跨角色 allchars。
			local Result, Reason = _Invoke("NpcQuestDeposit", Entry.Id, Need.Name, "all", nil)
			assert(type(Result) == "table", "活動任務角色交付回應格式已變更")
			_EventQuests.bReady = false
			local Before, After = tonumber((State.deposits or {})[Need.Name]) or 0, tonumber((Result.deposits or {})[Need.Name]) or 0
			_EventQuests.Show(if After > Before then "已交付活動角色：" .. Entry.Id .. "／" .. Need.Name .. "（" .. After .. "／" .. tostring(Need.Count or 1) .. "）"
				else "交付尚未確認：" .. Need.Name .. "／" .. tostring(Reason or "等待伺服器同步"))
			return
		end
		table.insert(Waiting, Entry.Id .. "：" .. table.concat(Missing, "；"))
	end
	if #Entries == 0 then _EventQuests.Show("目前沒有在場的支援活動任務") return end
	if OpenCount == 0 then _EventQuests.Show("活動任務已完成或等待前置階段解鎖") return end
	_EventQuests.Show("等待任務條件：\n" .. table.concat(Waiting, "\n"))
end
-- EVENT_QUESTS_END

--[[
	建立自動功能介面與遊戲事件；失敗時由入口統一釋放已建立的資源。
	使用範例：
	```lua
	-- 入口自動呼叫一次；重新執行先卸載舊控制器。
	-- 開啟介面開關後排程器才啟動對應工作。
	```
]]
local function _Initialize(): ()
	local bConfigAvailable, Missing = _ConfigCapabilities()
	assert(BjzUi.ConfigurationVersion == 2, "請同步更新 BjzUiLibrary_2.0.luau 後再執行")
	_Runtime.Window = BjzUi:CreateWindow({
		Name = "Fish an Anime Rng · BjzHub",
		Subtitle = "自動功能與效能設定 · BjzHub",
		ConfigId = "FishAnAnimeRng_" .. tostring(game.PlaceId), GameName = "FishAnAnimeRng", GameId = game.PlaceId, LegacyConfigIds = { "FishAnAnimeRng_" .. LocalPlayer.UserId .. "_" .. game.PlaceId },
		Width = 860,
		Height = 660,
		ConfigurationSaving = { bEnabled = bConfigAvailable },
		DefaultFlags = DEFAULT_GAME_SETTINGS.Flags, DefaultUI = DEFAULT_GAME_SETTINGS.UI,
		OnUnload = Controller.Unload,
	})
	local Window = _Runtime.Window
	assert(type(Window.LoadConfiguration) == "function" and type(Window.SaveConfiguration) == "function",
		"遠端 BjzUi 缺少設定保存／載入 API")
	assert(
		Window.ScreenGui and Window.ScreenGui:IsDescendantOf(UIParent),
		"BjzUi 未掛在 gethui()，請確認遠端 UI 版本"
	)
	local Tabs, GroupsByFeature, Cards, CardCounts = {}, {}, {}, {}
	for _, Group in UI_GROUPS do
		Tabs[Group.Key] = Window:CreateTab(Group.Name, Group.Icon)
		CardCounts[Group.Key] = 0
		for _, Key in Group.Features do
			assert(not GroupsByFeature[Key], "功能重複分類：" .. Key)
			GroupsByFeature[Key] = Group.Key
		end
	end
	for _, Feature in _Features do
		local GroupKey = GroupsByFeature[Feature.Key]
		assert(GroupKey and Tabs[GroupKey], "功能尚未分類：" .. Feature.Key)
		CardCounts[GroupKey] += 1
		local Section = Tabs[GroupKey]:CreateSection({ Name = Feature.Name, Side = if CardCounts[GroupKey] % 2 == 1 then "left" else "right" })
		Cards[Feature.Key] = Section
		Controller[Feature.Key] = false
		Controller.Intervals[Feature.Key] = Feature.Interval
		--[[
			由開關事件切換對應工作。
			@param bValue true 開啟；false 關閉並還原暫時狀態。
		]]
		_Runtime.Controls[Feature.Key] = _Setting(Section, "CreateToggle", {
			Name = Feature.Name,
			Flag = Feature.Key,
			bCurrentValue = false,
			Callback = function(bValue)
				_SetEnabled(Feature.Key, bValue == true)
			end,
		})
		_Runtime.Labels[Feature.Key] = Section:CreateLabel("已關閉")
		--[[
			套用該功能的執行間隔，不切換開關或中斷目前操作。
			@param Value 下一輪等待秒數。
		]]
		_Setting(Section, "CreateSlider", {
			Name = Feature.Name .. "間隔", Description = "每輪完成後的等待秒數",
			Flag = Feature.Key .. "_Interval", Range = { 0.1, 300 }, Increment = 0.01,
			Suffix = "秒", CurrentValue = Feature.Interval,
			Callback = function(Value) _SetInterval(Feature, Value) end,
		})
	end
	local Options = Tabs.Settings:CreateSection({ Name = "全域設定與保存", Side = "right" })
	do
		local Rendering = Tabs.Settings:CreateSection({ Name = "3D 渲染", Side = "left" })
		_Performance.RenderingLabel = Rendering:CreateParagraph({ Title = "3D 渲染狀態", Content = "3D 渲染已開啟" })
		_Performance.RenderingControl = _Setting(Rendering, "CreateToggle", {
			Name = "關閉 3D 渲染", Flag = "bDisable3dRendering", bCurrentValue = false,
			Description = "閒置時使用此選項；釣魚期間持續關閉 3D，停止釣魚並開始其他移動／載入後才開啟。",
			--[[ @param bDisabled 閒置時是否關閉 3D；工作期間由自動策略決定，失敗時回復前次選項。 ]]
			Callback = function(bDisabled)
				local bPrevious = Controller.bDisable3dRendering
				Controller.bDisable3dRendering = bDisabled == true
				local bOk = _Performance.SyncRendering()
				if not bOk then
					Controller.bDisable3dRendering = bPrevious
					_Performance.RenderingControl:Set(bPrevious, true)
				end
			end,
		})
	end
	--[[
		切換研究優先類別；優先類別沒有可用項目時仍可研究其他已解鎖且可負擔項目。
		@param Value 研究優先類別名稱。
	]]
	_UpgradePriority.CreateUi(Cards.bAutoUpgrade)
	_Setting(Cards.bAutoUpgrade, "CreateSlider", { Name = "轉生存錢門檻", Flag = "UpgradeRebirthSavePercent",
		Range = { 0, 100 }, Increment = 1, Suffix = "%", CurrentValue = Controller.UpgradeRebirthSavePercent,
		--[[ @param Value 目前資金達下一次轉生費用的百分比後停止升級。 ]]
		Callback = function(Value) Controller.UpgradeRebirthSavePercent = math.clamp(tonumber(Value) or 80, 0, 100) end })
	Cards.bAutoUpgrade:CreateParagraph({ Title = "升級與轉生資金", Content = "自動轉生開啟時，達到存錢門檻後停止升級，保留金錢直到完成轉生；預設80%。低於門檻時按順位與價格加權升級。自動轉生關閉時維持原本升級方式。" })
	_Setting(Cards.bAutoResearch, "CreateDropdown", {
		Name = "研究優先條件", Flag = "ResearchPriority", CurrentOption = Controller.ResearchPriority,
		Options = { "金錢項目優先", "藥水項目優先", "自動項目優先", "食物項目優先", "角色項目優先", "建築項目優先", "最低費用優先" },
		Callback = function(Value) if RESEARCH_PRIORITIES[Value] then Controller.ResearchPriority = Value end end,
	})
	_Runtime.ResearchLabel = Cards.bAutoResearch:CreateParagraph({ Title = "進行中的研究", Content = "尚未同步研究資料" })
	--[[
		獨立設定研究的 Gems 許可，舊設定沒有此欄位時預設允許，不更動買藥的既有許可。
		@param bValue true 研究可使用 Gems；false 只挑選不需 Gems 的研究。
	]]
	_Setting(Cards.bAutoResearch, "CreateToggle", {
		Name = "允許研究花費鑽石", Flag = "bResearchAllowGems", bCurrentValue = true,
		Description = "預設開啟，只適用自動研究；仍會確認 Cash 與 Gems 足夠。",
		Callback = function(bValue) Controller.bResearchAllowGems = bValue == true end,
	})
	_Runtime.ResearchSelectionLabel = Cards.bAutoResearch:CreateParagraph({ Title = "研究篩選狀態", Content = "開啟自動研究後列出已解鎖項目、費用與排除原因" })
	Cards.bAutoResearch:CreateParagraph({ Title = "研究選擇", Content = "先排除已完成、研究中、前置未解鎖及無法負擔的項目，再按優先類別、Cash、Gems 與項目 ID 排序。優先類別沒有可用項目時會研究其他可用項目；研究預設允許使用 Gems，可由本卡獨立關閉。倒數使用伺服器完成時間，歸零後等待遊戲確認。" })
	_Runtime.NativeAutoFishLabel = Cards.bAutoFish:CreateLabel({ Name = "Auto Fish 狀態", bSave = false })
	_NativeAutoFishStatus("隨自動釣魚維持開啟；未解鎖不購買")
	Cards.bAutoFish:CreateParagraph({ Title = "連續釣魚", Content = "每回合完成並結束揭曉後會接著拋竿。收集食物、餵食、蓋家或派工找到可操作目標時，先暫停釣魚並等待取消確認，再前往操作；完成後回到岸邊接續釣魚。研究直接在原地開始，不中斷釣魚。" })
	Cards.bAutoFish:CreateParagraph({ Title = "內建 Auto Fish", Content = "自動釣魚回合中會持續確認並開啟內建 Auto Fish，意外關閉時自動補開，無須額外開關。尚未解鎖不購買；等待拋竿確認、位移及特殊揭曉時暫停。停止自動釣魚時，只還原本腳本開啟的內建狀態。" })
	_Runtime.ConfigLabel = Options:CreateLabel({ Name = "設定保存狀態", bSave = false })
	Options:CreateParagraph({
		Title = "使用方式",
		Content = "自動收集食物與自動餵食是獨立開關，可單獨或同時開啟。收集前往菜園，餵食只使用現有 Food 前往角色，完成後各自返回；與釣魚及派工依序移動。研究在原地開始，可與其他操作並行。先選藥水再買藥／喝藥；升級商店消耗 Cash。",
	})
	Options:CreateParagraph({ Title = "執行間隔", Content = "每個自動功能的開關旁都有獨立間隔滑桿，可設定 0.1～300 秒並自動保存。這是每輪完成後的等待時間；調整不會中斷目前操作，遊戲本身的冷卻及移動等待仍會生效。" })
	Cards.bLowEffects:CreateParagraph({ Title = "效能模式", Content = "接入共用 PerformanceEngine：調低畫質、材質、陰影、反射與裝飾特效。3D 畫面由獨立開關控制；保留遊戲 UI、釣魚按鈕、角色、碰撞與互動物件，不刪除 Instance。關閉或卸載時還原仍由本模式持有的屬性；已清除的粒子不會重建。" })
	Cards.bPreventAutoRejoin:CreateParagraph({ Title = "閒置重連保護", Content = "停用遊戲 AutoRejoinClient 的閒置重新加入要求，保留原生防閒置。關閉或卸載會恢復本功能停用的腳本。伺服器關閉、網路斷線及平台強制離線仍可能中斷連線。" })
	Cards.bDeleteUiEffects:CreateParagraph({ Title = "永久 UI 特效清理", Content = "刪除 Food／Gems／Cash 飛散圖示及其獨立特效腳本、已確認的商店流星粒子、光芒旋轉與促銷文字縮放動畫腳本。保留數值顯示、按鈕、提示、品質顏色、靜態圖示與釣魚介面。預設關閉；開啟後監聽新特效。關閉只停止後續清理，已刪除項目須重新加入遊戲才能恢復；資源收集附帶的裝飾音效也會停止。" })
	Cards.bAutoSkipTutorial:CreateParagraph({ Title = "原生跳過教學", Content = "預設開啟，依遊戲原生 Skip Tutorial 按鈕及專用確認視窗跳過，保留教學結束時的相機、移動及 UI 還原。已完成教學時不操作，不接受其他購買／轉生確認視窗。" })
	Cards.bSuppressGameplayPause:CreateParagraph({ Title = "暫停保護", Content = "預設開啟：隱藏原生 Gameplay Paused 通知，嘗試停用串流完整性暫停；仍暫停時請求載入玩家附近場景。權限不足會顯示未成功的部分。保留地面與位置確認，不修改唯讀暫停狀態。關閉或卸載還原原設定。" })
	Cards.bBlockPlatformPrompts:CreateParagraph({ Title = "平台彈窗範圍", Content = "預設開啟：阻擋本遊戲用戶端發起的 Robux 商品／GamePass 購買、加入社群、活動 RSVP、通知許可與遊戲邀請。一般遊戲確認、Cash／Gems 購買、教學與錯誤提示保留。不刪除 CoreGui；已開啟、伺服器或平台直接顯示的視窗可能仍須手動關閉。缺少所需能力時顯示原因。" })
	Cards.bAutoWorkers:CreateParagraph({ Title = "自動派工", Content = "家中配置優先：自動裝備計算或換位時暫停派遣；確認完成後，保留目標角色名單，再從剩餘閒置背包選人。已放在家中與尚待部署的目標都不派走；背包改變先重新規劃。攤位看品質及 Gems 變異，Dock 看品質，Garden 試工比較食物產量。工作角色入選家中方案時先確認卸任再召回。" })
	_Runtime.WorkerLabel = Cards.bAutoWorkers:CreateParagraph({ Title = "派工同步狀態", Content = "尚未進行派工" })
	_Runtime.PairLabel = Cards.bAutoCharacters:CreateParagraph({ Title = "配對收益與配置", Content = "比較背包、家中及正在派遣的角色，計入全部58組與原生配對、等級、變異和同排相鄰收益。方案需要工作角色時先確認卸任，再調整家中配置；完整搜尋後才換位，不以品質或連結數取代收益。" })
	Cards.bAutoRebirth:CreateParagraph({ Title = "轉生前全部餵食", Content = "有食物時，依序對準備開始時家中的已放置角色各嘗試一次全部餵食；無須開啟一般自動餵食，也不更動其設定。單隻最多等3秒、整輪最多30秒；食物不足、提示不可用或超時都不會阻擋轉生，不等待食物歸零。" })
	_Runtime.CharacterDebugLabel = Cards.bAutoCharacters:CreateParagraph({ Title = "Debug 複製狀態", Content = "發現配置收益不符預期時，按下按鈕並將完整報告貼回對話。" })
	Cards.bAutoLimitedShop:CreateParagraph({ Title = "限時商店購買範圍", Content = "支援 Selene、Angelia、Yang、Sasha，輪流購買可用且可負擔的商品，每輪最多一件。原地查詢未開放但地圖 NPC 已在場時，會靠近重查，操作後返回並接續釣魚。依各店原生購買方式使用 Cash／Gems；鑽石預設禁止，使用下方共用許可。單一商店未出現或查詢失敗不阻擋其他商店，不觸發 Robux。" })
	for _, Store in LIMITED_SHOPS do
		_Runtime.LimitedShopLabels[Store.Key] = Cards.bAutoLimitedShop:CreateParagraph({ Title = Store.Name .. " 商店狀態", Content = "尚未查詢" })
	end
	--[[
		切換四種限時商店的共用鑽石許可，不影響一般買藥或研究設定。
		@param bValue true 允許限時商品使用 Gems；false 僅允許 Cash。
	]]
	_Setting(Cards.bAutoLimitedShop, "CreateToggle", {
		Name = "限時商店允許使用鑽石", Flag = "bLimitedShopAllowGems", bCurrentValue = false,
		Callback = function(bValue) Controller.bLimitedShopAllowGems = bValue == true end,
	})
	Cards.bAutoCharacters:CreateButton({ Name = "複製 Debug 資訊", Callback = _CharacterPairs.CopyDebug })
	Cards.bAutoFeed:CreateParagraph({ Title = "餵食排序", Content = "平均分配：可餵食角色中先選品質最高者，同品質選等級最低者，再以較久未餵食者優先。直接依目前已裝備角色判斷，裝備功能以金錢收益選角；餵食設定獨立。" })
	Cards.bAutoMapPickup:CreateParagraph({ Title = "拾取範圍", Content = "每輪依序傳送，處理本輪開始時可拾取的全部活動鑽石、Amnetic Coin、糖果、一般地面道具、Love Essence／Sakura Leaf 及任務物品。排除地圖角色、角色工具和角色模型。整輪結束才返回並接續釣魚，預設等待 60 秒；新生成物留到下一輪。觸碰後仍留在原處且未取得結果的物件會暫停重試，重開功能可再試。不操作商店、建築、展台角色或菜園食物。" })
	Cards.bAutoBoxes:CreateParagraph({ Title = "開 Box 說明", Content = "開啟後會依序消耗背包現有的所有種類 Box，每輪依遊戲批次上限開啟；開箱動畫中等待。不購買 Box。" })
	Cards.bAutoNpcRewards:CreateParagraph({ Title = "領取範圍", Content = "只領取已符合條件的獎勵。NPC／活動任務不自動交付角色或支付鑽石；每個開關皆自動保存。" })
	Cards.bAutoEventQuests:CreateParagraph({ Title = "活動任務與角色保留", Content = "支援在場 Amnesia／Halloween 任務：原地交付需求角色並領獎，不主動撿取地圖物品。開啟後，自動出售保留所有未完成階段需要的同名角色（含變異），活動完成或 NPC 離場後解除。角色交付會消耗背包角色；缺少時可搭配自動釣魚。" })
	_Runtime.EventQuestLabel = Cards.bAutoEventQuests:CreateParagraph({ Title = "活動任務進度", Content = "尚未查詢" })
	--[[
		保留買藥的既有 Gems 許可，不再控制研究。
		@param bValue true 買藥允許 Gems；false 只用 Cash。
	]]
	_Setting(Cards.bAutoBuyPotions, "CreateToggle", {
		Name = "允許自動花費鑽石",
		Description = "只適用自動買藥；研究使用獨立設定。",
		Flag = "bAllowGems",
		bCurrentValue = false,
		Callback = function(bValue)
			Controller.bAllowGems = bValue == true
		end,
	})
	--[[
		切換角色餵食策略，不更動已累計的食物消耗紀錄。
		@param Value 平均分配或最高品質優先；保留舊版儲存值，只更新顯示名稱與控制器策略。
	]]
	_Setting(Cards.bAutoFeed, "CreateDropdown", {
		Name = "餵食分配模式", Options = { "平均分配", { Name = "最高品質優先", Value = "只餵最強角色" } }, CurrentOption = Controller.FeedMode,
		Flag = "FeedMode",
		Callback = function(Value)
			if Value == "平均分配" then Controller.FeedMode = Value
			elseif Value == "只餵最強角色" or Value == "最高品質優先" then Controller.FeedMode = "最高品質優先" end
		end,
	})
	--[[
		選擇原生全部餵食或單次升級，保留舊設定沒有此欄位時的全部餵食預設值。
		@param Value 全部餵食或一個一個餵；其餘值不採用。
	]]
	_Setting(Cards.bAutoFeed, "CreateDropdown", { Name = "餵食方式", Options = { "全部餵食", "一個一個餵" },
		CurrentOption = Controller.FeedAction, Flag = "FeedAction",
		Callback = function(Value)
			if Value == "全部餵食" or Value == "一個一個餵" then Controller.FeedAction = Value end
		end,
	})
	_Runtime.FeedLabel = Cards.bAutoFeed:CreateParagraph({ Title = "餵食判斷", Content = "開啟後顯示目標角色、Food、原生提示費用與判斷來源" })
	Options:CreateButton({ Name = "卸載腳本", Callback = Controller.Unload })
	local SellSection = Cards.bAutoSellCharacters
	SellSection:CreateParagraph({ Title = "英文品質清單", Content = table.concat(_RarityOptions, "、") })
	SellSection:CreateParagraph({ Title = "出售方式", Content = "先多選品質，再開啟「自動賣角色」。未解鎖 Sell Rarity 時從背包逐組出售，略過收藏及裝備中的角色；解鎖後按品質出售。已出售角色無法復原。" })
	--[[
		只保留多選清單中實際存在的英文品質，空選取代表完全不出售。
		@param Selection 使用者勾選的品質名稱陣列，nil 表示清空。
	]]
	_Setting(SellSection, "CreateDropdown", { Name = "要出售的角色品質", Options = _RarityOptions,
		bMulti = true, bSearchable = true, CurrentOption = {}, Flag = "SellRarities",
		Callback = function(Selection)
			local Selected = {}
			if type(Selection) == "table" then
				for _, Name in Selection do
					if type(Name) == "string" and _KnownRarities[Name] then Selected[Name] = true end
				end
			end
			Controller.SellRarities = Selected
		end,
	})
	local Potions = Tabs.Items:CreateSection({ Name = "允許購買／飲用的藥水", Side = "right" })
	--[[
		選取所有藥水，同步白名單及可保存控制項。
	]]
	Potions:CreateButton({ Name = "全選藥水", Callback = function() _SetAllPotions(true) end })
	--[[
		取消所有藥水選取，不關閉其他功能。
	]]
	Potions:CreateButton({ Name = "全取消藥水", Callback = function() _SetAllPotions(false) end })
	for Key, Definition in (Constants.Potions or {}).Definitions or {} do
		--[[
			設定買藥與喝藥的共同白名單。
			@param bValue true 選取；false 不自動消耗該藥水。
		]]
		_Runtime.PotionControls[Key] = _Setting(Potions, "CreateToggle", {
			Name = Definition.ToolName or Key,
			Flag = "Potion_" .. Key,
			bCurrentValue = false,
			Callback = function(bValue)
				Controller.PotionKeys[Key] = bValue == true
			end,
		})
	end
	table.insert(_Runtime.Connections, _Remote("FishingState", "RemoteEvent").OnClientEvent:Connect(_OnFishingState))
	local ResearchUpdate = Remotes:FindFirstChild("ResearchUpdate")
	if ResearchUpdate and ResearchUpdate:IsA("RemoteEvent") then
		table.insert(_Runtime.Connections, ResearchUpdate.OnClientEvent:Connect(_ApplyResearchState))
	end
	local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")
	local MainGui = PlayerGui and PlayerGui:FindFirstChild("MainGui")
	local FishAction = MainGui and MainGui:FindFirstChild("FishAction")
	if FishAction and FishAction:GetAttribute("FishingUiOpen") == true then
		_Runtime.FishPhase, _Runtime.FishChangedAt = "Waiting", os.clock()
	end
	local bLoaded, LoadReason = false, nil
	if bConfigAvailable then bLoaded, LoadReason = Window:LoadConfiguration(true) end
	-- 全部介面與事件已就緒；靜默載入不會發回呼，必須先同步選項再讓排程器啟動。
	for _, Binding in _Runtime.Settings do Binding.Apply(Binding.Control:Get()) end
	_UpgradePriority.Load()
	_Runtime.ConfigMessage = if not bConfigAvailable then "自動保存停用：缺少 " .. Missing
		elseif bLoaded then "已自動載入設定；變更後約 1.5 秒自動保存"
		elseif Window.LastConfigError then "設定載入失敗：" .. tostring(LoadReason)
		else "首次使用預設設定；變更後約 1.5 秒自動保存"
	_ConfigStatus()
end

--[[
	執行單輪工作，不阻塞其他功能；完成後依間隔重啟，派工前置等待則短暫重試。
	@param Feature 包含 Step、Key 與 Interval 的功能定義。
]]
local function _RunFeature(Feature): ()
	_Runtime.StartedAt[Feature.Key] = os.clock()
	--[[
		執行本輪，錯誤顯示於對應功能狀態並清理餵食位移。
	]]
	_Runtime.Jobs[Feature.Key] = task.defer(function()
		-- 輪詢與條件檢查不開啟渲染；實際位移、按鈕或操作請求才取得保留權。
		local bOk, Reason = pcall(Feature.Step)
		if not bOk then
			if Feature.Key == "bAutoRebirth" then _RebirthFood.Cancel() end
			if Feature.Key == "bAutoBuild" then _ReleaseBuildTouch() end
			if Feature.Key == "bAutoMapPickup" then _MapPickup.ReleaseTouch("bAutoMapPickup") _MapPickup.ProgressAt = nil end
			if Feature.Key == "bAutoEventQuests" then _EventQuests.bReady = false end
			if Feature.Key == "bAutoWorkers" then _Runtime.WorkerWait = nil _RestoreWorkerGear() end
			if Feature.Key == "bAutoCharacters" then
				if _Runtime.HomeReservations then _Runtime.HomeReservations.bReady = false end
				if _Runtime.WorkerGear and _Runtime.WorkerGear.Feature == Feature.Key then _RestoreWorkerGear() end
				_Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil
				_Runtime.bCharacterContinue = false
			end
			_RestoreMove(Feature.Key)
			_Status(Feature.Key, "錯誤：" .. tostring(Reason))
		end
		_Runtime.FinishedAt[Feature.Key] = os.clock()
		_Runtime.RetryNotBefore[Feature.Key] = nil
		local Delay = if Feature.Key == "bAutoCharacters" and _Runtime.bCharacterContinue then 0.1 else Feature.Interval
		-- 等待前置操作不算完成一輪；避免家中配置與派工在相同長間隔反覆相撞。
		if Feature.Key == "bAutoWorkers" and _Runtime.WorkerWait then Delay = math.min(1, Feature.Interval) end
		_Runtime.RetryAt[Feature.Key] = _Runtime.FinishedAt[Feature.Key] + Delay
		_Runtime.Jobs[Feature.Key] = nil
		_Performance.EndInteraction(Feature.Key)
		if bOk and Feature.Key == "bAutoCharacters" then _CharacterPairs.WakeWorkers() end
	end)
end

_Features[1].Step, _Features[2].Step, _Features[3].Step = _Rebirth, _Fish, _EquipRod
_Features[4].Step, _Features[5].Step, _Features[6].Step = _EquipCharacters, _Feed, _BuyPotions
_Features[7].Step, _Features[8].Step, _Features[9].Step = _DrinkPotions, _Research, _Upgrade
_Features[10].Step = _SellCharacters
_Features[11].Step = _LowEffects
_Features[12].Step = _BuyBestRod
_Features[13].Step, _Features[14].Step = _QuestRewards, _IndexRewards
_Features[15].Step, _Features[16].Step = _DailyRewards, _PlaytimeRewards
_Features[17].Step, _Features[18].Step = _InboxRewards, _MedalRewards
_Features[19].Step, _Features[20].Step = _NpcRewards, _OfflineRewards
_Features[21].Step = _LeaveRewards
_Features[22].Step = _Build
_Features[23].Step, _Features[24].Step = _Workers, _OpenBoxes
_Features[25].Step = _CollectFood
_Features[26].Step = _MapPickup.Step
_Features[27].Step = _BuyLimitedShop
_Features[28].Step = _EventQuests.Step
_Features[29].Step = _Rejoin.Step
_Features[30].Step = _UiEffects.Step
_Features[31].Step = _Tutorial.Step
_Features[32].Step = _ClientUi.PauseStep
_Features[33].Step = _ClientUi.PromptStep
Environment.FishAnAnimeRngBjz = Controller
local bInitialized, InitializationError = pcall(_Initialize)
if not bInitialized then
	Controller.Unload()
	error("Fish RNG 初始化失敗：" .. tostring(InitializationError))
end

--[[
	啟動已開啟功能，地圖拾取二十秒無新進度或其他工作超過二十秒時取消；逾時不假設成功。
]]
_Runtime.Jobs.Scheduler = task.defer(function()
	while _Runtime.bAlive do
		_ConfigStatus()
		_RenderResearchProgress()
		-- 保持原生開關的檢查輕量且同步，不另建背景工作或可保存開關。
		local bNativeOk, NativeReason = pcall(_MaintainNativeAutoFish)
		if not bNativeOk then _NativeAutoFishStatus("維持開啟失敗：" .. tostring(NativeReason)) end
		local Now = os.clock()
		_Performance.SyncRendering()
		if _Runtime.CharacterDebugJob and Now - (_Runtime.CharacterDebugStartedAt or Now) > 20 then
			pcall(task.cancel, _Runtime.CharacterDebugJob)
			_Runtime.CharacterDebugJob = nil
			_Runtime.CharacterDebugLabel:Set("Debug 複製狀態", "收集資料逾時，請稍後重新按下複製")
		end
		for _, Feature in _Features do
			local Job = _Runtime.Jobs[Feature.Key]
			local ProgressAt = if Feature.Key == "bAutoMapPickup" then _MapPickup.ProgressAt or _Runtime.StartedAt[Feature.Key]
				elseif Feature.Key == "bAutoRebirth" then _Runtime.RebirthFoodProgressAt or _Runtime.StartedAt[Feature.Key] else _Runtime.StartedAt[Feature.Key]
			if Job and Now - ProgressAt > 20 then
				pcall(task.cancel, Job)
				if Feature.Key == "bAutoRebirth" then _RebirthFood.Cancel() end
				if Feature.Key == "bAutoBuild" then _ReleaseBuildTouch() end
				if Feature.Key == "bAutoMapPickup" then _MapPickup.ReleaseTouch("bAutoMapPickup") _MapPickup.ProgressAt = nil end
				if Feature.Key == "bAutoEventQuests" then _EventQuests.bReady = false end
				if Feature.Key == "bAutoWorkers" then _Runtime.WorkerWait = nil _RestoreWorkerGear() end
				if Feature.Key == "bAutoCharacters" then
					if _Runtime.HomeReservations then _Runtime.HomeReservations.bReady = false end
					if _Runtime.WorkerGear and _Runtime.WorkerGear.Feature == Feature.Key then _RestoreWorkerGear() end
					_Runtime.CharacterApplying, _Runtime.CharacterPlan = nil, nil
					_Runtime.bCharacterContinue = false
				end
				_Runtime.Jobs[Feature.Key], _Runtime.RetryAt[Feature.Key] = nil, Now + math.max(10, Feature.Interval)
				_Runtime.FinishedAt[Feature.Key], _Runtime.RetryNotBefore[Feature.Key] = Now, Now + 10
				_RestoreMove(Feature.Key)
				_Performance.EndInteraction(Feature.Key)
				_Status(Feature.Key, "等待伺服器逾時；依設定間隔重試，至少等待 10 秒；原操作可能仍已生效")
			elseif Controller[Feature.Key] and not Job and Now >= (_Runtime.RetryAt[Feature.Key] or 0)
				and (not _RebirthFood.bActive or Feature.Key == "bAutoRebirth" or Feature.Key == "bLowEffects" or Feature.Key == "bPreventAutoRejoin" or Feature.Key == "bDeleteUiEffects" or Feature.Key == "bAutoSkipTutorial" or Feature.Key == "bSuppressGameplayPause" or Feature.Key == "bBlockPlatformPrompts") then
				_RunFeature(Feature)
			end
		end
		task.wait(0.1)
	end
end)

return Controller

--!nonstrict
--[[
	離線驗證正式設定讀寫邏輯；所有檔案 API 都使用記憶體替身，不改動使用者設定。
]]
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Serde = require("@lune/serde")
local Source = Fs.readFile("Library/BjzUiLibrary_2.0.luau")
Luau.compile(Source)
local Files, Folders, Writes = {}, {}, {}
local FailurePath, FolderFailure
local Api = {
	--[[ @param Path 檔案路徑。 @return 是否存在。 ]]
	isfile = function(Path) return Files[Path] ~= nil end,
	--[[ @param Path 檔案路徑。 @return 已保存文字。 ]]
	readfile = function(Path) return assert(Files[Path]) end,
	--[[ @param Path 檔案路徑。 @param Value JSON 文字。 ]]
	writefile = function(Path, Value)
		assert(Path ~= FailurePath, "模擬寫入失敗")
		Files[Path] = Value
		table.insert(Writes, Path)
	end,
	--[[ @param Path 資料夾路徑。 @return 是否存在。 ]]
	isfolder = function(Path) return Folders[Path] == true end,
	--[[ @param Path 要建立的資料夾路徑。 ]]
	makefolder = function(Path)
		assert(not FolderFailure, "模擬建立資料夾失敗")
		Folders[Path] = true
	end,
}
local Environment = setmetatable({
	CONFIG_PATH = "BjzUi/UiConfig.json", CONFIG_FOLDER = "BjzUi", _ConfigFiles = {},
	_CopyTable = table.clone, game = { PlaceId = 74729868188364 },
	--[[ @param Name 檔案能力名稱。 @return 對應替身。 ]]
	_FileFunction = function(Name) return Api[Name] end,
	HttpService = {
		--[[ @param self 編碼服務。 @param Raw JSON 文字。 @return 解碼資料。 ]]
		JSONDecode = function(self, Raw) return Serde.decode("json", Raw) end,
		--[[ @param self 編碼服務。 @param Data 原始資料。 @return JSON 文字。 ]]
		JSONEncode = function(self, Data) return Serde.encode("json", Data) end,
	},
}, { __index = getfenv() })
local Start = assert(Source:find("local function _ReadConfig", 1, true))
local Finish = assert(Source:find("-- CONFIG_FILES_END", Start, true))
local Config = Luau.load(Source:sub(Start, Finish - 1) .. "\nreturn _ConfigFiles", { environment = Environment })()
local FishSource = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
Luau.compile(FishSource)
local PresetStart = assert(FishSource:find("-- GAME_DEFAULTS_START", 1, true))
local PresetEnd = assert(FishSource:find("-- GAME_DEFAULTS_END", PresetStart, true))
local Preset = Luau.load(FishSource:sub(PresetStart, PresetEnd - 1) .. "\nreturn DEFAULT_GAME_SETTINGS")()
local Info = Config.Layout({ GameName = "FishAnAnimeRng", DefaultFlags = Preset.Flags, DefaultUI = Preset.UI }, "Old_42")
assert(Info.Path == "BjzUi/FishAnAnimeRng/FishAnAnimeRng_74729868188364.json")
assert(Config.Layout({ GameName = "FishAnAnimeRng" }, "Old_99").Path == Info.Path, "玩家不影響路徑")
assert(Config.Layout({ GameName = "../A Test", GameId = 9 }, "x").Path == "BjzUi/ATest/ATest_9.json")
assert(not pcall(Config.Layout, { GameId = math.huge }, "x"))
local Loaded, Error, bFound = Config.Load(Info)
assert(Loaded and not Error and not bFound)
assert(Loaded.Flags.bAutoFish and Loaded.Flags.bAutoFeed and Loaded.Flags.bAutoRebirth)
assert(Loaded.Flags.bPreventAutoRejoin and Loaded.Flags.bPreventAutoRejoin_Interval == 15)
assert(Loaded.Flags.bDisable3dRendering == false and Loaded.Flags.bRenderingEnabled == nil)
assert(Loaded.Flags.bDeleteUiEffects == false and Loaded.Flags.bDeleteUiEffects_Interval == 60)
assert(Loaded.Flags.bSuppressGameplayPause == true and Loaded.Flags.bBlockPlatformPrompts == true)
assert(Loaded.Flags.bAutoSkipTutorial == true and Loaded.Flags.bAutoSkipTutorial_Interval == 2)
assert(Loaded.Flags.bAutoFish_Interval == 0.5 and Loaded.Flags.bAutoCharacters_Interval == 300)
assert(Loaded.Flags.FeedMode == "平均分配" and Loaded.Flags.FeedAction == "全部餵食")
assert(Loaded.Flags.UpgradePriority_1 == "T1O1" and Loaded.Flags.UpgradePriority_15 == "T4O1")
assert(Loaded.Flags.bAutoCollectFood == false and Loaded.Flags.bAllowGems == false)
assert(Loaded.Flags.bAutoNativeFish == nil and Loaded.Flags.CharacterPriority == nil)
local CommonPath = "BjzUi/UiConfig.json"
Files[CommonPath] = Serde.encode("json", { Version = 1, Windows = {
	Old_42 = { UI = { Scale = 1.2, Tab = "舊分頁" }, Flags = { bAutoFish = false } },
	OtherGame_123 = { Flags = { Secret = true } },
} })
Loaded = Config.Load(Info)
assert(Loaded.Flags.bAutoFish and Loaded.UI.Scale == 1.2 and Loaded.UI.Tab ~= "舊分頁", "舊檔只採用通用外觀")
Loaded.Flags.bAutoFish = false
Loaded.UI.Tab, Loaded.UI.Subtabs = "角色", { ["角色"] = "餵食" }
Loaded.UI.ExtraGameField = "不可存入共用檔"
local bSaved, Path = Config.Save(Info, Loaded)
assert(bSaved and Path == Info.Path)
assert(#Writes == 2 and Writes[1] == Info.Path and Writes[2] == CommonPath, "只寫入遊戲與共用檔，不備份")
assert(Folders.BjzUi and Folders["BjzUi/FishAnAnimeRng"])
local Common = Serde.decode("json", Files[CommonPath])
assert(Common.Windows.Shared.UI.Scale == 1.2 and Common.Windows.Shared.Flags == nil)
assert(Common.Windows.Shared.UI.Tab == nil and Common.Windows.Shared.UI.Subtabs == nil)
assert(Common.Windows.Shared.UI.ExtraGameField == nil and Common.Windows.Old_42 == nil)
local GameData = Serde.decode("json", Files[Info.Path])
assert(GameData.Flags.bAutoFish == false and GameData.UI.Tab == "角色" and GameData.UI.Scale == nil)
assert(GameData.GameName == "FishAnAnimeRng" and GameData.UserId == nil and GameData.Windows == nil)
Loaded, Error, bFound = Config.Load(Info)
assert(bFound and not Error and Loaded.Flags.bAutoFish == false and Loaded.UI.Subtabs["角色"] == "餵食")
assert(Preset.Flags.bAutoFish, "修改載入資料不得污染預設值")
local Other = Config.Layout({ GameName = "OtherGame", GameId = 123, DefaultFlags = { bEnabled = false } }, "Other")
local OtherData = Config.Load(Other)
assert(OtherData.Flags.bAutoFish == nil and OtherData.Flags.bEnabled == false)
OtherData.Flags.bEnabled = true
assert(Config.Save(Other, OtherData))
assert(Config.Load(Info).Flags.bAutoFish == false and Config.Load(Other).Flags.bEnabled)
local Original = Files[Info.Path]
Files[Info.Path] = "{corrupt"
local Count = #Writes
assert(Config.Load(Info) == nil and not Config.Save(Info, Loaded) and #Writes == Count)
Files[Info.Path] = Original
local OriginalCommon = Files[CommonPath]
Files[CommonPath] = Serde.encode("json", { Version = 99, Windows = {} })
assert(Config.Load(Info) == nil and not Config.Save(Info, Loaded) and #Writes == Count)
Files[CommonPath] = OriginalCommon
FailurePath = Info.Path
assert(not Config.Save(Info, Loaded) and #Writes == Count)
FailurePath = nil
Folders, FolderFailure = {}, true
assert(not Config.Save(Info, Loaded) and #Writes == Count)
FolderFailure = false
for _, Relative in {
	"Games/Isle/Isle_Bjz.luau", "Games/ThoseWhoRemain/ThoseWhoRemain_Bjz.luau",
	"Games/2PlayerRaidTycoon/2PlayerRaidTycoon_Bjz.luau", "Games/OWSawang/OW_Sawang_Bjz_v1.luau",
	"Games/SEAR/Sear_Bjz.luau", "Games/HexCardGame/HexCardGame_Bjz.luau",
	"Games/PixelLineage/PixelLineage_Bjz.luau", "Games/RagdollMultiplayer/Ragdoll_Multiplayer_Bjz_v1.luau",
} do
	local Entry = Fs.readFile(Relative)
	Luau.compile(Entry)
	assert(Entry:find("GameName =", 1, true) and Entry:find("ConfigurationVersion == 2", 1, true), Relative)
end
print("BjzUiConfiguration: split files, shared UI, presets, account independence, failures and entry syntax passed")

--!nonstrict
--[[
	以真實資料物件和排程／服務替身驗證共用引擎；不代表實際 GPU 效能或執行器權限已驗證。
]]
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Source = Fs.readFile("Core/Features/PerformanceEngine.luau")
Luau.compile(Source)
local Signals, Connections, Jobs = {}, {}, {}
--[[ @return 可追蹤連線生命週期的事件替身。 ]]
local function _Signal()
	local Signal = { List = {} }
	--[[ @param self 訊號。 @param Callback 回呼。 @return 可解除連線。 ]]
	function Signal.Connect(self, Callback)
		local Connection = { bConnected = true, Callback = Callback }
		--[[ @param self 要解除的連線。 ]]
		function Connection.Disconnect(self) self.bConnected = false end
		table.insert(self.List, Connection)
		table.insert(Connections, Connection)
		return Connection
	end
	--[[ @param self 訊號。 @param ... 事件參數。 ]]
	function Signal.Fire(self, ...)
		for _, Connection in self.List do if Connection.bConnected then Connection.Callback(...) end end
	end
	return Signal
end
--[[ @param Object 物件。 @return 此容器的新增事件。 ]]
Rbx.implementProperty("Instance", "DescendantAdded", function(Object)
	if not Signals[Object] then Signals[Object] = _Signal() end
	return Signals[Object]
end)
--[[ @param ClassName 類別。 @param Name 名稱。 @param Parent 容器。 @return 新資料物件。 ]]
local function _Object(ClassName, Name, Parent)
	local Object = Rbx.Instance.new(ClassName)
	Object.Name, Object.Parent = Name, Parent
	return Object
end
local World = _Object("Workspace", "Workspace")
local Lighting = _Object("Lighting", "Lighting")
local Core = _Object("Folder", "CoreGui")
local Hui = _Object("Folder", "HiddenUI", Core)
local Panel = _Object("ScreenGui", "BjzUi", Hui)
local NativeUi = _Object("PlayerGui", "PlayerGui")
local MainUi = _Object("ScreenGui", "MainGui", NativeUi)
local Button = _Object("TextButton", "AutoFish", MainUi)
local StarterGui = _Object("StarterGui", "StarterGui")
local TemplateUi = _Object("ScreenGui", "TemplateUi", StarterGui)
local Part = _Object("Part", "Pond", World)
Part.Material, Part.CastShadow, Part.Reflectance = Rbx.Enum.Material.Neon, true, 0.5
local Prompt = _Object("ProximityPrompt", "Feed", Part)
local Surface = _Object("SurfaceGui", "ResearchDisplay", Part)
local Script = _Object("LocalScript", "GameLogic", MainUi)
local Particle = _Object("ParticleEmitter", "Particle", Part)
Particle.Enabled = true
local Decal = _Object("Decal", "Art", Part)
Decal.Transparency = 0.25
local Mesh = _Object("MeshPart", "Character", World)
Mesh.TextureID = "rbxassetid://123"
local Shadow = Lighting.GlobalShadows
local QualitySignal = _Signal()
local QualityValue = Rbx.Enum.SavedQualitySetting.QualityLevel7
local QualityAccesses = 0
local Quality = setmetatable({
	--[[ @param self 畫質設定。 @param Property 目標屬性。 @return 屬性訊號。 ]]
	GetPropertyChangedSignal = function(self, Property) assert(Property == "SavedQualityLevel") return QualitySignal end,
}, {
	--[[ @param self 畫質設定。 @param Key 屬性名稱。 @return 保存畫質。 ]]
	__index = function(self, Key) if Key == "SavedQualityLevel" then return QualityValue end end,
	--[[ @param self 畫質設定。 @param Key 屬性。 @param Value 新值。 ]]
	__newindex = function(self, Key, Value)
		assert(Key == "SavedQualityLevel")
		if QualityValue ~= Value then QualityValue = Value QualitySignal:Fire() end
	end,
})
local Rendering = { QualityLevel = Rbx.Enum.QualityLevel.Level10 }
local Run = { bEnabled = true }
--[[ @param self 渲染服務。 @return 是否開啟 3D。 ]]
function Run.Is3dRenderingEnabled(self) return self.bEnabled end
--[[ @param self 渲染服務。 @param bEnabled 是否開啟 3D。 ]]
function Run.Set3dRenderingEnabled(self, bEnabled) self.bEnabled = bEnabled end
local Player = { ChildAdded = _Signal() }
--[[ @param self 玩家。 @param ClassName UI 類別。 @return 玩家 UI。 ]]
function Player.FindFirstChildOfClass(self, ClassName) assert(ClassName == "PlayerGui") return NativeUi end
local Services = { Players = { LocalPlayer = Player }, Workspace = World, Lighting = Lighting,
	RunService = Run, CoreGui = Core, StarterGui = StarterGui }
local Game = {}
--[[ @param self 遊戲。 @param Name 服務名稱。 @return 對應服務。 ]]
function Game.GetService(self, Name) return assert(Services[Name], Name) end
--[[ @param Callback 非同步工作。 @param ... 工作參數。 @return 排程執行緒。 ]]
local function _Schedule(Callback, ...)
	local Arguments = table.pack(...)
	--[[ 執行已保存參數的掃描或新增物件工作。 ]]
	local Thread = coroutine.create(function() Callback(table.unpack(Arguments, 1, Arguments.n)) end)
	table.insert(Jobs, Thread)
	return Thread
end
--[[ 執行非同步工作，保留 yield 行為以測試卸載中止。 ]]
local function _Drain()
	while #Jobs > 0 do
		local Thread = table.remove(Jobs, 1)
		if coroutine.status(Thread) ~= "dead" then
			local bOk, Error = coroutine.resume(Thread)
			assert(bOk, Error)
			if coroutine.status(Thread) ~= "dead" then table.insert(Jobs, Thread) end
		end
	end
end
local Environment = setmetatable({ Enum = Rbx.Enum,
	task = { spawn = _Schedule, defer = _Schedule, wait = coroutine.yield },
	--[[ @return 使用者畫質服務容器。 ]]
	UserSettings = function()
		QualityAccesses += 1
		return { --[[ @param self 容器。 @param Name 服務名稱。 @return 畫質設定。 ]]
			GetService = function(self, Name) assert(Name == "UserGameSettings") return Quality end }
	end,
	--[[ @return 渲染設定容器。 ]]
	settings = function() return { Rendering = Rendering } end,
}, { __index = getfenv() })
local EngineModule = Luau.load(Source, { environment = Environment })()
assert(EngineModule.SafeModeVersion == 1)
local Before = #World:GetDescendants()
local Engine = EngineModule.new({ Game = Game, bPreserveUi = true, bDeleteVisuals = false, bRenderingEnabled = true,
	bDeleteCoreGui = true, bDeleteGetHui = true, ProtectedRoots = { Panel } })
Engine.Start()
Engine.Start()
_Drain()
assert(Run.bEnabled and QualityValue == Rbx.Enum.SavedQualitySetting.QualityLevel1)
assert(Part.Material == Rbx.Enum.Material.Plastic and not Part.CastShadow and Part.Reflectance == 0)
assert(not Particle.Enabled and Decal.Transparency == 1 and Mesh.TextureID == "")
assert(#World:GetDescendants() == Before and Engine.DeletedCount == 0, "安全模式不可刪除物件")
assert(Button.Parent == MainUi and Script.Parent == MainUi and Prompt.Parent == Part and Surface.Parent == Part)
assert(TemplateUi.Parent == StarterGui and Panel.Parent == Hui, "安全模式保留全部 UI")
assert(Signals[NativeUi] == nil and Signals[StarterGui] == nil, "保留 UI 時不掃描 UI 容器")
local NewParticle = _Object("ParticleEmitter", "Streamed", Part)
NewParticle.Enabled = true
World.DescendantAdded:Fire(NewParticle)
_Drain()
assert(not NewParticle.Enabled and NewParticle.Parent == Part, "串流新增視覺元件只停用")
Quality.SavedQualityLevel = Rbx.Enum.SavedQualitySetting.QualityLevel8
assert(QualityValue == Rbx.Enum.SavedQualitySetting.QualityLevel1, "畫質變更仍維持低畫質")
Engine.SetUiCleanup(true, true)
_Drain()
assert(MainUi.Parent == NativeUi and Engine.DeletedCount == 0)
Part.Reflectance = 0.8
Engine.Destroy()
Engine.Destroy()
_Drain()
assert(Part.Material == Rbx.Enum.Material.Neon and Part.CastShadow and math.abs(Part.Reflectance - 0.8) < 0.00001)
assert(Particle.Enabled and NewParticle.Enabled and Decal.Transparency == 0.25 and Mesh.TextureID == "rbxassetid://123")
assert(QualityValue == Rbx.Enum.SavedQualitySetting.QualityLevel7 and Lighting.GlobalShadows == Shadow)
assert(Run.bEnabled and Rendering.QualityLevel == Rbx.Enum.QualityLevel.Level10)
for _, Connection in Connections do assert(not Connection.bConnected, "卸載不得留下事件") end
local Delayed = _Object("ParticleEmitter", "Delayed", Part)
Delayed.Enabled = true
local Canceled = EngineModule.new({ Game = Game, bPreserveUi = true, bDeleteVisuals = false, bRenderingEnabled = true })
Canceled.Start()
World.DescendantAdded:Fire(Delayed)
Canceled.Destroy()
_Drain()
assert(Delayed.Enabled and #Jobs == 0, "卸載後排程中的掃描及新增工作不得繼續寫入")
local Legacy = EngineModule.new({ Game = Game, ProtectedRoots = { Panel } })
Legacy.Start()
_Drain()
assert(not Run.bEnabled and Legacy.DeletedCount > 0, "未指定安全模式時保留原有通用入口行為")
assert(Panel.Parent == Hui, "舊模式仍保護指定面板")
Legacy.Destroy()
_Drain()
assert(Run.bEnabled)
assert(EngineModule.LowMemoryVersion == 1)
local QualityBefore, AccessesBefore = QualityValue, QualityAccesses
local LowMemory = EngineModule.new({ Game = Game, bLowMemory = true, bSetSavedQuality = false,
	bPreserveUi = true, bDeleteVisuals = false, bRenderingEnabled = false })
LowMemory.Start()
_Drain()
assert(QualityValue == QualityBefore and QualityAccesses == AccessesBefore, "AFK 模式不得讀取或寫入會保存的畫質設定")
local Burst = {}
for Index = 1, 2000 do
	local Value = _Object("ParticleEmitter", "Burst" .. Index, Part)
	Value.Enabled = true
	table.insert(Burst, Value)
	World.DescendantAdded:Fire(Value)
end
assert(#Jobs == 1 and LowMemory.Resources.Queued <= 256 and LowMemory.Resources.QueuePeak == 256,
	"低記憶體模式必須只有一個新增清理工作，且待處理物件數有上限")
_Drain()
for _, Value in Burst do assert(not Value.Enabled, "溢位合併重掃不能遺漏物件") end
LowMemory.Prune()
local ChangesBefore = LowMemory.Resources.Changes
for _, Value in Burst do Value:Destroy() end
LowMemory.Prune()
assert(LowMemory.Resources.Changes == ChangesBefore - #Burst, "被銷毀物件的還原紀錄必須釋放")
local Matching = _Object("Part", "AlreadyMinimal", World)
Matching.Material, Matching.CastShadow, Matching.Reflectance = Rbx.Enum.Material.Plastic, false, 0
local BeforeMatching = LowMemory.Resources.Changes
World.DescendantAdded:Fire(Matching)
_Drain()
LowMemory.Prune()
assert(LowMemory.Resources.Changes == BeforeMatching, "已符合目標的屬性不得重複寫入或保存無用還原紀錄")
local QueuedAtUnload = _Object("ParticleEmitter", "QueuedAtUnload", Part)
QueuedAtUnload.Enabled = true
World.DescendantAdded:Fire(QueuedAtUnload)
LowMemory.Destroy()
_Drain()
assert(LowMemory.Resources.Queued == 0 and QualityValue == QualityBefore and QueuedAtUnload.Enabled,
	"卸載必須清空佇列並阻止低記憶體工作繼續處理物件")
assert(EngineModule.UiCleanupVersion == 1)
local ClientUi = _Object("ScreenGui", "AfkClientUi", NativeUi)
local ClientFrame = _Object("Frame", "Panel", ClientUi)
local CoreUi = _Object("ScreenGui", "AfkCoreUi", Core)
local HiddenUi = _Object("ScreenGui", "AfkHiddenUi", Hui)
local StarterUi = _Object("ScreenGui", "AfkTemplateUi", StarterGui)
for Index = 1, 1000 do _Object("Part", "SceneBacklog" .. Index, World) end
local UiPriority = EngineModule.new({ Game = Game, bLowMemory = true, bSetSavedQuality = false,
	bDeleteCoreGui = true, bDeleteGetHui = true,
	--[[ @return 測試用隱藏 UI 容器。 ]]
	GetHui = function() return Hui end })
UiPriority.Start()
assert(not ClientUi.Parent and not ClientFrame.Parent and not CoreUi.Parent and not HiddenUi.Parent and not StarterUi.Parent,
	"啟動時必須立即永久刪除客戶端／CoreGui／隱藏／範本 UI，不等待場景佇列")
local SceneJob = Jobs[1]
local bSceneOk, SceneError = coroutine.resume(SceneJob)
assert(bSceneOk, SceneError)
assert(coroutine.status(SceneJob) == "suspended", "重現 1 FPS 場景仍分批清理的狀態")
local RebuiltUi = _Object("ScreenGui", "RebuiltUi", NativeUi)
local RebuiltFrame = _Object("Frame", "RebuiltFrame", RebuiltUi)
NativeUi.DescendantAdded:Fire(RebuiltUi)
NativeUi.DescendantAdded:Fire(RebuiltFrame)
assert(#Jobs == 2, "重建 UI 應只建立一個獨立優先工作")
local bUiOk, UiError = coroutine.resume(Jobs[2])
assert(bUiOk, UiError)
assert(not RebuiltUi.Parent and coroutine.status(SceneJob) == "suspended",
	"UI 重建後必須能在場景掃描完成前再次永久刪除")
_Drain()
local AfterUnloadUi = _Object("ScreenGui", "AfterUnloadUi", NativeUi)
NativeUi.DescendantAdded:Fire(AfterUnloadUi)
UiPriority.Destroy()
_Drain()
assert(AfterUnloadUi.Parent == NativeUi, "卸載後不得繼續刪除新 UI")
print("PerformanceEngine: safe UI/visuals, streamed objects, restoration, cancellation and legacy defaults passed")

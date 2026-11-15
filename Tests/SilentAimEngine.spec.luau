-- Run from repository root: lune run Tests/SilentAimEngine.spec.luau
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Vector3, CFrame, Ray = Rbx.Vector3, Rbx.CFrame, Rbx.Ray

--[[
	Lune 相機投影替身，固定投影倍率供幾何篩選測試；向量、CFrame、Ray 使用真實資料型別。
	@param self 被呼叫的相機。
	@param Point 測試世界座標。
	@return 確定性的畫面座標與相機深度。
	@return true 表示在測試 Viewport 內且位於相機前方，false 表示離屏。
]]
Rbx.implementMethod("Camera", "WorldToViewportPoint", function(self, Point)
	local Screen = Vector3.new(400 + Point.X * 5, 300 - Point.Y * 5, -Point.Z)
	return Screen, Screen.Z > 0 and Screen.X >= 0 and Screen.X <= 800 and Screen.Y >= 0 and Screen.Y <= 600
end)

--[[
	目前視線測試的可控制碰撞結果與記錄。
]]
local _Hit, _RayOrigin, _RayParams
--[[
	Lune 射線替身，記錄實際原點與排除參數，回傳目前測試的遮擋結果。
	@param self 被查詢的世界。
	@param Origin 射線起點。
	@param Direction 射線方向與長度。
	@param Params 排除設定。
	@return 測試指定的碰撞資料，nil 表示暢通。
]]
Rbx.implementMethod("Workspace", "Raycast", function(self, Origin, Direction, Params)
	_RayOrigin, _RayParams = Origin, Params
	return _Hit
end)

local World = Rbx.Instance.new("Workspace")
local Camera = Rbx.Instance.new("Camera")
Camera.CFrame = CFrame.new()
Camera.ViewportSize = Rbx.Vector2.new(800, 600)
World.CurrentCamera = Camera
--[[
	Lune 不提供 RaycastParams；回傳供射線替身讀取的參數容器。
	@return 可設定 FilterType、FilterDescendantsInstances 與 IgnoreWater 的表。
]]
local function _NewRaycastParams()
	return {}
end
--[[
	Lune 0.10.5 的 lookAt 在本環境回傳反向 LookVector，以正交基底重現 Rbx 的朝向約定。
	生產模組仍呼叫 Rbx 原生 CFrame.lookAt，此替身只補齊離線測試環境。
	@param Origin 座標框位置。
	@param Point 要面向的位置。
	@param Up 建立正交基底使用的上方向。
	@return LookVector 朝向 Point 的 CFrame。
]]
local function _LookAt(Origin, Point, Up)
	local Direction = (Point - Origin).Unit
	local Right = Direction:Cross(Up).Unit
	return CFrame.fromMatrix(Origin, Right, Right:Cross(Direction), -Direction)
end
local TestCFrame = table.clone(CFrame)
TestCFrame.lookAt = _LookAt
local Environment = setmetatable({
	workspace = World,
	Vector3 = Vector3,
	Vector2 = Rbx.Vector2,
	CFrame = TestCFrame,
	Ray = Ray,
	RaycastParams = { new = _NewRaycastParams },
	Enum = Rbx.Enum,
	Instance = Rbx.Instance,
	UDim = Rbx.UDim,
	UDim2 = Rbx.UDim2,
	Color3 = Rbx.Color3,
}, { __index = getfenv() })
local Source = Fs.readFile("Core/Features/SilentAimEngine.luau")
Luau.compile(Source)
local CSilentAimEngine = Luau.load(Source, { environment = Environment, debugName = "SilentAimEngine" })()

--[[
	每次 Select 都讀取的即時候選資料，可模擬死亡、投降、移動與自訂角色。
]]
local _Candidates = {}
--[[
	回傳目前候選快照。
	@param Context 本次射擊資料。
	@return 測試指定的候選陣列。
]]
local function _GetCandidates(Context)
	return _Candidates
end
--[[
	以測試候選的 Data 欄位模擬投降或敵友變更。
	@param Context 本次射擊資料。
	@param Candidate 要驗證的候選。
	@return true 為可選敵人，false 為投降／非敵人。
]]
local function _IsEligible(Context, Candidate)
	return Candidate.Data ~= "Surrendered"
end

local Engine = CSilentAimEngine.new({ World = World, GetCandidates = _GetCandidates, IsEligible = _IsEligible })
local Center = { Id = "Center", Point = Vector3.new(0, 0, -100), Health = 100 }
local Edge = { Id = "Edge", Point = Vector3.new(10, 0, -50), Health = 20 }
local Behind = { Id = "Behind", Point = Vector3.new(0, 0, 10), Health = 80 }
_Candidates = { Edge, Behind, Center }
local ShotData = { Origin = Vector3.zero }
assert(Engine:Select(ShotData) == nil, "Engine must start disabled")
Engine:Configure({ bEnabled = true })
local First = Engine:Select(ShotData)
assert(First, Engine:GetLastError())
assert(First.Candidate == Center, "Pixel priority must select closest reticle target")
Engine:Configure({ Priority = "Distance" })
assert(Engine:Select(ShotData).Candidate == Edge, "Distance priority must still honor front-facing FOV")
Engine:Configure({ Priority = "Health" })
assert(Engine:Select(ShotData).Candidate == Edge, "Health priority must select lowest health")
Engine:Configure({ FovMode = "Angle", FovAngle = 10, Priority = "Angle" })
assert(Engine:Select(ShotData).Candidate == Center, "Angle FOV must use half of full configured angle")
Engine:Configure({ FovMode = "All", Priority = "Distance" })
assert(Engine:Select(ShotData).Candidate == Behind, "360 mode must allow targets behind camera")
assert(Engine:Select({ Origin = Vector3.zero, Range = 5 }) == nil, "Weapon range must constrain selection")

Engine:Configure({ FovMode = "Pixels", Priority = "Screen", bSticky = true })
assert(Engine:Select(ShotData).Candidate == Center)
Center.Point, Edge.Point = Vector3.new(5, 0, -100), Vector3.new(0, 0, -50)
assert(Engine:Select(ShotData).Candidate == Center, "Sticky target must persist while valid")
Center.Data = "Surrendered"
assert(Engine:Select(ShotData).Candidate == Edge, "Sticky target must revalidate game eligibility")
Edge.Health = 0
assert(Engine:Select(ShotData) == nil, "Dead and surrendered targets must not be retained")
Center.Data, Edge.Health = nil, 20
Engine:Configure({ bSticky = false })

local Blocker = Rbx.Instance.new("Part")
Blocker.Parent = World
_Hit = { Instance = Blocker }
assert(Engine:Select(ShotData) == nil, "Blocked targets must be rejected")
_Hit = nil
local Muzzle = Vector3.new(3, 0, 0)
assert(Engine:Select({ Origin = Muzzle }))
assert(_RayOrigin == Muzzle, "Visibility must be checked from muzzle rather than camera")
assert(table.find(_RayParams.FilterDescendantsInstances, Camera), "Visibility must exclude current camera")

_Candidates = { Center }
Center.Point, Center.Velocity = Vector3.new(0, 0, -100), Vector3.new(10, 0, 0)
Engine:Configure({ bPrediction = true })
local Predicted = Engine:Select({ Origin = Vector3.zero, Speed = 100, Gravity = Vector3.new(0, -32.2, 0) })
assert(
	Predicted and Predicted.Point.X > 10 and Predicted.Point.Y > 16,
	"Prediction must lead target and compensate custom gravity"
)
local Hitscan = Engine:Select({ Origin = Vector3.zero, Latency = 0.1 })
assert(math.abs(Hitscan.Point.X - 1) < 0.001 and Hitscan.FlightTime == 0, "Hitscan latency must not invent flight time")
assert(
	Engine:Select({ Origin = Vector3.zero, Speed = 1 }) == nil,
	"Unreachable prediction horizon must reject solution"
)
assert(Engine:Select({ Origin = Vector3.new(0 / 0, 0, 0) }) == nil, "NaN origin must fail closed")
--[[
	自訂遊戲彈道覆寫，不要求使用內建固定重力模型。
	@param ShotData 本次射擊資料。
	@param Candidate 候選目標。
	@param Point 原始瞄準點。
	@return 遊戲指定的補償位置。
	@return 遊戲指定的飛行秒數。
]]
local function _CustomPrediction(ShotData, Candidate, Point)
	return Point + Vector3.yAxis * 20, 0.5
end
local CustomEngine = CSilentAimEngine.new({
	World = World,
	GetCandidates = _GetCandidates,
	Predict = _CustomPrediction,
}, { bEnabled = true, bPrediction = true })
assert(CustomEngine:Select(ShotData).Point.Y == 20, "Custom projectile simulation must override built-in prediction")
CustomEngine:Destroy()
local bConfigured = pcall(Engine.Configure, Engine, { FovMode = "Invalid" })
assert(not bConfigured and Engine:Select(ShotData), "Invalid configuration must not partially change working settings")
Engine:Configure({ bPrediction = false })
local Vertical = { Id = "Vertical", Point = Vector3.new(0, 100, 0) }
_Candidates = { Vertical }
Engine:Configure({ FovMode = "All" })
local Frame = Engine:RedirectFrame(CFrame.new(1, 0, 0))
assert(
	Frame.Position == Vector3.new(1, 0, 0) and Frame.LookVector.X == Frame.LookVector.X,
	"Vertical CFrame must remain finite and preserve origin"
)
_Candidates = { Center }
local UnitRay = Engine:RedirectRay(Ray.new(Vector3.zero, Vector3.xAxis))
assert(
	math.abs(UnitRay.Direction.Magnitude - 1) < 0.001 and UnitRay.Direction.Z < -0.99,
	"Unit camera ray length must not become weapon range"
)
local LongDirection = Engine:RedirectDirection(Vector3.zero, Vector3.xAxis * 500)
assert(math.abs(LongDirection.Magnitude - 500) < 0.001, "Ray vector magnitude must be preserved")

--[[
	只允許本機玩家的射擊實參；索引模擬 TWR 的第三個 file 資料。
	@param Values 本次要改寫的實參。
	@param Arguments 原始完整實參。
	@return true 為本機射擊，false 為其他玩家。
]]
local function _LocalShot(Values, Arguments)
	return Arguments[3] == "Local"
end
local FrameBinding = CSilentAimEngine.CreateBinding({
	Kind = "FrameDirection",
	ValueIndex = 4,
	DirectionIndex = 5,
	Matches = _LocalShot,
})
--[[
	測試原函數呼叫次數與完整實參／回傳值。
]]
local _Calls, _Seen = 0, nil
--[[
	保存完整射擊實參，並回傳含中間與尾端 nil 的多值。
	@param ... 原始射擊資料。
	@return 固定標記。
	@return nil 中間回傳值。
	@return 傳入實參數量。
	@return nil 尾端回傳值。
]]
local function _Original(...)
	_Calls += 1
	_Seen = table.pack(...)
	return "Result", nil, _Seen.n, nil
end
local Module = { Fire2 = _Original }
local Disconnect, Reason = Engine:BindMethod(Module, "Fire2", FrameBinding)
assert(Disconnect, Reason)
local OriginalFrame, OriginalDirection = CFrame.new(), Vector3.xAxis * 2
local Results = table.pack(Module.Fire2("Data", nil, "Local", OriginalFrame, OriginalDirection, nil, "UID", nil))
assert(
	_Calls == 1 and _Seen.n == 8 and _Seen[7] == "UID" and _Seen[8] == nil,
	"Argument count, UID and nils must survive"
)
assert(
	Results.n == 4 and Results[1] == "Result" and Results[2] == nil and Results[3] == 8 and Results[4] == nil,
	"All return values must survive"
)
assert(
	_Seen[4].Position == OriginalFrame.Position and _Seen[5].Z < -1.9,
	"Frame and direction must be aligned from one solution"
)
Module.Fire2("Data", nil, "Remote", OriginalFrame, OriginalDirection)
assert(_Seen[4] == OriginalFrame and _Seen[5] == OriginalDirection, "Other players' shots must remain unchanged")
local Duplicate = Engine:BindMethod(Module, "Fire2", FrameBinding, "Table")
assert(Duplicate == nil, "Duplicate method binding must be rejected")
Disconnect()
assert(Module.Fire2 == _Original, "Table binding must restore owned slot")

--[[
	明確允許測試用協定；正式遊戲應檢查真正的本機射擊狀態。
	@param Values 要處理的參數或回傳值。
	@param Arguments 原始實參。
	@return true 表示處理此次測試。
]]
local function _Allow(Values, Arguments)
	return true
end
local Command = { f = 1, fireIntent = 1, gunStateEpoch = 7, fo = Vector3.zero, fa = Vector3.xAxis, move = 9 }
--[[
	模擬 SEAR 的 GenerateCommand 回傳與額外尾端 nil。
	@return 原始移動／射擊指令。
	@return nil 額外回傳值。
]]
local function _GenerateCommand()
	return Command, nil
end
local Commands = { GenerateCommand = _GenerateCommand }
--[[
	只允許實際開火指令，排除移動、換彈與無武器狀態。
	@param Values 原函數產生的回傳值。
	@param Arguments 產生指令的原始參數。
	@return true 表示實際射擊，false 表示不修改。
]]
local function _FireIntent(Values, Arguments)
	local Value = Values[1]
	return Value.f == 1 and Value.fireIntent == 1 and Value.gunStateEpoch ~= 0
end
local CommandBinding = CSilentAimEngine.CreateBinding({
	Kind = "Command",
	Phase = "After",
	ValueIndex = 1,
	OriginField = "fo",
	AimField = "fa",
	AimLength = 2000,
	Matches = _FireIntent,
})
assert(Engine:BindMethod(Commands, "GenerateCommand", CommandBinding, "Table"))
Results = table.pack(Commands.GenerateCommand())
assert(
	Results.n == 2 and Results[1] ~= Command and Command.fa == Vector3.xAxis,
	"Command rewrite must clone payload and preserve results"
)
assert(
	Results[1].fo == Command.fo and Results[1].move == 9 and math.abs(Results[1].fa.Magnitude - 2000) < 0.01,
	"Command rewrite must preserve origin/movement and native aim length"
)
Command.fireIntent = 0
assert(Commands.GenerateCommand() == Command, "Non-firing commands must pass through")
Command.fireIntent = 1

local PositionBinding = CSilentAimEngine.CreateBinding({
	Kind = "Position",
	ValueIndex = 7,
	OriginIndex = 2,
	Matches = _Allow,
})
local Raid = { frame = _Original }
assert(Engine:BindMethod(Raid, "frame", PositionBinding, "Table"))
Raid.frame("Tool", Vector3.zero, 3, 4, nil, 6, Vector3.xAxis, nil)
assert(_Seen[7] == Center.Point and _Seen[3] == 3 and _Seen.n == 8, "Raid position mapping must only replace index 7")
local DirectionModule = { Cast = _Original }
local DirectionBinding = CSilentAimEngine.CreateBinding({
	Kind = "Direction",
	ValueIndex = 2,
	OriginIndex = 1,
	Matches = _Allow,
})
assert(Engine:BindMethod(DirectionModule, "Cast", DirectionBinding, "Table"))
DirectionModule.Cast(Vector3.zero, Vector3.xAxis * 300, "Params")
assert(
	math.abs(_Seen[2].Magnitude - 300) < 0.01 and _Seen[2].Z < -299 and _Seen[3] == "Params",
	"Direction-only protocols must preserve cast length and other fields"
)

local FrameOnly = { Discharge = _Original }
local FrameOnlyBinding = CSilentAimEngine.CreateBinding({ Kind = "Frame", ValueIndex = 2, Matches = _Allow })
assert(Engine:BindMethod(FrameOnly, "Discharge", FrameOnlyBinding, "Table"))
FrameOnly.Discharge("Service", OriginalFrame, "Caliber", "Barrel", "UID", true, true)
assert(
	_Seen[2].LookVector.Z < -0.99 and _Seen[3] == "Caliber" and _Seen[5] == "UID",
	"Discharge must preserve non-aim fields"
)

local CameraApi = {}
--[[
	回傳 Ragdoll 類型相機射線與其他回傳值。
	@param ... 相機原始參數。
	@return 相機單位射線。
	@return 額外標記，應保持不變。
]]
CameraApi.ScreenPointToRay = function(...)
	return Ray.new(Vector3.zero, Vector3.xAxis), "Extra"
end
local RayBinding = CSilentAimEngine.CreateBinding({ Kind = "Ray", Phase = "After", ValueIndex = 1, Matches = _Allow })
assert(Engine:BindMethod(CameraApi, "ScreenPointToRay", RayBinding, "Table"))
local Redirected, Extra = CameraApi.ScreenPointToRay(10, 10)
assert(Redirected.Direction.Z < -0.99 and Extra == "Extra", "Camera ray result mapping must preserve other returns")

--[[
	拋錯的遊戲適配器，用來驗證失敗不會重送射擊。
	@param Context 射擊上下文。
	@return 不會回傳；刻意拋出錯誤。
]]
local function _BrokenCandidates(Context)
	error("adapter failure")
end
local Broken = CSilentAimEngine.new({ World = World, GetCandidates = _BrokenCandidates }, { bEnabled = true })
local FailModule = { Fire = _Original }
assert(Broken:BindMethod(FailModule, "Fire", FrameOnlyBinding, "Table"))
local Before = _Calls
FailModule.Fire("Service", OriginalFrame)
assert(
	_Calls == Before + 1 and _Seen[2] == OriginalFrame and Broken:GetLastError(),
	"Adapter failure must pass through exactly once"
)

--[[
	模擬原始遊戲函數錯誤；引擎不得捕捉後再執行一次。
	@param ... 原始實參。
	@return 不會回傳；刻意拋出錯誤。
]]
local function _Throw(...)
	_Calls += 1
	error("original failure")
end
local ThrowModule = { Fire = _Throw }
assert(Engine:BindMethod(ThrowModule, "Fire", FrameOnlyBinding, "Table"))
Before = _Calls
local bOk = pcall(ThrowModule.Fire, "Service", OriginalFrame)
assert(not bOk and _Calls == Before + 1, "Original errors must propagate without duplicate calls")

--[[
	sUNC API 測試替身的函數儲存格；只驗證生命週期，不宣稱模擬原生閉包替換。
]]
local _Installed, _HookCount = nil, 0
--[[
	可透過測試儲存格接入的射擊入口。
	@param ... 原始實參。
	@return 目前 hook 或原函數的完整結果。
]]
local function _HookTarget(...)
	return (if _Installed then _Installed else _Original)(...)
end
--[[
	保存替身 hook 並回傳未被替換的原函數。
	@param Target 指定的射擊入口。
	@param Wrapper 要安裝的包裝函數。
	@return 原函數。
]]
Environment.hookfunction = function(Target, Wrapper)
	assert(Target == _HookTarget)
	_Installed, _HookCount = Wrapper, _HookCount + 1
	return _Original
end
--[[
	Lune 不提供原生 C closure，替身只回傳傳入函數。
	@param Callback 要包裝的函數。
	@return 原函數；測試不驗證原生 C closure 特性。
]]
Environment.newcclosure = function(Callback)
	return Callback
end
local HookClass = Luau.load(Source, { environment = Environment })()
local HookEngine = HookClass.new(
	{ World = World, GetCandidates = _GetCandidates },
	{ bEnabled = true, FovMode = "All" }
)
local Hooks = { Fire = _HookTarget }
local HookDisconnect = HookEngine:BindMethod(Hooks, "Fire", FrameOnlyBinding)
assert(HookDisconnect and _HookCount == 1 and Hooks.Fire == _HookTarget, "Auto mode must prefer sUNC when available")
Hooks.Fire("Service", OriginalFrame)
assert(_Seen[2].LookVector.Z < -0.99)
HookDisconnect()
Hooks.Fire("Service", OriginalFrame)
assert(_Seen[2] == OriginalFrame, "Detached function hook must become transparent")
local OtherEngine = HookClass.new(
	{ World = World, GetCandidates = _GetCandidates },
	{ bEnabled = true, FovMode = "All" }
)
assert(OtherEngine:BindFunction(_HookTarget, FrameOnlyBinding))
assert(_HookCount == 1, "Inactive function dispatchers must be reused")
HookDisconnect()
HookEngine:Destroy()
Hooks.Fire("Service", OriginalFrame)
assert(_Seen[2].LookVector.Z < -0.99, "Old disconnect or engine destruction must not disable new owner")
OtherEngine:Destroy()
Hooks.Fire("Service", OriginalFrame)
assert(_Seen[2] == OriginalFrame, "Destroy must disable all owned bindings")
Engine:Destroy()
assert(Commands.GenerateCommand == _GenerateCommand and Raid.frame == _Original, "Destroy must restore method slots")
Engine:Destroy()
assert(
	Engine:Select(ShotData) == nil and Engine:GetSelected() == nil,
	"Destroyed engine must not retain or select targets"
)
Broken:Destroy()

--[[
	模擬宣稱提供 C closure API 但呼叫失敗的 Executor。
	@param Callback 要包裝的函數。
	@return 不會回傳，模擬不相容實作。
]]
Environment.newcclosure = function(Callback)
	error("unsupported closure")
end
local FallbackClass = Luau.load(Source, { environment = Environment })()
local FallbackEngine = FallbackClass.new(
	{ World = World, GetCandidates = _GetCandidates },
	{ bEnabled = true, FovMode = "All" }
)
local FallbackModule = { Fire = _Original }
assert(
	FallbackEngine:BindMethod(FallbackModule, "Fire", FrameOnlyBinding),
	"Broken sUNC capability must allow table fallback"
)
local Frozen = table.freeze({ Fire = _Original })
assert(
	FallbackEngine:BindMethod(Frozen, "Fire", FrameOnlyBinding) == nil,
	"Frozen tables with unavailable hook must report failure"
)
FallbackEngine:Destroy()
assert(FallbackModule.Fire == _Original)

--[[
	游標排序使用可移動的 Viewport 座標，與既有準星中心排序分開驗證。
]]
local _Cursor = Rbx.Vector2.new(500, 300)
local CursorCenter = { Point = Vector3.new(0, 0, -100) }
local CursorTarget = { Point = Vector3.new(20, 0, -100) }
local NearestTarget = { Point = Vector3.new(10, 0, -10) }
--[[
	回傳分別靠近準星、游標與射擊原點的候選。
	@param Context 本次射擊上下文。
	@return 測試候選快照。
]]
local function _CursorCandidates(Context)
	return { CursorCenter, CursorTarget, NearestTarget }
end
--[[
	回傳目前指定的測試游標位置。
	@return Viewport 像素座標。
]]
local function _CursorPosition()
	return _Cursor
end
local CursorEngine = CSilentAimEngine.new(
	{ World = World, GetCandidates = _CursorCandidates, GetCursorPosition = _CursorPosition },
	{ bEnabled = true, bVisibleOnly = false, Priority = "Cursor" }
)
local CursorShot = { Origin = Vector3.zero }
local CursorSolution = CursorEngine:Select(CursorShot)
assert(
	CursorSolution.Candidate == CursorTarget and CursorShot.Center == nil,
	"Cursor mode must use the cursor and leave the original Shot unchanged"
)
assert(
	CursorEngine:Select({ Origin = Vector3.zero, Center = Rbx.Vector2.new(400, 300) }).Candidate == CursorCenter,
	"An explicit viewport center must override the cursor adapter"
)
CursorEngine:Configure({ Priority = "Distance" })
assert(CursorEngine:Select(CursorShot).Candidate == NearestTarget, "Distance mode must use shot-origin distance")
CursorEngine:Configure({ Priority = "Screen" })
assert(
	CursorEngine:Select(CursorShot).Candidate == CursorCenter,
	"Existing Screen mode must keep viewport-center behavior"
)
CursorEngine:Configure({ Priority = "Cursor", FovRadius = 1 })
assert(CursorEngine:Select(CursorShot).Candidate == CursorTarget, "Pixel FOV must follow the cursor in Cursor mode")
_Cursor = Rbx.Vector2.new(700, 300)
assert(CursorEngine:Select(CursorShot) == nil, "Moving the cursor must refresh selection each shot")
CursorEngine:Destroy()

--[[
	使用具深度縮放的相機替身，驗證標記隨部位移動與距離改變，而非固定像素半徑。
]]
local _MarkerCamera = { CFrame = CFrame.new(), ViewportSize = Rbx.Vector2.new(800, 600) }
--[[
	執行簡化透視投影，不包含任何 GUI inset 偏移。
	@param self 測試相機。
	@param Point 世界座標。
	@return 畫面座標與相機深度。
	@return true 表示投影點位於畫面內，false 表示離屏或在鏡頭後方。
]]
function _MarkerCamera.WorldToViewportPoint(self: typeof(_MarkerCamera), Point)
	local Depth = -Point.Z
	local Screen = Vector3.new(400 + Point.X * 400 / Depth, 300 - Point.Y * 400 / Depth, Depth)
	return Screen, Depth > 0 and Screen.X >= 0 and Screen.X <= 800 and Screen.Y >= 0 and Screen.Y <= 600
end
local MarkerModel = Rbx.Instance.new("Model")
MarkerModel.Parent = World
local MarkerPart = Rbx.Instance.new("Part")
MarkerPart.Size = Vector3.new(2, 2, 2)
MarkerPart.Position = Vector3.new(0, 0, -100)
MarkerPart.CFrame = CFrame.new(MarkerPart.Position)
MarkerPart.Parent = MarkerModel
local LargeBody = Rbx.Instance.new("Part")
LargeBody.Size = Vector3.new(100, 100, 100)
LargeBody.Parent = MarkerModel
--[[
	提供只瞄準小部位的候選，模型另有巨大部位，避免誤用全身邊界。
	@param Context 本次射擊上下文。
	@return 瞄準部位快照。
]]
local function _MarkerCandidates(Context)
	return { { Part = MarkerPart, Model = MarkerModel } }
end
--[[
	回傳目前可替換或移除的測試相機。
	@return 測試相機；nil 表示暫時沒有相機。
]]
local function _MarkerGetCamera()
	return _MarkerCamera
end
local MarkerEngine = CSilentAimEngine.new(
	{ World = World, GetCandidates = _MarkerCandidates, GetCamera = _MarkerGetCamera },
	{ bEnabled = true, bVisibleOnly = false }
)
local OverlayParent = Rbx.Instance.new("Folder")
assert(#OverlayParent:GetChildren() == 0, "Constructing the engine must not create implicit UI")
MarkerEngine:SetTargetMarkerParent(OverlayParent)
local MarkerGui = OverlayParent:FindFirstChild("SilentAimEngine_TargetMarker")
local Marker = MarkerGui:FindFirstChild("AimPartCircle")
local MarkerSelection = MarkerEngine:Select({ Origin = Vector3.zero })
MarkerEngine:RenderTargetMarker()
assert(
	Marker.Visible and Marker.Position.X.Offset == 400 and Marker.Position.Y.Offset == 300,
	"Marker must be centered on the aim part in viewport coordinates"
)
local InitialDiameter = Marker.Size.X.Offset
assert(
	InitialDiameter >= 8 and InitialDiameter <= 9 and Marker.Size.Y.Offset == InitialDiameter,
	"Marker must fit the selected 2-stud part, not the huge model or a fixed radius"
)
MarkerEngine:Configure({ bEnabled = true })
assert(
	MarkerEngine:GetSelected() == MarkerSelection and Marker.Visible,
	"Repeated identical configuration must not clear the target between render frames"
)
MarkerPart.Position = Vector3.new(5, 0, -200)
MarkerPart.CFrame = CFrame.new(MarkerPart.Position)
MarkerEngine:RenderTargetMarker()
assert(
	Marker.Position.X.Offset == 410 and Marker.Size.X.Offset < InitialDiameter * 0.51,
	"Render must follow the current part and shrink with depth without requiring another Select"
)
MarkerPart.Size = Vector3.new(4, 4, 4)
MarkerEngine:RenderTargetMarker()
assert(Marker.Size.X.Offset >= 8, "Marker must respond to changes in the aim part size")
MarkerEngine:Configure({ bShowTargetMarker = false })
MarkerEngine:RenderTargetMarker()
assert(not Marker.Visible, "Hiding the marker must take effect on the next UI render")
MarkerEngine:Configure({ bShowTargetMarker = true })
MarkerEngine:Select({ Origin = Vector3.zero })
MarkerEngine:RenderTargetMarker()
assert(Marker.Visible)
MarkerPart.Position = Vector3.new(1000, 0, -100)
MarkerPart.CFrame = CFrame.new(MarkerPart.Position)
MarkerEngine:RenderTargetMarker()
assert(not Marker.Visible, "Offscreen parts must not leave a stale visible marker")
MarkerPart.Position = Vector3.new(0, 0, -0.5)
MarkerPart.CFrame = CFrame.new(MarkerPart.Position)
MarkerEngine:RenderTargetMarker()
assert(not Marker.Visible, "Parts crossing the camera plane must not produce an oversized circle")
MarkerPart.Position = Vector3.new(0, 0, -100)
MarkerPart.CFrame = CFrame.new(MarkerPart.Position)
MarkerEngine:RenderTargetMarker()
assert(Marker.Visible)
local SavedMarkerCamera = _MarkerCamera
_MarkerCamera = nil
MarkerEngine:RenderTargetMarker()
assert(not Marker.Visible, "Missing camera must hide the marker")
_MarkerCamera = SavedMarkerCamera
_MarkerCamera.ViewportSize = Rbx.Vector2.zero
MarkerEngine:RenderTargetMarker()
assert(not Marker.Visible, "Zero-size viewport must hide the marker")
_MarkerCamera.ViewportSize = Rbx.Vector2.new(800, 600)
MarkerEngine:RenderTargetMarker()
assert(Marker.Visible, "Marker must recover after camera and viewport restoration")
MarkerEngine:ClearSelection()
MarkerEngine:RenderTargetMarker()
assert(not Marker.Visible and MarkerEngine:GetSelected() == nil, "Clearing selection must hide the marker on render")
MarkerEngine:Select({ Origin = Vector3.zero })
MarkerEngine:RenderTargetMarker()
MarkerPart.Parent = nil
MarkerEngine:RenderTargetMarker()
assert(not Marker.Visible, "Removed target parts must hide their marker")
assert(MarkerEngine:Select({ Origin = Vector3.zero }) == nil, "Invalid target must clear the selected solution")
MarkerPart.Parent = MarkerModel
local OldMarkerGui = MarkerGui
MarkerEngine:SetTargetMarkerParent(OverlayParent)
assert(OldMarkerGui.Parent == nil and #OverlayParent:GetChildren() == 1, "Replacing a marker must not leak UI")
MarkerEngine:Select({ Origin = Vector3.zero })
MarkerEngine:Configure({ bEnabled = false })
assert(MarkerEngine:GetSelected() == nil, "Disabling the engine must clear marker selection")
MarkerEngine:Destroy()
MarkerEngine:Destroy()
assert(#OverlayParent:GetChildren() == 0 and OverlayParent.Parent == nil, "Destroy must remove owned UI only")

print(
	"PASS: cursor/distance selection, FOV/sticky/prediction, aim-part marker sizing/movement/recovery/cleanup, protocols and hook ownership"
)

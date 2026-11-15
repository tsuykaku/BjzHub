--[[
	Silent Aim 共用選取、彈道與射擊協定適配引擎。載入模組不安裝 hook。
	遊戲提供候選目標、敵友規則與射擊入口；引擎不猜測 RemoteEvent 或伺服器協定。
	詳見 Docs/SilentAimEngine.md 的五個現有遊戲對應與新遊戲接入範例。
]]

--[[
	遊戲協定邊界使用可變參數，保留中間及尾端 nil；any 僅用於未知外部參數。
]]
export type PackedValues = { [number]: any, n: number }
export type AimCandidate = {
	Id: unknown?,
	Model: Model?,
	Part: BasePart?,
	Point: Vector3?,
	Velocity: Vector3?,
	Health: number?,
	bEligible: boolean?,
	Data: unknown?,
}
export type Shot = {
	Origin: Vector3,
	Range: number?,
	Speed: number?,
	Gravity: Vector3?,
	Latency: number?,
	Center: Vector2?,
	bAllDirections: boolean?,
	Data: unknown?,
}
export type AimContext = { Shot: Shot, Camera: Camera?, Range: number }
export type AimSolution = {
	Candidate: AimCandidate,
	Origin: Vector3,
	Point: Vector3,
	Direction: Vector3,
	Frame: CFrame,
	Distance: number,
	FlightTime: number,
	Score: number,
}

--[[
	選取時同步呼叫的遊戲適配介面；回呼不得 yield，不得修改引擎或原始射擊資料。
	GetCandidates 每次回傳最新陣列；虛擬角色可只提供 Point，不要求 Humanoid。
	IsEligible 應判斷本機、敵友、投降、死亡與遊戲專屬狀態；不提供時只使用基本有效性檢查。
	IsVisible 可覆寫原生 Raycast，處理載具與遊戲專屬遮蔽物規則。
	GetCursorPosition 可提供 Viewport 像素座標；未提供時讀取 UserInputService:GetMouseLocation。
	Predict 在啟用預判時覆寫內建計算，回傳補償點與非負飛行秒數。
	@param Context 本次射擊原點、相機及有效射程。
	@param ShotData 本次原始射擊與彈道設定（Predict）。
	@param Candidate 要檢查的候選目標（IsEligible／IsVisible）。
	@param Point 原始瞄準點（IsVisible）。
	@return GetCandidates 回傳候選陣列；IsEligible／IsVisible 回傳 true 接受、false 排除。
	@return GetCamera 回傳當前相機或 nil；GetIgnoreInstances 回傳視線檢查需排除的物件。
	@return GetCursorPosition 回傳有限的 Viewport Vector2，不應再次扣除 GUI inset。
	@return Predict 回傳補償位置（nil 表示無解）及飛行秒數。
]]
export type AimAdapter = {
	World: Workspace?,
	GetCandidates: (Context: AimContext) -> { AimCandidate },
	GetCamera: (() -> Camera?)?,
	GetCursorPosition: (() -> Vector2)?,
	IsEligible: ((Context: AimContext, Candidate: AimCandidate) -> boolean)?,
	IsVisible: ((Context: AimContext, Candidate: AimCandidate, Point: Vector3) -> boolean)?,
	GetIgnoreInstances: ((Context: AimContext) -> { Instance })?,
	Predict: ((ShotData: Shot, Candidate: AimCandidate, Point: Vector3) -> (Vector3?, number))?,
}
export type AimOptions = {
	bEnabled: boolean?,
	FovMode: ("Pixels" | "Angle" | "All")?,
	FovRadius: number?,
	FovAngle: number?,
	MaxDistance: number?,
	Priority: ("Screen" | "Cursor" | "Angle" | "Distance" | "Health")?,
	bShowTargetMarker: boolean?,
	bOnScreen: boolean?,
	bVisibleOnly: boolean?,
	bSticky: boolean?,
	bPrediction: boolean?,
	MaxPredictionTime: number?,
	MaxTargetSpeed: number?,
	PredictionIterations: number?,
}

--[[
	通用協定適配器，Before 改實參，After 改原函數回傳值。
	回呼同步執行，不得 yield 或修改傳入的巢狀資料；需要修改時複製對應表格。
	@param Values 將處理的參數或回傳值副本，包含 n。
	@param Arguments 原始完整實參，包含冒號方法的 self。
	@param Solution 本次有效射擊解（Write）。
	@return Matches 回傳 true 才處理；Read 回傳 Shot，nil 表示略過。
	@return Write 回傳改寫後的 PackedValues，nil 表示沿用原值。
]]
export type ShotBinding = {
	Phase: "Before" | "After",
	Matches: (Values: PackedValues, Arguments: PackedValues) -> boolean,
	Read: (Values: PackedValues, Arguments: PackedValues) -> Shot?,
	Write: (Values: PackedValues, Solution: AimSolution, Arguments: PackedValues) -> PackedValues?,
}

--[[
	常見射擊協定的宣告式映射；索引包含明確傳入的 self。
	Command 以 OriginField 讀原點，AimField 寫瞄準位置，保留其餘欄位。
	Position／Direction 需提供 OriginIndex 或 GetShot；其他種類可直接從 CFrame／Ray 取得原點。
	GetShot 可提供即時射程、彈速、重力與遊戲資料，nil 表示不處理此次呼叫。
	@param Values 要處理的實參或回傳值（Matches／GetShot）。
	@param Arguments 完整原始實參（Matches／GetShot）。
	@return Matches 回傳 true 才處理；GetShot 回傳射擊資料或 nil。
]]
export type BindingSpec = {
	Kind: "Frame" | "FrameDirection" | "Direction" | "Position" | "Ray" | "Command",
	Phase: ("Before" | "After")?,
	ValueIndex: number,
	DirectionIndex: number?,
	OriginIndex: number?,
	OriginField: string?,
	AimField: string?,
	AimLength: number?,
	Matches: (Values: PackedValues, Arguments: PackedValues) -> boolean,
	GetShot: ((Values: PackedValues, Arguments: PackedValues) -> Shot?)?,
}

--[[
	相同模組實例共用的函數 hook 記錄，卸載時將 Invoke 換回 Original。
	不呼叫 restorefunction：sUNC 定義會清除整條 hook 鏈，可能破壞其他擁有者。
	重用已停用的透明轉交器，避免同一模組重複接入時不斷疊加 hook。
]]
local _FunctionHooks = setmetatable({}, { __mode = "k" })
--[[
	記錄方法表綁定的擁有者，避免對同一欄位重複安裝。
]]
local _MethodBindings = setmetatable({}, { __mode = "k" })
local EPSILON = 0.001
--[[
	可建構的共用引擎；不改鏡頭、不合成開火輸入、不安排背景事件。
]]
local CSilentAimEngine = {}
CSilentAimEngine.__index = CSilentAimEngine
CSilentAimEngine.API_VERSION = 2
--[[
	引擎實例狀態與 metatable 方法。綁定解除器只在此實例卸載時執行。
]]
export type CSilentAimEngineType = typeof(setmetatable(
	{} :: {
		_Adapter: AimAdapter,
		_Options: AimOptions,
		_Selected: AimSolution?,
		_LastError: string?,
		_Disconnectors: { () -> () },
		_Busy: { [thread]: boolean },
		_MarkerGui: ScreenGui?,
		_Marker: Frame?,
		_bDestroyed: boolean,
	},
	CSilentAimEngine
))

--[[
	確認數值有限，避免 NaN 或無限值進入彈道計算。
	@param Value 要檢查的數值。
	@return true 表示有限數值，false 表示型別或數值無效。
]]
local function _IsFinite(Value: unknown): boolean
	return type(Value) == "number" and Value == Value and math.abs(Value) < math.huge
end

--[[
	確認向量的每個分量均有限。
	@param Value 要檢查的向量。
	@return true 表示有效 Vector3，false 表示無法使用。
]]
local function _IsVector(Value: unknown): boolean
	return typeof(Value) == "Vector3" and _IsFinite(Value.X) and _IsFinite(Value.Y) and _IsFinite(Value.Z)
end

--[[
	複製射擊資料並固定射擊原點，避免改動呼叫端的設定表。
	@param Origin 本次真正使用的射擊原點。
	@param Settings 可選的射程與彈道設定。
	@return 以 Origin 為原點的獨立資料表。
]]
local function _ShotAt(Origin: Vector3, Settings: Shot?): Shot
	local Result = if Settings then table.clone(Settings) else {}
	Result.Origin = Origin
	return Result
end

--[[
	取得可跨候選快照比較的黏著識別值。
	@param Candidate 要辨識的候選資料。
	@return 優先使用 Id，其次為 Model、Part，最後為候選表本身。
]]
local function _Identity(Candidate: AimCandidate): unknown
	if Candidate.Id ~= nil then
		return Candidate.Id
	end
	return Candidate.Model or Candidate.Part or Candidate
end

--[[
	驗證自訂協定必備的回呼與處理階段。
	@param Binding 要接入的外部協定。
	@return true 表示可安裝，false 表示缺少必要介面。
]]
local function _IsBinding(Binding: unknown): boolean
	return type(Binding) == "table"
		and type(Binding.Matches) == "function"
		and type(Binding.Read) == "function"
		and type(Binding.Write) == "function"
		and (Binding.Phase == "Before" or Binding.Phase == "After")
end

--[[
	建立引擎，預設停用，必須明確提供遊戲候選來源。
	@param Adapter 遊戲提供的目標與視線適配介面。
	@param Options 可選設定；FovAngle 為完整角度，FovRadius 為 Viewport 像素半徑。
	@return 獨立引擎；接入方式見 Docs/SilentAimEngine.md，卸載時呼叫 Destroy。
]]
function CSilentAimEngine.new(Adapter: AimAdapter, Options: AimOptions?): CSilentAimEngineType
	assert(type(Adapter) == "table" and type(Adapter.GetCandidates) == "function", "GetCandidates is required")
	local self = setmetatable({
		_Adapter = Adapter,
		_Options = {
			bEnabled = false,
			FovMode = "Pixels",
			FovRadius = 120,
			FovAngle = 60,
			MaxDistance = 2000,
			Priority = "Screen",
			bShowTargetMarker = true,
			bOnScreen = true,
			bVisibleOnly = true,
			bSticky = false,
			bPrediction = false,
			MaxPredictionTime = 3,
			MaxTargetSpeed = 250,
			PredictionIterations = 4,
		},
		_Selected = nil :: AimSolution?,
		_LastError = nil :: string?,
		_Disconnectors = {} :: { () -> () },
		_Busy = setmetatable({}, { __mode = "k" }),
		_MarkerGui = nil :: ScreenGui?,
		_Marker = nil :: Frame?,
		_bDestroyed = false,
	}, CSilentAimEngine)
	self:Configure(Options or {})
	return self
end

--[[
	驗證並原子更新設定；實際變更才清除選取結果，相同設定不打斷標記；無效設定會拋錯。
	@param self 要設定的引擎。
	@param Changes 僅包含要覆寫的設定欄位。
]]
function CSilentAimEngine.Configure(self: CSilentAimEngineType, Changes: AimOptions): ()
	if self._bDestroyed then
		return
	end
	local Options = table.clone(self._Options)
	local bChanged = false
	for Key, Value in pairs(Changes) do
		assert(Options[Key] ~= nil, "Unknown aim option: " .. Key)
		bChanged = bChanged or Options[Key] ~= Value
		Options[Key] = Value
	end
	for _, Key in ipairs({ "bEnabled", "bOnScreen", "bVisibleOnly", "bSticky", "bPrediction", "bShowTargetMarker" }) do
		assert(type(Options[Key]) == "boolean", Key .. " must be boolean")
	end
	for _, Key in ipairs({ "FovRadius", "FovAngle", "MaxPredictionTime", "MaxTargetSpeed", "PredictionIterations" }) do
		assert(_IsFinite(Options[Key]) and Options[Key] >= 0, Key .. " must be finite and nonnegative")
	end
	assert(type(Options.MaxDistance) == "number" and Options.MaxDistance > 0, "MaxDistance must be positive")
	assert(Options.FovAngle <= 360, "FovAngle must not exceed 360 degrees")
	assert(
		Options.PredictionIterations >= 1
			and Options.PredictionIterations <= 12
			and Options.PredictionIterations % 1 == 0,
		"PredictionIterations must be an integer from 1 to 12"
	)
	assert(table.find({ "Pixels", "Angle", "All" }, Options.FovMode), "Invalid FovMode")
	assert(table.find({ "Screen", "Cursor", "Angle", "Distance", "Health" }, Options.Priority), "Invalid Priority")
	self._Options = Options
	if bChanged then
		self:ClearSelection()
	end
end

--[[
	清除選取；下一次 RenderTargetMarker 隱藏目標圈，不在射擊回呼中操作 UI 或解除綁定。
	@param self 要清除目標的引擎。
]]
function CSilentAimEngine.ClearSelection(self: CSilentAimEngineType): ()
	self._Selected = nil
end

--[[
	回傳最近一次通過即時選取檢查的解，不代表下一次射擊仍有效。
	@param self 要讀取的引擎。
	@return 最近結果；停用、無目標或卸載時為 nil。
]]
function CSilentAimEngine.GetSelected(self: CSilentAimEngineType): AimSolution?
	return self._Selected
end

--[[
	讀取最近一次適配器／綁定錯誤，不將錯誤當作命中成功。
	@param self 要讀取的引擎。
	@return 錯誤說明；尚無錯誤或最近一次 Select 成功執行時為 nil。
]]
function CSilentAimEngine.GetLastError(self: CSilentAimEngineType): string?
	return self._LastError
end

--[[
	設定目標圈的 UI 父節點，建立引擎專屬的全螢幕覆蓋層；替換時銷毀舊覆蓋層。
	不自行呼叫 gethui 或安裝渲染事件；呼叫端須在可建立 UI 的執行身分下操作。
	@param self 要設定標記的引擎。
	@param Parent 通常由呼叫端提供 gethui()；nil 表示移除標記，不刪除父節點。

	使用範例：
	```lua
	-- 前提：Engine 已建立，OverlayParent 是呼叫端的 UI 根節點。
	Engine:SetTargetMarkerParent(OverlayParent)
	-- 呼叫端在相機更新後逐幀執行：
	Engine:RenderTargetMarker()
	Engine:SetTargetMarkerParent(nil) -- 移除覆蓋層；選取與射擊綁定仍可使用。
	```
]]
function CSilentAimEngine.SetTargetMarkerParent(self: CSilentAimEngineType, Parent: Instance?): ()
	if self._bDestroyed then
		return
	end
	if self._MarkerGui then
		self._MarkerGui:Destroy()
	end
	self._MarkerGui, self._Marker = nil, nil
	if not Parent then
		return
	end
	local Overlay = Instance.new("ScreenGui")
	Overlay.Name = "SilentAimEngine_TargetMarker"
	Overlay.IgnoreGuiInset = true
	Overlay.ResetOnSpawn = false
	Overlay.DisplayOrder = 2
	-- 先登錄擁有權，初始化中途出錯時 Destroy 仍能清理已建立的物件。
	self._MarkerGui = Overlay
	local Marker = Instance.new("Frame")
	Marker.Name = "AimPartCircle"
	Marker.BackgroundTransparency = 1
	Marker.BorderSizePixel = 0
	Marker.AnchorPoint = Vector2.new(0.5, 0.5)
	Marker.Visible = false
	Marker.Parent = Overlay
	self._Marker = Marker
	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(1, 0)
	Corner.Parent = Marker
	local Stroke = Instance.new("UIStroke")
	Stroke.Thickness = 1
	Stroke.Color = Color3.fromRGB(255, 225, 110)
	Stroke.Parent = Marker
	Overlay.Parent = Parent
end

--[[
	投影瞄準部位的八個角，取得部位畫面邊界的內接圓直徑，不讀取整個角色尺寸。
	@param Camera 目前有效相機。
	@param Part 目前瞄準的實體部位。
	@return 以像素表示的圓直徑；部位穿過相機平面或無有效尺寸時為 nil。
]]
local function _PartMarkerDiameter(Camera: Camera, Part: BasePart): number?
	local HalfSize = Part.Size * 0.5
	local MinX, MinY, MaxX, MaxY = math.huge, math.huge, -math.huge, -math.huge
	for X = -1, 1, 2 do
		for Y = -1, 1, 2 do
			for Z = -1, 1, 2 do
				local Corner = Part.CFrame * Vector3.new(HalfSize.X * X, HalfSize.Y * Y, HalfSize.Z * Z)
				local Screen = Camera:WorldToViewportPoint(Corner)
				if not _IsVector(Screen) or Screen.Z <= EPSILON then
					return nil
				end
				MinX, MinY = math.min(MinX, Screen.X), math.min(MinY, Screen.Y)
				MaxX, MaxY = math.max(MaxX, Screen.X), math.max(MaxY, Screen.Y)
			end
		end
	end
	local Diameter = math.min(MaxX - MinX, MaxY - MinY)
	return if _IsFinite(Diameter) and Diameter > EPSILON then Diameter else nil
end

--[[
	逐幀將圓圈置於目前瞄準部位，隨部位投影尺寸縮放；沒有有效目標或離屏時隱藏。
	只有 Point 而沒有 Part 的虛擬目標不繪製，避免以整個角色代替瞄準部位。
	@param self 要繪製的引擎；呼叫端在相機更新後、可操作 UI 的執行身分下呼叫。
]]
function CSilentAimEngine.RenderTargetMarker(self: CSilentAimEngineType): ()
	local Marker = self._Marker
	if not Marker then
		return
	end
	Marker.Visible = false
	if self._bDestroyed or not self._Options.bEnabled or not self._Options.bShowTargetMarker then
		return
	end
	local Selected = self._Selected
	local Candidate = Selected and Selected.Candidate
	local Part = Candidate and Candidate.Part
	local World = self._Adapter.World or workspace
	if
		not Part
		or not Part:IsDescendantOf(World)
		or (Candidate.Model and not Candidate.Model:IsDescendantOf(World))
		or (Candidate.Health ~= nil and Candidate.Health <= 0)
	then
		return
	end
	local Camera = if self._Adapter.GetCamera then self._Adapter.GetCamera() else World.CurrentCamera
	if not Camera or Camera.ViewportSize.X <= 0 or Camera.ViewportSize.Y <= 0 then
		return
	end
	local Screen, bOnScreen = Camera:WorldToViewportPoint(Part.Position)
	if not bOnScreen or not _IsVector(Screen) or Screen.Z <= EPSILON then
		return
	end
	local Diameter = _PartMarkerDiameter(Camera, Part)
	if not Diameter then
		return
	end
	Marker.Position = UDim2.fromOffset(Screen.X, Screen.Y)
	Marker.Size = UDim2.fromOffset(Diameter, Diameter)
	Marker.Visible = true
end

--[[
	檢查從真正射擊原點到目標的視線，可由遊戲覆寫載具等特殊規則。
	@param self 提供世界與視線回呼的引擎。
	@param Context 本次射擊資料。
	@param Candidate 要檢查的候選目標。
	@param Point 原始目標位置。
	@return true 表示可見，false 表示遮擋。
]]
function CSilentAimEngine._IsVisible(
	self: CSilentAimEngineType,
	Context: AimContext,
	Candidate: AimCandidate,
	Point: Vector3
): boolean
	local Adapter = self._Adapter
	if Adapter.IsVisible then
		return Adapter.IsVisible(Context, Candidate, Point) == true
	end
	local Ignore = if Adapter.GetIgnoreInstances then table.clone(Adapter.GetIgnoreInstances(Context)) else {}
	if Context.Camera then
		table.insert(Ignore, Context.Camera)
	end
	local Params = RaycastParams.new()
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = Ignore
	Params.IgnoreWater = true
	local Hit = (Adapter.World or workspace):Raycast(Context.Shot.Origin, Point - Context.Shot.Origin, Params)
	return Hit == nil
		or Hit.Instance == Candidate.Part
		or (Candidate.Model ~= nil and Hit.Instance:IsDescendantOf(Candidate.Model))
end

--[[
	以固定次數迭代估計飛行時間，補償等速目標與固定重力；不模擬阻力或追蹤彈。
	@param self 提供預判上限的引擎。
	@param ShotData 原點、彈速、重力加速度向量與延遲秒數。
	@param Candidate 含目標速度或實際 Part 的候選。
	@param Point 原始瞄準點。
	@return 補償後位置；無法在上限內估計時為 nil。
	@return 預估飛行秒數；hitscan 為 0。
]]
function CSilentAimEngine._Predict(
	self: CSilentAimEngineType,
	ShotData: Shot,
	Candidate: AimCandidate,
	Point: Vector3
): (Vector3?, number)
	if not self._Options.bPrediction then
		return Point, 0
	end
	if self._Adapter.Predict then
		return self._Adapter.Predict(ShotData, Candidate, Point)
	end
	local Velocity = Candidate.Velocity or (Candidate.Part and Candidate.Part.AssemblyLinearVelocity) or Vector3.zero
	if not _IsVector(Velocity) then
		return nil, 0
	end
	if Velocity.Magnitude > self._Options.MaxTargetSpeed then
		Velocity = Vector3.zero
	end
	local Gravity = ShotData.Gravity or Vector3.zero
	local Latency = ShotData.Latency or 0
	if not _IsVector(Gravity) or not _IsFinite(Latency) or Latency < 0 then
		return nil, 0
	end
	local Speed = ShotData.Speed
	if Speed == nil then
		return Point + Velocity * Latency, 0
	end
	if not _IsFinite(Speed) or Speed <= EPSILON then
		return nil, 0
	end
	local Position, Time = Point, (Point - ShotData.Origin).Magnitude / Speed
	for _ = 1, self._Options.PredictionIterations do
		if not _IsFinite(Time) or Time > self._Options.MaxPredictionTime then
			return nil, 0
		end
		Position = Point + Velocity * (Time + Latency) - Gravity * (0.5 * Time * Time)
		Time = (Position - ShotData.Origin).Magnitude / Speed
	end
	if not _IsVector(Position) or not _IsFinite(Time) or Time > self._Options.MaxPredictionTime then
		return nil, 0
	end
	return Position, Time
end

--[[
	立即重查目標有效性、射程、視錐、視線與預判，產生候選射擊解。
	@param self 提供設定與遊戲規則的引擎。
	@param Context 本次射擊原點與當前相機。
	@param Candidate 此次快照中的候選資料。
	@return 有效解；不符合任一條件時為 nil。
]]
function CSilentAimEngine._Evaluate(
	self: CSilentAimEngineType,
	Context: AimContext,
	Candidate: AimCandidate
): AimSolution?
	if Candidate.bEligible == false then
		return nil
	end
	if Candidate.Model and not Candidate.Model.Parent then
		return nil
	end
	if Candidate.Part and not Candidate.Part.Parent then
		return nil
	end
	if Candidate.Health ~= nil and (not _IsFinite(Candidate.Health) or Candidate.Health <= 0) then
		return nil
	end
	if self._Adapter.IsEligible and not self._Adapter.IsEligible(Context, Candidate) then
		return nil
	end
	local Point = Candidate.Point or (Candidate.Part and Candidate.Part.Position)
	if not _IsVector(Point) then
		return nil
	end
	local Delta = Point - Context.Shot.Origin
	local Distance = Delta.Magnitude
	if not _IsFinite(Distance) or Distance <= EPSILON or Distance > Context.Range then
		return nil
	end
	local Options, Camera = self._Options, Context.Camera
	local bAll = Context.Shot.bAllDirections == true or Options.FovMode == "All"
	local PixelDistance, Angle = Distance, 0
	if not bAll then
		if not Camera or Camera.ViewportSize.X <= 0 or Camera.ViewportSize.Y <= 0 then
			return nil
		end
		local CameraDelta = Point - Camera.CFrame.Position
		if CameraDelta.Magnitude <= EPSILON then
			return nil
		end
		Angle = math.deg(math.acos(math.clamp(Camera.CFrame.LookVector:Dot(CameraDelta.Unit), -1, 1)))
		local Screen, bOnScreen = Camera:WorldToViewportPoint(Point)
		if Options.bOnScreen and (not bOnScreen or Screen.Z <= 0) then
			return nil
		end
		local Center = Context.Shot.Center or Camera.ViewportSize * 0.5
		PixelDistance = (Vector2.new(Screen.X, Screen.Y) - Center).Magnitude
		if not _IsFinite(PixelDistance) then
			return nil
		end
		if Options.FovMode == "Pixels" and (Screen.Z <= 0 or PixelDistance > Options.FovRadius) then
			return nil
		end
		if Options.FovMode == "Angle" and Angle > Options.FovAngle * 0.5 then
			return nil
		end
	end
	if Options.bVisibleOnly and not self:_IsVisible(Context, Candidate, Point) then
		return nil
	end
	local Predicted, FlightTime = self:_Predict(Context.Shot, Candidate, Point)
	if not Predicted or not _IsVector(Predicted) or not _IsFinite(FlightTime) or FlightTime < 0 then
		return nil
	end
	local AimDelta = Predicted - Context.Shot.Origin
	if not _IsFinite(AimDelta.Magnitude) or AimDelta.Magnitude <= EPSILON then
		return nil
	end
	local Direction = AimDelta.Unit
	local Up = if math.abs(Direction:Dot(Vector3.yAxis)) > 0.98 then Vector3.xAxis else Vector3.yAxis
	local Score = if bAll then Distance else PixelDistance
	if Options.Priority == "Distance" then
		Score = Distance
	elseif Options.Priority == "Angle" and not bAll then
		Score = Angle
	elseif Options.Priority == "Health" then
		Score = Candidate.Health or math.huge
	end
	return {
		Candidate = Candidate,
		Origin = Context.Shot.Origin,
		Point = Predicted,
		Direction = Direction,
		Frame = CFrame.lookAt(Context.Shot.Origin, Predicted, Up),
		Distance = Distance,
		FlightTime = FlightTime,
		Score = Score,
	}
end

--[[
	取得即時候選並選出最低分數；黏著目標也必須重新通過全部檢查。
	@param self 要執行選取的引擎。
	@param ShotData 實際射擊資料。
	@return 本次最佳解，沒有有效目標時為 nil。
]]
function CSilentAimEngine._Select(self: CSilentAimEngineType, ShotData: Shot): AimSolution?
	if not _IsVector(ShotData.Origin) then
		return nil
	end
	local Range = ShotData.Range or self._Options.MaxDistance
	if type(Range) ~= "number" or Range ~= Range or Range <= 0 then
		return nil
	end
	Range = math.min(Range, self._Options.MaxDistance)
	local Adapter = self._Adapter
	local Camera = if Adapter.GetCamera then Adapter.GetCamera() else (Adapter.World or workspace).CurrentCamera
	if self._Options.Priority == "Cursor" and ShotData.Center == nil then
		local Cursor = if Adapter.GetCursorPosition
			then Adapter.GetCursorPosition()
			else game:GetService("UserInputService"):GetMouseLocation()
		if typeof(Cursor) ~= "Vector2" or not _IsFinite(Cursor.X) or not _IsFinite(Cursor.Y) then
			error("GetCursorPosition must return a finite viewport Vector2")
		end
		ShotData = _ShotAt(ShotData.Origin, ShotData)
		ShotData.Center = Cursor
	end
	local Context = { Shot = ShotData, Camera = Camera, Range = Range }
	local Previous = self._Selected
	local Best: AimSolution? = nil
	for _, Candidate in ipairs(Adapter.GetCandidates(Context)) do
		local Solution = self:_Evaluate(Context, Candidate)
		if Solution then
			if self._Options.bSticky and Previous and _Identity(Candidate) == _Identity(Previous.Candidate) then
				return Solution
			end
			if not Best or Solution.Score < Best.Score then
				Best = Solution
			end
		end
	end
	return Best
end

--[[
	以真正射擊原點即時選取，不使用跨射擊快取；適配器錯誤會留下原因並回傳 nil。
	@param self 要選取的引擎。
	@param ShotData 原點與此發子彈的彈道設定。
	@return 本次有效解；停用、無目標、無效輸入或回呼出錯時為 nil。
]]
function CSilentAimEngine.Select(self: CSilentAimEngineType, ShotData: Shot): AimSolution?
	if self._bDestroyed or not self._Options.bEnabled then
		self:ClearSelection()
		return nil
	end
	self._LastError = nil
	local bOk, Result = pcall(self._Select, self, ShotData)
	if not bOk then
		self._LastError = tostring(Result)
		self:ClearSelection()
		return nil
	end
	self._Selected = Result
	if not Result then
		self:ClearSelection()
	end
	return Result
end

--[[
	改變方向但保留原始向量長度，無解時沿用原方向。
	@param self 要選取的引擎。
	@param Origin 真正射擊原點。
	@param Direction 原方向，可為單位向量或帶長度的射線。
	@param Settings 可選射程與彈道設定；不從向量長度猜測武器射程。
	@return 改寫後方向或原方向。
]]
function CSilentAimEngine.RedirectDirection(
	self: CSilentAimEngineType,
	Origin: Vector3,
	Direction: Vector3,
	Settings: Shot?
): Vector3
	if not _IsVector(Direction) or Direction.Magnitude <= EPSILON then
		return Direction
	end
	local Solution = self:Select(_ShotAt(Origin, Settings))
	return if Solution then Solution.Direction * Direction.Magnitude else Direction
end

--[[
	改變 CFrame 朝向，保持槍口位置並處理近乎垂直的方向。
	@param self 要選取的引擎。
	@param Frame 原始射擊座標框。
	@param Settings 可選射程與彈道設定。
	@return 有效解的座標框或原始座標框。
]]
function CSilentAimEngine.RedirectFrame(self: CSilentAimEngineType, Frame: CFrame, Settings: Shot?): CFrame
	local Solution = self:Select(_ShotAt(Frame.Position, Settings))
	return if Solution then Solution.Frame else Frame
end

--[[
	改變相機射線方向，保留 Origin 與 Direction 的原長度。
	@param self 要選取的引擎。
	@param BaseRay 原始射線；相機單位射線不等於武器射程。
	@param Settings 可選的真正武器射程與彈道設定。
	@return 改寫後射線；沒有有效解時方向不變。
]]
function CSilentAimEngine.RedirectRay(self: CSilentAimEngineType, BaseRay: Ray, Settings: Shot?): Ray
	return Ray.new(BaseRay.Origin, self:RedirectDirection(BaseRay.Origin, BaseRay.Direction, Settings))
end

--[[
	建立常見射擊資料映射；未宣告的參數與回傳值保持不變。
	@param Spec 明確的參數／欄位索引與本機射擊判斷，不會自行猜測。
	@return 可供 BindMethod 或 BindFunction 使用的綁定。

	使用範例：
	```lua
	-- IsLocalShot 為遊戲已實作的本機射擊判斷函數。
	local Binding = CSilentAimEngine.CreateBinding({
		Kind = "FrameDirection", ValueIndex = 4, DirectionIndex = 5, Matches = IsLocalShot,
	})
	```
]]
function CSilentAimEngine.CreateBinding(Spec: BindingSpec): ShotBinding
	Spec = table.clone(Spec)
	assert(type(Spec.Matches) == "function", "Explicit Matches predicate is required")
	assert(
		table.find({ "Frame", "FrameDirection", "Direction", "Position", "Ray", "Command" }, Spec.Kind),
		"Invalid binding kind"
	)
	assert(Spec.Phase == nil or Spec.Phase == "Before" or Spec.Phase == "After", "Invalid binding phase")
	assert(_IsFinite(Spec.ValueIndex) and Spec.ValueIndex >= 1 and Spec.ValueIndex % 1 == 0, "Invalid ValueIndex")
	if Spec.Kind == "FrameDirection" then
		assert(
			_IsFinite(Spec.DirectionIndex)
				and Spec.DirectionIndex >= 1
				and Spec.DirectionIndex % 1 == 0
				and Spec.DirectionIndex ~= Spec.ValueIndex,
			"Distinct DirectionIndex is required"
		)
	end
	if Spec.Kind == "Command" then
		assert(
			type(Spec.OriginField) == "string" and type(Spec.AimField) == "string" and Spec.OriginField ~= Spec.AimField,
			"Distinct command origin and aim fields are required"
		)
	end
	if Spec.AimLength ~= nil then
		assert(_IsFinite(Spec.AimLength) and Spec.AimLength > 0, "AimLength must be positive")
	end
	--[[
		從明確指定的協定欄位擷取原點與彈道資料。
		@param Values 本次要修改的實參或回傳值。
		@param Arguments 原始完整實參。
		@return 本次射擊資料；格式不符或遊戲回呼拒絕時為 nil。
	]]
	local function Read(Values: PackedValues, Arguments: PackedValues): Shot?
		local Value = Values[Spec.ValueIndex]
		local Settings = if Spec.GetShot then Spec.GetShot(Values, Arguments) else nil
		if Spec.GetShot and not Settings then
			return nil
		end
		local Origin
		if Spec.Kind == "Frame" or Spec.Kind == "FrameDirection" then
			if typeof(Value) ~= "CFrame" then
				return nil
			end
			Origin = Value.Position
		elseif Spec.Kind == "Ray" then
			if typeof(Value) ~= "Ray" or not _IsVector(Value.Direction) or Value.Direction.Magnitude <= EPSILON then
				return nil
			end
			Origin = Value.Origin
		elseif Spec.Kind == "Command" then
			if type(Value) ~= "table" then
				return nil
			end
			Origin = Value[Spec.OriginField]
		else
			if not _IsVector(Value) then
				return nil
			end
			Origin = if Spec.OriginIndex then Values[Spec.OriginIndex] else Settings and Settings.Origin
		end
		if not _IsVector(Origin) then
			return nil
		end
		if Spec.Kind == "Direction" and Value.Magnitude <= EPSILON then
			return nil
		end
		if Spec.Kind == "FrameDirection" then
			local Direction = Values[Spec.DirectionIndex]
			if not _IsVector(Direction) or Direction.Magnitude <= EPSILON then
				return nil
			end
		end
		return _ShotAt(Origin, Settings)
	end
	--[[
		以同一射擊解更新已宣告欄位；Command 複製資料表以免影響原始模擬狀態。
		@param Values 可修改的參數／回傳值淺複本。
		@param Solution 此次射擊解。
		@param Arguments 原始實參；宣告式寫入不修改此表。
		@return 更新後完整封包，保留 nil 與 n。
	]]
	local function Write(Values: PackedValues, Solution: AimSolution, Arguments: PackedValues): PackedValues
		local Index, Kind = Spec.ValueIndex, Spec.Kind
		local Value = Values[Index]
		if Kind == "Frame" or Kind == "FrameDirection" then
			Values[Index] = Solution.Frame
			if Kind == "FrameDirection" then
				Values[Spec.DirectionIndex] = Solution.Direction * Values[Spec.DirectionIndex].Magnitude
			end
		elseif Kind == "Direction" then
			Values[Index] = Solution.Direction * Value.Magnitude
		elseif Kind == "Ray" then
			Values[Index] = Ray.new(Value.Origin, Solution.Direction * Value.Direction.Magnitude)
		elseif Kind == "Position" then
			Values[Index] = Solution.Point
		else
			local Command = table.clone(Value)
			Command[Spec.AimField] = if Spec.AimLength
				then Solution.Origin + Solution.Direction * Spec.AimLength
				else Solution.Point
			Values[Index] = Command
		end
		return Values
	end
	return { Phase = Spec.Phase or "Before", Matches = Spec.Matches, Read = Read, Write = Write }
end

--[[
	驗證與執行一次協定轉換；失敗只沿用原值，不重試原射擊。
	@param self 提供候選與設定的引擎。
	@param Binding 已宣告的協定。
	@param Values 本次實參或回傳值。
	@param Arguments 完整原始實參。
	@return 成功轉換的封包或原封包。
]]
function CSilentAimEngine._Transform(
	self: CSilentAimEngineType,
	Binding: ShotBinding,
	Values: PackedValues,
	Arguments: PackedValues
): PackedValues
	local Thread = coroutine.running()
	if self._bDestroyed or not self._Options.bEnabled or self._Busy[Thread] then
		return Values
	end
	self._Busy[Thread] = true
	--[[
		在受保護區內執行使用者協定與選取；保留原始封包作為失敗時的轉交資料。
		@return 改寫後封包，略過此次射擊時為 nil。
	]]
	local bOk, Result = pcall(function()
		local Copy = table.clone(Values)
		if not Binding.Matches(Copy, Arguments) then
			return nil
		end
		local ShotData = Binding.Read(Copy, Arguments)
		if not ShotData then
			return nil
		end
		local Solution = self:Select(ShotData)
		if not Solution then
			return nil
		end
		return Binding.Write(Copy, Solution, Arguments)
	end)
	self._Busy[Thread] = nil
	if not bOk then
		self._LastError = tostring(Result)
		return Values
	end
	if Result == nil then
		return Values
	end
	if type(Result) ~= "table" or not _IsFinite(Result.n) or Result.n < 0 or Result.n % 1 ~= 0 then
		self._LastError = "Binding.Write must return packed values with a nonnegative integer n"
		return Values
	end
	return Result
end

--[[
	為一個已知射擊入口建立可停用轉交器，原函數恰好呼叫一次。
	@param self 接入入口的引擎。
	@param Record 包含 Original 的內部記錄，解除時清除 Invoke 對引擎的引用。
	@param Binding 明確的本機射擊判斷與協定。
]]
function CSilentAimEngine._Activate(self: CSilentAimEngineType, Record, Binding: ShotBinding): ()
	assert(
		type(Binding.Matches) == "function" and type(Binding.Read) == "function" and type(Binding.Write) == "function",
		"Invalid binding callbacks"
	)
	assert(Binding.Phase == "Before" or Binding.Phase == "After", "Invalid binding phase")
	Binding = table.clone(Binding)
	Record.bActive = true
	--[[
		在原函數呼叫前或後轉換封包，不捕捉原函數錯誤，也不重送射擊。
		@param ... 原始完整實參，可能包含 nil。
		@return 原始或經適配的完整回傳值，保留尾端 nil。
	]]
	Record.Invoke = function(...)
		local Arguments = table.pack(...)
		if Binding.Phase == "Before" then
			local Changed = self:_Transform(Binding, Arguments, Arguments)
			return Record.Original(table.unpack(Changed, 1, Changed.n))
		end
		local Results = table.pack(Record.Original(...))
		local Changed = self:_Transform(Binding, Results, Arguments)
		return table.unpack(Changed, 1, Changed.n)
	end
end

--[[
	以 sUNC 函數 hook 接入確定的射擊函數，缺少 API 時不模擬 hookfunction。
	@param self 要接入的引擎。
	@param Target 明確指定的原始函數，含既有模組已保存的閉包引用。
	@param Binding 需處理的本機射擊協定。
	@return 解除函數；失敗時為 nil。解除後保留透明轉交器，不清除其他 hook。
	@return 失敗原因；成功時為 nil。
]]
function CSilentAimEngine.BindFunction(self: CSilentAimEngineType, Target, Binding: ShotBinding): ((() -> ())?, string?)
	if self._bDestroyed then
		return nil, "Engine is destroyed"
	end
	if type(Target) ~= "function" then
		return nil, "Target must be a function"
	end
	if not _IsBinding(Binding) then
		return nil, "Invalid binding callbacks or phase"
	end
	if type(hookfunction) ~= "function" or type(newcclosure) ~= "function" then
		return nil, "hookfunction and newcclosure are required"
	end
	local Record = _FunctionHooks[Target]
	if Record and Record.bActive then
		return nil, "Function already has an active engine binding"
	end
	if not Record then
		Record = { Original = Target, Invoke = Target, bActive = false }
		--[[
			透過單一記錄轉交呼叫；停用時 Invoke 直接指向先前函數。
			@param ... 原始實參。
			@return Invoke 的全部回傳值。
		]]
		local bWrapped, Wrapper = pcall(newcclosure, function(...)
			return Record.Invoke(...)
		end)
		if not bWrapped or type(Wrapper) ~= "function" then
			return nil, "newcclosure failed: " .. tostring(Wrapper)
		end
		local bOk, Original = pcall(hookfunction, Target, Wrapper)
		if not bOk or type(Original) ~= "function" then
			return nil, tostring(Original)
		end
		Record.Original, Record.Invoke = Original, Original
		_FunctionHooks[Target] = Record
	end
	self:_Activate(Record, Binding)
	local OwnerToken = {}
	Record.OwnerToken = OwnerToken
	--[[
		停用此次綁定並釋放引擎與協定引用；不破壞其他擁有者的 hook 鏈。
	]]
	local function Disconnect()
		if not Record.bActive or Record.OwnerToken ~= OwnerToken then
			return
		end
		Record.bActive = false
		Record.Invoke = Record.Original
		Record.OwnerToken = nil
	end
	table.insert(self._Disconnectors, Disconnect)
	return Disconnect, nil
end

--[[
	接入已知方法表；Auto 優先使用 sUNC，能力不足或安裝失敗時才嘗試方法表替換。
	Table 只修改該表欄位；Function 可涵蓋已保存的閉包引用。兩者都需明確 Matches。
	@param self 接入入口的引擎。
	@param Owner 明確的模組或方法擁有者，必須指定真正存放函數的表。
	@param Key 方法欄位名稱。
	@param Binding 射擊協定。
	@param Mode Auto、Function 或 Table；省略時為 Auto。
	@return 解除函數；失敗時為 nil。
	@return 失敗原因；成功時為 nil。

	使用範例：
	```lua
	-- Engine、FireModule、Binding 已依遊戲實際協定建立。
	local Disconnect, Reason = Engine:BindMethod(FireModule, "Fire", Binding)
	assert(Disconnect, Reason)
	Disconnect()
	```
]]
function CSilentAimEngine.BindMethod(
	self: CSilentAimEngineType,
	Owner,
	Key: string,
	Binding: ShotBinding,
	Mode: ("Auto" | "Function" | "Table")?
): ((() -> ())?, string?)
	if self._bDestroyed then
		return nil, "Engine is destroyed"
	end
	if not _IsBinding(Binding) then
		return nil, "Invalid binding callbacks or phase"
	end
	Mode = Mode or "Auto"
	if not table.find({ "Auto", "Function", "Table" }, Mode) then
		return nil, "Invalid binding mode"
	end
	if type(Owner) ~= "table" or type(rawget(Owner, Key)) ~= "function" then
		return nil, "Owner must contain the method directly"
	end
	local Original = rawget(Owner, Key)
	if
		(_MethodBindings[Owner] and _MethodBindings[Owner][Key])
		or (_FunctionHooks[Original] and _FunctionHooks[Original].bActive)
	then
		return nil, "Method already has an active engine binding"
	end
	if Mode ~= "Table" then
		local Disconnect, Reason = self:BindFunction(Original, Binding)
		if Disconnect or Mode == "Function" then
			return Disconnect, Reason
		end
	end
	if table.isfrozen(Owner) then
		return nil, "Method table is frozen and function hook is unavailable"
	end
	local Record = { Original = Original, Invoke = Original, bActive = false }
	self:_Activate(Record, Binding)
	--[[
		將表欄位呼叫轉交給目前啟用的實作。
		@param ... 原始完整實參。
		@return 適配或原始方法的完整回傳值。
	]]
	local function Wrapper(...)
		return Record.Invoke(...)
	end
	Owner[Key] = Wrapper
	local Bindings = _MethodBindings[Owner] or {}
	_MethodBindings[Owner], Bindings[Key] = Bindings, Record
	--[[
		只在欄位仍屬於此綁定時還原；其他包裝器已接手時留下透明轉交器。
	]]
	local function Disconnect()
		if not Record.bActive then
			return
		end
		Record.bActive = false
		Record.Invoke = Original
		if Bindings[Key] == Record then
			Bindings[Key] = nil
		end
		if rawget(Owner, Key) == Wrapper and not table.isfrozen(Owner) then
			Owner[Key] = Original
		end
	end
	table.insert(self._Disconnectors, Disconnect)
	return Disconnect, nil
end

--[[
	停用引擎、解除其全部綁定並清除選取結果；可重複呼叫。
	@param self 要卸載的引擎；其他實例與呼叫端的事件由各自擁有者管理。
]]
function CSilentAimEngine.Destroy(self: CSilentAimEngineType): ()
	if self._bDestroyed then
		return
	end
	self:SetTargetMarkerParent(nil)
	self._bDestroyed, self._Selected = true, nil
	for Index = #self._Disconnectors, 1, -1 do
		local bOk, Reason = pcall(self._Disconnectors[Index])
		if not bOk then
			self._LastError = tostring(Reason)
		end
	end
	table.clear(self._Disconnectors)
	table.clear(self._Busy)
end

return CSilentAimEngine

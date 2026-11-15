--[[
	共用原生 GUI ESP；呼叫端提供目標資料並安排 Refresh 與 Render。
	不掃描遊戲場景、不判斷敵友，也不持有 UI Library 或全域單例。
]]

export type EspTarget = {
	Object: Instance,
	Part: BasePart,
	Title: string,
	Color: Color3,
	Priority: number,
}

export type EspOptions = {
	bShowLabels: boolean,
	bShowTracers: boolean,
	MaxDistance: number,
	MaxMarkers: number,
}

--[[
	引擎擁有的單一目標視覺物件；Part 可在 Refresh 時換成新錨點。
]]
type Marker = {
	Part: BasePart,
	Highlight: Highlight,
	Billboard: BillboardGui,
	Text: TextLabel,
	Line: Frame,
	Arrow: TextLabel,
	Dot: Frame,
}

--[[
	每個實例獨立擁有標記、世界效果資料夾與畫面指引層。
]]
local CEspEngine = {}
CEspEngine.__index = CEspEngine

--[[
	引擎實例的私有狀態與 CEspEngine metatable 方法；不共用其他實例的視覺物件。
]]
export type CEspEngineType = typeof(setmetatable(
	{} :: {
		_World: Workspace,
		_Effects: Folder,
		_TracerLayer: Frame,
		_Markers: { [Instance]: Marker },
		_bShowTracers: boolean,
		_bDestroyed: boolean,
	},
	CEspEngine
))

--[[
	建立引擎使用的原生物件，設定屬性後再掛入父節點。
	@param ClassName Rbx 類別名稱。
	@param Properties 要設定的原生屬性。
	@param Parent 引擎擁有的父節點。
	@return 已完成設定的物件。
]]
local function _New(ClassName: string, Properties: { [string]: unknown }, Parent: Instance): Instance
	local Object = Instance.new(ClassName)
	for Key, Value in pairs(Properties) do
		Object[Key] = Value
	end
	Object.Parent = Parent
	return Object
end

--[[
	建立原生文字標記，統一名稱標籤與方向箭頭的字型和對齊。
	@param Parent 文字所在的 BillboardGui 或畫面指引層。
	@param Text 初始文字。
	@param Size 標籤尺寸。
	@param TextSize 字體大小。
	@param Color 文字顏色。
	@return 新建立的文字標籤。
]]
local function _Label(Parent: Instance, Text: string, Size: UDim2, TextSize: number, Color: Color3): TextLabel
	return _New("TextLabel", {
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0, 0),
		Size = Size,
		Text = Text,
		TextColor3 = Color,
		TextSize = TextSize,
		Font = Enum.Font.Gotham,
		TextXAlignment = Enum.TextXAlignment.Center,
	}, Parent) :: TextLabel
end

--[[
	建立獨立 ESP 引擎，不自動連接 RunService 事件。
	@param OverlayParent 指引層的父節點，須與 Camera Viewport 座標對齊。
	@param World 目標所在世界；省略時使用 workspace。
	@return 引擎實例；呼叫端卸載時須呼叫 Destroy。

	使用範例：
	```lua
	-- Overlay 為與 Viewport 對齊的全畫面 GUI 容器，Target 為場景中的 BasePart。
	local Engine = CEspEngine.new(Overlay)
	Engine:Refresh({{
		Object = Target, Part = Target, Title = "目標",
		Color = Color3.new(1, 1, 1), Priority = 1,
	}}, { bShowLabels = true, bShowTracers = true, MaxDistance = 500, MaxMarkers = 160 })
	Engine:Render() -- 由呼叫端每幀呼叫；Refresh 可使用較低頻率。
	Engine:Destroy()
	```
]]
function CEspEngine.new(OverlayParent: Instance, World: Workspace?): CEspEngineType
	local TargetWorld = World or workspace
	local self = setmetatable({
		_World = TargetWorld,
		_Effects = _New("Folder", { Name = "EspEngine_LocalEffects" }, TargetWorld) :: Folder,
		_TracerLayer = _New("Frame", {
			Name = "TracerLayer",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Visible = false,
			ZIndex = 1,
		}, OverlayParent) :: Frame,
		_Markers = {} :: { [Instance]: Marker },
		_bShowTracers = false,
		_bDestroyed = false,
	}, CEspEngine)
	return self
end

--[[
	刪除一個目標的全部視覺物件。
	@param self 持有標記的引擎。
	@param Object 目標的穩定識別物件。
]]
function CEspEngine._RemoveMarker(self: CEspEngineType, Object: Instance): ()
	local Record = self._Markers[Object]
	if not Record then
		return
	end
	Record.Highlight:Destroy()
	Record.Billboard:Destroy()
	Record.Line:Destroy()
	Record.Arrow:Destroy()
	Record.Dot:Destroy()
	self._Markers[Object] = nil
end

--[[
	建立一個目標的輪廓、文字與方向指引物件。
	@param self 擁有新物件的引擎。
	@param Target 呼叫端提供的目標與外觀資料。
	@return 新建立的視覺記錄。
]]
function CEspEngine._CreateMarker(self: CEspEngineType, Target: EspTarget): Marker
	local Highlight = _New("Highlight", {
		Adornee = Target.Object,
		DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
		FillTransparency = 0.75,
		OutlineTransparency = 0,
	}, self._Effects) :: Highlight
	local Billboard = _New("BillboardGui", {
		Adornee = Target.Part,
		AlwaysOnTop = true,
		Size = UDim2.fromOffset(230, 44),
		StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0),
	}, self._Effects) :: BillboardGui
	local Text = _Label(Billboard, "", UDim2.fromScale(1, 1), 12, Target.Color)
	Text.TextStrokeColor3 = Color3.new(0, 0, 0)
	Text.TextStrokeTransparency = 0.2
	local Line = _New("Frame", {
		Name = "DirectionLine",
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		BackgroundTransparency = 0.2,
		BackgroundColor3 = Target.Color,
		Visible = false,
	}, self._TracerLayer) :: Frame
	local Arrow = _Label(self._TracerLayer, "▲", UDim2.fromOffset(20, 20), 16, Target.Color)
	Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	Arrow.TextStrokeTransparency = 0.4
	Arrow.Visible = false
	local Dot = _New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(5, 5),
		BorderSizePixel = 0,
		BackgroundColor3 = Target.Color,
		Visible = false,
	}, self._TracerLayer) :: Frame
	_New("UICorner", { CornerRadius = UDim.new(0, 3) }, Dot)
	return {
		Part = Target.Part,
		Highlight = Highlight,
		Billboard = Billboard,
		Text = Text,
		Line = Line,
		Arrow = Arrow,
		Dot = Dot,
	}
end

--[[
	立即切換全部方向指引；不影響 Highlight 與名稱標籤。
	@param self 要更新的引擎。
	@param bEnabled true 顯示方向指引，false 隱藏。
]]
function CEspEngine.SetTracersEnabled(self: CEspEngineType, bEnabled: boolean): ()
	if self._bDestroyed then
		return
	end
	self._bShowTracers = bEnabled
	self._TracerLayer.Visible = bEnabled
end

--[[
	以完整目標快照更新標記，移除不再入選的物件；不修改輸入資料。
	按 Priority 由小到大、同優先級按相機距離排序，套用距離與數量限制。
	@param self 要更新的引擎。
	@param Targets 已完成遊戲分類與去重的目標陣列；省略舊目標會移除其標記。
	@param Options 此次顯示設定；MaxDistance 使用 studs，math.huge 代表不限距離。

	使用範例：
	```lua
	-- Engine 為已建立的引擎。空快照移除全部標記。
	Engine:Refresh({}, {
		bShowLabels = true, bShowTracers = false, MaxDistance = math.huge, MaxMarkers = 160,
	})
	```
]]
function CEspEngine.Refresh(self: CEspEngineType, Targets: { EspTarget }, Options: EspOptions): ()
	if self._bDestroyed then
		return
	end
	self:SetTracersEnabled(Options.bShowTracers)
	local Camera = self._World.CurrentCamera
	local Visible = {}
	if Camera then
		for _, Target in ipairs(Targets) do
			if Target.Object:IsDescendantOf(self._World) and Target.Part:IsDescendantOf(self._World) then
				local Distance = (Target.Part.Position - Camera.CFrame.Position).Magnitude
				if Distance <= Options.MaxDistance then
					table.insert(Visible, { Target = Target, Distance = Distance })
				end
			end
		end
	end
	--[[
		先比較分類優先級，再比較相機距離。
		@param Left 左側候選目標與距離。
		@param Right 右側候選目標與距離。
		@return true 表示 Left 應排在 Right 前面，false 表示不優先。
	]]
	table.sort(Visible, function(Left, Right)
		if Left.Target.Priority ~= Right.Target.Priority then
			return Left.Target.Priority < Right.Target.Priority
		end
		return Left.Distance < Right.Distance
	end)
	local Selected = {}
	for Index, Row in ipairs(Visible) do
		if Index > Options.MaxMarkers then
			break
		end
		Selected[Row.Target.Object] = Row
	end
	for Object in pairs(self._Markers) do
		if not Selected[Object] then
			self:_RemoveMarker(Object)
		end
	end
	for Object, Row in pairs(Selected) do
		local Target = Row.Target
		local Record = self._Markers[Object] or self:_CreateMarker(Target)
		self._Markers[Object] = Record
		Record.Part = Target.Part
		Record.Highlight.FillColor = Target.Color
		Record.Highlight.OutlineColor = Target.Color
		Record.Billboard.Adornee = Target.Part
		Record.Billboard.Enabled = Options.bShowLabels
		Record.Text.TextColor3 = Target.Color
		Record.Text.Text = Target.Title .. "\n" .. math.floor(Row.Distance) .. " studs"
		Record.Line.BackgroundColor3 = Target.Color
		Record.Arrow.TextColor3 = Target.Color
		Record.Dot.BackgroundColor3 = Target.Color
	end
end

--[[
	將投影座標限制在畫面邊緣，處理鏡頭後方與非有限座標。
	@param X 投影水平座標。
	@param Y 投影垂直座標。
	@param Z 相機深度；小於等於 0 表示鏡頭後方。
	@param Width Viewport 寬度，須大於 0。
	@param Height Viewport 高度，須大於 0。
	@return 指引終點水平座標。
	@return 指引終點垂直座標。
	@return true 表示使用邊緣箭頭，false 表示畫面內圓點。
]]
local function _TracerEndpoint(
	X: number,
	Y: number,
	Z: number,
	Width: number,
	Height: number
): (number, number, boolean)
	local Margin = math.min(16, Width / 4, Height / 4)
	local CenterX, CenterY = Width / 2, Height / 2
	local bInvalid = X ~= X or Y ~= Y or math.abs(X) == math.huge or math.abs(Y) == math.huge
	if bInvalid then
		X, Y = CenterX, CenterY
	end
	local bOutside = bInvalid or Z <= 0 or X < Margin or X > Width - Margin or Y < Margin or Y > Height - Margin
	if not bOutside then
		return X, Y, false
	end
	local DeltaX, DeltaY = X - CenterX, Y - CenterY
	if Z <= 0 then
		DeltaX, DeltaY = -DeltaX, -DeltaY
	end
	if math.abs(DeltaX) + math.abs(DeltaY) < 0.0001 then
		DeltaX, DeltaY = 0, -1
	end
	local FactorX = math.abs(DeltaX) > 0.0001 and (CenterX - Margin) / math.abs(DeltaX) or math.huge
	local FactorY = math.abs(DeltaY) > 0.0001 and (CenterY - Margin) / math.abs(DeltaY) or math.huge
	local Factor = math.min(FactorX, FactorY)
	return math.clamp(CenterX + DeltaX * Factor, Margin, Width - Margin),
		math.clamp(CenterY + DeltaY * Factor, Margin, Height - Margin),
		true
end

--[[
	每幀依照目前相機與目標位置更新方向指引，不建立 RunService 連線。
	@param self 要繪製的引擎；沒有相機或有效 Viewport 時隱藏指引。
]]
function CEspEngine.Render(self: CEspEngineType): ()
	if self._bDestroyed or not self._bShowTracers then
		return
	end
	local Camera = self._World.CurrentCamera
	local View = Camera and Camera.ViewportSize
	if not View or View.X <= 0 or View.Y <= 0 then
		self._TracerLayer.Visible = false
		return
	end
	self._TracerLayer.Visible = true
	local StartX, StartY = View.X / 2, View.Y - 45
	for Object, Record in pairs(self._Markers) do
		if not Object:IsDescendantOf(self._World) or not Record.Part:IsDescendantOf(self._World) then
			self:_RemoveMarker(Object)
		else
			local Position = Camera:WorldToViewportPoint(Record.Part.Position)
			local X, Y, bOutside = _TracerEndpoint(Position.X, Position.Y, Position.Z, View.X, View.Y)
			local DeltaX, DeltaY = X - StartX, Y - StartY
			local Length = math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
			Record.Line.Visible = Length > 1
			Record.Line.Position = UDim2.fromOffset((StartX + X) / 2, (StartY + Y) / 2)
			Record.Line.Size = UDim2.fromOffset(Length, 1.5)
			Record.Line.Rotation = math.deg(math.atan2(DeltaY, DeltaX))
			Record.Dot.Visible = not bOutside
			Record.Dot.Position = UDim2.fromOffset(X, Y)
			Record.Arrow.Visible = bOutside
			Record.Arrow.Position = UDim2.fromOffset(X, Y)
			Record.Arrow.Rotation = math.deg(math.atan2(Y - View.Y / 2, X - View.X / 2)) + 90
		end
	end
end

--[[
	卸載全部引擎物件；可重複呼叫，卸載後 Refresh 與 Render 不再執行。
	@param self 要卸載的引擎；不會刪除呼叫端提供的父節點或目標。
]]
function CEspEngine.Destroy(self: CEspEngineType): ()
	if self._bDestroyed then
		return
	end
	self._bDestroyed = true
	for Object in pairs(self._Markers) do
		self:_RemoveMarker(Object)
	end
	self._Effects:Destroy()
	self._TracerLayer:Destroy()
end

return CEspEngine

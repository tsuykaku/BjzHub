-- Run from the repository root: lune run Tests/EspEngine.spec.luau
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Rbx = require("@lune/roblox")
local Instance = Rbx.Instance
local Vector3 = Rbx.Vector3
local Color3 = Rbx.Color3

--[[
	Lune 未實作相機投影；測試用指定投影驗證畫面內、離屏及鏡頭後方行為。
	其餘物件階層、屬性、向量與銷毀皆使用 Lune 的 Rbx 實作。
]]
local _Projection = Vector3.new(400, 300, 10)
--[[
	回傳目前測試情境的固定投影。
	@param self 接收投影呼叫的相機。
	@param Position 目標世界座標，此替身以 _Projection 取代實際投影運算。
	@return 測試指定的畫面座標與深度。
	@return true 表示投影替身接受此次呼叫；引擎自行判定邊界。
]]
Rbx.implementMethod("Camera", "WorldToViewportPoint", function(self, Position)
	return _Projection, true
end)

local World = Instance.new("Workspace")
local Camera = Instance.new("Camera")
Camera.CFrame = Rbx.CFrame.new()
Camera.ViewportSize = Rbx.Vector2.new(800, 600)
World.CurrentCamera = Camera
local Overlay = Instance.new("Frame")
local Environment = setmetatable({
	workspace = World,
	Instance = Instance,
	Vector2 = Rbx.Vector2,
	Vector3 = Vector3,
	Color3 = Color3,
	UDim = Rbx.UDim,
	UDim2 = Rbx.UDim2,
	Enum = Rbx.Enum,
}, { __index = getfenv() })
local CEspEngine = Luau.load(Fs.readFile("Core/Features/EspEngine.luau"), {
	environment = Environment,
	debugName = "EspEngine",
})()
Luau.compile(Fs.readFile("Games/Isle/Isle_Bjz.luau"))

--[[
	建立測試場景目標。
	@param Distance 目標與原點相機的距離，單位為 studs。
	@param Priority 分類優先級，較小者優先。
	@return 可傳入引擎的目標資料。
]]
local function _Target(Distance: number, Priority: number)
	local Part = Instance.new("Part")
	Part.Position = Vector3.new(Distance, 0, 0)
	Part.Parent = World
	return { Object = Part, Part = Part, Title = "Target", Color = Color3.new(1, 0, 0), Priority = Priority }
end

local Engine = CEspEngine.new(Overlay)
local Options = { bShowLabels = true, bShowTracers = true, MaxDistance = 100, MaxMarkers = 1 }
local Near = _Target(10, 2)
local Priority = _Target(50, 1)
local Far = _Target(101, 0)
Engine:Refresh({ Near, Priority, Far }, Options)
local Effects = World:FindFirstChild("EspEngine_LocalEffects")
local Layer = Overlay:FindFirstChild("TracerLayer")
assert(#Effects:GetChildren() == 2, "Marker limit must restrict highlight and billboard count")
local Highlight = Effects:FindFirstChildWhichIsA("Highlight")
local Billboard = Effects:FindFirstChildWhichIsA("BillboardGui")
assert(Highlight.Adornee == Priority.Object, "Priority must win over proximity; out-of-range target must be excluded")
assert(
	Billboard:FindFirstChildWhichIsA("TextLabel").Text == "Target\n50 studs",
	"Name and camera distance must match Isle"
)

-- 同分類以較近者優先；相同目標重複 Refresh 不重建視覺物件。
Near.Priority = 1
Engine:Refresh({ Near, Priority }, Options)
assert(Effects:FindFirstChildWhichIsA("Highlight").Adornee == Near.Object, "Nearest target must win within a priority")
Billboard = Effects:FindFirstChildWhichIsA("BillboardGui")
local NewAnchor = Instance.new("Part")
NewAnchor.Position = Vector3.new(20, 0, 0)
NewAnchor.Parent = Near.Object
Near.Part = NewAnchor
Near.Title = "Changed"
Near.Color = Color3.new(0, 1, 0)
Options.bShowLabels = false
Engine:Refresh({ Near }, Options)
assert(Effects:FindFirstChildWhichIsA("BillboardGui") == Billboard, "Refresh must reuse an existing marker")
assert(Billboard.Adornee == NewAnchor and not Billboard.Enabled, "Anchor replacement and labels toggle must propagate")
assert(Effects:FindFirstChildWhichIsA("Highlight").FillColor == Near.Color, "Category color changes must propagate")
assert(
	Billboard:FindFirstChildWhichIsA("TextLabel").Text == "Changed\n20 studs",
	"Caption must update with anchor and title"
)

Engine:Render()
local Arrow, Dot, Line
for _, Child in ipairs(Layer:GetChildren()) do
	if Child:IsA("TextLabel") then
		Arrow = Child
	elseif Child.Name == "DirectionLine" then
		Line = Child
	else
		Dot = Child
	end
end
assert(Dot.Visible and not Arrow.Visible and Line.Visible, "On-screen target must show dot and line")
_Projection = Vector3.new(900, 300, 10)
Engine:Render()
assert(Arrow.Visible and not Dot.Visible and Arrow.Position.X.Offset == 784, "Offscreen target must clamp to edge")
_Projection = Vector3.new(400, 300, -10)
Engine:Render()
assert(
	Arrow.Visible and Arrow.Position.Y.Offset == 16,
	"Target directly behind camera must produce a finite edge arrow"
)
_Projection = Vector3.new(0 / 0, math.huge, 10)
Engine:Render()
assert(Arrow.Position.X.Offset == Arrow.Position.X.Offset, "Invalid projection must not propagate NaN")

Engine:SetTracersEnabled(false)
assert(not Layer.Visible, "Tracer toggle must hide overlay immediately")
Engine:SetTracersEnabled(true)
-- Lune 不接受將 CurrentCamera 的 Ref 屬性設為 nil，使用空世界替身模擬暫時缺少相機。
Engine._World = {}
Engine:Render()
assert(not Layer.Visible, "Missing camera must hide stale tracer overlay")
Engine._World = World
Camera.ViewportSize = Rbx.Vector2.new(0, 0)
Engine:Render()
assert(not Layer.Visible, "Zero viewport must hide tracers")
Camera.ViewportSize = Rbx.Vector2.new(800, 600)
Engine:Render()
assert(Layer.Visible, "Restored viewport must resume rendering")

Near.Object.Parent = nil
Engine:Render()
assert(#Effects:GetChildren() == 0 and #Layer:GetChildren() == 0, "Removed target must release all owned visuals")
Engine:Refresh({ Priority }, Options)
Engine:Refresh({}, Options)
assert(#Effects:GetChildren() == 0, "Empty snapshot must remove old markers")

local OtherEngine = CEspEngine.new(Overlay)
OtherEngine:Refresh({ Priority }, Options)
Engine:Destroy()
Engine:Destroy()
Engine:Refresh({ Priority }, Options)
Engine:Render()
assert(#World:GetChildren() > 0 and Priority.Object.Parent == World, "Destroy must preserve scene targets")
assert(#Overlay:GetChildren() == 1, "Destroy must leave other engine's overlay intact")
OtherEngine:Destroy()
assert(#Overlay:GetChildren() == 0, "Destroy must release tracer layers")

print(
	"PASS: syntax, selection, distance/count limits, marker reuse, anchors, labels/colors, tracers, camera/viewport recovery, removal, instance isolation and idempotent cleanup"
)

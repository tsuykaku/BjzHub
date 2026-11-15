--!nonstrict
--[[
	離線驗證內建 SVG 的正式解析器與導覽用圖示資料；不代表已在遊戲渲染 UI。
]]
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Source = Fs.readFile("Library/BjzUiLibrary_2.0.luau")
Luau.compile(Source)
local ParserStart = assert(Source:find("local CSvg =", 1, true))
local ParserEnd = assert(Source:find("function CSvg.Available", ParserStart, true))
local SourcesStart = assert(Source:find("CSvg.Sources = {", ParserEnd, true))
local SourcesEnd = assert(Source:find("local function _Icon", SourcesStart, true))
--[[
	提供解析器需要的有限數判斷，保留 NaN 與無窮值的拒絕行為。
	@param Value 待檢查的解析數值。
	@return true 為有限數；false 為其他值。
]]
local function _IsFinite(Value)
	return type(Value) == "number" and Value == Value and math.abs(Value) < math.huge
end
local TestEnvironment = setmetatable(
	{ _CopyTable = table.clone, _Clamp = math.clamp, _IsFinite = _IsFinite },
	{ __index = getfenv() }
)
local Svg =
	Luau.load(Source:sub(ParserStart, ParserEnd - 1) .. Source:sub(SourcesStart, SourcesEnd - 1) .. "return CSvg", {
		environment = TestEnvironment,
	})()
local ExpectedPaths = { Coin = 4, TreasureChest = 6, Potion = 5, People = 6, Food = 3 }
for Name, Count in ExpectedPaths do
	assert(Svg.Sources[Name], "缺少提供的 SVG：" .. Name)
	local Data = Svg.Builtin(Name)
	assert(#Data.Paths == Count and Data.PointCount > 0, "路徑數不符：" .. Name .. "=" .. #Data.Paths)
	assert(Svg.Builtin(Name:lower()) == Data, "大小寫別名必須沿用同份圖示快取")
	assert(
		#Data.Warnings == 0 and Data.ViewBox[3] == 24 and Data.ViewBox[4] == 24,
		"圖示必須適配現有導覽 viewport"
	)
	for _, Shape in Data.Paths do
		assert(math.abs(Shape.StrokeWidth - 1.7) < 0.000001, "不同原始尺寸應保留一致描邊寬度")
		for _, Point in Shape.Points do
			assert(
				Point.X >= -0.1 and Point.X <= 24.1 and Point.Y >= -0.1 and Point.Y <= 24.1,
				"圖示座標未正規化：" .. Name
			)
		end
	end
end
for Name in Svg.Sources do
	assert(Svg.Builtin(Name).PointCount > 0, "既有圖示不得失效：" .. Name)
end
print("BjzUiIcons: SVG parsing, geometry, stroke widths, aliases and existing builtins passed")

--!nonstrict
local Fs = require("@lune/fs")
local Luau = require("@lune/luau")
local Source = Fs.readFile("Games/FishAnAnimeRNG/FishAnAnimeRNG_Delta_Bjz.luau")
local PlannerSource = assert(Source:match("%-%- PAIR_PLANNER_START(.-)%-%- PAIR_PLANNER_END"))
local Planner = Luau.load(PlannerSource .. "\nreturn _CharacterPairs")()
local Definitions = { A = { CombinationPartner = { "B", "C" } }, B = {}, C = {}, Strong = {}, Weak = {} }
--[[ @param Name 角色名稱。 @param Cps 本體收益。 @param Count 同組份數。 @return 候選紀錄。 ]]
local function Character(Name, Cps, Count)
	return { Key = Name .. tostring(Cps), Name = Name, Cps = Cps, Count = Count or 1 }
end
--[[ @param Candidates 持有量。 @param Slots 實際格號。 @param Current 現況或空。 @return 完整搜尋結果。 ]]
local function Solve(Candidates, Slots, Current)
	local Empty = {}
	for Index = 1, #Slots do Empty[Index] = false end
	local Work = Planner.Start(Candidates, Slots, Definitions, Current or Empty)
	local Slices = 0
	while not Work.Done do
		local bOk, Reason = coroutine.resume(Work.Thread)
		assert(bOk, Reason)
		Slices += 1
		assert(Slices < 20000, "搜尋未收斂")
	end
	return Work
end
local A, B, C = Character("A", 10), Character("B", 9), Character("C", 8)
assert(Planner.IsAdjacent(1, 2) and not Planner.IsAdjacent(5, 6) and not Planner.IsAdjacent(2, 4))
assert(Planner.IsPair(B, A, Definitions), "單向定義也要辨識配對")
local Paired = Solve({ A, B, Character("Strong", 40) }, { 1, 2 })
assert(Paired.Income == 57 and Paired.Links == 1, "兩隻中階配對勝過最高單角")
local Single = Solve({ A, B, Character("Strong", 100) }, { 1, 2 })
assert(Single.Income == 110 and Single.Links == 0, "配對數多但總收益低時保留高產單角")
do
	local _, MoneyIncome, MoneyLinks = Planner.Select(Single)
	assert(MoneyIncome == 110 and MoneyLinks == 0, "固定選擇配對後收益最高配置")
end
local Across = Solve({ A, B }, { 5, 6 })
assert(Across.Income == 19 and Across.Links == 0, "不可跨排乘三")
do
	local Itsi, Ichi, Solo = Character("Itsi Naka", 10), Character("Ichi Naka", 9), Character("Strong", 100)
	for _, Native in {
		{ ["Itsi Naka"] = { CombinationPartner = { "Ichi Naka", "Miku Naka", "Nina Naka", "Yotso Naka" } },
			["Ichi Naka"] = { CombinationPartner = { "Itsi Naka", "Miku Naka", "Nina Naka", "Yotso Naka" } } },
		{},
	} do
		local Work = Planner.Start({ Itsi, Ichi, Solo }, { 1, 2, 3 }, Native, { Itsi, Solo, Ichi })
		while not Work.Done do local bOk, Reason = coroutine.resume(Work.Thread) assert(bOk, Reason) end
		local Layout, Income, Links = Planner.Select(Work)
		assert(Income == 157 and Links == 1, "Itsi Naka／Ichi Naka 在收益模式應以同一批角色重新排列，而非保留119 CPS")
		local IndexItsi, IndexIchi
		for Index, Value in Layout do
			if Value.Name == "Itsi Naka" then IndexItsi = Index end
			if Value.Name == "Ichi Naka" then IndexIchi = Index end
		end
		assert(math.abs(IndexItsi - IndexIchi) == 1, "Itsi Naka 與 Ichi Naka 必須輸出相鄰位置")
	end
	local Native = { A = { CombinationPartner = {} }, B = {} }
	local Snapshot, Before = Planner.Snapshot({ A, B }, Native)
	table.insert(Native.A.CombinationPartner, "B")
	local _, After = Planner.Snapshot({ A, B }, Native)
	assert(Before ~= After and not Planner.IsPair(A, B, Snapshot), "原生配對表更新須改變指紋，舊搜尋快照須保持不變")
end
do
	-- 固定同一批已選角色，只改順序就能提高產量時，收益模式也必須讓配對相鄰。
	local Strong = Character("Strong", 100)
	local Work = Solve({ A, B, Strong }, { 1, 2, 3 }, { A, Strong, B })
	local Layout, Income, Links = Planner.Select(Work)
	assert(Income == 157 and Links == 1, "總收益優先不可保留 A／單角／B 的未連結排列")
	assert((Layout[1].Name == "A" and Layout[2].Name == "B") or (Layout[1].Name == "B" and Layout[2].Name == "A")
		or (Layout[2].Name == "A" and Layout[3].Name == "B") or (Layout[2].Name == "B" and Layout[3].Name == "A"),
		"總收益優先須輸出實際相鄰位置，而非只提高收益數字")
end
local Chain = Solve({ A, B, C }, { 1, 2, 3 })
assert(Chain.Income == 81 and Chain.Links == 2, "中間角色兩邊配對也只乘三一次")
do
	local Strong = Character("Strong", 1000000000, 3)
	local Work = Solve({ A, B, C, Strong }, { 1, 2, 3 }, { Strong, Strong, Strong })
	local _, Income, Links = Planner.Select(Work)
	assert(Income == 3000000000 and Links == 0, "可達更多連結但收益更低時仍須保留最高收益配置")
end
local Duplicate = Solve({ Character("A", 10, 2), B }, { 1, 2, 3 })
assert(Duplicate.Income == 87 and Duplicate.Links == 2, "必須依持有份數配置，不憑空複製角色")
local Few = Solve({ A, B }, { 5, 6, 7 })
assert(Few.Income == 57 and Few.Best[1] == false, "角色不足時保留空格，配對留在同排")
local Variants = Solve({ A, Character("A", 1), B }, { 1, 2 })
assert(Variants.Income == 57, "同角色不同等級收益應分開比較")
local Empty = Solve({}, { 1, 2 })
assert(Empty.Income == 0)
do
	local High, LowA, LowB = Character("High", 1), Character("A", 100), Character("B", 90)
	High.Rarity, LowA.Rarity, LowB.Rarity = "God", "Common", "Common"
	local Work = Solve({ High, LowA, LowB }, { 1, 2 })
	assert(Work.Income == 570 and Work.Links == 1, "高品質不能排擠收益更高的低品質配對")
	Work = Solve({ A, B, Character("Strong", 100), Character("Strong2", 80) }, { 4, 5, 6 })
	assert(Work.Income == 190 and Work.Links == 0, "單角組合較高收益時不可硬塞配對")
	Work = Solve({ A, B, Character("Strong", 100) }, { 4, 5, 6 })
	assert(Work.Income == 157 and Work.Best[3].Name == "Strong", "配對須放同排4／5，單角留在6，不能讓單角阻斷配對")
end

do
	local Serde = require("@lune/serde")
	local Fixture = Serde.decode("json", Fs.readFile("Tests/FishAnAnimePairsFromHtml.json"))
	local Aliases = { ["Teto"] = "Tetora", ["C.C"] = "CeCe", ["Ai Hoshi"] = "AI Hoshi",
		["Ramilia Scarlette"] = "Rami Scarlette", ["Flandra Scarlette"] = "Flara Scarlette", ["Kirara"] = "Kirali" }
	local Seen, Count = {}, 0
	assert(#Fixture.pairs == 58 and #Planner.HTML_PAIRS == 58, "必須完整收錄 HTML 展開後的58組")
	for _, Pair in Fixture.pairs do
		local Left, Right = Character(Pair.CharacterA, 10), Character(Pair.CharacterB, 9)
		assert(Planner.IsPair(Left, Right, {}) and Planner.IsPair(Right, Left, {}), "HTML配對須雙向成立：" .. Pair.CharacterA .. "/" .. Pair.CharacterB)
		Left.Name, Right.Name = Aliases[Left.Name] or Left.Name, Aliases[Right.Name] or Right.Name
		local KeyBefore = Left.Key
		assert(Planner.IsPair(Left, Right, {}), "遊戲內部名稱也必須辨識配對")
		local Work = Solve({ Left, Right, Character("Strong", 40) }, { 1, 2 })
		assert(Work.Income == 57 and Work.Links == 1 and Left.Key == KeyBefore, "每一組均須真正納入收益搜尋且不改寫背包原始鍵")
		local Names = { Left.Name, Right.Name }
		table.sort(Names)
		local Key = table.concat(Names, "|")
		assert(not Seen[Key], "名稱對照後不能重複計算同一條配對")
		Seen[Key], Count = true, Count + 1
	end
	assert(Count == 58)
	-- 原生資料仍可補充 HTML 沒有的新配對，不把共同夥伴錯當成彼此可連結。
	assert(not Planner.IsPair(Character("Kira Ho", 1), Character("Yin", 1), {}))
	assert(Planner.IsPair(A, B, Definitions) and not Planner.IsPair(B, C, Definitions))
	local Nakas = { "Itsi Naka", "Ichi Naka", "Miku Naka", "Nina Naka", "Yotso Naka" }
	for Left = 1, #Nakas do
		for Right = Left + 1, #Nakas do assert(Planner.IsPair(Character(Nakas[Left], 1), Character(Nakas[Right], 1), {})) end
	end
end

--[[
	獨立暴力列舉作為 oracle；不使用規劃器的剪枝、快取或計分。
	@param Candidates 唯一實體角色，每份最多使用一次。
	@param Slots 小規模展台清單。
	@return 最高收益。
	@return 最高收益配置中最多相鄰連結數。
]]
local function Brute(Candidates, Slots)
	local Best, BestLinks, Layout, Used = 0, 0, {}, {}
	--[[ @param Position 下一個格位。 ]]
	local function Visit(Position)
		if Position > #Slots then
			local Total, Links, Boost = 0, 0, {}
			for Index = 2, #Slots do
				local Left, Right = Layout[Index - 1], Layout[Index]
				if Left and Right and Slots[Index] == Slots[Index - 1] + 1 and math.ceil(Slots[Index] / 5) == math.ceil(Slots[Index - 1] / 5)
					and ((Left.Name == "A" and (Right.Name == "B" or Right.Name == "C"))
						or (Right.Name == "A" and (Left.Name == "B" or Left.Name == "C"))) then
					Boost[Index], Boost[Index - 1], Links = true, true, Links + 1
				end
			end
			for Index, Value in Layout do if Value then Total += Value.Cps * (if Boost[Index] then 3 else 1) end end
			if Total > Best or (Total == Best and Links > BestLinks) then Best, BestLinks = Total, Links end
			return
		end
		for Index, Value in Candidates do
			if Used[Index] then continue end
			Used[Index], Layout[Position] = true, Value
			Visit(Position + 1)
			Used[Index] = nil
		end
		Layout[Position] = false
		Visit(Position + 1)
	end
	Visit(1)
	return Best, BestLinks
end
math.randomseed(78291)
for Trial = 1, 80 do
	local Candidates = {}
	for Index, Name in { "A", "A", "B", "C", "Strong" } do
		local Value = Character(Name, math.random(1, 50))
		Value.Key ..= tostring(Index)
		Candidates[Index] = Value
	end
	local Slots = if Trial % 2 == 0 then { 3, 4, 5, 6 } else { 1, 2, 3, 4 }
	local Expected, BestLinks = Brute(Candidates, Slots)
	local Actual = Solve(Candidates, Slots)
	assert(Actual.Income == Expected and Actual.Links == BestLinks, "最高收益及同收益連結數必須與獨立 oracle 一致：" .. Trial)
end
do
	-- 強制極短片長，驗證正式 Advance 呼叫會連續推進，並能在時間片之間取消。
	local AdvanceSource = assert(Source:match("(function _CharacterPairs%.Advance.-\nend)"))
	local Runtime, Controller = { bAlive = true }, { bAutoCharacters = true }
	local Waits, bCancelOnWait = 0, true
	local Tasks = {}
	--[[ @param Seconds 片間短暫讓出時間，不使用使用者的整輪間隔。 ]]
	function Tasks.wait(Seconds)
		assert(Seconds == 0.03)
		Waits += 1
		if bCancelOnWait and Waits == 3 then Controller.bAutoCharacters = false end
	end
	--[[ @param Key 功能狀態鍵。 @param Text 搜尋狀態。 ]]
	local function Status(Key, Text) assert(Key == "bAutoCharacters" and type(Text) == "string") end
	local Engine = Luau.load(PlannerSource:gsub("Work.Nodes %% 2000", "Work.Nodes %% 2") .. "\n" .. AdvanceSource .. "\nreturn _CharacterPairs", {
		environment = { _Runtime = Runtime, Controller = Controller, task = Tasks, _Status = Status },
	})()
	--[[ @param Work 正在計算的工作，確認顯示參照同一份進度。 ]]
	function Engine.Render(Work) assert(Work.Nodes > 0) end
	local Work = Engine.Start({ A, B, C, Character("Strong", 40), Character("Weak", 2) }, { 1, 2, 3, 4 }, Definitions, { false, false, false, false })
	Engine.Advance(Work)
	assert(Waits == 3 and not Work.Done and Runtime.bCharacterContinue, "停止開關須在片間生效，並保留搜尋進度")
	local Before = Work.Nodes
	Engine.Advance(Work)
	assert(Work.Nodes == Before, "停用後不得繼續計算")
	Controller.bAutoCharacters, bCancelOnWait = true, false
	for Index = 1, 1000 do if Work.Done then break end Engine.Advance(Work) end
	assert(Work.Done and Work.Nodes > Before and Waits > 3, "同一工作必須持續推進至完成")
end
print("FishAnAnimePairs: all assertions passed")

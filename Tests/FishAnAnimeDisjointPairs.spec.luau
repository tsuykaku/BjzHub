local Fs, Luau, Serde = require("@lune/fs"), require("@lune/luau"), require("@lune/serde")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local Planner = Luau.load(assert(Source:match("%-%- PAIR_PLANNER_START(.-)%-%- PAIR_PLANNER_END")) .. "\nreturn _CharacterPairs")()
local Fixture = Serde.decode("json", Fs.readFile("Tests/FishAnAnimeDisjointPairs.json"))
--[[ @param Candidates 持有角色。 @param Slots 格位。 @param Definitions 配對表。 @param Current 現況。 @return 完成的獨立配對方案。 ]]
local function Solve(Candidates, Slots, Definitions, Current)
	local Work = Planner.Start(Candidates, Slots, Definitions, Current)
	while not Work.Done do
		local bOk, Reason = coroutine.resume(Work.Thread)
		assert(bOk, Reason)
		assert(Work.Nodes < 20000, "獨立配對不得回到大量排列搜尋")
	end
	return Work
end
do
	local Mika222, Tetora264, Mika249, Akaria = Fixture.Current[11], Fixture.Current[12], Fixture.Current[13], Fixture.Current[14]
	local Tetora1
	for _, Candidate in Fixture.Candidates do if Candidate.Key == "C|Tetora|" then Tetora1 = Candidate end end
	assert(Tetora1 and Tetora1.Count >= 1)
	assert(Mika222.PairMultiplier == 3 and Tetora264.PairMultiplier == 3 and Mika249.PairMultiplier == 1,
		"真實報告明確顯示第三格 Mika 未取得配對，不可再假設共享 Tetora")
	local Current = { Mika222, Tetora264, Mika249, Akaria }
	local Proposed = { Mika222, Tetora264, Mika249, Tetora1 }
	local Before, BeforeLinks = Planner.Score(Current, { 11, 12, 13, 14 }, Fixture.Definitions, true)
	local After, AfterLinks = Planner.Score(Proposed, { 11, 12, 13, 14 }, Fixture.Definitions)
	assert(Before == 6989571318 and BeforeLinks == 1 and After == 9293486082 and AfterLinks == 2,
		"使用者提出的四格配置須依真實 CPS 驗證，而非以舊共享模型否定")
	assert(After - Before == 2303914764)
	local Work = Solve({ Mika222, Tetora264, Mika249, Akaria, Tetora1 }, { 11, 12, 13, 14 }, Fixture.Definitions, Current)
	assert(Work.Income >= After and Work.Links == 2 and not Work.bBestObserved, "搜尋必須找到兩組獨立配對，取代高估收益的三人鏈")
end
do
	-- 相同錯誤套用至每組任意名稱，不能只為 Mika／Tetora 寫特例。
	for _, Names in { { "Remi", "Subara" }, { "Riza II", "Kaneko" }, { "Ichi Naka", "Itsi Naka" }, { "NewLeft", "NewRight" } } do
		local A = { Key = "A-high", Name = Names[1], Cps = 100, Count = 1 }
		local A2 = { Key = "A-low", Name = Names[1], Cps = 90, Count = 1 }
		local B = { Key = "B-high", Name = Names[2], Cps = 10, Count = 1 }
		local B2 = { Key = "B-low", Name = Names[2], Cps = 1, Count = 1 }
		local Solo = { Key = "Solo", Name = "Unpaired", Cps = 80, Count = 1 }
		local Definitions = { [Names[1]] = { CombinationPartner = Names[2] } }
		local Before, BeforeLinks = Planner.Score({ A, B, A2, Solo }, { 1, 2, 3, 4 }, Definitions)
		assert(Before == 500 and BeforeLinks == 1, "通用三人鏈不可共享中間夥伴")
		local Work = Solve({ A, A2, B, B2, Solo }, { 1, 2, 3, 4 }, Definitions, { A, B, A2, Solo })
		assert(Work.Income == 603 and Work.Links == 2, "所有名稱都必須能以兩組配對勝過單角混排")
		local Income, _, Pairs = Planner.Score(Work.Best, { 1, 2, 3, 4 }, Definitions)
		local Used = {}
		assert(Income == 603)
		for _, Pair in Pairs do for _, Position in Pair do assert(not Used[Position]) Used[Position] = true end end
		Solo.Cps = 1000
		Work = Solve({ A, A2, B, B2, Solo }, { 1, 2, 3, 4 }, Definitions, { A, B, A2, Solo })
		assert(Work.Income == 1420 and Work.Links == 1, "高產單角勝過第二組配對時仍要保留，不能盲目追求配對數")
	end
end
local Before = Planner.Score(Fixture.Current, Fixture.Slots, Fixture.Definitions, true)
local Work = Solve(Fixture.Candidates, Fixture.Slots, Fixture.Definitions, Fixture.Current)
local Income, Links, Pairs = Planner.Score(Work.Best, Fixture.Slots, Work.Definitions, Work.bBestObserved)
assert(Work.Algorithm == "DisjointPairsV2" and Income == Work.Income and Links == Work.Links and Income > Before,
	"完整34格快照須依實際加成比較，並找到較高收益方案")
local Available, Used = {}, {}
for _, Candidate in Fixture.Candidates do Available[Candidate.Key] = (Available[Candidate.Key] or 0) + Candidate.Count end
for _, Character in Work.Best do if Character then Available[Character.Key] -= 1 assert(Available[Character.Key] >= 0) end end
for _, Pair in Pairs do
	for _, Position in Pair do assert(not Used[Position], "任何實例最多參與一組有效配對") Used[Position] = true end
end
local BoostedMika = 0
for Index, Character in Work.Best do if Character and Character.Name == "Summer Mika II" and Used[Index] then BoostedMika += 1 end end
assert(BoostedMika == 2, "完整快照也必須讓兩隻 Mika 各使用獨立夥伴，不只修正四格範例")
print(string.format("FishAnAnimeDisjointPairs: passed; observed %.0f CPS -> %.0f CPS; %d pairs, %d nodes", Before, Income, Links, Work.Nodes))

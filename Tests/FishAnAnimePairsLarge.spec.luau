local Fs, Luau, Serde = require("@lune/fs"), require("@lune/luau"), require("@lune/serde")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local Planner = Luau.load(assert(Source:match("%-%- PAIR_PLANNER_START(.-)%-%- PAIR_PLANNER_END")) .. "\nreturn _CharacterPairs")()
local Fixture = Serde.decode("json", Fs.readFile("Tests/FishAnAnimePairsLarge.json"))
local Started = os.clock()
local Work = Planner.Start(Fixture.Candidates, Fixture.Slots, Fixture.Definitions, Fixture.Current)
local Slices = 0
while not Work.Done do
	local bOk, Reason = coroutine.resume(Work.Thread)
	assert(bOk, Reason)
	Slices += 1
	assert(Work.Nodes < 10000 and Slices < 10000, "34格回歸必須在一萬次計算內完成，不能再展開數十萬個排列狀態")
end
assert(Work.Income >= Planner.Score(Fixture.Current, Fixture.Slots, Fixture.Definitions), "修正共享角色的錯誤估值後，仍須優於相同模型下的現況")
local Income, Links = Planner.Score(Work.Best, Fixture.Slots, Work.Definitions, Work.bBestObserved)
assert(Income == Work.Income and Links == Work.Links, "最佳收益必須對應實際可放置位置")
local Counts = {}
for _, Value in Fixture.Candidates do Counts[Value.Key] = (Counts[Value.Key] or 0) + Value.Count end
for _, Value in Work.Best do
	if Value then Counts[Value.Key] -= 1 assert(Counts[Value.Key] >= 0, "不能因合併同名角色而重複使用同一份變異／等級角色") end
end
print(string.format("FishAnAnimePairsLarge: passed; %d slots, %d blocks, %d states, %d nodes, %.3fs; %.0f CPS", #Fixture.Slots, Work.BlockCount, Work.States, Work.Nodes, os.clock() - Started, Work.Income))

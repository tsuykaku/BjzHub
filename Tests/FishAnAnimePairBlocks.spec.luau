local Fs, Luau = require("@lune/fs"), require("@lune/luau")
local Source = Fs.readFile("Games/FishAnAnimeRng/FishAnAnimeRng_Bjz.luau")
local Planner = Luau.load(assert(Source:match("%-%- PAIR_PLANNER_START(.-)%-%- PAIR_PLANNER_END")) .. "\nreturn _CharacterPairs")()
--[[
	直接列舉每個持有實例與空格作為獨立 oracle，不使用規劃器的區塊、裝箱或計分。
	@param Instances 個別持有實例，包含同名不同變異與同組多份。
	@param Slots 原生格位，可能跨排或缺格。
	@param Edges 雙向配對矩陣，與規劃器的定義轉換分開。
	@return 暴力最大收益。
	@return 相同收益下最大連結數。
]]
local function Brute(Instances, Slots, Edges)
	local Best, BestLinks, Used, Layout = 0, 0, {}, {}
	--[[ @param Position 下一個實體位置。 ]]
	local function Visit(Position)
		if Position > #Slots then
			local Boost, Links, Income = {}, 0, 0
			for Index = 2, #Slots do
				local Left, Right = Layout[Index - 1], Layout[Index]
				if not Boost[Index - 1] and Left and Right and Slots[Index] == Slots[Index - 1] + 1 and math.ceil(Slots[Index] / 5) == math.ceil(Slots[Index - 1] / 5)
					and (Edges[Left.Name] or {})[Right.Name] then Boost[Index], Boost[Index - 1], Links = true, true, Links + 1 end
			end
			for Index, Character in Layout do if Character then Income += Character.Cps * (if Boost[Index] then 3 else 1) end end
			if Income > Best or (Income == Best and Links > BestLinks) then Best, BestLinks = Income, Links end
			return
		end
		for Index, Character in Instances do
			if Used[Index] then continue end
			Used[Index], Layout[Position] = true, Character
			Visit(Position + 1)
			Used[Index] = nil
		end
		Layout[Position] = false
		Visit(Position + 1)
	end
	Visit(1)
	return Best, BestLinks
end
math.randomseed(840336)
for Trial = 1, 300 do
	local Candidates, Instances, Definitions, Edges = {}, {}, {}, {}
	local Names = { "TestA", "TestB", "TestC", "TestD" }
	for _, Name in Names do Definitions[Name], Edges[Name] = { CombinationPartner = {} }, {} end
	for Left, Name in Names do
		for Right = Left, #Names do
			if math.random() < 0.4 then
				table.insert(Definitions[Name].CombinationPartner, Names[Right])
				Edges[Name][Names[Right]], Edges[Names[Right]][Name] = true, true
			end
		end
	end
	for Index = 1, 5 do
		local Count = if Index == 1 and Trial % 3 == 0 then 2 else 1
		local Character = { Name = Names[math.random(1, #Names)], Key = "variant" .. Index, Count = Count, Cps = math.random(1, 25) }
		table.insert(Candidates, Character)
		for _ = 1, Count do table.insert(Instances, Character) end
	end
	local Slots = if Trial % 3 == 0 then { 3, 4, 5, 6, 7 } elseif Trial % 3 == 1 then { 1, 2, 4, 5 } else { 4, 5, 7, 8, 9 }
	local Current = {}
	for Index = 1, #Slots do Current[Index] = false end
	local Work = Planner.Start(Candidates, Slots, Definitions, Current)
	while not Work.Done do local bOk, Reason = coroutine.resume(Work.Thread) assert(bOk, Reason) end
	local Income, Links = Brute(Instances, Slots, Edges)
	assert(Work.Income == Income and Work.Links == Links, "區塊解與獨立完整排列不一致：" .. Trial .. " / " .. Work.Income .. " vs " .. Income)
end
do
	local Candidates, Definitions, Current = {}, {}, {}
	for Index = 1, 9 do Candidates[Index] = { Name = "Pack" .. Index, Key = "P" .. Index, Count = 1, Cps = 1 } Current[Index] = false end
	for _, Pair in { { 1, 2 }, { 2, 3 }, { 4, 5 }, { 6, 7 }, { 8, 9 } } do
		local Name = "Pack" .. Pair[1]
		Definitions[Name] = Definitions[Name] or { CombinationPartner = {} }
		table.insert(Definitions[Name].CombinationPartner, "Pack" .. Pair[2])
	end
	local Work = Planner.Start(Candidates, { 1, 2, 3, 4, 5, 6, 7, 8, 9 }, Definitions, Current)
	while not Work.Done do local bOk, Reason = coroutine.resume(Work.Thread) assert(bOk, Reason) end
	assert(Work.Income == 25 and Work.Links == 4, "五格排加四格排最多四組獨立配對，三人鏈不能共享中間角色")
end
print("FishAnAnimePairBlocks: passed (300 independent exhaustive cases and mixed row packing)")

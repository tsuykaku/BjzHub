--!nonstrict
--[[
	FishAnAnimeRng 無介面 AFK：1 FPS、關閉 3D、最低畫質、永久 UI／視覺／聲音清理。
	沿用 Universal/PerformanceMode_Bjz.luau 的 PerformanceEngine，不載入 UI 函式庫。
	新共用引擎提供有界佇列與 UI 優先刪除；舊版使用原清理流程，不中斷 AFK 初始化。
	不定時遍歷失效連線或修改紀錄；Animator 只在銷毀事件中解除自己的訂閱。
	不呼叫檔案讀寫 API、不反覆下載引擎；新版引擎不修改持久畫質，無法禁止引擎快取、分頁或系統日誌 I/O。
	保留場景碰撞、角色、工具、Remote 與遊戲邏輯；不提供自動釣魚等遊戲操作。
	永久刪除沒有備份，Destroy 只還原仍由本控制器持有的設定，已刪除物件需重新加入才能恢復。
	API 查證：sUNC getgenv／gethui；sUNC 導覽未列 FPS API，Pesde fps cap 搜尋無法存取。
	FPS 採用既有 UNC setfpscap 與執行器文件中的 getfpscap，不自行實作幀率限制器。
	https://docs.sunc.io/Environment/getgenv/、https://docs.sunc.io/Instances/gethui/
	https://github.com/unified-naming-convention/NamingStandard/blob/main/api/misc.md#setfpscap
	https://www.getwave.gg/documentation、https://create.roblox.com/docs/reference/engine/classes/AnimationTrack
	防閒置沿用附件 AntiIdleClient 的 VirtualUser 呼叫；重連只停用已核對的 AutoRejoinClient。
	使用範例：
	```lua
	-- 執行本檔後，可透過回傳值或共用環境卸載，不需要控制面板。
	getgenv().FishAnAnimeRngAfkBjz.Destroy()
	```
]]
local ENGINE_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/PerformanceEngine.luau"
local SINGLETON_KEY = "FishAnAnimeRngAfkBjz"
assert(game.PlaceId == 74729868188364, "此 AFK 腳本僅供 FishAnAnimeRng 使用")
assert(type(getgenv) == "function", "缺少 getgenv，無法管理 AFK 實例")
local Environment = getgenv()
assert(type(Environment) == "table", "getgenv 必須回傳 table")
local SetFpsCap, GetFpsCap = Environment.setfpscap or setfpscap, Environment.getfpscap or getfpscap
assert(type(SetFpsCap) == "function", "缺少 setfpscap，無法依要求限制為 1 FPS")
local Players, Workspace = game:GetService("Players"), game:GetService("Workspace")
local RunService, SoundService = game:GetService("RunService"), game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer
assert(Player, "請在遊戲用戶端執行")
local Previous = Environment[SINGLETON_KEY]
if type(Previous) == "table" and type(Previous.Destroy) == "function" then Previous.Destroy() end
local Api = { Version = "1.1.1", bActive = true, Warnings = {}, DeletedSounds = 0, StoppedAnimations = 0,
	Resources = { Queued = 0, QueuePeak = 0, MaxQueued = 512, Animators = 0 },
	Fps = { Requested = 1, Observed = nil, bVerified = false }, bRejoinBlocked = false, bAntiIdleReady = false }
--[[ 只持有本入口建立的工作、連線及可還原屬性；永久刪除不保存副本。 ]]
local _Engine, _Worker, _Maintenance, _OriginalFps, _AppliedFps, _VirtualUser = nil, nil, nil, nil, nil, nil
local _bFpsTouched, _LastIdleAt = false, -math.huge
local _Connections, _Queue = {}, {}
local _Watched, _Animators, _Scripts = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
--[[ 含有子物件的聲音只靜音，不連帶刪除其資料；卸載時還原仍持有的屬性。 ]]
local _Sounds = setmetatable({}, { __mode = "k" })
--[[ 素材範本先清空資源 ID，避免每次複製後又載入；只保留可還原的字串，不備份素材。 ]]
local _Templates, _OverflowRoots = setmetatable({}, { __mode = "k" }), setmetatable({}, { __mode = "k" })
Environment[SINGLETON_KEY] = Api

--[[
	同類錯誤只警告一次，並保留可讀狀態供無介面診斷。
	@param Key 能力或操作名稱。
	@param Reason 失敗原因。
]]
local function _Warn(Key: string, Reason): ()
	if Api.Warnings[Key] then return end
	Api.Warnings[Key] = tostring(Reason)
	warn("[FishAnAnimeRng AFK] " .. Key .. "：" .. tostring(Reason))
end

--[[
	讀取有效的 FPS 上限；沒有 getter 或讀取失敗時不猜測原設定。
	@return 有限且非負的上限；無法取得時為 nil。
]]
local function _ReadFps(): number?
	if type(GetFpsCap) ~= "function" then return nil end
	local bOk, Value = pcall(GetFpsCap)
	return if bOk and type(Value) == "number" and Value == Value and Value >= 0 and Value < math.huge then Value else nil
end

--[[
	套用 1 FPS 並在可讀時核對；被其他程式更改時由低頻維護重新套用。
	讀不到上限只記錄請求成功，不能宣稱已驗證實際 FPS。
]]
local function _LimitFps(): ()
	local Current = _ReadFps()
	if _bFpsTouched and Current == 1 then return end
	local bOk, Reason = pcall(SetFpsCap, 1)
	assert(bOk, "無法限制 1 FPS：" .. tostring(Reason))
	_bFpsTouched = true
	Api.Fps.Observed = _ReadFps()
	_AppliedFps = Api.Fps.Observed or 1
	Api.Fps.bVerified = Api.Fps.Observed == 1
	assert(Api.Fps.Observed == nil or Api.Fps.bVerified, "執行器未接受 1 FPS，上限回報為 " .. tostring(Api.Fps.Observed))
	if not Api.Fps.bVerified then _Warn("FPS 核對", "已呼叫 setfpscap(1)，但無法讀取上限，卸載也無法自動還原原上限") end
end

--[[
	只停用確定的視覺或重連腳本；記錄自己更動的原始啟用值。
	@param Object 已核對用途的 LocalScript。
]]
local function _DisableScript(Object): ()
	if not Object.Enabled then return end
	if _Scripts[Object] == nil then _Scripts[Object] = true end
	Object.Enabled = false
	assert(not Object.Enabled, "無法停用 " .. Object.Name)
end

--[[
	停用 PlayerScripts.Player.AutoRejoinClient，不攔截傳送或封鎖一般 Remote。
	每十五秒重新核對，可處理重生後替換的腳本；原生防閒置由本入口獨立承接。
]]
local function _PreventRejoin(): ()
	local Scripts = Player:FindFirstChild("PlayerScripts")
	local Folder = Scripts and Scripts:FindFirstChild("Player")
	local Rejoin = Folder and Folder:FindFirstChild("AutoRejoinClient")
	Api.bRejoinBlocked = false
	if Rejoin and Rejoin:IsA("LocalScript") then
		_DisableScript(Rejoin)
		Api.bRejoinBlocked = Rejoin.Enabled == false
	end
end

--[[
	處理引擎閒置事件，使用遊戲 AntiIdleClient 相同的原生呼叫。
	不依賴會被永久清理的 PlayerGui；失敗會留下具體原因。
]]
local function _AntiIdle(): ()
	if not Api.bActive or os.clock() - _LastIdleAt < 60 then return end
	_LastIdleAt = os.clock()
	--[[ 原生防閒置標記讓遊戲辨識這次合成輸入；不修改玩家貨幣或伺服器資料。 ]]
	local bOk, Reason = pcall(function()
		_G.__AntiIdleSyntheticAt = os.clock()
		_VirtualUser:CaptureController()
		_VirtualUser:ClickButton2(Vector2.new())
	end)
	if not bOk then _Warn("防閒置", Reason) end
end

--[[
	停止已存在或剛播放的動畫，不銷毀 Animator／Motor6D 等角色邏輯元件。
	@param Track 原生動畫軌道。
]]
local function _StopTrack(Track): ()
	if not Api.bActive then return end
	local bOk, Reason = pcall(Track.Stop, Track, 0.1)
	if bOk then Api.StoppedAnimations += 1 else _Warn("停止動畫", Reason) end
end

--[[
	取得純聲音／動畫／貼圖範本的資源欄位，不變更 MeshId、碰撞或遊戲資料。
	@param Object 複寫容器中的素材。
	@return 可清空的欄位；非目標物件為 nil。
]]
local function _TemplateProperty(Object): string?
	if Object:IsA("Sound") then return "SoundId" end
	if Object:IsA("Animation") then return "AnimationId" end
	if Object:IsA("Decal") or Object:IsA("Texture") then return "Texture" end
	if Object:IsA("MeshPart") then return "TextureID" end
	if Object:IsA("SpecialMesh") then return "TextureId" end
	return nil
end

--[[
	僅接受已確認的純視覺腳本，不讓其他遊戲腳本反覆佔用清理佇列。
	@param Object 待檢查的 LocalScript。
	@return 是否可停用。
]]
local function _IsVisualScript(Object): boolean
	local Scripts = Player:FindFirstChild("PlayerScripts")
	local WorldFx = Scripts and Scripts:FindFirstChild("WorldFX")
	return (WorldFx ~= nil and Object:IsDescendantOf(WorldFx))
		or (Object.Name == "Animate" and Object.Parent:IsA("Model") and Object.Parent:FindFirstChildOfClass("Humanoid") ~= nil)
end

--[[
	僅將真正需要處理的物件加入有上限的佇列；溢位合併成容器重掃，不無限保留物件。
	@param Object 新增物件或動畫軌道。
	@param Root 來源容器；動畫無容器時可為 nil。
]]
local function _Enqueue(Object, Root): ()
	if not Api.bActive or _Queue[Object] then return end
	local bTrack = Object:IsA("AnimationTrack")
	if not bTrack and not Object.Parent then return end
	local bInTemplates = not bTrack and Object:IsDescendantOf(ReplicatedStorage)
	local Property = if bInTemplates then _TemplateProperty(Object) else nil
	local bTemplate = Property ~= nil and Object[Property] ~= ""
	local bRelevant = if bInTemplates then bTemplate else bTrack or (Object:IsA("Sound") and not _Sounds[Object])
		or (Object:IsA("Animator") and not _Animators[Object])
		or (Object:IsA("LocalScript") and Object.Enabled and _IsVisualScript(Object))
	if not bRelevant then return end
	if Api.Resources.Queued >= Api.Resources.MaxQueued then
		if Root then _OverflowRoots[Root] = true end
		return
	end
	_Queue[Object] = true
	Api.Resources.Queued += 1
	Api.Resources.QueuePeak = math.max(Api.Resources.QueuePeak, Api.Resources.Queued)
end

--[[
	處理聲音、Animator 及已確認的純視覺腳本；不刪除模型、碰撞、工具或遊戲資料。
	@param Object 掃描或新增的物件。
]]
local function _Process(Object): ()
	if not Api.bActive or not Object.Parent then return end
	if Object:IsDescendantOf(ReplicatedStorage) then
		local Property = _TemplateProperty(Object)
		if Property and Object[Property] ~= "" then
			local Original = Object[Property]
			Object[Property] = ""
			if not _Templates[Object] then _Templates[Object] = { Property = Property, Original = Original } end
		end
		return
	end
	if Object:IsA("Sound") then
		if #Object:GetChildren() > 0 and not _Sounds[Object] then
			_Sounds[Object] = { Volume = Object.Volume, PlayOnRemove = Object.PlayOnRemove }
		end
		Object.PlayOnRemove = false
		Object:Stop()
		Object.Volume = 0
		if #Object:GetChildren() == 0 then Object:Destroy() Api.DeletedSounds += 1 end
	elseif Object:IsA("Animator") and Object:IsDescendantOf(Workspace) and not _Animators[Object] then
		for _, Track in Object:GetPlayingAnimationTracks() do _StopTrack(Track) end
		local Record = {}
		_Animators[Object] = Record
		Api.Resources.Animators += 1
		--[[
			動畫開始後延後停止，避免在原生 AnimationPlayed 事件內改變播放狀態。
			@param Track 新開始的動畫。
		]]
		Record.Played = Object.AnimationPlayed:Connect(function(Track) _Enqueue(Track, nil) end)
		--[[ 只回應實際銷毀事件，解除本 Animator 的訂閱；不執行定時遍歷。 ]]
		Record.Destroying = Object.Destroying:Connect(function()
			if _Animators[Object] ~= Record then return end
			Record.Played:Disconnect()
			Record.Destroying:Disconnect()
			_Animators[Object] = nil
			Api.Resources.Animators -= 1
		end)
	elseif Object:IsA("LocalScript") then
		if _IsVisualScript(Object) then _DisableScript(Object) end
	end
end

--[[
	監聽新增物件並把初始掃描放入去重佇列，不在事件派送中直接銷毀物件。
	@param Root 要監聽的容器。
]]
local function _Watch(Root): ()
	if not Root or _Watched[Root] then return end
	_Watched[Root] = true
	--[[
		新增物件只排入佇列，由單一工作批次處理。
		@param Object 新增的物件。
	]]
	table.insert(_Connections, Root.DescendantAdded:Connect(function(Object)
		_Enqueue(Object, Root)
	end))
	for _, Object in Root:GetDescendants() do _Enqueue(Object, Root) end
end

--[[
	停止所有工作與監聽，還原自己仍持有的腳本、畫質、渲染與 FPS 設定；可重複呼叫。
	永久刪除與已停止的動畫不重建；沒有有效原 FPS 上限時不猜測還原值。
	使用範例：
	```lua
	getgenv().FishAnAnimeRngAfkBjz.Destroy()
	```
]]
function Api.Destroy(): ()
	if not Api.bActive then return end
	Api.bActive = false
	for _, Job in { _Worker, _Maintenance } do if Job then pcall(task.cancel, Job) end end
	for _, Connection in _Connections do pcall(Connection.Disconnect, Connection) end
	table.clear(_Connections)
	table.clear(_Queue)
	Api.Resources.Queued = 0
	for _, Record in _Animators do
		if Record.Played then pcall(Record.Played.Disconnect, Record.Played) end
		if Record.Destroying then pcall(Record.Destroying.Disconnect, Record.Destroying) end
	end
	Api.Resources.Animators = 0
	table.clear(_OverflowRoots)
	if _Engine then
		local bOk, Reason = pcall(_Engine.Destroy)
		if not bOk then _Warn("還原共用引擎", Reason) end
	end
	for Object, bOriginal in _Scripts do
		--[[ 只還原自己停用且尚未被其他程式改動的腳本。 ]]
		pcall(function() if Object.Parent and not Object.Enabled then Object.Enabled = bOriginal end end)
	end
	table.clear(_Scripts)
	table.clear(_Animators)
	table.clear(_Watched)
	for Object, Original in _Sounds do
		--[[ 還原未刪除且仍由本入口靜音的聲音設定，不強制重新播放。 ]]
		pcall(function()
			if Object.Parent and Object.Volume == 0 then Object.Volume = Original.Volume end
			if Object.Parent and not Object.PlayOnRemove then Object.PlayOnRemove = Original.PlayOnRemove end
		end)
	end
	table.clear(_Sounds)
	for Object, Record in _Templates do
		--[[ 只還原仍由本入口清空的素材 ID；其他程式改動過的值不覆寫。 ]]
		pcall(function() if Object.Parent and Object[Record.Property] == "" then Object[Record.Property] = Record.Original end end)
	end
	table.clear(_Templates)
	if _bFpsTouched and _OriginalFps ~= nil then
		local Current = _ReadFps()
		if Current == _AppliedFps then
			local bOk, Reason = pcall(SetFpsCap, _OriginalFps)
			if not bOk then _Warn("還原 FPS", Reason) end
		end
	end
	if Environment[SINGLETON_KEY] == Api then Environment[SINGLETON_KEY] = nil end
end

--[[
	先建立獨立防閒置與 FPS 保護，再啟動共用引擎及額外清理；部分失敗由外層卸載。
]]
local function _Initialize(): ()
	_OriginalFps = _ReadFps()
	_LimitFps()
	_VirtualUser = game:GetService("VirtualUser")
	table.insert(_Connections, Player.Idled:Connect(_AntiIdle))
	Api.bAntiIdleReady = true
	_PreventRejoin()
	local EngineModule = loadstring(game:HttpGet(ENGINE_URL))()
	if not Api.bActive then return end
	assert(type(EngineModule) == "table" and EngineModule.Version == "3.0.0" and type(EngineModule.new) == "function",
		"需要 PerformanceEngine.luau 3.0.0，請同步更新共用引擎")
	Api.bLowMemoryActive = EngineModule.LowMemoryVersion == 1 and EngineModule.UiCleanupVersion == 1
	if not Api.bLowMemoryActive then _Warn("共用引擎", "尚未同步 UI 優先清理版本，先使用原本永久刪除流程；AFK 繼續執行") end
	local GetHui = Environment.gethui or gethui
	if type(GetHui) ~= "function" then _Warn("gethui", "缺少能力，無法清除隱藏容器；其他清理繼續") end
	_Engine = EngineModule.new({ GetHui = GetHui, bRenderingEnabled = false,
		bDeleteCoreGui = true, bDeleteGetHui = true, bPreserveUi = false, bDeleteVisuals = true,
		bLowMemory = Api.bLowMemoryActive, bSetSavedQuality = false })
	Api.Engine = _Engine
	_Engine.Start()
	_Watch(Workspace)
	_Watch(SoundService)
	_Watch(Player)
	_Watch(ReplicatedStorage)
	--[[ 單一低頻批次工作，處理新聲音／動畫，不建立逐幀掃描或每物件背景迴圈。 ]]
	_Worker = task.defer(function()
		while Api.bActive do
			if not next(_Queue) then
				local Root = next(_OverflowRoots)
				if Root then
					_OverflowRoots[Root] = nil
					for _, Object in Root:GetDescendants() do
						_Enqueue(Object, Root)
						if Api.Resources.Queued >= Api.Resources.MaxQueued then _OverflowRoots[Root] = true break end
					end
				end
			end
			local Count = 0
			while Api.bActive and Count < 500 do
				local Object = next(_Queue)
				if not Object then break end
				_Queue[Object] = nil
				Api.Resources.Queued -= 1
				local bOk, Reason = pcall(if Object:IsA("AnimationTrack") then _StopTrack else _Process, Object)
				if not bOk then _Warn("額外清理", Reason) end
				Count += 1
			end
			task.wait(1)
		end
	end)
	--[[ 防止遊戲重新建立重連腳本或其他程式改動 FPS／渲染；不重掃完整場景。 ]]
	_Maintenance = task.defer(function()
		while Api.bActive do
			task.wait(15)
			if not Api.bActive then break end
			local bOk, Reason = pcall(_PreventRejoin)
			if not bOk then _Warn("閒置重連保護", Reason) end
			bOk, Reason = pcall(_LimitFps)
			if not bOk then _Warn("維持 1 FPS", Reason) end
			local bRead, bEnabled = pcall(RunService.Is3dRenderingEnabled, RunService)
			if not bRead or bEnabled then
				local bApplied, RenderError = _Engine.SetRenderingEnabled(false)
				if not bApplied then _Warn("關閉 3D", RenderError) end
			end
		end
	end)
end

local bOk, Reason = pcall(_Initialize)
if not bOk then Api.Destroy() error("[FishAnAnimeRng AFK] 初始化失敗：" .. tostring(Reason), 0) end
return Api

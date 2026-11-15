--!nonstrict
--[[
	Rbx 共用效能引擎。模組載入沒有副作用；控制器以點號呼叫 Start、SetRenderingEnabled、SetUiCleanup、Destroy。
	永久刪除僅限 UI 與視覺元件，不保存副本，重新加入遊戲才能恢復。
	來源：https://docs.sunc.io/Instances/gethui/、Rbx RunService 與 UserGameSettings 文件。
	Pesde rendering/performance 搜尋結果為生命週期等套件；此處沿用引擎原生能力，不增加依賴。
]]
local PerformanceEngine = { Version = "3.0.0", SafeModeVersion = 1, LowMemoryVersion = 1, UiCleanupVersion = 1 }

--[[
	建立尚未啟動的獨立控制器；初始化失敗時仍可 Destroy 清理。
	@param Options 選填 Game、GetHui、ProtectedRoots、bRenderingEnabled、bDeleteCoreGui、bDeleteGetHui；bPreserveUi=true 保留所有 UI，bDeleteVisuals=false 不刪除視覺物件；bLowMemory=true 使用唯一有界工作；bSetSavedQuality=false 不修改持久畫質設定。省略維持原行為。
	@return 控制器；各方法使用點號呼叫，不傳入 self。
	使用範例：
	```lua
	local Engine = PerformanceEngine.new({ GetHui = gethui, bRenderingEnabled = false })
	Engine.Start()
	Engine.SetRenderingEnabled(true)
	Engine.Destroy()
	```
]]
function PerformanceEngine.new(Options)
	Options = Options or {}
	local Game = Options.Game or game
	local Players = Game:GetService("Players")
	local Workspace = Game:GetService("Workspace")
	local Lighting = Game:GetService("Lighting")
	local RunService = Game:GetService("RunService")
	local CoreGui = Game:GetService("CoreGui")
	local Player = Players.LocalPlayer
	assert(Player, "請在遊戲用戶端執行")
	local Api = {
		Version = PerformanceEngine.Version,
		Config = { bDeleteCoreGui = Options.bDeleteCoreGui == true, bDeleteGetHui = Options.bDeleteGetHui == true,
			bPreserveUi = Options.bPreserveUi == true, bDeleteVisuals = Options.bDeleteVisuals ~= false },
		bRenderingEnabled = true, bStarted = false, DeletedCount = 0, DeleteFailureCount = 0,
		Resources = { Queued = 0, QueuePeak = 0, MaxQueued = 256, Changes = 0, Connections = 0 },
	}
	--[[ 控制器擁有的連線、修改紀錄與工作取消狀態。弱鍵避免保留已離開場景的物件。 ]]
	local _Connections, _UiRoots = {}, setmetatable({}, { __mode = "k" })
	local _Changes = setmetatable({}, { __mode = "k" })
	local _bDestroyed, _bRenderingTouched = false, false
	local _bOriginalRenderingEnabled = true
	local _HiddenUiRoot = nil
	local _ProtectedRoots = Options.ProtectedRoots or {}
	--[[ AFK 低記憶體模式只建立一個批次工作；溢位按容器合併重掃，不為每物件新增工作。 ]]
	local _Queue, _ScanRoots, _WorkJob = {}, setmetatable({}, { __mode = "k" }), nil
	--[[ 低記憶體工作先宣告、處理邏輯稍後定義，共用同一個實作。 ]]
	local _Process
	--[[ UI 獨立優先處理，不排在可能需數十個畫格才能完成的場景掃描後方。 ]]
	local _UiQueue, _UiOverflowRoots, _UiJob, _UiQueued = {}, setmetatable({}, { __mode = "k" }), nil, 0
	local _ClearUiRoot

	--[[
		套用並保存屬性；第一次寫入成功才保存原值。
		@param Object 要修改的物件。
		@param Property 屬性名稱。
		@param Value 目標值。
		@return true 表示成功，false 表示讀寫失敗或已卸載。
	]]
	local function _Set(Object, Property, Value)
		if _bDestroyed then return false end
		local bOk, Old = pcall(function() return Object[Property] end)
		if not bOk then return false end
		if Old == Value then return true end
		bOk = pcall(function() Object[Property] = Value end)
		if bOk then
			local Properties = _Changes[Object]
			if not Properties then Properties = {}; _Changes[Object] = Properties end
			if not Properties[Property] then Properties[Property] = { Original = Old, Applied = Value } end
		end
		return bOk
	end

--[[
	釋放已離開場景的修改紀錄與已失效連線；不還原或重新套用任何屬性。
]]
	function Api.Prune()
		for Object in _Changes do
			if typeof(Object) == "Instance" and not Object.Parent and Object ~= Lighting
				and not Object:IsA("UserGameSettings") and not Object:IsA("RenderSettings") then _Changes[Object] = nil end
		end
		for Index = #_Connections, 1, -1 do
			if _Connections[Index].Connected == false then table.remove(_Connections, Index) end
		end
		local Count = 0
		for _ in _Changes do Count += 1 end
		Api.Resources.Changes, Api.Resources.Connections = Count, #_Connections
	end

	--[[
		啟動唯一清理工作，新增事件最多暫存256個物件；其餘合併為容器重掃。
		初始掃描逐批處理，卸載後不再建立或執行清理工作。
	]]
	local function _ScheduleLowMemory()
		if _bDestroyed or _WorkJob then return end
		--[[ 處理新增物件與合併的初始／溢位掃描，空佇列即釋放工作。 ]]
		_WorkJob = task.defer(function()
			local Count = 0
			while not _bDestroyed do
				local Object = next(_Queue)
				if Object then
					_Queue[Object] = nil
					Api.Resources.Queued -= 1
					local bOk, Reason = pcall(_Process, Object)
					if not bOk and not Api.ProcessError then Api.ProcessError = tostring(Reason) warn("[PerformanceEngine] " .. tostring(Reason)) end
					Count += 1
				else
					local Root = next(_ScanRoots)
					if not Root then break end
					_ScanRoots[Root] = nil
					local bOk, Items = pcall(Root.GetDescendants, Root)
					if bOk then
						local bHadParent = Root.Parent ~= nil
						for _, Item in Items do
							if _bDestroyed or (bHadParent and not Root.Parent) then break end
							local bProcessed, Reason = pcall(_Process, Item)
							if not bProcessed and not Api.ProcessError then Api.ProcessError = tostring(Reason) warn("[PerformanceEngine] " .. tostring(Reason)) end
							Count += 1
							if Count >= 300 then Count = 0 task.wait() end
						end
					end
				end
				if Count >= 300 then Count = 0 task.wait() end
			end
			_WorkJob = nil
		end)
	end

	--[[
		檢查控制面板及其祖先，避免清理父 UI 時連帶刪除。
		@param Object 待檢查物件。
		@return true 表示必須保留，false 表示不在保護範圍。
	]]
	local function _IsProtected(Object)
		for _, Root in ipairs(_ProtectedRoots) do
			if Object == Root or Object:IsDescendantOf(Root) or Root:IsDescendantOf(Object) then return true end
		end
		return false
	end

	--[[
		依目前選項判斷 UI 刪除範圍；gethui 在 CoreGui 內時優先採較精確範圍。
		@param Object 要判斷的 UI 元件。
		@return true 表示允許清除，false 表示保留。
	]]
	local function _CanDeleteUi(Object)
		if Api.Config.bPreserveUi then return false end
		if _IsProtected(Object) then return false end
		if _HiddenUiRoot then
			if Object == _HiddenUiRoot then return false end
			if Object:IsDescendantOf(_HiddenUiRoot) then
				if _HiddenUiRoot == CoreGui and not Api.Config.bDeleteCoreGui then return false end
				return Api.Config.bDeleteGetHui
			end
			if _HiddenUiRoot:IsDescendantOf(Object) and not Api.Config.bDeleteGetHui then return false end
		end
		if Object:IsDescendantOf(CoreGui) then
			return Api.Config.bDeleteCoreGui and (_HiddenUiRoot ~= nil or Api.Config.bDeleteGetHui)
		end
		return true
	end

	--[[
		永久刪除單一物件，失敗統計並只警告第一次。
		@param Object 已確認可清理的物件。
	]]
	local function _Delete(Object)
		local bOk, Message = pcall(function() Object:Destroy() end)
		if bOk then
			Api.DeletedCount += 1
		else
			Api.DeleteFailureCount += 1
			if Api.DeleteFailureCount == 1 then warn("[PerformanceEngine] 無法刪除部分受保護物件：" .. tostring(Message)) end
		end
	end

	--[[
		處理 UI、視覺元件與可還原的低畫質屬性；保留角色、碰撞與邏輯物件。
		@param Object 掃描取得或新加入的物件。
	]]
	_Process = function(Object)
		if _bDestroyed or not Object.Parent or _IsProtected(Object) then return end
		if Object:IsA("LayerCollector") or Object:IsA("GuiObject") then
			if _CanDeleteUi(Object) then _Delete(Object) end
			return
		end
		local bVisual = Object:IsA("Decal") or Object:IsA("Texture") or Object:IsA("SurfaceAppearance")
			or Object:IsA("ParticleEmitter") or Object:IsA("Trail") or Object:IsA("Beam")
			or Object:IsA("Fire") or Object:IsA("Smoke") or Object:IsA("Sparkles")
			or Object:IsA("Light") or Object:IsA("Highlight") or Object:IsA("PostEffect")
			or Object:IsA("Atmosphere") or Object:IsA("Clouds") or Object:IsA("Sky")
		if bVisual and (Object:IsDescendantOf(Workspace) or Object:IsDescendantOf(Lighting)) then
			if Api.Config.bDeleteVisuals and #Object:GetChildren() == 0 then _Delete(Object); return end
			_Set(Object, "Enabled", false)
			_Set(Object, "Transparency", 1)
			if Object:IsA("Clouds") or Object:IsA("Atmosphere") then _Set(Object, "Density", 0) end
		end
		if Object:IsA("BasePart") then
			_Set(Object, "Material", Enum.Material.Plastic)
			_Set(Object, "CastShadow", false)
			_Set(Object, "Reflectance", 0)
		end
		if Object:IsA("MeshPart") then
			_Set(Object, "RenderFidelity", Enum.RenderFidelity.Performance)
			_Set(Object, "TextureID", "")
		elseif Object:IsA("SpecialMesh") then
			_Set(Object, "TextureId", "")
		end
	end

--[[
	初始化時直接刪除 UI 根物件，非 UI 容器才繼續找子物件，不建立整份 UI 子孫快照。
	@param Root StarterGui、PlayerGui、CoreGui 或隱藏 UI 容器。
]]
	_ClearUiRoot = function(Root)
		if _bDestroyed or Api.Config.bPreserveUi then return end
		for _, Child in Root:GetChildren() do
			if (Child:IsA("LayerCollector") or Child:IsA("GuiObject")) and _CanDeleteUi(Child) then
				_Delete(Child)
			else _ClearUiRoot(Child) end
		end
	end

	--[[
		新 UI 只排入單一有界工作；刪除最外層 UI，避免每個子元件各建立工作。
		@param Object 新增的 GUI 物件。
		@param Root 來源容器，溢位時只合併一次 UI 重掃。
	]]
	local function _QueueUi(Object, Root)
		if _bDestroyed or Api.Config.bPreserveUi then return end
		local Candidate, Parent = Object, Object.Parent
		while Parent and Parent ~= Root do
			if Parent:IsA("LayerCollector") or Parent:IsA("GuiObject") then Candidate = Parent end
			Parent = Parent.Parent
		end
		if not _UiQueue[Candidate] then
			if _UiQueued < 256 then _UiQueue[Candidate] = true _UiQueued += 1
			else _UiOverflowRoots[Root] = true end
		end
		if _UiJob then return end
		--[[ UI 工作獨立於場景掃描，最遲在下一次排程取得執行機會。 ]]
		_UiJob = task.defer(function()
			while not _bDestroyed do
				local Item = next(_UiQueue)
				if Item then
					_UiQueue[Item] = nil
					_UiQueued -= 1
					_Process(Item)
				else
					local UiRoot = next(_UiOverflowRoots)
					if not UiRoot then break end
					_UiOverflowRoots[UiRoot] = nil
					_ClearUiRoot(UiRoot)
				end
			end
			_UiJob = nil
		end)
	end

	--[[
		監聽並分批掃描容器；重複呼叫只重掃，不重複建立連線。
		@param Root 要監聽的場景或 UI 容器。
	]]
	local function _Watch(Root)
		if not Root or _bDestroyed then return end
		if not _UiRoots[Root] then
			--[[ 延後處理避免在 DescendantAdded 派送期間同步銷毀物件。 ]]
			local bOk, Connection = pcall(function()
				return Root.DescendantAdded:Connect(function(Object)
					if _bDestroyed then return end
					if not Options.bLowMemory then task.defer(_Process, Object) return end
					if Object:IsA("LayerCollector") or Object:IsA("GuiObject") then _QueueUi(Object, Root) return end
					if not _Queue[Object] then
						if Api.Resources.Queued < Api.Resources.MaxQueued then
							_Queue[Object] = true
							Api.Resources.Queued += 1
							Api.Resources.QueuePeak = math.max(Api.Resources.QueuePeak, Api.Resources.Queued)
						else _ScanRoots[Root] = true end
					end
					_ScheduleLowMemory()
				end)
			end)
			if not bOk then warn("[PerformanceEngine] 無法監聽容器：" .. tostring(Connection)); return end
			_UiRoots[Root] = true
			table.insert(_Connections, Connection)
		end
		if Options.bLowMemory then
			if Root ~= Workspace and Root ~= Lighting then _ClearUiRoot(Root) return end
			_ScanRoots[Root] = true _ScheduleLowMemory() return
		end
		--[[ 掃描只在初始化或使用者更改清理選項時執行，不逐幀遍歷場景。 ]]
		task.spawn(function()
			local bOk, Items = pcall(function() return Root:GetDescendants() end)
			if not bOk then warn("[PerformanceEngine] 無法掃描容器：" .. tostring(Items)); return end
			for Index, Object in ipairs(Items) do
				if _bDestroyed then return end
				_Process(Object)
				if Index % 300 == 0 then task.wait() end
			end
		end)
	end

	--[[
		設定 3D 渲染，執行器拒絕時保留上一次成功狀態。
		@param bEnabled true 開啟，false 關閉。
		@return true 成功，false 失敗或已卸載。
		@return 失敗原因；成功為 nil。
	]]
	function Api.SetRenderingEnabled(bEnabled)
		assert(type(bEnabled) == "boolean", "bEnabled 必須是 boolean")
		if _bDestroyed then return false, "引擎已卸載" end
		local bOk, Message = pcall(function() RunService:Set3dRenderingEnabled(bEnabled) end)
		if bOk then Api.bRenderingEnabled = bEnabled; _bRenderingTouched = true end
		return bOk, if bOk then nil else tostring(Message)
	end

	--[[
		設定 CoreGui、gethui 清理選項；停用不會恢復已刪除元件。
		@param bCoreGui 是否清除 CoreGui。
		@param bGetHui 是否清除隱藏 UI。
	]]
	function Api.SetUiCleanup(bCoreGui, bGetHui)
		if _bDestroyed then return end
		Api.Config.bDeleteCoreGui = bCoreGui == true
		Api.Config.bDeleteGetHui = bGetHui == true
		if not Api.bStarted or Api.Config.bPreserveUi then return end
		if bCoreGui then _Watch(CoreGui) end
		if bGetHui then
			if _HiddenUiRoot then _Watch(_HiddenUiRoot) else warn("[PerformanceEngine] gethui 不可用") end
		end
	end

	--[[ 啟動畫質最低設定、渲染選項與清理；部分失敗時呼叫端須 Destroy。 ]]
	function Api.Start()
		if _bDestroyed or Api.bStarted then return end
		Api.bStarted = true
		if type(Options.GetHui) == "function" then
			local bOk, Root = pcall(Options.GetHui)
			if bOk and typeof(Root) == "Instance" then _HiddenUiRoot = Root end
		end
		local bReadOk, bEnabled = pcall(function() return RunService:Is3dRenderingEnabled() end)
		if bReadOk and type(bEnabled) == "boolean" then
			_bOriginalRenderingEnabled = bEnabled
			Api.bRenderingEnabled = bEnabled
		end
		local bRenderOk, Message = Api.SetRenderingEnabled(Options.bRenderingEnabled == true)
		if not bRenderOk then warn("[PerformanceEngine] 無法設定 3D 渲染：" .. tostring(Message)) end
		--[[ 設定最低手動畫質，並以屬性事件維持，卸載時先斷開事件再還原。 ]]
		local bQualityOk, UserGameSettings = false, nil
		if Options.bSetSavedQuality ~= false then
			bQualityOk, UserGameSettings = pcall(function() return UserSettings():GetService("UserGameSettings") end)
		end
		if bQualityOk and _Set(UserGameSettings, "SavedQualityLevel", Enum.SavedQualitySetting.QualityLevel1) then
			--[[ 使用者或其他腳本更改畫質時調回第 1 級。 ]]
			table.insert(_Connections, UserGameSettings:GetPropertyChangedSignal("SavedQualityLevel"):Connect(function()
				if not _bDestroyed then _Set(UserGameSettings, "SavedQualityLevel", Enum.SavedQualitySetting.QualityLevel1) end
			end))
		elseif Options.bSetSavedQuality ~= false then warn("[PerformanceEngine] 無法設定 SavedQualityLevel，執行器權限可能不足") end
		local bSettingsOk, Rendering = pcall(function() return settings().Rendering end)
		if bSettingsOk then _Set(Rendering, "QualityLevel", Enum.QualityLevel.Level01) end
		_Set(Lighting, "GlobalShadows", false)
		_Set(Lighting, "EnvironmentDiffuseScale", 0)
		_Set(Lighting, "EnvironmentSpecularScale", 0)
		local Terrain = Workspace:FindFirstChildOfClass("Terrain")
		if Terrain then
			_Set(Terrain, "Decoration", false)
			_Set(Terrain, "WaterWaveSize", 0)
			_Set(Terrain, "WaterWaveSpeed", 0)
			_Set(Terrain, "WaterReflectance", 0)
		end
		_Watch(Workspace)
		_Watch(Lighting)
		if not Api.Config.bPreserveUi then
			_Watch(Game:GetService("StarterGui"))
			_Watch(Player:FindFirstChildOfClass("PlayerGui"))
			--[[ 重生或替換 PlayerGui 後持續清理。 ]]
			table.insert(_Connections, Player.ChildAdded:Connect(function(Object)
				if not _bDestroyed and Object:IsA("PlayerGui") then _Watch(Object) end
			end))
		end
		Api.SetUiCleanup(Api.Config.bDeleteCoreGui, Api.Config.bDeleteGetHui)
	end

	--[[ 停止所有工作並還原自己仍持有的設定；無法還原永久刪除的物件。可重複呼叫。 ]]
	function Api.Destroy()
		if _bDestroyed then return end
		_bDestroyed = true
		if _WorkJob and type(task.cancel) == "function" then pcall(task.cancel, _WorkJob) end
		if _UiJob and type(task.cancel) == "function" then pcall(task.cancel, _UiJob) end
		_WorkJob = nil
		_UiJob, _UiQueued = nil, 0
		table.clear(_UiQueue)
		table.clear(_UiOverflowRoots)
		table.clear(_Queue)
		table.clear(_ScanRoots)
		Api.Resources.Queued = 0
		for _, Connection in ipairs(_Connections) do Connection:Disconnect() end
		table.clear(_Connections)
		table.clear(_UiRoots)
		for Object, Properties in pairs(_Changes) do
			for Property, Change in pairs(Properties) do
				--[[ 只還原仍等於本控制器設定值的屬性，避免覆寫其他腳本的新設定。 ]]
				pcall(function()
					if Object[Property] == Change.Applied then Object[Property] = Change.Original end
				end)
			end
		end
		table.clear(_Changes)
		if _bRenderingTouched then
			local bOk, Message = pcall(function() RunService:Set3dRenderingEnabled(_bOriginalRenderingEnabled) end)
			if not bOk then warn("[PerformanceEngine] 無法還原渲染：" .. tostring(Message)) end
		end
	end
	return Api
end
return PerformanceEngine

--!nonstrict
--[[
	BjzUi 效能模式入口；依賴遠端 PerformanceEngine 3.0.0 與現行 BjzUi 3.x。
	將引擎與本檔一同更新到 main 才能使用遠端載入；清理時保留本控制面板。
]]
local ENGINE_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/PerformanceEngine.luau"
local LIBRARY_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Library/BjzUiLibrary_2.0.luau"
local SINGLETON_KEY = "__BjzHubPerformance"
assert(type(getgenv) == "function", "需要 getgenv")
local Env = getgenv()
assert(type(Env) == "table", "getgenv 必須回傳 table")
local GetHui = Env.gethui or gethui
assert(type(GetHui) == "function", "需要 gethui 建立控制面板")
local bRootOk, Root = pcall(GetHui)
assert(bRootOk and typeof(Root) == "Instance", "gethui 未回傳有效容器")
local Previous = Env[SINGLETON_KEY]
if type(Previous) == "table" and type(Previous.Destroy) == "function" then Previous.Destroy() end
local Overrides = if type(Env.PerformanceModeConfig) == "table" then Env.PerformanceModeConfig else {}
local Api = { Version = "3.0.0" }
--[[ 入口擁有的引擎、視窗及初始化取消狀態；未建立前為 nil。 ]]
local _Engine, _Window, _Status = nil, nil, nil
local _bDestroyed = false
Env[SINGLETON_KEY] = Api

--[[ 卸載引擎與控制面板；初始化中卸載也安全，可重複呼叫。 ]]
function Api.Destroy()
	if _bDestroyed then return end
	_bDestroyed = true
	if _Engine then _Engine.Destroy() end
	if _Window then _Window:Destroy() end
	if Env[SINGLETON_KEY] == Api then Env[SINGLETON_KEY] = nil end
end

--[[
	更新控制面板訊息。
	@param Message 使用者可讀的操作結果。
]]
local function _Report(Message)
	if not _bDestroyed and _Status then _Status:Set("目前狀態", Message) end
end

--[[ 下載相容依賴，先建立並保護 UI，再啟動永久清理。失敗由外層統一卸載。 ]]
local function _Initialize()
	local EngineModule = loadstring(game:HttpGet(ENGINE_URL))()
	if _bDestroyed then return end
	assert(type(EngineModule) == "table" and EngineModule.Version == "3.0.0"
		and type(EngineModule.new) == "function", "請先將 PerformanceEngine.luau 3.0.0 更新到 main")
	local Library = loadstring(game:HttpGet(LIBRARY_URL))()
	if _bDestroyed then return end
	assert(type(Library) == "table" and type(Library.CreateWindow) == "function", "BjzUi API 不相容")
	_Window = Library:CreateWindow({
		Name = "極致效能模式", Brand = "BjzHub", ConfigId = "PerformanceMode",
		Width = 700, Height = 500, ConfigurationSaving = { bEnabled = false },
		OnUnload = Api.Destroy,
	})
	_Window.ScreenGui.Parent = Root
	assert(_Window.ScreenGui.Parent == Root, "無法將控制面板掛載到 gethui")
	Api.Window = _Window
	Api.LibraryVersion = Library.Version
	_Engine = EngineModule.new({
		GetHui = GetHui, ProtectedRoots = { _Window.ScreenGui },
		bRenderingEnabled = Overrides.bRenderingEnabled == true,
		bDeleteCoreGui = Overrides.bDeleteCoreGui == true,
		bDeleteGetHui = Overrides.bDeleteGetHui == true,
	})
	Api.Engine = _Engine
	_Engine.Start()
	local Tab = _Window:CreateTab({ Name = "效能模式" })
	local Controls = Tab:CreateSection({ Name = "控制", Side = "left" })
	local Information = Tab:CreateSection({ Name = "狀態", Side = "right" })
	_Status = Information:CreateParagraph({ Title = "目前狀態", Content = "已啟用最低畫質與清理" })
	Information:CreateParagraph({ Title = "永久清理", Content = "遊戲 UI 與視覺裝飾會持續刪除。關閉清理不會恢復已刪除物件；需重新加入遊戲。本控制面板會保留。" })
	--[[ 切換渲染失敗時回復開關顯示，保持 UI 與實際成功狀態一致。 ]]
	local RenderingToggle
	RenderingToggle = Controls:CreateToggle({
		Name = "開啟 3D 渲染", bCurrentValue = _Engine.bRenderingEnabled, bSave = false,
		--[[
			@param bEnabled true 開啟，false 關閉 3D 畫面。
		]]
		Callback = function(bEnabled)
			local bOk, Message = _Engine.SetRenderingEnabled(bEnabled)
			if bOk then
				_Report(if bEnabled then "3D 渲染已開啟，畫質維持最低" else "3D 渲染已關閉")
			else
				RenderingToggle:Set(_Engine.bRenderingEnabled, true)
				_Report("無法切換渲染：" .. tostring(Message))
			end
		end,
	})
	Controls:CreateToggle({
		Name = "永久清除 CoreGui", bCurrentValue = _Engine.Config.bDeleteCoreGui, bSave = false,
		--[[
			@param bEnabled 是否清除 CoreGui 中的 UI。
		]]
		Callback = function(bEnabled)
			_Engine.SetUiCleanup(bEnabled, _Engine.Config.bDeleteGetHui)
			_Report("CoreGui 清理" .. (if bEnabled then "已啟用" else "已停止（已刪除的 UI 不會恢復）"))
		end,
	})
	Controls:CreateToggle({
		Name = "永久清除 gethui（保留本面板）", bCurrentValue = _Engine.Config.bDeleteGetHui, bSave = false,
		--[[
			@param bEnabled 是否清除隱藏容器內其他 UI。
		]]
		Callback = function(bEnabled)
			_Engine.SetUiCleanup(_Engine.Config.bDeleteCoreGui, bEnabled)
			_Report("gethui 清理" .. (if bEnabled then "已啟用" else "已停止（已刪除的 UI 不會恢復）"))
		end,
	})
	Controls:CreateButton({ Name = "卸載效能模式", Callback = Api.Destroy })
end

local bOk, Reason = pcall(_Initialize)
if not bOk then
	Api.Destroy()
	error("[BjzHub Performance] 初始化失敗：" .. tostring(Reason), 0)
end
return Api

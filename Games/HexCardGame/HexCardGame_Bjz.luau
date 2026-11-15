--[[
HexCardGame | BjzUi Library 3.0 API 相容版

相容新版 b 前綴 API；不使用 MainFrame、Tab 等已移除的轉接入口。
Delta：將 BjzUiLibrary_2.0.luau 放在 workspace 根目錄或 workspace/BjzUi/。
優先讀取本機 UI Library；找不到才使用原本的 GitHub 網址。
自動刷怪模組同樣可放在上述目錄，檔名 HexCardGameAutoFarmLib.luau。
該模組在第一次開啟自動刷怪時載入，原本的卡牌與回合順序保持不變。

UI 設定：workspace/BjzUi/UiConfig.json；分組 CardGame_<UserId>。
保存角色數值與介面設定；傳送、副本選擇及刷怪開關不會自動恢復執行。
世界／副本：先選下拉選項，再按傳送／進入；重新整理不會觸發操作。
戰鬥範圍：一般頁提供卡片／移動的客戶端距離開關，預設關閉、不自動恢復。
開啟後涵蓋目前戰場；行動仍由伺服器驗證，無法保證伺服器接受超距離行動。
右上角可最小化／關閉；RightShift 顯示或隱藏，四邊四角可調整大小。
]]

if game.GameId ~= 380561452 then
    return
end

repeat task.wait() until game:IsLoaded() and game:GetService("Players").LocalPlayer

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local localPlayer = Players.LocalPlayer
local env = getgenv()

local AUTOFARM_LIBRARY_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Games/HexCardGame/Modules/HexCardGameAutoFarmLib.luau"

local function loadModule(filename, url)
    local sourceText, origin
    if type(readfile) == "function" then
        for _, path in ipairs({filename, "BjzUi/" .. filename}) do
            local ok, content = pcall(readfile, path)
            if ok and type(content) == "string" and content:find("%S") then
                sourceText, origin = content, path
                break
            end
        end
    end
    if not sourceText then
        local ok, content = pcall(function() return game:HttpGet(url) end)
        assert(ok and type(content) == "string" and content:find("%S"),
            filename .. " 載入失敗。請將檔案放入 Delta workspace 後重試。")
        sourceText, origin = content, filename .. " (GitHub)"
    end
    local chunk, compileError = loadstring(sourceText, "@" .. origin)
    assert(chunk, origin .. " 語法錯誤：" .. tostring(compileError))
    local ok, result = pcall(chunk)
    assert(ok, origin .. " 初始化失敗：" .. tostring(result))
    assert(type(result) == "table", origin .. " 必須回傳 Library table。")
    return result
end

--[[
    只載入採用 b 前綴 API 的 BjzUi 3.x；來源依序為本機、傳送快取及既有 GitHub 網址。
    本機舊版或損壞檔案不會阻擋後續來源；全部失敗時，錯誤會列出來源與原因。
    載入模組不建立視窗，且不提供舊 API 別名。
    @param CacheSource 跨服攜帶的 UI 原始碼；nil 表示沒有快取。
    @return 已驗證版本與 CreateWindow 的 Library。
    @return 實際載入的原始碼，供 PixelLineage 保存到下一次傳送快取。

    使用範例：
    ```lua
    local Library = _LoadBjzUi(nil)
    local Window = Library:CreateWindow({ Name = "控制中心", bResizable = true })
    Window:Destroy()
    ```
]]
local function _LoadBjzUi(CacheSource: string?)
    local Env = (type(getgenv) == "function" and getgenv()) or _G
    local ReadFile = type(Env.readfile) == "function" and Env.readfile or readfile
    local Compile = type(Env.loadstring) == "function" and Env.loadstring or loadstring
    local Errors = {}
    assert(type(Compile) == "function", "目前執行環境沒有 loadstring，無法載入 BjzUi。")

    --[[
        編譯並初始化一份來源，驗證成功後才將其交給呼叫端。
        @param Source UI 原始碼；空白或非字串會略過。
        @param Origin 顯示在編譯錯誤與版本錯誤中的來源名稱。
        @return 通過 3.x API 檢查的模組；nil 表示來源不可用。
        @return 通過檢查的原始碼；失敗時不提供。
    ]]
    local function _TrySource(Source, Origin: string)
        if type(Source) ~= "string" or not Source:find("%S") then
            return nil, nil
        end
        local Chunk, CompileError = Compile(Source, "@" .. Origin)
        if not Chunk then
            Errors[#Errors + 1] = Origin .. "：" .. tostring(CompileError)
            return nil, nil
        end
        local bLoaded, Library = pcall(Chunk)
        if not bLoaded then
            Errors[#Errors + 1] = Origin .. "：" .. tostring(Library)
            return nil, nil
        end
        if type(Library) ~= "table" or type(Library.CreateWindow) ~= "function"
            or type(Library.Version) ~= "string" or not Library.Version:match("^3%.") then
            local Version = type(Library) == "table" and tostring(Library.Version) or "未知"
            Errors[#Errors + 1] = Origin .. "：版本 " .. Version .. "，需要 BjzUi 3.x 的 b 前綴 API。"
            return nil, nil
        end
        return Library, Source
    end

    if type(ReadFile) == "function" then
        for _, Path in ipairs({ "BjzUiLibrary_2.0.luau", "BjzUi/BjzUiLibrary_2.0.luau" }) do
            local bRead, Source = pcall(ReadFile, Path)
            if bRead then
                local Library, AcceptedSource = _TrySource(Source, Path)
                if Library then return Library, AcceptedSource end
            end
        end
    end
    local CachedLibrary, AcceptedCache = _TrySource(CacheSource, "BjzUi 跨服快取")
    if CachedLibrary then return CachedLibrary, AcceptedCache end

    --[[
        本機與快取不可用時讀取原腳本指定的遠端來源；HTTP 失敗由外層 pcall 收集。
        @return GitHub 回傳的 UI 原始碼。
    ]]
    local bFetched, RemoteSource = pcall(function()
        return game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Library/BjzUiLibrary_2.0.luau")
    end)
    if bFetched then
        local Library, AcceptedSource = _TrySource(RemoteSource, "BjzUiLibrary_2.0.luau (GitHub)")
        if Library then return Library, AcceptedSource end
    else
        Errors[#Errors + 1] = "GitHub：" .. tostring(RemoteSource)
    end
    error("無法載入 BjzUi 3.x。請將最新版 BjzUiLibrary_2.0.luau 放入 Delta workspace/ 或 workspace/BjzUi/。\n"
        .. table.concat(Errors, "\n"), 0)
end

local lib = _LoadBjzUi(nil)

-- 重複執行時，先停止上一份腳本建立的工作與事件。
local previous = env.__CardGameBjzRuntime
if type(previous) == "table" and type(previous.Destroy) == "function" then
    previous:Destroy()
end
local runtime = {Alive = true, Connections = {}, Jobs = {}, CellGuis = {}}
env.__CardGameBjzRuntime = runtime
local window, autofarm, stopRangeOverrides
local controls = {}

local function connect(signal, callback)
    local connection = signal:Connect(function(...)
        if runtime.Alive then callback(...) end
    end)
    runtime.Connections[connection] = true
    return connection
end

local function disconnect(connection)
    if connection then
        connection:Disconnect()
        runtime.Connections[connection] = nil
    end
end

local function notify(title, content)
    if runtime.Alive and window and not window.bDestroyed then
        window:Notify({Title = title, Content = tostring(content), Duration = 5})
    else
        warn("[CardGame] " .. tostring(title) .. ": " .. tostring(content))
    end
end

local function action(callback)
    return function(...)
        if not runtime.Alive then return end
        local ok, err = pcall(callback, ...)
        if not ok then notify("操作失敗", err) end
    end
end

env.placeId = {
	["起始地"] = 969798545,
	["法師領地"] = 1461706253,
	["火法師領地"] = 6287373289,
	["雪地"] = 4525015679,
	["未知世界"] = 3452391468,
	["競技場"] = 1476253013,
	["魔法塔"] = 1301466176,
	["吸血鬼地"] = 5734999449,
	["沼澤地"] = 13548225266,
	["活動大廳"] = 6177512281,
	-- ["褻瀆懸崖"] = 10487168709,
}

env.pos = {
	current = CFrame.new(0, 0, 0),
	fireCardPack = CFrame.new(110, 125, 366),
	sellCardGuy = CFrame.new(
		358.464111,
		48.9593163,
		-619.483887,
		-0.0234648008,
		4.51503196e-10,
		0.999724686,
		2.00882582e-08,
		1,
		1.98692399e-11,
		-0.999724686,
		2.00831938e-08,
		-0.0234648008
	),
	zombieBossFront = CFrame.new(
		0.347828358,
		9.69091034,
		-27.4280586,
		-0.997035027,
		-1.22082975e-08,
		-0.0769490153,
		-7.70720376e-09,
		1,
		-5.87914641e-08,
		0.0769490153,
		-5.80240851e-08,
		-0.997035027
	),
	snowBossFront = CFrame.new(
		-238.042023,
		75.0571976,
		269.393616,
		-0.0173208397,
		-8.57200675e-08,
		0.999849975,
		-5.3933924e-08,
		1,
		8.47986072e-08,
		-0.999849975,
		-5.24570503e-08,
		-0.0173208397
	),
	fireMagicLibrary = CFrame.new(
		1026.46423,
		10.295579,
		776.565063,
		0.117833294,
		-9.90591147e-08,
		-0.993033409,
		-2.93516447e-08,
		1,
		-1.03236928e-07,
		0.993033409,
		4.13119103e-08,
		0.117833294
	),
	kirito = CFrame.new(
		-595.04303,
		285.073914,
		503.96637,
		1,
		0,
		0,
		0,
		0.998299956,
		0.0582857393,
		0,
		-0.0582857393,
		0.998299956
	),
}

env.heal = {
	zombie_raid = CFrame.new(
		0.312521458,
		10.4981375,
		-139.266251,
		0.88499558,
		-1.29474929e-08,
		0.465599418,
		1.1524806e-08,
		1,
		5.90226401e-09,
		-0.465599418,
		1.42465664e-10,
		0.88499558
	),
	magic_1 = CFrame.new(310, 80, 186),
	snow_1 = CFrame.new(
		-237.132385,
		127.252983,
		265.588287,
		0.869784296,
		3.38113204e-09,
		0.493432164,
		1.52292721e-08,
		1,
		-3.36972619e-08,
		-0.493432164,
		3.68239625e-08,
		0.869784296
	),
}

env.buyItem = {
	["起爆卡包"] = "CardPacks.Blazing Inferno",
}

env.settings = {
	autofarmZombieBossBuff = false,
	autofarmZombieBoss = false,
	autofarmWeakZombie = false,
}

local settings = env.settings

local function stopJob(key)
    settings[key] = false
    local job = runtime.Jobs[key]
    runtime.Jobs[key] = nil
    if job and job.Thread then pcall(task.cancel, job.Thread) end
end

local function cleanup()
    if not runtime.Alive then return end
    runtime.Alive = false
    if stopRangeOverrides then stopRangeOverrides() end
    for key in pairs(settings) do stopJob(key) end
    for connection in pairs(runtime.Connections) do connection:Disconnect() end
    runtime.Connections = {}
    for _, gui in pairs(runtime.CellGuis) do gui:Destroy() end
    runtime.CellGuis = {}
    if env.__CardGameBjzRuntime == runtime then env.__CardGameBjzRuntime = nil end
end

function runtime:Destroy()
    cleanup()
    if window and not window.bDestroyed then window:Destroy() end
end

window = lib:CreateWindow({
    Name = "卡牌",
    LoadingSubtitle = "HexCardGame · BjzUi 3.x",
    ConfigId = "CardGame_" .. tostring(localPlayer.UserId),
    ConfigurationSaving = {bEnabled = true},
    ToggleKey = Enum.KeyCode.RightShift,
    Width = 1000, Height = 700,
    MinWidth = 360, MinHeight = 300,
    bResizable = true,
})
runtime.Window = window

-- 包裝此視窗的公開 Destroy，讓關閉按鈕與重新載入都能停止工作。
local destroyWindow = window.Destroy
function window:Destroy()
    cleanup()
    return destroyWindow(self)
end
connect(window.ScreenGui.Destroying, cleanup)

local function applyMovement(humanoid)
    if not runtime.Alive or not humanoid then return end
    if controls.WalkSpeed then humanoid.WalkSpeed = controls.WalkSpeed:Get() end
    if controls.JumpPower then humanoid.JumpPower = controls.JumpPower:Get() end
end

local characterConnection
local function bindCharacter(character)
    disconnect(characterConnection)
    env.character = character
    env.humanoid = character and character:FindFirstChildOfClass("Humanoid") or nil
    applyMovement(env.humanoid)
    if character then
        characterConnection = connect(character.ChildAdded, function(child)
            if child:IsA("Humanoid") then
                env.humanoid = child
                applyMovement(child)
            end
        end)
    end
end
connect(localPlayer.CharacterAdded, bindCharacter)
bindCharacter(localPlayer.Character)

local function rootPart()
    local character = localPlayer.Character
    local root = character and (character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart)
    assert(root, "角色尚未準備好，請稍後再試。")
    return root
end

local function tp(position)
    rootPart().CFrame = position
end

local function getRootPartPos()
    return rootPart().CFrame
end

local function copyCurrentPlaceId()
    local copy = env.setclipboard or setclipboard or env.toclipboard or toclipboard
    assert(type(copy) == "function", "目前執行環境沒有剪貼簿功能。")
    local placeId = tostring(game.PlaceId)
    copy(placeId)
    notify("已複製", "當前 Place ID：" .. placeId)
end

local function socket(name, timeout)
    local container = localPlayer:FindFirstChild("Socket")
    if not container and timeout then container = localPlayer:WaitForChild("Socket", timeout) end
    local remote = container and container:FindFirstChild(name)
    if not remote and container and timeout then remote = container:WaitForChild(name, timeout) end
    assert(remote, "目前找不到遊戲 Socket." .. name .. "，請稍後再試。")
    return remote
end

-- 僅改寫目前玩家的客戶端選取距離；不偽造 CombatActionSubmitted 的回覆。
local rangeOverrides = {
    Card = false, Move = false, Busy = false, Patches = {},
    Params = setmetatable({}, {__mode = "k"}),
    Scopes = setmetatable({}, {__mode = "k"}),
}
runtime.RangeOverrides = rangeOverrides

local function rangeModules()
    if rangeOverrides.Modules then return rangeOverrides.Modules end
    local shared = ReplicatedStorage:FindFirstChild("SharedScripts")
    local combatFolder = shared and shared:FindFirstChild("Combat")
    local targetingModule = combatFolder and combatFolder:FindFirstChild("CombatTargeting")
    local scripts = localPlayer:FindFirstChild("PlayerScripts") or localPlayer:WaitForChild("PlayerScripts", 5)
    local services = scripts and scripts:FindFirstChild("Services")
    local mapModule = services and services:FindFirstChild("MapService")
    local combatModule = services and services:FindFirstChild("CombatService")
    assert(targetingModule and mapModule and combatModule, "戰鬥模組尚未準備好，請稍後再開啟。")
    local modules = {
        Targeting = require(targetingModule),
        MapService = require(mapModule),
        CombatService = require(combatModule),
    }
    for _, name in ipairs({"CreateCardParams", "CreateMoveParams", "CanTargetCell", "GetTargetCells", "GetMinRangeCells"}) do
        assert(type(modules.Targeting) == "table" and type(modules.Targeting[name]) == "function",
            "遊戲的 CombatTargeting." .. name .. " 已變更，無法套用距離開關。")
    end
    assert(type(modules.MapService) == "table" and type(modules.MapService.MaxRange) == "function",
        "遊戲的 MapService.MaxRange 已變更，無法套用距離開關。")
    assert(type(modules.CombatService) == "table", "無法取得目前戰鬥。")
    assert(runtime.Alive, "腳本已關閉。")
    rangeOverrides.Modules = modules
    return modules
end

local function refreshRangeTargeting()
    local modules = rangeOverrides.Modules
    if not modules then return end
    for _, combat in pairs(modules.CombatService.combats or {}) do
        local selection = combat.actionSelect
        if selection and not selection.destroyed and selection.combatant and selection.combatant.player == localPlayer then
            local ok, err = pcall(function() combat:RefreshTargeting() end)
            if not ok and runtime.Alive then warn("[CardGame] 範圍顯示更新失敗：" .. tostring(err)) end
        end
    end
end

local function restoreRangeMethods()
    for index = #rangeOverrides.Patches, 1, -1 do
        local patch = rangeOverrides.Patches[index]
        -- 若其他腳本後來接手此方法，保留它的修改；舊回呼會依開關回到原行為。
        if patch.Table[patch.Name] == patch.Wrapper then patch.Table[patch.Name] = patch.RawOriginal end
        rangeOverrides.Patches[index] = nil
    end
end

stopRangeOverrides = function()
    rangeOverrides.Card, rangeOverrides.Move = false, false
    restoreRangeMethods()
    refreshRangeTargeting()
end

local function rangeKind(targeting, origin, params)
    if not runtime.Alive or type(params) ~= "table" then return nil end
    local info = rangeOverrides.Params[params]
    local kind = info and info.Kind
    if not kind and type(params.ActionType) == "string" then
        kind = params.ActionType == "Move" and "Move" or (params.ActionType:match("^Card%.") and "Card")
    end
    if not kind or not rangeOverrides[kind] then return nil end
    local owner = info and info.Owner
    if not owner or owner.qr ~= origin then
        local combat = targeting.combat
        owner = combat and combat:GetCombatantAtCell(origin)
    end
    return owner and owner.player == localPlayer and kind or nil
end

local function withoutMapRange(callback, ...)
    local thread = coroutine.running()
    local previousDepth = rangeOverrides.Scopes[thread]
    rangeOverrides.Scopes[thread] = (previousDepth or 0) + 1
    local result = table.pack(pcall(callback, ...))
    rangeOverrides.Scopes[thread] = previousDepth
    if not result[1] then error(result[2], 0) end
    return table.unpack(result, 2, result.n)
end

local function unlimitedParams(params, kind)
    local copy = table.clone(params)
    copy.Range, copy.MinRange = nil, nil
    rangeOverrides.Params[copy] = rangeOverrides.Params[params]
    -- 原生的 nil Range 會遍歷現有格子；math.huge 會讓六角環迴圈無法結束。
    if kind == "Card" and type(params.CustomTargeting) == "function" then
        local custom = params.CustomTargeting
        copy.CustomTargeting = function(origin, combat, output)
            local map = combat.map
            local function allCells(_, center, radius, callback)
                if center ~= origin then return map:IterateAxialRange(center, radius, callback) end
                local running = true
                map:ForEachCell(function(cell)
                    if not running then return end
                    local qr = map:CellToAxial(cell)
                    if qr and callback(qr) == false then running = false end
                end)
                if not running then return false end
            end
            -- 保留特殊卡牌自己的敵我、占格與形狀篩選，只擴展從施法者出發的距離。
            local proxyMap = setmetatable({
                IterateAxialRange = allCells,
                IterateAxialRing = function(self, center, radius, callback)
                    if center == origin then return allCells(self, center, radius, callback) end
                    return map:IterateAxialRing(center, radius, callback)
                end,
                GetMagnitude = function(_, from, to)
                    if from == origin then return 0 end
                    return map:GetMagnitude(from, to)
                end,
            }, {__index = map})
            return custom(origin, setmetatable({map = proxyMap}, {__index = combat}), output)
        end
    end
    return copy
end

local function installRangeMethods()
    if #rangeOverrides.Patches > 0 then return end
    local modules = rangeModules()
    local function patch(target, name, factory)
        local original = target[name]
        local rawOriginal = rawget(target, name)
        local wrapper = factory(original)
        target[name] = wrapper
        rangeOverrides.Patches[#rangeOverrides.Patches + 1] = {
            Table = target, Name = name, RawOriginal = rawOriginal, Wrapper = wrapper,
        }
    end
    local ok, err = pcall(function()
        patch(modules.MapService, "MaxRange", function(original)
            return function(self, ...)
                if runtime.Alive and rangeOverrides.Scopes[coroutine.running()] then return false end
                return original(self, ...)
            end
        end)
        for _, entry in ipairs({{"CreateCardParams", "Card"}, {"CreateMoveParams", "Move"}}) do
            local method, kind = entry[1], entry[2]
            patch(modules.Targeting, method, function(original)
                return function(self, owner, ...)
                    local params = original(self, owner, ...)
                    if type(params) == "table" then rangeOverrides.Params[params] = {Kind = kind, Owner = owner} end
                    return params
                end
            end)
        end
        patch(modules.Targeting, "CanTargetCell", function(original)
            return function(self, origin, target, params, ...)
                local kind = rangeKind(self, origin, params)
                if not kind then return original(self, origin, target, params, ...) end
                return withoutMapRange(original, self, origin, target, unlimitedParams(params, kind), ...)
            end
        end)
        patch(modules.Targeting, "GetTargetCells", function(original)
            return function(self, origin, params, ...)
                local kind = rangeKind(self, origin, params)
                if not kind then return original(self, origin, params, ...) end
                return withoutMapRange(original, self, origin, unlimitedParams(params, kind), ...)
            end
        end)
        patch(modules.Targeting, "GetMinRangeCells", function(original)
            return function(self, origin, params, ...)
                if rangeKind(self, origin, params) then return {} end
                return original(self, origin, params, ...)
            end
        end)
    end)
    if not ok then restoreRangeMethods(); error(err, 0) end
end

local function setRangeFeature(kind, enabled)
    if rangeOverrides.Busy then
        controls["Range" .. kind]:Set(rangeOverrides[kind], true)
        notify("正在設定範圍", "請等待目前的設定完成。")
        return
    end
    rangeOverrides.Busy = true
    local previousValue = rangeOverrides[kind]
    local ok, err = pcall(function()
        if enabled then installRangeMethods() end
        if not runtime.Alive then return end
        rangeOverrides[kind] = enabled
        if not rangeOverrides.Card and not rangeOverrides.Move then restoreRangeMethods() end
        refreshRangeTargeting()
    end)
    rangeOverrides.Busy = false
    if not runtime.Alive then return end
    if not ok then
        rangeOverrides[kind] = previousValue
        controls["Range" .. kind]:Set(previousValue, true)
        notify("範圍設定失敗", err)
        return
    end
    local name = kind == "Card" and "卡片" or "戰鬥移動"
    notify(name .. "距離", enabled and "已解除客戶端距離限制；行動仍由伺服器確認。" or "已恢復原本距離。")
end

-- 副本選項只保存純量 ID，對應的 Instance 留在腳本內。
local raidIds = setmetatable({}, {__mode = "k"})
local raidById, nextRaidId = {}, 0
local raidFolder, raidAddedConnection, raidRemovedConnection
local raidDropdown, raidButton, raidInfo
local function refreshRaids()
    local folder = Workspace:FindFirstChild("RaidPortals")
    if folder ~= raidFolder then
        disconnect(raidAddedConnection)
        disconnect(raidRemovedConnection)
        raidFolder = folder
        if folder then
            raidAddedConnection = connect(folder.ChildAdded, function() refreshRaids() end)
            raidRemovedConnection = connect(folder.ChildRemoved, function() refreshRaids() end)
        end
    end
    local raids = folder and folder:GetChildren() or {}
    env.currentRaid = raids
    local options = {}
    raidById = {}
    table.sort(raids, function(a, b) return a.Name < b.Name end)
    for _, raid in ipairs(raids) do
        if not raidIds[raid] then
            nextRaidId = nextRaidId + 1
            raidIds[raid] = "raid_" .. nextRaidId
        end
        local id = raidIds[raid]
        raidById[id] = raid
        options[#options + 1] = {Name = raid.Name, Value = id}
    end
    if raidDropdown then
        raidDropdown:Refresh(options, true, true)
        raidDropdown:SetEnabled(#options > 0)
        raidButton:SetEnabled(#options > 0)
        raidInfo:Set(#options > 0 and ("可用副本：" .. #options) or "目前世界沒有可用副本。")
    end
end

local generalTab = window:CreateTab("一般", "home")
local worldSection = generalTab:CreateSection({Name = "傳送世界", Side = "left"})
local worldOptions = {}
for name, placeId in pairs(env.placeId) do
    worldOptions[#worldOptions + 1] = {Name = name, Value = placeId}
end
table.sort(worldOptions, function(a, b) return a.Name < b.Name end)
local worldDropdown = worldSection:CreateDropdown({
    Name = "目的地", Options = worldOptions, bSearchable = true,
    Flag = "cg_world", bSave = false,
})
worldSection:CreateButton({Name = "傳送至選擇的世界", Callback = action(function()
    local placeId = worldDropdown:Get()
    assert(type(placeId) == "number", "請先選擇世界。")
    TeleportService:Teleport(placeId, localPlayer)
end)})

local characterSection = generalTab:CreateSection({Name = "角色", Side = "right"})
controls.WalkSpeed = characterSection:CreateSlider({
    Name = "跑速", Range = {16, 100}, Increment = 1,
    CurrentValue = env.humanoid and env.humanoid.WalkSpeed or 16,
    Flag = "cg_walk_speed", Callback = function(value)
        if env.humanoid then env.humanoid.WalkSpeed = value end
    end,
})
controls.JumpPower = characterSection:CreateSlider({
    Name = "跳躍力量", Description = "對應原腳本的 Humanoid.JumpPower。",
    Range = {50, 300}, Increment = 1,
    CurrentValue = env.humanoid and env.humanoid.JumpPower or 50,
    Flag = "cg_jump_power", Callback = function(value)
        if env.humanoid then env.humanoid.JumpPower = value end
    end,
})
-- 新版控制項還原設定時不會自動呼叫 Callback，明確套用一次即可。
applyMovement(env.humanoid)

local rangeSection = generalTab:CreateSection({Name = "戰鬥範圍", Side = "right"})
rangeSection:CreateParagraph({
    Title = "客戶端範圍開關",
    Content = "解除本機的卡片／移動距離檢查，涵蓋目前戰場。超距離行動是否成立，以伺服器回覆為準。",
})
for _, entry in ipairs({{"Card", "卡片無限距離"}, {"Move", "戰鬥移動無限距離"}}) do
    local kind, name = entry[1], entry[2]
    controls["Range" .. kind] = rangeSection:CreateToggle({
        Name = name, bCurrentValue = false, Flag = "cg_range_" .. kind:lower(), bSave = false,
        Callback = function(enabled) setRangeFeature(kind, enabled) end,
    })
end

local infoSection = generalTab:CreateSection({Name = "獲取", Side = "left"})
infoSection:CreateInput({Name = "現在 Place 的 Id", CurrentValue = tostring(game.PlaceId), bEnabled = false, bSave = false})
infoSection:CreateButton({Name = "複製當前Place ID", Style = "outline", Callback = action(copyCurrentPlaceId)})
infoSection:CreateButton({Name = "獲取現在角色位置", Style = "outline", Callback = action(function()
    assert(type(writefile) == "function", "目前執行環境沒有 writefile。")
    writefile("CurrentCFrame.txt", tostring(getRootPartPos()))
    notify("已儲存", "角色位置已寫入 workspace/CurrentCFrame.txt。")
end)})

local raidTab = window:CreateTab("副本", "grid")
local raidSection = raidTab:CreateSection({Name = "所在世界可進入的副本", Side = "full"})
raidInfo = raidSection:CreateLabel({Name = "正在讀取副本…"})
raidDropdown = raidSection:CreateDropdown({Name = "副本", Options = {}, Flag = "cg_raid", bSave = false})
raidButton = raidSection:CreateButton({Name = "進入選擇的副本", bEnabled = false, Callback = action(function()
    local raid = raidById[raidDropdown:Get()]
    if not raid or raid.Parent ~= Workspace:FindFirstChild("RaidPortals") then
        refreshRaids()
        notify("副本已變更", "請重新選擇目前可用的副本。")
        return
    end
    socket("Event"):FireServer("JoinRaid", raid)
end)})
raidSection:CreateButton({Name = "重新整理副本", Style = "outline", Callback = action(refreshRaids)})
connect(Workspace.ChildAdded, function(child) if child.Name == "RaidPortals" then refreshRaids() end end)
connect(Workspace.ChildRemoved, function(child) if child == raidFolder then refreshRaids() end end)
refreshRaids()

local tpTab = window:CreateTab("傳送", "crosshair")
local function teleportSection(name, side, destinations)
    local section = tpTab:CreateSection({Name = name, Side = side})
    for _, destination in ipairs(destinations) do
        local title, position = destination[1], destination[2]
        section:CreateButton({Name = title, Style = "outline", Callback = action(function() tp(position) end)})
    end
end
teleportSection("起始地", "left", {{"賣卡商人", env.pos.sellCardGuy}, {"換桐人劍", env.pos.kirito}})
teleportSection("殭屍副本", "right", {{"殭屍王補血", env.heal.zombie_raid}, {"殭屍王前", env.pos.zombieBossFront}})
teleportSection("雪地", "left", {{"雪地補血 1", env.heal.snow_1}})
teleportSection("雪王副本", "right", {{"雪王前", env.pos.snowBossFront}})
teleportSection("火法師副本", "left", {{"圖書館補血", env.pos.fireMagicLibrary}})

local buyTab = window:CreateTab("購買物品", "file")
local buySection = buyTab:CreateSection({Name = "卡包", Side = "full"})
local packStatus = buySection:CreateLabel({Name = "每次購買 1 包；購買成功後請到背包查看。"})
local packButtons, packPurchasePending = {}, false

local function packProduct(pack)
    -- 優先使用遊戲當前商品表；模組不可讀時使用此 Place 檔中的售價。
    local resources = ReplicatedStorage:FindFirstChild("Resources")
    local module = resources and resources:FindFirstChild("Purchases")
    if module and module:IsA("ModuleScript") then
        local ok, purchases = pcall(require, module)
        local product = ok and type(purchases) == "table" and type(purchases.CardPacks) == "table"
            and purchases.CardPacks[pack.SetName]
        if type(product) == "table" and type(product.Cost) == "number" and type(product.Currency) == "string" then
            return product
        end
    end
    return {Cost = pack.Cost, Currency = "Gold"}
end

local function purchaseCardPack(pack)
    if packPurchasePending then
        notify("購買處理中", "請等待目前這筆購買完成。")
        return
    end
    packPurchasePending = true
    for _, button in ipairs(packButtons) do button:SetEnabled(false) end
    packStatus:Set("正在購買「" .. pack.Name .. "」…")

    -- 與遊戲商店相同，先檢查資格與餘額，再送出一次 TryPurchase。
    -- 不自動重送購買請求，避免延遲或錯誤後重複扣款。
    local ok, message = pcall(function()
        local remote = socket("Function", 5)
        if not runtime.Alive then return end
        assert(remote:IsA("RemoteFunction"), "遊戲的購買連線尚未準備好。")
        local restricted = remote:InvokeServer("PlayerCantBuyPacks")
        if not runtime.Alive then return end
        assert(not restricted, "遊戲目前不允許此帳號購買卡包；可透過戰鬥掉落取得。")

        local product = packProduct(pack)
        if not runtime.Alive then return end
        local data = remote:InvokeServer("FetchCharacterData")
        if not runtime.Alive then return end
        local balance = type(data) == "table" and tonumber(data[product.Currency])
        assert(balance, "尚未取得角色的貨幣資料，請稍後再試。")
        assert(balance >= product.Cost, string.format("%s 不足：需要 %s，目前只有 %s。",
            product.Currency, tostring(product.Cost), tostring(balance)))

        local purchased, reason = remote:InvokeServer("TryPurchase", pack.ItemId)
        if not runtime.Alive then return end
        if not purchased then
            local detail = type(reason) == "string" and reason ~= "" and reason
                or "伺服器未接受購買；請確認遊戲原生商店是否能購買此卡包。"
            error(detail, 0)
        end
        return string.format("已購買「%s」1 包，花費 %s %s；請到背包查看。",
            pack.Name, tostring(product.Cost), product.Currency)
    end)

    packPurchasePending = false
    if not runtime.Alive or window.bDestroyed then return end
    for _, button in ipairs(packButtons) do button:SetEnabled(true) end
    packStatus:Set(ok and message or ("購買失敗：" .. tostring(message)))
    notify(ok and "購買成功" or "購買失敗", message)
end

for _, pack in ipairs({
    {Name = "Core卡包", SetName = "Genesis", ItemId = "CardPacks.Genesis", Cost = 150},
    {Name = "海螺卡包", SetName = "Mystic Wisdom", ItemId = "CardPacks.Mystic Wisdom", Cost = 250},
    {Name = "起爆卡包", SetName = "Blazing Inferno", ItemId = "CardPacks.Blazing Inferno", Cost = 350},
}) do
    packButtons[#packButtons + 1] = buySection:CreateButton({Name = pack.Name, Style = "outline", Callback = action(function()
        purchaseCardPack(pack)
    end)})
end

-- 原有自動刷怪流程；各工作使用獨立 round，避免共用 getgenv().round。
local function autofarmZombieBossBuff()
	local round = 1

	local running = false

	while runtime.Alive and settings.autofarmZombieBossBuff do
		if round == 1 and not running then
			running = not running
			autofarm:waitForBattleStart()
			autofarm:waitForMyTurn()
			task.wait(2.5)

			local spawn_q = autofarm:getPosition(localPlayer.Name)["q"]
			local spawn_r = autofarm:getPosition(localPlayer.Name)["r"]

			if spawn_q == -3 and spawn_r == 3 then
				repeat
					local q = autofarm:getPosition(localPlayer.Name)["q"]
					local r = autofarm:getPosition(localPlayer.Name)["r"]
					autofarm:move(-2, 4)
					task.wait(0.25)
				until q == -2 and r == 4
			elseif spawn_q == -1 and spawn_r == 3 then
				repeat
					local q = autofarm:getPosition(localPlayer.Name)["q"]
					local r = autofarm:getPosition(localPlayer.Name)["r"]
					autofarm:move(0, 4)
					task.wait(0.25)
				until q == 0 and r == 4
			elseif spawn_q == 1 and spawn_r == 2 then
				repeat
					local q = autofarm:getPosition(localPlayer.Name)["q"]
					local r = autofarm:getPosition(localPlayer.Name)["r"]
					autofarm:move(1, 3)
					task.wait(0.25)
				until q == 1 and r == 3
			elseif spawn_q == 3 and spawn_r == 0 then
				repeat
					local q = autofarm:getPosition(localPlayer.Name)["q"]
					local r = autofarm:getPosition(localPlayer.Name)["r"]
					autofarm:move(2, 2)
					task.wait(0.25)
				until q == 2 and r == 2
			end

			task.wait(2.5)
			autofarm:useCard("Guided Strike", "hxfgfg")
			autofarm:useCard("Strength Duality", "hxfgfg")
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 2
			running = not running
		elseif round == 2 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:useCard("Guided Strike", "hxfgfg")
			autofarm:useCard("Strength Duality", "hxfgfg")
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 3
			running = not running
		elseif round == 3 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:useCard("Defense Debuff", "Gonaku")
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 4
			running = not running
		elseif round == 4 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:useCard("Defense Debuff", "Gonaku")
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 5
			running = not running
		elseif round == 5 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 6
			running = not running
		elseif round == 6 then
			running = not running

			autofarm:waitForMyTurn()
			autofarm:pass()
			autofarm:waitForTurnEnd()
			autofarm:waitForBattleEnd()

			repeat
				tp(getgenv().heal.zombie_raid)
				task.wait(0.3)
			until game:GetService("Workspace").Shrines.Heal.Ball.Center.Color == Color3.fromRGB(80, 80, 80)

			tp(CFrame.new(-10.3923044, 9.8258276, -6, -0.866025388, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025388))

			round = 1
			running = not running
		end
		task.wait(1)
	end
end

local function autofarmZombieBoss()
	local round = 1

	local running = false

	while runtime.Alive and settings.autofarmZombieBoss do
		if round == 1 and not running then
			running = not running
			autofarm:waitForBattleStart()
			autofarm:waitForMyTurn()

			repeat
				local q = autofarm:getPosition(localPlayer.Name)["q"]
				local r = autofarm:getPosition(localPlayer.Name)["r"]
				autofarm:dash(0, 0)
				task.wait(0.25)
			until q == 0 and r == 0

			repeat
				local q = autofarm:getPosition(localPlayer.Name)["q"]
				local r = autofarm:getPosition(localPlayer.Name)["r"]
				autofarm:move(0, -2)
				task.wait(0.25)
			until q == 0 and r == -2

			autofarm:useCard("Defense Debuff", "Gonaku")
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 2
			running = not running
		elseif round == 2 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:useCard("Shadow Trade", localPlayer.Name)
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 3
			running = not running
		elseif round == 3 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 4
			running = not running
		elseif round == 4 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 5
			running = not running
		elseif round == 5 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:useCard("Tremor", localPlayer.Name)
			autofarm:pass()
			autofarm:waitForTurnEnd()
			round = 6
			running = not running
		elseif round == 6 then
			running = not running
			autofarm:waitForMyTurn()
			autofarm:useCard("Scimitar", "Gonaku")
			autofarm:pass()
			autofarm:waitForTurnEnd()
			autofarm:waitForBattleEnd()
			task.wait(2.5)

			repeat
				tp(getgenv().heal.zombie_raid)

				for i = 1, 10 do
					local v1 = "TryShrineActivation"
					local v2 = 1
					local event = game:GetService("Players").LocalPlayer.Socket.Event
					event:FireServer(v1, v2)
					task.wait(0.3)
				end
			until game:GetService("Workspace").Shrines.Heal.Ball.Center.Color == Color3.fromRGB(80, 80, 80)

			tp(CFrame.new(-10.3923044, 9.8258276, -6, -0.866025388, 0, 0.5, 0, 1, 0, -0.5, 0, -0.866025388))

			round = 1
			running = not running
		end
		task.wait(1)
	end
end

local function autofarmWeakZombie()
	tp(CFrame.new(-10.3923044, 6.8516221, -198, 0, 0, -1, 0, 1, 0, 1, 0, 0))

	local round = 1

	local running = false

	while runtime.Alive and settings.autofarmWeakZombie do
		if round == 1 and not running then
			running = not running
			print(round)
			autofarm:waitForMyTurn()
			autofarm:useCard("Guided Strike", localPlayer.Name)
			autofarm:weakZombieDash()
			autofarm:weakZombieMove()
			autofarm:pass()
			round = 2
			running = not running
		elseif round == 2 and not running then
			running = not running
			print(round)
			autofarm:waitForMyTurn()
			autofarm:useCard("Shadow Trade", localPlayer.Name)
			autofarm:pass()
			round = 3
			running = not running
		elseif round == 3 and not running then
			running = not running
			print(round)
			autofarm:waitForMyTurn()
			autofarm:useCard("Tremor", localPlayer.Name)
			autofarm:pass()

			task.wait(5)

			repeat
				tp(getgenv().heal.zombie_raid)
				task.wait(1)
				for i = 1, 5 do
					local v1 = "TryShrineActivation"
					local v2 = 1
					local event = game:GetService("Players").LocalPlayer.Socket.Event
					event:FireServer(v1, v2)
					task.wait(0.7)
				end
			until game:GetService("Workspace").Shrines.Heal.Ball.Center.Color == Color3.fromRGB(80, 80, 80)

			task.wait(1)

			tp(CFrame.new(-10.3923044, 6.8516221, -198, 0, 0, -1, 0, 1, 0, 1, 0, 0))

			round = 1
			running = not running
		end
		task.wait(1)
	end
end

local autoTab = window:CreateTab("自動刷怪", "zap")
local buffSection = autoTab:CreateSection({Name = "Buff", Side = "left"})
local attackSection = autoTab:CreateSection({Name = "攻擊", Side = "right"})
local weakSection = autoTab:CreateSection({Name = "小殭屍", Side = "left"})
weakSection:CreateParagraph({Title = "卡牌配置", Content = "地震 x1、強攻擊 Buff x1、Dash x1、Shadow Trade x1"})

local function farmToggle(section, name, key, worker)
    local control
    control = section:CreateToggle({
        Name = name, bCurrentValue = false, Flag = "cg_" .. key, bSave = false,
        Callback = function(enabled)
            stopJob(key)
            if not enabled or not runtime.Alive then return end
            settings[key] = true
            local job = {}
            runtime.Jobs[key] = job
            -- 自行追蹤工作，不把無限迴圈留在 UI callback 裡。
            job.Thread = task.defer(function()
                local ok, err = pcall(function()
                    if not runtime.Alive or not settings[key] then return end
                    if not autofarm then
                        autofarm = loadModule("HexCardGameAutoFarmLib.luau", AUTOFARM_LIBRARY_URL)
                    end
                    if runtime.Alive and settings[key] then worker() end
                end)
                if runtime.Jobs[key] ~= job then return end
                runtime.Jobs[key] = nil
                settings[key] = false
                if not control.bDestroyed then control:Set(false, true) end
                if not ok and runtime.Alive then notify("自動刷怪已停止", err) end
            end)
        end,
    })
    return control
end
farmToggle(buffSection, "自動刷殭屍王（Buff）", "autofarmZombieBossBuff", autofarmZombieBossBuff)
farmToggle(attackSection, "自動刷殭屍王（攻擊）", "autofarmZombieBoss", autofarmZombieBoss)
farmToggle(weakSection, "自動刷小殭屍", "autofarmWeakZombie", autofarmWeakZombie)

local uiTab = window:CreateTab("介面設定", "settings")
local appearance = uiTab:CreateSection({Name = "外觀", Side = "left"})
local accentControl = appearance:CreateColorPicker({
    Name = "主題顏色", Color = window.Theme.Accent, bSave = false,
    Callback = function(color) window:SetAccent(color) end,
})
local scaleControl = appearance:CreateSlider({
    Name = "介面縮放", Range = {65, 150}, Increment = 5, Suffix = "%",
    CurrentValue = window.Scale * 100, bSave = false,
    Callback = function(value) window:SetScale(value / 100) end,
})
local animationControl = appearance:CreateToggle({
    Name = "介面動畫", bCurrentValue = window.bAnimations, bSave = false,
    Callback = function(value) window:SetAnimations(value) end,
})
local configSection = uiTab:CreateSection({Name = "設定檔", Side = "right"})
configSection:CreateParagraph({Title = "自動儲存", Content = "介面與角色設定會自動儲存；刷怪功能每次執行均由關閉狀態開始。"})
configSection:CreateButton({Name = "儲存設定", Callback = action(function()
    local ok, reason = window:SaveConfiguration()
    notify(ok and "已儲存設定" or "儲存失敗", ok and "workspace/BjzUi/UiConfig.json" or reason)
end)})
configSection:CreateButton({Name = "讀取設定", Style = "outline", Callback = action(function()
    local ok, reason = window:LoadConfiguration(true)
    if ok then
        applyMovement(env.humanoid)
        accentControl:Set(window.Theme.Accent, true)
        scaleControl:Set(window.Scale * 100, true)
        animationControl:Set(window.bAnimations, true)
    end
    notify(ok and "已讀取設定" or "讀取失敗", ok and "已套用介面與角色設定。" or reason)
end)})

-- 保留格子座標顯示；沒有戰鬥地圖時直接略過，不阻擋整個 GUI。
local function showCellPosition()
    local bin = Workspace:FindFirstChild("HexMapBin")
    local map = bin and bin:FindFirstChild("MainMap")
    local cells = map and map:FindFirstChild("Cells")
    if not cells then return end
    local nameConnections = {}
    local function addCell(cell)
        if runtime.CellGuis[cell] or not cell:IsA("BasePart") or cell:FindFirstChildOfClass("SurfaceGui") then return end
        local gui = Instance.new("SurfaceGui")
        gui.Name, gui.Face = "CardGameCellPosition", Enum.NormalId.Top
        local text = Instance.new("TextLabel")
        text.BackgroundTransparency = 1
        text.AnchorPoint = Vector2.new(0.5, 0.5)
        text.Position = UDim2.fromScale(0.5, 0.5)
        text.Size = UDim2.fromScale(2, 2)
        text.Font = Enum.Font.RobotoMono
        text.TextColor3 = Color3.fromRGB(255, 0, 255)
        text.TextScaled = true
        text.Text = cell.Name:gsub("[^()%-%d,]", "")
        text.Parent, gui.Parent = gui, cell
        runtime.CellGuis[cell] = gui
        nameConnections[cell] = connect(cell:GetPropertyChangedSignal("Name"), function()
            text.Text = cell.Name:gsub("[^()%-%d,]", "")
        end)
    end
    local function removeCell(cell)
        disconnect(nameConnections[cell])
        nameConnections[cell] = nil
        local gui = runtime.CellGuis[cell]
        if gui then gui:Destroy(); runtime.CellGuis[cell] = nil end
    end
    for _, cell in ipairs(cells:GetChildren()) do addCell(cell) end
    connect(cells.ChildAdded, addCell)
    connect(cells.ChildRemoved, removeCell)
end
showCellPosition()

-- 可供其他腳本取得視窗；再次執行仍會清理上一個實例。
return window

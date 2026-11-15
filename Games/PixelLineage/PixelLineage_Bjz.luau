--[[
Pixel Lineage AutoFarm v2.13 · BjzUi 自動出售裝備版

UI Library 需要新版 BjzUiLibrary_2.0.luau（內部版本 3.x、b 前綴 API），可放 workspace/ 或 workspace/BjzUi/。
保留你提供的 GitHub .luau 載入網址。

續跑改為啟動時預先排程；使用短啟動碼，不再把完整腳本塞進 queue_on_teleport。
來源與狀態優先快取到 workspace/BjzUi/PixelLineage/；檔案 API 不可用時，
改用同一遊戲內保留的 TeleportService 設定。切換伺服器後等待玩家與遊戲物件就緒。
續跑需執行器實際提供且接受 queue_on_teleport 或相容 API；不再僅以函式存在判定成功。
SOLO 分頁會顯示排程結果；傳送失敗後重排，同一目的地重複啟動會去重。
按「停止並關閉」會取消續跑；傳送時 UI 被銷毀只清理舊客戶端工作。

介面設定：workspace/BjzUi/UiConfig.json。
SOLO 設定：workspace/PixelLineage_AutoFarm_<GameId>_<UserId>.json（沿用原檔）。
診斷：workspace/BjzUi/PixelLineage/ResumeStatus_<GameId>_<UserId>.json。
戰鬥開啟「允許使用 SCROLL」且卷軸可用時，先使用卷軸，再回到原本的行動策略。
開啟「通關後自動接續」時，一般模式 PLAY AGAIN；TORMENT 可選下一級或重新開始目前等級。
下一級依遊戲 RunState.tormentNext 與 NextTier 按鈕決定；不猜測未解鎖等級。
選擇「進入下一級」時，已達上限或下一級尚未提供會保持等待。
選擇「重新開始目前等級」時，使用 PLAY AGAIN；已送出的請求維持原選擇，變更套用於下一次通關。
TORMENT 接續方式與目標等級同步保存至 SOLO 設定與跨服續跑狀態。
「多人模式」提供三個預設開啟的開關：鑰匙提案自動同意、冒險開始自動準備、CASTLE 房間自動 READY。
沿用原遊戲確認流程，已準備時不重送、不取消；房主的 START RUN 仍由房主決定。
多人選項保存到原玩家設定檔並跨服沿用；總開關關閉時一起停止。
QTE 改成直接提交：攻擊回報滿命中數／刀刃中心位置，不再對準 UI 或觸發 pressHandler。
防禦與 RAID GATE 連段逐擊提交事件提供的中心時間戳；使用 task.delay 加 Heartbeat 備援。
接管已辨識的原生 QTE 起始方法，略過對準面板並避免重複提交；停用後新 QTE 走原生流程。
保留火球卷軸的逐擊預覽與攻擊最短等待；不安裝全域 remote、時鐘或判定函式 hook。
防禦仍受伺服器 PressTime 延遲補償與截止時間限制；過晚／斷線無法保證 100%。
QTE 判定欄區分已提交與伺服器 DefenseTimingResolved 的實際回報，不偽裝成功。
本地遊戲快照沒有完整伺服器接收程式；攻擊協定接受情況仍需實機確認。
新增「裝備管理」：自動出售預設關閉，門檻包含所選品質及以下；預設 Common。
只處理 gearBag 裝備，排除鎖定、穿戴、外觀欄使用中、初始與活動限定等不可出售裝備。
品質順序取自 GearConfig；使用原生 GearSellMany 出售，不刪除、不解鎖、不卸裝。
角色就緒且不在戰鬥／傳送時處理，每批最多 25 件；取得新 Profile 後才繼續，單件至多兩次。
開關與門檻保存至原玩家設定檔並跨服沿用；背包與待確認請求不跨服保存。
既有 TORMENT、SCROLL、多人準備與跨服設定保留。已做模擬測試，尚未在 Delta / 遊戲實機驗證。
]]
if not game:IsLoaded() then game.Loaded:Wait() end
local coreSource = [====[
-- Pixel Lineage / Delta Executor v2.13 + BjzUiLibrary_2.0 continuation fix.
-- Not runtime tested. Server-side changes may require an update.
-- Secret-boss routing uses disclosed flags/names; unknown odds are not invented.

if game.GameId ~= 10767928510 then
	return
end

local env = getgenv and getgenv() or _G
if env.PixelLineageAuto and env.PixelLineageAuto.Stop then
    pcall(env.PixelLineageAuto.Stop)
end
-- UI Library source is portable across teleport; never carry a live Window instance.
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
local BjzUi,bjzUiSource=_LoadBjzUi(env.PixelLineageBjzUiSource)
env.PixelLineageBjzUiSource=bjzUiSource
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
-- game.Loaded alone does not imply LocalPlayer / replicated remotes are ready.
-- A single deadline prevents a chain of missing objects from waiting indefinitely.
local startupDeadline=os.clock()+180
local function awaitReady(label,getter)
    repeat
        local value=getter()
        if value then return value end
        if os.clock()>=startupDeadline then
            error('PixelLineage 啟動逾時：等待 '..label..'；請確認遊戲載入與角色選擇已完成。',0)
        end
        task.wait(0.2)
    until false
end
local player=awaitReady('LocalPlayer',function() return Players.LocalPlayer end)
local pg=awaitReady('PlayerGui',function() return player:FindFirstChild('PlayerGui') end)
local root=awaitReady('PlatformBattles',function() return RS:FindFirstChild('PlatformBattles') end)
local remotes=awaitReady('Remotes',function() return root:FindFirstChild('Remotes') end)
local command=awaitReady('RPGCommand',function() return remotes:FindFirstChild('RPGCommand') end)
local stateRemote=awaitReady('RPGState',function() return remotes:FindFirstChild('RPGState') end)
local shared=root:FindFirstChild('Shared')
if not shared and env.PixelLineageResumeContext then shared=root:WaitForChild('Shared',10) end
--[[
    嘗試載入遊戲共享模組；非必要功能可選擇不等待尚未複製的 ModuleScript。
    @param name 原生模組名稱。
    @param bNoWait true 表示只讀取目前存在的模組，不阻塞啟動與戰鬥迴圈。
    @return 成功載入的模組；不存在或 require 失敗時不提供值。
]]
local function optionalModule(name,bNoWait)
    local module=shared and shared:FindFirstChild(name)
    if not module and shared and env.PixelLineageResumeContext and not bNoWait then module=shared:WaitForChild(name,5) end
    if not module then return end
    local ok,data=pcall(require,module)
    if ok then return data end
end
--[[
    裝備出售只讀取遊戲 GearConfig 與 Profile.gearBag；品質順序沿用遊戲定義。
    缺少模組時保留已知品質供介面顯示，但出售流程會等待有效模組，不猜測物品。
]]
local _GearConfig = optionalModule('GearConfig',true)
local _GearRanks = {Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Secret=6}
local GEAR_RARITY_NAMES = {Common='普通',Uncommon='優良',Rare='稀有',Epic='史詩',Legendary='傳說',Secret='秘密'}
local GEAR_SELL_BATCH_SIZE = 25
local GEAR_SELL_RETRY_SECONDS = 5
local GEAR_SELL_MAX_ATTEMPTS = 2
if type(_GearConfig)=='table' and type(_GearConfig.Rarities)=='table' then
    local Ranks = {}
    for Name,Definition in pairs(_GearConfig.Rarities) do
        local Rank = type(Definition)=='table' and Definition.order
        if type(Name)=='string' and type(Rank)=='number' and Rank>0 and Rank<math.huge then
            Ranks[Name]=Rank
        end
    end
    if next(Ranks) then _GearRanks=Ranks end
end
--[[
    出售排程共用既有主迴圈。Profile 更新才標記待檢查；每次提交後等待新的背包快照。
    Attempts 依 UID 限制重試，跨服不攜帶背包、舊角色資料或尚未確認的請求。
]]
local _GearSell = {Profile=nil,Revision=0,WaitRevision=nil,bDirty=true,NextAt=0,
    Attempts={},View=nil,ScanCount=0,ScanAt=0,bAwaitFresh=false,LastMessage=nil}


local runConfig=optionalModule('RunConfig')
local villageConfig=optionalModule('VillageConfig')
local soloActs=runConfig and runConfig.Acts or {{id='sunmeadow',name='SUNMEADOW WILDS'}}
local soloDifficulties={}
for _,d in ipairs(runConfig and runConfig.Difficulties or {{id='normal',name='NORMAL'},{id='hard',name='HARD'},{id='nightmare',name='NIGHTMARE'}}) do
    table.insert(soloDifficulties,{id=d.id,name=d.name})
end
local torment=runConfig and runConfig.Torment
if torment and torment.Id and torment.Name then
    for tier=1,tonumber(torment.OpenTiers) or 0 do
        table.insert(soloDifficulties,{id=torment.Id(tier),name=torment.Name(tier),tier=tier})
    end
end
local soloActIndex,soloDifficultyIndex=1,1
local startSolo,soloRefresh
local _SetTormentAfterVictory
local soloPendingAt,latestProfile,lobbyState
--[[
    多人流程的暫存狀態；只保存本伺服器的集合快照、準備介面及請求節流。
    由既有狀態監聽器和主迴圈更新，跨服僅攜帶 C 中的開關。
]]
local _Party={Gather=nil,bGatherObserved=false,bLobbyObserved=false,
    Requests={},Buttons={},ScanAt=0,bSurfaceWaiting=false}
local savedChildren={}
local C = {Battle=true, Continue=true, Path=true, QTE=true, Scroll=true,
    bAutoSellGear=false,GearSellRarity='Common',
    bAutoConfirmKey=true,bAutoRunReady=true,bAutoLobbyReady=true,
    Item=true, Shop=true, Camp=true, Shrine=true, Altar=true, Replay=true, Skip=true, AutoEnter=true, TormentAfterVictory="next", BaseClass="Archer", SuperClass="", HealAt=45, EnergyAt=25, GuardAt=20}
--[[
    總開關暫停時仍保存使用者原先選擇，避免改其他設定或跨服時把出售偏好覆寫成 false。
    @return 使用者選擇的自動出售開關，不包含總開關的暫時停用狀態。
]]
local function _AutoSellPreference(): boolean
    if not C.Battle and savedChildren.bAutoSellGear~=nil then return savedChildren.bAutoSellGear==true end
    return C.bAutoSellGear==true
end
local continuationRefresh,continuationStop
local HttpService=game:GetService('HttpService')
local settingsPath='PixelLineage_AutoFarm_'..tostring(game.GameId)..'_'..tostring(player.UserId)..'.json'
local settingsMemoryKey='PixelLineageSoloSettings_'..tostring(game.GameId)..'_'..tostring(player.UserId)
local settingsChangedAt=os.clock()
local settingsLoaded=false
local settingsPersisted=false
local function decodeSoloSettings(raw)
    if type(raw)~='string' or #raw>16384 then return end
    local ok,data=pcall(function() return HttpService:JSONDecode(raw) end)
    if ok and type(data)=='table' and data.schema==1 and data.userId==player.UserId and data.gameId==game.GameId then return data end
end
local function restoreSoloSettings(data)
    if type(data)~='table' then return end
    for i,act in ipairs(soloActs) do if act.id==data.actId then soloActIndex=i;break end end
    for i,diff in ipairs(soloDifficulties) do if diff.id==data.difficultyId then soloDifficultyIndex=i;break end end
    if type(data.autoEnter)=='boolean' then C.AutoEnter=data.autoEnter end
    if type(data.replay)=='boolean' then C.Replay=data.replay end
    if type(data.bAutoSellGear)=='boolean' then C.bAutoSellGear=data.bAutoSellGear end
    if data.GearSellRarity~=nil then
        if type(data.GearSellRarity)=='string' and _GearRanks[data.GearSellRarity] then
            C.GearSellRarity=data.GearSellRarity
        else C.bAutoSellGear=false;C.GearSellRarity='Common' end
    end
    for _,Key in ipairs({'bAutoConfirmKey','bAutoRunReady','bAutoLobbyReady'}) do
        if type(data[Key])=='boolean' then C[Key]=data[Key] end
    end
    if data.tormentAfterVictory=='next' or data.tormentAfterVictory=='replay' then
        C.TormentAfterVictory=data.tormentAfterVictory
    end
    settingsLoaded=true
end
local cachedSettings=env[settingsMemoryKey]
if type(readfile)=='function' then
    local ok,raw=pcall(readfile,settingsPath)
    if ok then cachedSettings=decodeSoloSettings(raw) or cachedSettings end
end
restoreSoloSettings(cachedSettings)
local function saveSoloSettings()
    local data={schema=1,userId=player.UserId,gameId=game.GameId,
        actId=soloActs[soloActIndex].id,difficultyId=soloDifficulties[soloDifficultyIndex].id,autoEnter=C.AutoEnter,replay=C.Replay,tormentAfterVictory=C.TormentAfterVictory,
                bAutoConfirmKey=C.bAutoConfirmKey,bAutoRunReady=C.bAutoRunReady,bAutoLobbyReady=C.bAutoLobbyReady,
                bAutoSellGear=_AutoSellPreference(),GearSellRarity=C.GearSellRarity}
    env[settingsMemoryKey]=data
    settingsChangedAt=os.clock()
    settingsPersisted=false
    if type(writefile)=='function' then
        local ok,raw=pcall(function() return HttpService:JSONEncode(data) end)
        if ok then settingsPersisted=pcall(writefile,settingsPath,raw) end
    end
    if continuationRefresh then continuationRefresh() end
    return settingsPersisted
end
local restartSession,autoCastleSince,autoSoloAttemptAt,travelBlockedUntil
local carry=env.PixelLineageAutoCarry
env.PixelLineageAutoCarry=nil
if type(carry)=='table' and carry.userId==player.UserId and carry.gameId==game.GameId then
    if type(carry.options)=='table' then
        for key,value in pairs(carry.options) do
            if C[key]~=nil and type(C[key])==type(value) then C[key]=value end
        end
    end
    if type(carry.selection)=='table' then restoreSoloSettings(carry.selection) end
    if C.Replay and type(carry.restart)=='table' and not carry.restart.started then
        restartSession=carry.restart;restartSession.sentAt=nil;restartSession.waitingAt=nil
        restartSession.endedAt=os.clock();restartSession.attempts=0
    end
end
if not _GearRanks[C.GearSellRarity] then C.GearSellRarity='Common';C.bAutoSellGear=false end
if C.TormentAfterVictory~='next' and C.TormentAfterVictory~='replay' then C.TormentAfterVictory='next' end
local alive, battle, run, version = true, nil, nil, 0
local connections, qtes = {}, {}
local _CancelQtes
local restorers = {}
local _bQteDriver = false
local lastBattle, lastRun, sentAt, pending = nil, nil, 0, false
local window=BjzUi:CreateWindow({
    Name='PIXEL LINEAGE',LoadingSubtitle='自動戰鬥 · SOLO 冒險',
    ConfigId='PixelLineage_'..tostring(game.GameId)..'_'..tostring(player.UserId),
    ConfigurationSaving={bEnabled=true},ToggleKey=Enum.KeyCode.RightShift,
    Width=1000,Height=700,MinWidth=360,MinHeight=300,bResizable=true,DisplayOrder=10000,
})
local gui=window.ScreenGui
local API={Window=window,Controls={}}
local controls=API.Controls
local engineThread
local function bind(signal,fn)
    local c=signal:Connect(function(...) if alive then fn(...) end end)
    table.insert(connections,c)
    return c
end
local status,lastStatus
local function say(message)
    message=tostring(message)
    if alive and status and message~=lastStatus then
        lastStatus=message
        status:Set('執行狀態',message)
    end
end
local toggles={}
local childKeys={'Continue','Path','QTE','Scroll','Item','Shop','Camp','Shrine','Altar','Replay','Skip','AutoEnter','bAutoConfirmKey','bAutoRunReady','bAutoLobbyReady','bAutoSellGear'}
local function setMaster(enabled)
    enabled=enabled==true
    if C.Battle~=enabled then
        if not enabled then
            for _,key in ipairs(childKeys) do savedChildren[key]=C[key];C[key]=false end
            version=version+1;if _CancelQtes then _CancelQtes() end;table.clear(qtes);pending=false;lastRun=nil
        else
            for _,key in ipairs(childKeys) do C[key]=savedChildren[key]~=false end
        end
        C.Battle=enabled;_GearSell.bDirty=true
    end
    for _,refresh in pairs(toggles) do refresh() end
    if continuationRefresh then continuationRefresh() end
end

-- Keep the original public Stop API and make native window destruction clean up
-- gameplay listeners, the existing engine task, and the Archer-driver restorers.
local destroyWindow=window.Destroy
function API.Stop(reason)
    if not alive then return end
    -- Client teardown must not invalidate the already queued destination startup.
    -- Explicit Stop / close / rerun still cancel the pending continuation record.
    if continuationStop and reason~='teleport' and reason~='surface-destroyed' then continuationStop() end
    alive=false;version=version+1;if _CancelQtes then _CancelQtes() end;table.clear(qtes)
    if engineThread then pcall(task.cancel,engineThread);engineThread=nil end
    for _,c in ipairs(connections) do c:Disconnect() end
    table.clear(connections)
    for _,restore in ipairs(restorers) do pcall(restore) end
    table.clear(restorers)
    if env.PixelLineageAuto==API then env.PixelLineageAuto=nil end
    if not window.bDestroyed then destroyWindow(window) end
end
--[[
    接收 BjzUi 的外部 ScreenGui 銷毀通知；傳送拆除保留續跑，使用者關閉則取消。
    @param self 目前視窗；_bGuiDestroying 由 BjzUi 在外部銷毀期間設定。
]]
function window.Destroy(self: typeof(window)): ()
    API.Stop(self._bGuiDestroying and 'surface-destroyed' or nil)
end
env.PixelLineageAuto=API
bind(gui.Destroying,function()
    -- Do not recursively destroy ScreenGui while its Destroying event is running.
    task.defer(function() API.Stop('surface-destroyed') end)
end)
-- BjzUi's default × hides the window. Preserve this script's original × = Stop.
for _,child in ipairs(window.Body:GetChildren()) do
    if child:IsA('TextButton') and child.Text=='×' then bind(child.Activated,API.Stop);break end
end
window.Mini.Text='PL'
if type(window._SavedUI)~='table' or type(window._SavedUI.MiniX)~='number' then
    window.Mini.Position=UDim2.fromOffset(math.max(4,(window.Surface.AbsoluteSize.X-46)/2),8)
end

do
    local combatTab=window:CreateTab('自動戰鬥','crosshair')
    local eventTab=window:CreateTab('冒險事件','grid')
    local soloTab=window:CreateTab('SOLO 冒險','zap')
    local PartyTab=window:CreateTab('多人模式','bell')
    local strategyTab=window:CreateTab('戰鬥設定','file')
    local GearTab=window:CreateTab('裝備管理','file')
    local uiTab=window:CreateTab('介面設定','settings')
    local statusSection=combatTab:CreateSection({Name='目前狀態',Side='full'})
    status=statusSection:CreateParagraph({Title='執行狀態',Content='正在載入…'})
    API.Status=status
    API.QteStatus=statusSection:CreateParagraph({Title='QTE 判定',Content='直接提交模式；等待 QTE 事件。'})
    local mainSection=combatTab:CreateSection({Name='控制',Side='left'})
    local combatSection=combatTab:CreateSection({Name='戰鬥選項',Side='right'})
    local routeSection=eventTab:CreateSection({Name='路線與流程',Side='left'})
    local eventSection=eventTab:CreateSection({Name='事件處理',Side='right'})
    local soloSection=soloTab:CreateSection({Name='關卡與難度',Side='left'})
    local repeatSection=soloTab:CreateSection({Name='冒險循環',Side='right'})
    local PartySection=PartyTab:CreateSection({Name='多人準備與確認',Side='full'})
    local GearSection=GearTab:CreateSection({Name='自動出售',Side='full'})
    local classSection=strategyTab:CreateSection({Name='職業',Side='left'})
    local thresholdSection=strategyTab:CreateSection({Name='戰鬥門檻',Side='right'})

    -- Gameplay controls use the existing C/solo settings as their source of truth.
    -- bSave=false prevents UiConfig from overriding a freshly restored teleport snapshot.
    local function toggle(section,key,name,description)
        local child=key~='Battle'
        local control
        control=section:CreateToggle({
            Name=name,Description=description,bCurrentValue=C[key],Flag='pl_'..key,bSave=false,
            bEnabled=not child or C.Battle,
            Callback=function(value)
                if key=='Battle' then
                    setMaster(value)
                    say(value and '自動戰鬥已啟用' or '全部停止')
                elseif C.Battle then
                    C[key]=value
                    if key=='QTE' and not value and _CancelQtes then _CancelQtes() end
                    if key=='bAutoSellGear' then _GearSell.bDirty=true end
                    if key=='AutoEnter' or key=='Replay' or key=='bAutoConfirmKey'
                        or key=='bAutoRunReady' or key=='bAutoLobbyReady' or key=='bAutoSellGear' then saveSoloSettings()
                    elseif continuationRefresh then continuationRefresh() end
                else
                    control:Set(false,true)
                end
            end,
        })
        controls[key]=control
        toggles[key]=function()
            control:Set(C[key],true)
            control:SetEnabled(not child or C.Battle)
        end
        toggles[key]()
    end
    toggle(mainSection,'Battle','自動戰鬥 · 總開關')
    mainSection:CreateButton({Name='停止全部',Style='outline',Callback=function()
        setMaster(false);say('全部停止')
    end})
    mainSection:CreateButton({Name='最小化',Style='secondary',Callback=function() window:Minimize() end})
    mainSection:CreateButton({Name='停止並關閉介面',Style='outline',Callback=API.Stop})
    toggle(combatSection,'QTE','自動 QTE（直接提交）','略過對準面板；攻擊提交滿命中資料，RAID 防禦逐擊提交中心時間。')
    toggle(combatSection,'Scroll','允許使用 SCROLL','有可用卷軸時優先使用。')
    toggle(combatSection,'Item','允許使用 SATCHEL')
    toggle(routeSection,'Continue','自動 CONTINUE')
    toggle(routeSection,'Path','自動路線 · 隱藏 BOSS 優先')
    toggle(routeSection,'Skip','自動 SKIP 動畫')
    toggle(eventSection,'Shop','自動 SHOP','選購完成後按 DONE。')
    toggle(eventSection,'Camp','自動 CAMP','選擇完成後按 TO BATTLE。')
    toggle(eventSection,'Shrine','自動 TRAINER’S SHRINE')
    toggle(eventSection,'Altar','自動 BLOOD ALTAR')
    toggle(repeatSection,'Replay','通關後自動接續','一般模式重新開始；TORMENT 依下方選擇接續。')
    --[[
        保存 TORMENT 通關後的接續方式；切換本身不發出遊戲指令。
        @param Choice next 表示下一級；replay 表示重新開始目前等級。
    ]]
    controls.TormentAfterVictory=repeatSection:CreateDropdown({
        Name='TORMENT 通關後',Options={
            {Name='進入下一級',Value='next'},
            {Name='重新開始目前等級',Value='replay'},
        },
        CurrentOption=C.TormentAfterVictory,bSearchable=false,bSave=false,Flag='pl_TormentAfterVictory',
        Callback=function(Choice) if _SetTormentAfterVictory then _SetTormentAfterVictory(Choice) end end,
    })
    toggle(repeatSection,'AutoEnter','CASTLE 自動進入 SOLO')
    toggle(PartySection,'bAutoConfirmKey','自動同意鑰匙副本','多人冒險收到鑰匙副本提案時，自動 CONFIRM ENTRY。')
    toggle(PartySection,'bAutoRunReady','冒險開始自動準備','進入多人冒險的集合畫面後，自動按 READY!。')
    toggle(PartySection,'bAutoLobbyReady','CASTLE 房間自動 READY','加入多人房間後自動準備；已準備時不取消。')
    PartySection:CreateParagraph({Title='多人流程',Content='三個開關各自保存並跨服沿用。全部受自動戰鬥總開關控制。房主仍需按 START RUN；等待隊友時會暫停 CASTLE 自動 SOLO。'})

    toggle(GearSection,'bAutoSellGear','自動賣裝備','啟用後，出售所選品質及以下的可出售裝備；受總開關控制。')
    local GearOptions={}
    for Rarity,Rank in pairs(_GearRanks) do
        GearOptions[#GearOptions+1]={Name=(GEAR_RARITY_NAMES[Rarity] or Rarity)..' · '..Rarity..' 以下（含）',Value=Rarity,Rank=Rank}
    end
    --[[
        品質選項依遊戲順位由低至高排列。
        @param A 左側選項。
        @param B 右側選項。
        @return true 表示 A 應顯示在 B 前面。
    ]]
    table.sort(GearOptions,function(A,B) return A.Rank<B.Rank or (A.Rank==B.Rank and A.Value<B.Value) end)
    controls.GearSellRarity=GearSection:CreateDropdown({
        Name='出售品質上限（包含）',Options=GearOptions,CurrentOption=C.GearSellRarity,
        bSearchable=false,bSave=false,Flag='pl_GearSellRarity',
        --[[
            改變包含在內的品質門檻，保存並要求主迴圈重新篩選；回呼本身不出售。
            @param Rarity 下拉欄選擇的遊戲品質識別字。
        ]]
        Callback=function(Rarity)
            if type(Rarity)~='string' or not _GearRanks[Rarity] then return end
            C.GearSellRarity=Rarity;_GearSell.bDirty=true;saveSoloSettings()
        end,
    })
    API.GearSellStatus=GearSection:CreateParagraph({Title='出售狀態',Content='未啟用自動出售。'})
    GearSection:CreateParagraph({Title='出售規則',Content='例如選 Rare，會出售 Common、Uncommon、Rare。已穿戴、外觀欄使用中、鎖定與遊戲禁止出售的裝備保留；消耗品與寵物不處理。戰鬥時暫停，取得新背包資料後才繼續。'})
    GearSection:CreateParagraph({Title='自動保存',Content='開關與品質門檻依玩家保存，跨服續跑沿用。首次預設關閉；總開關關閉時一起停止。'})

    local function textRow(key,name,placeholder)
        local control
        control=classSection:CreateInput({
            Name=name,CurrentValue=C[key],PlaceholderText=placeholder,
            Flag='pl_'..key,bSave=false,
            Callback=function(value)
                C[key]=value:match('^%s*(.-)%s*$')
                control:Set(C[key],true)
                if continuationRefresh then continuationRefresh() end
            end,
        })
        controls[key]=control
    end
    textRow('BaseClass','無職業時選擇','例如 Archer / Spear')
    textRow('SuperClass','目標轉職（留空 TRAIN）','輸入完整名稱或 ID')
    local function numberRow(key,name)
        controls[key]=thresholdSection:CreateSlider({
            Name=name,Range={0,100},Increment=1,Suffix='%',CurrentValue=C[key],
            Flag='pl_'..key,bSave=false,Callback=function(value)
                C[key]=value
                if continuationRefresh then continuationRefresh() end
            end,
        })
    end
    numberRow('HealAt','低於此血量時優先補血')
    numberRow('EnergyAt','低於此能量時優先 MEDITATE')

    local function soloDropdown(key,name,values,getIndex,setIndex)
        local options={}
        for i,value in ipairs(values) do
            options[#options+1]={Name=tostring(value.name or value.id or i),Value=i}
        end
        controls[key]=soloSection:CreateDropdown({
            Name=name,Options=options,CurrentOption=getIndex(),bSearchable=true,
            Flag='pl_'..key,bSave=false,Callback=function(index)
                if not values[index] then return end
                setIndex(index);saveSoloSettings()
                say(name..'已選擇'..(settingsPersisted and '並保存' or '（僅保留本次執行）'))
            end,
        })
    end
    soloDropdown('SoloAct','SOLO 關卡',soloActs,function() return soloActIndex end,function(i) soloActIndex=i end)
    soloDropdown('SoloDifficulty','難度',soloDifficulties,function() return soloDifficultyIndex end,function(i) soloDifficultyIndex=i end)
    local soloGo=soloSection:CreateButton({Name='CASTLE → SOLO 出發',Callback=function()
        if startSolo then startSolo() end
    end})
    controls.SoloAction=soloGo
    soloRefresh=function() soloGo:SetEnabled(C.Battle) end
    toggles.SoloAction=soloRefresh;soloRefresh()
    repeatSection:CreateParagraph({Title='SOLO 設定自動保存',Content='關卡、難度、自動進入與接續選項會沿用原本的玩家設定檔。TORMENT 接續方式與目標等級也會保存。切換選項不會立刻出發。'})
    controls.Continuation=repeatSection:CreateParagraph({Title='跨服續跑',Content='正在建立續跑排程…'})
    repeatSection:CreateButton({Name='重新設定跨服續跑',Style='outline',Callback=function()
        if API.RearmContinuation then API.RearmContinuation() end
    end})

    local appearance=uiTab:CreateSection({Name='外觀',Side='left'})
    local accent=appearance:CreateColorPicker({Name='主題顏色',Color=window.Theme.Accent,bSave=false,
        Callback=function(color) window:SetAccent(color) end})
    local scale=appearance:CreateSlider({Name='介面縮放',Range={65,150},Increment=5,Suffix='%',
        CurrentValue=window.Scale*100,bSave=false,Callback=function(value) window:SetScale(value/100) end})
    local animations=appearance:CreateToggle({Name='介面動畫',bCurrentValue=window.bAnimations,bSave=false,
        Callback=function(value) window:SetAnimations(value) end})
    local configSection=uiTab:CreateSection({Name='介面設定檔',Side='right'})
    configSection:CreateParagraph({Title='自動儲存',Content='主題、尺寸、縮放與位置會自動保存。RightShift 可顯示或隱藏介面。'})
    configSection:CreateButton({Name='儲存介面設定',Callback=function()
        local ok,reason=window:SaveConfiguration()
        window:Notify({Title=ok and '已儲存' or '儲存失敗',Content=ok and 'workspace/BjzUi/UiConfig.json' or tostring(reason)})
    end})
    configSection:CreateButton({Name='讀取介面設定',Style='outline',Callback=function()
        local ok,reason=window:LoadConfiguration(true)
        if ok then
            accent:Set(window.Theme.Accent,true)
            scale:Set(window.Scale*100,true)
            animations:Set(window.bAnimations,true)
        end
        window:Notify({Title=ok and '已讀取' or '讀取失敗',Content=ok and '已套用介面設定。' or tostring(reason)})
    end})
    -- A carried master-off state must display every child as off and disabled.
    if not C.Battle then
        for _,key in ipairs(childKeys) do savedChildren[key]=C[key];C[key]=false end
        setMaster(false)
    end
end
local function send(name,data) if alive and C.Battle then command:FireServer(name,data) end end
--[[
    更新裝備分頁的狀態文字；內容相同時不重繪。
    @param Message 要顯示的執行或等待狀態。
]]
local function _GearSellReport(Message: string): ()
    if alive and API.GearSellStatus and _GearSell.LastMessage~=Message then
        _GearSell.LastMessage=Message
        API.GearSellStatus:Set('出售狀態',Message)
    end
end

--[[
    接收目前角色的伺服器背包快照；不把前一份快照與不完整的新資料合併。
    @param Profile RPGState 的 Profile 或已辨識原生 GearView 的目前 Profile。
]]
local function _ObserveGearProfile(Profile): ()
    local Previous=_GearSell.Profile
    _GearSell.Revision+=1
    _GearSell.bDirty=true
    _GearSell.bAwaitFresh=false
    if type(Profile)~='table' or type(Profile.gearBag)~='table' or type(Profile.gear)~='table'
        or (Profile.vanity~=nil and type(Profile.vanity)~='table') then
        _GearSell.Profile=nil
        _GearSell.bAwaitFresh=true
        return
    end
    if Previous and Previous.heroSlot~=Profile.heroSlot then table.clear(_GearSell.Attempts) end
    _GearSell.Profile=Profile
    for Uid in pairs(_GearSell.Attempts) do
        if Profile.gearBag[Uid]==nil then _GearSell.Attempts[Uid]=nil end
    end
end

--[[
    啟用時至多探索三次已載入的原生裝備介面，補回腳本啟動前已發生的 Profile。
    只接受同一玩家、同一 RPGCommand 與存活介面的實例；不修改原生介面或其方法。
    找不到時等待 RPGState，不猜測 ProfileRequest 的參數。
    @param Now 本機單調時間，單位為秒。
]]
local function _RecoverGearProfile(Now: number): ()
    if _GearSell.Profile or _GearSell.bAwaitFresh then return end
    if _GearSell.View and _GearSell.View.gui and _GearSell.View.gui.Parent then
        _ObserveGearProfile(_GearSell.View.profile)
        return
    end
    if type(getgc)~='function' or _GearSell.ScanCount>=3 or Now<_GearSell.ScanAt then return end
    _GearSell.ScanCount+=1
    _GearSell.ScanAt=Now+5
    local bOk,Objects=pcall(getgc,true)
    if not bOk or type(Objects)~='table' then return end
    for _,Object in pairs(Objects) do
        if type(Object)=='table' and rawget(Object,'player')==player
            and rawget(Object,'commandRemote')==command then
            local Meta=getmetatable(Object)
            local Methods=type(Meta)=='table' and rawget(Meta,'__index')
            local Gui=rawget(Object,'gui')
            if type(Methods)=='table' and type(rawget(Methods,'_sellable'))=='function'
                and type(rawget(Methods,'_pickTotals'))=='function'
                and typeof(Gui)=='Instance' and Gui.Parent then
                _GearSell.View=Object
                _ObserveGearProfile(rawget(Object,'profile'))
                return
            end
        end
    end
end

--[[
    檢查單件裝備是否在門檻內且可以出售；只使用 gearBag，消耗品與寵物不會進入此流程。
    @param Uid 背包內的唯一識別字，不以裝備名稱出售。
    @param Item 該 UID 最新的裝備資料。
    @param Worn 裝備欄與外觀欄正在使用的 UID 集合。
    @param Maximum 包含在內的最高品質順位。
    @return true 表示此快照中的裝備符合門檻及遊戲出售規則；資料不明時為 false。
]]
local function _CanAutoSellGear(Uid,Item,Worn,Maximum: number): boolean
    if type(Uid)~='string' or Uid=='' or type(Item)~='table' or Worn[Uid]
        or (Item.locked~=nil and Item.locked~=false) or Item.starter==true or Item.promo==true
        or (Item.uid~=nil and Item.uid~=Uid) then return false end
    local Base=_GearConfig.Items[Item.base or Item.id or '']
    if type(Base)~='table' or Base.starter==true or Base.promo==true then return false end
    local Rarity=Item.rarity or Base.rarity
    local Rank=type(Rarity)=='string' and _GearRanks[Rarity]
    if not Rank or Rank>Maximum then return false end
    local bOk,bSellable=pcall(_GearConfig.CanSell,Item)
    return bOk and bSellable==true
end

--[[
    在既有低頻主迴圈內處理背包變更。每批最多 25 件，送出後需新的 Profile 才能再送。
    同一 UID 最多兩次且至少相隔五秒；重試前重新檢查品質、鎖定、裝備欄及目前角色。
    只送 GearSellMany 的出售協定，不發出刪除、解鎖或卸裝指令。

    使用範例：
    ```lua
    -- 前提：主腳本已建立 controls 並接收目前角色的 Profile。
    controls.GearSellRarity:Set('Rare') -- Common、Uncommon、Rare 都符合門檻。
    controls.bAutoSellGear:Set(true) -- 由既有主迴圈處理；已穿戴或鎖定者保留。
    ```
]]
local function _GearSellTick(): ()
    if not C.Battle or not C.bAutoSellGear then
        _GearSellReport(not C.Battle and '總開關已關閉，停止出售。' or '未啟用自動出售。')
        return
    end
    if player:GetAttribute('RPGGameplayReady')~=true or player:GetAttribute('RPGInTheLight')==true
        or player:GetAttribute('PBCustomizing')==true or player:GetAttribute('PBTutorial')~=nil then
        _GearSellReport('等待角色進入遊戲。')
        return
    end
    if battle or player:GetAttribute('InTurnBattle')==true or player:GetAttribute('PlatformBattleActive')==true
        or (API.Continuation and API.Continuation.Departing) then
        _GearSellReport('戰鬥或傳送中，稍後出售。')
        return
    end
    if not _GearConfig then
        -- Late replication may supply GearConfig after startup; never block the engine waiting for it.
        local CurrentTime=os.clock()
        if CurrentTime>=(_GearSell.ConfigAt or 0) then
            _GearSell.ConfigAt=CurrentTime+5
            _GearConfig=optionalModule('GearConfig',true)
        end
    end
    if type(_GearConfig)~='table' or type(_GearConfig.Items)~='table'
        or type(_GearConfig.CanSell)~='function' then
        _GearSellReport('無法取得 GearConfig，暫停出售。')
        return
    end
    local Now=os.clock()
    _RecoverGearProfile(Now)
    local Profile=_GearSell.Profile
    if not Profile then _GearSellReport('等待背包資料；可開啟遊戲 GEAR 後再試。');return end
    if _GearSell.WaitRevision and _GearSell.Revision<=_GearSell.WaitRevision then
        if Now>=_GearSell.NextAt+9 then _GearSellReport('已提交出售，等待新的背包資料；不重複送出舊清單。') end
        return
    end
    if not _GearSell.bDirty or Now<_GearSell.NextAt then return end
    local Maximum=_GearRanks[C.GearSellRarity]
    if not Maximum then _GearSellReport('品質設定無效，暫停出售。');return end
    _GearSell.bDirty=false
    local Worn={}
    for _,Uid in pairs(Profile.gear) do if type(Uid)=='string' then Worn[Uid]=true end end
    for _,Uid in pairs(Profile.vanity or {}) do if type(Uid)=='string' then Worn[Uid]=true end end
    local Candidates={}
    local RetryAt,bExhausted=nil,false
    for Uid,Item in pairs(Profile.gearBag) do
        if not _CanAutoSellGear(Uid,Item,Worn,Maximum) then continue end
        local Attempt=_GearSell.Attempts[Uid]
        if Attempt and Attempt.Count>=GEAR_SELL_MAX_ATTEMPTS then bExhausted=true;continue end
        if Attempt and Attempt.Revision>=_GearSell.Revision then continue end
        if Attempt and Now-Attempt.At<GEAR_SELL_RETRY_SECONDS then
            RetryAt=math.min(RetryAt or math.huge,Attempt.At+GEAR_SELL_RETRY_SECONDS)
        else
            table.insert(Candidates,Uid)
        end
    end
    if #Candidates==0 then
        if RetryAt then
            _GearSell.bDirty=true;_GearSell.NextAt=RetryAt
            _GearSellReport('等待出售回應；取得新資料後才會有限次重試。')
        elseif bExhausted then
            _GearSellReport('部分裝備仍在背包，已停止重試；其他新裝備仍會自動處理。')
        else
            _GearSellReport('目前沒有符合條件的可出售裝備。')
        end
        return
    end
    table.sort(Candidates)
    local Uids={}
    for Index=1,math.min(GEAR_SELL_BATCH_SIZE,#Candidates) do
        local Uid=Candidates[Index]
        local Previous=_GearSell.Attempts[Uid]
        _GearSell.Attempts[Uid]={Count=(Previous and Previous.Count or 0)+1,At=Now,Revision=_GearSell.Revision}
        table.insert(Uids,Uid)
    end
    _GearSell.NextAt=Now+1
    _GearSell.WaitRevision=_GearSell.Revision
    local bSent,Reason=pcall(command.FireServer,command,'GearSellMany',{uids=Uids})
    if bSent then
        _GearSellReport('已提交 '..#Uids..' 件出售（'..C.GearSellRarity..' 以下，含本級），等待背包更新。')
    else
        _GearSellReport('出售請求失敗，等待新背包資料：'..tostring(Reason))
    end
end


local function liveLobby()
    if not getgc then return end
    local ok,objects=pcall(getgc,true)
    if not ok then return end
    for _,obj in pairs(objects) do
        if type(obj)=='table' and type(rawget(obj,'view'))=='table' and rawget(obj,'screen') then
            local mt=getmetatable(obj)
            local methods=type(mt)=='table' and rawget(mt,'__index')
            if type(methods)=='table' and type(rawget(methods,'_canStart'))=='function'
                and type(rawget(methods,'_solo'))=='function' then return obj end
        end
    end
end
local function soloEligibility(attributes,activeBattle,lobby)
    if not C.Battle then return false,'請先開啟自動戰鬥總開關' end
    if attributes.RPGGameplayReady~=true then return false,'請先進入角色的 CASTLE' end
    if activeBattle or attributes.PBInRun==true or attributes.InTurnBattle==true
        or attributes.PlatformBattleActive==true or attributes.RPGInTheLight==true
        or attributes.PBCustomizing==true or attributes.PBTutorial~=nil then
        return false,'目前不在可出發的 CASTLE 狀態'
    end
    if lobby and (lobby.state=='lobby' or lobby.state=='queue') then return false,'請先退出目前的多人隊伍或配對' end
    if (_Party.Gather and not _Party.Gather.closed) or _Party.bSurfaceWaiting then
        return false,'正在等待多人準備，請先退出多人流程'
    end
    return true
end
startSolo=function(selection)
    local ok,reason=soloEligibility(player:GetAttributes(),battle~=nil,lobbyState)
    if not ok then say('SOLO：'..reason);return end
    if soloPendingAt and os.clock()-soloPendingAt<10 then say('SOLO：正在進入關卡，請稍候');return end
    local actIndex=selection and selection.actIndex or soloActIndex
    local selected=soloDifficulties[soloDifficultyIndex]
    if selection and selection.difficultyId then
        selected=nil
        for _,diff in ipairs(soloDifficulties) do if diff.id==selection.difficultyId then selected=diff;break end end
    end
    if not soloActs[actIndex] or not selected then say('SOLO：關卡或難度資料尚未就緒');return false end
    local lobby=liveLobby()
    local profile=lobby and lobby.view.profile or latestProfile
    if lobby and lobby.state and (lobby.state.state=='lobby' or lobby.state.state=='queue') then
        say('SOLO：請先退出目前的多人隊伍或配對');return
    end
    if profile and villageConfig and villageConfig.CanStartAt then
        local valid,allowed=pcall(villageConfig.CanStartAt,profile.village,actIndex,#soloActs,profile)
        if not valid or not allowed then say('SOLO：此關卡尚未解鎖，請檢查城堡傳送門與通關進度');return end
    elseif actIndex>1 then
        say('SOLO：尚未讀取解鎖進度；請先開啟遊戲原本的 SET OUT 選單再試');return
    end
    if selected.tier then
        if not profile or not torment or not torment.Unlocked or not torment.MaxTier then
            say('SOLO：尚未讀取 TORMENT 解鎖資料');return
        end
        local valid,unlocked=pcall(torment.Unlocked,profile,profile.village)
        local gotTier,maxTier=pcall(torment.MaxTier,profile)
        if not valid or not unlocked or not gotTier or selected.tier>maxTier then
            say('SOLO：此 TORMENT 難度尚未解鎖');return
        end
    end
    send('RunLobby',{action='solo',difficulty=selected.id,startAct=actIndex})
    soloPendingAt=os.clock()
    say('SOLO：'..tostring(soloActs[actIndex].name)..' / '..tostring(selected.name)..' → 進入中')
    return true
end
local function category(a)
    local s=string.lower(tostring(a.category or a.kind or a.id or ''))
    if s=='meditate' then return 'Meditate' end
    if s=='gearscroll' then return 'Scroll' end
    for _,v in ipairs({'skill','spell','ability'}) do if s:find(v,1,true) then return 'Skill' end end
    for _,v in ipairs({'item','bag','potion'}) do if s:find(v,1,true) then return 'Item' end end
    for _,v in ipairs({'guard','defend','block'}) do if s:find(v,1,true) then return 'Guard' end end
    for _,v in ipairs({'run','flee','escape'}) do if s:find(v,1,true) then return 'Run' end end
    return 'Attack'
end
local function ratio(t,key,maxKey)
    local value,max=tonumber(t[key]),tonumber(t[maxKey])
    if not value or not max or max<=0 then return nil end
    return value/max*100
end
-- Snapshot actions may omit damage and area flags: enrich from replicated definitions.
local actionDefinitions={}
local function indexCombatDefinitions(value,seen,depth)
    if type(value)~='table' or seen[value] or depth>12 then return end
    seen[value]=true
    if value.id and (value.power or value.damage or value.allEnemies or value.aoe or value.kind=='MultiDamage') then
        actionDefinitions[tostring(value.id)]=value
    end
    for _,child in pairs(value) do
        if type(child)=='table' then indexCombatDefinitions(child,seen,depth+1) end
    end
end
if root then
    local shared=root:FindFirstChild('Shared')
    local config=shared and shared:FindFirstChild('GameConfig')
    if config then
        local ok,data=pcall(require,config)
        if ok then indexCombatDefinitions(data,{},0) end
    end
end
local function attackInfo(action,actor)
    local definition=actionDefinitions[tostring(action.id)] or {}
    local function field(key)
        if action[key]~=nil then return action[key] end
        return definition[key]
    end
    local description=string.lower(tostring(action.description or definition.description or ''))
    local targetType=tostring(field('targetType') or '')
    local all=field('allEnemies')==true or field('aoe')==true or field('effect')=='allEnemies'
        or targetType=='AllEnemies'
    if not all then
        for _,phrase in ipairs({'all enemies','every enemy','all foes','all opponents','entire enemy','全體敵人','所有敵人'}) do
            if description:find(phrase,1,true) then all=true;break end
        end
    end
    local cat=category(action)
    local kind=tostring(field('kind') or '')
    local offensive=all or targetType=='Enemy' or kind=='Damage' or kind=='MultiDamage'
        or field('effect')=='strike' or field('effect')=='randomHits' or cat=='Attack'
    -- Healing/support effects do not become offensive merely because they have power.
    if targetType=='Ally' or kind=='Heal' or kind=='Restore' then offensive=false end
    local damage=tonumber(field('estimatedDamage')) or tonumber(field('damage'))
    if not damage then
        local power=tonumber(field('power')) or 1
        local scaling=actor[tostring(field('scaling') or 'attack')]
        damage=power*math.max(1,tonumber(scaling) or 1)
        if kind=='MultiDamage' then damage=damage*math.max(1,tonumber(field('hits')) or 1) end
    end
    return offensive,all,math.max(0,damage)
end
local function chooseAction(b)
    local p=b.player or {};local hp=ratio(p,'hp','maxHp');local energy=ratio(p,'mp','maxMp') or ratio(p,'energy','maxEnergy')
    local availableEnergy=tonumber(p.mp or p.energy)
    local best,score,bestTarget,bestDamage
    local bBestScroll=false
    local target,lowest,enemyCount=nil,math.huge,0
    for i,e in ipairs(b.enemies or {}) do
        local actor=e.actor or e;local h=tonumber(actor.hp)
        if h and h>0 and not e.dead and not actor.dead then
            enemyCount=enemyCount+1
            if h<lowest then target=e.index or i;lowest=h end
        end
    end
    for _,a in ipairs(b.actions or {}) do
        local cost=tonumber(a.cost) or 0
        if a.id and a.enabled~=false and (not availableEnergy or cost<=availableEnergy) then
            local cat=category(a)
            local bScroll=cat=='Scroll'
            if bScroll and not C.Scroll then continue end
            -- Usable support scrolls are eligible even without damage or missing HP.
            local s=bScroll and 0 or -math.huge
            local desc=string.lower(tostring(a.id)..' '..tostring(a.name)..' '..tostring(a.description))
            local heal=desc:find('heal',1,true) or desc:find(' hp',1,true) or desc:find('restore hp',1,true) or desc:find('health',1,true)
            local energyItem=desc:find('energy',1,true) or desc:find(' mp',1,true) or desc:find('mana',1,true)
            local offensive,all,damage=attackInfo(a,p)
            local allowed=cat=='Attack' or cat=='Skill' or (cat=='Scroll' and C.Scroll)
            if offensive and allowed and enemyCount>0 then
                -- Group preference dominates damage; damage ranks actions within the group.
                local preferred=(enemyCount>1 and all) or (enemyCount==1 and not all)
                s=preferred and 50 or 20
            end
            if heal and hp and hp<C.HealAt and (cat~='Item' or C.Item) then s=110+(100-hp) end
            if cat=='Item' and C.Item and energyItem and not heal and energy and energy<C.EnergyAt then s=95 end
            if cat=='Meditate' and energy and energy<C.EnergyAt then s=85 end
            if cat=='Guard' and hp and hp<C.GuardAt then s=60 end
            if a.targetDowned or (bScroll and offensive and enemyCount==0) then s=-math.huge end
            local ally
            if a.targetType=='Enemy' and not target then s=-math.huge end
            if a.targetType=='Ally' then
                local low=math.huge
                for _,member in ipairs(b.party or {}) do
                    local r=ratio(member,'hp','maxHp')
                    if member.userId and tonumber(member.hp) and member.hp>0 and r and r<low then low=r;ally=member.userId end
                end
                if not ally then s=-math.huge end
            end
            -- Scroll priority is separate from the normal score: even emergency
            -- healing / energy recovery cannot outrank a usable enabled scroll.
            if s~=-math.huge and (not best or (bScroll and not bBestScroll)
                or (bScroll==bBestScroll and (s>score or (s==score and damage>(bestDamage or -1))))) then
                best=a;score=s;bestTarget=ally;bestDamage=damage;bBestScroll=bScroll
            end
        end
    end
    if not best or score==-math.huge then return end
    local payload={battleId=b.id,actionId=best.id}
    if best.targetType=='Enemy' then payload.targetEnemyIndex=target end
    if best.targetType=='Ally' then payload.targetUserId=bestTarget end
    return best,payload
end
local secretNames={'honklord','justarock','chonkus','toddfromaccounting','lordmildew','error404','nanarot'}
local function flatten(t,depth)
    if type(t)~='table' then return tostring(t) end
    if depth>4 then return '' end
    local out={}
    for k,v in pairs(t) do table.insert(out,tostring(k)..' '..flatten(v,depth+1)) end
    return table.concat(out,' ')
end
local function pathScore(c)
    if type(c)~='table' then return 0,0 end
    local text=string.lower(flatten(c,0));local secret=0
    if c.secretBoss==true or c.secret==true or c.hiddenBoss==true then secret=2 end
    if text:find('secret boss',1,true) or text:find('hidden boss',1,true) then secret=math.max(secret,1) end
    for _,name in ipairs(secretNames) do if text:gsub('%W',''):find(name,1,true) then secret=2 end end
    local chance=tonumber(c.secretBossChance or c.hiddenBossChance)
    -- Use a disclosed chance when present; zero chance is not an indication of a boss.
    if chance then secret=chance>0 and (3+chance) or 0 end
    local reward=tonumber(c.rewardScore) or 0
    local weights={legendary=100,epic=70,rare=40,treasure=45,chest=40,elite=25,miniboss=30,gold=10,rest=5}
    for word,w in pairs(weights) do if text:find(word,1,true) then reward=reward+w end end
    return secret,reward
end
local function runSend(action,choice)
    if not run then return end
    send('RunAction',{action=action,choice=choice,runId=run.id,round=run.round,phase=run.phase})
end
-- The shop uses RunState.eventData, members and per-user eventBought.
local shopSession
local runRevision=0
local function localMember(r)
    for _,m in pairs(r.members or {}) do
        if type(m)=='table' and tonumber(m.userId)==player.UserId then return m end
    end
end
local function selectShopItem(items,member,bought,failed)
    local gold=tonumber(member.gold)
    if not gold then return nil,'missing_gold' end
    local hp=ratio(member,'hp','maxHp')
    local potions=tonumber(member.potions)
    local statuses=member.statuses or {}
    local best,score
    for _,item in ipairs(items or {}) do
        local price=tonumber(item.price)
        if item.id and price and price>=0 and price<=gold and not bought[item.id] and not failed[item.id] then
            local priority
            if item.id=='tonic' and hp and hp<=70 then priority=200+(100-hp)
            elseif item.id=='potion' and potions and potions<3 then priority=120+(3-potions)*10
            elseif item.id=='ward' and not statuses.Fortified and hp and hp<80 then priority=90
            elseif item.id=='whetstone' and not statuses.Inspired then priority=70
            elseif item.id=='ward' and not statuses.Fortified then priority=50 end
            if priority and (not score or priority>score) then best,score=item,priority end
        end
    end
    return best
end
local function shopTick()
    if not C.Shop or not run or run.phase~='event' or not run.eventData or run.eventData.kind~='shop' then
        shopSession=nil;return
    end
    local key=tostring(run.id)..':'..tostring(run.round)
    if not shopSession or shopSession.key~=key then shopSession={key=key,failed={},attempts=0} end
    local session=shopSession
    if session.done then return end
    for _,id in ipairs(run.eventReady or {}) do if tonumber(id)==player.UserId then session.done=true;return end end
    local member=localMember(run)
    if not member then say('SHOP：等待角色資料');return end
    local bought=(run.eventBought or {})[tostring(player.UserId)] or {}
    local now=os.clock()
    if session.pending then
        if bought[session.pending] then
            say('SHOP：已購買 '..session.pending);session.pending=nil;session.attempts=0
        elseif now-session.sentAt<3 then return
        elseif runRevision>(session.pendingRevision or 0) then
            session.failed[session.pending]=true
            say('SHOP：伺服器未確認購買，略過 '..session.pending)
            session.pending=nil
        elseif session.attempts<2 then
            send('RunAction',{action='state'});session.attempts=session.attempts+1;session.sentAt=now;return
        else
            -- Do not send DONE while the result of a purchase remains unknown.
            say('SHOP：購買尚未確認，等待伺服器；可關閉 SHOP 手動處理')
            if now-session.sentAt>5 then send('RunAction',{action='state'});session.sentAt=now end
            return
        end
    end
    if session.nextAt and now<session.nextAt then return end
    local item,reason=selectShopItem(run.eventData.items,member,bought,session.failed)
    if reason then say('SHOP：等待金幣資料');return end
    if item then
        session.pending=item.id;session.pendingRevision=runRevision;session.sentAt=now;session.attempts=0;session.nextAt=now+0.5
        send('RunAction',{action='eventChoice',item=item.id,runId=run.id,round=run.round,phase=run.phase})
        say('SHOP：購買 '..tostring(item.label or item.id)..' / '..tostring(item.price))
    else
        if not session.readyAt or now-session.readyAt>3 then
            runSend('eventReady');session.readyAt=now;say('SHOP：選購完成 → DONE')
        end
    end
end
local campSession
local function selectCampOption(options,member)
    local hp=ratio(member,'hp','maxHp')
    if not hp then return nil end
    local rest,sharpen
    for _,option in ipairs(options or {}) do
        if option.enabled~=false then
            if option.id=='rest' then rest=option end
            if option.id=='sharpen' then sharpen=option end
        end
    end
    -- Rest restores 15% HP; at <=85% none of that healing is wasted.
    -- Avoid repeating INSPIRED when it is already present and HP is missing.
    if hp<=85 or (hp<100 and (member.statuses or {}).Inspired) then return rest or sharpen end
    return sharpen or rest
end
local function campTick()
    if not C.Camp or not run or run.phase~='event' or not run.eventData or run.eventData.kind~='camp' then
        campSession=nil;return
    end
    local key=tostring(run.id)..':'..tostring(run.round)
    if not campSession or campSession.key~=key then campSession={key=key} end
    local session=campSession
    for _,id in ipairs(run.eventReady or {}) do if tonumber(id)==player.UserId then return end end
    local chosen=(run.eventChosen or {})[tostring(player.UserId)]==true
    local now=os.clock()
    if chosen then
        if not session.readyAt or now-session.readyAt>3 then
            runSend('eventReady');session.readyAt=now;say('CAMP：選擇已確認 → TO BATTLE')
        end
        return
    end
    if session.sentAt then
        -- Wait for confirmation before sending TO BATTLE or another choice.
        if now-session.sentAt>3 then
            send('RunAction',{action='state'});session.sentAt=now
            say('CAMP：等待伺服器確認選擇')
        end
        return
    end
    local member=localMember(run)
    if not member then say('CAMP：等待角色資料');return end
    local option=selectCampOption(run.eventData.options,member)
    if not option then say('CAMP：等待血量或可用選項');return end
    send('RunAction',{action='eventChoice',option=option.id,runId=run.id,round=run.round,phase=run.phase})
    session.sentAt=now
    say('CAMP：'..tostring(option.label or option.id)..'（HP '..math.floor(ratio(member,'hp','maxHp'))..'%）')
end
local shrineSession
local function shrineChoice(event,member,config)
    local function same(a,b) return tostring(a):lower()==tostring(b):lower() end
    if member.classless then
        for _,class in ipairs(event.classes or {'Warrior','Mage','Thief','Fist','Bard','Archer','Spear'}) do
            local id=type(class)=='table' and class.id or class
            if same(id,config.BaseClass) then return {classId=id},'選擇職業 '..tostring(id) end
        end
        return nil,'指定的初始職業尚未出現在選項中'
    end
    local target=config.SuperClass or ''
    local supers=event.supers and event.supers[member.baseClass]
    if target~='' and not member.superClass and type(supers)=='table' then
        for _,super in ipairs(supers) do
            if type(super)=='table' and (same(super.id,target) or same(super.name,target)) then
                if not super.id or super.enabled==false or super.locked==true then break end
                return {superClass=super.id},'轉職 '..tostring(super.name or super.id)
            end
        end
    end
    return {option='train'},'TRAIN（獲取經驗）'
end
local function shrineTick()
    if not C.Shrine or not run or run.phase~='event' or not run.eventData or run.eventData.kind~='shrine' then
        shrineSession=nil;return
    end
    local key=tostring(run.id)..':'..tostring(run.round)
    if not shrineSession or shrineSession.key~=key then shrineSession={key=key} end
    local session=shrineSession
    for _,id in ipairs(run.eventReady or {}) do if tonumber(id)==player.UserId then return end end
    local now=os.clock()
    if (run.eventChosen or {})[tostring(player.UserId)]==true then
        if not session.readyAt or now-session.readyAt>=3 then
            runSend('eventReady');session.readyAt=now;say('SHRINE：選擇已確認 → TO BATTLE')
        end
        return
    end
    if session.sentAt then
        if now-session.sentAt>=3 then send('RunAction',{action='state'});session.sentAt=now end
        return
    end
    local member=localMember(run)
    if not member then say('SHRINE：等待角色資料');return end
    local choice,reason=shrineChoice(run.eventData,member,C)
    if not choice then say('SHRINE：'..reason);return end
    choice.action='eventChoice';choice.runId=run.id;choice.round=run.round;choice.phase=run.phase
    send('RunAction',choice);session.sentAt=now;say('SHRINE：'..reason)
end
local altarSession
local function altarChoice(options,member,healAt)
    local hp=ratio(member,'hp','maxHp')
    local minHp=math.max(80,(tonumber(healAt) or 45)+20)
    local focused=(member.statuses or {}).Focused
    local desired=(hp and hp>=minHp and not focused) and 'offer' or 'leave'
    local leave
    for _,option in ipairs(options or {}) do
        if option.enabled~=false then
            if option.id=='leave' then leave=option end
            if option.id==desired then return option end
        end
    end
    return leave
end
local function altarTick()
    if not C.Altar or not run or run.phase~='event' or not run.eventData or run.eventData.kind~='altar' then
        altarSession=nil;return
    end
    local key=tostring(run.id)..':'..tostring(run.round)
    if not altarSession or altarSession.key~=key then altarSession={key=key} end
    local session=altarSession
    for _,id in ipairs(run.eventReady or {}) do if tonumber(id)==player.UserId then return end end
    local now=os.clock()
    if (run.eventChosen or {})[tostring(player.UserId)]==true then
        if not session.readyAt or now-session.readyAt>=3 then
            runSend('eventReady');session.readyAt=now;say('BLOOD ALTAR：選擇已確認 → TO BATTLE')
        end
        return
    end
    if session.sentAt then
        if now-session.sentAt>=3 then send('RunAction',{action='state'});session.sentAt=now end
        return
    end
    local member=localMember(run)
    if not member then say('BLOOD ALTAR：等待角色資料');return end
    local option=altarChoice(run.eventData.options,member,C.HealAt)
    if not option then say('BLOOD ALTAR：等待可用選項');return end
    send('RunAction',{action='eventChoice',option=option.id,runId=run.id,round=run.round,phase=run.phase})
    session.sentAt=now;say('BLOOD ALTAR：'..tostring(option.label or option.id))
end
local mysterySession
local function mysteryTick()
    if not C.Continue or not run or run.phase~='event' or not run.eventData
        or (string.lower(tostring(run.eventData.kind))~='mystery'
            and string.lower(tostring(run.eventData.kind))~='scout') then
        mysterySession=nil;return
    end
    local key=tostring(run.id)..':'..tostring(run.round)
    if not mysterySession or mysterySession.key~=key then mysterySession={key=key} end
    for _,id in ipairs(run.eventReady or {}) do
        if tonumber(id)==player.UserId then return end
    end
    local now=os.clock()
    if not mysterySession.sentAt or now-mysterySession.sentAt>=3 then
        runSend('eventReady')
        mysterySession.sentAt=now
        say(string.upper(tostring(run.eventData.kind))..' → TO BATTLE')
    end
end
local function visible(obj)
    if not obj:IsDescendantOf(pg) then return false end
    local p=obj
    while p and p~=pg do
        if p:IsA('GuiObject') and not p.Visible then return false end
        if p:IsA('ScreenGui') and not p.Enabled then return false end
        p=p.Parent
    end
    return obj.AbsoluteSize.X>0 and obj.AbsoluteSize.Y>0
end
local clicked=setmetatable({},{__mode='k'})
local function activate(b)
    if not getconnections then return false end
    local ok,cs=pcall(getconnections,b.Activated)
    if not ok then return false end
    local fired=false
    for _,c in ipairs(cs) do
        if c.Enabled~=false and c.Fire then local yes=pcall(function() c:Fire() end);fired=fired or yes end
    end
    return fired
end
local function buttonText(b)
    local text=b.Text or ''
    if not text:find('%S') then
        local label=b:FindFirstChild('Label')
        if label and (label:IsA('TextLabel') or label:IsA('TextButton')) then text=label.Text end
    end
    return string.upper(text):gsub('<[^>]->',''):gsub('^%s+',''):gsub('%s+$','')
end
--[[
    送出本次房間／投票的準備操作；等待回覆期間每三秒最多重試一次，共三次。
    先記錄請求再送出，避免同步狀態回覆造成重複；不會送出取消準備。
    @param Kind Lobby、Gather 或 Key，分別保存各流程的請求。
    @param Token 房間版本、集合階段或鑰匙提案的識別。
    @param Name 遊戲原生指令名稱。
    @param Payload 由目前伺服器狀態建立的指令資料。
    @param Message 送出後顯示的狀態文字。
]]
local function _SendPartyReady(Kind: string, Token, Name: string, Payload, Message: string): ()
    local Now=os.clock()
    local Request=_Party.Requests[Kind]
    if not Request or Request.Token~=Token then
        Request={Token=Token,Attempts=0}
        _Party.Requests[Kind]=Request
    end
    if Request.Attempts>=3 or (Request.SentAt and Now-Request.SentAt<3) then return end
    Request.Attempts+=1
    Request.SentAt=Now
    send(Name,Payload)
    say(Message)
end

--[[
    每秒最多掃描一次遊戲的兩個準備介面，供腳本較晚啟動時辨識已開啟的房間。
    快取僅含原生 RunReady 按鈕與 LobbyCode；不掃描或觸發 BjzUi 控制項。
    @param Now 本機單調時鐘秒數。
]]
local function _ScanPartyButtons(Now: number): ()
    if Now<_Party.ScanAt then return end
    _Party.ScanAt=Now+1
    table.clear(_Party.Buttons)
    for _,Screen in ipairs(pg:GetChildren()) do
        local bGather=Screen.Name=='PBTravelScreen'
        if Screen:IsA('ScreenGui') and (bGather or Screen.Name=='PlatformBattlesVillage') then
            for _,Object in ipairs(Screen:GetDescendants()) do
                if (Object:IsA('TextButton') and Object.Name=='RunReady')
                    or (not bGather and Object:IsA('GuiObject') and Object.Name=='LobbyCode') then
                    local bInLobby=bGather
                    local Ancestor=Object.Parent
                    while not bInLobby and Ancestor and Ancestor~=Screen do
                        bInLobby=Ancestor.Name=='SetOutWindow'
                        Ancestor=Ancestor.Parent
                    end
                    if bInLobby then
                        table.insert(_Party.Buttons,{Object=Object,Kind=bGather and 'Gather' or 'Lobby'})
                    end
                end
            end
        end
    end
end

--[[
    更新多人等待畫面；只有尚未取得該流程的狀態時才使用晚啟動備援。
    集合直接設定 ready=true；CASTLE 則使用原按鈕保留房間 revision。
    @param bCanReady true 表示玩家已載入且尚未進入冒險／戰鬥。
]]
local function _PartyUiTick(bCanReady: boolean): ()
    _ScanPartyButtons(os.clock())
    _Party.bSurfaceWaiting=false
    for _,Entry in ipairs(_Party.Buttons) do
        local Button=Entry.Object
        if not visible(Button) then continue end
        _Party.bSurfaceWaiting=true
        if not bCanReady or not Button:IsA('TextButton') or not Button.Active
            or Button:GetAttribute('Enabled')==false then continue end
        local Text=buttonText(Button):gsub('%s+',' ')
        if Entry.Kind=='Gather' and C.bAutoRunReady and not _Party.bGatherObserved and Text=='READY!' then
            _SendPartyReady('Gather','gather','RunReady',{ready=true},'多人冒險：已按 READY，等待隊友')
        elseif Entry.Kind=='Lobby' and C.bAutoLobbyReady and not _Party.bLobbyObserved and Text=='READY' then
            local Request=_Party.Requests.LobbyUi
            if not Request or Request.Button~=Button then
                Request={Button=Button,Attempts=0}
                _Party.Requests.LobbyUi=Request
            end
            local Now=os.clock()
            if Request.Attempts<3 and (not Request.SentAt or Now-Request.SentAt>=3) then
                Request.Attempts+=1
                Request.SentAt=Now
                if activate(Button) then say('CASTLE 多人房間：已按 READY')
                else say('CASTLE：等待房間狀態；目前無法觸發原生 READY 按鈕') end
            end
        end
    end
end

--[[
    依 RunLobby、RunGather 與 RunState 各自的原生協定完成多人確認。
    僅對本人的未準備狀態送出 true；鑰匙只同意現有提案，不主動選用物品。
    在既有四分之一秒主迴圈執行，不建立額外工作執行緒。

    使用範例：
    ```lua
    -- 前提：既有 RPGState 監聽器已保存最新房間／集合／冒險狀態。
    -- 主迴圈呼叫後，等待伺服器 ready=true；相同狀態不會每幀重送。
    _PartyTick()
    ```
]]
local function _PartyTick(): ()
    if not C.Battle then return end
    local bCanReady=player:GetAttribute('RPGGameplayReady')==true
        and player:GetAttribute('PBInRun')~=true and not battle
        and player:GetAttribute('InTurnBattle')~=true
        and player:GetAttribute('PlatformBattleActive')~=true
    _PartyUiTick(bCanReady)

    local Lobby=lobbyState
    if C.bAutoLobbyReady and bCanReady and type(Lobby)=='table' and Lobby.state=='lobby'
        and Lobby.fromQueue~=true and tonumber(Lobby.hostUserId) and tonumber(Lobby.hostUserId)~=player.UserId
        and type(Lobby.members)=='table' and #Lobby.members>1 then
        local Member=localMember(Lobby)
        local Revision=Lobby.revision
        if Member and Member.ready==true then
            _Party.Requests.Lobby=nil
        elseif Member and type(Revision)=='number' and Revision>=0 and Revision<math.huge and Revision%1==0 then
            local Token=tostring(Lobby.code)..':'..tostring(Lobby.hostUserId)..':'..tostring(Revision)
            _SendPartyReady('Lobby',Token,'RunLobby',{action='ready',ready=true,revision=Revision},
                'CASTLE 多人房間：已按 READY，等待房主出發')
        end
    end

    local Gather=_Party.Gather
    if C.bAutoRunReady and bCanReady and type(Gather)=='table' and not Gather.closed
        and type(Gather.members)=='table'
        and (tonumber(Gather.expected) or #Gather.members)>1 then
        local Member=localMember(Gather)
        if Member and Member.ready==true then
            _Party.Requests.Gather=nil
        elseif Member and Member.loaded==true then
            _SendPartyReady('Gather','gather','RunReady',{ready=true},'多人冒險：已按 READY，等待隊友')
        end
    end

    if not run or run.active==false or run.phase~='dungeonConfirm' then
        _Party.Requests.Key=nil
        return
    end
    local Offer=run.dungeonOffer
    if not C.bAutoConfirmKey or type(run.members)~='table' or #run.members<2
        or not localMember(run) or not run.id or type(Offer)~='table' or not Offer.id
        or type(Offer.ready)~='table' then return end
    if Offer.ready[tostring(player.UserId)]==true then
        _Party.Requests.Key=nil
        return
    end
    local Token=tostring(run.id)..':'..tostring(run.round)..':'..tostring(Offer.id)
    _SendPartyReady('Key',Token,'RunAction',{
        action='dungeonReady',offerId=Offer.id,runId=run.id,round=run.round,phase=run.phase,
    },'多人鑰匙副本：已同意進入，等待隊友')
end

local function continueUI()
    for _,b in ipairs(pg:GetDescendants()) do
        if b:IsA('TextButton') and not b:IsDescendantOf(gui) and visible(b) and b.Active and b:GetAttribute('Enabled')~=false then
            local text=buttonText(b)
            local bossChest=b.Name=='ChestHit' and b.ZIndex==120
            local chestContinue=text:match('^%s*CONTINUE%s*>%s*$')~=nil
            if bossChest or chestContinue or text=='CONTINUE' or text=='TAP TO CONTINUE' or text=='RETURN TO THE ROAD' or text:match('^%w+ TO CONTINUE$') then
                local last=clicked[b] or 0
                if os.clock()-last>1.5 then
                    clicked[b]=os.clock()
                    if activate(b) then
                        say(bossChest and 'BOSS 寶箱 → 開啟' or (chestContinue and 'BOSS 寶箱獎勵 → CONTINUE' or 'CONTINUE'))
                    else
                        say(bossChest and 'Delta 缺少可用的 getconnections；寶箱需手動開啟。' or 'Delta 缺少可用的 getconnections；CONTINUE 需手動按。')
                    end
                    return
                end
            end
        end
    end
end
local skippedButtons=setmetatable({},{__mode='k'})
local function isSkipButton(name,text)
    text=text:gsub('%s+',' '):gsub('^%s+',''):gsub('%s+$','')
    local bare=text:gsub('%s*[>›»]+%s*$','')
    return bare=='SKIP' or bare=='TAP TO SKIP' or bare=='CLICK TO SKIP'
        or (name:lower()=='skip' and (bare:match('^SKIP%s*%b()$')~=nil
            or bare:match('^[^ ]+ TO SKIP$')~=nil))
end
local function skipTick()
    if not C.Battle or not C.Skip then return end
    for _,b in ipairs(pg:GetDescendants()) do
        if b:IsA('TextButton') and not b:IsDescendantOf(gui) and visible(b) and b.Active
            and b:GetAttribute('Enabled')~=false and isSkipButton(b.Name,buttonText(b)) then
            local now=os.clock()
            if not skippedButtons[b] or now-skippedButtons[b]>=1 then
                skippedButtons[b]=now
                -- Use the animation's own SKIP handler so its completion runs normally.
                if activate(b) then say('動畫 → SKIP')
                else say('SKIP：Delta 無法觸發按鈕，請手動跳過動畫') end
                return
            end
        end
    end
end
--[[
    辨識本局的 TORMENT 等級；優先採用遊戲模組，保留模組未就緒時的識別。
    @param DifficultyId RunState 的本局難度 ID，不以使用者目前選單值取代。
    @return 正整數等級；非 TORMENT 回傳 nil。
]]
local function _GetTormentTier(DifficultyId: string?): number?
    if torment and type(torment.TierOf)=='function' then
        local bOk,Tier=pcall(torment.TierOf,DifficultyId)
        if bOk and type(Tier)=='number' and Tier>=1 and Tier<math.huge and Tier%1==0 then return Tier end
    end
    for _,Difficulty in ipairs(soloDifficulties) do
        if Difficulty.id==DifficultyId and Difficulty.tier then return Difficulty.tier end
    end
    -- Verified TormentConfig.Id format; this only identifies the mode, never unlocks it.
    local Tier=type(DifficultyId)=='string' and tonumber(DifficultyId:match('^torment(%d+)$')) or nil
    return Tier and Tier>=1 and Tier<math.huge and Tier%1==0 and Tier or nil
end

--[[
    建立或更新本次通關的接續目標；相同 run.id 保留重試次數與確認狀態。
    TORMENT 選擇下一級時，僅接受本局 RunState.tormentNext 且須在 OpenTiers 內；未提供則等待。
    選擇重新開始時使用本局難度；送出請求後固定當次選擇，避免重試時切換指令。
    @return 本局接續狀態；沒有勝利的通關資料時回傳 nil。

    使用範例：
    ```lua
    -- 前提：本腳本已收到勝利的 RunState；例：difficulty="torment1", tormentNext=2。
    local Session = _PrepareRestartSession()
    -- Session.NextTier 為 2；difficultyId 由遊戲的 Torment.Id(2) 產生。
    ```
]]
local function _PrepareRestartSession()
    if not run or run.phase~='ended' or run.result~='victory' then return nil end
    local RunId=tostring(run.id)
    if not restartSession or restartSession.runId~=RunId then
        restartSession={runId=RunId,endedAt=os.clock(),attempts=0,
            actIndex=tonumber(run.startAct) or soloActIndex,
            SourceDifficultyId=run.difficulty or soloDifficulties[soloDifficultyIndex].id}
    end
    local Session=restartSession
    if Session.started then return Session end
    Session.SourceDifficultyId=run.difficulty or Session.SourceDifficultyId
    local CurrentTier=_GetTormentTier(Session.SourceDifficultyId)
    if not Session.bModeLocked then Session.TormentAfterVictory=C.TormentAfterVictory end
    Session.bAdvanceTorment=CurrentTier~=nil and Session.TormentAfterVictory=='next'
    if not Session.bAdvanceTorment then
        Session.difficultyId=Session.SourceDifficultyId
        Session.NextTier=nil;Session.PauseReason=nil
        return Session
    end
    local NextTier=tonumber(run.tormentNext)
    local OpenTiers=torment and tonumber(torment.OpenTiers)
    local Target
    if NextTier and OpenTiers and NextTier==CurrentTier+1 and NextTier<=OpenTiers then
        for _,Difficulty in ipairs(soloDifficulties) do
            if Difficulty.tier==NextTier then Target=Difficulty;break end
        end
    end
    Session.NextTier=Target and NextTier or nil
    Session.difficultyId=Target and Target.id or nil
    Session.PauseReason=nil
    if not Target then
        Session.PauseReason=OpenTiers and CurrentTier>=OpenTiers
            and 'TORMENT：已達目前開放的最高級；自動接續暫停。'
            or 'TORMENT：等待遊戲提供有效的下一級入口；不重開同級。'
    end
    return Session
end

--[[
    確認可見按鈕是遊戲的 NextTier，或標籤吻合本次下一級名稱。
    可見性與可用狀態由呼叫端檢查；不因 PLAY AGAIN 同時存在而改成重開。
    @param Button 本局結算畫面的 TextButton。
    @param NextTier 已由 RunState 與 OpenTiers 確認的下一級。
    @return true 表示下一級入口；false 表示其他按鈕。
]]
local function _IsNextTormentButton(Button: TextButton,NextTier: number): boolean
    local Text=buttonText(Button):gsub('%s+',' '):gsub('%s*[>›»]+%s*$','')
    local Expected='NEXT: '..string.upper(tostring(torment.Name(NextTier)))
    return (Button.Name=='NextTier' and Text~='STARTING...' and not Text:match('^WAITING'))
        or Text==Expected
end

--[[
    將 TORMENT 接續目標同步至難度選單、原設定檔及跨服紀錄，不觸發下拉欄回呼。
    必須在傳送請求之前呼叫，讓同步回傳 RunStart 的情況也保存正確目標。
    @param Session 已驗證的接續狀態；一般模式僅更新原有續跑紀錄。
]]
local function _SaveRestartTarget(Session)
    if _GetTormentTier(Session.SourceDifficultyId) and Session.difficultyId then
        for Index,Difficulty in ipairs(soloDifficulties) do
            if Difficulty.id==Session.difficultyId and soloDifficultyIndex~=Index then
                soloDifficultyIndex=Index
                if controls.SoloDifficulty then controls.SoloDifficulty:Set(Index,true) end
                saveSoloSettings()
                return
            end
        end
    end
    if continuationRefresh then continuationRefresh() end
end

--[[
    更新 TORMENT 接續偏好，並立即調整尚未送出請求的通關目標。
    已送出的請求保持原模式，避免等待伺服器時同時投票重開與升級。
    @param Choice next 為下一級，replay 為目前等級；其他值忽略。
]]
_SetTormentAfterVictory=function(Choice: string)
    if Choice~='next' and Choice~='replay' then return end
    C.TormentAfterVictory=Choice
    local Session=restartSession
    if Session and not Session.started and not Session.bModeLocked
        and _GetTormentTier(Session.SourceDifficultyId) then
        Session.TormentAfterVictory=Choice
        if run and tostring(run.id)==Session.runId then
            _PrepareRestartSession()
        elseif Choice=='replay' then
            Session.bAdvanceTorment=false;Session.NextTier=nil;Session.PauseReason=nil
            Session.difficultyId=Session.SourceDifficultyId
        else
            -- After a handoff, no new tier is invented from the old replay target.
            Session.bAdvanceTorment=true;Session.NextTier=nil;Session.difficultyId=nil
            Session.PauseReason='TORMENT：等待遊戲提供有效的下一級入口。'
        end
    end
    saveSoloSettings()
    local Label=Choice=='next' and '進入下一級' or '重新開始目前等級'
    say('TORMENT 通關後：'..Label..(Session and Session.bModeLocked
        and '；本次請求已送出，變更從下一次通關套用。' or '；已保存。'))
end

local function replayTick()
    if not C.Battle or not C.Replay then return end
    if not run or run.phase~='ended' or run.result~='victory' then return end
    local now=os.clock()
    local session=_PrepareRestartSession()
    if not session then return end
    if session.started then return end
    if session.bAdvanceTorment and not session.NextTier then
        say(session.PauseReason or 'TORMENT：等待遊戲提供下一級。');return
    end
    local castleGui=pg:FindFirstChild('PlatformBattlesVillage')
    if castleGui and castleGui.Enabled then return end
    if travelBlockedUntil and now<travelBlockedUntil then return end
    if session.sentAt and now-session.sentAt<5 then return end
    if session.waitingAt and now-session.waitingAt<15 then return end
    if session.attempts>=3 then return end
    for _,b in ipairs(pg:GetDescendants()) do
        -- Match the visible label too: a client update can change the instance name.
        if b:IsA('TextButton') and not b:IsDescendantOf(gui) and visible(b) and b.Active
            and b:GetAttribute('Enabled')~=false then
            local bMatches=session.bAdvanceTorment and _IsNextTormentButton(b,session.NextTier)
                or (not session.bAdvanceTorment and buttonText(b):match('^PLAY AGAIN%s*>?%s*$')~=nil)
            if not bMatches then continue end
            session.sentAt=now;session.attempts=session.attempts+1;session.waitingAt=nil
            session.bModeLocked=true
            -- Mirror the game's NextTier / PlayAgain handlers; one request per attempt.
            -- Save before FireServer: RunStart / teleport can arrive synchronously.
            _SaveRestartTarget(session)
            if session.bAdvanceTorment then
                send('RunLobby',{action='replayNext',tier=session.NextTier})
                say('TORMENT 通關 → '..tostring(torment.Name(session.NextTier))..'（等待伺服器確認）')
            else
                send('RunLobby',{action='replay'})
                say(_GetTormentTier(session.SourceDifficultyId)
                    and 'TORMENT 通關 → 重新開始目前等級（等待伺服器確認）'
                    or '冒險通關 → 申請 PLAY AGAIN（等待伺服器確認）')
            end
            return
        end
    end
end
local function autoEnterTick()
    if not C.Battle then autoCastleSince=nil;return end
    local recovery=C.Replay and restartSession and not restartSession.started
    if recovery and restartSession.bAdvanceTorment and not restartSession.NextTier then
        autoCastleSince=nil
        say(restartSession.PauseReason or 'TORMENT：尚未確認下一級，請在遊戲中選擇。');return
    end
    if not C.AutoEnter and not recovery then autoCastleSince=nil;return end
    local now=os.clock()
    if travelBlockedUntil and now<travelBlockedUntil then return end
    if soloPendingAt and now-soloPendingAt<15 then return end
    local castleGui=pg:FindFirstChild('PlatformBattlesVillage')
    local castleRoot=castleGui and castleGui:FindFirstChild('Village')
    if not castleGui or not castleGui.Enabled or not castleRoot or not visible(castleRoot) then autoCastleSince=nil;return end
    local eligible=soloEligibility(player:GetAttributes(),battle~=nil,lobbyState)
    if not eligible or player:GetAttribute('PBInRun')==true then autoCastleSince=nil;return end
    -- Do not issue a new SOLO request while an ended-run summary or its replay vote is open.
    for _,b in ipairs(pg:GetDescendants()) do
        if b:IsA('TextButton') and not b:IsDescendantOf(gui) and visible(b) then
            local text=buttonText(b)
            if b.Name=='PlayAgain' or b.Name=='NextTier' or text:match('^PLAY AGAIN')
                or text:match('^NEXT:%s*TORMENT') or text:match('^WAITING%s+%d+/%d+') then
                autoCastleSince=nil;return
            end
        end
    end
    autoCastleSince=autoCastleSince or now
    if now-autoCastleSince<3 or now-settingsChangedAt<5 then return end
    if autoSoloAttemptAt and now-autoSoloAttemptAt<15 then return end
    autoSoloAttemptAt=now
    local selection=recovery and {actIndex=restartSession.actIndex,difficultyId=restartSession.difficultyId} or nil
    local RecoverySession=recovery and restartSession or nil
    local bWasLocked=RecoverySession and RecoverySession.bModeLocked==true
    if RecoverySession then
        RecoverySession.bModeLocked=true
        _SaveRestartTarget(RecoverySession)
    end
    local bAdvanceTorment=recovery and restartSession.bAdvanceTorment==true
    if startSolo(selection) then
        if recovery then
            say(bAdvanceTorment and '已返回 CASTLE → 進入下一級 TORMENT'
                or '已返回 CASTLE → 重新進入上一場冒險')
        end
        autoCastleSince=nil
    elseif RecoverySession then
        -- Eligibility / profile checks can reject before a request is submitted.
        RecoverySession.bModeLocked=bWasLocked
        if continuationRefresh then continuationRefresh() end
    end
end
--[[
    QTE 協定驅動：攻擊提交命中數／中心位置，防禦提交每擊中心時間戳。
    不讀取畫面、不模擬按鍵，也不修改共享判定函式；防禦結果仍由伺服器決定。
    Pending 只保留待送資料；qtes 保留本場 token，防止原生流程或重複事件再次提交。
]]
local _Qte={Pending={},Instances=setmetatable({},{__mode='k'}),Installed={},
    Rules={Duration=0.85,MaxLatencyCredit=0.3},WakeThread=nil,WakeAt=nil,bTicking=false}
do
    local RulesModule=shared and shared:FindFirstChild('DefenseTiming')
    if RulesModule then
        local bOk,Rules=pcall(require,RulesModule)
        if bOk and type(Rules)=='table' then _Qte.Rules=Rules end
    end
end

--[[ 讀取有限數值；不完整的選用欄位採原生預設值。 ]]
local function _QteNumber(Value, Default)
    local Number=tonumber(Value)
    return Number and Number==Number and math.abs(Number)<math.huge and Number or Default
end

--[[ 更新獨立診斷欄；「已提交」與伺服器實際回報分開顯示。 ]]
local function _QteReport(Message: string): ()
    if alive and API.QteStatus then API.QteStatus:Set('QTE 判定',Message) end
end

--[[ 檢查此工作仍屬於目前開關、戰鬥版本及 token。 ]]
local function _QteActive(Context): boolean
    return alive and C.Battle and C.QTE and not Context.bCancelled
        and Context.Version==version and qtes[Context.Token]==Context
end

--[[ 取消唯一的延遲喚醒；待送工作另由 Pending 管理。 ]]
local function _CancelQteWake(): ()
    local Thread=_Qte.WakeThread
    _Qte.WakeThread=nil;_Qte.WakeAt=nil
    if Thread then pcall(task.cancel,Thread) end
end

--[[ 停用、離開戰鬥及 Stop 均立即作廢待送工作，不在重新開啟時補送。 ]]
_CancelQtes=function()
    _CancelQteWake()
    for _,Context in pairs(qtes) do Context.bCancelled=true end
    table.clear(_Qte.Pending)
    table.clear(_Qte.Instances)
end
table.insert(restorers,_CancelQtes)

--[[
    依原生送出格式建立攻擊結果，保留原生最短等待及火球逐步預覽。
    @return 依時間排序的封包；nil 表示不支援該事件。
]]
local function _AttackQteSteps(Event: string, Data, Now: number)
    local Steps={}
    local Payload={battleId=tostring(Data.battleId),token=tostring(Data.token)}
    local Delay,Command
    if Event=='WarriorBladeTimingStarted' then
        local Rounds={}
        for Index,Round in ipairs(type(Data.rounds)=='table' and Data.rounds or {}) do
            if Index>5 or type(Round)~='table' then break end
            Rounds[Index]=Round
        end
        if #Rounds==0 then Rounds[1]={} end
        Payload.results={};Delay=0;Command='WarriorBladeTimingResult'
        for Index,Round in ipairs(Rounds) do
            local Position=math.clamp(_QteNumber(Round.targetPosition,0.5),0,1)
            Payload.results[Index]={pressed=true,position=Position}
            -- Reverse changes travel time, not the position reported to the server.
            Delay+=math.max(0.15,_QteNumber(Round.sweepSeconds,1))
                *(Round.reverse==true and 1-Position or Position)+0.32
        end
    elseif Event=='MageRhythmStarted' then
        local Count=math.clamp(type(Data.circles)=='table' and #Data.circles or 0,1,3)
        local Duration=math.clamp(_QteNumber(Data.circleSeconds,0.95),0.15,1.5)
        local Center=(math.clamp(_QteNumber(Data.openWindow,0.72),0.5,0.95)+1)/2
        Delay=0;Command='MageRhythmResult';Payload.hits=Count
        for Index=1,Count do
            Delay+=Duration*Center
            if Data.actionId=='scroll_fireball' then
                table.insert(Steps,{At=Now+Delay,Command=Command,Payload={
                    battleId=Payload.battleId,token=Payload.token,preview=true,step=Index,hits=Index}})
            end
            Delay+=0.25
        end
        Delay=math.max(1.35,Delay)
    elseif Event=='ThiefSlashStarted' then
        local Count=type(Data.targets)=='table' and #Data.targets or 0
        local Maximum=math.clamp(math.floor(_QteNumber(Data.maximumHits,Count)),1,6)
        local Duration=math.clamp(_QteNumber(Data.targetSeconds,0.78),0.15,1.25)
        Payload.hits=math.max(1,math.min(Maximum,Count))
        Delay=math.max(1.1,Maximum*Duration*0.46)+0.08
        Command='ThiefSlashResult'
    else return nil end
    table.insert(Steps,{At=Now+Delay,Command=Command,Payload=Payload,bFinal=true})
    for _,Step in ipairs(Steps) do Step.Expires=Step.At+1 end
    return Steps
end

--[[
    防禦必須等待該擊時間；只送原協定的 pressedAt，不新增不存在的 perfect/outcome 欄位。
    時間戳取伺服器事件的中心，抵消喚醒晚於中心的誤差；伺服器仍會套用 PressTime 限制。
    @return 逐擊封包；必要時間資料不正確時回傳 nil，交回原生流程。
]]
local function _DefenseQteSteps(Data)
    local StartedAt=_QteNumber(Data.startedAt,nil)
    local bBarrage=type(Data.marks)=='table'
    local Marks=bBarrage and Data.marks or {Data.target}
    local Duration=_QteNumber(Data.duration,bBarrage and 2 or (_Qte.Rules.Duration or 0.85))
    if not StartedAt or not Duration or Duration<=0 or #Marks<1 or #Marks>8 then return nil end
    if bBarrage then Duration=math.max(0.2,Duration) end
    local Credit=math.clamp(_QteNumber(_Qte.Rules.MaxLatencyCredit,0.3),0,0.3)
    local Steps={}
    for Index,Mark in ipairs(Marks) do
        local Position=_QteNumber(Mark,nil)
        if not Position then return nil end
        local Center=StartedAt+math.clamp(Position,0,1)*Duration
        if Index>1 and Center<=Steps[Index-1].At then return nil end
        Steps[Index]={At=Center,Expires=Center+Credit,bDefense=true,Strike=Index,
            Command='DefenseTimingInput',Payload={battleId=Data.battleId,token=tostring(Data.token),pressedAt=Center}}
    end
    return Steps
end

local _TickQte
--[[ 只排程下一個到期點；Heartbeat 作備援，無 RenderStepped 依賴與忙碌輪詢。 ]]
local function _ArmQteWake(): ()
    local NextAt
    for _,Context in pairs(_Qte.Pending) do
        local Step=Context.Steps[Context.Next]
        if _QteActive(Context) and Step and (not NextAt or Step.At<NextAt) then NextAt=Step.At end
    end
    if not NextAt then _CancelQteWake();return end
    if _Qte.WakeThread and _Qte.WakeAt==NextAt then return end
    _CancelQteWake();_Qte.WakeAt=NextAt
    -- A small minimum avoids zero-delay rescheduling if server-clock synchronization moves backwards.
    _Qte.WakeThread=task.delay(math.max(0.001,NextAt-workspace:GetServerTimeNow()),function()
        _Qte.WakeThread=nil;_Qte.WakeAt=nil
        local bOk,Error=pcall(_TickQte)
        if not bOk then _QteReport('排程錯誤：'..tostring(Error)) end
    end)
end

--[[ 每個 token 只建立一次；不讓兩個事件監聽器或重播事件重排已完成／取消的工作。 ]]
local function _RegisterQte(Event: string, Data)
    if not alive or not C.Battle or not C.QTE or type(Data)~='table' then return nil end
    if Data.userId and tonumber(Data.userId)~=player.UserId then return nil end
    if (type(Data.token)~='string' and type(Data.token)~='number') or tostring(Data.token)==''
        or (type(Data.battleId)~='string' and type(Data.battleId)~='number') then return nil end
    local Token=tostring(Data.token)
    local Previous=qtes[Token]
    if Previous then
        if Previous.Event==Event and Previous.BattleId==tostring(Data.battleId) then return Previous end
        return nil
    end
    local Steps=Event=='DefenseTimingStarted' and _DefenseQteSteps(Data)
        or (Event~='DefenseTimingStarted' and _AttackQteSteps(Event,Data,workspace:GetServerTimeNow()))
    if type(Steps)~='table' or #Steps==0 then return nil end
    local Context={Token=Token,BattleId=tostring(Data.battleId),Event=Event,Version=version,
        Steps=Steps,Next=1,Sent=0,Skipped=0,bCancelled=false}
    qtes[Token]=Context;_Qte.Pending[Token]=Context
    _QteReport(Event=='DefenseTimingStarted' and ('防禦已排程：'..#Steps..' 擊，等待伺服器判定')
        or '攻擊已排程：直接提交結果')
    _ArmQteWake()
    return Context
end

--[[
    依封包時間逐一提交。連段掉幀跨過多擊時只處理最新到期擊，避免舊包被限時器
    夾到下一擊後誤消耗下一擊；仍未到期的後續擊數保持排程。
]]
_TickQte=function()
    if _Qte.bTicking then return end
    _Qte.bTicking=true
    local bOk,Error=pcall(function()
        local Now=workspace:GetServerTimeNow()
        for Token,Context in pairs(_Qte.Pending) do
            if not _QteActive(Context) then
                Context.bCancelled=true;_Qte.Pending[Token]=nil
            else
                while true do
                    local Step=Context.Steps[Context.Next]
                    if not Step or Step.At>Now then break end
                    local Following=Context.Steps[Context.Next+1]
                    local bExpired=Now>Step.Expires
                    local bOvertaken=Step.bDefense and Following and Following.At<=Now
                    Context.Next+=1 -- Claim before FireServer; reentrant callbacks cannot duplicate it.
                    if bExpired or bOvertaken then
                        Context.Skipped+=1
                        _QteReport('QTE 已錯過 '..Context.Skipped..' 擊／封包；繼續後續排程')
                    else
                        local bSent,SendError=pcall(send,Step.Command,Step.Payload)
                        if bSent then
                            Context.Sent+=1
                            if Step.bFinal then _QteReport('攻擊滿命中資料已提交；最終判定由伺服器處理') end
                        else _QteReport('提交失敗：'..tostring(SendError)) end
                    end
                    if not _QteActive(Context) then break end
                end
                if not Context.Steps[Context.Next] then _Qte.Pending[Token]=nil end
            end
        end
    end)
    _Qte.bTicking=false
    _ArmQteWake()
    if not bOk then error(Error,0) end
end

--[[ 只呈現真正收到的 DefenseTimingResolved，不把本機預測標示為伺服器成功。 ]]
local function _ResolveQte(Data): ()
    if type(Data)~='table' or not Data.token then return end
    if Data.userId and tonumber(Data.userId)~=player.UserId then return end
    local Context=qtes[tostring(Data.token)]
    if not Context or Context.bResolved or (Data.battleId and tostring(Data.battleId)~=Context.BattleId) then return end
    Context.bResolved=true;Context.bCancelled=true;_Qte.Pending[Context.Token]=nil
    local Outcome=type(Data.outcomes)=='table' and Data.outcomes or Data.outcome
    if type(Outcome)=='table' then
        local Dodges=0
        for _,Grade in ipairs(Outcome) do if Grade=='Dodge' then Dodges+=1 end end
        _QteReport('伺服器防禦回報：DODGE '..Dodges..' / '..#Outcome)
    elseif type(Outcome)=='string' then _QteReport('伺服器防禦回報：'..Outcome)
    else _QteReport('防禦已結算；事件未附判定結果') end
    _ArmQteWake()
end

--[[
    接管已辨識的 QTE 起始入口，略過對準面板與原生失敗提交；其他操作保持原方法。
    僅替換特定模組的方法，不安裝全域 __namecall / FireServer / 時鐘 hook。
]]
local function _InstallQteDriver(Module, LegacyEvent): boolean
    if type(Module)~='table' then return false end
    if _Qte.Installed[Module] then return true end
    local Methods
    if LegacyEvent then
        if type(rawget(Module,'Start'))~='function' or type(rawget(Module,'Cancel'))~='function' then return false end
        Methods={Start=LegacyEvent}
    else
        if type(rawget(Module,'_timedMarks'))~='function' or type(rawget(Module,'_run'))~='function'
            or type(rawget(Module,'_pip'))~='function' then return false end
        Methods={_warrior='WarriorBladeTimingStarted',_mage='MageRhythmStarted',_thief='ThiefSlashStarted',
            _timedMarks='ThiefSlashStarted',_defense='DefenseTimingStarted',_barrage='DefenseTimingStarted'}
    end
    local Originals,Wrappers={},{}
    local Cancel=Module.Cancel
    for Name,Event in pairs(Methods) do
        local Original=rawget(Module,Name)
        if type(Original)~='function' then continue end
        Originals[Name]=Original
        Wrappers[Name]=function(Self,Data,...)
            local Context=_RegisterQte(Event,Data)
            if Context then
                if Context.bCancelled then return end
                local Previous=_Qte.Instances[Self]
                if Previous~=Context then
                    if Previous then Previous.bCancelled=true;_Qte.Pending[Previous.Token]=nil end
                    if type(Cancel)=='function' then pcall(Cancel,Self) end
                    _Qte.Instances[Self]=Context
                    Self.token=Context.Token
                end
                return
            end
            return Original(Self,Data,...)
        end
        Module[Name]=Wrappers[Name]
    end
    if type(Cancel)=='function' then
        Originals.Cancel=Cancel
        Wrappers.Cancel=function(Self,...)
            local Context=_Qte.Instances[Self]
            if Context then
                Context.bCancelled=true;_Qte.Pending[Context.Token]=nil;_Qte.Instances[Self]=nil
                _ArmQteWake()
            end
            return Cancel(Self,...)
        end
        Module.Cancel=Wrappers.Cancel
    end
    if type(Module._send)=='function' then
        Originals._send=Module._send
        Wrappers._send=function(Self,Command,Payload)
            local Context=type(Payload)=='table' and qtes[tostring(Payload.token)] or nil
            if alive and C.Battle and C.QTE and Context and Context.Version==version
                and tostring(Payload.battleId)==Context.BattleId
                and (Command=='WarriorBladeTimingResult' or Command=='MageRhythmResult'
                    or Command=='ThiefSlashResult' or Command=='DefenseTimingInput') then return end
            return Originals._send(Self,Command,Payload)
        end
        Module._send=Wrappers._send
    end
    local ResolveName=LegacyEvent=='DefenseTimingStarted' and 'Resolve' or '_defenseResolved'
    if type(Module[ResolveName])=='function' then
        Originals[ResolveName]=Module[ResolveName]
        Wrappers[ResolveName]=function(Self,Data,...)
            _ResolveQte(Data)
            return Originals[ResolveName](Self,Data,...)
        end
        Module[ResolveName]=Wrappers[ResolveName]
    end
    _Qte.Installed[Module]=true
    table.insert(restorers,function()
        for Name,Wrapper in pairs(Wrappers) do
            if Module[Name]==Wrapper then Module[Name]=Originals[Name] end
        end
    end)
    return true
end

--[[ 啟動時探索一次已載入的 PixelQTE 及原遊戲的其他 QTE 呈現模組。 ]]
local function _DiscoverQteDriver(): boolean
    local bFound=false
    if type(getgc)=='function' then
        local bOk,Objects=pcall(getgc,true)
        if bOk then
            for _,Object in pairs(Objects) do
                if type(Object)=='table' and type(rawget(Object,'_timedMarks'))=='function' then
                    bFound=_InstallQteDriver(Object,nil) or bFound
                end
            end
        end
    end
    local Names={PixelQTE=false,MageRhythmClient='MageRhythmStarted',ThiefSlashClient='ThiefSlashStarted',
        WarriorBladeTimingClient='WarriorBladeTimingStarted',DefenseTimingClient='DefenseTimingStarted'}
    local Containers={RS}
    local PlayerScripts=player:FindFirstChild('PlayerScripts')
    if PlayerScripts then table.insert(Containers,1,PlayerScripts) end
    for _,Container in ipairs(Containers) do
        for _,Object in ipairs(Container:GetDescendants()) do
            if Object:IsA('ModuleScript') and Names[Object.Name]~=nil then
                local bOk,Module=pcall(require,Object)
                if bOk then bFound=_InstallQteDriver(Module,Names[Object.Name]) or bFound end
            end
        end
    end
    return bFound
end
_bQteDriver=_DiscoverQteDriver()

--[[ 原生入口與 RPGState 共用同一 token，事件先後順序不會造成重複送出。 ]]
local function _HandleQte(Event: string, Data): ()
    if Event=='DefenseTimingResolved' then _ResolveQte(Data)
    elseif Event=='DefenseTimingStarted' or Event=='WarriorBladeTimingStarted'
        or Event=='MageRhythmStarted' or Event=='ThiefSlashStarted' then
        _RegisterQte(Event,Data)
    end
end

bind(stateRemote.OnClientEvent,function(event,p)
    if event=='Profile' and type(p)=='table' then
        latestProfile=p.profile or p
        _ObserveGearProfile(latestProfile)
    elseif event=='RunLobby' and type(p)=='table' then
        lobbyState=p;_Party.bLobbyObserved=true
        if p.state~='lobby' then _Party.Requests.Lobby=nil end
    elseif event=='RunGather' and type(p)=='table' then
        _Party.Gather=p;_Party.bGatherObserved=true
        if p.closed then _Party.Requests.Gather=nil end
    elseif event=='RunStart' then
        soloPendingAt=os.clock();lobbyState=nil;autoCastleSince=nil
        _Party.Gather=nil;_Party.bGatherObserved=true;_Party.bLobbyObserved=true
        table.clear(_Party.Requests)
        if restartSession then restartSession.started=true end
    elseif event=='RunTravelFailed' then
        soloPendingAt=nil;travelBlockedUntil=os.clock()+15
        _Party.Gather=nil;_Party.bGatherObserved=true;table.clear(_Party.Requests)
        if restartSession then restartSession.started=false end
        say('SOLO：進入失敗，15 秒後重試')
    elseif event=='BattleStarted' or event=='BattleUpdated' then
        if type(p)=='table' then
            battle=p.snapshot or p.battle or p
            pending=false;lastBattle=nil
        end
    elseif event=='BattleEnded' or event=='CharacterWiped' then
        if event=='CharacterWiped' then
            _GearSell.Profile=nil;_GearSell.View=nil;_GearSell.bAwaitFresh=true
            _GearSell.WaitRevision=nil;_GearSell.bDirty=true;table.clear(_GearSell.Attempts)
            restartSession=nil;_Party.Gather=nil;table.clear(_Party.Requests)
        end
        battle=nil;pending=false;version=version+1;if _CancelQtes then _CancelQtes() end;table.clear(qtes)
    elseif event=='RunReplay' and type(p)=='table' then
        if restartSession then
            if p.failed then restartSession.waitingAt=nil;restartSession.lastError=p.message or p.reason
            elseif p.waiting then restartSession.waitingAt=os.clock() end
        end
    elseif event=='RunState' then
        runRevision=runRevision+1
        run=type(p)=='table' and p or nil
        if C.Replay and run and run.phase=='ended' and run.result=='victory' then
            _PrepareRestartSession()
        end
        if run and run.id and run.phase~='ended' and run.active~=false then
            soloPendingAt=nil
            if restartSession and tostring(run.id)~=restartSession.runId then restartSession=nil end
        end
    end
    _HandleQte(event,p)
    if continuationRefresh and (event=='RunStart' or event=='RunTravelFailed' or event=='CharacterWiped'
        or (event=='RunState' and run and run.phase=='ended')) then continuationRefresh() end
end)
bind(RunService.Heartbeat,function()
    if not alive then return end
    local bOk,Error=pcall(_TickQte)
    if not bOk then _QteReport('排程錯誤：'..tostring(Error)) end
end)
-- Recover an already open native lobby once; later changes use RPGState events.
do
    local ExistingLobby=liveLobby()
    if not lobbyState and ExistingLobby and type(ExistingLobby.state)=='table' then
        lobbyState=ExistingLobby.state;_Party.bLobbyObserved=true
    end
end
engineThread=task.spawn(function()
    while alive do
        local ok,err=pcall(function()
            if C.Battle and battle and battle.canAct==true and not pending and os.clock()-sentAt>0.8 then
                local a,payload=chooseAction(battle)
                if a then
                    pending=true;sentAt=os.clock();send('CombatAction',payload)
                    say('行動：'..tostring(a.name or a.id))
                else say('沒有可用行動，等待更新') end
            end
            if pending and os.clock()-sentAt>8 then
                pending=false;send('SyncBattle');sentAt=os.clock()
            end
            if C.Path and run and run.phase=='choose' then
                local key=tostring(run.id)..':'..tostring(run.round)..':'..tostring(run.phase)
                if key~=lastRun then
                    local index,bs,br=nil,-1,-math.huge
                    for i,c in ipairs(run.choices or {}) do
                        local s,r=pathScore(c)
                        if s>bs or (s==bs and r>br) then index,bs,br=i,s,r end
                    end
                    if index then
                        runSend('vote',index);lastRun=key
                        say('路線 '..index..(bs>0 and '：隱藏 BOSS 線索優先' or '：獎勵評分（未公開 BOSS 機率）'))
                    end
                end
            elseif run and run.phase~='choose' then lastRun=nil end
            _GearSellTick()
            _PartyTick()
            shopTick()
            campTick()
            shrineTick()
            altarTick()
            mysteryTick()
            replayTick()
            autoEnterTick()
            skipTick()
            if C.Continue then continueUI() end
        end)
        if not ok then say('錯誤：'..tostring(err)) end
        task.wait(0.25)
    end
end)
local CONTINUATION_BOOTSTRAP=[==[
-- Executed by the executor in the destination client. Parameters are prepended.
local e=getgenv and getgenv() or _G
local ts=game:GetService('TeleportService')
local http=game:GetService('HttpService')
local lockKey
local function fileFunction(name)
    local value=e[name]
    if type(value)=='function' then return value end
    if name=='readfile' then return readfile end
    if name=='writefile' then return writefile end
end
local function log(phase,message)
    local ok,encoded=pcall(function()
        return http:JSONEncode({phase=phase,message=tostring(message or ''),token=TOKEN,
            jobId=game.JobId,placeId=game.PlaceId,at=os.time()})
    end)
    if ok then
        pcall(function() ts:SetTeleportSetting(KEY..':status',encoded) end)
        local write=fileFunction('writefile')
        if type(write)=='function' then pcall(write,BASE..'/ResumeStatus_'..ID..'.json',encoded) end
    end
end
local function readRecord(suffix)
    local raw
    if MODE=='file' then
        local read=fileFunction('readfile')
        assert(type(read)=='function','readfile unavailable after teleport')
        raw=read(BASE..'/'..suffix..'_'..ID..'.json')
    else
        raw=ts:GetTeleportSetting(KEY..':'..suffix)
    end
    assert(type(raw)=='string',suffix..' continuation data missing')
    return http:JSONDecode(raw)
end
local ok,err=pcall(function()
    local existing=e.PixelLineageAuto
    local knownLock=e.__PixelLineageResumeLocks and e.__PixelLineageResumeLocks[tostring(game.JobId)..':'..TOKEN]
    if not (existing and existing.Window and not existing.Window.bDestroyed) and not knownLock then
        log('bootstrap','續跑啟動碼已執行，等待遊戲載入。')
    end
    local deadline=os.clock()+180
    while not game:IsLoaded() do
        assert(os.clock()<deadline,'game load timeout')
        task.wait(0.2)
    end
    if game.GameId~=GAME_ID then return end
    local players=game:GetService('Players')
    while not players.LocalPlayer do
        assert(os.clock()<deadline,'LocalPlayer timeout')
        task.wait(0.2)
    end
    if players.LocalPlayer.UserId~=USER_ID then return end
    -- A manual rerun can supersede an older queued item. Never revive stale data.
    local record
    for attempt=1,5 do
        local valid,value=pcall(readRecord,'Session')
        if valid then record=value;break end
        if attempt==5 then error(value) end
        task.wait(0.2)
    end
    if type(record)~='table' or record.schema~=1 or record.token~=TOKEN or record.active~=true
        or record.userId~=USER_ID or record.gameId~=GAME_ID then return end
    if record.originJobId and record.originJobId~='' and record.originJobId==game.JobId then return end
    e.__PixelLineageResumeLocks=e.__PixelLineageResumeLocks or {}
    lockKey=tostring(game.JobId)..':'..TOKEN
    if e.__PixelLineageResumeLocks[lockKey] then return end
    e.__PixelLineageResumeLocks[lockKey]=true
    local bundle=readRecord('Runtime')
    assert(type(bundle)=='table' and bundle.schema==1 and bundle.token==TOKEN,'runtime cache token mismatch')
    assert(type(bundle.core)=='string' and type(bundle.ui)=='string','runtime cache incomplete')
    e.PixelLineageAutoSource=bundle.core
    e.PixelLineageBjzUiSource=bundle.ui
    e.PixelLineageAutoCarry=record.snapshot
    e.PixelLineageResumeContext={token=TOKEN,jobId=game.JobId}
    log('starting','快取與設定已讀取，等待遊戲物件就緒。')
    local compile=(type(e.loadstring)=='function' and e.loadstring) or loadstring
    assert(type(compile)=='function','loadstring unavailable after teleport')
    local launch,compileError=compile(bundle.core,'@PixelLineageResume')
    assert(launch,compileError)
    local api=launch()
    assert(type(api)=='table' and api.Window and not api.Window.bDestroyed,'runtime did not finish startup')
    if api.Continuation and api.Continuation.Queued then
        log('running','續跑已啟動，並已準備下一次跨服。')
    else
        log('running','續跑已啟動；下一次跨服尚未排程，請查看 SOLO 分頁的續跑狀態。')
    end
end)
if not ok then
    if lockKey and e.__PixelLineageResumeLocks then e.__PixelLineageResumeLocks[lockKey]=nil end
    e.PixelLineageResumeContext=nil
    log('error',err)
    warn('[PixelLineage 跨服續跑] '..tostring(err))
end
]==]
-- Persist sources once; update only the small state record when settings change.
-- No idle polling and no remote/game method interception is needed for continuation.
local continuation={State='preparing',Queued=false,LastError=nil,Provider=nil,Mode=nil}
API.Continuation=continuation
do
    local service=game:GetService('TeleportService')
    local base='BjzUi/PixelLineage'
    local id=tostring(game.GameId)..'_'..tostring(player.UserId)
    local key='BjzUi.PixelLineage.Resume.'..id
    local token=HttpService:GenerateGUID(false)
    local source=env.PixelLineageAutoSource
    local bundle={schema=1,token=token,core=source,ui=bjzUiSource}
    local bootstrap
    local serial=0
    local lastFailureAt=-math.huge
    local filesReady,nativeReady=false,false
    local mode
    local function fs(name)
        if type(env[name])=='function' then return env[name] end
        if name=='readfile' then return readfile end
        if name=='writefile' then return writefile end
        if name=='makefolder' then return makefolder end
    end
    local function log(phase,message)
        local ok,encoded=pcall(function()
            return HttpService:JSONEncode({phase=phase,message=tostring(message or ''),token=token,
                jobId=game.JobId,placeId=game.PlaceId,at=os.time()})
        end)
        if not ok then return end
        pcall(function() service:SetTeleportSetting(key..':status',encoded) end)
        local write=fs('writefile')
        if type(write)=='function' and filesReady then pcall(write,base..'/ResumeStatus_'..id..'.json',encoded) end
    end
    local function report(state,message,err)
        continuation.State=state;continuation.LastError=err
        continuation.Message=message
        if controls.Continuation and not controls.Continuation.bDestroyed then
            controls.Continuation:Set('跨服續跑',message..(err and ('\n'..tostring(err)) or ''))
        end
        log(state,err or message)
    end
    local function prepare()
        filesReady,nativeReady=false,false
        local ok,encoded=pcall(function() return HttpService:JSONEncode(bundle) end)
        if not ok then return false,encoded end
        local read,write,mkdir=fs('readfile'),fs('writefile'),fs('makefolder')
        if type(read)=='function' and type(write)=='function' then
            if type(mkdir)=='function' then pcall(mkdir,'BjzUi');pcall(mkdir,base) end
            filesReady=pcall(function()
                local path=base..'/Runtime_'..id..'.json'
                assert(write(path,encoded)~=false,'runtime cache write rejected')
                assert(read(path)==encoded,'runtime cache verification failed')
            end)
        end
        nativeReady=pcall(function()
            service:SetTeleportSetting(key..':Runtime',encoded)
            assert(service:GetTeleportSetting(key..':Runtime')==encoded,'teleport cache verification failed')
        end)
        mode=filesReady and 'file' or (nativeReady and 'native' or nil)
        continuation.Mode=mode
        continuation.StatusFile=filesReady and (base..'/ResumeStatus_'..id..'.json') or nil
        if not mode then return false,'無法建立本機快取或 TeleportSetting 快取。' end
        -- Both modes use the same short, source-free queued loader.
        bootstrap='local MODE='..string.format('%q',mode)..'; local BASE='..string.format('%q',base)
            ..'; local ID='..string.format('%q',id)..'; local KEY='..string.format('%q',key)
            ..'; local TOKEN='..string.format('%q',token)..'; local GAME_ID='..tostring(game.GameId)
            ..'; local USER_ID='..tostring(player.UserId)..';\n'..CONTINUATION_BOOTSTRAP
        continuation.BootstrapBytes=#bootstrap
        return true
    end
    local function snapshot()
        local options={}
        for name,value in pairs(C) do options[name]=value end
        local restart
        if restartSession and not restartSession.started then
            restart={runId=restartSession.runId,attempts=0,started=false,
                actIndex=restartSession.actIndex,difficultyId=restartSession.difficultyId,
                bAdvanceTorment=restartSession.bAdvanceTorment,SourceDifficultyId=restartSession.SourceDifficultyId,
                NextTier=restartSession.NextTier,PauseReason=restartSession.PauseReason,
                TormentAfterVictory=restartSession.TormentAfterVictory,bModeLocked=restartSession.bModeLocked}
        end
        return {userId=player.UserId,gameId=game.GameId,options=options,
            selection={actId=soloActs[soloActIndex].id,difficultyId=soloDifficulties[soloDifficultyIndex].id,
                autoEnter=C.AutoEnter,replay=C.Replay,tormentAfterVictory=C.TormentAfterVictory,
                bAutoConfirmKey=C.bAutoConfirmKey,bAutoRunReady=C.bAutoRunReady,bAutoLobbyReady=C.bAutoLobbyReady,
                bAutoSellGear=_AutoSellPreference(),GearSellRarity=C.GearSellRarity},restart=restart}
    end
    local function persist(active)
        serial=serial+1
        local record={schema=1,token=token,userId=player.UserId,gameId=game.GameId,
            originJobId=game.JobId,active=active==true,revision=serial,snapshot=snapshot()}
        local ok,encoded=pcall(function() return HttpService:JSONEncode(record) end)
        if not ok then return false,encoded end
        local fileOK,nativeOK=false,false
        if filesReady then
            fileOK=pcall(function()
                local write=fs('writefile')
                assert(type(write)=='function' and write(base..'/Session_'..id..'.json',encoded)~=false,'session write failed')
            end)
        end
        if nativeReady then nativeOK=pcall(function() service:SetTeleportSetting(key..':Session',encoded) end) end
        if (mode=='file' and fileOK) or (mode=='native' and nativeOK) then return true end
        return false,'續跑狀態無法保存；請按「重新設定跨服續跑」重試。'
    end
    local function queueCandidates()
        local out,seen={},{}
        local function add(fn,name)
            if type(fn)=='function' and not seen[fn] then
                seen[fn]=true;out[#out+1]={Function=fn,Name=name}
            end
        end
        add(env.queue_on_teleport,'getgenv.queue_on_teleport')
        add(env.queueonteleport,'getgenv.queueonteleport')
        add(queue_on_teleport,'queue_on_teleport');add(queueonteleport,'queueonteleport')
        for _,entry in ipairs({{'syn',syn},{'delta',delta},{'fluxus',fluxus}}) do
            for _,container in pairs({env[entry[1]],entry[2]}) do
                if type(container)=='table' then
                    add(container.queue_on_teleport,entry[1]..'.queue_on_teleport')
                    add(container.queueonteleport,entry[1]..'.queueonteleport')
                end
            end
        end
        return out
    end
    local function arm(force)
        if not alive then return false end
        if not mode then
            local ok,reason=prepare()
            if not ok then report('error','跨服續跑未就緒。',reason);return false end
        end
        local stored,reason=persist(C.Battle)
        if not stored then report('error','跨服續跑狀態保存失敗。',reason);return false end
        if not C.Battle then report('paused','總開關已關閉；換服後不會自動啟動。');return false end
        if continuation.Queued and not force then return true end
        local candidates=queueCandidates()
        if #candidates==0 then
            report('unsupported','執行器沒有提供跨服排程 API。','新伺服器需手動執行；可在 API 就緒後按下重試。')
            return false
        end
        local errors={}
        for _,entry in ipairs(candidates) do
            local ok,result=pcall(entry.Function,bootstrap)
            if ok and result~=false then
                continuation.Queued=true;continuation.Provider=entry.Name
                report('armed','已預先排程，等待傳送。')
                return true
            end
            errors[#errors+1]=entry.Name..': '..tostring(result)
        end
        continuation.Queued=false
        report('error','執行器拒絕了跨服排程。',table.concat(errors,'\n'))
        return false
    end
    continuationRefresh=function()
        local wasPaused=continuation.State=='paused'
        local ok=arm(false)
        if ok and wasPaused then report('armed','已恢復跨服續跑，等待傳送。') end
        return ok
    end
    continuationStop=function()
        persist(false)
        continuation.Queued=false
        report('stopped','續跑已取消。')
    end
    function API.RearmContinuation()
        if not alive then return false end
        continuation.Queued=false
        local ok,reason=prepare()
        if not ok then report('error','跨服續跑未就緒。',reason);return false end
        return arm(true)
    end
    local function failed(reason)
        if os.clock()-lastFailureAt<1 then return end
        lastFailureAt=os.clock();continuation.Queued=false;continuation.Departing=false
        local armed=arm(true)
        if armed then report('armed','本次傳送失敗；已為下次傳送重新排程。') end
    end
    bind(player.OnTeleport,function(state)
        if state==Enum.TeleportState.Failed then failed('OnTeleport.Failed');return end
        if state==Enum.TeleportState.RequestedFromServer or state==Enum.TeleportState.Started
            or state==Enum.TeleportState.WaitingForServer or state==Enum.TeleportState.InProgress then
            continuation.Departing=true
            if arm(false) then report('departing','正在傳送；已保存最新設定。') end
        end
    end)
    local hasFailureSignal,failureSignal=pcall(function() return service.TeleportInitFailed end)
    if hasFailureSignal and failureSignal then
        bind(failureSignal,function(who,_,message) if who==player then failed(message) end end)
    end
    arm(false)
end

send('RunAction',{action='state'})
send('SyncBattle')
say('v2.13 · BjzUi 已載入；SOLO 設定'..(settingsLoaded and '已讀取' or '使用預設')..'。\nQTE 直接提交：'..(_bQteDriver and '已連接' or '備援')..'；跨服續跑：'..(continuation.Queued and '已排程' or '請查看 SOLO 分頁的續跑狀態'))

env.PixelLineageResumeContext=nil
return API

]====]
local runtime = getgenv and getgenv() or _G
runtime.PixelLineageAutoSource=coreSource
local launch,err=loadstring(coreSource)
assert(launch,err)
return launch()

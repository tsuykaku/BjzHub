-- MuMu PC Native Scheme / Works Prototype / Universal Edge Turn v12.2
-- 以可用的 Works 原型為基礎；四邊持續轉向，不搬動系統游標。
-- 設定依玩家及 GameId 保存在執行器 workspace；支援自動保存、手動保存與載入。
-- 關閉控制立即還原遊戲控制器、人物轉向、相機模式與滑鼠狀態。
-- 維持 PC Native Scheme；對遊戲回報鍵鼠身份，並切換已快取的手機 / 手把控制分支。
-- 身份回報不會產生硬體輸入；實際滑鼠位移仍須由 MuMu 傳入。
-- F8 開關控制；右 Shift 展開 / 最小化設定；關閉視窗會完整卸載。
-- UI 透過 loadstring 載入 BjzUiLibrary；根節點與全部 UI 子物件一律位於 gethui() 容器內。

local Config = {
    Enabled = true,
    SensitivityMultiplier = 1,
    InvertY = false,
    InputMode = "Auto", -- 保留原型：Auto / Event / Delta / Position
    EdgeTurn = true,
    EdgeVertical = true,
    EdgeMargin = 8, -- 四邊各 8 像素的邊界區域
    EdgeSpeed = 120, -- 邊界持續轉向的基準角速度，度 / 秒
    PrototypeCapture = true,
    RivalsSync = true,
    ToggleKey = Enum.KeyCode.F8,
}

local GameId = tonumber(game.GameId) or 0
local PlaceId = tonumber(game.PlaceId) or 0
-- 依 rbxl 的執行中 PlayerScripts/Client 結構辨識，不依賴存檔名稱的 PlaceId。
local LiveScripts = game:GetService("Players").LocalPlayer:FindFirstChild("PlayerScripts")
local LiveClient = LiveScripts and LiveScripts:FindFirstChild("Client")
local IsTWR = LiveClient and LiveClient:IsA("ModuleScript") and LiveClient:FindFirstChild("Animate")
    and LiveClient:FindFirstChild("SpawnDie") and LiveClient:FindFirstChild("EquipUnEquip")
    and game:GetService("ReplicatedStorage"):FindFirstChild("Game Stuff")
local Profile = GameId == 6035872082 and {Name = "RIVALS", Key = "Rivals"} or {Name = "通用遊戲", Key = "Generic"}
if IsTWR then Profile = {Name = "Those Who Remain", Key = "TWR"} end
Config.RivalsSync = Profile.Key == "Rivals"

local LIBRARY_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/refs/heads/main/Library/BjzUiLibrary_2.0.luau"
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer
assert(Player, "請先進入 Rbx 遊戲。")
local PlayerGui = Player:WaitForChild("PlayerGui")
local Env = (type(getgenv) == "function" and getgenv()) or _G
local GetHui = Env.gethui or gethui
assert(type(GetHui) == "function", "目前執行器未提供 gethui()，無法建立 UI。")
local bUIRoot, UIRoot = pcall(GetHui)
assert(bUIRoot and typeof(UIRoot) == "Instance", "gethui() 未回傳有效的 UI 容器。")

local bFetched, Source = pcall(function() return game:HttpGet(LIBRARY_URL) end)
assert(bFetched and type(Source) == "string", "BjzUiLibrary 下載失敗：" .. tostring(Source))
assert(type(loadstring) == "function", "目前執行環境沒有提供 loadstring。")
local Chunk, CompileError = loadstring(Source, "BjzUiLibrary_2.0")
assert(Chunk, "BjzUiLibrary 編譯失敗：" .. tostring(CompileError))
local bLoaded, Library = pcall(Chunk)
assert(bLoaded and type(Library) == "table" and type(Library.CreateWindow) == "function",
    "BjzUiLibrary 載入失敗：" .. tostring(Library))

local SingletonKey = "__MuMuRobloxMouseLook"
local Previous = Env[SingletonKey]
if type(Previous) == "table" and type(Previous.Destroy) == "function" then pcall(Previous.Destroy) end
local Api = {Config = Config, Version = "12.2", UIRoot = UIRoot}
Api.Game = {GameId = GameId, PlaceId = PlaceId, Name = Profile.Name, Key = Profile.Key}
Env[SingletonKey] = Api
local Stats = {
    Events = 0, EventMoves = 0, PollMoves = 0, PositionMoves = 0,
    BridgeCalls = 0, NativeCalls = 0, Relocks = 0,
    LastDX = 0, LastDY = 0, LastSource = "尚無", LastError = "",
    LastRawInput = "尚無", LastTest = "尚未執行", Identity = "尚未設定",
    NativeZeroCalls = 0, ModalCount = 0, ModalBlocked = 0, SensitivityFixes = 0,
    LastPlayLock = "尚未進入捕捉狀態",
}
Api.Stats = Stats

local Connections = {}
local Adapter, Window, EnableToggle, StatusParagraph, InputParagraph, DeviceParagraph, TestParagraph, CaptureParagraph
local bAlive, bFocused, bWritingMouse = true, true, false
local bDiscovering, DiscoveryGeneration = false, 0
local MouseSnapshot, LastPosition
local PendingX, PendingY, bPendingEvent = 0, 0, false
local DiscoveryClock, StatusClock = 1, 0
local BindName = "MuMuWorksEdgeTurn_" .. HttpService:GenerateGUID(false)
local UpdateMouse, UpdateStatus, Discover
local IdentityState, TestProbe
local PlayerAttributeSnapshot
local ModalSnapshots, ModalFailures = {}, {}
local ModalClock, bNeedRelock = 1, true
local ResetSimple, RenderSimple, SimpleBodyParts
local DiscoverRivals, EnsureSimple, RestoreRivals, DiscoverTWR
local Edge = {Direction = 0, DirectionY = 0, Active = false, Seconds = 0, Frames = 0, Status = "等待滑鼠抵達畫面邊界"}
Api.Edge = Edge
local EdgeParagraph, GameParagraph, RivalsParagraph, SettingsParagraph
local SettingControls = {}
local Settings = {Ready = false, Applying = false, Blocked = false, Status = "尚未載入設定", DirtyAt = nil}
Settings.UserId = tonumber(Player.UserId) or 0
Settings.Folder = "MuMu_PC_Native_MouseLook"
Settings.Path = Settings.Folder .. "/" .. tostring(Settings.UserId) .. "_" .. tostring(GameId) .. ".json"
Api.Settings = Settings
local PersistKeys = {"Enabled", "SensitivityMultiplier", "InvertY", "InputMode", "EdgeTurn", "EdgeVertical",
    "EdgeMargin", "EdgeSpeed", "PrototypeCapture", "RivalsSync"}
local DefaultSettings = {}
for _, Key in ipairs(PersistKeys) do DefaultSettings[Key] = Config[Key] end
local ModeLabels = {Auto = "自動", Event = "滑鼠事件", Delta = "位移輪詢", Position = "座標差（備援）"}
local MarkSettingsDirty, ReadSettings, SyncSettingControls
local Rivals = {Camera = nil, Mechanics = nil, Loaded = false, LastTry = -math.huge, Status = "等待辨識"}
local function IsSimple(Current) return Current and Current.Kind and Current.Kind ~= "Hypershot" end

-- MouseEnabled / PreferredInput 是引擎唯讀值。只攔截遊戲讀取 UserInputService 的
-- 結果，不假裝改寫硬體，也不修改 InputObject.UserInputType 或產生虛構滑鼠位移。
local function SetupMouseIdentity()
    local StateKey = "__MuMuMouseIdentityV3"
    local State = Env[StateKey]
    if type(State) == "table" and State.Version == 3 then
        State.Owner, State.bEnabled = Api, Config.Enabled
        IdentityState = State
        Stats.Identity = State.bIndex and "鍵盤 / 滑鼠" or "僅切換遊戲 PC 分支"
        return
    end
    local Hook = Env.hookmetamethod or hookmetamethod
    if type(Hook) ~= "function" then
        Stats.Identity = "執行器未提供 hookmetamethod；僅切換遊戲 PC 分支"
        return
    end
    local Wrap = Env.newcclosure or newcclosure or function(Fn) return Fn end
    local NamecallMethod = Env.getnamecallmethod or getnamecallmethod
    State = {Version = 3, Owner = Api, bEnabled = false, bIndex = false, bNamecall = false}
    local bEnumOk, PreferredMouse = pcall(function() return Enum.PreferredInput.KeyboardAndMouse end)
    local OriginalIndex, OriginalNamecall
    local LastInput = function() return Enum.UserInputType.MouseMovement end
    local NoGamepad = function() return false end
    local NoGamepads = function() return {} end
    local bIndexOk, IndexResult = pcall(Hook, game, "__index", Wrap(function(Self, Key)
        if State.bEnabled and Self == UIS then
            if Key == "MouseEnabled" or Key == "KeyboardEnabled" then return true end
            if Key == "TouchEnabled" or Key == "TouchScreenEnabled" or Key == "GamepadEnabled" then return false end
            if Key == "PreferredInput" and bEnumOk then return PreferredMouse end
            if Key == "GetLastInputType" then return LastInput end
            if Key == "GetGamepadConnected" then return NoGamepad end
            if Key == "GetConnectedGamepads" then return NoGamepads end
        end
        return OriginalIndex(Self, Key)
    end))
    if bIndexOk and type(IndexResult) == "function" then
        OriginalIndex, State.bIndex = IndexResult, true
        State.ReadOriginal = function(Key) return OriginalIndex(UIS, Key) end
    else
        Stats.Identity = "設備讀取攔截不可用；僅切換遊戲 PC 分支"
        return
    end
    if type(NamecallMethod) == "function" then
        local bCallOk, CallResult = pcall(Hook, game, "__namecall", Wrap(function(Self, ...)
            local Method = NamecallMethod()
            if State.bEnabled and Self == UIS then
                if Method == "GetLastInputType" then return Enum.UserInputType.MouseMovement end
                if Method == "GetGamepadConnected" then return false end
                if Method == "GetConnectedGamepads" then return {} end
            end
            return OriginalNamecall(Self, ...)
        end))
        if bCallOk and type(CallResult) == "function" then OriginalNamecall, State.bNamecall = CallResult, true end
    end
    -- 重新執行時沿用同一層 dispatcher；卸載後關閉回報，不堆疊多層 hook。
    State.bEnabled = Config.Enabled
    Env[StateKey], IdentityState = State, State
    Stats.Identity = State.bNamecall and "鍵盤 / 滑鼠" or "鍵鼠屬性（手把方法攔截不可用）"
end

local function ApplyPlayerIdentity()
    if not Config.Enabled then return end
    if not PlayerAttributeSnapshot then
        PlayerAttributeSnapshot = {IsMobile = Player:GetAttribute("IsMobile"), IsPhone = Player:GetAttribute("IsPhone")}
    end
    if Player:GetAttribute("IsMobile") ~= false then Player:SetAttribute("IsMobile", false) end
    if Player:GetAttribute("IsPhone") ~= false then Player:SetAttribute("IsPhone", false) end
end

local function RestorePlayerIdentity()
    if not PlayerAttributeSnapshot then return end
    local Saved = PlayerAttributeSnapshot
    PlayerAttributeSnapshot = nil
    pcall(function()
        Player:SetAttribute("IsMobile", Saved.IsMobile)
        Player:SetAttribute("IsPhone", Saved.IsPhone)
    end)
end

local PCFields = {"IS_MOBILE", "IS_PHONE", "IS_CONSOLE", "IS_XBOX", "ACTIVE_INPUT"}
local function ReleasePCButtons(Current)
    if not Current then return end
    if Current.bOwnMouse then Current.Shared.MouseDown = false Current.bOwnMouse = false end
    if Current.bOwnSprint then Current.Shared.SprintKeyDown = false Current.bOwnSprint = false end
    if Current.bOwnScope then
        Current.Shared.ScopeKeyDown = false
        Current.bOwnScope = false
        if type(Current.Controller.Scope) == "function" then pcall(Current.Controller.Scope, Current.Controller, true) end
    end
end

local function RestorePCMode(Current)
    if IsSimple(Current) or not Current or not Current.bPCMode then return end
    ReleasePCButtons(Current)
    for _, Record in ipairs(Current.PCTables) do
        for _, Key in ipairs(PCFields) do Record.Target[Key] = Record.Saved[Key] end
    end
    for _, Record in ipairs(Current.PCVisibility or {}) do
        pcall(function() Record.Target.Visible = Record.Saved end)
    end
    Current.bPCMode = false
end

local function ApplyPCMode(Current)
    if not Config.Enabled or not Current or IsSimple(Current) then return end
    if not Current.bPCMode then
        for _, Record in ipairs(Current.PCTables) do
            Record.Saved = {}
            for _, Key in ipairs(PCFields) do Record.Saved[Key] = Record.Target[Key] end
        end
        for _, Record in ipairs(Current.PCVisibility or {}) do Record.Saved = Record.Target.Visible end
        Current.bPCMode = true
    end
    for _, Record in ipairs(Current.PCTables) do
        local Target = Record.Target
        Target.IS_MOBILE, Target.IS_PHONE, Target.IS_CONSOLE, Target.IS_XBOX = false, false, false, false
        Target.ACTIVE_INPUT = "PC"
    end
    for _, Record in ipairs(Current.PCVisibility or {}) do Record.Target.Visible = Record.Value end
end

local function InstallPCBindings(Current)
    Current.Actions = {}
    local HandlerModule = Current.Main:FindFirstChild("InputHandler")
    if not HandlerModule then return end
    local Handler = require(HandlerModule)
    assert(type(Handler.BindAction) == "function" and type(Handler.RemoveAction) == "function", "InputHandler 介面不相容")
    Current.InputHandler = Handler
    Current.OriginalBind, Current.OriginalRemove = Handler.BindAction, Handler.RemoveAction
    if Current.bOriginallyMobile then
        local Inputs = Current.Main:FindFirstChild("Inputs")
        local MobileModule = Inputs and Inputs:FindFirstChild("Mobile")
        if MobileModule then
            local bOk, Mobile = pcall(require, MobileModule)
            if bOk and type(Mobile) == "table" then Current.Mobile = Mobile end
        end
        -- 攜帶目前已經綁定的動作，不重新載入 KBM 的永久 InputChanged 監聽。
        local ReadUpvalues = Env.getupvalues or getupvalues or (debug and debug.getupvalues)
        if Current.Mobile and type(ReadUpvalues) == "function" then
            local bOk, Values = pcall(ReadUpvalues, Current.Mobile.BindAction)
            if bOk and type(Values) == "table" then
                for _, Value in pairs(Values) do
                    if type(Value) == "table" then
                        for Name, Callback in pairs(Value) do
                            if type(Name) == "string" and type(Callback) == "function" then Current.Actions[Name] = Callback end
                        end
                    end
                end
            end
        end
    end
    Current.BindWrapper = function(Self, Name, Callback)
        Current.Actions[Name] = Callback
        if not bAlive or Current.bDetached or not Config.Enabled then return Current.OriginalBind(Self, Name, Callback) end
        if Current.bOriginallyMobile then
            if Current.Mobile then return Current.Mobile:BindAction(Name, Callback) end
        else
            return Current.OriginalBind(Self, Name, Callback)
        end
    end
    Current.RemoveWrapper = function(Self, Name)
        Current.Actions[Name] = nil
        if not bAlive or Current.bDetached or not Config.Enabled then return Current.OriginalRemove(Self, Name) end
        if Current.bOriginallyMobile then
            if Current.Mobile then return Current.Mobile:RemoveAction(Name) end
        else
            return Current.OriginalRemove(Self, Name)
        end
    end
    Handler.BindAction, Handler.RemoveAction = Current.BindWrapper, Current.RemoveWrapper
end

local function PCAction(Current, Name, bReleased)
    local Shared, Controller = Current.Shared, Current.Controller
    if not bReleased then
        local Callback = Current.Actions[Name]
        if type(Callback) == "function" then task.spawn(Callback) end
    end
    if Name == "Sprint" then Shared.SprintKeyDown = not bReleased Current.bOwnSprint = not bReleased return end
    if Name == "Scope" then
        Shared.ScopeKeyDown = not bReleased
        Current.bOwnScope = not bReleased
        if type(Controller.Scope) == "function" then Controller:Scope(bReleased or nil) end
        return
    end
    if bReleased then return end
    local Methods = {Zoom = "Zoom", ["Alt Melee"] = "AltMelee", Reload = "Reload", Inspect = "Inspect",
        Crouch = "Crouch", Ping = "Ping", Slide = "Slide", ["Quick Melee"] = "QuickMelee"}
    local Method = Methods[Name]
    if Method and type(Controller[Method]) == "function" then Controller[Method](Controller)
    elseif Name == "Slot 1" or Name == "Slot 2" or Name == "Melee" then
        if type(Controller.Equip) == "function" then Controller:Equip(Name == "Slot 1" and 1 or Name == "Slot 2" and 2 or 3) end
    elseif Name == "Ability 1" or Name == "Ability 2" or Name == "Ability 3" then
        if type(Controller.Ability) == "function" then Controller:Ability(tonumber(Name:sub(-1))) end
    end
end

local function PCKey(Current, Key, bReleased)
    local Binds = Current.Shared.MenuCoreData and Current.Shared.MenuCoreData.Keybinds or {}
    for Name, Keys in pairs(Binds) do
        if type(Keys) == "table" then
            for _, Bound in pairs(Keys) do
                if Bound ~= "" and Bound == Key then PCAction(Current, Name, bReleased) break end
            end
        end
    end
    if Key == "K" and not bReleased and type(Current.Controller.ToggleSettingsFrame) == "function" then
        Current.Controller:ToggleSettingsFrame()
    end
end

local function Connect(Signal, Callback)
    local Connection = Signal:Connect(Callback)
    Connections[#Connections + 1] = Connection
    return Connection
end

local function ClearPending()
    PendingX, PendingY, bPendingEvent = 0, 0, false
end

local function IsFinite(Value)
    return type(Value) == "number" and Value == Value and math.abs(Value) < 1e12
end

local function AdapterValid(Current)
    if Current and Current.Kind == "TWR" then
        return not Current.bDetached and Current.Main:IsDescendantOf(Player) and Workspace.CurrentCamera ~= nil
    end
    if IsSimple(Current) then return not Current.bDetached and Workspace.CurrentCamera ~= nil end
    return Current ~= nil and Current.Main:IsDescendantOf(PlayerGui)
        and Current.FirstPerson:IsDescendantOf(PlayerGui)
        and Current.Main.Parent ~= nil and Current.Main.Parent.Enabled ~= false
end

local function Gate()
    if not bAlive then return false, "已卸載" end
    if not Config.Enabled then return false, "控制已關閉" end
    if not AdapterValid(Adapter) then return false, "等待角色與相機" end
    if not bFocused then return false, "視窗未取得焦點" end
    if GuiService.MenuIsOpen then return false, "Rbx 選單開啟中" end
    if UIS:GetFocusedTextBox() then return false, "文字輸入中" end
    if Window and Window.bVisible then return false, "設定展開中；最小化後恢復" end
    if Adapter.Kind == "TWR" then
        local Current = Adapter
        local Temp = Player:FindFirstChild("TempStats")
        local Spawned = Temp and Temp:FindFirstChild("Spawned")
        if not Spawned or not Spawned.Value then return false, "等待進入戰局；大廳與觀戰使用原控制" end
        local Main = PlayerGui:FindFirstChild("Main")
        local Aligned = Main and Main:FindFirstChild("Aligned")
        local Center = Aligned and Aligned:FindFirstChild("Center")
        local Summary = Center and Center:FindFirstChild("RoundSummary")
        if Summary and Summary.Visible then return false, "回合結算中" end
        if type(Current.Gui.BossIntroPlaying) == "function" and Current.Gui.BossIntroPlaying() then
            return false, "Boss 介紹中"
        end
        if type(Current.Gui.GetOpenedFrame) == "function" then
            local Frame = Current.Gui.GetOpenedFrame()
            if Frame and Frame ~= "" and Frame ~= "HUD" and Frame ~= "Game" then
                return false, "遊戲選單開啟中：" .. tostring(Frame)
            end
        end
        local File = Current.Client.GetPlayerFile()
        if type(File) ~= "table" or type(File.Angle) ~= "table" then return false, "等待遊戲角度資料" end
        if File.GunnerInfo and File.GunnerInfo.Mounted then return false, "固定機槍使用遊戲原控制" end
        local _, Humanoid = SimpleBodyParts()
        if not Humanoid or Humanoid.Health <= 0 then return false, "等待重生" end
        return true, "Those Who Remain 原生角度控制中"
    end
    if IsSimple(Adapter) then
        local Root, Humanoid = SimpleBodyParts()
        if not Root or not Humanoid or not Root.Parent or Humanoid.Health <= 0 then return false, "等待可控制角色" end
        if Root.Anchored or Humanoid.Sit or Humanoid.PlatformStand then return false, "角色目前無法同步轉向" end
        return true, "角色與視角控制中"
    end
    if Adapter.Shared.Dead then return false, "等待角色重生" end
    if Adapter.Shared.MouseLocked == false then return false, "遊戲選單已釋放滑鼠" end
    if type(Adapter.ActionHandler.IsLocalPlayer) == "function"
        and not Adapter.ActionHandler:IsLocalPlayer() then
        return false, "目前為選單或觀戰狀態"
    end
    return true, "控制啟用中"
end

local function RestoreModals()
    for Object, Value in pairs(ModalSnapshots) do pcall(function() Object.Modal = Value end) end
    ModalSnapshots = {}
    Stats.ModalCount = 0
end

local function EffectivelyVisible(Object)
    local Node, Depth = Object, 0
    while Node and Depth < 80 do
        -- 系統提示由 Rbx 管理；遊戲控制只處理一般遊戲 / 執行器介面。
        if Node.Name == "RobloxPromptGui" or Node.Name == "PurchasePrompt" then return false end
        if Node:IsA("GuiObject") and not Node.Visible then return false end
        if Node:IsA("LayerCollector") and not Node.Enabled then return false end
        if Node == PlayerGui or Node == CoreGui or Node == UIRoot then return true end
        Node, Depth = Node.Parent, Depth + 1
    end
    return false
end

local function SuppressVisibleModals()
    if not Gate() then RestoreModals() return end
    for _, Root in ipairs({PlayerGui, CoreGui, UIRoot}) do
        local bOk, Objects = pcall(function() return Root:GetDescendants() end)
        if bOk then
            for _, Object in ipairs(Objects) do
                if Object:IsA("GuiButton") and not ModalFailures[Object] then
                    local bRead, bBlocking = pcall(function() return Object.Modal and EffectivelyVisible(Object) end)
                    if bRead and bBlocking then
                        local bSet = pcall(function() Object.Modal = false end)
                        if bSet then
                            ModalSnapshots[Object] = true
                            bNeedRelock = true
                        else
                            ModalFailures[Object] = true
                            Stats.ModalBlocked = Stats.ModalBlocked + 1
                        end
                    end
                end
            end
        end
    end
    local Count = 0
    for Object in pairs(ModalSnapshots) do
        if Object.Parent then Count = Count + 1 else ModalSnapshots[Object] = nil end
    end
    Stats.ModalCount = Count
end

local function RestoreMouse()
    RestoreModals()
    if not MouseSnapshot then return end
    local Saved = MouseSnapshot
    MouseSnapshot = nil
    bWritingMouse = true
    pcall(function()
        if Saved.bOwnSensitivity and UIS.MouseDeltaSensitivity == 1 then
            UIS.MouseDeltaSensitivity = Saved.SensitivityBeforeCorrection
        end
        UIS.MouseBehavior = Saved.Behavior
        UIS.MouseIconEnabled = Saved.Icon
    end)
    bWritingMouse = false
    LastPosition = nil
end

UpdateMouse = function()
    if bWritingMouse then return end
    if not bAlive or not Config.Enabled or not AdapterValid(Adapter) then
        RestoreMouse()
        return
    end
    local bControl = Gate()
    if not bControl then RestoreModals() end
    local Desired = bControl and Config.PrototypeCapture and Enum.MouseBehavior.LockCenter or Enum.MouseBehavior.Default
    if not MouseSnapshot then
        MouseSnapshot = {Behavior = UIS.MouseBehavior, Icon = UIS.MouseIconEnabled}
        LastPosition = nil
    end
    bWritingMouse = true
    local bOk, Err = pcall(function()
        if bControl and UIS.MouseDeltaSensitivity == 0 then
            -- 引擎靈敏度為 0 時，MouseMovement 和 GetMouseDelta 都會回報零。
            if not MouseSnapshot.bOwnSensitivity then MouseSnapshot.SensitivityBeforeCorrection = 0 end
            MouseSnapshot.bOwnSensitivity = true
            UIS.MouseDeltaSensitivity = 1
            Stats.SensitivityFixes = Stats.SensitivityFixes + 1
        elseif not bControl and MouseSnapshot.bOwnSensitivity then
            if UIS.MouseDeltaSensitivity == 1 then UIS.MouseDeltaSensitivity = MouseSnapshot.SensitivityBeforeCorrection end
            MouseSnapshot.bOwnSensitivity = false
        end
        if bControl and bNeedRelock then
            -- 一次性重新申請捕捉；不在每個 Heartbeat 持續解除再鎖定。
            bNeedRelock = false
            UIS.MouseBehavior = Enum.MouseBehavior.Default
            LastPosition = nil
        end
        if UIS.MouseBehavior ~= Desired then
            if Desired == Enum.MouseBehavior.LockCenter then Stats.Relocks = Stats.Relocks + 1 end
            UIS.MouseBehavior = Desired
        end
        UIS.MouseIconEnabled = not bControl
    end)
    bWritingMouse = false
    if not bOk then error(Err, 0) end
end

local function Detach()
    local Current = Adapter
    Adapter = nil
    if Current and ResetSimple then ResetSimple(Current) end
    if Current then
        if Current.Kind == "TWR" and Current.Animate.AddAngle == Current.AngleWrapper then
            Current.Animate.AddAngle = Current.OriginalAngle
        end
        Current.bDetached = true
        RestorePCMode(Current)
        if Current.InputHandler then
            if Current.InputHandler.BindAction == Current.BindWrapper then Current.InputHandler.BindAction = Current.OriginalBind end
            if Current.InputHandler.RemoveAction == Current.RemoveWrapper then Current.InputHandler.RemoveAction = Current.OriginalRemove end
        end
        if Current.Controller.UpdateCamRot == Current.Wrapper then
            Current.Controller.UpdateCamRot = Current.Original
        end
        if Current.ScriptEnv and Current.ScriptEnv.LockMouse == Current.LockWrapper then
            pcall(function() Current.ScriptEnv.LockMouse = Current.OriginalLockMouse end)
        end
    end
    ClearPending()
    LastPosition = nil
    RestoreMouse()
end

local function Attach(Main, FirstPerson, Shared, Controller, ActionHandler)
    Detach()
    local Current = {
        Kind = "Hypershot", Main = Main, FirstPerson = FirstPerson, Shared = Shared,
        Controller = Controller, ActionHandler = ActionHandler,
        Original = Controller.UpdateCamRot, NativeSinceFlush = 0,
        bForwarding = false, bDetached = false,
        bOriginallyMobile = Shared.IS_MOBILE == true, PCTables = {{Target = Shared}}, PCVisibility = {}, bPCMode = false,
    }
    for Name, Value in pairs({MobileButtons = false, Controls = true}) do
        local Object = Main.Parent:FindFirstChild(Name)
        if Object and Object:IsA("GuiObject") then
            Current.PCVisibility[#Current.PCVisibility + 1] = {Target = Object, Value = Value}
        end
    end
    if type(Shared.MenuShared) == "table" and Shared.MenuShared ~= Shared then
        Current.PCTables[#Current.PCTables + 1] = {Target = Shared.MenuShared}
    end
    local ActionModule = FirstPerson:FindFirstChild("ActionHandler")
    local ActionSharedModule = ActionModule and ActionModule:FindFirstChild("Shared")
    if ActionSharedModule then
        local bOk, ActionShared = pcall(require, ActionSharedModule)
        if bOk and type(ActionShared) == "table" and ActionShared ~= Shared then
            Current.PCTables[#Current.PCTables + 1] = {Target = ActionShared}
        end
    end
    InstallPCBindings(Current)
    ApplyPCMode(Current)
    Current.Wrapper = function(Self, DX, DY, ...)
        if not bAlive or Current.bDetached or not Config.Enabled or Current.bForwarding then
            return Current.Original(Self, DX, DY, ...)
        end
        -- MuMu 可能送出 MouseMovement 但 Delta=(0,0)。零位移不能算成已處理，
        -- 否則 Flush 會忽略真正有改變的座標差，正是 v3 的問題。
        local bMoved = IsFinite(DX) and IsFinite(DY) and (DX ~= 0 or DY ~= 0)
        if not bMoved then Stats.NativeZeroCalls = Stats.NativeZeroCalls + 1 end
        if not Gate() then return end
        if bMoved then
            Current.NativeSinceFlush = Current.NativeSinceFlush + 1
            Current.NativeXSinceFlush = (Current.NativeXSinceFlush or 0) + math.abs(DX)
            Current.NativeYSinceFlush = (Current.NativeYSinceFlush or 0) + math.abs(DY)
            Stats.NativeCalls = Stats.NativeCalls + 1
            Current.Shared.LastMouseInput = tick()
        end
        return Current.Original(Self, DX * Config.SensitivityMultiplier,
            DY * Config.SensitivityMultiplier * (Config.InvertY and -1 or 1), ...)
    end
    Controller.UpdateCamRot = Current.Wrapper
    Adapter = Current
    -- 若 Delta 提供 getsenv，直接替換該 LocalScript 的 LockMouse，避免 Android
    -- 每個 Heartbeat 先解除捕捉再重新捕捉。不可用時仍由 MouseBehavior 屬性監聽處理。
    local GetScriptEnv = Env.getsenv or getsenv
    if type(GetScriptEnv) == "function" then
        local bEnvOk, ScriptEnv = pcall(GetScriptEnv, Main)
        if bEnvOk and type(ScriptEnv) == "table" and type(ScriptEnv.LockMouse) == "function" then
            Current.ScriptEnv, Current.OriginalLockMouse = ScriptEnv, ScriptEnv.LockMouse
            Current.LockWrapper = function(...)
                if not bAlive or Current.bDetached or not Config.Enabled then
                    return Current.OriginalLockMouse(...)
                end
                local bOk, Err = pcall(UpdateMouse)
                if not bOk then
                    Stats.LastError = tostring(Err)
                    Config.Enabled = false
                    RestoreMouse()
                    return Current.OriginalLockMouse(...)
                end
            end
            local bPatched = pcall(function() ScriptEnv.LockMouse = Current.LockWrapper end)
            if not bPatched then Current.ScriptEnv = nil end
        end
    end
    Stats.LastError = ""
end

local function ResetEdge(Reason)
    Edge.Direction, Edge.DirectionY, Edge.Active = 0, 0, false
    Edge.Status = Reason or "等待滑鼠抵達畫面邊界"
end

local function EdgeDelta(DT, DX, DY, NativeX, NativeY)
    if not Config.EdgeTurn then ResetEdge("邊界持續轉向已關閉") return 0, 0 end
    local Position, Camera = Edge.Position, Workspace.CurrentCamera
    if not Position or not Camera then ResetEdge("等待有效游標座標") return 0, 0 end
    local Size = Camera.ViewportSize
    if not IsFinite(Size.X) or not IsFinite(Size.Y) or Size.X < 16 or Size.Y < 16
        or Position.X < 0 or Position.X > Size.X or Position.Y < 0 or Position.Y > Size.Y then
        ResetEdge("游標不在遊戲畫面內") return 0, 0
    end
    local Margin = math.clamp(tonumber(Config.EdgeMargin) or 8, 1, math.min(64, Size.X / 4, Size.Y / 4))
    local Direction = Position.X <= Margin and -1 or (Position.X >= Size.X - 1 - Margin and 1 or 0)
    local DirectionY = Config.EdgeVertical and (Position.Y <= Margin and -1 or (Position.Y >= Size.Y - 1 - Margin and 1 or 0)) or 0
    if Direction == 0 and DirectionY == 0 then ResetEdge() return 0, 0 end
    -- 逐軸優先使用有效原生位移；其中一軸仍在移動，不影響另一軸的邊界轉向。
    -- 不依賴 MouseMovement 事件持續觸發，游標停在邊界仍可每幀轉動。
    if DX ~= 0 or NativeX > 0 then Direction = 0 end
    if DY ~= 0 or NativeY > 0 then DirectionY = 0 end
    if Direction == 0 and DirectionY == 0 then
        ResetEdge("已到邊界；優先使用實際滑鼠位移") return 0, 0
    end
    local Step = IsFinite(DT) and math.clamp(DT, 0, 0.1) or 0
    if Step == 0 then ResetEdge("等待下一幀") return 0, 0 end
    local Speed = math.clamp(tonumber(Config.EdgeSpeed) or 120, 15, 360)
    Edge.Direction, Edge.DirectionY, Edge.Active = Direction, DirectionY, true
    Edge.Seconds, Edge.Frames = Edge.Seconds + Step, Edge.Frames + 1
    local Directions = {}
    if Direction ~= 0 then Directions[#Directions + 1] = Direction < 0 and "左" or "右" end
    if DirectionY ~= 0 then Directions[#Directions + 1] = DirectionY < 0 and "上" or "下" end
    Edge.Status = table.concat(Directions, "／") .. "邊界：持續轉向；移回畫面內即可停止"
    return Direction * math.rad(Speed) * Step, DirectionY * math.rad(Speed) * Step
end

SimpleBodyParts = function()
    if Profile.Key == "Rivals" and Config.RivalsSync then
        local Fighter = Rivals.Mechanics and Rivals.Mechanics.LocalFighter
        if not Fighter and Rivals.Camera and type(Rivals.Camera.GetCurrentSubject) == "function" then
            local OK, Value = pcall(Rivals.Camera.GetCurrentSubject, Rivals.Camera)
            if OK and Value and Value.IsLocalPlayer == true then Fighter = Value end
        end
        local Entity = Fighter and Fighter.Entity
        if Entity and Entity.RootPart and Entity.RootPart.Parent and Entity.Humanoid then
            return Entity.RootPart, Entity.Humanoid, Entity.Head or Entity.RootPart.Parent:FindFirstChild("Head")
        end
    end
    local Character = Player.Character
    if not Character then return nil end
    local Humanoid = Character:FindFirstChildOfClass("Humanoid")
    local Root = Character:FindFirstChild("HumanoidRootPart") or (Humanoid and Humanoid.RootPart) or Character.PrimaryPart
    return Root, Humanoid, Character:FindFirstChild("Head")
end

ResetSimple = function(Current)
    if not IsSimple(Current) then return end
    if Current.BodySaved then
        pcall(function() Current.BodySaved.Humanoid.AutoRotate = Current.BodySaved.AutoRotate end)
        Current.BodySaved = nil
    end
    if Current.HeadSaved then
        pcall(function() Current.HeadSaved.Head.LocalTransparencyModifier = Current.HeadSaved.Value end)
        Current.HeadSaved = nil
    end
    if Current.CameraSaved then
        local Saved = Current.CameraSaved
        pcall(function()
            if Saved.Camera.CameraType == Enum.CameraType.Scriptable then Saved.Camera.CameraType = Saved.Type end
        end)
        Current.CameraSaved = nil
    end
    Current.Yaw, Current.Pitch, Current.LastWritten, Current.UseGameCamera = nil, nil, nil, false
end

local function SeedSimple(Current)
    if Current.Yaw ~= nil then return end
    local Look = Workspace.CurrentCamera.CFrame.LookVector
    Current.Yaw = math.atan2(-Look.X, -Look.Z)
    Current.Pitch = math.asin(math.clamp(Look.Y, -1, 1))
end

EnsureSimple = function()
    if Adapter and IsSimple(Adapter) then return end
    Detach()
    local Current = {Kind = Profile.Key == "Rivals" and "Rivals" or "Generic", Label = "通用角色相機",
        Shared = {IS_MOBILE = false, IS_CONSOLE = false, ACTIVE_INPUT = "PC"},
        ActionHandler = {}, NativeSinceFlush = 0, bOriginallyMobile = false}
    Current.Controller = {}
    Current.Controller.UpdateCamRot = function(_, DX, DY)
        SeedSimple(Current)
        local GameCamera = Config.RivalsSync and Profile.Key == "Rivals" and Rivals.Camera
        local State
        if GameCamera and not GameCamera.IsFrozen then
            local OK, Value = pcall(GameCamera.GetPublicState, GameCamera)
            if OK then State = Value end
        end
        if GameCamera and State and State ~= GameCamera.CameraState.States.CustomFreecam
            and State ~= GameCamera.CameraState.States.ThirdPersonUnlockedMouse then
            Current.BeforeLook = Workspace.CurrentCamera.CFrame.LookVector
            Rivals.Injecting = true
            local OK, Error = pcall(GameCamera.ApplyRotationDelta, GameCamera, Vector2.new(-DY, -DX))
            Rivals.Injecting = false
            if not OK then error(Error, 0) end
            Current.Yaw, Current.Pitch = GameCamera.Rotation.Y, GameCamera.Rotation.X
            Current.UseGameCamera, Current.HadInput = true, true
            Current.Label = "RIVALS 遊戲角度同步"
        else
            Current.Yaw = (Current.Yaw - DX + math.pi) % (math.pi * 2) - math.pi
            Current.Pitch = math.clamp(Current.Pitch - DY, -math.rad(85), math.rad(85))
            Current.UseGameCamera = false
        end
    end
    Current.Original = Current.Controller.UpdateCamRot
    Current.ActionHandler.IsLocalPlayer = function() return true end
    Adapter = Current
end

RenderSimple = function(Current)
    if Current.Kind == "TWR" then return end -- 遊戲自行套用 Angle、後座力、武器動畫與人物朝向。
    local Camera = Workspace.CurrentCamera
    local Root, Humanoid, Head = SimpleBodyParts()
    if not Root or not Humanoid then return end
    SeedSimple(Current)
    if Current.UseGameCamera and Current.HadInput then
        local Expected = (CFrame.Angles(0, Current.Yaw, 0) * CFrame.Angles(Current.Pitch, 0, 0)).LookVector
        local Look = Camera.CFrame.LookVector
        local Wanted = math.acos(math.clamp(Current.BeforeLook:Dot(Expected), -1, 1))
        local Actual = math.acos(math.clamp(Current.BeforeLook:Dot(Look), -1, 1))
        if Wanted > math.rad(0.1) and Actual < Wanted * 0.2 then
            Current.UseGameCamera = false
            Rivals.Status = "遊戲鏡頭未跟上；使用角色綁定相機"
        else Rivals.Status = "RIVALS 鏡頭與角色同步" end
        Current.HadInput = false
    end
    if Current.BodySaved and Current.BodySaved.Humanoid ~= Humanoid then ResetSimple(Current) SeedSimple(Current) end
    if not Current.BodySaved then Current.BodySaved = {Humanoid = Humanoid, AutoRotate = Humanoid.AutoRotate} end
    local Yaw = Current.UseGameCamera and math.atan2(-Camera.CFrame.LookVector.X, -Camera.CFrame.LookVector.Z) or Current.Yaw
    Humanoid.AutoRotate = false
    Root.CFrame = CFrame.new(Root.Position) * CFrame.Angles(0, Yaw, 0)
    if Current.UseGameCamera then return end
    if Current.CameraSaved and Current.CameraSaved.Camera ~= Camera then ResetSimple(Current) SeedSimple(Current) end
    if not Current.CameraSaved then Current.CameraSaved = {Camera = Camera, Type = Camera.CameraType, CFrame = Camera.CFrame} end
    local Position = Head and Head.Position + Vector3.new(0, 0.1, 0) or Root.Position + Vector3.new(0, 1.5, 0)
    if Head then
        if not Current.HeadSaved then Current.HeadSaved = {Head = Head, Value = Head.LocalTransparencyModifier} end
        Head.LocalTransparencyModifier = 1
    end
    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = CFrame.new(Position) * CFrame.Angles(0, Current.Yaw, 0) * CFrame.Angles(Current.Pitch, 0, 0)
    Current.LastWritten = Camera.CFrame
    if Profile.Key == "Rivals" and Config.RivalsSync and Rivals.Camera then
        pcall(Rivals.Camera.SetRotation, Rivals.Camera, Vector2.new(Current.Pitch, Current.Yaw))
    end
end

DiscoverRivals = function()
    if not Config.Enabled or Profile.Key ~= "Rivals" or Rivals.Loaded or os.clock() - Rivals.LastTry < 3 then return end
    Rivals.LastTry = os.clock()
    local Scripts = Player:FindFirstChild("PlayerScripts")
    local Controllers = Scripts and Scripts:FindFirstChild("Controllers")
    if not Controllers then return end
    local CameraModule = Controllers:FindFirstChild("CameraController")
    if not CameraModule or not CameraModule:FindFirstChild("CameraState") then return end
    Rivals.Loaded = true
    local Generation = DiscoveryGeneration
    task.spawn(function()
        local OK, Camera = pcall(require, CameraModule)
        local MechanicsModule = Controllers:FindFirstChild("MechanicsController")
        local Mechanics
        if MechanicsModule then
            local HasMechanics, Value = pcall(require, MechanicsModule)
            if HasMechanics and type(Value) == "table" then Mechanics = Value end
        end
        if not bAlive or not Config.Enabled or Generation ~= DiscoveryGeneration then return end
        Rivals.Mechanics = Mechanics
        if OK and type(Camera) == "table" and type(Camera.ApplyRotationDelta) == "function"
            and type(Camera.GetPublicState) == "function" and type(Camera.SetRotation) == "function" and Camera.CameraState then
            Rivals.Camera, Rivals.Status = Camera, "RIVALS 控制器已載入"
            local Original = Camera.ApplyRotationDelta
            local Wrapper = function(Self, Delta, ...)
                local Result = Original(Self, Delta, ...)
                local Current = Adapter
                if not Rivals.Injecting and Config.Enabled and Config.RivalsSync and IsSimple(Current) and Gate()
                    and Delta and IsFinite(Delta.X) and IsFinite(Delta.Y) and (Delta.X ~= 0 or Delta.Y ~= 0) then
                    Current.NativeSinceFlush = Current.NativeSinceFlush + 1
                    Current.NativeXSinceFlush = (Current.NativeXSinceFlush or 0) + math.abs(Delta.Y)
                    Current.NativeYSinceFlush = (Current.NativeYSinceFlush or 0) + math.abs(Delta.X)
                    Stats.NativeCalls = Stats.NativeCalls + 1
                    Current.Yaw, Current.Pitch = Self.Rotation.Y, Self.Rotation.X
                    Current.UseGameCamera = true
                end
                return Result
            end
            Rivals.OriginalApply, Rivals.ApplyWrapper = Original, Wrapper
            Camera.ApplyRotationDelta = Wrapper
        else Rivals.Status = "保留通用角色相機；RIVALS 角度介面尚未可用" end
    end)
end


RestoreRivals = function()
    if Rivals.Camera and Rivals.Camera.ApplyRotationDelta == Rivals.ApplyWrapper then
        Rivals.Camera.ApplyRotationDelta = Rivals.OriginalApply
    end
    Rivals.Camera, Rivals.Mechanics, Rivals.ApplyWrapper, Rivals.OriginalApply = nil, nil, nil, nil
    Rivals.Loaded, Rivals.LastTry, Rivals.Injecting = false, -math.huge, false
    Rivals.Status = "等待重新啟用控制"
end

local function FindMain()
    local Gui = PlayerGui:FindFirstChild("ControllerGUI")
    local Main = Gui and Gui:FindFirstChild("NewMainLocal")
    if Main and Main:GetAttribute("ControllerReady") == true then return Main end
    -- 回合重建時，不假定執行中的控制器一定使用固定 ScreenGui 名稱。
    for _, Object in ipairs(PlayerGui:GetDescendants()) do
        if Object.Name == "NewMainLocal" and Object:IsA("LocalScript")
            and Object:GetAttribute("ControllerReady") == true
            and Object.Parent and Object.Parent.Enabled ~= false
            and Object:FindFirstChild("Controller") and Object:FindFirstChild("Shared") then
            return Object
        end
    end
end

-- TWR 的 Client.InputChanged 只接受畫面右半邊，而且 MuMu 的 Delta 可能為零。
-- 直接呼叫原本 Animate.AddAngle，沿用遊戲的 ±85° 限制，不寫入相機 CFrame。
DiscoverTWR = function()
    if AdapterValid(Adapter) and Adapter.Kind == "TWR" then return end
    if bDiscovering then return end
    local Scripts = Player:FindFirstChild("PlayerScripts")
    local Main = Scripts and Scripts:FindFirstChild("Client")
    local AnimateModule = Main and Main:FindFirstChild("Animate")
    local GuiModule = Main and Main:FindFirstChild("Gui")
    if not Main or not AnimateModule or not GuiModule then return end
    bDiscovering = true
    local Generation = DiscoveryGeneration
    task.spawn(function()
        local OK, Error = pcall(function()
            -- 僅讀取 PlayerScripts 的執行中副本，不啟動 StarterPlayer 範本。
            local Client, Animate, Gui = require(Main), require(AnimateModule), require(GuiModule)
            assert(type(Client.GetPlayerFile) == "function" and type(Client.GetPlayerData) == "function"
                and type(Animate.AddAngle) == "function", "TWR 模組介面與 rbxl 不一致")
            if not bAlive or not Config.Enabled or Generation ~= DiscoveryGeneration then return end
            Detach()
            local Current = {Kind = "TWR", Label = "TWR Animate.AddAngle（遊戲原生相機）",
                Main = Main, Client = Client, Animate = Animate, Gui = Gui,
                Shared = {IS_MOBILE = false, IS_CONSOLE = false, ACTIVE_INPUT = "PC"},
                ActionHandler = {}, Controller = {}, NativeSinceFlush = 0, bOriginallyMobile = false}
            Current.OriginalAngle = Animate.AddAngle
            Current.AngleWrapper = function(File, X, Y, ...)
                -- 啟用橋接時統一由 Flush 處理滑鼠，避免原生事件與補送位移重複轉向。
                if Adapter == Current and Gate() and File == Client.GetPlayerFile() then
                    Stats.NativeCalls = Stats.NativeCalls + 1
                    return
                end
                return Current.OriginalAngle(File, X, Y, ...)
            end
            Current.Controller.UpdateCamRot = function(_, DX, DY)
                local File = Client.GetPlayerFile()
                if type(File) == "table" and type(File.Angle) == "table" then
                    Current.OriginalAngle(File, -DX, -DY)
                end
            end
            Current.Original = Current.Controller.UpdateCamRot
            Current.ActionHandler.IsLocalPlayer = function() return true end
            Adapter = Current
            Animate.AddAngle = Current.AngleWrapper
            Stats.LastError = ""
        end)
        if Generation == DiscoveryGeneration then
            bDiscovering = false
            if not OK then Stats.LastError = tostring(Error) end
        end
    end)
end

Discover = function()
    if not bAlive or not Config.Enabled or bDiscovering or (AdapterValid(Adapter) and not IsSimple(Adapter)) then return end
    if Profile.Key == "TWR" then DiscoverTWR() return end
    if Profile.Key == "Rivals" then DiscoverRivals() EnsureSimple() return end
    local Main = FindMain()
    local FirstPerson = PlayerGui:FindFirstChild("FirstPersonGUI")
    local ActionModule = FirstPerson and FirstPerson:FindFirstChild("ActionHandler")
    if not Main or not ActionModule then EnsureSimple() return end
    local SharedModule, ControllerModule = Main:FindFirstChild("Shared"), Main:FindFirstChild("Controller")
    if not SharedModule or not ControllerModule then return end
    bDiscovering = true
    local Generation = DiscoveryGeneration
    task.spawn(function()
        local bOk, Err = pcall(function()
            -- 只 require 已完成初始化的 PlayerGui 執行中模組，避免啟動 ReplicatedStorage 範本。
            local Shared = require(SharedModule)
            local Controller = require(ControllerModule)
            local ActionHandler = require(ActionModule)
            if type(Controller.GetShared) == "function" then
                local bSharedOk, LiveShared = pcall(Controller.GetShared, Controller)
                if bSharedOk and type(LiveShared) == "table" then Shared = LiveShared end
            end
            assert(type(Shared) == "table" and type(Controller) == "table"
                and type(Controller.UpdateCamRot) == "function"
                and type(ActionHandler) == "table" and type(ActionHandler.GetCamRot) == "function",
                "執行中的控制器與提供的 rbxl 不一致")
            if bAlive and Generation == DiscoveryGeneration and Main:IsDescendantOf(PlayerGui)
                and FirstPerson:IsDescendantOf(PlayerGui) and Main.Parent.Enabled ~= false then
                Attach(Main, FirstPerson, Shared, Controller, ActionHandler)
            end
        end)
        if bAlive and Generation == DiscoveryGeneration and not bOk then Stats.LastError = tostring(Err) end
        bDiscovering = false
    end)
end

local function PCSensitivity(Current)
    if Current.Kind == "TWR" then
        local File = Current.Client.GetPlayerFile()
        local Data = Current.Client.GetPlayerData()
        local Options = Data and Data.Options or {}
        local Scale = 1
        local Sequence = File and File.SequenceWhole or {}
        local States = File and File.States or {}
        local Aiming = States[#States] == "Aim" and not (Sequence.Reload or Sequence.Equip
            or Sequence.BasicEquip or Sequence.Sliding or File.Rechambered)
        if Aiming then
            local Stats = File.WeaponModule and File.WeaponModule.Stats
            Scale = tonumber(Stats and Stats.ReduceSensitivity and Options.ScopeScale or Options.AimScale) or 1
        end
        return math.rad(tonumber(Options.Sensitivity) or 0.1) * Scale * Config.SensitivityMultiplier
    end
    if IsSimple(Current) then
        local Camera = Workspace.CurrentCamera
        return 0.0006 * (Camera and Camera.FieldOfView or 70) / 70 * Config.SensitivityMultiplier
    end
    local Settings = Current.Shared.MenuCoreData and Current.Shared.MenuCoreData.Settings or {}
    local Sensitivity = tonumber(Settings.Sensitivity) or 1
    local Camera = Workspace.CurrentCamera
    local FOV = Camera and Camera.FieldOfView or 70
    -- 與 NewMainLocal 的 PC 計算相同；不採用手機版 CurrSens。
    local Value = math.max(Sensitivity, 0.01) * 0.0006 * FOV / 70
    if Current.Shared.Scoping then Value = Value * math.max(tonumber(Settings["ADS Sensitivity"]) or 1, 0.01) end
    return Value * Config.SensitivityMultiplier
end

local function PositionDelta()
    -- 不以 Android 原始 MouseEnabled 作為閘門；以實際座標是否有效及改變判斷。
    local bOk, Position = pcall(function() return UIS:GetMouseLocation() end)
    if not bOk or not Position or not IsFinite(Position.X) or not IsFinite(Position.Y) then
        LastPosition, Edge.Position = nil, nil
        return 0, 0
    end
    Edge.Position = Position
    local PreviousPosition = LastPosition
    LastPosition = Position
    if not PreviousPosition then return 0, 0 end
    local DX, DY = Position.X - PreviousPosition.X, Position.Y - PreviousPosition.Y
    local Camera = Workspace.CurrentCamera
    if Camera then
        local Size = Camera.ViewportSize
        local Threshold = math.min(Size.X, Size.Y) * 0.35
        -- 排除重新捕捉滑鼠時的回中跳動；座標差僅為沒有相對位移時的備援。
        if math.abs(DX) > Threshold or math.abs(DY) > Threshold then return 0, 0 end
        if math.abs(Position.X - Size.X / 2) <= 2 and math.abs(Position.Y - Size.Y / 2) <= 2
            and (math.abs(DX) > 4 or math.abs(DY) > 4) then return 0, 0 end
    end
    return DX, DY
end

local function CameraLook()
    local bOk, Look = pcall(function() return Workspace.CurrentCamera.CFrame.LookVector end)
    if bOk and Look and IsFinite(Look.X) and IsFinite(Look.Y) and IsFinite(Look.Z) then
        return {X = Look.X, Y = Look.Y, Z = Look.Z}
    end
end

local function CheckTestProbe()
    if not TestProbe then return end
    TestProbe.Frames = TestProbe.Frames - 1
    if TestProbe.Frames > 0 then return end
    local Probe = TestProbe
    TestProbe = nil
    local Look = CameraLook()
    if Probe.Look and Look then
        local Dot = math.clamp(Probe.Look.X * Look.X + Probe.Look.Y * Look.Y + Probe.Look.Z * Look.Z, -1, 1)
        local Angle = math.deg(math.acos(Dot))
        Stats.LastTest = Angle >= 3 and string.format("鏡頭有轉動（約 %.1f°）", Angle)
            or "內部角度已更新，但實際鏡頭未轉動"
    else
        Stats.LastTest = "內部角度已更新；無法量測鏡頭"
    end
    if Window and not Window.bDestroyed then Window:Show() end
    if UpdateStatus then UpdateStatus() end
end

function Api.TestTurn()
    if not AdapterValid(Adapter) then
        Stats.LastTest = "尚未連接控制器；請先進入回合"
        if UpdateStatus then UpdateStatus() end
        return
    end
    local Current = Adapter
    local Probe = {Look = CameraLook(), Frames = 4}
    local bOk, Err = pcall(Current.Original, Current.Controller, math.rad(30), 0)
    if bOk then
        Stats.LastTest = "已送出右轉 30°，正在量測"
        TestProbe = Probe
        ClearPending()
        Window:Minimize()
    else
        Stats.LastTest = "測試失敗：" .. tostring(Err)
    end
    if UpdateStatus then UpdateStatus() end
end

local function Flush(DT)
    if not bAlive then return end
    CheckTestProbe()
    UpdateMouse()
    local Current = Adapter
    local bControl, Reason = Gate()
    if not bControl then
        ClearPending()
        LastPosition, Edge.Position = nil, nil
        ResetEdge(Reason)
        if Current then Current.NativeSinceFlush, Current.NativeXSinceFlush, Current.NativeYSinceFlush = 0, 0, 0 ReleasePCButtons(Current) end
        return
    end
    local PositionX, PositionY = PositionDelta()
    local DX, DY, InputSource = PendingX, PendingY, "滑鼠事件"
    if Config.InputMode == "Position" then
        DX, DY, InputSource = PositionX, PositionY, "座標差（備援）"
    elseif Config.InputMode == "Delta" or (Config.InputMode == "Auto" and not bPendingEvent) then
        local Delta = UIS:GetMouseDelta()
        DX, DY, InputSource = Delta.X, Delta.Y, "位移輪詢"
        if DX ~= 0 or DY ~= 0 then Stats.PollMoves = Stats.PollMoves + 1 end
        if Config.InputMode == "Auto" and DX == 0 and DY == 0 then
            DX, DY, InputSource = PositionX, PositionY, "座標差（備援）"
        end
    end
    local NativeCalls, NativeX, NativeY = Current.NativeSinceFlush, Current.NativeXSinceFlush or 0, Current.NativeYSinceFlush or 0
    Current.NativeSinceFlush, Current.NativeXSinceFlush, Current.NativeYSinceFlush = 0, 0, 0
    ClearPending()
    if not IsFinite(DX) or not IsFinite(DY) then ResetEdge("等待有效滑鼠位移") return end
    local EdgeAngle, EdgeAngleY = EdgeDelta(DT, DX, DY, NativeX, NativeY)
    if DX == 0 and DY == 0 and EdgeAngle == 0 and EdgeAngleY == 0 then return end
    if InputSource == "座標差（備援）" and (DX ~= 0 or DY ~= 0) then Stats.PositionMoves = Stats.PositionMoves + 1 end
    Stats.LastDX, Stats.LastDY, Stats.LastSource = DX, DY, Edge.Active and "邊界持續轉向" or InputSource
    Current.Shared.LastMouseInput = tick()
    local Sensitivity = PCSensitivity(Current)
    local AngleX = NativeCalls == 0 and DX * Sensitivity or 0
    local AngleY = NativeCalls == 0 and DY * Sensitivity * (Config.InvertY and -1 or 1) or 0
    AngleX = AngleX + EdgeAngle
    AngleY = AngleY + EdgeAngleY * (Config.InvertY and -1 or 1)
    if AngleX == 0 and AngleY == 0 then return end
    Current.bForwarding = true
    local bOk, Err = pcall(Current.Controller.UpdateCamRot, Current.Controller, AngleX, AngleY)
    Current.bForwarding = false
    if not bOk then error(Err, 0) end
    Stats.BridgeCalls = Stats.BridgeCalls + 1
end

function Api.SetEnabled(bEnabled, bSkipSave)
    Config.Enabled = bEnabled == true
    if IdentityState and IdentityState.Owner == Api then IdentityState.bEnabled = Config.Enabled end
    ClearPending()
    LastPosition, Edge.Position = nil, nil
    ResetEdge(Config.Enabled and "等待滑鼠抵達畫面邊界" or "控制已關閉；已交還遊戲原本控制")
    if Config.Enabled then
        ApplyPlayerIdentity()
        Discover()
        ApplyPCMode(Adapter)
    else
        -- 立即卸下遊戲控制器改寫；停用期間不再自動重新安裝。
        DiscoveryGeneration, bDiscovering = DiscoveryGeneration + 1, false
        TestProbe = nil
        RestoreRivals()
        Detach()
        RestorePlayerIdentity()
        RestoreMouse()
    end
    if Adapter then Adapter.NativeSinceFlush, Adapter.NativeXSinceFlush, Adapter.NativeYSinceFlush = 0, 0, 0 end
    if EnableToggle then EnableToggle:Set(Config.Enabled, true) end
    if UpdateStatus then UpdateStatus() end
    if not bSkipSave and MarkSettingsDirty then MarkSettingsDirty() end
end

function Api.Reconnect()
    DiscoveryGeneration = DiscoveryGeneration + 1
    bDiscovering = false
    RestoreRivals()
    Detach()
    ResetEdge()
    DiscoveryClock = 1
    Discover()
end

function Api.CaptureMouse()
    Api.SetEnabled(true)
    Window:Minimize()
    ClearPending()
    LastPosition = nil
    bNeedRelock, ModalClock = true, 1
    SuppressVisibleModals()
    UpdateMouse()
end

function Api.Destroy()
    if not bAlive then return end
    if Settings.Ready and Settings.DirtyAt and not Settings.Blocked then Api.SaveSettings(false) end
    bAlive = false
    if IdentityState and IdentityState.Owner == Api then IdentityState.bEnabled = false IdentityState.Owner = nil end
    RestorePlayerIdentity()
    DiscoveryGeneration = DiscoveryGeneration + 1
    RunService:UnbindFromRenderStep(BindName .. "_Lock")
    RunService:UnbindFromRenderStep(BindName .. "_Input")
    RunService:UnbindFromRenderStep(BindName .. "_LateLock")
    for _, Connection in ipairs(Connections) do Connection:Disconnect() end
    ResetEdge("已卸載")
    RestoreRivals()
    Detach()
    if Window and not Window.bDestroyed then Window:Destroy() end
    if Env[SingletonKey] == Api then Env[SingletonKey] = nil end
end

local function Fail(Err)
    Stats.LastError = tostring(Err)
    Api.SetEnabled(false, true)
    if Window and not Window.bDestroyed then Window:Show() end
    warn("[MuMu Edge Turn] " .. Stats.LastError)
end

local function Safe(Callback)
    return function(...)
        if not bAlive then return end
        local bOk, Err = pcall(Callback, ...)
        if not bOk then Fail(Err) end
    end
end

local function SettingsStatus(Message)
    Settings.Status = Message
    if SettingsParagraph then SettingsParagraph:Set("設定保存", Message .. "\n檔案：" .. Settings.Path) end
end

local function FileFunction(Name)
    return Env[Name] or ({readfile = readfile, writefile = writefile, isfile = isfile,
        isfolder = isfolder, makefolder = makefolder})[Name]
end

local function NormalizeSettings(Values)
    local Result = {}
    local Ranges = {SensitivityMultiplier = {0.1, 10, 0.05}, EdgeSpeed = {15, 360, 5}, EdgeMargin = {1, 64, 1}}
    for _, Key in ipairs(PersistKeys) do
        local Value, Default = Values[Key], DefaultSettings[Key]
        Result[Key] = Default
        if type(Default) == "boolean" and type(Value) == "boolean" then Result[Key] = Value end
        local Range = Ranges[Key]
        if Range and IsFinite(Value) then
            local Clamped = math.clamp(Value, Range[1], Range[2])
            Result[Key] = math.clamp(Range[1] + math.floor((Clamped - Range[1]) / Range[3] + 0.5) * Range[3], Range[1], Range[2])
        end
    end
    if type(Values.InputMode) == "string" and ModeLabels[Values.InputMode] then Result.InputMode = Values.InputMode end
    if Profile.Key ~= "Rivals" then Result.RivalsSync = false end
    return Result
end

MarkSettingsDirty = function()
    if not bAlive or not Settings.Ready or Settings.Applying or Settings.Blocked then return end
    Settings.DirtyAt = os.clock() + 0.65
    SettingsStatus("設定已變更；等待自動儲存")
end

ReadSettings = function()
    local Read, Exists = FileFunction("readfile"), FileFunction("isfile")
    if type(Read) ~= "function" then
        SettingsStatus("執行器未提供 readfile；無法載入設定")
        return false
    end
    local KnownExists
    if type(Exists) == "function" then
        local OK, Value = pcall(Exists, Settings.Path)
        if OK then KnownExists = Value == true end
        if KnownExists == false then
            Settings.Blocked = false
            SettingsStatus("尚無此玩家／遊戲的設定檔")
            return false
        end
    end
    local OK, Raw = pcall(Read, Settings.Path)
    if not OK or type(Raw) ~= "string" then
        Settings.Blocked = KnownExists == true
        SettingsStatus("設定檔不存在或無法讀取：" .. tostring(Raw):sub(1, 100))
        return false
    end
    local Decoded, Data = pcall(function() return HttpService:JSONDecode(Raw) end)
    if not Decoded or type(Data) ~= "table" or Data.Version ~= 1 or type(Data.Settings) ~= "table"
        or Data.GameId ~= GameId or Data.UserId ~= Settings.UserId then
        Settings.Blocked = true
        SettingsStatus("設定檔格式、版本或玩家／遊戲不符；自動儲存暫停，可按「儲存設定」覆寫")
        return false
    end
    Settings.Blocked = false
    SettingsStatus("已讀取設定")
    return true, NormalizeSettings(Data.Settings)
end

function Api.SaveSettings(bManual)
    Settings.DirtyAt = nil
    if Settings.Blocked and not bManual then return false, Settings.Status end
    local Write = FileFunction("writefile")
    if type(Write) ~= "function" then
        SettingsStatus("執行器未提供 writefile；本次設定無法保存")
        return false, Settings.Status
    end
    local Values = NormalizeSettings(Config)
    local Encoded, Raw = pcall(function()
        return HttpService:JSONEncode({Version = 1, UserId = Settings.UserId, GameId = GameId, Settings = Values})
    end)
    if not Encoded or type(Raw) ~= "string" then
        SettingsStatus("設定編碼失敗：" .. tostring(Raw):sub(1, 100))
        return false, Settings.Status
    end
    local FolderExists, MakeFolder = FileFunction("isfolder"), FileFunction("makefolder")
    local HasFolder = false
    if type(FolderExists) == "function" then
        local OK, Value = pcall(FolderExists, Settings.Folder)
        HasFolder = OK and Value == true
    end
    if not HasFolder and type(MakeFolder) == "function" then pcall(MakeFolder, Settings.Folder) end
    local Written, Error = pcall(Write, Settings.Path, Raw)
    if not Written then
        SettingsStatus("設定儲存失敗：" .. tostring(Error):sub(1, 100))
        return false, Settings.Status
    end
    local Read = FileFunction("readfile")
    if type(Read) == "function" then
        local OK, Actual = pcall(Read, Settings.Path)
        if not OK or Actual ~= Raw then
            SettingsStatus("寫入後讀回不一致；尚未確認設定已保存")
            return false, Settings.Status
        end
    end
    Settings.Blocked = false
    SettingsStatus(type(Read) == "function" and "設定已儲存" or "設定已寫入；執行器未提供 readfile，無法讀回確認")
    return true, Settings.Path
end

SyncSettingControls = function()
    for Key, Control in pairs(SettingControls) do
        local Value = Key == "InputMode" and ModeLabels[Config.InputMode] or Config[Key]
        Control:Set(Value, true)
    end
end

function Api.LoadSettings()
    local OK, Values = ReadSettings()
    if not OK then return false, Settings.Status end
    Settings.Applying, Settings.DirtyAt = true, nil
    -- 先交還目前控制，再一次套用完整設定，避免載入順序留下舊控制器或舊角度。
    Api.SetEnabled(false, true)
    for _, Key in ipairs(PersistKeys) do Config[Key] = Values[Key] end
    ClearPending()
    LastPosition, Edge.Position, bNeedRelock = nil, nil, true
    SyncSettingControls()
    Api.SetEnabled(Values.Enabled, true)
    Settings.Applying = false
    UpdateMouse()
    SettingsStatus("設定已載入")
    if UpdateStatus then UpdateStatus() end
    return true
end

-- 啟動時先讀取，再建立 UI；介面初始值與實際控制值一致。
do
    local OK, Values = ReadSettings()
    if OK then
        for _, Key in ipairs(PersistKeys) do Config[Key] = Values[Key] end
        SettingsStatus("已自動載入設定")
    end
end

local bWindowCreated, WindowError = pcall(function()
    Window = Library:CreateWindow({
        Name = "MuMu 原生滑鼠視角", Brand = "MuMu", Icon = "Crosshair",
        Subtitle = Profile.Name .. " · GameId " .. tostring(GameId), ConfigId = "MuMuWorksEdgeTurnV12",
        Width = 760, Height = 570, MinWidth = 440, MinHeight = 360,
        ToggleKey = Enum.KeyCode.RightShift, DisplayOrder = 10000,
        ConfigurationSaving = {bEnabled = false}, Cursor = {bEnabled = true},
        OnUnload = function() Api.Destroy() end,
    })
    -- 視窗、設定、提示、游標等皆由此 ScreenGui 往下建立，統一使用 gethui()。
    Window.ScreenGui.Parent = UIRoot
    assert(Window.ScreenGui.Parent == UIRoot, "UI 無法放入 gethui() 容器")
    Api.Window = Window
    local Page = Window:CreateTab({Name = "視角控制", Icon = "Crosshair"})
    local Controls = Page:CreateSection({Name = "操作", Side = "left"})
    local Diagnostics = Page:CreateSection({Name = "輸入狀態", Side = "right"})
    EnableToggle = Controls:CreateToggle({
        Name = "使用 PC 鍵盤 / 滑鼠", bCurrentValue = Config.Enabled, bSave = false,
        Callback = function(Value) Api.SetEnabled(Value) end,
    })
    SettingControls.Enabled = EnableToggle
    SettingControls.SensitivityMultiplier = Controls:CreateSlider({
        Name = "靈敏度倍率", Range = {0.1, 10}, Increment = 0.05, Suffix = "x",
        CurrentValue = Config.SensitivityMultiplier, bSave = false,
        Callback = function(Value) Config.SensitivityMultiplier = Value MarkSettingsDirty() end,
    })
    SettingControls.InvertY = Controls:CreateToggle({
        Name = "反轉上下", bCurrentValue = Config.InvertY, bSave = false,
        Callback = function(Value) Config.InvertY = Value MarkSettingsDirty() end,
    })
    local Modes = {["自動"] = "Auto", ["滑鼠事件"] = "Event", ["位移輪詢"] = "Delta", ["座標差（備援）"] = "Position"}
    SettingControls.InputMode = Controls:CreateDropdown({
        Name = "滑鼠輸入來源", Options = {"自動", "滑鼠事件", "位移輪詢", "座標差（備援）"},
        CurrentOption = ModeLabels[Config.InputMode], bSave = false,
        Callback = function(Value)
            Config.InputMode = Modes[Value] or "Auto"
            ClearPending()
            LastPosition = nil
            MarkSettingsDirty()
        end,
    })
    Controls:CreateButton({Name = "開始控制（最小化）", Style = "primary", Callback = function()
        Api.CaptureMouse()
    end})
    Controls:CreateButton({Name = "重新捕捉滑鼠（最小化）", Callback = function() Api.CaptureMouse() end})
    Controls:CreateButton({Name = "重新連接控制器", Callback = function() Api.Reconnect() end})
    Controls:CreateButton({Name = "測試視角：右轉 30°", Callback = function() Api.TestTurn() end})
    StatusParagraph = Diagnostics:CreateParagraph({Title = "控制器", Content = "等待進入回合"})
    DeviceParagraph = Diagnostics:CreateParagraph({Title = "輸入設備", Content = "正在設定鍵鼠身份"})
    CaptureParagraph = Diagnostics:CreateParagraph({Title = "滑鼠捕捉", Content = "等待捕捉狀態"})
    InputParagraph = Diagnostics:CreateParagraph({Title = "原生滑鼠", Content = "等待移動訊號"})
    TestParagraph = Diagnostics:CreateParagraph({Title = "視角測試", Content = "尚未執行"})
    Diagnostics:CreateParagraph({Title = "快捷鍵", Content = "F8：開關控制\n右 Shift：設定 / 最小化\n展開設定、聊天或遊戲選單時暫停轉動。"})
    Diagnostics:CreateParagraph({Title = "使用方式", Content = "到左／右／上／下邊界後會持續轉向；移回畫面內停止。設定、聊天、選單、失焦時暫停。關閉控制會立即交還遊戲原本控制。"})
    GameParagraph = Diagnostics:CreateParagraph({Title = "目前遊戲", Content = Profile.Name .. "\nGameId：" .. tostring(GameId) .. "\nPlaceId：" .. tostring(PlaceId)})
    EdgeParagraph = Diagnostics:CreateParagraph({Title = "邊界持續轉向", Content = Edge.Status})
    SettingControls.EdgeTurn = Controls:CreateToggle({Name = "啟用邊界持續轉向", bCurrentValue = Config.EdgeTurn, bSave = false, Callback = function(Value)
        Config.EdgeTurn = Value ResetEdge() MarkSettingsDirty()
    end})
    SettingControls.EdgeVertical = Controls:CreateToggle({Name = "上／下邊界持續轉向", bCurrentValue = Config.EdgeVertical, bSave = false, Callback = function(Value)
        Config.EdgeVertical = Value ResetEdge() MarkSettingsDirty()
    end})
    SettingControls.EdgeSpeed = Controls:CreateSlider({Name = "邊界轉向速度", Range = {15, 360}, Increment = 5, Suffix = "°/s",
        CurrentValue = Config.EdgeSpeed, bSave = false, Callback = function(Value) Config.EdgeSpeed = Value MarkSettingsDirty() end})
    SettingControls.EdgeMargin = Controls:CreateSlider({Name = "邊界判定範圍", Range = {1, 64}, Increment = 1, Suffix = "px",
        CurrentValue = Config.EdgeMargin, bSave = false, Callback = function(Value) Config.EdgeMargin = Value MarkSettingsDirty() end})
    SettingControls.PrototypeCapture = Controls:CreateToggle({Name = "保留原型鎖鼠方式", bCurrentValue = Config.PrototypeCapture, bSave = false, Callback = function(Value)
        Config.PrototypeCapture = Value bNeedRelock = true LastPosition = nil UpdateMouse() MarkSettingsDirty()
    end})
    local SavedControls = Page:CreateSection({Name = "設定保存", Side = "left"})
    SavedControls:CreateButton({Name = "儲存設定", Callback = function() Api.SaveSettings(true) end})
    SavedControls:CreateButton({Name = "載入設定", Callback = function() Api.LoadSettings() end})
    SettingsParagraph = SavedControls:CreateParagraph({Title = "設定保存", Content = Settings.Status .. "\n檔案：" .. Settings.Path})
    if Profile.Key == "Rivals" then
        local RPage = Window:CreateTab({Name = "RIVALS", Icon = "Crosshair"})
        local RControls = RPage:CreateSection({Name = "RIVALS 對應功能", Side = "full"})
        RControls:CreateParagraph({Title = "遊戲識別", Content = "GameId 6035872082：同步 RIVALS 遊戲角度及角色方向。"})
        SettingControls.RivalsSync = RControls:CreateToggle({Name = "同步 RIVALS 遊戲角度", bCurrentValue = Config.RivalsSync, bSave = false, Callback = function(Value) Config.RivalsSync = Value MarkSettingsDirty() end})
        RControls:CreateButton({Name = "重新連接 RIVALS 控制器", Callback = function() Rivals.Loaded = false Rivals.LastTry = -math.huge Api.Reconnect() end})
        RivalsParagraph = RControls:CreateParagraph({Title = "RIVALS 狀態", Content = "等待控制器"})
    end
end)
if not bWindowCreated then
    Api.Destroy()
    error("BjzUi / gethui() 初始化失敗：" .. tostring(WindowError), 0)
end

UpdateStatus = function()
    if not bAlive or not Window or Window.bDestroyed then return end
    local bControl, Reason = Gate()
    local Current = Adapter
    local Detail = Reason
    if Current then
        Detail = Detail .. "\n手機分支：" .. tostring(Current.Shared.IS_MOBILE)
            .. " / 手把：" .. tostring(Current.Shared.IS_CONSOLE)
            .. "\nACTIVE_INPUT：" .. tostring(Current.Shared.ACTIVE_INPUT)
            .. "\n目標：" .. (IsSimple(Current) and Current.Label or "Controller.UpdateCamRot")
            .. "\n鎖定：" .. (Current.ScriptEnv and "遊戲 LockMouse" or "屬性監聽")
    end
    if Stats.LastError ~= "" then Detail = Detail .. "\n錯誤：" .. Stats.LastError end
    StatusParagraph:Set(bControl and "已連接" or "狀態", Detail)
    InputParagraph:Set("原生滑鼠", string.format(
        "來源：%s\n事件：%d（有位移 %d）\n輪詢：%d / 座標：%d\n橋接：%d / 原生有效：%d\n原生零位移：%d\n重新鎖定：%d\n最近位移：%.1f, %.1f",
        Stats.LastSource, Stats.Events, Stats.EventMoves, Stats.PollMoves, Stats.PositionMoves,
        Stats.BridgeCalls, Stats.NativeCalls, Stats.NativeZeroCalls, Stats.Relocks, Stats.LastDX, Stats.LastDY))
    local Device = "對遊戲回報：" .. Stats.Identity
    Device = Device .. "\n實際收到事件：" .. Stats.LastRawInput
    if IdentityState and type(IdentityState.ReadOriginal) == "function" then
        local bOk, RawMouse = pcall(IdentityState.ReadOriginal, "MouseEnabled")
        if bOk then Device = Device .. "\n引擎原始 MouseEnabled：" .. tostring(RawMouse) end
    end
    DeviceParagraph:Set("輸入設備", Device)
    local Capture = bControl and (Config.PrototypeCapture and "目前：遊玩中，要求鎖定中心" or "目前：遊玩中，使用座標差與邊界轉向") or "目前：" .. Reason
    Capture = Capture .. "\n最近遊玩：" .. Stats.LastPlayLock
        .. string.format("\n已處理 Modal：%d / 無法修改：%d", Stats.ModalCount, Stats.ModalBlocked)
        .. string.format("\n零靈敏度修正：%d", Stats.SensitivityFixes)
    CaptureParagraph:Set("滑鼠捕捉", Capture)
    TestParagraph:Set("視角測試", Stats.LastTest)
    EdgeParagraph:Set("邊界持續轉向", Edge.Status .. string.format("\n速度：%s°/s；邊界範圍：%s px\n累計轉向：%.1f 秒", tostring(Config.EdgeSpeed), tostring(Config.EdgeMargin), Edge.Seconds))
    if RivalsParagraph then RivalsParagraph:Set("RIVALS 狀態", Rivals.Status) end
end

Connect(UIS.InputChanged, Safe(function(Input)
    Stats.LastRawInput = tostring(Input.UserInputType)
    if Input.UserInputType == Enum.UserInputType.MouseWheel then
        if not IsSimple(Adapter) and Config.Enabled and AdapterValid(Adapter) and Adapter.bOriginallyMobile and Gate()
            and type(Adapter.Controller.ScrollEquip) == "function" then
            Adapter.Controller:ScrollEquip(Input.Position.Z > 0 and -1 or 1)
        end
        return
    end
    if Input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
    Stats.Events = Stats.Events + 1
    local Delta = Input.Delta
    if not IsFinite(Delta.X) or not IsFinite(Delta.Y) then return end
    if Delta.X == 0 and Delta.Y == 0 then return end
    Stats.EventMoves = Stats.EventMoves + 1
    if not Gate() then return end
    PendingX, PendingY = PendingX + Delta.X, PendingY + Delta.Y
    bPendingEvent = true
end))

-- NewMainLocal 的 Heartbeat 會在手機分支寫入 Default；屬性改變時立即恢復正確模式。
Connect(UIS:GetPropertyChangedSignal("MouseBehavior"), Safe(UpdateMouse))
Connect(UIS.InputBegan, Safe(function(Input, bProcessed)
    Stats.LastRawInput = tostring(Input.UserInputType)
    if Input.KeyCode == Config.ToggleKey then
        Api.SetEnabled(not Config.Enabled)
        if Config.Enabled then Api.CaptureMouse() end
        return
    end
    if bProcessed or UIS:GetFocusedTextBox() then return end
    local Current = Adapter
    if not Current or not Current.bOriginallyMobile or not Gate() then return end
    if Input.UserInputType == Enum.UserInputType.Keyboard then
        PCKey(Current, Input.KeyCode.Name, false)
    elseif Input.UserInputType == Enum.UserInputType.MouseButton1 then
        Current.Shared.MouseDown = true
        Current.bOwnMouse = true
        local Callback = Current.Actions.Shoot
        if type(Callback) == "function" then task.spawn(Callback) end
        if type(Current.Controller.LeftClick) == "function" then Current.Controller:LeftClick() end
    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 or Input.UserInputType == Enum.UserInputType.MouseButton3 then
        PCKey(Current, Input.UserInputType.Name, false)
    end
end))
Connect(UIS.InputEnded, Safe(function(Input)
    local Current = Adapter
    if not Config.Enabled or not Current or not Current.bOriginallyMobile then return end
    if Input.UserInputType == Enum.UserInputType.MouseButton1 then Current.Shared.MouseDown = false Current.bOwnMouse = false end
    if Current.Shared.Dead then ReleasePCButtons(Current) return end
    if Input.UserInputType == Enum.UserInputType.Keyboard then PCKey(Current, Input.KeyCode.Name, true)
    elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then PCKey(Current, Input.UserInputType.Name, true) end
end))
Connect(UIS.WindowFocusReleased, Safe(function()
    bFocused = false
    ClearPending()
    LastPosition = nil
    UpdateMouse()
end))
Connect(UIS.WindowFocused, Safe(function() bFocused = true UpdateMouse() end))
Connect(UIS.TextBoxFocused, Safe(function() ClearPending() LastPosition = nil UpdateMouse() end))
Connect(GuiService.MenuOpened, Safe(function() ClearPending() LastPosition = nil UpdateMouse() end))
Connect(RunService.Heartbeat, Safe(function(DT)
    if Settings.Ready and Settings.DirtyAt and os.clock() >= Settings.DirtyAt then Api.SaveSettings(false) end
    if Config.Enabled then ApplyPlayerIdentity() ApplyPCMode(Adapter) end
    if Adapter and not AdapterValid(Adapter) then Detach() end
    DiscoveryClock, StatusClock, ModalClock = DiscoveryClock + DT, StatusClock + DT, ModalClock + DT
    if DiscoveryClock >= 0.75 then DiscoveryClock = 0 Discover() end
    UpdateMouse()
    if ModalClock >= 0.5 then ModalClock = 0 SuppressVisibleModals() end
    if StatusClock >= 0.25 then StatusClock = 0 UpdateStatus() end
end))

SetupMouseIdentity()
ApplyPlayerIdentity()
-- 提供的 rbxl 在 201 更新 CamUpdate；在 199 把輸入交給遊戲，讓同一幀使用新的角度。
RunService:BindToRenderStep(BindName .. "_Lock", Enum.RenderPriority.Input.Value - 1, Safe(UpdateMouse))
RunService:BindToRenderStep(BindName .. "_Input", Enum.RenderPriority.Camera.Value - 1, Safe(Flush))
RunService:BindToRenderStep(BindName .. "_LateLock", Enum.RenderPriority.Last.Value + 1, Safe(function()
    UpdateMouse()
    if not Gate() then
        ResetEdge(select(2, Gate()))
        if IsSimple(Adapter) then ResetSimple(Adapter) end
        return
    end
    if IsSimple(Adapter) then RenderSimple(Adapter) end
    local bPosition, Position = pcall(function() return UIS:GetMouseLocation() end)
    local Camera = Workspace.CurrentCamera
    local Behavior = tostring(UIS.MouseBehavior)
    if Camera and bPosition and Position and IsFinite(Position.X) and IsFinite(Position.Y) then
        local DX, DY = Position.X - Camera.ViewportSize.X / 2, Position.Y - Camera.ViewportSize.Y / 2
        local Distance = math.sqrt(DX * DX + DY * DY)
        Stats.LastPlayLock = string.format("%s；距中心 %.1f px；靈敏度 %s", Behavior, Distance, tostring(UIS.MouseDeltaSensitivity))
        if Distance > 12 then Stats.LastPlayLock = Stats.LastPlayLock .. "（游標仍有偏移）" end
    else
        Stats.LastPlayLock = Behavior .. "；無法量測游標位置"
    end
end))
Settings.Ready = true
Window:Minimize()
Discover()
UpdateStatus()
Window:Notify({Title = Config.Enabled and "PC 鍵鼠模式已載入" or "設定已載入；控制目前關閉", Content = "四邊持續轉向；右 Shift 設定，F8 開關。設定變更後自動儲存。", Duration = 5})
print("[MuMu Edge Turn v12.2] UI 使用 gethui()；四邊持續轉向；設定自動保存／載入；靈敏度最高 10。")
return Api

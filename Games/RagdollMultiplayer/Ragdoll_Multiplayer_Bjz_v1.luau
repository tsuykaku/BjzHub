--!nonstrict
--[[
    Ragdoll Multiplayer · Delta / BjzUi · v1.0.0
    場景：120421389568929 / 使用者提供的 PlaceVersion 66。
    使用：將整份腳本貼入 Delta 執行，或放在 Delta workspace 後執行：
        loadstring(readfile("Ragdoll_Multiplayer_Delta_Bjz_v1.luau"))()

    UI 依照指定網址以 loadstring 載入，不內嵌／改寫 UI Library。
    NPC：Workspace.Dummies 的 Model；使用 RD_Prepared、Dead 等狀態。
    透視：Highlight、名稱、距離、狀態；可選追蹤線、屍體與各種透明度。
    Ragebot：手動開火；射線瞄準／鏡頭鎖定，預設不自動開火。
    射線模式只接受已知遊戲戰鬥腳本呼叫 Camera 的射線方法。
    不修改射速、武器、玩家移動或原始戰鬥事件封包。

    反作弊：未驗證。場景存檔不包含伺服器端程式，無法證明繞過。
    Crumbs 在可見來源中回報武器／效能統計，不能據此判定是反作弊。
    沒有將阻擋 Crumbs、所有 Remote 或 Kick 當作繞過功能。

    RightShift／視窗縮小按鈕：縮小、還原。
    預設「顯示設定介面時暫停」；啟用 Ragebot 後先縮小主視窗。
    重複執行會清理舊實例；卸載後唯一保留的 hook 只轉交原呼叫。
    本檔已做 Luau 編譯與模擬邏輯測試，尚未在 Delta 連線實測。
]]

--local PLACE_ID = 120421389568929
local UI_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/refs/heads/main/Library/BjzUiLibrary_2.0.luau"
local SESSION_KEY = "__RagdollDeltaBjzSessionV1"
local DISPATCH_KEY = "__RagdollDeltaBjzCameraDispatchV1"

if not game:IsLoaded() then game.Loaded:Wait() end
--if game.PlaceId ~= PLACE_ID then
--    error("[Ragdoll Delta] 此腳本只適用於 PlaceId " .. tostring(PLACE_ID), 0)
--end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then error("[Ragdoll Delta] 尚未取得 LocalPlayer。", 0) end
local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 15)
if not PlayerScripts then error("[Ragdoll Delta] PlayerScripts 尚未就緒，請進入遊戲後再執行。", 0) end

local bDownloaded, UiSource = pcall(function() return game:HttpGet(UI_URL) end)
if not bDownloaded or type(UiSource) ~= "string" or #UiSource < 100 then
    error("[Ragdoll Delta] 無法下載 BjzUi：" .. tostring(UiSource), 0)
end
local UiChunk, UiError = loadstring(UiSource, "@BjzUiLibrary_2.0.luau")
if not UiChunk then error("[Ragdoll Delta] BjzUi 編譯失敗：" .. tostring(UiError), 0) end
local bUiLoaded, Library = pcall(UiChunk)
if not bUiLoaded or type(Library) ~= "table" or type(Library.CreateWindow) ~= "function" then
    error("[Ragdoll Delta] BjzUi 載入失敗：" .. tostring(Library), 0)
end

local Env = type(getgenv) == "function" and getgenv() or _G
local Previous = Env[SESSION_KEY]
if type(Previous) == "table" and type(Previous.Destroy) == "function" then Previous:Destroy() end

local Config = {
    bEsp = false, bShowDead = true, bThroughWalls = true,
    bNames = true, bDistance = true, bState = true, bTracers = false,
    EspDistance = 2000, MarkerLimit = 80,
    EspColor = Color3.fromRGB(100, 230, 170),
    DeadColor = Color3.fromRGB(145, 150, 160),
    TargetColor = Color3.fromRGB(255, 108, 98),
    FillTransparency = 0.75, OutlineTransparency = 0,
    LineTransparency = 0.2,
    bRage = false, Mode = "射線瞄準", AimPart = "頭部",
    Priority = "準星最近", AimDistance = 1000, AimAngle = 90,
    bVisibleOnly = true, bOnScreen = true, bSticky = true,
    bFightersOnly = false, bPauseWithUi = true,
    bAimCircle = true, Smoothness = 1,
}

local State = {
    bRunning = true, bFocused = true,
    Config = Config,
    Connections = {}, RootConnections = {}, Records = {}, AllowedCallers = {},
    Root = nil, Target = nil, TargetAt = 0, Weapon = nil,
    Status = "初始化中", HookStatus = "尚未檢查", LastError = "無",
    RedirectedRays = 0, CandidateCount = 0, AliveCount = 0,
    Window = nil, Overlay = nil, Highlights = nil, Bus = nil,
    RenderName = "RD_Bjz_" .. HttpService:GenerateGUID(false),
}
Env[SESSION_KEY] = State

local function DisconnectAll(List)
    for _, Connection in ipairs(List) do pcall(function() Connection:Disconnect() end) end
    table.clear(List)
end

local function Connect(Signal, Callback, List)
    local Connection = Signal:Connect(Callback)
    table.insert(List or State.Connections, Connection)
    return Connection
end

local function New(ClassName, Properties, Parent)
    local Object = Instance.new(ClassName)
    for Key, Value in pairs(Properties or {}) do Object[Key] = Value end
    Object.Parent = Parent
    return Object
end

local function ClearVisual(Record)
    for _, Key in ipairs({ "Highlight", "Billboard", "Line" }) do
        if Record[Key] then Record[Key]:Destroy(); Record[Key] = nil end
    end
    Record.Label = nil
end

function State:Destroy()
    if not self.bRunning then return end
    self.bRunning = false
    Config.bEsp, Config.bRage = false, false
    self.Target = nil
    if self.Bus and self.Bus.Owner == self then self.Bus.Owner = nil end
    RunService:UnbindFromRenderStep(self.RenderName)
    DisconnectAll(self.RootConnections)
    DisconnectAll(self.Connections)
    for _, Record in pairs(self.Records) do ClearVisual(Record) end
    table.clear(self.Records)
    if self.Overlay then self.Overlay:Destroy(); self.Overlay = nil end
    if self.Highlights then self.Highlights:Destroy(); self.Highlights = nil end
    if self.Window and not self.Window.bDestroyed and self.DestroyWindow then
        self.DestroyWindow(self.Window)
    end
    if Env[SESSION_KEY] == self then Env[SESSION_KEY] = nil end
end

local function IsNpc(Model)
    return typeof(Model) == "Instance" and Model:IsA("Model")
        and State.Root ~= nil and Model.Parent == State.Root
        and Model ~= LocalPlayer.Character and Players:GetPlayerFromCharacter(Model) == nil
end

local function IsAlive(Model)
    if not IsNpc(Model) or Model:GetAttribute("SharkConsumed") == true then return false end
    local Dead = Model:GetAttribute("Dead")
    if Dead ~= nil then return Dead ~= true end
    local Humanoid = Model:FindFirstChildOfClass("Humanoid")
    return Humanoid == nil or Humanoid.Health > 0
end

local function FindPart(Model, bForAim)
    local Names
    if bForAim and Config.AimPart == "胸口" then
        Names = { "UpperTorso", "Torso", "LowerTorso", "Head" }
    elseif bForAim then
        Names = { "Head", "UpperTorso", "Torso", "LowerTorso" }
    else
        Names = { "HumanoidRootPart", "UpperTorso", "Torso", "LowerTorso", "Head" }
    end
    for _, Name in ipairs(Names) do
        local Part = Model:FindFirstChild(Name)
        if Part and Part:IsA("BasePart") then return Part end
    end
    return nil
end

local function RemoveNpc(Model)
    local Record = State.Records[Model]
    if Record then ClearVisual(Record); State.Records[Model] = nil end
    if State.Target and State.Target.Model == Model then State.Target = nil end
end

local function AddNpc(Model)
    if IsNpc(Model) and not State.Records[Model] then State.Records[Model] = { Model = Model } end
end

local function BindRoot()
    local Root = Workspace:FindFirstChild("Dummies")
    if Root == State.Root then return end
    DisconnectAll(State.RootConnections)
    for _, Record in pairs(State.Records) do ClearVisual(Record) end
    table.clear(State.Records)
    State.Root, State.Target = Root, nil
    if not Root then return end
    Connect(Root.ChildAdded, AddNpc, State.RootConnections)
    Connect(Root.ChildRemoved, RemoveNpc, State.RootConnections)
    for _, Model in ipairs(Root:GetChildren()) do AddNpc(Model) end
end

local WeaponDefinitions, GameClock, WeaponInventory
local function LoadGameModules()
    local Engine = ReplicatedStorage:FindFirstChild("RagdollEngine")
    for _, Row in ipairs({
        { Engine, "Weapons", function(Value) WeaponDefinitions = Value end },
        { Engine, "Clock", function(Value) GameClock = Value end },
        { ReplicatedStorage, "WeaponInventory", function(Value) WeaponInventory = Value end },
    }) do
        local Module = Row[1] and Row[1]:FindFirstChild(Row[2])
        if Module and Module:IsA("ModuleScript") then
            local bOk, Result = pcall(require, Module)
            if bOk and type(Result) == "table" then Row[3](Result) end
        end
    end
end

local function ReadWeapon()
    local Character = LocalPlayer.Character
    if not Character then return nil end
    for _, Child in ipairs(Character:GetChildren()) do
        if Child:IsA("Tool") then
            local Key = Child:GetAttribute("RagdollWeapon")
            local Definition = WeaponDefinitions and WeaponDefinitions[Key]
            if type(Key) == "string" and type(Definition) == "table" then
                return { Key = Key, Definition = Definition, Tool = Child }
            end
        end
    end
    return nil
end

local function UpdateCallers()
    table.clear(State.AllowedCallers)
    local Shooter = PlayerScripts:FindFirstChild("ShooterClient")
    if Shooter then
        State.AllowedCallers[Shooter] = true
        for _, Descendant in ipairs(Shooter:GetDescendants()) do
            if Descendant:IsA("ModuleScript") then State.AllowedCallers[Descendant] = true end
        end
    end
    for _, Name in ipairs({ "AdvancedWeapons", "Railgun", "SpecialWeapons" }) do
        local Module = ReplicatedStorage:FindFirstChild(Name)
        if Module and Module:IsA("ModuleScript") then State.AllowedCallers[Module] = true end
    end
end

local function BlockReason()
    if not State.bRunning or not Config.bRage then return "Ragebot 已關閉" end
    if not State.bFocused then return "視窗失去焦點" end
    if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then return "選單／輸入文字中" end
    if Config.bPauseWithUi and State.Window and State.Window.bVisible then return "請先縮小設定介面" end
    if LocalPlayer:GetAttribute("MapSwitching") then return "地圖切換中" end
    if LocalPlayer:GetAttribute("FreecamEnabled") then return "自由鏡頭中" end
    if LocalPlayer:GetAttribute("EquippedAction") == "spawn" then return "NPC 生成模式" end
    if GameClock and GameClock.frozen then return "遊戲時間已凍結" end
    if WeaponInventory and type(WeaponInventory.menuOpen) == "function" and WeaponInventory.menuOpen() then
        return "遊戲武器選單開啟中"
    end
    local Character = LocalPlayer.Character
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return "等待存活角色" end
    if not State.Weapon or State.Weapon.Tool.Parent ~= Character then return "請先裝備武器" end
    if Config.Mode == "射線瞄準" and not (State.Bus and State.Bus.bReady) then return "射線功能不可用，請改用鏡頭鎖定" end
    return nil
end

local function SightParams()
    local Exclude = {}
    if LocalPlayer.Character then table.insert(Exclude, LocalPlayer.Character) end
    local Camera = Workspace.CurrentCamera
    if Camera then table.insert(Exclude, Camera) end
    for _, Name in ipairs({ "LocalFX", "Wounds" }) do
        local Object = Workspace:FindFirstChild(Name)
        if Object then table.insert(Exclude, Object) end
    end
    local Params = RaycastParams.new()
    Params.FilterType = Enum.RaycastFilterType.Exclude
    Params.FilterDescendantsInstances = Exclude
    Params.IgnoreWater = false
    return Params
end

local function ClearSight(Origin, Part, Model)
    local Delta = Part.Position - Origin
    if Delta.Magnitude < 0.001 then return false end
    local Hit = Workspace:Raycast(Origin, Delta, SightParams())
    return Hit == nil or Hit.Instance:IsDescendantOf(Model)
end

local function Evaluate(Model, Camera)
    if not IsAlive(Model) or Model:GetAttribute("RD_Prepared") ~= true then return nil end
    if Model:GetAttribute("Demo") == true then return nil end
    if Config.bFightersOnly and Model:GetAttribute("FighterEnabled") ~= true then return nil end
    local Part = FindPart(Model, true)
    if not Part then return nil end
    local Delta = Part.Position - Camera.CFrame.Position
    local Distance = Delta.Magnitude
    local WeaponRange = State.Weapon and tonumber(State.Weapon.Definition.range) or Config.AimDistance
    if Distance < 0.001 or Distance > math.min(Config.AimDistance, WeaponRange) then return nil end
    local Dot = math.clamp(Camera.CFrame.LookVector:Dot(Delta.Unit), -1, 1)
    local Angle = math.acos(Dot)
    if Angle > math.rad(Config.AimAngle * 0.5) + 0.00001 then return nil end
    local _, bOnScreen = Camera:WorldToViewportPoint(Part.Position)
    if Config.bOnScreen and not bOnScreen then return nil end
    if Config.bVisibleOnly and not ClearSight(Camera.CFrame.Position, Part, Model) then return nil end
    return { Model = Model, Part = Part, Distance = Distance, Angle = Angle }
end

local function SelectTarget()
    State.Weapon = ReadWeapon()
    local Reason = BlockReason()
    local Camera = Workspace.CurrentCamera
    if Reason or not Camera then
        State.Target, State.Status = nil, Reason or "等待攝影機"
        return
    end
    if Config.bSticky and State.Target then
        local Existing = Evaluate(State.Target.Model, Camera)
        if Existing then
            State.Target, State.TargetAt = Existing, os.clock()
            State.Status = "鎖定：" .. Existing.Model.Name
            return
        end
    end
    local Best, Score
    for Model in pairs(State.Records) do
        local Candidate = Evaluate(Model, Camera)
        if Candidate then
            local Value = Config.Priority == "距離最近" and Candidate.Distance or Candidate.Angle
            if not Best or Value < Score then Best, Score = Candidate, Value end
        end
    end
    State.Target, State.TargetAt = Best, os.clock()
    State.Status = Best and ("鎖定：" .. Best.Model.Name) or "範圍內沒有可鎖定的 NPC"
end

function State:RedirectRay(BaseRay)
    if BlockReason() or Config.Mode ~= "射線瞄準" or typeof(BaseRay) ~= "Ray" then return nil end
    local Target = self.Target
    if not Target or os.clock() - self.TargetAt > 0.25 then return nil end
    if not IsAlive(Target.Model) or Target.Part.Parent ~= Target.Model then return nil end
    local Delta = Target.Part.Position - BaseRay.Origin
    local Range = math.min(Config.AimDistance, tonumber(self.Weapon.Definition.range) or Config.AimDistance)
    if Delta.Magnitude < 0.001 or Delta.Magnitude > Range then return nil end
    if Config.bVisibleOnly and not ClearSight(BaseRay.Origin, Target.Part, Target.Model) then return nil end
    self.RedirectedRays += 1
    return Ray.new(BaseRay.Origin, Delta.Unit * BaseRay.Direction.Magnitude)
end

local function InstallDispatcher()
    local Existing = Env[DISPATCH_KEY]
    if type(Existing) == "table" and Existing.Version == 1 and Existing.bReady then
        Existing.Owner, State.Bus = State, Existing
        State.HookStatus = "射線攔截已安裝（重用）"
        return
    end
    local Required = {
        hookmetamethod = hookmetamethod, getnamecallmethod = getnamecallmethod,
        checkcaller = checkcaller, getcallingscript = getcallingscript, newcclosure = newcclosure,
    }
    local Missing = {}
    for Name, Function in pairs(Required) do
        if type(Function) ~= "function" then table.insert(Missing, Name) end
    end
    -- nil 不會存在於 table，另外逐項檢查，避免缺少 API 被誤判為可用。
    for _, Name in ipairs({ "hookmetamethod", "getnamecallmethod", "checkcaller", "getcallingscript", "newcclosure" }) do
        if type(Required[Name]) ~= "function" and not table.find(Missing, Name) then table.insert(Missing, Name) end
    end
    if #Missing > 0 then
        State.HookStatus = "缺少 API：" .. table.concat(Missing, ", ")
        Config.Mode = "鏡頭鎖定"
        return
    end
    local Bus = { Version = 1, bReady = false, Owner = State }
    local Original
    local Hook = Required.newcclosure(function(Self, ...)
        local Method = Required.getnamecallmethod()
        local Owner = Bus.Owner
        if not Owner or not Owner.bRunning or Self ~= Workspace.CurrentCamera
            or (Method ~= "ScreenPointToRay" and Method ~= "ViewportPointToRay")
            or Owner.Config.Mode ~= "射線瞄準" or not Owner.Config.bRage or Required.checkcaller() then
            return Original(Self, ...)
        end
        local Caller = Required.getcallingscript()
        if not Owner.AllowedCallers[Caller] then return Original(Self, ...) end
        local BaseRay = Original(Self, ...)
        local bOk, NewRay = pcall(Owner.RedirectRay, Owner, BaseRay)
        if not bOk then Owner.LastError = tostring(NewRay) end
        return bOk and NewRay or BaseRay
    end)
    local bOk, Result = pcall(Required.hookmetamethod, game, "__namecall", Hook)
    if not bOk or type(Result) ~= "function" then
        State.HookStatus = "安裝失敗：" .. tostring(Result)
        Config.Mode = "鏡頭鎖定"
        return
    end
    Original, Bus.bReady = Result, true
    State.Bus, Env[DISPATCH_KEY] = Bus, Bus
    State.HookStatus = "射線攔截已安裝；命中效果待連線驗證"
end

local function EnsureVisual(Record)
    if Record.Highlight then return end
    Record.Highlight = New("Highlight", { Adornee = Record.Model }, State.Highlights)
    Record.Billboard = New("BillboardGui", {
        Size = UDim2.fromOffset(220, 48), StudsOffsetWorldSpace = Vector3.new(0, 2.8, 0),
        ResetOnSpawn = false, MaxDistance = Config.EspDistance, LightInfluence = 0,
    }, State.Highlights)
    Record.Label = New("TextLabel", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, TextSize = 13,
        Font = Enum.Font.GothamMedium, TextStrokeTransparency = 0.25,
        TextStrokeColor3 = Color3.new(0, 0, 0), Text = "", RichText = false,
    }, Record.Billboard)
end

local function UpdateVisuals()
    local Camera = Workspace.CurrentCamera
    if not Camera then return end
    local Rows, AliveCount, Count = {}, 0, 0
    for Model, Record in pairs(State.Records) do
        if not IsNpc(Model) then RemoveNpc(Model); continue end
        Count += 1
        local bAlive = IsAlive(Model)
        if bAlive then AliveCount += 1 end
        local RootPart = FindPart(Model, false)
        local Distance = RootPart and (RootPart.Position - Camera.CFrame.Position).Magnitude or math.huge
        if Config.bEsp and RootPart and Distance <= Config.EspDistance and (bAlive or Config.bShowDead) then
            table.insert(Rows, { Record = Record, Part = RootPart, Distance = Distance, bAlive = bAlive })
        else ClearVisual(Record) end
    end
    State.CandidateCount, State.AliveCount = Count, AliveCount
    table.sort(Rows, function(A, B) return A.Distance < B.Distance end)
    for Index, Row in ipairs(Rows) do
        local Record = Row.Record
        if Index > Config.MarkerLimit then ClearVisual(Record); continue end
        EnsureVisual(Record)
        Record.Part = Row.Part
        local bTarget = State.Target and State.Target.Model == Record.Model
        local Color = bTarget and Config.TargetColor or (Row.bAlive and Config.EspColor or Config.DeadColor)
        local Highlight = Record.Highlight
        Highlight.DepthMode = Config.bThroughWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        Highlight.FillColor, Highlight.OutlineColor = Color, Color
        Highlight.FillTransparency, Highlight.OutlineTransparency = Config.FillTransparency, Config.OutlineTransparency
        local LabelRows = {}
        if Config.bNames then table.insert(LabelRows, Record.Model.Name) end
        local Details = {}
        if Config.bDistance then table.insert(Details, string.format("%.0f studs", Row.Distance)) end
        if Config.bState then
            local Value = Row.bAlive and (Record.Model:GetAttribute("State") or "存活") or "死亡"
            table.insert(Details, tostring(Value))
        end
        if #Details > 0 then table.insert(LabelRows, table.concat(Details, " · ")) end
        local Billboard = Record.Billboard
        Billboard.Adornee = Record.Model:FindFirstChild("Head") or Row.Part
        Billboard.AlwaysOnTop, Billboard.MaxDistance = Config.bThroughWalls, Config.EspDistance
        Billboard.Enabled = #LabelRows > 0
        Record.Label.Text, Record.Label.TextColor3 = table.concat(LabelRows, "\n"), Color
        if Config.bTracers then
            if not Record.Line then
                Record.Line = New("Frame", {
                    AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, Visible = false,
                    Active = false,
                }, State.Overlay)
            end
            Record.Line.BackgroundColor3 = Color
            Record.Line.BackgroundTransparency = Config.LineTransparency
        elseif Record.Line then Record.Line:Destroy(); Record.Line = nil end
    end
end

local function UpdateOverlay(Camera)
    for _, Record in pairs(State.Records) do
        if not Record.Line or not Record.Part then continue end
        local Point, bOnScreen = Camera:WorldToViewportPoint(Record.Part.Position)
        Record.Line.Visible = Config.bEsp and Config.bTracers and bOnScreen and Point.Z > 0
        if Record.Line.Visible then
            local A = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y - 6)
            local B = Vector2.new(Point.X, Point.Y)
            local Delta = B - A
            Record.Line.Position = UDim2.fromOffset((A.X + B.X) / 2, (A.Y + B.Y) / 2)
            Record.Line.Size = UDim2.fromOffset(Delta.Magnitude, 1)
            Record.Line.Rotation = math.deg(math.atan2(Delta.Y, Delta.X))
        end
    end
    local Circle = State.Circle
    Circle.Visible = Config.bRage and Config.bAimCircle and Config.AimAngle < 175
    if Circle.Visible then
        local Radius = Camera.ViewportSize.Y * 0.5 * math.tan(math.rad(Config.AimAngle * 0.5))
            / math.tan(math.rad(Camera.FieldOfView * 0.5))
        Circle.Position = UDim2.fromOffset(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        Circle.Size = UDim2.fromOffset(Radius * 2, Radius * 2)
        State.CircleStroke.Color = State.Target and Config.TargetColor or Config.EspColor
    end
end

local Controls = {}
local function Toggle(Section, Key, Name, Description, bSave)
    local Control = Section:CreateToggle({
        Name = Name, Description = Description, Flag = Key, bSave = bSave ~= false,
        bCurrentValue = Config[Key], Callback = function(Value) Config[Key] = Value end,
    })
    Controls[Key] = Control
    Config[Key] = Control:Get() == true
    return Control
end

local function Slider(Section, Key, Name, Minimum, Maximum, Step, Suffix)
    local Control = Section:CreateSlider({
        Name = Name, Flag = Key, CurrentValue = Config[Key], Range = { Minimum, Maximum },
        Increment = Step, Suffix = Suffix, Callback = function(Value) Config[Key] = Value end,
    })
    Controls[Key], Config[Key] = Control, Control:Get()
    return Control
end

local function Dropdown(Section, Key, Name, Options)
    local Control = Section:CreateDropdown({
        Name = Name, Flag = Key, Options = Options, CurrentOption = Config[Key],
        Callback = function(Value) Config[Key] = Value; State.Target = nil end,
    })
    Controls[Key], Config[Key] = Control, Control:Get()
    return Control
end

local function ColorPicker(Section, Key, Name)
    local Control = Section:CreateColorPicker({
        Name = Name, Flag = Key, Color = Config[Key], Callback = function(Value) Config[Key] = Value end,
    })
    Controls[Key], Config[Key] = Control, Control:Get()
end

local function Notify(Title, Content)
    Library:Notify({ Title = Title, Content = Content, Duration = 5 })
end

local function Diagnostic()
    return table.concat({
        "Ragdoll Delta Bjz v1.0.0", "PlaceId: " .. tostring(game.PlaceId),
        "PlaceVersion: " .. tostring(game.PlaceVersion), "NPC: " .. State.CandidateCount .. " / alive " .. State.AliveCount,
        "Status: " .. State.Status, "Mode: " .. Config.Mode, "Hook: " .. State.HookStatus,
        "Redirected rays: " .. State.RedirectedRays,
        "Weapon: " .. (State.Weapon and State.Weapon.Key or "none"), "Error: " .. State.LastError,
        "Anticheat bypass: unverified; server source unavailable",
    }, "\n")
end

local function Start()
    LoadGameModules()
    UpdateCallers()
    InstallDispatcher()
    assert(Library.ConfigurationVersion == 2, "請同步更新 BjzUiLibrary_2.0.luau 後再執行")
    local Window = Library:CreateWindow({
        Name = "Ragdoll Multiplayer", Subtitle = "NPC 透視 · Ragebot · Delta",
        ConfigId = "RagdollMultiplayer_" .. tostring(game.PlaceId), GameName = "RagdollMultiplayer", GameId = game.PlaceId, LegacyConfigIds = { "RDDelta_120421389568929_v1" }, Width = 800, Height = 560,
        MinWidth = 360, MinHeight = 300, bResizable = true, ToggleKey = Enum.KeyCode.RightShift,
        ConfigurationSaving = { bEnabled = true },
    })
    State.Window, State.DestroyWindow = Window, Window.Destroy
    Window.Destroy = function() State:Destroy() end
    State.Highlights = New("Folder", { Name = HttpService:GenerateGUID(false) }, Workspace.CurrentCamera or Workspace)
    State.Overlay = New("ScreenGui", {
        Name = HttpService:GenerateGUID(false), ResetOnSpawn = false, IgnoreGuiInset = true,
        DisplayOrder = math.max(1, Window.ScreenGui.DisplayOrder - 1),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, Window.ScreenGui.Parent)
    State.Circle = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1,
        BorderSizePixel = 0, Visible = false, Active = false,
    }, State.Overlay)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, State.Circle)
    State.CircleStroke = New("UIStroke", { Thickness = 1, Transparency = 0.3, Color = Config.EspColor }, State.Circle)

    local EspTab = Window:CreateTab("NPC 透視", "eye")
    local Esp = EspTab:CreateSection({ Name = "顯示內容", Side = "left" })
    Toggle(Esp, "bEsp", "啟用 NPC 透視", nil, false)
    Toggle(Esp, "bThroughWalls", "穿牆顯示")
    Toggle(Esp, "bShowDead", "顯示死亡 NPC")
    Toggle(Esp, "bNames", "顯示名稱")
    Toggle(Esp, "bDistance", "顯示距離")
    Toggle(Esp, "bState", "顯示狀態")
    Toggle(Esp, "bTracers", "顯示追蹤線")
    Slider(Esp, "EspDistance", "透視最遠距離", 50, 5000, 50, " studs")
    Slider(Esp, "MarkerLimit", "最多顯示數量", 10, 150, 1, "")
    local Style = EspTab:CreateSection({ Name = "外觀", Side = "right" })
    ColorPicker(Style, "EspColor", "存活 NPC 顏色")
    ColorPicker(Style, "DeadColor", "死亡 NPC 顏色")
    ColorPicker(Style, "TargetColor", "鎖定目標顏色")
    Slider(Style, "FillTransparency", "Highlight 填色透明度", 0, 1, 0.01, "")
    Slider(Style, "OutlineTransparency", "Highlight 輪廓透明度", 0, 1, 0.01, "")
    Slider(Style, "LineTransparency", "追蹤線透明度", 0, 1, 0.01, "")
    Style:CreateParagraph({ Title = "NPC 範圍", Content = "只顯示此場景的 Dummies；不把玩家角色當作 NPC。透明度 0 為不透明，1 為完全透明。" })

    local RageTab = Window:CreateTab("Ragebot", "crosshair")
    local Aim = RageTab:CreateSection({ Name = "目標與瞄準", Side = "left" })
    Toggle(Aim, "bRage", "啟用 Ragebot", "保留手動開火。開啟後縮小介面即可作用。", false)
    Dropdown(Aim, "Mode", "瞄準模式", { "射線瞄準", "鏡頭鎖定" })
    Dropdown(Aim, "AimPart", "瞄準部位", { "頭部", "胸口" })
    Dropdown(Aim, "Priority", "目標優先順序", { "準星最近", "距離最近" })
    Slider(Aim, "AimDistance", "最遠鎖定距離", 10, 3000, 10, " studs")
    Slider(Aim, "AimAngle", "鎖定角度", 10, 360, 5, "°")
    Slider(Aim, "Smoothness", "鏡頭鎖定速度", 0.05, 1, 0.05, "")
    local Filter = RageTab:CreateSection({ Name = "篩選與操作", Side = "right" })
    Toggle(Filter, "bVisibleOnly", "只鎖定無遮擋目標")
    Toggle(Filter, "bOnScreen", "只鎖定畫面內目標")
    Toggle(Filter, "bSticky", "持續鎖定目前目標")
    Toggle(Filter, "bFightersOnly", "只鎖定 Fighter NPC")
    Toggle(Filter, "bPauseWithUi", "顯示設定介面時暫停")
    Toggle(Filter, "bAimCircle", "顯示角度範圍圓")
    Filter:CreateParagraph({ Title = "模式說明", Content = "射線瞄準：保留目前視角，導向目標。若沒有改向計數，請改用鏡頭鎖定。\n鏡頭鎖定：鏡頭轉向 NPC。\n兩者都需要你自行按下遊戲開火鍵，並受武器射程與遮擋限制。" })

    local StatusTab = Window:CreateTab("狀態與設定", "settings")
    local StatusSection = StatusTab:CreateSection({ Name = "執行狀態", Side = "left" })
    State.StatusLabel = StatusSection:CreateLabel({ Name = "初始化中" })
    State.CountLabel = StatusSection:CreateLabel({ Name = "NPC：0 · 存活：0" })
    State.RayLabel = StatusSection:CreateLabel({ Name = "已改向射線：0" })
    StatusSection:CreateParagraph({ Title = "射線能力", Content = State.HookStatus })
    StatusSection:CreateParagraph({ Title = "反作弊：未驗證", Content = "場景檔缺少伺服器端程式，無法確認或保證繞過伺服器檢查。" })
    StatusSection:CreateButton({ Name = "複製診斷資訊", Callback = function()
        local Report = Diagnostic()
        if type(setclipboard) == "function" then
            local bOk = pcall(setclipboard, Report)
            if bOk then Notify("診斷資訊", "已複製，可貼回對話中檢查。") else warn(Report) end
        else warn(Report); Notify("診斷資訊", "此版本無剪貼簿 API，已輸出至 Console。") end
    end })
    local Settings = StatusTab:CreateSection({ Name = "控制", Side = "right" })
    Settings:CreateParagraph({ Title = "使用方式", Content = "啟用功能後，按 RightShift 或右上角縮小按鈕。觸控裝置可點可拖曳的小方塊還原。\n死亡 NPC 預設可透視；Ragebot 只選存活且已就緒的 NPC。" })
    Settings:CreateButton({ Name = "關閉全部功能", Callback = function()
        Config.bEsp, Config.bRage, State.Target = false, false, nil
        Controls.bEsp:Set(false, true); Controls.bRage:Set(false, true)
        UpdateVisuals()
        Notify("已關閉", "NPC 透視與 Ragebot 均已關閉。")
    end })
    Settings:CreateButton({ Name = "保存設定", Callback = function()
        local bOk, Reason = Window:SaveConfiguration()
        Notify("設定", bOk and "已保存。下次載入仍需手動啟用功能。" or tostring(Reason))
    end })
    Settings:CreateButton({ Name = "卸載腳本", Callback = function() State:Destroy() end })
    Window:CreateCursorSettings(Settings)
    if not (State.Bus and State.Bus.bReady) then
        Config.Mode = "鏡頭鎖定"; Controls.Mode:Set(Config.Mode, true)
    end
    Config.bEsp, Config.bRage = false, false
    Controls.bEsp:Set(false, true); Controls.bRage:Set(false, true)
    BindRoot()
    Connect(Workspace.ChildAdded, function(Child) if Child.Name == "Dummies" then BindRoot() end end)
    Connect(Workspace.ChildRemoved, function(Child) if Child == State.Root then BindRoot() end end)
    Connect(Workspace:GetPropertyChangedSignal("CurrentCamera"), function()
        State.Target = nil
        State.Highlights.Parent = Workspace.CurrentCamera or Workspace
    end)
    Connect(LocalPlayer.CharacterRemoving, function() State.Target, State.Weapon = nil, nil end)
    Connect(UserInputService.WindowFocused, function() State.bFocused = true end)
    Connect(UserInputService.WindowFocusReleased, function() State.bFocused = false; State.Target = nil end)

    local Accum, SlowAccum = 0, 0
    Connect(RunService.Heartbeat, function(Dt)
        if not State.bRunning then return end
        Accum += Dt; SlowAccum += Dt
        if Accum < 0.075 then return end
        Accum = 0
        local bOk, Reason = pcall(function()
            SelectTarget()
            UpdateVisuals()
            if SlowAccum >= 0.5 then
                SlowAccum = 0
                UpdateCallers()
                if not State.Root then BindRoot() end
                State.StatusLabel:Set(State.Status)
                State.CountLabel:Set("NPC：" .. State.CandidateCount .. " · 存活：" .. State.AliveCount)
                State.RayLabel:Set("已改向射線：" .. State.RedirectedRays)
            end
        end)
        if not bOk then State.LastError, State.Status, State.Target = tostring(Reason), "發生錯誤；可複製診斷資訊", nil end
    end)
    RunService:BindToRenderStep(State.RenderName, Enum.RenderPriority.Camera.Value + 3, function(Dt)
        if not State.bRunning then return end
        local Camera = Workspace.CurrentCamera
        if not Camera then return end
        local bOk, Reason = pcall(function()
            local Target = State.Target
            if Config.Mode == "鏡頭鎖定" and not BlockReason() and Target
                and os.clock() - State.TargetAt <= 0.25 and IsAlive(Target.Model)
                and Target.Part.Parent == Target.Model then
                local Position = Camera.CFrame.Position
                if (Target.Part.Position - Position).Magnitude > 0.001 then
                    local Alpha = 1 - (1 - Config.Smoothness) ^ (math.clamp(Dt, 0, 0.1) * 60)
                    Camera.CFrame = Camera.CFrame:Lerp(CFrame.lookAt(Position, Target.Part.Position), Alpha)
                end
            end
            UpdateOverlay(Camera)
        end)
        if not bOk then State.LastError = tostring(Reason) end
    end)
    Notify("載入完成", "先啟用 NPC 透視／Ragebot。Ragebot 啟用後請縮小介面，再手動開火。")
end

local bStarted, StartError = xpcall(Start, function(Message) return debug.traceback(tostring(Message), 2) end)
if not bStarted then
    State:Destroy()
    error("[Ragdoll Delta] 初始化失敗：\n" .. tostring(StartError), 0)
end

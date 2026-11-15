-- SEAR | BjzUi ESP + Silent Aim
-- Target place: 128818711682777 (snapshot supplied by user)
-- Runtime: Delta Executor; uses loadstring() to load BjzUi from a local file or optional raw URL.
-- The game uses Chickynoid client command fa/fo; this script does not forge hit confirmation.

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- Rerunning closes the prior UI/overlay and disables/restores the prior hook.
local Environment = type(getgenv) == "function" and getgenv() or _G
if Environment.__SEAR_BJZ_HUB and type(Environment.__SEAR_BJZ_HUB.Shutdown) == "function" then
    pcall(Environment.__SEAR_BJZ_HUB.Shutdown)
end

local Hub = { Active = true, Connections = {}, Records = {}, HookMode = "未安裝" }
Environment.__SEAR_BJZ_HUB = Hub

local State = {
    Esp = false, EspBox = true, EspHighlight = true, EspTracer = false,
    EspName = true, EspDistanceText = true, EspBots = false,
    EspMaxDistance = 1200, TeamCheck = true,
    Aim = false, AimHead = true, AimBots = false, AimVisible = true,
    AimFov = 200, AimMaxDistance = 1200, FovCircle = true,
    EspColor = Color3.fromRGB(60, 213, 255),
    TargetColor = Color3.fromRGB(255, 96, 112),
}

local function SafeRequire(instance)
    if not instance then return nil end
    local ok, result = pcall(require, instance)
    if ok then return result end
    warn("[SEAR] 模組載入失敗:", instance:GetFullName(), tostring(result))
    return nil
end

local function Nested(root, ...)
    local current = root
    for _, name in ipairs({...}) do
        if not current then return nil end
        current = current:FindFirstChild(name)
    end
    return current
end

local ClientModule = SafeRequire(Nested(ReplicatedStorage, "Client", "System", "Chickynoid", "Core", "ClientModule"))
local BodyIdentity = SafeRequire(Nested(ReplicatedStorage, "Client", "System", "Chickynoid", "Core", "BodyIdentity"))
local ClientMods = SafeRequire(Nested(ReplicatedStorage, "Client", "System", "Chickynoid", "Core", "ClientMods"))
local Ballistics = SafeRequire(Nested(ReplicatedStorage, "Shared", "Features", "Gun", "Ballistics"))
local Enemy = SafeRequire(Nested(ReplicatedStorage, "Shared", "Features", "Enemy"))

local function ModuleForCommands()
    -- The game registers GenerateCommand in the `clientmods` registry.
    if ClientMods and type(ClientMods.GetMod) == "function" then
        local ok, result = pcall(function()
            return ClientMods:GetMod("clientmods", "GenerateCommand")
        end)
        if ok and result and type(result.GenerateCommand) == "function" then
            return result
        end
    end
    -- Fallback for snapshots where registration has not completed yet.
    local root = Nested(ReplicatedStorage, "Client", "System", "Chickynoid")
    if root then
        local target = root:FindFirstChild("GenerateCommand", true)
        if target and target:IsA("ModuleScript") then
            return SafeRequire(target)
        end
    end
    return nil
end

local function IsBot(id)
    if Enemy and type(Enemy.IsBotId) == "function" then
        local ok, result = pcall(Enemy.IsBotId, id)
        if ok then return result == true end
    end
    return Players:GetPlayerByUserId(id) == nil
end

local function IsTeammate(id)
    if id == LocalPlayer.UserId then return true end
    if not State.TeamCheck then return false end
    if BodyIdentity and type(BodyIdentity.IsTeammateBody) == "function" then
        local ok, result = pcall(BodyIdentity.IsTeammateBody, id)
        if ok then return result == true end
    end
    local other = Players:GetPlayerByUserId(id)
    return other ~= nil and LocalPlayer.Team ~= nil and other.Team == LocalPlayer.Team
end

local function CurrentCamera()
    return workspace.CurrentCamera
end

local function ExtractModel(entry, player)
    if entry then
        local cm = entry.characterModel
        if cm and not cm.destroyed and not cm.corpseOwned and not cm.ragdollLatched then
            local model = cm.model
            if typeof(model) == "Instance" and model:IsA("Model") and model.Parent then
                return model
            end
        end
        -- Skip invalid/destroyed custom characters; don't ESP an old Player.Character.
        return nil
    end
    local model = player and player.Character
    if model and model.Parent and model:IsA("Model") then return model end
    return nil
end

local function ExtractPosition(entry, model)
    if entry and typeof(entry.position) == "Vector3" then
        return entry.position
    end
    local root = model and (model.PrimaryPart or model:FindFirstChild("HumanoidRootPart"))
    if root and root:IsA("BasePart") then return root.Position end
    if model then
        local ok, pivot = pcall(function() return model:GetPivot() end)
        if ok then return pivot.Position end
    end
    return nil
end

local function AimPoint(entry, model, base, head)
    local data = entry and entry.characterData
    if entry and base and Ballistics and type(Ballistics.HitBoxOf) == "function" then
        local stance = 0
        if type(Ballistics.StanceOf) == "function" then
            local ok, result = pcall(Ballistics.StanceOf, data and data.crouched, data and data.downed)
            if ok and type(result) == "number" then stance = result end
        end
        local ok, size, offset = pcall(Ballistics.HitBoxOf, stance)
        if ok and typeof(size) == "Vector3" and type(offset) == "number" then
            return base + Vector3.new(0, offset + (head and size.Y * 0.35 or 0), 0)
        end
    end
    if model then
        local part = model:FindFirstChild(head and "Head" or "UpperTorso", true)
        if part and part:IsA("BasePart") then return part.Position end
    end
    return base and (base + Vector3.new(0, head and 3.9 or 2.5, 0)) or nil
end

local function IterateCharacters(action)
    local visited = {}
    if ClientModule and type(ClientModule.characters) == "table" then
        for key, entry in pairs(ClientModule.characters) do
            local id = tonumber(key)
            if id and id ~= LocalPlayer.UserId and type(entry) == "table" then
                visited[id] = true
                local player = Players:GetPlayerByUserId(id)
                local model = ExtractModel(entry, player)
                local pos = model and ExtractPosition(entry, model)
                if model and pos then action(id, player, entry, model, pos) end
            end
        end
    end
    for _, player in ipairs(Players:GetPlayers()) do
        local id = player.UserId
        if id ~= LocalPlayer.UserId and not visited[id] then
            local model = ExtractModel(nil, player)
            local pos = model and ExtractPosition(nil, model)
            if model and pos then action(id, player, nil, model, pos) end
        end
    end
end

local function VisibleFrom(origin, targetPosition, model)
    local ray = targetPosition - origin
    if ray.Magnitude <= 0.1 then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    local exclude = {}
    if LocalPlayer.Character then table.insert(exclude, LocalPlayer.Character) end
    if ClientModule and ClientModule.characterModel and ClientModule.characterModel.model then
        table.insert(exclude, ClientModule.characterModel.model)
    end
    params.FilterDescendantsInstances = exclude
    local ok, result = pcall(function() return workspace:Raycast(origin, ray, params) end)
    return ok and (result == nil or result.Instance:IsDescendantOf(model))
end

local Selected = nil
local function GetBestTarget(origin)
    local camera = CurrentCamera()
    if not camera then return nil end
    local center = camera.ViewportSize * 0.5
    local bestScore = State.AimFov
    local best = nil
    local originPos = typeof(origin) == "Vector3" and origin or camera.CFrame.Position
    IterateCharacters(function(id, player, entry, model, base)
        if IsTeammate(id) or (IsBot(id) and not State.AimBots) then return end
        if (base - originPos).Magnitude > State.AimMaxDistance then return end
        local point = AimPoint(entry, model, base, State.AimHead)
        if not point then return end
        local v, onScreen = camera:WorldToViewportPoint(point)
        if not onScreen or v.Z <= 0 then return end
        local pxDist = (Vector2.new(v.X, v.Y) - center).Magnitude
        if pxDist >= bestScore then return end
        if State.AimVisible and not VisibleFrom(originPos, point, model) then return end
        bestScore = pxDist
        best = { Id = id, Player = player, Model = model, Point = point }
    end)
    Selected = best
    return best
end

local function ModifyCommand(command)
    if not State.Aim or not Hub.Active or type(command) ~= "table" then return end
    -- Only manipulate actual firearm commands. Don't alter movement, reload, melee or throwables.
    if command.f ~= 1 or command.fireIntent ~= 1 or not command.gunStateEpoch or command.gunStateEpoch == 0 then
        return
    end
    if typeof(command.fo) ~= "Vector3" then return end
    local target = GetBestTarget(command.fo)
    if target then
        local delta = target.Point - command.fo
        if delta.Magnitude > 0.1 then
            -- Same 2000-stud aim length used by SEAR CameraModule.GetShotRay().
            command.fa = command.fo + delta.Unit * 2000
        end
    end
end

-- Silent aim modifies the native Chickynoid command BEFORE simulation/network serialization.
-- hookfunction replaces its shared closure; the table-property fallback is reversible.
local CommandModule, OriginalCommand, PatchedCommand, HookedFunction
local function InstallHook()
    CommandModule = ModuleForCommands()
    if not CommandModule or type(CommandModule.GenerateCommand) ~= "function" then
        Hub.HookMode = "找不到 GenerateCommand"
        return false
    end
    OriginalCommand = CommandModule.GenerateCommand
    local replacement = function(...)
        local result = OriginalCommand(...)
        if Hub.Active and State.Aim then
            local ok, err = pcall(ModifyCommand, result)
            if not ok then warn("[SEAR] Silent Aim:", err) end
        end
        return result
    end
    -- Direct table replacement works with ClientMods:GetMods(). It avoids disturbing other closures.
    local success = pcall(function()
        CommandModule.GenerateCommand = replacement
        assert(CommandModule.GenerateCommand == replacement)
    end)
    if success then
        PatchedCommand = replacement
        Hub.HookMode = "GenerateCommand · ClientMods"
        return true
    end
    -- sUNC fallback for a read-only module (game-specific module rather than a remote spoof).
    if type(hookfunction) == "function" then
        local wrapping = type(newcclosure) == "function" and newcclosure or function(f) return f end
        local old
        local cb = wrapping(function(...)
            local result = old(...)
            if Hub.Active and State.Aim then pcall(ModifyCommand, result) end
            return result
        end)
        local ok, orig = pcall(hookfunction, OriginalCommand, cb)
        if ok and type(orig) == "function" then
            old = orig
            HookedFunction = OriginalCommand
            Hub.HookMode = "GenerateCommand · sUNC hookfunction"
            return true
        end
    end
    Hub.HookMode = "Hook 安裝失敗"
    return false
end

-- Use Rbx UI objects instead of Drawing, which is not uniformly available on mobile Delta.
local function OverlayParent()
    if type(gethui) == "function" then
        local ok, result = pcall(gethui)
        if ok and typeof(result) == "Instance" then return result end
    end
    local ok = pcall(function() return CoreGui.Name end)
    if ok then return CoreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local Overlay = Instance.new("ScreenGui")
Overlay.Name = "SEAR_HUD_" .. tostring(math.random(100000,999999))
Overlay.IgnoreGuiInset = true
Overlay.ResetOnSpawn = false
Overlay.DisplayOrder = 150
Overlay.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Overlay.Parent = OverlayParent()
Hub.Overlay = Overlay

local function Frame(name, parent)
    local f = Instance.new("Frame")
    f.Name = name
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.Visible = false
    f.Parent = parent
    return f
end
local function Text(name, parent, size, y)
    local t = Instance.new("TextLabel")
    t.Name = name
    t.BackgroundTransparency = 1
    t.BorderSizePixel = 0
    t.Font = Enum.Font.GothamBold
    t.TextSize = size
    t.TextStrokeTransparency = 0.3
    t.TextXAlignment = Enum.TextXAlignment.Center
    t.TextColor3 = State.EspColor
    t.Text = ""
    t.Size = UDim2.new(1, 80, 0, 18)
    t.Position = UDim2.new(0, -40, 0, y)
    t.Parent = parent
    return t
end
local function Stroke(parent, thickness)
    local s = Instance.new("UIStroke")
    s.Thickness = thickness or 1.5
    s.Color = State.EspColor
    s.Parent = parent
    return s
end

local Fov = Frame("AimFOV", Overlay)
Fov.AnchorPoint = Vector2.new(0.5, 0.5)
Fov.ZIndex = 8
local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = Fov
local fovStroke = Stroke(Fov, 1.5)
fovStroke.Color = State.TargetColor
fovStroke.Transparency = 0.2

local function CreateRecord(id)
    local holder = Frame("Player_"..tostring(id), Overlay)
    holder.ZIndex = 9
    local outline = Stroke(holder, 1.6)
    local name = Text("Name", holder, 13, -20)
    local distance = Text("Distance", holder, 12, 0)
    local tracer = Frame("Tracer", Overlay)
    tracer.AnchorPoint = Vector2.new(0.5, 0.5)
    tracer.BackgroundTransparency = 0
    tracer.ZIndex = 8
    local record = { Frame = holder, Stroke = outline, Name = name, Distance = distance,
                     Tracer = tracer, Model = nil, Highlight = nil }
    Hub.Records[id] = record
    return record
end

local function DestroyRecord(id)
    local record = Hub.Records[id]
    if not record then return end
    if record.Highlight then record.Highlight:Destroy() end
    if record.Frame then record.Frame:Destroy() end
    if record.Tracer then record.Tracer:Destroy() end
    Hub.Records[id] = nil
end

local function ShowHighlight(record, model, color)
    if record.Model ~= model then
        if record.Highlight then record.Highlight:Destroy() end
        record.Model = model
        record.Highlight = nil
    end
    if not record.Highlight then
        local hl = Instance.new("Highlight")
        hl.Name = "SEAR_PlayerOutline"
        hl.Adornee = model
        hl.FillTransparency = 0.84
        hl.OutlineTransparency = 0
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.Parent = CurrentCamera() or workspace
        record.Highlight = hl
    end
    record.Highlight.OutlineColor = color
    record.Highlight.FillColor = color
    record.Highlight.Enabled = true
end

local function HideRecord(record)
    record.Frame.Visible = false
    record.Tracer.Visible = false
    if record.Highlight then record.Highlight.Enabled = false end
end

local function DrawESP()
    local camera = CurrentCamera()
    if not camera then return end
    local center = camera.ViewportSize / 2
    Fov.Visible = State.Aim and State.FovCircle
    Fov.Size = UDim2.fromOffset(State.AimFov * 2, State.AimFov * 2)
    Fov.Position = UDim2.fromOffset(center.X, center.Y)
    if not State.Esp then
        for _, record in pairs(Hub.Records) do HideRecord(record) end
        return
    end
    local live = {}
    local myself = ClientModule and ClientModule.characterModel and ClientModule.characterModel.model
    local origin = (myself and myself.PrimaryPart and myself.PrimaryPart.Position) or camera.CFrame.Position
    IterateCharacters(function(id, player, entry, model, base)
        if IsTeammate(id) or (IsBot(id) and not State.EspBots) then return end
        if (base - origin).Magnitude > State.EspMaxDistance then return end
        local record = Hub.Records[id] or CreateRecord(id)
        live[id] = true
        local head = AimPoint(entry, model, base, true) or base + Vector3.new(0, 4, 0)
        local foot = base - Vector3.new(0, 0.35, 0)
        local headScreen, inFront = camera:WorldToViewportPoint(head)
        local footScreen = camera:WorldToViewportPoint(foot)
        if not inFront or headScreen.Z <= 0 then HideRecord(record); return end
        local h = math.abs(footScreen.Y - headScreen.Y)
        if h < 4 then HideRecord(record); return end
        local w = math.max(8, h * 0.5)
        local x = (headScreen.X + footScreen.X) * 0.5
        local top = math.min(headScreen.Y, footScreen.Y)
        local distance = math.floor((base - origin).Magnitude + 0.5)
        local color = Selected and Selected.Id == id and State.Aim and State.TargetColor or State.EspColor
        record.Frame.Visible = State.EspBox or State.EspName or State.EspDistanceText
        record.Frame.Position = UDim2.fromOffset(x - w/2, top)
        record.Frame.Size = UDim2.fromOffset(w, h)
        record.Frame.BackgroundTransparency = 1
        record.Stroke.Enabled = State.EspBox
        record.Stroke.Color = color
        local displayName = player and player.DisplayName or (entry and entry.characterModel and entry.characterModel.ownerPlayer and entry.characterModel.ownerPlayer.DisplayName) or ("BOT " .. tostring(id))
        record.Name.Visible = State.EspName
        record.Name.Text = displayName
        record.Name.TextColor3 = color
        record.Distance.Visible = State.EspDistanceText
        record.Distance.Text = string.format("%d studs", distance)
        record.Distance.TextColor3 = color
        record.Distance.Position = UDim2.new(0, -40, 1, 0)
        local tracer = record.Tracer
        tracer.Visible = State.EspTracer
        if State.EspTracer then
            local start = Vector2.new(center.X, camera.ViewportSize.Y - 8)
            local finish = Vector2.new(x, top + h)
            local diff = finish - start
            tracer.Size = UDim2.fromOffset(diff.Magnitude, 1.5)
            tracer.Position = UDim2.fromOffset((start.X + finish.X) / 2, (start.Y + finish.Y) / 2)
            tracer.Rotation = math.deg(math.atan2(diff.Y, diff.X))
            tracer.BackgroundColor3 = color
        end
        if State.EspHighlight then
            ShowHighlight(record, model, color)
        elseif record.Highlight then
            record.Highlight.Enabled = false
        end
    end)
    for id in pairs(Hub.Records) do
        if not live[id] then DestroyRecord(id) end
    end
end

-- === BjzUi 動態載入（不是將 Library 內嵌在主腳本）============================
-- 本地模式（預設）：將 BjzUiLibrary_2.0.luau 放在 Delta workspace 根目錄。
-- 遠端模式（選用）：若將 Library 原始碼放到可公開讀取的 HTTPS raw URL，
-- 請填入下方 LibraryRawUrl；不要填 GitHub 一般網頁的 /blob/ 連結。
local LibraryRawUrl = ""
local LibraryFileNames = { "BjzUiLibrary_2.0.luau", "BjzUiLibrary_2.0(2).luau" }

local function CompileLibrary(source, origin)
    if type(source) ~= "string" or source == "" then
        return nil, tostring(origin) .. ": 函數庫內容為空"
    end
    if type(loadstring) ~= "function" then
        return nil, "執行器不支援 loadstring"
    end
    -- 核心載入方式：loadstring(函數庫原始碼)()
    local compiled, compileError = loadstring(source)
    if not compiled then return nil, tostring(origin) .. ": " .. tostring(compileError) end
    local loaded, library = pcall(compiled)
    if not loaded then return nil, tostring(origin) .. ": " .. tostring(library) end
    if type(library) ~= "table" or type(library.CreateWindow) ~= "function" then
        return nil, tostring(origin) .. ": 沒有回傳正確的 BjzUi Library"
    end
    return library
end

local function LoadBjzUi(CacheSource: string?)
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

local okLibrary, BjzUi = pcall(LoadBjzUi)
if not okLibrary then
    Hub.Active = false
    Overlay:Destroy()
    error(BjzUi)
end
-- ===============================================================================

local Window = BjzUi:CreateWindow({
    Name = "SEAR · ESP / Silent Aim",
    Subtitle = "Chickynoid · Delta · BjzUi 3.0 API",
    ConfigId = "SEAR_EspSilentAim_v1",
    Width = 920, Height = 660,
    ToggleKey = Enum.KeyCode.RightShift,
    bResizable = true,
    ConfigurationSaving = { bEnabled = true },
})
Hub.Window = Window

local TabEsp = Window:CreateTab("玩家透視", "eye")
local SecEsp = TabEsp:CreateSection({ Name = "透視功能", Side = "left" })
local SecEspStyle = TabEsp:CreateSection({ Name = "視覺與篩選", Side = "right" })
local TabAim = Window:CreateTab("Silent Aim", "crosshair")
local SecAim = TabAim:CreateSection({ Name = "瞄準設定", Side = "left" })
local SecAimFilter = TabAim:CreateSection({ Name = "目標條件", Side = "right" })
local TabMisc = Window:CreateTab("系統", "settings")
local SecMisc = TabMisc:CreateSection({ Name = "執行資訊", Side = "left" })

local Controls = {}
local function Toggle(section, field, label, description)
    local ctrl = section:CreateToggle({
        Name = label, Description = description, Flag = field,
        bCurrentValue = State[field],
        Callback = function(value) State[field] = value == true end,
    })
    Controls[#Controls + 1] = { field, ctrl }
    return ctrl
end
local function Slider(section, field, label, low, high, step, suffix)
    local ctrl = section:CreateSlider({
        Name = label, Range = { low, high }, Increment = step,
        CurrentValue = State[field], Suffix = suffix, Flag = field,
        Callback = function(value) State[field] = value end,
    })
    Controls[#Controls + 1] = { field, ctrl }
    return ctrl
end

Toggle(SecEsp, "Esp", "玩家透視 · ESP")
Toggle(SecEsp, "EspHighlight", "穿牆描邊 · Highlight")
Toggle(SecEsp, "EspBox", "2D 方框")
Toggle(SecEsp, "EspTracer", "方向指引線")
Toggle(SecEsp, "EspName", "顯示玩家名稱")
Toggle(SecEsp, "EspDistanceText", "顯示距離")
Slider(SecEsp, "EspMaxDistance", "透視最大距離", 100, 2500, 50, " studs")
Toggle(SecEspStyle, "TeamCheck", "不顯示隊友 · 排除隊友")
Toggle(SecEspStyle, "EspBots", "包含 NPC / BOT")
local espPicker = SecEspStyle:CreateColorPicker({
    Name = "ESP 顏色", Flag = "EspColor", Color = State.EspColor,
    Callback = function(color) if typeof(color) == "Color3" then State.EspColor = color end end,
})

Toggle(SecAim, "Aim", "開啟 Silent Aim", "只有實際開火時才修改 fa/fo 射擊指令")
Slider(SecAim, "AimFov", "瞄準 FOV（像素）", 25, 550, 5, " px")
Slider(SecAim, "AimMaxDistance", "最大射擊距離", 100, 2500, 50, " studs")
Toggle(SecAim, "FovCircle", "顯示 FOV 圈")
Toggle(SecAimFilter, "AimHead", "優先瞄準頭部")
Toggle(SecAimFilter, "AimVisible", "僅選擇無遮擋目標")
Toggle(SecAimFilter, "AimBots", "允許瞄準 NPC / BOT")
local aimPicker = SecAimFilter:CreateColorPicker({
    Name = "鎖定目標顏色", Flag = "TargetColor", Color = State.TargetColor,
    Callback = function(color) if typeof(color) == "Color3" then State.TargetColor = color end end,
})

-- Read back saved controls: library does not emit callbacks on initial load.
for _, pair in ipairs(Controls) do
    local value = pair[2]:Get()
    if value ~= nil then State[pair[1]] = value end
end
local okColor, savedColor = pcall(function() return espPicker:Get() end)
if okColor and typeof(savedColor) == "Color3" then State.EspColor = savedColor end
local okTargetColor, savedTargetColor = pcall(function() return aimPicker:Get() end)
if okTargetColor and typeof(savedTargetColor) == "Color3" then State.TargetColor = savedTargetColor end

local hookInstalled = InstallHook()
SecMisc:CreateParagraph({
    Title = "遊戲機制",
    Content = "SEAR 使用 Chickynoid。Silent Aim 改寫 GenerateCommand 的 fa 目標，不修改鏡頭、不偽造 GunHitReport。伺服器可能驗證視角與彈道，因此不保證命中。",
})
SecMisc:CreateParagraph({
    Title = "Hook 狀態",
    Content = Hub.HookMode .. (hookInstalled and " · 已準備" or " · 只提供透視功能"),
})
SecMisc:CreateParagraph({
    Title = "按鍵與儲存",
    Content = "RightShift 顯示/隱藏 UI。設定儲存在 Delta workspace/BjzUi/UiConfig.json 的 SEAR_EspSilentAim_v1 分組。",
})
SecMisc:CreateButton({
    Name = "手動儲存所有設定",
    Callback = function()
        local success, info = Window:SaveConfiguration()
        Window:Notify({ Title = success and "已儲存" or "儲存失敗", Content = tostring(info or "") })
    end,
})

function Hub.Shutdown()
    if not Hub.Active then return end
    Hub.Active = false
    if CommandModule and PatchedCommand and CommandModule.GenerateCommand == PatchedCommand then
        pcall(function() CommandModule.GenerateCommand = OriginalCommand end)
    end
    if HookedFunction and type(restorefunction) == "function" then
        pcall(restorefunction, HookedFunction)
    end
    for _, connection in ipairs(Hub.Connections) do pcall(function() connection:Disconnect() end) end
    for id in pairs(Hub.Records) do DestroyRecord(id) end
    if Overlay and Overlay.Parent then Overlay:Destroy() end
    if Window and not Window.bDestroyed then pcall(function() Window:Destroy() end) end
    if Environment.__SEAR_BJZ_HUB == Hub then Environment.__SEAR_BJZ_HUB = nil end
end

SecMisc:CreateButton({ Name = "卸載腳本並還原", Style = "outline", Callback = function() Hub.Shutdown() end })

local elapsed = 0
Hub.Connections[#Hub.Connections + 1] = RunService.RenderStepped:Connect(function(dt)
    if not Hub.Active then return end
    elapsed = elapsed + dt
    if elapsed < 1 / 25 then return end
    elapsed = 0
    if State.Aim and not State.Esp then
        -- Also update selected target for visual tracking when ESP is switched off.
        GetBestTarget(nil)
    elseif not State.Aim then
        Selected = nil
    end
    local ok, err = pcall(DrawESP)
    if not ok then warn("[SEAR] ESP:", err) end
end)

Window:Notify({
    Title = hookInstalled and "SEAR 已載入" or "SEAR 部分載入",
    Content = hookInstalled and "ESP + Silent Aim 已準備，按 RightShift 切換 UI" or "Silent Aim 模組未就緒；ESP 可使用",
    Duration = 6,
})
print("[SEAR] Loaded. PlaceId:", game.PlaceId, "hook:", Hub.HookMode)

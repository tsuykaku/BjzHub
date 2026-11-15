--!nonstrict
--[[
    OW_Sawang / place 13622622708 / Delta / BjzUi 3.x
    Based on the supplied place version 319 (2026-11-05).

    Usage: execute this entire file in Delta after entering the playable map.
    UI is downloaded with loadstring from the exact URL supplied by the user.
    UI is explicitly parented to CoreGui. ESP uses pooled native Highlight, BillboardGui and Frame instances.
    Live positions update every render frame; actor metadata is updated in batches.
    Environment buttons permanently delete grass, bushes and leaves on this client.
    Enable the requested ESP categories and Ragebot in the UI. Shooting is manual.

    Enemy, surrendered enemy NPC, friendly and item ESP have independent switches.
    Live surrender detection combines model state and animation events. A hostile
    NPC retains its hostile origin when surrender also changes its faction flag.
    Surrendered enemy NPCs are excluded from camera lock and redirection.
    Unknown affiliation is ignored. Humanoids used by foliage are excluded.
    Ragebot = camera lock + optional local Discharge hook. Shooting is manual.
    The hook preserves the muzzle position, caliber, UID and all other arguments.
    It only redirects calls with the game's explicit Local flag equal to true.
    It never alters other players' or NPCs' replicated projectiles.

    LIMITATIONS:
    The supplied save omits Flux/client and all server code. Live actor tables
    are resolved by UID and nested render references at runtime.
    No anti-cheat bypass is included; UI parenting is not such a bypass.
    The server can reject a modified shot. Vehicle hits require live verification. Counters in Settings help distinguish these cases.
    No guessed RemoteEvent payloads, fabricated hits or blanket Kick hooks.
    Unload restores owned hooks and disconnects events. No firing input is synthesized.
]]

local UI_URL = "https://raw.githubusercontent.com/tsuykaku/BjzHub/refs/heads/main/Library/BjzUiLibrary_2.0.luau"
local VERSION = "1.7.1"
local ENV = (type(getgenv) == "function" and getgenv()) or _G
local INSTANCE_KEY = "__OW_SAWANG_BJZ_V1"

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
assert(LocalPlayer, "請在 Rbx 用戶端執行。")

-- Load and validate the library before replacing an existing session.
local bLibraryOK, LibraryOrError = pcall(function()
    local Source = game:HttpGet(UI_URL)
    assert(type(Source) == "string" and #Source > 100, "UI Library 回應不完整。")
    local Chunk, CompileError = loadstring(Source, "BjzUiLibrary")
    assert(Chunk, CompileError)
    local Result = Chunk()
    assert(type(Result) == "table" and type(Result.CreateWindow) == "function",
        "UI Library 沒有 CreateWindow。")
    return Result
end)
if not bLibraryOK then error("[OW] UI 載入失敗：" .. tostring(LibraryOrError), 0) end
local Library = LibraryOrError

local Previous = ENV[INSTANCE_KEY]
if type(Previous) == "table" and type(Previous.Destroy) == "function" then
    pcall(Previous.Destroy, Previous)
end

local Config = {
    bEnemyESP = false, bSurrenderedESP = false, bFriendlyESP = false, bItemESP = false,
    bUnknownESP = true, bHighlight = true, bTracers = false, TracerOrigin = "Bottom",
    bHighlightFill = false, HighlightOutlineTransparency = 0, HighlightFillTransparency = 0.75,
    bNames = true, bHealth = true, ESPDistance = 3000, ItemDistance = 1500,
    MaxActors = 60, MaxItems = 30, ESPInterval = 0.25, TargetInterval = 0.1,
    EnemyColor = Color3.fromRGB(255, 84, 98),
    SurrenderedColor = Color3.fromRGB(183, 140, 255),
    FriendlyColor = Color3.fromRGB(83, 214, 156),
    ItemColor = Color3.fromRGB(255, 211, 89),
    UnknownColor = Color3.fromRGB(255, 173, 77),
    bRage = false, bPlayers = true, bNPCs = true,
    bDischarge = true, bPrediction = true,
    bPauseUI = false, bLineOfSight = true,
    AimPart = "Head", Priority = "Crosshair", AimFOV = 120,
    AimDistance = 2500, FallbackVelocity = 2800,
    NoTeamPolicy = "Ignore",
    bPickupTeleport = true, PickupTimeout = 12,
}

local State = {
    __OWOwned = true,
    bAlive = true, bFocused = true, bScanning = false,
    Actors = {}, Items = {}, Visuals = {}, Connections = {}, Hooks = {},
    RuntimeByModel = setmetatable({}, {__mode = "k"}), RuntimeByUID = {},
    Profiles = {}, Pending = {}, Dirty = {}, ModuleByName = {}, Controls = {}, HostileUIDs = {},
    Target = nil, BulletService = nil, ShotVelocity = nil,
    ShotRange = nil, ShotSeen = 0, LocalShotSeen = 0, Redirected = 0,
    HookStatus = "尚未連接", AimStatus = "停用", LastError = "無", Rendered = 0,
    ScanStatus = "等待掃描", UnknownCount = 0,
    SurrenderTransitions = 0, LastTransition = "無",
    DrawList = {}, DrawRecords = {}, DrawPool = {},
    ActorList = {}, ActorCursor = 1,
    PlayerByUID = {}, PlayerByUserId = {},
    PlayerByCharacter = {}, LocalActorUIDs = {},
    bOpenWorld = game.PlaceId == 13622622708,
    ItemCatalog = {}, ItemAliases = {}, ItemRuntime = setmetatable({}, {__mode = "k"}),
    ItemCandidates = setmetatable({}, {__mode = "k"}), ItemSources = {},
    PickupPrompts = setmetatable({}, {__mode = "k"}), PickupIds = setmetatable({}, {__mode = "k"}),
    PickupById = {}, NextPickupId = 0, PickupStatus = "選擇物品後按下取得", ActivePickup = nil,
    PickupAppliedOptions = nil, PickupListPending = false, PickupCharacterStatus = "尚未解析角色",
    Perf = {Classifications = 0, Raycasts = 0, Bounds = 0, RenderMs = 0, Created = 0},
    VisualStatus = "正在初始化原生 GUI", VisualReady = false,
    VisualIssues = {}, VisualFailures = 0,
    RegistrySources = {}, RegistrySeen = {},
    FoliageJobs = {}, FoliageRemoved = 0,
    EnvironmentStatus = "尚未刪除草木",
    RenderName = "OW_" .. HttpService:GenerateGUID(false),
}
ENV[INSTANCE_KEY] = State

local Window
local _RefreshModules, _ScanRuntime, _SelectTarget
local _TryActor, _TryItem, _RefreshVisuals, _RefreshStatus, _RemoveVisual
local _IndexWorldItem, _LoadItemCatalog
local _RefreshPickupList
local PickupDropdown, PickupButton, PickupReadout
local FIELD_KEYS = {}
local META_KEYS = {"State", "Data", "Stats", "Actor", "Config", "Preset"}

local function _Connect(Signal, Callback)
    local Connection = Signal:Connect(Callback)
    table.insert(State.Connections, Connection)
    return Connection
end

local function _Error(Context, Message)
    State.LastError = Context .. ": " .. tostring(Message)
    warn("[OW] " .. State.LastError)
end

local function _Notify(Title, Content)
    pcall(function() Library:Notify({Title = Title, Content = Content, Duration = 5}) end)
end

local function _Raw(Object, Key)
    if type(Object) == "table" then
        local Keys = FIELD_KEYS[Key]
        if not Keys then
            local Lower = string.lower(string.sub(Key, 1, 1)) .. string.sub(Key, 2)
            Keys = {Key, "_" .. Key, Lower, "_" .. Lower, string.lower(Key), "_" .. string.lower(Key)}
            FIELD_KEYS[Key] = Keys
        end
        for _, Name in ipairs(Keys) do
            local Value = rawget(Object, Name)
            if Value ~= nil then return Value end
        end
    end
    return nil
end

local function _Attribute(Object, Key)
    if typeof(Object) == "Instance" then return Object:GetAttribute(Key) end
    return nil
end

local function _First(...)
    for Index = 1, select("#", ...) do
        local Value = select(Index, ...)
        if Value ~= nil then return Value end
    end
    return nil
end

local function _NormalizeGroup(Value)
    if Value == 0 or Value == "Friendly" then return 0 end
    if Value == 1 or Value == "Hostile" then return 1 end
    if Value == 2 or Value == "Zombie" then return 2 end
    return nil
end

-- BEGIN RELATION CORE (pure rules, tested separately from the Rbx runtime)
local function _ResolveRelation(Facts)
    if Facts.bSelf then return "Self" end
    if Facts.bPlayer and Facts.bOpenWorld then return "Friendly" end
    if Facts.bCivilian then return "Neutral" end
    -- Any explicit friendly evidence vetoes hostile evidence.
    if Facts.bSameTeam or Facts.bSameSquad or Facts.Friendly == true then return "Friendly" end
    if Facts.bPlayer then
        if Facts.bDifferentTeam then return "Enemy" end
        if Facts.Group ~= nil and Facts.LocalGroup ~= nil then
            return Facts.Group == Facts.LocalGroup and "Friendly" or "Enemy"
        end
        if Facts.Friendly == false then return "Enemy" end
        if Facts.NoTeamPolicy == "Friendly" then return "Friendly" end
        if Facts.NoTeamPolicy == "Enemy" then return "Enemy" end
        return "Unknown"
    end
    if Facts.Group ~= nil then
        local LocalGroup = Facts.LocalGroup or 0
        return Facts.Group == LocalGroup and "Friendly" or "Enemy"
    end
    if Facts.Friendly == false then return "Enemy" end
    return "Unknown"
end

local function _CanRewriteShot(bEnabled, bActive, LocalFlag, Relation)
    return bEnabled and bActive and LocalFlag == true and Relation == "Enemy"
end
-- END RELATION CORE

local function _FindRigPart(Model, Name)
    local Part = Model:FindFirstChild(Name)
    return Part and Part:IsA("BasePart") and Part or nil
end

local function _RigParts(Model)
    local Head = _FindRigPart(Model, "Head")
    local Root = _FindRigPart(Model, "HumanoidRootPart")
        or _FindRigPart(Model, "Root") or _FindRigPart(Model, "UpperTorso") or _FindRigPart(Model, "Torso")
    return Root, Head
end

local function _RigFromInstance(Object)
    if typeof(Object) ~= "Instance" then return nil end
    local Current = Object
    for _ = 1, 7 do
        if not Current or Current == workspace then break end
        if Current:IsA("Model") then
            local Root, Head = _RigParts(Current)
            if Root and Head then return Current end
        end
        Current = Current.Parent
    end
    return nil
end

local function _ReadEntry(Entry, Key)
    local Metadata = State.RuntimeByModel[Entry.Model] or State.RuntimeByUID[tostring(Entry.UID)]
    if type(Metadata) == "table" then
        local Value = _Raw(Metadata, Key)
        if Value ~= nil then return Value end
        for _, Subkey in ipairs(META_KEYS) do
            Value = _Raw(_Raw(Metadata, Subkey), Key)
            if Value ~= nil then return Value end
        end
    end
    return _First(_Attribute(Entry.Model, Key), _Attribute(Entry.Root, Key), _Attribute(Entry.Head, Key), _Attribute(Entry.Player, Key))
end

local function _Profile(Entry)
    for _, Key in ipairs({"Preset", "PresetName", "BotPreset", "BotType", "Type"}) do
        local Value = _ReadEntry(Entry, Key)
        if type(Value) == "table" then
            if _Raw(Value, "IsFriendly") ~= nil or _Raw(Value, "Behaviour") then return Value end
        elseif type(Value) == "string" and State.Profiles[Value] then
            return State.Profiles[Value]
        end
    end
    return State.Profiles[Entry.Model.Name]
end

-- Exact IDs from Shared.Configs.Emotes in the supplied save. AI_Scared is a
-- different animation (4507048152); being scared alone never means surrender.
local SURRENDER_ANIMATIONS = {
    ["4168259720"] = true,     -- AI_Surrender Start/Idle
    ["133161176549514"] = true, -- Surrender Start (NPCs only)
    ["71218028014242"] = true,  -- Surrender Idle; End is intentionally excluded
}
local SURRENDER_FLAGS = {"IsSurrendered", "Surrendered", "IsSurrendering", "Surrendering", "Surrender", "HandsUp"}
local SURRENDER_STATES = {"Emote", "EmoteName", "CurrentEmote", "_emote", "State", "Status", "AnimationState"}
local SURRENDER_TAGS = {"Surrendered", "Surrendering", "AI_Surrender"}

local function _SurrenderName(Value)
    if type(Value) == "table" then
        if rawget(Value, "IsPlaying") == false or rawget(Value, "Stage") == "End" then return false end
        Value = _First(rawget(Value, "Name"), rawget(Value, "EmoteName"), rawget(Value, "Id"))
    end
    if type(Value) ~= "string" then return false end
    local Name = string.lower(Value):gsub("[^%a]", "")
    return Name == "aisurrender" or Name == "surrender" or Name == "surrendered"
        or Name == "surrendering" or Name == "handsup"
end

local function _SurrenderTrack(Track)
    if not Track then return false end
    local Animation = Track.Animation
    local Id = Animation and tostring(Animation.AnimationId):match("%d+")
    if Id == "82876035092090" then return false end -- Surrender End
    return (Id ~= nil and SURRENDER_ANIMATIONS[Id] == true)
        or _SurrenderName(Track.Name) or (Animation ~= nil and _SurrenderName(Animation.Name))
end

local function _ReadSurrenderObject(Object, bInstance)
    if not Object then return nil end
    local bExplicitFalse = false
    local function Read(Key)
        if bInstance then
            local Value = Object:GetAttribute(Key)
            if Value ~= nil then return Value end
            local Child = Object:FindFirstChild(Key)
            if Child and (Child:IsA("BoolValue") or Child:IsA("StringValue")) then return Child.Value end
        else return _Raw(Object, Key) end
        return nil
    end
    for _, Key in ipairs(SURRENDER_FLAGS) do
        local Value = Read(Key)
        if Value == true then return true end
        if Value == false then bExplicitFalse = true end
    end
    for _, Key in ipairs(SURRENDER_STATES) do
        local Value = Read(Key)
        if _SurrenderName(Value) then return true end
        if (Key == "Emote" or Key == "EmoteName" or Key == "CurrentEmote" or Key == "_emote")
            and (type(Value) == "string" or Value == false or (type(Value) == "table" and
                (rawget(Value, "IsPlaying") == false or rawget(Value, "Stage") == "End"))) then
            bExplicitFalse = true
        end
    end
    if bInstance then
        for _, Tag in ipairs(SURRENDER_TAGS) do if Object:HasTag(Tag) then return true end end
    end
    if bExplicitFalse then return false end
    return nil
end

local function _SurrenderState(Entry)
    if Entry.Player then return false end
    -- Replicated instance state takes precedence over stale cached actor fields.
    local InstanceResult
    for _, Object in ipairs({Entry.Model, Entry.Root}) do
        local Value = _ReadSurrenderObject(Object, true)
        if Value == true then InstanceResult = true; break end
        if Value == false then InstanceResult = false end
    end
    local HumanoidState = _ReadSurrenderObject(Entry.Humanoid, true)
    if HumanoidState == true then InstanceResult = true
    elseif HumanoidState == false and InstanceResult == nil then InstanceResult = false end
    if InstanceResult == true then return true end
    for Track in pairs(Entry.ActiveSurrenderTracks or {}) do
        if Track.IsPlaying ~= false then return true end
    end
    if InstanceResult == false then return false end
    local Metadata = State.RuntimeByModel[Entry.Model] or State.RuntimeByUID[tostring(Entry.UID)]
    if type(Metadata) == "table" then
        -- Config/Preset fields describe capability, not a changing surrender state.
        local StateData, Data = _Raw(Metadata, "State"), _Raw(Metadata, "Data")
        local Result = _ReadSurrenderObject(StateData, false)
        if Result ~= nil then return Result end
        Result = _ReadSurrenderObject(Data, false)
        if Result ~= nil then return Result end
        Result = _ReadSurrenderObject(Metadata, false)
        if Result ~= nil then return Result end
    end
    return false
end

-- AI receiver names used by exactly one faction across all nine supplied BotPresets modules.
-- Shared weapons (including AI_SWG_AK) are deliberately excluded.
local AI_RECEIVER_ROLES = {
    ["AI_AK"] = "Enemy",
    ["AI_APS"] = "Enemy",
    ["AI_AR15"] = "Enemy",
    ["AI_DB"] = "Enemy",
    ["AI_G36"] = "Enemy",
    ["AI_KSVK"] = "Enemy",
    ["AI_M2010"] = "Enemy",
    ["AI_M249"] = "Enemy",
    ["AI_MAKAROV"] = "Enemy",
    ["AI_MOSIN"] = "Enemy",
    ["AI_PKM"] = "Enemy",
    ["AI_PP19"] = "Enemy",
    ["AI_PPSH"] = "Enemy",
    ["AI_R700"] = "Enemy",
    ["AI_RPD"] = "Enemy",
    ["AI_RPK"] = "Enemy",
    ["AI_SAIGA"] = "Enemy",
    ["AI_SCARL"] = "Enemy",
    ["AI_SVD"] = "Enemy",
    ["AI_SWG_BenelliM4"] = "Enemy",
    ["AI_SWG_BrowningHP"] = "Enemy",
    ["AI_SWG_Deagle"] = "Enemy",
    ["AI_SWG_FNFAL"] = "Enemy",
    ["AI_SWG_FNP90"] = "Enemy",
    ["AI_SWG_M107A1"] = "Enemy",
    ["AI_SWG_M16"] = "Enemy",
    ["AI_SWG_M16_Sniper"] = "Enemy",
    ["AI_SWG_M249"] = "Enemy",
    ["AI_SWG_M4A1"] = "Enemy",
    ["AI_SWG_M4A1S"] = "Enemy",
    ["AI_SWG_M590A1"] = "Enemy",
    ["AI_SWG_MP5"] = "Enemy",
    ["AI_SWG_RPD"] = "Enemy",
    ["AI_SWG_SCARH"] = "Enemy",
    ["AI_SWG_SCARSSR"] = "Enemy",
    ["AI_SWG_SVD"] = "Enemy",
    ["AI_SWG_XM2010"] = "Enemy",
    ["AI_UMP45"] = "Enemy",
    ["AI_VZ"] = "Enemy",
}

local function _RefreshPlayerMap()
    table.clear(State.PlayerByUID)
    table.clear(State.PlayerByUserId)
    table.clear(State.PlayerByCharacter)
    for _, Player in ipairs(Players:GetPlayers()) do
        State.PlayerByUserId[Player.UserId] = Player
        local Character = Player.Character
        if Character then State.PlayerByCharacter[Character] = Player end
        local Root, Head
        if Character then Root, Head = _RigParts(Character) end
        local UID = _First(_Attribute(Player, "ActorUID"), _Attribute(Character, "ActorUID"), _Attribute(Root, "ActorUID"), _Attribute(Head, "ActorUID"))
        if UID ~= nil then
            State.PlayerByUID[tostring(UID)] = Player
            if Player == LocalPlayer then State.LocalActorUIDs[tostring(UID)] = true end
        end
    end
end

local function _PlayerForEntry(Entry)
    local Player = Players:GetPlayerFromCharacter(Entry.Model)
    if Player then return Player end
    local Ancestor = Entry.Model
    for _ = 1, 8 do
        if not Ancestor or Ancestor == workspace then break end
        Player = State.PlayerByCharacter[Ancestor]
        if Player then return Player end
        Ancestor = Ancestor.Parent
    end
    Player = _ReadEntry(Entry, "Player")
    if typeof(Player) == "Instance" and Player:IsA("Player") then return Player end
    for _, Key in ipairs({"Client", "Owner", "User"}) do
        local Owner = _ReadEntry(Entry, Key)
        if typeof(Owner) == "Instance" and Owner:IsA("Player") then return Owner end
        if type(Owner) == "table" then
            Player = _Raw(Owner, "Player")
            if typeof(Player) == "Instance" and Player:IsA("Player") then return Player end
            local Id = tonumber(_Raw(Owner, "UserId") or _Raw(Owner, "UserID"))
            if Id and State.PlayerByUserId[Id] then return State.PlayerByUserId[Id] end
        end
    end
    local UserId = tonumber(_ReadEntry(Entry, "UserId") or _ReadEntry(Entry, "UserID") or _ReadEntry(Entry, "PlayerId"))
    if UserId and State.PlayerByUserId[UserId] then return State.PlayerByUserId[UserId] end
    if Entry.UID ~= nil and State.PlayerByUID[tostring(Entry.UID)] then return State.PlayerByUID[tostring(Entry.UID)] end
    if _ReadEntry(Entry, "IsLocal") == true or _ReadEntry(Entry, "Local") == true
        or (Entry.UID ~= nil and State.LocalActorUIDs[tostring(Entry.UID)]) then return LocalPlayer end
    return nil
end

local function _IsLocalEntry(Entry)
    if Entry.Player == LocalPlayer or State.PlayerByCharacter[Entry.Model] == LocalPlayer then return true end
    if Entry.UID ~= nil and State.LocalActorUIDs[tostring(Entry.UID)] then return true end
    local Character = LocalPlayer.Character
    return Character ~= nil and (Entry.Model == Character or Entry.Model:IsDescendantOf(Character))
end

local function _AliveData(Data)
    if type(Data) ~= "table" then return true end
    local Health = _Raw(Data, "CurrentHealth") or _Raw(Data, "Health")
    if type(Health) == "table" then Health = _Raw(Health, "Current") or _Raw(Health, "Value") end
    if type(Health) == "number" and Health <= 0 then return false end
    if _Raw(Data, "Dead") == true or _Raw(Data, "IsDead") == true or _Raw(Data, "Alive") == false then return false end
    return true
end

local function _LiveAlive(Entry)
    if Entry.bDisposed or not Entry.bAlive then return false end
    if Entry.Humanoid and Entry.Humanoid.Health <= 0 then return false end
    local Meta = State.RuntimeByModel[Entry.Model] or State.RuntimeByUID[tostring(Entry.UID)]
    if not _AliveData(Meta) or not _AliveData(_Raw(Meta, "State")) or not _AliveData(_Raw(Meta, "Data")) then return false end
    if not Entry.Humanoid then
        local Health = _Attribute(Entry.Model, "Health") or _Attribute(Entry.Root, "Health") or _Attribute(Entry.Head, "Health")
        if type(Health) == "number" and Health <= 0 then return false end
    end
    return true
end

local function _MarkDead(Entry)
    local bHadVisual = State.Visuals[Entry.Model] ~= nil
    Entry.bAlive = false
    if State.Target == Entry then State.Target = nil end
    if _RemoveVisual then _RemoveVisual(Entry.Model) end
    if bHadVisual then State.VisualMembershipDirty = true end
end

local function _ReceiverEvidence(Entry)
    if Entry.Player or Entry.UID == nil then return nil end
    if Entry.Model.Name ~= "Male" and Entry.Model.Name ~= "Female" and _ReadEntry(Entry, "IsNPC") ~= true then return nil end
    for _, Child in ipairs(Entry.Model:GetChildren()) do
        if AI_RECEIVER_ROLES[Child.Name] then return AI_RECEIVER_ROLES[Child.Name] end
    end
    return nil
end

local function _RefreshEntry(Entry, bForce)
    local Model = Entry.Model
    if not Model.Parent or not Model:IsDescendantOf(workspace) then return false end
    local Time = os.clock()
    if not bForce and Entry.ClassifiedAt and Time - Entry.ClassifiedAt < Config.ESPInterval
        and Entry.Root and Entry.Root.Parent and Entry.Head and Entry.Head.Parent then return true end
    State.Perf.Classifications += 1
    local Camera = workspace.CurrentCamera
    if Camera and Model:IsDescendantOf(Camera) then return false end
    Entry.Root, Entry.Head = _RigParts(Model)
    if not Entry.Root or not Entry.Head then return false end
    Entry.Humanoid = Model:FindFirstChildOfClass("Humanoid")
    Entry.LeftFoot = _FindRigPart(Model, "LeftFoot") or _FindRigPart(Model, "Left Leg")
    Entry.RightFoot = _FindRigPart(Model, "RightFoot") or _FindRigPart(Model, "Right Leg")
    if Entry.Humanoid and Entry.Humanoid:GetAttribute("ChunkFoliageHumanoid") then return false end
    local UID = _First(Model:GetAttribute("ActorUID"), Entry.Root:GetAttribute("ActorUID"), Entry.Head:GetAttribute("ActorUID"), Entry.UID)
    if Entry.UID ~= nil and UID ~= nil and UID ~= Entry.UID then
        local OldMetadata = State.RuntimeByModel[Model]
        if State.RuntimeByUID[tostring(Entry.UID)] == OldMetadata then State.RuntimeByUID[tostring(Entry.UID)] = nil end
        State.RuntimeByModel[Model] = nil
        Entry.bWasEnemyNPC = false
    end
    Entry.UID = UID
    Entry.Player = _PlayerForEntry(Entry)
    if Entry.Player == LocalPlayer and UID ~= nil then State.LocalActorUIDs[tostring(UID)] = true end
    if UID ~= nil and State.HostileUIDs[tostring(UID)] then Entry.bWasEnemyNPC = true end
    local Profile = not Entry.Player and _Profile(Entry) or nil
    local Friendly = _First(_ReadEntry(Entry, "IsFriendly"), _ReadEntry(Entry, "Friendly"), _Raw(Profile, "IsFriendly"))
    -- Conflicting explicit flags fail closed to friendly.
    if _ReadEntry(Entry, "IsFriendly") == true or _ReadEntry(Entry, "Friendly") == true
        or _Raw(Profile, "IsFriendly") == true then Friendly = true end
    local Behaviour = _First(_ReadEntry(Entry, "Behaviour"), _Raw(Profile, "Behaviour"))
    local Group = _NormalizeGroup(_ReadEntry(Entry, "TargetGroup"))
    local LocalModel = LocalPlayer.Character
    local LocalEntry = LocalModel and State.Actors[LocalModel]
    local LocalGroup = _NormalizeGroup(_First(_Attribute(LocalPlayer, "TargetGroup"), _Attribute(LocalModel, "TargetGroup")))
    if not LocalGroup and LocalEntry then LocalGroup = _NormalizeGroup(_ReadEntry(LocalEntry, "TargetGroup")) end
    local TargetTeam = Entry.Player and Entry.Player.Team
    local LocalTeam = LocalPlayer.Team
    local LocalSquad = _Attribute(LocalPlayer, "SquadUID")
    local TargetSquad = Entry.Player and _Attribute(Entry.Player, "SquadUID")
    local Policy = Config.NoTeamPolicy
    if Policy == "Ignore" and State.bPvP == false then Policy = "Friendly" end
    local BaseRelation = _ResolveRelation({
        bSelf = _IsLocalEntry(Entry) or Model == LocalModel
            or (LocalModel ~= nil and Model:IsDescendantOf(LocalModel)),
        bCivilian = Behaviour == "Civilian" or _ReadEntry(Entry, "Civilian") == true,
        bPlayer = Entry.Player ~= nil,
        bOpenWorld = State.bOpenWorld,
        bSameTeam = TargetTeam ~= nil and LocalTeam ~= nil and TargetTeam == LocalTeam,
        bDifferentTeam = TargetTeam ~= nil and LocalTeam ~= nil and TargetTeam ~= LocalTeam,
        bSameSquad = LocalSquad ~= nil and LocalSquad ~= "" and TargetSquad == LocalSquad,
        Friendly = Friendly, Group = Group, LocalGroup = LocalGroup,
        NoTeamPolicy = Policy,
    })
    Entry.RelationSource = Entry.Player and "玩家資料" or "執行期／屬性"
    if BaseRelation == "Unknown" and not Entry.Player then
        local Evidence = _ReceiverEvidence(Entry)
        if Evidence then BaseRelation = Evidence; Entry.RelationSource = "NPC 專用武器設定"
        elseif Entry.bWasEnemyNPC then BaseRelation = "Enemy"; Entry.RelationSource = "ActorUID 身分紀錄"
        else Entry.RelationSource = "缺少陣營資料" end
    end
    Entry.BaseRelation = BaseRelation
    if not Entry.Player and BaseRelation == "Enemy" then Entry.bWasEnemyNPC = true end
    if not Entry.Player and BaseRelation ~= "Self" and Behaviour ~= "Civilian" and _Raw(Profile, "IsFriendly") == false then
        Entry.bWasEnemyNPC = true
    end
    if Entry.bWasEnemyNPC and UID ~= nil then State.HostileUIDs[tostring(UID)] = true end
    local OldRelation = Entry.Relation
    Entry.bSurrendered = not Entry.Player and BaseRelation ~= "Self" and _SurrenderState(Entry)
    Entry.Relation = Entry.bSurrendered and Entry.bWasEnemyNPC and "SurrenderedEnemy" or BaseRelation
    local Health = _First(_ReadEntry(Entry, "CurrentHealth"), _ReadEntry(Entry, "Health"), _ReadEntry(Entry, "_health"))
    if type(Health) == "table" then Health = _First(_Raw(Health, "Current"), _Raw(Health, "Value")) end
    if Entry.Humanoid then Health = Entry.Humanoid.Health end
    Entry.Health = type(Health) == "number" and Health or nil
    Entry.MaxHealth = Entry.Humanoid and Entry.Humanoid.MaxHealth
        or _First(_ReadEntry(Entry, "MaxHealth"), _Raw(Profile, "Health"), Entry.Health)
    local bDead = _ReadEntry(Entry, "Dead") == true or _ReadEntry(Entry, "IsDead") == true
        or _ReadEntry(Entry, "Alive") == false or Model:HasTag("Corpse") or Model:HasTag("Ragdoll")
        or (Entry.Health ~= nil and Entry.Health <= 0)
    Entry.bAlive = not bDead
    if not _LiveAlive(Entry) then _MarkDead(Entry) end
    Entry.Name = Entry.Player and Entry.Player.DisplayName
        or _First(_ReadEntry(Entry, "DisplayName"), _ReadEntry(Entry, "PresetName"), Model.Name)
    if OldRelation ~= Entry.Relation then
        State.Dirty[Model] = true
        State.VisualMembershipDirty = true
        if OldRelation and (OldRelation == "SurrenderedEnemy" or Entry.Relation == "SurrenderedEnemy") then
            State.SurrenderTransitions += 1
            local Names = {Enemy = "敵人 NPC", SurrenderedEnemy = "投降敵人 NPC", Friendly = "友軍", Neutral = "中立", Unknown = "未知"}
            State.LastTransition = tostring(Entry.Name) .. "：" .. (Names[OldRelation] or OldRelation) .. " → " .. (Names[Entry.Relation] or Entry.Relation)
        end
        if State.Target == Entry and Entry.Relation ~= "Enemy" then
            State.Target = nil
            
        end
    end
    Entry.ClassifiedAt = Time
    return true
end

local function _DropActor(Model)
    local Entry = State.Actors[Model]
    if not Entry then return end
    Entry.bDisposed = true
    local Index = Entry.RegistryIndex
    if Index and State.ActorList[Index] == Entry then
        local Last = State.ActorList[#State.ActorList]
        State.ActorList[Index] = Last
        Last.RegistryIndex = Index
        State.ActorList[#State.ActorList] = nil
        Entry.RegistryIndex = nil
    end
    for _, Connection in ipairs(Entry.ObserverConnections or {}) do Connection:Disconnect() end
    for _, Connections in pairs(Entry.TrackConnections or {}) do
        for _, Connection in ipairs(Connections) do Connection:Disconnect() end
    end
    State.Actors[Model] = nil
    if _RemoveVisual then _RemoveVisual(Model) end
    State.Dirty[Model] = nil
    local Metadata = State.RuntimeByModel[Model]
    State.RuntimeByModel[Model] = nil
    if Entry.UID ~= nil and State.RuntimeByUID[tostring(Entry.UID)] == Metadata then State.RuntimeByUID[tostring(Entry.UID)] = nil end
    if State.Target == Entry then State.Target = nil;  end
end

local function _WatchActor(Entry)
    if Entry.ObserverConnections then return end
    Entry.ObserverConnections, Entry.TrackConnections = {}, {}
    Entry.ActiveSurrenderTracks, Entry.WatchedValues = {}, {}
    local function Connect(Signal, Callback)
        if not Signal then return end
        local Connection = Signal:Connect(Callback)
        table.insert(Entry.ObserverConnections, Connection)
    end
    local function Changed()
        if not State.bAlive or Entry.bDisposed then return end
        if not _RefreshEntry(Entry, true) then _DropActor(Entry.Model); return end
        State.Dirty[Entry.Model] = true
    end
    local function WatchTrack(Track)
        if not _SurrenderTrack(Track) or Entry.TrackConnections[Track] then return end
        Entry.ActiveSurrenderTracks[Track] = true
        local Connections = {}
        Entry.TrackConnections[Track] = Connections
        local function Finished()
            for _, Connection in ipairs(Connections) do Connection:Disconnect() end
            Entry.TrackConnections[Track] = nil
            Entry.ActiveSurrenderTracks[Track] = nil
            Changed()
        end
        table.insert(Connections, Track.Stopped:Connect(Finished))
        table.insert(Connections, Track.Ended:Connect(Finished))
    end
    local function WatchAnimator(Animator)
        local Parent = Animator.Parent
        if Parent ~= Entry.Humanoid and Parent ~= Entry.Model
            and not (Parent and Parent:IsA("AnimationController") and Parent.Parent == Entry.Model) then return end
        if Entry.Animator == Animator then return end
        Entry.Animator = Animator
        Connect(Animator.AnimationPlayed, function(Track)
            if _SurrenderTrack(Track) then WatchTrack(Track); Changed() end
        end)
        local bOK, Tracks = pcall(Animator.GetPlayingAnimationTracks, Animator)
        if bOK then for _, Track in ipairs(Tracks) do WatchTrack(Track) end end
        Changed()
    end
    local function WatchValue(Object)
        if not (Object:IsA("BoolValue") or Object:IsA("StringValue")) then return false end
        if table.find(SURRENDER_FLAGS, Object.Name) or table.find(SURRENDER_STATES, Object.Name) then
            if not Entry.WatchedValues[Object] then Entry.WatchedValues[Object] = true; Connect(Object.Changed, Changed) end
            return true
        end
        return false
    end
    local Relevant = {ActorUID=true, IsFriendly=true, Friendly=true, TargetGroup=true, Behaviour=true, Civilian=true,
        Health=true, CurrentHealth=true, MaxHealth=true, Dead=true, IsDead=true, Alive=true, Preset=true, Type=true, SquadUID=true}
    for _, Key in ipairs(SURRENDER_FLAGS) do Relevant[Key] = true end
    for _, Key in ipairs(SURRENDER_STATES) do Relevant[Key] = true end
    local function AttributeChanged(Key) if Relevant[Key] then Changed() end end
    Connect(Entry.Model.AttributeChanged, AttributeChanged)
    Connect(Entry.Root.AttributeChanged, AttributeChanged)
    if Entry.Humanoid then
        Connect(Entry.Humanoid.AttributeChanged, AttributeChanged)
        Connect(Entry.Humanoid.Died, function() _MarkDead(Entry) end)
        Connect(Entry.Humanoid.HealthChanged, function(Health)
            if Health <= 0 then _MarkDead(Entry) else Changed() end
        end)
    end
    Connect(Entry.Model.Destroying, function() _DropActor(Entry.Model) end)
    Connect(Entry.Model.DescendantAdded, function(Object)
        if Object:IsA("Animator") then WatchAnimator(Object)
        elseif WatchValue(Object) then Changed()
        elseif Object.Parent == Entry.Model and (Object.Name == "Head" or Object.Name == "Root"
            or Object.Name == "HumanoidRootPart" or AI_RECEIVER_ROLES[Object.Name]) then Changed() end
    end)
    local Controller = Entry.Humanoid or Entry.Model:FindFirstChildOfClass("AnimationController")
    local Animator = Controller and Controller:FindFirstChildOfClass("Animator") or Entry.Model:FindFirstChildOfClass("Animator")
    if Animator then WatchAnimator(Animator) end
    for _, Object in ipairs(Entry.Model:GetChildren()) do WatchValue(Object) end
end

_TryActor = function(Model)
    if not Model or not Model:IsA("Model") or not Model:IsDescendantOf(workspace) then return end
    local Root, Head = _RigParts(Model)
    if not Root or not Head then return end
    local Entry = State.Actors[Model] or {__OWOwned = true, Model = Model, Root = Root, Head = Head}
    if _RefreshEntry(Entry, true) then
        if not State.Actors[Model] then
            State.ActorList[#State.ActorList + 1] = Entry
            Entry.RegistryIndex = #State.ActorList
            State.VisualMembershipDirty = true
        end
        State.Actors[Model] = Entry
        _WatchActor(Entry)
    end
end

local ITEM_TAGS = {"Item", "WorldItem", "DroppedItem", "Loot", "SupplyCrate", "Pickup", "InventoryItem", "DroppedLoot"}
local ITEM_FOLDERS = {Items = true, DroppedItems = true, WorldItems = true, Loot = true, Pickups = true, Drops = true, Tools = true}
local ITEM_PREFABS = {Ammo = true, Item = true, WorldItem = true, DroppedItem = true, Loot = true, SupplyCrate = true, Pickup = true, InventoryItem = true}

-- ItemLayout is the same complete catalog used by Shared.Inventory.Item.new.
_LoadItemCatalog = function(Catalog)
    if type(Catalog) ~= "table" then return end
    local bChanged = false
    for Key, Layout in pairs(Catalog) do
        if type(Key) == "string" and type(Layout) == "table" and (Layout.ItemType ~= nil or Layout.Size ~= nil) then
            local Name = type(Layout.Name) == "string" and Layout.Name or Key
            if not State.ItemCatalog[Key] then bChanged = true end
            State.ItemCatalog[Key] = Name
            State.ItemAliases[Key] = Key
            for _, Alias in ipairs({Name, type(Layout.Build) == "string" and Layout.Build or Key}) do
                local Existing = State.ItemAliases[Alias]
                State.ItemAliases[Alias] = (Existing == nil or Existing == Key) and Key or false
            end
        end
    end
    if bChanged then State.ItemCatalogScan = true end
end

local function _ItemPart(Object, Cached, bSearch)
    if Object:IsA("BasePart") then return Object end
    local Part = Object:IsA("Model") and Object.PrimaryPart
        or Object:FindFirstChild("Handle") or Object:FindFirstChild("Root")
    if Part and Part:IsA("BasePart") then return Part end
    if Cached and Cached.Parent and Cached:IsDescendantOf(Object) then return Cached end
    return bSearch and Object:FindFirstChildWhichIsA("BasePart", true) or nil
end

local function _WorldItem(Object)
    if not Object.Parent or not Object:IsDescendantOf(workspace) then return false end
    local Camera = workspace.CurrentCamera
    if Camera and Object:IsDescendantOf(Camera) then return false end
    local Parent = Object
    for _ = 1, 12 do
        if not Parent or Parent == workspace then break end
        if State.PlayerByCharacter[Parent] or State.Actors[Parent] or Parent:IsA("Backpack") then return false end
        if Parent:IsA("Model") then
            local Root, Head = _RigParts(Parent)
            if Root and Head then return false end
        end
        Parent = Parent.Parent
    end
    return true
end

local function _InventoryEvidence(Object, Runtime)
    local Prefab = Object:GetAttribute("Prefab")
    local Data = _Raw(Runtime, "Item") or _Raw(Runtime, "ItemData") or Runtime
    if type(Data) ~= "table" then Data = nil end
    local RawItem = Object:GetAttribute("ItemData") or Object:GetAttribute("Item") or Object:GetAttribute("SerializedItem")
    if RawItem == nil then
        local Value = Object:FindFirstChild("ItemData") or Object:FindFirstChild("Item")
        if Value and Value:IsA("StringValue") then RawItem = Value.Value end
    end
    if type(RawItem) == "string" and (RawItem:sub(1, 1) == "[" or RawItem:sub(1, 1) == "{") then
        local bOK, Decoded = pcall(HttpService.JSONDecode, HttpService, RawItem)
        if bOK and type(Decoded) == "table" then Data = Decoded end
    end
    local ItemName = _Raw(Data, "Name") or (Data and rawget(Data, 1)) or Object:GetAttribute("ItemName")
        or Object:GetAttribute("ItemId") or Object:GetAttribute("ItemID") or (type(RawItem) == "string" and RawItem)
    local ObjectName = Object.Name:gsub("#%d+$", "")
    local Name = type(ItemName) == "string" and ItemName or ObjectName
    local ItemKey = type(ItemName) == "string" and State.ItemAliases[ItemName] or nil
    local CatalogKey = ItemKey or State.ItemAliases[ObjectName]
    -- A display/Build alias labels a known pickup; it does not prove that scenery
    -- is an inventory item. In particular, map Pipe models alias MeleePipe.
    local bCatalogItem = State.ItemCatalog[ObjectName] ~= nil
        or (ItemKey ~= nil and ItemKey ~= false)
    local bItem = bCatalogItem
        or Object:IsA("Tool") or ITEM_PREFABS[Prefab] == true or Object:FindFirstChild("#Pickup") ~= nil
        or Object:GetAttribute("ItemUID") ~= nil or Object:GetAttribute("ItemId") ~= nil or Object:GetAttribute("ItemID") ~= nil
        or Object:GetAttribute("InventoryItem") == true
        or (_Raw(Data, "Layout") ~= nil and (_Raw(Data, "MetaData") ~= nil or _Raw(Data, "UID") ~= nil))
    if not bItem then
        for _, Tag in ipairs(ITEM_TAGS) do if Object:HasTag(Tag) then bItem = true; break end end
    end
    if not bItem and Object.Parent and ITEM_FOLDERS[Object.Parent.Name] then bItem = true end
    local DisplayName = CatalogKey and State.ItemCatalog[CatalogKey] or Name
    return bItem, Prefab == "Ammo" and "彈藥補給" or DisplayName
end

_TryItem = function(Object, bTagged, Runtime)
    if not Object or not Object.Parent or not Object:IsDescendantOf(workspace) then return end
    if not (Object:IsA("Model") or Object:IsA("BasePart") or Object:IsA("Tool") or Object:IsA("Folder")) then return end
    Runtime = Runtime or State.ItemRuntime[Object]
    local bItem, Name = _InventoryEvidence(Object, Runtime)
    if not bItem and not bTagged then return end
    if not _WorldItem(Object) then return end
    -- Prefer one marker for the complete pickup, never its child meshes as well.
    local Parent = Object.Parent
    for _ = 1, 8 do
        if not Parent or Parent == workspace then break end
        if State.Items[Parent] then return end
        Parent = Parent.Parent
    end
    local Previous = State.Items[Object]
    local Part = _ItemPart(Object, Previous and Previous.Root, true)
    if not Part then State.ItemCandidates[Object] = true; return end
    State.Items[Object] = {__OWOwned = true, Object = Object, Root = Part, Name = Name or Object.Name}
    State.ItemCandidates[Object] = nil
    State.VisualMembershipDirty = true
    if Runtime then State.ItemRuntime[Object] = Runtime end
    for Child in pairs(State.Items) do
        if Child ~= Object and Child:IsDescendantOf(Object) then
            State.Items[Child] = nil
            if _RemoveVisual then _RemoveVisual(Child) end
        end
    end
end

local function _WorldInstance(Value, Depth)
    if typeof(Value) == "Instance" then
        if Value:IsA("Model") or Value:IsA("BasePart") or Value:IsA("Tool") then return Value end
        return nil
    end
    if type(Value) ~= "table" or Depth >= 3 then return nil end
    for _, Key in ipairs({"Model", "Instance", "Object", "WorldModel", "Part", "Handle", "Render", "Component"}) do
        local Object = _WorldInstance(_Raw(Value, Key), Depth + 1)
        if Object then return Object end
    end
    return nil
end

_IndexWorldItem = function(Data)
    local Item = _Raw(Data, "Item") or _Raw(Data, "ItemData")
    local Layout = _Raw(Data, "Layout")
    local Name = _Raw(Data, "Name")
    if not Item and not (type(Layout) == "table" and _Raw(Layout, "ItemType") ~= nil)
        and not (type(Name) == "string" and State.ItemCatalog[Name]) then return end
    local Object = _WorldInstance(Data, 0)
    if Object and Object:IsDescendantOf(workspace) then
        State.ItemRuntime[Object] = Data
        _TryItem(Object, Item ~= nil or Layout ~= nil, Data)
    end
end


-- Isle-style pickup transaction, using this game's existing prompt callbacks.
-- No Isle-only remote, invented server command, or local inventory write is used.
local function _PickupRoot(Model)
    if not Model or not Model:IsA("Model") or not Model:IsDescendantOf(workspace) then return nil end
    local Camera = workspace.CurrentCamera
    if Camera and Model:IsDescendantOf(Camera) then return nil end
    local Root = _RigParts(Model)
    if not Root then
        for _, Name in ipairs({"HumanoidRootPart", "Root", "UpperTorso", "Torso"}) do
            local Part = Model:FindFirstChild(Name, true)
            if Part and Part:IsA("BasePart") then Root = Part; break end
        end
    end
    if not Root and Model.PrimaryPart and Model.PrimaryPart:IsA("BasePart") then Root = Model.PrimaryPart end
    if not Root or not Root.Parent or not Root:IsDescendantOf(Model) then return nil end
    local Rig = _RigFromInstance(Root) or Model
    return Root, Rig:FindFirstChildOfClass("Humanoid"), Rig
end

local function _PickupOccupied(Seat, Humanoid, Actor)
    local Occupant
    if typeof(Seat) == "Instance" then
        if not Seat.Parent or not (Seat:IsA("Seat") or Seat:IsA("VehicleSeat")) then return false end
        Occupant = Seat.Occupant
    elseif type(Seat) == "table" then Occupant = _Raw(Seat, "Occupant") end
    return Occupant ~= nil and Occupant ~= false and (Occupant == LocalPlayer
        or (Humanoid ~= nil and Occupant == Humanoid) or (Actor ~= nil and Occupant == Actor))
end

local function _PickupReadiness(Rig, Humanoid)
    local Entry = State.Actors[Rig]
    local Actor = State.RuntimeByModel[Rig] or (Entry and State.RuntimeByUID[tostring(Entry.UID)])
    -- Cached Entry.bAlive and the existence of a vehicle controller are not live state.
    if Humanoid then
        if Humanoid.Health <= 0 then return "角色已死亡，請等待重生" end
        local Seat = Humanoid.SeatPart
        if Seat and Seat.Parent and (Humanoid.Sit == true or _PickupOccupied(Seat, Humanoid, Actor)) then
            return "角色目前在座位中，請先離座"
        end
    elseif not _AliveData(Actor) or not _AliveData(_Raw(Actor, "State")) then return "角色目前無法互動" end
    for _, Key in ipairs({"InVehicle", "IsSeated", "Seated"}) do
        if _Raw(Actor, Key) == true then return "角色目前在載具座位中，請先離座" end
    end
    local Vehicle = _Raw(Actor, "Vehicle")
    for _, Key in ipairs({"Seat", "SeatPart", "CurrentSeat"}) do
        if _PickupOccupied(_Raw(Actor, Key), Humanoid, Actor)
            or _PickupOccupied(_Raw(Vehicle, Key), Humanoid, Actor) then
            return "角色目前在載具座位中，請先離座"
        end
    end
    return nil
end

-- Position lookup remains available while dead or seated, so browsing never
-- reports "waiting for character" merely because pickup is temporarily blocked.
local function _PickupCharacter(bPositionOnly)
    local Character = LocalPlayer.Character
    local Root, Humanoid, Rig = _PickupRoot(Character)
    if not Root then
        local Best, BestRoot, BestHumanoid, BestRig, BestScore = nil, nil, nil, nil, -math.huge
        for _, Entry in pairs(State.Actors) do
            if Entry.bDisposed or not _IsLocalEntry(Entry) then continue end
            local CandidateRoot, CandidateHumanoid, CandidateRig = _PickupRoot(Entry.Model)
            if not CandidateRoot or (CandidateHumanoid and CandidateHumanoid.Health <= 0) then continue end
            local Actor = State.RuntimeByModel[Entry.Model] or State.RuntimeByUID[tostring(Entry.UID)]
            local Score = Entry.Player == LocalPlayer and 20 or 0
            if _Raw(Actor, "IsLocal") == true or _Raw(Actor, "Local") == true then Score += 100 end
            if _Raw(Actor, "Player") == LocalPlayer then Score += 50 end
            if Score > BestScore then
                Best, BestRoot, BestHumanoid, BestRig, BestScore = Entry.Model, CandidateRoot, CandidateHumanoid, CandidateRig, Score
            end
        end
        Character, Root, Humanoid, Rig = Best, BestRoot, BestHumanoid, BestRig
        if Root and LocalPlayer.Character and Root:IsDescendantOf(LocalPlayer.Character) then Character = LocalPlayer.Character end
    end
    if not Root then
        State.PickupCharacterStatus = "找不到自己的角色根零件，請等待角色載入"
        State.PickupCharacterSource = nil
        return nil, nil, nil, State.PickupCharacterStatus
    end
    local Reason = _PickupReadiness(Rig, Humanoid)
    State.PickupCharacterStatus = Reason or "角色可用"
    State.PickupCharacterSource = Root:GetFullName()
    if Reason and not bPositionOnly then return nil, nil, nil, Reason end
    return Character, Root, Humanoid, Reason
end

local function _PickupUID(Object)
    local Data = State.ItemRuntime[Object]
    local Item = _Raw(Data, "Item") or _Raw(Data, "ItemData") or Data
    local Meta = _Raw(Item, "MetaData")
    local UID = _Raw(Meta, "UID") or _Raw(Item, "UID") or Object:GetAttribute("ItemUID") or Object:GetAttribute("UID")
    if UID == nil then
        local Serialized = Object:GetAttribute("ItemData") or Object:GetAttribute("Item") or Object:GetAttribute("SerializedItem")
        if Serialized == nil then
            local Value = Object:FindFirstChild("ItemData") or Object:FindFirstChild("Item")
            if Value and Value:IsA("StringValue") then Serialized = Value.Value end
        end
        if type(Serialized) == "string" then
            local bOK, Decoded = pcall(HttpService.JSONDecode, HttpService, Serialized)
            if bOK and type(Decoded) == "table" then
                local Metadata = _Raw(Decoded, "MetaData") or rawget(Decoded, 2)
                UID = _Raw(Metadata, "UID")
            end
        end
    end
    return UID ~= nil and tostring(UID) or nil
end

local function _OwnedPickup(Object, UID)
    local Backpack = LocalPlayer:FindFirstChildOfClass("Backpack")
    local Character = _PickupCharacter(true) or LocalPlayer.Character
    if (Backpack and Object:IsDescendantOf(Backpack)) or (Character and Object:IsDescendantOf(Character)) then return true end
    if not UID then return false end
    -- SharedInventory stores items at Storages[*].Sections[*][*].MetaData.UID.
    for _, Entry in pairs(State.Actors) do
        if not _IsLocalEntry(Entry) then continue end
        local Actor = State.RuntimeByModel[Entry.Model] or State.RuntimeByUID[tostring(Entry.UID)]
        for _, Data in ipairs({Actor or false, _Raw(Actor, "Inventory") or false}) do
            local Storages = _Raw(Data, "Storages")
            if type(Storages) ~= "table" then continue end
            local Count = 0
            for _, Storage in pairs(Storages) do
                local Sections = _Raw(Storage, "Sections")
                if type(Sections) ~= "table" then continue end
                for _, Section in pairs(Sections) do
                    if type(Section) ~= "table" then continue end
                    for _, Item in pairs(Section) do
                        if tostring(_Raw(_Raw(Item, "MetaData"), "UID")) == UID then return true end
                        Count += 1
                        if Count >= 2048 then return false end
                    end
                end
            end
        end
    end
    return false
end

local function _PromptPoint(Prompt)
    local Parent = Prompt.Parent
    if not Parent then return nil end
    if Parent:IsA("Attachment") then return Parent.WorldPosition end
    if Parent:IsA("BasePart") then return Parent.Position end
    local Part = _ItemPart(Parent, nil, true)
    return Part and Part.Position or nil
end

local function _PickupPrompt(Object, Part)
    local UID = _PickupUID(Object)
    local Metadata = State.ItemRuntime[Object]
    local InteractionUID = _Raw(Metadata, "InventoryUID") or _Raw(Metadata, "InteractionUID") or Object:GetAttribute("InventoryUID")
    local Best, BestMode, BestScore, bAmbiguous = nil, nil, math.huge, false
    for Prompt in pairs(State.PickupPrompts) do
        if not Prompt.Parent or not Prompt:IsDescendantOf(workspace) then State.PickupPrompts[Prompt] = nil; continue end
        if not Prompt.Enabled then continue end
        local Action = string.lower(Prompt.ActionText or ""):gsub("[%s_%-]", "")
        local bTake = Action == "pickup" or Action == "pickupitem" or Action == "take" or Action == "takeitem"
            or Action == "collect" or Action == "collectitem" or Action == "grab" or Action == "拾取" or Action == "取得"
        local bStorage = Action == "accessstorage" or Action == "openinventory" or Action == "accessinventory" or Action == "accesstrunk"
        if not bTake and not bStorage then continue end
        local Point = _PromptPoint(Prompt)
        if not Point then continue end
        local Distance = (Point - Part.Position).Magnitude
        local bLinked = Prompt:IsDescendantOf(Object) or (UID ~= nil and Prompt.Name == UID)
            or (InteractionUID ~= nil and Prompt.Name == tostring(InteractionUID))
        -- Terrain-hosted prompts are associated only when close and unambiguous.
        if not bLinked and Distance > (bTake and 3 or 1.5) then continue end
        local Score = (bLinked and 0 or 100) + (bStorage and 10 or 0) + Distance
        if Score < BestScore - 0.1 then
            Best, BestMode, BestScore, bAmbiguous = Prompt, bStorage and "Storage" or "Pickup", Score, false
        elseif math.abs(Score - BestScore) <= 0.1 then bAmbiguous = true end
    end
    if bAmbiguous then return nil, "附近有多個同等互動提示，請先在遊戲中確認目標" end
    return Best, BestMode
end

local function _ReturnPickup(Transaction)
    if not Transaction.Moved or Transaction.Returned then return true end
    local Character, Root = _PickupCharacter()
    if Character ~= Transaction.Character or Root ~= Transaction.Root then return false end
    local bOK = pcall(function()
        Character:PivotTo(Transaction.Origin)
        Root.AssemblyLinearVelocity, Root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
    end)
    if bOK then Transaction.Returned = true end
    return bOK
end

local function _PickupMessage(Message)
    State.PickupStatus = Message
    if PickupReadout and State.bAlive then PickupReadout:Set(Message) end
end

local function _FinishPickup(Transaction, Message)
    if State.ActivePickup ~= Transaction then return end
    if Transaction.Holding and Transaction.Prompt.Parent then pcall(Transaction.Prompt.InputHoldEnd, Transaction.Prompt) end
    local bReturned = _ReturnPickup(Transaction)
    State.ActivePickup = nil
    if Transaction.Confirmed then
        State.Items[Transaction.Object] = nil
        if _RemoveVisual then _RemoveVisual(Transaction.Object) end
    end
    if Transaction.Moved then Message ..= bReturned and "；已在本機返回原位" or "；角色狀態已改變，未返回原位" end
    _PickupMessage(Message)
    if State.bAlive then _Notify("取得物品", Message); if _RefreshPickupList then _RefreshPickupList() end end
end

local function _CancelPickup()
    local Transaction = State.ActivePickup
    if Transaction then _FinishPickup(Transaction, "已取消取得") end
end

local function _RequestPickup(Object)
    if State.ActivePickup then _Notify("取得物品", "已有請求處理中，請等待或取消。"); return end
    local Entry = State.Items[Object]
    if not Entry or not _WorldItem(Object) then _PickupMessage("物品已被取得或移除，請重新整理"); return end
    local Character, Root, Humanoid, Reason = _PickupCharacter()
    if not Character then _PickupMessage(Reason); return end
    local Part = _ItemPart(Object, Entry.Root, true)
    if not Part then _PickupMessage("尚未取得物品位置"); return end
    local Prompt, Mode = _PickupPrompt(Object, Part)
    if not Prompt then _PickupMessage(Mode or "找不到對應的拾取或背包提示，尚未送出請求"); return end
    local UID = _PickupUID(Object)
    if _OwnedPickup(Object, UID) then _PickupMessage("此物品已在自己的背包或角色上"); return end
    local Transaction = {__OWOwned = true, Character = Character, Root = Root, Humanoid = Humanoid, Origin = Character:GetPivot(),
        Prompt = Prompt, Object = Object, UID = UID, Moved = false, Returned = false, Holding = false,
        Deadline = os.clock() + Config.PickupTimeout}
    State.ActivePickup = Transaction
    State.LastPickupInfo = {Item = Object:GetFullName(), UID = UID, Prompt = Prompt:GetFullName(), Action = Prompt.ActionText,
        Mode = Mode, Backend = type(fireproximityprompt) == "function" and "fireproximityprompt" or "InputHoldBegin/End"}
    State.Target = nil
    if PickupButton then PickupButton:SetEnabled(false) end
    _PickupMessage("正在接近：" .. tostring(Entry.Name))
    task.spawn(function()
        local bOK, Message = pcall(function()
            if not State.bAlive or State.ActivePickup ~= Transaction then return "已取消取得" end
            local Point = _PromptPoint(Prompt)
            if not Point then return "互動提示已移除" end
            local Range = Prompt.MaxActivationDistance or 6
            if Range <= 0 then return "此互動提示尚未開放使用" end
            if (Root.Position - Point).Magnitude > Range - 0.2 then
                if not Config.bPickupTeleport then return "物品太遠，請先接近或開啟遠距離取得" end
                local Offset = Vector3.new(0, math.min(1, Range / 4), math.min(3, Range / 2))
                Transaction.Moved = true
                Character:PivotTo(Character:GetPivot() + (Point + Offset - Root.Position))
                Root.AssemblyLinearVelocity, Root.AssemblyAngularVelocity = Vector3.zero, Vector3.zero
                task.wait(0.5)
            end
            if not State.bAlive or State.ActivePickup ~= Transaction then return "已取消取得" end
            local Current, CurrentRoot = _PickupCharacter()
            Point = Prompt.Parent and _PromptPoint(Prompt)
            if Current ~= Character or CurrentRoot ~= Root then return "角色或座位狀態已改變，取消取得" end
            if not _WorldItem(Object) or not Point then return "目標物品或互動提示已移除" end
            if (Root.Position - Point).Magnitude > Range then return "未能接近物品，位置可能已被伺服器還原" end
            if not Prompt.Enabled then return "此互動提示目前不可用" end
            local Hold = math.max(0, Prompt.HoldDuration or 0)
            if Hold + 0.1 > Transaction.Deadline - os.clock() then return "互動所需時間超出本次等待上限" end
            if type(fireproximityprompt) == "function" then
                fireproximityprompt(Prompt)
            else
                Transaction.Holding = true
                Prompt:InputHoldBegin(); task.wait(Hold + 0.1)
                if not State.bAlive or State.ActivePickup ~= Transaction then return "已取消取得" end
                Prompt:InputHoldEnd(); Transaction.Holding = false
            end
            if not State.bAlive or State.ActivePickup ~= Transaction then return "已取消取得" end
            _PickupMessage(Mode == "Storage" and "已開啟容器；請在遊戲背包介面移入物品，確認後會返回" or "已送出拾取互動，正在確認背包")
            if Mode == "Storage" and Window then Window:Minimize() end
            repeat
                if not State.bAlive or State.ActivePickup ~= Transaction then return "已取消取得" end
                if _OwnedPickup(Object, UID) then Transaction.Confirmed = true; return "已確認物品進入自己的背包或角色" end
                if not Object.Parent or not Object:IsDescendantOf(workspace) then return "物品已離開地面；背包歸屬尚未確認" end
                local CurrentCharacter, CurrentRootPart = _PickupCharacter()
                if CurrentCharacter ~= Character or CurrentRootPart ~= Root then return "角色狀態已改變，取消等待" end
                task.wait(0.1)
            until os.clock() >= Transaction.Deadline
            return Mode == "Storage" and "容器已開啟，但尚未確認物品轉入背包" or "等待逾時，未確認取得；請檢查背包容量與拾取條件"
        end)
        if State.ActivePickup == Transaction then _FinishPickup(Transaction, bOK and Message or ("取得發生錯誤：" .. tostring(Message))) end
    end)
end

local function _PickupMenuOpen()
    local Popup = Window and Window._Popup
    return PickupDropdown ~= nil and ((type(Popup) == "table" and Popup.Owner == PickupDropdown)
        or PickupDropdown._PaintOptions ~= nil)
end

local function _SamePickupOptions(A, B)
    if not A or #A ~= #B then return false end
    for Index, Option in ipairs(B) do
        if A[Index].Value ~= Option.Value or A[Index].Name ~= Option.Name then return false end
    end
    return true
end

local function _PickupControlEnabled(Control, bEnabled)
    local Current = Control.bEnabled
    if type(Current) ~= "boolean" then Current = Control.Enabled end
    if Current ~= bEnabled then Control:SetEnabled(bEnabled) end
end

_RefreshPickupList = function()
    if not State.bAlive or not PickupDropdown then return end
    local _, Root, _, Reason = _PickupCharacter(true)
    local Rows, Options, ById = {}, {}, {}
    for Object, Entry in pairs(State.Items) do
        if not _WorldItem(Object) or Object:GetAttribute("Prefab") == "Ammo" then continue end
        local Part = _ItemPart(Object, Entry.Root, false)
        if Part then
            local Id = State.PickupIds[Object]
            if not Id then State.NextPickupId += 1; Id = "ow_item_" .. State.NextPickupId; State.PickupIds[Object] = Id end
            Rows[#Rows + 1] = {__OWOwned = true, Object = Object, Id = Id, Name = Entry.Name,
                Distance = Root and (Root.Position - Part.Position).Magnitude or math.huge}
        end
    end
    table.sort(Rows, function(A, B)
        if A.Distance ~= B.Distance then return A.Distance < B.Distance end
        return A.Id < B.Id
    end)
    for _, Row in ipairs(Rows) do
        ById[Row.Id] = Row.Object
        Options[#Options + 1] = {Name = tostring(Row.Name) .. (Row.Distance < math.huge and
            (" · " .. math.floor(Row.Distance) .. " studs") or " · 角色尚未載入"), Value = Row.Id}
    end
    -- Keep validity current even while displaying an older popup snapshot.
    State.PickupById = ById
    local bOpen = _PickupMenuOpen()
    local bChanged = not _SamePickupOptions(State.PickupAppliedOptions, Options)
    State.PickupListPending = bOpen and bChanged
    if bChanged and not bOpen then
        -- Library Refresh() closes its popup. Never call it while the user browses.
        PickupDropdown:Refresh(Options, true, true)
        State.PickupAppliedOptions = Options
    end
    if not bOpen then _PickupControlEnabled(PickupDropdown, #Options > 0 and State.ActivePickup == nil) end
    local bValidSelection = ById[PickupDropdown:Get()] ~= nil
    _PickupControlEnabled(PickupButton, bValidSelection and Root ~= nil and Reason == nil and State.ActivePickup == nil)
    local Suffix = Reason and ("；" .. Reason) or ""
    if State.PickupListPending then Suffix ..= "；清單更新將於選單關閉後套用" end
    if PickupReadout then PickupReadout:Set("可選物品 " .. #Options .. " 個；" .. State.PickupStatus .. Suffix) end
end


local function _FoliageCategory(Part)
    local Name = string.lower(Part.Name)
    if string.find(Name, "trunk", 1, true) or string.find(Name, "bark", 1, true) then return nil end
    if string.find(Name, "leaves", 1, true) or string.find(Name, "frond", 1, true) or string.find(Name, "canopy", 1, true) then return "Leaves" end
    if string.find(Name, "grass", 1, true) then return "Grass" end
    if string.find(Name, "shrub", 1, true) or string.find(Name, "bush", 1, true) then return "Bushes" end
    if string.find(Name, "lod", 1, true) and (string.find(Name, "tree", 1, true)
        or string.find(Name, "bamboo", 1, true) or string.find(Name, "palm", 1, true)) then return "Leaves" end
    local Parent = Part.Parent
    for _ = 1, 4 do
        if not Parent or Parent == workspace then break end
        local ParentName = string.lower(Parent.Name)
        if string.find(ParentName, "shrub", 1, true) or string.find(ParentName, "bush", 1, true) then return "Bushes" end
        if ParentName == "leaves" or ParentName == "foliage" or ParentName == "grass" then return ParentName == "grass" and "Grass" or "Leaves" end
        Parent = Parent.Parent
    end
    return nil
end

-- Buttons perform one deletion pass over currently loaded vegetation.
-- They have no saved flags and never enable an automatic deletion mode.
local function _FoliageAllowed(Part)
    local Camera = workspace.CurrentCamera
    if (Camera and Part:IsDescendantOf(Camera)) or _RigFromInstance(Part) or Part:GetAttribute("ActorUID") then return false end
    if State.Items[Part] or State.ItemRuntime[Part] or Part:GetAttribute("ItemUID")
        or Part:HasTag("Item") or Part:HasTag("InventoryItem") then return false end
    local Parent = Part.Parent
    for _ = 1, 8 do
        if not Parent or Parent == workspace then break end
        if Parent.Name == "Male" or Parent.Name == "Female" or Parent:IsA("Tool")
            or State.Items[Parent] or State.ItemRuntime[Parent] or Parent:GetAttribute("ItemUID")
            or Parent:HasTag("Item") or Parent:HasTag("InventoryItem") then return false end
        Parent = Parent.Parent
    end
    return true
end

local function _DeleteFoliage(Category)
    if State.FoliageJobs[Category] then _Notify("草木移除", "此類別正在處理中。"); return end
    State.FoliageJobs[Category] = true
    State.EnvironmentStatus = "正在分批刪除目前已載入的草木"
    task.spawn(function()
        if not State.bAlive then State.FoliageJobs[Category] = nil; return end
        local Deleted, Slice = 0, os.clock()
        local bOK, Message = pcall(function()
            if Category == "Grass" then
                local Terrain = workspace:FindFirstChildOfClass("Terrain")
                if Terrain then
                    local bTerrainOK = pcall(function() Terrain.Decoration = false end)
                    if not bTerrainOK and type(sethiddenproperty) == "function" then
                        bTerrainOK = pcall(sethiddenproperty, Terrain, "Decoration", false)
                    end
                    if not bTerrainOK then State.LastError = "無法關閉 Terrain 草；繼續刪除模型草" end
                end
            end
            for Index, Part in ipairs(workspace:GetDescendants()) do
                if not State.bAlive then return end
                if Part:IsA("BasePart") and Part.Parent and _FoliageCategory(Part) == Category and _FoliageAllowed(Part) then
                    Part:Destroy(); Deleted += 1; State.FoliageRemoved += 1
                end
                if Index % 128 == 0 or os.clock() - Slice > 0.002 then task.wait(); Slice = os.clock() end
            end
        end)
        State.FoliageJobs[Category] = nil
        if not State.bAlive then return end
        if bOK then State.EnvironmentStatus = string.format("本次已刪除 %d 個零件；新載入草木需再次按下按鈕", Deleted)
        else State.EnvironmentStatus = "草木刪除中止"; State.LastError = tostring(Message) end
    end)
end


local function _QueueObject(Object)
    if Object:IsA("ProximityPrompt") then State.PickupPrompts[Object] = true end
    if Object:IsA("Model") or Object:IsA("Tool") or Object:IsA("BasePart") then
        _TryItem(Object)
        local Parent = Object.Parent
        for _ = 1, 3 do
            if not Parent or Parent == workspace then break end
            if State.ItemCandidates[Parent] then _TryItem(Parent, true) end
            Parent = Parent.Parent
        end
    elseif Object.Name == "ItemData" or Object.Name == "Item" then
        if Object.Parent then _TryItem(Object.Parent) end
    elseif Object.Name == "#Pickup" or Object:IsA("ProximityPrompt") then
        local Action = Object:IsA("ProximityPrompt") and string.lower(Object.ActionText) or "pickup"
        if Action == "pickup" or Action == "pick up" or Action == "collect" or Action == "take item" then
            local Parent = Object.Parent
            if Parent and Parent:IsA("Attachment") then Parent = Parent.Parent end
            if Parent then _TryItem(Parent, true) end
        end
    end
    if Object:IsA("Humanoid") then
        State.Pending[Object.Parent] = os.clock() + 2
    elseif Object:IsA("Tool") then
        State.Pending[Object] = os.clock() + 2
    elseif Object:IsA("Model") then
        -- Only actual rigs or item containers enter the queue, not scenery models.
        if Object:FindFirstChild("Head") then State.Pending[Object] = os.clock() + 2
        elseif ITEM_PREFABS[Object:GetAttribute("Prefab")] or Object:GetAttribute("ItemUID") then _TryItem(Object) end
    elseif Object:IsA("BasePart") then
        if Object.Parent and Object.Parent:IsA("Tool") then State.Pending[Object.Parent] = os.clock() + 2 end
        if Object.Name == "Head" or Object.Name == "HumanoidRootPart" or Object.Name == "Root" then
            local Model = Object:FindFirstAncestorOfClass("Model")
            if Model then
                State.Pending[Model] = os.clock() + 2
                _TryActor(Model)
            end
        end
        if ITEM_PREFABS[Object:GetAttribute("Prefab")] or Object:GetAttribute("ItemUID") then
            _TryItem(Object)
        end
    end
end

local function _ScanWorkspace()
    if State.bScanning then return end
    State.bScanning = true
    State.ScanStatus = "掃描地圖中"
    task.spawn(function()
        local bOK, Message = pcall(function()
            for Index, Object in ipairs(workspace:GetDescendants()) do
                if not State.bAlive then break end
                _QueueObject(Object)
                if Index % 500 == 0 then task.wait() end
            end
        end)
        if not bOK then _Error("地圖掃描", Message) end
        State.bScanning = false
        State.ScanStatus = bOK and "掃描完成" or "掃描失敗"
    end)
end

local function _ItemTags()
    for _, Tag in ipairs(ITEM_TAGS) do
        for _, Object in ipairs(CollectionService:GetTagged(Tag)) do _TryItem(Object, true) end
    end
    for _, Object in ipairs(CollectionService:GetTagged("Prefab")) do
        if ITEM_PREFABS[Object:GetAttribute("Prefab")] then _TryItem(Object, true) end
    end
    for Name in pairs(ITEM_FOLDERS) do
        local Folder = workspace:FindFirstChild(Name)
        if Folder then for _, Object in ipairs(Folder:GetChildren()) do _TryItem(Object, true) end end
    end
end

-- Native Rbx rendering, following the attached Isle implementation.
-- World-space Highlight/BillboardGui plus a CoreGui layer for tracers.
local function _DestroyNative(Object)
    if Object then pcall(Object.Destroy, Object) end
end

local function _VisualIssue(Key, Message)
    State.VisualIssues[Key] = tostring(Message)
    State.LastError = "原生透視 " .. Key .. ": " .. tostring(Message)
end

local function _Gui(Class, Properties, Parent, Owned)
    local Object = Instance.new(Class)
    if Owned then Owned[#Owned + 1] = Object end
    State.Perf.Created += 1
    for Key, Value in pairs(Properties) do Object[Key] = Value end
    Object.Parent = Parent
    return Object
end

local function _InitOverlay()
    State.Overlay = _Gui("ScreenGui", {
        Name = "OW_NativeESP", IgnoreGuiInset = true, ResetOnSpawn = false,
        DisplayOrder = 900, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, game:GetService("CoreGui"))
    State.OverlayLayer = _Gui("Frame", {
        Name = "ESPProjection", Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1, BorderSizePixel = 0, Active = false,
    }, State.Overlay)
    State.Effects = _Gui("Folder", {Name = "OW_LocalEffects"}, workspace)
    State.VisualReady = true
    State.VisualStatus = "原生 Highlight / BillboardGui / Frame 已啟用"
end

local function _HideVisual(Visual)
    Visual.Tracer.Visible, Visual.Arrow.Visible = false, false
    Visual.Billboard.Enabled, Visual.Highlight.Enabled = false, false
end

local function _NewVisualRecord()
    local Owned = {}
    local bOK, Result = pcall(function()
        local Highlight = _Gui("Highlight", {Name = "ActorOutline", Enabled = false,
            DepthMode = Enum.HighlightDepthMode.AlwaysOnTop,
            FillTransparency = Config.bHighlightFill and Config.HighlightFillTransparency or 1,
            OutlineTransparency = Config.HighlightOutlineTransparency}, State.Effects, Owned)
        local Billboard = _Gui("BillboardGui", {Name = "TargetLabel", AlwaysOnTop = true,
            Enabled = false, Size = UDim2.fromOffset(230, 48), LightInfluence = 0,
            StudsOffsetWorldSpace = Vector3.new(0, 1.8, 0)}, State.Effects, Owned)
        local Text = _Gui("TextLabel", {Name = "Caption", BackgroundTransparency = 1,
            BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), Font = Enum.Font.GothamMedium,
            TextSize = 12, Text = "", TextXAlignment = Enum.TextXAlignment.Center,
            TextYAlignment = Enum.TextYAlignment.Center, TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
            TextStrokeTransparency = 0.2, Active = false}, Billboard, Owned)
        local Tracer = _Gui("Frame", {Name = "DirectionLine", AnchorPoint = Vector2.new(0.5, 0.5),
            BorderSizePixel = 0, BackgroundTransparency = 0, Visible = false, Active = false,
            Size = UDim2.fromOffset(0, 1), ZIndex = 9}, State.OverlayLayer, Owned)
        local Arrow = _Gui("TextLabel", {Name = "OffscreenDirection", Text = "▲", TextSize = 16,
            Font = Enum.Font.GothamMedium, AnchorPoint = Vector2.new(0.5, 0.5),
            Size = UDim2.fromOffset(20, 20), BackgroundTransparency = 1, BorderSizePixel = 0,
            TextStrokeColor3 = Color3.fromRGB(0, 0, 0), TextStrokeTransparency = 0.2,
            Visible = false, Active = false, ZIndex = 11}, State.OverlayLayer, Owned)
        return {__OWOwned = true, Highlight = Highlight,
            Billboard = Billboard, Text = Text, Tracer = Tracer, Arrow = Arrow}
    end)
    if not bOK then
        for _, Object in ipairs(Owned) do _DestroyNative(Object) end
        _VisualIssue("建立物件", Result)
        return nil
    end
    State.DrawRecords[#State.DrawRecords + 1] = Result
    return Result
end

_RemoveVisual = function(Key)
    local Visual = State.Visuals[Key]
    if not Visual then return end
    _HideVisual(Visual)
    Visual.Highlight.Adornee, Visual.Billboard.Adornee = nil, nil
    State.Visuals[Key] = nil
    Visual.Object, Visual.Root, Visual.Entry, Visual.RetryAt = nil, nil, nil, nil
    if not Visual.bPooled then
        Visual.bPooled = true
        State.DrawPool[#State.DrawPool + 1] = Visual
    end
end

local function _Visual(Key, Root, Entry)
    local Visual = State.Visuals[Key]
    if not Visual then
        Visual = table.remove(State.DrawPool) or _NewVisualRecord()
        if not Visual then return nil end
        Visual.bPooled = false
        State.Visuals[Key] = Visual
    end
    Visual.Object, Visual.Root, Visual.Entry = Key, Root, Entry
    return Visual
end

local function _CategoryEnabled(Entry)
    if not Entry then return Config.bItemESP end
    if _IsLocalEntry(Entry) or not _LiveAlive(Entry) then return false end
    local Relation = Entry.Relation
    return (Relation == "Enemy" and Config.bEnemyESP)
        or (Relation == "SurrenderedEnemy" and Config.bSurrenderedESP)
        or (Relation == "Friendly" and Config.bFriendlyESP)
        or (Relation == "Unknown" and Config.bUnknownESP)
end

local function _UpdateVisualStyle(Visual)
    local Entry = Visual.Entry
    local Relation = Entry and Entry.Relation or "Item"
    local Color = Relation == "SurrenderedEnemy" and Config.SurrenderedColor
        or Relation == "Enemy" and Config.EnemyColor or Relation == "Unknown" and Config.UnknownColor
        or Relation == "Item" and Config.ItemColor or Config.FriendlyColor
    if Visual.Color ~= Color then
        Visual.Color = Color
        Visual.Text.TextColor3, Visual.Tracer.BackgroundColor3, Visual.Arrow.TextColor3 = Color, Color, Color
        Visual.Highlight.OutlineColor, Visual.Highlight.FillColor = Color, Color
    end
    local FillTransparency = Config.bHighlightFill and Config.HighlightFillTransparency or 1
    if Visual.Highlight.FillTransparency ~= FillTransparency then Visual.Highlight.FillTransparency = FillTransparency end
    if Visual.Highlight.OutlineTransparency ~= Config.HighlightOutlineTransparency then
        Visual.Highlight.OutlineTransparency = Config.HighlightOutlineTransparency
    end
    local Distance = Entry and Config.ESPDistance or Config.ItemDistance
    if Visual.MaxDistance ~= Distance then
        Visual.MaxDistance, Visual.Billboard.MaxDistance = Distance, Distance
    end
    local Health, Name = Entry and Entry.Health, Entry and Entry.Name or Visual.ItemName
    Visual.bTextEnabled = Config.bNames or (Entry ~= nil and (Config.bHealth or Relation == "SurrenderedEnemy" or Relation == "Unknown"))
    if Visual.LastRelation == Relation and Visual.LastName == Name and Visual.LastHealth == Health
        and Visual.LastDistance == Visual.DistanceMeters and Visual.LastNames == Config.bNames
        and Visual.LastShowHealth == Config.bHealth then return end
    Visual.LastRelation, Visual.LastName, Visual.LastHealth = Relation, Name, Health
    Visual.LastDistance, Visual.LastNames, Visual.LastShowHealth = Visual.DistanceMeters, Config.bNames, Config.bHealth
    if not Visual.bTextEnabled then return end
    local Lines = {}
    if Relation == "SurrenderedEnemy" then Lines[#Lines + 1] = "[投降敵人 NPC]" end
    if Relation == "Unknown" then Lines[#Lines + 1] = "[陣營未確認]" end
    if Config.bNames then Lines[#Lines + 1] = (Entry and (Entry.Player and "玩家 " or "NPC ") or "") .. tostring(Name) end
    local Stats = tostring(Visual.DistanceMeters or 0) .. "m"
    if Entry and Config.bHealth and Health then Stats ..= string.format("  HP %d", math.max(0, math.floor(Health))) end
    Lines[#Lines + 1] = Stats
    Visual.Text.Text = table.concat(Lines, "\n")
    Visual.Billboard.Size = UDim2.fromOffset(230, #Lines * 16 + 4)
end

-- Resolve only current anchors; native Highlight/BillboardGui track the model.
-- Projection is needed only when a tracer is enabled.
local function _LiveAnchor(Visual)
    local Entry = Visual.Entry
    if Entry then
        local Root, Head = _RigParts(Entry.Model)
        if not Root or not Head then return nil end
        Entry.Root, Entry.Head, Visual.Root = Root, Head, Root
        return Head
    end
    local Root = _ItemPart(Visual.Object, Visual.Root, false)
    Visual.Root = Root
    return Root
end

-- Same edge-clamping calculation as Isle's native GUI tracer.
local function _TracerEndpoint(X, Y, Z, Width, Height)
    local Margin = math.min(16, Width / 4, Height / 4)
    local CX, CY = Width / 2, Height / 2
    local bInvalid = X ~= X or Y ~= Y or math.abs(X) == math.huge or math.abs(Y) == math.huge
    if bInvalid then X, Y = CX, CY end
    local bOutside = bInvalid or Z <= 0 or X < Margin or X > Width - Margin or Y < Margin or Y > Height - Margin
    if not bOutside then return X, Y, false end
    local DX, DY = X - CX, Y - CY
    if Z <= 0 then DX, DY = -DX, -DY end
    if math.abs(DX) + math.abs(DY) < 0.0001 then DX, DY = 0, -1 end
    local TX = math.abs(DX) > 0.0001 and (CX - Margin) / math.abs(DX) or math.huge
    local TY = math.abs(DY) > 0.0001 and (CY - Margin) / math.abs(DY) or math.huge
    local Factor = math.min(TX, TY)
    return math.clamp(CX + DX * Factor, Margin, Width - Margin), math.clamp(CY + DY * Factor, Margin, Height - Margin), true
end

local function _SetTracer(Visual, Origin, X, Y, bOutside, Viewport)
    local DX, DY = X - Origin.X, Y - Origin.Y
    local Length = math.sqrt(DX * DX + DY * DY)
    Visual.Tracer.Position = UDim2.fromOffset((Origin.X + X) / 2, (Origin.Y + Y) / 2)
    Visual.Tracer.Size = UDim2.fromOffset(Length, 1)
    Visual.Tracer.Rotation = math.deg(math.atan2(DY, DX))
    Visual.Tracer.Visible = Length > 1
    Visual.Arrow.Visible = bOutside
    if bOutside then
        Visual.Arrow.Position = UDim2.fromOffset(X, Y)
        Visual.Arrow.Rotation = math.deg(math.atan2(Y - Viewport.Y / 2, X - Viewport.X / 2)) + 90
    end
end

local function _DrawOneVisual(Camera, Visual, Origin)
    if Visual.bPooled or not Visual.Object or not Visual.Object.Parent then _HideVisual(Visual); return false end
    if Visual.Entry and not _LiveAlive(Visual.Entry) then _MarkDead(Visual.Entry); return false end
    if not Visual.Entry and not _WorldItem(Visual.Object) then
        State.Items[Visual.Object] = nil; _RemoveVisual(Visual.Object); return false
    end
    if not _CategoryEnabled(Visual.Entry) then _HideVisual(Visual); return false end
    local Root = _LiveAnchor(Visual)
    if not Root or not Root.Parent then _HideVisual(Visual); return false end
    _UpdateVisualStyle(Visual)
    local Adornee = (Visual.Object:IsA("Model") or Visual.Object:IsA("BasePart")) and Visual.Object or Root
    if Visual.Highlight.Adornee ~= Adornee then Visual.Highlight.Adornee = Adornee end
    if Visual.Highlight.Enabled ~= Config.bHighlight then Visual.Highlight.Enabled = Config.bHighlight end
    if Visual.Billboard.Adornee ~= Root then Visual.Billboard.Adornee = Root end
    if Visual.Billboard.Enabled ~= Visual.bTextEnabled then Visual.Billboard.Enabled = Visual.bTextEnabled end
    if Config.bTracers then
        local Point = Camera:WorldToViewportPoint(Root.Position)
        local Viewport = Camera.ViewportSize
        local EndX, EndY, bOutside = _TracerEndpoint(Point.X, Point.Y, Point.Z, Viewport.X, Viewport.Y)
        _SetTracer(Visual, Origin, EndX, EndY, bOutside, Viewport)
    else Visual.Tracer.Visible, Visual.Arrow.Visible = false, false end
    return Visual.Highlight.Enabled or Visual.Billboard.Enabled or Visual.Tracer.Visible
end

local function _DrawVisuals()
    local Camera, Start = workspace.CurrentCamera, os.clock()
    if not Camera or not State.VisualReady or Camera.ViewportSize.X <= 0 or Camera.ViewportSize.Y <= 0 then
        for _, Visual in ipairs(State.DrawList) do _HideVisual(Visual) end
        State.Rendered = 0; return
    end
    local Viewport = Camera.ViewportSize
    local Origin = Vector2.new(Viewport.X / 2, Config.TracerOrigin == "Center" and Viewport.Y / 2 or Viewport.Y - 45)
    local Count = 0
    for _, Visual in ipairs(State.DrawList) do
        if Start < (Visual.RetryAt or 0) then continue end
        local bOK, Result = pcall(_DrawOneVisual, Camera, Visual, Origin)
        if not bOK then
            pcall(_HideVisual, Visual); Visual.RetryAt = Start + 1
            State.VisualFailures += 1; _VisualIssue("目標更新", Result)
        elseif Result then Count += 1 end
    end
    State.Rendered = Count
    State.Perf.RenderMs = State.Perf.RenderMs * 0.9 + (os.clock() - Start) * 1000 * 0.1
end

local function _UpdateActorClasses()
    local Count, Length = 0, #State.ActorList
    if Length == 0 then return end
    local Start = os.clock()
    while Count < math.min(16, Length) and os.clock() - Start < 0.0015 do
        if State.ActorCursor > #State.ActorList then State.ActorCursor = 1 end
        local Entry = State.ActorList[State.ActorCursor]
        if not Entry then break end
        if not _RefreshEntry(Entry) then _DropActor(Entry.Model)
        else State.ActorCursor += 1 end
        Count += 1
    end
end

_RefreshVisuals = function()
    local Camera = workspace.CurrentCamera
    if not Camera or not State.VisualReady then return end
    local Position = Camera.CFrame.Position
    local Wanted, ActorRows, ItemRows = {}, {}, {}
    State.UnknownCount = 0
    for Model, Entry in pairs(State.Actors) do
        if Entry.Relation == "Unknown" then State.UnknownCount += 1 end
        if Entry.Head and Entry.Head.Parent and _CategoryEnabled(Entry) then
            local Distance = (Entry.Head.Position - Position).Magnitude
            if Distance <= Config.ESPDistance then ActorRows[#ActorRows + 1] = {Entry, Distance} end
        end
    end
    for Object, Entry in pairs(State.Items) do
        if not _WorldItem(Object) then State.Items[Object] = nil
        elseif Config.bItemESP then
            local Root = _ItemPart(Object, Entry.Root, true)
            if Root then
                Entry.Root = Root
                local Distance = (Root.Position - Position).Magnitude
                if Distance <= Config.ItemDistance then ItemRows[#ItemRows + 1] = {Entry, Distance} end
            else State.ItemCandidates[Object] = true end
        end
    end
    local function Nearer(A, B) return A[2] < B[2] end
    table.sort(ActorRows, Nearer); table.sort(ItemRows, Nearer)
    table.clear(State.DrawList)
    -- Release first so membership churn reuses objects instead of raising the peak.
    for Index = 1, math.min(#ActorRows, Config.MaxActors) do Wanted[ActorRows[Index][1].Model] = true end
    for Index = 1, math.min(#ItemRows, Config.MaxItems) do Wanted[ItemRows[Index][1].Object] = true end
    for Key in pairs(State.Visuals) do if not Wanted[Key] then _RemoveVisual(Key) end end
    for Index = 1, math.min(#ActorRows, Config.MaxActors) do
        local Row, Entry = ActorRows[Index], ActorRows[Index][1]
        local Visual = _Visual(Entry.Model, Entry.Root, Entry)
        if Visual then
            Visual.DistanceMeters = math.floor(Row[2] / 3.281 + 0.5)
            State.DrawList[#State.DrawList + 1] = Visual
        end
    end
    for Index = 1, math.min(#ItemRows, Config.MaxItems) do
        local Row, Entry = ItemRows[Index], ItemRows[Index][1]
        local Visual = _Visual(Entry.Object, Entry.Root, nil)
        if Visual then
            Visual.ItemName = Entry.Name
            Visual.DistanceMeters = math.floor(Row[2] / 3.281 + 0.5)
            State.DrawList[#State.DrawList + 1] = Visual
        end
    end
end


local function _ActiveCombat()
    if State.ActivePickup then State.AimStatus = "取得物品中，暫停鎖定"; return false end
    if not State.bAlive or not Config.bRage then State.AimStatus = "停用"; return false end
    if not State.bFocused then State.AimStatus = "視窗未聚焦"; return false end
    if Config.bPauseUI and Window and Window.bVisible then State.AimStatus = "介面展開，已暫停"; return false end
    if GuiService.MenuIsOpen or UserInputService:GetFocusedTextBox() then State.AimStatus = "選單／文字輸入中"; return false end
    local Character = LocalPlayer.Character
    local LocalEntry = Character and State.Actors[Character]
    if LocalEntry and not LocalEntry.bAlive then State.AimStatus = "角色已死亡"; return false end
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    if Humanoid and Humanoid.Health <= 0 then State.AimStatus = "角色已死亡"; return false end
    State.AimStatus = State.Target and ("鎖定：" .. tostring(State.Target.Name)) or "搜尋已確認的敵人"
    return true
end

local function _AimPart(Entry)
    local Root, Head = _RigParts(Entry.Model)
    Entry.Root, Entry.Head = Root, Head
    return Config.AimPart == "Head" and Head or _FindRigPart(Entry.Model, "UpperTorso") or _FindRigPart(Entry.Model, "Torso") or Root
end

local function _IgnoreList()
    local Ignore = {}
    local Character = LocalPlayer.Character
    if Character then table.insert(Ignore, Character) end
    if workspace.CurrentCamera then table.insert(Ignore, workspace.CurrentCamera) end
    -- Exclude our own occupied vehicle when its seat is identifiable.
    local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")
    local Seat = Humanoid and Humanoid.SeatPart
    if Seat then
        local Vehicle = Seat:FindFirstAncestorOfClass("Model")
        if Vehicle and Vehicle ~= Character then table.insert(Ignore, Vehicle) end
    end
    return Ignore
end

local function _VehicleForEntry(Entry)
    for _, Key in ipairs({"Vehicle", "CurrentVehicle", "MountedVehicle", "Seat", "SeatPart", "Turret"}) do
        local Object = _WorldInstance(_ReadEntry(Entry, Key), 0)
        if Object then
            local Model = Object:IsA("Model") and Object or Object:FindFirstAncestorOfClass("Model")
            if Model and Model ~= Entry.Model and not Model:IsDescendantOf(Entry.Model) then return Model end
        end
    end
    local Humanoid = Entry.Humanoid
    local Seat = Humanoid and Humanoid.SeatPart
    if Seat then
        local Model = Seat:FindFirstAncestorOfClass("Model")
        if Model and Model ~= Entry.Model then
            if (Model.Name == "Seats" or Model.Name == "Interior" or Model.Name == "Chassis") and Model.Parent:IsA("Model") then
                Model = Model.Parent
            end
            return Model
        end
    end
    local Parent = Entry.Model.Parent
    for _ = 1, 6 do
        if not Parent or Parent == workspace then break end
        if Parent:IsA("Model") then
            local Prefab = Parent:GetAttribute("Prefab")
            if Parent:HasTag("Vehicle") or Parent:GetAttribute("VehicleUID") or Prefab == "Vehicle"
                or Prefab == "Turret" or Prefab == "Helicopter" or Prefab == "Boat" then return Parent end
        end
        Parent = Parent.Parent
    end
    return nil
end

local function _ClearLine(Origin, Entry, Budget)
    local Part = _AimPart(Entry)
    if not Part then return false end
    local LocalHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    local LocalSeat = LocalHumanoid and LocalHumanoid.SeatPart
    local Params = State.RaycastParams
    if not Params or State.RayCharacter ~= LocalPlayer.Character or State.RayCamera ~= workspace.CurrentCamera or State.RaySeat ~= LocalSeat then
        Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        local Ignore = _IgnoreList()
        for _, Object in ipairs(State.RayIgnored or {}) do Ignore[#Ignore + 1] = Object end
        Params.FilterDescendantsInstances = Ignore
        Params.IgnoreWater = true
        if State.BulletGroup then Params.CollisionGroup = State.BulletGroup end
        State.RaycastParams, State.RayCharacter, State.RayCamera = Params, LocalPlayer.Character, workspace.CurrentCamera
        State.RaySeat = LocalSeat
    end
    State.Perf.Raycasts += 1
    local Hit = workspace:Raycast(Origin, Part.Position - Origin, Params)
    if not Hit then return true end
    if Hit.Instance:IsDescendantOf(Entry.Model) then return true end
    -- Never intentionally fire through a friendly or unknown actor.
    local Rig = _RigFromInstance(Hit.Instance)
    if Rig then return false end
    -- Vehicle hulls are not actors. Re-test beyond only the target's own vehicle,
    -- retaining walls, terrain and other characters as line-of-sight blockers.
    local Vehicle = _VehicleForEntry(Entry)
    if Vehicle and Hit.Instance:IsDescendantOf(Vehicle) then
        if Budget and Budget < 2 then return false end
        if Entry.VehicleRayBase ~= Params or Entry.VehicleRayModel ~= Vehicle then
            local VehicleParams = RaycastParams.new()
            VehicleParams.FilterType = Enum.RaycastFilterType.Exclude
            local Ignore = table.clone(Params.FilterDescendantsInstances)
            Ignore[#Ignore + 1] = Vehicle
            VehicleParams.FilterDescendantsInstances = Ignore
            VehicleParams.IgnoreWater = true
            if State.BulletGroup then VehicleParams.CollisionGroup = State.BulletGroup end
            Entry.VehicleRayParams, Entry.VehicleRayBase, Entry.VehicleRayModel = VehicleParams, Params, Vehicle
        end
        State.Perf.Raycasts += 1
        Hit = workspace:Raycast(Origin, Part.Position - Origin, Entry.VehicleRayParams)
        if not Hit or Hit.Instance:IsDescendantOf(Entry.Model) then return true end
        if _RigFromInstance(Hit.Instance) then return false end
    end
    return not Config.bLineOfSight
end

local function _ValidEnemy(Entry, bForce)
    if not Entry or Entry.bDisposed or not Entry.Model.Parent then return false end
    Entry.Root, Entry.Head = _RigParts(Entry.Model)
    if not Entry.Root or not Entry.Head or _IsLocalEntry(Entry) then return false end
    if bForce and not _RefreshEntry(Entry, true) then return false end
    if not _LiveAlive(Entry) then _MarkDead(Entry); return false end
    if Entry.Relation ~= "Enemy" or (Entry.Player and State.bOpenWorld) then return false end
    if not Entry.Player and Entry.bSurrendered then return false end
    return (Entry.Player ~= nil and Config.bPlayers) or (Entry.Player == nil and Config.bNPCs)
end

_SelectTarget = function()
    if not _ActiveCombat() then return nil end
    local Camera = workspace.CurrentCamera
    if not Camera then return nil end
    local Candidates = {}
    for _, Entry in pairs(State.Actors) do
        if not _ValidEnemy(Entry) then continue end
        local Delta = _AimPart(Entry).Position - Camera.CFrame.Position
        local Distance = Delta.Magnitude
        if Distance < 0.1 or Distance > Config.AimDistance then continue end
        local Dot = math.clamp(Camera.CFrame.LookVector:Dot(Delta.Unit), -1, 1)
        local Angle = math.deg(math.acos(Dot))
        if Angle > Config.AimFOV / 2 then continue end
        local Score = Angle
        if Config.Priority == "Distance" then Score = Distance end
        if Config.Priority == "Health" then Score = Entry.Health or math.huge end
        Candidates[#Candidates + 1] = {Entry, Score}
    end
    table.sort(Candidates, function(A, B) return A[2] < B[2] end)
    local RaysBefore = State.Perf.Raycasts
    for Index = 1, math.min(#Candidates, 8) do
        local Budget = 8 - (State.Perf.Raycasts - RaysBefore)
        if Budget <= 0 then break end
        local Entry = Candidates[Index][1]
        if _ClearLine(Camera.CFrame.Position, Entry, Budget) then return Entry end
    end
    return nil
end

local function _PredictPosition(Origin, Part, Speed)
    local Position = Part.Position
    if not Config.bPrediction or not Speed or Speed <= 1 then return Position end
    local Velocity = Part.AssemblyLinearVelocity
    if Velocity.Magnitude > 250 then Velocity = Vector3.zero end
    -- BulletClassMultithread._getPosition uses 32.2, not workspace.Gravity.
    local Time = (Position - Origin).Magnitude / Speed
    for _ = 1, 3 do
        Position = Part.Position + Velocity * Time + Vector3.new(0, 0.5 * 32.2 * Time * Time, 0)
        Time = (Position - Origin).Magnitude / Speed
    end
    return Position
end

local function _AttachBullet(Service)
    if State.BulletService == Service then return end
    if type(Service) ~= "table" then return end
    local Owner = Service
    if type(rawget(Owner, "Discharge")) ~= "function" then
        local Metatable = getmetatable(Service)
        if type(Metatable) ~= "table" then return end
        Owner = type(rawget(Metatable, "__index")) == "table" and rawget(Metatable, "__index") or Metatable
    end
    local Original = _Raw(Owner, "Discharge")
    if type(Original) ~= "function" or type(Service.GetInfo) ~= "function" then return end
    -- The saved implementation has both fields; this avoids similarly named services.
    if type(_Raw(Service, "_workers")) ~= "table" or type(_Raw(Service, "_bulletWorkers")) ~= "table" then return end
    local Record = {Owner = Owner, Original = Original, TargetFunction = Original, Service = Service, bHookFunction = false}
    local function Replacement(Self, Origin, Caliber, Barrel, UID, Replicate, LocalFlag, ...)
        if not State.bAlive then return Record.Original(Self, Origin, Caliber, Barrel, UID, Replicate, LocalFlag, ...) end
        State.ShotSeen += 1
        if LocalFlag == true then
            State.LocalShotSeen += 1
            local bInfoOK, Speed, _, Range = pcall(Service.GetInfo, Self, Caliber, Barrel)
            if bInfoOK and type(Speed) == "number" and Speed > 1 then
                State.ShotVelocity = Speed
                State.ShotRange = type(Range) == "number" and Range or nil
            end
        end
        local Entry = State.Target
        if _CanRewriteShot(Config.bDischarge, _ActiveCombat(), LocalFlag, Entry and Entry.Relation)
            and typeof(Origin) == "CFrame" then
            local bOK, NewOrigin = pcall(function()
                if not _ValidEnemy(Entry, true) or not _ClearLine(Origin.Position, Entry) then return nil end
                local Part = _AimPart(Entry)
                local Distance = (Part.Position - Origin.Position).Magnitude
                if Distance > Config.AimDistance or (State.ShotRange and Distance > State.ShotRange) then return nil end
                local Position = _PredictPosition(Origin.Position, Part, State.ShotVelocity or Config.FallbackVelocity)
                if (Position - Origin.Position).Magnitude < 0.1 then return nil end
                return CFrame.lookAt(Origin.Position, Position)
            end)
            if bOK and NewOrigin then Origin = NewOrigin; State.Redirected += 1 end
            if not bOK then State.LastError = "彈道修正：" .. tostring(NewOrigin) end
        end
        return Record.Original(Self, Origin, Caliber, Barrel, UID, Replicate, LocalFlag, ...)
    end
    Record.Replacement = Replacement
    local bOK, Result
    if type(hookfunction) == "function" then
        local Hook = type(newcclosure) == "function" and newcclosure(Replacement) or Replacement
        bOK, Result = pcall(hookfunction, Original, Hook)
        if bOK and type(Result) == "function" then
            Record.Original = Result
            Record.Replacement = Hook
            Record.bHookFunction = true
        else bOK = false end
    end
    if not bOK then
        bOK, Result = pcall(function()
            assert(not table.isfrozen(Owner), "BulletService 方法表已凍結")
            Owner.Discharge = Replacement
        end)
    end
    if not bOK then State.HookStatus = "無法連接：" .. tostring(Result); return end
    State.BulletService = Service
    State.HookStatus = Record.bHookFunction and "Discharge 函式接入" or "Discharge 方法接入"
    table.insert(State.Hooks, Record)
end

local RUNTIME_MODEL_KEYS = {"Model", "Character", "Rig", "RootPart", "HumanoidRootPart", "Root", "Render", "Body", "Instance", "Object", "Humanoid", "Actor", "Avatar"}

local function _RuntimeRig(Object, Depth, Seen)
    if typeof(Object) == "Instance" then return _RigFromInstance(Object) end
    if type(Object) ~= "table" or Depth > 3 or Seen[Object] then return nil end
    Seen[Object] = true
    for _, Key in ipairs(RUNTIME_MODEL_KEYS) do
        local Value = _Raw(Object, Key)
        if Value ~= nil then
            local Model = _RuntimeRig(Value, Depth + 1, Seen)
            if Model then return Model end
        end
    end
    return nil
end

local function _IndexRuntime(Object)
    if type(Object) ~= "table" or rawget(Object, "__OWOwned") then return end
    _IndexWorldItem(Object)
    if _Raw(Object, "_workers") and _Raw(Object, "_bulletWorkers") then _AttachBullet(Object) end
    local UID = _First(_Raw(Object, "ActorUID"), _Raw(Object, "UID"))
    local bActorData = UID ~= nil or _Raw(Object, "TargetGroup") ~= nil
        or _Raw(Object, "IsFriendly") ~= nil or _Raw(Object, "Health") ~= nil
        or _Raw(Object, "_health") ~= nil or _Raw(Object, "Player") ~= nil
        or _Raw(Object, "Config") ~= nil or _Raw(Object, "State") ~= nil
    if not bActorData then return end
    local Model = _RuntimeRig(Object, 0, {})
    if Model and not Model:IsDescendantOf(workspace) then Model = nil end
    local function Score(Table)
        if not Table then return -1 end
        local Value = 0
        for _, Key in ipairs({"TargetGroup", "IsFriendly", "Friendly", "Health", "Config", "Preset", "Player", "State", "Data"}) do
            if _Raw(Table, Key) ~= nil then Value += 1 end
        end
        return Value
    end
    if Model then
        local Root, Head = _RigParts(Model)
        UID = _First(UID, Model:GetAttribute("ActorUID"), _Attribute(Root, "ActorUID"), _Attribute(Head, "ActorUID"))
        if Score(Object) >= Score(State.RuntimeByModel[Model]) then State.RuntimeByModel[Model] = Object end
        if (_Raw(Object, "IsLocal") == true or _Raw(Object, "Local") == true or _Raw(Object, "Player") == LocalPlayer)
            and UID ~= nil then State.LocalActorUIDs[tostring(UID)] = true end
    end
    if (type(UID) == "string" or type(UID) == "number") and Score(Object) > 0 then
        if Score(Object) >= Score(State.RuntimeByUID[tostring(UID)]) then State.RuntimeByUID[tostring(UID)] = Object end
    end
    if Model then _TryActor(Model) end
end

local bRuntimeScanning = false
_ScanRuntime = function()
    if bRuntimeScanning then return end
    bRuntimeScanning = true
    task.spawn(function()
        local bOK, Message = pcall(function()
            if type(getgc) ~= "function" then State.ScanStatus = "getgc 不可用；使用模型屬性"; return end
            local Objects = getgc(true)
            local Slice = os.clock()
            for Index, Object in ipairs(Objects) do
                if not State.bAlive then return end
                _IndexRuntime(Object)
                if Index % 128 == 0 or os.clock() - Slice > 0.002 then task.wait(); Slice = os.clock() end
            end
        end)
        bRuntimeScanning = false
        if not bOK then _Error("執行期辨識", Message) end
    end)
end

local function _IndexRegistry(Export)
    if type(Export) ~= "table" then return end
    _IndexRuntime(Export)
    for _, Key in ipairs({"Actors", "Characters", "Bots", "Clients", "Items", "WorldItems", "DroppedItems", "Drops", "Pickups", "ItemObjects"}) do
        local Registry = _Raw(Export, Key)
        if type(Registry) ~= "table" then continue end
        if not State.RegistrySeen[Registry] then
            State.RegistrySeen[Registry] = true
            State.RegistrySources[#State.RegistrySources + 1] = Registry
        end
        local Count = 0
        for UID, Value in pairs(Registry) do
            if typeof(Value) == "Instance" then _TryItem(Value, true)
            elseif type(Value) == "table" then
                _IndexRuntime(Value)
                if type(UID) == "string" and #UID >= 20 then State.RuntimeByUID[UID] = Value end
            end
            Count += 1
            if Count >= 4096 then break end
        end
    end
end

local function _RefreshCachedRegistries()
    for _, Registry in ipairs(State.RegistrySources) do
        for UID, Value in pairs(Registry) do
            if typeof(Value) == "Instance" then _TryItem(Value, true)
            elseif type(Value) == "table" then
                _IndexWorldItem(Value)
                local Key = _First(_Raw(Value, "ActorUID"), _Raw(Value, "UID"), type(UID) == "string" and #UID >= 20 and UID or nil)
                if Key ~= nil then State.RuntimeByUID[tostring(Key)] = Value end
            end
        end
    end
end

local function _RefreshRuntimeSettings()
    State.RaycastParams = nil
    State.RayIgnored = CollectionService:GetTagged("RayIgnore")
    local Settings = ReplicatedStorage:FindFirstChild("Settings")
    if Settings and Settings:IsA("StringValue") then
        local bOK, Data = pcall(function() return HttpService:JSONDecode(Settings.Value) end)
        if bOK and type(Data) == "table" then
            if type(Data.IS_PVP) == "boolean" then State.bPvP = Data.IS_PVP end
            local Mode = Data.MODE or Data.GAME_MODE or Data.Mode or Data.GameMode
            if type(Mode) == "string" then
                State.bOpenWorld = string.lower(Mode):gsub("[^%a]", "") == "openworld"
            else State.bOpenWorld = game.PlaceId == 13622622708 or Data.IS_PVP == false end
        end
    end
    local bOK, Groups = pcall(function() return workspace:GetRegisteredCollisionGroups() end)
    if not bOK then bOK, Groups = pcall(function() return game:GetService("PhysicsService"):GetRegisteredCollisionGroups() end) end
    if bOK and type(Groups) == "table" then
        for _, Group in ipairs(Groups) do
            local Name, Id = Group.name or Group.Name, Group.id or Group.Id
            if type(Name) == "string" and (Id == 9 or Name == "BulletCast" or Name == "9") then State.BulletGroup = Name; break end
        end
    end
end

_RefreshModules = function()
    -- The game unparents its client modules after startup. Its existing importer
    -- can still reach the initialized exports even if getloadedmodules is absent.
    if type(shared) == "table" and type(shared.import) == "function" then
        local bOK, Importer = pcall(shared.import, "require")
        if bOK and (type(Importer) == "table" or type(Importer) == "function") then
            local bBulletOK, Service = pcall(function() return Importer("BulletService") end)
            if bBulletOK then _AttachBullet(Service) end
            local bItemsOK, Catalog = pcall(function() return Importer("ItemLayout") end)
            if bItemsOK then _LoadItemCatalog(Catalog) end
            for _, Name in ipairs({"ActorService", "CharacterService", "BotService", "clients", "ItemService", "WorldItemService", "InventoryService", "LootService"}) do
                local bRegistryOK, Registry = pcall(function() return Importer(Name) end)
                if bRegistryOK then _IndexRegistry(Registry) end
            end
        end
    end
    local Candidates = {}
    if type(getloadedmodules) == "function" then
        local bOK, Modules = pcall(getloadedmodules)
        if bOK and type(Modules) == "table" then
            for _, Module in ipairs(Modules) do
                if typeof(Module) == "Instance" and (Module.Name == "BulletService" or Module.Name == "Bots"
                    or Module.Name == "ActorService" or Module.Name == "CharacterService" or Module.Name == "BotService" or Module.Name == "clients"
                    or Module.Name == "ItemLayout" or Module.Name == "ItemService" or Module.Name == "WorldItemService"
                    or Module.Name == "InventoryService" or Module.Name == "LootService") then
                    table.insert(Candidates, Module)
                end
            end
        end
    end
    -- Already-loaded modules can be unparented; getloadedmodules finds those.
    -- The saved Bots configuration is pure data and is safe to read directly.
    local Shared = ReplicatedStorage:FindFirstChild("Shared")
    local Configs = Shared and Shared:FindFirstChild("Configs")
    local Bots = Configs and Configs:FindFirstChild("Bots")
    if Bots and Bots:IsA("ModuleScript") then table.insert(Candidates, Bots) end
    local Inventory = Shared and Shared:FindFirstChild("Inventory")
    local ItemLayout = Inventory and Inventory:FindFirstChild("ItemLayout")
    if ItemLayout and ItemLayout:IsA("ModuleScript") then table.insert(Candidates, ItemLayout) end
    for _, Module in ipairs(Candidates) do
        if State.ModuleByName[Module] then continue end
        State.ModuleByName[Module] = true
        task.spawn(function()
            local bOK, Value = pcall(require, Module)
            if not State.bAlive then return end
            if bOK and type(Value) == "table" then
                if Module.Name == "BulletService" then _AttachBullet(Value) end
                if Module.Name == "ItemLayout" then _LoadItemCatalog(Value) end
                if Module.Name ~= "Bots" then _IndexRegistry(Value) end
                if Module.Name == "Bots" then
                    for Name, Profile in pairs(Value) do
                        if type(Name) == "string" and type(Profile) == "table" then State.Profiles[Name] = Profile end
                    end
                end
            elseif not bOK then State.LastError = "讀取 " .. Module.Name .. ": " .. tostring(Value) end
        end)
    end
end

function State.Destroy(Self)
    if not Self.bAlive then return end
    Self.bAlive = false
    _CancelPickup()
    pcall(function() RunService:UnbindFromRenderStep(Self.RenderName) end)
    for _, Connection in ipairs(Self.Connections) do Connection:Disconnect() end
    local Models = {}
    for Model in pairs(Self.Actors) do table.insert(Models, Model) end
    for _, Model in ipairs(Models) do _DropActor(Model) end
    for _, Record in ipairs(Self.Hooks) do
        if Record.bHookFunction then
            if type(restorefunction) == "function" then
                pcall(restorefunction, Record.TargetFunction)
            end
            -- If the executor cannot restore hooks, the dead wrapper is pass-through.
        elseif _Raw(Record.Owner, "Discharge") == Record.Replacement then
            pcall(function() Record.Owner.Discharge = Record.Original end)
        end
    end
    for _, Visual in ipairs(Self.DrawRecords) do
        if not Visual.bDestroyed then
            _DestroyNative(Visual.Tracer); _DestroyNative(Visual.Arrow)
            _DestroyNative(Visual.Billboard); _DestroyNative(Visual.Highlight)
            Visual.bDestroyed = true
        end
    end
    _DestroyNative(Self.Overlay); _DestroyNative(Self.Effects)
    table.clear(Self.DrawList); table.clear(Self.DrawPool)
    if Window and not Window.bDestroyed then Window:Destroy() end
    if ENV[INSTANCE_KEY] == Self then ENV[INSTANCE_KEY] = nil end
    table.clear(Self.Actors); table.clear(Self.Items); table.clear(Self.Visuals); table.clear(Self.HostileUIDs)
end

local function _Toggle(Section, Key, Name, Description, bSave)
    local Control = Section:CreateToggle({
        Name = Name, Description = Description, Flag = Key,
        bCurrentValue = Config[Key], bSave = bSave ~= false,
        Callback = function(Value)
            Config[Key] = Value
            State.VisualMembershipDirty = true
            if Key == "bRage" and not Value then State.Target = nil end
        end,
    })
    State.Controls[Key] = Control
    return Control
end

local function _Slider(Section, Key, Name, Minimum, Maximum, Step, Suffix)
    local Control = Section:CreateSlider({
        Name = Name, Flag = Key, Range = {Minimum, Maximum}, Increment = Step,
        CurrentValue = Config[Key], Suffix = Suffix,
        Callback = function(Value) Config[Key] = Value end,
    })
    State.Controls[Key] = Control
    return Control
end

local function _Dropdown(Section, Key, Name, Options)
    local Control = Section:CreateDropdown({
        Name = Name, Flag = Key, Options = Options, CurrentOption = Config[Key],
        Callback = function(Value) if Value ~= nil then Config[Key] = Value end end,
    })
    State.Controls[Key] = Control
    return Control
end

local Status, ShotStatus, ActorStatus, ErrorStatus, PerformanceStatus, EnvironmentStatus

local function _BuildUI()
    Window = Library:CreateWindow({
        Name = "OW Sawang", Subtitle = "Delta · ESP / Ragebot · " .. VERSION,
        ConfigId = "OW_Sawang_13622622708_" .. tostring(LocalPlayer.UserId),
        Width = 730, Height = 500, bResizable = true,
        Accent = "#54D6AB", ConfigurationSaving = {bEnabled = true},
        ToggleKey = Enum.KeyCode.RightShift,
    })
    -- Explicit user preference: the UI is always parented to CoreGui.
    Window.ScreenGui.Parent = game:GetService("CoreGui")
    local ESP = Window:CreateTab("透視", "eye")
    local Characters = ESP:CreateSection({Name = "角色", Side = "left"})
    _Toggle(Characters, "bEnemyESP", "敵人透視", "顯示已確認的敵對玩家與 NPC。")
    _Toggle(Characters, "bSurrenderedESP", "投降敵人 NPC 透視", "獨立分類；敵人投降時立即切換，Ragebot 同步停止鎖定。")
    _Toggle(Characters, "bFriendlyESP", "友軍透視", "Openworld 中其他玩家一律為友軍，並顯示已確認的友軍 NPC。")
    _Toggle(Characters, "bUnknownESP", "未確認陣營（橘色）", "單獨顯示尚未取得陣營的角色；不納入 Ragebot。")
    _Toggle(Characters, "bHighlight", "Highlight 輪廓")
    _Toggle(Characters, "bHighlightFill", "Highlight 填色（Fill）", "關閉時只顯示輪廓；填色會使用各分類的顏色。")
    _Slider(Characters, "HighlightOutlineTransparency", "輪廓透明度", 0, 1, 0.05)
    _Slider(Characters, "HighlightFillTransparency", "Fill 透明度", 0, 1, 0.05)
    _Toggle(Characters, "bTracers", "追蹤線")
    _Dropdown(Characters, "TracerOrigin", "追蹤線起點", {{Name = "畫面底部", Value = "Bottom"}, {Name = "畫面中央", Value = "Center"}})
    Characters:CreateParagraph({Title = "原生 GUI 透視", Content = "依照 Isle 使用 Highlight、BillboardGui 與 Frame。使用模型 Highlight，追蹤線固定 1px；透明度 0 為不透明，1 為完全透明。畫面外以方向箭頭指引，死亡角色立即移除。"})
    _Toggle(Characters, "bNames", "顯示名稱與距離")
    _Toggle(Characters, "bHealth", "顯示生命值")
    _Slider(Characters, "ESPDistance", "角色顯示距離", 100, 10000, 100, " studs")
    _Slider(Characters, "MaxActors", "角色顯示上限（由近至遠）", 10, 200, 10)
    local Items = ESP:CreateSection({Name = "物品", Side = "right"})
    _Toggle(Items, "bItemESP", "物品透視", "使用背包 ItemLayout 目錄、序列化 Item 與掉落物資料辨識可拾取物品；排除已持有的物品。")
    _Slider(Items, "ItemDistance", "物品顯示距離", 100, 6000, 100, " studs")
    _Slider(Items, "MaxItems", "物品顯示上限（由近至遠）", 10, 150, 10)
    Items:CreateParagraph({Title = "辨識方式", Content = "自訂角色以零件 ActorUID 對應資料。未確認陣營會另外以橘框標示，不會納入敵人鎖定；樹木 Humanoid 排除。"})
    for _, Row in ipairs({{"EnemyColor", "敵人顏色"}, {"SurrenderedColor", "投降敵人顏色"}, {"FriendlyColor", "友軍顏色"}, {"ItemColor", "物品顏色"}}) do
        local Key = Row[1]
        local Control = Items:CreateColorPicker({Name = Row[2], Flag = Key, Color = Config[Key], Callback = function(Color) Config[Key] = Color end})
        State.Controls[Key] = Control
    end
    local PickupTab = Window:CreateTab("物品", "file")
    local Ground = PickupTab:CreateSection({Name = "取得物品", Side = "full"})
    Ground:CreateParagraph({Title = "取得流程", Content = "在下拉欄選擇物品後按取得；使用遊戲本身的拾取提示，完成或取消後返回原位。若提示只提供 Access Storage，需在遊戲背包介面完成移轉；未確認入包時不會顯示成功。"})
    _Toggle(Ground, "bPickupTeleport", "遠距離取得後返回", "開啟時會先在本機接近物品；關閉時只處理目前可互動距離內的物品。")
    PickupReadout = Ground:CreateLabel("正在讀取物品…")
    PickupDropdown = Ground:CreateDropdown({Name = "選擇物品", Options = {}, bSearchable = true,
        Flag = "ow_pickup_selection", Save = false, bSave = false})
    PickupButton = Ground:CreateButton({Name = "取得選取物品", Enabled = false, Callback = function()
        local Object = State.PickupById[PickupDropdown:Get()]
        if Object then _RequestPickup(Object) else _PickupMessage("物品已變更，請重新整理並選擇") end
    end})
    Ground:CreateButton({Name = "取消取得並返回", Callback = _CancelPickup})
    Ground:CreateButton({Name = "重新整理物品", Style = "outline", Callback = function()
        _ScanWorkspace(); _ItemTags(); _RefreshPickupList()
    end})
    local EnvironmentTab = Window:CreateTab("環境", "leaf")
    local Plants = EnvironmentTab:CreateSection({Name = "草木移除", Side = "full"})
    Plants:CreateButton({Name = "刪除草", Callback = function() _DeleteFoliage("Grass") end})
    Plants:CreateButton({Name = "刪除草叢", Callback = function() _DeleteFoliage("Bushes") end})
    Plants:CreateButton({Name = "刪除樹葉", Callback = function() _DeleteFoliage("Leaves") end})
    Plants:CreateParagraph({Title = "直接刪除", Content = "按鈕分批刪除目前已載入的草木 Instance，不會恢復。新載入的草木需再次按下按鈕；不會儲存或自動套用刪除設定。"})
    EnvironmentStatus = Plants:CreateLabel("尚未刪除草木")
    local Combat = Window:CreateTab("Ragebot", "crosshair")
    local Aim = Combat:CreateSection({Name = "目標鎖定", Side = "left"})
    _Toggle(Aim, "bRage", "啟用 Ragebot", "只鎖定已確認的敵人；射擊由你手動操作。每次載入預設關閉。", false)
    _Toggle(Aim, "bPlayers", "鎖定敵對玩家")
    _Toggle(Aim, "bNPCs", "鎖定敵對 NPC")
    _Dropdown(Aim, "AimPart", "瞄準部位", {{Name = "頭部", Value = "Head"}, {Name = "身體", Value = "Body"}})
    _Dropdown(Aim, "Priority", "目標優先順序", {{Name = "最接近準心", Value = "Crosshair"}, {Name = "最近距離", Value = "Distance"}, {Name = "最低生命值", Value = "Health"}})
    _Slider(Aim, "AimFOV", "搜尋角度", 10, 360, 10, "°")
    _Slider(Aim, "AimDistance", "鎖定距離", 100, 6000, 100, " studs")
    local Fire = Combat:CreateSection({Name = "射擊與載具", Side = "right"})
    _Toggle(Fire, "bDischarge", "接入共用彈道", "只修正自己的 Discharge；機砲需使用同一服務。")
    _Toggle(Fire, "bPrediction", "移動預判與彈道下墜補償")
    _Toggle(Fire, "bLineOfSight", "需要直線視野")
    _Toggle(Fire, "bPauseUI", "介面展開時暫停")
    Fire:CreateParagraph({Title = "手動射擊", Content = "啟用後修正瞄準方向。此版本沒有自動開火或模擬點擊；請自行按下射擊鍵。"})
    _Slider(Fire, "FallbackVelocity", "尚未偵測到射擊時的彈速", 300, 6000, 100)
    Fire:CreateParagraph({Title = "載具機砲", Content = "先進入機砲操作或第一人稱瞄準模式。相機鎖定會持續運作；有偵測到自己的 Discharge 時，才會修正共用彈道。伺服器命中仍需實測。"})
    Fire:CreateParagraph({Title = "載具內敵人", Content = "使用座位與載具資料辨識乘員；視線檢查會略過目標所乘載具，仍保留牆壁及其他角色遮擋判定。射擊維持手動。"})
    local Settings = Window:CreateTab("設定", "settings")
    local Detection = Settings:CreateSection({Name = "敵友與狀態", Side = "left"})
    _Dropdown(Detection, "NoTeamPolicy", "沒有隊伍資訊的玩家", {{Name = "略過（預設）", Value = "Ignore"}, {Name = "視為友軍（PvE）", Value = "Friendly"}, {Name = "視為敵軍（限 FFA）", Value = "Enemy"}})
    Status = Detection:CreateLabel("正在初始化…")
    ActorStatus = Detection:CreateLabel("角色：0")
    ShotStatus = Detection:CreateLabel("射擊：0 / 自己：0 / 修正：0")
    PerformanceStatus = Detection:CreateLabel("原生 GUI：等待初始化")
    ErrorStatus = Detection:CreateParagraph({Title = "最近狀態", Content = "無"})
    Detection:CreateParagraph({Title = "反作弊繞過未實作", Content = "附檔沒有 Flux/client 與伺服器檢查，無法據此實作已確認有效的繞過。此版本未包含反作弊繞過。"})
    local Actions = Settings:CreateSection({Name = "操作", Side = "right"})
    Actions:CreateButton({Name = "重新掃描地圖與執行期", Callback = function() _ScanWorkspace(); _RefreshModules(); _ScanRuntime(); _ItemTags() end})
    Actions:CreateButton({Name = "儲存設定", Callback = function()
        local bOK, Message = Window:SaveConfiguration()
        _Notify(bOK and "已儲存設定" or "設定未儲存", tostring(Message))
    end})
    Actions:CreateButton({Name = "縮小視窗", Callback = function() Window:Minimize() end})
    Actions:CreateButton({Name = "複製診斷", Callback = function()
        local Actors = {}
        for _, Entry in pairs(State.Actors) do
            if #Actors >= 12 then break end
            local Attributes = {}
            for _, Key in ipairs({"ActorUID", "TargetGroup", "IsFriendly", "Friendly", "Preset", "Type", "Health", "IsSurrendered", "Surrendered", "Surrendering", "Emote", "EmoteName"}) do
                local Value = _ReadEntry(Entry, Key)
                if type(Value) == "string" or type(Value) == "boolean" or type(Value) == "number" then Attributes[Key] = Value end
            end
            table.insert(Actors, {Path = Entry.Model:GetFullName(), UID = Entry.UID, Relation = Entry.Relation, Source = Entry.RelationSource, BaseRelation = Entry.BaseRelation,
                Surrendered = Entry.bSurrendered == true, HostileOrigin = Entry.bWasEnemyNPC == true, Attributes = Attributes})
        end
        local Report = HttpService:JSONEncode({Version = VERSION, PlaceId = game.PlaceId,
            PlaceVersion = game.PlaceVersion, Hook = State.HookStatus, Aim = State.AimStatus, Rendered = State.Rendered,
            ShotSeen = State.ShotSeen, LocalShotSeen = State.LocalShotSeen, Redirected = State.Redirected,
            Error = State.LastError, Renderer = State.VisualStatus, Backend = "Rbx native GUI",
            VisualReady = State.VisualReady, VisualIssues = State.VisualIssues,
            OpenWorld = State.bOpenWorld, FoliageDeleted = State.FoliageRemoved,
            Pickup = State.PickupStatus, PickupBusy = State.ActivePickup ~= nil, PickupDetails = State.LastPickupInfo,
            PickupCharacter = State.PickupCharacterStatus, PickupRoot = State.PickupCharacterSource, PickupListPending = State.PickupListPending,
            VisualFailures = State.VisualFailures, VisualCandidates = #State.DrawList,
            ESPEnabled = {Enemy = Config.bEnemyESP, Surrendered = Config.bSurrenderedESP, Friendly = Config.bFriendlyESP,
                Unknown = Config.bUnknownESP, Items = Config.bItemESP, Highlight = Config.bHighlight, Fill = Config.bHighlightFill,
                OutlineTransparency = Config.HighlightOutlineTransparency, FillTransparency = Config.HighlightFillTransparency, Tracers = Config.bTracers},
            RenderMilliseconds = State.Perf.RenderMs,
            NativeInstancesCreated = State.Perf.Created, SurrenderTransitions = State.SurrenderTransitions, LastTransition = State.LastTransition, Actors = Actors})
        if type(setclipboard) == "function" then setclipboard(Report); _Notify("已複製診斷", "包含繪圖相容性、角色辨識與射擊狀態。")
        else print("[OW diagnostics] " .. Report); _Notify("診斷已輸出", "執行器沒有剪貼簿 API，請查看主控台。") end
    end})
    local CursorSection = Settings:CreateSection({Name = "介面游標", Side = "right"})
    if type(Window.CreateCursorSettings) == "function" then Window:CreateCursorSettings(CursorSection) end
    Actions:CreateButton({Name = "卸載並清理", Callback = function() State:Destroy() end})
    Window:LoadConfiguration(true)
    for Key, Control in pairs(State.Controls) do Config[Key] = Control:Get() end
    Config.bRage = false
    State.Controls.bRage:Set(false, true)
    -- Reset the old version's default pause, which otherwise looks like a broken lock.
    Config.bPauseUI = false
    State.Controls.bPauseUI:Set(false, true)
    if Config.MaxActors == 100 then Config.MaxActors = 60; State.Controls.MaxActors:Set(60, true) end
    if Config.MaxItems == 60 then Config.MaxItems = 30; State.Controls.MaxItems:Set(30, true) end
    _Connect(Window.ScreenGui.Destroying, function() State:Destroy() end)
end

_RefreshStatus = function()
    local Enemy, Surrendered, Friendly, Unknown, Items = 0, 0, 0, 0, 0
    for _, Entry in pairs(State.Actors) do
        if Entry.bAlive and Entry.Relation == "Enemy" then Enemy += 1
        elseif Entry.bAlive and Entry.Relation == "SurrenderedEnemy" then Surrendered += 1
        elseif Entry.bAlive and Entry.Relation == "Friendly" then Friendly += 1
        elseif Entry.Relation == "Unknown" then Unknown += 1 end
    end
    for _ in pairs(State.Items) do Items += 1 end
    Status:Set(State.HookStatus)
    ActorStatus:Set(string.format("敵 %d / 投降 %d / 友 %d / 未知 %d / 已繪製 %d", Enemy, Surrendered, Friendly, Unknown, State.Rendered))
    ShotStatus:Set(string.format("射擊 %d / 自己 %d / 修正 %d", State.ShotSeen, State.LocalShotSeen, State.Redirected))
    PerformanceStatus:Set(string.format("原生 GUI / 物件 %d / 更新 %.2f ms", State.Perf.Created, State.Perf.RenderMs))
    EnvironmentStatus:Set(string.format("已刪除 %d 個零件；%s", State.FoliageRemoved, State.EnvironmentStatus))
    ErrorStatus:Set("最近狀態", string.format("%s\n%s\n鎖定狀態：%s\n分類變化：%s\n最近錯誤：%s", State.ScanStatus, State.VisualStatus, State.AimStatus, State.LastTransition, State.LastError))
end

local bInitOK, InitError = xpcall(function()
    _BuildUI()
    _InitOverlay()
    _Connect(workspace.DescendantAdded, _QueueObject)
    _Connect(UserInputService.WindowFocusReleased, function() State.bFocused = false end)
    _Connect(UserInputService.WindowFocused, function() State.bFocused = true end)
    _Connect(Players.PlayerAdded, function(Player)
        _Connect(Player.CharacterAdded, function(Character)
            State.PlayerByCharacter[Character] = Player
            _RefreshPlayerMap(); State.Pending[Character] = os.clock() + 3
        end)
    end)
    for _, Player in ipairs(Players:GetPlayers()) do
        _Connect(Player.CharacterAdded, function(Character)
            State.PlayerByCharacter[Character] = Player
            _RefreshPlayerMap(); State.Pending[Character] = os.clock() + 3
        end)
        if Player.Character then State.Pending[Player.Character] = os.clock() + 3 end
    end
    for _, Tag in ipairs(ITEM_TAGS) do
        _Connect(CollectionService:GetInstanceAddedSignal(Tag), function(Object) _TryItem(Object, true) end)
    end
    _Connect(CollectionService:GetInstanceAddedSignal("Prefab"), function(Object)
        if ITEM_PREFABS[Object:GetAttribute("Prefab")] then _TryItem(Object, true) end
    end)
    local LastESP, LastTarget, LastStatus, LastItems, LastPlayers, LastRegistry, LastPending, LastPickupUI = 0, 0, 0, 0, 0, 0, 0, 0
    _Connect(RunService.Heartbeat, function()
        if not State.bAlive then return end
        local Time = os.clock()
        local Pickup = State.ActivePickup
        if Pickup and Time >= Pickup.Deadline then _FinishPickup(Pickup, "取得逾時，結果尚未確認；請檢查背包") end
        if Time - LastPending >= 0.1 then
            LastPending = Time
            local Count = 0
            for Model, Expiry in pairs(State.Pending) do
                if Model and Model.Parent then _TryActor(Model); _TryItem(Model) end
                if not Model or not Model.Parent or State.Actors[Model] or State.Items[Model] or Time >= Expiry then State.Pending[Model] = nil end
                Count += 1
                if Count >= 32 then break end
            end
        end
        if State.ItemCatalogScan and not State.bScanning then
            State.ItemCatalogScan = false; _ScanWorkspace()
        end
        _UpdateActorClasses()
        if Time - LastTarget >= Config.TargetInterval then LastTarget = Time; State.Target = _SelectTarget() end
        if State.VisualMembershipDirty or Time - LastESP >= Config.ESPInterval then
            LastESP = Time
            State.VisualMembershipDirty = false
            local bOK, Message = pcall(_RefreshVisuals)
            table.clear(State.Dirty)
            if not bOK then State.LastError = "透視：" .. tostring(Message) end
        end
        if Time - LastPickupUI >= 1 then LastPickupUI = Time; _RefreshPickupList() end
        if Time - LastStatus >= 1 then LastStatus = Time; _RefreshStatus() end
        if Time - LastItems >= 3 then
            LastItems = Time; _ItemTags(); _RefreshRuntimeSettings()
            for Object in pairs(State.ItemCandidates) do if Object.Parent then _TryItem(Object, true) else State.ItemCandidates[Object] = nil end end
        end
        if Time - LastPlayers >= 0.5 then LastPlayers = Time; _RefreshPlayerMap() end
        if Time - LastRegistry >= 2 then LastRegistry = Time; _RefreshCachedRegistries() end
    end)
    local Priority = Enum.RenderPriority.Last.Value + 1
    RunService:BindToRenderStep(State.RenderName, Priority, function()
        local bOK, Message = pcall(function()
            if _ActiveCombat() then
                if _ValidEnemy(State.Target) then
                    local Camera = workspace.CurrentCamera
                    if Camera then
                        local Position = _PredictPosition(Camera.CFrame.Position, _AimPart(State.Target), State.ShotVelocity or Config.FallbackVelocity)
                        if (Position - Camera.CFrame.Position).Magnitude > 0.1 then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, Position) end
                    end
                elseif State.Target then State.Target = nil end
            end
        end)
        if not bOK then State.LastError = "瞄準：" .. tostring(Message) end
    end)
    -- Same lifecycle as the attached Isle implementation: list discovery is separate
    -- from a render event that reads the current camera and current part positions.
    _Connect(RunService.RenderStepped, function()
        if not State.bAlive then return end
        local bOK, Message = pcall(_DrawVisuals)
        if not bOK then State.LastError = "畫面繪製：" .. tostring(Message) end
    end)
    _RefreshPlayerMap(); _RefreshRuntimeSettings(); _ScanWorkspace(); _RefreshModules(); _ScanRuntime(); _ItemTags(); _RefreshPickupList()
    _Notify("OW Sawang 已載入", "原生 GUI 透視已啟用，UI 位於 CoreGui；草木使用按鈕刪除，射擊維持手動。")
end, debug.traceback)
if not bInitOK then State:Destroy(); error("[OW] 初始化失敗：" .. tostring(InitError), 0) end

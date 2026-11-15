-- Rbx Delta Executor
-- Daylight + FullBright + No Fog + Clear Sky

local Lighting = game:GetService("Lighting")
local Terrain = workspace.Terrain

local env = getgenv()

-- 停止舊版腳本
if env.BalancedDaylight then
    env.BalancedDaylight.Enabled = false
end

local Settings = {
    ClockTime = 14,
    Brightness = 2,
    ExposureCompensation = 0,
    Ambient = Color3.fromRGB(170, 170, 170),
    OutdoorAmbient = Color3.fromRGB(190, 190, 190),
    ColorShift_Top = Color3.fromRGB(0, 0, 0),
    ColorShift_Bottom = Color3.fromRGB(0, 0, 0),
    GlobalShadows = false,
    FogStart = 0,
    FogEnd = 1000000
}

local State = {
    Enabled = true,
    OriginalSkies = {},
    OriginalEffects = {},
    OriginalClouds = {},
    DaySky = nil
}

env.BalancedDaylight = State

-- 保留原本天空，以便停止後還原
for _, obj in ipairs(Lighting:GetChildren()) do
    if obj:IsA("Sky") then
        table.insert(State.OriginalSkies, obj)
        obj.Parent = nil
    end
end

-- 使用 Rbx 預設天空
local DaySky = Instance.new("Sky")
DaySky.Name = "BalancedDaylightSky"
DaySky.Parent = Lighting

State.DaySky = DaySky

local function SetProperty(object, property, value)
    pcall(function()
        object[property] = value
    end)
end

local function ApplyLighting()
    -- 固定白天
    for property, value in pairs(Settings) do
        SetProperty(Lighting, property, value)
    end

    SetProperty(Lighting, "TimeOfDay", "14:00:00")

    -- 移除霧氣及夜間後製濾鏡
    for _, obj in ipairs(Lighting:GetChildren()) do
        if obj:IsA("Atmosphere") then
            SetProperty(obj, "Density", 0)
            SetProperty(obj, "Haze", 0)
            SetProperty(obj, "Glare", 0)

        elseif obj:IsA("ColorCorrectionEffect")
            or obj:IsA("BloomEffect")
            or obj:IsA("BlurEffect")
            or obj:IsA("DepthOfFieldEffect") then

            SetProperty(obj, "Enabled", false)

        elseif obj:IsA("Sky") and obj ~= DaySky then
            if not table.find(State.OriginalSkies, obj) then
                table.insert(State.OriginalSkies, obj)
            end
            obj.Parent = nil
        end
    end

    -- 移除動態雲層
    for _, obj in ipairs(Terrain:GetChildren()) do
        if obj:IsA("Clouds") then
            SetProperty(obj, "Cover", 0)
            SetProperty(obj, "Density", 0)
        end
    end

    -- 確保白天天空存在
    if DaySky.Parent ~= Lighting then
        DaySky.Parent = Lighting
    end
end

-- 立即套用
ApplyLighting()

-- 持續維持白天
task.spawn(function()
    while State.Enabled do
        ApplyLighting()
        task.wait(0.5)
    end
end)

print("[Daylight] Daytime + FullBright + No Fog enabled")

-- 等待遊戲加載完畢
if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local env = (getgenv and getgenv()) or _G
local TAG = "[AntiAfk]"

-- 防止重複載入
if env.AntiAFKConnection then
    env.AntiAFKConnection:Disconnect()
end

env.AntiAFKConnection = Players.LocalPlayer.Idled:Connect(function()
    local Success, Err = pcall(function()
        VirtualUser:ClickButton2(
            Vector2.new(0, 0),
            workspace.CurrentCamera and workspace.CurrentCamera.CFrame or CFrame.new()
        )
    end)

    if not Success then
        warn(`{TAG} 執行失敗: `, Err)
    end
end)

print(`{TAG} 已載入完畢`)
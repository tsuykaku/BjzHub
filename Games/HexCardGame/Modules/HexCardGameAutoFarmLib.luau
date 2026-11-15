getgenv().myTurn = false

local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local systeminfo = "〈自動刷怪〉 "

local lib = {}


local function getEntityPosition(): table
    local posTable = {}

    local NPCs = game:GetService("Workspace").NPCBin:GetChildren()
    local FXBin = game:GetService("Workspace").FXBin

    for i,npc in ipairs(NPCs) do
        local rootPart = npc.PrimaryPart
    
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Exclude
        raycastParams.FilterDescendantsInstances = {npc, FXBin} -- 過濾NPC本身、FXBin
    
        local raycastResult = workspace:Raycast(rootPart.CFrame.Position, rootPart.CFrame.UpVector * -50, raycastParams)
        if raycastResult then
            local pos = raycastResult.Instance.Name:gsub("[^()%-%d,]", "")
            local q = string.match(pos, "(%-?%d+),")
            local r = string.match(pos, ",(%-?%d+)")
            posTable[npc.Name] = {
                ["q"] = tonumber(q),
                ["r"] = tonumber(r),
            }
            
        end
    end

    for i,player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player.Name == localPlayer.Name then
            local localCharacter = player.Character or player.CharacterAdded:Wait()
            local rootPart = localCharacter.PrimaryPart
    
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {localCharacter, FXBin} -- 過濾player本身、FXBin
        
            local raycastResult = workspace:Raycast(rootPart.CFrame.Position, rootPart.CFrame.UpVector * -50, raycastParams)
            if raycastResult then
                local pos = raycastResult.Instance.Name:gsub("[^()%-%d,]", "")
                local q = string.match(pos, "(%-?%d+),")
                local r = string.match(pos, ",(%-?%d+)")
                posTable[localPlayer.Name] = {
                    ["q"] = tonumber(q),
                    ["r"] = tonumber(r),
                }
            end
        else
            local otherPlayerCharacter = game:GetService("Workspace").SpoofBin[player.Name]

            local rootPart = otherPlayerCharacter.PrimaryPart
    
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            raycastParams.FilterDescendantsInstances = {otherPlayerCharacter, FXBin} -- 過濾player本身、FXBin
        
            local raycastResult = workspace:Raycast(rootPart.CFrame.Position, rootPart.CFrame.UpVector * -50, raycastParams)
            if raycastResult then
                local pos = raycastResult.Instance.Name:gsub("[^()%-%d,]", "")
                local q = string.match(pos, "(%-?%d+),")
                local r = string.match(pos, ",(%-?%d+)")
                posTable[otherPlayerCharacter.Name] = {
                    ["q"] = tonumber(q),
                    ["r"] = tonumber(r),
                }
            end
        end
    end
    return posTable
end

function lib:getPosition(playerName)
    if playerName == nil then
        return getEntityPosition()
    else
        return getEntityPosition()[playerName]
    end
end

function lib:pass()
    if getgenv().battleEnded then
        print(systeminfo .. "pass ：戰鬥已結束")
    else
        print(systeminfo .. "回合：" .. getgenv().round .. "，嘗試跳過回合")
        local v1 = "CombatActionSubmitted"
        local v2 = {
            ["ActionType"] = 1, 
            ["combatantId"] = 0, 
            ["SharedKeys"] = {
                [1] = "ActionType", 
                [2] = "target", 
                [3] = "card"
            }
        }
        local event = localPlayer.Socket.Function
    
        event:InvokeServer(v1, v2)
    
        if localPlayer.PlayerGui:FindFirstChild("ActionSelect") then
            localPlayer.PlayerGui:FindFirstChild("ActionSelect").Enabled = false
        end
    
        print(systeminfo .. "回合：" .. getgenv().round .. "，已跳過回合")
    end
end

function lib:move(q, r)
    local v1 = "CombatActionSubmitted"
    local v2 = {
        ["target"] = {
            ["q"] = q, 
            ["r"] = r
        }, 
        ["ActionType"] = 2, 
        ["combatantId"] = 0, 
        ["SharedKeys"] = {
            [1] = "ActionType", 
            [2] = "target", 
            [3] = "card"
        }
    }
    local event = localPlayer.Socket.Function

    event:InvokeServer(v1, v2)
end

function lib:waitForMyTurn()
    if getgenv().battleEnded then
        print(systeminfo .. "waitForMyTurn ：戰鬥已結束")
    else
        print(systeminfo .. "回合：" .. getgenv().round .. "，正在等待自己的回合...")

        getgenv().myTurn = false
    
        repeat
            task.wait(1.5)
            if not self:bossAlive("Gonaku") then
                print("嘗試跳出迴圈")
                break
            end

            if localPlayer.PlayerGui:FindFirstChild("ActionSelect") then
                getgenv().myTurn = true
            else
                getgenv().myTurn = false
            end
            
        until getgenv().myTurn == true
    
        print(systeminfo .. "回合：" .. getgenv().round .. "，是自己的回合！")
    end
end

function lib:waitForTurnEnd()
    if getgenv().battleEnded then
        getgenv().battleEnded = false
        print(systeminfo .. "waitForTurnEnd ：戰鬥已結束")
    else
        repeat
            task.wait(0.5)
        until localPlayer.PlayerGui:FindFirstChild("ActionSelect") == nil
    
        print(systeminfo .. "回合：" .. getgenv().round .."，等待自己的回合結束...")
    end
end

function lib:waitForBattleStart()
    local inBattle = false

    repeat
        print(systeminfo .. "等待戰鬥開始...")
        for _, child in ipairs(localPlayer.PlayerGui:GetChildren()) do
            if child.Name == "CombatInfoTag" and child:IsA("BillboardGui") and child:FindFirstChild("NameLabel").Text == localPlayer.Name then

                inBattle = true

            end
        end
        task.wait(1)
    until inBattle == true
    print(systeminfo .. "戰鬥開始！")
    -- print(systeminfo .. "等待戰鬥開始...")
    -- repeat
    --     fxbin = next(game:GetService("Workspace").FXBin:GetChildren())
    --     task.wait(0.5)
    -- until fxbin ~= nil

    -- print(systeminfo .. "戰鬥開始！")
end

function lib:waitForBattleEnd()
    if getgenv().battleEnded then
        getgenv().battleEnded = false
        print(systeminfo .. "waitForBattleEnd ：戰鬥已結束")
    end

    local fxbin
    print(systeminfo .. "等待戰鬥結束...")
    repeat
        fxbin = next(game:GetService("Workspace").FXBin:GetChildren())
        task.wait(0.5)
    until fxbin == nil

    print(systeminfo .. "戰鬥結束！")
end


function lib:zombieBossDash()
    local v1 = "CombatActionSubmitted"
    local v2 = {
        ["card"] = "Dash", 
        ["target"] = {
            ["q"] = 0, 
            ["r"] = 0
        }, 
        ["ActionType"] = 3, 
        ["combatantId"] = 0, 
        ["SharedKeys"] = {
            [1] = "ActionType", 
            [2] = "target", 
            [3] = "card"
        }
    }
    local event = localPlayer.Socket.Function

    event:InvokeServer(v1, v2)
end

function lib:zombieBossMove()
    local v1 = "CombatActionSubmitted"
    local v2 = {
        ["target"] = {
            ["q"] = 0, 
            ["r"] = -2
        }, 
        ["ActionType"] = 2, 
        ["combatantId"] = 0, 
        ["SharedKeys"] = {
            [1] = "ActionType", 
            [2] = "target", 
            [3] = "card"
        }
    }
    local event = localPlayer.Socket.Function

    event:InvokeServer(v1, v2)
end

function lib:weakZombieDash()
    local v1 = "CombatActionSubmitted"
    local v2 = {
        ["card"] = "Dash", 
        ["target"] = {
            ["q"] = -33, 
            ["r"] = 16
        }, 
        ["ActionType"] = 3, 
        ["combatantId"] = 0, 
        ["SharedKeys"] = {
            [1] = "ActionType", 
            [2] = "target", 
            [3] = "card"
        }
    }
    local event = localPlayer.Socket.Function

    event:InvokeServer(v1, v2)
end

function lib:weakZombieMove()
    local v1 = "CombatActionSubmitted"
    local v2 = {
        ["target"] = {
            ["q"] = -33, 
            ["r"] = 14
        }, 
        ["ActionType"] = 2, 
        ["combatantId"] = 0, 
        ["SharedKeys"] = {
            [1] = "ActionType", 
            [2] = "target", 
            [3] = "card"
        }
    }
    local event = localPlayer.Socket.Function

    event:InvokeServer(v1, v2)
end

function lib:checkCards(): table -- 陣列
    local cards = {}

    local cardFolder = localPlayer.PlayerGui.ActionSelect.Container.ContainerCards.Bin

    for i,card in ipairs(cardFolder:GetChildren()) do
        if card:IsA("ImageLabel") then
            local cardName = card.Header.CardName.Text
            table.insert(cards, cardName)
        end
    end
    
    return cards
end

-- 卡片函式

--[[
    -- [target]

    "Guided Strike"
    "Defense Debuff" 
    "Scimitar" 

    -- [self]
    
    "Shadow Trade"
    "Tremor"
]]

function lib:useCard(cardName: string, target: string)
    if getgenv().battleEnded then
        print(systeminfo .. "useCard ：戰鬥已結束")
    else
        local v1 = "CombatActionSubmitted"
        local v2 = {
            ["card"] = cardName,
            ["target"] = {
                ["q"] = getEntityPosition()[target]["q"],
                ["r"] = getEntityPosition()[target]["r"]
            },
            ["ActionType"] = 3,
            ["combatantId"] = 0,
            ["SharedKeys"] = {
                [1] = "ActionType",
                [2] = "target",
                [3] = "card"
            }
        }
        local event = localPlayer.Socket.Function
        event:InvokeServer(v1, v2)
        
        print(string.format("%s使用卡片：%s，使用對象：%s，位置：q = %d，r = %d", systeminfo, v2["card"], target, v2["target"]["q"], v2["target"]["r"]))
        -- print(target, v2["target"]["q"], v2["target"]["r"])
    end
end


function lib:dash(q, r)
    if getgenv().battleEnded then
        print(systeminfo .. "useCard ：戰鬥已結束")
    else
        local v1 = "CombatActionSubmitted"
        local v2 = {
            ["card"] = "Dash",
            ["target"] = {
                ["q"] = q,
                ["r"] = r
            },
            ["ActionType"] = 3,
            ["combatantId"] = 0,
            ["SharedKeys"] = {
                [1] = "ActionType",
                [2] = "target",
                [3] = "card"
            }
        }
        local event = localPlayer.Socket.Function

        event:InvokeServer(v1, v2)
        
        print(string.format("%s使用卡片：%s，位置：q = %d，r = %d", systeminfo, v2["card"], v2["target"]["q"], v2["target"]["r"]))
        -- print(target, v2["target"]["q"], v2["target"]["r"])
    end
end

function lib:bossAlive(bossName): boolean
    for _,child in ipairs(localPlayer.PlayerGui:GetChildren()) do
        if child.Name == "CombatInfoTag" and child:IsA("BillboardGui") and child:FindFirstChild("NameLabel").Text == bossName then
            local debounce = false

            local bossAlive

            local healthText = child.Health.Counter.Label
            if tonumber(healthText.Text) <= 0 then
                if not debounce then
                    debounce = not debounce
                    getgenv().battleEnded = true
                    getgenv().myTurn = true
                    print(string.format("%s%s 死了！", systeminfo, bossName))
                    bossAlive = false
                    task.wait(3)
                    debounce = not debounce
                end
            else
                bossAlive = true
                print(string.format("%s%s 沒死。", systeminfo, bossName))
            end

            return bossAlive
        end
    end
end

return lib

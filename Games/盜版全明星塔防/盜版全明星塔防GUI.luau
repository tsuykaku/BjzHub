--[[

  \\\\\\\\\\      盜版全明星塔防GUI      //////////
   \\\\\\\\\\     盜版全明星塔防GUI     //////////
    \\\\\\\\\\    盜版全明星塔防GUI    //////////
     \\\\\\\\\\   盜版全明星塔防GUI   //////////
      \\\\\\\\\\  盜版全明星塔防GUI  //////////
       \\\\\\\\\\ 盜版全明星塔防GUI //////////
        \\\\\\\\\\盜版全明星塔防GUI//////////
        //////////盜版全明星塔防GUI\\\\\\\\\\
       ////////// 盜版全明星塔防GUI \\\\\\\\\\
      //////////  盜版全明星塔防GUI  \\\\\\\\\\
     //////////   盜版全明星塔防GUI   \\\\\\\\\\
    //////////    盜版全明星塔防GUI    \\\\\\\\\\
   //////////     盜版全明星塔防GUI     \\\\\\\\\\
  //////////      盜版全明星塔防GUI      \\\\\\\\\\

]]
repeat wait() until game:IsLoaded() and game.Players and game.Players.LocalPlayer and game.Players.LocalPlayer.Character or (game.placeId == 10098525303 and game:IsLoaded())
if game.GameId ~= 3183403065 then return end


getgenv().Settings = {
    votestart = false,
    autoupgrade = false,
    backtolobby = false,
    ClaimQuest = false,
    antiAFK = false,
    tptoAFK = false,
    ClaimDailyReward = false,
    DeletePlaceHitbox = false,
    Record = false,
    Playback = false,
    AutoToNamek = false,
    DiscordAlert = false,
    BoostFPS = false,
    WindowFocus = false,
    TPLevel = false,
    SmallWindow = false,
    unit1 = {"UnitName","uuid"},
    unit2 = {"UnitName","uuid"},
    unit3 = {"UnitName","uuid"},
    unit4 = {"UnitName","uuid"},
    unit5 = {"UnitName","uuid"},
    unit6 = {"UnitName","uuid"},
    SelectedRecordFile = "選擇錄製檔",
    SelectedLevel = "",
    SellUnitWave = 250,
    TotalGem = 0,
    TotalGold = 0,
    TotalXP = 0,

}

--[變數]--[變數]--[變數]--[變數]--[變數]--[變數]--[變數]--

--[服務]：
local players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--[簡寫]：
local guiName = "盜版全明星塔防GUI v0.24"
local settingdata = "houkei_gui/FakeAllStar.json"
local localplayer = players.LocalPlayer
local PlayerGui = localplayer.PlayerGui
local client_to_server = ReplicatedStorage.endpoints["client_to_server"]
--[空變數]：
local OldSettings
local uuid
local UnitName
local RecordFileName
--[布林值]：
local FirstDiscordAlert = true
--[空陣列]：
local RecordFile = {}


--[陣列]：
local levelListCN = {
    "那美克第一關",
    "那美克第二關",
    "那美克第三關",
    "那美克第四關",
    "那美克第五關",
    "那美克第六關",
    "那美克「無限」",

    "進擊的巨人第一關",
    "進擊的巨人第二關",
    "進擊的巨人第三關",
    "進擊的巨人第四關",
    "進擊的巨人第五關",
    "進擊的巨人第六關",
    "進擊的巨人「無限」",

    "鬼滅之刃第一關",
    "鬼滅之刃第二關",
    "鬼滅之刃第三關",
    "鬼滅之刃第四關",
    "鬼滅之刃第五關",
    "鬼滅之刃第六關",
    "鬼滅之刃「無限」",

    "火影忍者第一關",
    "火影忍者第二關",
    "火影忍者第三關",
    "火影忍者第四關",
    "火影忍者第五關",
    "火影忍者第六關",
    "火影忍者「無限」",

    "海賊王第一關",
    "海賊王第二關",
    "海賊王第三關",
    "海賊王第四關",
    "海賊王第五關",
    "海賊王第六關",
    "海賊王「無限」",

    "東京喰種第一關",
    "東京喰種第二關",
    "東京喰種第三關",
    "東京喰種第四關",
    "東京喰種第五關",
    "東京喰種第六關",
    "東京喰種「無限」",

    "死神第一關",
    "死神第二關",
    "死神第三關",
    "死神第四關",
    "死神第五關",
    "死神第六關",
    "死神「無限」",
}

local levelList = {
    "namek_level_1",
    "namek_level_2",
    "namek_level_3",
    "namek_level_4",
    "namek_level_5",
    "namek_level_6",
    "namek_infinite",

    "aot_level_1",
    "aot_level_2",
    "aot_level_3",
    "aot_level_4",
    "aot_level_5",
    "aot_level_6",
    "aot_infinite",

    "demonslayer_level_1",
    "demonslayer_level_2",
    "demonslayer_level_3",
    "demonslayer_level_4",
    "demonslayer_level_5",
    "demonslayer_level_6",
    "demonslayer_infinite",

    "naruto_level_1",
    "naruto_level_2",
    "naruto_level_3",
    "naruto_level_4",
    "naruto_level_5",
    "naruto_level_6",
    "naruto_infinite",

    "marineford_level_1",
    "marineford_level_2",
    "marineford_level_3",
    "marineford_level_4",
    "marineford_level_5",
    "marineford_level_6",
    "marineford_infinite",

    "tokyoghoul_level_1",
    "tokyoghoul_level_2",
    "tokyoghoul_level_3",
    "tokyoghoul_level_4",
    "tokyoghoul_level_5",
    "tokyoghoul_level_6",
    "tokyoghoul_infinite",

    "hueco_level_1",
    "hueco_level_2",
    "hueco_level_3",
    "hueco_level_4",
    "hueco_level_5",
    "hueco_level_6",
    "hueco_infinite",

}
--[變數]--[變數]--[變數]--[變數]--[變數]--[變數]--[變數]--


function CheckData(DataName)
    if OldSettings[DataName] == nil then
        print(DataName .. "值:缺失")
        OldSettings[DataName] = getgenv().Settings[DataName]
        print(DataName .. "值:已補上")
    else
        print(DataName .. "值:存在")
    end
end


print("[檢查「盜版全明星塔防GUI」設定檔完整性...]")

--[檢查資料夾
if isfolder("houkei_gui") then--有houkei資料夾
    print("houkei資料夾:存在")
else
    makefolder("houkei_gui")
end

if isfolder("houkei_gui/錄製檔") then
    print("錄製檔資料夾:存在")
else
    makefolder("houkei_gui/錄製檔")
end
--檢查資料夾]


if isfile(settingdata) then--有FakeAllStar.json
    print("FakeAllStar.json:存在")
    --[導入OldSettings
    OldSettings = HttpService:JSONDecode(readfile(settingdata))
    --導入OldSettings]
    --[檢查FakeAllStar.json完整性
    CheckData("votestart")

    CheckData("autoupgrade")

    CheckData("backtolobby")

    CheckData("ClaimQuest")

    CheckData("antiAFK")

    CheckData("tptoAFK")

    CheckData("ClaimDailyReward")

    CheckData("unit1")

    CheckData("unit2")

    CheckData("unit3")

    CheckData("unit4")

    CheckData("unit5")

    CheckData("unit6")

    CheckData("DeletePlaceHitbox")

    CheckData("Record")

    CheckData("Playback")

    CheckData("SelectedRecordFile")

    CheckData("AutoToNamek")

    CheckData("SellUnitWave")

    CheckData("TotalGem")

    CheckData("TotalGold")

    CheckData("TotalXP")

    CheckData("DiscordAlert")

    CheckData("BoostFPS")

    CheckData("WindowFocus")

    CheckData("SelectedLevel")

    CheckData("TPLevel")

    CheckData("SmallWindow")

    --檢查FakeAllStar.json完整性]
    --[導入OldSettings到getgenv().Settings
    getgenv().Settings = OldSettings
    print("設定檔導入成功！")
    print("[檢查「盜版全明星塔防GUI」設定檔完整性:完成]")
    --導入OldSettings到getgenv().Settings]
else
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
end

getgenv().RecordFileList = listfiles("houkei_gui/錄製檔")


spawn(function()
    while wait(1.5) do
        getgenv().RecordFileList = listfiles("houkei_gui/錄製檔")
    end
end)

--[檢查完檔案後才能跑 GUI library
local library = loadstring(game:HttpGet(("https://raw.githubusercontent.com/kakuun333/Exploit_Scripts/main/%E5%8C%85%E8%8E%96%E6%BE%A4GUI/GUI-Library/%E5%8C%85%E8%8E%96%E6%BE%A4GUI-Library.lua")))()
--檢查完檔案後才能跑 GUI library]

--------------------------------------[函數

function stringtocframe(str)
    return CFrame.new(table.unpack(str:gsub(" ",""):split(",")))
end

function votestart()
    if game.placeId == 10098525303 then return end
    repeat wait() until game:GetService("Workspace"):FindFirstChild("_DATA")
    while getgenv().Settings.votestart do
        if game:GetService("Workspace")["_DATA"].VoteStart.VotingFinished.Value == false then
            client_to_server["vote_start"]:InvokeServer()
        end
        wait()
    end
end

function autoupgrade()
    if getgenv().Settings.autoupgrade then
        if game.placeId == 10098525303 then return end
        local messages = PlayerGui.MessageGui.messages
        messages.UIListLayout.SortOrder = Enum.SortOrder.Name
        messages.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        messages.ChildAdded:Connect(function(child)
            if child:IsA("Frame") and child.Name == "Error" and child:WaitForChild("Tex").Text == "Not enough money!" then
                child.Tex.Text = ""
                repeat wait() until child.UIScale
                child:Destroy()
            end
        end)
    end
    while getgenv().Settings.autoupgrade do
        for i,v in next, game:GetService("Workspace")["_UNITS"]:GetDescendants() do
            if v:IsA("ObjectValue") and v.Name == "player" then
                if v.Value == localplayer then
                    local unit = v.Parent.Parent
                    local Target = client_to_server["upgrade_unit_ingame"]
                    Target:InvokeServer(unit)
                end
            end
        end
        wait()
    end
end

function backtolobby()
    if game.placeId == 10098525303 then return end
    repeat wait(0.5) until PlayerGui.ResultsUI.Enabled == true
    if getgenv().Settings.backtolobby == true then
        while getgenv().Settings.backtolobby do
            wait(1)
            client_to_server["teleport_back_to_lobby"]:InvokeServer()
        end
    end
end

function ClaimQuest()
    if game.placeId == 10098525303 then return end
    local questcontent = PlayerGui.QuestsUI.Main.Main.Main.Content
    local function claim(v)
        local questname = v.Name
        client_to_server["redeem_quest"]:InvokeServer(questname)
    end

    while getgenv().Settings.ClaimQuest do

        for i,v in next, questcontent.event.Scroll:GetChildren() do
            if v and v:IsA("Frame") and v.Name ~= "Empty" and v:WaitForChild("ClaimQuest").Visible == true then
                claim(v)
            end
        end
        
        for i,v in next, questcontent.daily.Scroll:GetChildren() do
            if v and v:IsA("Frame") and v.Name ~= "Empty" and v:WaitForChild("ClaimQuest").Visible == true then
                claim(v)
            end
        end
        
        for i,v in next, questcontent.story.Scroll:GetChildren() do
            if v and v:IsA("Frame") and v.Name ~= "Empty" and v:WaitForChild("ClaimQuest").Visible == true then
                claim(v)
            end
        end
        
        wait(5)
    end
end

function ClaimDailyReward()
    repeat
        client_to_server["claim_daily_reward"]:InvokeServer()--領每日獎勵
        wait(5)
    until PlayerGui.DailyRewards.Enabled == false
end

function code()
    local codes = {
    "GHOUL",
    "FIRSTRAIDS",
    "DATAFIX",
    "MARINEFORD",
    "TWOMILLION",
    "subtomaokuma",
    "SORRYFORSHUTDOWN",
    "TWOMILLION",
    "CHALLENGEFIXin",
    "GINYUFIX",
    "RELEASE",
    "SubToKelvingts",
    "SubToBlamspot",
    "KingLuffy",
    "TOADBOIGAMING",
    "noclypso",
    "FictioNTheFirst",
    "Cursed",
    "MUGENTRAIN",
    "HOLLOW",
    }
    for count = 1,#codes do
        local arg = codes[count]
        local Target = client_to_server["redeem_code"]
        Target:InvokeServer(arg)
    end
end



function antiAFK()
    repeat wait() until game:IsLoaded()
    spawn(function()
        while wait(60) do
            game:GetService("VirtualUser"):ClickButton2(Vector2.new())
        end
    end)
    print("反AFK測試腳本已載入")
end

function tptoAFK()
    if game.placeId == 8304191830 then
        repeat wait() until client_to_server["teleport_to_time_machine"]
        while getgenv().Settings.tptoAFK do
            client_to_server["teleport_to_time_machine"]:InvokeServer()
            wait(5)
        end
    end
end

function unitsList()
    local list = {}
    for i,v in next, PlayerGui.collection.grid.List.Outer.UnitFrames:GetChildren() do
        if v:IsA("ImageButton") then
            table.insert(list,v.Name)
        end
    end
    return list
end

function GetOptionUnitsName()
    if game.placeId == 8304191830 then
        for i,v in next, PlayerGui.collection.grid.List.Outer.UnitFrames:GetChildren() do
            if v:IsA("ImageButton") then
                uuid = v:FindFirstChild("_uuid")
                if uuid and uuid:IsA("StringValue") and v.Equipped.Visible == true then
                    UnitName = v.name.Text
                    v.Name = UnitName .. ":" .. uuid.Value
                end
            end
        end
    end
end
GetOptionUnitsName()

function DeletePlaceHitbox()
    while getgenv().Settings.DeletePlaceHitbox do
        for i,v in next, game:GetService("Workspace")["_UNITS"]:GetChildren() do
            if v:FindFirstChild("_hitbox") then
                v["_hitbox"]:Destroy()
            end
        end
        wait(0.6)
    end
end



function CreateRecordFile()
    for i,CoreGui in next, game:GetService("CoreGui"):GetChildren() do
        if CoreGui:FindFirstChild("MainFrame") then
            for i,ScrollingFrame in next, CoreGui.MainFrame.ScrollingFrameFolder:GetChildren() do
                if ScrollingFrame:FindFirstChild("TextBoxFrame") then
                    RecordFile[ScrollingFrame.TextBoxFrame.TextBox.Text] = {}
                    RecordFileName = ScrollingFrame.TextBoxFrame.TextBox.Text
                    if RecordFileName ~= "" then
                        writefile("houkei_gui/錄製檔/" .. RecordFileName .. ".json",HttpService:JSONEncode(RecordFile))
                    end
                    RecordFile = {}
                end
            end
        end
    end
end

function Record()
    if getgenv().Settings.Record == true then
        local SelectedFile = HttpService:JSONDecode(readfile("houkei_gui/錄製檔/" .. string.sub(getgenv().Settings.SelectedRecordFile,22,-1)))
        local SelectedFileName = string.sub(getgenv().Settings.SelectedRecordFile,22,-6)
        local startTime = os.clock()
        local firstTime = true
        --[偵測放置角色
        game:GetService("Workspace")["_UNITS"].ChildAdded:Connect(function(AddedUnit)
            if AddedUnit:WaitForChild("_stats"):WaitForChild("player").Value == localplayer and AddedUnit:WaitForChild("_shadow") then
                local placeTime = os.clock() - startTime
                local unit = AddedUnit.Name
                local UUID = AddedUnit["_stats"]:WaitForChild("uuid").Value
                local CFrameValue = AddedUnit["_shadow"].CFrame

                if firstTime == true then
                    firstTime = false
                    SelectedFile[SelectedFileName] = {}
                end

                table.insert(SelectedFile[SelectedFileName],
                {
                    placeTime,
                    {
                        "Spawn",
                        {
                            Unit = unit,
                            uuid = UUID,
                            cframe = tostring(CFrameValue)
                        }
                    }
                })
                writefile("houkei_gui/錄製檔/" .. string.sub(getgenv().Settings.SelectedRecordFile,22,-1),HttpService:JSONEncode(SelectedFile))
                --[-----------------------------------------------------------------------------------------------------------------------]
                --[偵測角色升級
                local UpgradeValue = AddedUnit["_stats"]:WaitForChild("upgrade")
    
                UpgradeValue.Changed:Connect(function()
                    local UpgradeTime = os.clock() - startTime
                        
                    table.insert(SelectedFile[SelectedFileName],
                    {
                        UpgradeTime,
                        {
                            "Upgrade",
                            {
                                Name = unit,
                                Location = tostring(CFrameValue)
                            }
                        }
                    })
                    writefile("houkei_gui/錄製檔/" .. string.sub(getgenv().Settings.SelectedRecordFile,22,-1),HttpService:JSONEncode(SelectedFile))
                end)

                
                --偵測角色升級]
                --[偵測角色攻擊模式
                local PriorityValue = AddedUnit["_stats"]:WaitForChild("priority")

                PriorityValue.Changed:Connect(function()
                    local ChangePriorityTime = os.clock() - startTime
                        
                    table.insert(SelectedFile[SelectedFileName],
                    {
                        ChangePriorityTime,
                        {
                            "ChangePriority",
                            {
                                Name = unit,
                                Location = tostring(CFrameValue)
                            }
                        }
                    })
                    writefile("houkei_gui/錄製檔/" .. string.sub(getgenv().Settings.SelectedRecordFile,22,-1),HttpService:JSONEncode(SelectedFile))
                end)
                --偵測角色攻擊模式]
                --[偵測角色開技能
                local ActiveAttackValue = AddedUnit["_stats"]["active_attack"]
                local LastActiveCast = AddedUnit["_stats"]["last_active_cast"]
                if ActiveAttackValue ~= nil then
                    LastActiveCast.Changed:Connect(function()
                    local UseAbilityTime = os.clock() - startTime
                        
                    table.insert(SelectedFile[SelectedFileName],
                    {
                        UseAbilityTime,
                        {
                            "UseAbility",
                            {
                                Name = unit,
                                Location = tostring(CFrameValue)
                            }
                        }
                    })
                    writefile("houkei_gui/錄製檔/" .. string.sub(getgenv().Settings.SelectedRecordFile,22,-1),HttpService:JSONEncode(SelectedFile))
                    end)
                end
            end
        end)
        --偵測放置角色]
    end
end

function Playerback()
    if getgenv().Settings.Playerback == true then
        local SelectedFile = HttpService:JSONDecode(readfile("houkei_gui/錄製檔/" .. string.sub(getgenv().Settings.SelectedRecordFile,22,-1)))
        local SelectedFileName = string.sub(getgenv().Settings.SelectedRecordFile,22,-6)
        local GemFrame = PlayerGui["spawn_units"].Lives.Frame.Gem
        local GoldFrame = PlayerGui["spawn_units"].Lives.Frame.Gold
--[[
            !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            !!!!!!!!!!!!!!!!!!!!!!!!!!!!在for i,v 裡面就要把第一個table去掉!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            !!!!!!!!!!json檔裡的cframe是「字串」要使用 stringtocframe(字串cframe) 轉換為cframe!!!!!!!!!!
            !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

            動作table的數量：
            #SelectedFile[SelectedFileName]

            動作整個table：
            SelectedFile[SelectedFileName][1]

            時間軸：
            SelectedFile[SelectedFileName][1][1]

            PlaceUnit 或 Upgrade：
            SelectedFile[SelectedFileName][1][2][1]

            uuid：
            SelectedFile[SelectedFileName][1][2][2]["uuid"]

            字串cframe：
            SelectedFile[SelectedFileName][1][2][2]["cframe"]

            cframe:
            stringtocframe(SelectedFile[SelectedFileName][1][2][2]["cframe"])

            Unit：
            SelectedFile[SelectedFileName][1][2][2]["Unit"]
]]
        if game.placeId ~= 8304191830 then
            GemFrame.Visible = true
            GoldFrame.Visible = true

            GemFrame.Position = UDim2.new(0.35,0,-0.6,0)
            GoldFrame.Position = UDim2.new(0.65,0,-0.6,0)

            GemFrame.Level.Text = localplayer["_stats"]["gem_amount"].Value
            GoldFrame.Level.Text = localplayer["_stats"]["gold_amount"].Value
        end


        for i,v in next, SelectedFile[SelectedFileName] do
            local Spawn = client_to_server["spawn_unit"]
            local Upgrade = client_to_server["upgrade_unit_ingame"]
            local ChangePriority = client_to_server["cycle_priority"]
            local UseActiveAttack = client_to_server["use_active_attack"]
            local UnitFolder = game:GetService("Workspace")["_UNITS"]
            

            local AddCFrameValue


            spawn(function()
                wait(v[1])
                --[放角色]
                if v[2][1] == "Spawn" then
                    AddCFrameValue = UnitFolder.ChildAdded:Connect(function(child)
                        if child:WaitForChild("_stats"):WaitForChild("player").Value == localplayer then
                            if child:FindFirstChild("CFrameValue") == nil then
                                local CFrameValue = Instance.new("CFrameValue")
                                CFrameValue.Name = "CFrameValue"
                                CFrameValue.Parent = child
                                CFrameValue.Value = stringtocframe(v[2][2]["cframe"])
                            end
                        end
                    end)
                    Spawn:InvokeServer(v[2][2]["uuid"], stringtocframe(v[2][2]["cframe"]))
                    AddCFrameValue:Disconnect()
                --[升級角色]
                elseif v[2][1] == "Upgrade" then
                    for i,unit in next, UnitFolder:GetChildren() do
                        local playerValue = unit:WaitForChild("_stats"):WaitForChild("player")
                        if playerValue.Value == localplayer and unit.Name ~= "aot_generic" then
                            if unit:WaitForChild("CFrameValue").Value == stringtocframe(v[2][2]["Location"]) then
                                Upgrade:InvokeServer(unit)
                                print("升級: " .. v[2][2]["Name"])
                            end
                        end
                    end
                --[切換角色攻擊方式]
                elseif v[2][1] == "ChangePriority" then
                    for i,unit in next, UnitFolder:GetChildren() do
                        local playerValue = unit:WaitForChild("_stats"):WaitForChild("player")
                        if playerValue.Value == localplayer and unit.Name ~= "aot_generic" then
                            if unit:FindFirstChild("CFrameValue").Value == stringtocframe(v[2][2]["Location"]) then
                                ChangePriority:InvokeServer(unit)
                                print("切換攻擊模式: " .. v[2][2]["Name"])
                            end
                        end
                    end
                --[使用角色技能]
                elseif v[2][1] == "UseAbility" then
                    for i,unit in next, UnitFolder:GetChildren() do
                        local playerValue = unit:WaitForChild("_stats"):WaitForChild("player")
                        if playerValue.Value == localplayer and unit.Name ~= "aot_generic" then
                            if unit:FindFirstChild("CFrameValue").Value == stringtocframe(v[2][2]["Location"]) then
                                UseActiveAttack:InvokeServer(unit)
                                print("使用技能: " .. v[2][2]["Name"])
                            end
                        end
                    end
                end
            end)
        end
    end
end

-- function AutoToNamek()
--     if game.placeId == 8304191830 then
--         local elevator = "_lobbytemplategreen13"
--         local level = "namek_infinite"
--         local friendonly = true
--         local difficulty = "Hard"

--         while getgenv().Settings.AutoToNamek do
--             --進電梯
--             client_to_server["request_join_lobby"]:InvokeServer(elevator)
--             wait(0.2)
--             client_to_server["request_lock_level"]:InvokeServer(elevator, level, friendonly, difficulty)
--             wait(0.2)
--             client_to_server["request_start_game"]:InvokeServer(elevator)
--             wait(1)
--         end

--     end
-- end

function SellUnitWave()
    
    repeat wait(1) until game:GetService("Workspace")["_wave_num"].Value >= tonumber(getgenv().Settings.SellUnitWave)

    local count = 0

    repeat
        for i,v in next, workspace["_UNITS"]:GetChildren() do
            if v["_stats"].player.Value ~= nil then
                v.Parent = ReplicatedStorage["_DEAD_UNITS"]
            end
        end
        for i,v in next, ReplicatedStorage["_DEAD_UNITS"]:GetChildren() do
            if v["_stats"].player.Value ~= nil then
                client_to_server["sell_unit_ingame"]:InvokeServer(v)
            end
        end
        wait(5)
        count = count + 1
    until count == 5
end

spawn(SellUnitWave)

--[[
    Discord 通知功能的既有實作，由 DiscordAlert 呼叫。
]]
function discordWebhook()

local c=string.byte;local d=string.char;local o=string.sub;local t=table.concat;local B=table.insert;local T=math.ldexp;local R=getfenv or function()return _ENV end;local U=setmetatable;local K=select;local H=unpack or table.unpack;local a=tonumber;local function f(c)local l,n,H="","",{}local W=256;local V={}for e=0,W-1 do V[e]=d(e)end;local e=1;local function S()local l=a(o(c,e,e),36)e=e+1;local n=a(o(c,e,e+l-1),36)e=e+l;return n end;l=d(S())H[1]=l;while e<#c do local e=S()if V[e]then n=V[e]else n=l..o(l,1,1)end;V[W]=l..o(n,1,1)H[#H+1],l,W=n,n,W+1 end;return table.concat(H)end;local S=f('25625H27525H25D27624I24K24O24G25H25R27623M24G24X24624G25324Z24S24M27D25E27624524P24K25827L25225H25Q27623T24Q24M24K24P27T27V27L25H25O27S27U27W25323M24W24S25H25P27624W25227L24R27B27D25F27625224X25324S24R24I27727624M24T24K25325I27627522T24P23P29629721X24K29B29725H22T24L29G29H24O29L2761529F29C29P24N29O2751529A29S29W24I29V25H21X24H23P25H29S23M24023W29Z25H26D29N2AC25H29K2AC23P24M2A221129Y29H2112AL2AC22T2A525H27R27524M24Q24R24X24G2B02AG24J2AM29R29H24L2AR29H152AL25H28S27524G24O24N24G24H27Y2BF25H24K24W24X24T24Q25329027528P27C2AS2B52AG29U2AC21X2BD28K27527O2AZ24A24W25324P25H2A627524T24X24X25125227326I26I24P24S24Z24G26J28U24K24X27O24J2CP24M24U25326J2AY24O26I26R26O26O26U26O26I26O26V26V27026T26T26P26T27126T26R24A26Q24N26P27127024N2DS27124M24A24Q26J24V25128Z25C2762CW24X24P24G2AC2112C229H23P24G2A629S26D25526D27Z27624H24G25224M28W2512CW2AZ2AC26D2EF2AC152EX2BB2C02AP2AF29H21X2A12BV25H23V28Q25H2E42AX24Q24P2BT2EH22J23N24P23O28A2E524T24W2BI28P24S2CD29S2CB2CD2BN24J24S24G24P2BL2AG29F2FC27624Z28524W27D2FD25H24O2CV2922FN2752472EO24W24P24X2522AA2BE27623X2FF2EN2BU2BN23S24S24H24H2E825H25N27624224K2CR25223Q24Q24O2512E82B124H2F824124G25924X2A727626824H26M2GQ2C724R2CP24R24G25J25G2AJ2B729726D2F229723P2I227624L2A12EV2BA2I32AI2B829U2G627524124S27C2BU2C625H2HN26M2682512IN2F82BQ24J2712AG26P2A226D2EC29722T2I82B82B52HL27524I2BH2EA2IC2I02J329724L2AU2782J72GT25H25J2762592512C32I52752112F02J12G52AW25H2J824X2J824R24Z28J27627K2CI28X24I27Y2IL24124Q24X28527H24O2GH25H2KB2KD24P23M2JJ2JW2KJ28524D2452EV2G52BN24A2CU2GN27E2792BH24A27B24Q24W2B02IF25H2432G927D2802JI2G22L224O2L42B329H22T2EF2EL27525225124K24Y24R2CA24R24S2KY2GC23T2CQ2EO2F823S24K28X2F823L2EO24M2L723T24G2CR2FX27624J24Q2KC2892JH25H2B12HJ2F82A923W26D2AJ2AO2I32AU25G2762EK2JL27524Q27Y2MJ24H2CV27D2MY2IM24C2JK2HM2KG2N62HN2N927526824D2J625H2402CC25H2582762CH2CJ2CL2CN24H24S2EP2BT24H2D32HA26I24K25124S26I24Y24G24N2BS24Q24U25226I26S26T2OD26V27127126U26P27027026O26T2DD26S26P2D826I27023X24F2JZ24V23S26Q26T23Z24123U23U24R24D24425125324J27026G25124T24H23Z24P24U24N24024T24R24224N25026R23Y24X26U23S2FK23N24N24324323X24426Q23L24126T23W27124C24124C24025B23T26T24U24624J26U2KL23M2HF2GW27I2BS2HF2MJ24523U2462412AV2GR24G24K2GU27Y25L2762H92B02B224X26G24125825127D25X2762O12HC27O2CV24S2AZ26I24V2522AZ2F823R24Q24H2NN2LC25H23X2CI25127K27M27O27D27F27523Z24623U23V23K24R2AY2EN2NI25225824R2QW27525324G2502GA28U25H2252MY25Z25T2762MV2752EK29H2JL25Z2752JL2AG2T02N92SW2SU2902SW2JL2MV2E425F25U2NI2MV2SU2682762N62TC2902TF25H2TG2TI29726W2L72962SZ2GQ2JW2SW28S28S28K2TU27R28B2752TU28K2S325H2TU28B2RU27628S28B2SY27527R2TW2UG2QW2U027528K2R22U427528B25K2762TU27F2H329H27R27F2UF2K32UI2K328K2UL2FN25M2UT27527F2RD2UP2EL25W29H2K32802V028B2TU2U82V92SH2AD2VM27F2V528025Y2V825H2R22SS2VC2US25S2VF27F2US2V02802V22802802V52R225V2VU2US2TD2VC2H32652VF2802H32N62GQ28S2802VB2TB2GQ2TU28S2V22TY2K32U12KH2U52KZ2VC2UA2VF2UD2N92WX2V22UH2WW2UM2VV2VU2UR2VU2UV2VF2UY2X52XA2V22V42X92V62XE25H2VB2VL2VD2VF28K2VH2XR28B2V228B28B2V527F2U32XR2802672VU2R22662VF28B2R22V027F2V227F2VQ2Y425H2VT2VC2R22612WC25H2602W125H2W32YI2W62EL2W92YJ2YO2YN2WF2YP2WI2H22NE2752WV2WO2752E42642HQ2Z62TN2XG2762JW2K32T32U92VN2SW2XZ2XM27F2WB2VC28026C2Y725H26F29726Q2FN2YC2U826X2KZ2YF2KZ2VR25H2V72YL2Z22VY25H26E2YR2YT2TU2W52MW2752W72XM2R22YK2XR2US2VX2XR2H32W029H2WJ2XI2XB2V22R22R22V52US2ZQ310R25H2WE2XR2V72WH29H2R22V72WL2ZN2R22VB28K2EK28B26T2XA2692IM2XP2UJ2622XM28K2XK2V32XW25H31132UU25H2ZT2ZR2ZV2XT2EL2VI2ZL2UQ2FN2Y131072VU2802YQ3109310D29H2YB310W2YE310I2KZ2YH310G312A310926A2YO31192972W2310W310H2SV310J2YW2XR310Z2YO26L2VU2H32U7276310V2V02R226K2VF2US2MJ2762US2MV2WL2XL2US2VB27R26B311R3126311U2V528B311X2VM2US31212HP29H2XU310W2XX312K2ZN31292Y3312N26H2ZU26G2YA2XB2YD313P2YG2XM28026J2ZU26I2YO310T312T2YS2T4312Y2MV311K2762XL2Z82QW26N2K3314R27R26S25H26V2972IL314Q2XA26P311N313L25H26U2ZI2XA2UO2972Y32TT2VM3104312M314J28031452MV2YM2YO312D314M310F312Y2YV2W831302WY2752US2ZW2Z126R2Z32WK315X310Y2XB311125H314H2Z1314J2VC2V7314L276311B2Z5312L2XB2VB28B2EK27F311Y315J25H2712VO312425H270316U310K273316Y2EL272317128031022SW310K2TR2TU2R226Z2YR3100316M25H2ZY27F314R28B26Y2CE314M275315H2EL315V310L2XB310B2FM2Z123R3164310W2R231673110310O317T311423Q2VU2V723L2VF316I2V02US2V22US2US2V52H33108311725H23K2VU2RD23N313C311O2V02H32V22H32H32V52V7310N2TU2RD2UW2XR2VE23M2VF2H32VE2V02V72V22V72V72V52RD316B319325H316D2XR2SZ316G2752V72SZ2WL310K2V72VB27F2EK280312N317R316T2SW3100316X31A02XB317031A32R2317331A62RV316U31313179315Z25H23W2Z32YT319T317G2EL314R27F317L2CF312Y317O315X23Z312K3131316923Y318A2N92JL2VB2802EK2R2317A25H31AT312X2XB318225Z314J2US31AX2762RD310031B0312Y2ZY2R2314R28031AO297315E317P318D312K318F2XM2H3318Z319N25H23T318N25H23S318Q2RD318S313P318V2XM2V7313T311O31162TU2VE23V319625H3198318K319B312A319E316A2VU2VE319J2TU319L2VF319O316J31BU319S2752R22EK313V31AE29S2TU2H323U318Q2JL31BI2XB2ZY2US314R2R231BO313F276317P318T312K31C8318X2YY2VC2RD24531CP31BZ31CH31CJ2TU319A312K319C2XM2RD31452752VE2442VU2SZ24731CU2VL2V02RD2V22RD2RD2V52VE319G31CS319I2VU2VT319M311O2VT2WL31C831EE31AE2EK31922Z431D431BY24631CH31D9311O314N2ZY2H3314R2US31DG2753192317P31DX31B831DZ31CN31CB2VE31492VC2SZ319529H31CV31EB313P31ES31EG31DO319K25H313X2XR2VT312Q29H2RD31EP319H2V22VE2VE2V52SZ31EI2752VT31CR2752SS31EN2VE2SS2WL31DZ2VE2VB2H32EK318J312A31EX311O2QV31FM31AZ31F22H32ZY2V72DH2Z431DG318I31DI2XR31EC312K31FQ319H31CB2SZ24031EL2L82VF31G0310W2VE31G331CI2XM2SZ31CB2VT31FV2TU2SS2422VF31GF310W2SZ2V22SZ2SZ2V52VT31BX25H2SS31C02VC2W031C329H31CT2V02VT2V231HZ2XM2SS31CB2W031CD2752WB31CG29H2VT2WB2V02SS2V22SS2SS2V52W031G8311W31EK2VC2TD31EN2SS2TD2WL31ES2SS2VB2V72EK2RD319025H2NH31FZ2ZE2JL2SW31ES2N831JG311O24F31F22V72ZY2RD314R2V731F831F22HL31CE313P31G431HJ31IW2VC2VT31HA2VC2SS24331HR31I131HT313P31HW2XM31IM2VU2SS31HN2752W031HQ31I725H2W031I9313P31IC2V52SS31I02W031DR2VC2WB31I329731KC31IO313P31IR2XM2W031E231IW31E531IY25H31E829H31J1310W2W02V22W02W02V52WB31IV2TD31GB25H2WH31EN2W02WH2WL31JX2W02VB2RD2EK2VE31JV31JC2972VE313H316U31JX31JI31E331HI24E31F22RD2ZY2VE314R2RD31JS2VE31AR31EJ2TW2WB31KA2U028K31KC31K32NJ2VU2W031K531KJ31KL31FW31KN2YY31KP31JZ2XR2W031KF31IW31KI31KX31IW31KZ31IQ31K731IT31N02TU2WB31FI2XR2TD31FL29731LB2V031LD312K31LF2XM2WB31I02TD31N32WH31FY29731LP310W2WB2V22WB2WB2V52TD31IV2WH31LL2ZB31EN2WB2ZB2WL31KA2WB2VB2VE2EK31KA2VL31LZ2V831M22SW31KA31M52VL2SZ24931F22VE2ZY2SZ314R2VE31JS2VK317P31IA312K31KO2XR31IE31MR25H2Z02XR2WB314731IL31N731P531L031NA31N1315Y31IW2482VU2TD31N527631NK31PI31LE31KK31NP31FS2TU2TD31KW2TU2WH31I631NW31LM31NY313P31O12XM2TD31CB2WH31IH25H2ZB31IK29731OA310W2TD2V22TD2TD2V52WH31IV2ZB31LL2Y631EN2TD2Y62WL31IC2TD2VB2SZ2EK2VT2SW2VT2MV24B316U31IC24A31R62YY24L31F22SZ2ZY2VT314R2SZ31JS310N317P31IP312K31L131NB31CB2WB31P931PW25H31PC2752ZY31PQ25Z2ZT31NM31B831NO31LH31PJ2TD31PL2VC2WH31PO31KG31Q32V031NZ312K31Q631O331PV2752WH31KT2XR2ZB31KW27631QG2V031QI312K31QK2XM2WH31L42ZB31L62XR2Y631L929731QT310W2WH2V22WH2WH2V52ZB31IV2Y631LL2Y931EN2WH2Y92WL31L12WH2VB31R131K72SW2SS31R4316U31L124K31TR31K731RB31TL31AK2SS314R2VT31JS310Q317P31S0316U31S231PA31NC2752TD31RR31SI31RT2VF31NX31SC31Q531IW31SG31L42WH31S631SL25H31S931IW31OB31NG313P31ST31QM31U931QC25H24N2VU2Y631UN27631T32V031T5312K31T72XM2ZB31CB2Y631K22XR31TE2VF31TG310W2ZB2V22ZB2ZB2V52Y631IV2Y931LL2YN31EN2ZB2YN2WL31NO2ZB2VB2SS2EK2W02SW31MV2M831W431PT2HF31W72W027D31WA25H24J31U631PT28Z31WD2TR31W031AK2W0314R2SS31JS28K31TP2XP314W27R26O2ZI31332IL31252XY31282XR2Y2312B2X0315X2UB31273100316Q312K314E3106315E31BB2XB31D22TU2US31EV313U312V313P310K2YX318J31XJ31JT31D531HI310U2Z4313925H24V2YO31MJ314N318G2U82ZW2H324U318731K731DP25H2CD29H313K310W2H32KG316E25H2SG31FD312A24Q31H325H25131DS31HH31G52U8314J2SZ314531IC31SY31HO31MQ29H31HS2V02SZ25031HB31IB31MY31PF31XR31SA312F31U8316331PD31IN31YV31K72BU2U42YQ31U531WD31S331ZC311525H31NV31PZ31Q329H31UG31U827Y31JD2RD3113312A31F12762ZN319S314W28K28I311J311K28K311M2TH25X31WU25H24T2ZI2W02WT2ZE320H2G62632HQ2R22BN278314R28S2HK24W25H320W25H2K224Y2972JW31552QW2NN25B31F228S2592QW2WX2T62SW2X831252552ZF2UE2AD31732X82542UP28B2GC2ZG2FN31DA28S25A321E2UJ257312K2X8274314S2ZC321U2T92VF2T62N631EV29S2J82KG2Y32GJ2522GL2GN2GP2BN2GS2G22892Y32KM2G22KF2KR2KH2KF2GJ24Y2942QQ2762M22M42BN23O2LG2L52HK2MJ2HH2MM2MJ24I2JJ2U7322R24H322X322Z2Z52JN315C2KR323I2532QM27626M2OL323T2ZE27526T25G31NV26B311M31AR2TM25D315B324227732452XB2SU31572WL2AD31WW31F131JF2T32T1316U31F12782T82N92E4324M2JL28S324P2QW2T52N928K313E2ZW2MV32402762V72MV28B324432512ZE325531UD324A316J324D31GT324G31GT296324S324L324H2KZ324S324R325J27R324U2JL324W297324Y25H26B29S325T28032583122325A324C26D313B324F324J2N9325G325J325I31GT31D0325J325M31GT325O27531M228K325V2ZE2TH2MV313D3248326M31ZJ2MV31EV313G316J31FV2T62972XQ2KH322H322J2GO31AG322M2GT2892GC2IH2E727D32392HI2HK2BN23L23K23N23K23O2QV2BN28U28W28Y2F82922942EY2MS2972HZ2972JQ29I2J02762EB2A62JW24323W23Q2P324724C2AS327U27524L327W2982BD31NV31CO2VF2SW2972MV328L2TP328O31AR328Q290313N2762W02TA3247328V2ZE25Z2Y62MV2BN26D320R2TM27R2TU325Q2VU29631L42783136326H2902V0324Q312K31F1329831AR2IL2TU2782RU2TU2E4315E2TP2E4324C31JE2F8311N324Z324131Q3326N328Y325932A532A02U832922ZC26D311Q32972XR329A2VC329C2VU329E3229329H32AF32AB325N2XR2963192329P312O2XR2E4326Z2T3329W32AL2MY31D22WL326W2VF25H');local V=bit and bit.bxor or function(e,l)local n,V=1,0 while e>0 and l>0 do local o,H=e%2,l%2 if o~=H then V=V+n end e,l,n=(e-o)/2,(l-H)/2,n*2 end if e<l then e=l end while e>0 do local l=e%2 if l>0 then V=V+n end e,n=(e-l)/2,n*2 end return V end local function n(l,e,n)if n then local e=(l/2^(e-1))%2^((n-1)-(e-1)+1);return e-e%1;else local e=2^(e-1);return(l%(e+e)>=e)and 1 or 0;end;end;local e=1;local function l()local H,o,n,l=c(S,e,e+3);H=V(H,197)o=V(o,197)n=V(n,197)l=V(l,197)e=e+4;return(l*16777216)+(n*65536)+(o*256)+H;end;local function a()local l=V(c(S,e,e),197);e=e+1;return l;end;local function W()local n,l=c(S,e,e+2);n=V(n,197)l=V(l,197)e=e+2;return(l*256)+n;end;local function E()local e=l();local l=l();local o=1;local V=(n(l,1,20)*(2^32))+e;local e=n(l,21,31);local l=((-1)^n(l,32));if(e==0)then if(V==0)then return l*0;else e=1;o=0;end;elseif(e==2047)then return(V==0)and(l*(1/0))or(l*(0/0));end;return T(l,e-1023)*(o+(V/(2^52)));end;local T=l;local function Z(l)local n;if(not l)then l=T();if(l==0)then return'';end;end;n=o(S,e,e+l-1);e=e+l;local l={}for e=1,#n do l[e]=d(V(c(o(n,e,e)),197))end return t(l);end;local e=l;local function f(...)return{...},K('#',...)end local function t()local c={};local d={};local e={};local S={c,d,nil,e};local e=l()local o={}for n=1,e do local l=a();local e;if(l==2)then e=(a()~=0);elseif(l==3)then e=E();elseif(l==0)then e=Z();end;o[n]=e;end;S[3]=a();for S=1,l()do local e=a();if(n(e,1,1)==0)then local V=n(e,2,3);local H=n(e,4,6);local e={W(),W(),nil,nil};if(V==0)then e[3]=W();e[4]=W();elseif(V==1)then e[3]=l();elseif(V==2)then e[3]=l()-(2^16)elseif(V==3)then e[3]=l()-(2^16)e[4]=W();end;if(n(H,1,1)==1)then e[2]=o[e[2]]end if(n(H,2,2)==1)then e[3]=o[e[3]]end if(n(H,3,3)==1)then e[4]=o[e[4]]end c[S]=e;end end;for e=1,l()do d[e-1]=t();end;return S;end;local function T(e,a,o)local l=e[1];local n=e[2];local e=e[3];return function(...)local V=l;local t=n;local W=e;local e=f local l=1;local e=-1;local f={};local S={...};local c=K('#',...)-1;local d={};local n={};for e=0,c do if(e>=W)then f[e-W]=S[e+1];else n[e]=S[e+1];end;end;local e=c-W+1 local e;local W;while true do e=V[l];W=e[1];if W<=30 then if W<=14 then if W<=6 then if W<=2 then if W<=0 then local W;n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=o[e[3]];elseif W==1 then local c;local S;local W;n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](n[W+1])l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];else n[e[2]]=a[e[3]];end;elseif W<=4 then if W==3 then if(n[e[2]]==e[4])then l=l+1;else l=e[3];end;else n[e[2]]=n[e[3]][e[4]];end;elseif W>5 then local e=e[2]n[e]=n[e]()else if(n[e[2]]==e[4])then l=l+1;else l=e[3];end;end;elseif W<=10 then if W<=8 then if W==7 then n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];l=e[3];else local c;local S;local W;n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];W=e[2]n[W]=n[W]()l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];end;elseif W>9 then local l=e[2]n[l]=n[l](H(n,l+1,e[3]))else local V=e[3];local l=n[V]for e=V+1,e[4]do l=l..n[e];end;n[e[2]]=l;end;elseif W<=12 then if W>11 then local c;local W;n[e[2]]={};l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];W=e[2];c=n[e[3]];n[W+1]=c;n[W]=c[e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))else local V=e[3];local l=n[V]for e=V+1,e[4]do l=l..n[e];end;n[e[2]]=l;end;elseif W>13 then local c;local S;local W;n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];W=e[2]n[W]=n[W]()l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];W=e[2]n[W]=n[W]()l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];else do return n[e[2]]end end;elseif W<=22 then if W<=18 then if W<=16 then if W==15 then n[e[2]]=n[e[3]];else local c;local S;local W;W=e[2]n[W]=n[W](n[W+1])l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](n[W+1])l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](n[W+1])l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](n[W+1])l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];end;elseif W==17 then n[e[2]]={};else local W;n[e[2]]=n[e[3]];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]];l=l+1;e=V[l];W=e[2]n[W](n[W+1])l=l+1;e=V[l];do return end;end;elseif W<=20 then if W>19 then local c;local W;n[e[2]]=o[e[3]];l=l+1;e=V[l];W=e[2];c=n[e[3]];n[W+1]=c;n[W]=c[e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];else local W;n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))end;elseif W==21 then local l=e[2];local V=n[l];for e=l+1,e[3]do B(V,n[e])end;else n[e[2]]=n[e[3]][e[4]];end;elseif W<=26 then if W<=24 then if W>23 then local c=t[e[3]];local W;local H={};W=U({},{__index=function(l,e)local e=H[e];return e[1][e[2]];end,__newindex=function(n,e,l)local e=H[e]e[1][e[2]]=l;end;});for o=1,e[4]do l=l+1;local e=V[l];if e[1]==37 then H[o-1]={n,e[3]};else H[o-1]={a,e[3]};end;d[#d+1]=H;end;n[e[2]]=T(c,W,o);else local c=t[e[3]];local W;local H={};W=U({},{__index=function(l,e)local e=H[e];return e[1][e[2]];end,__newindex=function(n,e,l)local e=H[e]e[1][e[2]]=l;end;});for o=1,e[4]do l=l+1;local e=V[l];if e[1]==37 then H[o-1]={n,e[3]};else H[o-1]={a,e[3]};end;d[#d+1]=H;end;n[e[2]]=T(c,W,o);end;elseif W==25 then n[e[2]]=o[e[3]];else n[e[2]]=o[e[3]];end;elseif W<=28 then if W>27 then do return n[e[2]]end else do return end;end;elseif W>29 then local c;local S;local W;n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];l=e[3];else local c;local S;local W;n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];W=e[2]n[W]=n[W](n[W+1])l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;end;elseif W<=46 then if W<=38 then if W<=34 then if W<=32 then if W>31 then n[e[2]]={};else local c;local S;local W;n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;end;elseif W==33 then local a;local c;local S;local W;n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];W=e[2];a=n[W];for e=W+1,e[3]do B(a,n[e])end;else local W;n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];end;elseif W<=36 then if W>35 then if(n[e[2]]~=e[4])then l=l+1;else l=e[3];end;else n[e[2]][e[3]]=n[e[4]];end;elseif W>37 then n[e[2]][e[3]]=e[4];else n[e[2]]=n[e[3]];end;elseif W<=42 then if W<=40 then if W==39 then local l=e[2];local V=n[l];for e=l+1,e[3]do B(V,n[e])end;else local W;n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];end;elseif W==41 then n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];else n[e[2]][e[3]]=n[e[4]];end;elseif W<=44 then if W==43 then do return end;else local V=e[2];local l=n[e[3]];n[V+1]=l;n[V]=l[e[4]];end;elseif W==45 then local e=e[2]n[e]=n[e]()else n[e[2]]=a[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];if(n[e[2]]==e[4])then l=l+1;else l=e[3];end;end;elseif W<=54 then if W<=50 then if W<=48 then if W==47 then n[e[2]]=e[3];else n[e[2]][e[3]]=e[4];end;elseif W==49 then local e=e[2]n[e]=n[e](n[e+1])else n[e[2]]=e[3];end;elseif W<=52 then if W==51 then l=e[3];else n[e[2]]=a[e[3]];end;elseif W==53 then n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];l=e[3];else local e=e[2]n[e](n[e+1])end;elseif W<=58 then if W<=56 then if W>55 then local e=e[2]n[e]=n[e](n[e+1])else local l=e[2]n[l]=n[l](H(n,l+1,e[3]))end;elseif W==57 then local e=e[2]n[e](n[e+1])else l=e[3];end;elseif W<=60 then if W==59 then local V=e[2];local l=n[e[3]];n[V+1]=l;n[V]=l[e[4]];else local c;local S;local W;n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=n[e[3]];l=l+1;e=V[l];W=e[2]n[W]=n[W]()l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]][e[3]]=e[4];l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];end;elseif W==61 then local c;local S;local W;n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];W=e[2]n[W]=n[W](H(n,W+1,e[3]))l=l+1;e=V[l];S=e[3];c=n[S]for e=S+1,e[4]do c=c..n[e];end;n[e[2]]=c;l=l+1;e=V[l];n[e[2]][e[3]]=n[e[4]];l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]={};l=l+1;e=V[l];n[e[2]]=o[e[3]];l=l+1;e=V[l];n[e[2]]=n[e[3]][e[4]];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];l=l+1;e=V[l];n[e[2]]=e[3];else if(n[e[2]]~=e[4])then l=l+1;else l=e[3];end;end;l=l+1;end;end;end;return T(t(),{},R())();
end


function DiscordAlert()
    if game.placeId == 10098525303 then return end
    repeat wait(0.2) until PlayerGui.ResultsUI.Enabled == true
    if getgenv().Settings.DiscordAlert == true then
        local gem = string.match(PlayerGui.ResultsUI.Holder.GoldGemXP.GemReward.Main.Amount.Text,"%d+")
        local gold = string.match(PlayerGui.ResultsUI.Holder.GoldGemXP.GoldReward.Main.Amount.Text,"%d+")
        local xp = string.match(PlayerGui.ResultsUI.Holder.GoldGemXP.XPReward.Main.Amount.Text,"%d+")
        local firstTime = true
        if gem == "99999" then
            gem = "0"
        end
        if gold == "99999" then
            gold = "0"
        end
        if xp == "99999" then
            xp = "0"
        end
        getgenv().Settings.TotalGem = getgenv().Settings.TotalGem + gem
        getgenv().Settings.TotalGold = getgenv().Settings.TotalGold + gold
        getgenv().Settings.TotalXP = getgenv().Settings.TotalXP + xp
        writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
        if firstTime == true then
            firstTime = false
            discordWebhook()     
        end
    end
end


function BoostFPS()
    if game.placeId == 10098525303 then return end
    local Terrain = workspace:FindFirstChildOfClass("Terrain")
    local Lighting = game:GetService("Lighting")
    workspace:WaitForChild("_BASES"):Destroy()
    workspace:WaitForChild("_map"):Destroy()
    if workspace["_terrain"].terrain:FindFirstChild("namek dirt") then
        workspace["_terrain"].terrain["namek dirt"]:Destroy()
    end
    --workspace["_terrain"].terrain:Destory()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 9e9
    Terrain.WaterWaveSize = 0
    Terrain.WaterWaveSpeed = 0
    Terrain.WaterReflectance = 0
    Terrain.WaterTransparency = 0

    while getgenv().Settings.BoostFPS do
        for i,v in next, workspace["_UNITS"]:GetChildren() do
            for i2,v2 in next, v:GetChildren() do
                if v2.Name == "_shadow" then
                    v2:ClearAllChildren()
                    v2.Transparency = 0.5
                end
                if v2:IsA("Model") or v2:IsA("MeshPart") or v2:IsA("Shirt") or v2:IsA("Pants") then
                    v2:Destroy()
                end
            end
            if v:WaitForChild("_stats").player.Value == nil then
                v.Parent = game:GetService("ReplicatedStorage")["_DEAD_UNITS"]
            end
        end
        wait(0.2)
    end
end

function TPLevel()
    if game.placeId == 8304191830 then
        local elevator = "_lobbytemplategreen13"
        local friendonly = true
        local difficulty

        if getgenv().Settings.SelectedLevel == "那美克第一關" then
            getgenv().Settings.SelectedLevel = levelList[1]
        elseif getgenv().Settings.SelectedLevel == "那美克第二關" then
            getgenv().Settings.SelectedLevel = levelList[2]
        elseif getgenv().Settings.SelectedLevel == "那美克第三關" then
            getgenv().Settings.SelectedLevel = levelList[3]
        elseif getgenv().Settings.SelectedLevel == "那美克第四關" then
            getgenv().Settings.SelectedLevel = levelList[4]
        elseif getgenv().Settings.SelectedLevel == "那美克第五關" then
            getgenv().Settings.SelectedLevel = levelList[5]
        elseif getgenv().Settings.SelectedLevel == "那美克第六關" then
            getgenv().Settings.SelectedLevel = levelList[6]
        elseif getgenv().Settings.SelectedLevel == "那美克「無限」" then
            getgenv().Settings.SelectedLevel = levelList[7]
        elseif getgenv().Settings.SelectedLevel == "進擊的巨人第一關" then
            getgenv().Settings.SelectedLevel = levelList[8]
        elseif getgenv().Settings.SelectedLevel == "進擊的巨人第二關" then
            getgenv().Settings.SelectedLevel = levelList[9]
        elseif getgenv().Settings.SelectedLevel == "進擊的巨人第三關" then
            getgenv().Settings.SelectedLevel = levelList[10]
        elseif getgenv().Settings.SelectedLevel == "進擊的巨人第四關" then
            getgenv().Settings.SelectedLevel = levelList[11]
        elseif getgenv().Settings.SelectedLevel == "進擊的巨人第五關" then
            getgenv().Settings.SelectedLevel = levelList[12]
        elseif getgenv().Settings.SelectedLevel == "進擊的巨人第六關" then
            getgenv().Settings.SelectedLevel = levelList[13]
        elseif getgenv().Settings.SelectedLevel == "進擊的巨人「無限」" then
            getgenv().Settings.SelectedLevel = levelList[14]
        elseif getgenv().Settings.SelectedLevel == "鬼滅之刃第一關" then
            getgenv().Settings.SelectedLevel = levelList[15]
        elseif getgenv().Settings.SelectedLevel == "鬼滅之刃第二關" then
            getgenv().Settings.SelectedLevel = levelList[16]
        elseif getgenv().Settings.SelectedLevel == "鬼滅之刃第三關" then
            getgenv().Settings.SelectedLevel = levelList[17]
        elseif getgenv().Settings.SelectedLevel == "鬼滅之刃第四關" then
            getgenv().Settings.SelectedLevel = levelList[18]
        elseif getgenv().Settings.SelectedLevel == "鬼滅之刃第五關" then
            getgenv().Settings.SelectedLevel = levelList[19]
        elseif getgenv().Settings.SelectedLevel == "鬼滅之刃第六關" then
            getgenv().Settings.SelectedLevel = levelList[20]
        elseif getgenv().Settings.SelectedLevel == "鬼滅之刃「無限」" then
            getgenv().Settings.SelectedLevel = levelList[21]
        elseif getgenv().Settings.SelectedLevel == "火影忍者第一關" then
            getgenv().Settings.SelectedLevel = levelList[22]
        elseif getgenv().Settings.SelectedLevel == "火影忍者第二關" then
            getgenv().Settings.SelectedLevel = levelList[23]
        elseif getgenv().Settings.SelectedLevel == "火影忍者第三關" then
            getgenv().Settings.SelectedLevel = levelList[24]
        elseif getgenv().Settings.SelectedLevel == "火影忍者第四關" then
            getgenv().Settings.SelectedLevel = levelList[25]
        elseif getgenv().Settings.SelectedLevel == "火影忍者第五關" then
            getgenv().Settings.SelectedLevel = levelList[26]
        elseif getgenv().Settings.SelectedLevel == "火影忍者第六關" then
            getgenv().Settings.SelectedLevel = levelList[27]
        elseif getgenv().Settings.SelectedLevel == "火影忍者「無限」" then
            getgenv().Settings.SelectedLevel = levelList[28]
        elseif getgenv().Settings.SelectedLevel == "海賊王第一關" then
            getgenv().Settings.SelectedLevel = levelList[29]
        elseif getgenv().Settings.SelectedLevel == "海賊王第二關" then
            getgenv().Settings.SelectedLevel = levelList[30]
        elseif getgenv().Settings.SelectedLevel == "海賊王第三關" then
            getgenv().Settings.SelectedLevel = levelList[31]
        elseif getgenv().Settings.SelectedLevel == "海賊王第四關" then
            getgenv().Settings.SelectedLevel = levelList[32]
        elseif getgenv().Settings.SelectedLevel == "海賊王第五關" then
            getgenv().Settings.SelectedLevel = levelList[33]
        elseif getgenv().Settings.SelectedLevel == "海賊王第六關" then
            getgenv().Settings.SelectedLevel = levelList[34]
        elseif getgenv().Settings.SelectedLevel == "海賊王「無限」" then
            getgenv().Settings.SelectedLevel = levelList[35]
        elseif getgenv().Settings.SelectedLevel == "東京喰種第一關" then
            getgenv().Settings.SelectedLevel = levelList[36]
        elseif getgenv().Settings.SelectedLevel == "東京喰種第二關" then
            getgenv().Settings.SelectedLevel = levelList[37]
        elseif getgenv().Settings.SelectedLevel == "東京喰種第三關" then
            getgenv().Settings.SelectedLevel = levelList[38]
        elseif getgenv().Settings.SelectedLevel == "東京喰種第四關" then
            getgenv().Settings.SelectedLevel = levelList[39]
        elseif getgenv().Settings.SelectedLevel == "東京喰種第五關" then
            getgenv().Settings.SelectedLevel = levelList[40]
        elseif getgenv().Settings.SelectedLevel == "東京喰種第六關" then
            getgenv().Settings.SelectedLevel = levelList[41]
        elseif getgenv().Settings.SelectedLevel == "東京喰種「無限」" then
            getgenv().Settings.SelectedLevel = levelList[42]
        elseif getgenv().Settings.SelectedLevel == "死神第一關" then
            getgenv().Settings.SelectedLevel = levelList[43]
        elseif getgenv().Settings.SelectedLevel == "死神第二關" then
            getgenv().Settings.SelectedLevel = levelList[44]
        elseif getgenv().Settings.SelectedLevel == "死神第三關" then
            getgenv().Settings.SelectedLevel = levelList[45]
        elseif getgenv().Settings.SelectedLevel == "死神第四關" then
            getgenv().Settings.SelectedLevel = levelList[46]
        elseif getgenv().Settings.SelectedLevel == "死神第五關" then
            getgenv().Settings.SelectedLevel = levelList[47]
        elseif getgenv().Settings.SelectedLevel == "死神第六關" then
            getgenv().Settings.SelectedLevel = levelList[48]
        elseif getgenv().Settings.SelectedLevel == "死神「無限」" then
            getgenv().Settings.SelectedLevel = levelList[49]
        end
        
        if string.find(getgenv().Settings.SelectedLevel,"infinite",1,true) then
            difficulty = "Hard"
        else
            difficulty = "Normal"
        end



        while getgenv().Settings.TPLevel do
            --進電梯
            client_to_server["request_join_lobby"]:InvokeServer(elevator)
            wait(0.2)
            client_to_server["request_lock_level"]:InvokeServer(elevator, getgenv().Settings.SelectedLevel, friendonly, difficulty)
            wait(0.2)
            client_to_server["request_start_game"]:InvokeServer(elevator)
            wait(1)
        end
    end
end
--------------------------------------函數]



local Main = library:MainFrame(guiName)

local ingameTab = Main:Tab("遊戲內")

local lobbyTab = Main:Tab("大廳")

local recordTab = Main:Tab("錄製v0.24")

local performanceTab = Main:Tab("效能")

Main:ZoomWindow(function(bool)
    getgenv().Settings.ZoomWindow = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
end):Set(getgenv().Settings.ZoomWindow)

ingameTab:Toggle("自動升級角色",function(bool)
    getgenv().Settings.autoupgrade = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.autoupgrade then
        spawn(autoupgrade)
    end
end):Set(getgenv().Settings.autoupgrade)

ingameTab:Toggle("自動投票開始",function(bool)
    getgenv().Settings.votestart = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.votestart then
        spawn(votestart)
    end
end):Set(getgenv().Settings.votestart)


ingameTab:Toggle("自動回大廳",function(bool)
    getgenv().Settings.backtolobby = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.backtolobby then
        spawn(backtolobby)
    end
end):Set(getgenv().Settings.backtolobby)


ingameTab:Toggle("刪除放置阻擋方塊",function(bool)
    getgenv().Settings.DeletePlaceHitbox = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.DeletePlaceHitbox then
        spawn(DeletePlaceHitbox)
    end
end):Set(getgenv().Settings.DeletePlaceHitbox)

---------------------------------------------------------------------------------------------

lobbyTab:Tag("傳送")


lobbyTab:ToggleDropdown("傳送關卡",levelListCN,
function(SelectedLevel)
    getgenv().Settings.SelectedLevel = SelectedLevel
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.TPLevel then
        spawn(TPLevel)
    end
end,
function(bool)
    getgenv().Settings.TPLevel = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.TPLevel then
        spawn(TPLevel)
    end
end):Set(getgenv().Settings.SelectedLevel,getgenv().Settings.TPLevel)


lobbyTab:Toggle("傳送至掛機區",function(bool)
    getgenv().Settings.tptoAFK = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.tptoAFK then
        spawn(tptoAFK)
    end
end):Set(getgenv().Settings.tptoAFK)

-- lobbyTab:Toggle("自動傳送「滷蛋頭無限」",function(bool)
--     getgenv().Settings.AutoToNamek = bool
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
--     if getgenv().Settings.AutoToNamek then
--         spawn(AutoToNamek)
--     end
-- end):Set(getgenv().Settings.AutoToNamek)

lobbyTab:Slider("賣掉全角色的回合",1,250,function(arg)
    getgenv().Settings.SellUnitWave = arg
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))  
end):Set(getgenv().Settings.SellUnitWave)

--[[---------------------------------]]lobbyTab:Line()--[[---------------------------------]]

lobbyTab:Toggle("反掛機踢出",function(bool)
    getgenv().Settings.antiAFK = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.antiAFK then
        spawn(antiAFK)
    end
end):Set(getgenv().Settings.antiAFK)

lobbyTab:Toggle("自動領取任務獎勵",function(bool)
    getgenv().Settings.ClaimQuest = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.ClaimQuest then
        spawn(ClaimQuest)
    end
end):Set(getgenv().Settings.ClaimQuest)

lobbyTab:Toggle("自動領取每日獎勵(Bug)",function(bool)
    getgenv().Settings.ClaimDailyReward = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.ClaimDailyReward then
        spawn(ClaimDailyReward)
    end
end):Set(getgenv().Settings.ClaimDailyReward)

--[[---------------------------------]]lobbyTab:Line()--[[---------------------------------]]

lobbyTab:Button("兌換代碼",function()
    code()
end)

---------------------------------------------------------------------------------------------

recordTab:RecordDropdown("選擇檔案",getgenv().RecordFileList,function(SelectedButton)
    print(SelectedButton)
    getgenv().Settings.SelectedRecordFile = SelectedButton
    print(getgenv().Settings.SelectedRecordFile)
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
end):Set(getgenv().Settings.SelectedRecordFile)

recordTab:Toggle("回放",function(bool)
    getgenv().Settings.Playerback = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.Playerback then
        spawn(Playerback)
    end
end):Set(getgenv().Settings.Playerback)



recordTab:Toggle("Discord結果通知",function(bool)
    getgenv().Settings.DiscordAlert = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.DiscordAlert and FirstDiscordAlert == true then
        FirstDiscordAlert = false
        spawn(DiscordAlert)
    else
        getgenv().Settings.TotalGem = 0
        getgenv().Settings.TotalGold = 0
        getgenv().Settings.TotalXP = 0
        writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    end
end):Set(getgenv().Settings.DiscordAlert)

recordTab:TextBox("錄製檔名稱")

recordTab:Button("創建錄製檔",function()
    spawn(CreateRecordFile)
end)


--[[---------------------------------]]recordTab:Line()--[[---------------------------------]]

recordTab:Toggle("錄製",function(bool)
    getgenv().Settings.Record = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.Record then
        spawn(Record)
    end
end):Set(getgenv().Settings.Record)

-- recordTab:Tag("欄位一：")

-- recordTab:Dropdown("選角色",unitsList(),function(SelectedButton)
--     getgenv().Settings.unit1[1] = SelectedButton["name"].Text
--     getgenv().Settings.unit1[2] = SelectedButton["_uuid"].Value
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
-- end):Set(getgenv().Settings.unit1[1] .. ":" .. getgenv().Settings.unit1[2])

-- recordTab:Tag("欄位二：")

-- recordTab:Dropdown("選角色",unitsList(),function(SelectedButton)
--     getgenv().Settings.unit2[1] = SelectedButton["name"].Text
--     getgenv().Settings.unit2[2] = SelectedButton["_uuid"].Value
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
-- end):Set(getgenv().Settings.unit2[1] .. ":" .. getgenv().Settings.unit2[2])

-- recordTab:Tag("欄位三：")

-- recordTab:Dropdown("選角色",unitsList(),function(SelectedButton)
--     getgenv().Settings.unit3[1] = SelectedButton["name"].Text
--     getgenv().Settings.unit3[2] = SelectedButton["_uuid"].Value
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
-- end):Set(getgenv().Settings.unit3[1] .. ":" .. getgenv().Settings.unit3[2])

-- recordTab:Tag("欄位四：")

-- recordTab:Dropdown("選角色",unitsList(),function(SelectedButton)
--     getgenv().Settings.unit4[1] = SelectedButton["name"].Text
--     getgenv().Settings.unit4[2] = SelectedButton["_uuid"].Value
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
-- end):Set(getgenv().Settings.unit4[1] .. ":" .. getgenv().Settings.unit4[2])

-- recordTab:Tag("欄位五：")

-- recordTab:Dropdown("選角色",unitsList(),function(SelectedButton)
--     getgenv().Settings.unit5[1] = SelectedButton["name"].Text
--     getgenv().Settings.unit5[2] = SelectedButton["_uuid"].Value
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
-- end):Set(getgenv().Settings.unit5[1] .. ":" .. getgenv().Settings.unit5[2])

-- recordTab:Tag("欄位六：")

-- recordTab:Dropdown("選角色",unitsList(),function(SelectedButton)
--     getgenv().Settings.unit6[1] = SelectedButton["name"].Text
--     getgenv().Settings.unit6[2] = SelectedButton["_uuid"].Value
--     writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
-- end):Set(getgenv().Settings.unit6[1] .. ":" .. getgenv().Settings.unit6[2])

performanceTab:Tag("降低CPU使用率")

performanceTab:Toggle("刪除場景、角色物件",function(bool)
    getgenv().Settings.BoostFPS = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.BoostFPS then
        spawn(BoostFPS)
    end
end):Set(getgenv().Settings.BoostFPS)

performanceTab:Toggle("關閉3D渲染",function(bool)
    getgenv().Settings.WindowFocus = bool
    writefile(settingdata,HttpService:JSONEncode(getgenv().Settings))
    if getgenv().Settings.WindowFocus then
        -- local RENDER = true
        -- local UserInputService = game:GetService("UserInputService")
        local RunService = game:GetService("RunService")
        RunService:Set3dRenderingEnabled(false)
    else
        local RunService = game:GetService("RunService")
        RunService:Set3dRenderingEnabled(true)
        -- WindowFocused = UserInputService.WindowFocused:Connect(function()
        --     if RENDER then
        --         RunService:Set3dRenderingEnabled(true)
        --     end
        -- end)

        -- WindowFocusReleased = UserInputService.WindowFocusReleased:Connect(function()
        --     if RENDER then
        --         RunService:Set3dRenderingEnabled(false)
        --     end
        -- end)
    end
end):Set(getgenv().Settings.WindowFocus)

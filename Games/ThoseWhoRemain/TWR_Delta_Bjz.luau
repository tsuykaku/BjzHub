-- TWR / place 8287862132 / Delta Executor
-- Based on the supplied place snapshot. Live Delta/server behavior is untested.
-- UI: gethui only. No Drawing API, namecall hooks, or remote spam.
local URL = 'https://raw.githubusercontent.com/tsuykaku/BjzHub/refs/heads/main/Library/BjzUiLibrary_2.0.luau'
local Env = getgenv()
assert(type(gethui) == 'function', 'Delta 必須提供 gethui()')
local Parent = gethui()
assert(typeof(Parent) == 'Instance', 'gethui() 未回傳 Instance')
local ok, source = pcall(function() return game:HttpGet(URL) end)
assert(ok and type(source) == 'string', 'UI Library 下載失敗：' .. tostring(source))
local chunk, compileError = loadstring(source)
assert(chunk, 'UI Library 編譯失敗：' .. tostring(compileError))
local Library = chunk()
local Players = game:GetService('Players')
local RS = game:GetService('ReplicatedStorage')
local Run = game:GetService('RunService')
local LP = Players.LocalPlayer
local PS = LP:WaitForChild('PlayerScripts')
local function findClient()
    for _, obj in ipairs(PS:GetDescendants()) do
        if obj:IsA('ModuleScript') and obj.Name == 'Client'
            and obj:FindFirstChild('Bullets') and obj:FindFirstChild('Animate') then
            return obj
        end
    end
end
local clientScript = findClient()
assert(clientScript, '找不到 TWR Client 模組；請進入遊戲並完成載入後再執行')
local function loadModule(obj, label)
    assert(obj, '找不到 ' .. label)
    local success, result = pcall(require, obj)
    assert(success and type(result) == 'table', label .. ' 載入失敗：' .. tostring(result))
    return result
end
local Client = loadModule(clientScript, 'Client')
local Bullets = loadModule(clientScript:FindFirstChild('Bullets'), 'Bullets')
local Animate = loadModule(clientScript:FindFirstChild('Animate'), 'Animate')
assert(type(Client.GetPlayerFile) == 'function' and type(Bullets.Fire2) == 'function', '遊戲版本與 place 不一致')
local weaponFolder = RS:WaitForChild('Modules'):WaitForChild('Weapon Modules')
local weapons = {}
for _, obj in ipairs(weaponFolder:GetChildren()) do
    if obj:IsA('ModuleScript') then
        local success, data = pcall(require, obj)
        if success and type(data) == 'table' and type(data.Stats) == 'table'
            and data.Stats.WeaponType == 'Gun' then weapons[obj.Name] = data.Stats end
    end
end
if Env.__TWR_BJZ then Env.__TWR_BJZ.Stop() end
local S = {Ammo=false, Recoil=false, Auto=false, Silent=false, ESP=false,
    FOV=180, Distance=1500, Visible=true, Head=true, ShowFOV=true,
    Extender=false, Limb='Head', LimbSize=5, LimbTransparency=.8, ResetDead=false,
    Items=false, Energy=false, FireRate=false, FireRateMultiplier=1, Wallbang=false, AutoAttack=false, Aim360=false, SkipBossIntro=false, FastBurst=false, ExtraShots=2, Disable3D=false, AdminGuard=true}
local alive, connections, originals, saved, ammoRows = true, {}, {}, {}, {}
local Window
local adminContext,adminParagraph,cancelAdminGuard
local burstRunning=false
local optimization={Scans=0,CacheHits=0,SuppressedFX=0,SuppressedHUD=0,RemovedInstances=0}
local ownedResources=setmetatable({},{__mode='k'})
local function newOwned(className,parent)
    local instance=Instance.new(className)
    ownedResources[instance]=true
    if parent then instance.Parent=parent end
    return instance
end
local function destroyOwned(instance)
    if not instance or not ownedResources[instance] then return end
    local descendants=instance:GetDescendants()
    local success=pcall(function() instance:Destroy() end)
    if not success then return end
    ownedResources[instance]=nil
    optimization.RemovedInstances=optimization.RemovedInstances+1
    for _,child in ipairs(descendants) do
        if ownedResources[child] then
            ownedResources[child]=nil
            optimization.RemovedInstances=optimization.RemovedInstances+1
        end
    end
end
local function destroyAllOwned()
    for instance in pairs(ownedResources) do destroyOwned(instance) end
end
local overlay,circle
local function destroyFOV()
    if overlay then destroyOwned(overlay) end
    overlay,circle=nil,nil
end
local function updateFOV(cam)
    if S.Disable3D or not S.Silent or not S.ShowFOV or S.Aim360 or S.AutoAttack then
        destroyFOV(); return
    end
    if not overlay then
        overlay=newOwned('ScreenGui',Parent)
        overlay.Name='TWR_Overlay'; overlay.IgnoreGuiInset=true
        overlay.ResetOnSpawn=false; overlay.DisplayOrder=20
        circle=newOwned('Frame',overlay)
        circle.AnchorPoint=Vector2.new(.5,.5); circle.BackgroundTransparency=1
        local corner=newOwned('UICorner',circle); corner.CornerRadius=UDim.new(1,0)
        local stroke=newOwned('UIStroke',circle)
        stroke.Color=Color3.fromRGB(255,170,70); stroke.Transparency=.25; stroke.Thickness=1
    end
    circle.Position=UDim2.fromOffset(cam.ViewportSize.X*.5,cam.ViewportSize.Y*.5)
    circle.Size=UDim2.fromOffset(S.FOV*2,S.FOV*2)
end
local markers = {}
local function infectedFolder()
    local entities = workspace:FindFirstChild('Entities')
    return entities and entities:FindFirstChild('Infected')
end
local function valid(model)
    if not model:IsA('Model') or model.Name == 'Escort' then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    local h = model:FindFirstChildOfClass('Humanoid')
    return not (h and h.Health <= 0) and model:FindFirstChild('AI') ~= nil
        and model:FindFirstChild('HumanoidRootPart') ~= nil
end
local function clearMarker(model)
    local m = markers[model]
    if m then destroyOwned(m.h); destroyOwned(m.gui); markers[model]=nil end
end
local function updateMarkers(cam)
    local folder = infectedFolder()
    local seen = {}
    if S.ESP and not S.Disable3D and folder then
        for _, model in ipairs(folder:GetChildren()) do
            if valid(model) then
                local root = model.HumanoidRootPart
                local distance = (root.Position-cam.CFrame.Position).Magnitude
                if distance <= S.Distance then
                    seen[model] = true
                    local m = markers[model]
                    if not m then
                        local h = newOwned('Highlight')
                        h.Adornee=model; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillColor=Color3.fromRGB(255,90,70); h.FillTransparency=.7
                        h.OutlineColor=Color3.fromRGB(255,190,100); h.Parent=Parent
                        local gui = newOwned('BillboardGui')
                        gui.Adornee=root; gui.AlwaysOnTop=true
                        gui.Size=UDim2.fromOffset(170,30); gui.StudsOffset=Vector3.new(0,3.5,0)
                        gui.Parent=Parent
                        local text = newOwned('TextLabel')
                        text.Size=UDim2.fromScale(1,1); text.BackgroundTransparency=1
                        text.TextColor3=Color3.new(1,1,1); text.TextStrokeTransparency=.2
                        text.Font=Enum.Font.GothamBold; text.TextSize=13; text.Parent=gui
                        m={h=h,gui=gui,text=text}; markers[model]=m
                    end
                    local label=string.format('%s  [%d studs]',model.Name,distance)
                    if m.lastText~=label then m.text.Text=label; m.lastText=label end
                end
            end
        end
    end
    for model in pairs(markers) do if not seen[model] then clearMarker(model) end end
end
-- Track only our changes. Never guess original sizes or delete game highlights.
local limbsChanged, itemHighlights, drinksChanged = {}, {}, {}
local function resetLimb(part)
    local original=limbsChanged[part]
    if not original then return end
    pcall(function()
        part.Size=original.Size; part.Transparency=original.Transparency
        part.CanCollide=original.CanCollide; part.Massless=original.Massless
        if original.Mesh and original.Mesh.Parent then original.Mesh.Scale=original.Scale end
    end)
    if original.Highlight then destroyOwned(original.Highlight) end
    limbsChanged[part]=nil
end
local function resetLimbs()
    for part in pairs(limbsChanged) do resetLimb(part) end
end
local function updateLimbs()
    local seen={}
    local folder=infectedFolder()
    if S.Extender and folder then
        for _, model in ipairs(folder:GetChildren()) do
            if model:IsA('Model') and model.Name~='Escort' and not Players:GetPlayerFromCharacter(model) then
                local human=model:FindFirstChildOfClass('Humanoid')
                local part=model:FindFirstChild(S.Limb)
                if part and part:IsA('BasePart') and model:FindFirstChild('AI')
                    and not (S.ResetDead and human and human.Health<=0) then
                    seen[part]=true
                    local original=limbsChanged[part]
                    if not original then
                        local mesh=part:FindFirstChildOfClass('SpecialMesh')
                        original={Size=part.Size,Transparency=part.Transparency,
                            CanCollide=part.CanCollide,Massless=part.Massless,
                            Mesh=mesh,Scale=mesh and mesh.Scale}
                        limbsChanged[part]=original
                    end
                    if S.Disable3D then
                        if original.Highlight then destroyOwned(original.Highlight); original.Highlight=nil end
                    elseif not original.Highlight then
                        local h=newOwned('Highlight',Parent)
                        h.Adornee=part; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                        h.FillColor=Color3.fromRGB(0,140,140); h.FillTransparency=1
                        h.OutlineColor=Color3.new(1,1,1); original.Highlight=h
                    end
                    part.Size=Vector3.new(S.LimbSize,S.LimbSize,S.LimbSize)
                    part.Transparency=S.LimbTransparency
                    part.CanCollide=false; part.Massless=true
                    if original.Mesh and original.Mesh.Parent then
                        original.Mesh.Scale=Vector3.new(1.25,1.25,1.25)
                    end
                end
            end
        end
    end
    for part in pairs(limbsChanged) do if not seen[part] then resetLimb(part) end end
end
local function clearItems()
    for model,h in pairs(itemHighlights) do destroyOwned(h); itemHighlights[model]=nil end
end
local function updateItems()
    local ignore=workspace:FindFirstChild('Ignore')
    local folder=ignore and ignore:FindFirstChild('Items')
    local seen={}
    if S.Items and not S.Disable3D and folder then
        for _,model in ipairs(folder:GetChildren()) do
            if model:IsA('Model') and model:FindFirstChildWhichIsA('BasePart',true) then
                seen[model]=true
                if not itemHighlights[model] then
                    local h=newOwned('Highlight')
                    h.Adornee=model; h.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
                    h.FillColor=Color3.fromRGB(0,255,100); h.FillTransparency=.5
                    h.OutlineColor=h.FillColor; h.Parent=Parent
                    itemHighlights[model]=h
                end
            end
        end
    end
    for model,h in pairs(itemHighlights) do
        if not seen[model] then destroyOwned(h); itemHighlights[model]=nil end
    end
end
local function resetDrinks()
    for value,original in pairs(drinksChanged) do
        pcall(function() value.Value=original.Value end)
        drinksChanged[value]=nil
    end
end
local function updateEnergy()
    local character=LP.Character
    local value=character and character:FindFirstChild('Drinked')
    for old,original in pairs(drinksChanged) do
        if old~=value then
            pcall(function() old.Value=original.Value end)
            drinksChanged[old]=nil
        end
    end
    if S.Energy and value and value:IsA('BoolValue') then
        if not drinksChanged[value] then drinksChanged[value]={Value=value.Value} end
        value.Value=true
    elseif not S.Energy then resetDrinks() end
end
local function clearVisualResources()
    for model in pairs(markers) do clearMarker(model) end
    clearItems()
    for _,original in pairs(limbsChanged) do
        if original.Highlight then destroyOwned(original.Highlight); original.Highlight=nil end
    end
    destroyFOV()
end
local function cleanupResources()
    if S.Disable3D then clearVisualResources() end
    local ignore=workspace:FindFirstChild('Ignore')
    local items=ignore and ignore:FindFirstChild('Items')
    for model in pairs(markers) do
        if not model.Parent or not model:IsDescendantOf(workspace) then clearMarker(model) end
    end
    for model,h in pairs(itemHighlights) do
        if not model.Parent or model.Parent~=items then destroyOwned(h); itemHighlights[model]=nil end
    end
    for part in pairs(limbsChanged) do
        if not part.Parent or not part:IsDescendantOf(workspace) then resetLimb(part) end
    end
    -- Only unparented resources created by this script are eligible here.
    for instance in pairs(ownedResources) do
        if not instance.Parent then destroyOwned(instance) end
    end
end
local targetCache={}
local function target(origin,allDirections)
    local cam=workspace.CurrentCamera
    local folder=infectedFolder()
    if not cam or not folder then return end
    allDirections=allDirections or S.Aim360
    local now=os.clock()
    if targetCache.time and now-targetCache.time<.05
        and targetCache.all==allDirections and targetCache.head==S.Head
        and targetCache.visible==S.Visible and targetCache.wall==S.Wallbang
        and targetCache.distance==S.Distance and targetCache.fov==S.FOV
        and (origin-targetCache.origin).Magnitude<3
        and (allDirections or cam.CFrame.LookVector:Dot(targetCache.look)>.999) then
        local part=targetCache.part
        if not part or (part.Parent and valid(part.Parent) and (part.Position-origin).Magnitude<=S.Distance) then
            optimization.CacheHits=optimization.CacheHits+1
            return part
        end
    end
    optimization.Scans=optimization.Scans+1
    local best, score=nil,allDirections and math.huge or S.FOV
    local center=cam.ViewportSize*.5
    for _, model in ipairs(folder:GetChildren()) do
        if valid(model) then
            local part=(S.Head and model:FindFirstChild('Head')) or model:FindFirstChild('HumanoidRootPart')
            if part and part:IsA('BasePart') and (part.Position-origin).Magnitude<=S.Distance then
                local delta,eligible
                if allDirections then
                    delta=(part.Position-origin).Magnitude
                    eligible=true
                else
                    local point,onScreen=cam:WorldToViewportPoint(part.Position)
                    delta=(Vector2.new(point.X,point.Y)-center).Magnitude
                    eligible=onScreen
                end
                if eligible and delta<score then
                    local visible=true
                    if S.Visible and not S.Wallbang then
                        local params=RaycastParams.new()
                        params.FilterType=Enum.RaycastFilterType.Exclude
                        local exclude={folder}
                        if LP.Character then table.insert(exclude,LP.Character) end
                        local ignore=workspace:FindFirstChild('Ignore')
                        if ignore then table.insert(exclude,ignore) end
                        params.FilterDescendantsInstances=exclude
                        visible=workspace:Raycast(origin,part.Position-origin,params)==nil
                    end
                    if visible then best,score=part,delta end
                end
            end
        end
    end
    targetCache={time=now,origin=origin,look=cam.CFrame.LookVector,part=best,
        all=allDirections,head=S.Head,visible=S.Visible,wall=S.Wallbang,distance=S.Distance,fov=S.FOV}
    return best
end
-- Align both the shot frame and travel direction. The original Fire2 derives
-- a backward start offset from this frame; changing direction alone can skew
-- the initial segment when the view points straight up/down.
local function aimShot(cf,allDirections)
    local part=target(cf.Position,allDirections)
    if not part then return cf,nil end
    local delta=part.Position-cf.Position
    if delta.Magnitude<=.001 then return cf,nil end
    local direction=delta.Unit
    local up=Vector3.new(0,1,0)
    -- Avoid a degenerate lookAt basis for almost vertical target directions.
    if math.abs(direction:Dot(up))>.98 then up=Vector3.new(1,0,0) end
    return CFrame.lookAt(cf.Position,part.Position,up),direction
end
local autoAttackReady=type(Client.SetMouse1Down)=='function' and type(Client.SetMouse1Up)=='function'
local autoHolding=false
local autoRenderName="TWR_AutoFire_"..tostring(LP.UserId)
local function releaseAutoAttack()
    if autoHolding then
        autoHolding=false
        pcall(Client.SetMouse1Up)
    end
end
local function updateAutoAttack(dt)
    if not alive or not S.AutoAttack or not autoAttackReady then releaseAutoAttack(); return end
    local file=Client.GetPlayerFile()
    local character=LP.Character
    local human=character and character:FindFirstChildOfClass('Humanoid')
    local stats=file and file.WeaponModule and file.WeaponModule.Stats
    if not human or human.Health<=0 or not file.Equipped or not stats or stats.WeaponType~='Gun' then
        releaseAutoAttack(); return
    end
    local model=file.Objs and file.Objs.WeaponModel
    local muzzle=model and model:FindFirstChild('Pos')
    local cam=workspace.CurrentCamera
    local origin=muzzle and muzzle.Position or (cam and cam.CFrame.Position)
    if not origin or not target(origin,true) then releaseAutoAttack(); return end
    -- Preserve the held-fire state during cycling/reloads, as physical input does.
    -- Do not send another down event while busy: it can cancel the reload.
    local sequence=file.SequenceWhole
    if sequence and (sequence.Reload or sequence.Equip or sequence.BasicEquip or sequence.Sliding) then return end
    autoHolding=true
    -- Let the native handler and held-fire loop own RPM timing. No second timer.
    -- The game's input handler enforces its firing interval and weapon behavior.
    -- Repeated presses also support semi-auto and resume after weapon changes.
    local success=pcall(Client.SetMouse1Down)
    if not success then releaseAutoAttack() end
end
local function patch(tbl,key,value)
    if not saved[tbl] then saved[tbl]={} end
    if saved[tbl][key]==nil then saved[tbl][key]={value=rawget(tbl,key)} end
    tbl[key]=value
end
local function restore(tbl,key)
    local entry=saved[tbl] and saved[tbl][key]
    if entry then tbl[key]=entry.value; saved[tbl][key]=nil end
end
local rateCheckReady=false
local function applyStats()
    for _, stats in pairs(weapons) do
        for _, key in ipairs({'VerticleRecoil','HorizontalRecoil','RecoilShake'}) do
            if S.Recoil then patch(stats,key,0) else restore(stats,key) end
        end
        if S.Auto then
            local base=saved[stats] and saved[stats].Type
            local mode=base and base.value or stats.Type
            if mode=='Semi' or mode=='Shotgun' then
                patch(stats,'Type',mode=='Shotgun' and 'AutoShotgun' or 'Auto')
            end
        else restore(stats,'Type') end
        if S.FireRate and rateCheckReady and type(stats.RPM)=='number' and stats.RPM>0 then
            local original=saved[stats] and saved[stats].RPM
            local baseRPM=original and original.value or stats.RPM
            patch(stats,'RPM',baseRPM*S.FireRateMultiplier)
        else restore(stats,'RPM') end
    end
end
-- The supplied Client RF callback reports weapon RPM through GetCC.
-- Keep that report consistent with the original weapon definition.
-- This addresses this client callback only, not server-side shot timing checks.
local function reportBaseRPM(result)
    if type(result)~='table' or type(result.WC)~='table' then return result end
    local copy=table.clone(result)
    copy.WC=table.clone(result.WC)
    for name,row in pairs(result.WC) do
        local stats=weapons[name]
        local entry=stats and saved[stats] and saved[stats].RPM
        if type(row)=='table' and entry then
            local weaponReport=table.clone(row)
            weaponReport.RPM=entry.value
            copy.WC[name]=weaponReport
        end
    end
    return copy
end
local checkRemote=RS:FindFirstChild('RF')
local function getCallback(remote)
    if type(getcallbackvalue)=='function' then
        local success,callback=pcall(getcallbackvalue,remote,'OnClientInvoke')
        if success and type(callback)=='function' then return callback end
    end
    local success,callback=pcall(function() return remote.OnClientInvoke end)
    if success and type(callback)=='function' then return callback end
end
local rateCallback,rateWrapper
if checkRemote and checkRemote:IsA('RemoteFunction') then
    rateCallback=getCallback(checkRemote)
    if rateCallback then
        rateWrapper=function(command,...)
            local results=table.pack(rateCallback(command,...))
            if alive and command=='GetCC' then results[1]=reportBaseRPM(results[1]) end
            return table.unpack(results,1,results.n)
        end
        local success=pcall(function() checkRemote.OnClientInvoke=rateWrapper end)
        rateCheckReady=success
    end
end
-- Prefer the live inventory passed to UpdateHUD; getgc is an initial fallback.
local inventory, refillQueued, fallbackScanAt = nil, false, 0
local function refillRow(row)
    if type(row)~='table' or (table.isfrozen and table.isfrozen(row)) then return end
    local name=rawget(row,'Name')
    local stats=type(name)=='string' and weapons[name]
    if not stats then return end
    local mag,pool=rawget(row,'Mag'),rawget(row,'Pool')
    -- Use the current weapon stats, never an old row -> stats association.
    if type(mag)=='number' and type(stats.Mag)=='number' and mag<stats.Mag then row.Mag=stats.Mag end
    if type(pool)=='number' and type(stats.Pool)=='number' and pool<stats.Pool then row.Pool=stats.Pool end
end
local function refillAmmo()
    if not alive or not S.Ammo then return end
    if inventory then
        for _,row in pairs(inventory) do refillRow(row) end
    else
        for _,item in ipairs(ammoRows) do refillRow(item.row) end
    end
end
local function queueRefill()
    if not alive or not S.Ammo or refillQueued then return end
    refillQueued=true
    -- Resume after the shooting caller finishes its synchronous consumption checks.
    -- Never refill synchronously inside Fire2 or UpdateHUD.
    task.defer(function()
        refillQueued=false
        refillAmmo()
    end)
end
local function scanAmmo()
    if inventory then
        local count=0
        for _,row in pairs(inventory) do
            if type(row)=='table' and weapons[rawget(row,'Name')] then count=count+1 end
        end
        refillAmmo()
        return count>0,'即時彈藥資料：'..count..' 筆'
    end
    if type(getgc)~='function' then return false,'等待裝備槍枝，以取得即時彈藥資料' end
    local success,objects=pcall(getgc,true)
    if not success then return false,tostring(objects) end
    local found={}
    for _,obj in ipairs(objects) do
        if type(obj)=='table' then
            local name=rawget(obj,'Name')
            if type(name)=='string' and weapons[name] and type(rawget(obj,'Mag'))=='number'
                and type(rawget(obj,'Pool'))=='number' and rawget(obj,'WeaponType')==nil
                and not (table.isfrozen and table.isfrozen(obj)) then
                found[#found+1]={row=obj}
            end
        end
    end
    ammoRows=found
    refillAmmo()
    return #found>0,'備援彈藥資料：'..#found..' 筆；裝備槍枝後自動接管即時資料'
end
local guiScript=clientScript:FindFirstChild('Gui')
if guiScript then
    local success,guiModule=pcall(require,guiScript)
    if success and type(guiModule)=='table' and type(guiModule.UpdateHUD)=='function' then
        local original=guiModule.UpdateHUD
        local wrapper=function(file,data,gui,rows,...)
            if alive and file==Client.GetPlayerFile() and type(rows)=='table' then
                inventory=rows
                ammoRows={} -- Drop stale respawn/loadout snapshots.
                queueRefill()
                if burstRunning then optimization.SuppressedHUD=optimization.SuppressedHUD+1; return end
            end
            return original(file,data,gui,rows,...)
        end
        guiModule.UpdateHUD=wrapper
        originals[#originals+1]={guiModule,'UpdateHUD',original,wrapper}
    end
end
-- Experimental additional native shots. Resolve the original module environment;
-- never substitute a different function or manufacture damage messages.
local function resolveFireCore()
    if type(getfenv)~='function' then return nil,'Delta 不提供 getfenv' end
    local function owns(candidate)
        if type(candidate)~='function' then return false end
        local success,environment=pcall(getfenv,candidate)
        if not success or type(environment)~='table' then return false end
        -- script may be inherited through the environment metatable.
        local matched,owner=pcall(function() return environment.script end)
        return matched and owner==clientScript
    end
    for _,export in ipairs({Client.SetMouse1Down,Client.GetPlayerFile}) do
        if type(export)=='function' then
            local success,environment=pcall(getfenv,export)
            if success and type(environment)=='table' then
                local found,candidate=pcall(function() return environment.Fire2 end)
                if found and owns(candidate) then return candidate,'模組環境' end
            end
        end
    end
    -- Some builds keep Fire2 local instead of exporting it into the environment.
    if type(getgc)=='function' then
        local success,objects=pcall(getgc,true)
        if success then
            for _,candidate in ipairs(objects) do
                if owns(candidate) then
                    local named,name=pcall(function() return debug.info(candidate,'n') end)
                    if named and name=='Fire2' then
                        local known,arity=pcall(function() return debug.info(candidate,'a') end)
                        if not known or arity==10 then return candidate,'本機模組函式' end
                    end
                end
            end
        end
    end
    return nil,'找不到此 Client 的原始 Fire2'
end
local nativeFireCore,burstResolveStatus=resolveFireCore()
local burstDiag={Base=0,Calls=0,Projectiles=0,Skipped=0,Reason='等待射擊',Elapsed=0,Weapon='尚未射擊'}
local burstStatus
local burstQueued=false
local function skipBurst(reason)
    burstDiag.Skipped=burstDiag.Skipped+1
    burstDiag.Reason=reason
end
local function updateBurstStatus(dt)
    burstDiag.Elapsed=burstDiag.Elapsed+dt
    if not burstStatus or burstDiag.Elapsed<.5 then return end
    burstDiag.Elapsed=0
    burstStatus:Set('加速連射執行狀態',string.format(
        '原始函式：%s\n目前武器：%s\n正常子彈：%d｜追加呼叫：%d｜追加本機子彈：%d\n略過：%d｜%s\n本機子彈計數不代表伺服器已接受傷害。',
        nativeFireCore and ('可用（'..burstResolveStatus..'）') or burstResolveStatus,
        burstDiag.Weapon,burstDiag.Base,burstDiag.Calls,burstDiag.Projectiles,burstDiag.Skipped,burstDiag.Reason))
end
local burstToggle
local function queueBurst(data,file,cf,direction)
    if burstRunning or burstQueued or not alive or not S.FastBurst or not nativeFireCore
        or not file or file.player~=LP then return end
    local weapon=file.WeaponModule
    local stats=weapon and weapon.Stats
    local slot=file.Equipped
    local activeRow=inventory and inventory[slot]
    local weaponName=type(activeRow)=='table' and rawget(activeRow,'Name') or file.EquipName
    burstDiag.Weapon=string.format('%s | WeaponType=%s | Type=%s | BoltAction=%s',
        tostring(weaponName or '?'),tostring(stats and stats.WeaponType),
        tostring(stats and stats.Type),tostring(stats and stats.BoltAction))
    local supported=stats and (stats.Type=='Auto' or stats.Type=='Semi'
        or stats.Type=='Shotgun' or stats.Type=='AutoShotgun')
    if not stats or stats.WeaponType~='Gun' or not supported then
        skipBurst('不支援此射擊流程：'..tostring(stats and stats.Type)); return
    end
    if stats.BoltAction then skipBurst('栓動槍需要獨立的拉栓流程，暫不追加'); return end
    burstQueued=true
    task.defer(function()
        burstQueued=false
        if not alive or not S.FastBurst or file~=Client.GetPlayerFile()
            or file.WeaponModule~=weapon or file.Equipped~=slot then skipBurst('已關閉或切換武器'); return end
        local row=inventory and inventory[slot]
        if type(row)~='table' or weapons[rawget(row,'Name')]~=stats then skipBurst('尚未取得目前武器的即時彈藥表'); return end
        local character=LP.Character
        local human=character and character:FindFirstChildOfClass('Humanoid')
        if not human or human.Health<=0 then skipBurst('角色未存活'); return end
        local sequence=file.SequenceWhole
        -- OnFire starts Sliding on ordinary guns too; it is not a reload lock.
        -- BoltAction was checked separately above. Keep actual reload/equip guards.
        if sequence and sequence.Reload then skipBurst('正在換彈（Reload）'); return end
        if sequence and sequence.Equip then skipBurst('正在裝備（Equip）'); return end
        if sequence and sequence.BasicEquip then skipBurst('正在裝備（BasicEquip）'); return end
        local count=math.clamp(math.floor(S.ExtraShots),1,100)
        burstRunning=true
        local success,message=pcall(function()
            for _=1,count do
                if not alive or not S.FastBurst or file.WeaponModule~=weapon or file.Equipped~=slot then break end
                if S.Ammo then refillRow(row) end
                if type(row.Mag)~='number' or row.Mag<1 then skipBurst('彈匣不足；追加發射仍會消耗子彈'); break end
                row.Mag=row.Mag-1
                local currentCF=cf
                local model=file.Objs and file.Objs.WeaponModel
                local muzzle=model and model:FindFirstChild('Pos')
                if muzzle then currentCF=muzzle.CFrame end
                local currentDirection=direction
                if S.Silent or S.AutoAttack then
                    local aligned,desired=aimShot(currentCF,S.AutoAttack)
                    if desired then currentCF,currentDirection=aligned,desired end
                end
                local recoilScale=data.Perks and data.Perks.Marksman
                    and data.Perks.Marksman['Steady Hand'] and .5 or 1
                local pellets
                if stats.Type=='Shotgun' or stats.Type=='AutoShotgun' then
                    -- Native Fire2 expects eight {roll, spread} angle pairs, not nil.
                    -- Consume one shell per native shot, preserving its pellet pattern.
                    pellets={}
                    local states=file.States
                    local aimed=states and states[#states]=='Aim'
                    local spread=type(stats.Spread)=='number' and math.max(stats.Spread,0) or 0
                    local scale=aimed and .5 or 1
                    for pellet=1,8 do
                        pellets[pellet]={math.rad(math.random(0,360)),
                            math.rad((math.random()*2-1)*spread*scale)}
                    end
                end
                nativeFireCore(data,file,math.random(-1,1),row.Mag,currentCF,pellets,
                    currentDirection,true,recoilScale,data.Options and data.Options.TracerNum)
                burstDiag.Calls=burstDiag.Calls+1
                burstDiag.Reason='已執行追加射擊；請比較目標血量變化'
            end
        end)
        burstRunning=false
        queueRefill()
        if not success then
            S.FastBurst=false
            burstDiag.Reason='射擊函式錯誤：'..tostring(message)
            if burstToggle then burstToggle:Set(false,true) end
            Window:Notify({Title='加速連射已停止',Content='原始射擊函式執行失敗：'..tostring(message)})
        end
    end)
end
local shotDataCache=setmetatable({},{__mode='k'})
local function dataForShot(data)
    if type(data)~='table' or type(data.Options)~='table' or (not S.Disable3D and not burstRunning) then return data end
    local now=os.clock()
    local cached=shotDataCache[data]
    if cached and cached.options==data.Options and cached.minimal==S.Disable3D and now-cached.time<.25 then
        return cached.value
    end
    local copy=table.clone(data)
    copy.Options=table.clone(data.Options)
    copy.Options.BulletTracers=false
    if S.Disable3D then
        copy.Options.BloodEffects=false; copy.Options.BloodStains=false; copy.Options.BulletHoles=false
    end
    shotDataCache[data]={value=copy,options=data.Options,minimal=S.Disable3D,time=now}
    return copy
end
local fireOriginal=Bullets.Fire2
local fireWrapper=function(data,gui,file,cf,direction,...)
    if alive and file and file.player==LP then queueRefill() end
    if alive and (S.Silent or S.AutoAttack) and file and file.player==LP and typeof(cf)=='CFrame' then
        if burstRunning then
            direction=cf.LookVector -- Already aligned once before this shot's pellets.
        else
            local aligned,desired=aimShot(cf,S.AutoAttack)
            if desired then cf,direction=aligned,desired end
        end
    end
    local results=table.pack(fireOriginal(dataForShot(data),gui,file,cf,direction,...))
    if file and file.player==LP then
        if burstRunning then burstDiag.Projectiles=burstDiag.Projectiles+1
        else burstDiag.Base=burstDiag.Base+1 end
    end
    queueBurst(data,file,cf,direction)
    return table.unpack(results,1,results.n)
end
Bullets.Fire2=fireWrapper
originals[#originals+1]={Bullets,'Fire2',fireOriginal,fireWrapper}
if type(Animate.RecoilCamera)=='function' then
    local original=Animate.RecoilCamera
    local wrapper=function(file,...)
        if alive and file==Client.GetPlayerFile() then queueRefill() end
        if alive and (S.Recoil or burstRunning) and file==Client.GetPlayerFile() then return end
        return original(file,...)
    end
    Animate.RecoilCamera=wrapper
    originals[#originals+1]={Animate,'RecoilCamera',original,wrapper}
end
if type(Animate.OnFire)=='function' then
    local original=Animate.OnFire
    local wrapper=function(camera,data,file,...)
        if alive and burstRunning and file and file.player==LP then
            optimization.SuppressedFX=optimization.SuppressedFX+1
            return
        end
        return original(camera,data,file,...)
    end
    Animate.OnFire=wrapper
    originals[#originals+1]={Animate,'OnFire',original,wrapper}
end
if type(Animate.Flash)=='function' then
    local original=Animate.Flash
    local wrapper=function(file,...)
        if alive and burstRunning and file and file.player==LP then
            optimization.SuppressedFX=optimization.SuppressedFX+1
            return
        end
        return original(file,...)
    end
    Animate.Flash=wrapper
    originals[#originals+1]={Animate,'Flash',original,wrapper}
end
-- Modify the local bullet collision filter, never the map parts themselves.
local wallFilters=setmetatable({},{__mode='k'})
local wallbangReady=false
local function restoreBulletWalls(bullet)
    local entry=wallFilters[bullet]
    if not entry then return end
    -- Remove only roots inserted by this feature; keep normal hit exclusions.
    for i=#entry.list,1,-1 do
        if entry.added[entry.list[i]] then table.remove(entry.list,i) end
    end
    wallFilters[bullet]=nil
end
local function clearBulletWalls()
    for bullet in pairs(wallFilters) do restoreBulletWalls(bullet) end
end
local function updateBulletWalls(bullet)
    if not alive or not S.Wallbang or bullet.player~=LP then
        restoreBulletWalls(bullet)
        return
    end
    if type(bullet.igList)~='table' then return end
    local entry=wallFilters[bullet]
    if entry and entry.list~=bullet.igList then restoreBulletWalls(bullet); entry=nil end
    if not entry then
        entry={list=bullet.igList,added={}}
        wallFilters[bullet]=entry
    end
    for _,name in ipairs({'Map','World','Terrain'}) do
        local root=workspace:FindFirstChild(name)
        if root and not table.find(entry.list,root) then
            entry.list[#entry.list+1]=root
            entry.added[root]=true
        end
    end
end
local localModules=clientScript.Parent:FindFirstChild('Modules')
local other=localModules and localModules:FindFirstChild('Other')
local bulletScript=other and other:FindFirstChild('Bullet')
if bulletScript then
    local success,bulletModule=pcall(require,bulletScript)
    if success and type(bulletModule)=='table' and type(bulletModule.Update)=='function' then
        local original=bulletModule.Update
        local wrapper=function(bullet,...)
            updateBulletWalls(bullet)
            return original(bullet,...)
        end
        bulletModule.Update=wrapper
        originals[#originals+1]={bulletModule,'Update',original,wrapper}
        if type(bulletModule.End)=='function' then
            local endOriginal=bulletModule.End
            local endWrapper=function(bullet,...)
                local results=table.pack(endOriginal(bullet,...))
                restoreBulletWalls(bullet)
                return table.unpack(results,1,results.n)
            end
            bulletModule.End=endWrapper
            originals[#originals+1]={bulletModule,'End',endOriginal,endWrapper}
        end
        wallbangReady=true
    end
end
-- Suppress only the local intro deadline. The server's boss state is untouched.
-- Leave BossOutroEnds alone so victory/outro behavior remains available.
local introCaptured,introDeadline,introWriting=false,nil,false
local function restoreBossIntro()
    if not introCaptured then return end
    local deadline=introDeadline
    introCaptured=false; introDeadline=nil
    introWriting=true
    workspace:SetAttribute('BossIntroEnds',deadline)
    introWriting=false
end
local function updateBossIntro()
    if not alive or not S.SkipBossIntro then restoreBossIntro(); return end
    if not introCaptured then
        introDeadline=workspace:GetAttribute('BossIntroEnds')
        introCaptured=true
    end
    if workspace:GetAttribute('BossIntroEnds')~=0 then
        introWriting=true
        workspace:SetAttribute('BossIntroEnds',0)
        introWriting=false
    end
end
connections[#connections+1]=workspace:GetAttributeChangedSignal('BossIntroEnds'):Connect(function()
    if introWriting or not alive or not S.SkipBossIntro then return end
    -- Retain each new server deadline, including a server reset to zero.
    introDeadline=workspace:GetAttribute('BossIntroEnds')
    introCaptured=true
    updateBossIntro()
end)
local renderControl
local function applyRendering()
    local success,message=pcall(function() Run:Set3dRenderingEnabled(not S.Disable3D) end)
    if not success then
        S.Disable3D=false
        if renderControl then renderControl:Set(false,true) end
        pcall(function() Run:Set3dRenderingEnabled(true) end)
        if Window and not Window.bDestroyed then
            Window:Notify({Title='3D 渲染切換失敗',Content=tostring(message)})
        end
    end
    if success and S.Disable3D then clearVisualResources() end
    return success
end
local function collectDebug()
    local success,file=pcall(Client.GetPlayerFile)
    if not success or type(file)~='table' then file={} end
    local stats=file.WeaponModule and file.WeaponModule.Stats or {}
    local row=inventory and inventory[file.Equipped]
    local sequences={}
    for key,value in pairs(file.SequenceWhole or {}) do
        if value then sequences[#sequences+1]=tostring(key) end
    end
    table.sort(sequences)
    local settings={}
    for key,value in pairs(S) do settings[key]=value end
    local clipboard=Env.setclipboard or setclipboard or Env.toclipboard or toclipboard
    local visualCount=0
    for _ in pairs(ownedResources) do visualCount=visualCount+1 end
    return {
        Build='TWR-admin-guard-1',PlaceId=game.PlaceId,
        AdminGuard={Enabled=S.AdminGuard,GroupId=2838077,
            Checked=adminContext and adminContext.Checked or 0,
            QueryFailures=adminContext and adminContext.Failures or 0,
            LastError=adminContext and adminContext.LastError,
            Status=adminContext and adminContext.Status,
            Detected=adminContext and adminContext.Detected},
        Optimization={TargetScans=optimization.Scans,TargetCacheHits=optimization.CacheHits,
            SuppressedExtraEffects=optimization.SuppressedFX,SuppressedExtraHUD=optimization.SuppressedHUD,
            RemovedInstances=optimization.RemovedInstances,LiveVisualInstances=visualCount,CacheSeconds=.05,
            ESPWhile3DDisabled=false},
        Burst={Enabled=S.FastBurst,ExtraShots=S.ExtraShots,
            CoreAvailable=nativeFireCore~=nil,CoreSource=burstResolveStatus,
            NormalProjectiles=burstDiag.Base,AdditionalCalls=burstDiag.Calls,
            AdditionalLocalProjectiles=burstDiag.Projectiles,Skipped=burstDiag.Skipped,
            LastReason=burstDiag.Reason,WeaponSummary=burstDiag.Weapon,
            Queued=burstQueued,Running=burstRunning},
        Weapon={Name=type(row)=='table' and row.Name or file.EquipName,
            Slot=file.Equipped,WeaponType=stats.WeaponType,Type=stats.Type,
            BoltAction=stats.BoltAction,RPM=stats.RPM,Rechambered=file.Rechambered,
            Mag=type(row)=='table' and row.Mag,Pool=type(row)=='table' and row.Pool,
            ActiveAnimations=sequences,LiveInventory=inventory~=nil},
        Capabilities={Clipboard=type(clipboard)=='function',GetGC=type(getgc)=='function',
            GetFenv=type(getfenv)=='function',RateCheck=rateCheckReady,
            Wallbang=wallbangReady,AutoAttack=autoAttackReady},
        Settings=settings,
        Note='Local projectile counts do not confirm server-accepted damage.'
    }
end
local function copyDebug()
    local success,report=pcall(function()
        return game:GetService('HttpService'):JSONEncode(collectDebug())
    end)
    if not success then
        Window:Notify({Title='Debug 匯出失敗',Content=tostring(report)})
        return
    end
    local clipboard=Env.setclipboard or setclipboard or Env.toclipboard or toclipboard
    if type(clipboard)=='function' then
        local copied,message=pcall(clipboard,report)
        if copied then
            Window:Notify({Title='已複製 Debug 資訊',Content='可直接貼到對話中，包含連射計數、武器、動畫與設定。'})
            return
        end
    end
    warn('[TWR Debug] '..report)
    Window:Notify({Title='無法寫入剪貼簿',Content='Debug 已輸出至執行器主控台，可從主控台複製。'})
end
local function stop()
    if not alive then return end
    if cancelAdminGuard then cancelAdminGuard() end
    releaseAutoAttack()
    Run:UnbindFromRenderStep(autoRenderName)
    pcall(function() Run:Set3dRenderingEnabled(true) end)
    alive=false
    inventory=nil; ammoRows={}
    if rateCheckReady and checkRemote then
        local current=getCallback(checkRemote)
        if current==rateWrapper then pcall(function() checkRemote.OnClientInvoke=rateCallback end) end
    end
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, item in ipairs(originals) do
        if item[1][item[2]]==item[4] then item[1][item[2]]=item[3] end
    end
    for tbl, fields in pairs(saved) do
        for key, entry in pairs(fields) do tbl[key]=entry.value end
    end
    for model in pairs(markers) do clearMarker(model) end
    resetLimbs(); clearItems(); resetDrinks(); clearBulletWalls(); restoreBossIntro()
    destroyFOV(); destroyAllOwned()
    targetCache={}; shotDataCache=setmetatable({},{__mode='k'})
    if Window and not Window.bDestroyed then Window:Destroy() end
    Env.__TWR_BJZ=nil
end
-- Group-based local exit rule. Non-members and Member-only users are allowed.
-- The modern roles API checks every assigned role, not just one legacy rank.
local ADMIN_GROUP_ID=2838077
local GroupService=game:GetService('GroupService')
local adminStatusTime=0
local function classifyAdminRoles(result)
    if type(result)~='table' or type(result.IsMember)~='boolean' then return nil,'群組回傳格式無效' end
    if not result.IsMember then return 'nonmember' end
    if type(result.Roles)~='table' or #result.Roles==0 then return nil,'社群成員缺少角色資料' end
    for _,role in ipairs(result.Roles) do
        if type(role)~='table' or type(role.Name)~='string' or type(role.Rank)~='number'
            or role.Name=='' or role.Rank<=0 then return nil,'角色名稱或等級資料無效' end
        local normalized=string.lower((role.Name:gsub('^%s+',''):gsub('%s+$','')))
        if normalized=='' then return nil,'角色名稱為空白' end
        if normalized~='member' then return 'staff',role.Name,role.Rank end
    end
    return 'member'
end
local function adminCheckActive(context,player)
    return alive and S.AdminGuard and context==adminContext and context.Active
        and (not player or (player~=LP and player.Parent==Players))
end
cancelAdminGuard=function()
    local context=adminContext
    if not context then return end
    context.Active=false
    context.Status=context.Detected and '已偵測到指定階層，正在退出' or '偵測已關閉'
    for timer in pairs(context.Timers) do
        pcall(task.cancel,timer)
        context.Timers[timer]=nil
    end
    context.Queue={}; context.Pending={}
end
local enqueueAdminCheck
local function inspectAdminPlayer(context,player)
    for attempt=1,3 do
        if not adminCheckActive(context,player) then return end
        local success,result=pcall(function()
            return GroupService:GetRolesInGroupAsync(player.UserId,ADMIN_GROUP_ID)
        end)
        if not adminCheckActive(context,player) then return end
        local category,name,rank
        if success then category,name,rank=classifyAdminRoles(result) end
        if category then
            context.Checked=context.Checked+1
            context.Records[player.UserId]={Category=category,Role=name,Rank=rank}
            if category=='staff' and not context.Detected then
                context.Detected={Name=player.Name,UserId=player.UserId,Role=name,Rank=rank}
                context.Status='偵測到 '..player.Name..'（'..name..'）'
                local message=string.format('[TWR] 偵測到社群 %d 的非 Member 階層，已自動退出。\n%s (@%s)｜%s｜Rank %d',
                    ADMIN_GROUP_ID,player.DisplayName,player.Name,name,rank)
                pcall(stop)
                local kicked,kickError=pcall(function() LP:Kick(message) end)
                if not kicked then warn('[TWR AdminGuard] 無法退出：'..tostring(kickError)) end
            else
                context.Status='已檢查 '..context.Checked..' 位玩家，監看新加入玩家'
            end
            return
        end
        context.Failures=context.Failures+1
        context.LastError=success and tostring(name) or tostring(result)
        context.Status='查詢失敗，重試 '..attempt..'/3'
        if attempt<3 then task.wait(attempt) end
    end
    if not adminCheckActive(context,player) then return end
    context.Status='部分玩家尚未確認，10 秒後重試'
    if not context.Warned and Window and not Window.bDestroyed then
        context.Warned=true
        Window:Notify({Title='社群階層查詢暫時失敗',Content='不會因查詢失敗而誤判；背景將重試，可複製 Debug 查看原因。'})
    end
    local timer
    timer=task.delay(10,function()
        context.Timers[timer]=nil
        if adminCheckActive(context,player) then enqueueAdminCheck(context,player,true) end
    end)
    context.Timers[timer]=true
end
local function pumpAdminChecks(context)
    while adminCheckActive(context) and context.Workers<3 and context.Queue[context.Head] do
        context.Workers=context.Workers+1
        task.spawn(function()
            while adminCheckActive(context) do
                local player=context.Queue[context.Head]
                if not player then break end
                context.Queue[context.Head]=false; context.Head=context.Head+1
                if adminCheckActive(context,player) then inspectAdminPlayer(context,player) end
                context.Pending[player]=nil
            end
            context.Workers=context.Workers-1
        end)
    end
end
enqueueAdminCheck=function(context,player,priority)
    if not adminCheckActive(context,player) or context.Pending[player] or context.Records[player.UserId] then return end
    context.Pending[player]=true
    if context.Head>#context.Queue then context.Queue={}; context.Head=1 end
    if priority then table.insert(context.Queue,context.Head,player)
    else context.Queue[#context.Queue+1]=player end
    pumpAdminChecks(context)
end
local function applyAdminGuard()
    if cancelAdminGuard then cancelAdminGuard() end
    if not alive or not S.AdminGuard then return end
    local context={Active=true,Queue={},Head=1,Pending={},Records={},Timers={},Workers=0,
        Checked=0,Failures=0,Status='正在檢查目前伺服器玩家'}
    adminContext=context
    for _,player in ipairs(Players:GetPlayers()) do enqueueAdminCheck(context,player) end
end
local function updateAdminStatus(dt)
    adminStatusTime=adminStatusTime+dt
    if not adminParagraph or adminStatusTime<1 then return end
    adminStatusTime=0
    local context=adminContext
    adminParagraph:Set('社群階層偵測狀態',string.format(
        '社群：%d｜允許階層：Member\n狀態：%s\n已檢查：%d｜查詢失敗：%d',
        ADMIN_GROUP_ID,S.AdminGuard and (context and context.Status or '等待啟動') or '已關閉',
        context and context.Checked or 0,context and context.Failures or 0))
end
connections[#connections+1]=Players.PlayerAdded:Connect(function(player)
    if adminContext then enqueueAdminCheck(adminContext,player,true) end
end)
connections[#connections+1]=Players.PlayerRemoving:Connect(function(player)
    if adminContext then
        adminContext.Pending[player]=nil
        adminContext.Records[player.UserId]=nil
    end
end)
Env.__TWR_BJZ={Stop=stop,Settings=S}
local setupOK, setupError=pcall(function()
    Window=Library:CreateWindow({Name='TWR · Delta',Brand='TWR',ConfigId='TWR_Delta',ToggleKey=Enum.KeyCode.Insert,OnUnload=stop})
    Window.ScreenGui.Parent=Parent
    local tab=Window:CreateTab('功能','settings')
    local gun=tab:CreateSection({Name='槍枝',Side='left'})
    local function toggle(section,label,key,description,callback)
        return section:CreateToggle({Name=label,Flag='TWR_'..key,bCurrentValue=S[key],Description=description,Callback=function(value)
            S[key]=value
            if callback then callback(value) end
        end})
    end
    toggle(gun,'無限彈藥','Ammo','逐次射擊後補回，並自動追蹤換槍與重生',function(value)
        if value then
            local success,message=scanAmmo()
            if not success then Window:Notify({Title='彈藥',Content=message}) end
        end
    end)
    local wallToggle=toggle(gun,'子彈穿牆','Wallbang',
        wallbangReady and '略過地圖、場景與地形；Silent Aim 可選取牆後殭屍' or '找不到相容子彈模組，已停用',
        function(value)
            if not wallbangReady then S.Wallbang=false end
            if not S.Wallbang then clearBulletWalls() end
        end)
    if not wallbangReady then wallToggle:SetEnabled(false) end
    toggle(gun,'無後座力','Recoil',nil,applyStats)
    toggle(gun,'全自動','Auto','半自動 → 自動；霰彈槍 → 自動霰彈槍',applyStats)
    local rateToggle=toggle(gun,'射速調整','FireRate',
        rateCheckReady and '已處理 GetCC 的 RPM 回報；伺服器仍可能限制射速' or '此執行器無法取得檢查回呼，射速調整已停用',
        function(value)
            if value and not rateCheckReady then
                S.FireRate=false
                Window:Notify({Title='射速調整不可用',Content='無法取得原始檢查回呼，維持原始射速。'})
            end
            applyStats()
        end)
    if not rateCheckReady then rateToggle:SetEnabled(false) end
    gun:CreateSlider({Name='射速倍率',Flag='TWR_FireRateMultiplier',Range={1,1000},Increment=.1,CurrentValue=S.FireRateMultiplier,
        Suffix='×',Callback=function(value)
            S.FireRateMultiplier=math.clamp(value,1,1000)
            applyStats()
        end})
    burstToggle=toggle(gun,'加速連射（實驗）','FastBurst',
        nativeFireCore and '正常射擊後追加發射；支援手動與自動攻擊，傷害須實測' or 'Delta 無法取得原始射擊函式，已停用',
        function(value)
            if not nativeFireCore then S.FastBurst=false end
        end)
    if not nativeFireCore then burstToggle:SetEnabled(false) end
    gun:CreateSlider({Name='每次額外發數',Flag='TWR_ExtraShots',Range={1,100},Increment=1,
        CurrentValue=S.ExtraShots,Callback=function(value) S.ExtraShots=math.clamp(math.floor(value),1,100) end})
    burstStatus=gun:CreateParagraph({Title='加速連射執行狀態',Content='等待射擊資料…'})
    gun:CreateButton({Name='複製 Debug 資訊',Callback=copyDebug})
    gun:CreateButton({Name='重新偵測連射函式',Callback=function()
        if burstQueued or burstRunning then return end
        nativeFireCore,burstResolveStatus=resolveFireCore()
        burstToggle:SetEnabled(nativeFireCore~=nil)
        if not nativeFireCore then S.FastBurst=false; burstToggle:Set(false,true) end
        burstDiag.Elapsed=1; updateBurstStatus(0)
    end})
    gun:CreateButton({Name='重設連射計數',Callback=function()
        burstDiag.Base=0; burstDiag.Calls=0; burstDiag.Projectiles=0; burstDiag.Skipped=0
        burstDiag.Reason='已重設，請開始射擊'; burstDiag.Elapsed=1; updateBurstStatus(0)
    end})
    gun:CreateButton({Name='重新掃描彈藥',Callback=function()
        local _,message=scanAmmo(); Window:Notify({Title='彈藥掃描',Content=message})
    end})
    local aim=tab:CreateSection({Name='殭屍 Silent Aim',Side='right'})
    toggle(aim,'Silent Aim','Silent','只調整本機玩家子彈方向，不移動鏡頭')
    local autoToggle=toggle(aim,'自動攻擊殭屍','AutoAttack','360° 自動射擊；觸發間隔隨射速倍率調整',function(value)
        if not autoAttackReady then S.AutoAttack=false end
        if not S.AutoAttack then releaseAutoAttack() end
    end)
    if not autoAttackReady then autoToggle:SetEnabled(false) end
    toggle(aim,'360° 目標選取','Aim360','手動射擊搭配 Silent Aim 時，也能選取鏡頭外目標')
    local function settingToggle(label,key)
        aim:CreateToggle({Name=label,Flag='TWR_'..key,bCurrentValue=S[key],Callback=function(v) S[key]=v end})
    end
    settingToggle('優先頭部','Head'); settingToggle('遮擋檢查','Visible'); settingToggle('顯示 FOV','ShowFOV')
    aim:CreateSlider({Name='FOV 半徑',Flag='TWR_FOV',Range={30,600},Increment=5,CurrentValue=S.FOV,Callback=function(v) S.FOV=v end})
    aim:CreateSlider({Name='最大距離 (studs)',Flag='TWR_Distance',Range={100,3000},Increment=50,CurrentValue=S.Distance,Callback=function(v) S.Distance=v end})
    local esp=tab:CreateSection({Name='殭屍 ESP',Side='left'})
    toggle(esp,'殭屍輪廓與距離','ESP','僅標示 Infected，不標示玩家或 Escort')
    local extras=Window:CreateTab('擴充功能','grid')
    local hitbox=extras:CreateSection({Name='殭屍命中範圍',Side='left'})
    toggle(hitbox,'擴大指定部位','Extender',nil,updateLimbs)
    hitbox:CreateDropdown({Name='目標部位',Flag='TWR_Limb',Options={'Head','Torso','Left Arm','Right Arm','Left Leg','Right Leg'},
        CurrentOption=S.Limb,Callback=function(value)
            resetLimbs(); S.Limb=value; updateLimbs()
        end})
    hitbox:CreateSlider({Name='部位大小 (studs)',Flag='TWR_LimbSize',Range={1,100},Increment=.5,CurrentValue=S.LimbSize,
        Callback=function(value) S.LimbSize=math.clamp(value,1,100); updateLimbs() end})
    hitbox:CreateSlider({Name='部位透明度',Flag='TWR_LimbTransparency',Range={0,1},Increment=.05,CurrentValue=S.LimbTransparency,
        Callback=function(value) S.LimbTransparency=value; updateLimbs() end})
    toggle(hitbox,'殭屍死亡時還原','ResetDead',nil,updateLimbs)
    local items=extras:CreateSection({Name='物品與補給',Side='right'})
    toggle(items,'物品 ESP','Items','標示 workspace.Ignore.Items 裡的物品',updateItems)
    toggle(items,'無限能量飲料','Energy','持續設定本機角色 Drinked；效果依遊戲判定',updateEnergy)
    local boss=extras:CreateSection({Name='Butcher BOSS',Side='right'})
    toggle(boss,'跳過 Butcher 出場演出','SkipBossIntro',
        '略過本機鏡頭與操作限制；演出期間能否造成傷害仍由伺服器決定',updateBossIntro)
    local system=tab:CreateSection({Name='控制',Side='right'})
    system:CreateButton({Name='卸載並還原',Callback=stop})
    -- The library restores initial controls silently. Synchronize runtime settings
    -- explicitly so restored toggles also activate features, not only their UI.
    local function applyConfiguration()
        local previousLimb=S.Limb
        targetCache={}; shotDataCache=setmetatable({},{__mode='k'})
        for key in pairs(S) do
            local control=Window.Flags['TWR_'..key]
            if control then S[key]=control:Get() end
        end
        if not nativeFireCore then S.FastBurst=false; burstToggle:Set(false,true) end
        S.ExtraShots=math.clamp(math.floor(S.ExtraShots),1,100)
        if not autoAttackReady then S.AutoAttack=false; autoToggle:Set(false,true) end
        if not S.AutoAttack then releaseAutoAttack() end
        S.FireRateMultiplier=math.clamp(S.FireRateMultiplier,1,1000)
        S.LimbSize=math.clamp(S.LimbSize,1,100)
        if not rateCheckReady then
            S.FireRate=false
            rateToggle:Set(false,true)
        end
        if not wallbangReady then
            S.Wallbang=false
            wallToggle:Set(false,true)
        end
        if not S.Wallbang then clearBulletWalls() end
        if previousLimb~=S.Limb then resetLimbs() end
        applyStats(); updateLimbs(); updateItems(); updateEnergy(); updateBossIntro(); applyRendering()
        if S.Ammo then scanAmmo() end
        applyAdminGuard()
    end
    local configTab=Window:CreateTab('設定','settings')
    local configSection=configTab:CreateSection({Name='設定保存與載入',Side='full'})
    local adminSection=configTab:CreateSection({Name='指定社群階層自動退出',Side='full'})
    toggle(adminSection,'偵測非 Member 階層並退出','AdminGuard',
        '社群 2838077；非社群成員與 Member 不觸發，其他階層會讓本機玩家退出',applyAdminGuard)
    adminParagraph=adminSection:CreateParagraph({Title='社群階層偵測狀態',Content='準備查詢…'})
    adminSection:CreateButton({Name='重新檢查伺服器玩家',Callback=function()
        applyAdminGuard(); adminStatusTime=1; updateAdminStatus(0)
    end})
    renderControl=toggle(configSection,'關閉 3D 渲染','Disable3D',
        '停止繪製 3D 場景；保留介面，關閉此開關即可恢復',applyRendering)
    configSection:CreateButton({Name='複製 Debug 資訊',Callback=copyDebug})
    configSection:CreateButton({Name='立即清理暫存資源',Callback=function()
        local before=optimization.RemovedInstances
        cleanupResources()
        Window:Notify({Title='資源清理完成',Content='本次移除 '..(optimization.RemovedInstances-before)..' 個腳本暫存 Instance。'})
    end})
    configSection:CreateButton({Name='儲存設定',Callback=function()
        local success,message=Window:SaveConfiguration()
        Window:Notify({Title=success and '儲存成功' or '儲存失敗',
            Content=success and '已保存功能開關、數值與介面設定。' or tostring(message)})
    end})
    configSection:CreateButton({Name='載入設定',Callback=function()
        -- Restore all controls before applying dependent functionality.
        local success,message=Window:LoadConfiguration(true)
        if success then applyConfiguration() end
        Window:Notify({Title=success and '載入成功' or '載入失敗',
            Content=success and '已載入並套用保存的設定。' or tostring(message)})
    end})
    applyConfiguration()
    if alive and not Window.bDestroyed then Window:Notify({Title='已載入',Content='已套用保存設定；社群階層偵測可在設定分頁切換。'}) end
end)
if not setupOK then stop(); error(setupError) end
if not alive then return end
-- Both frame boundaries and shot callbacks use the same cheap live-table refill.
Run:BindToRenderStep(autoRenderName,Enum.RenderPriority.Input.Value+1,function(dt)
    if not alive then return end
    refillAmmo()
    if not S.Disable3D then updateAutoAttack(dt) end
end)
local espTime,extrasTime,cleanupTime=0,0,0
connections[#connections+1]=Run.Heartbeat:Connect(function(dt)
    if not alive then return end
    if Window.bDestroyed then stop(); return end
    refillAmmo()
    updateBurstStatus(dt)
    updateAdminStatus(dt)
    -- Keep our automation polling when 3D rendering is disabled.
    if S.Disable3D then updateAutoAttack(dt) end
    if S.Ammo and not inventory and os.clock()>=fallbackScanAt then
        fallbackScanAt=os.clock()+5
        scanAmmo()
    end
    extrasTime=extrasTime+dt
    if extrasTime>=.1 then
        extrasTime=0; updateLimbs(); updateItems(); updateEnergy()
    end
    cleanupTime=cleanupTime+dt
    if cleanupTime>=1 then cleanupTime=0; cleanupResources() end
    local cam=workspace.CurrentCamera
    if not cam then destroyFOV(); return end
    updateFOV(cam)
    espTime=espTime+dt
    if espTime>=.1 then espTime=0; updateMarkers(cam) end
end)

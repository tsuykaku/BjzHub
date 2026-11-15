# SilentAimEngine

共用引擎提供選取、彈道計算與瞄準部位圓圈，以明確的協定適配器接入遊戲。載入不會掃描模組、安裝 hook、建立 UI、移動鏡頭或自動開火；只有呼叫 `SetTargetMarkerParent` 才建立標記覆蓋層。

不同遊戲的角色、敵友、武器與網路協定無法自動推定，因此「可擴充至其他遊戲」需要新增適配器，並不代表不需設定就能在所有遊戲生效。伺服器權威射擊、命中驗證、阻力、追蹤彈及自訂模擬需要各自的遊戲邏輯。RaidTycoon 已接入共用選取、射擊綁定與目標圈，其餘腳本的協定對照供適配時參考。

## 載入與目標來源

```luau
local CSilentAimEngine = loadstring(game:HttpGet("https://raw.githubusercontent.com/tsuykaku/BjzHub/main/Core/Features/SilentAimEngine.luau"))()
```

遠端載入才可使用。引擎不依賴 EspEngine 或 BjzUi。

RaidTycoon 會檢查快取與下載結果的 `API_VERSION = 2` 及實際使用的方法。載入網址帶有版本查詢參數；若取得舊內容或發生下載錯誤，最多使用另一個查詢參數重試一次。兩次都失敗時停止初始化並列出不相容版本、缺少的方法或下載錯誤，不會把不相容模組寫入快取。相容快取會直接重用，以保留已停用的 hook 轉交器。

遊戲適配器必須提供 `GetCandidates(Context)`；每次射擊重新取得候選，不持有跨射擊快取。候選使用 `Part` 或 `Point` 表示瞄準點，支援一般角色、NPC、載具目標及 SEAR 類型的虛擬 hitbox。

```luau
-- 此範例接在遊戲既有的目標登錄系統；四個函數由遊戲適配層提供。
local Engine = CSilentAimEngine.new({
    World = workspace,
    GetCandidates = CollectAimCandidates,
    IsEligible = IsEnemyAndAlive,
    GetIgnoreInstances = GetLocalCharacterAndEffects,
    IsVisible = CheckGameVisibility,
}, {
    bEnabled = false,
    FovMode = "Pixels",
    FovRadius = 120,
    MaxDistance = 2000,
    bVisibleOnly = true,
})
```

| 適配回呼 | 呼叫方式與責任 |
| --- | --- |
| `GetCandidates(Context)` | 必填，回傳目標陣列，例如 `{ Id = UserId, Model = Character, Part = Head, Health = Health }`。`Point` 存在時優先於 `Part.Position`，應每次重新計算。 |
| `IsEligible(Context, Candidate)` | 可選；即時檢查本機、敵友、投降、無敵、死亡等遊戲狀態。即使啟用黏著也會重查。引擎本身只檢查物件仍有 Parent、提供的 Health 大於 0、`bEligible` 不為 false。 |
| `GetCamera()` | 可選；預設讀取 `World.CurrentCamera`。 |
| `GetCursorPosition()` | 可選；`Priority = "Cursor"` 且 `Shot.Center` 未指定時呼叫，回傳 Viewport 像素座標。預設使用 `UserInputService:GetMouseLocation()`，不再扣除 GUI inset。 |
| `GetIgnoreInstances(Context)` | 可選；原生視線檢查的排除清單，應包含本機角色及本機效果。引擎會另外排除相機，不會排除所有角色。 |
| `IsVisible(Context, Candidate, Point)` | 可選；完整取代預設 Raycast，處理載具、玻璃、特殊碰撞群組等。原點為 `Context.Shot.Origin`。 |
| `Predict(ShotData, Candidate, Point)` | 可選；`bPrediction = true` 時覆寫內建彈道，回傳 `(補償位置或 nil, 飛行秒數)`。用於阻力、加速度或其他自訂模擬。 |

所有回呼須同步完成，不可 yield 或修改引擎與原始射擊封包。`Context` 包含 `Shot`、`Camera` 與 `Range`。候選的 `Data`、射擊的 `Data` 可攜帶遊戲專屬資料，核心不解讀其內容。

## 選取與彈道設定

| 欄位 | 預設與意義 |
| --- | --- |
| `bEnabled` | `false`；透過 `Engine:Configure({ bEnabled = true })` 啟用。 |
| `FovMode` | `"Pixels"`；另有 `"Angle"`、`"All"`。 |
| `FovRadius` | `120`；Viewport 像素半徑，非 GUI inset 座標。Cursor 模式圍繞游標，其餘模式預設圍繞畫面中心；`Shot.Center` 可覆寫中心。 |
| `FovAngle` | `60`；完整角度，實際半錐為 30°。 |
| `MaxDistance` | `2000` studs；每發 `Shot.Range` 可縮小此上限，`math.huge` 可表示無設定上限。 |
| `Priority` | `"Screen"`；另有 `"Cursor"`、`"Angle"`、`"Distance"`、`"Health"`。Cursor 選取離游標最近的目標，Distance 依射擊原點距離排序；兩者仍須通過射程、FOV 與可見性檢查。未提供血量的目標在 Health 排序時最後。 |
| `bShowTargetMarker` | `true`；已有標記覆蓋層時顯示部位圓圈，false 在下一次繪製隱藏。未設定標記父節點時不會建立 UI。 |
| `bOnScreen` | `true`；`All` 或本次 `Shot.bAllDirections` 會略過畫面與 FOV 限制，Screen／Angle 排序改用距離。 |
| `bVisibleOnly` | `true`；從實際射擊原點檢查視線。 |
| `bSticky` | `false`；使用穩定 `Id`、Model 或 Part 辨識既有目標，重新通過有效性檢查後才保留。 |
| `bPrediction` | `false`；內建等速目標、固定重力的有限次數飛行時間迭代。 |
| `MaxPredictionTime` | `3` 秒；無法在上限內估計時放棄改寫。 |
| `MaxTargetSpeed` | `250` studs/s；超過時視為異常速度，內建預判改用零速度。 |
| `PredictionIterations` | `4`；可設定 1–12 次，屬近似求解。 |

每次射擊的 `Shot` 必須包含 `Origin: Vector3`，可另外提供：

- `Range`：真正武器射程。相機射線通常長度為 1，引擎不把向量長度當作武器射程。
- `Speed`：子彈速度，studs/s；未提供表示 hitscan。
- `Gravity`：重力加速度向量，studs/s²，預設為零。OW 的自訂模擬使用 `Vector3.new(0, -32.2, 0)`，不能一律使用 `workspace.Gravity`。
- `Latency`：目標等速運動的額外預判秒數，預設 0。
- `Center`：Viewport 座標的瞄準中心，省略時 Cursor 模式使用游標，其餘模式使用畫面中央。引擎不修改呼叫端的 Shot 表。
- `bAllDirections`：此發射擊使用 360° 選取。

`Engine:Select(Shot)` 回傳 `AimSolution?`，包含 Candidate、Origin、Point、單位 Direction、保持原點的 Frame、原始 Distance、FlightTime 與 Score。需要直接接在既有 wrapper 時，也可使用：

```luau
local NewFrame = Engine:RedirectFrame(ShotFrame, ShotSettings)
local NewDirection = Engine:RedirectDirection(Origin, Direction, ShotSettings)
local NewRay = Engine:RedirectRay(BaseRay, ShotSettings)
```

這三個方法各自重新選取。若同一發射擊需要同時改 CFrame 與方向，使用一次 `Select` 的解，或以下 `FrameDirection` 綁定，避免重複選取。

## 五份現有腳本的接入對照

`CreateBinding(Spec)` 產生宣告式適配器。索引從 1 開始，包含明確傳入的 `self`。`Matches(Values, Arguments)` 必填，必須檢查本機／真正射擊狀態；After 階段的 Values 是回傳值、Arguments 仍是原始完整實參。

| 腳本與入口 | Kind／Phase | 索引與必要規則 |
| --- | --- | --- |
| TWR `Bullets.Fire2(data, gui, file, cf, direction, ...)` | `FrameDirection`／Before | `ValueIndex = 4`、`DirectionIndex = 5`；`file.player == LocalPlayer`，由 CFrame 取得原點，同步改朝向與方向。 |
| SEAR `GenerateCommand(...)` | `Command`／After | `ValueIndex = 1`、`OriginField = "fo"`、`AimField = "fa"`、`AimLength = 2000`；檢查 `f == 1`、`fireIntent == 1`、非零 `gunStateEpoch`。複製指令並保留移動及其他欄位。 |
| Ragdoll `ScreenPointToRay`／`ViewportPointToRay` | `Ray`／After | `ValueIndex = 1`；以 `BindFunction` 接入實際相機方法。Matches 檢查目前相機、允許的 ShooterClient 呼叫來源、非 Executor 呼叫與遊戲暫停狀態；提供真正武器 Range。兩個方法分別綁定。 |
| OW `Service:Discharge(origin, caliber, barrel, uid, replicate, localFlag, ...)` | `Frame`／Before | `ValueIndex = 2`；確認 `Arguments[1] == Service` 且 `[7] == true`，還要檢查敵對／投降狀態。GetShot 由 Service.GetInfo 取得 Speed／Range，設定該遊戲的重力。 |
| RaidTycoon `Fire.frame(...)` | 自訂 `ShotBinding`／Before | 第 7 個實參是瞄準位置，可為 nil；Read 使用 `_ShotOrigin(camera, tool)` 與 `_AimRange(tool)`，Write 填入位置並保留其他實參及尾端 nil。通用 Position 映射要求原欄位已有 Vector3，因此此遊戲採自訂讀寫。 |

例如 TWR 的最小綁定（前提是已取得 `Bullets`、`LocalPlayer` 與設定好的 `Engine`）：

```luau
--[[
    只接受本機玩家的 Fire2 呼叫。
    @param Values 此次射擊的完整實參。
    @param Arguments 原始完整實參。
    @return true 為本機射擊，false 表示略過。
]]
local function _IsLocalShot(Values, Arguments)
    local File = Arguments[3]
    return type(File) == "table" and File.player == LocalPlayer
end

local Binding = CSilentAimEngine.CreateBinding({
    Kind = "FrameDirection",
    ValueIndex = 4,
    DirectionIndex = 5,
    Matches = _IsLocalShot,
})
local Disconnect, Reason = Engine:BindMethod(Bullets, "Fire2", Binding)
assert(Disconnect, Reason)
```

其他 Kind 還包含 `Direction`（保留原向量長度）。`Position`／`Direction` 需用 `OriginIndex` 指定同一封包中的 Vector3 原點，或提供 `GetShot(Values, Arguments)`。`Frame`、`FrameDirection`、`Ray`、`Command` 也能提供 GetShot 加上即時彈道設定；此時原點仍以宣告的 Frame／Ray／Command 原點為準。GetShot 回傳 nil 會略過此次呼叫。

未列出的協定使用完整 `ShotBinding`：`Phase`、`Matches`、`Read`、`Write`。Read 回傳 Shot 或 nil；Write 接收 `(Values, Solution, Arguments)`，回傳改寫後封包或 nil。封包為 `table.pack` 格式，必須保留 `n`。嵌套封包、子彈列表、特殊命令與回傳結構可在此適配；先複製要變更的巢狀表，不得修改原始資料。霰彈的每顆彈丸與散布是否跟隨同一解，由遊戲的 Write 規則決定。

## 瞄準部位圓圈

呼叫端提供 UI 根節點，並在相機更新後逐幀呼叫繪製方法；引擎不持有 RunService 連線。

```luau
-- 前提：Engine 已建立，且目前執行身分允許操作 OverlayParent。
Engine:SetTargetMarkerParent(OverlayParent)
Engine:Configure({ bEnabled = true, Priority = "Cursor", bShowTargetMarker = true })
-- 使用既有射擊綁定或 Engine:Select(Shot) 更新目標後，每幀呼叫：
Engine:RenderTargetMarker()
Engine:ClearSelection() -- 清除目標，下一次 RenderTargetMarker 隱藏圓圈。
Engine:Destroy() -- 解除綁定並銷毀引擎專屬的 UI。
```

標記覆蓋層使用原生 GUI，`IgnoreGuiInset = true`。圓心跟隨 `Candidate.Part.Position`，直徑採該部位八個角投影邊界的較短邊，隨部位大小、相機遠近與方向改變，不使用全身邊界或固定像素半徑。預判開啟時，圓圈仍標示實際部位位置。

只有 Point、沒有 Part 的虛擬目標仍可被選取，但不繪製部位圈。部位離屏、被移除、穿過相機平面、沒有相機、功能停用或沒有選取結果時，下一次繪製會隱藏圓圈；即使停用也應持續呼叫 `RenderTargetMarker`。選取、設定與清除目標的路徑不操作 UI，以免射擊回呼的執行身分無法存取覆蓋層。`SetTargetMarkerParent(nil)` 可立即移除 UI，保留選取與射擊功能。重複同步相同設定不會清掉目前目標；實際變更設定仍會清除舊選取。

RaidTycoon 的「目標選擇方式」可選「離游標最近」或「距離最近」，另有「顯示瞄準部位圓圈」開關。

## Hook 與卸載

- `BindMethod(Owner, Key, Binding, Mode?)`：預設 Auto，優先使用 sUNC `hookfunction` 與 `newcclosure`，失敗時嘗試可寫方法表。Function 模式不退回 Table，Table 模式只修改該表欄位。Owner 必須是直接持有該函數的表；繼承方法需由適配器找到真正擁有者。
- `BindFunction(Target, Binding)`：直接接入函數或相機方法，需要 sUNC 能力。可涵蓋遊戲已保存的閉包引用；方法表替換無法涵蓋那些引用。
- 安裝成功回傳解除函數，失敗回傳 `nil, 原因`。同一模組實例拒絕重複的活躍綁定。適配器與映射錯誤會沿用原射擊資料，可讀取 `GetLastError()`；原函數錯誤照常向上傳遞，不會重送射擊。
- 方法表卸載只還原仍由引擎擁有的欄位；其他 wrapper 接手時不覆蓋它。函數 hook 卸載後留下透明轉交器並釋放引擎引用，不直接使用 `restorefunction` 清除整條 hook 鏈。這是行為停用，不是移除原生 hook。
- 同一份載入的模組可重用已停用的函數轉交器；重新下載並執行模組會建立另一份登錄表，應在遊戲腳本中快取模組並先卸載舊引擎。
- `Engine:Destroy()` 解除全部擁有的綁定並銷毀目標圈 UI，可重複呼叫。其他 UI、事件、候選登錄與更新頻率由呼叫端管理。

sUNC API 行為依據：[hookfunction](https://docs.sunc.io/Closures/hookfunction/)、[newcclosure](https://docs.sunc.io/Closures/newcclosure/)、[restorefunction](https://docs.sunc.io/Closures/restorefunction/)。已搜尋 Pesde 的 Silent Aim 需求，未找到可直接替換這五種現有協定的候選；本引擎整理專案既有模式，未新增套件依賴。

## 驗證

```text
lune run Tests/SilentAimEngine.spec.luau
```

測試使用 Lune Rbx 資料型別與明確標註的投影、Raycast、lookAt／Executor API 替身，涵蓋五種協定資料形狀、游標／距離排序、FOV、預判、部位圈縮放與移動，以及綁定與 UI 生命週期。離線測試不代表實際 Executor 的 hook 相容性或伺服器命中已驗證。

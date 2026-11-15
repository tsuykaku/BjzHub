--!nonstrict
--[[
    BjzUi Library 3.5.1 · 先快後慢的視窗最小化動態版
    檔名維持 BjzUiLibrary_2.0.luau；沿用 3.x 自訂名稱，不提供舊名稱別名。
    保留單檔、事件驅動、無外部執行期依賴；型別與文件不建立額外執行期物件。

    使用者規範：PascalCase、私人 _ 前綴、boolean b 前綴、類別 C 前綴。
    Rbx API、metamethod、執行器能力名稱與既有 JSON 協定保留原拼字。
    初始化不隱含觸發回呼；明確指定 bEmitInitial=true 才通知初值。
    bSilent=true 的 Set/LoadConfiguration 不觸發值變更回呼。
    bDisabled=true 或 bEnabled=false 會停用元件；停用按鈕背景與邊框為灰色。
    RightShift 在主視窗與可拖曳小方塊之間切換；Hide 仍可明確隱藏視窗。
    導覽列預設收合；游標進入側欄時展開、離開時收合，寬度與名稱同步播放動畫。
    SetNavigationExpanded(boolean) 可設定目前狀態；後續仍由游標位置更新，不保存懸停狀態。
    文字輸入框使用原本的 UIStroke 顯示懸停／焦點，不受文字內距影響。
    有時限的通知底部會顯示由右向左遞減的剩餘時間條。
    內建圖示優先以原生 Path2D 繪製；舊用戶端保留內建圖示的 Frame 備援。
    Library:ParseSvg(Svg, Options) 解析完整 SVG 或 path d，回傳資料／錯誤。
    Library:RegisterSvg("名稱", Svg, Options) 註冊後可直接使用 Icon="名稱"。
    Icon 也接受內嵌 SVG 字串；不下載 SVG 網址，不使用外部執行期套件。
    Window:CreateSvg({ Svg=Svg或註冊名稱, Parent=Frame, Size=UDim2, Color="#FFFFFF" }) 建立獨立圖示。
    支援 M/L/H/V/C/S/Q/T/A/Z（含相對座標）、多子路徑、path/line/polyline/polygon/rect/circle/ellipse。
    支援 viewBox、群組 transform、基本描邊色／透明度；自動適應尺寸與主題色。
    Path2D 僅描邊；不支援 fill、遮罩、濾鏡、文字、use、CSS 樣式表或外部素材。
    bOutlineFill=true 可將填色圖形改成輪廓；不會將輪廓宣稱為原本的填色效果。
    弧線以每段最多 45° 的三次曲線近似；端點／接合採 Path2D 原生樣式。
    RegisterSvg/CreateSvg 的第三回傳值為轉換限制警告；bPreserveColors=true 保留 SVG 描邊色。
    CSvg.Sources 的內建名稱使用 PascalCase；既有小寫 Icon 名稱仍可解析。
    內建 Coin、TreasureChest、Potion、People、Food；來自提供的 SVG，使用主題色輪廓與 24x24 座標。
    內建 Coin、TreasureChest、Potion、People、Food；來自提供的 SVG，使用主題色輪廓與 24x24 座標。
    最小化／最大化／還原／關閉與四種游標皆從 SVG 建立；Arrow/Dot 的實心輪廓由同一份 SVG 取樣。
    Window:ToggleMaximize()／SetMaximized(boolean) 可切換最大化，保留原本視窗尺寸。
    最大化按鈕預設隱藏；CreateWindow({ bShowMaximizeButton=true }) 可顯示。
    關閉按鈕預設呼叫 Window:Unload()，清理視窗資源；OnUnload(Window) 可清理外部腳本工作。
    CreateWindow({ CloseAction="Hide" }) 可改成隱藏；Destroy／Unload 都只執行一次 OnUnload。
    CheckBox 使用 SVG 勾選圖示，切換時縮放及淡入淡出；通知預設 Info 圖示，可用 Icon 修改。
    例如 Window:Notify({ Title="完成", Content="設定已儲存", Icon="Bell", Duration=5 })。
    Icon 接受內建／註冊名稱、內嵌 SVG 或圖片 asset ID；通知既有 Image 選項仍可使用。
    CreateWindow({ Brand="BJZ UI", Icon="Home" }) 可設定品牌文字及最小化圖示。
    未指定 Icon 時，小方塊顯示品牌的第一個字元；SetBrand／SetIcon 可在執行中更新。
    最小化以 Quint Out 先快後慢地將整個視窗縮向小方塊；再次切換、隱藏、卸載或停用動畫會安全結束過場。
    通知以淡入滑入／淡出滑出顯示，關閉動畫結束後釋放資源；Destroy(true) 可立即移除。

    Delta 檔案 API 以 workspace 為根目錄，設定路徑固定為 BjzUi/UiConfig.json。
    專屬游標預設開啟，僅顯示於介面區域與滑鼠拖曳期間；不依賴遊戲的原生游標可見性。
    Cursor 可設定 bEnabled、Style、Size、Color、OutlineColor、Opacity、bUseAccent、bHideNative。
    Style：Arrow／Crosshair／Dot／Ring；Size：12–64 螢幕像素；Opacity：0.1–1。
    Window:SetCursor({...})／GetCursor() 操作設定；CreateCursorSettings(Section) 建立設定面板。
    Demo 的「設定 → 專屬游標」可即時調整；各 ConfigId 保存於 UI.Cursor。
    Arrow 使用附檔 cursor-svgrepo-com.svg 的圓角實心輪廓，固定跟隨 Theme.Accent。
    舊 Arrow 配色也會跟隨主題；其他樣式仍可選擇固定色。大小與透明度設定保留。
    圖形內嵌於本檔，以原生 GUI 繪製，不需另外放置 SVG、下載圖片或註冊本機素材。
    僅繪製指標，不更改 MouseBehavior 鎖定模式、不模擬輸入；觸控／手把／失焦／ESC 選單不繪製。
    原生游標只在介面內暫時隱藏，離開或銷毀時還原已觀測狀態；多視窗共用事件，沒有逐幀輪詢。
    ConfigId 是同一 JSON 內的視窗分組。四邊與四角支援滑鼠及觸控調整尺寸。
    使用隨機 ScreenGui 名稱，依序嘗試 gethui、CoreGui、PlayerGui；不保證規避偵測。

    快速開始（請先把本檔放入 Delta workspace）：

    local BjzUi = loadstring(readfile("BjzUiLibrary_2.0.luau"))()
    local Window = BjzUi:CreateWindow({
        Name = "控制中心", ConfigId = "MyHub", bResizable = true,
        ConfigurationSaving = { bEnabled = true },
    })
    local Tab = Window:CreateTab("一般", "grid")
    local Section = Tab:CreateSection({ Name = "設定", Side = "left" })
    local Toggle = Section:CreateToggle({ Name = "啟用", bCurrentValue = false, Flag = "enabled" })
    Toggle:Set(true)
    Section:CreateButton({ Name = "停用按鈕", bEnabled = false })
    -- BjzUi:Demo() 可建立完整展示；本檔載入時不會自動建立視窗。

    公開工廠：CreateWindow → CreateTab → CreateSection → CreateButton/Toggle/Checkbox/
    Slider/Input/Dropdown/Keybind/ColorPicker/Paragraph/Label/Divider/Progress/Badge/RadioGroup。
    舊 MainFrame、Tab 簡寫、ZoomWindow、CreateTextbox、CreateBind 及 Tab 級元件轉接已移除。
    多選使用 bMulti；布林控制項初值使用 bCurrentValue；其他元件仍使用 CurrentValue/CurrentOption。
    取得值請用 Get；用 SetEnabled/SetVisible 改狀態，以執行完整互動清理。

    Pesde 評估日期：2026-10-26；關鍵字：Rbx UI、reactive UI、vide、fusion、iris。
    本專案沒有 pesde.toml 或 pesde.lock。
    centau/vide 0.4.0：Rbx、MIT、型別與官方 API 文件，Pesde 頁面顯示無相依。
    GitHub 擷取約 350 stars；此為關注指標，不是使用人數。下載／實際採用數未知。
    lumin/ui 0.3.0-rc3：Rbx、MIT、宣告式 New/Event API；儲存庫快照較舊，
    曾顯示 14 stars 與 0.4.4 release，但無法據此確認目前維護狀態或採用量。
    本次只整理既有實作，兩者皆非既有 CreateWindow API 的直接替換品；
    導入需重寫元件與打包流程，因此不新增依賴，也不重新實作新的通用框架。
    來源：https://pesde.dev/packages/centau/vide
    https://pesde.dev/packages/centau/vide/0.4.0/roblox/dependencies
    https://github.com/centau/vide · https://centau.github.io/vide/api/reactivity-core.html
    https://pesde.dev/packages/lumin/ui/0.3.0-rc3/any · https://github.com/lumin-org/ui
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

--[[
    模組公開入口與目前存活視窗／Flag 的索引；載入本檔不自動建立 UI。
]]
local Library = { Version = "3.5.1", Flags = {}, Windows = {}, ConfigPath = "BjzUi/UiConfig.json" }

--[[
    視窗類別表，CWindow.new 建立實例，__index 共用尺寸、互動與生命週期方法。
]]
local CWindow = {}
CWindow.__index = CWindow

--[[
    主分頁類別表，CTab.new 建立包含導覽項目與子分頁的實例。
]]
local CTab = {}
CTab.__index = CTab

--[[
    元件區塊類別表，CSection.new 決定欄位位置與固定／自動高度。
]]
local CSection = {}
CSection.__index = CSection

--[[
    控制項共同類別表，CControl.new 建立狀態與 Flag；各工廠安裝專屬行為。
]]
local CControl = {}
CControl.__index = CControl

--[[
    Delta workspace 相對路徑；所有視窗分組共用這份 Version=1 JSON。
]]
local CONFIG_PATH, CONFIG_FOLDER = "BjzUi/UiConfig.json", "BjzUi"
local NAVIGATION_DURATION = 0.2
local TOAST_ANIMATION_DURATION = 0.16
local MINIMIZE_DURATION = 0.26

--[[
    取得保留尾端 nil 所需的 unpack 實作；支援提供不同全域名稱的執行環境。
]]
local _UnpackValues = table.unpack or unpack

--[[
    預設主題色，只作為每個新視窗的複製來源；修改視窗色彩不回寫此表。
]]
local DEFAULT_THEME = {
    Background = Color3.fromRGB(19, 27, 32),
    Sidebar = Color3.fromRGB(25, 34, 40),
    Card = Color3.fromRGB(29, 39, 46),
    Input = Color3.fromRGB(23, 32, 38),
    Border = Color3.fromRGB(52, 67, 78),
    Hover = Color3.fromRGB(42, 56, 67),
    Disabled = Color3.fromRGB(68, 72, 78),
    DisabledText = Color3.fromRGB(163, 168, 176),
    Text = Color3.fromRGB(235, 242, 246),
    Muted = Color3.fromRGB(155, 173, 185),
    Accent = Color3.fromRGB(45, 212, 191),
    AccentText = Color3.fromRGB(11, 42, 39),
    Success = Color3.fromRGB(79, 210, 135),
    Warning = Color3.fromRGB(245, 193, 73),
    Error = Color3.fromRGB(247, 111, 125),
    Info = Color3.fromRGB(103, 182, 246),
}
--[[
    控制項可保存的基本選項值；布林值可作為選項資料，不代表啟用狀態。
]]
export type OptionValue = string | number | boolean
export type ColorInput = Color3 | string
export type SvgPoint = { X: number, Y: number, LX: number, LY: number, RX: number, RY: number }
export type SvgPathDefinition = {
    Points: { SvgPoint }, bClosed: boolean, StrokeWidth: number, Opacity: number,
    Color: Color3?, bNonScalingStroke: boolean,
}
export type SvgDefinition = { ViewBox: { number }, Paths: { SvgPathDefinition }, Warnings: { string }, PointCount: number, AspectRatio: string }
export type SvgParseOptions = { ViewBox: { number }?, StrokeWidth: number?, bOutlineFill: boolean?, bPreserveColors: boolean? }
export type SvgOptions = SvgParseOptions & {
    Svg: string, Parent: GuiObject?, Name: string?, Size: UDim2?, Position: UDim2?,
    Padding: number?, Color: ColorInput?, Opacity: number?, bUseAccent: boolean?, ZIndex: number?,
}
export type ESectionSide = "left" | "right" | "full"
export type EButtonStyle = "primary" | "secondary" | "outline"
export type EControlKind =
    "Button"
    | "Toggle"
    | "Checkbox"
    | "Slider"
    | "Input"
    | "Dropdown"
    | "Keybind"
    | "ColorPicker"
    | "Label"
    | "Paragraph"
    | "Divider"
    | "Progress"
    | "Badge"
    | "RadioGroup"

--[[
    儲存值由控制項決定；只有 ColorPicker 使用 Color 與 Alpha 記錄。
    EnumItem 只存在執行期，鍵位寫入 JSON 前會轉為名稱。
]]
export type ControlValue =
    OptionValue
    | Color3
    | EnumItem
    | { OptionValue }
    | { Color: string, Alpha: number }
export type OptionDefinition = OptionValue | { Name: string?, Value: OptionValue?, bDisabled: boolean? }
export type NormalizedOption = { Name: string, Value: OptionValue, bDisabled: boolean, Index: number }

--[[
    共用回呼由控制項在值改變時非同步呼叫；錯誤以 warn 回報。
    參數依控制項種類提供；色彩、下拉選單與 Paragraph 有各自的具體型別。
    @param ... 控制項文件指定的值與附加資料；不會傳入控制項本身。
]]
export type ControlCallback = (...unknown) -> ()

--[[
    使用者完成選擇後呼叫；多選的值與索引都以陣列提供。
    @param Selection 單選值、多選值陣列；清空單選時為 nil。
    @param Index 單選索引、多選索引陣列；沒有單選項目時為 nil。
]]
export type DropdownCallback = (Selection: OptionValue | { OptionValue }?, Index: number | { number }?) -> ()

--[[
    調色盤值改變時呼叫；bSilent=true 的程式設定不觸發。
    @param Color 目前 RGB 顏色。
    @param Alpha 不透明度，範圍 0 到 1；未啟用透明度時固定為 1。
]]
export type ColorCallback = (Color: Color3, Alpha: number) -> ()

--[[
    開關或勾選框的值實際改變時非同步呼叫；靜默設定不觸發。
    @param bValue true 為開啟或勾選；false 為關閉或未勾選。
]]
export type BooleanCallback = (bValue: boolean) -> ()

--[[
    滑桿值經範圍與步進正規化後，若與舊值不同便非同步呼叫。
    @param Value 已限制並量化的數值。
]]
export type NumberCallback = (Value: number) -> ()

--[[
    輸入框提交或 bLive 的有效編輯期間非同步呼叫。
    @param Text 正規化後的輸入文字。
]]
export type TextCallback = (Text: string) -> ()

--[[
    快捷鍵按下時呼叫；bHoldToInteract=true 時釋放與失焦也會通知。
    @param bPressed true 表示按下；false 表示按住操作已釋放。
]]
export type KeybindCallback = (bPressed: boolean) -> ()

--[[
    RadioGroup 改變選取結果時非同步呼叫。
    @param Selection 群組內未停用的選項值。
]]
export type RadioCallback = (Selection: OptionValue) -> ()

--[[
    控制項 Set 在提交前呼叫，用以驗證與正規化外部輸入。
    @param Value 尚未驗證的輸入。
    @return 可提交的資料；無效輸入或允許清空的元件可能回傳 nil。
    @return false 表示拒絕提交；true 或 nil 表示接受第一個回傳值。
]]
type NormalizeCallback = (Value: unknown) -> (ControlValue?, boolean?)

--[[
    拖曳由視窗唯一的輸入連線分派，位置採螢幕像素。
    @param Position 最新的滑鼠或觸控位置；X、Y 用於二維佈局。
]]
type DragCallback = (Position: Vector3) -> ()

--[[
    延遲工作、拖曳結束或浮層關閉時呼叫；釋放所屬 Scope 後不再執行延遲工作。
]]
type VoidCallback = () -> ()

--[[
    主題更新時同步求值；此回呼只回傳顏色，不應 yield 或改動介面樹。
    @param Theme 視窗目前的主題色表。
    @return 指定屬性需要套用的顏色。
]]
type ThemeCallback = (Theme: ThemeColors) -> Color3

export type ThemeColors = {
    Background: Color3,
    Sidebar: Color3,
    Card: Color3,
    Input: Color3,
    Border: Color3,
    Hover: Color3,
    Disabled: Color3,
    DisabledText: Color3,
    Text: Color3,
    Muted: Color3,
    Accent: Color3,
    AccentText: Color3,
    Success: Color3,
    Warning: Color3,
    Error: Color3,
    Info: Color3,
}

export type ConfigurationOptions = { bEnabled: boolean?, FileName: string? }
export type KeySettings = {
    Title: string?,
    Subtitle: string?,
    Note: string?,
    Key: string | { string }?,
    bSaveKey: boolean?,
}
export type ECursorStyle = "Arrow" | "Crosshair" | "Dot" | "Ring"
export type CursorOptions = {
    bEnabled: boolean?,
    Style: ECursorStyle?,
    Size: number?,
    Color: ColorInput?,
    OutlineColor: ColorInput?,
    Opacity: number?,
    bUseAccent: boolean?,
    bHideNative: boolean?,
}
export type CursorSettings = {
    bEnabled: boolean,
    Style: ECursorStyle,
    Size: number,
    Color: Color3,
    OutlineColor: Color3,
    Opacity: number,
    bUseAccent: boolean,
    bHideNative: boolean,
}
export type SavedCursor = {
    bEnabled: boolean?,
    Style: ECursorStyle?,
    Size: number?,
    Color: string?,
    OutlineColor: string?,
    Opacity: number?,
    bUseAccent: boolean?,
    bHideNative: boolean?,
}
export type WindowOptions = {
    Cursor: CursorOptions?,
    Name: string?,
    Brand: string?,
    Icon: string | number?,
    LoadingSubtitle: string?,
    Subtitle: string?,
    ConfigId: string?,
    ConfigurationSaving: ConfigurationOptions?,
    UserName: string?,
    Accent: ColorInput?,
    Scale: number?,
    Width: number?,
    Height: number?,
    MinWidth: number?,
    MinHeight: number?,
    MaxWidth: number?,
    MaxHeight: number?,
    DisplayOrder: number?,
    ToggleKey: Enum.KeyCode | string?,
    bAnimations: boolean?,
    bResizable: boolean?,
    bShowMaximizeButton: boolean?,
    CloseAction: "Unload" | "Hide"?,
    OnUnload: ((CWindowType) -> ())?,
    bKeySystem: boolean?,
    KeySettings: KeySettings?,
}
export type TabOptions = { Name: string?, Icon: string | number?, Subtabs: { string }?, Description: string? }
export type SectionOptions = { Name: string?, Side: ESectionSide?, Subtab: string | number?, Height: number? }

export type BaseControlOptions = {
    Name: string?,
    Description: string?,
    Flag: string?,
    bEnabled: boolean?,
    bDisabled: boolean?,
    bVisible: boolean?,
    bSave: boolean?,
    bEmitInitial: boolean?,
}
export type ButtonOptions = BaseControlOptions & { Style: EButtonStyle?, Callback: VoidCallback? }
export type BooleanOptions = BaseControlOptions & { bCurrentValue: boolean?, Callback: BooleanCallback? }
export type SliderOptions = BaseControlOptions & {
    Range: { number }?,
    Increment: number?,
    Suffix: string?,
    CurrentValue: number?,
    Callback: NumberCallback?,
}
export type InputOptions = BaseControlOptions & {
    CurrentValue: string | number?,
    CurrentText: string?,
    PlaceholderText: string?,
    bLive: boolean?,
    bRemoveTextAfterFocusLost: boolean?,
    Callback: TextCallback?,
}
export type DropdownOptions = BaseControlOptions & {
    Options: { OptionDefinition }?,
    CurrentOption: OptionValue | { OptionValue }?,
    PlaceholderText: string?,
    bMulti: boolean?,
    bSearchable: boolean?,
    Callback: DropdownCallback?,
}
export type KeybindOptions = BaseControlOptions & {
    CurrentKeybind: Enum.KeyCode | string?,
    bHoldToInteract: boolean?,
    bGlobal: boolean?,
    Callback: KeybindCallback?,
}
export type ColorPickerOptions = BaseControlOptions & {
    Color: ColorInput?,
    Alpha: number?,
    bExpanded: boolean?,
    Swatches: { ColorInput }?,
    Callback: ColorCallback?,
}
export type ParagraphOptions = BaseControlOptions & { Title: string?, Content: string? }
export type LabelOptions = BaseControlOptions & { Icon: string | number?, Color: string? }
export type ProgressOptions = BaseControlOptions & { CurrentValue: number? }
export type BadgeOptions = BaseControlOptions & { Status: "success" | "warning" | "error" | "info"? }
export type RadioOptions = BaseControlOptions & {
    Options: { OptionDefinition }?,
    CurrentOption: OptionValue?,
    Callback: RadioCallback?,
}

--[[
    通知按鈕的 Callback 在使用者按下後非同步執行，通知隨即關閉。
    Duration 以秒計；小於或等於 0 時只由使用者或 Destroy 關閉。
]]
export type NotificationOptions = {
    Title: string?,
    Content: string?,
    Image: string | number?,
    Icon: string | number?,
    Duration: number?,
    Actions: { [string]: { Name: string?, Callback: VoidCallback? } }?,
}

--[[
    事件與計時器的生命週期容器；物件、浮層各自持有一份，清理為冪等操作。
]]
type ScopeState = {
    _Connections: { RBXScriptConnection },
    _Timers: { [thread]: boolean },
    _bDead: boolean,
}
type CursorPaint = {
    Object: GuiObject | Path2D,
    Property: string,
    bOutline: boolean,
}
type FeedbackOptions = { Target: GuiObject?, Inset: number?, ZIndex: number?, Color: string? }
type CursorManager = {
    Version: number,
    Windows: { [CWindowType]: number },
    Sequence: number,
    _Scope: ScopeState,
    _Owner: CWindowType?,
    _Env: { [string]: unknown },
    _bFocused: boolean,
    _bMouse: boolean,
    _bMenu: boolean,
    _bUpdating: boolean,
    _bOwnNative: boolean,
    _bRestoreNative: boolean?,
    _Refresh: VoidCallback,
}
type DragState = {
    _Input: InputObject,
    _Update: DragCallback,
    _Finish: VoidCallback?,
    _Scrollers: { [ScrollingFrame]: boolean },
    _Owner: GuiObject?,
}
type PopupState =
    { Host: Frame, Panel: Frame, Scope: ScopeState, Owner: CControlType, OnClose: VoidCallback? }
type PageState = {
    Name: string,
    Sections: { CSectionType },
    Frame: ScrollingFrame,
    Full: Frame,
    Columns: Frame,
    Left: Frame,
    Right: Frame,
    Button: TextButton?,
}

--[[
    UiConfig.json 的 Version=1 外部格式。Animations、KeyAccepted 等欄位
    是既有儲存協定的固定名稱，與程式 API 的 b 前綴分開處理。
    不保存 Instance、連線、閉包或其他執行期物件。
]]
export type SavedUI = {
    Cursor: SavedCursor?,
    Accent: string?,
    Scale: number?,
    Animations: boolean?,
    Width: number?,
    Height: number?,
    X: number?,
    Y: number?,
    MiniX: number?,
    MiniY: number?,
    ToggleKey: string?,
    Tab: string?,
    Subtabs: { [string]: string }?,
}
export type SavedWindow = { UI: SavedUI, Flags: { [string]: ControlValue }, KeyAccepted: boolean? }
export type ConfigurationFile = { Version: number, Windows: { [string]: SavedWindow } }

--[[
    CWindow.new 建立的視窗實例；實例保存狀態，CWindow metatable 提供共用方法。
    GUI 欄位在建構流程中建立後才回傳；可選欄位只在相應互動或通知存在時設定。
]]
export type CWindowType = typeof(setmetatable(
    {} :: {
        Name: string,
        ConfigId: string,
        bConfigEnabled: boolean,
        Theme: ThemeColors,
        Cursor: CursorSettings,
        _CursorFrame: Frame?,
        _CursorManager: CursorManager?,
        _CursorTargets: { [Frame]: boolean },
        _CursorSettingsGroups: { { [string]: CControlType } },
        _CursorShape: string?,
        _CursorPaint: { CursorPaint },
        _bGuiDestroying: boolean?,
        Scale: number,
        bAnimations: boolean,
        bResizable: boolean,
        bVisible: boolean,
        bDestroyed: boolean,
        bMinimized: boolean,
        bMaximized: boolean,
        _RestorePosition: UDim2?,
        bNavigationExpanded: boolean,
        _bNavigationExpanded: boolean?,
        _bNavigationFocused: boolean,
        _NavigationTask: thread?,
        bLocked: boolean?,
        bSingleColumn: boolean?,
        ToggleKey: Enum.KeyCode,
        PreferredWidth: number,
        PreferredHeight: number,
        MinWidth: number,
        MaxWidth: number,
        MinHeight: number,
        MaxHeight: number,
        Width: number,
        Height: number,
        RenderScale: number,
        Flags: { [string]: CControlType },
        Tabs: { CTabType },
        ActiveTab: CTabType?,
        LastConfigError: string?,
        ScreenGui: ScreenGui,
        Surface: Frame,
        Main: Frame,
        UIScale: UIScale,
        Sidebar: Frame,
        Brand: TextLabel,
        BrandText: string,
        Icon: string | number?,
        _bRenderingBrand: boolean?,
        User: TextLabel,
        UserText: string,
        Body: Frame,
        Title: TextLabel,
        Subtitle: TextLabel,
        Nav: ScrollingFrame,
        Search: TextBox,
        PageTitle: TextLabel,
        Content: Frame,
        Mini: TextButton,
        MiniContent: Frame,
        MiniScale: UIScale,
        MiniIcon: Frame?,
        _MinimizeTask: thread?,
        _MinimizeMotion: {Position: UDim2, Blocker: TextButton}?,
        MinimizeButton: TextButton,
        MaximizeButton: TextButton,
        CloseButton: TextButton,
        MaximizeIcon: Frame,
        CloseAction: "Unload" | "Hide",
        _OnUnload: ((CWindowType) -> ())?,
        _CursorComposite: CanvasGroup?,
        ResizeHandles: { [string]: TextButton },
        ToastHost: Frame?,
        _Scope: ScopeState,
        _Controls: { CControlType },
        _Keybinds: { [CControlType]: boolean },
        _Toasts: { [ToastType]: number | boolean },
        _Bindings: { [Instance]: { [string]: string | ThemeCallback } },
        _Tweens: { [Instance]: Tween },
        _Feedback: { [GuiObject]: (boolean?) -> () },
        _SvgScopes: { [Frame]: ScopeState },
        _SavedFlags: { [string]: ControlValue },
        _SavedUI: SavedUI,
        _Registry: { [string]: CWindowType },
        _ResizeHints: { [string]: Frame },
        _bLoading: boolean,
        _bConfigWarned: boolean?,
        _bKeyAccepted: boolean?,
        _bPositioned: boolean?,
        _SaveTask: thread?,
        _Drag: DragState?,
        _Popup: PopupState?,
        _Capture: CControlType?,
        _ResponsiveMode: string?,
        _Resizing: string?,
        _ToastOrder: number?,
    },
    CWindow
))

--[[
    CTab.new 建立的導覽分頁；Pages 是其子分頁，Sections 是跨子分頁的區塊清單。
    透過 CTab metatable 共用選取與搜尋行為。
]]
export type CTabType = typeof(setmetatable(
    {} :: {
        Window: CWindowType,
        Name: string,
        Pages: { PageState },
        Sections: { CSectionType },
        Frame: Frame,
        NavButton: TextButton,
        NavIcon: Frame,
        NavLabel: TextLabel,
        SubBar: ScrollingFrame?,
        ActivePage: PageState,
        _Scope: ScopeState,
    },
    CTab
))

--[[
    CSection.new 建立的元件區塊，保留所屬視窗、分頁與欄位位置。
    CSection metatable 提供各控制項工廠，Body 可能是普通 Frame 或可捲動容器。
]]
export type CSectionType = typeof(setmetatable(
    {} :: {
        Window: CWindowType,
        Tab: CTabType,
        Page: PageState,
        Side: ESectionSide,
        Name: string,
        Controls: { CControlType },
        bVisible: boolean,
        Frame: Frame,
        Title: TextLabel,
        Body: Frame | ScrollingFrame,
        _Scope: ScopeState,
    },
    CSection
))

--[[
    CControl.new 建立的共同基底；各工廠在回傳前安裝種類專屬的 Get、Set 與繪製方法。
    Value 為多種元件共用的資料欄位，因此不是單一 boolean 欄位。
    只有對應種類會建立 Input、Button、調色盤與下拉選單等可選欄位。
]]
type ControlFields = {
    Window: CWindowType,
    Section: CSectionType,
    Kind: EControlKind,
    Name: string,
    bEnabled: boolean,
    bVisible: boolean,
    bSave: boolean,
    bDestroyed: boolean,
    Flag: string?,
    Callback: ControlCallback?,
    Value: ControlValue?,
    Frame: Frame,
    Title: TextLabel?,
    Description: TextLabel?,
    Body: TextLabel?,
    Button: TextButton?,
    Stroke: UIStroke?,
    Input: TextBox?,
    Switch: TextButton?,
    Knob: Frame?,
    CheckGroup: CanvasGroup?,
    CheckScale: UIScale?,
    Track: Frame?,
    Percent: TextLabel?,
    Selection: TextLabel?,
    Arrow: Frame?,
    Chip: Frame?,
    HexLabel: TextLabel?,
    Range: { number }?,
    Increment: number?,
    Options: { NormalizedOption }?,
    bMulti: boolean?,
    bHold: boolean?,
    bGlobal: boolean?,
    bHasAlpha: boolean?,
    Alpha: number?,
    Color: Color3?,
    H: number?,
    S: number?,
    V: number?,
    Swatches: { Color3 }?,
    _Scope: ScopeState,
    _Interactive: { GuiObject },
    _bHeld: boolean?,
    _bKeepHSV: boolean?,
    _bRadioInitialized: boolean?,
    _LastHSVColor: Color3?,
    _PaintOptions: VoidCallback?,
    _PaletteRender: VoidCallback?,
    _Normalize: NormalizeCallback?,
    _Render: ((self: CControlType) -> ())?,
}

export type CControlType = typeof(setmetatable({} :: ControlFields, CControl))

--[[
    具單一值的控制項介面。ValueType 限定 Get/Set 的資料，
    例如 boolean 開關、number 滑桿、string 輸入框；其生命週期方法仍由 CControl 提供。
]]
export type CValueControlType<ValueType> = typeof(setmetatable(
    {} :: ControlFields & {
        Value: ValueType,
        Get: (self: CValueControlType<ValueType>) -> ValueType,
        Set: (
            self: CValueControlType<ValueType>,
            Value: ValueType,
            bSilent: boolean?
        ) -> CValueControlType<ValueType>,
    },
    CControl
))

--[[
    按鈕以 Name 保存文字；Fire 只在可互動時呼叫無參數 Callback。
    Set 更新文字，Get 回傳文字，兩者不保存 Flag 值。
]]
export type CButtonType = typeof(setmetatable(
    {} :: ControlFields & {
        Button: TextButton,
        Stroke: UIStroke,
        Get: (self: CButtonType) -> string,
        Set: (self: CButtonType, Text: string) -> CButtonType,
        Fire: (self: CButtonType) -> CButtonType,
    },
    CControl
))

--[[
    狀態標籤以 Name 保存文字；Get/Set 讀寫標籤文字，沒有獨立的 Value 初值。
    狀態色由建立時的 Status 決定，文字更新不改變狀態色或觸發值回呼。
]]
export type CBadgeType = typeof(setmetatable(
    {} :: ControlFields & {
        Title: TextLabel,
        Get: (self: CBadgeType) -> string,
        Set: (self: CBadgeType, Text: string) -> CBadgeType,
    },
    CControl
))

--[[
    下拉控制項提供浮層生命週期與動態選項更新。
    Refresh 的 bKeepSelection=false 會捨棄原選取，bSilent=true 不發出回呼。
    單選 Get 可為 nil，多選 Get 為獨立陣列複本；索引由 Callback 提供。
]]
export type CDropdownType = typeof(setmetatable(
    {} :: ControlFields & {
        Options: { NormalizedOption },
        bMulti: boolean,
        Button: TextButton,
        Selection: TextLabel,
        Arrow: Frame,
        Get: (self: CDropdownType) -> (OptionValue | { OptionValue })?,
        Set: (
            self: CDropdownType,
            Selection: (OptionValue | { OptionValue })?,
            bSilent: boolean?
        ) -> CDropdownType,
        Open: (self: CDropdownType) -> CDropdownType,
        Close: (self: CDropdownType) -> CDropdownType,
        Refresh: (
            self: CDropdownType,
            Options: { OptionDefinition },
            bKeepSelection: boolean?,
            bSilent: boolean?
        ) -> CDropdownType,
        _Selected: (self: CDropdownType, Value: OptionValue) -> boolean,
    },
    CControl
))

--[[
    調色盤 Get 固定回傳 Color3、Alpha；Set 的第二參數可以是 Alpha 或靜默旗標。
    Open/Close 只影響浮層，展開式調色盤保留在區塊內。
    H、S、V 分別為 0 到 1 的色相、飽和度與明度。
]]
export type CColorPickerType = typeof(setmetatable(
    {} :: ControlFields & {
        Color: Color3,
        Alpha: number,
        H: number,
        S: number,
        V: number,
        bHasAlpha: boolean,
        Swatches: { Color3 },
        Button: TextButton,
        Chip: Frame,
        HexLabel: TextLabel,
        Get: (self: CColorPickerType) -> (Color3, number),
        Set: (
            self: CColorPickerType,
            Color: ColorInput,
            Alpha: number | boolean?,
            bSilent: boolean?
        ) -> CColorPickerType,
        Open: (self: CColorPickerType) -> CColorPickerType,
        Close: (self: CColorPickerType) -> CColorPickerType,
        _SetHSV: (self: CColorPickerType, Hue: number, Saturation: number, Brightness: number) -> (),
    },
    CControl
))

--[[
    段落 Get 回傳標題與內文；Set 同時更新兩者，不發送控制項值回呼。
]]
export type CParagraphType = typeof(setmetatable(
    {} :: ControlFields & {
        Title: TextLabel,
        Body: TextLabel,
        Get: (self: CParagraphType) -> (string, string),
        Set: (self: CParagraphType, Title: string?, Body: string?) -> CParagraphType,
    },
    CControl
))

--[[
    通知控制柄只提供 Destroy；bDestroyed 在第一次銷毀後為 true。
    Destroy 可重複呼叫，且會移除該通知的連線與計時器。
    @param self 要關閉的通知控制柄。
]]
export type ToastType = { bDestroyed: boolean?, bClosing: boolean?, _bRemoved: boolean?, Destroy: (self: ToastType, bImmediate: boolean?) -> () }

--[[
    模組回傳表，並非透過 new 建立的類別。Windows 與 Flags 只記錄仍存在的物件。
    _Last 是最近建立的視窗，用於模組層級的 Notify。
]]
export type LibraryType = {
    Version: string,
    ConfigPath: string,
    Flags: { [string]: CControlType },
    Windows: { [string]: CWindowType },
    _Last: CWindowType?,
    CreateWindow: (self: LibraryType, Options: WindowOptions?) -> CWindowType,
    Notify: (self: LibraryType, Options: NotificationOptions) -> ToastType?,
    Demo: (self: LibraryType, Options: WindowOptions?) -> CWindowType,
    ParseSvg: (self: LibraryType, Source: string, Options: SvgParseOptions?) -> (SvgDefinition?, string?),
    RegisterSvg: (self: LibraryType, Name: string, Source: string, Options: SvgParseOptions?) -> (boolean, string?, { string }?),
}

--[[
    淺複製資料表，避免控制項向呼叫端暴露可直接修改的陣列。

    @param Values 來源資料表；複製時可為 nil，選項處理時依陣列順序讀取。
    @return 獨立的淺複本；輸入 nil 時為空表。
]]
local function _CopyTable(Values)
    local Copy = {}
    for Key, Item in pairs(Values or {}) do
        Copy[Key] = Item
    end
    return Copy
end

--[[
    判斷輸入是否為有限數值，排除 NaN 與正負無限大。

    @param Number 待驗證、限制或轉換的數值。
    @return true 表示有限數值；false 表示非數值、NaN 或無限大。
]]
local function _IsFinite(Number): boolean
    return type(Number) == "number" and Number == Number and Number > -math.huge and Number < math.huge
end

--[[
    將數值限制在指定的閉區間。

    @param Number 待驗證、限制或轉換的數值。
    @param Minimum 允許的最小值。
    @param Maximum 允許的最大值。
    @return 限制在 Minimum 與 Maximum 之間的數值。
]]
local function _Clamp(Number, Minimum: number, Maximum: number): number
    return math.max(Minimum, math.min(Maximum, Number))
end

--[[
    將輸入轉成有限數值，無法轉換時採用預設值。

    @param Number 待驗證、限制或轉換的數值。
    @param DefaultValue 輸入無法轉為有限數值時使用的預設。
    @return 有效輸入轉成的數值，或 DefaultValue。
]]
local function _NumberOr(Number, DefaultValue: number): number
    Number = tonumber(Number)
    return _IsFinite(Number) and Number or DefaultValue
end

--[[
    將名稱簡寫轉為選項表；傳入資料表時沿用該表。

    @param Settings 已正規化的設定表或允許的名稱簡寫。
    @return 原選項表或包含 Name 的新表。
]]
local function _Options(Settings)
    return type(Settings) == "table" and Settings or { Name = tostring(Settings or "") }
end

--[[
    將 RGB 顏色四捨五入後轉成大寫六位 HEX 字串。

    @param Color 要轉換的 RGB Color3。
    @return 含井號的大寫六位 HEX 字串。
]]
local function _ToHex(Color: Color3): string
    return string.format(
        "#%02X%02X%02X",
        math.floor(Color.R * 255 + 0.5),
        math.floor(Color.G * 255 + 0.5),
        math.floor(Color.B * 255 + 0.5)
    )
end

--[[
    解析 Color3、三位或六位 HEX 顏色。

    @param Value 待檢查或套用的值，依此控制項種類解讀。
    @return 解析後的 Color3；不支援或格式錯誤時為 nil。
]]
local function _ParseColor(Value): Color3?
    if typeof(Value) == "Color3" then
        return Value
    end
    if type(Value) == "string" then
        local Hex = Value:gsub("#", "")
        if #Hex == 3 and Hex:match("^%x+$") then
            Hex = Hex:gsub("(.)", "%1%1")
        end
        if #Hex == 6 and Hex:match("^%x+$") then
            return Color3.fromRGB(
                tonumber(Hex:sub(1, 2), 16),
                tonumber(Hex:sub(3, 4), 16),
                tonumber(Hex:sub(5, 6), 16)
            )
        end
    end
end

--[[
    遞迴比較兩個值；資料表按內容比較，不比較 metatable。

    @param First 要比較的第一個值。
    @param Second 要比較的第二個值。
    @return true 表示內容相等；false 表示型別或內容不同。
]]
local function _ValuesEqual(First, Second): boolean
    if First == Second then
        return true
    end
    if type(First) ~= "table" or type(Second) ~= "table" then
        return First == Second
    end
    for Key, Item in pairs(First) do
        if not _ValuesEqual(Item, Second[Key]) then
            return false
        end
    end
    for Key in pairs(Second) do
        if First[Key] == nil then
            return false
        end
    end
    return true
end

--[[
    建立獨立的事件與延遲工作生命週期容器。
    @return 尚未清理、沒有連線與計時器的 Scope。
]]
local function _CreateScope(): ScopeState
    return { _Connections = {}, _Timers = {}, _bDead = false }
end

--[[
    註冊事件，並將連線納入 Scope 的清理清單。

    @param Scope 管理此連線或工作生命週期的容器。
    @param Event 要監聽的 Rbx 事件。
    @param Callback 要執行的回呼；未提供函數時略過。
    @return 新建立的 RBXScriptConnection，會隨 Scope 清理。

    使用範例：
    前提：在本模組內，Button 是已建立的 TextButton。
    ```lua
    local Scope = _CreateScope()
    _Connect(Scope, Button.Activated, print)
    _CleanScope(Scope) -- 後續點擊不再呼叫 print
    ```
]]
local function _Connect(Scope: ScopeState, Event: RBXScriptSignal, Callback): RBXScriptConnection
    --[[
        只在 Scope 尚未清理時將事件參數轉交給已註冊的回呼。

        @param ... 依原始順序轉交的事件或回呼參數；保留尾端 nil 的數量。
    ]]
    local Connection = Event:Connect(function(...): ()
        if not Scope._bDead then
            Callback(...)
        end
    end)
    Scope._Connections[#Scope._Connections + 1] = Connection
    return Connection
end

--[[
    嘗試取消指定工作；不存在或已完成的工作不會向外拋出錯誤。

    @param Thread 要取消的工作；nil 表示沒有工作。
]]
local function _CancelTask(Thread: thread?): ()
    if Thread then
        pcall(task.cancel, Thread)
    end
end

--[[
    排程一次性延遲工作；執行前會先從 Scope 移除該計時器。

    @param Scope 管理此連線或工作生命週期的容器。
    @param Delay 延遲秒數。
    @param Callback 要執行的回呼；未提供函數時略過。
    @return 已登記在 Scope 的延遲工作。

    使用範例：
    前提：在本模組內。
    ```lua
    local Scope = _CreateScope()
    _Schedule(Scope, 1, print)
    _CleanScope(Scope) -- 一秒後的工作已取消
    ```
]]
local function _Schedule(Scope: ScopeState, Delay: number, Callback): thread
    local Thread

    --[[
        移除到期的計時器記錄，並在 Scope 仍有效時執行工作。
    ]]
    Thread = task.delay(Delay, function(): ()
        Scope._Timers[Thread] = nil
        if not Scope._bDead then
            Callback()
        end
    end)
    Scope._Timers[Thread] = true
    return Thread
end

--[[
    冪等地釋放 Scope 的所有連線與延遲工作，並標記其已停止。

    @param Scope 管理此連線或工作生命週期的容器。
]]
local function _CleanScope(Scope: ScopeState): ()
    if Scope._bDead then
        return
    end
    Scope._bDead = true
    for _, Control in ipairs(Scope._Connections) do
        Control:Disconnect()
    end
    for Thread in pairs(Scope._Timers) do
        _CancelTask(Thread)
    end
    Scope._Connections = {}
    Scope._Timers = {}
end

--[[
    非同步呼叫使用者回呼；擁有者已銷毀時略過，回呼錯誤以 warn 回報。

    @param Owner 回呼或浮層所屬物件，用於生命週期判斷。
    @param Callback 要執行的回呼；未提供函數時略過。
    @param ... 依原始順序轉交的事件或回呼參數；保留尾端 nil 的數量。

    使用範例：
    前提：在本模組內，Control 尚未銷毀。
    ```lua
    _InvokeCallback(Control, print, "已更新") -- 非同步輸出文字
    ```
]]
local function _InvokeCallback(Owner, Callback, ...): ()
    if type(Callback) ~= "function" then
        return
    end
    local Args = { Count = select("#", ...), ... }

    --[[
        檢查擁有者生命週期後執行回呼，並攔截回呼拋出的錯誤。
    ]]
    task.spawn(function(): ()
        if Owner.bDestroyed then
            return
        end
        local bOk, Err = pcall(Callback, _UnpackValues(Args, 1, Args.Count))
        if not bOk then
            warn("[BjzUi] Callback: " .. tostring(Err))
        end
    end)
end

--[[
    建立 Rbx Instance、套用屬性，最後設定 Parent；無效屬性會拋出錯誤。

    @param ClassName Instance.new 接受的 Rbx 類別名稱。
    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Properties 要套用的 Rbx 屬性與值。
    @return 已套用屬性並掛到 Parent 的 Instance。
]]
local function _CreateInstance(ClassName, Parent, Properties)
    local Object = Instance.new(ClassName)
    for Key, Item in pairs(Properties or {}) do
        Object[Key] = Item
    end
    Object.Parent = Parent
    return Object
end

--[[
    銷毀介面子樹，同步移除其主題綁定與尚在執行的 Tween。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Root 要銷毀的子樹根物件。
]]
local function _Dispose(Window: CWindowType, Root): ()
    local Items = Root:GetDescendants()
    Items[#Items + 1] = Root
    for _, Object in ipairs(Items) do
        if Window._SvgScopes[Object] then
            _CleanScope(Window._SvgScopes[Object])
            Window._SvgScopes[Object] = nil
        end
        Window._Bindings[Object] = nil
        Window._Feedback[Object] = nil
        if Window._Tweens[Object] then
            Window._Tweens[Object]:Cancel()
            Window._Tweens[Object] = nil
        end
    end
    Root:Destroy()
end

--[[
    由陣列尾端移除第一個相等項目，保留其他項目的順序。

    @param Array 要原地修改的連續陣列。
    @param Value 待檢查或套用的值，依此控制項種類解讀。
]]
local function _RemoveItem(Array, Value): ()
    for Index = #Array, 1, -1 do
        if Array[Index] == Value then
            table.remove(Array, Index)
            return
        end
    end
end

--[[
    為父物件建立 UICorner。

    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Radius 圓角半徑，單位為像素；nil 使用 8。
    @return 新建立的 UICorner。
]]
local function _Corner(Parent, Radius: number?): UICorner
    return _CreateInstance("UICorner", Parent, { CornerRadius = UDim.new(0, Radius or 5) })
end

--[[
    為父物件建立四邊等距的 UIPadding。

    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Number 四邊內距，單位為像素。
    @return 新建立的 UIPadding。
]]
local function _Padding(Parent, Number: number): UIPadding
    return _CreateInstance("UIPadding", Parent, {
        PaddingLeft = UDim.new(0, Number),
        PaddingRight = UDim.new(0, Number),
        PaddingTop = UDim.new(0, Number),
        PaddingBottom = UDim.new(0, Number),
    })
end

--[[
    建立依 LayoutOrder 排序的 UIListLayout。

    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Gap 項目間距，單位為像素；nil 使用 8。
    @return 新建立的 UIListLayout。
]]
local function _ListLayout(Parent, Gap: number?): UIListLayout
    return _CreateInstance(
        "UIListLayout",
        Parent,
        { Padding = UDim.new(0, Gap or 8), SortOrder = Enum.SortOrder.LayoutOrder }
    )
end

--[[
    建立透明、無邊框且預設不裁切子物件的 Frame。

    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Size GUI 尺寸；可省略的呼叫會採用函數預設尺寸。
    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
    @return 新建立的透明 Frame。
]]
local function _Frame(Parent, Size, Position): Frame
    return _CreateInstance("Frame", Parent, {
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        ClipsDescendants = false,
        Size = Size or UDim2.new(1, 0, 0, 32),
        Position = Position or UDim2.new(),
    })
end

--[[
    記錄主題屬性綁定，並立即套用目前主題的顏色。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Object 要套用屬性或檢查範圍的 Rbx Instance。
    @param Property 要綁定的 Rbx 顏色屬性名稱。
    @param Token 主題色名稱或同步求值的主題回呼；可省略時使用函數預設色。

    使用範例：
    前提：在本模組內，Window 與 Label 是已建立的視窗與文字標籤。
    ```lua
    _BindTheme(Window, Label, "TextColor3", "Accent")
    Window:SetAccent("#FF8800") -- Label 顏色跟著更新
    ```
]]
local function _BindTheme(Window: CWindowType, Object, Property, Token): ()
    local Item = Window._Bindings[Object] or {}
    Window._Bindings[Object] = Item
    Item[Property] = Token
    Object[Property] = type(Token) == "function" and Token(Window.Theme) or Window.Theme[Token]
end

--[[
    建立邊框 UIStroke 並綁定主題顏色。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Object 要套用屬性或檢查範圍的 Rbx Instance。
    @param Token 主題色名稱或同步求值的主題回呼；可省略時使用函數預設色。
    @return 已綁定主題的 UIStroke。
]]
local function _Stroke(Window: CWindowType, Object, Token): UIStroke
    local Border =
        _CreateInstance("UIStroke", Object, { Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
    _BindTheme(Window, Border, "Color", Token or "Border")
    return Border
end

--[[
    建立單行標籤，並綁定文字主題色。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Text 要顯示或搜尋的文字；接受 tostring 可轉換的值。
    @param Size GUI 尺寸；可省略的呼叫會採用函數預設尺寸。
    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
    @param FontSize 文字像素大小；nil 使用 13。
    @param Token 主題色名稱或同步求值的主題回呼；可省略時使用函數預設色。
    @return 已綁定主題的 TextLabel。
]]
local function _Label(Window: CWindowType, Parent, Text, Size, Position, FontSize: number?, Token): TextLabel
    local Object = _CreateInstance("TextLabel", Parent, {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = tostring(Text or ""),
        Size = Size or UDim2.new(1, 0, 0, 22),
        Position = Position or UDim2.new(),
        Font = Enum.Font.Gotham,
        TextSize = FontSize or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        RichText = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
    })
    _BindTheme(Window, Object, "TextColor3", Token or "Text")
    return Object
end

--[[
    建立停用原生自動變色的文字按鈕。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Text 要顯示或搜尋的文字；接受 tostring 可轉換的值。
    @param Size GUI 尺寸；可省略的呼叫會採用函數預設尺寸。
    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
    @param Kind 控制項種類或按鈕樣式，用於建立對應外觀。
    @return 新建立的 TextButton。
]]
local function _Button(Window: CWindowType, Parent, Text, Size, Position, Kind): TextButton
    local Object = _CreateInstance("TextButton", Parent, {
        Size = Size or UDim2.new(1, 0, 0, 34),
        Position = Position or UDim2.new(),
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = tostring(Text or ""),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        RichText = false,
        TextTruncate = Enum.TextTruncate.AtEnd,
        ClipsDescendants = false,
    })
    _BindTheme(Window, Object, "BackgroundColor3", Kind == "primary" and "Accent" or "Input")
    _BindTheme(Window, Object, "TextColor3", Kind == "primary" and "AccentText" or "Text")
    _Corner(Object, 4)
    _Stroke(Window, Object, Kind == "primary" and "Accent" or "Border")
    return Object
end

--[[
    建立輸入框、邊框與文字內距，供控制項註冊焦點行為。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Text 要顯示或搜尋的文字；接受 tostring 可轉換的值。
    @param Size GUI 尺寸；可省略的呼叫會採用函數預設尺寸。
    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
    @return 新建立的 TextBox。
    @return 輸入框使用的 UIStroke。
]]
local function _TextBox(Window: CWindowType, Parent, Text, Size, Position): (TextBox, UIStroke)
    local Object = _CreateInstance("TextBox", Parent, {
        Size = Size or UDim2.new(1, 0, 0, 34),
        Position = Position or UDim2.new(),
        BorderSizePixel = 0,
        Text = tostring(Text or ""),
        PlaceholderText = "",
        Font = Enum.Font.Gotham,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        MultiLine = false,
    })
    _BindTheme(Window, Object, "BackgroundColor3", "Input")
    _BindTheme(Window, Object, "TextColor3", "Text")
    _BindTheme(Window, Object, "PlaceholderColor3", "Muted")
    _Corner(Object, 4)
    local Border = _Stroke(Window, Object)
    _CreateInstance("UIPadding", Object, { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10) })
    return Object, Border
end

--[[
    建立沿垂直方向自動擴張 Canvas 的捲動容器。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Size GUI 尺寸；可省略的呼叫會採用函數預設尺寸。
    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
    @return 新建立的 ScrollingFrame。
]]
local function _ScrollingFrame(Window: CWindowType, Parent, Size, Position): ScrollingFrame
    local Object = _CreateInstance("ScrollingFrame", Parent, {
        Size = Size,
        Position = Position or UDim2.new(),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 3,
        ClipsDescendants = true,
    })
    _BindTheme(Window, Object, "ScrollBarImageColor3", "Border")
    return Object
end

--[[
    判斷事件是否由滑鼠左鍵或觸控開始。

    @param Input 開始或更新互動的 Rbx InputObject。
    @return true 表示滑鼠左鍵或觸控；false 表示其他輸入。
]]
local function _IsPointer(Input: InputObject): boolean
    return Input.UserInputType == Enum.UserInputType.MouseButton1
        or Input.UserInputType == Enum.UserInputType.Touch
end

--[[
    文字輸入框沿用原生邊框，避免子 Frame 被 UIPadding 縮小或位移。
    其他元件使用獨立邊框播放懸停／焦點動畫，不覆寫選取底色。
    Changed 只通知視覺狀態，可用於滑塊大小動畫，不會提交控制項值。
    浮層傳入自己的 Scope；_Dispose 同步移除其回饋記錄。
]]
local function _SetupFeedback(Window: CWindowType, Object: GuiObject, Scope: ScopeState, CanUse, Changed, Options: FeedbackOptions?): ()
    if Window._Feedback[Object] then
        return
    end
    local bTextBox = Object:IsA("TextBox")
    local Border, BaseToken
    if bTextBox then
        Border = Object:FindFirstChildOfClass("UIStroke") or _Stroke(Window, Object)
        BaseToken = Window._Bindings[Border] and Window._Bindings[Border].Color or "Border"
    else
        local Settings = Options or {}
        local Target = Settings.Target or Object
        local Inset = math.max(0, _NumberOr(Settings.Inset, 1))
        local Feedback = _Frame(Target, UDim2.new(1, -Inset * 2, 1, -Inset * 2), UDim2.fromOffset(Inset, Inset))
        Feedback.Name = "HoverFeedback"
        Feedback.Active = false
        Feedback.Selectable = false
        Feedback.ZIndex = Settings.ZIndex or Target.ZIndex
        local Corner = Target:FindFirstChildOfClass("UICorner")
        if Corner then
            _Corner(Feedback, 0).CornerRadius = UDim.new(Corner.CornerRadius.Scale, math.max(0, Corner.CornerRadius.Offset - Inset))
        end
        Border = _Stroke(Window, Feedback, Settings.Color or "Accent")
        Border.Transparency = 1
        Border.Thickness = 1.5
    end
    local bHovered, bSelected, bLastActive = false, false, false

    local function _Refresh(bReset: boolean?): ()
        if Scope._bDead or not Object.Parent then
            return
        end
        if bReset then
            bHovered, bSelected = false, false
        end
        local bFocused = not bReset and bTextBox and Object:IsFocused()
        local bActive = not Window.bDestroyed
            and (not CanUse or CanUse())
            and (bHovered or bSelected or bFocused)
        if bTextBox then
            _BindTheme(Window, Border, "Color", bActive and "Accent" or BaseToken)
        else
            Window:_Tween(Border, { Transparency = bActive and (bFocused and 0 or 0.2) or 1 })
        end
        if bActive ~= bLastActive then
            bLastActive = bActive
            if Changed then
                Changed(bActive)
            end
        end
    end
    Window._Feedback[Object] = _Refresh
    _Connect(Scope, Object.MouseEnter, function(): ()
        bHovered = true
        _Refresh()
    end)
    _Connect(Scope, Object.MouseLeave, function(): ()
        bHovered = false
        _Refresh()
    end)
    _Connect(Scope, Object.SelectionGained, function(): ()
        bSelected = true
        _Refresh()
    end)
    _Connect(Scope, Object.SelectionLost, function(): ()
        bSelected = false
        _Refresh()
    end)
    if Object:IsA("TextBox") then
        _Connect(Scope, Object.Focused, function(): ()
            _Refresh()
        end)
        _Connect(Scope, Object.FocusLost, function(): ()
            _Refresh()
        end)
    end
end

local function _SetupControlFeedback(Control: CControlType, Object: GuiObject, Scope: ScopeState?, CanUse, Changed, Options: FeedbackOptions?): ()
    _SetupFeedback(Control.Window, Object, Scope or Control._Scope, function(): boolean
        return Control:_CanUse() and (not CanUse or CanUse())
    end, Changed, Options)
end

--[[
    以絕對位置與尺寸判斷螢幕座標是否落在 GUI 範圍內。

    @param Object 要套用屬性或檢查範圍的 Rbx Instance。
    @param Point 要檢查的螢幕座標。
    @return true 表示座標在物件範圍內（含邊界）；false 表示在外。
]]
local function _ContainsPoint(Object, Point): boolean
    local Position, Size = Object.AbsolutePosition, Object.AbsoluteSize
    return Point.X >= Position.X
        and Point.Y >= Position.Y
        and Point.X <= Position.X + Size.X
        and Point.Y <= Position.Y + Size.Y
end

--[[
    將 KeyCode 或鍵位名稱轉為 Rbx KeyCode 列舉值。

    @param Value 待檢查或套用的值，依此控制項種類解讀。
    @return 解析後的 KeyCode；無效輸入時為 nil。
]]
local function _KeyFrom(Value): Enum.KeyCode?
    if typeof(Value) == "EnumItem" and Value.EnumType == Enum.KeyCode then
        return Value
    end
    if type(Value) == "string" then
        --[[
            查詢 KeyCode 成員，交由外層 pcall 處理無效名稱。
            @return 依名稱查得的 KeyCode。
        ]]
        local bOk, Key = pcall(function()
            return Enum.KeyCode[Value:gsub("Enum.KeyCode%.", "")]
        end)
        if bOk then
            return Key
        end
    end
    return nil
end

--[[
    從執行環境取得檔案函數；沒有該能力時回傳 nil。

    @param Name 顯示名稱、圖示名稱或查找鍵，依此函數用途解讀。
    @return 環境提供的能力值；沒有對應能力時為 nil，使用前仍須確認為 function。
]]
local function _FileFunction(Name)
    local Env = (type(getgenv) == "function" and getgenv()) or _G
    return Env[Name]
        or ({
            readfile = readfile,
            writefile = writefile,
            isfile = isfile,
            isfolder = isfolder,
            makefolder = makefolder,
        })[Name]
end

--[[
    讀取並驗證 UiConfig.json；不覆寫損毀或版本不支援的內容。
    @return 有效設定表；沒有檔案能力或檔案尚不存在時為預設空設定；讀取或格式錯誤時為 nil。
    @return 失敗原因；成功時為 nil。
]]
local function _ReadConfig(): (ConfigurationFile?, string?)
    local ReadFile, IsFile = _FileFunction("readfile"), _FileFunction("isfile")
    if type(ReadFile) ~= "function" then
        return { Version = 1, Windows = {} }
    end
    if type(IsFile) == "function" then
        local bOk, bExists = pcall(IsFile, CONFIG_PATH)
        if bOk and not bExists then
            return { Version = 1, Windows = {} }
        end
    end
    local bOk, Raw = pcall(ReadFile, CONFIG_PATH)
    if not bOk then
        return nil, "UiConfig.json 讀取失敗：" .. tostring(Raw)
    end

    --[[
        將已讀取的設定字串解碼；解析錯誤交由外層 pcall 處理。
        @return JSON 解碼後的資料，由外層繼續驗證格式。
    ]]
    local bDecoded, Data = pcall(function()
        return HttpService:JSONDecode(Raw)
    end)
    if not bDecoded or type(Data) ~= "table" or type(Data.Windows) ~= "table" then
        return nil, "UiConfig.json 無法解析；請先備份或修復，程式不會覆寫損毀內容。"
    end
    if Data.Version ~= 1 then
        return nil, "UiConfig.json 版本不支援，未覆寫。"
    end
    return Data
end

--[[
    建立設定資料夾並寫入 JSON；檔案或編碼錯誤轉為回傳狀態。

    @param Data 要編碼保存的 Version=1 設定表。
    @return true 表示寫入呼叫完成；false 表示能力缺失或發生錯誤。
    @return 成功時為設定路徑；失敗時為錯誤原因。

    使用範例：
    前提：執行環境提供 writefile；在本模組內。
    ```lua
    local bSaved, Result = _WriteConfig({ Version = 1, Windows = {} })
    print(bSaved, Result) -- 成功路徑或失敗原因
    ```
]]
local function _WriteConfig(Data): (boolean, string)
    local WriteFile, MakeFolder, IsFolder =
        _FileFunction("writefile"), _FileFunction("makefolder"), _FileFunction("isfolder")
    if type(WriteFile) ~= "function" then
        return false, "執行環境未提供 writefile。"
    end
    local bExists = false
    if type(IsFolder) == "function" then
        local bOk, Value = pcall(IsFolder, CONFIG_FOLDER)
        bExists = bOk and Value
    end
    if not bExists and type(MakeFolder) == "function" then
        pcall(MakeFolder, CONFIG_FOLDER)
    end

    --[[
        將設定表編碼後寫入固定設定路徑，供外層回報成功或錯誤。
    ]]
    local bOk, Err = pcall(function(): ()
        WriteFile(CONFIG_PATH, HttpService:JSONEncode(Data))
    end)
    return bOk, bOk and CONFIG_PATH or tostring(Err)
end

-- Inline vector icons: no HTTP or asset download for built-in icon names.

--[[
    內建向量圖示路徑；座標以 24×24 為基準，鍵名是公開圖示識別字。
]]
local ICON_PATHS = {
    minimize = { { 5, 17, 19, 17 } },
    maximize = { { 5, 5, 19, 5, 19, 19, 5, 19, 5, 5 } },
    restore = { { 9, 5, 19, 5, 19, 15 }, { 5, 9, 15, 9, 15, 19, 5, 19, 5, 9 } },
    close = { { 6, 6, 18, 18 }, { 18, 6, 6, 18 } },
    grid = {
        { 3, 3, 9, 3, 9, 9, 3, 9, 3, 3 },
        { 15, 3, 21, 3, 21, 9, 15, 9, 15, 3 },
        { 3, 15, 9, 15, 9, 21, 3, 21, 3, 15 },
        { 15, 15, 21, 15, 21, 21, 15, 21, 15, 15 },
    },
    home = { { 3, 11, 12, 3, 21, 11 }, { 6, 10, 6, 21, 10, 21, 10, 15, 14, 15, 14, 21, 18, 21, 18, 10 } },
    settings = {
        { 4, 6, 20, 6 },
        { 4, 12, 20, 12 },
        { 4, 18, 20, 18 },
        { 8, 3, 8, 9 },
        { 16, 9, 16, 15 },
        {
            10,
            15,
            10,
            21,
        },
    },
    eye = { { 2, 12, 7, 6, 17, 6, 22, 12, 17, 18, 7, 18, 2, 12 }, { 10, 10, 14, 10, 14, 14, 10, 14, 10, 10 } },
    code = { { 8, 5, 2, 12, 8, 19 }, { 16, 5, 22, 12, 16, 19 }, { 14, 3, 10, 21 } },
    file = {
        { 5, 2, 14, 2, 20, 8, 20, 22, 5, 22, 5, 2 },
        { 14, 2, 14, 8, 20, 8 },
        { 8, 12, 16, 12 },
        {
            8,
            17,
            16,
            17,
        },
    },
    bell = { { 5, 16, 6, 8, 9, 5, 15, 5, 18, 8, 19, 16, 5, 16 }, { 9, 20, 15, 20 }, { 12, 2, 12, 5 } },
    brush = { { 4, 20, 8, 19, 20, 7, 17, 4, 5, 16, 4, 20 }, { 5, 16, 8, 19 } },
    crosshair = {
        { 12, 2, 12, 8 },
        { 12, 16, 12, 22 },
        { 2, 12, 8, 12 },
        { 16, 12, 22, 12 },
        {
            7,
            7,
            17,
            7,
            17,
            17,
            7,
            17,
            7,
            7,
        },
    },
    skull = {
        { 5, 5, 9, 2, 15, 2, 19, 5, 20, 13, 17, 16, 17, 21, 7, 21, 7, 16, 4, 13, 5, 5 },
        { 8, 9, 9, 9 },
        { 15, 9, 16, 9 },
        { 10, 17, 10, 21 },
        { 14, 17, 14, 21 },
    },
    zap = { { 13, 2, 4, 14, 11, 14, 10, 22, 20, 9, 13, 9, 13, 2 } },
}

-- SVG stroke geometry. Coordinates and tangent vectors remain in SVG user units.
-- SVG2 path/arc algorithms: https://www.w3.org/TR/SVG2/paths.html
-- Path2D tangents are offsets from their associated control point, not absolute positions.
local CSvg = { Registered = {}, Builtins = {}, _bAvailable = nil, _Limit = 50 }

function CSvg._Fail(Message: string): never
    error("SVG: " .. Message, 0)
end

function CSvg._Skip(Reader): ()
    local _, Last = Reader.Text:find("^[%s,]*", Reader.Pos)
    Reader.Pos = Last and Last + 1 or Reader.Pos
end

function CSvg._Number(Reader): number
    CSvg._Skip(Reader)
    local Text, Start = Reader.Text, Reader.Pos
    local Pos = Start
    local Char = Text:sub(Pos, Pos)
    if Char == "+" or Char == "-" then Pos += 1 end
    local Digits = 0
    while Text:sub(Pos, Pos):match("%d") do Pos += 1; Digits += 1 end
    if Text:sub(Pos, Pos) == "." then
        Pos += 1
        while Text:sub(Pos, Pos):match("%d") do Pos += 1; Digits += 1 end
    end
    if Digits == 0 then CSvg._Fail("第 " .. Start .. " 字元應為數值。") end
    if Text:sub(Pos, Pos):match("[eE]") then
        Pos += 1
        Char = Text:sub(Pos, Pos)
        if Char == "+" or Char == "-" then Pos += 1 end
        local Exponent = Pos
        while Text:sub(Pos, Pos):match("%d") do Pos += 1 end
        if Pos == Exponent then CSvg._Fail("無效的科學記號。") end
    end
    local Value = tonumber(Text:sub(Start, Pos - 1))
    if not _IsFinite(Value) then CSvg._Fail("座標必須是有限數值。") end
    Reader.Pos = Pos
    return Value
end

function CSvg._Numbers(Text: string): { number }
    local Reader, Values = { Text = Text, Pos = 1 }, {}
    CSvg._Skip(Reader)
    while Reader.Pos <= #Text do
        Values[#Values + 1] = CSvg._Number(Reader)
        CSvg._Skip(Reader)
    end
    return Values
end

function CSvg._Length(Text, Default: number): number
    if Text == nil then return Default end
    local Reader = { Text = tostring(Text), Pos = 1 }
    local Value = CSvg._Number(Reader)
    local Unit = Reader.Text:sub(Reader.Pos):match("^%s*(.-)%s*$")
    if Unit ~= "" and Unit ~= "px" then CSvg._Fail("目前僅支援數字或 px 長度：" .. tostring(Text)) end
    return Value
end

function CSvg._Node(X: number, Y: number)
    return { X = X, Y = Y, LX = 0, LY = 0, RX = 0, RY = 0 }
end

function CSvg._Cubic(Points, X1, Y1, X2, Y2, X, Y): ()
    local Last = Points[#Points]
    Last.RX, Last.RY = X1 - Last.X, Y1 - Last.Y
    local Next = CSvg._Node(X, Y)
    Next.LX, Next.LY = X2 - X, Y2 - Y
    Points[#Points + 1] = Next
end

-- Endpoint-to-center conversion, including the SVG radii correction rules.
-- Arcs are approximated by cubic segments spanning at most 45 degrees.
function CSvg._Arc(Points, Rx, Ry, Degrees, bLarge, bSweep, X, Y): ()
    local Start = Points[#Points]
    local X0, Y0 = Start.X, Start.Y
    if X == X0 and Y == Y0 then return end
    Rx, Ry = math.abs(Rx), math.abs(Ry)
    if Rx == 0 or Ry == 0 then Points[#Points + 1] = CSvg._Node(X, Y); return end
    local Phi = math.rad(Degrees % 360)
    local Cos, Sin = math.cos(Phi), math.sin(Phi)
    local Dx, Dy = (X0 - X) / 2, (Y0 - Y) / 2
    local U, V = Cos * Dx + Sin * Dy, -Sin * Dx + Cos * Dy
    local Ratio = (U / Rx) ^ 2 + (V / Ry) ^ 2
    if Ratio > 1 then
        local Scale = math.sqrt(Ratio)
        Rx, Ry = Rx * Scale, Ry * Scale
    end
    local Denominator = Rx * Rx * V * V + Ry * Ry * U * U
    local Numerator = math.max(0, Rx * Rx * Ry * Ry - Denominator)
    local Factor = Denominator > 0 and math.sqrt(Numerator / Denominator) or 0
    if bLarge == bSweep then Factor = -Factor end
    local Cx0, Cy0 = Factor * Rx * V / Ry, -Factor * Ry * U / Rx
    local Cx = Cos * Cx0 - Sin * Cy0 + (X0 + X) / 2
    local Cy = Sin * Cx0 + Cos * Cy0 + (Y0 + Y) / 2
    local Ax, Ay = (U - Cx0) / Rx, (V - Cy0) / Ry
    local Bx, By = (-U - Cx0) / Rx, (-V - Cy0) / Ry
    local Angle = math.atan2(Ay, Ax)
    local Delta = math.atan2(Ax * By - Ay * Bx, Ax * Bx + Ay * By)
    if bSweep and Delta < 0 then Delta += 2 * math.pi end
    if not bSweep and Delta > 0 then Delta -= 2 * math.pi end
    local Count = math.max(1, math.ceil(math.abs(Delta) / (math.pi / 4)))
    local Step = Delta / Count
    local function _At(T)
        local C, S = math.cos(T), math.sin(T)
        return Cx + Rx * Cos * C - Ry * Sin * S, Cy + Rx * Sin * C + Ry * Cos * S,
            -Rx * Cos * S - Ry * Sin * C, -Rx * Sin * S + Ry * Cos * C
    end
    for Index = 1, Count do
        local T0, T1 = Angle + (Index - 1) * Step, Angle + Index * Step
        local Px, Py, Tx, Ty = _At(T0)
        local Qx, Qy, Ux, Uy = _At(T1)
        local K = 4 / 3 * math.tan(Step / 4)
        if Index == Count then Qx, Qy = X, Y end
        CSvg._Cubic(Points, Px + K * Tx, Py + K * Ty, Qx - K * Ux, Qy - K * Uy, Qx, Qy)
    end
end

function CSvg._Path(Text: string)
    local Reader = { Text = Text, Pos = 1 }
    local Paths, Points = {}, nil
    local X, Y, StartX, StartY = 0, 0, 0, 0
    local Command, Previous, CubicX, CubicY, QuadX, QuadY
    local Count = 0
    local function _Flush(bClosed)
        if Points and #Points >= 2 then
            local First, Last = Points[1], Points[#Points]
            if bClosed and #Points > 2 and First.X == Last.X and First.Y == Last.Y then
                First.LX, First.LY = Last.LX, Last.LY
                table.remove(Points)
            end
            Paths[#Paths + 1] = { Points = Points, bClosed = bClosed == true }
        end
        Points = nil
    end
    local function _Ensure()
        if not Points then Points = { CSvg._Node(X, Y) }; StartX, StartY = X, Y end
    end
    local function _Pair(bRelative)
        local Px, Py = CSvg._Number(Reader), CSvg._Number(Reader)
        return Px + (bRelative and X or 0), Py + (bRelative and Y or 0)
    end
    local function _Flag()
        CSvg._Skip(Reader)
        local Char = Text:sub(Reader.Pos, Reader.Pos)
        if Char ~= "0" and Char ~= "1" then CSvg._Fail("弧線旗標必須是 0 或 1。") end
        Reader.Pos += 1
        return Char == "1"
    end
    while true do
        CSvg._Skip(Reader)
        if Reader.Pos > #Text then break end
        local Char = Text:sub(Reader.Pos, Reader.Pos)
        if Char:match("%a") then Command = Char; Reader.Pos += 1 end
        if not Command then CSvg._Fail("路徑必須從 M 或 m 開始。") end
        local Upper, bRelative = Command:upper(), Command ~= Command:upper()
        if not Previous and Upper ~= "M" then CSvg._Fail("路徑必須從 M 或 m 開始。") end
        if Upper == "Z" then
            _Flush(true)
            X, Y = StartX, StartY
            Command, Previous = nil, "Z"
        elseif Upper == "M" then
            local Px, Py = _Pair(bRelative)
            _Flush(false)
            X, Y, StartX, StartY = Px, Py, Px, Py
            Points = { CSvg._Node(X, Y) }
            Previous = "M"
            Command = bRelative and "l" or "L"
        else
            _Ensure()
            if Upper == "L" then
                X, Y = _Pair(bRelative)
                Points[#Points + 1] = CSvg._Node(X, Y)
            elseif Upper == "H" then
                X = CSvg._Number(Reader) + (bRelative and X or 0)
                Points[#Points + 1] = CSvg._Node(X, Y)
            elseif Upper == "V" then
                Y = CSvg._Number(Reader) + (bRelative and Y or 0)
                Points[#Points + 1] = CSvg._Node(X, Y)
            elseif Upper == "C" or Upper == "S" then
                local X1, Y1
                if Upper == "C" then X1, Y1 = _Pair(bRelative)
                elseif Previous == "C" or Previous == "S" then X1, Y1 = 2 * X - CubicX, 2 * Y - CubicY
                else X1, Y1 = X, Y end
                local X2, Y2 = _Pair(bRelative)
                local Px, Py = _Pair(bRelative)
                CSvg._Cubic(Points, X1, Y1, X2, Y2, Px, Py)
                X, Y, CubicX, CubicY = Px, Py, X2, Y2
            elseif Upper == "Q" or Upper == "T" then
                local Qx, Qy
                if Upper == "Q" then Qx, Qy = _Pair(bRelative)
                elseif Previous == "Q" or Previous == "T" then Qx, Qy = 2 * X - QuadX, 2 * Y - QuadY
                else Qx, Qy = X, Y end
                local Px, Py = _Pair(bRelative)
                CSvg._Cubic(Points, X + 2 / 3 * (Qx - X), Y + 2 / 3 * (Qy - Y),
                    Px + 2 / 3 * (Qx - Px), Py + 2 / 3 * (Qy - Py), Px, Py)
                X, Y, QuadX, QuadY = Px, Py, Qx, Qy
            elseif Upper == "A" then
                local Rx, Ry, Rotation = CSvg._Number(Reader), CSvg._Number(Reader), CSvg._Number(Reader)
                local bLarge, bSweep = _Flag(), _Flag()
                local Px, Py = _Pair(bRelative)
                CSvg._Arc(Points, Rx, Ry, Rotation, bLarge, bSweep, Px, Py)
                X, Y = Px, Py
            else CSvg._Fail("不支援的路徑指令：" .. Upper) end
            Previous = Upper
        end
        Count += 1
        if Count > 8192 then CSvg._Fail("單一路徑指令過多。") end
    end
    _Flush(false)
    return Paths
end

function CSvg._Multiply(A, B)
    return { A[1]*B[1]+A[3]*B[2], A[2]*B[1]+A[4]*B[2], A[1]*B[3]+A[3]*B[4], A[2]*B[3]+A[4]*B[4],
        A[1]*B[5]+A[3]*B[6]+A[5], A[2]*B[5]+A[4]*B[6]+A[6] }
end

function CSvg._Transform(Text)
    local Matrix = { 1, 0, 0, 1, 0, 0 }
    if not Text then return Matrix end
    local Pos = 1
    while Pos <= #Text do
        local _, Last = Text:find("^[%s,]*", Pos)
        Pos = Last and Last + 1 or Pos
        if Pos > #Text then break end
        local First, Finish, Name, Body = Text:find("([%a]+)%s*%(([^()]*)%)", Pos)
        if First ~= Pos then CSvg._Fail("無效的 transform。") end
        local V, Part = CSvg._Numbers(Body), nil
        if Name == "matrix" and #V == 6 then Part = V
        elseif Name == "translate" and (#V == 1 or #V == 2) then Part = {1,0,0,1,V[1],V[2] or 0}
        elseif Name == "scale" and (#V == 1 or #V == 2) then Part = {V[1],0,0,V[2] or V[1],0,0}
        elseif Name == "rotate" and (#V == 1 or #V == 3) then
            local C, S, Cx, Cy = math.cos(math.rad(V[1])), math.sin(math.rad(V[1])), V[2] or 0, V[3] or 0
            Part = {C,S,-S,C,Cx-C*Cx+S*Cy,Cy-S*Cx-C*Cy}
        elseif Name == "skewX" and #V == 1 then Part = {1,0,math.tan(math.rad(V[1])),1,0,0}
        elseif Name == "skewY" and #V == 1 then Part = {1,math.tan(math.rad(V[1])),0,1,0,0}
        else CSvg._Fail("不支援或參數錯誤的 transform：" .. Name) end
        Matrix = CSvg._Multiply(Matrix, Part)
        Pos = Finish + 1
    end
    return Matrix
end

function CSvg._Decode(Text: string): string
    return (Text:gsub("&([^;]+);", function(Entity)
        local Named = { amp = "&", lt = "<", gt = ">", quot = '"', apos = "'" }
        if Named[Entity] then return Named[Entity] end
        local Number = Entity:match("^#x(%x+)$")
        local Value = Number and tonumber(Number, 16) or tonumber(Entity:match("^#(%d+)$"))
        if Value and Value >= 0 and Value <= 0x10FFFF and not (Value >= 0xD800 and Value <= 0xDFFF) then
            return utf8.char(Value)
        end
        CSvg._Fail("不支援的 XML entity：&" .. Entity .. ";")
    end))
end

function CSvg._Attributes(Text: string)
    local Attributes, Pos = {}, 1
    while Pos <= #Text do
        local _, Last = Text:find("^%s*", Pos)
        Pos = Last and Last + 1 or Pos
        if Pos > #Text then break end
        local First, Finish, Name, Quote = Text:find("([%w_:%-]+)%s*=%s*(['\"])", Pos)
        if First ~= Pos then CSvg._Fail("SVG 屬性必須使用引號。") end
        local EndQuote = Text:find(Quote, Finish + 1, true)
        if not EndQuote then CSvg._Fail("SVG 屬性的引號未結束。") end
        if Attributes[Name] ~= nil then CSvg._Fail("重複的 SVG 屬性：" .. Name) end
        Attributes[Name] = CSvg._Decode(Text:sub(Finish + 1, EndQuote - 1))
        Pos = EndQuote + 1
    end
    if Attributes.style then
        for Name, Value in Attributes.style:gmatch("([%w%-]+)%s*:%s*([^;]+)") do
            Attributes[Name] = Value:match("^%s*(.-)%s*$")
        end
    end
    return Attributes
end

function CSvg._Warn(Data, Message: string): ()
    if not table.find(Data.Warnings, Message) then Data.Warnings[#Data.Warnings + 1] = Message end
end

function CSvg._Paint(Value)
    if Value == "none" then return false end
    if Value == "currentColor" or Value == nil then return nil end
    local Parsed = _ParseColor(Value)
    if Parsed then return Parsed end
    local R, G, B = Value:match("^rgb%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$")
    if R then return Color3.fromRGB(_Clamp(tonumber(R),0,255),_Clamp(tonumber(G),0,255),_Clamp(tonumber(B),0,255)) end
    local Named = { black="#000000", white="#FFFFFF", red="#FF0000", green="#008000", blue="#0000FF",
        yellow="#FFFF00", gray="#808080", grey="#808080", orange="#FFA500", purple="#800080" }
    if Named[Value:lower()] then return _ParseColor(Named[Value:lower()]) end
    CSvg._Fail("不支援的描邊顏色：" .. tostring(Value))
end

function CSvg._Style(Parent, Attributes)
    local Style = _CopyTable(Parent)
    for _, Key in ipairs({"stroke","fill","stroke-width","stroke-opacity","display","visibility","vector-effect"}) do
        if Attributes[Key] and Attributes[Key] ~= "inherit" then Style[Key] = Attributes[Key] end
    end
    Style.Opacity = Parent.Opacity * _Clamp(CSvg._Length(Attributes.opacity, 1), 0, 1)
    Style.Matrix = CSvg._Multiply(Parent.Matrix, CSvg._Transform(Attributes.transform))
    Style.bHidden = Parent.bHidden or Style.display == "none"
    return Style
end

function CSvg._Shape(Name: string, A)
    local function _V(Key, Default) return CSvg._Length(A[Key], Default or 0) end
    if Name == "path" then return CSvg._Path(A.d or "") end
    if Name == "line" then
        return {{ Points={CSvg._Node(_V("x1"),_V("y1")),CSvg._Node(_V("x2"),_V("y2"))}, bClosed=false }}
    end
    if Name == "polyline" or Name == "polygon" then
        local Values, Points = CSvg._Numbers(A.points or ""), {}
        if #Values % 2 ~= 0 then CSvg._Fail("points 必須包含成對座標。") end
        for Index = 1, #Values, 2 do Points[#Points+1] = CSvg._Node(Values[Index], Values[Index+1]) end
        return {{ Points=Points, bClosed=Name == "polygon" }}
    end
    if Name == "circle" or Name == "ellipse" then
        local Cx, Cy = _V("cx"), _V("cy")
        local Rx = Name == "circle" and _V("r") or _V("rx")
        local Ry = Name == "circle" and Rx or _V("ry")
        if Rx < 0 or Ry < 0 then CSvg._Fail("圓形半徑不能為負數。") end
        if Rx == 0 or Ry == 0 then return {} end
        local Points = {CSvg._Node(Cx+Rx,Cy)}
        CSvg._Arc(Points,Rx,Ry,0,false,true,Cx-Rx,Cy)
        CSvg._Arc(Points,Rx,Ry,0,false,true,Cx+Rx,Cy)
        local Last = table.remove(Points)
        Points[1].LX, Points[1].LY = Last.LX, Last.LY
        return {{Points=Points,bClosed=true}}
    end
    if Name == "rect" then
        local X, Y, W, H = _V("x"), _V("y"), _V("width"), _V("height")
        if W < 0 or H < 0 then CSvg._Fail("矩形寬高不能為負數。") end
        if W == 0 or H == 0 then return {} end
        local Rx = _V("rx", A.ry and _V("ry") or 0)
        local Ry = _V("ry", Rx)
        if Rx < 0 or Ry < 0 then CSvg._Fail("圓角半徑不能為負數。") end
        Rx, Ry = math.min(Rx,W/2), math.min(Ry,H/2)
        if Rx == 0 or Ry == 0 then
            return {{Points={CSvg._Node(X,Y),CSvg._Node(X+W,Y),CSvg._Node(X+W,Y+H),CSvg._Node(X,Y+H)},bClosed=true}}
        end
        local Points = {CSvg._Node(X+Rx,Y),CSvg._Node(X+W-Rx,Y)}
        CSvg._Arc(Points,Rx,Ry,0,false,true,X+W,Y+Ry)
        Points[#Points+1] = CSvg._Node(X+W,Y+H-Ry)
        CSvg._Arc(Points,Rx,Ry,0,false,true,X+W-Rx,Y+H)
        Points[#Points+1] = CSvg._Node(X+Rx,Y+H)
        CSvg._Arc(Points,Rx,Ry,0,false,true,X,Y+H-Ry)
        Points[#Points+1] = CSvg._Node(X,Y+Ry)
        CSvg._Arc(Points,Rx,Ry,0,false,true,X+Rx,Y)
        local Last = table.remove(Points)
        Points[1].LX, Points[1].LY = Last.LX, Last.LY
        return {{Points=Points,bClosed=true}}
    end
    CSvg._Fail("不支援的 SVG 元素：<" .. Name .. ">")
end

function CSvg._Add(Data, Shapes, Style, Options): ()
    if Style.bHidden or Style.visibility == "hidden" or Style.visibility == "collapse" then return end
    local Stroke = Style.stroke
    local bFill = Style.fill ~= "none"
    if Stroke == "none" then
        if not bFill then return end
        if not Options.bOutlineFill then CSvg._Fail("填色圖形沒有描邊；請使用 fill='none' 與 stroke，或設定 bOutlineFill=true 只繪製輪廓。") end
        Stroke = Style.fill
    end
    if bFill then CSvg._Warn(Data, "Path2D 僅繪製輪廓，不繪製 SVG fill。") end
    local Color = CSvg._Paint(Stroke)
    local Width = CSvg._Length(Options.StrokeWidth, CSvg._Length(Style["stroke-width"],1))
    if Width < 0 then CSvg._Fail("stroke-width 不能為負數。") end
    local Opacity = Style.Opacity * _Clamp(CSvg._Length(Style["stroke-opacity"],1),0,1)
    if Width == 0 or Opacity == 0 then return end
    local M = Style.Matrix
    for _, Value in ipairs(M) do
        if not _IsFinite(Value) then CSvg._Fail("變換矩陣超出有限範圍。") end
    end
    local bNonScaling = Style["vector-effect"] == "non-scaling-stroke"
    if not bNonScaling then
        Width *= math.sqrt(math.abs(M[1]*M[4]-M[2]*M[3]))
        local XScale, YScale = M[1]^2+M[2]^2, M[3]^2+M[4]^2
        if math.abs(XScale-YScale)>0.000001 or math.abs(M[1]*M[3]+M[2]*M[4])>0.000001 then
            CSvg._Warn(Data,"非等比變換的描邊寬度以面積等效比例近似。")
        end
    end
    if not _IsFinite(Width) then CSvg._Fail("變換後的描邊寬度超出有限範圍。") end
    for _, Shape in ipairs(Shapes) do
        if #Shape.Points >= 2 then
            for _, P in ipairs(Shape.Points) do
                P.X, P.Y = M[1]*P.X+M[3]*P.Y+M[5], M[2]*P.X+M[4]*P.Y+M[6]
                P.LX, P.LY = M[1]*P.LX+M[3]*P.LY, M[2]*P.LX+M[4]*P.LY
                P.RX, P.RY = M[1]*P.RX+M[3]*P.RY, M[2]*P.RX+M[4]*P.RY
                for _, V in ipairs({P.X,P.Y,P.LX,P.LY,P.RX,P.RY}) do
                    if not _IsFinite(V) then CSvg._Fail("變換後的座標超出有限範圍。") end
                end
            end
            Shape.Color, Shape.StrokeWidth, Shape.Opacity = Color, Width, Opacity
            Shape.bNonScalingStroke = bNonScaling
            Data.Paths[#Data.Paths+1] = Shape
            Data.PointCount += #Shape.Points
            if Data.PointCount > 16384 or #Data.Paths > 2048 then CSvg._Fail("SVG 圖示過於複雜。") end
        end
    end
end

function CSvg._Parse(Source: string, Options)
    if type(Source) ~= "string" or #Source == 0 then CSvg._Fail("請提供 SVG 字串或 path d。") end
    if #Source > 262144 then CSvg._Fail("SVG 字串超過 256 KiB。") end
    if Source:sub(1,3) == "\239\187\191" then Source = Source:sub(4) end
    local Data = {ViewBox=type(Options.ViewBox)=="table" and table.clone(Options.ViewBox) or Options.ViewBox or {0,0,24,24},Paths={},Warnings={},PointCount=0,AspectRatio="xMidYMid meet"}
    local Default = {stroke="none",fill="black",["stroke-width"]="1",["stroke-opacity"]="1",Opacity=1,
        Matrix={1,0,0,1,0,0},bHidden=false}
    if not Source:match("^%s*<") then
        Default.stroke, Default.fill = "currentColor", "none"
        CSvg._Add(Data,CSvg._Path(Source),Default,Options)
    else
        local Stack, Pos, bRoot, bRootClosed = {}, 1, false, false
        while Pos <= #Source do
            local First = Source:find("<",Pos,true)
            if not First then
                if Source:sub(Pos):match("%S") then CSvg._Fail("SVG 中含有不支援的文字內容。") end
                break
            end
            local Text = Source:sub(Pos,First-1)
            local Top = Stack[#Stack]
            if Text:match("%S") and not (Top and Top.bSkip) then CSvg._Fail("SVG 中含有不支援的文字內容。") end
            if Source:sub(First,First+3) == "<!--" then
                local Finish = Source:find("-->",First+4,true)
                if not Finish then CSvg._Fail("SVG 註解未結束。") end
                Pos = Finish+3
            elseif Source:sub(First,First+1) == "<?" then
                local Finish = Source:find("?>",First+2,true)
                if not Finish then CSvg._Fail("XML 宣告未結束。") end
                Pos = Finish+2
            else
                local Finish, Quote = First+1, nil
                while Finish <= #Source do
                    local C = Source:sub(Finish,Finish)
                    if Quote then if C == Quote then Quote = nil end
                    elseif C == '"' or C == "'" then Quote = C
                    elseif C == ">" then break end
                    Finish += 1
                end
                if Finish > #Source then CSvg._Fail("SVG 標籤未結束。") end
                local Tag = Source:sub(First+1,Finish-1)
                local bClosing, bSelf = Tag:match("^%s*/") ~= nil, Tag:match("/%s*$") ~= nil
                local Name, Body = Tag:match("^%s*/?%s*([%w_:%-]+)(.*)$")
                if not Name then CSvg._Fail("不支援 XML declaration/DOCTYPE。") end
                Name = Name:match("([^:]+)$"):lower()
                if bClosing then
                    if not Top or Top.Name ~= Name or Body:match("%S") then CSvg._Fail("SVG 結束標籤不匹配。") end
                    table.remove(Stack)
                    if Name == "svg" then bRootClosed = true end
                else
                    if bRootClosed then CSvg._Fail("SVG 只能有一個根節點。") end
                    if bSelf then Body = Body:gsub("/%s*$","") end
                    local A = CSvg._Attributes(Body)
                    local Style = CSvg._Style(Top and Top.Style or Default,A)
                    local bSkip = Top and Top.bSkip or Name == "title" or Name == "desc" or Name == "metadata" or Name == "defs"
                    if not bSkip then
                        for _, Key in ipairs({"clip-path","mask","filter"}) do
                            if A[Key] and A[Key] ~= "none" then CSvg._Fail("不支援 " .. Key .. "。") end
                        end
                    end
                    if Name == "svg" then
                        if bRoot then CSvg._Fail("目前不支援巢狀 svg viewport。") end
                        bRoot = true
                        if not Options.ViewBox then
                            Data.ViewBox = A.viewBox and CSvg._Numbers(A.viewBox)
                                or {0,0,CSvg._Length(A.width,24),CSvg._Length(A.height,24)}
                        end
                        Data.AspectRatio = A.preserveAspectRatio or Data.AspectRatio
                        if bSelf then bRootClosed = true end
                    elseif not bRoot then CSvg._Fail("SVG 根節點必須是 <svg>。")
                    elseif not bSkip and Name ~= "g" then
                        CSvg._Add(Data,CSvg._Shape(Name,A),Style,Options)
                    end
                    if not bSelf then
                        Stack[#Stack+1] = {Name=Name,Style=Style,bSkip=bSkip}
                        if #Stack > 64 then CSvg._Fail("SVG 群組巢狀過深。") end
                    end
                end
                Pos = Finish+1
            end
        end
        if not bRoot or not bRootClosed or #Stack > 0 then CSvg._Fail("SVG 根節點或標籤未完整關閉。") end
    end
    local V = Data.ViewBox
    if type(V) ~= "table" or #V ~= 4 then CSvg._Fail("ViewBox 必須是 {x,y,width,height}。") end
    for _, Value in ipairs(V) do if not _IsFinite(Value) then CSvg._Fail("ViewBox 必須包含有限數值。") end end
    if V[3] <= 0 or V[4] <= 0 then CSvg._Fail("ViewBox 寬高必須大於零。") end
    if #Data.Paths == 0 then CSvg._Fail("SVG 沒有可繪製的描邊路徑。") end
    return Data
end

function CSvg.Parse(Source: string, Options)
    local bOk, Result = pcall(CSvg._Parse,Source,Options or {})
    return bOk and Result or nil, not bOk and tostring(Result) or nil
end

function CSvg.Available(): (boolean, string?)
    if CSvg._bAvailable ~= nil then return CSvg._bAvailable, CSvg._UnavailableReason end
    local Probe
    local bOk, Err = pcall(function(): ()
        Probe = Instance.new("Path2D")
        Probe:SetControlPoints({Path2DControlPoint.new(UDim2.new()),Path2DControlPoint.new(UDim2.fromScale(1,1))})
        local bLimit, Limit = pcall(function() return Probe:GetMaxControlPoints() end)
        if bLimit and _IsFinite(Limit) then CSvg._Limit = math.max(2,math.floor(Limit)) end
    end)
    if Probe then Probe:Destroy() end
    CSvg._bAvailable = bOk
    CSvg._UnavailableReason = not bOk and ("目前用戶端無法建立 Path2D：" .. tostring(Err)) or nil
    return bOk, CSvg._UnavailableReason
end

function CSvg._GuiScale(Host): number
    local Scale, Current = 1, Host
    while Current do
        local Modifier = Current:FindFirstChildOfClass("UIScale")
        if Modifier then Scale *= Modifier.Scale end
        if Current:IsA("ScreenGui") then break end
        Current = Current.Parent
    end
    return math.max(Scale,0.0001)
end

function CSvg._Chunks(Shape)
    local Points, Chunks = Shape.Points, {}
    local bClosed = Shape.bClosed and #Points >= 3 and #Points <= CSvg._Limit
    if Shape.bClosed and not bClosed then
        Points = table.clone(Points)
        Points[#Points+1] = Points[1]
    end
    local Start = 1
    while Start < #Points do
        local Finish = math.min(#Points,Start+CSvg._Limit-1)
        local Nodes = {}
        for Index = Start, Finish do Nodes[#Nodes+1] = Points[Index] end
        Chunks[#Chunks+1] = {Points=Nodes,bClosed=bClosed}
        Start = Finish
    end
    return Chunks
end

function CSvg.Render(Window: CWindowType, Host: Frame, Data, Options, Token): (boolean, string?)
    local bAvailable, Err = CSvg.Available()
    if not bAvailable then return false, Err end
    Options = Options or {}
    local Scope, Rendered = _CreateScope(), {}
    local Canvas = _Frame(Host,UDim2.fromScale(1,1))
    Canvas.Name = "SvgViewport"
    local V = Data.ViewBox
    local Padding = math.max(0,_NumberOr(Options.Padding,0))
    local Aspect = (Data.AspectRatio or "xMidYMid meet"):match("^%s*(.-)%s*$")
    local Alignment, Mode = Aspect:match("^(x%a+Y%a+)%s*(%a*)$")
    local Alignments = {xMinYMin=true,xMidYMin=true,xMaxYMin=true,xMinYMid=true,xMidYMid=true,xMaxYMid=true,xMinYMax=true,xMidYMax=true,xMaxYMax=true}
    if Aspect ~= "none" and (not Alignment or not Alignments[Alignment]
        or (Mode ~= "" and Mode ~= "meet" and Mode ~= "slice")) then
        _Dispose(Window,Canvas)
        return false,"SVG: 不支援的 preserveAspectRatio：" .. Aspect
    end
    if Mode == "slice" then Host.ClipsDescendants = true end
    local FixedColor = _ParseColor(Options.Color)
    local Opacity = _Clamp(_NumberOr(Options.Opacity,1),0,1)
    local bOk, RenderError = pcall(function(): ()
        for _, Shape in ipairs(Data.Paths) do
            for _, Chunk in ipairs(CSvg._Chunks(Shape)) do
                local Native = _CreateInstance("Path2D",Canvas,{
                    Name="SvgPath",Closed=Chunk.bClosed,Thickness=1,Visible=true,ZIndex=Host.ZIndex,
                })
                local Points = {}
                for _, P in ipairs(Chunk.Points) do
                    Points[#Points+1] = Path2DControlPoint.new(
                        UDim2.fromScale((P.X-V[1])/V[3],(P.Y-V[2])/V[4]),
                        UDim2.fromScale(P.LX/V[3],P.LY/V[4]),
                        UDim2.fromScale(P.RX/V[3],P.RY/V[4])
                    )
                end
                Native:SetControlPoints(Points)
                if FixedColor then Native.Color3 = FixedColor
                elseif Options.bPreserveColors and Shape.Color then Native.Color3 = Shape.Color
                else _BindTheme(Window,Native,"Color3",Token or "Accent") end
                local Alpha = Shape.Opacity * Opacity
                if Alpha < 1 or Options.bDynamicOpacity then
                    _CreateInstance("UIGradient",Native,{
                        Color=ColorSequence.new(Color3.new(1,1,1)),Transparency=NumberSequence.new(1-Alpha),
                    })
                end
                Rendered[#Rendered+1] = {Object=Native,Shape=Shape}
            end
        end
    end)
    if not bOk then
        _CleanScope(Scope)
        _Dispose(Window,Canvas)
        return false,"SVG Path2D 建立失敗：" .. tostring(RenderError)
    end
    local function _LayoutSvg(): ()
        if Scope._bDead or not Host.Parent then return end
        local GuiScale = CSvg._GuiScale(Host)
        local Width, Height = Host.AbsoluteSize.X/GuiScale,Host.AbsoluteSize.Y/GuiScale
        local W, H = math.max(0,Width-Padding*2),math.max(0,Height-Padding*2)
        Canvas.Visible = W > 0 and H > 0
        local Sx, Sy = W/V[3],H/V[4]
        if Aspect ~= "none" then
            local Scale = Mode == "slice" and math.max(Sx,Sy) or math.min(Sx,Sy)
            Sx, Sy = Scale, Scale
        end
        local Cw, Ch = Sx*V[3],Sy*V[4]
        local X, Y = (W-Cw)/2,(H-Ch)/2
        if Alignment then
            if Alignment:find("xMin",1,true) then X=0 elseif Alignment:find("xMax",1,true) then X=W-Cw end
            if Alignment:find("YMin",1,true) then Y=0 elseif Alignment:find("YMax",1,true) then Y=H-Ch end
        elseif Aspect == "none" then X,Y=0,0 end
        Canvas.Position = UDim2.fromOffset(Padding+X,Padding+Y)
        Canvas.Size = UDim2.fromOffset(Cw,Ch)
        Canvas.ZIndex = Host.ZIndex
        for _, Item in ipairs(Rendered) do
            local Shape = Item.Shape
            local Scale = Shape.bNonScalingStroke and 1 or math.sqrt(math.abs(Sx*Sy))
            Item.Object.Thickness = _Clamp(Shape.StrokeWidth*Scale*_NumberOr(Options.StrokeScale,1),0,100)
            Item.Object.ZIndex = Host.ZIndex
        end
    end
    local bLaidOut, LayoutError = pcall(_LayoutSvg)
    if not bLaidOut then
        _CleanScope(Scope)
        _Dispose(Window,Canvas)
        return false,"SVG 版面建立失敗：" .. tostring(LayoutError)
    end
    Window._SvgScopes[Host] = Scope
    _Connect(Scope,Host:GetPropertyChangedSignal("AbsoluteSize"),_LayoutSvg)
    _Connect(Scope,Host:GetPropertyChangedSignal("ZIndex"),_LayoutSvg)
    _Connect(Scope,Host.Destroying,function(): ()
        Window._SvgScopes[Host] = nil
        for _, Item in ipairs(Rendered) do Window._Bindings[Item.Object] = nil end
        _CleanScope(Scope)
    end)
    return true
end

function Library.ParseSvg(self: LibraryType, Source: string, Options: SvgParseOptions?): (SvgDefinition?, string?)
    return CSvg.Parse(Source,Options)
end

function Library.RegisterSvg(self: LibraryType, Name: string, Source: string, Options: SvgParseOptions?): (boolean, string?, { string }?)
    if type(Name) ~= "string" or not Name:match("^[%w_%-]+$") then
        return false,"SVG 名稱僅能包含英數字、底線或連字號。"
    end
    local Data, Err = CSvg.Parse(Source,Options)
    if not Data then return false,Err end
    CSvg.Registered[Name] = {Data=Data,Source=Source,Options=_CopyTable(Options)}
    return true,nil,table.clone(Data.Warnings)
end

-- Returns a Frame owned by this window. Destroying the frame releases its SVG listeners.
function CWindow.CreateSvg(self: CWindowType, Options: SvgOptions): (Frame?, string?, { string }?)
    Options = Options or {}
    if self.bDestroyed then return nil,"視窗已銷毀。" end
    local Registered = CSvg.Registered[Options.Svg]
    local Settings = Registered and _CopyTable(Registered.Options) or {}
    for Key, Value in pairs(Options) do Settings[Key] = Value end
    local Data, Err
    if Registered and Options.ViewBox == nil and Options.StrokeWidth == nil and Options.bOutlineFill == nil then
        Data = Registered.Data
    else
        Data,Err = CSvg.Parse(Registered and Registered.Source or Options.Svg,Settings)
    end
    if not Data then return nil,Err end
    local Parent = Settings.Parent or self.Body
    if typeof(Parent) ~= "Instance" or not Parent:IsA("GuiObject") then return nil,"SVG Parent 必須是 GuiObject。" end
    local Host = _Frame(Parent,Settings.Size or UDim2.fromOffset(48,48),Settings.Position)
    Host.Name = Settings.Name or "SvgIcon"
    Host.ZIndex = _NumberOr(Settings.ZIndex,1)
    Host.ClipsDescendants = Data.AspectRatio:find("slice",1,true) ~= nil
    local bOk, RenderErr = CSvg.Render(self,Host,Data,Settings,Settings.bUseAccent == false and "Text" or "Accent")
    if not bOk then _Dispose(self,Host); return nil,RenderErr end
    return Host,nil,table.clone(Data.Warnings)
end

-- Built-in names use the same SVG converter. The old polyline data remains a fallback
-- only for clients without the native Path2D API.
CSvg.Sources = {
    -- User-provided SVG paths; normalized to 24x24 and rendered as theme-colored outlines.
    Coin = '<g transform="translate(2 1.5) scale(1)" vector-effect="non-scaling-stroke"><path d="M9 13.858h-.051A.949.949 0 0 1 8 12.909a1 1 0 1 0-2 0 2.949 2.949 0 0 0 2.949 2.949H9v1a1 1 0 0 0 2 0v-1a3 3 0 0 0 0-6v-2h.022c.54 0 .978.438.978.978a1 1 0 0 0 2 0 2.978 2.978 0 0 0-2.978-2.978H11v-1a1 1 0 0 0-2 0v1a3 3 0 1 0 0 6v2zm2 0v-2a1 1 0 0 1 0 2zm-2-6v2a1 1 0 1 1 0-2zm1 13c-5.523 0-10-4.477-10-10s4.477-10 10-10 10 4.477 10 10-4.477 10-10 10z"/></g>',
    TreasureChest = '<g transform="translate(0 0) scale(1)" vector-effect="non-scaling-stroke"><path d="M21 12.4984L14 12.4984M3 12.4984L10 12.4984M7 4.5V19.4984M17 4.5V19.4984M6.2 19.5H17.8C18.9201 19.5 19.4802 19.5 19.908 19.282C20.2843 19.0903 20.5903 18.7843 20.782 18.408C21 17.9802 21 17.4201 21 16.3V10.9C21 8.65979 21 7.53968 20.564 6.68404C20.1805 5.93139 19.5686 5.31947 18.816 4.93597C17.9603 4.5 16.8402 4.5 14.6 4.5H9.4C7.15979 4.5 6.03968 4.5 5.18404 4.93597C4.43139 5.31947 3.81947 5.93139 3.43597 6.68404C3 7.53968 3 8.65979 3 10.9V16.3C3 17.4201 3 17.9802 3.21799 18.408C3.40973 18.7843 3.71569 19.0903 4.09202 19.282C4.51984 19.5 5.07989 19.5 6.2 19.5ZM10 10.4984H14V14.4984H10V10.4984Z"/></g>',
    Potion = '<g transform="translate(0 0) scale(0.046875)" vector-effect="non-scaling-stroke"><path d="M500.335,51.437l-39.771-39.771c-15.554-15.554-40.863-15.554-56.418,0l-14.051,14.051l-4.121-4.121 c-8.654-8.654-22.687-8.654-31.343,0c-8.655,8.654-8.655,22.687,0,31.343l4.121,4.121l-84.825,84.825 c-72.727-33.061-159.858-17.93-217.185,39.395C20.152,217.873,0,266.523,0,318.269c0,51.746,20.152,100.396,56.741,136.987 c36.591,36.592,85.24,56.743,136.989,56.743c51.747,0,100.398-20.152,136.987-56.743c57.327-57.325,72.455-144.456,39.397-217.185 l84.825-84.825l4.121,4.121c4.328,4.328,10,6.492,15.671,6.492c5.671,0,11.344-2.165,15.671-6.492 c8.655-8.654,8.655-22.687,0-31.343l-4.121-4.121l14.051-14.051C515.889,92.299,515.889,66.991,500.335,51.437z M118.642,394.071 c-14.418,0-26.148-11.73-26.148-26.149s11.73-26.148,26.148-26.148c14.419,0,26.149,11.729,26.149,26.148 S133.062,394.071,118.642,394.071z M168.522,451.883c-14.419,0-26.149-11.729-26.149-26.148s11.73-26.148,26.149-26.148 c14.418,0,26.148,11.729,26.148,26.148S182.94,451.883,168.522,451.883z M248.982,431.841c-14.419,0-26.149-11.729-26.149-26.148 s11.73-26.148,26.149-26.148c14.418,0,26.148,11.729,26.148,26.148S263.4,431.841,248.982,431.841z M328.033,217.471 c-0.123,0.123-0.225,0.256-0.344,0.381c-7.088,6.854-8.969,17.856-3.883,26.832c4.124,7.277,7.572,14.797,10.362,22.479 c-22.254-4.267-45.357-4.103-67.533,0.584c-12.506,2.642-25.363,3.341-38.049,2.139c-0.158-0.047-0.307-0.109-0.467-0.152 l-22.967-6.245c-25.997-7.067-53.673-7.859-80.033-2.29c-20.585,4.35-42.12,3.463-62.276-2.562l-5.458-1.631 c7.342-16.322,17.665-31.344,30.7-44.379c47.349-47.347,121.051-57.395,179.231-24.431c8.966,5.08,19.957,3.208,26.813-3.862 c0.132-0.124,0.272-0.233,0.4-0.362l95.565-95.566l33.503,33.503L328.033,217.471z"/></g>',
    People = '<g transform="translate(0 0) scale(0.8571428571428571)" vector-effect="non-scaling-stroke"><path d="M17.75,18 C18.7164983,18 19.5,18.7835017 19.5,19.75 L19.5,21.7519766 L19.4921156,21.8604403 C19.1813607,23.9866441 17.2715225,25.0090369 14.0667905,25.0090369 C10.8736123,25.0090369 8.93330141,23.9983408 8.51446278,21.8965776 L8.5,21.75 L8.5,19.75 C8.5,18.7835017 9.28350169,18 10.25,18 L17.75,18 Z M18.2439108,11.9999135 L24.25,12 C25.2164983,12 26,12.7835017 26,13.75 L26,15.7519766 L25.9921156,15.8604403 C25.6813607,17.9866441 23.7715225,19.0090369 20.5667905,19.0090369 L20.3985759,19.007437 C20.0900029,17.9045277 19.1110503,17.0815935 17.9288034,17.0057197 L17.75,17 L16.8277704,17.0007255 C17.8477843,16.1757619 18.5,14.9140475 18.5,13.5 C18.5,12.9740145 18.4097576,12.4691063 18.2439108,11.9999135 Z M3.75,12 L9.75608915,11.9999135 C9.59024243,12.4691063 9.5,12.9740145 9.5,13.5 C9.5,14.8308682 10.0777413,16.0267978 10.996103,16.8506678 L11.1722296,17.0007255 L10.25,17 C8.9877951,17 7.92420242,17.85036 7.60086562,19.0094363 L7.5667905,19.0090369 C4.37361228,19.0090369 2.43330141,17.9983408 2.01446278,15.8965776 L2,15.75 L2,13.75 C2,12.7835017 2.78350169,12 3.75,12 Z M14,10 C15.9329966,10 17.5,11.5670034 17.5,13.5 C17.5,15.4329966 15.9329966,17 14,17 C12.0670034,17 10.5,15.4329966 10.5,13.5 C10.5,11.5670034 12.0670034,10 14,10 Z M20.5,4 C22.4329966,4 24,5.56700338 24,7.5 C24,9.43299662 22.4329966,11 20.5,11 C18.5670034,11 17,9.43299662 17,7.5 C17,5.56700338 18.5670034,4 20.5,4 Z M7.5,4 C9.43299662,4 11,5.56700338 11,7.5 C11,9.43299662 9.43299662,11 7.5,11 C5.56700338,11 4,9.43299662 4,7.5 C4,5.56700338 5.56700338,4 7.5,4 Z"/></g>',
    Food = '<g transform="translate(0 0.75) scale(0.1953125)" vector-effect="non-scaling-stroke"><path d="M29.03,100.46l20.79-25.21l9.51,12.13L41,110.69C33.98,119.61,20.99,110.21,29.03,100.46L29.03,100.46z M53.31,43.05 c1.98-6.46,1.07-11.98-6.37-20.18L28.76,1c-2.58-3.03-8.66,1.42-6.12,5.09L37.18,24c2.75,3.34-2.36,7.76-5.2,4.32L16.94,9.8 c-2.8-3.21-8.59,1.03-5.66,4.7c4.24,5.1,10.8,13.43,15.04,18.53c2.94,2.99-1.53,7.42-4.43,3.69L6.96,18.32 c-2.19-2.38-5.77-0.9-6.72,1.88c-1.02,2.97,1.49,5.14,3.2,7.34L20.1,49.06c5.17,5.99,10.95,9.54,17.67,7.53 c1.03-0.31,2.29-0.94,3.64-1.77l44.76,57.78c2.41,3.11,7.06,3.44,10.08,0.93l0.69-0.57c3.4-2.83,3.95-8,1.04-11.34L50.58,47.16 C51.96,45.62,52.97,44.16,53.31,43.05L53.31,43.05z M65.98,55.65l7.37-8.94C63.87,23.21,99-8.11,116.03,6.29 C136.72,23.8,105.97,66,84.36,55.57l-8.73,11.09L65.98,55.65L65.98,55.65z"/></g>',
    Grid = '<rect x="3" y="3" width="6" height="6" rx="1"/><rect x="15" y="3" width="6" height="6" rx="1"/><rect x="3" y="15" width="6" height="6" rx="1"/><rect x="15" y="15" width="6" height="6" rx="1"/>',
    Home = '<path d="M3 11L12 3 21 11M6 10V21H10V15H14V21H18V10"/>',
    Settings = '<path d="M4 6H20M4 12H20M4 18H20"/><circle cx="8" cy="6" r="2"/><circle cx="16" cy="12" r="2"/><circle cx="10" cy="18" r="2"/>',
    Eye = '<path d="M2 12C6 4 18 4 22 12C18 20 6 20 2 12Z"/><circle cx="12" cy="12" r="3"/>',
    Code = '<path d="M8 5L2 12 8 19M16 5L22 12 16 19M14 3L10 21"/>',
    File = '<path d="M14 2H5V22H20V8L14 2ZM14 2V8H20M8 12H16M8 17H16"/>',
    Bell = '<path d="M5 16C7 14 6 10 7 8C9 3 15 3 17 8C18 10 17 14 19 16H5ZM9 20Q12 23 15 20M12 2V4"/>',
    Brush = '<path d="M8 18L20 6 17 3 5 15M5 15Q3 17 4 21Q7 21 9 18L5 15Z"/>',
    Crosshair = '<path d="M12 2V7M12 17V22M2 12H7M17 12H22"/><circle cx="12" cy="12" r="6"/>',
    Skull = '<path d="M7 16C2 14 3 6 7 4C10 1 16 2 19 6C22 11 19 15 17 16V21H7V16ZM10 17V21M14 17V21"/><circle cx="8.5" cy="10" r="1.5"/><circle cx="15.5" cy="10" r="1.5"/>',
    Zap = '<path d="M13 2L4 14H11L10 22 20 9H13L13 2Z"/>',
    ChevronDown = '<path d="M6 9L12 15L18 9"/>',
    Minimize = '<path d="M5 17H19"/>',
    Maximize = '<rect x="5" y="5" width="14" height="14" rx="1"/>',
    Restore = '<path d="M9 5H19V15M5 9H15V19H5Z"/>',
    Close = '<path d="M6 6L18 18M18 6L6 18"/>',
    Check = '<path d="M5 12L10 17L20 7"/>',
    Info = '<circle cx="12" cy="12" r="9"/><path d="M12 11V17"/><circle cx="12" cy="7" r="0.7"/>',
    CursorArrow = '<path d="M7.92098 2.29951C6.93571 1.5331 5.5 2.23523 5.5 3.48349V20.4923C5.5 21.9145 7.2945 22.5382 8.17661 21.4226L12.3676 16.1224C12.6806 15.7267 13.1574 15.4958 13.6619 15.4958H20.5143C21.9425 15.4958 22.5626 13.6887 21.4353 12.8119L7.92098 2.29951Z"/>',
    CursorCrosshair = '<path d="M2 12H8M16 12H22M12 2V8M12 16V22"/>',
    CursorDot = '<circle cx="12" cy="12" r="8"/>',
    CursorRing = '<circle cx="12" cy="12" r="9"/>',
}

CSvg.Names = {}
for Name in pairs(CSvg.Sources) do CSvg.Names[Name:lower()] = Name end

function CSvg.Builtin(Name: string)
    Name = type(Name) == "string" and CSvg.Names[Name:lower()] or nil
    Name = Name or "Grid"
    if not CSvg.Builtins[Name] then
        CSvg.Builtins[Name] = assert(CSvg.Parse('<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.7">' .. CSvg.Sources[Name] .. '</svg>'))
    end
    return CSvg.Builtins[Name]
end

--[[
    使用內建／已註冊／內嵌 SVG 建立 Path2D，或建立指定 asset ID 的 ImageLabel。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Name 內建名稱、已註冊 SVG 名稱、完整 SVG 字串、path d 或圖片 asset ID。
    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
    @param Size 正方形邊長，單位為像素；nil 使用 24。
    @param Token 主題色名稱或同步求值的主題回呼；可省略時使用函數預設色。
    @return 承載向量線段或圖片的圖示 Frame。
]]
local function _Icon(Window: CWindowType, Parent, Name, Position, Size, Token): Frame
    Size = Size or 24
    local Host = _Frame(Parent, UDim2.fromOffset(Size, Size), Position)
    Host.Name = "Icon"
    Host.ClipsDescendants = false
    local Inset = 2
    local Unit = (Size - Inset * 2) / 24
    if type(Name) == "number" or (type(Name) == "string" and Name:match("^rbxassetid://")) then
        local Image = _CreateInstance("ImageLabel", Host, {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -Inset * 2, 1, -Inset * 2),
            Position = UDim2.fromOffset(Inset, Inset),
            ScaleType = Enum.ScaleType.Fit,
            ClipsDescendants = false,
            Image = type(Name) == "number" and "rbxassetid://" .. Name or Name,
        })
        _BindTheme(Window, Image, "ImageColor3", Token or "Muted")
        return Host
    end
    local Registered = CSvg.Registered[Name]
    local Data, Err
    if Registered then
        Data = Registered.Data
    elseif type(Name) == "string" and (Name:match("^%s*<") or Name:match("^%s*[Mm]%s*[%d%+%-%.]")) then
        Data, Err = CSvg.Parse(Name)
    else
        Data = CSvg.Builtin(Name)
    end
    if Data then
        local Settings = Registered and _CopyTable(Registered.Options) or {}
        Settings.Padding = 2
        local bOk, RenderErr = CSvg.Render(Window,Host,Data,Settings,Token or "Muted")
        if bOk then return Host end
        if Registered or (type(Name) == "string" and Name:match("^%s*<")) then Err = RenderErr end
    end
    if Err then warn("[BjzUi] " .. Err) end
    local Paths = ICON_PATHS[type(Name) == "string" and Name:lower() or "grid"] or ICON_PATHS.grid
    if Data then
        Paths = {}
        for _, Shape in ipairs(Data.Paths) do
            local Points, Path = CSvg.Polygon(Shape,Unit), {}
            for _, Point in ipairs(Points) do
                Path[#Path+1], Path[#Path+2] = Point[1], Point[2]
            end
            if Shape.bClosed and #Points > 0 then
                Path[#Path+1], Path[#Path+2] = Points[1][1], Points[1][2]
            end
            Paths[#Paths+1] = Path
        end
    end
    for _, Path in ipairs(Paths) do
        for J = 1, #Path - 2, 2 do
            local X, Y, Dx, Dy = Path[J], Path[J + 1], Path[J + 2] - Path[J], Path[J + 3] - Path[J + 1]
            local Layout = _Frame(
                Host,
                UDim2.fromOffset(math.sqrt(Dx * Dx + Dy * Dy) * Unit, 1.4),
                UDim2.fromOffset(Inset + (X + Dx / 2) * Unit, Inset + (Y + Dy / 2) * Unit)
            )
            Layout.AnchorPoint = Vector2.new(0.5, 0.5)
            Layout.BackgroundTransparency = 0
            Layout.Rotation = math.deg(math.atan2(Dy, Dx))
            _BindTheme(Window, Layout, "BackgroundColor3", Token or "Muted")
        end
    end
    return Host
end
-- A font-independent chevron; no Unicode glyph truncation or missing font fallback.

--[[
    以兩條線建立下拉箭頭，避免依賴字型中的符號字形。

    @param Window 管理主題、拖曳及生命週期的視窗。
    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
    @return 可透過 Rotation 切換展開方向的箭頭 Frame。
]]
local function _Chevron(Window: CWindowType, Parent, Position): Frame
    local Host = _Frame(Parent, UDim2.fromOffset(18, 18), Position)
    Host.Name = "DropdownArrow"
    local Data = CSvg.Builtin("ChevronDown")
    if CSvg.Render(Window,Host,Data,{},"Muted") then return Host end
    for Index = 1, 2 do
        local Line = _Frame(Host, UDim2.fromOffset(7, 2), UDim2.fromOffset(Index == 1 and 6.5 or 11.5, 9))
        Line.AnchorPoint = Vector2.new(0.5, 0.5)
        Line.Rotation = Index == 1 and 45 or -45
        Line.BackgroundTransparency = 0
        _BindTheme(Window, Line, "BackgroundColor3", "Muted")
    end
    return Host
end

-- 原始 SVG 箭頭的點擊基準；圖形來源集中於 CSvg.Sources.CursorArrow。
local CURSOR_ARROW_HOTSPOT = Vector2.new(5.93207387 / 24, 2.42754869 / 24)

--[[
    專屬游標的預設值；大小使用螢幕像素，不隨視窗 UIScale 改變。
]]
local DEFAULT_CURSOR = {
    bEnabled = true,
    Style = "Arrow",
    Size = 24,
    Color = Color3.fromRGB(255, 255, 255),
    OutlineColor = Color3.fromRGB(12, 18, 24),
    Opacity = 1,
    bUseAccent = true,
    bHideNative = true,
}

--[[
    合併部分游標選項；忽略無效欄位，不讓 NaN、無限大或非法樣式進入繪圖。
    @param Current 目前設定；nil 使用預設值。
    @param Options 要更新的部分設定。
    @return 完整且獨立的游標設定表。
]]
local function _NormalizeCursor(Current, Options): CursorSettings
    local Result = _CopyTable(Current or DEFAULT_CURSOR)
    if type(Options) ~= "table" then
        return Result
    end
    for _, Key in ipairs({ "bEnabled", "bUseAccent", "bHideNative" }) do
        if type(Options[Key]) == "boolean" then
            Result[Key] = Options[Key]
        end
    end
    if
        Options.Style == "Arrow"
        or Options.Style == "Crosshair"
        or Options.Style == "Dot"
        or Options.Style == "Ring"
    then
        Result.Style = Options.Style
    end
    Result.Size = math.floor(_Clamp(_NumberOr(Options.Size, Result.Size), 12, 64) + 0.5)
    Result.Opacity = math.floor(_Clamp(_NumberOr(Options.Opacity, Result.Opacity), 0.1, 1) * 100 + 0.5) / 100
    Result.Color = _ParseColor(Options.Color) or Result.Color
    Result.OutlineColor = _ParseColor(Options.OutlineColor) or Result.OutlineColor
    if Result.Style == "Arrow" then
        Result.bUseAccent = true
    end
    return Result
end

--[[
    建立不攔截滑鼠、觸控及鍵盤導覽的游標圖形部件。
    @param Parent 圖形的父物件。
    @param Size 部件尺寸。
    @param Position 部件位置。
    @return 透明背景的非互動 Frame。
]]
local function _CursorFrame(Parent, Size, Position): Frame
    local Part = _Frame(Parent, Size, Position)
    Part.Active = false
    Part.Selectable = false
    --[[
        舊引擎未提供 Interactable 時仍保留非互動 Frame 的設定。
    ]]
    pcall(function(): ()
        Part.Interactable = false
    end)
    return Part
end

-- 從同一份 SVG 曲線取樣填色輪廓；Path2D 負責描邊。
-- 此填色僅用於內建單一封閉輪廓的 Arrow/Dot，不擴張公開 SVG 匯入的填色支援。
function CSvg.Polygon(Shape, Unit: number)
    local Points, Nodes = {}, Shape.Points
    for Index, A in ipairs(Nodes) do
        local B = Nodes[Index % #Nodes + 1]
        if not Shape.bClosed and Index == #Nodes then break end
        local Length = math.sqrt(A.RX^2+A.RY^2)
            + math.sqrt((B.X+B.LX-A.X-A.RX)^2+(B.Y+B.LY-A.Y-A.RY)^2)
            + math.sqrt(B.LX^2+B.LY^2)
        local Count = math.max(1,math.min(256,math.ceil(Length*Unit*2)))
        for Step = 0, Count-1 do
            local T, U = Step/Count,1-Step/Count
            Points[#Points+1] = {
                U^3*A.X+3*U^2*T*(A.X+A.RX)+3*U*T^2*(B.X+B.LX)+T^3*B.X,
                U^3*A.Y+3*U^2*T*(A.Y+A.RY)+3*U*T^2*(B.Y+B.LY)+T^3*B.Y,
            }
        end
    end
    if not Shape.bClosed then
        local Last = Nodes[#Nodes]
        Points[#Points+1] = {Last.X,Last.Y}
    end
    return Points
end

-- 只在尺寸／樣式改變時重建 SVG；移動、換色與透明度更新沿用已建立的部件。
function CWindow._PaintCursor(self: CWindowType): ()
    local Host = self._CursorFrame
    if not Host or self.bDestroyed then return end
    local Settings = self.Cursor
    local Unit = Settings.Size/24
    local Color = Settings.bUseAccent and self.Theme.Accent or Settings.Color
    local ShapeKey = Settings.Style .. ":" .. tostring(Settings.Size)
    if self._CursorShape == ShapeKey then
        self._CursorComposite.GroupTransparency = 1-Settings.Opacity
        for _, Paint in ipairs(self._CursorPaint) do
            Paint.Object[Paint.Property] = Paint.bOutline and Settings.OutlineColor or Color
        end
        return
    end
    self._CursorShape = ShapeKey
    self._CursorPaint = {}
    for _, Child in ipairs(Host:GetChildren()) do _Dispose(self,Child) end
    Host.Size = UDim2.fromOffset(Settings.Size,Settings.Size)
    Host.AnchorPoint = Settings.Style == "Arrow" and CURSOR_ARROW_HOTSPOT or Vector2.new(0.5,0.5)
    -- 先以不透明的連續線條／單一圓形合成，再統一套用透明度，避免分段接縫。
    -- 合成區域包含描邊與圓形端點的外擴空間，不讓 Path2D／CanvasGroup 裁切外框。
    local Margin = math.ceil(4*Unit)+2
    local Composite = _CreateInstance("CanvasGroup",Host,{
        Name="CursorComposite",BackgroundTransparency=1,BorderSizePixel=0,
        Size=UDim2.fromOffset(Settings.Size+Margin*2,Settings.Size+Margin*2),
        Position=UDim2.fromOffset(-Margin,-Margin),GroupTransparency=1-Settings.Opacity,
        GroupColor3=Color3.new(1,1,1),ClipsDescendants=true,Active=false,Selectable=false,
    })
    pcall(function(): () Composite.Interactable = false end)
    self._CursorComposite = Composite
    local Drawing = _CursorFrame(Composite,UDim2.fromOffset(Settings.Size,Settings.Size),UDim2.fromOffset(Margin,Margin))

    local function _Record(Object, Property, bOutline): ()
        self._CursorPaint[#self._CursorPaint+1] = {
            Object=Object,Property=Property,bOutline=bOutline==true,
        }
    end
    local function _Fill(Data, bOutline): ()
        local FillColor = bOutline and Settings.OutlineColor or Color
        local Layer = _CursorFrame(Drawing,UDim2.fromScale(1,1))
        Layer.Name, Layer.ZIndex = "CursorSolid", 2
        if Settings.Style == "Dot" then
            -- SVG 圓形的四個極值直接決定單一實心圓的界線，不再以多列 Frame 拼接。
            local MinX,MinY,MaxX,MaxY = math.huge,math.huge,-math.huge,-math.huge
            for _, Point in ipairs(Data.Paths[1].Points) do
                MinX,MinY = math.min(MinX,Point.X),math.min(MinY,Point.Y)
                MaxX,MaxY = math.max(MaxX,Point.X),math.max(MaxY,Point.Y)
            end
            local Solid = _CursorFrame(Layer,UDim2.fromOffset((MaxX-MinX)*Unit,(MaxY-MinY)*Unit),UDim2.fromOffset(MinX*Unit,MinY*Unit))
            Solid.Name, Solid.ZIndex = "CursorFillShape", 2
            Solid.BackgroundColor3, Solid.BackgroundTransparency = FillColor, 0
            _Corner(Solid,0).CornerRadius = UDim.new(1,0)
            _Record(Solid,"BackgroundColor3",bOutline)
            return
        end
        local Paths, Polygons = {}, {}
        local Step = math.min(1,Unit)
        local function _Crossings(Points,Y)
            local Crossings = {}
            for Index,A in ipairs(Points) do
                local B = Points[Index % #Points+1]
                if (A[2]<=Y and B[2]>Y) or (B[2]<=Y and A[2]>Y) then
                    Crossings[#Crossings+1] = A[1]+(Y-A[2])*(B[1]-A[1])/(B[2]-A[2])
                end
            end
            table.sort(Crossings)
            return Crossings
        end
        for _, Shape in ipairs(Data.Paths) do
            local Points = CSvg.Polygon(Shape,Unit)
            Polygons[#Polygons+1] = Points
            local Nodes, bReverse = {}, false
            local function _Flush(): ()
                if #Nodes>=2 then
                    Paths[#Paths+1] = {Points=Nodes,bClosed=false,StrokeWidth=Step*2.25/Unit,Opacity=1}
                end
                Nodes = {}
            end
            for Row=0,math.ceil(Settings.Size/Step)-1 do
                local Y = (Row+0.5)*Step/Unit
                local Crossings = _Crossings(Points,Y)
                if #Crossings==2 then
                    local Inset = math.min((Crossings[2]-Crossings[1])/4,Step*0.65/Unit)
                    Crossings[1] += Inset
                    Crossings[2] -= Inset
                    for _,X in ipairs(bReverse and {Crossings[2],Crossings[1]} or Crossings) do
                        Nodes[#Nodes+1] = {X=X,Y=Y,LX=0,LY=0,RX=0,RY=0}
                    end
                    bReverse = not bReverse
                else _Flush() end
            end
            _Flush()
        end
        -- 原生連續折線在同一像素座標系內覆蓋整個實心區域，沒有 GUI 填色列的取整接縫。
        local bOk = CSvg.Render(self,Layer,{ViewBox=Data.ViewBox,AspectRatio=Data.AspectRatio,Paths=Paths},{Color=FillColor},"Accent")
        if bOk then
            for _, Part in ipairs(Layer:GetDescendants()) do
                if Part:IsA("Path2D") then
                    Part.Name = "CursorFillPath"
                    _Record(Part,"Color3",bOutline)
                end
            end
            return
        end
        -- 舊用戶端使用整數座標且垂直重疊一整個像素，避免子像素 Frame 被分別取整。
        for _, Points in ipairs(Polygons) do
            for Row=0,Settings.Size-1 do
                local Crossings = _Crossings(Points,(Row+0.5)/Unit)
                for Index=1,#Crossings-1,2 do
                    local Left,Right = math.floor(Crossings[Index]*Unit),math.ceil(Crossings[Index+1]*Unit)
                    local Part = _CursorFrame(Layer,UDim2.fromOffset(Right-Left,2),UDim2.fromOffset(Left,Row))
                    Part.Name, Part.ZIndex = "CursorFillFallback", 2
                    Part.BackgroundColor3, Part.BackgroundTransparency = FillColor, 0
                    _Record(Part,"BackgroundColor3",bOutline)
                end
            end
        end
    end
    local function _StrokeSvg(Data, StrokeScale, bOutline): ()
        local Layer = _CursorFrame(Drawing,UDim2.fromOffset(Settings.Size+Margin*2,Settings.Size+Margin*2),UDim2.fromOffset(-Margin,-Margin))
        Layer.Name = "CursorSvg" .. (bOutline and "Outline" or "Paint")
        Layer.ZIndex = bOutline and 1 or 3
        local FillColor = bOutline and Settings.OutlineColor or Color
        local Padded = table.clone(Data)
        Padded.ViewBox = {-Margin/Unit,-Margin/Unit,24+Margin*2/Unit,24+Margin*2/Unit}
        local bOk = CSvg.Render(self,Layer,Padded,{
            Color=FillColor,Opacity=1,StrokeScale=StrokeScale,
        },"Accent")
        if bOk then
            for _, Part in ipairs(Layer:GetDescendants()) do
                if Part:IsA("Path2D") then _Record(Part,"Color3",bOutline) end
            end
        else
            -- 舊用戶端也從 SVG 曲線建立線段，不再保留第二份游標形狀資料。
            for _, Shape in ipairs(Data.Paths) do
                local Points = CSvg.Polygon(Shape,Unit)
                for Index = 1, #Points-(Shape.bClosed and 0 or 1) do
                    local A, B = Points[Index], Points[Index % #Points+1]
                    local Dx, Dy = B[1]-A[1], B[2]-A[2]
                    local Part = _CursorFrame(Layer,UDim2.fromOffset(math.sqrt(Dx*Dx+Dy*Dy)*Unit,Shape.StrokeWidth*StrokeScale*Unit))
                    Part.AnchorPoint = Vector2.new(0.5,0.5)
                    Part.Position = UDim2.fromOffset(Margin+(A[1]+B[1])*Unit/2,Margin+(A[2]+B[2])*Unit/2)
                    Part.Rotation = math.deg(math.atan2(Dy,Dx))
                    Part.BackgroundColor3 = FillColor
                    Part.BackgroundTransparency = 0
                    _Record(Part,"BackgroundColor3",bOutline)
                end
            end
        end
        for _, Shape in ipairs(Data.Paths) do
            if not Shape.bClosed then
                -- 原生開放路徑沒有可設定的圓形線帽，以同色圓端點補齊黑色外框。
                local Diameter = Shape.StrokeWidth*StrokeScale*Unit
                for _, Point in ipairs({Shape.Points[1],Shape.Points[#Shape.Points]}) do
                    local Cap = _CursorFrame(Layer,UDim2.fromOffset(Diameter,Diameter),UDim2.fromOffset(Margin+Point.X*Unit,Margin+Point.Y*Unit))
                    Cap.Name, Cap.ZIndex = "CursorStrokeCap", Layer.ZIndex
                    Cap.AnchorPoint, Cap.BackgroundTransparency = Vector2.new(0.5,0.5),0
                    Cap.BackgroundColor3 = FillColor
                    _Corner(Cap,0).CornerRadius = UDim.new(1,0)
                    _Record(Cap,"BackgroundColor3",bOutline)
                end
            end
        end
    end
    local Data = CSvg.Builtin("Cursor" .. Settings.Style)
    if Settings.Style == "Arrow" then
        _StrokeSvg(Data,2.9,true)
        _Fill(Data,false)
        _StrokeSvg(Data,1.45,false)
    elseif Settings.Style == "Dot" then
        _StrokeSvg(Data,2.9,true)
        _Fill(Data,false)
        _StrokeSvg(Data,1.45,false)
    else
        _StrokeSvg(Data,2.9,true)
        _StrokeSvg(Data,1.45,false)
    end
end


--[[
    檢查主視窗、浮層、八向把手、通知或最小化圖示的實際可見區域。
    @param self 要檢查的視窗。
    @param Point 已扣除 GetGuiInset 的 CoreUISafeInsets 座標，與 AbsolutePosition 一致。
    @return true 表示指標位於介面或由此視窗捕捉滑鼠拖曳。
    @return true 表示目前正由此視窗捕捉滑鼠拖曳。
]]
function CWindow._CursorHit(self: CWindowType, Point: Vector2): (boolean, boolean)
    if
        self.bDestroyed
        or not self.ScreenGui.Parent
        or not self.ScreenGui.Enabled
        or not self.Surface.Visible
        or not _ContainsPoint(self.Surface, Point)
    then
        return false, false
    end
    local bDrag = self._Drag ~= nil and self._Drag._Input.UserInputType == Enum.UserInputType.MouseButton1
    if bDrag then
        return true, true
    end
    if self.Main.Visible then
        if _ContainsPoint(self.Main, Point) then
            return true, false
        end
        if self.bResizable then
            for _, Handle in pairs(self.ResizeHandles or {}) do
                if Handle.Visible and _ContainsPoint(Handle, Point) then
                    return true, false
                end
            end
        end
    end
    if self.Mini.Visible and _ContainsPoint(self.Mini, Point) then
        return true, false
    end
    if self._Popup and self._Popup.Panel.Visible and _ContainsPoint(self._Popup.Panel, Point) then
        return true, false
    end
    for Target in pairs(self._CursorTargets) do
        if Target.Parent and Target.Visible and _ContainsPoint(Target, Point) then
            return true, false
        end
    end
    return false, false
end

--[[
    共用管理器只在輸入、視窗狀態或系統選單事件時更新，選擇最上層視窗的唯一游標。
    @param Manager 同一執行環境共用的游標狀態。
]]
local function _RefreshCursors(Manager): ()
    if Manager._bUpdating or Manager._Scope._bDead then
        return
    end
    Manager._bUpdating = true
    -- AbsolutePosition is in CoreUISafeInsets coordinates even when IgnoreGuiInset is true.
    -- Convert once for both hit testing and rendering; Surface.AbsolutePosition then accounts
    -- for its own origin. Never hard-code the top bar height or subtract its inset twice.
    local GuiInset = game:GetService("GuiService"):GetGuiInset()
    local Point = UserInputService:GetMouseLocation() - GuiInset
    local Selected, SelectedOrder, SelectedSequence
    if Manager._bFocused and Manager._bMouse and UserInputService.MouseEnabled and not Manager._bMenu then
        for Window, Sequence in pairs(Manager.Windows) do
            local bHit = Window:_CursorHit(Point)
            local Order = Window.ScreenGui.DisplayOrder
            if
                bHit
                and (
                    not Selected
                    or Order > SelectedOrder
                    or (Order == SelectedOrder and Sequence > SelectedSequence)
                )
            then
                Selected, SelectedOrder, SelectedSequence = Window, Order, Sequence
            end
        end
    end
    -- Disabled top windows still occlude lower windows; do not draw the lower window's cursor over them.
    if Selected and not Selected.Cursor.bEnabled then
        Selected = nil
    end
    if
        Manager._Owner
        and Manager._Owner ~= Selected
        and Manager._Owner._CursorFrame
        and Manager._Owner._CursorFrame.Parent
    then
        Manager._Owner._CursorFrame.Visible = false
    end
    Manager._Owner = Selected
    if Selected then
        local Position = Point - Selected.Surface.AbsolutePosition
        Selected._CursorFrame.Position = UDim2.fromOffset(Position.X, Position.Y)
        Selected._CursorFrame.Visible = true
    end
    local bHide = Selected ~= nil and Selected.Cursor.bHideNative
    if bHide then
        if not Manager._bOwnNative then
            Manager._bRestoreNative = UserInputService.MouseIconEnabled
            Manager._bOwnNative = true
        end
        UserInputService.MouseIconEnabled = false
    elseif Manager._bOwnNative then
        local bRestore = Manager._bRestoreNative
        Manager._bOwnNative = false
        UserInputService.MouseIconEnabled = bRestore
    end
    Manager._bUpdating = false
end

--[[
    建立或重用跨模組載入的游標管理器；所有視窗共用一組全域輸入監聽。
    @return 可註冊視窗的共用管理器。
]]
local function _GetCursorManager()
    local Env = (type(getgenv) == "function" and getgenv()) or _G
    local Existing = Env.__BjzUiCursorV1
    if type(Existing) == "table" and Existing.Version == 1 and not Existing._Scope._bDead then
        --[[
            重新載入修正版時同步更新共用管理器，避免沿用舊模組的座標轉換。
        ]]
        Existing._Refresh = function(): ()
            _RefreshCursors(Existing)
        end
        return Existing
    end
    local GuiService = game:GetService("GuiService")
    local InputType = UserInputService:GetLastInputType()
    local Manager = {
        Version = 1,
        Windows = {},
        Sequence = 0,
        _Scope = _CreateScope(),
        _bFocused = true,
        _bMouse = InputType ~= Enum.UserInputType.Touch and not InputType.Name:match("^Gamepad"),
        _bMenu = GuiService.MenuIsOpen,
        _bOwnNative = false,
        _bUpdating = false,
        _Env = Env,
    }
    --[[
        重新求值目前位置、顯示範圍與原生游標所有權。
    ]]
    Manager._Refresh = function(): ()
        _RefreshCursors(Manager)
    end
    --[[
        滑鼠恢復游標；觸控或手把接手時隱藏，以免留下假指標。
        @param Input 最新的輸入事件。
    ]]
    local function _Input(Input: InputObject): ()
        local Kind = Input.UserInputType
        if
            Kind == Enum.UserInputType.MouseMovement
            or Kind == Enum.UserInputType.MouseButton1
            or Kind == Enum.UserInputType.MouseButton2
            or Kind == Enum.UserInputType.MouseButton3
            or Kind == Enum.UserInputType.MouseWheel
        then
            Manager._bMouse = true
            Manager._Refresh()
        elseif Kind == Enum.UserInputType.Touch or Kind.Name:match("^Gamepad") then
            Manager._bMouse = false
            Manager._Refresh()
        end
    end
    _Connect(Manager._Scope, UserInputService.InputChanged, _Input)
    _Connect(Manager._Scope, UserInputService.InputBegan, _Input)
    --[[
        頂端介面或安全區改變時，滑鼠靜止也重新計算游標位置。
    ]]
    _Connect(Manager._Scope, GuiService:GetPropertyChangedSignal("TopbarInset"), function(): ()
        Manager._Refresh()
    end)
    _Connect(Manager._Scope, UserInputService:GetPropertyChangedSignal("MouseEnabled"), Manager._Refresh)
    --[[
        記錄遊戲在接管期間實際變更的原生游標狀態；自身寫入不作為遊戲的新偏好。
    ]]
    _Connect(Manager._Scope, UserInputService:GetPropertyChangedSignal("MouseIconEnabled"), function(): ()
        if Manager._bUpdating then
            return
        end
        if Manager._bOwnNative then
            Manager._bRestoreNative = UserInputService.MouseIconEnabled
        end
        Manager._Refresh()
    end)
    --[[
        切出 Rbx 時隱藏繪製游標並交還原生狀態。
    ]]
    _Connect(Manager._Scope, UserInputService.WindowFocusReleased, function(): ()
        Manager._bFocused = false
        Manager._Refresh()
    end)
    --[[
        回到 Rbx 時依最新位置恢復介面游標。
    ]]
    _Connect(Manager._Scope, UserInputService.WindowFocused, function(): ()
        Manager._bFocused = true
        Manager._Refresh()
    end)
    --[[
        系統 ESC 選單使用其原生游標。
    ]]
    _Connect(Manager._Scope, GuiService.MenuOpened, function(): ()
        Manager._bMenu = true
        Manager._Refresh()
    end)
    --[[
        系統選單關閉後重新檢查介面範圍。
    ]]
    _Connect(Manager._Scope, GuiService.MenuClosed, function(): ()
        Manager._bMenu = false
        Manager._Refresh()
    end)
    Env.__BjzUiCursorV1 = Manager
    return Manager
end

--[[
    通知共用管理器重新判斷目前指標；建構完成前可安全呼叫。
    @param self 要更新的視窗。
]]
function CWindow._RefreshCursor(self: CWindowType): ()
    if self._CursorManager then
        self._CursorManager._Refresh()
    end
end

--[[
    建立最高層的非互動游標，註冊視窗的外部狀態變更。
    @param self 要安裝游標的視窗。
]]
function CWindow._InstallCursor(self: CWindowType): ()
    self._CursorFrame = _CursorFrame(self.Surface, UDim2.fromOffset(24, 24))
    self._CursorFrame.Name = "UiCursor"
    self._CursorFrame.ZIndex = 10000
    self._CursorFrame.Visible = false
    self._CursorFrame.ClipsDescendants = false
    self:_PaintCursor()
    local Manager = _GetCursorManager()
    self._CursorManager = Manager
    Manager.Sequence += 1
    Manager.Windows[self] = Manager.Sequence
    --[[
        尺寸、位置與顯示屬性由外部程式改動時也更新游標。
    ]]
    local function _Refresh(): ()
        self:_RefreshCursor()
    end
    for _, Object in ipairs({ self.Main, self.Mini, self.Surface }) do
        for _, Property in ipairs({ "AbsolutePosition", "AbsoluteSize", "Visible" }) do
            _Connect(self._Scope, Object:GetPropertyChangedSignal(Property), _Refresh)
        end
    end
    _Connect(self._Scope, self.ScreenGui:GetPropertyChangedSignal("Enabled"), _Refresh)
    _Connect(self._Scope, self.ScreenGui:GetPropertyChangedSignal("DisplayOrder"), _Refresh)
    _Connect(self._Scope, self.ScreenGui.AncestryChanged, _Refresh)
    --[[
        ScreenGui 被外部銷毀時同步釋放事件與原生游標；避免遞迴 Destroy。
    ]]
    _Connect(self._Scope, self.ScreenGui.Destroying, function(): ()
        if not self.bDestroyed then
            self._bGuiDestroying = true
            self:Destroy()
        end
    end)
    self:_RefreshCursor()
end

--[[
    移除視窗的游標所有權；最後一個視窗關閉時清理共用事件並還原原生游標。
    @param self 即將銷毀的視窗。
]]
function CWindow._ReleaseCursor(self: CWindowType): ()
    local Manager = self._CursorManager
    if not Manager then
        return
    end
    Manager.Windows[self] = nil
    Manager._Refresh()
    self._CursorManager = nil
    if not next(Manager.Windows) then
        _CleanScope(Manager._Scope)
        if Manager._Env.__BjzUiCursorV1 == Manager then
            Manager._Env.__BjzUiCursorV1 = nil
        end
    end
end

--[[
    取得游標設定的獨立副本；修改副本不會繞過 SetCursor 的繪圖與保存流程。
    @param self 要讀取的視窗。
    @return 完整的游標設定。
]]
function CWindow.GetCursor(self: CWindowType): CursorSettings
    return _CopyTable(self.Cursor)
end

--[[
    同步更新游標外觀及已建立的設定控制項，並以既有節流保存至 UiConfig.json。
    @param self 要設定的視窗。
    @param Options 部分或完整游標設定；省略欄位維持目前值。Arrow 固定跟隨主題強調色，忽略 bUseAccent = false。
    @return 目前視窗，可繼續串接呼叫。

    使用範例：
    ```lua
    Window:SetCursor({ bEnabled = true, Style = "Crosshair", Size = 30, bUseAccent = true })
    ```
]]
function CWindow.SetCursor(self: CWindowType, Options: CursorOptions): CWindowType
    if self.bDestroyed then
        return self
    end
    local Settings = _NormalizeCursor(self.Cursor, Options)
    local bChanged = not _ValuesEqual(Settings, self.Cursor)
    local Previous = self.Cursor
    self.Cursor = Settings
    if
        Previous.Style ~= Settings.Style
        or Previous.Size ~= Settings.Size
        or Previous.Opacity ~= Settings.Opacity
        or Previous.Color ~= Settings.Color
        or Previous.OutlineColor ~= Settings.OutlineColor
        or Previous.bUseAccent ~= Settings.bUseAccent
    then
        self:_PaintCursor()
    end
    for Index = #self._CursorSettingsGroups, 1, -1 do
        local Group = self._CursorSettingsGroups[Index]
        if Group.bEnabled.bDestroyed then
            table.remove(self._CursorSettingsGroups, Index)
        else
            for Key, Control in pairs(Group) do
                if not Control.bDestroyed then
                    if Key == "Color" or Key == "OutlineColor" then
                        Control:Set(Settings[Key], nil, true)
                    else
                        Control:Set(Settings[Key], true)
                    end
                end
            end
            Group.Color:SetEnabled(not Settings.bUseAccent)
            Group.bUseAccent:SetEnabled(Settings.Style ~= "Arrow")
            Group.OutlineColor:SetEnabled(Settings.Style ~= "Arrow")
        end
    end
    self:_RefreshCursor()
    if bChanged then
        return self:_ChangedUI()
    end
    return self
end

--[[
    在指定區塊加入專屬游標設定；所有值由 Window.Cursor 保存，不另外建立 Flag 或相容別名。
    @param self 控制這組游標的視窗。
    @param Section 此視窗中用來承載設定的區塊。
    @return 按設定欄位索引的控制項集合。

    使用範例：
    ```lua
    local Tab = Window:CreateTab("介面設定", "settings")
    Window:CreateCursorSettings(Tab:CreateSection({ Name = "專屬游標", Side = "full" }))
    ```
]]
function CWindow.CreateCursorSettings(self: CWindowType, Section: CSectionType)
    assert(
        not self.bDestroyed and Section.Window == self,
        "BjzUi cursor settings require a section from this window"
    )
    local Settings = self.Cursor
    local Controls = {}
    for _, Spec in ipairs({
        { "bEnabled", "啟用介面專屬游標" },
        { "bHideNative", "介面內隱藏原生游標" },
        { "bUseAccent", "跟隨主題顏色" },
    }) do
        local Key = Spec[1]
        Controls[Key] = Section:CreateToggle({
            Name = Spec[2],
            Description = Key == "bUseAccent" and "箭頭樣式固定跟隨主題強調色。" or nil,
            bCurrentValue = Settings[Key],
            bSave = false,
            --[[
                將布林設定交給視窗統一套用。
                @param bValue 新設定值。
            ]]
            Callback = function(bValue: boolean): ()
                self:SetCursor({ [Key] = bValue })
            end,
        })
    end
    Controls.Style = Section:CreateDropdown({
        Name = "游標樣式",
        Options = {
            { Name = "箭頭", Value = "Arrow" },
            { Name = "十字", Value = "Crosshair" },
            { Name = "圓點", Value = "Dot" },
            { Name = "圓環", Value = "Ring" },
        },
        CurrentOption = Settings.Style,
        bSave = false,
        bSearchable = false,
        --[[
            切換內建圖形樣式。
            @param Style 內建樣式名稱。
        ]]
        Callback = function(Style: string): ()
            self:SetCursor({ Style = Style })
        end,
    })
    for _, Spec in ipairs({
        { "Size", "游標大小", 12, 64, 1, "px" },
        { "Opacity", "不透明度", 0.1, 1, 0.01, "" },
    }) do
        local Key = Spec[1]
        Controls[Key] = Section:CreateSlider({
            Name = Spec[2],
            Range = { Spec[3], Spec[4] },
            Increment = Spec[5],
            Suffix = Spec[6],
            CurrentValue = Settings[Key],
            bSave = false,
            --[[
                調整游標尺寸或不透明度。
                @param Value 新數值。
            ]]
            Callback = function(Value: number): ()
                self:SetCursor({ [Key] = Value })
            end,
        })
    end
    for _, Spec in ipairs({ { "Color", "游標顏色" }, { "OutlineColor", "外框顏色" } }) do
        local Key = Spec[1]
        Controls[Key] = Section:CreateColorPicker({
            Name = Spec[2],
            Color = Settings[Key],
            bSave = false,
            --[[
                設定固定填色或對比外框色。
                @param Color 新的 RGB 顏色。
            ]]
            Callback = function(Color: Color3): ()
                self:SetCursor({ [Key] = Color })
            end,
        })
    end
    Controls.Color:SetEnabled(not Settings.bUseAccent)
    Controls.bUseAccent:SetEnabled(Settings.Style ~= "Arrow")
    Controls.OutlineColor:SetEnabled(Settings.Style ~= "Arrow")
    Section:CreateButton({
        Name = "還原游標預設值",
        Style = "outline",
        bSave = false,
        --[[
            還原預設游標，其他視窗與遊戲設定維持原值。
        ]]
        Callback = function(): ()
            self:SetCursor(DEFAULT_CURSOR)
        end,
    })
    table.insert(self._CursorSettingsGroups, Controls)
    return Controls
end

--[[
    取消同一物件的舊 Tween，再依動畫設定更新指定屬性。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Object 要套用屬性或檢查範圍的 Rbx Instance。
    @param Properties 要套用的 Rbx 屬性與值。
]]
function CWindow._Tween(self: CWindowType, Object, Properties, Duration: number?, EasingStyle: Enum.EasingStyle?): ()
    if self._Tweens[Object] then
        self._Tweens[Object]:Cancel()
        self._Tweens[Object] = nil
    end
    if self.bAnimations and (Duration == nil or Duration > 0) then
        local Tw = TweenService:Create(
            Object,
            TweenInfo.new(Duration or 0.12, EasingStyle or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            Properties
        )
        self._Tweens[Object] = Tw
        Tw:Play()
    else
        for Key, Item in pairs(Properties) do
            Object[Key] = Item
        end
    end
end

-- 清除指定子樹或整個視窗的懸停狀態，避免隱藏／停用後殘留高亮。
function CWindow._ResetFeedback(self: CWindowType, Root: GuiObject?): ()
    for Object, Refresh in pairs(self._Feedback) do
        if not Root or Object == Root or Object:IsDescendantOf(Root) then
            Refresh(true)
        end
    end
end

--[[
    將設定儲存延後 1.5 秒，連續變更會合併為同一次寫入。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CWindow._Dirty(self: CWindowType): ()
    if self.bDestroyed or not self.bConfigEnabled or self._bLoading then
        return
    end
    if self._SaveTask then
        self._Scope._Timers[self._SaveTask] = nil
        _CancelTask(self._SaveTask)
    end

    --[[
        清除已到期的儲存工作記錄，再保存目前視窗設定。
    ]]
    self._SaveTask = _Schedule(self._Scope, 1.5, function(): ()
        self._SaveTask = nil
        self:SaveConfiguration()
    end)
end

--[[
    擷取視窗外觀、分頁及可保存的 Flag；只產生可序列化資料。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 此視窗的可序列化設定快照。
]]
function CWindow._Snapshot(self: CWindowType): SavedWindow
    local Values = _CopyTable(self._SavedFlags)
    for Flag, Control in pairs(self.Flags) do
        if not Control.bDestroyed and Control.bSave then
            Values[Flag] = Control:_Serialize()
        else
            Values[Flag] = nil
        end
    end
    local Position = (self.bMaximized and self._RestorePosition)
        or (self._MinimizeMotion and self._MinimizeMotion.Position) or self.Main.Position
    local UI = {
        Cursor = {
            bEnabled = self.Cursor.bEnabled,
            Style = self.Cursor.Style,
            Size = self.Cursor.Size,
            Color = _ToHex(self.Cursor.Color),
            OutlineColor = _ToHex(self.Cursor.OutlineColor),
            Opacity = self.Cursor.Opacity,
            bUseAccent = self.Cursor.bUseAccent,
            bHideNative = self.Cursor.bHideNative,
        },
        Accent = _ToHex(self.Theme.Accent),
        Scale = self.Scale,
        Animations = self.bAnimations,
        Width = self.PreferredWidth,
        Height = self.PreferredHeight,
        X = Position.X.Offset,
        Y = Position.Y.Offset,
        MiniX = self.Mini.Position.X.Offset,
        MiniY = self.Mini.Position.Y.Offset,
        ToggleKey = self.ToggleKey.Name,
        Tab = self.ActiveTab and self.ActiveTab.Name or nil,
        Subtabs = {},
    }
    for _, Tab in ipairs(self.Tabs) do
        UI.Subtabs[Tab.Name] = Tab.ActivePage.Name
    end
    return { UI = UI, Flags = Values, KeyAccepted = self._bKeyAccepted == true }
end

--[[
    將此 ConfigId 的設定合併寫回同一份 UiConfig.json。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return true 表示設定已交由檔案 API 寫入；false 表示未保存。
    @return 成功時為設定路徑；失敗時為原因。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local bSaved, Result = Window:SaveConfiguration()
    print(bSaved, Result) -- 沒有檔案能力時為 false 與原因
    ```
]]
function CWindow.SaveConfiguration(self: CWindowType): (boolean, string)
    if self.bDestroyed then
        return false, "視窗已銷毀。"
    end
    if not self.bConfigEnabled then
        return false, "ConfigurationSaving.Enabled=false"
    end
    local Data, Err = _ReadConfig()
    if not Data then
        self.LastConfigError = Err
        return false, Err
    end
    Data.Windows[self.ConfigId] = self:_Snapshot()
    local bOk, Result = _WriteConfig(Data)
    self.LastConfigError = not bOk and Result or nil
    if not bOk and not self._bConfigWarned then
        self._bConfigWarned = true
        warn("[BjzUi] " .. Result)
    end
    return bOk, Result
end

--[[
    讀取此 ConfigId 的外觀與控制項值；依 bSilent 決定是否觸發值變更回呼。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param bSilent true 時不觸發值變更回呼；省略或 false 時依變更結果發送回呼。
    @return true 表示找到並套用了設定；false 表示沒有設定或讀取失敗。
    @return 失敗原因；成功時為 nil。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local bLoaded, Reason = Window:LoadConfiguration(true)
    print(bLoaded, Reason) -- true 表示已靜默恢復
    ```
]]
function CWindow.LoadConfiguration(self: CWindowType, bSilent: boolean?): (boolean, string?)
    if self.bDestroyed then
        return false, "視窗已銷毀。"
    end
    local Data, Err = _ReadConfig()
    if not Data then
        return false, Err
    end
    local Saved = Data.Windows[self.ConfigId]
    if type(Saved) ~= "table" then
        return false, "找不到此 ConfigId 的設定。"
    end
    self._bLoading = true
    self._SavedFlags = type(Saved.Flags) == "table" and Saved.Flags or {}
    self:_ApplyUI(type(Saved.UI) == "table" and Saved.UI or {})
    for Flag, Control in pairs(self.Flags) do
        if self._SavedFlags[Flag] ~= nil and Control.bSave then
            Control:_Restore(self._SavedFlags[Flag], bSilent == true)
        end
    end
    self._bLoading = false
    return true
end

--[[
    套用儲存的外觀、尺寸與分頁，再重新計算響應式佈局。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param UI 從設定檔讀取的外觀資料；缺少欄位時沿用目前設定。
]]
function CWindow._ApplyUI(self: CWindowType, UI: SavedUI): ()
    self._SavedUI = UI
    if type(UI.Cursor) == "table" then
        self:SetCursor(UI.Cursor)
    end
    local Accent = _ParseColor(UI.Accent)
    if Accent then
        self:SetAccent(Accent)
    end
    self.Scale = _Clamp(_NumberOr(UI.Scale, self.Scale), 0.65, 1.5)
    self.PreferredWidth = _Clamp(_NumberOr(UI.Width, self.PreferredWidth), self.MinWidth, self.MaxWidth)
    self.PreferredHeight = _Clamp(_NumberOr(UI.Height, self.PreferredHeight), self.MinHeight, self.MaxHeight)
    if type(UI.Animations) == "boolean" then
        self.bAnimations = UI.Animations
    end
    self.ToggleKey = _KeyFrom(UI.ToggleKey) or self.ToggleKey
    if _IsFinite(UI.X) and _IsFinite(UI.Y) then
        self.Main.Position = UDim2.fromOffset(UI.X, UI.Y)
    end
    if _IsFinite(UI.MiniX) and _IsFinite(UI.MiniY) then
        self.Mini.Position = UDim2.fromOffset(UI.MiniX, UI.MiniY)
    end
    self:_Layout()
    if type(UI.Subtabs) == "table" then
        for _, Tab in ipairs(self.Tabs) do
            Tab:SelectSubtab(UI.Subtabs[Tab.Name])
        end
    end
    self:SelectTab(UI.Tab)
    self:_UpdateNavigationHover()
end

--[[
    更新強調色並重算所有仍存在的主題綁定，最後排程保存。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Color Color3 或支援的 HEX 顏色輸入。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.SetAccent(self: CWindowType, Color: ColorInput): CWindowType
    Color = _ParseColor(Color)
    if not Color or self.bDestroyed then
        return self
    end
    self.Theme.Accent = Color
    if self.Cursor.bUseAccent then
        self:_PaintCursor()
    end
    for Object, Properties in pairs(self._Bindings) do
        if Object.Parent then
            for Property, Token in pairs(Properties) do
                Object[Property] = type(Token) == "function" and Token(self.Theme) or self.Theme[Token]
            end
        else
            self._Bindings[Object] = nil
        end
    end
    return self:_ChangedUI()
end

--[[
    標記外觀設定已改變並回傳視窗，支援連續呼叫。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前實例，可繼續串接操作。
]]
function CWindow._ChangedUI(self: CWindowType): CWindowType
    self:_Dirty()
    return self
end

--[[
    限制介面縮放比例，關閉浮層並重新佈局。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Number 介面縮放比例，會限制到 0.65 至 1.5。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.SetScale(self: CWindowType, Number: number): CWindowType
    self.Scale = _Clamp(_NumberOr(Number, 1), 0.65, 1.5)
    self:ClosePopup()
    self:_Layout()
    return self:_ChangedUI()
end

--[[
    更新偏好尺寸，限制於允許範圍並依螢幕重新佈局。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Width 邏輯寬度，單位為未縮放像素。
    @param Height 邏輯高度，單位為未縮放像素。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.SetSize(self: CWindowType, Width: number, Height: number): CWindowType
    if self.bDestroyed then
        return self
    end
    if self.bMaximized then self:SetMaximized(false) end
    self:ClosePopup()
    self:_FinishDrag()
    self.PreferredWidth = _Clamp(_NumberOr(Width, self.PreferredWidth), self.MinWidth, self.MaxWidth)
    self.PreferredHeight = _Clamp(_NumberOr(Height, self.PreferredHeight), self.MinHeight, self.MaxHeight)
    self:_Layout()
    return self:_ChangedUI()
end

--[[
    取得目前佈局後的邏輯寬度與高度。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前邏輯寬度，未乘上 RenderScale。
    @return 目前邏輯高度，未乘上 RenderScale。
]]
function CWindow.GetSize(self: CWindowType): (number, number)
    return self.Width, self.Height
end

--[[
    設定是否允許從四邊與四角調整尺寸。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param bEnabled true 啟用此行為；false 停用。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.SetResizable(self: CWindowType, bEnabled: boolean): CWindowType
    self.bResizable = bEnabled == true
    if not self.bResizable and self._Resizing then
        self:_FinishDrag()
    end
    for _, Handle in pairs(self.ResizeHandles or {}) do
        Handle.Visible = self.bResizable and not self.bMaximized
    end
    return self
end

--[[
    切換短動畫並排程保存外觀設定。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param bEnabled true 啟用此行為；false 停用。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.SetAnimations(self: CWindowType, bEnabled: boolean): CWindowType
    self.bAnimations = bEnabled == true
    if not self.bAnimations then self:_FinishMinimizeMotion() end
    return self:_ChangedUI()
end

--[[
    同步更新視窗名稱與標題文字。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Text 要顯示或搜尋的文字；接受 tostring 可轉換的值。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.SetTitle(self: CWindowType, Text): CWindowType
    self.Title.Text = tostring(Text)
    self.Name = tostring(Text)
    return self
end

local function _BrandInitial(Text: string): string
    Text = tostring(Text or ""):match("^%s*(.-)%s*$")
    if Text == "" then return "B" end
    local bOk, Next = pcall(utf8.offset,Text,2)
    return bOk and (Next and Text:sub(1,Next-1) or Text) or Text:sub(1,1)
end

function CWindow._RenderBrand(self: CWindowType): ()
    self._bRenderingBrand = true
    self.Brand.Text = self.bNavigationExpanded and self.BrandText or _BrandInitial(self.BrandText)
    self._bRenderingBrand = false
    if self.Mini then self.Mini.Text = self.MiniIcon and "" or _BrandInitial(self.BrandText) end
end

function CWindow.SetBrand(self: CWindowType, Text: string): CWindowType
    if self.bDestroyed then return self end
    self.BrandText = tostring(Text or "")
    self:_RenderBrand()
    return self
end

-- 未設定或清除 Icon 時回到品牌開頭文字；SVG、註冊名稱及圖片 ID 使用既有圖示流程。
function CWindow.SetIcon(self: CWindowType, Icon: string | number?): CWindowType
    if self.bDestroyed then return self end
    if (type(Icon)~="string" and type(Icon)~="number") or Icon=="" or Icon==0 then Icon=nil end
    if self.Icon~=Icon or (Icon and not self.MiniIcon) then
        if self.MiniIcon then _Dispose(self,self.MiniIcon);self.MiniIcon=nil end
        self.Icon = Icon
        if Icon then
            self.MiniIcon = _Icon(self,self.MiniContent,Icon,nil,28,"AccentText")
            self.MiniIcon.AnchorPoint = Vector2.new(0.5,0.5)
            self.MiniIcon.Position = UDim2.fromScale(0.5,0.5)
        end
    end
    self:_RenderBrand()
    return self
end

--[[
    更新視窗副標題文字。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Text 要顯示或搜尋的文字；接受 tostring 可轉換的值。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.SetSubtitle(self: CWindowType, Text): CWindowType
    self.Subtitle.Text = tostring(Text)
    return self
end

--[[
    結束唯一的進行中拖曳，恢復捲動容器並呼叫結束回呼。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CWindow._FinishDrag(self: CWindowType): ()
    local Drag = self._Drag
    self._Drag = nil
    self:_RefreshCursor()
    if Drag then
        for Object, Old in pairs(Drag._Scrollers) do
            if Object.Parent then
                Object.ScrollingEnabled = Old
            end
        end
        if Drag._Finish then
            Drag._Finish()
        end
        self:_UpdateNavigationHover()
    end
end

--[[
    開始滑鼠或觸控拖曳；先結束舊拖曳，暫停祖先捲動容器，立即傳入目前座標。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Input 開始或更新互動的 Rbx InputObject。
    @param Update 指標更新時執行的回呼；開始拖曳時立即呼叫一次。
    @param Finish 拖曳結束時的回呼；nil 表示無額外收尾。
    @param Owner 回呼或浮層所屬物件，用於生命週期判斷。

    使用範例：
    前提：在本模組內，Window、Input 與 Handle 分別是視窗、有效指標輸入與 GUI。
    ```lua
    Window:_BeginDrag(Input, print, nil, Handle) -- 立即輸出座標，後續移動由視窗分派
    Window:_FinishDrag() -- 恢復祖先容器的捲動
    ```
]]
function CWindow._BeginDrag(
    self: CWindowType,
    Input: InputObject,
    Update: DragCallback,
    Finish: VoidCallback?,
    Owner: GuiObject?
): ()
    if not _IsPointer(Input) or self.bDestroyed then
        return
    end
    self:_FinishDrag()
    local Scrollers = {}
    local Object = Owner
    while Object and Object ~= self.ScreenGui do
        if Object:IsA("ScrollingFrame") then
            Scrollers[Object] = Object.ScrollingEnabled
            Object.ScrollingEnabled = false
        end
        Object = Object.Parent
    end
    self._Drag =
        { _Input = Input, _Update = Update, _Finish = Finish, _Scrollers = Scrollers, _Owner = Owner }
    Update(Input.Position)
    self:_RefreshCursor()
end

--[[
    釋放所有仍按住的快捷鍵，並以 false 通知對應回呼。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CWindow._ReleaseKeys(self: CWindowType): ()
    for Control in pairs(self._Keybinds) do
        if Control._bHeld then
            Control._bHeld = false
            _InvokeCallback(Control, Control.Callback, false)
        end
    end
end

--[[
    取消鍵位擷取並恢復控制項的正常文字。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CWindow._CancelCapture(self: CWindowType): ()
    if self._Capture then
        local Control = self._Capture
        self._Capture = nil
        Control:_Render()
    end
end

-- 結束或取消縮小過場；只還原隱藏視窗的變形，不改寫偏好尺寸與原始位置。
function CWindow._FinishMinimizeMotion(self: CWindowType): ()
    local Motion = self._MinimizeMotion
    if not Motion then return end
    self._MinimizeMotion = nil
    if self._MinimizeTask and self._Scope._Timers[self._MinimizeTask] then
        self._Scope._Timers[self._MinimizeTask] = nil
        _CancelTask(self._MinimizeTask)
    end
    self._MinimizeTask = nil
    self.Main.Visible = self.bVisible and not self.bDestroyed
    self:_Tween(self.Main,{Position=Motion.Position},0)
    self:_Tween(self.UIScale,{Scale=self.RenderScale or self.Scale},0)
    _Dispose(self,Motion.Blocker)
    self:_RefreshCursor()
end

--[[
    隱藏主視窗與最小化圖示，並結束浮層、拖曳、過場與按鍵擷取。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.Hide(self: CWindowType): CWindowType
    if self.bDestroyed then
        return self
    end
    self:_FinishMinimizeMotion()
    self:ClosePopup()
    self:_FinishDrag()
    self:_ReleaseKeys()
    self:_CancelCapture()
    self.Main.Visible = false
    self.Mini.Visible = false
    self.bVisible = false
    self:SetNavigationExpanded(false)
    if self._NavigationTask then
        self._Scope._Timers[self._NavigationTask] = nil
        _CancelTask(self._NavigationTask)
        self._NavigationTask = nil
    end
    self:_Layout()
    self:_ResetFeedback()
    self:_RefreshCursor()
    return self
end

--[[
    顯示主視窗、隱藏最小化圖示並重新佈局。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.Show(self: CWindowType): CWindowType
    if self.bDestroyed then
        return self
    end
    self:_FinishMinimizeMotion()
    self.Main.Visible = true
    self.Mini.Visible = false
    self.bVisible = true
    self.bMinimized = false
    self:_ResetFeedback(self.Mini)
    self:_Layout()
    self:_UpdateNavigationHover()
    return self
end

--[[
    在主視窗與可拖曳小方塊之間切換；明確 Hide 後也能重新顯示。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.Toggle(self: CWindowType): CWindowType
    if self.bVisible then
        return self:Minimize()
    else
        return self:Restore()
    end
end

--[[
    將視窗縮成可拖曳的小圖示。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.Minimize(self: CWindowType): CWindowType
    if self.bDestroyed or (self.bMinimized and self.Mini.Visible) then
        return self
    end
    local bAnimate = self.bAnimations and self.bVisible and self.Main.Visible
    local Original = self.Main.Position
    self:Hide()
    self.Mini.Visible = true
    self.bMinimized = true
    if bAnimate then
        self.Main.Position = Original
        self.Main.Visible = true
        local Blocker = _CreateInstance("TextButton",self.Main,{
            Name="MinimizeInputBlocker",Text="",BackgroundTransparency=1,BorderSizePixel=0,
            Size=UDim2.fromScale(1,1),AutoButtonColor=false,Active=true,Selectable=false,ZIndex=1000,
        })
        self._MinimizeMotion = {Position=Original,Blocker=Blocker}
        local Size,Position = self.Mini.AbsoluteSize,self.Mini.AbsolutePosition-self.Surface.AbsolutePosition
        local Scale = math.min(Size.X/self.Width,Size.Y/self.Height)
        local Target = UDim2.fromOffset(Position.X+(Size.X-self.Width*Scale)/2,Position.Y+(Size.Y-self.Height*Scale)/2)
        self:_Tween(self.Main,{Position=Target},MINIMIZE_DURATION,Enum.EasingStyle.Quint)
        self:_Tween(self.UIScale,{Scale=Scale},MINIMIZE_DURATION,Enum.EasingStyle.Quint)
        self._MinimizeTask = _Schedule(self._Scope,MINIMIZE_DURATION,function(): ()
            self._MinimizeTask = nil
            self:_FinishMinimizeMotion()
        end)
    end
    self:_RefreshCursor()
    return self
end

--[[
    從最小化狀態恢復主視窗。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前實例，可繼續串接操作。
]]
function CWindow.Restore(self: CWindowType): CWindowType
    self:Show()
    return self
end

-- 最大化保留原本的偏好尺寸；還原後回到原來位置。
function CWindow.SetMaximized(self: CWindowType, bEnabled: boolean): CWindowType
    bEnabled = bEnabled == true
    if self.bDestroyed or self.bMaximized == bEnabled then return self end
    self:_FinishMinimizeMotion()
    self:ClosePopup()
    self:_FinishDrag()
    self:_CancelCapture()
    if bEnabled then
        self._RestorePosition = self.Main.Position
    elseif self._RestorePosition then
        self.Main.Position = self._RestorePosition
        self._RestorePosition = nil
    end
    self.bMaximized = bEnabled
    if self.MaximizeIcon then _Dispose(self,self.MaximizeIcon) end
    self.MaximizeIcon = _Icon(self,self.MaximizeButton,bEnabled and "Restore" or "Maximize",nil,20,"Text")
    self.MaximizeIcon.AnchorPoint = Vector2.new(0.5,0.5)
    self.MaximizeIcon.Position = UDim2.fromScale(0.5,0.5)
    self:_Layout()
    return self
end

function CWindow.ToggleMaximize(self: CWindowType): CWindowType
    return self:SetMaximized(not self.bMaximized)
end

-- 更新目前展開狀態；相同狀態不重新啟動動畫，也不保存暫時的懸停狀態。
function CWindow.SetNavigationExpanded(self: CWindowType, bExpanded: boolean): CWindowType
    bExpanded = bExpanded == true
    if self.bDestroyed or self.bNavigationExpanded == bExpanded then
        return self
    end
    self.bNavigationExpanded = bExpanded
    self:ClosePopup()
    self:_ResetFeedback()
    self:_Layout(true, true)
    return self
end

function CWindow.ToggleNavigation(self: CWindowType): CWindowType
    return self:SetNavigationExpanded(not self._bNavigationExpanded)
end

-- 只在滑鼠移動、側欄邊界及視窗狀態事件更新；不使用逐幀輪詢。
function CWindow._UpdateNavigationHover(self: CWindowType): ()
    if self.bDestroyed or not self.Sidebar or self._Drag then
        return
    end
    if not self.bVisible
        or not self.Main.Visible
        or not self.ScreenGui.Enabled
        or self.bLocked
        or not self._bNavigationFocused
        or not UserInputService.MouseEnabled
    then
        self:SetNavigationExpanded(false)
        return
    end
    local GuiInset = game:GetService("GuiService"):GetGuiInset()
    local Point = UserInputService:GetMouseLocation() - GuiInset
    self:SetNavigationExpanded(_ContainsPoint(self.Sidebar, Point))
end

--[[
    保存設定後釋放視窗、控制項、浮層、通知與事件；可重複呼叫。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CWindow.Destroy(self: CWindowType): ()
    if self.bDestroyed then
        return
    end
    self:_FinishMinimizeMotion()
    if self.bConfigEnabled then
        self:SaveConfiguration()
    end
    self:ClosePopup()
    self:_FinishDrag()
    self:_ReleaseKeys()
    self:_CancelCapture()
    self.bDestroyed = true
    self:_ReleaseCursor()
    for Index = #self._Controls, 1, -1 do
        self._Controls[Index]:Destroy()
    end
    for _, Tab in ipairs(self.Tabs) do
        _CleanScope(Tab._Scope)
        for _, Section in ipairs(Tab.Sections) do
            _CleanScope(Section._Scope)
        end
    end
    for Toast in pairs(self._Toasts) do
        Toast:Destroy()
    end
    for _, Tw in pairs(self._Tweens) do
        Tw:Cancel()
    end
    _CleanScope(self._Scope)
    self._NavigationTask = nil
    for Host in pairs(self._SvgScopes) do
        _Dispose(self,Host)
    end
    self._SvgScopes = {}
    if not self._bGuiDestroying then
        self.ScreenGui:Destroy()
    end
    self._CursorSettingsGroups = {}
    self._CursorTargets = {}
    self._CursorPaint = {}
    self._CursorComposite = nil
    self._Bindings = {}
    self._Tweens = {}
    self._Feedback = {}
    self.ResizeHandles = {}
    self._ResizeHints = {}
    if Library.Windows[self.ConfigId] == self then
        Library.Windows[self.ConfigId] = nil
    end
    if self._Registry[self.ConfigId] == self then
        self._Registry[self.ConfigId] = nil
    end
    if Library._Last == self then
        Library._Last = nil
    end
    local Callback = self._OnUnload
    self._OnUnload = nil
    if Callback then
        local bOk, Err = pcall(Callback,self)
        if not bOk then warn("[BjzUi] OnUnload: " .. tostring(Err)) end
    end
end

-- 清理 Library 管理的事件、計時器、浮層、通知及視窗，再通知外部腳本清理自己的工作。
function CWindow.Unload(self: CWindowType): ()
    self:Destroy()
end

--[[
    依目前螢幕與縮放計算可用的尺寸上下限。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 允許的最小寬度。
    @return 允許的最大寬度。
    @return 允許的最小高度。
    @return 允許的最大高度。
]]
function CWindow._SizeLimits(self: CWindowType): (number, number, number, number)
    local Screen = self.Surface.AbsoluteSize
    local Scale = self.RenderScale or self.Scale
    local MaxW = math.min(self.MaxWidth, math.max(1, (Screen.X - 24) / Scale))
    local MaxH = math.min(self.MaxHeight, math.max(1, (Screen.Y - 24) / Scale))
    return math.min(self.MinWidth, MaxW), MaxW, math.min(self.MinHeight, MaxH), MaxH
end

--[[
    依螢幕與偏好尺寸安排側欄、內容欄與搜尋列；只在斷點變更時重掛區塊。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param bForce true 強制重掛區塊；false 或 nil 僅在響應式斷點改變時重掛。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    Window:SetSize(480, 600) -- 內容使用單欄；側欄仍依游標進出自動展開／收合
    Window:SetSize(1000, 700) -- 寬度足夠時恢復雙欄
    ```
]]
function CWindow._Layout(self: CWindowType, bForce: boolean?, bAnimateNavigation: boolean?): ()
    if self.bDestroyed then
        return
    end
    self:_FinishMinimizeMotion()
    local Screen = self.Surface.AbsoluteSize
    if Screen.X < 1 or Screen.Y < 1 then
        return
    end
    if self.ToastHost then
        local ToastWidth = math.min(320, math.max(160, Screen.X - 32))
        self.ToastHost.Size = UDim2.new(0, ToastWidth, 1, -32)
        self.ToastHost.Position = UDim2.new(1, -ToastWidth - 16, 0, 16)
    end
    local Scale = math.max(
        0.05,
        math.min(self.Scale, (Screen.X - 24) / self.MinWidth, (Screen.Y - 24) / self.MinHeight)
    )
    self.RenderScale = Scale
    self.UIScale.Scale = Scale
    local Width = math.max(1, self.bMaximized and (Screen.X - 24) / Scale or math.min(self.PreferredWidth, (Screen.X - 24) / Scale))
    local Height = math.max(1, self.bMaximized and (Screen.Y - 24) / Scale or math.min(self.PreferredHeight, (Screen.Y - 24) / Scale))
    self.Width, self.Height = Width, Height
    self.Main.Size = UDim2.fromOffset(Width, Height)
    for _, Handle in pairs(self.ResizeHandles or {}) do Handle.Visible = self.bVisible and self.bResizable and not self.bMaximized end
    if self._NavigationTask then
        self._Scope._Timers[self._NavigationTask] = nil
        _CancelTask(self._NavigationTask)
        self._NavigationTask = nil
    end
    local bExpanded = self.bNavigationExpanded
    local bAnimate = bAnimateNavigation == true and self.bAnimations and self.bVisible
    local Duration = bAnimate and NAVIGATION_DURATION or 0
    self._bNavigationExpanded = bExpanded
    local Nav = bExpanded and 186 or 60
    self:_Tween(self.Sidebar, { Size = UDim2.new(0, Nav, 1, 0) }, Duration)
    self:_RenderBrand()
    self.Brand.TextXAlignment = bExpanded and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
    self:_Tween(self.Brand, {
        Position = UDim2.fromOffset(bExpanded and 16 or 0, 18),
        Size = UDim2.new(1, bExpanded and -28 or 0, 0, 36),
    }, Duration)
    self.User.Text = bExpanded and self.UserText or "●"
    local Gutter = Width < 720 and 12 or 18
    self:_Tween(self.Body, {
        Position = UDim2.fromOffset(Nav + Gutter, 0),
        Size = UDim2.new(1, -Nav - Gutter * 2, 1, 0),
    }, Duration)
    for _, Tab in ipairs(self.Tabs) do
        Tab.NavIcon.AnchorPoint = Vector2.new(0.5, 0.5)
        self:_Tween(Tab.NavIcon, {
            Position = bExpanded and UDim2.new(0, 19, 0.5, 0) or UDim2.fromScale(0.5, 0.5),
        }, Duration)
        -- 收合期間先淡出名稱，結束後才隱藏；展開時先顯示再淡入。
        Tab.NavLabel.Visible = bExpanded or bAnimate
        self:_Tween(Tab.NavLabel, { TextTransparency = bExpanded and 0 or 1 }, Duration)
    end
    if bAnimate and not bExpanded then
        self._NavigationTask = _Schedule(self._Scope, Duration, function(): ()
            self._NavigationTask = nil
            if not self.bNavigationExpanded then
                for _, Tab in ipairs(self.Tabs) do
                    Tab.NavLabel.Visible = false
                end
            end
        end)
    end
    self.Subtitle.Visible = Height > 340
    local Available = Width - Nav - Gutter * 2
    self.Title.TextSize = Available < 380 and 18 or 23
    self.PageTitle.Visible = Available >= 410
    self.Search.Size = UDim2.new(1, Available >= 410 and -106 or 0, 0, 30)
    local SearchY = Height > 340 and 84 or 60
    self.Search.Position = UDim2.fromOffset(0, SearchY)
    self.PageTitle.Position = UDim2.new(1, -98, 0, SearchY)
    self.Content.Position = UDim2.fromOffset(0, SearchY + 40)
    self.Content.Size = UDim2.new(1, 0, 1, -SearchY - 52)
    self.bSingleColumn = Available < 620
    -- Reparent sections only when a breakpoint changes, not at every pointer event.
    local Mode = tostring(bExpanded) .. ":" .. tostring(self.bSingleColumn)
    if bForce or Mode ~= self._ResponsiveMode then
        self._ResponsiveMode = Mode
        for _, Tab in ipairs(self.Tabs) do
            for _, Page in ipairs(Tab.Pages) do
                Page.Right.Visible = not self.bSingleColumn
                Page.Left.Size = self.bSingleColumn and UDim2.new(1, 0, 0, 0) or UDim2.new(0.5, -6, 0, 0)
                for _, Sec in ipairs(Page.Sections) do
                    local Parent = (Sec.Side == "full" and Page.Full)
                        or (Sec.Side == "right" and not self.bSingleColumn and Page.Right)
                        or Page.Left
                    if Sec.Frame.Parent ~= Parent then
                        Sec.Frame.Parent = Parent
                    end
                end
            end
        end
    end
    local X, Y = self.Main.Position.X.Offset, self.Main.Position.Y.Offset
    if self.bMaximized then
        X, Y = 12, 12
    elseif not self._bPositioned then
        X = (Screen.X - Width * Scale) / 2
        Y = (Screen.Y - Height * Scale) / 2
        self._bPositioned = true
    end
    self.Main.Position = UDim2.fromOffset(
        _Clamp(X, 4, math.max(4, Screen.X - Width * Scale - 4)),
        _Clamp(Y, 4, math.max(4, Screen.Y - Height * Scale - 4))
    )
    self.Mini.Position = UDim2.fromOffset(
        _Clamp(self.Mini.Position.X.Offset, 4, math.max(4, Screen.X - 52)),
        _Clamp(self.Mini.Position.Y.Offset, 4, math.max(4, Screen.Y - 52))
    )
    self:_RefreshCursor()
end

--[[
    建立八個尺寸拖曳把手，將滑鼠與觸控事件納入視窗生命週期。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    Window:SetResizable(false) -- 八個把手隱藏
    Window:SetResizable(true) -- 四邊與四角可再次拖曳
    ```
]]
function CWindow._InstallResizeHandles(self: CWindowType): ()
    self.ResizeHandles = {}
    self._ResizeHints = {}
    local Specs = {
        { "Left", -1, 0, UDim2.new(0, 10, 1, -28), UDim2.fromOffset(-4, 14) },
        { "Right", 1, 0, UDim2.new(0, 10, 1, -28), UDim2.new(1, -6, 0, 14) },
        { "Top", 0, -1, UDim2.new(1, -28, 0, 10), UDim2.fromOffset(14, -4) },
        { "Bottom", 0, 1, UDim2.new(1, -28, 0, 10), UDim2.new(0, 14, 1, -6) },
        { "TopLeft", -1, -1, UDim2.fromOffset(20, 20), UDim2.fromOffset(-4, -4) },
        { "TopRight", 1, -1, UDim2.fromOffset(20, 20), UDim2.new(1, -16, 0, -4) },
        { "BottomLeft", -1, 1, UDim2.fromOffset(20, 20), UDim2.new(0, -4, 1, -16) },
        { "BottomRight", 1, 1, UDim2.fromOffset(20, 20), UDim2.new(1, -16, 1, -16) },
    }
    for _, Spec in ipairs(Specs) do
        local Name, DirX, DirY = Spec[1], Spec[2], Spec[3]
        local Handle = _CreateInstance("TextButton", self.Main, {
            Name = "Resize" .. Name,
            Text = "",
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            AutoButtonColor = false,
            Size = Spec[4],
            Position = Spec[5],
            ZIndex = 50,
            Active = true,
            Visible = self.bResizable,
            ClipsDescendants = false,
        })
        self.ResizeHandles[Name] = Handle
        local Hint = _Frame(Handle, UDim2.new(1, -4, 1, -4), UDim2.fromOffset(2, 2))
        Hint.Visible = false
        _Corner(Hint, 4)
        local Border = _Stroke(self, Hint, "Accent")
        Border.Transparency = 0.25
        self._ResizeHints[Name] = Hint
        local bHovering = false

        --[[
            標記滑鼠位於尺寸把手上並顯示其提示框。
        ]]
        _Connect(self._Scope, Handle.MouseEnter, function(): ()
            bHovering = true
            Hint.Visible = true
        end)

        --[[
            移除滑鼠停留狀態；該把手未在拖曳時隱藏提示框。
        ]]
        _Connect(self._Scope, Handle.MouseLeave, function(): ()
            bHovering = false
            if self._Resizing ~= Name then
                Hint.Visible = false
            end
        end)

        --[[
            在視窗可互動時記錄原始矩形與對邊位置，並開始調整尺寸。

            @param Input 開始或更新互動的 Rbx InputObject。
        ]]
        _Connect(self._Scope, Handle.InputBegan, function(Input: InputObject): ()
            if not self.bResizable or not self.bVisible or self.bLocked or not _IsPointer(Input) then
                return
            end
            self:ClosePopup()
            self:_CancelCapture()
            self:_FinishDrag()
            local Start = Input.Position
            local Scale = self.RenderScale or self.Scale
            local X, Y = self.Main.Position.X.Offset, self.Main.Position.Y.Offset
            local Width, Height = self.Width, self.Height
            local FixedRight, FixedBottom = X + Width * Scale, Y + Height * Scale
            local MinW, MaxW, MinH, MaxH = self:_SizeLimits()
            local Screen = self.Surface.AbsoluteSize
            local bChanged = false
            self:_BeginDrag(
                Input,
                --[[
                    依把手方向更新矩形，固定相對邊並限制最小尺寸與螢幕範圍。

                    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
                ]]
                function(Position): ()
                    local Dx, Dy = Position.X - Start.X, Position.Y - Start.Y
                    local Left, Top, Right, Bottom = X, Y, FixedRight, FixedBottom
                    if DirX < 0 then
                        Left =
                            _Clamp(X + Dx, math.max(4, FixedRight - MaxW * Scale), FixedRight - MinW * Scale)
                    elseif DirX > 0 then
                        Right = _Clamp(
                            FixedRight + Dx,
                            X + MinW * Scale,
                            math.min(Screen.X - 8, X + MaxW * Scale)
                        )
                    end
                    if DirY < 0 then
                        Top = _Clamp(
                            Y + Dy,
                            math.max(4, FixedBottom - MaxH * Scale),
                            FixedBottom - MinH * Scale
                        )
                    elseif DirY > 0 then
                        Bottom = _Clamp(
                            FixedBottom + Dy,
                            Y + MinH * Scale,
                            math.min(Screen.Y - 8, Y + MaxH * Scale)
                        )
                    end
                    self._Resizing = Name
                    Hint.Visible = true
                    if
                        math.abs(Right - Left - Width * Scale) > 0.01
                        or math.abs(Bottom - Top - Height * Scale) > 0.01
                    then
                        bChanged = true
                    end
                    self.PreferredWidth = (Right - Left) / Scale
                    self.PreferredHeight = (Bottom - Top) / Scale
                    self.Main.Position = UDim2.fromOffset(Left, Top)
                    self._bPositioned = true
                    self:_Layout()
                end,
                --[[
                    結束尺寸調整；只有尺寸確實變動時才排程儲存。
                ]]
                function(): ()
                    self._Resizing = nil
                    Hint.Visible = bHovering
                    if bChanged then
                        self:_Dirty()
                    end
                end,
                Handle
            )
        end)
    end
end

--[[
    關閉現有浮層並釋放其事件；必要時結束浮層內的拖曳。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CWindow.ClosePopup(self: CWindowType): ()
    local Popup = self._Popup
    self._Popup = nil
    if Popup then
        if self._Drag and self._Drag._Owner and self._Drag._Owner:IsDescendantOf(Popup.Host) then
            self:_FinishDrag()
        end
        _CleanScope(Popup.Scope)
        _Dispose(self, Popup.Host)
        if Popup.OnClose then
            Popup.OnClose()
        end
    end
    self:_RefreshCursor()
end

--[[
    在獨立浮層建立面板，避開螢幕邊界並在背景點擊或祖先捲動時關閉。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Anchor 浮層的錨點 GUI，用其絕對位置決定浮層位置。
    @param Width 邏輯寬度，單位為未縮放像素。
    @param Height 邏輯高度，單位為未縮放像素。
    @param Owner 回呼或浮層所屬物件，用於生命週期判斷。
    @param OnClose 浮層清理後執行的回呼；nil 表示不額外處理。
    @return 浮層面板；視窗已銷毀或隱藏時為 nil。
    @return 面板的事件 Scope；未建立面板時為 nil。

    使用範例：
    前提：在本模組內，Window、Button 與 Control 已建立。
    ```lua
    local Panel, Scope = Window:_OpenPopup(Button, 280, 200, Control, nil)
    if Panel then Window:ClosePopup() end -- 同時清理 Scope
    ```
]]
function CWindow._OpenPopup(
    self: CWindowType,
    Anchor,
    Width: number,
    Height: number,
    Owner: CControlType,
    OnClose: VoidCallback?
): (Frame?, ScopeState?)
    self:ClosePopup()
    if self.bDestroyed or not self.bVisible then
        return nil
    end
    local PopupScope = _CreateScope()
    local Host = _Frame(self.Surface, UDim2.fromScale(1, 1))
    Host.ZIndex = 100
    local Dismiss = _Button(self, Host, "", UDim2.fromScale(1, 1))
    Dismiss.BackgroundTransparency = 1
    Dismiss.ZIndex = 100
    for _, Item in ipairs(Dismiss:GetChildren()) do
        if Item:IsA("UIStroke") then
            Item.Enabled = false
        end
    end
    local Screen = self.Surface.AbsoluteSize
    local Scale = self.RenderScale or self.Scale
    Width = math.min(Width, (Screen.X - 16) / Scale)
    Height = math.min(Height, (Screen.Y - 16) / Scale)
    local Position, Size = Anchor.AbsolutePosition, Anchor.AbsoluteSize
    local X = _Clamp(Position.X, 8, math.max(8, Screen.X - Width * Scale - 8))
    local Y = Position.Y + Size.Y + 6
    if Y + Height * Scale > Screen.Y - 8 then
        Y = Position.Y - Height * Scale - 6
    end
    Y = _Clamp(Y, 8, math.max(8, Screen.Y - Height * Scale - 8))
    local Panel = _Frame(Host, UDim2.fromOffset(Width, Height), UDim2.fromOffset(X, Y))
    Panel.ZIndex = 101
    Panel.BackgroundTransparency = 0
    Panel.Active = true
    _BindTheme(self, Panel, "BackgroundColor3", "Card")
    _Corner(Panel, 6)
    _Stroke(self, Panel)
    _CreateInstance("UIScale", Panel, { Scale = Scale })
    self._Popup = { Host = Host, Panel = Panel, Scope = PopupScope, Owner = Owner, OnClose = OnClose }
    self:_RefreshCursor()

    --[[
        使用者點擊浮層外側時關閉目前浮層。
    ]]
    _Connect(PopupScope, Dismiss.Activated, function(): ()
        self:ClosePopup()
    end)
    local Object = Anchor.Parent
    while Object and Object ~= self.ScreenGui do
        if Object:IsA("ScrollingFrame") then
            --[[
                錨點所在容器捲動時關閉浮層，避免浮層位置脫離控制項。
            ]]
            _Connect(PopupScope, Object:GetPropertyChangedSignal("CanvasPosition"), function(): ()
                self:ClosePopup()
            end)
        end
        Object = Object.Parent
    end
    return Panel, PopupScope
end

--[[
    建立視窗、載入設定並註冊輸入生命週期；同 ConfigId 的舊視窗會先銷毀。

    @param OwnerLibrary 管理此視窗註冊與全域 Flag 的模組。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 完成初始化且已註冊輸入的視窗實例。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    Window:Destroy() -- 清理視窗擁有的事件與計時器
    ```
]]
function CWindow.new(OwnerLibrary: LibraryType, Options: WindowOptions?): CWindowType
    local Settings = _Options(Options)
    local Config = Settings.ConfigurationSaving or {}
    local Id = tostring(
        Settings.ConfigId or Config.FileName or ((Settings.Name or "BjzUi") .. "_" .. tostring(game.PlaceId))
    )
    local Env = (type(getgenv) == "function" and getgenv()) or _G
    if type(Env.__BjzUiWindowsV1) ~= "table" then
        Env.__BjzUiWindowsV1 = {}
    end
    local Registry = Env.__BjzUiWindowsV1
    if Registry[Id] and type(Registry[Id].Destroy) == "function" then
        Registry[Id]:Destroy()
    end
    local Data, ConfigError = _ReadConfig()
    local Saved = Data and Data.Windows[Id] or {}
    if type(Saved) ~= "table" then
        Saved = {}
    end
    local UI = type(Saved.UI) == "table" and Saved.UI or {}
    local MinWidth = _Clamp(_NumberOr(Settings.MinWidth, 360), 300, 1800)
    local MinHeight = _Clamp(_NumberOr(Settings.MinHeight, 300), 240, 1200)
    local MaxWidth = math.max(MinWidth, _NumberOr(Settings.MaxWidth, 1800))
    local MaxHeight = math.max(MinHeight, _NumberOr(Settings.MaxHeight, 1200))
    local Window = setmetatable({
        Name = tostring(Settings.Name or "控制中心"),
        BrandText = tostring(Settings.Brand or "BJZ UI"),
        ConfigId = Id,
        bConfigEnabled = Config.bEnabled ~= false,
        Theme = _CopyTable(DEFAULT_THEME),
        Scale = _Clamp(_NumberOr(UI.Scale, _NumberOr(Settings.Scale, 1)), 0.65, 1.5),
        bAnimations = Settings.bAnimations ~= false,
        ToggleKey = _KeyFrom(Settings.ToggleKey) or _KeyFrom(UI.ToggleKey) or Enum.KeyCode.RightShift,
        PreferredWidth = _Clamp(_NumberOr(UI.Width, _NumberOr(Settings.Width, 1000)), MinWidth, MaxWidth),
        PreferredHeight = _Clamp(_NumberOr(UI.Height, _NumberOr(Settings.Height, 700)), MinHeight, MaxHeight),
        MinWidth = MinWidth,
        MaxWidth = MaxWidth,
        MinHeight = MinHeight,
        MaxHeight = MaxHeight,
        bResizable = Settings.bResizable ~= false,
        CloseAction = Settings.CloseAction == "Hide" and "Hide" or "Unload",
        _OnUnload = type(Settings.OnUnload) == "function" and Settings.OnUnload or nil,
        Flags = {},
        Tabs = {},
        _Controls = {},
        _CursorTargets = {},
        _CursorSettingsGroups = {},
        _Keybinds = {},
        _Toasts = {},
        _Scope = _CreateScope(),
        -- Keep live Instance wrappers strongly referenced until _Dispose()/Destroy().
        _Bindings = {},
        _Tweens = setmetatable({}, { __mode = "k" }),
        _Feedback = {},
        _SvgScopes = {},
        _SavedFlags = type(Saved.Flags) == "table" and Saved.Flags or {},
        _SavedUI = UI,
        _Registry = Registry,
        _bLoading = true,
        bVisible = true,
        bDestroyed = false,
        bMinimized = false,
        bMaximized = false,
        bNavigationExpanded = false,
        _bNavigationFocused = true,
        LastConfigError = ConfigError,
    }, CWindow)
    if type(UI.Animations) == "boolean" then
        Window.bAnimations = UI.Animations
    end
    Window._CursorPaint = {}
    Window.Cursor = _NormalizeCursor(_NormalizeCursor(nil, Settings.Cursor), UI.Cursor)
    Window.Theme.Accent = _ParseColor(UI.Accent) or _ParseColor(Settings.Accent) or DEFAULT_THEME.Accent
    Window.ScreenGui = _CreateInstance("ScreenGui", nil, {
        Name = HttpService:GenerateGUID(false):gsub("%-", ""),
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        DisplayOrder = _NumberOr(Settings.DisplayOrder, 1000),
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })

    --[[
        在平台支援時停用 ScreenInsets；不支援的屬性由外層 pcall 忽略。
    ]]
    pcall(function(): ()
        Window.ScreenGui.ScreenInsets = Enum.ScreenInsets.None
    end)
    local bParented = false
    local GetHiddenUI = Env.gethui or gethui
    if type(GetHiddenUI) == "function" then
        --[[
            嘗試將 ScreenGui 掛到執行器提供的介面容器。
        ]]
        bParented = pcall(function(): ()
            Window.ScreenGui.Parent = GetHiddenUI()
        end)
    end
    if not bParented or not Window.ScreenGui.Parent then
        --[[
            嘗試將 ScreenGui 掛到 CoreGui。
        ]]
        bParented = pcall(function(): ()
            Window.ScreenGui.Parent = game:GetService("CoreGui")
        end)
    end
    if not bParented or not Window.ScreenGui.Parent then
        local Player = Players.LocalPlayer
        assert(Player, "BjzUi requires a client LocalPlayer")
        Window.ScreenGui.Parent = Player:WaitForChild("PlayerGui")
    end
    Window.Surface = _Frame(Window.ScreenGui, UDim2.fromScale(1, 1))
    Window.Main = _Frame(Window.Surface, UDim2.fromOffset(Window.PreferredWidth, Window.PreferredHeight))
    Window.Main.Name = "MainWindow"
    Window.Main.ZIndex = 10
    Window.Main.BackgroundTransparency = 0
    Window.Main.Active = true
    _BindTheme(Window, Window.Main, "BackgroundColor3", "Background")
    _Corner(Window.Main, 8)
    _Stroke(Window, Window.Main)
    Window.UIScale = _CreateInstance("UIScale", Window.Main, { Scale = Window.Scale })
    Window.Sidebar = _Frame(Window.Main, UDim2.new(0, 60, 1, 0))
    Window.Sidebar.Name = "NavigationBar"
    Window.Sidebar.Active = true
    Window.Sidebar.ClipsDescendants = true
    Window.Sidebar.BackgroundTransparency = 0
    _BindTheme(Window, Window.Sidebar, "BackgroundColor3", "Sidebar")
    _Corner(Window.Sidebar, 8)
    Window.Brand = _Label(
        Window,
        Window.Sidebar,
        Window.BrandText,
        UDim2.new(1, -28, 0, 36),
        UDim2.fromOffset(18, 18),
        20,
        "Accent"
    )
    Window.Brand.Font = Enum.Font.GothamBold
    _Connect(Window._Scope, Window.Sidebar.MouseEnter, function(): ()
        if Window.bVisible and not Window.bLocked and Window._bNavigationFocused and not Window._Drag then
            Window:SetNavigationExpanded(true)
        end
    end)
    _Connect(Window._Scope, Window.Sidebar.MouseLeave, function(): ()
        -- 子物件接手滑鼠時仍以實際側欄範圍判定，避免誤收合。
        Window:_UpdateNavigationHover()
    end)
    local NavLine = _Frame(Window.Sidebar, UDim2.new(1, -24, 0, 1), UDim2.fromOffset(12, 70))
    NavLine.BackgroundTransparency = 0
    _BindTheme(Window, NavLine, "BackgroundColor3", "Border")
    Window.Nav = _ScrollingFrame(Window, Window.Sidebar, UDim2.new(1, -16, 1, -134), UDim2.fromOffset(8, 86))
    _ListLayout(Window.Nav, 5)
    _Padding(Window.Nav, 3)
    local Player = Players.LocalPlayer
    Window.UserText = tostring(Settings.UserName or (Player and Player.DisplayName) or "使用者")
    Window.User = _Label(
        Window,
        Window.Sidebar,
        Window.UserText,
        UDim2.new(1, -28, 0, 30),
        UDim2.new(0, 16, 1, -42),
        12,
        "Muted"
    )
    Window.Body = _Frame(Window.Main, UDim2.new(1, -222, 1, 0), UDim2.fromOffset(204, 0))
    local bShowMaximize = Settings.bShowMaximizeButton == true
    local ToolbarWidth = bShowMaximize and 136 or 96
    Window.Title =
        _Label(Window, Window.Body, Window.Name, UDim2.new(1, -ToolbarWidth, 0, 32), UDim2.fromOffset(0, 18), 23)
    Window.Title.Font = Enum.Font.GothamBold
    Window.Subtitle = _Label(
        Window,
        Window.Body,
        tostring(
            Settings.LoadingSubtitle or Settings.Subtitle or "一致、清晰、易於操作的介面設計"
        ),
        UDim2.new(1, -8, 0, 20),
        UDim2.fromOffset(0, 52),
        12,
        "Muted"
    )
    local Dragger = _CreateInstance("TextButton", Window.Body, {
        Name = "DragHandle",
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Size = UDim2.new(1, -ToolbarWidth, 0, 52),
        Position = UDim2.fromOffset(0, 12),
        ZIndex = 3,
    })
    local Minimize = _Button(Window, Window.Body, "", UDim2.fromOffset(32, 30), UDim2.new(1, bShowMaximize and -116 or -76, 0, 20))
    local Maximize = _Button(Window, Window.Body, "", UDim2.fromOffset(32, 30), UDim2.new(1, -76, 0, 20))
    local Close = _Button(Window, Window.Body, "", UDim2.fromOffset(32, 30), UDim2.new(1, -36, 0, 20))
    Maximize.Visible = bShowMaximize
    Window.MinimizeButton, Window.MaximizeButton, Window.CloseButton = Minimize, Maximize, Close
    Minimize.Name, Maximize.Name, Close.Name = "MinimizeButton", "MaximizeButton", "CloseButton"
    local MinimizeIcon = _Icon(Window,Minimize,"Minimize",nil,20,"Text")
    local CloseIcon = _Icon(Window,Close,"Close",nil,20,"Text")
    Window.MaximizeIcon = _Icon(Window,Maximize,"Maximize",nil,20,"Text")
    for _, Icon in ipairs({MinimizeIcon,Window.MaximizeIcon,CloseIcon}) do
        Icon.AnchorPoint = Vector2.new(0.5,0.5)
        Icon.Position = UDim2.fromScale(0.5,0.5)
    end
    Window.Search = _TextBox(Window, Window.Body, "", UDim2.new(1, -106, 0, 30), UDim2.fromOffset(0, 84))
    Window.Search.PlaceholderText = "搜尋目前分頁的組件…"
    Window.PageTitle =
        _Label(Window, Window.Body, "", UDim2.fromOffset(98, 30), UDim2.new(1, -98, 0, 84), 12, "Muted")
    Window.Content = _Frame(Window.Body, UDim2.new(1, 0, 1, -128), UDim2.fromOffset(0, 124))
    Window.Content.ClipsDescendants = true
    Window.Mini =
        _Button(Window, Window.Surface, "", UDim2.fromOffset(46, 46), UDim2.fromOffset(18, 80), "primary")
    Window.Mini.ZIndex = 20
    Window.Mini.TextSize = 20
    Window.Mini.Font = Enum.Font.GothamBold
    Window.Mini.Visible = false
    Window.MiniContent = _Frame(Window.Mini,UDim2.fromScale(1,1),UDim2.fromScale(0.5,0.5))
    Window.MiniContent.AnchorPoint = Vector2.new(0.5,0.5)
    Window.MiniScale = _CreateInstance("UIScale",Window.MiniContent,{Scale=1})
    Window:SetIcon(Settings.Icon)
    _Connect(Window._Scope,Window.Brand:GetPropertyChangedSignal("Text"),function(): ()
        if not Window._bRenderingBrand then Window:SetBrand(Window.Brand.Text) end
    end)
    for _, Button in ipairs({ Minimize, Maximize, Close }) do
        _SetupFeedback(Window, Button, Window._Scope)
    end
    _SetupFeedback(Window,Window.Mini,Window._Scope,function(): boolean
        return Window.bMinimized and Window.Mini.Visible
    end,function(bActive: boolean): ()
        Window:_Tween(Window.Mini,{TextSize=bActive and 23 or 20})
        Window:_Tween(Window.MiniScale,{Scale=bActive and 1.12 or 1})
    end,{Color="AccentText",ZIndex=21,Inset=2})
    _SetupFeedback(Window, Window.Search, Window._Scope, function(): boolean
        return Window.bVisible and not Window.bLocked
    end)

    --[[
        按下最小化按鈕時縮小視窗。
    ]]
    _Connect(Window._Scope, Minimize.Activated, function(): ()
        Window:Minimize()
    end)
    _Connect(Window._Scope, Maximize.Activated, function(): ()
        Window:ToggleMaximize()
    end)

    --[[
        關閉預設卸載視窗；明確指定 CloseAction="Hide" 時才保留背景資源。
    ]]
    _Connect(Window._Scope, Close.Activated, function(): ()
        if Window.CloseAction == "Hide" then Window:Hide() else Window:Unload() end
    end)

    --[[
        將標題或最小化圖示的指標事件接到視窗拖曳流程。

        @param Handle 接受指標事件的 GUI。
        @param Target 實際移動位置的 GUI。
        @param bMini true 表示最小化圖示，其未移動的輕點會恢復視窗。

        使用範例：
        前提：在 CWindow.new 內，Dragger 與 Window.Main 已建立。
        ```lua
        _AttachMove(Dragger, Window.Main, false) -- 移動標題會拖曳視窗
        ```
    ]]
    local function _AttachMove(Handle, Target, bMini: boolean): ()
        --[[
            記錄拖曳起點與原始位置；最小化圖示的輕點保留為恢復操作。

            @param Input 開始或更新互動的 Rbx InputObject。
        ]]
        _Connect(Window._Scope, Handle.InputBegan, function(Input: InputObject): ()
            if not _IsPointer(Input) or (not bMini and (Window.bMaximized or not Window.bVisible)) then
                return
            end
            Window:ClosePopup()
            local Start = Input.Position
            local Original = Target.Position
            local bMoved = false
            Window:_BeginDrag(
                Input,
                --[[
                    超過移動門檻後依指標位移更新位置，並限制在螢幕內。

                    @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
                ]]
                function(Position): ()
                    local Delta = Position - Start
                    if math.abs(Delta.X) + math.abs(Delta.Y) > 5 then
                        bMoved = true
                    end
                    if bMoved then
                        Target.Position =
                            UDim2.fromOffset(Original.X.Offset + Delta.X, Original.Y.Offset + Delta.Y)
                        Window:_Layout()
                    end
                end,
                --[[
                    結束移動；最小化圖示未移動時恢復視窗，再排程保存位置。
                ]]
                function(): ()
                    if bMini and not bMoved then
                        Window:Restore()
                    end
                    Window:_Dirty()
                end,
                Handle
            )
        end)
    end
    _AttachMove(Dragger, Window.Main, false)
    _AttachMove(Window.Brand, Window.Main, false)
    _AttachMove(Window.Mini, Window.Mini, true)

    --[[
        將有效的滑鼠移動或同一觸控輸入送往目前拖曳回呼。

        @param Input 開始或更新互動的 Rbx InputObject。
    ]]
    _Connect(Window._Scope, UserInputService.InputChanged, function(Input: InputObject): ()
        local Drag = Window._Drag
        if
            Drag
            and (
                Input == Drag._Input
                or (
                    Drag._Input.UserInputType == Enum.UserInputType.MouseButton1
                    and Input.UserInputType == Enum.UserInputType.MouseMovement
                )
            )
        then
            Drag._Update(Input.Position)
        end
        if Input.UserInputType == Enum.UserInputType.MouseMovement then
            Window:_UpdateNavigationHover()
        end
    end)

    --[[
        在指標或快捷鍵釋放時結束拖曳與持續按住狀態。

        @param Input 開始或更新互動的 Rbx InputObject。
    ]]
    _Connect(Window._Scope, UserInputService.InputEnded, function(Input: InputObject): ()
        local Drag = Window._Drag
        if
            Drag
            and (
                Input == Drag._Input
                or (
                    Drag._Input.UserInputType == Enum.UserInputType.MouseButton1
                    and Input.UserInputType == Enum.UserInputType.MouseButton1
                )
            )
        then
            Window:_FinishDrag()
        end
        for Control in pairs(Window._Keybinds) do
            if Control._bHeld and Input.KeyCode == Control.Value then
                Control._bHeld = false
                _InvokeCallback(Control, Control.Callback, false)
            end
        end
    end)

    --[[
        處理鍵位擷取、Escape、視窗切換鍵及使用者快捷鍵；輸入框焦點期間略過快捷鍵。

        @param Input 開始或更新互動的 Rbx InputObject。
        @param bProcessed true 表示平台已處理此輸入，普通快捷鍵應略過。
    ]]
    _Connect(Window._Scope, UserInputService.InputBegan, function(Input: InputObject, bProcessed: boolean): ()
        if Input.UserInputType ~= Enum.UserInputType.Keyboard then
            return
        end
        if Window._Capture then
            local Control = Window._Capture
            Window._Capture = nil
            if Input.KeyCode ~= Enum.KeyCode.Escape then
                Control:Set(Input.KeyCode)
            else
                Control:_Render()
            end
            return
        end
        if UserInputService:GetFocusedTextBox() then
            return
        end
        if Input.KeyCode == Enum.KeyCode.Escape and Window._Popup then
            Window:ClosePopup()
            return
        end
        if bProcessed then
            return
        end
        if Input.KeyCode == Window.ToggleKey then
            Window:Toggle()
            return
        end
        for Control in pairs(Window._Keybinds) do
            if
                not Window.bLocked
                and Control.bEnabled
                and not Control.bDestroyed
                and Input.KeyCode == Control.Value
                and (Window.bVisible or Control.bGlobal)
            then
                if Control.bHold then
                    if not Control._bHeld then
                        Control._bHeld = true
                        _InvokeCallback(Control, Control.Callback, true)
                    end
                else
                    _InvokeCallback(Control, Control.Callback, true)
                end
            end
        end
    end)

    --[[
        應用程式失去焦點時結束拖曳、按住的鍵與鍵位擷取。
    ]]
    _Connect(Window._Scope, UserInputService.WindowFocusReleased, function(): ()
        Window._bNavigationFocused = false
        Window:SetNavigationExpanded(false)
        Window:_FinishDrag()
        Window:_ReleaseKeys()
        Window:_CancelCapture()
    end)
    _Connect(Window._Scope, UserInputService.WindowFocused, function(): ()
        Window._bNavigationFocused = true
        Window:_UpdateNavigationHover()
    end)

    --[[
        螢幕尺寸改變時關閉浮層、結束拖曳並重新佈局。
    ]]
    _Connect(Window._Scope, Window.Surface:GetPropertyChangedSignal("AbsoluteSize"), function(): ()
        Window:ClosePopup()
        Window:_FinishDrag()
        Window:_Layout()
        Window:_UpdateNavigationHover()
    end)

    --[[
        搜尋文字變更時重新篩選目前分頁。
    ]]
    _Connect(Window._Scope, Window.Search:GetPropertyChangedSignal("Text"), function(): ()
        if Window.ActiveTab then
            Window.ActiveTab:_Filter(Window.Search.Text)
        end
    end)
    if _IsFinite(UI.X) and _IsFinite(UI.Y) then
        Window.Main.Position = UDim2.fromOffset(UI.X, UI.Y)
        Window._bPositioned = true
    end
    if _IsFinite(UI.MiniX) and _IsFinite(UI.MiniY) then
        Window.Mini.Position = UDim2.fromOffset(UI.MiniX, UI.MiniY)
    end
    Window:_InstallResizeHandles()
    Window:_Layout()
    Window._bLoading = false
    Registry[Id] = Window
    OwnerLibrary.Windows[Id] = Window
    OwnerLibrary._Last = Window
    Window:_InstallCursor()
    if Settings.bKeySystem then
        Window:_KeyGate(Settings.KeySettings or {}, Saved.KeyAccepted == true)
    end
    Window:_UpdateNavigationHover()
    return Window
end

--[[
    按名稱、索引或分頁物件選取主分頁，並更新導覽樣式與搜尋。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Id 分頁名稱、1 起算索引，或主分頁實例。
    @return true 表示已選取目標；false 表示找不到目標分頁。
]]
function CWindow.SelectTab(self: CWindowType, Id): boolean
    local Selected = type(Id) == "number" and self.Tabs[Id] or nil
    if type(Id) == "table" then
        Selected = Id
    end
    if type(Id) == "string" then
        for _, Tab in ipairs(self.Tabs) do
            if Tab.Name == Id then
                Selected = Tab
                break
            end
        end
    end
    if not Selected then
        return false
    end
    self:ClosePopup()
    self:_CancelCapture()
    self:_FinishDrag()
    self.ActiveTab = Selected
    self:_ResetFeedback()
    self.PageTitle.Text = Selected.Name
    for _, Tab in ipairs(self.Tabs) do
        Tab.Frame.Visible = Tab == Selected
        Tab.NavButton.BackgroundTransparency = Tab == Selected and 0 or 1
        _BindTheme(self, Tab.NavLabel, "TextColor3", Tab == Selected and "Accent" or "Muted")
        for _, Object in ipairs(Tab.NavIcon:GetDescendants()) do
            local Bindings = self._Bindings[Object]
            if Bindings then
                for Property in pairs(Bindings) do
                    _BindTheme(self, Object, Property, Tab == Selected and "Accent" or "Muted")
                end
            end
        end
    end
    Selected:_Filter(self.Search.Text)
    self:_Dirty()
    return true
end

--[[
    建立左側導覽項目及子分頁容器；重複名稱會拋出錯誤。

    @param OwnerWindow 新分頁所屬的視窗。
    @param Name 顯示名稱、圖示名稱或查找鍵，依此函數用途解讀。
    @param IconName 內建圖示名或 asset ID；Name 已是選項表時忽略此參數。
    @param Subtabs 子分頁名稱陣列；省略或空陣列時建立一般頁面。
    @return 已加入視窗的主分頁實例。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Tab = Window:CreateTab("設定", "settings", { "一般", "外觀" })
    Tab:SelectSubtab("外觀") -- 切換到第二個子分頁
    ```
]]
function CTab.new(
    OwnerWindow: CWindowType,
    Name: string | TabOptions?,
    IconName: string | number?,
    Subtabs: { string }?
): CTabType
    local Settings = type(Name) == "table" and Name or { Name = Name, Icon = IconName, Subtabs = Subtabs }
    local Tab = setmetatable({
        Window = OwnerWindow,
        Name = tostring(Settings.Name or "分頁"),
        Pages = {},
        Sections = {},
        _Scope = _CreateScope(),
    }, CTab)
    for _, Existing in ipairs(OwnerWindow.Tabs) do
        assert(Existing.Name ~= Tab.Name, "BjzUi duplicate tab name: " .. Tab.Name)
    end
    Tab.Frame = _Frame(OwnerWindow.Content, UDim2.fromScale(1, 1))
    Tab.Frame.Visible = false
    Tab.NavButton = _Button(OwnerWindow, OwnerWindow.Nav, "", UDim2.new(1, 0, 0, 42))
    Tab.NavButton.LayoutOrder = #OwnerWindow.Tabs + 1
    Tab.NavButton.BackgroundTransparency = 1
    _SetupFeedback(OwnerWindow, Tab.NavButton, Tab._Scope, function(): boolean
        return OwnerWindow.bVisible and not OwnerWindow.bLocked
    end)

    --[[
        將側欄底色與強調色混合，產生已選導覽項目的背景色。

        @param Theme 視窗目前的主題色表。
        @return 依目前主題計算的導覽背景色。
    ]]
    _BindTheme(OwnerWindow, Tab.NavButton, "BackgroundColor3", function(Theme: ThemeColors)
        return Theme.Sidebar:Lerp(Theme.Accent, 0.23)
    end)
    for _, Item in ipairs(Tab.NavButton:GetChildren()) do
        if Item:IsA("UIStroke") then
            Item.Enabled = false
        end
    end
    Tab.NavIcon =
        _Icon(OwnerWindow, Tab.NavButton, Settings.Icon or "grid", UDim2.fromOffset(7, 9), 24, "Muted")
    Tab.NavIcon.ZIndex = 2
    Tab.NavLabel = _Label(
        OwnerWindow,
        Tab.NavButton,
        Tab.Name,
        UDim2.new(1, -48, 1, 0),
        UDim2.fromOffset(44, 0),
        13,
        "Muted"
    )
    local Names = type(Settings.Subtabs) == "table" and Settings.Subtabs or {}
    local bHasTabs = #Names > 0
    if not bHasTabs then
        Names = { "一般" }
    end
    local Top = bHasTabs and 46 or 0
    if bHasTabs then
        Tab.SubBar = _ScrollingFrame(OwnerWindow, Tab.Frame, UDim2.new(1, 0, 0, 40))
        Tab.SubBar.AutomaticCanvasSize = Enum.AutomaticSize.X
        Tab.SubBar.ScrollingDirection = Enum.ScrollingDirection.X
        Tab.SubBar.ScrollBarThickness = 0
        _Padding(Tab.SubBar, 4)
        local Layout = _ListLayout(Tab.SubBar, 6)
        Layout.FillDirection = Enum.FillDirection.Horizontal
        Layout.VerticalAlignment = Enum.VerticalAlignment.Center
    end
    for Index, SubtabName in ipairs(Names) do
        for _, Page in ipairs(Tab.Pages) do
            assert(Page.Name ~= tostring(SubtabName), "BjzUi duplicate subtab")
        end
        local Page = { Name = tostring(SubtabName), Sections = {} }
        Page.Frame =
            _ScrollingFrame(OwnerWindow, Tab.Frame, UDim2.new(1, 0, 1, -Top), UDim2.fromOffset(0, Top))
        Page.Frame.Visible = false
        _Padding(Page.Frame, 2)
        _ListLayout(Page.Frame, 12)
        Page.Full = _Frame(Page.Frame, UDim2.new(1, -5, 0, 0))
        Page.Full.AutomaticSize = Enum.AutomaticSize.Y
        Page.Full.LayoutOrder = 1
        _ListLayout(Page.Full, 12)
        Page.Columns = _Frame(Page.Frame, UDim2.new(1, -5, 0, 0))
        Page.Columns.AutomaticSize = Enum.AutomaticSize.Y
        Page.Columns.LayoutOrder = 2
        Page.Left = _Frame(Page.Columns, UDim2.new(0.5, -6, 0, 0))
        Page.Left.AutomaticSize = Enum.AutomaticSize.Y
        _ListLayout(Page.Left, 12)
        Page.Right = _Frame(Page.Columns, UDim2.new(0.5, -6, 0, 0), UDim2.new(0.5, 6, 0, 0))
        Page.Right.AutomaticSize = Enum.AutomaticSize.Y
        _ListLayout(Page.Right, 12)
        if bHasTabs then
            Page.Button = _Button(
                OwnerWindow,
                Tab.SubBar,
                Page.Name,
                UDim2.fromOffset(math.max(90, #Page.Name * 7 + 20), 30)
            )
            Page.Button.LayoutOrder = Index
            _SetupFeedback(OwnerWindow, Page.Button, Tab._Scope, function(): boolean
                return OwnerWindow.bVisible and not OwnerWindow.bLocked
            end)

            --[[
                按下子分頁按鈕時選取對應子分頁。
            ]]
            _Connect(Tab._Scope, Page.Button.Activated, function(): ()
                Tab:SelectSubtab(Index)
            end)
        end
        Tab.Pages[#Tab.Pages + 1] = Page
    end
    OwnerWindow.Tabs[#OwnerWindow.Tabs + 1] = Tab
    Tab:SelectSubtab(
        type(OwnerWindow._SavedUI.Subtabs) == "table" and OwnerWindow._SavedUI.Subtabs[Tab.Name] or 1
    )
    if not Tab.ActivePage then
        Tab:SelectSubtab(1)
    end

    --[[
        按下導覽項目時選取對應主分頁。
    ]]
    _Connect(Tab._Scope, Tab.NavButton.Activated, function(): ()
        OwnerWindow:SelectTab(Tab)
    end)
    if not OwnerWindow.ActiveTab or OwnerWindow._SavedUI.Tab == Tab.Name then
        OwnerWindow:SelectTab(Tab)
    end
    OwnerWindow:_Layout(true)
    return Tab
end

--[[
    按名稱或索引選取子分頁，結束原分頁互動並更新保存狀態。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Id 分頁名稱、1 起算索引，或主分頁實例。
    @return true 表示已選取目標；false 表示找不到子分頁。
]]
function CTab.SelectSubtab(self: CTabType, Id): boolean
    local Page = type(Id) == "number" and self.Pages[Id] or nil
    if type(Id) == "string" then
        for _, Item in ipairs(self.Pages) do
            if Item.Name == Id then
                Page = Item
                break
            end
        end
    end
    if not Page then
        return false
    end
    self.Window:ClosePopup()
    self.Window:_CancelCapture()
    self.Window:_FinishDrag()
    self.ActivePage = Page
    self.Window:_ResetFeedback(self.Frame)
    for _, Item in ipairs(self.Pages) do
        Item.Frame.Visible = Item == Page
        if Item.Button then
            _BindTheme(self.Window, Item.Button, "BackgroundColor3", Item == Page and "Accent" or "Input")
            _BindTheme(self.Window, Item.Button, "TextColor3", Item == Page and "AccentText" or "Muted")
        end
    end
    self:_Filter(self.Window.Search.Text)
    self.Window:_Dirty()
    return true
end

--[[
    以區塊名及控制項名篩選目前內容，且保留控制項主動隱藏的設定。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Text 要顯示或搜尋的文字；接受 tostring 可轉換的值。
]]
function CTab._Filter(self: CTabType, Text): ()
    local Query = string.lower(tostring(Text or ""))
    for _, Sec in ipairs(self.Sections) do
        local bMatches = string.find(string.lower(Sec.Name), Query, 1, true) ~= nil
        local Count = 0
        for _, Control in ipairs(Sec.Controls) do
            if not Control.bDestroyed then
                local bShow = Control.bVisible
                    and (
                        Query == ""
                        or bMatches
                        or string.find(string.lower(Control.Name), Query, 1, true) ~= nil
                    )
                Control.Frame.Visible = bShow
                if bShow then
                    Count = Count + 1
                end
            end
        end
        Sec.Frame.Visible = Sec.bVisible and (Query == "" or Count > 0)
    end
end

--[[
    在指定子分頁與欄位建立區塊；設定 Height 時使用可捲動的固定高度容器。

    @param OwnerTab 新區塊所屬的分頁。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 已加入分頁的區塊實例。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Tab = Window:CreateTab("一般", "grid")
    local Section = Tab:CreateSection({ Name = "列表", Side = "right", Height = 190 })
    Section:CreateCheckbox({ Name = "啟用", bCurrentValue = true })
    ```
]]
function CSection.new(OwnerTab: CTabType, Options: SectionOptions | string?): CSectionType
    local Settings = _Options(Options)
    local Window = OwnerTab.Window
    local Page = OwnerTab.ActivePage
    if Settings.Subtab ~= nil then
        Page = type(Settings.Subtab) == "number" and OwnerTab.Pages[Settings.Subtab] or nil
        if type(Settings.Subtab) == "string" then
            for _, Item in ipairs(OwnerTab.Pages) do
                if Item.Name == Settings.Subtab then
                    Page = Item
                end
            end
        end
        assert(Page, "BjzUi unknown Subtab: " .. tostring(Settings.Subtab))
    end
    local Side = string.lower(tostring(Settings.Side or "left"))
    assert(Side == "left" or Side == "right" or Side == "full", "Side must be left, right, or full")
    local Section = setmetatable({
        Window = Window,
        Tab = OwnerTab,
        Page = Page,
        Side = Side,
        Name = tostring(Settings.Name or "設定"),
        Controls = {},
        bVisible = true,
        _Scope = _CreateScope(),
    }, CSection)
    local Parent = Side == "full" and Page.Full
        or (Side == "right" and not Window.bSingleColumn and Page.Right or Page.Left)
    Section.Frame = _Frame(Parent, UDim2.new(1, 0, 0, 0))
    Section.Frame.Name = Section.Name
    Section.Frame.BackgroundTransparency = 0
    Section.Frame.LayoutOrder = #Page.Sections + 1
    _BindTheme(Window, Section.Frame, "BackgroundColor3", "Card")
    _Corner(Section.Frame, 6)
    _Stroke(Window, Section.Frame)
    Section.Title =
        _Label(Window, Section.Frame, Section.Name, UDim2.new(1, -28, 0, 24), UDim2.fromOffset(14, 10), 14)
    Section.Title.Font = Enum.Font.GothamMedium
    local Fixed = _IsFinite(Settings.Height) and math.max(86, Settings.Height) or nil
    Section.Body = Fixed
            and _ScrollingFrame(Window, Section.Frame, UDim2.new(1, -24, 1, -50), UDim2.fromOffset(12, 40))
        or _Frame(Section.Frame, UDim2.new(1, -28, 0, 0), UDim2.fromOffset(14, 42))
    if Fixed then
        Section.Frame.Size = UDim2.new(1, 0, 0, Fixed)
    else
        Section.Frame.AutomaticSize = Enum.AutomaticSize.Y
        Section.Body.AutomaticSize = Enum.AutomaticSize.Y
        _CreateInstance("UIPadding", Section.Frame, { PaddingBottom = UDim.new(0, 12) })
    end
    _ListLayout(Section.Body, 10)
    if Fixed then
        _CreateInstance(
            "UIPadding",
            Section.Body,
            { PaddingRight = UDim.new(0, 5), PaddingBottom = UDim.new(0, 4) }
        )
    end
    Page.Sections[#Page.Sections + 1] = Section
    OwnerTab.Sections[#OwnerTab.Sections + 1] = Section
    return Section
end

--[[
    更新區塊顯示設定並重新套用分頁搜尋條件。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param bEnabled true 啟用此行為；false 停用。
    @return 目前實例，可繼續串接操作。
]]
function CSection.SetVisible(self: CSectionType, bEnabled: boolean): CSectionType
    self.bVisible = bEnabled == true
    self.Tab:_Filter(self.Window.Search.Text)
    return self
end

--[[
    由後向前銷毀區塊內控制項，再移除區塊的連線與容器。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CSection.Destroy(self: CSectionType): ()
    for Index = #self.Controls, 1, -1 do
        self.Controls[Index]:Destroy()
    end
    _CleanScope(self._Scope)
    self.bVisible = false
    _Dispose(self.Window, self.Frame)
    _RemoveItem(self.Page.Sections, self)
    _RemoveItem(self.Tab.Sections, self)
end

--[[
    建立控制項共同狀態、框架與 Flag 註冊；重複 Flag 或已銷毀視窗會拋出錯誤。

    @param OwnerSection 新控制項所屬的區塊。
    @param Settings 已正規化的設定表或允許的名稱簡寫。
    @param Kind 控制項種類或按鈕樣式，用於建立對應外觀。
    @param Height 邏輯高度，單位為未縮放像素。
    @return 尚待具體工廠安裝行為的控制項基底。

    使用範例：
    前提：在本模組內，Section 已建立。
    ```lua
    local Control = CControl.new(Section, { Name = "顯示" }, "Label", 26)
    Control:Destroy() -- 基底尚未安裝標籤顯示行為；外部請使用 CreateLabel
    ```
]]
function CControl.new(
    OwnerSection: CSectionType,
    Settings: BaseControlOptions | string,
    Kind,
    Height: number?
): CControlType
    Settings = _Options(Settings)
    local Window = OwnerSection.Window
    assert(not Window.bDestroyed, "BjzUi window is destroyed")
    if Settings.Flag then
        assert(not Window.Flags[tostring(Settings.Flag)], "BjzUi duplicate Flag: " .. tostring(Settings.Flag))
    end
    local Control = setmetatable({
        Window = Window,
        Section = OwnerSection,
        Kind = Kind,
        Name = tostring(Settings.Name or Kind),
        Callback = Settings.Callback,
        bEnabled = Settings.bEnabled ~= false and Settings.bDisabled ~= true,
        bVisible = Settings.bVisible ~= false,
        bSave = Settings.bSave ~= false,
        Flag = Settings.Flag and tostring(Settings.Flag) or nil,
        bDestroyed = false,
        _Scope = _CreateScope(),
        _Interactive = {},
    }, CControl)
    Control.Frame = _Frame(OwnerSection.Body, UDim2.new(1, 0, 0, Height or 34))
    Control.Frame.Name = Control.Name
    Control.Frame.LayoutOrder = #OwnerSection.Controls + 1
    Control.Frame.Visible = Control.bVisible
    OwnerSection.Controls[#OwnerSection.Controls + 1] = Control
    Window._Controls[#Window._Controls + 1] = Control
    if Control.Flag then
        Window.Flags[Control.Flag] = Control
        Library.Flags[Control.Flag] = Control
    end
    return Control
end

--[[
    判斷控制項、視窗與本機 Key 門鎖是否允許使用者互動。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return true 表示可接受互動；false 表示已銷毀、停用、隱藏或受門鎖阻擋。
]]
function CControl._CanUse(self: CControlType): boolean
    return not self.bDestroyed
        and self.bEnabled
        and self.bVisible
        and self.Window.bVisible
        and not self.Window.bLocked
end

--[[
    取得控制項值；資料表值回傳淺複本。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前值；資料表為淺複本，未設定時可為 nil。
]]
function CControl.Get(self: CControlType): ControlValue?
    return typeof(self.Value) == "table" and _CopyTable(self.Value) or self.Value
end

--[[
    取得可保存的控制項值；特殊元件會覆寫此方法。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 可保存的目前值，未設定時可為 nil。
]]
function CControl._Serialize(self: CControlType): ControlValue?
    return self:Get()
end

--[[
    將儲存資料交回控制項的 Set 流程。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Value 待檢查或套用的值，依此控制項種類解讀。
    @param bSilent true 時不觸發值變更回呼；省略或 false 時依變更結果發送回呼。
    @return 目前控制項實例，可繼續串接操作。
]]
function CControl._Restore(self: CControlType, Value, bSilent: boolean?): CControlType
    return self:Set(Value, bSilent)
end

--[[
    提交正規化後的值；實際變更時才排程儲存與回呼。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Value 待檢查或套用的值，依此控制項種類解讀。
    @param bSilent true 時不觸發值變更回呼；省略或 false 時依變更結果發送回呼。
    @return 目前控制項實例，可繼續串接操作。
]]
function CControl._Commit(self: CControlType, Value, bSilent: boolean?): CControlType
    if self.bDestroyed then
        return self
    end
    local bChanged = not _ValuesEqual(self.Value, Value)
    self.Value = typeof(Value) == "table" and _CopyTable(Value) or Value
    if self._Render then
        self:_Render()
    end
    if bChanged then
        self.Window:_Dirty()
        if not bSilent then
            self:_Emit()
        end
    end
    return self
end

--[[
    非同步發出目前控制項值的變更回呼。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CControl._Emit(self: CControlType): ()
    _InvokeCallback(self, self.Callback, self:Get())
end

--[[
    正規化輸入並提交；無效值保持目前狀態。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Value 待檢查或套用的值，依此控制項種類解讀。
    @param bSilent true 時不觸發值變更回呼；省略或 false 時依變更結果發送回呼。
    @return 目前控制項實例，可繼續串接操作。
]]
function CControl.Set(self: CControlType, Value, bSilent: boolean?): CControlType
    if self._Normalize then
        local bValid
        Value, bValid = self._Normalize(Value)
        if bValid == false then
            return self
        end
    end
    return self:_Commit(Value, bSilent)
end

--[[
    設定初始值，再恢復已保存的 Flag；只有 bEmitInitial 才發出初始回呼。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Value 待檢查或套用的值，依此控制項種類解讀。
    @param Settings 已正規化的設定表或允許的名稱簡寫。
    @return 目前控制項實例，可繼續串接操作。
]]
function CControl._Initial(self: CControlType, Value, Settings): CControlType
    self:Set(Value, true)
    if self.bSave and self.Flag and self.Window._SavedFlags[self.Flag] ~= nil then
        self:_Restore(self.Window._SavedFlags[self.Flag], true)
    end
    if Settings.bEmitInitial then
        self:_Emit()
    end
    return self
end

--[[
    設定控制項啟用狀態；停用時關閉相關浮層、拖曳、擷取與按住的鍵。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param bEnabled true 啟用此行為；false 停用。
    @return 目前控制項實例，可繼續串接操作。
]]
function CControl.SetEnabled(self: CControlType, bEnabled: boolean): CControlType
    self.bEnabled = bEnabled == true
    if not self.bEnabled then
        if self.Window._Popup and self.Window._Popup.Owner == self then
            self.Window:ClosePopup()
        end
        if self.Window._Capture == self then
            self.Window:_CancelCapture()
        end
        if
            self.Window._Drag
            and self.Window._Drag._Owner
            and self.Window._Drag._Owner:IsDescendantOf(self.Frame)
        then
            self.Window:_FinishDrag()
        end
        if self._bHeld then
            self._bHeld = false
            _InvokeCallback(self, self.Callback, false)
        end
    end
    if self.Title then
        self.Title.TextTransparency = self.bEnabled and 0 or 0.55
    end
    for _, Object in ipairs(self._Interactive) do
        if Object:IsA("TextBox") then
            Object.TextEditable = self.bEnabled
        end
        if Object:IsA("TextButton") or Object:IsA("TextBox") then
            Object.TextTransparency = self.bEnabled and 0 or 0.55
        end
    end
    if self._Render then
        self:_Render()
    end
    self.Window:_ResetFeedback(self.Frame)
    return self
end

--[[
    設定控制項顯示狀態並重新篩選分頁；隱藏時結束相關浮層與按鍵狀態。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param bEnabled true 啟用此行為；false 停用。
    @return 目前控制項實例，可繼續串接操作。
]]
function CControl.SetVisible(self: CControlType, bEnabled: boolean): CControlType
    self.bVisible = bEnabled == true
    if not self.bVisible then
        self.Window:_ResetFeedback(self.Frame)
    end
    if not self.bVisible and self.Window._Popup and self.Window._Popup.Owner == self then
        self.Window:ClosePopup()
    end
    if not self.bVisible and self.Window._Capture == self then
        self.Window:_CancelCapture()
    end
    if not self.bVisible and self._bHeld then
        self._bHeld = false
        _InvokeCallback(self, self.Callback, false)
    end
    self.Section.Tab:_Filter(self.Window.Search.Text)
    return self
end

--[[
    替換使用者回呼；傳入 nil 可移除回呼。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Callback 要執行的回呼；未提供函數時略過。
    @return 目前控制項實例，可繼續串接操作。
]]
function CControl.SetCallback(self: CControlType, Callback): CControlType
    self.Callback = Callback
    return self
end

--[[
    更新控制項名稱與標籤，並重新套用搜尋。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Name 顯示名稱、圖示名稱或查找鍵，依此函數用途解讀。
    @return 目前控制項實例，可繼續串接操作。
]]
function CControl.SetName(self: CControlType, Name): CControlType
    self.Name = tostring(Name)
    if self.Title then
        self.Title.Text = self.Name
    end
    self.Section.Tab:_Filter(self.Window.Search.Text)
    return self
end

--[[
    冪等地銷毀控制項、清除互動與 Flag 註冊，並從區塊移除。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
]]
function CControl.Destroy(self: CControlType): ()
    if self.bDestroyed then
        return
    end
    local Window = self.Window
    if Window._Popup and Window._Popup.Owner == self then
        Window:ClosePopup()
    end
    if Window._Capture == self then
        Window:_CancelCapture()
    end
    if Window._Drag and Window._Drag._Owner and Window._Drag._Owner:IsDescendantOf(self.Frame) then
        Window:_FinishDrag()
    end
    if self._bHeld then
        self._bHeld = false
        _InvokeCallback(self, self.Callback, false)
    end
    self.bDestroyed = true
    _CleanScope(self._Scope)
    _Dispose(Window, self.Frame)
    Window._Keybinds[self] = nil
    _RemoveItem(Window._Controls, self)
    _RemoveItem(self.Section.Controls, self)
    if self.Flag then
        if Window.Flags[self.Flag] == self then
            Window.Flags[self.Flag] = nil
        end
        if Library.Flags[self.Flag] == self then
            Library.Flags[self.Flag] = nil
        end
    end
end

--[[
    建立控制項標題與可選描述，預留右側互動元件寬度。

    @param Control 要建立顯示或處理互動的控制項。
    @param Settings 已正規化的設定表或允許的名稱簡寫。
    @param RightWidth 標題右側保留寬度，單位為像素；nil 視為 0。
]]
local function _Caption(Control: CControlType, Settings, RightWidth: number?): ()
    Control.Title =
        _Label(Control.Window, Control.Frame, Control.Name, UDim2.new(1, -(RightWidth or 0), 0, 22), nil, 13)
    if Settings.Description then
        Control.Description = _Label(
            Control.Window,
            Control.Frame,
            tostring(Settings.Description),
            UDim2.new(1, -(RightWidth or 0), 0, 18),
            UDim2.fromOffset(0, 23),
            11,
            "Muted"
        )
    end
end

--[[
    將輸入框加入互動清單，並提供一致的懸停與焦點回饋。

    @param Control 要建立顯示或處理互動的控制項。
    @param Object 要套用屬性或檢查範圍的 Rbx Instance。
    @param Border 輸入框使用的 UIStroke。
]]
local function _SetupText(Control: CControlType, Object, Border): ()
    Control._Interactive[#Control._Interactive + 1] = Object
    _BindTheme(Control.Window, Border, "Color", "Border")
    _SetupControlFeedback(Control, Object)
end

--[[
    建立一般、次要或外框按鈕；停用時保持灰色底色。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateButton(self: CSectionType, Options: ButtonOptions | string?): CButtonType
    local Settings = _Options(Options)
    local Control = self:_Control(Settings, "Button", 36)
    local Window = self.Window
    local Kind = Settings.Style or "primary"
    Control.Button = _Button(Window, Control.Frame, Control.Name, UDim2.new(1, 0, 1, 0), nil, Kind)
    Control.Stroke = Control.Button.UIStroke
    Control._Interactive = { Control.Button }
    _SetupControlFeedback(Control, Control.Button)

    --[[
        依按鈕樣式與啟用狀態重設顏色綁定，取消可能覆蓋停用樣式的 Tween。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CButtonType): ()
        -- Preserve a neutral disabled fill even while SetAccent() refreshes all bindings.

        --[[
            計算按鈕背景色；停用狀態優先使用固定灰色主題值。

            @param Theme 視窗目前的主題色表。
            @return 依樣式與啟用狀態計算的按鈕背景色。
        ]]
        _BindTheme(Window, self.Button, "BackgroundColor3", function(Theme: ThemeColors)
            if not self.bEnabled then
                return Theme.Disabled
            end
            return Kind == "primary" and Theme.Accent or Theme.Input
        end)

        --[[
            計算按鈕文字色，區分停用、外框與一般樣式。

            @param Theme 視窗目前的主題色表。
            @return 依樣式與啟用狀態計算的按鈕文字色。
        ]]
        _BindTheme(Window, self.Button, "TextColor3", function(Theme: ThemeColors)
            if not self.bEnabled then
                return Theme.DisabledText
            end
            if Kind == "outline" then
                return Theme.Accent
            end
            return Kind == "primary" and Theme.AccentText or Theme.Text
        end)
        _BindTheme(
            Window,
            self.Stroke,
            "Color",
            function(Theme: ThemeColors): Color3
                if not self.bEnabled then
                    return Theme.Disabled
                end
                return (Kind == "primary" or Kind == "outline") and Theme.Accent or Theme.Border
            end
        )
        if Window._Tweens[self.Button] then
            Window._Tweens[self.Button]:Cancel()
            Window._Tweens[self.Button] = nil
        end
        self.Button.BackgroundTransparency = self.bEnabled and Kind == "outline" and 1 or 0
        self.Button.TextTransparency = 0
    end

    --[[
        在控制項可互動時非同步執行按鈕回呼。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前控制項實例，可繼續串接操作。
    ]]
    function Control.Fire(self: CButtonType): CButtonType
        if self:_CanUse() then
            _InvokeCallback(self, self.Callback)
        end
        return self
    end

    --[[
        更新按鈕名稱及按鈕顯示文字。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 目前控制項實例，可繼續串接操作。
    ]]
    function Control.Set(self: CButtonType, Value): CButtonType
        self.Name = tostring(Value)
        self.Button.Text = self.Name
        return self
    end

    --[[
        取得按鈕目前的文字。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前按鈕文字。
    ]]
    function Control.Get(self: CButtonType): string
        return self.Name
    end

    --[[
        將按鈕啟動事件轉交 Fire。
    ]]
    _Connect(Control._Scope, Control.Button.Activated, function(): ()
        Control:Fire()
    end)

    --[[
        滑鼠進入可用按鈕時播放短暫懸停效果。
    ]]
    _Connect(Control._Scope, Control.Button.MouseEnter, function(): ()
        if Control:_CanUse() then
            Window:_Tween(Control.Button, { BackgroundTransparency = Kind == "outline" and 0.7 or 0.15 })
        end
    end)

    --[[
        滑鼠離開時恢復背景透明度；停用按鈕重新套用停用樣式。
    ]]
    _Connect(Control._Scope, Control.Button.MouseLeave, function(): ()
        if Control.bEnabled then
            Window:_Tween(Control.Button, { BackgroundTransparency = Kind == "outline" and 1 or 0 })
        else
            Control:_Render()
        end
    end)
    Control.bSave = false
    Control:SetEnabled(Control.bEnabled)
    return Control
end

--[[
    建立共用的布林控制項，依 bCheckbox 選擇勾選框或滑動開關外觀。

    @param Section 新控制項所屬的區塊。
    @param Options 布林控制項選項；初始狀態使用 bCurrentValue。
    @param bCheckbox true 建立勾選框；false 建立滑動開關。
    @return 目前控制項實例，可繼續串接操作。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Tab = Window:CreateTab("一般", "grid")
    local Section = Tab:CreateSection({ Name = "設定", Side = "left" })
    local Toggle = Section:CreateToggle({ Name = "啟用", bCurrentValue = true, Callback = print })
    Toggle:Set(false, true) -- 更新顯示但不輸出回呼
    ```
]]
local function _CreateBoolean(
    Section: CSectionType,
    Options: BooleanOptions | string?,
    bCheckbox: boolean
): CValueControlType<boolean>
    local Settings = _Options(Options)
    local Control =
        Section:_Control(Settings, bCheckbox and "Checkbox" or "Toggle", Settings.Description and 46 or 32)
    local Window = Section.Window
    _Caption(Control, Settings, 62)
    Control.Switch = _Button(
        Window,
        Control.Frame,
        "",
        UDim2.fromOffset(bCheckbox and 24 or 44, 24),
        UDim2.new(1, bCheckbox and -26 or -46, 0, 3)
    )
    Control.Switch.UICorner.CornerRadius = UDim.new(1, 0)
    if bCheckbox then
        Control.Switch.UICorner.CornerRadius = UDim.new(0, 3)
        Control.CheckGroup = _CreateInstance("CanvasGroup",Control.Switch,{
            Name="Checkmark",BackgroundTransparency=1,BorderSizePixel=0,
            Size=UDim2.fromOffset(22,22),Position=UDim2.fromScale(0.5,0.5),AnchorPoint=Vector2.new(0.5,0.5),
            GroupTransparency=1,GroupColor3=Color3.new(1,1,1),ClipsDescendants=true,
            Active=false,Selectable=false,
        })
        Control.CheckScale = _CreateInstance("UIScale",Control.CheckGroup,{Scale=0.65})
        local CheckIcon = _Icon(Window,Control.CheckGroup,"Check",nil,20,"AccentText")
        CheckIcon.AnchorPoint, CheckIcon.Position = Vector2.new(0.5,0.5), UDim2.fromScale(0.5,0.5)
    else
        Control.Knob = _Frame(Control.Switch, UDim2.fromOffset(18, 18), UDim2.fromOffset(3, 3))
        Control.Knob.BackgroundTransparency = 0
        _BindTheme(Window, Control.Knob, "BackgroundColor3", "Text")
        _Corner(Control.Knob, 20)
    end
    Control._Interactive = { Control.Switch }
    local bHovering = false
    local function _RenderKnob(): ()
        if Control.Knob then
            local Extra = bHovering and 1 or 0
            Window:_Tween(Control.Knob, {
                Size = UDim2.fromOffset(18 + Extra * 2, 18 + Extra * 2),
                Position = UDim2.fromOffset((Control.Value and 23 or 3) - Extra, 3 - Extra),
            })
        end
    end
    _SetupControlFeedback(Control, Control.Switch, nil, nil, function(bActive: boolean): ()
        bHovering = bActive
        _RenderKnob()
    end)
    --[[
        只有明確的 true 會被正規化為開啟狀態。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return true 表示輸入恰為 true；其他輸入皆為 false。
    ]]
    Control._Normalize = function(Value): boolean
        return Value == true
    end

    --[[
        同步布林值、按鈕顏色及滑塊位置或勾選記號。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CValueControlType<boolean>): ()
        _BindTheme(Window, self.Switch, "BackgroundColor3", self.Value and "Accent" or "Hover")
        self.Switch.BackgroundTransparency = self.bEnabled and 0 or 0.45
        if self.Knob then
            _RenderKnob()
        else
            local Duration = self._bCheckboxInitialized and 0.14 or 0
            Window:_Tween(self.CheckGroup,{GroupTransparency=self.Value and (self.bEnabled and 0 or 0.55) or 1},Duration)
            Window:_Tween(self.CheckScale,{Scale=self.Value and 1 or 0.65},Duration)
            self._bCheckboxInitialized = true
        end
    end

    --[[
        使用者啟動布林控制項時切換目前值。
    ]]
    _Connect(Control._Scope, Control.Switch.Activated, function(): ()
        if Control:_CanUse() then
            Control:Set(not Control.Value)
        end
    end)
    Control:_Initial(Settings.bCurrentValue == true, Settings)
    Control:SetEnabled(Control.bEnabled)
    return Control
end

--[[
    建立滑動開關控制項。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Settings 開關選項；初始狀態使用 bCurrentValue。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateToggle(
    self: CSectionType,
    Settings: BooleanOptions | string?
): CValueControlType<boolean>
    return _CreateBoolean(self, Settings, false)
end

--[[
    建立勾選框控制項。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Settings 勾選框選項；初始狀態使用 bCurrentValue。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateCheckbox(
    self: CSectionType,
    Settings: BooleanOptions | string?
): CValueControlType<boolean>
    return _CreateBoolean(self, Settings, true)
end

--[[
    建立具有數值輸入、拖曳與步進量限制的滑桿。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Tab = Window:CreateTab("一般", "grid")
    local Section = Tab:CreateSection({ Name = "設定", Side = "left" })
    local Slider = Section:CreateSlider({ Name = "音量", Range = { 0, 100 }, Increment = 10 })
    Slider:Set(23)
    print(Slider:Get()) -- 20
    ```
]]
function CSection.CreateSlider(
    self: CSectionType,
    Options: SliderOptions | string?
): CValueControlType<number>
    local Settings = _Options(Options)
    local Extra = Settings.Description and 20 or 0
    local Control = self:_Control(Settings, "Slider", 66 + Extra)
    local Window = self.Window
    _Caption(Control, Settings, 100)
    local Range = Settings.Range or { 0, 100 }
    local Minimum, Maximum = _NumberOr(Range[1], 0), _NumberOr(Range[2], 100)
    if Minimum > Maximum then
        Minimum, Maximum = Maximum, Minimum
    end
    local Step = math.max(0.000001, _NumberOr(Settings.Increment, 1))
    local Suffix = tostring(Settings.Suffix or "")
    Control.Range = { Minimum, Maximum }
    Control.Increment = Step
    local InputBox, Border =
        _TextBox(Window, Control.Frame, "", UDim2.fromOffset(84, 28), UDim2.new(1, -84, 0, 0))
    InputBox.TextXAlignment = Enum.TextXAlignment.Right
    Control.Input = InputBox
    _SetupText(Control, InputBox, Border)
    local Hit = _Button(Window, Control.Frame, "", UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 34 + Extra))
    Hit.BackgroundTransparency = 1
    Hit.UIStroke.Enabled = false
    local Track = _Frame(Hit, UDim2.new(1, -12, 0, 6), UDim2.fromOffset(6, 11))
    Track.Name = "SliderTrack"
    Track.ZIndex = 1
    Track.BackgroundTransparency = 0
    _Corner(Track, 8)
    _BindTheme(Window, Track, "BackgroundColor3", "Hover")
    local Fill = _Frame(Track, UDim2.new(0, 0, 1, 0))
    Fill.ZIndex = 2
    Fill.BackgroundTransparency = 0
    _Corner(Fill, 8)
    _BindTheme(Window, Fill, "BackgroundColor3", "Accent")
    local Knob = _Frame(Track, UDim2.fromOffset(16, 16), UDim2.fromScale(0, 0.5))
    Knob.Name = "SliderHandle"
    Knob.ZIndex = 4
    Knob.AnchorPoint = Vector2.new(0.5, 0.5)
    Knob.BackgroundTransparency = 0
    _Corner(Knob, 20)
    _BindTheme(Window, Knob, "BackgroundColor3", "Text")
    Control.Track = Track
    _SetupControlFeedback(Control, Hit, nil, nil, function(bActive: boolean): ()
        local Size = bActive and 20 or 16
        Window:_Tween(Knob, { Size = UDim2.fromOffset(Size, Size) })
    end, { Target = Track, Inset = 1, ZIndex = 3 })

    --[[
        驗證並量化滑桿值，同時保留範圍上限的精確值。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 限制並量化後的數值；無效時為 nil。
        @return 無效輸入時為 false；成功時省略此值。
    ]]
    Control._Normalize = function(Value): (number?, boolean?)
        local Number = tonumber(Value)
        if not _IsFinite(Number) then
            return nil, false
        end
        Number = _Clamp(Number, Minimum, Maximum)
        if Number == Maximum then
            return Maximum
        end
        Number = _Clamp(Minimum + math.floor((Number - Minimum) / Step + 0.5) * Step, Minimum, Maximum)
        return tonumber(string.format("%.8f", Number))
    end

    --[[
        更新滑桿填色、圓點位置與帶後綴的數值文字。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CValueControlType<number>): ()
        local Ratio = Maximum == Minimum and 0 or (self.Value - Minimum) / (Maximum - Minimum)
        Fill.Size = UDim2.new(Ratio, 0, 1, 0)
        Knob.Position = UDim2.fromScale(Ratio, 0.5)
        InputBox.Text = tostring(self.Value or Minimum) .. (Suffix ~= "" and " " .. Suffix or "")
        Fill.BackgroundTransparency = self.bEnabled and 0 or 0.6
    end

    --[[
        可互動的滑桿收到有效指標輸入時開始拖曳。

        @param Input 開始或更新互動的 Rbx InputObject。
    ]]
    _Connect(Control._Scope, Hit.InputBegan, function(Input: InputObject): ()
        if not Control:_CanUse() or not _IsPointer(Input) then
            return
        end

        --[[
            將指標水平位置轉為滑桿範圍內的值。

            @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
        ]]
        Window:_BeginDrag(Input, function(Position): ()
            Control:Set(
                Minimum
                    + _Clamp(
                            (Position.X - Track.AbsolutePosition.X) / math.max(1, Track.AbsoluteSize.X),
                            0,
                            1
                        )
                        * (Maximum - Minimum)
            )
        end, nil, Hit)
    end)

    --[[
        輸入框失焦時解析前綴數值，再恢復正規化後的顯示文字。
    ]]
    _Connect(Control._Scope, InputBox.FocusLost, function(): ()
        if Control:_CanUse() then
            Control:Set(tonumber(InputBox.Text:match("^%s*([%+%-]?[%d%.]+)")))
        end
        Control:_Render()
    end)
    Control:_Initial(_NumberOr(Settings.CurrentValue, Minimum), Settings)
    Control:SetEnabled(Control.bEnabled)
    return Control
end

--[[
    建立文字輸入控制項，支援即時更新與提交後清空。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Tab = Window:CreateTab("一般", "grid")
    local Section = Tab:CreateSection({ Name = "設定", Side = "left" })
    local Input = Section:CreateInput({ Name = "名稱", bLive = true, Callback = print })
    Input:Set("範例", true) -- 靜默更新；使用者輸入才觸發回呼
    ```
]]
function CSection.CreateInput(self: CSectionType, Options: InputOptions | string?): CValueControlType<string>
    local Settings = _Options(Options)
    local Extra = Settings.Description and 20 or 0
    local Control = self:_Control(Settings, "Input", 62 + Extra)
    local Window = self.Window
    _Caption(Control, Settings)
    local InputBox, Border =
        _TextBox(Window, Control.Frame, "", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 26 + Extra))
    Control.Input = InputBox
    InputBox.PlaceholderText = tostring(Settings.PlaceholderText or "請輸入…")
    _SetupText(Control, InputBox, Border)

    --[[
        接受字串或數值並轉為字串，其餘輸入判定為無效。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 正規化後的字串；無效時為 nil。
        @return 無效輸入時為 false；成功時省略此值。
    ]]
    Control._Normalize = function(Value): (string?, boolean?)
        if type(Value) ~= "string" and type(Value) ~= "number" then
            return nil, false
        end
        return tostring(Value)
    end

    --[[
        只在內容不同時同步輸入框文字，避免額外觸發文字變更。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CValueControlType<string>): ()
        if InputBox.Text ~= self.Value then
            InputBox.Text = self.Value or ""
        end
    end

    --[[
        在可互動時提交輸入文字；依設定清空輸入框或恢復原值。
    ]]
    _Connect(Control._Scope, InputBox.FocusLost, function(): ()
        if Control:_CanUse() then
            Control:Set(InputBox.Text)
            if Settings.bRemoveTextAfterFocusLost then
                Control:Set("", true)
            end
        else
            Control:_Render()
        end
    end)
    if Settings.bLive then
        --[[
            輸入框持有焦點且可互動時發送即時文字變更。
        ]]
        _Connect(Control._Scope, InputBox:GetPropertyChangedSignal("Text"), function(): ()
            if Control:_CanUse() and InputBox:IsFocused() then
                Control:Set(InputBox.Text)
            end
        end)
    end
    Control:_Initial(Settings.CurrentValue or Settings.CurrentText or "", Settings)
    Control:SetEnabled(Control.bEnabled)
    return Control
end

--[[
    將簡寫選項轉成具名稱、值、停用狀態與索引的陣列；重複值或無效型別會拋出錯誤。

    @param Values 來源資料表；複製時可為 nil，選項處理時依陣列順序讀取。
    @return 維持來源順序的正規化選項陣列。
]]
local function _NormalizeOptions(Values): { NormalizedOption }
    local Result = {}
    local Seen = {}
    for Index, Item in ipairs(type(Values) == "table" and Values or {}) do
        local Entry = type(Item) == "table" and Item or { Name = tostring(Item), Value = Item }
        local Value = Entry.Value
        if Value == nil then
            Value = Entry.Name or tostring(Index)
        end
        assert(
            type(Value) == "string" or type(Value) == "number" or type(Value) == "boolean",
            "Dropdown Value must be string, number or boolean"
        )
        local Key = type(Value) .. ":" .. tostring(Value)
        assert(not Seen[Key], "Duplicate dropdown option: " .. tostring(Value))
        Seen[Key] = true
        Result[#Result + 1] = {
            Name = tostring(Entry.Name or Value),
            Value = Value,
            bDisabled = Entry.bDisabled == true,
            Index = Index,
        }
    end
    return Result
end

--[[
    建立可搜尋的單選或多選下拉欄，使用獨立浮層避免被區塊裁切。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Tab = Window:CreateTab("一般", "grid")
    local Section = Tab:CreateSection({ Name = "設定", Side = "left" })
    local Dropdown = Section:CreateDropdown({ Name = "分類", Options = { "A", "B" }, bMulti = true })
    Dropdown:Set({ "A", "B" })
    Dropdown:Refresh({ "B", "C" }, true, true) -- 保留 B，靜默移除已不存在的 A
    ```
]]
function CSection.CreateDropdown(self: CSectionType, Options: DropdownOptions | string?): CDropdownType
    local Settings = _Options(Options)
    local Extra = Settings.Description and 20 or 0
    local Control = self:_Control(Settings, "Dropdown", 62 + Extra)
    local Window = self.Window
    Control.Options = _NormalizeOptions(Settings.Options)
    Control.bMulti = Settings.bMulti == true
    _Caption(Control, Settings)
    Control.Button =
        _Button(Window, Control.Frame, "", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 26 + Extra))
    Control.Selection =
        _Label(Window, Control.Button, "", UDim2.new(1, -42, 1, 0), UDim2.fromOffset(10, 0), 13)
    Control.Arrow = _Chevron(Window, Control.Button, UDim2.new(1, -27, 0, 8))
    Control._Interactive = { Control.Button }
    _SetupControlFeedback(Control, Control.Button)

    --[[
        在目前下拉選項中尋找值完全相等的項目。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 相符的正規化選項；不存在時為 nil。
    ]]
    local function _FindOption(Value): NormalizedOption?
        for _, Item in ipairs(Control.Options) do
            if Item.Value == Value then
                return Item
            end
        end
    end

    --[[
        依單選或多選模式正規化選取值，剔除不存在或停用的選項。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 有效的單選值、多選陣列，或清空／無效時的 nil。
        @return 無效輸入時為 false；有效選取或清空時省略此值。
    ]]
    Control._Normalize = function(Value)
        if Control.bMulti then
            if type(Value) ~= "table" then
                return nil, false
            end
            local Out = {}
            for _, Item in ipairs(Control.Options) do
                if not Item.bDisabled then
                    for _, Sel in ipairs(Value) do
                        if Item.Value == Sel then
                            Out[#Out + 1] = Item.Value
                            break
                        end
                    end
                end
            end
            return Out
        end
        if type(Value) == "table" then
            Value = Value[1]
        end
        local Entry = _FindOption(Value)
        if Entry and not Entry.bDisabled then
            return Entry.Value
        end
        if Value == nil then
            return nil
        end
        return nil, false
    end

    --[[
        判斷指定值是否包含在目前選取結果中。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return true 表示已選取此值；false 表示未選取。
    ]]
    function Control._Selected(self: CDropdownType, Value): boolean
        if self.bMulti then
            for _, Item in ipairs(self.Value or {}) do
                if Item == Value then
                    return true
                end
            end
            return false
        end
        return self.Value == Value
    end

    --[[
        更新選取文字、停用透明度與已展開的選項樣式。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CDropdownType): ()
        if self.bMulti then
            local Names = {}
            for _, Item in ipairs(self.Options) do
                if self:_Selected(Item.Value) then
                    Names[#Names + 1] = Item.Name
                end
            end
            self.Selection.Text = #Names > 0 and table.concat(Names, ", ")
                or tostring(Settings.PlaceholderText or "請選擇…")
        else
            local Entry = _FindOption(self.Value)
            self.Selection.Text = Entry and Entry.Name or tostring(Settings.PlaceholderText or "請選擇…")
        end
        self.Selection.TextTransparency = self.bEnabled and 0 or 0.55
        if self._PaintOptions then
            self._PaintOptions()
        end
    end

    --[[
        非同步回報選取值及索引；多選模式兩者均為陣列。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Emit(self: CDropdownType): ()
        if self.bMulti then
            local Indices = {}
            for _, Item in ipairs(self.Options) do
                if self:_Selected(Item.Value) then
                    Indices[#Indices + 1] = Item.Index
                end
            end
            _InvokeCallback(self, self.Callback, self:Get(), Indices)
        else
            local Entry = _FindOption(self.Value)
            _InvokeCallback(self, self.Callback, self.Value, Entry and Entry.Index or nil)
        end
    end

    --[[
        僅關閉由此下拉欄擁有的浮層。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前控制項實例，可繼續串接操作。
    ]]
    function Control.Close(self: CDropdownType): CDropdownType
        if Window._Popup and Window._Popup.Owner == self then
            Window:ClosePopup()
        end
        return self
    end

    --[[
        建立下拉浮層、搜尋框與選項事件；同一視窗最多保留一個浮層。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前控制項實例，可繼續串接操作。

        使用範例：
        前提：Dropdown 是 Section:CreateDropdown 的回傳值。
        ```lua
        Dropdown:Open() -- 建立目前的選項與搜尋事件
        Dropdown:Close() -- 關閉並清理浮層事件
        ```
    ]]
    function Control.Open(self: CDropdownType): CDropdownType
        if not self:_CanUse() then
            return self
        end
        local bSearchEnabled = Settings.bSearchable ~= false
        local Width = math.max(220, self.Button.AbsoluteSize.X / (Window.RenderScale or Window.Scale))
        local Height = math.min(7, math.max(1, #self.Options)) * 34 + (bSearchEnabled and 50 or 14)

        --[[
            浮層關閉時恢復箭頭方向並移除選項繪製回呼。
        ]]
        local Panel, PopupScope = Window:_OpenPopup(self.Button, Width, Height, self, function(): ()
            self.Arrow.Rotation = 0
            self._PaintOptions = nil
        end)
        if not Panel then
            return self
        end
        self.Arrow.Rotation = 180
        local Rows = {}
        local Top = bSearchEnabled and 44 or 6
        local Sc = _ScrollingFrame(Window, Panel, UDim2.new(1, -12, 1, -Top - 6), UDim2.fromOffset(6, Top))
        _ListLayout(Sc, 2)
        local Empty = _Label(Window, Sc, "沒有符合的選項", UDim2.new(1, 0, 0, 30), nil, 12, "Muted")
        Empty.Visible = #self.Options == 0

        --[[
            依選取值與停用狀態重繪浮層內的選項。
        ]]
        local function _PaintOptions(): ()
            for _, Row in ipairs(Rows) do
                local bSelected = self:_Selected(Row.Option.Value)
                Row.Check.Text = bSelected and "✓" or ""

                --[[
                    混合卡片與強調色，產生已選取選項的背景色。

                    @param Theme 視窗目前的主題色表。
                    @return 依目前主題計算的已選選項背景色。
                ]]
                _BindTheme(Window, Row.Button, "BackgroundColor3", bSelected and function(Theme: ThemeColors)
                    return Theme.Card:Lerp(Theme.Accent, 0.17)
                end or "Card")
                _BindTheme(Window, Row.Text, "TextColor3", bSelected and "Accent" or "Text")
                Row.Text.TextTransparency = Row.Option.bDisabled and 0.6 or 0
            end
        end
        for _, Entry in ipairs(self.Options) do
            local OptionButton = _Button(Window, Sc, "", UDim2.new(1, -3, 0, 32))
            OptionButton.LayoutOrder = Entry.Index
            OptionButton.UIStroke.Enabled = false
            local TextLabel =
                _Label(Window, OptionButton, Entry.Name, UDim2.new(1, -40, 1, 0), UDim2.fromOffset(9, 0), 13)
            local Check = _Label(
                Window,
                OptionButton,
                "",
                UDim2.fromOffset(22, 30),
                UDim2.new(1, -28, 0, 1),
                16,
                "Accent"
            )
            Rows[#Rows + 1] = { Button = OptionButton, Text = TextLabel, Check = Check, Option = Entry }

            --[[
                切換多選值或提交單選值；停用選項不處理點擊。
            ]]
            _Connect(PopupScope, OptionButton.Activated, function(): ()
                if Entry.bDisabled or not self:_CanUse() then
                    return
                end
                if self.bMulti then
                    local Value = self:Get()
                    local bFound = false
                    for Index, Item in ipairs(Value) do
                        if Item == Entry.Value then
                            table.remove(Value, Index)
                            bFound = true
                            break
                        end
                    end
                    if not bFound then
                        Value[#Value + 1] = Entry.Value
                    end
                    self:Set(Value)
                else
                    self:Set(Entry.Value)
                    self:Close()
                end
            end)

            _SetupControlFeedback(self, OptionButton, PopupScope, function(): boolean
                return not Entry.bDisabled
            end, nil, { Inset = 2 })
        end
        self._PaintOptions = _PaintOptions
        _PaintOptions()
        if bSearchEnabled then
            local Search = _TextBox(Window, Panel, "", UDim2.new(1, -16, 0, 30), UDim2.fromOffset(8, 7))
            Search.PlaceholderText = "搜尋選項…"
            _SetupControlFeedback(self, Search, PopupScope)

            --[[
                依搜尋字串篩選選項，更新空結果提示並回到列表頂端。
            ]]
            _Connect(PopupScope, Search:GetPropertyChangedSignal("Text"), function(): ()
                local Query = Search.Text:lower()
                local Count = 0
                for _, Row in ipairs(Rows) do
                    Row.Button.Visible = string.find(Row.Option.Name:lower(), Query, 1, true) ~= nil
                    if Row.Button.Visible then
                        Count = Count + 1
                    end
                end
                Empty.Visible = Count == 0
                Sc.CanvasPosition = Vector2.new(0, 0)
            end)
        end
        return self
    end

    --[[
        替換下拉選項並重新驗證選取結果；先關閉舊浮層以清理其事件。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Values 來源資料表；複製時可為 nil，選項處理時依陣列順序讀取。
        @param bKeepSelection false 丟棄原選取；省略或 true 儘量保留仍有效的項目。
        @param bSilent true 時不觸發值變更回呼；省略或 false 時依變更結果發送回呼。
        @return 目前控制項實例，可繼續串接操作。

        使用範例：
        前提：Dropdown 是單選下拉欄且目前選取 A。
        ```lua
        Dropdown:Refresh({ "B", "C" }, true, true)
        print(Dropdown:Get()) -- A 不存在，改選第一個可用的 B
        ```
    ]]
    function Control.Refresh(
        self: CDropdownType,
        Values,
        bKeepSelection: boolean?,
        bSilent: boolean?
    ): CDropdownType
        self:Close()
        local Old = self:Get()
        self.Options = _NormalizeOptions(Values)
        local NextValue
        if self.bMulti then
            NextValue = bKeepSelection == false and {} or (Old or {})
        else
            local Entry = bKeepSelection ~= false and _FindOption(Old) or nil
            if Entry and not Entry.bDisabled then
                NextValue = Old
            else
                for _, Item in ipairs(self.Options) do
                    if not Item.bDisabled then
                        NextValue = Item.Value
                        break
                    end
                end
            end
        end
        self:Set(NextValue, bSilent)
        self:_Render()
        return self
    end

    --[[
        按下下拉欄時開啟或關閉其浮層。
    ]]
    _Connect(Control._Scope, Control.Button.Activated, function(): ()
        if Window._Popup and Window._Popup.Owner == Control then
            Control:Close()
        else
            Control:Open()
        end
    end)
    local Initial = Settings.CurrentOption
    if Initial == nil then
        if Control.bMulti then
            Initial = {}
        else
            for _, Item in ipairs(Control.Options) do
                if not Item.bDisabled then
                    Initial = Item.Value
                    break
                end
            end
        end
    end
    Control:_Initial(Initial, Settings)
    Control:SetEnabled(Control.bEnabled)
    return Control
end

--[[
    建立快捷鍵控制項；按住模式在按下與釋放時分別回報 true 與 false。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Tab = Window:CreateTab("一般", "grid")
    local Section = Tab:CreateSection({ Name = "設定", Side = "left" })
    local Keybind = Section:CreateKeybind({ Name = "按住", CurrentKeybind = Enum.KeyCode.Q, bHoldToInteract = true, Callback = print })
    Keybind:Set(Enum.KeyCode.E) -- 更換鍵位本身不觸發按下回呼
    ```
]]
function CSection.CreateKeybind(
    self: CSectionType,
    Options: KeybindOptions | string?
): CValueControlType<Enum.KeyCode>
    local Settings = _Options(Options)
    local Control = self:_Control(Settings, "Keybind", Settings.Description and 48 or 34)
    local Window = self.Window
    _Caption(Control, Settings, 128)
    Control.bHold = Settings.bHoldToInteract == true
    Control.bGlobal = Settings.bGlobal == true
    Control.Button = _Button(Window, Control.Frame, "", UDim2.fromOffset(118, 30), UDim2.new(1, -118, 0, 0))
    Control._Interactive = { Control.Button }
    _SetupControlFeedback(Control, Control.Button)

    --[[
        解析鍵位並回報是否有效。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 解析後的鍵位；無效時為 nil。
        @return true 表示鍵位有效；false 表示無效。
    ]]
    Control._Normalize = function(Value): (Enum.KeyCode?, boolean)
        local Key = _KeyFrom(Value)
        return Key, Key ~= nil
    end

    --[[
        顯示目前鍵位名稱，未設定時顯示提示。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CValueControlType<Enum.KeyCode>): ()
        self.Button.Text = self.Value and self.Value.Name or "未設定"
    end

    --[[
        將鍵位轉為可保存的名稱字串。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return KeyCode 名稱；未設定時為 Unknown。
    ]]
    function Control._Serialize(self: CValueControlType<Enum.KeyCode>): string
        return self.Value and self.Value.Name or "Unknown"
    end

    --[[
        刻意略過鍵位變更回呼，避免重新綁定時觸發實際操作。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Emit(self: CValueControlType<Enum.KeyCode>): () end -- Changing a binding never triggers the bound action.

    --[[
        更換快捷鍵；若舊鍵仍按住，先回報釋放再提交新鍵。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @param bSilent true 時不觸發值變更回呼；省略或 false 時依變更結果發送回呼。
        @return 目前控制項實例，可繼續串接操作。
    ]]
    function Control.Set(
        self: CValueControlType<Enum.KeyCode>,
        Value,
        bSilent: boolean?
    ): CValueControlType<Enum.KeyCode>
        local Key = _KeyFrom(Value)
        if not Key then
            return self
        end
        if self._bHeld then
            self._bHeld = false
            _InvokeCallback(self, self.Callback, false)
        end
        return self:_Commit(Key, bSilent)
    end

    --[[
        開始擷取下一個鍵盤輸入，並提示使用者按鍵。
    ]]
    _Connect(Control._Scope, Control.Button.Activated, function(): ()
        if Control:_CanUse() then
            Window:_CancelCapture()
            Window._Capture = Control
            Control.Button.Text = "按下按鍵…"
        end
    end)
    Window._Keybinds[Control] = true
    Control:_Initial(_KeyFrom(Settings.CurrentKeybind) or Enum.KeyCode.Unknown, Settings)
    Control:SetEnabled(Control.bEnabled)
    return Control
end

--[[
    繪製固定格數的棋盤底，供透明度與預覽色塊使用。

    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
]]
local function _Checkerboard(Parent, Scope: ScopeState): ()
    Parent.BackgroundColor3 = Color3.fromRGB(235, 235, 235)
    Parent.BackgroundTransparency = 0
    local Grid = _Frame(Parent,UDim2.fromScale(1,1))
    Grid.Name, Grid.ClipsDescendants = "Checkerboard", true
    local PreviousWidth, PreviousHeight
    local function _LayoutCheckerboard(): ()
        local Scale = CSvg._GuiScale(Parent)
        local Width = math.max(0,Parent.AbsoluteSize.X/Scale)
        local Height = math.max(0,Parent.AbsoluteSize.Y/Scale)
        if Width == PreviousWidth and Height == PreviousHeight then return end
        PreviousWidth, PreviousHeight = Width, Height
        for _, Child in ipairs(Grid:GetChildren()) do Child:Destroy() end
        -- 以相同的像素邊長繪製方格，不因預覽區與滑條長寬比不同而拉伸。
        local Side = math.max(6,Width/128,Height/128)
        for Y = 0, math.ceil(Height/Side)-1 do
            for X = 0, math.ceil(Width/Side)-1 do
                if (X+Y)%2 == 0 then
                    local Cell = _Frame(Grid,UDim2.fromOffset(Side,Side),UDim2.fromOffset(X*Side,Y*Side))
                    Cell.Name, Cell.BackgroundTransparency = "CheckerCell", 0
                    Cell.BackgroundColor3 = Color3.fromRGB(178,178,178)
                end
            end
        end
    end
    _Connect(Scope,Parent:GetPropertyChangedSignal("AbsoluteSize"),_LayoutCheckerboard)
    _LayoutCheckerboard()
end

--[[
    建立 HSV、透明度、HEX、RGB 與色票編輯器，將所有事件歸入指定 Scope。

    @param Control 要建立顯示或處理互動的控制項。
    @param Parent 父 Instance；nil 表示暫不掛入介面樹。
    @param Scope 管理此連線或工作生命週期的容器。
    @param bExpanded true 為常駐展開式調色盤；false 為浮層內的調色盤。
    @return 可在狀態變更時同步顯示的繪製回呼；僅在所屬 Scope 存活時使用。

    使用範例：
    前提：在本模組內，Control 是已初始化的色彩控制項，Parent 為容器。
    ```lua
    local Scope = _CreateScope()
    local Render = _BuildPalette(Control, Parent, Scope, false)
    Render() -- 同步目前色彩
    _CleanScope(Scope) -- 之後不得再使用 Render
    ```
]]
local function _BuildPalette(
    Control: CColorPickerType,
    Parent,
    Scope: ScopeState,
    bExpanded: boolean
): VoidCallback
    local Window = Control.Window
    local SaturationValue = _Frame(Parent, UDim2.new(1, 0, 0, 120))
    SaturationValue.Name = "SaturationValue"
    SaturationValue.ClipsDescendants = false
    _Corner(SaturationValue,5)
    local Surface = _CreateInstance("CanvasGroup",SaturationValue,{
        Name="ColorSurface",Size=UDim2.fromScale(1,1),BackgroundTransparency=0,BorderSizePixel=0,
        GroupTransparency=0,GroupColor3=Color3.new(1,1,1),ClipsDescendants=true,
    })
    _Corner(Surface,5)
    local White = _Frame(Surface, UDim2.fromScale(1, 1))
    White.BackgroundTransparency = 0
    White.BackgroundColor3 = Color3.new(1, 1, 1)
    _CreateInstance("UIGradient", White, {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(1, 1),
        }),
    })
    local Black = _Frame(Surface, UDim2.fromScale(1, 1))
    Black.ZIndex = 2
    Black.BackgroundTransparency = 0
    Black.BackgroundColor3 = Color3.new(0, 0, 0)
    _CreateInstance("UIGradient", Black, {
        Rotation = 90,
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 0),
        }),
    })
    local Cursor = _Frame(SaturationValue, UDim2.fromOffset(12, 12))
    Cursor.Name = "ColorRing"
    Cursor.AnchorPoint = Vector2.new(0.5, 0.5)
    Cursor.ZIndex = 8
    _Corner(Cursor, 20)
    _CreateInstance("UIStroke",Cursor,{
        Color=Color3.new(0,0,0),Thickness=3,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
    })
    local Ring = _Frame(Cursor,UDim2.fromScale(1,1))
    Ring.Name, Ring.ZIndex = "RingHighlight", 8
    _Corner(Ring,20)
    _CreateInstance("UIStroke",Ring,{
        Color=Color3.new(1,1,1),Thickness=1.5,ApplyStrokeMode=Enum.ApplyStrokeMode.Border,
    })
    local SvHit = _CreateInstance("TextButton", SaturationValue, {
        Name = "SaturationValueInput",
        BorderSizePixel = 0,
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Text = "",
        AutoButtonColor = false,
        ZIndex = 5,
    })
    _Corner(SvHit,5)
    _SetupControlFeedback(Control, SvHit, Scope)
    local Right = _Frame(Parent, UDim2.new(1, 0, 0, 190), UDim2.fromOffset(0, 132))

    --[[
        建立色相或透明度滑條及拖曳行為。

        @param Title 標題文字。
        @param Y 相對父容器的垂直偏移，單位為像素。
        @param bHue true 建立色相滑條；false 建立透明度滑條。
        @return 滑條上的位置標記。
        @return 透明度漸層的顏色層；色相滑條為 nil。
        @return 滑條的顯示容器。

        使用範例：
        前提：在 _BuildPalette 內，Control 與 Right 已建立。
        ```lua
        local HueDot = _CreateBar("色相", 0, true)
        local AlphaDot, Paint = _CreateBar("透明度", 30, false) -- 第二回傳值只用於透明度
        ```
    ]]
    local function _CreateBar(Title: string, Y: number, bHue: boolean): (Frame, Frame?, Frame)
        _Label(Window, Right, Title, UDim2.fromOffset(48, 22), UDim2.fromOffset(0, Y), 11, "Muted")
        local Host = _Frame(Right, UDim2.new(1, -54, 0, 14), UDim2.fromOffset(54, Y + 4))
        Host.Name = bHue and "HueTrack" or "AlphaTrack"
        Host.ClipsDescendants = false
        _Corner(Host,3)
        local BarSurface = _CreateInstance("CanvasGroup",Host,{
            Name="BarSurface",Size=UDim2.fromScale(1,1),BackgroundTransparency=0,BorderSizePixel=0,
            GroupTransparency=0,GroupColor3=Color3.new(1,1,1),ClipsDescendants=true,
        })
        _Corner(BarSurface,3)
        local Paint
        if bHue then
            BarSurface.BackgroundColor3 = Color3.new(1, 1, 1)
            local Colors = {}
            for Index = 0, 6 do
                Colors[#Colors + 1] = ColorSequenceKeypoint.new(Index / 6, Color3.fromHSV(Index / 6, 1, 1))
            end
            _CreateInstance("UIGradient", BarSurface, { Color = ColorSequence.new(Colors) })
        else
            _Checkerboard(BarSurface,Scope)
            Paint = _Frame(BarSurface, UDim2.fromScale(1, 1))
            Paint.BackgroundTransparency = 0
            Paint.ZIndex = 2
            _CreateInstance("UIGradient", Paint, {
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
            })
        end
        local Dot = _Frame(Host, UDim2.fromOffset(6, 14))
        Dot.Name = bHue and "HueHandle" or "AlphaHandle"
        Dot.AnchorPoint = Vector2.new(0.5, 0)
        Dot.ZIndex = 4
        Dot.BackgroundTransparency = 0
        _Corner(Dot,2)
        _BindTheme(Window, Dot, "BackgroundColor3", "Text")
        local Hit = _CreateInstance("TextButton", Right, {
            Text = "",
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -54, 0, 26),
            Position = UDim2.fromOffset(54, Y - 2),
            ZIndex = 5,
            AutoButtonColor = false,
            BorderSizePixel = 0,
        })
        Hit.Name = bHue and "HueInput" or "AlphaInput"
        _SetupControlFeedback(Control, Hit, Scope, nil, function(bActive: boolean): ()
            Window:_Tween(Dot, { Size = UDim2.fromOffset(bActive and 8 or 6, 14) })
        end, { Target = Host, Inset = 1, ZIndex = 3 })

        --[[
            收到有效指標輸入時開始拖曳色相或透明度滑條。

            @param Input 開始或更新互動的 Rbx InputObject。
        ]]
        _Connect(Scope, Hit.InputBegan, function(Input: InputObject): ()
            if not Control:_CanUse() or not _IsPointer(Input) then
                return
            end

            --[[
                將滑條上的水平位置映射到 0 至 1，更新色相或不透明度。

                @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
            ]]
            Window:_BeginDrag(Input, function(Position): ()
                local Value =
                    _Clamp((Position.X - Host.AbsolutePosition.X) / math.max(1, Host.AbsoluteSize.X), 0, 1)
                if bHue then
                    Control:_SetHSV(Value, Control.S, Control.V)
                else
                    Control:Set(Control.Color, Value)
                end
            end, nil, Hit)
        end)
        return Dot, Paint, Host
    end
    local HueDot = _CreateBar("色相", 0, true)
    local AlphaDot, AlphaPaint
    if Control.bHasAlpha then
        AlphaDot, AlphaPaint = _CreateBar("透明度", 30, false)
    end
    local Y = Control.bHasAlpha and 66 or 36
    local Preview = _CreateInstance("CanvasGroup",Right,{
        Name="ColorPreview",Size=UDim2.fromOffset(30,30),Position=UDim2.fromOffset(0,Y),
        BorderSizePixel=0,GroupTransparency=0,GroupColor3=Color3.new(1,1,1),ClipsDescendants=true,
    })
    _Checkerboard(Preview,Scope)
    _Corner(Preview,4)
    local PreviewColor = _Frame(Preview, UDim2.fromScale(1, 1))
    PreviewColor.ZIndex = 2
    local HexBox =
        _TextBox(Window, Right, _ToHex(Control.Color), UDim2.new(1, -42, 0, 30), UDim2.fromOffset(42, Y))
    _SetupControlFeedback(Control, HexBox, Scope)
    local Fields = {}
    local Labels = Control.bHasAlpha and { "R", "G", "B", "A %" } or { "R", "G", "B" }
    for Index, Name in ipairs(Labels) do
        local Gap = 6
        local Slot =
            _Frame(Right, UDim2.new(1 / #Labels, -Gap, 0, 50), UDim2.new((Index - 1) / #Labels, Gap/2, 0, Y + 38))
        Slot.Name = "ColorField" .. tostring(Index)
        _Label(Window, Slot, Name, UDim2.new(1, 0, 0, 16), nil, 10, "Muted")
        local Box = _TextBox(Window, Slot, "", UDim2.new(1, 0, 0, 28), UDim2.fromOffset(0, 18))
        Box.Name = "ColorInput" .. tostring(Index)
        Box.UIPadding.PaddingLeft, Box.UIPadding.PaddingRight = UDim.new(0,3), UDim.new(0,3)
        _SetupControlFeedback(Control, Box, Scope)
        Fields[Index] = Box
        Box.TextXAlignment = Enum.TextXAlignment.Center
    end
    _Label(Window, Right, "常用色票", UDim2.new(1, 0, 0, 18), UDim2.fromOffset(0, Y + 94), 11, "Muted")
    local Swatches = Control.Swatches
    for Index, Color in ipairs(Swatches) do
        local Swatch = _Button(
            Window,
            Right,
            "",
            UDim2.fromOffset(22, 22),
            UDim2.new((Index - 1) / #Swatches, 0, 0, Y + 116)
        )
        Swatch.BackgroundColor3 = Color
        Window._Bindings[Swatch].BackgroundColor3 = nil
        Swatch.UICorner.CornerRadius = UDim.new(1, 0)
        _SetupControlFeedback(Control, Swatch, Scope)

        --[[
            使用者選取常用色票時套用顏色並保留不透明度。
        ]]
        _Connect(Scope, Swatch.Activated, function(): ()
            if Control:_CanUse() then
                Control:Set(Color, Control.Alpha)
            end
        end)
    end

    --[[
        在飽和度與明度區域開始二維拖曳。

        @param Input 開始或更新互動的 Rbx InputObject。
    ]]
    _Connect(Scope, SvHit.InputBegan, function(Input: InputObject): ()
        if not Control:_CanUse() or not _IsPointer(Input) then
            return
        end

        --[[
            將指標位置轉為飽和度與明度，保持目前色相。

            @param Position GUI 位置或事件傳入的螢幕座標，依此呼叫來源解讀。
        ]]
        Window:_BeginDrag(Input, function(Position): ()
            local X = _Clamp(
                (Position.X - SaturationValue.AbsolutePosition.X)
                    / math.max(1, SaturationValue.AbsoluteSize.X),
                0,
                1
            )
            local Value = 1
                - _Clamp(
                    (Position.Y - SaturationValue.AbsolutePosition.Y)
                        / math.max(1, SaturationValue.AbsoluteSize.Y),
                    0,
                    1
                )
            Control:_SetHSV(Control.H, X, Value)
        end, nil, SvHit)
    end)

    --[[
        同步調色盤指標、預覽與數字欄位；正在編輯的文字框不會被覆蓋。
    ]]
    local function _RenderPalette(): ()
        Surface.BackgroundColor3 = Color3.fromHSV(Control.H, 1, 1)
        Cursor.Position = UDim2.fromScale(Control.S, 1 - Control.V)
        HueDot.Position = UDim2.new(Control.H, 0, 0, 0)
        if AlphaDot then
            AlphaDot.Position = UDim2.new(Control.Alpha, 0, 0, 0)
            AlphaPaint.BackgroundColor3 = Control.Color
        end
        PreviewColor.BackgroundColor3 = Control.Color
        PreviewColor.BackgroundTransparency = 1 - Control.Alpha
        if not HexBox:IsFocused() then
            HexBox.Text = _ToHex(Control.Color)
        end
        local Values = {
            math.floor(Control.Color.R * 255 + 0.5),
            math.floor(Control.Color.G * 255 + 0.5),
            math.floor(Control.Color.B * 255 + 0.5),
            math.floor(Control.Alpha * 100 + 0.5),
        }
        for Index, Box in ipairs(Fields) do
            if not Box:IsFocused() then
                Box.Text = tostring(Values[Index])
            end
            Box.TextEditable = Control.bEnabled
        end
        HexBox.TextEditable = Control.bEnabled
    end

    --[[
        提交有效 HEX 顏色並將文字恢復成標準六位格式。
    ]]
    _Connect(Scope, HexBox.FocusLost, function(): ()
        local Color = _ParseColor(HexBox.Text)
        if Control:_CanUse() and Color then
            Control:Set(Color, Control.Alpha)
        end
        HexBox.Text = _ToHex(Control.Color)
        _RenderPalette()
    end)
    for Index, Box in ipairs(Fields) do
        --[[
            提交 RGB 或透明度欄位；超界數值會限制到允許範圍。
        ]]
        _Connect(Scope, Box.FocusLost, function(): ()
            local Number = tonumber(Box.Text)
            if Control:_CanUse() and _IsFinite(Number) then
                if Index == 4 then
                    Control:Set(Control.Color, _Clamp(Number / 100, 0, 1))
                else
                    local RGB = { Control.Color.R * 255, Control.Color.G * 255, Control.Color.B * 255 }
                    RGB[Index] = _Clamp(Number, 0, 255)
                    Control:Set(Color3.fromRGB(RGB[1], RGB[2], RGB[3]), Control.Alpha)
                end
            end
            _RenderPalette()
        end)
    end

    --[[
        依可用寬度切換調色盤單欄與雙欄排版，更新展開式元件高度。
    ]]
    local function _LayoutPalette(): ()
        local bWide = bExpanded and Parent.AbsoluteSize.X / (Window.RenderScale or Window.Scale) >= 550
        local RightHeight = Y + 140
        if bWide then
            SaturationValue.Size = UDim2.new(0.45, 0, 0, RightHeight)
            Right.Position = UDim2.new(0.48, 0, 0, 0)
            Right.Size = UDim2.new(0.52, 0, 0, RightHeight)
            Parent.Size = UDim2.new(1, -20, 0, RightHeight)
        else
            SaturationValue.Size = UDim2.new(1, 0, 0, 120)
            Right.Position = UDim2.fromOffset(0, 132)
            Right.Size = UDim2.new(1, 0, 0, RightHeight)
            Parent.Size = UDim2.new(1, -20, 0, 132 + RightHeight)
        end
        if bExpanded then
            Control.Frame.Size = UDim2.new(1, 0, 0, 50 + Parent.Size.Y.Offset)
        end
    end
    _Connect(Scope, Parent:GetPropertyChangedSignal("AbsoluteSize"), _LayoutPalette)
    _LayoutPalette()
    _RenderPalette()
    return _RenderPalette
end

--[[
    建立色彩選擇器，支援展開式調色盤或按需開啟的浮層。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Tab = Window:CreateTab("一般", "grid")
    local Section = Tab:CreateSection({ Name = "設定", Side = "left" })
    local Picker = Section:CreateColorPicker({ Name = "主題", Color = "#2DD4BF", Alpha = 1, bExpanded = true })
    Picker:Set("#FF8800", 0.5, true)
    local Color, Alpha = Picker:Get() -- Alpha 為 0.5
    ```
]]
function CSection.CreateColorPicker(
    self: CSectionType,
    Options: ColorPickerOptions | string?
): CColorPickerType
    local Settings = _Options(Options)
    local Control = self:_Control(Settings, "ColorPicker", 36)
    local Window = self.Window
    Control.bHasAlpha = Settings.Alpha ~= nil
    Control.Alpha = _Clamp(_NumberOr(Settings.Alpha, 1), 0, 1)
    Control.Color = _ParseColor(Settings.Color) or Window.Theme.Accent
    Control.H, Control.S, Control.V = Control.Color:ToHSV()
    Control.Swatches = {}
    for _, Item in
        ipairs(
            Settings.Swatches
                or { "#2DD4BF", "#3B82F6", "#A855F7", "#F472B6", "#FB923C", "#FACC15", "#4ADE80", "#64748B" }
        )
    do
        local Col = _ParseColor(Item)
        if Col and #Control.Swatches < 12 then
            Control.Swatches[#Control.Swatches + 1] = Col
        end
    end
    _Caption(Control, Settings, 112)
    Control.Button = _Button(Window, Control.Frame, "", UDim2.fromOffset(102, 28), UDim2.new(1, -102, 0, 0))
    Control._Interactive = { Control.Button }
    _SetupControlFeedback(Control, Control.Button)
    Control.Chip = _Frame(Control.Button, UDim2.fromOffset(18, 18), UDim2.fromOffset(5, 5))
    Control.Chip.BackgroundTransparency = 0
    _Corner(Control.Chip, 3)
    Control.HexLabel = _Label(
        Window,
        Control.Button,
        _ToHex(Control.Color),
        UDim2.fromOffset(74, 28),
        UDim2.fromOffset(26, 0),
        11
    )

    --[[
        取得目前顏色與不透明度。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前 Color3。
        @return 目前不透明度，範圍為 0 到 1。
    ]]
    function Control.Get(self: CColorPickerType): (Color3, number)
        return self.Color, self.Alpha
    end

    --[[
        將顏色轉為 HEX 與 Alpha 記錄供 JSON 保存。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 包含 HEX Color 與 Alpha 的可序列化記錄。
    ]]
    function Control._Serialize(self: CColorPickerType): { Color: string, Alpha: number }
        return { Color = _ToHex(self.Color), Alpha = self.Alpha }
    end

    --[[
        恢復已保存的顏色記錄，也接受單獨的顏色輸入。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @param bSilent true 時不觸發值變更回呼；省略或 false 時依變更結果發送回呼。
        @return 目前控制項實例，可繼續串接操作。
    ]]
    function Control._Restore(self: CColorPickerType, Value, bSilent: boolean?): CColorPickerType
        if type(Value) == "table" then
            return self:Set(Value.Color, Value.Alpha, bSilent)
        end
        return self:Set(Value, nil, bSilent)
    end

    --[[
        非同步回報目前 Color3 與不透明度。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Emit(self: CColorPickerType): ()
        _InvokeCallback(self, self.Callback, self.Color, self.Alpha)
    end

    --[[
        同步色塊、HEX 標籤與目前存在的調色盤。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CColorPickerType): ()
        self.Chip.BackgroundColor3 = self.Color
        self.Chip.BackgroundTransparency = 1 - self.Alpha
        self.HexLabel.Text = _ToHex(self.Color)
        self.HexLabel.TextTransparency = self.bEnabled and 0 or 0.55
        if self._PaletteRender then
            self._PaletteRender()
        end
    end

    --[[
        驗證並設定顏色與不透明度，必要時同步 HSV 並發出變更回呼。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Color Color3 或支援的 HEX 顏色輸入。
        @param Alpha 不透明度，範圍 0 到 1；nil 保留原值；boolean 可直接指定靜默設定。
        @param bSilent true 時不觸發值變更回呼；省略或 false 時依變更結果發送回呼。
        @return 目前控制項實例，可繼續串接操作。

        使用範例：
        前提：Picker 是有設定 Alpha 選項的 ColorPicker。
        ```lua
        Picker:Set("#FF8800", 0.5, true) -- 設定半透明且不觸發回呼
        local Color, Alpha = Picker:Get() -- Alpha 為 0.5
        ```
    ]]
    function Control.Set(
        self: CColorPickerType,
        Color: ColorInput,
        Alpha: number | boolean?,
        bSilent: boolean?
    ): CColorPickerType
        if self.bDestroyed then
            return self
        end
        if type(Alpha) == "boolean" and bSilent == nil then
            bSilent = Alpha
            Alpha = nil
        end
        Color = _ParseColor(Color)
        if not Color then
            return self
        end
        Alpha = self.bHasAlpha and _Clamp(_NumberOr(Alpha, self.Alpha), 0, 1) or 1
        local bChanged = self.Color ~= Color or self.Alpha ~= Alpha
        self.Color, self.Alpha = Color, Alpha
        if not self._bKeepHSV and Color ~= self._LastHSVColor then
            self.H, self.S, self.V = Color:ToHSV()
        end
        self._LastHSVColor = Color
        self:_Render()
        if bChanged then
            Window:_Dirty()
            if not bSilent then
                self:_Emit()
            end
        end
        return self
    end

    --[[
        以 HSV 更新顏色，保留零飽和或全黑時仍有意義的色相座標。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Hue 色相，範圍 0 到 1。
        @param Saturation 飽和度，範圍 0 到 1。
        @param Brightness 明度，範圍 0 到 1。
    ]]
    function Control._SetHSV(self: CColorPickerType, Hue: number, Saturation: number, Brightness: number): ()
        self.H, self.S, self.V = Hue, Saturation, Brightness
        self._bKeepHSV = true
        self:Set(Color3.fromHSV(Hue, Saturation, Brightness), self.Alpha)
        self._bKeepHSV = false
    end

    --[[
        僅關閉由此色彩選擇器擁有的浮層。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前控制項實例，可繼續串接操作。
    ]]
    function Control.Close(self: CColorPickerType): CColorPickerType
        if Window._Popup and Window._Popup.Owner == self then
            Window:ClosePopup()
        end
        return self
    end

    --[[
        開啟可捲動的調色盤浮層；展開式元件不另外開啟浮層。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前控制項實例，可繼續串接操作。

        使用範例：
        前提：Picker 為未設定 bExpanded=true 的 ColorPicker。
        ```lua
        Picker:Open() -- 建立調色盤與事件
        Picker:Close() -- 釋放浮層與繪製回呼
        ```
    ]]
    function Control.Open(self: CColorPickerType): CColorPickerType
        if Settings.bExpanded or not self:_CanUse() then
            return self
        end

        --[[
            色彩浮層關閉時移除其繪製回呼。
        ]]
        local Panel, PopupScope = Window:_OpenPopup(
            self.Button,
            320,
            self.bHasAlpha and 370 or 340,
            self,
            function(): ()
                self._PaletteRender = nil
            end
        )
        if not Panel then
            return self
        end
        local Scroll = _ScrollingFrame(Window, Panel, UDim2.new(1, -20, 1, -18), UDim2.fromOffset(10, 9))
        local Body = _Frame(Scroll, UDim2.new(1, -20, 0, 340), UDim2.fromOffset(10,10))
        self._PaletteRender = _BuildPalette(self, Body, PopupScope, false)
        return self
    end
    if Control.bSave and Control.Flag and Window._SavedFlags[Control.Flag] ~= nil then
        Control:_Restore(Window._SavedFlags[Control.Flag], true)
    end
    if Settings.bExpanded then
        local Body = _Frame(Control.Frame, UDim2.new(1, -20, 0, 340), UDim2.fromOffset(10,40))
        Control._PaletteRender = _BuildPalette(Control, Body, Control._Scope, true)
    end

    --[[
        按下色塊時切換此色彩選擇器的浮層。
    ]]
    _Connect(Control._Scope, Control.Button.Activated, function(): ()
        if Window._Popup and Window._Popup.Owner == Control then
            Control:Close()
        else
            Control:Open()
        end
    end)
    Control:_Render()
    Control:SetEnabled(Control.bEnabled)
    if Settings.bEmitInitial then
        Control:_Emit()
    end
    return Control
end

--[[
    建立可選圖示的唯讀文字標籤。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateLabel(self: CSectionType, Options: LabelOptions | string?): CValueControlType<string>
    local Settings = _Options(Options)
    local Control = self:_Control(Settings, "Label", 26)
    local X = Settings.Icon and 26 or 0
    if Settings.Icon then
        _Icon(self.Window, Control.Frame, Settings.Icon, UDim2.fromOffset(0, 3), 18)
    end
    Control.Title = _Label(
        self.Window,
        Control.Frame,
        Control.Name,
        UDim2.new(1, -X, 1, 0),
        UDim2.fromOffset(X, 0),
        13,
        Settings.Color or "Muted"
    )

    --[[
        將標籤輸入轉成字串，nil 轉為空字串。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 輸入的字串表示；nil 為空字串。
    ]]
    Control._Normalize = function(Value): string
        return tostring(Value or "")
    end

    --[[
        同步標籤顯示文字與搜尋名稱。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CValueControlType<string>): ()
        self.Title.Text = self.Value
        self.Name = self.Value
    end
    Control.bSave = false
    Control:_Initial(Control.Name, Settings)
    return Control
end

--[[
    建立依內容自動增高的標題與段落。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateParagraph(self: CSectionType, Options: ParagraphOptions | string?): CParagraphType
    local Settings = _Options(Options)
    Settings.Name = Settings.Title or Settings.Name or "說明"
    local Control = self:_Control(Settings, "Paragraph", 30)
    local Window = self.Window
    Control.Frame.AutomaticSize = Enum.AutomaticSize.Y
    Control.Title = _Label(Window, Control.Frame, Control.Name, UDim2.new(1, 0, 0, 22), nil, 13)
    Control.Body = _Label(
        Window,
        Control.Frame,
        Settings.Content or "",
        UDim2.new(1, 0, 0, 18),
        UDim2.fromOffset(0, 26),
        12,
        "Muted"
    )
    Control.Body.TextWrapped = true
    Control.Body.TextTruncate = Enum.TextTruncate.None
    Control.Body.AutomaticSize = Enum.AutomaticSize.Y

    --[[
        同時更新段落標題與內文。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Title 標題文字。
        @param Body 段落內文；nil 顯示空字串。
        @return 目前控制項實例，可繼續串接操作。
    ]]
    function Control.Set(self: CParagraphType, Title, Body): CParagraphType
        self.Name = tostring(Title or "")
        self.Title.Text = self.Name
        self.Body.Text = tostring(Body or "")
        return self
    end

    --[[
        取得段落目前的標題與內文。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前段落標題。
        @return 目前段落內文。
    ]]
    function Control.Get(self: CParagraphType): (string, string)
        return self.Title.Text, self.Body.Text
    end
    Control.bSave = false
    return Control
end

--[[
    建立不保存狀態的水平分隔線。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateDivider(self: CSectionType): CControlType
    local Control = self:_Control({ Name = "分隔線", bSave = false }, "Divider", 9)
    local Line = _Frame(Control.Frame, UDim2.new(1, 0, 0, 1), UDim2.fromOffset(0, 4))
    Line.BackgroundTransparency = 0
    _BindTheme(self.Window, Line, "BackgroundColor3", "Border")
    return Control
end

--[[
    建立顯示 0 至 100 百分比的進度條。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateProgress(
    self: CSectionType,
    Options: ProgressOptions | string?
): CValueControlType<number>
    local Settings = _Options(Options)
    local Control = self:_Control(Settings, "Progress", 44)
    local Window = self.Window
    _Caption(Control, Settings, 60)
    Control.Percent =
        _Label(Window, Control.Frame, "", UDim2.fromOffset(54, 22), UDim2.new(1, -54, 0, 0), 12, "Muted")
    Control.Percent.TextXAlignment = Enum.TextXAlignment.Right
    local Track = _Frame(Control.Frame, UDim2.new(1, 0, 0, 7), UDim2.fromOffset(0, 30))
    Track.BackgroundTransparency = 0
    _BindTheme(Window, Track, "BackgroundColor3", "Hover")
    _Corner(Track, 8)
    local Fill = _Frame(Track, UDim2.new(0, 0, 1, 0))
    Fill.BackgroundTransparency = 0
    _BindTheme(Window, Fill, "BackgroundColor3", "Accent")
    _Corner(Fill, 8)

    --[[
        將有限數值限制到百分比範圍；非數值輸入判定為無效。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 0 至 100 之間的百分比；無效時為 nil。
        @return true 表示數值有效；false 表示無效。
    ]]
    Control._Normalize = function(Value): (number?, boolean)
        Value = tonumber(Value)
        return _IsFinite(Value) and _Clamp(Value, 0, 100) or nil, _IsFinite(Value)
    end

    --[[
        更新進度填色與整數百分比文字。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CValueControlType<number>): ()
        Fill.Size = UDim2.new(self.Value / 100, 0, 1, 0)
        self.Percent.Text = string.format("%.0f%%", self.Value)
    end
    Control.bSave = false
    Control:_Initial(_NumberOr(Settings.CurrentValue, 0), Settings)
    return Control
end

--[[
    建立使用成功、警告、錯誤或資訊色的狀態標籤。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateBadge(self: CSectionType, Options: BadgeOptions | string?): CBadgeType
    local Settings = _Options(Options)
    local Control = self:_Control(Settings, "Badge", 34)
    local Window = self.Window
    local Token = ({ success = "Success", warning = "Warning", error = "Error", info = "Info" })[string.lower(
        tostring(Settings.Status or "info")
    )] or "Info"
    Control.Frame.BackgroundTransparency = 0
    _Corner(Control.Frame, 4)

    --[[
        以狀態色輕微混合卡片底色，產生提示標籤的背景。

        @param Theme 視窗目前的主題色表。
        @return 依狀態色計算的提示背景色。
    ]]
    _BindTheme(Window, Control.Frame, "BackgroundColor3", function(Theme: ThemeColors)
        return Theme.Card:Lerp(Theme[Token], 0.13)
    end)
    _Stroke(Window, Control.Frame, Token)
    Control.Title = _Label(
        Window,
        Control.Frame,
        Control.Name,
        UDim2.new(1, -20, 1, 0),
        UDim2.fromOffset(10, 0),
        12,
        Token
    )

    --[[
        更新狀態標籤的名稱與文字。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 目前控制項實例，可繼續串接操作。
    ]]
    function Control.Set(self: CBadgeType, Value): CBadgeType
        self.Name = tostring(Value)
        self.Title.Text = self.Name
        return self
    end

    --[[
        取得狀態標籤文字。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
        @return 目前狀態標籤文字。
    ]]
    function Control.Get(self: CBadgeType): string
        return self.Name
    end
    Control.bSave = false
    return Control
end

--[[
    建立單選群組；外圈尺寸固定，中心圓點以縮放與淡入淡出表示選取狀態。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 目前控制項實例，可繼續串接操作。
]]
function CSection.CreateRadioGroup(
    self: CSectionType,
    Options: RadioOptions | string?
): CValueControlType<OptionValue?>
    local Settings = _Options(Options)
    local Control = self:_Control(Settings, "RadioGroup", 30)
    local Window = self.Window
    _Caption(Control, Settings)
    Control.Options = _NormalizeOptions(Settings.Options)
    local Buttons = {}
    Control.Frame.Size = UDim2.new(1, 0, 0, 26 + #Control.Options * 32)
    for Index, Entry in ipairs(Control.Options) do
        local OptionButton = _Button(
            Window,
            Control.Frame,
            "",
            UDim2.new(1, 0, 0, 28),
            UDim2.fromOffset(0, 26 + (Index - 1) * 32)
        )
        OptionButton.BackgroundTransparency = 1
        OptionButton.UIStroke.Enabled = false
        _SetupControlFeedback(Control, OptionButton, nil, function(): boolean
            return not Entry.bDisabled
        end)
        -- Both states share one fixed 18x18 ring; only the 8x8 center is toggled.
        local Ring = _Frame(OptionButton, UDim2.fromOffset(18, 18), UDim2.fromOffset(3, 5))
        Ring.Name = "RadioRing"
        _Corner(Ring, 20)
        local Border = _Stroke(Window, Ring, "Muted")
        Border.Thickness = 1.5
        local Dot = _Frame(Ring, UDim2.fromOffset(0, 0), UDim2.fromScale(0.5, 0.5))
        Dot.Name = "RadioDot"
        Dot.AnchorPoint = Vector2.new(0.5, 0.5)
        Dot.BackgroundTransparency = 1
        _Corner(Dot, 20)
        _BindTheme(Window, Dot, "BackgroundColor3", "Accent")
        local Text =
            _Label(Window, OptionButton, Entry.Name, UDim2.new(1, -30, 1, 0), UDim2.fromOffset(30, 0), 13)
        Buttons[#Buttons + 1] = { Ring = Ring, Border = Border, Dot = Dot, Text = Text, Option = Entry }

        --[[
            選取被啟動且未停用的 Radio 選項。
        ]]
        _Connect(Control._Scope, OptionButton.Activated, function(): ()
            if Control:_CanUse() and not Entry.bDisabled then
                Control:Set(Entry.Value)
            end
        end)
    end

    --[[
        接受群組內未停用的選項值，其餘輸入判定為無效。

        @param Value 待檢查或套用的值，依此控制項種類解讀。
        @return 找到且未停用的選項值；無效時為 nil。
        @return 無效輸入時為 false；成功時省略此值。
    ]]
    Control._Normalize = function(Value)
        for _, Entry in ipairs(Control.Options) do
            if Entry.Value == Value and not Entry.bDisabled then
                return Value
            end
        end
        return nil, false
    end

    --[[
        更新 Radio 圓點、邊框色與停用透明度，保持外圈尺寸不變。

        @param self 要操作的目前實例；由冒號呼叫自動傳入。
    ]]
    function Control._Render(self: CValueControlType<OptionValue?>): ()
        local Duration = self._bRadioInitialized and 0.14 or 0
        for _, Row in ipairs(Buttons) do
            local bSelected = self.Value == Row.Option.Value
            local Transparency = (self.bEnabled and not Row.Option.bDisabled) and 0 or 0.55
            Row.Dot.Visible = true
            _BindTheme(Window, Row.Border, "Color", bSelected and "Accent" or "Muted")
            Row.Border.Transparency = Transparency
            Window:_Tween(Row.Border, { Thickness = bSelected and 1.8 or 1.5 }, Duration)
            Window:_Tween(Row.Dot, {
                Size = UDim2.fromOffset(bSelected and 8 or 0, bSelected and 8 or 0),
                BackgroundTransparency = bSelected and Transparency or 1,
            }, Duration)
            Row.Text.TextTransparency = Transparency
        end
        self._bRadioInitialized = true
    end
    local Initial = Settings.CurrentOption
    if Initial == nil then
        for _, Item in ipairs(Control.Options) do
            if not Item.bDisabled then
                Initial = Item.Value
                break
            end
        end
    end
    Control:_Initial(Initial, Settings)
    Control:SetEnabled(Control.bEnabled)
    return Control
end

--[[
    顯示可帶操作按鈕的通知；最多保留四則，並依 Duration 自動關閉。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 新通知的銷毀控制柄；視窗已銷毀時為 nil。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "範例", ConfigId = "Example" })
    local Toast = Window:Notify({ Title = "完成", Content = "設定已儲存", Duration = 5 })
    if Toast then Toast:Destroy() end -- 可在五秒前主動關閉
    ```
]]
function CWindow.Notify(self: CWindowType, Options: NotificationOptions): ToastType?
    if self.bDestroyed then return nil end
    local Settings, Window, Scope = _Options(Options), self, _CreateScope()
    if not self.ToastHost then
        self.ToastHost = _Frame(self.Surface,UDim2.new(0,320,1,-32),UDim2.new(1,-336,0,16))
        self.ToastHost.ZIndex = 200
        local Layout = _ListLayout(self.ToastHost,8)
        Layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
        self:_Layout()
    end
    local Toast = {bDestroyed=false,bClosing=false,_bRemoved=false}
    local Expiry, Countdown, Fill
    local ToastFrame = _Frame(self.ToastHost,UDim2.new(1,0,0,0))
    ToastFrame.Name = "Toast"
    ToastFrame.AutomaticSize = Enum.AutomaticSize.Y
    ToastFrame.LayoutOrder = self._ToastOrder or 0
    self._ToastOrder = ToastFrame.LayoutOrder+1
    self._CursorTargets[ToastFrame] = true
    local Panel = _CreateInstance("CanvasGroup",ToastFrame,{
        Name="ToastContent",Size=UDim2.new(1,0,0,0),Position=UDim2.fromOffset(16,0),
        AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=0,BorderSizePixel=0,
        GroupColor3=Color3.new(1,1,1),GroupTransparency=1,ClipsDescendants=true,
    })
    _BindTheme(Window,Panel,"BackgroundColor3","Card")
    _Corner(Panel,6)
    _Stroke(Window,Panel)
    _Padding(Panel,12)
    _ListLayout(Panel,6)
    for _, Property in ipairs({"AbsolutePosition","AbsoluteSize","Visible"}) do
        _Connect(Scope,ToastFrame:GetPropertyChangedSignal(Property),function(): () Window:_RefreshCursor() end)
    end
    local function _CanUse(): boolean return not Toast.bDestroyed end
    local function _Finalize(): ()
        if Toast._bRemoved then return end
        Toast._bRemoved, Toast.bDestroyed, Toast.bClosing = true, true, false
        _CleanScope(Scope)
        Window._CursorTargets[ToastFrame] = nil
        Window._Toasts[Toast] = nil
        _Dispose(Window,ToastFrame)
        Window:_RefreshCursor()
    end
    function Toast.Destroy(self: ToastType, bImmediate: boolean?): ()
        if self._bRemoved then return end
        if bImmediate or Window.bDestroyed or not Window.bAnimations then _Finalize(); return end
        if self.bClosing then return end
        self.bDestroyed, self.bClosing = true, true
        if Expiry and Scope._Timers[Expiry] then
            Scope._Timers[Expiry] = nil
            _CancelTask(Expiry)
        end
        Expiry = nil
        if Countdown then Countdown:Cancel() end
        if Fill then Window._Tweens[Fill] = nil end
        Window._CursorTargets[ToastFrame] = nil
        Window:_ResetFeedback(ToastFrame)
        Window:_Tween(Panel,{GroupTransparency=1,Position=UDim2.fromOffset(16,0)},TOAST_ANIMATION_DURATION)
        _Schedule(Scope,TOAST_ANIMATION_DURATION,_Finalize)
    end
    local Head = _Frame(Panel,UDim2.new(1,0,0,22))
    Head.LayoutOrder = 1
    local Title = _Label(Window,Head,Settings.Title or "通知",UDim2.new(1,-56,1,0),UDim2.fromOffset(28,0),14,"Accent")
    Title.Name = "NotificationTitle"
    local TitleIcon = _Icon(Window,Head,Settings.Icon or Settings.Image or "Info",UDim2.fromOffset(0,1),20,"Accent")
    TitleIcon.Name = "NotificationIcon"
    local Close = _Button(Window,Head,"",UDim2.fromOffset(22,22),UDim2.new(1,-22,0,0))
    local CloseIcon = _Icon(Window,Close,"Close",nil,16,"Text")
    CloseIcon.AnchorPoint, CloseIcon.Position = Vector2.new(0.5,0.5),UDim2.fromScale(0.5,0.5)
    _SetupFeedback(Window,Close,Scope,_CanUse)
    _Connect(Scope,Close.Activated,function(): () Toast:Destroy() end)
    local Body = _Label(Window,Panel,Settings.Content or "",UDim2.new(1,0,0,20),nil,12,"Muted")
    Body.LayoutOrder, Body.TextWrapped = 2, true
    Body.TextTruncate, Body.AutomaticSize = Enum.TextTruncate.None, Enum.AutomaticSize.Y
    local Actions, Keys = Settings.Actions or {}, {}
    for Key in pairs(Actions) do Keys[#Keys+1] = Key end
    table.sort(Keys,function(A,B): boolean return tostring(A)<tostring(B) end)
    for Index, Key in ipairs(Keys) do
        local Action = Actions[Key]
        local Button = _Button(Window,Panel,Action.Name or tostring(Key))
        Button.LayoutOrder = Index+2
        _SetupFeedback(Window,Button,Scope,_CanUse)
        _Connect(Scope,Button.Activated,function(): ()
            if Toast.bDestroyed then return end
            _InvokeCallback(Window,Action.Callback)
            Toast:Destroy()
        end)
    end
    local Duration = _NumberOr(Settings.Duration,5)
    if Duration > 0 then
        local Track = _Frame(Panel,UDim2.new(1,0,0,4))
        Track.Name, Track.LayoutOrder = "CountdownTrack", #Keys+3
        Track.BackgroundTransparency, Track.ClipsDescendants = 0, true
        _BindTheme(Window,Track,"BackgroundColor3","Hover")
        _Corner(Track,3)
        Fill = _Frame(Track,UDim2.fromScale(1,1))
        Fill.Name, Fill.AnchorPoint = "CountdownFill", Vector2.new(0,0)
        Fill.BackgroundTransparency = 0
        _BindTheme(Window,Fill,"BackgroundColor3","Accent")
        _Corner(Fill,3)
        Countdown = TweenService:Create(Fill,TweenInfo.new(Duration,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{
            Size=UDim2.fromScale(0,1),
        })
        Window._Tweens[Fill] = Countdown
        Countdown:Play()
        Expiry = _Schedule(Scope,Duration,function(): () Toast:Destroy() end)
    end
    self._Toasts[Toast] = ToastFrame.LayoutOrder
    local Count, Oldest = 0, nil
    for Item, Order in pairs(self._Toasts) do
        if not Item.bDestroyed then
            Count += 1
            if not Oldest or Order < self._Toasts[Oldest] then Oldest = Item end
        end
    end
    if Count > 4 and Oldest then Oldest:Destroy() end
    Window:_Tween(Panel,{GroupTransparency=0,Position=UDim2.fromOffset(0,0)},TOAST_ANIMATION_DURATION)
    Window:_RefreshCursor()
    return Toast
end


--[[
    將通知送到最近建立且尚未銷毀的視窗；沒有視窗時以 warn 提示。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Settings 已正規化的設定表或允許的名稱簡寫。
    @return 新通知控制柄；沒有有效視窗時為 nil。
]]
function Library.Notify(self: LibraryType, Settings: NotificationOptions): ToastType?
    if self._Last and not self._Last.bDestroyed then
        return self._Last:Notify(Settings)
    end
    warn("[BjzUi] CreateWindow must be called before Notify")
end

--[[
    建立僅限本機 UI 的 Key 門鎖；不發出網路請求，也不是伺服器授權機制。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Settings 本機 Key 比對與提示設定；Key 可為字串或字串陣列。
    @param bSavedAccepted true 表示設定檔已有通過記錄；仍須 bSaveKey 才直接通過。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:CreateWindow({ Name = "本機門鎖", bKeySystem = true, KeySettings = { Key = "demo", bSaveKey = false } })
    -- 輸入 demo 只解除這個用戶端的 UI 門鎖，不提供伺服器授權。
    ```
]]
function CWindow._KeyGate(self: CWindowType, Settings: KeySettings, bSavedAccepted: boolean?): ()
    -- UI-only local gate; user supplied remote key URLs are intentionally not fetched.
    if Settings.bSaveKey and bSavedAccepted then
        self._bKeyAccepted = true
        return
    end
    self.bLocked = true
    local Gate = _Frame(self.Main, UDim2.fromScale(1, 1))
    Gate.ZIndex = 60
    Gate.BackgroundTransparency = 0.04
    _BindTheme(self, Gate, "BackgroundColor3", "Background")
    _Corner(Gate, 8)
    local Blocker = _CreateInstance(
        "TextButton",
        Gate,
        { Text = "", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, AutoButtonColor = false }
    )
    local Card = _Frame(Gate, UDim2.new(1, -60, 0, 250), UDim2.new(0, 30, 0.5, -125))
    Card.ZIndex = 2
    _Label(self, Card, Settings.Title or "Key System", UDim2.new(1, 0, 0, 30), nil, 20, "Accent")
    _Label(
        self,
        Card,
        Settings.Subtitle or "輸入金鑰",
        UDim2.new(1, 0, 0, 22),
        UDim2.fromOffset(0, 38),
        13
    )
    local Note =
        _Label(self, Card, Settings.Note or "", UDim2.new(1, 0, 0, 42), UDim2.fromOffset(0, 66), 12, "Muted")
    Note.TextWrapped = true
    local InputBox = _TextBox(self, Card, "", UDim2.new(1, 0, 0, 36), UDim2.fromOffset(0, 118))
    InputBox.PlaceholderText = "Key"
    local Submit = _Button(self, Card, "解鎖", UDim2.new(1, 0, 0, 34), UDim2.fromOffset(0, 166), "primary")
    local Status = _Label(self, Card, "", UDim2.new(1, 0, 0, 24), UDim2.fromOffset(0, 208), 12, "Error")

    --[[
        比對使用者輸入與允許的 Key，成功時解除門鎖並依設定保存通過狀態。
    ]]
    local function _Unlock(): ()
        local Keys = type(Settings.Key) == "table" and Settings.Key or { Settings.Key }
        local bValid = false
        for _, Key in ipairs(Keys) do
            if type(Key) == "string" and #Key > 0 and InputBox.Text == Key then
                bValid = true
            end
        end
        if bValid then
            self.bLocked = false
            self._bKeyAccepted = Settings.bSaveKey == true
            _Dispose(self, Gate)
            self:_UpdateNavigationHover()
            self:_Dirty()
        else
            Status.Text = "金鑰不正確"
        end
    end
    _Connect(self._Scope, Submit.Activated, _Unlock)

    --[[
        使用者以 Enter 提交 Key 時執行解鎖檢查。

        @param bEnter true 表示以 Enter 提交；false 表示一般失焦。
    ]]
    _Connect(self._Scope, InputBox.FocusLost, function(bEnter: boolean): ()
        if bEnter then
            _Unlock()
        end
    end)
end

--[[
    建立含常用元件、調色盤及介面設定的完整示範視窗。

    @param self 要操作的目前實例；由冒號呼叫自動傳入。
    @param Options 此元件的建立選項；省略的欄位採用預設值。
    @return 已建立完整示範元件的視窗。

    使用範例：
    前提：Library 為本模組回傳值，且程式在 Rbx 用戶端執行。
    ```lua
    local Window = Library:Demo({ ConfigId = "Demo", bAnimations = false })
    Window:Destroy() -- 示範視窗與事件一起清理
    ```
]]
function Library.Demo(self: LibraryType, Options: WindowOptions?): CWindowType
    local Settings2 = _CopyTable(Options or {})
    Settings2.Name = Settings2.Name or "控制中心"
    Settings2.ConfigId = Settings2.ConfigId or "BjzUiDemo"
    local Window = self:CreateWindow(Settings2)
    local Page = Window:CreateTab({
        Name = "常用組件",
        Icon = "grid",
        Subtabs = { "表單與操作", "色彩與回饋" },
    })
    local Buttons = Page:CreateSection({ Name = "按鈕", Side = "left", Subtab = 1 })
    Buttons:CreateButton({
        Name = "儲存設定",
        --[[
            示範保存設定，並以通知呈現成功或錯誤結果。
        ]]
        Callback = function(): ()
            local bOk, Err = Window:SaveConfiguration()
            Window:Notify({ Title = bOk and "已儲存" or "儲存失敗", Content = Err })
        end,
    })
    Buttons:CreateButton({
        Name = "次要按鈕",
        Style = "secondary",
        --[[
            示範次要按鈕的點擊回呼與通知。
        ]]
        Callback = function(): ()
            Window:Notify({ Title = "按鈕", Content = "Callback 已執行" })
        end,
    })
    Buttons:CreateButton({ Name = "外框按鈕", Style = "outline" })
    Buttons:CreateButton({ Name = "停用按鈕", bEnabled = false })
    local Form = Page:CreateSection({ Name = "輸入與選擇", Side = "right", Subtab = 1 })
    Form:CreateInput({ Name = "名稱", CurrentValue = "我的專案", Flag = "projectName" })
    Form:CreateDropdown({
        Name = "分類",
        Options = { "一般", "工作", "個人", { Name = "封存", Value = "archive", bDisabled = true } },
        CurrentOption = "一般",
        Flag = "category",
    })
    Form:CreateDropdown({
        Name = "多選標籤",
        Options = { "實用", "輕量", "常用", "工具" },
        CurrentOption = { "實用", "輕量" },
        bMulti = true,
        Flag = "tags",
    })
    local Switches = Page:CreateSection({ Name = "開關與滑桿", Side = "left", Subtab = 1 })
    Switches:CreateToggle({
        Name = "自動儲存",
        bCurrentValue = true,
        Flag = "autosaveDemo",
        Description = "示範開關的啟用狀態",
    })
    Switches:CreateToggle({ Name = "推播通知", bCurrentValue = false, Flag = "notifications" })
    Switches:CreateSlider({
        Name = "音量",
        Range = { 0, 100 },
        Suffix = "%",
        CurrentValue = 65,
        Flag = "volume",
    })
    Switches:CreateCheckbox({ Name = "接收產品更新資訊", bCurrentValue = true, Flag = "updates" })
    local More = Page:CreateSection({ Name = "快捷鍵與單選", Side = "right", Subtab = 1 })
    More:CreateKeybind({
        Name = "測試通知",
        CurrentKeybind = Enum.KeyCode.Q,
        Flag = "notifyKey",
        --[[
            示範快捷鍵觸發通知。
        ]]
        Callback = function(): ()
            Window:Notify({ Title = "快捷鍵", Content = "已觸發測試通知" })
        end,
    })
    More:CreateRadioGroup({
        Name = "顯示密度",
        Options = { "標準", "舒適" },
        CurrentOption = "標準",
        Flag = "densityDemo",
    })
    local Palette = Page:CreateSection({ Name = "調色盤", Side = "full", Subtab = 2 })
    Palette:CreateColorPicker({
        Name = "主題顏色",
        Color = Window.Theme.Accent,
        Alpha = 1,
        bExpanded = true,
        bSave = false,
        --[[
            將示範調色盤的顏色套用為視窗強調色。

            @param Color 使用者在示範調色盤選取的 Color3。
        ]]
        Callback = function(Color: Color3): ()
            Window:SetAccent(Color)
        end,
    })
    local Feedback = Page:CreateSection({ Name = "狀態與回饋", Side = "left", Subtab = 2 })
    Feedback:CreateBadge({ Name = "操作成功", Status = "success" })
    Feedback:CreateBadge({ Name = "處理中", Status = "warning" })
    Feedback:CreateBadge({ Name = "發生錯誤", Status = "error" })
    Feedback:CreateProgress({ Name = "處理進度", CurrentValue = 72 })
    local Small = Page:CreateSection({ Name = "其他常用組件", Side = "right", Subtab = 2 })
    Small:CreateColorPicker({
        Name = "精簡調色盤",
        Color = Color3.fromRGB(103, 182, 246),
        Alpha = 1,
        Flag = "smallColor",
    })
    Small:CreateParagraph({
        Title = "使用方式",
        Content = "點擊色塊開啟調色盤。支援滑鼠、觸控、HEX、RGB 與透明度。",
    })
    Small:CreateDivider()
    Small:CreateLabel({ Name = "RightShift 縮小／還原視窗", Icon = "zap" })
    local Settings = Window:CreateTab("設定", "settings")
    Window:CreateCursorSettings(Settings:CreateSection({ Name = "專屬游標", Side = "full" }))
    local Appearance = Settings:CreateSection({ Name = "介面偏好", Side = "full" })
    Appearance:CreateSlider({
        Name = "介面縮放",
        Range = { 0.65, 1.5 },
        Increment = 0.05,
        CurrentValue = Window.Scale,
        bSave = false,
        --[[
            將示範縮放滑桿的值套用到視窗。

            @param Scale 介面縮放比例，會限制到 0.65 至 1.5。
        ]]
        Callback = function(Scale: number): ()
            Window:SetScale(Scale)
        end,
    })
    Appearance:CreateToggle({
        Name = "短動畫",
        bCurrentValue = Window.bAnimations,
        bSave = false,
        --[[
            以示範開關控制視窗動畫。

            @param bEnabled true 啟用此行為；false 停用。
        ]]
        Callback = function(bEnabled: boolean): ()
            Window:SetAnimations(bEnabled)
        end,
    })
    Appearance:CreateParagraph({
        Title = "設定保存",
        Content = "檔案：workspace/BjzUi/UiConfig.json。每個 ConfigId 使用獨立分組；停止操作 1.5 秒後自動儲存。",
    })
    return Window
end

--[[
    透過模組建立視窗；同 ConfigId 的舊視窗會先銷毀。
    @param self 管理視窗與 Flag 的模組入口。
    @param Options 視窗選項；nil 使用預設值。
    @return 完成初始化的視窗實例。

    使用範例：
    前提：Library 為本模組回傳值。
    ```lua
    local Window = Library:CreateWindow({ Name = "控制中心", ConfigId = "Main", bResizable = true })
    Window:Destroy()
    ```
]]
function Library.CreateWindow(self: LibraryType, Options: WindowOptions?): CWindowType
    return CWindow.new(self, Options)
end

--[[
    為視窗建立導覽分頁與可選子分頁；重複名稱會拋出錯誤。
    @param self 新分頁所屬視窗。
    @param Name 名稱或包含 Name、Icon、Subtabs 的選項表。
    @param IconName 內建圖示名或 asset ID；Name 為選項表時忽略。
    @param Subtabs 子分頁名稱陣列；省略時建立一般頁面。
    @return 已加入視窗的主分頁實例。

    使用範例：
    前提：Window 由 Library:CreateWindow 建立。
    ```lua
    local Tab = Window:CreateTab("設定", "settings", { "一般", "外觀" })
    Tab:SelectSubtab("外觀")
    ```
]]
function CWindow.CreateTab(
    self: CWindowType,
    Name: string | TabOptions?,
    IconName: string | number?,
    Subtabs: { string }?
): CTabType
    return CTab.new(self, Name, IconName, Subtabs)
end

--[[
    在指定子分頁與欄位建立元件區塊。
    @param self 新區塊所屬主分頁。
    @param Options 區塊選項或名稱；Height 會啟用固定高度的捲動內容。
    @return 已加入分頁的區塊實例。

    使用範例：
    前提：Tab 由 Window:CreateTab 建立。
    ```lua
    local Section = Tab:CreateSection({ Name = "設定", Side = "right", Height = 190 })
    Section:CreateCheckbox({ Name = "啟用", bCurrentValue = true })
    ```
]]
function CTab.CreateSection(self: CTabType, Options: SectionOptions | string?): CSectionType
    return CSection.new(self, Options)
end

--[[
    為具體元件工廠建立控制項基底，並註冊其 Flag。
    @param self 控制項所屬區塊。
    @param Settings 共用控制項選項或名稱。
    @param Kind 元件種類。
    @param Height 初始邏輯高度；nil 使用 34。
    @return 待具體工廠完成顯示與行為的控制項。
]]
function CSection._Control(
    self: CSectionType,
    Settings: BaseControlOptions | string,
    Kind: EControlKind,
    Height: number?
): CControlType
    return CControl.new(self, Settings, Kind, Height)
end

return Library

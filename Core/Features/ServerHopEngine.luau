--[[
	通用公開服搜尋引擎；依賴由入口注入，不建立 UI 或背景工作。
	清單人數是查詢快照，無法保證加入時仍無其他玩家。
]]

local CServerHopEngine = { Version = "1.0.0" }
CServerHopEngine.__index = CServerHopEngine

export type Server = { id: string, playing: number, maxPlayers: number }
export type Page = { data: { Server }, nextPageCursor: string? }
export type Options = { MaxPlayers: number?, MaxPages: number?, MaxAttempts: number? }
export type Services = {
	PlaceId: number,
	JobId: string,
	Player: Player,
	TeleportService: TeleportService,
	Request: ({ Url: string, Method: string }) -> { StatusCode: number, Body: string, Headers: { [string]: string }? },
	Decode: (string) -> Page,
	Encode: (string) -> string,
	Wait: (number) -> (),
	Clock: () -> number,
	Report: (string) -> (),
}

--[[
	實例私有狀態；Pending 保留至收到明確失敗，避免重複發出未決傳送。
]]
export type CServerHopEngineType = typeof(setmetatable(
	{} :: {
		_Services: Services,
		_Visited: { [string]: boolean },
		_Connection: RBXScriptConnection?,
		_bBusy: boolean,
		_bCancelled: boolean,
		_bDestroyed: boolean,
		_bPending: boolean,
	},
	CServerHopEngine
))

--[[
	正規化有限整數設定。
	@param Value 輸入值，非法值採用預設。
	@param Default 預設整數。
	@param Minimum 最小整數。
	@param Maximum 最大整數。
	@return 範圍內整數。
]]
local function _Limit(Value: number?, Default: number, Minimum: number, Maximum: number): number
	if type(Value) ~= "number" or Value ~= Value or math.abs(Value) == math.huge then
		return Default
	end
	return math.clamp(math.floor(Value), Minimum, Maximum)
end

--[[
	建立搜尋器，不會立即搜尋或傳送。
	@param Dependencies 目前 PlaceId 與入口提供的能力。
	@return 獨立記錄已嘗試伺服器的搜尋器。
]]
function CServerHopEngine.new(Dependencies: Services): CServerHopEngineType
	assert(type(Dependencies.Request) == "function", "缺少 request，無法查詢伺服器")
	return setmetatable(
		{
			_Services = Dependencies,
			_Visited = {},
			_Connection = nil,
			_bBusy = false,
			_bCancelled = false,
			_bDestroyed = false,
			_bPending = false,
		},
		CServerHopEngine
	)
end

--[[
	發送狀態，隔離 UI 回呼錯誤。
	@param self 目前搜尋器。
	@param Message 顯示文字。
]]
function CServerHopEngine._Report(self: CServerHopEngineType, Message: string): ()
	if not self._bDestroyed then
		pcall(self._Services.Report, Message)
	end
end

--[[
	解除自己持有的事件。
	@param self 目前搜尋器。
]]
function CServerHopEngine._Disconnect(self: CServerHopEngineType): ()
	if self._Connection then
		self._Connection:Disconnect()
		self._Connection = nil
	end
end

--[[
	可取消的短間隔等待，會 yield。
	@param self 目前搜尋器。
	@param Seconds 最多等待秒數。
	@return true 表示等待完成；false 表示取消或卸載。
]]
function CServerHopEngine._Wait(self: CServerHopEngineType, Seconds: number): boolean
	local Services = self._Services
	local Deadline = Services.Clock() + Seconds
	while not self._bCancelled and not self._bDestroyed and Services.Clock() < Deadline do
		Services.Wait(math.min(0.1, Deadline - Services.Clock()))
	end
	return not self._bCancelled and not self._bDestroyed
end

--[[
	讀取分頁，網路錯誤、429、5xx 最多重試兩次；JSON 錯誤直接回報。
	@param self 目前搜尋器。
	@param Url Rbx 官方查詢網址。
	@return 格式經檢查的分頁，失敗時拋出錯誤。
]]
function CServerHopEngine._Fetch(self: CServerHopEngineType, Url: string): Page
	for Attempt = 1, 3 do
		if self._bCancelled or self._bDestroyed then
			error("已取消", 0)
		end
		local bOk, Response = pcall(self._Services.Request, { Url = Url, Method = "GET" })
		if self._bCancelled or self._bDestroyed then
			error("已取消", 0)
		end
		local Status = if bOk and type(Response) == "table" then Response.StatusCode else nil
		if Status == 200 then
			assert(type(Response.Body) == "string", "API 缺少回應內容")
			local Data = self._Services.Decode(Response.Body)
			assert(type(Data) == "table" and type(Data.data) == "table", "API 分頁格式錯誤")
			assert(Data.nextPageCursor == nil or type(Data.nextPageCursor) == "string", "API 游標格式錯誤")
			return Data
		end
		local Reason = if Status then "HTTP " .. tostring(Status) else "request 失敗：" .. tostring(Response)
		local bRetryable = not bOk or (type(Status) == "number" and (Status == 429 or (Status >= 500 and Status < 600)))
		if not bRetryable or Attempt == 3 then
			error(Reason, 0)
		end
		local Delay = 2 ^ Attempt
		if type(Response) == "table" and type(Response.Headers) == "table" then
			for Key, Value in pairs(Response.Headers) do
				if type(Key) == "string" and string.lower(Key) == "retry-after" then
					Delay = _Limit(tonumber(Value), Delay, 1, 30)
				end
			end
		end
		self:_Report(Reason .. "，" .. tostring(Delay) .. " 秒後重試")
		if not self:_Wait(Delay) then
			error("已取消", 0)
		end
	end
	error("查詢未完成", 0)
end

--[[
	掃描有界分頁，過濾本服、滿服、重複及已嘗試服，依人數排序。
	@param self 目前搜尋器。
	@param MaxPlayers 加入前人數上限；0 僅接受空服。
	@param MaxPages 掃描頁數上限，每頁最多 100 筆。
	@return 掃描範圍內的合格伺服器，不保證是全球人數最少。
]]
function CServerHopEngine._Find(self: CServerHopEngineType, MaxPlayers: number, MaxPages: number): { Server }
	local Services = self._Services
	local Servers, Seen, Cursors = {}, {}, {}
	local Cursor = nil
	for PageIndex = 1, MaxPages do
		self:_Report("搜尋公開服：第 " .. tostring(PageIndex) .. " 頁")
		local Url = "https://games.roblox.com/v1/games/"
			.. tostring(Services.PlaceId)
			.. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
		if Cursor then
			Url ..= "&cursor=" .. Services.Encode(Cursor)
		end
		local Data = self:_Fetch(Url)
		for _, Server in ipairs(Data.data) do
			if
				type(Server) == "table"
				and type(Server.id) == "string"
				and Server.id ~= ""
				and type(Server.playing) == "number"
				and Server.playing >= 0
				and Server.playing % 1 == 0
				and type(Server.maxPlayers) == "number"
				and Server.maxPlayers > Server.playing
				and Server.playing <= MaxPlayers
				and Server.id ~= Services.JobId
				and not Seen[Server.id]
				and not self._Visited[Server.id]
			then
				Seen[Server.id] = true
				table.insert(Servers, Server)
			end
		end
		Cursor = Data.nextPageCursor
		if not Cursor or Cursor == "" or Cursors[Cursor] then
			break
		end
		Cursors[Cursor] = true
		if PageIndex < MaxPages and not self:_Wait(0.5) then
			break
		end
	end
	--[[
		相同人數使用 ID 決定順序。
		@param Left 左側候選。
		@param Right 右側候選。
		@return true 表示左側優先，false 表示右側優先。
	]]
	table.sort(Servers, function(Left, Right)
		return Left.playing < Right.playing or (Left.playing == Right.playing and Left.id < Right.id)
	end)
	return Servers
end

--[[
	發出一次傳送，等待明確失敗；未決狀態不自動重複傳送。
	@param self 目前搜尋器。
	@param Server 合格候選，其人數可能已變動。
	@return true 表示仍待 Rbx 處理；false 表示明確失敗。
]]
function CServerHopEngine._Teleport(self: CServerHopEngineType, Server: Server): boolean
	local Services = self._Services
	local bFailed = false
	self:_Disconnect()
	--[[
		僅處理可確認目標的失敗，避免其他腳本的傳送觸發重試。
		@param Player 失敗的玩家。
		@param Result Rbx 錯誤代碼。
		@param Message 錯誤說明。
		@param PlaceId 目的 PlaceId。
		@param TeleportOptions 重試選項；缺少時無法確認本次目標，保守保留 Pending。
	]]
	self._Connection = Services.TeleportService.TeleportInitFailed:Connect(
		function(Player, Result, Message, PlaceId, TeleportOptions)
			if
				Player == Services.Player
				and PlaceId == Services.PlaceId
				and TeleportOptions
				and TeleportOptions.ServerInstanceId == Server.id
			then
				bFailed = true
				self._bPending = false
				self:_Report("換服失敗：" .. tostring(Result) .. " " .. tostring(Message))
				self:_Disconnect()
			end
		end
	)
	self._Visited[Server.id] = true
	self._bPending = true
	self:_Report("正在加入 " .. tostring(Server.playing) .. " 人服：" .. Server.id)
	if self._bCancelled or self._bDestroyed then
		self._bPending = false
		self:_Disconnect()
		return false
	end
	local bOk, Reason = pcall(
		Services.TeleportService.TeleportToPlaceInstance,
		Services.TeleportService,
		Services.PlaceId,
		Server.id,
		Services.Player
	)
	if not bOk then
		self._bPending = false
		self:_Disconnect()
		self:_Report("傳送呼叫失敗：" .. tostring(Reason))
		return false
	end
	local Deadline = Services.Clock() + 15
	while not bFailed and not self._bCancelled and not self._bDestroyed and Services.Clock() < Deadline do
		Services.Wait(0.1)
	end
	-- 未決傳送保留唯一監聽，晚到的明確失敗仍能解除 Pending。
	return not bFailed
end

--[[
	執行會 yield 的搜尋與換服；拒絕重入，任何失敗都釋放 Busy。
	@param self 目前搜尋器。
	@param Settings 預設最多 10 人、5 頁、5 次傳送；硬上限為 100 人、20 頁、10 次。
	@return Pending、NotFound、Failed、Cancelled、Busy 或 Destroyed 結果代碼。
	@return 可顯示的說明；Pending 不表示已成功抵達。

	使用範例：
	```lua
	-- Engine 已透過 new(Dependencies) 初始化；呼叫本函數會 yield。
	local Code, Message = Engine:Run({ MaxPlayers = 0 })
	print(Code, Message) -- 無空服時回傳 NotFound，不放寬條件。
	```
]]
function CServerHopEngine.Run(self: CServerHopEngineType, Settings: Options?): (string, string)
	if self._bDestroyed then
		return "Destroyed", "搜尋器已卸載"
	end
	if self._bBusy or self._bPending then
		return "Busy", "仍在處理或等待 Rbx 傳送結果"
	end
	self._bBusy, self._bCancelled = true, false
	local Config = Settings or {}
	--[[
		保護外部能力邊界，確保例外後可清理及再次搜尋。
		@return 流程結果代碼。
		@return 結果說明。
	]]
	local bOk, Code, Message = pcall(function()
		local Servers = self:_Find(_Limit(Config.MaxPlayers, 10, 0, 100), _Limit(Config.MaxPages, 5, 1, 20))
		if #Servers == 0 then
			return "NotFound", "掃描範圍內沒有符合人數上限的其他公開服"
		end
		for Index = 1, math.min(#Servers, _Limit(Config.MaxAttempts, 5, 1, 10)) do
			if self._bCancelled or self._bDestroyed then
				break
			end
			if self:_Teleport(Servers[Index]) then
				return "Pending", "請求已送出，等待 Rbx；尚未確認抵達"
			end
			if not self:_Wait(2) then
				break
			end
		end
		return "Failed", "本次候選皆無法加入"
	end)
	self._bBusy = false
	if not bOk then
		self:_Disconnect()
	end
	if self._bCancelled or self._bDestroyed then
		return "Cancelled", "已停止後續操作；已送出的傳送無法撤回"
	end
	if not bOk then
		return "Failed", tostring(Code)
	end
	return Code, Message
end

--[[
	停止後續搜尋與重試，不撤回已送出的 HTTP 或傳送；未決傳送仍拒絕重入。
	@param self 目前搜尋器。
]]
function CServerHopEngine.Cancel(self: CServerHopEngineType): ()
	self._bCancelled = true
	self:_Report("已取消後續操作；已送出的傳送無法撤回")
end

--[[
	可重複卸載，解除唯一持有的連線，yield 中工作返回後不再發送請求。
	@param self 要卸載的搜尋器。
]]
function CServerHopEngine.Destroy(self: CServerHopEngineType): ()
	self._bDestroyed, self._bCancelled = true, true
	self:_Disconnect()
end

return CServerHopEngine

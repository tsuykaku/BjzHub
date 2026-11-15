print("載入包莖澤Library v0.45")

local TweenService = game:GetService("TweenService")

function RandomGUIName()
	local res = ""
	for i = 1, math.random(5, 20) do
		local string = {
			string.char(math.random(48, 57)),
			string.char(math.random(65, 90)),
			string.char(math.random(97, 122)),
		}
		res = res .. string[math.random(#string)]
	end
	return res
end

local Mainlib = {}

function Mainlib:MainFrame(GuiTitle, SubGuiTitle)
	local FirstTab = false
	local GuiTitle = GuiTitle or "包莖澤 GUI"
	local SubGuiTitle = SubGuiTitle or "Powered by 包莖澤GUI"
	-- Instances:
	local Window = Instance.new("ScreenGui")
	local MainFrame = Instance.new("Frame")
	local UIGradient = Instance.new("UIGradient")
	local UICorner = Instance.new("UICorner")
	local SubFrame = Instance.new("Frame")
	local UIGradient_2 = Instance.new("UIGradient")
	local ScrollingFrameFolder = Instance.new("Folder")
	local TabFrame = Instance.new("Frame")
	local UIGridLayout = Instance.new("UIGridLayout")
	local MainTitle = Instance.new("TextLabel")
	local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
	local SubTitle = Instance.new("TextLabel")

	--Properties:

	Window.Name = RandomGUIName()
	Window.Parent = game:GetService("CoreGui")
	Window.ResetOnSpawn = false

	MainFrame.Name = "MainFrame"
	MainFrame.Parent = Window
	MainFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
	MainFrame.BorderSizePixel = 0
	MainFrame.Position = UDim2.new(0.1, 0, 0.6, 0)
	MainFrame.Size = UDim2.new(0, 562, 0, 437)
	MainFrame.ClipsDescendants = true
	MainFrame.AnchorPoint = Vector2.new(0, 0)

	UIGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(45, 53, 63)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(80, 80, 81)),
	})
	UIGradient.Rotation = 25
	UIGradient.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0.00, 0.02), NumberSequenceKeypoint.new(1.00, 0.02) })
	UIGradient.Parent = MainFrame

	UICorner.CornerRadius = UDim.new(0, 3)
	UICorner.Parent = MainFrame

	SubFrame.Name = "SubFrame"
	SubFrame.Parent = MainFrame
	SubFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SubFrame.BackgroundTransparency = 0.200
	SubFrame.BorderColor3 = Color3.fromRGB(27, 42, 53)
	SubFrame.BorderSizePixel = 0
	SubFrame.Position = UDim2.new(0, 127, 0, 76)
	SubFrame.Size = UDim2.new(0.764, 0, 0.811, 0)

	UIGradient_2.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0.00, Color3.fromRGB(22, 22, 24)),
		ColorSequenceKeypoint.new(1.00, Color3.fromRGB(27, 28, 33)),
	})
	UIGradient_2.Rotation = 25
	UIGradient_2.Transparency =
		NumberSequence.new({ NumberSequenceKeypoint.new(0.00, 0.05), NumberSequenceKeypoint.new(1.00, 0.05) })
	UIGradient_2.Parent = SubFrame

	ScrollingFrameFolder.Name = "ScrollingFrameFolder"
	ScrollingFrameFolder.Parent = MainFrame

	TabFrame.Name = "TabFrame"
	TabFrame.Parent = MainFrame
	TabFrame.BackgroundColor3 = Color3.fromRGB(29, 29, 29)
	TabFrame.BackgroundTransparency = 0.500
	TabFrame.BorderSizePixel = 0
	TabFrame.Position = UDim2.new(0, 3, 0, 76)
	TabFrame.Size = UDim2.new(0, 123, 0, 354)

	UIGridLayout.Parent = TabFrame
	UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	UIGridLayout.CellPadding = UDim2.new(0, 5, 0, 0)
	UIGridLayout.CellSize = UDim2.new(0, 123, 0, 40)

	MainTitle.Name = "MainTitle"
	MainTitle.Parent = MainFrame
	MainTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	MainTitle.BackgroundTransparency = 1.000
	MainTitle.BorderSizePixel = 0
	MainTitle.Position = UDim2.new(0, 9, 0, 6)
	MainTitle.Size = UDim2.new(0, 117, 0, 43)
	MainTitle.Font = Enum.Font.Jura
	MainTitle.Text = GuiTitle
	MainTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	MainTitle.TextScaled = true
	MainTitle.TextSize = 14.000
	MainTitle.TextWrapped = true

	UITextSizeConstraint.Parent = MainTitle
	UITextSizeConstraint.MaxTextSize = 57

	SubTitle.Name = "SubTitle"
	SubTitle.Parent = MainFrame
	SubTitle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	SubTitle.BackgroundTransparency = 1.000
	SubTitle.BorderSizePixel = 0
	SubTitle.Position = UDim2.new(0, 6, 0, 49)
	SubTitle.Size = UDim2.new(0, 117, 0, 27)
	SubTitle.Font = Enum.Font.Jura
	SubTitle.Text = SubGuiTitle
	SubTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	SubTitle.TextScaled = true
	SubTitle.TextSize = 14.000
	SubTitle.TextWrapped = true

	--[拖移
	local UserInputService = game:GetService("UserInputService")

	local frame = MainFrame

	local dragging
	local dragInput
	local dragStart
	local startPos

	local function update(input)
		local delta = input.Position - dragStart
		frame.Position =
			UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end

	frame.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	frame.InputChanged:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
	--拖移]

	local InsideLibrary = {}

	function InsideLibrary:ZoomWindow(callback)
		local Fulled = false
		local debounce = false
		local actions = {}
		callback = callback or function(Fulled) end
		-- Instances:

		local SmallWindow = Instance.new("ImageButton")
		local FullWindow = Instance.new("ImageButton")
		--Properties:

		SmallWindow.Name = "SmallWindow"
		SmallWindow.Parent = MainFrame
		SmallWindow.BackgroundTransparency = 1.000
		SmallWindow.Position = UDim2.new(0, 154, 0, 37)
		SmallWindow.Rotation = 180.000
		SmallWindow.Size = UDim2.new(0, 25, 0, 25)
		SmallWindow.Visible = true
		SmallWindow.ZIndex = 1
		SmallWindow.Image = "rbxassetid://3926305904"
		SmallWindow.ImageRectOffset = Vector2.new(44, 164)
		SmallWindow.ImageRectSize = Vector2.new(36, 36)
		SmallWindow.AnchorPoint = Vector2.new(0.5, 0.5)

		FullWindow.Name = "FullWindow"
		FullWindow.Parent = MainFrame
		FullWindow.BackgroundTransparency = 1.000
		FullWindow.Position = UDim2.new(0, 154, 0, 37)
		FullWindow.Size = UDim2.new(0, 25, 0, 25)
		FullWindow.Visible = false
		FullWindow.ZIndex = 1
		FullWindow.Image = "rbxassetid://3926305904"
		FullWindow.ImageRectOffset = Vector2.new(724, 724)
		FullWindow.ImageRectSize = Vector2.new(36, 36)
		FullWindow.AnchorPoint = Vector2.new(0.5, 0.5)

		local function Fire()
			if debounce == false then
				debounce = true
				Fulled = not Fulled
				TweenService:Create(
					MainFrame,
					TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ Size = Fulled and UDim2.new(0, 180, 0, 75) or UDim2.new(0, 562, 0, 437) }
				):Play()
				TweenService:Create(
					SmallWindow,
					TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ ImageTransparency = Fulled and 1 or 0 }
				):Play()
				TweenService:Create(
					FullWindow,
					TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
					{ ImageTransparency = Fulled and 0 or 1 }
				):Play()
				SmallWindow.Visible = Fulled and false or true
				FullWindow.Visible = Fulled and true or false
				wait(0.25)
				debounce = false
				pcall(callback, Fulled)
			end
		end

		SmallWindow.MouseButton1Up:Connect(function()
			Fire()
		end)

		FullWindow.MouseButton1Up:Connect(function()
			Fire()
		end)

		SmallWindow.MouseEnter:Connect(function()
			TweenService:Create(
				SmallWindow,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 30, 0, 30) },
				{ ImageRectSize = UDim2.new(0, 34, 0, 34) }
			):Play()
		end)

		SmallWindow.MouseLeave:Connect(function()
			TweenService:Create(
				SmallWindow,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 25, 0, 25) },
				{ ImageRectSize = Vector2.new(36, 36) }
			):Play()
		end)

		FullWindow.MouseEnter:Connect(function()
			TweenService:Create(
				FullWindow,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 30, 0, 30) },
				{ ImageRectSize = UDim2.new(0, 34, 0, 34) }
			):Play()
		end)

		FullWindow.MouseLeave:Connect(function()
			TweenService:Create(
				FullWindow,
				TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(0, 25, 0, 25) },
				{ ImageRectSize = Vector2.new(36, 36) }
			):Play()
		end)

		function actions:Set(arg)
			if arg == true then
				Fire()
			end
		end

		-- FullWindow.MouseButton1Up:Connect(function()
		--     if FullWindow == false then
		--         TweenService:Create(
		--             MainFrame,
		--             TweenInfo.new(.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		--             {Size = UDim2.new(0, 562, 0, 437)}
		--         ):Play()
		--     end
		-- end)
		return actions
	end

	--[創建分頁的函數
	function InsideLibrary:Tab(TabButtonName)
		--Properties:
		local TabButton = Instance.new("TextButton")
		local UICorner = Instance.new("UICorner")
		local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
		local SubScrollingFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local UIPadding = Instance.new("UIPadding")
		local UIStroke = Instance.new("UIStroke")

		TabButton.Name = TabButtonName .. "_TabButton"
		TabButton.Parent = TabFrame
		TabButton.BackgroundColor3 = Color3.fromRGB(98, 94, 124)
		TabButton.BackgroundTransparency = 1.000
		TabButton.BorderSizePixel = 0
		TabButton.Position = UDim2.new(0, 0, -0.00030732248, 0)
		TabButton.Size = UDim2.new(0.999999881, 0, 0.114881098, 0)
		TabButton.ZIndex = 1
		TabButton.Font = Enum.Font.Jura
		TabButton.Text = TabButtonName
		TabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		TabButton.TextScaled = true
		TabButton.TextSize = 14.000
		TabButton.TextWrapped = true
		TabButton.AutoButtonColor = false
		TabButton.TextTransparency = 0.4

		--[變數
		local selected = Instance.new("BoolValue")
		selected.Name = "selected"
		selected.Parent = TabFrame:WaitForChild(TabButtonName .. "_TabButton")
		selected.Value = false
		--變數]

		UICorner.CornerRadius = UDim.new(0, 3)
		UICorner.Parent = TabButton

		UITextSizeConstraint.Parent = TabButton
		UITextSizeConstraint.MaxTextSize = 30

		SubScrollingFrame.Name = TabButtonName .. "_SubScrollingFrame"
		SubScrollingFrame.Parent = ScrollingFrameFolder
		SubScrollingFrame.Active = true
		SubScrollingFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		SubScrollingFrame.BackgroundTransparency = 1.000
		SubScrollingFrame.BorderSizePixel = 0
		SubScrollingFrame.Position = UDim2.new(0, 129, 0, 85)
		SubScrollingFrame.Size = UDim2.new(0, 427, 0, 338)
		SubScrollingFrame.ScrollBarThickness = 5
		SubScrollingFrame.Visible = false
		SubScrollingFrame.AutomaticCanvasSize = 2

		UIListLayout.Parent = SubScrollingFrame
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 8)

		UIStroke.Parent = TabButton
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		UIStroke.Color = Color3.fromRGB(170, 170, 255)
		UIStroke.Thickness = 2
		UIStroke.Transparency = 1

		UIPadding.PaddingTop = UDim.new(0, 5)
		UIPadding.Parent = SubScrollingFrame

		if FirstTab == false then
			selected.Value = true
			FirstTab = true
			SubScrollingFrame.Visible = true
			TabButton.BackgroundTransparency = 0
			TabButton.TextTransparency = 0
		end

		TabButton.MouseEnter:Connect(function()
			if selected.Value == false then
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 0.5 }
				):Play()
				TweenService:Create(
					TabButton,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0 }
				):Play()
				TweenService:Create(
					TabButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundTransparency = 0.7 }
				):Play()
			end
		end)

		TabButton.MouseLeave:Connect(function()
			if selected.Value == false then
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
				TweenService:Create(
					TabButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundTransparency = 1 }
				):Play()
				TweenService:Create(
					TabButton,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0.4 }
				):Play()
			end
		end)

		TabButton.MouseButton1Click:Connect(function()
			for i, v in next, ScrollingFrameFolder:GetChildren() do
				v.Visible = false
			end
			for i, v in next, TabFrame:GetChildren() do
				if v:IsA("TextButton") then
					TweenService:Create(
						v,
						TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ BackgroundTransparency = 1 }
					):Play()
					TweenService:Create(
						v.UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1 }
					):Play()
					v.ZIndex = 2
					v.TextTransparency = 0.4
					v.selected.Value = false
				end
			end

			SubScrollingFrame.Visible = true
			TabButton.ZIndex = 1
			TabButton.TextTransparency = 0
			selected.Value = true

			TweenService:Create(
				TabButton,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0 }
			):Play()
			TweenService
				:Create(
					UIStroke,
					TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 0 }
				)
				:Play()
		end)

		local functionLibrary = {}
		----------[創建「切換按鈕」的函數
		function functionLibrary:Toggle(FunctionName, callback)
			callback = callback or function(toggled) end
			FunctionName = FunctionName or "切換功能的名稱"
			local toggled = false
			local debounce = false
			local actions = {}
			--Instances:
			local ToggleFrame = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local UIGradient = Instance.new("UIGradient")
			local ToggleName = Instance.new("TextLabel")
			local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
			local ToggleButton = Instance.new("ImageButton")
			local UICorner_2 = Instance.new("UICorner")
			local UIStroke = Instance.new("UIStroke")

			--Properties:
			ToggleFrame.Name = "ToggleFrame"
			ToggleFrame.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			ToggleFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ToggleFrame.BorderSizePixel = 0
			ToggleFrame.Position = UDim2.new(0.040646553, 0, 0.0119453464, 0)
			ToggleFrame.Size = UDim2.new(0, 391, 0, 36)

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = ToggleFrame

			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(76, 90, 108)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(79, 95, 112)),
			})
			UIGradient.Rotation = 25
			UIGradient.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0.00, 0.50), NumberSequenceKeypoint.new(1.00, 0.50) })
			UIGradient.Parent = ToggleFrame

			ToggleName.Name = "ToggleName"
			ToggleName.Parent = ToggleFrame
			ToggleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ToggleName.BackgroundTransparency = 1.000
			ToggleName.BorderSizePixel = 0
			ToggleName.Position = UDim2.new(0.0299999993, 0, 0.150000006, 0)
			ToggleName.Size = UDim2.new(0.732013166, 0, 0.726040721, 0)
			ToggleName.Font = Enum.Font.Code
			ToggleName.Text = FunctionName
			ToggleName.TextColor3 = Color3.fromRGB(255, 255, 255)
			ToggleName.TextScaled = true
			ToggleName.TextSize = 14.000
			ToggleName.TextWrapped = true
			ToggleName.TextXAlignment = Enum.TextXAlignment.Left
			ToggleName.TextTransparency = 0.4

			UITextSizeConstraint.Parent = ToggleName
			UITextSizeConstraint.MaxTextSize = 57

			ToggleButton.Name = "ToggleButton"
			ToggleButton.Parent = ToggleFrame
			ToggleButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
			ToggleButton.Position = UDim2.new(0.899999976, 0, 0.150000006, 0)
			ToggleButton.Size = UDim2.new(0, 25, 0, 25)
			ToggleButton.ZIndex = 2
			ToggleButton.Image = "rbxassetid://3926311105"
			ToggleButton.ImageColor3 = Color3.fromRGB(0, 170, 0)
			ToggleButton.ImageRectOffset = Vector2.new(4, 836)
			ToggleButton.ImageRectSize = Vector2.new(48, 48)
			ToggleButton.ImageTransparency = 1
			ToggleButton.AutoButtonColor = false

			UICorner_2.CornerRadius = UDim.new(0, 5)
			UICorner_2.Parent = ToggleButton

			UIStroke.Parent = ToggleFrame
			UIStroke.Color = Color3.fromRGB(170, 170, 255)
			UIStroke.Thickness = 2
			UIStroke.Transparency = 1

			ToggleFrame.MouseEnter:Connect(function()
				if toggled == false then
					TweenService:Create(
						ToggleName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0 }
					):Play()
					TweenService:Create(
						ToggleButton,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ ImageTransparency = 0.8 }
					):Play()
					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 0 }
					):Play()
				end
			end)

			ToggleFrame.MouseLeave:Connect(function()
				if toggled == false then
					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1 }
					):Play()
					TweenService:Create(
						ToggleName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0.4 }
					):Play()
					TweenService:Create(
						ToggleButton,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ ImageTransparency = 1 }
					):Play()
				end
			end)

			local function Fire()
				if debounce == false then
					debounce = true
					toggled = not toggled
					TweenService:Create(
						ToggleButton,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ ImageTransparency = toggled and 0 or 1 }
					):Play()
					ToggleName.TextTransparency = toggled and 0
					UIStroke.Transparency = toggled and 0
					wait(0.25)
					debounce = false
					pcall(callback, toggled)
				end
			end

			function actions:Set(arg)
				if arg == true then
					Fire()
				end
			end

			local function inputBegan(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					Fire()
				end
			end
			ToggleFrame.InputBegan:Connect(inputBegan)

			ToggleButton.MouseButton1Click:Connect(Fire)

			return actions
		end
		----------創建「切換按鈕」的函數]

		----------[創建「滑條」的函數
		function functionLibrary:Slider(FunctionName, minvalue, maxvalue, callback)
			-----值-----
			minvalue = minvalue or 0
			maxvalue = maxvalue or 100

			-----回傳-----
			callback = callback or function() end

			-----變數-----
			local mouse = game:GetService("Players").LocalPlayer:GetMouse()
			local uis = game:GetService("UserInputService")
			local Value
			local sliderlength = 305
			local actions = {}

			-----實體-----
			local SliderFrame = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local UIGradient = Instance.new("UIGradient")
			local SliderName = Instance.new("TextLabel")
			local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
			local ToggleButtonBackground = Instance.new("ImageButton")
			local UICorner_2 = Instance.new("UICorner")
			local SliderButton = Instance.new("ImageButton")
			local UICorner_3 = Instance.new("UICorner")
			local SliderIn = Instance.new("Frame")
			local UICorner_4 = Instance.new("UICorner")
			local TextBox = Instance.new("TextBox")
			local UICorner_5 = Instance.new("UICorner")
			local UIStroke = Instance.new("UIStroke")
			local UIStroke_SliderButton = Instance.new("UIStroke")
			local UIStroke_TextBox = Instance.new("UIStroke")

			SliderFrame.Name = "SliderFrame"
			SliderFrame.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			SliderFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			SliderFrame.BorderSizePixel = 0
			SliderFrame.Position = UDim2.new(0.0406465307, 0, 0, 0)
			SliderFrame.Size = UDim2.new(0, 391, 0, 77)

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = SliderFrame

			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(46, 54, 65)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(59, 70, 83)),
			})
			UIGradient.Rotation = 25
			UIGradient.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0.00, 0.02), NumberSequenceKeypoint.new(1.00, 0.02) })
			UIGradient.Parent = SliderFrame

			SliderName.Name = "SliderName"
			SliderName.Parent = SliderFrame
			SliderName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			SliderName.BackgroundTransparency = 1.000
			SliderName.BorderSizePixel = 0
			SliderName.Position = UDim2.new(0.0299999993, 0, 0.150000006, 0)
			SliderName.Size = UDim2.new(0.731999993, 0, 0.332248867, 0)
			SliderName.Font = Enum.Font.Code
			SliderName.Text = FunctionName
			SliderName.TextColor3 = Color3.fromRGB(255, 255, 255)
			SliderName.TextScaled = true
			SliderName.TextSize = 14.000
			SliderName.TextWrapped = true
			SliderName.TextXAlignment = Enum.TextXAlignment.Left
			SliderName.TextTransparency = 0.4

			UITextSizeConstraint.Parent = SliderName
			UITextSizeConstraint.MaxTextSize = 57

			UICorner_2.CornerRadius = UDim.new(0, 20)
			UICorner_2.Parent = ToggleButtonBackground

			SliderButton.Name = "SliderButton"
			SliderButton.Parent = SliderFrame
			SliderButton.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
			SliderButton.BorderSizePixel = 0
			SliderButton.Position = UDim2.new(0.0299999993, 0, 0.670000017, 0)
			SliderButton.Size = UDim2.new(0.78, 0, 0.2, 0)
			SliderButton.AutoButtonColor = false
			SliderButton.ClipsDescendants = true

			UICorner_3.CornerRadius = UDim.new(0, 20)
			UICorner_3.Parent = SliderButton

			SliderIn.Name = "SliderIn"
			SliderIn.Parent = SliderButton
			SliderIn.BackgroundColor3 = Color3.fromRGB(170, 170, 255)
			SliderIn.Size = UDim2.new(0.02, 0, 1, 0)

			UICorner_4.CornerRadius = UDim.new(0, 20)
			UICorner_4.Parent = SliderIn

			TextBox.Parent = SliderFrame
			TextBox.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
			TextBox.Position = UDim2.new(0.834999979, 0, 0.55859673, 0)
			TextBox.Size = UDim2.new(0, 53, 0, 29)
			TextBox.Font = Enum.Font.SourceSans
			TextBox.Text = ""
			TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextBox.TextScaled = true
			TextBox.TextSize = 14.000
			TextBox.TextWrapped = true
			TextBox.TextTransparency = 0.4

			UICorner_5.CornerRadius = UDim.new(0, 5)
			UICorner_5.Parent = TextBox

			UIStroke.Parent = SliderFrame
			UIStroke.Color = Color3.fromRGB(170, 170, 255)
			UIStroke.Thickness = 2
			UIStroke.Transparency = 1

			UIStroke_SliderButton.Parent = SliderButton
			UIStroke_SliderButton.Color = Color3.fromRGB(170, 170, 255)
			UIStroke_SliderButton.Thickness = 1
			UIStroke_SliderButton.Transparency = 1

			UIStroke_TextBox.Parent = TextBox
			UIStroke_TextBox.Color = Color3.fromRGB(170, 170, 255)
			UIStroke_TextBox.Thickness = 1
			UIStroke_TextBox.Transparency = 1
			UIStroke_TextBox.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			function actions:Set(arg)
				pcall(function()
					callback(arg)
					TextBox.Text = arg
				end)
			end

			TextBox.MouseEnter:Connect(function()
				TweenService:Create(
					UIStroke_TextBox,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 0 }
				):Play()
			end)

			TextBox.MouseLeave:Connect(function()
				TweenService:Create(
					UIStroke_TextBox,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
			end)

			SliderButton.MouseEnter:Connect(function()
				TweenService:Create(
					UIStroke_SliderButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 0 }
				):Play()
			end)

			SliderButton.MouseLeave:Connect(function()
				TweenService:Create(
					UIStroke_SliderButton,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
			end)

			SliderFrame.MouseEnter:Connect(function()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 0 }
				):Play()
				TweenService:Create(
					SliderName,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0 }
				):Play()
				TweenService:Create(
					TextBox,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0 }
				):Play()
			end)

			SliderFrame.MouseLeave:Connect(function()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
				TweenService:Create(
					SliderName,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0.4 }
				):Play()
				TweenService:Create(
					TextBox,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0.4 }
				):Play()
			end)

			TextBox.FocusLost:Connect(function(Entered)
				if Entered and TextBox.Text ~= "" then
					Value = TextBox.Text
					pcall(function()
						callback(Value)
					end)
				else
				end
			end)

			SliderButton.MouseButton1Down:Connect(function()
				Value = math.floor(
					(((tonumber(maxvalue) - tonumber(minvalue)) / sliderlength) * SliderIn.AbsoluteSize.X)
						+ tonumber(minvalue)
				) or 0
				pcall(function()
					callback(Value)
				end)
				SliderIn.Size = UDim2.new(0, math.clamp(mouse.X - SliderIn.AbsolutePosition.X, 0, sliderlength), 0, 16)
				moveconnection = mouse.Move:Connect(function()
					TextBox.Text = Value
					Value = math.floor(
						(((tonumber(maxvalue) - tonumber(minvalue)) / sliderlength) * SliderIn.AbsoluteSize.X)
							+ tonumber(minvalue)
					)
					pcall(function()
						callback(Value)
					end)
					SliderIn.Size =
						UDim2.new(0, math.clamp(mouse.X - SliderIn.AbsolutePosition.X, 0, sliderlength), 0, 16)
				end)
				releaseconnection = uis.InputEnded:Connect(function(Mouse)
					if Mouse.UserInputType == Enum.UserInputType.MouseButton1 then
						Value = math.floor(
							(((tonumber(maxvalue) - tonumber(minvalue)) / sliderlength) * SliderIn.AbsoluteSize.X)
								+ tonumber(minvalue)
						)
						pcall(function()
							callback(Value)
						end)
						SliderIn.Size =
							UDim2.new(0, math.clamp(mouse.X - SliderIn.AbsolutePosition.X, 0, sliderlength), 0, 16)
						moveconnection:Disconnect()
						releaseconnection:Disconnect()
					end
				end)
			end)
			return actions
		end
		----------創建「滑條」的函數]

		----------[創建「按鈕」的函數
		function functionLibrary:Button(FunctionName, callback)
			local callback = callback or function() end

			local Button = Instance.new("ImageButton")
			local UIGradient = Instance.new("UIGradient")
			local ButtonName = Instance.new("TextLabel")
			local UITextSizeConstraint = Instance.new("UITextSizeConstraint")
			local UICorner = Instance.new("UICorner")
			local UIStroke = Instance.new("UIStroke")

			Button.Name = "Button"
			Button.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			Button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Button.Size = UDim2.new(0, 390, 0, 36)
			Button.AutoButtonColor = false

			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(76, 90, 108)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(79, 95, 112)),
			})
			UIGradient.Rotation = 25
			UIGradient.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0.00, 0.50), NumberSequenceKeypoint.new(1.00, 0.50) })
			UIGradient.Parent = Button

			ButtonName.Name = "ButtonName"
			ButtonName.Parent = Button
			ButtonName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ButtonName.BackgroundTransparency = 1.000
			ButtonName.BorderSizePixel = 0
			ButtonName.Position = UDim2.new(0.0299999993, 0, 0.150000006, 0)
			ButtonName.Size = UDim2.new(0.714129448, 0, 0.727579474, 0)
			ButtonName.Font = Enum.Font.Code
			ButtonName.Text = FunctionName
			ButtonName.TextColor3 = Color3.fromRGB(255, 255, 255)
			ButtonName.TextScaled = true
			ButtonName.TextSize = 14.000
			ButtonName.TextWrapped = true
			ButtonName.TextXAlignment = Enum.TextXAlignment.Left
			ButtonName.TextTransparency = 0.4

			UITextSizeConstraint.Parent = ButtonName
			UITextSizeConstraint.MaxTextSize = 57

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = Button

			UIStroke.Parent = Button
			UIStroke.Color = Color3.fromRGB(170, 170, 255)
			UIStroke.Thickness = 2
			UIStroke.Transparency = 1

			Button.MouseButton1Down:Connect(function()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Color = Color3.fromRGB(255, 255, 255) }
				):Play()
			end)

			Button.MouseButton1Up:Connect(function()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Color = Color3.fromRGB(170, 170, 255) }
				):Play()
			end)

			Button.MouseEnter:Connect(function()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 0 }
				):Play()
				TweenService:Create(
					ButtonName,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0 }
				):Play()
			end)

			Button.MouseLeave:Connect(function()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
				TweenService:Create(
					ButtonName,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0.4 }
				):Play()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Color = Color3.fromRGB(170, 170, 255) }
				):Play()
			end)

			Button.MouseButton1Click:Connect(function()
				pcall(callback)
			end)
		end
		----------創建「按鈕」的函數]

		----------[創建「下拉欄」的函數
		function functionLibrary:Dropdown(FunctionName, list, callback)
			callback = callback or function() end
			list = list or {}
			FunctionName = FunctionName or ""

			local Dropped = false
			local DropDebounce = false
			local FrameSize = 36
			local actions = {}

			local DropdownFrame = Instance.new("Frame")
			local DropdownName = Instance.new("TextLabel")
			local DropdownScrollFrame = Instance.new("Frame")
			local UIGradient = Instance.new("UIGradient")
			local UICorner = Instance.new("UICorner")
			local UIListLayout = Instance.new("UIListLayout")
			local UIPadding = Instance.new("UIPadding")
			local DropToggle = Instance.new("ImageButton")
			local UICorner_5 = Instance.new("UICorner")
			local UIGradient_2 = Instance.new("UIGradient")
			local FakeFrame = Instance.new("Frame")
			local UICorner_6 = Instance.new("UICorner")
			local UIGradient_3 = Instance.new("UIGradient")
			local UIStroke = Instance.new("UIStroke")

			DropdownFrame.Name = "DropdownFrame"
			DropdownFrame.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			DropdownFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropdownFrame.BorderSizePixel = 0
			DropdownFrame.ClipsDescendants = true
			DropdownFrame.Position = UDim2.new(0, 18, 0, 44)
			DropdownFrame.Size = UDim2.new(0, 391, 0, FrameSize)

			DropdownName.Name = "DropdownName"
			DropdownName.Parent = DropdownFrame
			DropdownName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropdownName.BackgroundTransparency = 1.000
			DropdownName.BorderSizePixel = 0
			DropdownName.Position = UDim2.new(0, 11, 0, 5)
			DropdownName.Size = UDim2.new(0, 305, 0, 26)
			DropdownName.ZIndex = 3
			DropdownName.Font = Enum.Font.Code
			DropdownName.Text = FunctionName
			DropdownName.TextColor3 = Color3.fromRGB(255, 255, 255)
			DropdownName.TextScaled = true
			DropdownName.TextSize = 14.000
			DropdownName.TextWrapped = true
			DropdownName.TextXAlignment = Enum.TextXAlignment.Left
			DropdownName.TextTransparency = 0.4

			DropdownScrollFrame.Name = "DropdownScrollFrame"
			DropdownScrollFrame.Parent = DropdownFrame
			DropdownScrollFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropdownScrollFrame.BackgroundTransparency = 1.000
			DropdownScrollFrame.ClipsDescendants = true
			DropdownScrollFrame.Size = UDim2.new(1, 0, 1, 0)

			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(19, 22, 27)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(29, 35, 42)),
			})
			UIGradient.Rotation = 25
			UIGradient.Parent = DropdownScrollFrame

			UICorner.CornerRadius = UDim.new(0, 10)
			UICorner.Parent = DropdownScrollFrame

			UIListLayout.Parent = DropdownScrollFrame
			UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			UIListLayout.SortOrder = Enum.SortOrder.Name

			UIPadding.Parent = DropdownScrollFrame
			UIPadding.PaddingTop = UDim.new(0, 36)

			DropToggle.Name = "DropToggle"
			DropToggle.Parent = DropdownFrame
			DropToggle.BackgroundTransparency = 1.000
			DropToggle.Position = UDim2.new(0, 350, 0, 5)
			DropToggle.Size = UDim2.new(0, 25, 0, 25)
			DropToggle.ZIndex = 3
			DropToggle.Image = "rbxassetid://3926305904"
			DropToggle.ImageRectOffset = Vector2.new(564, 284)
			DropToggle.ImageRectSize = Vector2.new(36, 36)

			UICorner_5.CornerRadius = UDim.new(0, 4)
			UICorner_5.Parent = DropdownFrame

			UIGradient_2.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(50, 59, 71)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(53, 65, 76)),
			})
			UIGradient_2.Rotation = 25
			UIGradient_2.Parent = DropdownFrame

			FakeFrame.Name = "FakeFrame"
			FakeFrame.Parent = DropdownFrame
			FakeFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			FakeFrame.BorderSizePixel = 0
			FakeFrame.Size = UDim2.new(0, 391, 0, 36)
			FakeFrame.ZIndex = 2

			UICorner_6.CornerRadius = UDim.new(0, 4)
			UICorner_6.Parent = FakeFrame

			UIGradient_3.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(50, 59, 71)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(53, 65, 76)),
			})
			UIGradient_3.Rotation = 25
			UIGradient_3.Parent = FakeFrame

			UIStroke.Parent = DropdownFrame
			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke.Color = Color3.fromRGB(170, 170, 255)
			UIStroke.Thickness = 2
			UIStroke.Transparency = 1

			DropdownFrame.MouseEnter:Connect(function()
				if Dropped == false then
					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 0 }
					):Play()
					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0 }
					):Play()
				end
			end)

			DropdownFrame.MouseLeave:Connect(function()
				if Dropped == false then
					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1 }
					):Play()
					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0.4 }
					):Play()
				end
			end)

			local function ToggleDrop()
				if DropDebounce == false then
					DropDebounce = true

					local OptionCount = 0

					Dropped = not Dropped

					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = Dropped and 0 }
					):Play()

					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = Dropped and 0 }
					):Play()

					TweenService:Create(
						DropToggle,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Rotation = Dropped and -180 or 0 }
					):Play()

					for i, v in next, DropdownScrollFrame:GetChildren() do
						if v:IsA("TextButton") then
							OptionCount = OptionCount + 1
						end
					end

					TweenService:Create(
						DropdownFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Size = Dropped and UDim2.new(0, 391, 0, FrameSize + 32 * OptionCount)
								or UDim2.new(0, 391, 0, FrameSize),
						}
					):Play()
					wait(0.25)
					DropDebounce = false
				end
			end

			function actions:Set(arg)
				if arg ~= nil then
					DropdownName.Text = arg
				end
			end

			local function inputBegan(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					ToggleDrop()
				end
			end

			FakeFrame.InputBegan:Connect(inputBegan)

			DropToggle.MouseButton1Click:Connect(ToggleDrop)

			for i, v in pairs(list) do
				local Option = Instance.new("TextButton")
				local OptionName = Instance.new("TextLabel")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")

				Option.Name = tostring(v)
				Option.Parent = DropdownScrollFrame
				Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Option.BackgroundTransparency = 1.000
				Option.Position = UDim2.new(0.0306905378, 0, 0, 0)
				Option.Size = UDim2.new(0, 347, 0, 32)
				Option.ZIndex = 2
				Option.Font = Enum.Font.SourceSans
				Option.Text = ""
				Option.TextColor3 = Color3.fromRGB(255, 255, 255)
				Option.TextScaled = true
				Option.TextSize = 14.000
				Option.TextWrapped = true

				OptionName.Name = "OptionName"
				OptionName.Parent = Option
				OptionName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				OptionName.BackgroundTransparency = 1.000
				OptionName.BorderSizePixel = 0
				OptionName.Position = UDim2.new(0, 0, 0.0833333358, 0)
				OptionName.Size = UDim2.new(1, 0, 0.800000012, 0)
				OptionName.ZIndex = 2
				OptionName.Font = Enum.Font.Code
				OptionName.Text = tostring(i) .. "  " .. tostring(v)
				OptionName.TextColor3 = Color3.fromRGB(255, 255, 255)
				OptionName.TextScaled = true
				OptionName.TextSize = 14.000
				OptionName.TextWrapped = true
				OptionName.TextTransparency = 0.4

				UICorner_2.CornerRadius = UDim.new(0, 4)
				UICorner_2.Parent = Option

				UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Thickness = 1
				UIStroke_2.Transparency = 1
				UIStroke_2.Parent = Option

				Option.MouseEnter:Connect(function()
					--if Dropped == true then
					TweenService:Create(
						UIStroke_2,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = Dropped and 0 }
					):Play()
					TweenService:Create(
						OptionName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = Dropped and 0 }
					):Play()
					--end
				end)

				Option.MouseLeave:Connect(function()
					--if Dropped == true then
					TweenService:Create(
						UIStroke_2,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1 }
					):Play()
					TweenService:Create(
						OptionName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0.4 }
					):Play()
					--end
				end)

				Option.MouseButton1Click:Connect(function()
					if Dropped == true then
						TweenService:Create(
							UIStroke,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Transparency = 1 }
						):Play()

						TweenService:Create(
							DropdownName,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ TextTransparency = 0.4 }
						):Play()

						TweenService:Create(
							DropToggle,
							TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Rotation = 0 }
						):Play()

						TweenService:Create(
							DropdownFrame,
							TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Size = UDim2.new(0, 391, 0, FrameSize) }
						):Play()

						Dropped = false
						DropdownName.Text = tostring(i) .. "  " .. tostring(v)

						callback(v)
					end
				end)
			end
			return actions
		end
		----------創建「下拉欄」的函數]

		----------[創建「切換下拉欄」的函數
		function functionLibrary:ToggleDropdown(FunctionName, list, callback, ToggleCallback)
			callback = callback or function() end
			ToggleCallback = ToggleCallback or function(toggled) end
			list = list or {}
			FunctionName = FunctionName or ""

			local Dropped = false
			local DropDebounce = false
			local debounce = false
			local toggled = false
			local FrameSize = 36
			local actions = {}

			local ToggleDropdownFrame = Instance.new("Frame")
			local DropdownName = Instance.new("TextLabel")
			local DropdownScrollFrame = Instance.new("Frame")
			local UIGradient = Instance.new("UIGradient")
			local UICorner = Instance.new("UICorner")
			local UIListLayout = Instance.new("UIListLayout")
			local UIPadding = Instance.new("UIPadding")
			local DropToggle = Instance.new("ImageButton")
			local UICorner_3 = Instance.new("UICorner")
			local UIGradient_2 = Instance.new("UIGradient")
			local FakeFrame = Instance.new("Frame")
			local UICorner_4 = Instance.new("UICorner")
			local UIGradient_3 = Instance.new("UIGradient")
			local ToggleButton = Instance.new("ImageButton")
			local UICorner_5 = Instance.new("UICorner")
			local UIStroke = Instance.new("UIStroke")

			ToggleDropdownFrame.Name = "ToggleDropdownFrame"
			ToggleDropdownFrame.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			ToggleDropdownFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ToggleDropdownFrame.BorderSizePixel = 0
			ToggleDropdownFrame.ClipsDescendants = true
			ToggleDropdownFrame.Position = UDim2.new(0, 18, 0, 44)
			ToggleDropdownFrame.Size = UDim2.new(0, 391, 0, 36)

			DropdownName.Name = "DropdownName"
			DropdownName.Parent = ToggleDropdownFrame
			DropdownName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropdownName.BackgroundTransparency = 1.000
			DropdownName.BorderSizePixel = 0
			DropdownName.Position = UDim2.new(0, 11, 0, 5)
			DropdownName.Size = UDim2.new(0, 305, 0, 26)
			DropdownName.ZIndex = 3
			DropdownName.Font = Enum.Font.Code
			DropdownName.Text = "下拉欄功能的名稱"
			DropdownName.TextColor3 = Color3.fromRGB(255, 255, 255)
			DropdownName.TextScaled = true
			DropdownName.TextSize = 14.000
			DropdownName.TextWrapped = true
			DropdownName.TextXAlignment = Enum.TextXAlignment.Left

			DropdownScrollFrame.Name = "DropdownScrollFrame"
			DropdownScrollFrame.Parent = ToggleDropdownFrame
			DropdownScrollFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropdownScrollFrame.BackgroundTransparency = 1.000
			DropdownScrollFrame.ClipsDescendants = true
			DropdownScrollFrame.Size = UDim2.new(1, 0, 1, 0)

			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(19, 22, 27)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(29, 35, 42)),
			})
			UIGradient.Rotation = 25
			UIGradient.Parent = DropdownScrollFrame

			UICorner.CornerRadius = UDim.new(0, 10)
			UICorner.Parent = DropdownScrollFrame

			UIListLayout.Parent = DropdownScrollFrame
			UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

			UIPadding.Parent = DropdownScrollFrame
			UIPadding.PaddingTop = UDim.new(0, 36)

			DropToggle.Name = "DropToggle"
			DropToggle.Parent = ToggleDropdownFrame
			DropToggle.BackgroundTransparency = 1.000
			DropToggle.Position = UDim2.new(0, 315, 0, 5)
			DropToggle.Size = UDim2.new(0, 25, 0, 25)
			DropToggle.ZIndex = 3
			DropToggle.Image = "rbxassetid://3926305904"
			DropToggle.ImageRectOffset = Vector2.new(564, 284)
			DropToggle.ImageRectSize = Vector2.new(36, 36)

			UICorner_3.CornerRadius = UDim.new(0, 4)
			UICorner_3.Parent = ToggleDropdownFrame

			UIGradient_2.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(50, 59, 71)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(53, 65, 76)),
			})
			UIGradient_2.Rotation = 25
			UIGradient_2.Parent = ToggleDropdownFrame

			FakeFrame.Name = "FakeFrame"
			FakeFrame.Parent = ToggleDropdownFrame
			FakeFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			FakeFrame.BorderSizePixel = 0
			FakeFrame.Size = UDim2.new(0, 391, 0, 36)
			FakeFrame.ZIndex = 2

			UICorner_4.CornerRadius = UDim.new(0, 4)
			UICorner_4.Parent = FakeFrame

			UIGradient_3.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(50, 59, 71)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(53, 65, 76)),
			})
			UIGradient_3.Rotation = 25
			UIGradient_3.Parent = FakeFrame

			ToggleButton.Name = "ToggleButton"
			ToggleButton.Parent = ToggleDropdownFrame
			ToggleButton.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
			ToggleButton.Position = UDim2.new(0, 351, 0, 5)
			ToggleButton.Size = UDim2.new(0, 25, 0, 25)
			ToggleButton.ZIndex = 2
			ToggleButton.AutoButtonColor = false
			ToggleButton.Image = "rbxassetid://3926311105"
			ToggleButton.ImageColor3 = Color3.fromRGB(0, 170, 0)
			ToggleButton.ImageRectOffset = Vector2.new(4, 836)
			ToggleButton.ImageRectSize = Vector2.new(48, 48)
			ToggleButton.TileSize = UDim2.new(2, 0, 2, 0)
			ToggleButton.ImageTransparency = 1

			UICorner_5.CornerRadius = UDim.new(0, 5)
			UICorner_5.Parent = ToggleButton

			UIStroke.Parent = ToggleDropdownFrame
			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke.Color = Color3.fromRGB(170, 170, 255)
			UIStroke.Thickness = 2
			UIStroke.Transparency = 1

			ToggleDropdownFrame.MouseEnter:Connect(function()
				if toggled == false then
					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 0 }
					):Play()
					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0 }
					):Play()
				end
			end)

			ToggleDropdownFrame.MouseLeave:Connect(function()
				if toggled == false then
					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1 }
					):Play()
					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0.4 }
					):Play()
				end
			end)

			ToggleButton.MouseEnter:Connect(function()
				if toggled == false then
					TweenService:Create(
						ToggleButton,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ ImageTransparency = 0.8 }
					):Play()
				end
			end)

			ToggleButton.MouseLeave:Connect(function()
				if toggled == false then
					TweenService:Create(
						ToggleButton,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ ImageTransparency = 1 }
					):Play()
				end
			end)

			local function ToggleDrop()
				if DropDebounce == false then
					DropDebounce = true

					local OptionCount = 0

					Dropped = not Dropped

					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = Dropped and 0 }
					):Play()

					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = Dropped and 0 }
					):Play()

					TweenService:Create(
						DropToggle,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Rotation = Dropped and -180 or 0 }
					):Play()

					for i, v in next, DropdownScrollFrame:GetChildren() do
						if v:IsA("TextButton") then
							OptionCount = OptionCount + 1
						end
					end

					TweenService:Create(
						ToggleDropdownFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Size = Dropped and UDim2.new(0, 391, 0, FrameSize + 32 * OptionCount)
								or UDim2.new(0, 391, 0, FrameSize),
						}
					):Play()
					wait(0.25)
					DropDebounce = false
				end
			end

			local function Toggle()
				if debounce == false then
					debounce = true
					toggled = not toggled
					TweenService:Create(
						ToggleButton,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ ImageTransparency = toggled and 0 or 1 }
					):Play()
					DropdownName.TextTransparency = toggled and 0
					UIStroke.Transparency = toggled and 0
					wait(0.25)
					debounce = false
					pcall(ToggleCallback, toggled)
				end
			end

			local function inputBegan(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					ToggleDrop()
				end
			end

			function actions:Set(SelectedName, Toggled)
				if SelectedName ~= nil then
					DropdownName.Text = SelectedName
				end

				if Toggled == true then
					Toggle()
				end
			end

			ToggleButton.MouseButton1Click:Connect(Toggle)

			FakeFrame.InputBegan:Connect(inputBegan)

			DropToggle.MouseButton1Click:Connect(ToggleDrop)

			for i, v in pairs(list) do
				local Option = Instance.new("TextButton")
				local OptionName = Instance.new("TextLabel")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")

				Option.Name = v
				Option.Parent = DropdownScrollFrame
				Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Option.BackgroundTransparency = 1.000
				Option.Position = UDim2.new(0.0306905378, 0, 0, 0)
				Option.Size = UDim2.new(0, 347, 0, 32)
				Option.ZIndex = 2
				Option.Font = Enum.Font.SourceSans
				Option.Text = ""
				Option.TextColor3 = Color3.fromRGB(255, 255, 255)
				Option.TextScaled = true
				Option.TextSize = 14.000
				Option.TextWrapped = true

				OptionName.Name = "OptionName"
				OptionName.Parent = Option
				OptionName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				OptionName.BackgroundTransparency = 1.000
				OptionName.BorderSizePixel = 0
				OptionName.Position = UDim2.new(0, 0, 0.0833333358, 0)
				OptionName.Size = UDim2.new(1, 0, 0.800000012, 0)
				OptionName.ZIndex = 2
				OptionName.Font = Enum.Font.Code
				OptionName.Text = v
				OptionName.TextColor3 = Color3.fromRGB(255, 255, 255)
				OptionName.TextScaled = true
				OptionName.TextSize = 14.000
				OptionName.TextWrapped = true
				OptionName.TextTransparency = 0.4

				UICorner_2.CornerRadius = UDim.new(0, 4)
				UICorner_2.Parent = Option

				UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Thickness = 1
				UIStroke_2.Transparency = 1
				UIStroke_2.Parent = Option

				Option.MouseEnter:Connect(function()
					--if Dropped == true then
					TweenService:Create(
						UIStroke_2,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = Dropped and 0 }
					):Play()
					TweenService:Create(
						OptionName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = Dropped and 0 }
					):Play()
					--end
				end)

				Option.MouseLeave:Connect(function()
					--if Dropped == true then
					TweenService:Create(
						UIStroke_2,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1 }
					):Play()
					TweenService:Create(
						OptionName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0.4 }
					):Play()
					--end
				end)

				Option.MouseButton1Click:Connect(function()
					if Dropped == true then
						TweenService:Create(
							UIStroke,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Transparency = 1 }
						):Play()

						TweenService:Create(
							DropdownName,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ TextTransparency = 0.4 }
						):Play()

						TweenService:Create(
							DropToggle,
							TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Rotation = 0 }
						):Play()

						TweenService:Create(
							ToggleDropdownFrame,
							TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Size = UDim2.new(0, 391, 0, FrameSize) }
						):Play()

						Dropped = false
						DropdownName.Text = v

						callback(v)
					end
				end)
			end
			return actions
		end
		----------創建「切換下拉欄」的函數]

		----------[創建「錄製下拉欄」的函數
		function functionLibrary:RecordDropdown(FunctionName, list, callback)
			callback = callback or function() end
			list = list or {}
			FunctionName = FunctionName or ""

			local Dropped = false
			local DropDebounce = false
			local RefreshDebounce = false
			local FrameSize = 36
			local actions = {}

			local DropdownFrame = Instance.new("Frame")
			local DropdownName = Instance.new("TextLabel")
			local DropdownScrollFrame = Instance.new("Frame")
			local UIGradient = Instance.new("UIGradient")
			local UICorner = Instance.new("UICorner")
			local UIListLayout = Instance.new("UIListLayout")
			local UIPadding = Instance.new("UIPadding")
			local DropToggle = Instance.new("ImageButton")
			local UICorner_5 = Instance.new("UICorner")
			local UIGradient_2 = Instance.new("UIGradient")
			local FakeFrame = Instance.new("Frame")
			local UICorner_6 = Instance.new("UICorner")
			local UIGradient_3 = Instance.new("UIGradient")
			local UIStroke = Instance.new("UIStroke")
			local refresh = Instance.new("ImageButton")

			DropdownFrame.Name = "DropdownFrame"
			DropdownFrame.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			DropdownFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropdownFrame.BorderSizePixel = 0
			DropdownFrame.ClipsDescendants = true
			DropdownFrame.Position = UDim2.new(0, 18, 0, 44)
			DropdownFrame.Size = UDim2.new(0, 391, 0, FrameSize)

			DropdownName.Name = "DropdownName"
			DropdownName.Parent = DropdownFrame
			DropdownName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropdownName.BackgroundTransparency = 1.000
			DropdownName.BorderSizePixel = 0
			DropdownName.Position = UDim2.new(0, 11, 0, 5)
			DropdownName.Size = UDim2.new(0, 305, 0, 26)
			DropdownName.ZIndex = 3
			DropdownName.Font = Enum.Font.Code
			DropdownName.Text = FunctionName
			DropdownName.TextColor3 = Color3.fromRGB(255, 255, 255)
			DropdownName.TextScaled = true
			DropdownName.TextSize = 14.000
			DropdownName.TextWrapped = true
			DropdownName.TextXAlignment = Enum.TextXAlignment.Left
			DropdownName.TextTransparency = 0.4

			DropdownScrollFrame.Name = "DropdownScrollFrame"
			DropdownScrollFrame.Parent = DropdownFrame
			DropdownScrollFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			DropdownScrollFrame.BackgroundTransparency = 1.000
			DropdownScrollFrame.ClipsDescendants = true
			DropdownScrollFrame.Size = UDim2.new(1, 0, 1, 0)

			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(19, 22, 27)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(29, 35, 42)),
			})
			UIGradient.Rotation = 25
			UIGradient.Parent = DropdownScrollFrame

			UICorner.CornerRadius = UDim.new(0, 10)
			UICorner.Parent = DropdownScrollFrame

			UIListLayout.Parent = DropdownScrollFrame
			UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			UIListLayout.SortOrder = Enum.SortOrder.Name

			UIPadding.Parent = DropdownScrollFrame
			UIPadding.PaddingTop = UDim.new(0, 36)

			DropToggle.Name = "DropToggle"
			DropToggle.Parent = DropdownFrame
			DropToggle.BackgroundTransparency = 1.000
			DropToggle.Position = UDim2.new(0, 350, 0, 5)
			DropToggle.Size = UDim2.new(0, 25, 0, 25)
			DropToggle.ZIndex = 3
			DropToggle.Image = "rbxassetid://3926305904"
			DropToggle.ImageRectOffset = Vector2.new(564, 284)
			DropToggle.ImageRectSize = Vector2.new(36, 36)

			UICorner_5.CornerRadius = UDim.new(0, 4)
			UICorner_5.Parent = DropdownFrame

			UIGradient_2.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(50, 59, 71)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(53, 65, 76)),
			})
			UIGradient_2.Rotation = 25
			UIGradient_2.Parent = DropdownFrame

			FakeFrame.Name = "FakeFrame"
			FakeFrame.Parent = DropdownFrame
			FakeFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			FakeFrame.BorderSizePixel = 0
			FakeFrame.Size = UDim2.new(0, 391, 0, 36)
			FakeFrame.ZIndex = 2

			UICorner_6.CornerRadius = UDim.new(0, 4)
			UICorner_6.Parent = FakeFrame

			UIGradient_3.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(50, 59, 71)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(53, 65, 76)),
			})
			UIGradient_3.Rotation = 25
			UIGradient_3.Parent = FakeFrame

			UIStroke.Parent = DropdownFrame
			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke.Color = Color3.fromRGB(170, 170, 255)
			UIStroke.Thickness = 2
			UIStroke.Transparency = 1

			refresh.Name = "refresh"
			refresh.Parent = DropdownFrame
			refresh.BackgroundTransparency = 1.000
			refresh.Position = UDim2.new(0, 320, 0, 5)
			refresh.Size = UDim2.new(0, 25, 0, 25)
			refresh.ZIndex = 2
			refresh.Image = "rbxassetid://3926307971"
			refresh.ImageRectOffset = Vector2.new(404, 84)
			refresh.ImageRectSize = Vector2.new(36, 36)

			DropdownFrame.MouseEnter:Connect(function()
				if Dropped == false then
					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 0 }
					):Play()
					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0 }
					):Play()
				end
			end)

			DropdownFrame.MouseLeave:Connect(function()
				if Dropped == false then
					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1 }
					):Play()
					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0.4 }
					):Play()
				end
			end)

			local function ToggleDrop()
				if DropDebounce == false then
					DropDebounce = true

					local OptionCount = 0

					Dropped = not Dropped

					TweenService:Create(
						UIStroke,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = Dropped and 0 }
					):Play()

					TweenService:Create(
						DropdownName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = Dropped and 0 }
					):Play()

					TweenService:Create(
						DropToggle,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Rotation = Dropped and -180 or 0 }
					):Play()

					for i, v in next, DropdownScrollFrame:GetChildren() do
						if v:IsA("TextButton") then
							OptionCount = OptionCount + 1
						end
					end

					TweenService:Create(
						DropdownFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Size = Dropped and UDim2.new(0, 391, 0, FrameSize + 32 * OptionCount)
								or UDim2.new(0, 391, 0, FrameSize),
						}
					):Play()
					wait(0.25)
					DropDebounce = false
				end
			end

			function actions:Set(arg)
				if arg ~= nil then
					DropdownName.Text = arg
				end
			end

			local function inputBegan(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					ToggleDrop()
				end
			end

			local function refreshList()
				if RefreshDebounce == false then
					RefreshDebounce = true
					local OptionCount = 0

					for i, v in next, DropdownScrollFrame:GetChildren() do
						if v:IsA("TextButton") then
							v:Destroy()
						end
					end

					wait(0.25)

					for i, v in next, getgenv().RecordFileList do
						print("刷新list")
						print(i, v)

						local Option = Instance.new("TextButton")
						local OptionName = Instance.new("TextLabel")
						local UICorner_2 = Instance.new("UICorner")
						local UIStroke_2 = Instance.new("UIStroke")

						Option.Name = v
						Option.Parent = DropdownScrollFrame
						Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						Option.BackgroundTransparency = 1.000
						Option.Position = UDim2.new(0.0306905378, 0, 0, 0)
						Option.Size = UDim2.new(0, 347, 0, 32)
						Option.ZIndex = 2
						Option.Font = Enum.Font.SourceSans
						Option.Text = ""
						Option.TextColor3 = Color3.fromRGB(255, 255, 255)
						Option.TextScaled = true
						Option.TextSize = 14.000
						Option.TextWrapped = true

						OptionName.Name = "OptionName"
						OptionName.Parent = Option
						OptionName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
						OptionName.BackgroundTransparency = 1.000
						OptionName.BorderSizePixel = 0
						OptionName.Position = UDim2.new(0, 0, 0.0833333358, 0)
						OptionName.Size = UDim2.new(1, 0, 0.800000012, 0)
						OptionName.ZIndex = 2
						OptionName.Font = Enum.Font.Code
						OptionName.Text = v
						OptionName.TextColor3 = Color3.fromRGB(255, 255, 255)
						OptionName.TextSize = 20
						OptionName.TextTransparency = 0.4

						UICorner_2.CornerRadius = UDim.new(0, 4)
						UICorner_2.Parent = Option

						UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
						UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
						UIStroke_2.Thickness = 1
						UIStroke_2.Transparency = 1
						UIStroke_2.Parent = Option

						Option.MouseEnter:Connect(function()
							--if Dropped == true then
							TweenService:Create(
								UIStroke_2,
								TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{ Transparency = Dropped and 0 }
							):Play()
							TweenService:Create(
								OptionName,
								TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{ TextTransparency = Dropped and 0 }
							):Play()
							--end
						end)

						Option.MouseLeave:Connect(function()
							--if Dropped == true then
							TweenService:Create(
								UIStroke_2,
								TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{ Transparency = 1 }
							):Play()
							TweenService:Create(
								OptionName,
								TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
								{ TextTransparency = 0.4 }
							):Play()
							--end
						end)

						Option.MouseButton1Click:Connect(function()
							if Dropped == true then
								TweenService:Create(
									UIStroke,
									TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
									{ Transparency = 1 }
								):Play()

								TweenService:Create(
									DropdownName,
									TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
									{ TextTransparency = 0.4 }
								):Play()

								TweenService:Create(
									DropToggle,
									TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
									{ Rotation = 0 }
								):Play()

								TweenService:Create(
									DropdownFrame,
									TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
									{ Size = UDim2.new(0, 391, 0, FrameSize) }
								):Play()

								Dropped = false
								DropdownName.Text = v

								callback(v)
							end
						end)
					end

					for i, v in next, DropdownScrollFrame:GetChildren() do
						if v:IsA("TextButton") then
							OptionCount = OptionCount + 1
						end
					end

					TweenService:Create(
						DropdownFrame,
						TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{
							Size = Dropped and UDim2.new(0, 391, 0, FrameSize + 32 * OptionCount)
								or UDim2.new(0, 391, 0, FrameSize),
						}
					):Play()

					wait(0.25)
					RefreshDebounce = false
				end
			end

			refresh.MouseButton1Click:Connect(refreshList)

			FakeFrame.InputBegan:Connect(inputBegan)

			DropToggle.MouseButton1Click:Connect(ToggleDrop)

			for i, v in pairs(list) do
				local Option = Instance.new("TextButton")
				local OptionName = Instance.new("TextLabel")
				local UICorner_2 = Instance.new("UICorner")
				local UIStroke_2 = Instance.new("UIStroke")

				Option.Name = v
				Option.Parent = DropdownScrollFrame
				Option.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Option.BackgroundTransparency = 1.000
				Option.Position = UDim2.new(0.0306905378, 0, 0, 0)
				Option.Size = UDim2.new(0, 347, 0, 32)
				Option.ZIndex = 2
				Option.Font = Enum.Font.SourceSans
				Option.Text = ""
				Option.TextColor3 = Color3.fromRGB(255, 255, 255)
				Option.TextScaled = true
				Option.TextSize = 14.000
				Option.TextWrapped = true

				OptionName.Name = "OptionName"
				OptionName.Parent = Option
				OptionName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				OptionName.BackgroundTransparency = 1.000
				OptionName.BorderSizePixel = 0
				OptionName.Position = UDim2.new(0, 0, 0.0833333358, 0)
				OptionName.Size = UDim2.new(1, 0, 0.800000012, 0)
				OptionName.ZIndex = 2
				OptionName.Font = Enum.Font.Code
				OptionName.Text = v
				OptionName.TextColor3 = Color3.fromRGB(255, 255, 255)
				OptionName.TextSize = 20
				OptionName.TextTransparency = 0.4

				UICorner_2.CornerRadius = UDim.new(0, 4)
				UICorner_2.Parent = Option

				UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				UIStroke_2.Color = Color3.fromRGB(255, 255, 255)
				UIStroke_2.Thickness = 1
				UIStroke_2.Transparency = 1
				UIStroke_2.Parent = Option

				Option.MouseEnter:Connect(function()
					--if Dropped == true then
					TweenService:Create(
						UIStroke_2,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = Dropped and 0 }
					):Play()
					TweenService:Create(
						OptionName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = Dropped and 0 }
					):Play()
					--end
				end)

				Option.MouseLeave:Connect(function()
					--if Dropped == true then
					TweenService:Create(
						UIStroke_2,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ Transparency = 1 }
					):Play()
					TweenService:Create(
						OptionName,
						TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ TextTransparency = 0.4 }
					):Play()
					--end
				end)

				Option.MouseButton1Click:Connect(function()
					if Dropped == true then
						TweenService:Create(
							UIStroke,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Transparency = 1 }
						):Play()

						TweenService:Create(
							DropdownName,
							TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ TextTransparency = 0.4 }
						):Play()

						TweenService:Create(
							DropToggle,
							TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Rotation = 0 }
						):Play()

						TweenService:Create(
							DropdownFrame,
							TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ Size = UDim2.new(0, 391, 0, FrameSize) }
						):Play()

						Dropped = false
						DropdownName.Text = v

						callback(v)
					end
				end)
			end
			return actions
		end
		----------創建「錄製下拉欄」的函數]

		----------[創建「標籤」的函數
		function functionLibrary:Tag(TagName)
			-- Instances:
			TagName = TagName or "標籤"

			local TagFrame = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local ToggleName = Instance.new("TextLabel")

			--Properties:

			TagFrame.Name = "TagFrame"
			TagFrame.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			TagFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TagFrame.BackgroundTransparency = 1.000
			TagFrame.BorderSizePixel = 0
			TagFrame.ClipsDescendants = true
			TagFrame.Position = UDim2.new(0.040646553, 0, 0.0119453464, 0)
			TagFrame.Size = UDim2.new(0, 391, 0, 26)

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = TagFrame

			ToggleName.Name = "ToggleName"
			ToggleName.Parent = TagFrame
			ToggleName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			ToggleName.BackgroundTransparency = 1.000
			ToggleName.BorderSizePixel = 0
			ToggleName.Position = UDim2.new(0.01, 0, 0, 0)
			ToggleName.Size = UDim2.new(0.989466071, 0, 0.726040721, 0)
			ToggleName.Font = Enum.Font.Code
			ToggleName.Text = TagName
			ToggleName.TextColor3 = Color3.fromRGB(255, 255, 255)
			ToggleName.TextScaled = true
			ToggleName.TextSize = 14.000
			ToggleName.TextWrapped = true
			ToggleName.TextXAlignment = Enum.TextXAlignment.Left
		end
		------創建「標籤」的函數]
		------[創建「線」的函數
		function functionLibrary:Line()
			-- Instances:

			local LineFrame = Instance.new("Frame")
			local Line = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local UIGradient = Instance.new("UIGradient")

			--Properties:

			LineFrame.Name = "LineFrame"
			LineFrame.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			LineFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			LineFrame.BackgroundTransparency = 1.000
			LineFrame.BorderSizePixel = 0
			LineFrame.Position = UDim2.new(0.040646553, 0, 0.0119453464, 0)
			LineFrame.Size = UDim2.new(0, 391, 0, 24)

			Line.Name = "Line"
			Line.Parent = LineFrame
			Line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Line.BorderSizePixel = 0
			Line.Position = UDim2.new(0, 0, 0.425000012, 0)
			Line.Size = UDim2.new(0, 391, 0, 4)

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = Line

			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(170, 170, 255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(170, 170, 255)),
			})
			UIGradient.Rotation = 25
			UIGradient.Parent = Line
		end
		------創建「線」的函數]
		------[創建「文字框」的函數
		function functionLibrary:TextBox(FunctionName, textBoxText)
			-- Instances:
			FunctionName = FunctionName or "文字框功能名稱"
			textBoxText = textBoxText or "Simple"

			local TextBoxFrame = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local TextBoxName = Instance.new("TextLabel")
			local TextBox = Instance.new("TextBox")
			local UICorner_2 = Instance.new("UICorner")
			local UIGradient = Instance.new("UIGradient")
			local UIStroke = Instance.new("UIStroke")
			local UIStroke_2 = Instance.new("UIStroke")
			--Properties:

			TextBoxFrame.Name = "TextBoxFrame"
			TextBoxFrame.Parent = ScrollingFrameFolder:WaitForChild(TabButtonName .. "_SubScrollingFrame")
			TextBoxFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextBoxFrame.BorderSizePixel = 0
			TextBoxFrame.Position = UDim2.new(0.040646553, 0, 0.0119453464, 0)
			TextBoxFrame.Size = UDim2.new(0, 391, 0, 36)

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = TextBoxFrame

			TextBoxName.Name = "TextBoxName"
			TextBoxName.Parent = TextBoxFrame
			TextBoxName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			TextBoxName.BackgroundTransparency = 1.000
			TextBoxName.BorderSizePixel = 0
			TextBoxName.Position = UDim2.new(0.0299999509, 0, 0.149999827, 0)
			TextBoxName.Size = UDim2.new(0.491964281, 0, 0.726040721, 0)
			TextBoxName.Font = Enum.Font.Code
			TextBoxName.Text = FunctionName
			TextBoxName.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextBoxName.TextScaled = true
			TextBoxName.TextSize = 14.000
			TextBoxName.TextWrapped = true
			TextBoxName.TextXAlignment = Enum.TextXAlignment.Left
			TextBoxName.TextTransparency = 0.4

			TextBox.Parent = TextBoxFrame
			TextBox.BackgroundColor3 = Color3.fromRGB(31, 31, 31)
			TextBox.BorderSizePixel = 0
			TextBox.Position = UDim2.new(0.560327411, 0, 0.205555558, 0)
			TextBox.Size = UDim2.new(0, 157, 0, 22)
			TextBox.Font = Enum.Font.Code
			TextBox.Text = textBoxText
			TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
			TextBox.TextScaled = true
			TextBox.TextSize = 14.000
			TextBox.TextWrapped = true
			TextBox.TextTransparency = 0.4
			TextBox.ClearTextOnFocus = false

			UICorner_2.Parent = TextBox

			UIGradient.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(76, 90, 108)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(79, 95, 112)),
			})
			UIGradient.Rotation = 25
			UIGradient.Transparency =
				NumberSequence.new({ NumberSequenceKeypoint.new(0.00, 0.50), NumberSequenceKeypoint.new(1.00, 0.50) })
			UIGradient.Parent = TextBoxFrame

			UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke.Color = Color3.fromRGB(170, 170, 255)
			UIStroke.Thickness = 1
			UIStroke.Transparency = 1
			UIStroke.Parent = TextBoxFrame

			UIStroke_2.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			UIStroke_2.Color = Color3.fromRGB(170, 170, 255)
			UIStroke_2.Thickness = 1
			UIStroke_2.Transparency = 1
			UIStroke_2.Parent = TextBox

			TextBox.MouseEnter:Connect(function()
				TweenService:Create(
					UIStroke_2,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 0 }
				):Play()

				TextBox.Text = textBoxText
			end)

			TextBox.MouseLeave:Connect(function()
				TweenService:Create(
					UIStroke_2,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()

				TextBox.Text = textBoxText
			end)

			TextBoxFrame.MouseEnter:Connect(function()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 0 }
				):Play()
				TweenService:Create(
					TextBoxName,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0 }
				):Play()
				TweenService:Create(
					TextBox,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0 }
				):Play()

				TextBox.Text = textBoxText
			end)

			TextBoxFrame.MouseLeave:Connect(function()
				TweenService:Create(
					UIStroke,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Transparency = 1 }
				):Play()
				TweenService:Create(
					TextBoxName,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0.4 }
				):Play()
				TweenService:Create(
					TextBox,
					TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ TextTransparency = 0.4 }
				):Play()

				TextBox.Text = textBoxText
			end)
		end
		------創建「文字框」的函數]
		return functionLibrary
	end

	return InsideLibrary
	--創建「分頁」的函數]
end

return Mainlib

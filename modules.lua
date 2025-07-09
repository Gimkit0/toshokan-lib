local Modules = {}

function Modules.TextAnimation()
	local TextAnimation = {}
	TextAnimation.__index = TextAnimation

	function TextAnimation.new()
		local self = setmetatable({}, TextAnimation)

		self.Services = {
			TweenService = game:GetService("TweenService"),
		}

		self.tween = function(obj, info, goal)
			local tween = self.Services.TweenService:Create(obj, info, goal)
			tween:Play()
			return tween
		end
		self.spawn = function(callback, debug)
			if type(callback) == "function" then
				if debug then
					task.spawn(callback) else task.spawn(pcall, callback)
				end
			end
		end
		self.spellOut = function(label, frame, onLetter, onComplete)
			local text = label.Text

			self.spawn(function()
				for i = 1, #text do
					if not frame then
						break
					end

					local letter = text:sub(i, i)

					local temp = Instance.new("TextLabel")
					temp.Size = UDim2.new(0,0,0,0)
					temp.AutomaticSize = Enum.AutomaticSize.X
					temp.BackgroundTransparency = 1
					temp.TextColor3 = label.TextColor3
					temp.Name = i

					if type(onLetter) == "function" then
						onLetter(temp, letter)
					end
				end
				if type(onComplete) == "function" then
					onComplete()
				end
			end)
		end
		self.createAnimFrame = function(label)
			local frame = Instance.new("Frame", label)
			frame.BackgroundTransparency = 1
			frame.Size = UDim2.new(1, 0, 1, 0)
			frame.Name = "_text_anim_frame_"

			local list = Instance.new("UIListLayout", frame)
			list.SortOrder = Enum.SortOrder.LayoutOrder
			list.FillDirection = Enum.FillDirection.Horizontal

			local function updateAlignment()
				if label.TextXAlignment == Enum.TextXAlignment.Left then
					list.HorizontalAlignment = Enum.HorizontalAlignment.Left elseif label.TextXAlignment == Enum.TextXAlignment.Right then
					list.HorizontalAlignment = Enum.HorizontalAlignment.Right elseif label.TextXAlignment == Enum.TextXAlignment.Center then
					list.HorizontalAlignment = Enum.HorizontalAlignment.Center
				end
				if label.TextYAlignment == Enum.TextYAlignment.Top then
					list.VerticalAlignment = Enum.VerticalAlignment.Top elseif label.TextYAlignment == Enum.TextYAlignment.Bottom then
					list.VerticalAlignment = Enum.VerticalAlignment.Bottom elseif label.TextYAlignment == Enum.TextYAlignment.Center then
					list.VerticalAlignment = Enum.VerticalAlignment.Center
				end
			end
			local function updateProp(prop, newProp)
				for _, text in ipairs(frame:GetChildren()) do
					if text:IsA("TextLabel") then
						text[prop] = newProp
					end
				end
			end

			local propConnX
			local propConnY

			propConnX = label:GetPropertyChangedSignal("TextXAlignment"):Connect(function()
				updateAlignment()
			end)
			propConnY = label:GetPropertyChangedSignal("TextYAlignment"):Connect(function()
				updateAlignment()
			end)
			frame.ChildAdded:Connect(function()
				updateProp("Font", label.Font)
				updateProp("TextSize", label.TextSize)
			end)
			frame.Destroying:Connect(function()
				propConnX:Disconnect()
				propConnY:Disconnect()
				frame = nil
			end)
			label:GetPropertyChangedSignal("Font"):Connect(function()
				updateProp("Font", label.Font)
			end)
			label:GetPropertyChangedSignal("TextSize"):Connect(function()
				updateProp("TextSize", label.TextSize)
			end)
			updateAlignment()

			return frame
		end
		self.removeAnimFrame = function(label)
			if not label then
				return
			end
			for _, v in pairs(label:GetChildren()) do
				if v.Name == "_text_anim_frame_"
					or (v:IsA("Frame") and v:FindFirstChild("_text_anim_frame_")) then
					v:Destroy()
				end
			end
		end

		return self
	end

	function TextAnimation:PopText(label, tweenInfo, padAmount, interval)
		if not label then
			return
		end
		if not interval then
			interval = 0
		end
		if not tweenInfo then
			tweenInfo = TweenInfo.new(.15)
		end

		self.removeAnimFrame(label)

		local frame = self.createAnimFrame(label)

		local text = label.Text
		local lastTextTrans = label.TextTransparency

		label.TextTransparency = 1

		self.spellOut(label, frame, function(temp, letter)
			local padding = Instance.new("UIPadding", temp)
			padding.PaddingBottom = UDim.new(0, padAmount)
			padding.PaddingLeft = UDim.new(0, padAmount)

			temp.Text = letter
			temp.Parent = frame
			temp.ZIndex = label.ZIndex + 2

			self.tween(temp, tweenInfo, {TextTransparency = 0})
			self.tween(padding, tweenInfo, {
				PaddingBottom = UDim.new(0, 0),
				PaddingLeft = UDim.new(0, 0)
			})
			task.wait(interval)
		end, function()
			task.wait(tweenInfo.Time)
			self.removeAnimFrame(label)
			label.TextTransparency = lastTextTrans
		end)
	end

	return TextAnimation
end

function Modules.TabControl()
	local TabControl = {}
	TabControl.__index = TabControl

	function TabControl.new(config)
		local self = setmetatable({}, TabControl)

		self.CurrentTab = nil
		self.LastActivatedTab = nil

		self.TabSessions = {}

		return self
	end

	function TabControl:_validateConfig(defaults, newConfig)
		for key, value in pairs(defaults) do
			if newConfig[key] == nil then
				newConfig[key] = value
			end
		end
		return newConfig
	end

	function TabControl:AddTab(button, name, onActivate, onDeactivate)
		local active = false

		local session = {
			name = name,
			temp = button,

			onActive = function(currentTab)
				self.CurrentTab = currentTab
				currentTab.active = true
				active = true
				if type(onActivate) == "function" then
					onActivate(currentTab)
				end
			end,
			onDeactive = function(currentTab)
				active = false
				currentTab.active = false
				if type(onDeactivate) == "function" then
					onDeactivate(currentTab)
				end
			end,

			active = active,
		}

		if not self.CurrentTab then
			session.onActive(session)
		end

		if button:IsA("TextButton") or button:IsA("ImageButton") then
			button.Activated:Connect(function()
				if active then
					return
				else
					self.CurrentTab.onDeactive(self.CurrentTab)
					session.onActive(session)
				end
			end)
		end

		return session
	end

	function TabControl:SwitchTab(session)
		if self.CurrentTab == session and type(session) ~= "table" then
			return
		end
		self.CurrentTab.onDeactive(self.CurrentTab)
		session.onActive(session)
		self.CurrentTab = session
	end

	return TabControl
end

function Modules.States()
	local States = {}
	States.__index = States

	function States.new(window, dragDetector, config)
		local self = setmetatable({}, States)

		self.Window = window
		self.DragDetector = dragDetector

		self.Config = config

		self.States = {
			_minimized = false,
			_maximized = false,
		}
		self.Saved = {
			LAST_POS = self.Window.Position,
			LAST_ANCHOR_POINT = self.Window.AnchorPoint,
			LAST_SIZE = self.Window.Size,
		}
		self.Connections = {}

		return self
	end

	function States:_tween(obj, info, goal)
		local tween = game:GetService("TweenService"):Create(obj, info, goal)
		tween:Play()
		return tween
	end

	function States:_addConn(name, connection)
		task.spawn(pcall, function()
			if self.Connections[name] then
				self.Connections[name]:Disconnect()
			end
			self.Connections[name] = connection
		end)
	end
	function States:_removeConn(name)
		if self.Connections[name] then
			self.Connections[name]:Disconnect()
			self.Connections[name] = nil
		end
	end

	function States:_changeState(state, boolean)
		for _, state in ipairs(self.States) do
			self.States[state] = false
		end
		self.States[state] = boolean
	end

	function States:_updateSaved()
		self.Saved.LAST_POS = self.Window.Position
		self.Saved.LAST_ANCHOR_POINT = self.Window.AnchorPoint
		self.Saved.LAST_SIZE = self.Window.Size
	end

	function States:_normal()
		self:_removeConn("MINIMIZE RENDER")

		self.DragDetector.Enabled = true

		self:_tween(self.Window, TweenInfo.new(self.Config.SPEED, self.Config.EASING_STYLE, self.Config.EASING_DIRECTION), {
			Position = self.Saved.LAST_POS,
			AnchorPoint = self.Saved.LAST_ANCHOR_POINT,
			Size = self.Saved.LAST_SIZE,
		})

		if self.States._minimized then
			self:_tween(self.Window, TweenInfo.new(self.Config.SPEED, self.Config.EASING_STYLE, self.Config.EASING_DIRECTION), {
				Position = UDim2.new(
					self.Window.Position.X.Scale,
					self.Window.Position.X.Offset,
					self.Window.Position.Y.Scale,
					self.Window.Position.Y.Offset + (self.Saved.LAST_SIZE.Y.Offset / 2.5)
				),
			})
		end

		self:_changeState("_minimized", false)
		self:_changeState("_maximized", false)

		if type(self.Config.ON_NORMALIZE) == "function" then
			self.Config.ON_NORMALIZE()
		end
	end

	function States:_minimize()
		if self.States._minimized then
			return
		end

		if self.States._maximized then
			self:_normal()
			task.wait(self.Config.SPEED)
		end

		self:_updateSaved()
		self:_changeState("_minimized", true)

		self:_tween(self.Window, TweenInfo.new(self.Config.SPEED, self.Config.EASING_STYLE, self.Config.EASING_DIRECTION), {
			Size = self.Config.MINIMIZED_SIZE,
			Position = UDim2.new(
				self.Window.Position.X.Scale,
				self.Window.Position.X.Offset,
				self.Window.Position.Y.Scale,
				self.Window.Position.Y.Offset - (self.Window.Size.Y.Offset / 2.5)
			),
			AnchorPoint = Vector2.new(.5, 0),
		})

		self:_addConn("MINIMIZE RENDER", game:GetService("RunService").RenderStepped:Connect(function()
			self.Saved.LAST_POS = self.Window.Position
		end))

		if type(self.Config.ON_MINIMIZED) == "function" then
			self.Config.ON_MINIMIZED()
		end
	end

	function States:_maximize()
		if self.States._maximized then
			return
		end

		if self.States._minimized then
			self:_normal()
			task.wait(self.Config.SPEED)
		end

		self:_updateSaved()
		self:_changeState("_maximized", true)

		self:_removeConn("MINIMIZE RENDER")

		self:_tween(self.Window, TweenInfo.new(self.Config.SPEED, self.Config.EASING_STYLE, self.Config.EASING_DIRECTION), {
			AnchorPoint = Vector2.new(.5,1),
		})
		self:_tween(self.Window, TweenInfo.new(self.Config.SPEED, self.Config.EASING_STYLE, self.Config.EASING_DIRECTION), {
			Position = UDim2.new(.5,0,1,0),
		})
		self:_tween(self.Window, TweenInfo.new(self.Config.SPEED, self.Config.EASING_STYLE, self.Config.EASING_DIRECTION), {
			Size = UDim2.new(1,0,1,-55),
		})

		self.DragDetector.Enabled = false

		if type(self.Config.ON_MAXIMIZED) == "function" then
			self.Config.ON_MAXIMIZED()
		end
	end

	function States:ChangeState(state)
		if state == "minimize" then
			self:_minimize()
		elseif state == "maximize" then
			self:_maximize()
		elseif state == "normal" then
			self:_normal()
		end
	end

	function States:CheckState(state)
		return self.States[state] or false
	end

	return States
end

function Modules.SmoothScroll()
	-- @Streeteenk | April 2020
	-- Smooth Scrolling

--[[
	Based off the SmoothScrolling library made by Elttob, just a simple rewriting with some improvements.
	Change the Factor to make faster or not the scrolling.
	
	Factor:
	0.1 = Smooth
	1 = Not Smooth
]]
	--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--------------------------------------------------------------------------------------------------------------------------------------------------------------


	local RunService = game:GetService('RunService')

	return function (ScrollFrame, Factor)
		Factor = Factor or 0.15
		ScrollFrame.ScrollingEnabled = false

		local Emulator = ScrollFrame:Clone()
		Emulator:ClearAllChildren()
		Emulator.BackgroundTransparency = 1
		Emulator.ScrollBarImageTransparency = 1
		Emulator.ZIndex = ScrollFrame.ZIndex + 1
		Emulator.Name = 'ScrollEmulator'
		Emulator.ScrollingEnabled = true
		Emulator.Parent = ScrollFrame.Parent

		local function SyncProperty(Property)
			ScrollFrame:GetPropertyChangedSignal(Property):Connect(function()
				if Property == 'ZIndex' then
					Emulator[Property] = ScrollFrame[Property + 1]
				else
					Emulator[Property] = ScrollFrame[Property]
				end
			end)
		end

		local Properties = {'CanvasSize', 'Position', 'Rotation', 'ScrollingDirection', 'ScrollBarThickness', 'BorderSizePixel', 'ElasticBehavior', 'SizeConstraint', 'ZIndex', 'BorderColor3', 'Size', 'AnchorPoint', 'Visible', 'AutomaticCanvasSize'}
		for Index = 1, #Properties do
			SyncProperty(Properties[Index])
		end

		local SmoothConnection = RunService.RenderStepped:Connect(function()
			task.spawn(pcall, function()
				local Canvas = ScrollFrame.CanvasPosition
				local FakeCanvas = Emulator.CanvasPosition
				local Math = (FakeCanvas - Canvas) * Factor + Canvas

				ScrollFrame.CanvasPosition = Math
			end)
		end)

		local SizeConnection = ScrollFrame:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(function()
			local Layout = ScrollFrame:FindFirstChildOfClass("UIListLayout") or ScrollFrame:FindFirstChildOfClass("UIGridLayout")
			if ScrollFrame.AutomaticCanvasSize ~= Enum.AutomaticSize.None then
				if not Layout then
					local AbsoluteSize = ScrollFrame.AbsoluteCanvasSize
					local CurrentCanvasSize = ScrollFrame.CanvasSize

					local sizeX = AbsoluteSize.X or CurrentCanvasSize.X.Offset
					local sizeY = AbsoluteSize.Y or CurrentCanvasSize.Y.Offset

					if ScrollFrame.AutomaticCanvasSize == Enum.AutomaticSize.X then
						sizeY = 0 elseif ScrollFrame.AutomaticCanvasSize == Enum.AutomaticSize.Y then
						sizeX = 0
					end

					local NewCanvasSize = Vector2.new(
						sizeX,
						sizeY
					)

					ScrollFrame.CanvasSize = UDim2.new(0, NewCanvasSize.X, 0, NewCanvasSize.Y)
				else
					local Padding = ScrollFrame:FindFirstChildOfClass("UIPadding")

					local ContentSize = Layout.AbsoluteContentSize
					local sizeX, sizeY = ContentSize.X, ContentSize.Y

					if Padding then
						sizeX += (Padding.PaddingLeft.Offset + Padding.PaddingRight.Offset)
						sizeY += (Padding.PaddingBottom.Offset + Padding.PaddingTop.Offset)
					end

					if ScrollFrame.AutomaticCanvasSize == Enum.AutomaticSize.X then
						sizeY = 0
					elseif ScrollFrame.AutomaticCanvasSize == Enum.AutomaticSize.Y then
						sizeX = 0
					end
					ScrollFrame.CanvasSize = UDim2.new(0, sizeX, 0, sizeY)
				end
			end
		end)

		ScrollFrame.AncestryChanged:Connect(function()
			if ScrollFrame.Parent == nil then
				Emulator:Destroy()
				SmoothConnection:Disconnect()
				SizeConnection:Disconnect()
			end
		end)
	end
end

function Modules.SearchModule()
	local SearchFunctions = {}
	local validTypes = {
		["Frame"] = true,
		["TextButton"] = true,
		["ImageButton"] = true,
		["ImageLabel"] = true,
		["TextLabel"] = true,
	}

	function GetAllItems(guiContainer: Frame | ScrollingFrame)
		local itemFrames = {}

		for _, child in pairs(guiContainer:GetChildren()) do
			if validTypes[child.ClassName] then
				table.insert(itemFrames, child)
			end
		end

		return itemFrames
	end

	function GetSearchTags(itemFrames: {})
		local itemTags = {}

		for _, itemFrame in pairs(itemFrames) do
			itemTags[itemFrame] = {}

			local hasTags = false
			if itemFrame:FindFirstChild("SearchTags") then
				for _, searchTag in pairs(itemFrame.SearchTags:GetChildren()) do
					local tag = searchTag.Value
					tag = string.lower(tag)

					table.insert(itemTags[itemFrame], tag)
					hasTags = true
				end
			end
			if not hasTags then
				local nameTag = string.lower(itemFrame.Name)
				table.insert(itemTags[itemFrame], nameTag)
			end
		end

		return itemTags
	end

	function SelectItems(query: {}, itemTags: {})
		local selectionRanked = {}
		for itemFrame, searchTags in pairs(itemTags) do
			local queryCopy = table.clone(query)
			for _, tag in pairs(searchTags) do
				for wordIndex, queriedWord in pairs(queryCopy) do
					if string.find(tag, queriedWord, 1, true) then
						table.remove(queryCopy, wordIndex)
						break
					end
				end
			end

			if #queryCopy == 0 then
				table.insert(selectionRanked, {itemFrame, #query})
			end
		end

		table.sort(selectionRanked, function(a, b)
			return a[2] > b[2]
		end)

		local selection = {}

		for _, selectionPair in ipairs(selectionRanked) do
			table.insert(selection, selectionPair[1])
		end

		return selection
	end

	function DisplaySelection(selection: {}, guiContainer: Frame | ScrollingFrame)
		if not selection then 
			selection = guiContainer:GetChildren()
		end

		for _, child in pairs(guiContainer:GetChildren()) do
			if validTypes[child.ClassName] then
				if table.find(selection, child) then
					child.Visible = true
				else
					child.Visible = false
				end
			end
		end
	end

	function GetSearchQuery(searchBar: TextBox)
		local text = searchBar.Text
		text = string.lower(text)

		if text == "" then 
			text = nil 
		else
			text = string.split(text, " ")

			for wordIndex, word in pairs(text) do
				if word == "" or word == " " then
					table.remove(text, wordIndex)
				end
			end
		end

		return text
	end

	function OnSearched(searchBar: TextBox, guiContainer: Frame | ScrollingFrame)
		local searchText = GetSearchQuery(searchBar)
		if not searchText then
			DisplaySelection(nil, guiContainer)
		else
			local allItems = GetAllItems(guiContainer)
			local allSearchTags = GetSearchTags(allItems)
			local selection = SelectItems(searchText, allSearchTags)

			DisplaySelection(selection, guiContainer)
		end
	end

	function SetupSearchBar(searchBar: TextBox, guiContainer: Frame)
		OnSearched(searchBar, guiContainer)
		searchBar:GetPropertyChangedSignal("Text"):Connect(function()
			OnSearched(searchBar, guiContainer)
		end)
	end


	return SetupSearchBar
end

function Modules.Ripple()
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")
	local RunService = game:GetService("RunService")

	local Ripple = {}
	Ripple.__index = Ripple

	Ripple.DefaultColor = Color3.fromRGB(25, 118, 210)
	Ripple.DefaultTransparency = 0.85
	Ripple.DefaultSpeed = 0.5

	-- Utility
	local function CalculateDistance(pointA, pointB)
		return (pointB - pointA).Magnitude
	end

	local function CreateCircle(color, transparency, zIndex)
		local circle = Instance.new("Frame")
		circle.BackgroundColor3 = color
		circle.BackgroundTransparency = transparency
		circle.AnchorPoint = Vector2.new(0.5, 0.5)
		circle.Size = UDim2.new(0, 0, 0, 0)
		circle.ZIndex = zIndex or 1

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0.5, 0)
		corner.Parent = circle

		return circle
	end

	function Ripple:PopRipple(guiElement, options)
		local player = Players.LocalPlayer
		local mouse = player:GetMouse()

		local color = options and options.Color or self.DefaultColor
		local transparency = options and options.Transparency or self.DefaultTransparency
		local speed = options and options.Speed or self.DefaultSpeed

		local mousePos = Vector2.new(mouse.X, mouse.Y)
		local absPos = guiElement.AbsolutePosition
		local absSize = guiElement.AbsoluteSize
		local relativePos = mousePos - absPos

		local circle = CreateCircle(color, transparency, guiElement.ZIndex + 1)
		circle.Position = UDim2.new(0, relativePos.X, 0, relativePos.Y)
		circle.Parent = guiElement

		local topLeft = CalculateDistance(relativePos, Vector2.new(0, 0))
		local topRight = CalculateDistance(relativePos, Vector2.new(absSize.X, 0))
		local bottomRight = CalculateDistance(relativePos, absSize)
		local bottomLeft = CalculateDistance(relativePos, Vector2.new(0, absSize.Y))
		local maxDist = math.max(topLeft, topRight, bottomRight, bottomLeft) * 2

		local tweenOut = TweenService:Create(circle, TweenInfo.new(speed), {
			Size = UDim2.new(0, maxDist, 0, maxDist)
		})
		local fadeOut = TweenService:Create(circle, TweenInfo.new(speed * 2), {
			BackgroundTransparency = 1,
		})
		tweenOut:Play()
		fadeOut:Play()

		tweenOut.Completed:Connect(function()
			task.wait(speed)
			circle:Destroy()
		end)
	end

	return Ripple

end

function Modules.Resuponshibu()
	--[[
		サーバーによって作成されたレスポンシブモジュール
	]]

	local Resuponshibu = {}
	Resuponshibu.__index = Resuponshibu

	function Resuponshibu.new()
		local self = setmetatable({}, Resuponshibu)

		self._services = {
			RunService = game:GetService("RunService"),
			TweenService = game:GetService("TweenService"),
		}

		self._scale = Instance.new("UIScale")
		self._connection = nil
		self._startChangeSize = 0
		self._smoothChange = false

		return self
	end

	function Resuponshibu:Set(gui, startChangeSize, smooth : boolean?)
		--assert(gui:IsA("GuiObject"), "Argument 'gui' must be a valid GUI object.")

		self._scale.Parent = gui
		self._scale.Name = "@Resuponshiburendaringu"

		self._startChangeSize = startChangeSize
		self._smoothChange = smooth

		if self._connection then
			self._connection:Disconnect()
		end

		self._connection = self._services.RunService.RenderStepped:Connect(function()
			self:_update()
		end)
	end

	function Resuponshibu:Destroy()
		if self._connection then
			self._connection:Disconnect()
			self._connection = nil
		end

		self._scale.Parent = nil
		self._scale:Destroy()
	end

	function Resuponshibu:_update()
		local cam = workspace.CurrentCamera
		if not cam then return end

		local vps = cam.ViewportSize
		local newScale = 0

		newScale = (vps.X + vps.Y)/self._startChangeSize
		if newScale >= 1 then
			newScale = 1
		end

		if self._smoothChange then
			self:_tween(self._scale, TweenInfo.new(.25), {Scale = newScale})
		else
			self._scale.Scale = newScale
		end
	end

	function Resuponshibu:_tween(object, info, goal)
		local tween = self._services.TweenService:Create(object, info, goal)
		tween:Play()
		return tween
	end

	return Resuponshibu
end

function Modules.Fade()
	local TweenService = game:GetService("TweenService")

	local Fade = {}

	local EXCLUDED_NAMES = {"Container"}
	local EASING_STYLE = Enum.EasingStyle.Quint
	local EASING_DIRECTION = Enum.EasingDirection.InOut

	function Fade:Tween(obj, info, goal)
		local tween = TweenService:Create(obj, info, goal)
		tween:Play()
		return tween
	end

	function Fade:_checkIfValid(obj)
		local VALID_CLASSES = {
			"TextButton", "TextLabel", "TextBox", "ScrollingFrame", "ImageLabel", "ImageButton", 
			"UIStroke", "BasePart", "MeshPart", "Frame", "Texture", "Decal", "Folder"
		}

		return table.find(VALID_CLASSES, obj.ClassName) and not table.find(EXCLUDED_NAMES, obj.Name)
	end

	function Fade:_storeInitialTransparency(obj, Attributes)
		for _, attr in ipairs(Attributes) do
			if obj[attr] ~= nil and obj:GetAttribute("Initial" .. attr) == nil then
				obj:SetAttribute("Initial" .. attr, obj[attr])
			end
		end
	end

	function Fade:_checkForAttributes(obj)
		local attributeMap = {
			TextButton = {"BackgroundTransparency", "TextTransparency"},
			TextLabel = {"BackgroundTransparency", "TextTransparency"},
			TextBox = {"BackgroundTransparency", "TextTransparency"},
			ScrollingFrame = {"BackgroundTransparency", "ScrollBarImageTransparency"},
			ImageLabel = {"BackgroundTransparency", "ImageTransparency"},
			ImageButton = {"BackgroundTransparency", "ImageTransparency"},
			UIStroke = {"Transparency"},
			Frame = {"BackgroundTransparency"},
			BasePart = {"Transparency"},
			MeshPart = {"Transparency"},
			Texture = {"Transparency"},
			Decal = {"Transparency"}
		}

		local attributes = attributeMap[obj.ClassName]
		if attributes then
			self:_storeInitialTransparency(obj, attributes)
		end
	end

	function Fade:SetTransparency(obj, transparency, speed)
		local function applyTransparency(obj, transparency)
			local goals = {}

			for _, attr in ipairs({"Transparency", "BackgroundTransparency", "ImageTransparency", "TextTransparency", "ScrollBarImageTransparency"}) do
				local InitialAttr = "Initial" .. attr
				if obj:GetAttribute(InitialAttr) ~= nil then
					goals[attr] = (transparency == 0) and obj:GetAttribute(InitialAttr) or transparency
				end
			end

			if next(goals) then
				self:Tween(obj, TweenInfo.new(speed, EASING_STYLE, EASING_DIRECTION), goals)
			end
		end

		local function scan(obj)
			if self:_checkIfValid(obj) then
				self:_checkForAttributes(obj)
				applyTransparency(obj, transparency)
			else
				return
			end

			for _, inst in ipairs(obj:GetChildren()) do
				scan(inst)
			end
		end

		scan(obj)
	end

	function Fade:FadeClose(obj, speed)
		self:SetTransparency(obj, 1, speed)
	end

	function Fade:FadeOpen(obj, speed)
		self:SetTransparency(obj, 0, speed)
	end

	return Fade
end

function Modules.Blur()
	local Lighting          = game:GetService("Lighting")
	local runService        = game:FindService("RunService")
	local camera			= workspace.CurrentCamera

	local BLUR_SIZE         = Vector2.one * 13
	local PART_SIZE         = 0.001
	local PART_TRANSPARENCY = 1
	local START_INTENSITY	= 0.25

	local BLUR_OBJ          = Instance.new("DepthOfFieldEffect")
	BLUR_OBJ.FarIntensity   = 0
	BLUR_OBJ.NearIntensity  = 1
	BLUR_OBJ.FocusDistance  = 0
	BLUR_OBJ.InFocusRadius  = 0
	BLUR_OBJ.Parent         = camera

	local PartsList         = {}
	local BlursList         = {}
	local BlurObjects       = {}
	local BlurredGui        = {}

	BlurredGui.__index      = BlurredGui

	function rayPlaneIntersect(planePos, planeNormal, rayOrigin, rayDirection)
		local n = planeNormal
		local d = rayDirection
		local v = rayOrigin - planePos

		local num = n.x*v.x + n.y*v.y + n.z*v.z
		local den = n.x*d.x + n.y*d.y + n.z*d.z
		local a = -num / den

		return rayOrigin + a * rayDirection, a
	end

	function rebuildPartsList()
		PartsList = {}
		BlursList = {}
		for blurObj, part in (BlurObjects) do
			table.insert(PartsList, part)
			table.insert(BlursList, blurObj)
		end
	end

	function BlurredGui.new(guiObject: GuiObject, shape)
		local blurPart        = Instance.new("Part")
		blurPart.Size         = Vector3.one * PART_SIZE
		blurPart.Anchored     = true
		blurPart.CanCollide   = false
		blurPart.CanTouch     = false
		blurPart.Material     = Enum.Material.Glass
		blurPart.Transparency = PART_TRANSPARENCY
		blurPart.Parent       = workspace.CurrentCamera

		local highlight = Instance.new("Highlight")
		highlight.Enabled = false
		highlight.Parent = blurPart

		local mesh
		if (shape == "Rectangle") then
			mesh        = Instance.new("BlockMesh")
			mesh.Parent = blurPart
		elseif (shape == "Oval") then
			mesh          = Instance.new("SpecialMesh")
			mesh.MeshType = Enum.MeshType.Sphere
			mesh.Parent   = blurPart
		end

		local ignoreInset = false
		local currentObj  = guiObject

		while true do
			currentObj = currentObj.Parent
			if (currentObj and currentObj:IsA("LayerCollector")) then
				ignoreInset = not currentObj.IgnoreGuiInset
				break
			elseif (currentObj == nil) then
				break
			end
		end

		local new = setmetatable({
			Frame          = guiObject;
			Part           = blurPart;
			Mesh           = mesh;
			IgnoreGuiInset = ignoreInset;
		}, BlurredGui)

		BlurObjects[new] = blurPart
		rebuildPartsList()

		runService:BindToRenderStep("...", Enum.RenderPriority.Camera.Value + 1, function()
			blurPart.CFrame = camera.CFrame
			BlurredGui.updateAll()
		end)

		--guiObject.Parent:GetPropertyChangedSignal("Visible"):Connect(function(...: any) 
		--highlight.Parent = if guiObject.Parent.Visible then blurPart else BLUR_OBJ
		--end)

		guiObject.Destroying:Once(function()
			blurPart:Destroy()
			BlurObjects[new] = nil
			rebuildPartsList()
		end)

		return new
	end

	function updateGui(blurObj)
		if (not blurObj.Mesh or not blurObj.Frame.Visible) then
			blurObj.Part.Transparency = 1
			return
		end

		local camera = workspace.CurrentCamera
		local frame  = blurObj.Frame
		local part   = blurObj.Part
		local mesh   = blurObj.Mesh

		part.Transparency = PART_TRANSPARENCY

		local corner0 = frame.AbsolutePosition + BLUR_SIZE
		local corner1 = corner0 + frame.AbsoluteSize - BLUR_SIZE*2
		local ray0, ray1

		if (blurObj.IgnoreGuiInset) then
			ray0 = camera:ViewportPointToRay(corner0.X, corner0.Y, 1)
			ray1 = camera:ViewportPointToRay(corner1.X, corner1.Y, 1)
		else
			ray0 = camera:ScreenPointToRay(corner0.X, corner0.Y, 1)
			ray1 = camera:ScreenPointToRay(corner1.X, corner1.Y, 1)
		end

		local planeOrigin = camera.CFrame.Position + camera.CFrame.LookVector * (0.05 - camera.NearPlaneZ)
		local planeNormal = camera.CFrame.LookVector
		local pos0 = rayPlaneIntersect(planeOrigin, planeNormal, ray0.Origin, ray0.Direction)
		local pos1 = rayPlaneIntersect(planeOrigin, planeNormal, ray1.Origin, ray1.Direction)

		local pos0 = camera.CFrame:PointToObjectSpace(pos0)
		local pos1 = camera.CFrame:PointToObjectSpace(pos1)

		local size   = pos1 - pos0
		local center = (pos0 + pos1)/2

		mesh.Offset = center
		mesh.Scale  = size / PART_SIZE
	end

	function BlurredGui.updateAll()
		task.spawn(pcall, function()
			for i = 1, #BlursList do
				updateGui(BlursList[i])
			end

			local cframes = table.create(#BlursList, workspace.CurrentCamera.CFrame)
			workspace:BulkMoveTo(PartsList, cframes, Enum.BulkMoveMode.FireCFrameChanged)
		end)
		--BLUR_OBJ.FocusDistance = 0.25 - camera.NearPlaneZ
	end

	function BlurredGui:Destroy()
		self.Part:Destroy()
		BLUR_OBJ:Destroy()
		BlurObjects[self] = nil
		rebuildPartsList()
	end

	return BlurredGui
end

function Modules.Snapdragon()
	local function getModules()
		local Modules = {}

		Modules.Maid = function()
			-- Manages the cleaning of events and other things.
			-- Useful for encapsulating state and make deconstructors easy
			-- @classmod Maid
			-- @see Signal

			local Maid = {}
			Maid.ClassName = "Maid"

			--- Returns a new Maid object
			-- @constructor Maid.new()
			-- @treturn Maid
			function Maid.new()
				local self = {}

				self._tasks = {}

				return setmetatable(self, Maid)
			end

			--- Returns Maid[key] if not part of Maid metatable
			-- @return Maid[key] value
			function Maid:__index(index)
				if Maid[index] then
					return Maid[index]
				else
					return self._tasks[index]
				end
			end

			--- Add a task to clean up
			-- @usage
			-- Maid[key] = (function)         Adds a task to perform
			-- Maid[key] = (event connection) Manages an event connection
			-- Maid[key] = (Maid)             Maids can act as an event connection, allowing a Maid to have other maids to clean up.
			-- Maid[key] = (Object)           Maids can cleanup objects with a `Destroy` method
			-- Maid[key] = nil                Removes a named task. If the task is an event, it is disconnected. If it is an object,
			--                                it is destroyed.
			function Maid:__newindex(index, newTask)
				if Maid[index] ~= nil then
					error(("'%s' is reserved"):format(tostring(index)), 2)
				end

				local tasks = self._tasks
				local oldTask = tasks[index]
				tasks[index] = newTask

				if oldTask then
					if type(oldTask) == "function" then
						oldTask()
					elseif typeof(oldTask) == "RBXScriptConnection" then
						oldTask:Disconnect()
					elseif oldTask.Destroy then
						oldTask:Destroy()
					end
				end
			end

			--- Same as indexing, but uses an incremented number as a key.
			-- @param task An item to clean
			-- @treturn number taskId
			function Maid:GiveTask(task)
				assert(task, "Task cannot be false or nil")

				local taskId = #self._tasks+1
				self[taskId] = task

				if type(task) == "table" and (not task.Destroy) then
					warn("[Maid.GiveTask] - Gave table task without .Destroy\n\n" .. debug.traceback())
				end

				return taskId
			end

			function Maid:GivePromise(promise)
				if not promise:IsPending() then
					return promise
				end

				local newPromise = promise.resolved(promise)
				local id = self:GiveTask(newPromise)

				-- Ensure GC
				newPromise:Finally(function()
					self[id] = nil
				end)

				return newPromise
			end

			--- Cleans up all tasks.
			-- @alias Destroy
			function Maid:DoCleaning()
				local tasks = self._tasks

				-- Disconnect all events first as we know this is safe
				for index, task in pairs(tasks) do
					if typeof(task) == "RBXScriptConnection" then
						tasks[index] = nil
						task:Disconnect()
					end
				end

				-- Clear out tasks table completely, even if clean up tasks add more tasks to the maid
				local index, task = next(tasks)
				while task ~= nil do
					tasks[index] = nil
					if type(task) == "function" then
						task()
					elseif typeof(task) == "RBXScriptConnection" then
						task:Disconnect()
					elseif task.Destroy then
						task:Destroy()
					end
					index, task = next(tasks)
				end
			end

			--- Alias for DoCleaning()
			-- @function Destroy
			Maid.Destroy = Maid.DoCleaning

			return Maid
		end
		Modules.Signal = function()
			local Signal = {}
			Signal.__index = Signal

			function Signal.new()
				return setmetatable({
					Bindable = Instance.new("BindableEvent");
				}, Signal)
			end

			function Signal:Connect(Callback)
				return self.Bindable.Event:Connect(function(GetArgumentStack)
					Callback(GetArgumentStack())
				end)
			end

			function Signal:Fire(...)
				local Arguments = { ... }
				local n = select("#", ...)

				self.Bindable:Fire(function()
					return unpack(Arguments, 1, n)
				end)
			end

			function Signal:Wait()
				return self.Bindable.Event:Wait()()
			end

			function Signal:Destroy()
				self.Bindable:Destroy()
			end

			return Signal
		end

		Modules.SnapdragonController = function()
			local UserInputService = game:GetService("UserInputService")

			local objectAssign = Modules.objectAssign()
			local Signal = Modules.Signal()
			local SnapdragonRef = Modules.SnapdragonRef()
			local t = Modules.t()
			local Maid = Modules.Maid()

			local MarginTypeCheck = t.interface({
				Vertical = t.optional(t.Vector2),
				Horizontal = t.optional(t.Vector2),
			})

			local AxisEnumCheck = t.literal("XY", "X", "Y")
			local DragRelativeToEnumCheck = t.literal("LayerCollector", "Parent")
			local DragPositionModeEnumCheck = t.literal("Offset", "Scale")

			local OptionsInterfaceCheck = t.interface({
				DragGui = t.union(t.instanceIsA("GuiObject"), SnapdragonRef.is),
				DragThreshold = t.number,
				DragGridSize = t.number,
				SnapMargin = MarginTypeCheck,
				SnapMarginThreshold = MarginTypeCheck,
				SnapAxis = AxisEnumCheck,
				DragAxis = AxisEnumCheck,
				DragRelativeTo = DragRelativeToEnumCheck,
				SnapEnabled = t.boolean,
				DragPositionMode = DragPositionModeEnumCheck,
			})

			local SnapdragonController = {}
			SnapdragonController.__index = SnapdragonController

			local controllers = setmetatable({}, {__mode = "k"})

			function SnapdragonController.new(gui, options)
				options = objectAssign({
					DragGui = gui,
					DragThreshold = 0,
					DragGridSize = 0,
					SnapMargin = {},
					SnapMarginThreshold = {},
					SnapEnabled = true,
					SnapAxis = "XY",
					DragAxis = "XY",
					DragRelativeTo = "LayerCollector",
					DragPositionMode = "Scale",
				}, options)

				assert(OptionsInterfaceCheck(options))

				local self = setmetatable({}, SnapdragonController)
				-- Basic immutable values
				local dragGui = options.DragGui
				self.dragGui = dragGui
				self.gui = gui
				self.originPosition = dragGui.Position

				self.snapEnabled = options.SnapEnabled
				self.snapAxis = options.SnapAxis

				self.dragAxis = options.DragAxis
				self.dragThreshold = options.DragThreshold
				self.dragRelativeTo = options.DragRelativeTo
				self.dragGridSize = options.DragGridSize
				self.dragPositionMode = options.DragPositionMode

				self.enabled = true

				-- Events
				local DragEnded = Signal.new()
				local DragBegan = Signal.new()
				self.DragEnded = DragEnded
				self.DragBegan = DragBegan

				-- Advanced stuff
				self.maid = Maid.new()
				self:SetSnapEnabled(options.SnapEnabled)
				self:SetSnapMargin(options.SnapMargin)
				self:SetSnapThreshold(options.SnapMarginThreshold)

				return self
			end

			function SnapdragonController:SetSnapEnabled(snapEnabled)
				assert(t.boolean(snapEnabled))
				self.snapEnabled = snapEnabled
			end

			function SnapdragonController:SetEnabled(boolean)
				assert(t.boolean(boolean))
				self.enabled = boolean
			end

			function SnapdragonController:SetSnapMargin(snapMargin)
				assert(MarginTypeCheck(snapMargin))
				local snapVerticalMargin = snapMargin.Vertical or Vector2.new()
				local snapHorizontalMargin = snapMargin.Horizontal or Vector2.new()
				self.snapVerticalMargin = snapVerticalMargin
				self.snapHorizontalMargin = snapHorizontalMargin
			end

			function SnapdragonController:SetSnapThreshold(snapThreshold)
				assert(MarginTypeCheck(snapThreshold))
				local snapThresholdVertical = snapThreshold.Vertical or Vector2.new()
				local snapThresholdHorizontal = snapThreshold.Horizontal or Vector2.new()
				self.snapThresholdVertical = snapThresholdVertical
				self.snapThresholdHorizontal = snapThresholdHorizontal
			end

			function SnapdragonController:GetDragGui()
				local gui = self.dragGui
				if SnapdragonRef.is(gui) then
					return gui:Get(), gui
				else
					return gui, gui
				end
			end

			function SnapdragonController:GetGui()
				local gui = self.gui
				if SnapdragonRef.is(gui) then
					return gui:Get()
				else
					return gui
				end
			end

			function SnapdragonController:ResetPosition()
				self.dragGui.Position = self.originPosition
			end

			function SnapdragonController:__bindControllerBehaviour()
				local maid = self.maid

				local gui = self:GetGui()
				local dragGui = self:GetDragGui()
				local snap = self.snapEnabled
				local DragEnded = self.DragEnded
				local DragBegan = self.DragBegan
				local snapAxis = self.snapAxis
				local dragAxis = self.dragAxis
				local dragRelativeTo = self.dragRelativeTo
				local dragGridSize = self.dragGridSize
				local dragPositionMode = self.dragPositionMode

				local dragging
				local dragInput
				local dragStart
				local startPos


				local function update(input)
					if not self.enabled then
						return
					end

					local snapHorizontalMargin = self.snapHorizontalMargin
					local snapVerticalMargin = self.snapVerticalMargin
					local snapThresholdVertical = self.snapThresholdVertical
					local snapThresholdHorizontal = self.snapThresholdHorizontal

					local screenSize = workspace.CurrentCamera.ViewportSize
					local delta = input.Position - dragStart

					if dragAxis == "X" then
						delta = Vector3.new(delta.X, 0, 0)
					elseif dragAxis == "Y" then
						delta = Vector3.new(0, delta.Y, 0)
					end

					gui = dragGui or gui

					local host = gui:FindFirstAncestorOfClass("ScreenGui") or gui:FindFirstAncestorOfClass("PluginGui")
					local topLeft = Vector2.new()
					if host and dragRelativeTo == "LayerCollector" then
						screenSize = host.AbsoluteSize
					elseif dragRelativeTo == "Parent" then
						assert(gui.Parent:IsA("GuiObject"), "DragRelativeTo is set to Parent, but the parent is not a GuiObject!")
						screenSize = gui.Parent.AbsoluteSize
					end

					if snap then
						local scaleOffsetX = screenSize.X * startPos.X.Scale
						local scaleOffsetY = screenSize.Y * startPos.Y.Scale
						local resultingOffsetX = startPos.X.Offset + delta.X
						local resultingOffsetY = startPos.Y.Offset + delta.Y
						local absSize = gui.AbsoluteSize + Vector2.new(snapHorizontalMargin.Y, snapVerticalMargin.Y + topLeft.Y)

						local anchorOffset = Vector2.new(
							gui.AbsoluteSize.X * gui.AnchorPoint.X,
							gui.AbsoluteSize.Y * gui.AnchorPoint.Y
						)

						if snapAxis == "XY" or snapAxis == "X" then
							local computedMinX = snapHorizontalMargin.X + anchorOffset.X
							local computedMaxX = screenSize.X - absSize.X + anchorOffset.X

							if (resultingOffsetX + scaleOffsetX) > computedMaxX - snapThresholdHorizontal.Y then
								resultingOffsetX = computedMaxX - scaleOffsetX
							elseif (resultingOffsetX + scaleOffsetX) < computedMinX + snapThresholdHorizontal.X then
								resultingOffsetX = -scaleOffsetX + computedMinX
							end
						end

						if snapAxis == "XY" or snapAxis == "Y" then
							local computedMinY = snapVerticalMargin.X + anchorOffset.Y
							local computedMaxY = screenSize.Y - absSize.Y + anchorOffset.Y

							if (resultingOffsetY + scaleOffsetY) > computedMaxY - snapThresholdVertical.Y then
								resultingOffsetY = computedMaxY - scaleOffsetY
							elseif (resultingOffsetY + scaleOffsetY) < computedMinY + snapThresholdVertical.X then
								resultingOffsetY = -scaleOffsetY + computedMinY
							end
						end

						if dragGridSize > 0 then
							resultingOffsetX = math.floor(resultingOffsetX / dragGridSize) * dragGridSize
							resultingOffsetY = math.floor(resultingOffsetY / dragGridSize) * dragGridSize
						end

						if dragPositionMode == "Offset" then
							gui.Position = UDim2.new(
								startPos.X.Scale, resultingOffsetX,
								startPos.Y.Scale, resultingOffsetY
							)
						else
							gui.Position = UDim2.new(
								startPos.X.Scale + (resultingOffsetX / screenSize.X),
								0,
								startPos.Y.Scale + (resultingOffsetY / screenSize.Y),
								0
							)
						end
					else
						if dragGridSize > 0 then
							delta = Vector2.new(
								math.floor(delta.X / dragGridSize) * dragGridSize,
								math.floor(delta.Y / dragGridSize) * dragGridSize
							)
						end

						gui.Position =
							UDim2.new(
								startPos.X.Scale,
								startPos.X.Offset + delta.X,
								startPos.Y.Scale,
								startPos.Y.Offset + delta.Y
							)
					end
				end

				maid.guiInputBegan = gui.InputBegan:Connect(
					function(input)
						if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
							dragging = true
							dragStart = input.Position
							startPos = (dragGui or gui).Position
							DragBegan:Fire(dragStart)

							input.Changed:Connect(
								function()
									if input.UserInputState == Enum.UserInputState.End then
										dragging = false
										DragEnded:Fire(input.Position)
									end
								end
							)
						end
					end
				)

				maid.guiInputChanged = gui.InputChanged:Connect(
					function(input)
						if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
							dragInput = input
						end
					end
				)

				maid.uisInputChanged = UserInputService.InputChanged:Connect(
					function(input)
						if input == dragInput and dragging then
							update(input)
						end
					end
				)
			end

			function SnapdragonController:Connect()
				if self.locked then
					error("[SnapdragonController] Cannot connect locked controller!", 2)
				end

				local _, ref = self:GetDragGui()

				if not controllers[ref] or controllers[ref] == self then
					controllers[ref] = self
					self:__bindControllerBehaviour()
				else
					error("[SnapdragonController] This object is already bound to a controller")
				end
				return self
			end

			function SnapdragonController:Disconnect()
				if self.locked then
					error("[SnapdragonController] Cannot disconnect locked controller!", 2)
				end

				local _, ref = self:GetDragGui()

				local controller = controllers[ref]
				if controller then
					self.maid:DoCleaning()
					controllers[ref] = nil
				end
			end

			function SnapdragonController:Destroy()
				self:Disconnect()
				self.DragEnded:Destroy()
				self.DragBegan:Destroy()
				self.DragEnded = nil
				self.DragBegan = nil
				self.locked = true
			end

			return SnapdragonController
		end

		Modules.SnapdragonRef = function()
			local refs = setmetatable({}, {__mode = "k"})

			local SnapdragonRef = {}
			SnapdragonRef.__index = SnapdragonRef

			function SnapdragonRef.new(current)
				local ref = setmetatable({
					current = current
				}, SnapdragonRef)
				refs[ref] = ref
				return ref
			end

			function SnapdragonRef:Update(current)
				self.current = current
			end

			function SnapdragonRef:Get()
				return self.current
			end

			function SnapdragonRef.is(ref)
				return refs[ref] ~= nil
			end

			return SnapdragonRef
		end

		Modules.Symbol = function()
	--[[
	A 'Symbol' is an opaque marker type.

	Symbols have the type 'userdata', but when printed to the console, the name
	of the symbol is shown.
]]

			local Symbol = {}

--[[
	Creates a Symbol with the given name.

	When printed or coerced to a string, the symbol will turn into the string
	given as its name.
]]
			function Symbol.named(name)
				assert(type(name) == "string", "Symbols must be created using a string name!")

				local self = newproxy(true)

				local wrappedName = ("Symbol(%s)"):format(name)

				getmetatable(self).__tostring = function()
					return wrappedName
				end

				return self
			end

			return Symbol
		end

		Modules.objectAssign = function()
			local function objectAssign(target, ...)
				local targets = {...}
				for _, t in pairs(targets) do
					for k ,v in pairs(t) do
						target[k] = v;
					end
				end
				return target
			end

			return objectAssign
		end

		Modules.t = function()
			-- t: a runtime typechecker for Roblox

			-- regular lua compatibility
			local typeof = typeof or type

			local function primitive(typeName)
				return function(value)
					local valueType = typeof(value)
					if valueType == typeName then
						return true
					else
						return false, string.format("%s expected, got %s", typeName, valueType)
					end
				end
			end

			local t = {}

--[[**
	matches any type except nil

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			function t.any(value)
				if value ~= nil then
					return true
				else
					return false, "any expected, got nil"
				end
			end

			--Lua primitives

--[[**
	ensures Lua primitive boolean type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.boolean = primitive("boolean")

--[[**
	ensures Lua primitive thread type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.thread = primitive("thread")

--[[**
	ensures Lua primitive callback type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.callback = primitive("function")

--[[**
	ensures Lua primitive none type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.none = primitive("nil")

--[[**
	ensures Lua primitive string type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.string = primitive("string")

--[[**
	ensures Lua primitive table type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.table = primitive("table")

--[[**
	ensures Lua primitive userdata type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.userdata = primitive("userdata")

--[[**
	ensures value is a number and non-NaN

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			function t.number(value)
				local valueType = typeof(value)
				if valueType == "number" then
					if value == value then
						return true
					else
						return false, "unexpected NaN value"
					end
				else
					return false, string.format("number expected, got %s", valueType)
				end
			end

--[[**
	ensures value is NaN

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			function t.nan(value)
				if value ~= value then
					return true
				else
					return false, "unexpected non-NaN value"
				end
			end

			-- roblox types

--[[**
	ensures Roblox Axes type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Axes = primitive("Axes")

--[[**
	ensures Roblox BrickColor type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.BrickColor = primitive("BrickColor")

--[[**
	ensures Roblox CFrame type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.CFrame = primitive("CFrame")

--[[**
	ensures Roblox Color3 type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Color3 = primitive("Color3")

--[[**
	ensures Roblox ColorSequence type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.ColorSequence = primitive("ColorSequence")

--[[**
	ensures Roblox ColorSequenceKeypoint type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.ColorSequenceKeypoint = primitive("ColorSequenceKeypoint")

--[[**
	ensures Roblox DockWidgetPluginGuiInfo type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.DockWidgetPluginGuiInfo = primitive("DockWidgetPluginGuiInfo")

--[[**
	ensures Roblox Faces type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Faces = primitive("Faces")

--[[**
	ensures Roblox Instance type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Instance = primitive("Instance")

--[[**
	ensures Roblox NumberRange type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.NumberRange = primitive("NumberRange")

--[[**
	ensures Roblox NumberSequence type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.NumberSequence = primitive("NumberSequence")

--[[**
	ensures Roblox NumberSequenceKeypoint type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.NumberSequenceKeypoint = primitive("NumberSequenceKeypoint")

--[[**
	ensures Roblox PathWaypoint type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.PathWaypoint = primitive("PathWaypoint")

--[[**
	ensures Roblox PhysicalProperties type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.PhysicalProperties = primitive("PhysicalProperties")

--[[**
	ensures Roblox Random type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Random = primitive("Random")

--[[**
	ensures Roblox Ray type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Ray = primitive("Ray")

--[[**
	ensures Roblox Rect type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Rect = primitive("Rect")

--[[**
	ensures Roblox Region3 type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Region3 = primitive("Region3")

--[[**
	ensures Roblox Region3int16 type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Region3int16 = primitive("Region3int16")

--[[**
	ensures Roblox TweenInfo type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.TweenInfo = primitive("TweenInfo")

--[[**
	ensures Roblox UDim type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.UDim = primitive("UDim")

--[[**
	ensures Roblox UDim2 type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.UDim2 = primitive("UDim2")

--[[**
	ensures Roblox Vector2 type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Vector2 = primitive("Vector2")

--[[**
	ensures Roblox Vector3 type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Vector3 = primitive("Vector3")

--[[**
	ensures Roblox Vector3int16 type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Vector3int16 = primitive("Vector3int16")

			-- roblox enum types

--[[**
	ensures Roblox Enum type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.Enum = primitive("Enum")

--[[**
	ensures Roblox EnumItem type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.EnumItem = primitive("EnumItem")

--[[**
	ensures Roblox RBXScriptSignal type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.RBXScriptSignal = primitive("RBXScriptSignal")

--[[**
	ensures Roblox RBXScriptConnection type

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			t.RBXScriptConnection = primitive("RBXScriptConnection")

--[[**
	ensures value is a given literal value

	@param literal The literal to use

	@returns A function that will return true iff the condition is passed
**--]]
			function t.literal(...)
				local size = select("#", ...)
				if size == 1 then
					local literal = ...
					return function(value)
						if value ~= literal then
							return false, string.format("expected %s, got %s", tostring(literal), tostring(value))
						end

						return true
					end
				else
					local literals = {}
					for i = 1, size do
						local value = select(i, ...)
						literals[i] = t.literal(value)
					end

					return t.union(table.unpack(literals, 1, size))
				end
			end

--[[**
	DEPRECATED
	Please use t.literal
**--]]
			t.exactly = t.literal

--[[**
	Returns a t.union of each key in the table as a t.literal

	@param keyTable The table to get keys from

	@returns True iff the condition is satisfied, false otherwise
**--]]
			function t.keyOf(keyTable)
				local keys = {}
				local length = 0
				for key in pairs(keyTable) do
					length = length + 1
					keys[length] = key
				end

				return t.literal(table.unpack(keys, 1, length))
			end

--[[**
	Returns a t.union of each value in the table as a t.literal

	@param valueTable The table to get values from

	@returns True iff the condition is satisfied, false otherwise
**--]]
			function t.valueOf(valueTable)
				local values = {}
				local length = 0
				for _, value in pairs(valueTable) do
					length = length + 1
					values[length] = value
				end

				return t.literal(table.unpack(values, 1, length))
			end

--[[**
	ensures value is an integer

	@param value The value to check against

	@returns True iff the condition is satisfied, false otherwise
**--]]
			function t.integer(value)
				local success, errMsg = t.number(value)
				if not success then
					return false, errMsg or ""
				end

				if value % 1 == 0 then
					return true
				else
					return false, string.format("integer expected, got %s", value)
				end
			end

--[[**
	ensures value is a number where min <= value

	@param min The minimum to use

	@returns A function that will return true iff the condition is passed
**--]]
			function t.numberMin(min)
				return function(value)
					local success, errMsg = t.number(value)
					if not success then
						return false, errMsg or ""
					end

					if value >= min then
						return true
					else
						return false, string.format("number >= %s expected, got %s", min, value)
					end
				end
			end

--[[**
	ensures value is a number where value <= max

	@param max The maximum to use

	@returns A function that will return true iff the condition is passed
**--]]
			function t.numberMax(max)
				return function(value)
					local success, errMsg = t.number(value)
					if not success then
						return false, errMsg
					end

					if value <= max then
						return true
					else
						return false, string.format("number <= %s expected, got %s", max, value)
					end
				end
			end

--[[**
	ensures value is a number where min < value

	@param min The minimum to use

	@returns A function that will return true iff the condition is passed
**--]]
			function t.numberMinExclusive(min)
				return function(value)
					local success, errMsg = t.number(value)
					if not success then
						return false, errMsg or ""
					end

					if min < value then
						return true
					else
						return false, string.format("number > %s expected, got %s", min, value)
					end
				end
			end

--[[**
	ensures value is a number where value < max

	@param max The maximum to use

	@returns A function that will return true iff the condition is passed
**--]]
			function t.numberMaxExclusive(max)
				return function(value)
					local success, errMsg = t.number(value)
					if not success then
						return false, errMsg or ""
					end

					if value < max then
						return true
					else
						return false, string.format("number < %s expected, got %s", max, value)
					end
				end
			end

--[[**
	ensures value is a number where value > 0

	@returns A function that will return true iff the condition is passed
**--]]
			t.numberPositive = t.numberMinExclusive(0)

--[[**
	ensures value is a number where value < 0

	@returns A function that will return true iff the condition is passed
**--]]
			t.numberNegative = t.numberMaxExclusive(0)

--[[**
	ensures value is a number where min <= value <= max

	@param min The minimum to use
	@param max The maximum to use

	@returns A function that will return true iff the condition is passed
**--]]
			function t.numberConstrained(min, max)
				assert(t.number(min) and t.number(max))
				local minCheck = t.numberMin(min)
				local maxCheck = t.numberMax(max)

				return function(value)
					local minSuccess, minErrMsg = minCheck(value)
					if not minSuccess then
						return false, minErrMsg or ""
					end

					local maxSuccess, maxErrMsg = maxCheck(value)
					if not maxSuccess then
						return false, maxErrMsg or ""
					end

					return true
				end
			end

--[[**
	ensures value is a number where min < value < max

	@param min The minimum to use
	@param max The maximum to use

	@returns A function that will return true iff the condition is passed
**--]]
			function t.numberConstrainedExclusive(min, max)
				assert(t.number(min) and t.number(max))
				local minCheck = t.numberMinExclusive(min)
				local maxCheck = t.numberMaxExclusive(max)

				return function(value)
					local minSuccess, minErrMsg = minCheck(value)
					if not minSuccess then
						return false, minErrMsg or ""
					end

					local maxSuccess, maxErrMsg = maxCheck(value)
					if not maxSuccess then
						return false, maxErrMsg or ""
					end

					return true
				end
			end

--[[**
	ensures value matches string pattern

	@param string pattern to check against

	@returns A function that will return true iff the condition is passed
**--]]
			function t.match(pattern)
				assert(t.string(pattern))
				return function(value)
					local stringSuccess, stringErrMsg = t.string(value)
					if not stringSuccess then
						return false, stringErrMsg
					end

					if string.match(value, pattern) == nil then
						return false, string.format("%q failed to match pattern %q", value, pattern)
					end

					return true
				end
			end

--[[**
	ensures value is either nil or passes check

	@param check The check to use

	@returns A function that will return true iff the condition is passed
**--]]
			function t.optional(check)
				assert(t.callback(check))
				return function(value)
					if value == nil then
						return true
					end

					local success, errMsg = check(value)
					if success then
						return true
					else
						return false, string.format("(optional) %s", errMsg or "")
					end
				end
			end

--[[**
	matches given tuple against tuple type definition

	@param ... The type definition for the tuples

	@returns A function that will return true iff the condition is passed
**--]]
			function t.tuple(...)
				local checks = {...}
				return function(...)
					local args = {...}
					for i, check in ipairs(checks) do
						local success, errMsg = check(args[i])
						if success == false then
							return false, string.format("Bad tuple index #%s:\n\t%s", i, errMsg or "")
						end
					end

					return true
				end
			end

--[[**
	ensures all keys in given table pass check

	@param check The function to use to check the keys

	@returns A function that will return true iff the condition is passed
**--]]
			function t.keys(check)
				assert(t.callback(check))
				return function(value)
					local tableSuccess, tableErrMsg = t.table(value)
					if tableSuccess == false then
						return false, tableErrMsg or ""
					end

					for key in pairs(value) do
						local success, errMsg = check(key)
						if success == false then
							return false, string.format("bad key %s:\n\t%s", tostring(key), errMsg or "")
						end
					end

					return true
				end
			end

--[[**
	ensures all values in given table pass check

	@param check The function to use to check the values

	@returns A function that will return true iff the condition is passed
**--]]
			function t.values(check)
				assert(t.callback(check))
				return function(value)
					local tableSuccess, tableErrMsg = t.table(value)
					if tableSuccess == false then
						return false, tableErrMsg or ""
					end

					for key, val in pairs(value) do
						local success, errMsg = check(val)
						if success == false then
							return false, string.format("bad value for key %s:\n\t%s", tostring(key), errMsg or "")
						end
					end

					return true
				end
			end

--[[**
	ensures value is a table and all keys pass keyCheck and all values pass valueCheck

	@param keyCheck The function to use to check the keys
	@param valueCheck The function to use to check the values

	@returns A function that will return true iff the condition is passed
**--]]
			function t.map(keyCheck, valueCheck)
				assert(t.callback(keyCheck), t.callback(valueCheck))
				local keyChecker = t.keys(keyCheck)
				local valueChecker = t.values(valueCheck)

				return function(value)
					local keySuccess, keyErr = keyChecker(value)
					if not keySuccess then
						return false, keyErr or ""
					end

					local valueSuccess, valueErr = valueChecker(value)
					if not valueSuccess then
						return false, valueErr or ""
					end

					return true
				end
			end

--[[**
	ensures value is a table and all keys pass valueCheck and all values are true

	@param valueCheck The function to use to check the values

	@returns A function that will return true iff the condition is passed
**--]]
			function t.set(valueCheck)
				return t.map(valueCheck, t.literal(true))
			end

			do
				local arrayKeysCheck = t.keys(t.integer)
	--[[**
		ensures value is an array and all values of the array match check

		@param check The check to compare all values with

		@returns A function that will return true iff the condition is passed
	**--]]
				function t.array(check)
					assert(t.callback(check))
					local valuesCheck = t.values(check)

					return function(value)
						local keySuccess, keyErrMsg = arrayKeysCheck(value)
						if keySuccess == false then
							return false, string.format("[array] %s", keyErrMsg or "")
						end

						-- # is unreliable for sparse arrays
						-- Count upwards using ipairs to avoid false positives from the behavior of #
						local arraySize = 0

						for _ in ipairs(value) do
							arraySize = arraySize + 1
						end

						for key in pairs(value) do
							if key < 1 or key > arraySize then
								return false, string.format("[array] key %s must be sequential", tostring(key))
							end
						end

						local valueSuccess, valueErrMsg = valuesCheck(value)
						if not valueSuccess then
							return false, string.format("[array] %s", valueErrMsg or "")
						end

						return true
					end
				end

	--[[**
		ensures value is an array of a strict makeup and size

		@param check The check to compare all values with

		@returns A function that will return true iff the condition is passed
	**--]]
				function t.strictArray(...)
					local valueTypes = { ... }
					assert(t.array(t.callback)(valueTypes))

					return function(value)
						local keySuccess, keyErrMsg = arrayKeysCheck(value)
						if keySuccess == false then
							return false, string.format("[strictArray] %s", keyErrMsg or "")
						end

						-- If there's more than the set array size, disallow
						if #valueTypes < #value then
							return false, string.format("[strictArray] Array size exceeds limit of %d", #valueTypes)
						end

						for idx, typeFn in pairs(valueTypes) do
							local typeSuccess, typeErrMsg = typeFn(value[idx])
							if not typeSuccess then
								return false, string.format("[strictArray] Array index #%d - %s", idx, typeErrMsg)
							end
						end

						return true
					end
				end
			end

			do
				local callbackArray = t.array(t.callback)
	--[[**
		creates a union type

		@param ... The checks to union

		@returns A function that will return true iff the condition is passed
	**--]]
				function t.union(...)
					local checks = {...}
					assert(callbackArray(checks))

					return function(value)
						for _, check in ipairs(checks) do
							if check(value) then
								return true
							end
						end

						return false, "bad type for union"
					end
				end

	--[[**
		Alias for t.union
	**--]]
				t.some = t.union

	--[[**
		creates an intersection type

		@param ... The checks to intersect

		@returns A function that will return true iff the condition is passed
	**--]]
				function t.intersection(...)
					local checks = {...}
					assert(callbackArray(checks))

					return function(value)
						for _, check in ipairs(checks) do
							local success, errMsg = check(value)
							if not success then
								return false, errMsg or ""
							end
						end

						return true
					end
				end

	--[[**
		Alias for t.intersection
	**--]]
				t.every = t.intersection
			end

			do
				local checkInterface = t.map(t.any, t.callback)
	--[[**
		ensures value matches given interface definition

		@param checkTable The interface definition

		@returns A function that will return true iff the condition is passed
	**--]]
				function t.interface(checkTable)
					assert(checkInterface(checkTable))
					return function(value)
						local tableSuccess, tableErrMsg = t.table(value)
						if tableSuccess == false then
							return false, tableErrMsg or ""
						end

						for key, check in pairs(checkTable) do
							local success, errMsg = check(value[key])
							if success == false then
								return false, string.format("[interface] bad value for %s:\n\t%s", tostring(key), errMsg or "")
							end
						end

						return true
					end
				end

	--[[**
		ensures value matches given interface definition strictly

		@param checkTable The interface definition

		@returns A function that will return true iff the condition is passed
	**--]]
				function t.strictInterface(checkTable)
					assert(checkInterface(checkTable))
					return function(value)
						local tableSuccess, tableErrMsg = t.table(value)
						if tableSuccess == false then
							return false, tableErrMsg or ""
						end

						for key, check in pairs(checkTable) do
							local success, errMsg = check(value[key])
							if success == false then
								return false, string.format("[interface] bad value for %s:\n\t%s", tostring(key), errMsg or "")
							end
						end

						for key in pairs(value) do
							if not checkTable[key] then
								return false, string.format("[interface] unexpected field %q", tostring(key))
							end
						end

						return true
					end
				end
			end

--[[**
	ensure value is an Instance and it's ClassName matches the given ClassName

	@param className The class name to check for

	@returns A function that will return true iff the condition is passed
**--]]
			function t.instanceOf(className, childTable)
				assert(t.string(className))

				local childrenCheck
				if childTable ~= nil then
					childrenCheck = t.children(childTable)
				end

				return function(value)
					local instanceSuccess, instanceErrMsg = t.Instance(value)
					if not instanceSuccess then
						return false, instanceErrMsg or ""
					end

					if value.ClassName ~= className then
						return false, string.format("%s expected, got %s", className, value.ClassName)
					end

					if childrenCheck then
						local childrenSuccess, childrenErrMsg = childrenCheck(value)
						if not childrenSuccess then
							return false, childrenErrMsg
						end
					end

					return true
				end
			end

			t.instance = t.instanceOf

--[[**
	ensure value is an Instance and it's ClassName matches the given ClassName by an IsA comparison

	@param className The class name to check for

	@returns A function that will return true iff the condition is passed
**--]]
			function t.instanceIsA(className, childTable)
				assert(t.string(className))

				local childrenCheck
				if childTable ~= nil then
					childrenCheck = t.children(childTable)
				end

				return function(value)
					local instanceSuccess, instanceErrMsg = t.Instance(value)
					if not instanceSuccess then
						return false, instanceErrMsg or ""
					end

					if not value:IsA(className) then
						return false, string.format("%s expected, got %s", className, value.ClassName)
					end

					if childrenCheck then
						local childrenSuccess, childrenErrMsg = childrenCheck(value)
						if not childrenSuccess then
							return false, childrenErrMsg
						end
					end

					return true
				end
			end

--[[**
	ensures value is an enum of the correct type

	@param enum The enum to check

	@returns A function that will return true iff the condition is passed
**--]]
			function t.enum(enum)
				assert(t.Enum(enum))
				return function(value)
					local enumItemSuccess, enumItemErrMsg = t.EnumItem(value)
					if not enumItemSuccess then
						return false, enumItemErrMsg
					end

					if value.EnumType == enum then
						return true
					else
						return false, string.format("enum of %s expected, got enum of %s", tostring(enum), tostring(value.EnumType))
					end
				end
			end

			do
				local checkWrap = t.tuple(t.callback, t.callback)

	--[[**
		wraps a callback in an assert with checkArgs

		@param callback The function to wrap
		@param checkArgs The functon to use to check arguments in the assert

		@returns A function that first asserts using checkArgs and then calls callback
	**--]]
				function t.wrap(callback, checkArgs)
					assert(checkWrap(callback, checkArgs))
					return function(...)
						assert(checkArgs(...))
						return callback(...)
					end
				end
			end

--[[**
	asserts a given check

	@param check The function to wrap with an assert

	@returns A function that simply wraps the given check in an assert
**--]]
			function t.strict(check)
				return function(...)
					assert(check(...))
				end
			end

			do
				local checkChildren = t.map(t.string, t.callback)

	--[[**
		Takes a table where keys are child names and values are functions to check the children against.
		Pass an instance tree into the function.
		If at least one child passes each check, the overall check passes.

		Warning! If you pass in a tree with more than one child of the same name, this function will always return false

		@param checkTable The table to check against

		@returns A function that checks an instance tree
	**--]]
				function t.children(checkTable)
					assert(checkChildren(checkTable))

					return function(value)
						local instanceSuccess, instanceErrMsg = t.Instance(value)
						if not instanceSuccess then
							return false, instanceErrMsg or ""
						end

						local childrenByName = {}
						for _, child in ipairs(value:GetChildren()) do
							local name = child.Name
							if checkTable[name] then
								if childrenByName[name] then
									return false, string.format("Cannot process multiple children with the same name %q", name)
								end

								childrenByName[name] = child
							end
						end

						for name, check in pairs(checkTable) do
							local success, errMsg = check(childrenByName[name])
							if not success then
								return false, string.format("[%s.%s] %s", value:GetFullName(), name, errMsg or "")
							end
						end

						return true
					end
				end
			end

			return t
		end

		return Modules
	end

	local Modules = getModules()

	local SnapdragonController = Modules.SnapdragonController()
	local SnapdragonRef = Modules.SnapdragonRef()

	local function createDragController(...)
		return SnapdragonController.new(...)
	end

	local function createRef(gui)
		return SnapdragonRef.new(gui)
	end

	local export
	export = {
		createDragController = createDragController, 
		SnapdragonController = SnapdragonController,
		createRef = createRef
	}
	-- roblox-ts `default` support
	export.default = export
	return export
end

return Modules

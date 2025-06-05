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
			local Layout = ScrollFrame:FindFirstChildOfClass("UIListLayout")
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

		for i = 1, #BlursList do
			updateGui(BlursList[i])
		end

		local cframes = table.create(#BlursList, workspace.CurrentCamera.CFrame)
		workspace:BulkMoveTo(PartsList, cframes, Enum.BulkMoveMode.FireCFrameChanged)

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

return Modules

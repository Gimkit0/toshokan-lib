local modules = {}

function modules.Fade()
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

function modules.Autocomplete()
	local Autocomplete = {}

	function Autocomplete:Get(...)
		local Args = {...}

		self.fillText = Args[1]
		self.currentText = Args[2]
		self.shortHands = Args[3]

		if self.shortHands[self.currentText] then
			self.currentText = self.fillText
		end

		return self.currentText.. string.rep("", #self.currentText) .. self.fillText:sub(#self.currentText + 1)
	end

	return Autocomplete
end

function modules.Resuponshibu()
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

function modules.Parser()
	--[[
		パーサーモジュールはもともとAdonis Creatorsによって作成されました
	]]

	local Parser = {}

	function Parser.new(client)
		local self = setmetatable({}, {__index = Parser})

		self.Client = client

		self.split = function(message, key, number, useMagicChars)
			if not message or not key then return {} end
			if key == "" or key == nil then key = " " end
			if number == nil then number = math.huge end
			if useMagicChars == nil then useMagicChars = true end

			local tab = {}
			local stringAccum = ""

			local spat, epat, escapeQuotePat, buff, quoted = [=[^(['"])]=], [=[(['"])$]=], [=[(\(['"]))]=], nil, nil

			if not useMagicChars then
				spat = ""
				epat = ""
				escapeQuotePat = ""
			end

			local keyPattern = "[^"..key.."]+"

			if string.match(key, "%s") then
				keyPattern = "%S+"
			end

			for argument in string.gmatch(message, keyPattern) do
				local squoted = string.match(argument, spat)
				local equoted = string.match(argument, epat)
				local escaped = string.match(argument, [=[(\*)['"]$]=])

				if #tab >= number then
					break
				elseif #tab >= number - 1 then
					table.insert(tab, string.sub(message, #stringAccum + 1, #message))
					continue
				end

				if squoted and not quoted and not equoted then
					buff, quoted = argument, squoted
				elseif buff and equoted == quoted and #escaped % 2 == 0 then
					argument, buff, quoted = buff .. key .. argument, nil, nil
				elseif buff then
					buff = buff .. key .. argument
				end

				if not buff then
					local result = string.gsub(string.gsub(string.gsub(argument, spat, ""), epat, ""), escapeQuotePat, "%2")
					stringAccum ..= result .. key
					table.insert(tab, result)
				end
			end

			return tab
		end
		self.getArguments = function(message, number, ...)
			local arguments = self.split(
				string.match(message, "^.-" .. self.Client.Config.EXECUTION.SPLIT_KEY .. "(.+)") or '',
				self.Client.Config.EXECUTION.SPLIT_KEY,
				number
			) or {}
			for index, value in {...} do
				table.insert(arguments, value)
			end
			return arguments
		end
		self.getCommand = function(command)
			local matched
			matched = if string.find(command, self.Client.Config.EXECUTION.SPLIT_KEY) then
				string.match(command, "^(%S+)" .. self.Client.Config.EXECUTION.SPLIT_KEY)
				else string.match(command, "^(%S+)")

			if matched then
				matched = string.gsub(matched, self.Client.Config.EXECUTION.PREFIX, "")
				local found = nil
				for _, value in next, self.Client.Commands do
					if value.Name:lower() == matched:lower() then
						found = value
					end

					if value.Aliases and not found then
						for _, alias in ipairs(value.Aliases) do
							if alias:lower() == matched:lower() then
								found = value
							end
						end
					end
				end

				if found then
					local real = found
					if real then
						return real
					end
				end
			end
		end
		self.trim = function(stringInput)
			return string.match(stringInput, "^%s*(.-)%s*$")
		end
		self.sanitizePattern = function(stringInput)
			return string.gsub(stringInput, "([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
		end
		self.stripArgumentPlaceholders = function(alias)
			return self.trim(string.gsub(alias, "<%S+>", ""))
		end
		self.checkAliasBlacklist = function(alias)
			local prefix = self.Client.Config.EXECUTION.PREFIX
			local blacklist = {
				[prefix .. "alias"] = true,
				[prefix .. "newalias"] = true,
				[prefix .. "removealias"] = true,
				[prefix .. "client"] = true,
				[prefix .. "userpanel"] = true,
			}
			return blacklist[alias]
		end
		self.formatAliasArgs = function(alias, aliasCmd, msg)
			local uniqueArgs = {}
			local argTab = {}
			local numArgs = 0

			for arg in string.gmatch(alias, "<(%S+)>") do
				if arg ~= "" and arg ~= " " then
					local argKey = "<" .. arg .. ">"
					if not uniqueArgs[argKey] then
						numArgs += 1
						uniqueArgs[argKey] = true
						table.insert(argTab, argKey)
					end
				end
			end

			if numArgs == 0 then
				for arg in string.gmatch(aliasCmd, "<(%S+)>") do
					if arg ~= "" and arg ~= " " then
						local argKey = "<" .. arg .. ">"
						if not uniqueArgs[argKey] then
							numArgs += 1
							uniqueArgs[argKey] = true
							table.insert(argTab, argKey)
						end
					end
				end
			end

			local suppliedArgs = self.getArguments(msg, numArgs)
			local out = aliasCmd

			for i, argType in ipairs(argTab) do
				local replaceWith = suppliedArgs[i]
				if replaceWith then
					out = string.gsub(out, self.sanitizePattern(argType), replaceWith)
				end
			end

			return out
		end
		self.aliasFormat = function(aliases, msg)
			local checkAliasBlacklist, sanitizePattern = self.checkAliasBlacklist, self.sanitizePattern

			if aliases then
				for alias, command in pairs(aliases) do
					local trimmedAlias = self.stripArgumentPlaceholders(alias)
					if not self.checkAliasBlacklist(trimmedAlias) then
						local pattern = "^" .. sanitizePattern(trimmedAlias) .. "(.*)"
						local args = string.match(msg, pattern)
						if args then
							local replacedCmd = self.formatAliasArgs(alias, command, msg)
							if replacedCmd then
								return replacedCmd
							end
						end
					end
				end
			end
		end
		self.getOverrideMap = function(stringInput)
			local inputs, outputs = string.match(stringInput, `{self.Client.Config.EXECUTION.BATCH_KEY}([%d,]+)>([%d,]+)`)
			local tbl1, tbl2 = {}, {}
			local i = 0

			for num in string.gmatch(inputs or "", "(%d+),?") do
				table.insert(tbl1, tonumber(num) or 1)
			end

			for num in string.gmatch(outputs or "", "(%d+),?") do
				i += 1
				if tbl1[i] then
					tbl2[tbl1[i]] = tonumber(num) or 1
				end
			end

			return tbl2
		end

		return self
	end

	function Parser:Parse(player, message, optimized)
		message = self.trim(message)

		if string.match(message, self.Client.Config.EXECUTION.BATCH_KEY) then
			local overrideArgsents = {}

			for command, overrideMap in string.gmatch(message, `([^{self.Client.Config.EXECUTION.BATCH_KEY}]+)({self.Client.Config.EXECUTION.BATCH_KEY}?[%d,>]*)`) do
				command, overrideMap = self.trim(command), self.getOverrideMap(overrideMap)

				local waiter = {self.Client.Config.EXECUTION.PREFIX}task.wait()
				if string.sub(string.lower(command), 1, #waiter) == waiter then
					local number = tonumber(overrideArgsents[1] or string.sub(command, #waiter + 1))

					if overrideMap[1] then
						table.clear(overrideArgsents)
						overrideArgsents[overrideMap[1]] = number
					end

					if number then
						task.wait(tonumber(number))
					end
				else
					local returnArguments = table.pack(self:Parse(player, command, optimized))
					table.clear(overrideArgsents)

					for index, value in overrideMap do
						overrideArgsents[value] = returnArguments[index + 1]
					end

					optimized.overrideArgsents = overrideArgsents
				end
			end
		else
			if string.match(message, self.Client.Config.EXECUTION.BATCH_KEY) then
				return self:Parse(player, message)
			end

			local command = self.getCommand(message)
			if not command then
				return
			end

			local commandArguments = command.Args or command.Arguments
			local argumentString = string.match(message, `^.-{self.Client.Config.EXECUTION.SPLIT_KEY}(.+)`) or ""
			local arguments = (#commandArguments > 0 and self.split(argumentString, self.Client.Config.EXECUTION.SPLIT_KEY, #commandArguments)) or {}

			if optimized.overrideArgsents then
				for index, override in optimized.overrideArgsents do
					arguments[index] = override
				end
			end

			self.Client.spawn(function()
				command.Function(player, arguments)
			end, true)
		end
	end

	function Parser:RunCommand(speaker, commandName, ...)
		local command = self.getCommand(commandName)
		if command then
			local commandArguments = command.Args or command.Arguments
			local arguments = self.getArguments(commandName, #commandArguments, ...)

			self.Client.spawn(function()
				command.Function(speaker, arguments)
			end)
		end
	end

	return Parser
end

function modules.Spring()
	local Spring = {}
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*math.pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = math.exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end

	return Spring
end

function modules.Input(client, INPUT_PRIORITY)
	local Input = {}

	local pi    = math.pi
	local abs   = math.abs
	local clamp = math.clamp
	local exp   = math.exp
	local rad   = math.rad
	local sign  = math.sign
	local sqrt  = math.sqrt
	local tan   = math.tan

	local thumbstickCurve do
		local K_CURVATURE = 2.0
		local K_DEADZONE = 0.15

		local function fCurve(x)
			return (exp(K_CURVATURE*x) - 1)/(exp(K_CURVATURE) - 1)
		end

		local function fDeadzone(x)
			return fCurve((x - K_DEADZONE)/(1 - K_DEADZONE))
		end

		function thumbstickCurve(x)
			return sign(x)*clamp(fDeadzone(abs(x)), 0, 1)
		end
	end

	local gamepad = {
		ButtonX = 0,
		ButtonY = 0,
		DPadDown = 0,
		DPadUp = 0,
		ButtonL2 = 0,
		ButtonR2 = 0,
		Thumbstick1 = Vector2.new(),
		Thumbstick2 = Vector2.new(),
	}

	local keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		U = 0,
		H = 0,
		J = 0,
		K = 0,
		I = 0,
		Y = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
		RightShift = 0,
	}

	local mouse = {
		Delta = Vector2.new(),
		MouseWheel = 0,
	}

	local NAV_GAMEPAD_SPEED  = Vector3.new(1, 1, 1)
	local NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	local PAN_MOUSE_SPEED    = Vector2.new(1, 1)*(pi/64)
	local PAN_GAMEPAD_SPEED  = Vector2.new(1, 1)*(pi/8)
	local FOV_WHEEL_SPEED    = 1.0
	local FOV_GAMEPAD_SPEED  = 0.25
	local NAV_ADJ_SPEED      = 0.75
	local NAV_SHIFT_MUL      = 0.25

	local navSpeed = 1

	function Input.Vel(dt)
		navSpeed = clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

		local kGamepad = Vector3.new(
			thumbstickCurve(gamepad.Thumbstick1.X),
			thumbstickCurve(gamepad.ButtonR2) - thumbstickCurve(gamepad.ButtonL2),
			thumbstickCurve(-gamepad.Thumbstick1.Y)
		)*NAV_GAMEPAD_SPEED

		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A + keyboard.K - keyboard.H,
			keyboard.E - keyboard.Q + keyboard.I - keyboard.Y,
			keyboard.S - keyboard.W + keyboard.J - keyboard.U
		)*NAV_KEYBOARD_SPEED

		local shift = client.Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or client.Services.UserInputService:IsKeyDown(Enum.KeyCode.RightShift)

		return (kGamepad + kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(dt)
		local kGamepad = Vector2.new(
			thumbstickCurve(gamepad.Thumbstick2.Y),
			thumbstickCurve(-gamepad.Thumbstick2.X)
		)*PAN_GAMEPAD_SPEED
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kGamepad + kMouse
	end

	function Input.Fov(dt)
		local kGamepad = (gamepad.ButtonX - gamepad.ButtonY)*FOV_GAMEPAD_SPEED
		local kMouse = mouse.MouseWheel*FOV_WHEEL_SPEED
		mouse.MouseWheel = 0
		return kGamepad + kMouse
	end

	do
		local function Keypress(action, state, input)
			keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function GpButton(action, state, input)
			gamepad[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		local function MousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(-delta.y, -delta.x)
			return Enum.ContextActionResult.Sink
		end

		local function Thumb(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position
			return Enum.ContextActionResult.Sink
		end

		local function Trigger(action, state, input)
			gamepad[input.KeyCode.Name] = input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function MouseWheel(action, state, input)
			mouse[input.UserInputType.Name] = -input.Position.z
			return Enum.ContextActionResult.Sink
		end

		local function Zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end

		function Input.StartCapture()
			client.Services.ContextActionService:BindActionAtPriority("FreecamKeyboard", Keypress, false, INPUT_PRIORITY,
				Enum.KeyCode.W, Enum.KeyCode.U,
				Enum.KeyCode.A, Enum.KeyCode.H,
				Enum.KeyCode.S, Enum.KeyCode.J,
				Enum.KeyCode.D, Enum.KeyCode.K,
				Enum.KeyCode.E, Enum.KeyCode.I,
				Enum.KeyCode.Q, Enum.KeyCode.Y,
				Enum.KeyCode.Up, Enum.KeyCode.Down
			)
			client.Services.ContextActionService:BindActionAtPriority("FreecamMousePan",          MousePan,   false, INPUT_PRIORITY, Enum.UserInputType.MouseMovement)
			client.Services.ContextActionService:BindActionAtPriority("FreecamMouseWheel",        MouseWheel, false, INPUT_PRIORITY, Enum.UserInputType.MouseWheel)
			client.Services.ContextActionService:BindActionAtPriority("FreecamGamepadButton",     GpButton,   false, INPUT_PRIORITY, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY)
			client.Services.ContextActionService:BindActionAtPriority("FreecamGamepadTrigger",    Trigger,    false, INPUT_PRIORITY, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonL2)
			client.Services.ContextActionService:BindActionAtPriority("FreecamGamepadThumbstick", Thumb,      false, INPUT_PRIORITY, Enum.KeyCode.Thumbstick1, Enum.KeyCode.Thumbstick2)
		end

		function Input.StopCapture()
			navSpeed = 1
			Zero(gamepad)
			Zero(keyboard)
			Zero(mouse)
			client.Services.ContextActionService:UnbindAction("FreecamKeyboard")
			client.Services.ContextActionService:UnbindAction("FreecamMousePan")
			client.Services.ContextActionService:UnbindAction("FreecamMouseWheel")
			client.Services.ContextActionService:UnbindAction("FreecamGamepadButton")
			client.Services.ContextActionService:UnbindAction("FreecamGamepadTrigger")
			client.Services.ContextActionService:UnbindAction("FreecamGamepadThumbstick")
		end
	end

	return Input
end

function modules.PlayerState(client)
	local PlayerState = {}

	local mouseBehavior = ""
	local mouseIconEnabled = ""
	local cameraType = ""
	local cameraFocus = ""
	local cameraCFrame = ""
	local cameraFieldOfView = ""

	local disabledGuis = {}

	local FFlagUserExitFreecamBreaksWithShiftlock
	do
		local success, result = pcall(function()
			return UserSettings():IsUserFeatureEnabled("UserExitFreecamBreaksWithShiftlock")
		end)
		FFlagUserExitFreecamBreaksWithShiftlock = success and result
	end

	local function checkMouseLockAvailability()
		local devAllowsMouseLock = client.LocalPlayer.DevEnableMouseLock
		local devMovementModeIsScriptable = client.LocalPlayer.DevComputerMovementMode == Enum.DevComputerMovementMode.Scriptable
		local userHasMouseLockModeEnabled = UserSettings().GameSettings.ControlMode == Enum.ControlMode.MouseLockSwitch
		local userHasClickToMoveEnabled =  UserSettings().GameSettings.ComputerMovementMode == Enum.ComputerMovementMode.ClickToMove
		local MouseLockAvailable = devAllowsMouseLock and userHasMouseLockModeEnabled and not userHasClickToMoveEnabled and not devMovementModeIsScriptable

		return MouseLockAvailable
	end

	local coreGuis = {
		Backpack = true,
		Chat = true,
		Health = true,
		PlayerList = true,
	}
	local setCores = {
		BadgesNotificationsActive = true,
		PointsNotificationsActive = true,
	}

	function PlayerState.Push(disableCores : boolean?)
		if disableCores then
			local playerGui = client.LocalPlayer:FindFirstChildOfClass("PlayerGui")
			if playerGui then
				for _, gui in pairs(playerGui:GetChildren()) do
					if gui:IsA("ScreenGui") and gui.Enabled then
						disabledGuis[#disabledGuis + 1] = gui
						gui.Enabled = false
					end
				end
			end
			for name in pairs(coreGuis) do
				coreGuis[name] = client.Services.StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType[name])
				client.Services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], false)
			end
			for name in pairs(setCores) do
				setCores[name] = client.Services.StarterGui:GetCore(name)
				client.Services.StarterGui:SetCore(name, false)
			end
		end

		cameraFieldOfView = client.Camera.FieldOfView
		client.Camera.FieldOfView = 70

		cameraType = client.Camera.CameraType
		client.Camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = client.Camera.CFrame
		cameraFocus = client.Camera.Focus

		mouseIconEnabled = client.Services.UserInputService.MouseIconEnabled
		--client.Services.UserInputService.MouseIconEnabled = false

		if FFlagUserExitFreecamBreaksWithShiftlock and checkMouseLockAvailability() then
			mouseBehavior = Enum.MouseBehavior.Default
		else
			mouseBehavior = client.Services.UserInputService.MouseBehavior
		end
		client.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end

	function PlayerState.Pop()
		for name, isEnabled in pairs(coreGuis) do
			client.Services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType[name], isEnabled)
		end
		for name, isEnabled in pairs(setCores) do
			client.Services.StarterGui:SetCore(name, isEnabled)
		end
		for _, gui in pairs(disabledGuis) do
			if gui.Parent then
				gui.Enabled = true
			end
		end

		client.Camera.FieldOfView = cameraFieldOfView
		cameraFieldOfView = nil

		client.Camera.CameraType = cameraType
		cameraType = nil

		client.Camera.CFrame = cameraCFrame
		cameraCFrame = nil

		client.Camera.Focus = cameraFocus
		cameraFocus = nil

		client.Services.UserInputService.MouseIconEnabled = mouseIconEnabled
		mouseIconEnabled = nil

		client.Services.UserInputService.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end

	return PlayerState
end

function modules.SimplePath()
	--[[
	-------------------------------------------------------------------

	Created by: @V3N0M_Z
	Reference: https://v3n0m-z.github.io/RBLX-SimplePath/
	License: MIT

	---------------------------------------------------------------------
	]]

	local DEFAULT_SETTINGS = {

		TIME_VARIANCE = 0.07;

		COMPARISON_CHECKS = 1;

		JUMP_WHEN_STUCK = true;
	}

	---------------------------------------------------------------------

	local PathfindingService = game:GetService("PathfindingService")
	local Players = game:GetService("Players")
	local function output(func, msg)
		func(((func == error and "SimplePath Error: ") or "SimplePath: ")..msg)
	end
	local Path = {
		StatusType = {
			Idle = "Idle";
			Active = "Active";
		};
		ErrorType = {
			LimitReached = "LimitReached";
			TargetUnreachable = "TargetUnreachable";
			ComputationError = "ComputationError";
			AgentStuck = "AgentStuck";
		};
	}
	Path.__index = function(table, index)
		if index == "Stopped" and not table._humanoid then
			output(error, "Attempt to use Path.Stopped on a non-humanoid.")
		end
		return (table._events[index] and table._events[index].Event)
			or (index == "LastError" and table._lastError)
			or (index == "Status" and table._status)
			or Path[index]
	end

	--Used to visualize waypoints
	local visualWaypoint = Instance.new("Part")
	visualWaypoint.Size = Vector3.new(0.3, 0.3, 0.3)
	visualWaypoint.Anchored = true
	visualWaypoint.CanCollide = false
	visualWaypoint.Material = Enum.Material.Neon
	visualWaypoint.Shape = Enum.PartType.Ball

	--[[ PRIVATE FUNCTIONS ]]--
	local function declareError(self, errorType)
		self._lastError = errorType
		self._events.Error:Fire(errorType)
	end

	--Create visual waypoints
	local function createVisualWaypoints(waypoints)
		local visualWaypoints = {}
		for _, waypoint in ipairs(waypoints) do
			local visualWaypointClone = visualWaypoint:Clone()
			visualWaypointClone.Position = waypoint.Position
			visualWaypointClone.Parent = workspace
			visualWaypointClone.Color =
				(waypoint == waypoints[#waypoints] and Color3.fromRGB(0, 255, 0))
				or (waypoint.Action == Enum.PathWaypointAction.Jump and Color3.fromRGB(255, 0, 0))
				or Color3.fromRGB(255, 139, 0)
			table.insert(visualWaypoints, visualWaypointClone)
		end
		return visualWaypoints
	end

	--Destroy visual waypoints
	local function destroyVisualWaypoints(waypoints)
		if waypoints then
			for _, waypoint in ipairs(waypoints) do
				waypoint:Destroy()
			end
		end
		return
	end

	--Get initial waypoint for non-humanoid
	local function getNonHumanoidWaypoint(self)
		--Account for multiple waypoints that are sometimes in the same place
		for i = 2, #self._waypoints do
			if (self._waypoints[i].Position - self._waypoints[i - 1].Position).Magnitude > 0.1 then
				return i
			end
		end
		return 2
	end

	--Make NPC jump
	local function setJumpState(self)
		pcall(function()
			if self._humanoid:GetState() ~= Enum.HumanoidStateType.Jumping and self._humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
				self._humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end

	--Primary move function
	local function move(self)
		if self._waypoints[self._currentWaypoint].Action == Enum.PathWaypointAction.Jump then
			setJumpState(self)
		end
		self._humanoid:MoveTo(self._waypoints[self._currentWaypoint].Position)
	end

	--Disconnect MoveToFinished connection when pathfinding ends
	local function disconnectMoveConnection(self)
		self._moveConnection:Disconnect()
		self._moveConnection = nil
	end

	--Fire the WaypointReached event
	local function invokeWaypointReached(self)
		local lastWaypoint = self._waypoints[self._currentWaypoint - 1]
		local nextWaypoint = self._waypoints[self._currentWaypoint]
		self._events.WaypointReached:Fire(self._agent, lastWaypoint, nextWaypoint)
	end

	local function moveToFinished(self, reached)

		--Stop execution if Path is destroyed
		if not getmetatable(self) then return end

		--Handle case for non-humanoids
		if not self._humanoid then
			if reached and self._currentWaypoint + 1 <= #self._waypoints then
				invokeWaypointReached(self)
				self._currentWaypoint += 1
			elseif reached then
				self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints)
				self._target = nil
				self._events.Reached:Fire(self._agent, self._waypoints[self._currentWaypoint])
			else
				self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints)
				self._target = nil
				declareError(self, self.ErrorType.TargetUnreachable)
			end
			return
		end

		if reached and self._currentWaypoint + 1 <= #self._waypoints  then --Waypoint reached
			if self._currentWaypoint + 1 < #self._waypoints then
				invokeWaypointReached(self)
			end
			self._currentWaypoint += 1
			move(self)
		elseif reached then --Target reached, pathfinding ends
			disconnectMoveConnection(self)
			self._status = Path.StatusType.Idle
			self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints)
			self._events.Reached:Fire(self._agent, self._waypoints[self._currentWaypoint])
		else --Target unreachable
			disconnectMoveConnection(self)
			self._status = Path.StatusType.Idle
			self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints)
			declareError(self, self.ErrorType.TargetUnreachable)
		end
	end

	--Refer to Settings.COMPARISON_CHECKS
	local function comparePosition(self)
		if self._currentWaypoint == #self._waypoints then return end
		self._position._count = ((self._agent.PrimaryPart.Position - self._position._last).Magnitude <= 0.07 and (self._position._count + 1)) or 0
		self._position._last = self._agent.PrimaryPart.Position
		if self._position._count >= self._settings.COMPARISON_CHECKS then
			if self._settings.JUMP_WHEN_STUCK then
				setJumpState(self)
			end
			declareError(self, self.ErrorType.AgentStuck)
		end
	end

	--[[ STATIC METHODS ]]--
	function Path.GetNearestCharacter(fromPosition)
		local character, dist = nil, math.huge
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character and (player.Character.PrimaryPart.Position - fromPosition).Magnitude < dist then
				character, dist = player.Character, (player.Character.PrimaryPart.Position - fromPosition).Magnitude
			end
		end
		return character
	end

	--[[ CONSTRUCTOR ]]--
	function Path.new(agent, agentParameters, override, noHum)
		if not (agent and agent:IsA("Model") and agent.PrimaryPart) then
			output(error, "Pathfinding agent must be a valid Model Instance with a set PrimaryPart.")
		end

		local self = setmetatable({
			_settings = override or DEFAULT_SETTINGS;
			_events = {
				Reached = Instance.new("BindableEvent");
				WaypointReached = Instance.new("BindableEvent");
				Blocked = Instance.new("BindableEvent");
				Error = Instance.new("BindableEvent");
				Stopped = Instance.new("BindableEvent");
				Ranned = Instance.new("BindableEvent");
			};
			_agent = agent;
			_humanoid = agent:FindFirstChildOfClass("Humanoid");
			_path = PathfindingService:CreatePath(agentParameters);
			_status = "Idle";
			_t = 0;
			_position = {
				_last = Vector3.new();
				_count = 0;
			};
		}, Path)

		--Configure settings
		for setting, value in pairs(DEFAULT_SETTINGS) do
			self._settings[setting] = self._settings[setting] == nil and value or self._settings[setting]
		end

		if noHum then
			self._humanoid = nil
		end

		--Path blocked connection
		self._path.Blocked:Connect(function(...)
			if (self._currentWaypoint <= ... and self._currentWaypoint + 1 >= ...) and self._humanoid then
				setJumpState(self)
				self._events.Blocked:Fire(self._agent, self._waypoints[...])
			end
		end)

		return self
	end


	--[[ NON-STATIC METHODS ]]--
	function Path:Destroy()
		for _, event in ipairs(self._events) do
			event:Destroy()
		end
		self._events = nil
		if rawget(self, "_visualWaypoints") then
			self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints)
		end
		self._path:Destroy()
		setmetatable(self, nil)
		for k, _ in pairs(self) do
			self[k] = nil
		end
	end

	function Path:Stop()
		if not self._humanoid then
			output(error, "Attempt to call Path:Stop() on a non-humanoid.")
			return
		end
		if self._status == Path.StatusType.Idle then
			output(function(m)
				warn(debug.traceback(m))
			end, "Attempt to run Path:Stop() in idle state")
			return
		end
		disconnectMoveConnection(self)
		self._status = Path.StatusType.Idle
		self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints)
		self._events.Stopped:Fire(self._model)
	end

	function Path:Run(target)

		--Non-humanoid handle case
		if not target and not self._humanoid and self._target then
			moveToFinished(self, true)
			return
		end

		--Parameter check
		if not (target and (typeof(target) == "Vector3" or target:IsA("BasePart"))) then
			output(error, "Pathfinding target must be a valid Vector3 or BasePart.")
		end

		--Refer to Settings.TIME_VARIANCE
		if os.clock() - self._t <= self._settings.TIME_VARIANCE and self._humanoid then
			task.wait(os.clock() - self._t)
			declareError(self, self.ErrorType.LimitReached)
			return false
		elseif self._humanoid then
			self._t = os.clock()
		end

		--Compute path
		local pathComputed, _ = pcall(function()
			self._path:ComputeAsync(self._agent.PrimaryPart.Position, (typeof(target) == "Vector3" and target) or target.Position)
		end)

		--Make sure path computation is successful
		if not pathComputed
			or self._path.Status == Enum.PathStatus.NoPath
			or #self._path:GetWaypoints() < 2
			or (self._humanoid and self._humanoid:GetState() == Enum.HumanoidStateType.Freefall) then
			self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints)
			task.wait()
			declareError(self, self.ErrorType.ComputationError)
			return false
		end

		--Set status to active; pathfinding starts
		self._status = (self._humanoid and Path.StatusType.Active) or Path.StatusType.Idle
		self._target = target

		--Set network owner to server to prevent "hops"
		pcall(function()
			self._agent.PrimaryPart:SetNetworkOwner(nil)
		end)

		--Initialize waypoints
		self._waypoints = self._path:GetWaypoints()
		self._currentWaypoint = 2

		--Refer to Settings.COMPARISON_CHECKS
		if self._humanoid then
			comparePosition(self)
		end

		--Visualize waypoints
		destroyVisualWaypoints(self._visualWaypoints)
		self._visualWaypoints = (self.Visualize and createVisualWaypoints(self._waypoints))

		--Create a new move connection if it doesn't exist already
		self._moveConnection = self._humanoid and (self._moveConnection or self._humanoid.MoveToFinished:Connect(function(...)
			moveToFinished(self, ...)
		end))

		self._events.Ranned:Fire(self._agent, self._waypoints[self._currentWaypoint], self._waypoints)

		--Begin pathfinding
		if self._humanoid then
			self._humanoid:MoveTo(self._waypoints[self._currentWaypoint].Position)
		elseif #self._waypoints == 2 then
			self._target = nil
			self._visualWaypoints = destroyVisualWaypoints(self._visualWaypoints)
			self._events.Reached:Fire(self._agent, self._waypoints[2])
		else
			self._currentWaypoint = getNonHumanoidWaypoint(self)
			moveToFinished(self, true)
		end
		return true
	end

	return Path
end

function modules.Core()
	--[[
		管理コマンドの主なコンポーネント
	]]

	local Core = {}
	Core.__index = Core

	function Core.new(client)
		local self = setmetatable({}, Core)

		self.Client = client

		self.Storage = {
			lastFakeGame = 0,

			currentPath = nil,

			checkPoints = {},
			connections = {
				flyKeyDown = nil,
				flyKeyUp = nil,

				mfly1 = nil,
				mfly2 = nil,

				cframeSpeed = nil,
			},

			values = {
				flying = false,

				vfly_speed = 2,
				fly_speed = 2,

				m_fly_name1 = "",
				m_fly_name2 = "",
			},

			instances = {
				animation = nil,

				animations = {},
			},
		}

		local cameraPos = Vector3.new()
		local cameraRot = Vector2.new()

		local velSpring = self.Client.PreloadedModules.spring.new(1.5, Vector3.new())
		local panSpring = self.Client.PreloadedModules.spring.new(1.0, Vector2.new())
		local fovSpring = self.Client.PreloadedModules.spring.new(4.0, 0)

		self.cameraPos = cameraPos
		self.cameraRot = cameraRot
		self.velSpring = velSpring
		self.panSpring = panSpring
		self.fovSpring = fovSpring

		self.disabledGuis = {}

		self.freecamActive = false

		self.cameraFov = 70

		return self
	end

	function Core:TeleportToServer(placeId, guid)
		local retries = 0
		local successful = false

		repeat
			local success, err = pcall(function()
				self.Client.Services.TeleportService:TeleportToPlaceInstance(placeId, guid, self.Client.LocalPlayer)
			end)
			if not success then
				retries += 1
				warn(`There was an error: {err} retry {retries} / 3`)
				task.wait(1)
			else
				successful = true
			end
		until retries < 3 or successful
	end

	function Core:TeleportToPlayerByPlace(user, placeId)
		local retries = 0

		local success, err = pcall(function()
			local user, userId = pcall(function()
				if tonumber(user) then
					return tonumber(user)
				end

				return self.Client.Services.Players:GetUserIdFromNameAsync(user)
			end)

			if user then
				local url = ("https://games.roblox.com/v1/games/"..placeId.."/servers/Public?sortOrder=Asc&limit=100")
				local http = self.Client.Services.HttpService:JSONDecode(game:HttpGet(url))

				local guid

				for i = 1, tonumber(self.Client.getTableLength(http.data)) do
					for _, playerId in pairs(http.data[i].playerIds) do
						if playerId == userId then
							guid = http.data[i].id
						end
					end
				end

				if guid then
					self:TeleportToServer(placeId, guid)
				end
			end
		end)
		if not success then
			error(`There was an error: {err}`)
		end
		return success
	end

	function Core:TeleportToLocation(cframe)
		local root = self.Client.fetchHrp(self.Client.LocalPlayer.Character)
		if root then
			local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)
			if hum and hum.SeatPart then
				if not hum.SeatPart.Anchored then
					hum.Sit = false
				end
			end
			self.Client.spawn(function()
				if game.PlaceId == 185655149--[[Bloxburg]] then
					local fakeGames = {
						10949429194040214,
						8599403013003,
						959491030313413,
						9313477575754,
						4843993134738183,
						3849138484933134,
						92939319484313,
						8449913848138134,
					}

					local function getFakeGame()
						local fakeGame = fakeGames[math.random(1, #fakeGames)]
						if fakeGame == self.Storage.lastFakeGame then
							fakeGame = getFakeGame()
						end
						return fakeGame
					end

					self.Client.Services.TeleportService:Teleport(getFakeGame(), self.Client.Services.Players)

					task.wait(1.5)

					root.CFrame = cframe
				else
					root.CFrame = cframe
				end
			end)
		end
	end

	function Core:SetJumppower(power)
		if not power then
			power = 50
		end

		local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)
		if hum then
			hum.UseJumpPower = true
			hum.JumpPower = tonumber(power)
		end
	end

	function Core:SetWalkspeed(speed, cframe : boolean?)
		if not speed then
			speed = 16
		end
		if game.PlaceId == 9872472334--[[Evade]]
			or game.PlaceId == 2788229376--[[Da Hood]]
		then
			cframe = true
		end

		local cframeSpeedDivider = 80

		local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)
		local hrp = self.Client.fetchHrp(self.Client.LocalPlayer.Character)
		local camera = self.Client.Camera

		if not cframe then
			if hum then
				hum.WalkSpeed = tonumber(speed)
			end
		else
			if self.Storage.connections.cframeSpeed then
				self.Storage.connections.cframeSpeed:Disconnect()
				self.Storage.connections.cframeSpeed = nil
			end

			self.Storage.connections.cframeSpeed = self.Client.Services.RunService.Heartbeat:Connect(function()
				if not hrp then
					if self.Storage.connections.cframeSpeed then self.Storage.connections.cframeSpeed:Disconnect() end
					return
				end

				hrp.CFrame = hrp.CFrame + hum.MoveDirection * speed/cframeSpeedDivider
			end)
		end
	end

	function Core:UncframeSpeed()
		if self.Storage.connections.cframeSpeed then
			self.Storage.connections.cframeSpeed:Disconnect()
			self.Storage.connections.cframeSpeed = nil
		end
	end

	function Core:RefreshPlayer()
		local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)
		local hrp = self.Client.fetchHrp(self.Client.LocalPlayer.Character)
		if hum and hrp then
			local lastPos = hrp.CFrame
			local viewPart = Instance.new("Part", workspace)
			viewPart.Name = self.Client.globalName
			viewPart.CFrame = lastPos
			viewPart.Transparency = 1
			viewPart.CanCollide = false
			viewPart.CanTouch = false
			viewPart.CanQuery = false

			self.Client.addConn("REFRESHING_PLAYER", self.Client.LocalPlayer.CharacterAdded:Connect(function(char)
				self:TeleportToLocation(lastPos)
				self.Client.Camera.CameraSubject = self.Client.LocalPlayer
				viewPart:Destroy()
				self.Client.removeConn("REFRESHING_PLAYER")
			end))

			self.Client.Camera.CameraSubject = viewPart
			self:TeleportToLocation(CFrame.new(0, 50000, 0))

			task.wait(.25)
			hum:ChangeState(Enum.HumanoidStateType.Dead)
		end
	end

	function Core:PromptRig(rig)
		local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)
		if hum then
			self.Client.Services.AvatarEditorService:PromptSaveAvatar(hum.HumanoidDescription, Enum.HumanoidRigType[rig])
			local result = self.Client.Services.AvatarEditorService.PromptSaveAvatarCompleted:Wait()
			if result == Enum.AvatarPromptResult.Success then
				--self.Client.Modules.Parser:RunCommand(self.Client.LocalPlayer, "reset")
				self:RefreshPlayer()
			end
		end
	end

	function Core:Fly(isVfly, speed)
		if game.PlaceId == 9872472334--[[Evade]] then
			loadstring(game:HttpGet("https://raw.githubusercontent.com/CF-Trail/random/main/bypassedfly.lua"))()
			_G.Speed = speed
		else
			local QEfly = true

			self:Unfly()

			if speed then
				if isVfly then
					self.Storage.values.vfly_speed = speed else
					self.Storage.values.fly_speed = speed
				end
			end

			if self.Client.Services.UserInputService.TouchEnabled then
				self:MobileFly(isVfly)
				return
			end

			repeat wait() until self.Client.LocalPlayer and self.Client.LocalPlayer.Character
				and self.Client.fetchHrp(self.Client.LocalPlayer.Character)
				and self.Client.fetchHum(self.Client.LocalPlayer.Character)
			repeat wait() until self.Client.Mouse

			local T = self.Client.fetchHrp(self.Client.LocalPlayer.Character)
			local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			local SPEED = 0

			local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)

			local function FLY()
				self.Storage.values.flying = true
				local BG = Instance.new('BodyGyro')
				local BV = Instance.new('BodyVelocity')
				BG.P = 9e4
				BG.Parent = T
				BV.Parent = T
				BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
				BG.cframe = T.CFrame
				BV.velocity = Vector3.new(0, 0, 0)
				BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
				task.spawn(function()
					repeat wait()
						if not isVfly and hum then
							hum.PlatformStand = true
						end
						if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
							SPEED = 50
						elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
							SPEED = 0
						end
						if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
							BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
							lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
						elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
							BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
						else
							BV.velocity = Vector3.new(0, 0, 0)
						end
						BG.cframe = workspace.CurrentCamera.CoordinateFrame
					until not self.Storage.values.flying
					CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
					lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
					SPEED = 0
					BG:Destroy()
					BV:Destroy()
					if hum then
						hum.PlatformStand = false
					end
				end)
			end
			self.Storage.connections.flyKeyDown = self.Client.Mouse.KeyDown:Connect(function(KEY)
				if KEY:lower() == 'w' then
					CONTROL.F = (isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed)
				elseif KEY:lower() == 's' then
					CONTROL.B = - (isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed)
				elseif KEY:lower() == 'a' then
					CONTROL.L = - (isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed)
				elseif KEY:lower() == 'd' then 
					CONTROL.R = (isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed)
				elseif QEfly and KEY:lower() == 'e' then
					CONTROL.Q = (isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed)*2
				elseif QEfly and KEY:lower() == 'q' then
					CONTROL.E = -(isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed)*2
				end
				pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
			end)
			self.Storage.connections.flyKeyUp = self.Client.Mouse.KeyUp:Connect(function(KEY)
				if KEY:lower() == 'w' then
					CONTROL.F = 0
				elseif KEY:lower() == 's' then
					CONTROL.B = 0
				elseif KEY:lower() == 'a' then
					CONTROL.L = 0
				elseif KEY:lower() == 'd' then
					CONTROL.R = 0
				elseif KEY:lower() == 'e' then
					CONTROL.Q = 0
				elseif KEY:lower() == 'q' then
					CONTROL.E = 0
				end
			end)
			FLY()
		end
	end

	function Core:MobileFly(isVfly)
		self:Unfly()
		self.Storage.values.flying = true

		self.Storage.values.m_fly_name1 = self:RandomString()
		self.Storage.values.m_fly_name2 = self:RandomString()

		local hrp = self.Client.fetchHrp(self.Client.LocalPlayer.Character)
		local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)

		local camera = workspace.CurrentCamera
		local v3none = Vector3.new()
		local v3zero = Vector3.new(0, 0, 0)
		local v3inf = Vector3.new(9e9, 9e9, 9e9)

		local controlModule = require(self.Client.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"):WaitForChild("ControlModule"))
		local bv = Instance.new("BodyVelocity")
		bv.Name = self.Storage.values.m_fly_name1
		bv.Parent = hrp
		bv.MaxForce = v3zero
		bv.Velocity = v3zero

		local bg = Instance.new("BodyGyro")
		bg.Name = self.Storage.values.m_fly_name2
		bg.Parent = hrp
		bg.MaxTorque = v3inf
		bg.P = 1000
		bg.D = 50

		self.Storage.connections.mfly1 = self.Client.LocalPlayer.CharacterAdded:Connect(function()
			local bv = Instance.new("BodyVelocity")
			bv.Name = self.Storage.values.m_fly_name1
			bv.Parent = hrp
			bv.MaxForce = v3zero
			bv.Velocity = v3zero

			local bg = Instance.new("BodyGyro")
			bg.Name = self.Storage.values.m_fly_name2
			bg.Parent = hrp
			bg.MaxTorque = v3inf
			bg.P = 1000
			bg.D = 50
		end)

		self.Storage.connections.mfly2 = self.Client.Services.RunService.RenderStepped:Connect(function()
			hrp = self.Client.fetchHrp(self.Client.LocalPlayer.Character)
			camera = workspace.CurrentCamera
			if hum and hrp
				and hrp:FindFirstChild(self.Storage.values.m_fly_name1)
				and hrp:FindFirstChild(self.Storage.values.m_fly_name2)
			then
				local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)
				local VelocityHandler = hrp:FindFirstChild(self.Storage.values.m_fly_name1)
				local GyroHandler = hrp:FindFirstChild(self.Storage.values.m_fly_name2)

				VelocityHandler.MaxForce = v3inf
				GyroHandler.MaxTorque = v3inf

				if not isVfly then
					hum.PlatformStand = true
				end

				GyroHandler.CFrame = camera.CoordinateFrame
				VelocityHandler.Velocity = v3none

				local direction = controlModule:GetMoveVector()
				if direction.X > 0 then
					VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed) * 50))
				end
				if direction.X < 0 then
					VelocityHandler.Velocity = VelocityHandler.Velocity + camera.CFrame.RightVector * (direction.X * ((isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed) * 50))
				end
				if direction.Z > 0 then
					VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * ((isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed) * 50))
				end
				if direction.Z < 0 then
					VelocityHandler.Velocity = VelocityHandler.Velocity - camera.CFrame.LookVector * (direction.Z * ((isVfly and self.Storage.values.vfly_speed or self.Storage.values.fly_speed) * 50))
				end
			end
		end)
	end

	function Core:Unfly()
		local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)
		local hrp = self.Client.fetchHrp(self.Client.LocalPlayer.Character)

		self.Storage.values.flying = false

		if self.Storage.connections.flyKeyDown or self.Storage.connections.flyKeyUp then
			self.Storage.connections.flyKeyDown:Disconnect()
			self.Storage.connections.flyKeyUp:Disconnect()

			self.Storage.connections.flyKeyDown = nil
			self.Storage.connections.flyKeyUp = nil
		end

		if self.Storage.connections.mfly1 or self.Storage.connections.mfly2 then
			self.Storage.connections.mfly1:Disconnect()
			self.Storage.connections.mfly2:Disconnect()

			self.Storage.connections.mfly1 = nil
			self.Storage.connections.mfly2 = nil
		end

		if hrp:FindFirstChild(self.Storage.values.m_fly_name1) then
			hrp[self.Storage.values.m_fly_name1]:Destroy()
		end
		if hrp:FindFirstChild(self.Storage.values.m_fly_name2) then
			hrp[self.Storage.values.m_fly_name2]:Destroy()
		end

		self.Client.spawn(function()
			self.Client.Camera.CameraType = Enum.CameraType.Custom
			if hum then
				hum.PlatformStand = false
			end
		end)
	end

	function Core:SetFlySpeed(isVfly, speed)
		if isVfly then
			self.Storage.values.vfly_speed = speed
		else
			self.Storage.values.fly_speed = speed
		end
	end

	function Core:RandomString()
		local length = math.random(10,20)
		local array = {}
		for i = 1, length do
			array[i] = string.char(math.random(32, 126))
		end
		return table.concat(array)
	end

	function Core:IsRigType(char, rigType)
		if char then
			local hum = self.Client.fetchHum(char)
			if hum then
				if hum.RigType == Enum.HumanoidRigType[rigType] then
					return true
				end
			end
		end
	end

	function Core:PlayAnimation(animId, properties, async: boolean?)
		if not async then
			self:StopAnimation()
		end

		local anim = Instance.new("Animation")
		anim.AnimationId = `rbxassetid://{animId}`

		local hum = self.Client.fetchHum(self.Client.LocalPlayer.Character)
		if hum then
			local animator = hum:FindFirstChild("Animator") or Instance.new("Animator", hum)
			local animation = animator:LoadAnimation(anim)

			if type(properties) == "table" then
				for i, v in pairs(properties) do
					animation[i] = v
				end
			end

			animation:Play()
			animation.Stopped:Connect(function()
				animation:Destroy()
			end)

			if not async then
				self.Storage.instances.animation = {inst = anim, anim = animation}
			else
				table.insert(self.Storage.instances.animations, {inst = anim, anim = animation})
			end
		else
			anim:Destroy()
		end
	end

	function Core:StopAnimation()
		if self.Storage.instances.animation then
			self.Storage.instances.animation.anim:Stop()
			self.Storage.instances.animation.inst:Destroy()
			self.Storage.instances.animation = nil
		end
		for i, v in pairs(self.Storage.instances.animations) do
			v.anim:Stop()
			v.inst:Destroy()
			v = nil
		end
	end

	function Core:SetAnimationSpeed(speed)
		if self.Storage.instances.animation then
			self.Storage.instances.animation.anim:AdjustSpeed(speed)
		end
		for i, v in pairs(self.Storage.instances.animations) do
			v.anim:AdjustSpeed(speed)
		end
	end

	function Core:Freecam(disableCores, pos)
		if self.freecamActive then
			self:StopFreecam()
		end
		self.freecamActive = true

		local cameraCFrame = self.Client.Camera.CFrame
		if pos then
			cameraCFrame = pos
		end

		local function stepFreecam(delta)
			local FOV_GAIN = 300

			local vel = self.velSpring:Update(delta, self.Client.PreloadedModules.input.Vel(delta))
			local pan = self.panSpring:Update(delta, self.Client.PreloadedModules.input.Pan(delta))
			local fov = self.fovSpring:Update(delta, self.Client.PreloadedModules.input.Fov(delta))

			local zoomFactor = math.sqrt(math.tan(math.rad(70/2)) / math.tan(math.rad(self.cameraFov/2)))

			self.cameraFov = math.clamp(self.cameraFov + fov*FOV_GAIN*(delta/zoomFactor), 1, 120)
			self.cameraRot = self.cameraRot + pan * Vector2.new(0.75, 1) * 8 * (delta / zoomFactor)
			self.cameraRot = Vector2.new(math.clamp(self.cameraRot.x, -math.rad(90), math.rad(90)), self.cameraRot.y % (2 * math.pi))

			local cameraCFrame = CFrame.new(self.cameraPos) * CFrame.fromOrientation(self.cameraRot.x, self.cameraRot.y, 0) * CFrame.new(vel * Vector3.new(1, 1, 1) * 64 * delta)
			self.cameraPos = cameraCFrame.p

			self.Client.Camera.FieldOfView = self.cameraFov
			self.Client.Camera.CFrame = cameraCFrame
			self.Client.Camera.Focus = cameraCFrame * CFrame.new(0, 0, self:_getFocusDistance(cameraCFrame))
		end

		self.cameraRot = Vector2.new()
		self.cameraPos = cameraCFrame.p
		self.cameraFov = self.Client.Camera.FieldOfView

		self.velSpring:Reset(Vector3.new())
		self.panSpring:Reset(Vector2.new())
		self.fovSpring:Reset(0)

		self.Client.Modules.parser:RunCommand(self.Client.LocalPlayer, "minzoom", "50")

		self.Client.PreloadedModules.playerState.Push(disableCores)

		self.Client.Services.RunService:BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, stepFreecam)

		self.Client.PreloadedModules.input.StartCapture()
	end

	function Core:StopFreecam()
		if self.freecamActive then
			self.freecamActive = false

			self.Client.PreloadedModules.input.StopCapture()
			self.Client.Services.RunService:UnbindFromRenderStep("Freecam")
			self.Client.PreloadedModules.playerState.Pop()
		end
	end

	function Core:Pathfind(goal, params, visualize, events, override, noHum)
		if not goal then
			return
		end
		if not events then
			events = {}
		end

		local path = self:_createNewPath(self.Client.LocalPlayer.Character, params, override, noHum)
		path.Visualize = visualize

		path.Ranned:Connect(function(model, currentWaypoint, nextWaypoint)
			if type(events.OnRan) == "function" then
				events.OnRan(model, currentWaypoint, nextWaypoint)
			end
		end)
		path.Error:Connect(function()
			if type(events.OnError) == "function" then
				events.OnError()
			end
			path:Run(goal)
		end)
		path.Blocked:Connect(function()
			if type(events.OnBlocked) == "function" then
				events.OnBlocked()
			end
			path:Run(goal)
		end)
		path.WaypointReached:Connect(function(model, lastWaypoint, nextWaypoint)
			if type(events.OnWaypointReached) == "function" then
				events.OnWaypointReached(model, lastWaypoint, nextWaypoint)
			end
			path:Run(goal)
		end)
		path.Reached:Connect(function(model, finalWaypoint)
			if type(events.OnReached) == "function" then
				events.OnReached(model, finalWaypoint)
			end
		end)
		path:Run(goal)

		return path
	end

	function Core:_getFocusDistance(cameraFrame)
		local znear = 0.1
		local viewport = self.Client.Camera.ViewportSize
		local projy = 2*math.tan(self.cameraFov/2)
		local projx = viewport.x/viewport.y*projy
		local fx = cameraFrame.rightVector
		local fy = cameraFrame.upVector
		local fz = cameraFrame.lookVector

		local minVect = Vector3.new()
		local minDist = 512

		for x = 0, 1, 0.5 do
			for y = 0, 1, 0.5 do
				local cx = (x - 0.5)*projx
				local cy = (y - 0.5)*projy
				local offset = fx*cx - fy*cy + fz
				local origin = cameraFrame.p + offset*znear
				local _, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
				local dist = (hit - origin).magnitude
				if minDist > dist then
					minDist = dist
					minVect = offset.unit
				end
			end
		end

		return fz:Dot(minVect)*minDist
	end

	function Core:_createNewPath(char, params, override, noHum)
		if self.Storage.currentPath then
			if not (self.Storage.currentPath._status == "Idle") then
				self.Storage.currentPath:Stop()
			end
			self.Storage.currentPath:Destroy()

			self.Storage.currentPath = nil
		end

		local path = modules.SimplePath().new(char, params, override, noHum)

		self.Storage.currentPath = path

		return path
	end

	return Core
end

function modules.ConsoleInterface()
	local G2L = {};

	-- StarterGui.Console
	G2L["1"] = Instance.new("ScreenGui");
	G2L["1"]["IgnoreGuiInset"] = true;
	G2L["1"]["Enabled"] = false;
	G2L["1"]["ScreenInsets"] = Enum.ScreenInsets.DeviceSafeInsets;
	G2L["1"]["Name"] = [[Console]];
	G2L["1"]["ResetOnSpawn"] = false;

	-- StarterGui.Console.Main
	G2L["2"] = Instance.new("Frame", G2L["1"]);
	G2L["2"]["ZIndex"] = -1;
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(31, 31, 31);
	G2L["2"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["2"]["Size"] = UDim2.new(0, 800, 0, 50);
	G2L["2"]["Position"] = UDim2.new(.5,0,.5,20);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Name"] = [[Main]];
	G2L["2"]["BackgroundTransparency"] = 1;

	-- StarterGui.Console.Main.Background
	G2L["3"] = Instance.new("Frame", G2L["2"]);
	G2L["3"]["ZIndex"] = 0;
	G2L["3"]["BorderSizePixel"] = 0;
	G2L["3"]["BackgroundColor3"] = Color3.fromRGB(41, 41, 41);
	G2L["3"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["3"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["3"]["Name"] = [[Background]];
	G2L["3"]["BackgroundTransparency"] = 0.8;

	-- StarterGui.Console.Main.Background.UICorner
	G2L["4"] = Instance.new("UICorner", G2L["3"]);
	G2L["4"]["CornerRadius"] = UDim.new(0, 10);

	-- StarterGui.Console.Main.Background.DropShadow2
	G2L["6"] = Instance.new("ImageLabel", G2L["3"]);
	G2L["6"]["ZIndex"] = -6;
	G2L["6"]["BorderSizePixel"] = 0;
	G2L["6"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["6"]["ImageTransparency"] = 0.8;
	G2L["6"]["ImageColor3"] = Color3.fromRGB(22, 22, 22);
	G2L["6"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["6"]["Image"] = [[rbxassetid://5587865193]];
	G2L["6"]["Size"] = UDim2.new(1.35, 0, 1.5, 0);
	G2L["6"]["BackgroundTransparency"] = 1;
	G2L["6"]["Name"] = [[DropShadow2]];
	G2L["6"]["Position"] = UDim2.new(0.507, 0, 0.7, 0);

	-- StarterGui.Console.Main.Background.DropShadow1
	G2L["7"] = Instance.new("ImageLabel", G2L["3"]);
	G2L["7"]["ZIndex"] = -22;
	G2L["7"]["BorderSizePixel"] = 0;
	G2L["7"]["SliceCenter"] = Rect.new(49, 49, 450, 450);
	G2L["7"]["ScaleType"] = Enum.ScaleType.Slice;
	G2L["7"]["ImageTransparency"] = 0.5;
	G2L["7"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["7"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["7"]["Image"] = [[rbxassetid://6014261993]];
	G2L["7"]["Size"] = UDim2.new(1, 40, 1, 40);
	G2L["7"]["BackgroundTransparency"] = 1;
	G2L["7"]["Name"] = [[DropShadow1]];
	G2L["7"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

	-- StarterGui.Console.Main.Content
	G2L["8"] = Instance.new("Frame", G2L["2"]);
	G2L["8"]["BorderSizePixel"] = 0;
	G2L["8"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["8"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["8"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["8"]["Name"] = [[Content]];
	G2L["8"]["BackgroundTransparency"] = 1;

	-- StarterGui.Console.Main.Content.ScrollingFrame
	G2L["9"] = Instance.new("ScrollingFrame", G2L["8"]);
	G2L["9"]["Active"] = true;
	G2L["9"]["BorderSizePixel"] = 0;
	G2L["9"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
	G2L["9"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["9"]["ScrollBarImageTransparency"] = 1;
	G2L["9"]["AutomaticCanvasSize"] = Enum.AutomaticSize.X;
	G2L["9"]["Size"] = UDim2.new(1, -120, 1, 0);
	G2L["9"]["ScrollBarImageColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["9"]["Position"] = UDim2.new(0, 45, 0, 0);
	G2L["9"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["9"]["ScrollBarThickness"] = 0;
	G2L["9"]["BackgroundTransparency"] = 1;

	-- StarterGui.Console.Main.Content.ScrollingFrame.TextBox
	G2L["a"] = Instance.new("TextBox", G2L["9"]);
	G2L["a"]["TextColor3"] = Color3.fromRGB(226, 226, 226);
	G2L["a"]["PlaceholderColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["a"]["ZIndex"] = 3;
	G2L["a"]["BorderSizePixel"] = 0;
	G2L["a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["a"]["TextSize"] = 18;
	G2L["a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["a"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["a"]["PlaceholderText"] = [[Bananas Admin Console]];
	G2L["a"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["a"]["Text"] = [[]];
	G2L["a"]["BackgroundTransparency"] = 1;

	-- StarterGui.Console.Main.Content.ScrollingFrame.TextBox.Autofill
	G2L["b"] = Instance.new("TextLabel", G2L["a"]);
	G2L["b"]["BorderSizePixel"] = 0;
	G2L["b"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["b"]["TextSize"] = 18;
	G2L["b"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["b"]["TextColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["b"]["BackgroundTransparency"] = 1;
	G2L["b"]["RichText"] = true;
	G2L["b"]["Size"] = UDim2.new(0, 0, 1, 0);
	G2L["b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["b"]["Text"] = [[]];
	G2L["b"]["AutomaticSize"] = Enum.AutomaticSize.X;
	G2L["b"]["Name"] = [[Autofill]];

	-- StarterGui.Console.Main.Content.ScrollingFrame.TextBox.Colorfill
	G2L["c"] = Instance.new("TextLabel", G2L["a"]);
	G2L["c"]["ZIndex"] = 4;
	G2L["c"]["BorderSizePixel"] = 0;
	G2L["c"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["c"]["TextSize"] = 18;
	G2L["c"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["c"]["TextColor3"] = Color3.fromRGB(226, 226, 226);
	G2L["c"]["BackgroundTransparency"] = 1;
	G2L["c"]["RichText"] = true;
	G2L["c"]["Size"] = UDim2.new(0, 0, 1, 0);
	G2L["c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["c"]["Text"] = [[]];
	G2L["c"]["AutomaticSize"] = Enum.AutomaticSize.X;
	G2L["c"]["Name"] = [[Colorfill]];

	-- StarterGui.Console.Main.Content.ScrollingFrame.UIPadding
	G2L["d"] = Instance.new("UIPadding", G2L["9"]);
	G2L["d"]["PaddingLeft"] = UDim.new(0, 5);

	-- StarterGui.Console.Main.Content.Commands
	G2L["e"] = Instance.new("Frame", G2L["8"]);
	G2L["e"]["ZIndex"] = -1;
	G2L["e"]["BorderSizePixel"] = 0;
	G2L["e"]["BackgroundColor3"] = Color3.fromRGB(41, 41, 41);
	G2L["e"]["ClipsDescendants"] = true;
	G2L["e"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["e"]["Name"] = [[Commands]];
	G2L["e"]["BackgroundTransparency"] = 0.1;

	-- StarterGui.Console.Main.Content.Commands.UICorner
	G2L["f"] = Instance.new("UICorner", G2L["e"]);
	G2L["f"]["CornerRadius"] = UDim.new(0, 10);

	-- StarterGui.Console.Main.Content.Commands.UIPadding
	G2L["10"] = Instance.new("UIPadding", G2L["e"]);
	G2L["10"]["PaddingTop"] = UDim.new(0, 50);

	-- StarterGui.Console.Main.Content.Commands.Background
	G2L["11"] = Instance.new("ImageLabel", G2L["e"]);
	G2L["11"]["ZIndex"] = -1;
	G2L["11"]["BorderSizePixel"] = 0;
	G2L["11"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["11"]["ScaleType"] = Enum.ScaleType.Crop;
	G2L["11"]["ImageTransparency"] = 0.9;
	G2L["11"]["Image"] = [[rbxassetid://16255699706]];
	G2L["11"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["11"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["11"]["BackgroundTransparency"] = 1;
	G2L["11"]["Name"] = [[Background]];

	-- StarterGui.Console.Main.Content.Commands.Background.UICorner
	G2L["12"] = Instance.new("UICorner", G2L["11"]);
	G2L["12"]["CornerRadius"] = UDim.new(0, 10);

	-- StarterGui.Console.Main.Content.Icon
	G2L["13"] = Instance.new("ImageLabel", G2L["8"]);
	G2L["13"]["ZIndex"] = 2;
	G2L["13"]["BorderSizePixel"] = 0;
	G2L["13"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["13"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["13"]["AnchorPoint"] = Vector2.new(0, 0.5);
	G2L["13"]["Image"] = [[rbxassetid://18559711622]];
	G2L["13"]["Size"] = UDim2.new(0, 20, 0, 20);
	G2L["13"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["13"]["BackgroundTransparency"] = 1;
	G2L["13"]["Name"] = [[Icon]];
	G2L["13"]["Position"] = UDim2.new(0, 15, 0.5, 0);

	-- StarterGui.Console.Main.Content.Icon.Background
	G2L["14"] = Instance.new("Frame", G2L["13"]);
	G2L["14"]["BorderSizePixel"] = 0;
	G2L["14"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
	G2L["14"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["14"]["Size"] = UDim2.new(1, 10, 1, 10);
	G2L["14"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);
	G2L["14"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["14"]["Name"] = [[Background]];

	-- StarterGui.Console.Main.Content.Icon.Background.UICorner
	G2L["15"] = Instance.new("UICorner", G2L["14"]);


	-- StarterGui.Console.Main.Content.Tab
	G2L["16"] = Instance.new("TextLabel", G2L["8"]);
	G2L["16"]["BorderSizePixel"] = 0;
	G2L["16"]["BackgroundColor3"] = Color3.fromRGB(51, 51, 51);
	G2L["16"]["TextSize"] = 14;
	G2L["16"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["16"]["TextColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["16"]["BackgroundTransparency"] = 0.1;
	G2L["16"]["AnchorPoint"] = Vector2.new(1, 0.5);
	G2L["16"]["Size"] = UDim2.new(0, 50, 0, 25);
	G2L["16"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["16"]["Text"] = [[Tab]];
	G2L["16"]["Name"] = [[Tab]];
	G2L["16"]["Position"] = UDim2.new(1, -15, 0.5, 0);

	-- StarterGui.Console.Main.Content.Tab.UICorner
	G2L["17"] = Instance.new("UICorner", G2L["16"]);


	-- StarterGui.Console.Main.Content.Templates
	G2L["18"] = Instance.new("Folder", G2L["8"]);
	G2L["18"]["Name"] = [[Templates]];

	-- StarterGui.Console.Main.Content.Templates.Command
	G2L["19"] = Instance.new("ImageLabel", G2L["18"]);
	G2L["19"]["ZIndex"] = -1;
	G2L["19"]["BackgroundColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["19"]["ImageTransparency"] = 1;
	G2L["19"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["19"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["19"]["Size"] = UDim2.new(1, 0, 0, 50);
	G2L["19"]["Visible"] = false;
	G2L["19"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["19"]["BackgroundTransparency"] = 1;
	G2L["19"]["Name"] = [[Command]];

	-- StarterGui.Console.Main.Content.Templates.Command.NameLabel
	G2L["1a"] = Instance.new("TextLabel", G2L["19"]);
	G2L["1a"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["1a"]["ZIndex"] = -1;
	G2L["1a"]["BorderSizePixel"] = 0;
	G2L["1a"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["1a"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1a"]["TextSize"] = 18;
	G2L["1a"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["1a"]["TextColor3"] = Color3.fromRGB(226, 226, 226);
	G2L["1a"]["BackgroundTransparency"] = 1;
	G2L["1a"]["RichText"] = true;
	G2L["1a"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["1a"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1a"]["Text"] = "";
	G2L["1a"]["Name"] = [[NameLabel]];

	-- StarterGui.Console.Main.Content.Templates.Command.NameLabel.UIPadding
	G2L["1b"] = Instance.new("UIPadding", G2L["1a"]);
	G2L["1b"]["PaddingBottom"] = UDim.new(0, 10);

	-- StarterGui.Console.Main.Content.Templates.Command.UIPadding
	G2L["1c"] = Instance.new("UIPadding", G2L["19"]);
	G2L["1c"]["PaddingTop"] = UDim.new(0, 15);
	G2L["1c"]["PaddingRight"] = UDim.new(0, 15);
	G2L["1c"]["PaddingLeft"] = UDim.new(0, 15);
	G2L["1c"]["PaddingBottom"] = UDim.new(0, 15);

	-- StarterGui.Console.Main.Content.Templates.Command.Description
	G2L["1d"] = Instance.new("TextLabel", G2L["19"]);
	G2L["1d"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["1d"]["ZIndex"] = -1;
	G2L["1d"]["BorderSizePixel"] = 0;
	G2L["1d"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["1d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1d"]["TextSize"] = 12;
	G2L["1d"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["1d"]["TextColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["1d"]["BackgroundTransparency"] = 1;
	G2L["1d"]["RichText"] = true;
	G2L["1d"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["1d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1d"]["Text"] = "";
	G2L["1d"]["Name"] = [[Description]];
	G2L["1d"]["Position"] = UDim2.new(0, 0, 0, 10);

	-- StarterGui.Console.Main.Content.Templates.Command.UICorner
	G2L["1e"] = Instance.new("UICorner", G2L["19"]);
	G2L["1e"]["CornerRadius"] = UDim.new(0, 10);

	-- StarterGui.Console.Main.Content.Templates.Command.Select
	G2L["1f"] = Instance.new("Frame", G2L["19"]);
	G2L["1f"]["Visible"] = false;
	G2L["1f"]["BorderSizePixel"] = 0;
	G2L["1f"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
	G2L["1f"]["AnchorPoint"] = Vector2.new(1, 0);
	G2L["1f"]["Size"] = UDim2.new(0, 2, 1, 0);
	G2L["1f"]["Position"] = UDim2.new(1, 0, 0, 0);
	G2L["1f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1f"]["Name"] = [[Select]];

	-- StarterGui.Console.Main.Content.Effects
	G2L["20"] = Instance.new("Frame", G2L["8"]);
	G2L["20"]["BorderSizePixel"] = 0;
	G2L["20"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["20"]["ClipsDescendants"] = true;
	G2L["20"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["20"]["BorderColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["20"]["Name"] = [[Effects]];
	G2L["20"]["BackgroundTransparency"] = 1;

	-- StarterGui.Console.Main.Content.Effects.EnterEffect
	G2L["21"] = Instance.new("ImageLabel", G2L["20"]);
	G2L["21"]["ZIndex"] = 10;
	G2L["21"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["21"]["ImageTransparency"] = 0.9;
	G2L["21"]["ImageColor3"] = Color3.fromRGB(255, 0, 0);
	G2L["21"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["21"]["Image"] = [[rbxassetid://266543268]];
	G2L["21"]["BorderColor3"] = Color3.fromRGB(28, 43, 54);
	G2L["21"]["BackgroundTransparency"] = 1;
	G2L["21"]["Name"] = [[EnterEffect]];
	G2L["21"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

	-- StarterGui.Console.Main.Scale
	G2L["22"] = Instance.new("UIScale", G2L["2"]);
	G2L["22"]["Name"] = [[Scale]];

	-- StarterGui.Console.Main.MouseUnlock
	G2L["23"] = Instance.new("TextButton", G2L["2"]);
	G2L["23"]["Modal"] = true;
	G2L["23"]["TextSize"] = 14;
	G2L["23"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["23"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["23"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["23"]["Selectable"] = false;
	G2L["23"]["BackgroundTransparency"] = 1;
	G2L["23"]["Name"] = [[MouseUnlock]];
	G2L["23"]["BorderColor3"] = Color3.fromRGB(28, 43, 54);
	G2L["23"]["Text"] = [[]];

	-- StarterGui.Console.Blur
	G2L["24"] = Instance.new("ScreenGui", G2L["1"]);
	G2L["24"]["IgnoreGuiInset"] = true;
	G2L["24"]["DisplayOrder"] = 2147483645;
	G2L["24"]["ScreenInsets"] = Enum.ScreenInsets.DeviceSafeInsets;
	G2L["24"]["Name"] = [[Blur]];

	-- StarterGui.Console.Blur.Frame
	G2L["25"] = Instance.new("Frame", G2L["24"]);
	G2L["25"]["BorderSizePixel"] = 0;
	G2L["25"]["BackgroundColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["25"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["25"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["25"]["BackgroundTransparency"] = 1;

	-- StarterGui.Console.Open
	G2L["26"] = Instance.new("TextButton", G2L["1"]);
	G2L["26"]["BorderSizePixel"] = 0;
	G2L["26"]["TextTransparency"] = 1;
	G2L["26"]["TextSize"] = 1;
	G2L["26"]["TextColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["26"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["26"]["FontFace"] = Font.new([[rbxasset://fonts/families/SourceSansPro.json]], Enum.FontWeight.Regular, Enum.FontStyle.Normal);
	G2L["26"]["AnchorPoint"] = Vector2.new(1, 0.5);
	G2L["26"]["Size"] = UDim2.new(0, 200, 0, 50);
	G2L["26"]["BackgroundTransparency"] = 1;
	G2L["26"]["Name"] = [[Open]];
	G2L["26"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["26"]["Text"] = [[]];
	G2L["26"]["Position"] = UDim2.new(1, -10, 0.5, 0);

	-- StarterGui.Console.Open.Background
	G2L["27"] = Instance.new("Frame", G2L["26"]);
	G2L["27"]["ZIndex"] = 0;
	G2L["27"]["BorderSizePixel"] = 0;
	G2L["27"]["BackgroundColor3"] = Color3.fromRGB(41, 41, 41);
	G2L["27"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["27"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["27"]["Name"] = [[Background]];
	G2L["27"]["BackgroundTransparency"] = 0.5;

	-- StarterGui.Console.Open.Background.UICorner
	G2L["28"] = Instance.new("UICorner", G2L["27"]);
	G2L["28"]["CornerRadius"] = UDim.new(0, 10);

	-- StarterGui.Console.Open.Background.UIStroke
	G2L["2a"] = Instance.new("UIStroke", G2L["27"]);
	G2L["2a"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
	G2L["2a"]["Color"] = Color3.fromRGB(41, 41, 41);

	-- StarterGui.Console.Open.Background.DropShadow1
	G2L["2b"] = Instance.new("ImageLabel", G2L["27"]);
	G2L["2b"]["ZIndex"] = -22;
	G2L["2b"]["BorderSizePixel"] = 0;
	G2L["2b"]["SliceCenter"] = Rect.new(49, 49, 450, 450);
	G2L["2b"]["ScaleType"] = Enum.ScaleType.Slice;
	G2L["2b"]["ImageTransparency"] = 0.5;
	G2L["2b"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2b"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["2b"]["Image"] = [[rbxassetid://6014261993]];
	G2L["2b"]["Size"] = UDim2.new(1, 40, 1, 40);
	G2L["2b"]["BackgroundTransparency"] = 1;
	G2L["2b"]["Name"] = [[DropShadow1]];
	G2L["2b"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

	-- StarterGui.Console.Open.Background.DropShadow2
	G2L["2c"] = Instance.new("ImageLabel", G2L["27"]);
	G2L["2c"]["ZIndex"] = -6;
	G2L["2c"]["BorderSizePixel"] = 0;
	G2L["2c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2c"]["ImageTransparency"] = 0.8;
	G2L["2c"]["ImageColor3"] = Color3.fromRGB(22, 22, 22);
	G2L["2c"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["2c"]["Image"] = [[rbxassetid://5587865193]];
	G2L["2c"]["Size"] = UDim2.new(1.35, 0, 1.5, 0);
	G2L["2c"]["BackgroundTransparency"] = 1;
	G2L["2c"]["Name"] = [[DropShadow2]];
	G2L["2c"]["Position"] = UDim2.new(0.507, 0, 0.7, 0);

	-- StarterGui.Console.Open.Title
	G2L["2d"] = Instance.new("TextLabel", G2L["26"]);
	G2L["2d"]["BorderSizePixel"] = 0;
	G2L["2d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["2d"]["TextSize"] = 16;
	G2L["2d"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["2d"]["TextColor3"] = Color3.fromRGB(236, 236, 236);
	G2L["2d"]["BackgroundTransparency"] = 1;
	G2L["2d"]["RichText"] = true;
	G2L["2d"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["2d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2d"]["Text"] = [[OPEN CONSOLE]];
	G2L["2d"]["Name"] = [[Title]];

	-- StarterGui.Console.Main.Background.UIStroke
	G2L["5"] = Instance.new("UIStroke", G2L["e"]);
	G2L["5"]["ApplyStrokeMode"] = Enum.ApplyStrokeMode.Border;
	G2L["5"]["Color"] = Color3.fromRGB(41, 41, 41);

	return G2L["1"];
end

function modules.NotifyUI()
	local G2L = {};
	-- StarterGui.ScreenGui.Notification
	G2L["2"] = Instance.new("Frame");
	G2L["2"]["BorderSizePixel"] = 0;
	G2L["2"]["BackgroundColor3"] = Color3.fromRGB(41, 41, 41);
	G2L["2"]["Size"] = UDim2.new(1, 0, 0, 150);
	G2L["2"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["2"]["Name"] = [[Notification]];
	G2L["2"]["BackgroundTransparency"] = 1;

	-- StarterGui.ScreenGui.Notification.Graphical
	G2L["3"] = Instance.new("Folder", G2L["2"]);
	G2L["3"]["Name"] = [[Graphical]];

	-- StarterGui.ScreenGui.Notification.Graphical.Background
	G2L["4"] = Instance.new("Frame", G2L["3"]);
	G2L["4"]["Visible"] = false;
	G2L["4"]["ZIndex"] = -5;
	G2L["4"]["BorderSizePixel"] = 0;
	G2L["4"]["BackgroundColor3"] = Color3.fromRGB(26, 26, 26);
	G2L["4"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["4"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["4"]["Name"] = [[Background]];
	G2L["4"]["BackgroundTransparency"] = 0.2;

	-- StarterGui.ScreenGui.Notification.Graphical.Background.DropShadow1
	G2L["5"] = Instance.new("ImageLabel", G2L["4"]);
	G2L["5"]["ZIndex"] = -6;
	G2L["5"]["BorderSizePixel"] = 0;
	G2L["5"]["SliceCenter"] = Rect.new(49, 49, 450, 450);
	G2L["5"]["ScaleType"] = Enum.ScaleType.Slice;
	G2L["5"]["ImageTransparency"] = 0.5;
	G2L["5"]["ImageColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["5"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["5"]["Image"] = [[rbxassetid://6014261993]];
	G2L["5"]["Size"] = UDim2.new(1, 47, 1, 47);
	G2L["5"]["BackgroundTransparency"] = 1;
	G2L["5"]["Name"] = [[DropShadow1]];
	G2L["5"]["Position"] = UDim2.new(0.5, 0, 0.5, 0);

	-- StarterGui.ScreenGui.Notification.Graphical.Background.UICorner
	G2L["6"] = Instance.new("UICorner", G2L["4"]);
	G2L["6"]["CornerRadius"] = UDim.new(0, 10);

	-- StarterGui.ScreenGui.Notification.Graphical.Background.DropShadow2
	G2L["7"] = Instance.new("ImageLabel", G2L["4"]);
	G2L["7"]["ZIndex"] = -6;
	G2L["7"]["BorderSizePixel"] = 0;
	G2L["7"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["7"]["ImageTransparency"] = 0.2;
	G2L["7"]["ImageColor3"] = Color3.fromRGB(22, 22, 22);
	G2L["7"]["AnchorPoint"] = Vector2.new(0.5, 0.5);
	G2L["7"]["Image"] = [[rbxassetid://5587865193]];
	G2L["7"]["Size"] = UDim2.new(1.6, 0, 1.3, 0);
	G2L["7"]["BackgroundTransparency"] = 1;
	G2L["7"]["Name"] = [[DropShadow2]];
	G2L["7"]["Position"] = UDim2.new(0.50748, 0, 0.5098, 0);
	-- Attributes
	G2L["7"]:SetAttribute([[InitialBackgroundTransparency]], 1);
	G2L["7"]:SetAttribute([[InitialImageTransparency]], 0.4);

	-- StarterGui.ScreenGui.Notification.Graphical.Background.Background
	G2L["9"] = Instance.new("ImageLabel", G2L["4"]);
	G2L["9"]["ZIndex"] = -1;
	G2L["9"]["BorderSizePixel"] = 0;
	G2L["9"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["9"]["ScaleType"] = Enum.ScaleType.Crop;
	G2L["9"]["ImageTransparency"] = 0.9;
	G2L["9"]["Image"] = [[rbxassetid://16255699706]];
	G2L["9"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["9"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["9"]["BackgroundTransparency"] = 1;
	G2L["9"]["Name"] = [[Background]];

	-- StarterGui.ScreenGui.Notification.Graphical.Background.Background.UICorner
	G2L["a"] = Instance.new("UICorner", G2L["9"]);
	G2L["a"]["CornerRadius"] = UDim.new(0, 10);

	-- StarterGui.ScreenGui.Notification.Graphical.Content
	G2L["b"] = Instance.new("Frame", G2L["3"]);
	G2L["b"]["Visible"] = false;
	G2L["b"]["BorderSizePixel"] = 0;
	G2L["b"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["b"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["b"]["Size"] = UDim2.new(1, 0, 1, -45);
	G2L["b"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["b"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["b"]["Name"] = [[Content]];
	G2L["b"]["BackgroundTransparency"] = 1;

	-- StarterGui.ScreenGui.Notification.Graphical.Content.Scroll
	G2L["c"] = Instance.new("ScrollingFrame", G2L["b"]);
	G2L["c"]["Active"] = true;
	G2L["c"]["BorderSizePixel"] = 0;
	G2L["c"]["CanvasSize"] = UDim2.new(0, 0, 0, 0);
	G2L["c"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["c"]["Name"] = [[Scroll]];
	G2L["c"]["AutomaticCanvasSize"] = Enum.AutomaticSize.Y;
	G2L["c"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["c"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["c"]["ScrollBarThickness"] = 1;
	G2L["c"]["BackgroundTransparency"] = 1;

	-- StarterGui.ScreenGui.Notification.Graphical.Content.Scroll.Description
	G2L["d"] = Instance.new("TextLabel", G2L["c"]);
	G2L["d"]["TextTruncate"] = Enum.TextTruncate.AtEnd;
	G2L["d"]["BorderSizePixel"] = 0;
	G2L["d"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["d"]["TextYAlignment"] = Enum.TextYAlignment.Top;
	G2L["d"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["d"]["TextSize"] = 14;
	G2L["d"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["d"]["TextColor3"] = Color3.fromRGB(151, 151, 151);
	G2L["d"]["BackgroundTransparency"] = 1;
	G2L["d"]["RichText"] = true;
	G2L["d"]["Size"] = UDim2.new(1, 0, 0, 0);
	G2L["d"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["d"]["Text"] = [[Wow guys! This is a description! Can't you believe that?]];
	G2L["d"]["AutomaticSize"] = Enum.AutomaticSize.Y;
	G2L["d"]["Name"] = [[Description]];

	-- StarterGui.ScreenGui.Notification.Graphical.Content.Scroll.Description.UIPadding
	G2L["e"] = Instance.new("UIPadding", G2L["d"]);
	G2L["e"]["PaddingTop"] = UDim.new(0, 15);
	G2L["e"]["PaddingRight"] = UDim.new(0, 15);
	G2L["e"]["PaddingLeft"] = UDim.new(0, 15);
	G2L["e"]["PaddingBottom"] = UDim.new(0, 15);

	-- StarterGui.ScreenGui.Notification.Graphical.Content.Bottom
	G2L["f"] = Instance.new("Frame", G2L["b"]);
	G2L["f"]["BorderSizePixel"] = 0;
	G2L["f"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["f"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["f"]["ClipsDescendants"] = true;
	G2L["f"]["Size"] = UDim2.new(1, 0, 0, 6);
	G2L["f"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["f"]["Name"] = [[Bottom]];
	G2L["f"]["BackgroundTransparency"] = 1;

	-- StarterGui.ScreenGui.Notification.Graphical.Content.Bottom.Fill
	G2L["10"] = Instance.new("Frame", G2L["f"]);
	G2L["10"]["BorderSizePixel"] = 0;
	G2L["10"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
	G2L["10"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["10"]["Size"] = UDim2.new(0, 0, 1, 10);
	G2L["10"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["10"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["10"]["Name"] = [[Fill]];

	-- StarterGui.ScreenGui.Notification.Graphical.Content.Bottom.Fill.UICorner
	G2L["11"] = Instance.new("UICorner", G2L["10"]);
	G2L["11"]["CornerRadius"] = UDim.new(0, 10);

	-- StarterGui.ScreenGui.Notification.Graphical.Top
	G2L["12"] = Instance.new("Frame", G2L["3"]);
	G2L["12"]["Visible"] = false;
	G2L["12"]["BorderSizePixel"] = 0;
	G2L["12"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["12"]["Size"] = UDim2.new(1, 0, 0, 45);
	G2L["12"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["12"]["Name"] = [[Top]];
	G2L["12"]["BackgroundTransparency"] = 1;

	-- StarterGui.ScreenGui.Notification.Graphical.Top.Title
	G2L["13"] = Instance.new("TextLabel", G2L["12"]);
	G2L["13"]["BorderSizePixel"] = 0;
	G2L["13"]["TextXAlignment"] = Enum.TextXAlignment.Left;
	G2L["13"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["13"]["TextSize"] = 16;
	G2L["13"]["FontFace"] = Font.new([[rbxasset://fonts/families/GothamSSm.json]], Enum.FontWeight.Medium, Enum.FontStyle.Normal);
	G2L["13"]["TextColor3"] = Color3.fromRGB(236, 236, 236);
	G2L["13"]["BackgroundTransparency"] = 1;
	G2L["13"]["RichText"] = true;
	G2L["13"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["13"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["13"]["Text"] = [[OmniControl]];
	G2L["13"]["Name"] = [[Title]];

	-- StarterGui.ScreenGui.Notification.Graphical.Top.Title.UIPadding
	G2L["14"] = Instance.new("UIPadding", G2L["13"]);
	G2L["14"]["PaddingTop"] = UDim.new(0, 15);
	G2L["14"]["PaddingRight"] = UDim.new(0, 15);
	G2L["14"]["PaddingLeft"] = UDim.new(0, 15);
	G2L["14"]["PaddingBottom"] = UDim.new(0, 15);

	-- StarterGui.ScreenGui.Notification.Graphical.Top.Underline
	G2L["15"] = Instance.new("Frame", G2L["12"]);
	G2L["15"]["BorderSizePixel"] = 0;
	G2L["15"]["BackgroundColor3"] = Color3.fromRGB(51, 51, 51);
	G2L["15"]["AnchorPoint"] = Vector2.new(0, 1);
	G2L["15"]["Size"] = UDim2.new(1, 0, 0, 1);
	G2L["15"]["Position"] = UDim2.new(0, 0, 1, 0);
	G2L["15"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["15"]["Name"] = [[Underline]];

	-- StarterGui.ScreenGui.Notification.Graphical.Top.Icon
	G2L["16"] = Instance.new("ImageLabel", G2L["12"]);
	G2L["16"]["BorderSizePixel"] = 0;
	G2L["16"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["16"]["ImageColor3"] = Color3.fromRGB(255, 0, 0);
	G2L["16"]["AnchorPoint"] = Vector2.new(1, 0.5);
	G2L["16"]["Image"] = [[rbxassetid://2790458276]];
	G2L["16"]["Size"] = UDim2.new(0, 25, 0, 25);
	G2L["16"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["16"]["BackgroundTransparency"] = 1;
	G2L["16"]["Name"] = [[Icon]];
	G2L["16"]["Position"] = UDim2.new(1, -10, 0.5, 0);

	-- StarterGui.ScreenGui.Notification.Graphical.Button
	G2L["17"] = Instance.new("ImageButton", G2L["3"]);
	G2L["17"]["BorderSizePixel"] = 0;
	G2L["17"]["ImageTransparency"] = 1;
	G2L["17"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["17"]["ZIndex"] = 5;
	G2L["17"]["Image"] = [[rbxasset://textures/ui/GuiImagePlaceholder.png]];
	G2L["17"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["17"]["BackgroundTransparency"] = 1;
	G2L["17"]["Name"] = [[Button]];
	G2L["17"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);

	-- StarterGui.ScreenGui.Notification.Scripts
	G2L["18"] = Instance.new("Folder", G2L["2"]);
	G2L["18"]["Name"] = [[Scripts]];

	-- StarterGui.ScreenGui.Notification.Scripts.Core
	G2L["19"] = Instance.new("LocalScript", G2L["18"]);
	G2L["19"]["Name"] = [[Core]];

	-- StarterGui.ScreenGui.Notification.Settings
	G2L["1a"] = Instance.new("Folder", G2L["2"]);
	G2L["1a"]["Name"] = [[Settings]];

	-- StarterGui.ScreenGui.Notification.Settings.NameString
	G2L["1b"] = Instance.new("StringValue", G2L["1a"]);
	G2L["1b"]["Name"] = [[NameString]];
	G2L["1b"]["Value"] = [[nil]];

	-- StarterGui.ScreenGui.Notification.Settings.DescriptionString
	G2L["1c"] = Instance.new("StringValue", G2L["1a"]);
	G2L["1c"]["Name"] = [[DescriptionString]];
	G2L["1c"]["Value"] = [[nil]];

	-- StarterGui.ScreenGui.Notification.Settings.DurationNumber
	G2L["1d"] = Instance.new("NumberValue", G2L["1a"]);
	G2L["1d"]["Name"] = [[DurationNumber]];
	G2L["1d"]["Value"] = 15;

	-- StarterGui.ScreenGui.Notification.Intro
	G2L["1e"] = Instance.new("Frame", G2L["2"]);
	G2L["1e"]["BorderSizePixel"] = 0;
	G2L["1e"]["BackgroundColor3"] = Color3.fromRGB(255, 255, 255);
	G2L["1e"]["ClipsDescendants"] = true;
	G2L["1e"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["1e"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1e"]["Name"] = [[Intro]];
	G2L["1e"]["BackgroundTransparency"] = 1;

	-- StarterGui.ScreenGui.Notification.Intro.Line
	G2L["1f"] = Instance.new("Frame", G2L["1e"]);
	G2L["1f"]["ZIndex"] = 10;
	G2L["1f"]["BorderSizePixel"] = 0;
	G2L["1f"]["BackgroundColor3"] = Color3.fromRGB(255, 0, 0);
	G2L["1f"]["Size"] = UDim2.new(1, 0, 1, 0);
	G2L["1f"]["Position"] = UDim2.new(-1, 0, 0, 0);
	G2L["1f"]["BorderColor3"] = Color3.fromRGB(0, 0, 0);
	G2L["1f"]["Name"] = [[Line]];

	-- StarterGui.ScreenGui.Notification.Scripts.Core


	return G2L["2"]
end

function modules.UniversalCommands()
	local module = {}

	function module.new(self)
		local sethidden
		local gethidden
		local queueteleport
		local httprequest
		local getconnections

		local universalValues = {
			-- Evade --
			evade_ticket_farming = false,
			break_bots = false,

			-- others --
			aimlock_holding_mouse = false,
			walkflinging = false,
			isInvisible = false,
		}

		local universalConnections = {
			bangDied = nil,

			invisFix = nil,
			invisDied = nil,

			swimming = nil,
			swimDied = nil,

			espCharAdded = {},
		}

		local universalStorage = {
			old_gravity = 192.2,
			old_hipheight = 0,
		}

		local universalFuncs = {
			turnVisible = nil,
		}

		local instances = {
			fov_circle = nil,
			spin_force = nil,

			esp_instances = {},
		}

		if not self.Services.RunService:IsStudio() then
			sethidden = sethiddenproperty or set_hidden_property or set_hidden_prop
			gethidden = gethiddenproperty or get_hidden_property or get_hidden_prop
			queueteleport = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
			httprequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
			getconnections = getconnections or get_signal_cons
		end

		local function gameDetectedNotify(gameName)
			self.spawn(function()
				task.wait(1)
				self:Notify(self.Config.SYSTEM.NAME, `Game detected: <b>{gameName}</b> new commands loaded or modified`, "INFO", nil, 5)
			end)
		end

		local function loadSupportedGame(placeId, gameName, func)
			if game.PlaceId == placeId then
				gameDetectedNotify(gameName)
				if type(func) == "function" then
					func()
				end
			end
		end
		local function loadDetection(name, detection, onLoad)
			if type(detection) == "function" and type(onLoad) == "function" then
				if detection() then
					self.spawn(function()
						task.wait(1)
						self:Notify(self.Config.SYSTEM.NAME, `Loading detection "<b>{name}</b>"`, "INFO", nil, 5)
					end)
					onLoad()
				end
			end
		end

		loadSupportedGame(9872472334, "Evade", function()
			local ticketWaitInterval = .5

			self:AddCommand({
				Name = "EventGrind",
				Description = "Makes you grind for the special points (Credits to: Bac0nH1ckOff)",

				Aliases = {"EGrind", "TicketGrind"},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --
					local tickets = workspace:FindFirstChild("Game")
						and workspace.Game:FindFirstChild("Effects")
						and workspace.Game.Effects:FindFirstChild("Tickets")

					-- 関数 --
					if tickets then
						universalValues.evade_ticket_farming = true

						while universalValues.evade_ticket_farming do
							local hrp = self.fetchHrp(speaker.Character)

							tickets = workspace:FindFirstChild("Game")
								and workspace.Game:FindFirstChild("Effects")
								and workspace.Game.Effects:FindFirstChild("Tickets")

							if tickets then
								if speaker.Character then
									if speaker.Character:GetAttribute("Downed") then
										self.Services.ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
									end

									for _, ticket in ipairs(tickets:GetChildren()) do
										local ticketPart = ticket:FindFirstChild("HumanoidRootPart")
										if ticketPart then
											self.Modules.core:TeleportToLocation(ticketPart.CFrame)
											task.wait(ticketWaitInterval)
										end
									end
								end
							end
							task.wait()
						end

					end
				end,
			})

			self:AddCommand({
				Name = "StopEventGrind",
				Description = "Stops you from grinding tickets",

				Aliases = {"StopEGrind", "StopTicketGrind"},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					universalValues.evade_ticket_farming = false
				end,
			})

			self:AddCommand({
				Name = "GrabAllTickets",
				Description = "Collects all of the tickets in the map",

				Aliases = {"CollectAllTickets"},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --
					local tickets = workspace:FindFirstChild("Game")
						and workspace.Game:FindFirstChild("Effects")
						and workspace.Game.Effects:FindFirstChild("Tickets")

					-- 関数 --
					if tickets then
						while #tickets:GetChildren() >= 1 do
							local hrp = self.fetchHrp(speaker.Character)

							if speaker.Character then
								if speaker.Character:GetAttribute("Downed") then
									self.Services.ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
								end

								for _, ticket in ipairs(tickets:GetChildren()) do
									local ticketPart = ticket:FindFirstChild("HumanoidRootPart")
									if ticketPart then
										self.Modules.core:TeleportToLocation(ticketPart.CFrame)
										task.wait(ticketWaitInterval)
									end
								end
							end
							task.wait()
						end
					end
				end,
			})

			self:AddCommand({
				Name = "FastRevive",
				Description = "Makes it so you can revive people faster",

				Aliases = {"FRevive", "SpeedRevive"},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --


					-- 関数 --
					workspace.Game.Settings:SetAttribute("ReviveTime", 2.2)
				end,
			})

			self:AddCommand({
				Name = "RemoveBarriers",
				Description = "Removes the invisible walls around the map",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					workspace.Game.Map.InvisParts:ClearAllChildren()
				end,
			})

			self:AddCommand({
				Name = "TeleportToObjectives",
				Description = "Disables water damaging",

				Aliases = {"ToObjectives"},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --
					local hrp = self.fetchHrp(speaker.Character)

					-- 関数 --
					if workspace.Game.Map.Parts:FindFirstChild("Objectives") then
						for i, v in next, workspace.Game.Map.Parts.Objectives:GetChildren() do
							if v.IsA(v, "Model") then
								self.Modules.core:TeleportToLocation(CFrame.new(v:FindFirstChildWhichIsA("BasePart").Position))
							end
						end
					end
				end,
			})

			self:AddCommand({
				Name = "AutofarmWins",
				Description = "Makes you win the game everytime",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					universalValues.break_bots = true
					while universalValues.break_bots do
						local n = math.random(1, 10000000)
						local z = math.random(200, 8000)
						local x = math.random(1, 10000000)
						if not universalValues.break_bots then
							break
						end
						if game:GetService("Workspace").Game:WaitForChild('Map'):WaitForChild('Parts'):FindFirstChild("KillBricks") then
							game:GetService("Workspace").Game:WaitForChild('Map').KillBricks:Destroy()
						end
						task.wait()
						game.Workspace.Game.Players:WaitForChild(game.Players.LocalPlayer.Name):WaitForChild("HumanoidRootPart").CFrame = CFrame.new(0, z, 0)
					end
				end,
			})

			self:AddCommand({
				Name = "StopAutofarmWins",
				Description = "Disables auto winning",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					if universalValues.break_bots then
						universalValues.break_bots = false
						self.Services.ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
					end
				end,
			})
		end)
		loadSupportedGame(662417684, "Lucky Block Battle Grounds", function()
			self:AddCommand({
				Name = "GiveLuckyBlock",
				Description = "Gives you [Amount] of lucky blocks",

				Aliases = {},
				Arguments = {"Amount"},

				Function = function(speaker, args)
					-- 引数 --
					local amount = self.getNum(args[1])

					-- 変数 --
					local blockName = "LuckyBlock"

					-- 関数 --
					if not amount then
						amount = 1
					end

					for i = 1, tonumber(amount) do
						self.Services.ReplicatedStorage[`Spawn{blockName}`]:FireServer()
					end
				end,
			})

			self:AddCommand({
				Name = "GiveSuperLuckyBlock",
				Description = "Gives you [Amount] of super lucky blocks",

				Aliases = {},
				Arguments = {"Amount"},

				Function = function(speaker, args)
					-- 引数 --
					local amount = self.getNum(args[1])

					-- 変数 --
					local blockName = "SuperBlock"

					-- 関数 --
					if not amount then
						amount = 1
					end

					for i = 1, tonumber(amount) do
						self.Services.ReplicatedStorage[`Spawn{blockName}`]:FireServer()
					end
				end,
			})

			self:AddCommand({
				Name = "GiveDiamondLuckyBlock",
				Description = "Gives you [Amount] of diamond lucky blocks",

				Aliases = {},
				Arguments = {"Amount"},

				Function = function(speaker, args)
					-- 引数 --
					local amount = self.getNum(args[1])

					-- 変数 --
					local blockName = "DiamondBlock"

					-- 関数 --
					if not amount then
						amount = 1
					end

					for i = 1, tonumber(amount) do
						self.Services.ReplicatedStorage[`Spawn{blockName}`]:FireServer()
					end
				end,
			})

			self:AddCommand({
				Name = "GiveRainbowLuckyBlock",
				Description = "Gives you [Amount] of rainbow lucky blocks",

				Aliases = {},
				Arguments = {"Amount"},

				Function = function(speaker, args)
					-- 引数 --
					local amount = self.getNum(args[1])

					-- 変数 --
					local blockName = "RainbowBlock"

					-- 関数 --
					if not amount then
						amount = 1
					end

					for i = 1, tonumber(amount) do
						self.Services.ReplicatedStorage[`Spawn{blockName}`]:FireServer()
					end
				end,
			})

			self:AddCommand({
				Name = "GiveGalaxyLuckyBlock",
				Description = "Gives you [Amount] of galaxy lucky blocks",

				Aliases = {},
				Arguments = {"Amount"},

				Function = function(speaker, args)
					-- 引数 --
					local amount = self.getNum(args[1])

					-- 変数 --
					local blockName = "GalaxyBlock"

					-- 関数 --
					if not amount then
						amount = 1
					end

					for i = 1, tonumber(amount) do
						self.Services.ReplicatedStorage[`Spawn{blockName}`]:FireServer()
					end
				end,
			})
		end)
		loadSupportedGame(95963293166138, "Namgyu Land for Namgyu Ethusiasts", function()
			self:AddCommand({
				Name = "CollectAllCoins",
				Description = "Makes you collect all coins in the map",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --


					-- 関数 --
					for i, v in ipairs(workspace:GetChildren()) do
						if v:IsA("BasePart") and v:FindFirstChildWhichIsA("Script") then
							if v.Color == Color3.fromRGB(253,234,141) then
								self.Modules.core:TeleportToLocation(v.CFrame)
								task.wait(.25)
							end
						end
					end
				end,
			})
		end)
		loadSupportedGame(185655149, "Welcome To Bloxburg", function()
			self:AddCommand({
				Name = "Autogrind",
				Description = "Makes you autogrind in the Pizza Place",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --
					local useTeleport = self.getBool(args[1])

					-- 変数 --
					local _game = workspace:WaitForChild("_game")
					local environment = workspace:WaitForChild("Environment")

					local locations = environment:WaitForChild("Locations")
					local spawnedCharacters = _game:WaitForChild("SpawnedCharacters")

					local customerName = "PizzaPlanetDeliveryCustomer"

					-- 関数 --
					local locPart = nil
					if workspace:FindFirstChild("LOC_PART") then
						locPart = workspace:FindFirstChild("LOC_PART")
					else
						locPart = Instance.new("Part", workspace)
						locPart.Name = "LOC_PART"
						locPart.CanCollide = false
						locPart.Anchored = true
						locPart.Transparency = 1
						locPart.CFrame = CFrame.new(1165, 15.1437988, 270.823181, 1, 0, 0, 0, 1, 0, 0, 0, 1)
					end

					local function moveTo(part)
						if useTeleport then
							self.Modules.core:Pathfind(part, nil, false, {
								OnRan = function(model, nextWaypoint)
									task.wait()
									model.PrimaryPart.CFrame = CFrame.new(
										nextWaypoint.Position.X,
										nextWaypoint.Position.Y - 10,
										nextWaypoint.Position.Z
									)
									self.Modules.parser:RunCommand(speaker, "breakvelocity")
								end,
							}, nil, true)
						else
							self.Modules.core:Pathfind(part)
						end
					end

					self.Modules.parser:RunCommand(speaker, "noclip")

					local npc = spawnedCharacters:FindFirstChild(customerName)
					if npc then
						moveTo(npc.PrimaryPart)
						repeat task.wait() until not npc
						moveTo(locPart)
					end
				end,
			})
		end)
		loadSupportedGame(15523276627, "CraftBlox", function()
			local oreEsp = false
			local oreHighlights = {}

			self:AddCommand({
				Name = "OreESP",
				Description = "Lets you see all of the ores around you [RefreshRate]",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --
					local refreshRate = self.getNum(args[1])

					-- 変数 --
					local blocks = workspace:WaitForChild("Blocks")

					-- 関数 --
					if not refreshRate then
						refreshRate = 5
					end

					self.Modules.parser:RunCommand(speaker, "UnOreESP")

					oreEsp = true

					local function updateHighlights()
						for _, folder in ipairs(blocks:GetDescendants()) do
							if folder.ClassName == "Folder" then
								for _, block in ipairs(folder:GetChildren()) do
									if block.ClassName == "MeshPart" and block.BrickColor ~= BrickColor.new("Medium stone grey") then
										local highlight = block:FindFirstChild("ORE_HIGHLIGHT")
										if not highlight then
											highlight = Instance.new("Highlight", block)
											highlight.FillColor = block.BrickColor.Color
											highlight.OutlineColor = Color3.new(0, 0, 0)
											highlight.OutlineTransparency = 0.7
											highlight.Name = "ORE_HIGHLIGHT"
											table.insert(oreHighlights, highlight)
										end
									end
								end
							end
						end
					end

					while oreEsp do
						updateHighlights()
						task.wait(refreshRate)
					end
				end,
			})

			self:AddCommand({
				Name = "UnOreESP",
				Description = "Stops Ore ESP",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					if oreEsp then
						oreEsp = false
						for _, highlight in ipairs(oreHighlights) do
							highlight:Destroy()
						end
					end
				end,
			})
		end)

		--------------------------------------------------------------------
		--[[							END								]]--
		--------------------------------------------------------------------

		self:AddCommand({
			Name = "View",
			Description = "Views the [Player]",

			Aliases = {"Spectate", "Watch"},
			Arguments = {"Player"},

			Function = function(speaker, args)
				-- 引数 --
				local user = args[1]

				-- 変数 --
				local users = self.getPlayer(speaker, user)

				-- 関数 --
				for index, player in next, users do
					if player.Character then
						self.removeConn("VIEW_DIED")
						self.removeConn("VIEW_CHANGED")
						self.removeConn("VIEW_PLAYER_REMOVED")

						self.Camera.CameraSubject = player.Character
						self.addConn("VIEW_DIED", player.CharacterAdded:Connect(function()
							repeat task.wait() until player.Character ~= nil and self.fetchHrp(player.Character)
							self.Camera.CameraSubject = player.Character
						end))
						self.addConn("VIEW_CHANGED", self.Camera:GetPropertyChangedSignal("CameraSubject"):Connect(function()
							self.Camera.CameraSubject = player.Character
						end))
						self.addConn("VIEW_PLAYER_REMOVED", self.Services.Players.PlayerRemoving:Connect(function(leftplayer)
							if leftplayer.Name == player.Name then
								self.Camera.CameraSubject = speaker.Character
							end
						end))
						self:Notify(self.Config.SYSTEM.NAME, `Viewing <b>{player.Name}</b> (@{player.DisplayName})`, "INFO", nil, 5)
					end
				end
			end,
		})

		self:AddCommand({
			Name = "Unview",
			Description = "Unviews if you're viewing someone",

			Aliases = {"Unspectate", "Unwatch"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.removeConn("VIEW_DIED")
				self.removeConn("VIEW_CHANGED")
				self.removeConn("VIEW_PLAYER_REMOVED")

				self.Camera.CameraSubject = speaker.Character
			end,
		})

		self:AddCommand({
			Name = "To",
			Description = "Teleports your character to [Player]",

			Aliases = {"Goto"},
			Arguments = {"Player"},

			Function = function(speaker, args)
				-- 引数 --
				local user = args[1]

				-- 変数 --
				local users = self.getPlayer(speaker, user)

				-- 関数 --
				for index, player in next, users do
					if player.Character then
						local hrp = self.fetchHrp(player.Character)
						if hrp then
							self.Modules.core:TeleportToLocation(hrp.CFrame + Vector3.new(3,1,0))
							self:Notify(self.Config.SYSTEM.NAME, `Teleported to <b>{player.Name}</b> (@{player.DisplayName})`, "INFO", nil, 5)
						end
					end
				end
				self.Modules.parser:RunCommand(speaker, "breakvelocity")
			end,
		})

		self:AddCommand({
			Name = "BreakVelocity",
			Description = "Makes your character have no velocity",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				local stopped, vector = false, Vector3.new(0, 0, 0)
				delay(1, function()
					stopped = true
				end)
				while not stopped do
					for _, v in ipairs(speaker.Character:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Velocity, v.RotVelocity = vector, vector
						end
					end
					task.wait()
				end
			end,
		})

		self:AddCommand({
			Name = "JumpPower",
			Description = "Makes your jumppower set to [Power]",

			Aliases = {},
			Arguments = {"Power"},

			Function = function(speaker, args)
				-- 引数 --
				local power = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				self.Modules.core:SetJumppower(power)
			end,
		})

		self:AddCommand({
			Name = "Walkspeed",
			Description = "Makes your walkspeed set to [Speed]",

			Aliases = {"Speed"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				self.Modules.core:SetWalkspeed(speed, false)
			end,
		})

		self:AddCommand({
			Name = "CFrameSpeed",
			Description = "Makes you move upon CFrame at a speed of [Speed]",

			Aliases = {"Speed"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				self.Modules.core:SetWalkspeed(speed, true)
			end,
		})

		self:AddCommand({
			Name = "UncframeSpeed",
			Description = "Disables CFrame speed",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Modules.core:UncframeSpeed()
			end,
		})

		self:AddCommand({
			Name = "Gravity",
			Description = "Sets the gravity to [Gravity] (CLIENT)",

			Aliases = {"Grav", "GGrav"},
			Arguments = {"Gravity"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				workspace.Gravity = speed
			end,
		})

		self:AddCommand({
			Name = "Reset",
			Description = "Resets your character",

			Aliases = {"Re", "Respawn"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if game.PlaceId == 9872472334--[[Evade]] then
					self.Services.ReplicatedStorage.Events.Player.ChangePlayerMode:FireServer(true)
				else
					local hum = self.fetchHum(speaker.Character)
					if hum then
						hum:ChangeState(Enum.HumanoidStateType.Dead)
					end
				end
			end,
		})

		self:AddCommand({
			Name = "Refresh",
			Description = "Refreshes your character",

			Aliases = {"Ref"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Modules.core:RefreshPlayer()
			end,
		})

		self:AddCommand({
			Name = "WalkOnWalls",
			Description = "Makes you able to walk on walls",

			Aliases = {"Wallwalk"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				loadstring(game:HttpGet("https://raw.githubusercontent.com/Gimkit0/Gim-Test/refs/heads/main/main/deps/walkwalk.lua"))()
			end,
		})

		self:AddCommand({
			Name = "God",
			Description = "Unkillable in most games",

			Aliases = {"GodMode", "AntiKill"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if game.PlaceId == 9872472334--[[Evade]] then
					self.spawn(function()
						for i, v in next, workspace.Game.Players:GetDescendants() do
							if v.IsA(v, "BindableEvent") and string.lower(v.Name) == "force" then
								v:Destroy()
							end
						end
						workspace.Game.Players.DescendantAdded:Connect(function(v)
							task.wait()
							if v.IsA(v, "BindableEvent") and string.lower(v.Name) == "force" then
								v:Destroy()
							end
						end)
					end)
				else
					loadstring(game:HttpGet("https://pastebin.com/raw/NdaKWSRG"))()
				end
			end,
		})

		self:AddCommand({
			Name = "PromptR15",
			Description = "Prompts you to change your avatar rig to R15",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Modules.core:PromptRig("R15")
			end,
		})

		self:AddCommand({
			Name = "PromptR6",
			Description = "Prompts you to change your avatar rig to R6",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Modules.core:PromptRig("R6")
			end,
		})

		self:AddCommand({
			Name = "Fly",
			Description = "Makes your character fly with the speed of [Speed]",

			Aliases = {"Bird", "Flight"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				self.Modules.core:Fly(false, speed)
			end,
		})

		self:AddCommand({
			Name = "VFly",
			Description = "Makes your character fly even with vehicles with the speed of [Speed]",

			Aliases = {"VehicleFly"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				self.Modules.core:Fly(true, speed)
			end,
		})

		self:AddCommand({
			Name = "Unfly",
			Description = "Unflies your character",

			Aliases = {"Unvfly", "Unvehiclefly", "Unbird", "Unflight"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Modules.core:Unfly()
			end,
		})

		self:AddCommand({
			Name = "FlySpeed",
			Description = "Sets the fly speed to [Speed]",

			Aliases = {"FSpeed"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				self.Modules.core:SetFlySpeed(false, speed)
			end,
		})

		self:AddCommand({
			Name = "VehicleFlySpeed",
			Description = "Sets the vehicle fly speed to [Speed]",

			Aliases = {"VFlySpeed"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				self.Modules.core:SetFlySpeed(true, speed)
			end,
		})

		self:AddCommand({
			Name = "Rejoin",
			Description = "Makes you rejoin the server",

			Aliases = {"RJ", "RJoin"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if #self.Services.Players:GetPlayers() <= 1 then
					speaker:Kick("REJOINING\n")
					wait()
					self.Services.TeleportService:Teleport(game.PlaceId, speaker)
				else
					self.Services.TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, speaker)
				end
			end,
		})

		self:AddCommand({
			Name = "ServerHop",
			Description = "Makes you join a different server",

			Aliases = {"SerHop"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if httprequest then
					local servers = {}
					local req = httprequest({Url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Desc&limit=100&excludeFullGames=true", game.PlaceId)})
					local body = self.Services.HttpService:JSONDecode(req.Body)

					if body and body.data then
						for i, v in next, body.data do
							if type(v) == "table" and tonumber(v.playing)
								and tonumber(v.maxPlayers)
								and v.playing < v.maxPlayers
								and v.id ~= game.JobId
							then
								table.insert(servers, 1, v.id)
							end
						end
					end

					if #servers > 0 then
						self.Modules.core:TeleportToServer(game.PlaceId, servers[math.random(1, #servers)])
					end
				end
			end,
		})

		self:AddCommand({
			Name = "JoinPlayer",
			Description = "Makes you join the [User] in [PlaceId]",

			Aliases = {"JoinP"},
			Arguments = {"User", "PlaceId"},

			Function = function(speaker, args)
				-- 引数 --
				local user = args[1]
				local placeId = args[2]

				-- 変数 --
				local retries = 0

				-- 関数 --
				self.Modules.core:TeleportToPlayerByPlace(user, placeId)
			end,
		})

		self:AddCommand({
			Name = "Exit",
			Description = "Exits the game",

			Aliases = {"ExitGame"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				game:Shutdown()
			end,
		})

		self:AddCommand({
			Name = "Noclip",
			Description = "Makes it so you can clip through walls",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.startLoop("NOCLIPPING", 0, function()
					for _, child in pairs(speaker.Character:GetDescendants()) do
						if child:IsA("BasePart") and child.CanCollide == true and child.Name ~= self.floatName then
							child.CanCollide = false
						end
					end
				end)
			end,
		})

		self:AddCommand({
			Name = "Clip",
			Description = "Disables noclip",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.stopLoop("NOCLIPPING")
			end,
		})

		self:AddCommand({
			Name = "WalkFling",
			Description = "When you touch someone with collision on, then it flings them",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --
				local hum = self.fetchHum(speaker.Character)

				-- 関数 --
				self.Modules.parser:RunCommand(speaker, "unwalkfling")
				if hum then
					hum.Died:Connect(function()
						self.Modules.parser:RunCommand(speaker, "unwalkfling")
					end)
				end

				self.Modules.parser:RunCommand(speaker, "noclip")
				task.wait()

				universalValues.walkflinging = true

				repeat self.Services.RunService.Heartbeat:Wait()
					local char = speaker.Character
					local root = self.fetchHrp(char)
					local vel, movel = nil, 0.1

					while not (char and char.Parent and root and root.Parent) do
						self.Services.RunService.Heartbeat:Wait()
						char = speaker.Character
						root = self.fetchHrp(char)
					end

					vel = root.Velocity
					root.Velocity = vel * 10000 + Vector3.new(0, 10000, 0)

					self.Services.RunService.RenderStepped:Wait()
					if char and char.Parent and root and root.Parent then
						root.Velocity = vel
					end

					self.Services.RunService.Stepped:Wait()
					if char and char.Parent and root and root.Parent then
						root.Velocity = vel + Vector3.new(0, movel, 0)
						movel = movel * -1
					end
				until universalValues.walkflinging == false
			end,
		})

		self:AddCommand({
			Name = "UnwalkFling",
			Description = "Disables walkflinging",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				universalValues.walkflinging = false
			end,
		})

		self:AddCommand({
			Name = "ChangeTheme",
			Description = "Changes the theme to [Theme]",

			Aliases = {"CTheme", "Theme"},
			Arguments = {"Theme"},

			Function = function(speaker, args)
				-- 引数 --
				local theme = args[1]

				-- 変数 --

				-- 関数 --
				self.changeTheme(theme)
			end,
		})

		self:AddCommand({
			Name = "Aimlock",
			Description = "Have god tier aim. [Epitaph] is prediction of where the bullet will land",

			Aliases = {"GodAim"},
			Arguments = {"Epitaph", "HeadOffset", "TeamCheck", "Npcs", "HoldToCheck"},

			Function = function(speaker, args)
				-- 引数 --
				local epipath = self.getNum(args[1])
				local offsetY = self.getNum(args[2])
				local teamCheck = self.getBool(args[3])
				local npcs = self.getBool(args[4])
				local holdToCheck = self.getBool(args[5])

				-- 変数 --
				if not offsetY then
					offsetY = 25
				end

				local headOffset = Vector3.new(0, offsetY/20, 0)

				local circleEnabled = false
				local circleSides = 64
				local circleRadius = 200
				local circleThickness = 1
				local circleTransparency = .5
				local circleFilled = false
				local circleVisible = true


				-- 関数 --
				self.Modules.parser:RunCommand(speaker, "Unaimlock")
				task.wait()
				if not epipath then
					epipath = .15
				end

				if circleEnabled then
					instances.fov_circle = Drawing.new("Circle")

					local circle = instances.fov_circle
					circle.Position = Vector2.new(self.Camera.ViewportSize.X / 2, self.Camera.ViewportSize.Y / 2)
					circle.Radius = circleRadius
					circle.Filled = circleFilled
					circle.Color = self.Theme.THEME_COLOR
					circle.Visible = circleVisible
					circle.Transparency = circleTransparency
					circle.NumSides = circleSides
					circle.Thickness = circleThickness
				end

				local function isTargetVisible(targetCharacter)
					local origin = self.Camera.CFrame.Position
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Exclude
					rayParams.FilterDescendantsInstances = {speaker.Character}

					for _, part in ipairs(targetCharacter:GetChildren()) do
						if part:IsA("BasePart") or part:IsA("MeshPart") then
							local direction = (part.Position - origin).Unit * (part.Position - origin).Magnitude
							local result = workspace:Raycast(origin, direction, rayParams)

							if result then
								local hitPart = result.Instance

								if hitPart and hitPart.Transparency > 0.05 then
									return true
								end
							else
								return true
							end
						end
					end
					return false
				end

				local function getAllNPCs()
					local npcsList = {}

					for _, obj in pairs(workspace:GetDescendants()) do
						if obj:IsA("Model") and obj:FindFirstChildWhichIsA("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
							table.insert(npcsList, obj)
						end
					end

					return npcsList
				end

				local function findNearest()
					local bestScore = math.huge
					local dist = math.huge
					local Target = nil

					for _, v in pairs(self.Services.Players:GetPlayers()) do
						if v.Character then
							local hum = self.fetchHum(v.Character)
							if v ~= speaker and v.Character and hum and hum.Health > 0 then
								if teamCheck and v.Team == speaker.Team then
									continue
								end

								local char = v.Character
								local root = char and char:FindFirstChild("Head") or self.fetchHrp(char)

								if root then
									local screenPos, visible = self.Camera:WorldToViewportPoint(root.Position)
									local playerDistance = (root.Position - speaker.Character.PrimaryPart.Position).Magnitude
									local screenDistance = (Vector2.new(self.Mouse.X, self.Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
									local visibilityPenalty = isTargetVisible(char) and 0 or 1000

									if visible then
										if (screenDistance < dist and screenDistance < circleRadius) then
											local score = (playerDistance * 0.6) + (screenDistance * 0.4) + visibilityPenalty

											if score < bestScore then
												dist = screenDistance
												bestScore = score
												Target = char
											end
										end
									end
								end
							end
						end
					end
					if npcs then
						for _, npc in pairs(getAllNPCs()) do
							local hum = self.fetchHum(npc)
							local root = self.fetchHrp(npc)

							if hum and root and hum.Health > 0 then
								local screenPos, visible = self.Camera:WorldToViewportPoint(root.Position)
								local npcDistance = (root.Position - speaker.Character.PrimaryPart.Position).Magnitude
								local screenDistance = (Vector2.new(self.Mouse.X, self.Mouse.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
								local visibilityPenalty = isTargetVisible(npc) and 0 or 1000

								if visible and screenDistance < circleRadius then
									local score = (npcDistance * 0.6) + (screenDistance * 0.4) + visibilityPenalty

									if score < bestScore then
										dist = screenDistance
										bestScore = score
										Target = npc
									end
								end
							end
						end
					end

					return Target
				end

				self.addConn("AIMLOCK_INPUT_BEGAN", self.Services.UserInputService.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						universalValues.aimlock_holding_mouse = true

						local target = findNearest()
						while universalValues.aimlock_holding_mouse do
							if universalValues.aimlock_holding_mouse then
								if holdToCheck then
									target = findNearest()
								end
								if target ~= nil then
									local hrp = target and target:FindFirstChild("Head") or self.fetchHrp(target)
									local hum = self.fetchHum(target)

									if (hum and hum.Health > 0) and (hrp) then
										local future = hrp.CFrame + (hrp.Velocity * epipath + (hrp.Name == "HumanoidRootPart" and headOffset or Vector3.new(0, 0, 0)))
										self.Camera.CFrame = CFrame.lookAt(self.Camera.CFrame.Position, future.Position)
										self.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
									else
										break
									end
								end
							end
							task.wait()
						end
					end
				end))
				self.addConn("AIMLOCK_INPUT_ENDED", self.Services.UserInputService.InputEnded:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton2 then
						universalValues.aimlock_holding_mouse = false
						self.Services.UserInputService.MouseBehavior = Enum.MouseBehavior.Default
					end
				end))
				self.addConn("AIMLOCK_CIRCLE_MOVE", self.Services.RunService.RenderStepped:Connect(function()
					if instances.fov_circle then
						instances.fov_circle.Position = Vector2.new(self.Mouse.X, self.Mouse.Y*1.5)
					end
				end))

				self:Notify(self.Config.SYSTEM.NAME, `To enable aimlock, press your <b>right mouse button</b>!`, "INFO", nil, 10)
			end,
		})

		self:AddCommand({
			Name = "Unaimlock",
			Description = "Stops the aimlock",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.removeConn("AIMLOCK_INPUT_BEGAN")
				self.removeConn("AIMLOCK_INPUT_ENDED")
				self.removeConn("AIMLOCK_CIRCLE_MOVE")

				universalValues.aimlock_holding_mouse = false

				if instances.fov_circle then
					instances.fov_circle:Destroy()
				end
			end,
		})

		self:AddCommand({
			Name = "AntiAfk",
			Description = "Disables the 20 minute afk kick message",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if getconnections then
					for i,v in pairs(getconnections(speaker.Idled)) do
						if v["Disable"] then
							v["Disable"](v)
						elseif v["Disconnect"] then
							v["Disconnect"](v)
						end
					end
				else
					speaker.Idled:Connect(function()
						local VirtualUser = game:GetService("VirtualUser")
						VirtualUser:CaptureController()
						VirtualUser:ClickButton2(Vector2.new())
					end)
				end
			end,
		})

		self:AddCommand({
			Name = "Dex",
			Description = "Loads Dex's explorer",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self:Notify(self.Config.SYSTEM.NAME, `Loading dex, hold on a sec!`, "INFO", nil, 5)
				loadstring(game:HttpGet("https://raw.githubusercontent.com/Gimkit0/Gim-Test/refs/heads/main/main/deps/newdex.lua"))()
			end,
		})
		
		self:AddCommand({
			Name = "FixChat",
			Description = "Fixes the chat",

			Aliases = {"ChatHistory"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if self.Services.TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
					local winConfig = self.Services.TextChatService:WaitForChild("ChatWindowConfiguration")
					winConfig.WidthScale = 1
					winConfig.HeightScale = 1
					winConfig.Enabled = true
				end
			end,
		})

		self:AddCommand({
			Name = "Blackhole",
			Description = "Unanchored parts will start to fly around you",

			Aliases = {"Singularity", "Tornado"},
			Arguments = {"Radius", "Height", "RotationSpeed", "Strength"},

			Function = function(speaker, args)
				-- 引数 --
				local radius = self.getNum(args[1])
				local height = self.getNum(args[2])
				local rotSpeed = self.getNum(args[3])
				local strength = self.getNum(args[4])

				-- 変数 --

				-- 関数 --
				local network = {
					parts = {},
					velocity = Vector3.new(14.46262424, 14.46262424, 14.46262424),
				}

				self.Modules.parser:RunCommand(speaker, "Unblackhole")
				self.Modules.parser:RunCommand(speaker, "Noclip")
				task.wait(.5)

				if not radius then
					radius = 50
				end
				if not height then
					height = 100
				end
				if not rotSpeed then
					rotSpeed = 10
				end
				if not strength then
					strength = 1000
				end

				speaker.ReplicationFocus = workspace

				local function retainPart(inst)
					if inst:IsA("BasePart") and inst:IsDescendantOf(workspace) then
						if inst.Parent == speaker.Character or inst:IsDescendantOf(speaker.Character) then
							return false
						end
						if inst.Anchored then
							return false
						end

						inst.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0, 0, 0)
						return true
					end
					return false
				end

				local parts = {}
				local function addPart(inst)
					if retainPart(inst) then
						if not table.find(parts, inst) then
							table.insert(parts, inst)
						end
					end
				end

				local function removePart(inst)
					local index = table.find(parts, inst)
					if index then
						table.remove(parts, index)
					end
				end

				self.addConn("PART_CONTROL", self.Services.RunService.Heartbeat:Connect(function()
					if sethidden then
						sethidden(speaker, "SimulationRadius", math.huge)
					end

					for _, inst in pairs(network.parts) do
						if inst:IsDescendantOf(workspace) then
							inst.Velocity = network.velocity
						end
					end
				end))

				for _, part in pairs(workspace:GetDescendants()) do
					addPart(part)
				end

				self.addConn("BLACKHOLE_DESCENDANT_ADDED", workspace.DescendantAdded:Connect(addPart))
				self.addConn("BLACKHOLE_DESCENDANT_REMOVED", workspace.DescendantRemoving:Connect(removePart))

				self.addConn("SINGULARITY", self.Services.RunService.Heartbeat:Connect(function()
					local hrp = self.fetchHrp(speaker.Character)
					if hrp then
						local tornadoCenter = hrp.Position
						for _, part in pairs(parts) do
							if part.Parent and not part.Anchored then
								local pos = part.Position
								local distance = (Vector3.new(pos.X, tornadoCenter.Y, pos.Z) - tornadoCenter).Magnitude
								local angle = math.atan2(pos.Z - tornadoCenter.Z, pos.X - tornadoCenter.X)
								local newAngle = angle + math.rad(rotSpeed)
								local targetPos = Vector3.new(
									tornadoCenter.X + math.cos(newAngle) * math.min(radius, distance),
									tornadoCenter.Y + (height * (math.abs(math.sin((pos.Y - tornadoCenter.Y) / height)))),
									tornadoCenter.Z + math.sin(newAngle) * math.min(radius, distance)
								)
								local directionToTarget = (targetPos - part.Position).unit
								part.Velocity = directionToTarget * strength
							end
						end
					end
				end))
			end,
		})

		self:AddCommand({
			Name = "Unblackhole",
			Description = "Stops attracting parts to you",

			Aliases = {"StopBlackhole", "StopSingularity", "StopTornado", "Untornado", "Unsingularity"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.removeConn("PART_CONTROL")
				self.removeConn("SINGULARITY")
				self.removeConn("BLACKHOLE_DESCENDANT_ADDED")
				self.removeConn("BLACKHOLE_DESCENDANT_REMOVED")
			end,
		})

		self:AddCommand({
			Name = "FixCamera",
			Description = "Fixes your camera just in case it's broken",

			Aliases = {"FixCam"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --
				local hum = self.fetchHum(speaker.Character)

				-- 関数 --
				self.Modules.parser:RunCommand(speaker, "unview")

				task.wait(.1)
				repeat task.wait() until speaker.Character ~= nil

				self.Camera.CameraSubject = hum
				self.Camera.CameraType = "Custom"
				speaker.CameraMinZoomDistance = 0.5
				speaker.CameraMaxZoomDistance = 400
				speaker.CameraMode = "Classic"

				if speaker.Character then
					local head = speaker.Character:FindFirstChild("Head")
					if head then
						head.Anchored = false
					end
				end
			end,
		})

		self:AddCommand({
			Name = "EnableShiftLock",
			Description = "If shift-lock is disabled, then it'll re-enable it",

			Aliases = {"EnableSL", "Shiftlock"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --


				-- 関数 --
				speaker.DevEnableMouseLock = true
			end,
		})

		self:AddCommand({
			Name = "MaxZoom",
			Description = "Sets your cameras Max Zoom Distance to [Number]",

			Aliases = {"MaxZoomDistance"},
			Arguments = {"Number"},

			Function = function(speaker, args)
				-- 引数 --
				local num = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				if not num then
					num = 400
				end
				speaker.CameraMaxZoomDistance = num
			end,
		})

		self:AddCommand({
			Name = "MinZoom",
			Description = "Sets your cameras Min Zoom Distance to [Number]",

			Aliases = {"MinZoomDistance"},
			Arguments = {"Number"},

			Function = function(speaker, args)
				-- 引数 --
				local num = self.getNum(args[1])

				-- 変数 --

				-- 関数 --
				if not num then
					num = 0
				end
				speaker.CameraMaxZoomDistance = num
			end,
		})

		self:AddCommand({
			Name = "F3X",
			Description = "Gives you BTools (Client)",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/refs/heads/main/f3x.lua"))()
			end,
		})

		self:AddCommand({
			Name = "Orbit",
			Description = "Makes your character circle around [Player]",

			Aliases = {},
			Arguments = {"Player", "Speed", "Distance"},

			Function = function(speaker, args)
				-- 引数 --
				local user = args[1]
				local speed = self.getNum(args[2])
				local distance = self.getNum(args[3])

				-- 変数 --
				local users = self.getPlayer(speaker, user)
				local speakerRoot = self.fetchHrp(speaker.Character)
				local hum = self.fetchHum(speaker.Character)
				local rotation = 0

				-- 関数 --
				if not speed then
					speed = 10
				end
				if not distance then
					distance = 6
				end

				speed = speed/20

				for index, player in next, users do
					if player.Character then
						local hrp = self.fetchHrp(player.Character)
						if hrp then
							self.addConn("ORBIT_1", self.Services.RunService.Heartbeat:Connect(function()
								self.spawn(function()
									rotation += speed
									self.Modules.core:TeleportToLocation(hrp.CFrame * CFrame.Angles(0, math.rad(rotation), 0) * CFrame.new(distance, 0, 0))
								end)
							end))
							self.addConn("ORBIT_2", self.Services.RunService.RenderStepped:Connect(function()
								self.spawn(function()
									self.Modules.core:TeleportToLocation(CFrame.new(speakerRoot.Position, hrp.Position))
								end)
							end))
							self.addConn("ORBIT_3", hum.Died:Connect(function()
								self.Modules.parser:RunCommand(speaker, "unorbit")
							end))
							self:Notify(self.Config.SYSTEM.NAME, `Orbiting around <b>{player.Name}</b> (@{player.DisplayName})`, "INFO", nil, 5)
						end
					end
				end
			end,
		})

		self:AddCommand({
			Name = "Unorbit",
			Description = "Stops you from orbiting a player",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.removeConn("ORBIT_1")
				self.removeConn("ORBIT_2")
				self.removeConn("ORBIT_3")
			end,
		})

		self:AddCommand({
			Name = "HipHeight",
			Description = "Sets your hipheight to [Number]",

			Aliases = {"HHeight"},
			Arguments = {"Number"},

			Function = function(speaker, args)
				-- 引数 --
				local num = self.getNum(args[1])

				-- 変数 --
				local hum = self.fetchHum(speaker.Character)

				-- 関数 --
				if hum then
					hum.HipHeight = num or (self.Modules.core:IsRigType(speaker.Character, "R15") and 2.1 or 0)
				end
			end,
		})

		self:AddCommand({
			Name = "Bang",
			Description = "Fucks your [Player] with a speed of [Speed]",

			Aliases = {"Rape", "Hump", "Fuck"},
			Arguments = {"Player", "Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local user = args[1]
				local speed = self.getNum(args[2])

				-- 変数 --
				local users = self.getPlayer(speaker, user)
				local anim = not self.Modules.core:IsRigType(speaker.Character, "R15") and 148840371 or 5918726674
				local speakerHrp = self.fetchHrp(speaker.Character)
				local hum = self.fetchHum(speaker.Character)

				-- 関数 --
				if not speed then
					speed = 3
				end

				self.Modules.parser:RunCommand(speaker, "unbang")

				task.wait()

				universalConnections.bangDied = hum.Died:Connect(function()
					self.Modules.parser:RunCommand(speaker, "unbang")
				end)

				for index, player in next, users do
					if player.Character then
						self.Modules.core:PlayAnimation(anim)
						self.Modules.core:SetAnimationSpeed(speed)

						self.startLoop("BANGING", 0, function()
							self.spawn(function()
								local hrp = self.fetchHrp(player.Character)
								if hrp then
									speakerHrp.CFrame = hrp.CFrame * self.Config.COMMANDS.BANG_OFFSET
								end
							end)
						end)
					end
				end
			end,
		})

		self:AddCommand({
			Name = "Unbang",
			Description = "Stops fucking your target",

			Aliases = {"Unrape", "Unhump", "Unfuck"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if universalConnections.bangDied then
					self.stopLoop("BANGING")
					self.Modules.core:StopAnimation()

					universalConnections.bangDied:Disconnect()
					universalConnections.bangDied = nil
				end
			end,
		})

		self:AddCommand({
			Name = "Swim",
			Description = "Makes you swim in the air with the speed of [Speed]",

			Aliases = {"AirSwim", "FlySwim"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --
				local hum = self.fetchHum(speaker.Character)
				local hrp = self.fetchHrp(speaker.Character)
				local enums = Enum.HumanoidStateType:GetEnumItems()

				-- 関数 --
				if universalConnections.swimming or (not hum) or (not hrp) then
					return
				end
				if not speed then
					speed = 50
				end

				universalStorage.old_gravity = workspace.Gravity
				table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))

				workspace.Gravity = 0

				universalConnections.swimDied = hum.Died:Connect(function()
					workspace.Gravity = universalStorage.old_gravity
				end)

				for i, v in pairs(enums) do
					hum:SetStateEnabled(v, false)
				end
				hum:ChangeState(Enum.HumanoidStateType.Swimming)

				self.Modules.parser:RunCommand(speaker, "cframespeed", speed)

				universalConnections.swimming = self.Services.RunService.Heartbeat:Connect(function()
					self.spawn(function()
						hrp.Velocity = ((hum.MoveDirection ~= Vector3.new()
							or self.Services.UserInputService:IsKeyDown(Enum.KeyCode.Space))
							and hrp.Velocity
							or Vector3.new()
						)
					end)
				end)

			end,
		})

		self:AddCommand({
			Name = "Unswim",
			Description = "Stops your character from swimming in the air",

			Aliases = {"Unairswim", "Unflyswim"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --
				local hum = self.fetchHum(speaker.Character)
				local enums = Enum.HumanoidStateType:GetEnumItems()

				-- 関数 --
				if universalConnections.swimming then
					universalConnections.swimming:Disconnect()
					universalConnections.swimming = nil

					workspace.Gravity = universalStorage.old_gravity

					if universalConnections.swimDied then
						universalConnections.swimDied:Disconnect()
						universalConnections.swimDied = nil
					end

					self.Modules.parser:RunCommand(speaker, "uncframespeed")

					table.remove(enums, table.find(enums, Enum.HumanoidStateType.None))
					for i, v in pairs(enums) do
						hum:SetStateEnabled(v, true)
					end
				end
			end,
		})

		self:AddCommand({
			Name = "Invisible",
			Description = "Makes you invisible",

			Aliases = {"Invis"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --
				local void = workspace.FallenPartsDestroyHeight
				local char = speaker.Character

				local currentlyInvis = false
				local isRunning = false

				-- 関数 --
				if universalValues.isInvisible then return end
				universalValues.isInvisible = true

				char.Archivable = true

				local currentlyInvis = false
				local isRunning = true

				local invisChar = char:Clone()
				invisChar.Parent = game.Lighting
				invisChar.Name = ""

				local function respawn()
					local hum = self.fetchHum(char)

					if hum and hum.Sit then
						hum.Sit = false
						hum.Jump = true
					end

					isRunning = false
					if currentlyInvis then
						self.spawn(function()
							speaker.Character = char
							task.wait()
							char.Parent = workspace
							hum:Destroy()
							currentlyInvis = false
							invisChar.Parent = nil
							universalValues.isInvisible = false
						end)
					else
						self.spawn(function()
							speaker.Character = char
							task.wait()
							char.Parent = workspace
							hum:Destroy()
							universalFuncs.turnVisible()
						end)
					end
				end

				universalConnections.invisFix = self.Services.RunService.Stepped:Connect(function()
					self.spawn(function()
						local hrp = self.fetchHrp(char)
						local charPos = hrp.Position
						if tostring(void):find('-') then
							if charPos.Y <= void then
								respawn()
							end
						else
							if charPos.Y >= void then
								respawn()
							end
						end
					end)
				end)

				for _, inst in pairs(invisChar:GetDescendants()) do
					if inst:IsA("BasePart") then
						inst.Transparency = (inst.Name == "HumanoidRootPart") and 1 or 0.5
					elseif inst:IsA("ForceField") then
						inst:Destroy()
					end
				end

				local hum = self.fetchHum(char)
				universalConnections.invisDied = hum.Died:Connect(function()
					if universalConnections.invisDied then
						respawn()
						universalConnections.invisDied:Disconnect()
						universalConnections.invisDied = nil
					end
				end)

				if currentlyInvis then return end
				currentlyInvis = true

				local charCFrame = char.HumanoidRootPart.CFrame
				char:MoveTo(Vector3.new(0, math.pi * 1000000, 0))

				local camera = self.Camera
				camera.CameraType = Enum.CameraType.Scriptable

				local ghostHrp = self.fetchHrp(invisChar)
				local ghostHum = self.fetchHum(invisChar)

				invisChar.Parent = workspace
				ghostHrp.CFrame = charCFrame
				ghostHum.DisplayName = ""

				self.Camera.CameraSubject = invisChar

				wait(.2)
				camera.CameraType = Enum.CameraType.Custom

				char.Parent = self.Services.Lighting
				speaker.Character = invisChar

				local animateScript = invisChar:FindFirstChild("Animate")
				if animateScript then
					animateScript.Disabled = true
					animateScript.Disabled = false
				end

				universalFuncs.turnVisible = function()
					if not currentlyInvis then
						return
					end

					local mainHrp = self.fetchHrp(char)
					local ghostHrp = self.fetchHrp(invisChar)

					if universalConnections.invisFix then
						universalConnections.invisFix:Disconnect()
						universalConnections.invisFix = nil
					end
					if universalConnections.invisDied then
						universalConnections.invisDied:Disconnect()
						universalConnections.invisDied = nil
					end

					mainHrp.CFrame = ghostHrp.CFrame
					invisChar:Destroy()
					speaker.Character = char
					char.Parent = workspace
					currentlyInvis = false

					local animateScript = char:FindFirstChild("Animate")
					if animateScript then
						animateScript.Disabled = true
						animateScript.Disabled = false
					end

					self.Camera.CameraSubject = char

					universalValues.isInvisible = false
				end
				self:Notify(self.Config.SYSTEM.NAME, `You are invisible to other players`, "INFO", nil, 5)
			end,
		})

		self:AddCommand({
			Name = "Visible",
			Description = "Makes you visible to other players",

			Aliases = {"Vis"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if type(universalFuncs.turnVisible) == "function" then
					universalFuncs.turnVisible()
					universalFuncs.turnVisible = nil
				end
			end,
		})

		self:AddCommand({
			Name = "HamsterBall",
			Description = "Rolls your character like a hamster ball",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				loadstring(game:HttpGet("https://raw.githubusercontent.com/Gimkit0/Gim-Test/refs/heads/main/main/deps/hamsterball.lua"))()
			end,
		})

		self:AddCommand({
			Name = "JerkOff",
			Description = "Makes you masterbathe with a speed of [Speed]",

			Aliases = {"Masterbathe"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = args[1]

				-- 変数 --
				local r6Anims = {
					JERK_OFF = 99198989,
					CLOSER_HANDS = 168086975,
				}

				-- 関数 --
				if not speed then
					speed = 2
				end

				if self.Modules.core:IsRigType(speaker.Character, "R6") then
					self.Modules.core:StopAnimation()

					self.Modules.core:PlayAnimation(r6Anims.JERK_OFF, {
						Looped = true,
					}, true)
					self.Modules.core:PlayAnimation(r6Anims.CLOSER_HANDS, {
						Looped = true,
					}, true)
					self.Modules.core:SetAnimationSpeed(speed)
				else
					loadstring(game:HttpGet("https://pastefy.app/YZoglOyJ/raw"))()
					self:Notify(self.Config.SYSTEM.NAME, `For now, R15 version uses a tool.`, "INFO", nil, 5)
				end
			end,
		})

		self:AddCommand({
			Name = "Undance",
			Description = "Stops you from dancing/jerking off",

			Aliases = {"Unmasterbathe", "UnjerkOff"},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --
				local tool = speaker.Backpack:FindFirstChild("Jerk Off R15")

				-- 関数 --
				self.Modules.core:StopAnimation()
				if tool then
					tool:Destroy()
				end
			end,
		})

		self:AddCommand({
			Name = "EnableInventory",
			Description = "Enables your inventory",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
			end,
		})

		self:AddCommand({
			Name = "DisableInventory",
			Description = "Disables your inventory",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
			end,
		})

		self:AddCommand({
			Name = "EnableChat",
			Description = "Enables the chat for you",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true)
			end,
		})

		self:AddCommand({
			Name = "DisableChat",
			Description = "Disables the chat for you",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Services.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, false)
			end,
		})

		self:AddCommand({
			Name = "Freecam",
			Description = "Makes you go in freecam mode",

			Aliases = {},
			Arguments = {"DisableCores"},

			Function = function(speaker, args)
				-- 引数 --
				local disableCores = self.getBool(args[1])

				-- 変数 --

				-- 関数 --
				self.Modules.core:Freecam(disableCores)
			end,
		})

		self:AddCommand({
			Name = "StopFreecam",
			Description = "Stops freecam mode",

			Aliases = {"Unfreecam"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Modules.core:StopFreecam()
			end,
		})

		self:AddCommand({
			Name = "ESP",
			Description = "See players/npcs through the walls",

			Aliases = {},
			Arguments = {"Transparency", "Npcs"},

			Function = function(speaker, args)
				-- 引数 --
				local transparency = self.getNum(args[1])
				local npcs = self.getBool(args[2])

				-- 変数 --

				-- 関数 --
				if not transparency then
					transparency = .5
				end

				self.Modules.parser:RunCommand(speaker, "unesp")

				task.wait(.1)

				local function getAllNPCs()
					local npcsList = {}

					for _, obj in pairs(workspace:GetDescendants()) do
						if obj:IsA("Model") and obj:FindFirstChildWhichIsA("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
							table.insert(npcsList, obj)
						end
					end

					return npcsList
				end

				local function addESP(target, isPlayer)
					if (not target) or (target and self.Services.Players:GetPlayerFromCharacter(target) and target.Name == speaker.Name) then
						return
					end
					local oldEsp = target:FindFirstChild(self.espName)
					if oldEsp then
						return
					end
					local highlightColor = Color3.fromRGB(255, 0, 0)
					if isPlayer and self.Services.Players:GetPlayerFromCharacter(target) then
						local player = self.Services.Players:GetPlayerFromCharacter(target)
						if player.Team then
							highlightColor = player.Team.TeamColor.Color
						end
					end

					local hrp = self.fetchHrp(target)

					local highlight = Instance.new("Highlight")
					highlight.FillColor = highlightColor
					highlight.FillTransparency = transparency
					highlight.OutlineColor = highlightColor
					highlight.Parent = target
					highlight.Name = self.espName

					local billboard = Instance.new("BillboardGui")
					billboard.Adornee = hrp
					billboard.Size = UDim2.new(4, 0, 1, 0)
					billboard.StudsOffset = Vector3.new(0, 5, 0)
					billboard.AlwaysOnTop = true
					billboard.Parent = highlight

					local textLabel = Instance.new("TextLabel")
					textLabel.Size = UDim2.new(1, 0, 1, 0)
					textLabel.BackgroundTransparency = 1
					textLabel.TextStrokeTransparency = 0.5
					textLabel.TextTransparency = .3
					textLabel.Text = target.Name
					textLabel.TextColor3 = highlightColor
					textLabel.Font = Enum.Font.GothamBold
					textLabel.TextSize = 14
					textLabel.Parent = billboard

					self.spawn(function()
						local player = self.Services.Players:GetPlayerFromCharacter(target)
						local hum = self.fetchHum(target)

						while billboard and textLabel do
							self.spawn(function()
								player = self.Services.Players:GetPlayerFromCharacter(target)
								if not player then
									hum = self.fetchHum(target)
									hrp = self.fetchHrp(target)
								else
									hum = self.fetchHum(player.Character)
									hrp = self.fetchHrp(player.Character)
								end

								billboard.Adornee = hrp

								local speakerHrp = self.fetchHrp(speaker.Character)
								local distance
								if speakerHrp and hrp then
									distance = math.round(tonumber((hrp.Position - speakerHrp.Position).Magnitude))
								end

								textLabel.Text = `{target.Name} @{player and player.DisplayName or ""}: Health: {hum and math.round(hum.Health).."/"..math.round(hum.MaxHealth) or "N/A"} | Distance: {distance or "N/A"}`
							end)
							task.wait()
						end
					end)

					table.insert(instances.esp_instances, highlight)
				end

				self.addConn("ESP_PLAYER_ADDED", self.safePlayerAdded(function(player)
					local conn = player.CharacterAdded:Connect(function()
						addESP(player.Character, true)
					end)
					if player.Character then
						addESP(player.Character, true)
					end

					table.insert(universalConnections.espCharAdded, conn)
				end))
				self.addConn("ESP_NPC_ADDED", self.safeChildAdded(workspace, function()
					if npcs then
						for _, npc in pairs(getAllNPCs()) do
							if not self.Services.Players:GetPlayerFromCharacter(npc) then
								addESP(npc, false)
							end
						end
					end
				end))
			end,
		})

		self:AddCommand({
			Name = "Unesp",
			Description = "Disables esp",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.removeConn("ESP_PLAYER_ADDED")
				self.removeConn("ESP_NPC_ADDED")

				for _, v in ipairs(instances.esp_instances) do
					if v then
						v:Destroy()
					end
				end
				for _, conn in pairs(universalConnections.espCharAdded) do
					if conn then
						conn:Disconnect()
					end
				end

				table.clear(instances.esp_instances)
			end,
		})

		self:AddCommand({
			Name = "Fullbright",
			Description = "Makes the map look brighter",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				self.Services.Lighting.FogEnd = 100000
				self.Services.Lighting.FogStart = 0
				self.Services.Lighting.ClockTime = 14
				self.Services.Lighting.Brightness = 2
				self.Services.Lighting.GlobalShadows = false
			end,
		})

		self:AddCommand({
			Name = "Spin",
			Description = "Makes you spin with the speed of [Speed]",

			Aliases = {},
			Arguments = {"Speed"},

			Function = function(speaker, args)
				-- 引数 --
				local speed = self.getNum(args[1])

				-- 変数 --
				local hrp = self.fetchHrp(speaker.Character)

				-- 関数 --
				if not speed then
					speed = 20
				end

				if instances.spin_force then
					instances.spin_force:Destroy()
					instances.spin_force = nil
				end

				if hrp then
					local spin = Instance.new("BodyAngularVelocity")
					spin.Name = "Spinning"
					spin.Parent = hrp
					spin.MaxTorque = Vector3.new(0, math.huge, 0)
					spin.AngularVelocity = Vector3.new(0,speed,0)
					instances.spin_force = spin
				end
			end,
		})

		self:AddCommand({
			Name = "Unspin",
			Description = "Stops you from spinning",

			Aliases = {"StopSpin"},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				if instances.spin_force then
					instances.spin_force:Destroy()
					instances.spin_force = nil
				end
			end,
		})

		self:AddCommand({
			Name = "XRay",
			Description = "See through the walls",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				for _, v in pairs(workspace:GetDescendants()) do
					if v:IsA("BasePart")
						and not v.Parent:FindFirstChildWhichIsA("Humanoid")
						and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid")
					then
						v.LocalTransparencyModifier = .5
					end
				end
			end,
		})

		self:AddCommand({
			Name = "UnXRay",
			Description = "Stop seeing through the walls",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --

				-- 関数 --
				for _, v in pairs(workspace:GetDescendants()) do
					if v:IsA("BasePart")
						and not v.Parent:FindFirstChildWhichIsA("Humanoid")
						and not v.Parent.Parent:FindFirstChildWhichIsA("Humanoid")
					then
						v.LocalTransparencyModifier = 0
					end
				end
			end,
		})

		self:AddCommand({
			Name = "Car",
			Description = "Makes you look like your driving a car with the speed of [Speed] and height of [HipHeight]",

			Aliases = {},
			Arguments = {"AccelerationRate", "DecelerationRate", "MaxSpeed", "HipHeight"},

			Function = function(speaker, args)
				-- 引数 --
				local accelRate = self.getNum(args[1])
				local decelRate = self.getNum(args[2])
				local speed = self.getNum(args[3])
				local hipheight = self.getNum(args[4])

				-- 変数 --
				local r6animation = 129342287
				local r15animation = 15570378042

				local hum = self.fetchHum(speaker.Character)

				local isMoving = false

				-- 関数 --
				if not hum then
					return
				end
				if not hipheight then
					hipheight = 1.03
				end
				if not speed then
					speed = 70
				end
				if not accelRate then
					accelRate = 2
				end
				if not decelRate then
					decelRate = 3
				end



				accelRate /= 5
				decelRate /= 2

				if hum then
					local currentSpeed = 16

					hum.WalkSpeed = 0

					self.Modules.parser:RunCommand(speaker, "jumppower", ".00001")

					self.addConn("CAR_ACCELERATION", self.Services.RunService.RenderStepped:Connect(function()
						if hum.MoveDirection.Magnitude > 0 then
							isMoving = true else
							isMoving = false
						end

						if isMoving and currentSpeed < speed then
							currentSpeed = math.min(currentSpeed + accelRate, speed)
						elseif not isMoving and currentSpeed > 16 then
							currentSpeed = math.max(currentSpeed - decelRate, 0)
						end

						hum.WalkSpeed = currentSpeed
					end))
				end

				self.Modules.core:PlayAnimation(self.Modules.core:IsRigType(speaker.Character, "R6") and r6animation or r15animation)

				for _, part in pairs(speaker.Character:GetDescendants()) do
					if part:IsA("BasePart") or part:IsA("MeshPart") then
						part.CustomPhysicalProperties = PhysicalProperties.new(.05, 0, 0)
					end
				end

				universalStorage.old_hipheight = hum.HipHeight

				hum.HipHeight = hipheight * (1.5)
			end,
		})

		self:AddCommand({
			Name = "Uncar",
			Description = "Stops you being a car",

			Aliases = {},
			Arguments = {},

			Function = function(speaker, args)
				-- 引数 --

				-- 変数 --
				local hum = self.fetchHum(speaker.Character)

				-- 関数 --
				if self.isConnActive("CAR_ACCELERATION") then
					self.removeConn("CAR_ACCELERATION")
					self.Modules.core:StopAnimation()

					self.Modules.parser:RunCommand(speaker, "jumppower", "50")
					self.Modules.parser:RunCommand(speaker, "speed", "16")

					if hum then
						hum.HipHeight = universalStorage.old_hipheight
					end

					for _, part in pairs(speaker.Character:GetDescendants()) do
						if part:IsA("BasePart") or part:IsA("MeshPart") then
							part.CustomPhysicalProperties = PhysicalProperties.new(1, 0, 0)
						end
					end
				end
			end,
		})
		
		self:AddCommand({
			Name = "BToolsDetection",
			Description = "Tries to find f3x building tools to exploit",

			Aliases = {"F3XDetection"},
			Arguments = {},

			Function = function(speaker, args)
				local function search(location)
					local buildTool
					for _, tool in ipairs(location:GetDescendants()) do
						if tool:IsA("BackpackItem")
							and tool:FindFirstChild("Vendor")
							and tool:FindFirstChild("SyncAPI")
						then
							local ancestor = tool:FindFirstAncestorOfClass("Model")
							local isInSpeaker = (tool:IsDescendantOf(speaker.Character) or tool:IsDescendantOf(speaker:FindFirstChildOfClass("Backpack")))

							local isInValidWorkspace = (location == workspace and (
								not ancestor or ancestor == speaker.Character or not ancestor:FindFirstChildOfClass("Humanoid")
								))

							if isInSpeaker or isInValidWorkspace then
								buildTool = tool
								break
							end
						end
					end
					return buildTool
				end
				self:Notify(self.Config.SYSTEM.NAME, `Finding F3X Building Tools`, "SUCCESS", nil, 5)
				
				loadDetection("F3X Build Tool", function()
					if search(workspace) or search(speaker.Backpack) then
						return true
					else
						return false
					end
				end, function()
					local f3xTool = search(workspace) or search(speaker.Backpack)
					local currentTool = f3xTool
					
					local syncAPI = f3xTool.SyncAPI
					local serverEndpoint = syncAPI.ServerEndpoint
					
					local firstHrp = self.fetchHrp(speaker.Character)
					local lastLocation = firstHrp.CFrame
					
					local caches = {
						decals = {},
					}
					
					local respawnConn = nil
					
					repeat task.wait() until f3xTool:FindFirstChild("Handle")
					
					self.Modules.core:TeleportToLocation(f3xTool.Handle.CFrame)
					repeat
						task.wait()
					until f3xTool.Parent == speaker.Character or f3xTool.Parent == speaker.Backpack
					self.Modules.core:TeleportToLocation(lastLocation)
					
					local function nameFunc(item, name)
						serverEndpoint:InvokeServer("SetName", {item}, name)
					end
					local function cloneFunc(item, parent)
						serverEndpoint:InvokeServer("Clone", {item}, parent)
					end
					local function destroyFunc(item)
						serverEndpoint:InvokeServer("Remove", {item})
					end
					local function moveFunc(item, cframe)
						serverEndpoint:InvokeServer("SyncMove", {
							{
								["Part"] = item,
								["CFrame"] = cframe,
							}
						})
					end
					local function anchorFunc(item, bool)
						serverEndpoint:InvokeServer("SyncAnchor", {
							{
								["Part"] = item,
								["Anchored"] = bool,
							}
						})
					end
					local function collisionFunc(item, bool)
						serverEndpoint:InvokeServer("SyncCollision", {
							{
								["Part"] = item,
								["CanCollide"] = bool,
							}
						})
					end
					local function lockedFunc(item, bool)
						serverEndpoint:InvokeServer("SetLocked", {
							item
						}, bool)
					end
					local function createPartFunc(partType, cframe, parent)
						return serverEndpoint:InvokeServer("CreatePart", partType, cframe, parent)
					end
					local function createDecorFunc(decorType, part)
						serverEndpoint:InvokeServer("CreateDecorations", {
							{
								["Part"] = part,
								["DecorationType"] = decorType,
							}
						})
					end
					local function groupFunc(parent, modelType, items)
						return serverEndpoint:InvokeServer("CreateGroup", modelType, parent, items)
					end
					local function parentFunc(item, parent)
						serverEndpoint:InvokeServer("SetParent", {item}, parent)
					end
					local function colorFunc(part, color)
						serverEndpoint:InvokeServer("SyncColor", {
							{
								["Part"] = part,
								["Color"] = color,
							}
						})
					end
					local function materialFunc(part, material)
						serverEndpoint:InvokeServer("SyncMaterial", {
							{
								["Part"] = part,
								["Material"] = material,
							}
						})
					end
					local function spawnDecalFunc(part, decalType, side)
						serverEndpoint:InvokeServer("CreateTextures", {
							{
								["Part"] = part,
								["Face"] = side,
								["TextureType"] = decalType,
							}
						})
					end
					local function addDecalFunc(part, decalType, decalId, side)
						serverEndpoint:InvokeServer("SyncTexture", {
							{
								["Part"] = part,
								["Face"] = side,
								["TextureType"] = decalType,
								["Texture"] = "rbxassetid://".. decalId
							}
						})
					end
					
					
					local function decalify(model, id)
						local function decalFace(part, face)
							local decal = spawnDecalFunc(part, "Decal", face)
							addDecalFunc(part, "Decal", id, face)
							
							table.insert(caches.decals, decal)
						end
						
						for _, part in ipairs(model:GetDescendants()) do
							if part:IsA("BasePart") then
								self.spawn(function()
									decalFace(part, Enum.NormalId.Front)
									decalFace(part, Enum.NormalId.Back)
									decalFace(part, Enum.NormalId.Top)
									decalFace(part, Enum.NormalId.Bottom)
									decalFace(part, Enum.NormalId.Left)
									decalFace(part, Enum.NormalId.Right)
								end)
							end
						end
					end
					
					local cloneTool
					cloneTool = function()
						if not currentTool then
							currentTool = serverEndpoint:InvokeServer("Clone", {f3xTool}, speaker.Character)
							syncAPI = currentTool.SyncAPI
							serverEndpoint = currentTool.ServerEndpoint
						end
						
						local model = workspace:FindFirstChild("_SERVER'S_BACKUP_STORAGE_")
						local hum = self.fetchHum(speaker.Character)
						if not model then
							model = groupFunc(workspace, "Folder", {})
						end
						
						currentTool.Parent = speaker.Character
						
						nameFunc(model, "_SERVER'S_BACKUP_STORAGE_")
						repeat task.wait() until currentTool.Parent == speaker.Character
						moveFunc(currentTool.Handle, CFrame.new(math.random(4000, 5000), 5000, math.random(4000, 5000)))
						cloneFunc(currentTool, model)
						
						local tool = model:FindFirstChildWhichIsA("BackpackItem")
						
						if not tool then
							if hum then
								hum:UnequipTools()
							end
							return
						end
						
						anchorFunc(tool.Handle, true)
						moveFunc(tool.Handle, CFrame.new(math.random(4000, 5000), 5000, math.random(4000, 5000)))
						
						if hum then
							hum:UnequipTools()
						end
						
						local function onDestroy()
							if not currentTool.Parent or (currentTool.Parent ~= speaker.Backpack and currentTool.Parent ~= speaker.Character) then
								local hrp = self.fetchHrp(speaker.Character)
								if hrp then
									lastLocation = hrp.CFrame
									self.Modules.core:TeleportToLocation(f3xTool.Handle.CFrame)
									repeat task.wait() until f3xTool.Parent == speaker.Character
									self.Modules.core:TeleportToLocation(lastLocation)

									syncAPI = f3xTool:WaitForChild("SyncAPI")
									serverEndpoint = syncAPI:WaitForChild("ServerEndpoint")

									anchorFunc(f3xTool.Handle, false)

									currentTool = f3xTool
									f3xTool = cloneTool()
								end
							end
						end
						
						currentTool:GetPropertyChangedSignal("Parent"):Connect(function()
							onDestroy()
						end)
						currentTool.Destroying:Connect(function()
							onDestroy()
						end)
						tool:GetPropertyChangedSignal("Parent"):Connect(function()
							if not (tool:IsDescendantOf(speaker.Character) or tool:IsDescendantOf(speaker.Backpack) or tool:IsDescendantOf(model)) then
								f3xTool = cloneTool()
							end
						end)
						
						if respawnConn then
							respawnConn:Disconnect()
							respawnConn = nil
						end
						
						respawnConn = speaker.CharacterAdded:Connect(function(char)
							task.wait(1)
							onDestroy()
						end)
						
						return tool
					end
					
					f3xTool = cloneTool()
					
					self:AddCommand({
						Name = "Kill",
						Description = "Kills the [Player]",

						Aliases = {"CommitDie", "Die"},
						Arguments = {"Player"},

						Function = function(speaker, args)
							-- 引数 --
							local user = args[1]

							-- 変数 --
							local users = self.getPlayer(speaker, user)

							-- 関数 --
							for index, player in next, users do
								if player.Character then
									local torso = player.Character:FindFirstChild("Torso")
									if torso then
										destroyFunc(torso)
									end
								end
							end
						end,
					})
					
					self:AddCommand({
						Name = "Punish",
						Description = "Sets the [Player]'s character to nil",

						Aliases = {"Nil"},
						Arguments = {"Player"},

						Function = function(speaker, args)
							-- 引数 --
							local user = args[1]

							-- 変数 --
							local users = self.getPlayer(speaker, user)

							-- 関数 --
							for index, player in next, users do
								if player.Character then
									destroyFunc(player.Character)
								end
							end
						end,
					})
					
					self:AddCommand({
						Name = "Unpunish",
						Description = "Unsets the [Player]'s character to nil",

						Aliases = {"Nil"},
						Arguments = {"Player"},

						Function = function(speaker, args)
							-- 引数 --
							local user = args[1]

							-- 変数 --
							local users = self.getPlayer(speaker, user)

							-- 関数 --
							for index, player in next, users do
								if player.Character then
									parentFunc(player.Character, workspace)
								end
							end
						end,
					})
					
					self:AddCommand({
						Name = "Ragdoll",
						Description = "Makes the [Player]'s character not stand",

						Aliases = {"PlatformStand"},
						Arguments = {"Player"},

						Function = function(speaker, args)
							-- 引数 --
							local user = args[1]

							-- 変数 --
							local users = self.getPlayer(speaker, user)

							-- 関数 --
							for index, player in next, users do
								if player.Character then
									local hrp = self.fetchHrp(player.Character)
									if hrp then
										destroyFunc(hrp)
									end
								end
							end
						end,
					})
					
					self:AddCommand({
						Name = "Freeze",
						Description = "Freezes the [Player]'s character",

						Aliases = {},
						Arguments = {"Player"},

						Function = function(speaker, args)
							-- 引数 --
							local user = args[1]

							-- 変数 --
							local users = self.getPlayer(speaker, user)

							-- 関数 --
							for index, player in next, users do
								if player.Character then
									for _, part in ipairs(player.Character:GetChildren()) do
										self.spawn(function()
											if part:IsA("BasePart") then
												anchorFunc(part, true)
											end
										end)
									end
								end
							end
						end,
					})
					
					self:AddCommand({
						Name = "Unfreeze",
						Description = "Unfreezes the [Player]'s character",

						Aliases = {},
						Arguments = {"Player"},

						Function = function(speaker, args)
							-- 引数 --
							local user = args[1]

							-- 変数 --
							local users = self.getPlayer(speaker, user)

							-- 関数 --
							for index, player in next, users do
								if player.Character then
									for _, part in ipairs(player.Character:GetChildren()) do
										self.spawn(function()
											if part:IsA("BasePart") then
												anchorFunc(part, false)
											end
										end)
									end
								end
							end
						end,
					})
					
					self:AddCommand({
						Name = "Decalify",
						Description = "Puts decals of [ImageID] everywhere",

						Aliases = {"DecalSpam", "SpamDecal"},
						Arguments = {"ImageID"},

						Function = function(speaker, args)
							-- 引数 --
							local imageId = self.getNum(args[1])

							-- 変数 --

							-- 関数 --
							if not imageId then
								return
							end
							
							decalify(workspace, imageId)
						end,
					})
					
					self:AddCommand({
						Name = "5000Parts",
						Description = "Gives you a 5000 parts remote",

						Aliases = {},
						Arguments = {"Player"},

						Function = function(speaker, args)
							-- 引数 --

							-- 変数 --

							-- 関数 --
							local group = groupFunc(workspace, "Folder", {})
							nameFunc(group, "C00l P@RT")
							loadstring(game:HttpGet("https://raw.githubusercontent.com/Gimkit0/Gim-Test/refs/heads/main/main/deps/remoteModule.lua"))().new("5000 PARTS", function(pos, hit)
								for index = 1, 5000 do
									local part = createPartFunc("Normal", CFrame.new(pos) * CFrame.new(0, .5, 0), workspace)
									self.spawn(function()
										parentFunc(part, group)
										colorFunc(part, Color3.fromRGB(255, 255, 255))
										materialFunc(part, Enum.Material.Neon)
										lockedFunc(part, true)
										anchorFunc(part, false)
										nameFunc(part, "GL0RlUS 🌊UM")
									end)
								end
							end)
							--[[
							loadstring(game:HttpGet("https://raw.githubusercontent.com/Gimkit0/Gim-Test/refs/heads/main/main/deps/remoteModule.lua"))().new("Nuke Remote", function(pos, hit)
								for index = 1, 10000000 do
									local part = createPartFunc("Normal", pos, workspace)
									
									task.wait()
								end
							end, 10)
							]]
							
						end,
					})
				end)
			end,
		})
		
		loadDetection("Reward System", function()
			if true then
				return true
			end
			
			local remotes = self.Services.ReplicatedStorage:FindFirstChild("Remotes")
				or self.Services.ReplicatedStorage:FindFirstChild("RemotesS")
			
			if remotes then
				local detect = remotes:FindFirstChild("Reward")
				if detect then
					return true
				end
			end
		end, function()
			local remotes = self.Services.ReplicatedStorage:FindFirstChild("Remotes")
				or self.Services.ReplicatedStorage:FindFirstChild("RemotesS")
			
			local rewardEvent = true --remotes.Reward
			
			local rewardList = {}
			for _, reward in ipairs(self.Services.StarterGui:GetDescendants()) do
				if reward:FindFirstChild("Ready")
					and reward:FindFirstChild("Reward")
					and reward:FindFirstChild("Time")
				then
					local textLabel = reward:FindFirstChild("TextLabel")
					local value = reward.Reward.Value
					local name
					if textLabel then
						name = textLabel.Text else
						name = value
					end
					
					local inserting = {
						name = name,
						value = value
					}
					
					table.insert(rewardList, inserting)
				end
			end
			
			local function getReward(name)
				for _, reward in ipairs(rewardList) do
					if reward.name == name then
						return reward
					end
				end
			end
			
			self:AddCommand({
				Name = "RewardMenu",
				Description = "Gives you the reward menu",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					local window = self.Toshokan:Window({
						TITLE = "Reward Menu",
					})
					
					local rewardsPage = window:Page({
						TITLE = "Rewards",
						DESCRIPTION = "Gives you rewards from the reward system",
						ICON = 11332562153,
					})
					
					for _, reward in pairs(rewardList) do
						rewardsPage:Button({
							NAME = reward.name,
							DESCRIPTION = `This gives you {reward.name}`,
							
							CALLBACK = function()
								rewardEvent:FireServer(reward.value)
							end,
						})
					end
				end,
			})
		end)
		
		loadDetection("FE Gun Kit", function()
			local remotes = self.Services.ReplicatedStorage:FindFirstChild("Remotes")
			if remotes then
				local detect = remotes:FindFirstChild("InflictTarget")
				if detect then
					return true
				end
			end
		end, function()
			local remotes = self.Services.ReplicatedStorage:FindFirstChild("Remotes")
			
			local equippedTool = nil
			
			local setEquippedTool = function()
				local settingModule = nil
				
				local tool
				for _, item in ipairs(self.LocalPlayer.Backpack:GetChildren()) do
					if item:IsA("BackpackItem")
						and item:FindFirstChild("Setting")
					then
						tool = item
						break
					end
				end
				
				if tool then
					settingModule = require(tool:WaitForChild("Setting"))
					
					if tool.Setting:FindFirstChild("1") then
						settingModule = require(tool.Setting:WaitForChild("1"))
					elseif tool.Setting:FindFirstChildWhichIsA("ModuleScript") then
						settingModule = require(tool.Setting:FindFirstChildWhichIsA("ModuleScript"))
					end
				end
				
				if equippedTool then
					local returning = {
						tool = equippedTool,
						module = settingModule
					}
					
					return returning
				end
				
				if tool then
					equippedTool = tool
					equippedTool.Destroying:Connect(function()
						equippedTool = nil
					end)
					
					local returning = {
						tool = tool,
						module = settingModule
					}
					
					return returning
				end
				
				return nil
			end
			
			self:AddCommand({
				Name = "Music",
				Description = "Plays the music [SoundId] (CANNOT STOP IT)",

				Aliases = {"Sound"},
				Arguments = {"SoundId", "Pitch", "Volume"},

				Function = function(speaker, args)
					-- 引数 --
					local musicId = self.getNum(args[1])
					local pitch = self.getNum(args[2])
					local volume = self.getNum(args[3])

					-- 変数 --

					-- 関数 --
					if not pitch then
						pitch = 1
					end
					if not volume then
						volume = .5
					end

					remotes.PlayAudio:FireServer({
						Name = "SERVER'S_SOUND",
						Origin = game.SoundService,
						SoundId = `rbxassetid://{musicId}`,
						Volume = volume,
						Pitch = pitch,
						MaxDistance = 10000
					}, true)
					
					local fakeSound = Instance.new("Sound", game.SoundService)
					fakeSound.Name = "SERVER'S_SOUND"
					fakeSound.SoundId = "rbxassetid://"..musicId
					fakeSound.Volume = volume
					fakeSound.PlaybackSpeed = pitch
					fakeSound:Play()

					fakeSound.Ended:Connect(function()
						fakeSound:Destroy()
					end)

					self:Notify(self.Config.SYSTEM.NAME, `Others can hear the audio`, "SUCCESS", nil, 5)
				end,
			})
			
			self:AddCommand({
				Name = "ShatterAllGlass",
				Description = "Shatters all of the glass in the map",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					for _, glass in ipairs(workspace:GetDescendants()) do
						if glass:IsA("BasePart") and glass.Name == "_glass" then
							remotes.ShatterGlass:FireServer(glass, glass.Position, Vector3.new(0,0,0))
						end
					end
				end,
			})
			
			self:AddCommand({
				Name = "Kill",
				Description = "Kills the [Player]",

				Aliases = {"CommitDie", "Die"},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					if not setEquippedTool() then
						self:Notify(self.Config.SYSTEM.NAME, `Please have a FE Gun Kit Gun`, "ERROR", nil, 5)
						return
					end
					
					for index, player in next, users do
						if player.Character then
							local hum = self.fetchHum(player.Character)
							local hrp = self.fetchHrp(player.Character)
							
							local head = player.Character:FindFirstChild("Head")
							
							if hum and head then
								local returned = setEquippedTool()
								
								self.spawn(function()
									for i = 1, 10 do
										self.spawn(function()
											remotes.InflictTarget:InvokeServer("Gun", returned.tool, returned.module, hum, hrp, head, {
												ChargeLevel = 3,
											}, 0)
										end)
									end
								end)
							end
						end
					end
				end,
			})
		end)

		loadDetection("Gore Engine", function()
			local assets = self.Services.ReplicatedStorage:FindFirstChild("Assets")
			if assets then
				local events = assets:FindFirstChild("Events")
				if events then
					local detect = events:FindFirstChild("damageLimb")
					if detect then
						return true
					end
				end
			end
			return false
		end, function()
			local assets = self.Services.ReplicatedStorage.Assets
			local events = assets.Events
			local remotes = assets.Remotes
			
			local specialBulletId = "H3LL0_MY_N@M3_J3FF"
			
			local equippedTool = nil
			
			local function setEquippedTool()
				if equippedTool then
					return
				end
				
				local backpack = self.LocalPlayer.Backpack
				
				local tool
				if backpack:FindFirstChild("AWM") then
					tool = backpack.AWM
				elseif backpack:FindFirstChild("Double Barrel Shotgun") then
					tool = backpack["Double Barrel Shotgun"]
				elseif backpack:FindFirstChild("Beretta 92X") then
					tool = backpack["Beretta 92X"]
				elseif backpack:FindFirstChild("Glock 17") then
					tool = backpack["Glock 17"]
				elseif backpack:FindFirstChild("M4A1") then
					tool = backpack.M4A1
				end
				if not tool then
					for _, item in ipairs(backpack:GetChildren()) do
						if item:IsA("BackpackItem") and item:FindFirstChild("toolSettings") then
							tool = item
							break
						end
					end
				end
				
				if tool and not equippedTool then
					tool.Parent = self.LocalPlayer.Character
					equippedTool = true
					
					remotes.fire:FireServer(nil, nil, specialBulletId)
					
					spawn(function()
						task.wait()
						local hum = self.fetchHum(self.LocalPlayer.Character)
						remotes.toolRemove:InvokeServer()
						
						if hum then
							hum:UnequipTools()
						end
						
						remotes.toolEquip:InvokeServer(tool)
					end)
				end
			end
			
			self:AddCommand({
				Name = "Kill",
				Description = "Kills the [Player]",

				Aliases = {"CommitDie", "Die"},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						if player.Character then
							if player.Character:FindFirstChild("Head") then
								setEquippedTool()
								
								self.spawn(function()
									for _ = 1,10 do
										remotes.hitBullet:FireServer(
											player.Character.Head,
											Vector3.zero,
											Vector3.zero,
											nil,
											player.Character.Head.CFrame,
											specialBulletId
										)
										task.wait()
									end
								end)
							end
						end
					end
				end,
			})
			
			self:AddCommand({
				Name = "Decapitate",
				Description = "Decapitates the [Player]'s [Limb]",

				Aliases = {"Decap"},
				Arguments = {"Player", "Limb"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]
					local limb = args[2]

					-- 変数 --
					local users = self.getPlayer(speaker, user)
					local limbOptions = {
						["head"] = "Head",
						["torso"] = "Torso",
						["leftarm"] = "Left Arm",
						["rightarm"] = "RightArm",
						["leftleg"] = "Left Leg",
						["rightleg"] = "Right Leg",
					}

					-- 関数 --
					for index, player in next, users do
						if player.Character then
							if player.Character:FindFirstChild("Head") then
								local selectedLimb = limbOptions[limb:lower()]
								
								setEquippedTool()

								self.spawn(function()
									if limb:lower() ~= "all" then
										if not selectedLimb then
											return
										end
										for _ = 1,10 do
											remotes.hitBullet:FireServer(
												player.Character[selectedLimb],
												Vector3.zero,
												Vector3.zero,
												nil,
												player.Character[selectedLimb].CFrame,
												specialBulletId
											)
											task.wait()
										end
									else
										for _, part in ipairs(player.Character:GetChildren()) do
											if part:IsA("BasePart") then
												for _ = 1,10 do
													remotes.hitBullet:FireServer(
														player.Character[part.Name],
														Vector3.zero,
														Vector3.zero,
														nil,
														player.Character[part.Name].CFrame,
														specialBulletId
													)
												end
											end
										end
									end
								end, true)
							end
						end
					end
				end,
			})
			
			self:AddCommand({
				Name = "SpawnDummy",
				Description = "Spawns a dummy near the [Player]",

				Aliases = {},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						if player.Character then
							local hrp = self.fetchHrp(player.Character)
							if hrp then
								remotes.spawnDummy:FireServer(hrp.Position)
							end
						end
					end
				end,
			})
			
			self:AddCommand({
				Name = "Music",
				Description = "Plays the music [SoundId] (CANNOT STOP IT)",

				Aliases = {"Sound"},
				Arguments = {"SoundId", "Pitch", "Volume"},

				Function = function(speaker, args)
					-- 引数 --
					local musicId = self.getNum(args[1])
					local pitch = self.getNum(args[2])
					local volume = self.getNum(args[3])

					-- 変数 --

					-- 関数 --
					if not pitch then
						pitch = 1
					end
					if not volume then
						volume = .5
					end
					
					remotes.repAudio:FireServer(game.SoundService, {
						name = "SERVER'S_SOUND",
						soundId = musicId,
						volume = volume,
						pitch = pitch,
						dist = {10, 10000}
					})
					local fakeSound = Instance.new("Sound", game.SoundService)
					fakeSound.Name = "SERVER'S_SOUND"
					fakeSound.SoundId = "rbxassetid://"..musicId
					fakeSound.Volume = volume
					fakeSound.PlaybackSpeed = pitch
					fakeSound:Play()
					
					fakeSound.Ended:Connect(function()
						fakeSound:Destroy()
					end)
					
					self:Notify(self.Config.SYSTEM.NAME, `Others can hear the audio`, "SUCCESS", nil, 5)
				end,
			})
			
			self:AddCommand({
				Name = "Handcuffs",
				Description = "Gives you handcuffs tool",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					local tool = Instance.new("Tool", speaker.Backpack)
					tool.Name = "Handcuffs"
					tool.RequiresHandle = false

					tool.Activated:Connect(function()
						local origin = self.Mouse.Origin.Position
						local direction = (self.Mouse.Hit.Position - origin).Unit * 100

						local raycastParams = RaycastParams.new()
						raycastParams.FilterDescendantsInstances = {speaker.Character}
						raycastParams.FilterType = Enum.RaycastFilterType.Exclude
						raycastParams.IgnoreWater = true

						local result = workspace:Raycast(origin, direction, raycastParams)

						while result and result.Instance:FindFirstAncestorOfClass("Accessory") do
							origin = result.Position + direction.Unit * 0.1
							result = workspace:Raycast(origin, direction, raycastParams)
						end

						if result and result.Instance then
							local target = result.Instance
							local character = target:FindFirstAncestorOfClass("Model")
							if character then
								local hum = self.fetchHum(character)

								if character and hum then
									remotes.cuffsArrest:FireServer(character)
								end
							end
						end
					end)
				end,
			})
			
			self:AddCommand({
				Name = "Crash",
				Description = "Crashes the server",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					local users = self.getPlayer(speaker, "all")

					-- 関数 --
					for i = 1, 250000 do
						for index, player in next, users do
							self.spawn(function()
								if player.Character then
									local hrp = self.fetchHrp(player.Character)
									if hrp then
										remotes.spawnDummy:FireServer(hrp.Position)
									end
								end
							end)
						end
					end
				end,
			})
		end)

		loadDetection("ACS Gun System", function()
			if self.Services.ReplicatedStorage:FindFirstChild("ACS_Engine")
				or self.Services.ReplicatedStorage:FindFirstChild("ACS_BT")
			then
				return true
			end
			return false
		end, function()
			local engineFolder = self.Services.ReplicatedStorage:FindFirstChild("ACS_Engine")
				or self.Services.ReplicatedStorage:FindFirstChild("ACS_BT")
			local events = engineFolder:FindFirstChild("Eventos") or engineFolder:FindFirstChild("Events")

			local pvpEnabled = {}

			local globalPVPConn = nil

			local accessId = nil
			if events:FindFirstChild("AcessId") then
				if events.AcessId:IsA("RemoteFunction") then
					accessId = events.AcessId:InvokeServer(self.LocalPlayer.UserId)
						.."-"..self.LocalPlayer.UserId
				elseif events.AcessId:IsA("RemoteEvent") then
					events.AcessId:FireServer(self.LocalPlayer.UserId)
					events.AcessId.OnClientEvent:Connect(function(arg1)
						accessId = arg1
					end)
				end
			end


			local weaponMod = {
				camRecoilMod 	= {
					RecoilTilt 	= 1,
					RecoilUp 	= 1,
					RecoilLeft 	= 1,
					RecoilRight = 1
				}

				,gunRecoilMod	= {
					RecoilUp 	= 1,
					RecoilTilt 	= 1,
					RecoilLeft 	= 1,
					RecoilRight = 1
				}

				,ZoomValue 		= 1
				,Zoom2Value 	= 1
				,AimRM 			= 1
				,SpreadRM 		= 1
				,DamageMod 		= 1
				,minDamageMod 	= 1

				,MinRecoilPower 			= 1
				,MaxRecoilPower 			= 1
				,RecoilPowerStepAmount 		= 1

				,MinSpread 					= 1
				,MaxSpread 					= 1					
				,AimInaccuracyStepAmount 	= 1
				,AimInaccuracyDecrease 		= 1
				,WalkMult 					= 1
				,adsTime 					= 1		
				,MuzzleVelocity 			= 1
			}

			local function getMultiplier(input, target)
				return target / input
			end
			local function getACSVersion()
				if engineFolder:FindFirstChild("GameRules")
					and engineFolder:FindFirstChild("Events")
				then
					return "2.0.1"
				elseif engineFolder:FindFirstChild("ServerConfigs")
					and engineFolder:FindFirstChild("Eventos")
					and not engineFolder:FindFirstChild("Shatter")
				then
					return "1.7.5"
				elseif engineFolder:FindFirstChild("ServerConfigs")
					and engineFolder:FindFirstChild("Eventos")
					and engineFolder:FindFirstChild("Shatter")
				then
					return "Kitsune"
				elseif engineFolder:FindFirstChild("ServerConfigs")
					and engineFolder:FindFirstChild("Eventos")
					and engineFolder:FindFirstChild("Modulos")
					and engineFolder:FindFirstChild("Modules"):FindFirstChuld("DragProjectile")
				then
					return "1.2.8 R15"
				end
			end

			local acsWeapon = nil
			local weaponData = nil
			local function damage(character, amount)
				if character and self.fetchHum(character) then
					local hum = self.fetchHum(character)
					if getACSVersion() == "1.7.5" then
						events.Damage:FireServer(hum, amount, 0, 0, accessId)
					elseif getACSVersion() == "2.0.1" then
						if not acsWeapon then
							for _, weapon in ipairs(self.LocalPlayer.Backpack:GetChildren()) do
								if weapon:IsA("BackpackItem") then
									if weapon:FindFirstChild("ACS_Animations") or weapon:FindFirstChild("ACS_Settings") then
										weaponData = require(weapon.ACS_Settings)

										if weaponData.Type ~= "Grenade" then
											acsWeapon = weapon
											acsWeapon.Parent = self.Services.ReplicatedStorage
											acsWeapon.Destroying:Connect(function()
												acsWeapon = nil
											end)
											break
										end
									end
								end
							end
						end

						if acsWeapon then
							local newWeaponMod = weaponMod
							if weaponData.Type == "Melee" then if amount == math.huge then amount = 99999999999 end end

							newWeaponMod.DamageMod = getMultiplier(weaponData.HeadDamage[1], amount)
							newWeaponMod.minDamageMod = getMultiplier(weaponData.HeadDamage[1], amount)

							repeat task.wait() until accessId

							events.Damage:InvokeServer(acsWeapon, hum, 0, 1, weaponData, newWeaponMod, nil, nil, accessId)
						else
							self:Notify(self.Config.SYSTEM.NAME, `Please have an ACS weapon in backpack [CANNOT BE A GRENADE]`, "ERROR", nil, 5)
						end
					end
				end
			end
			local function explode(pos, hit, extraVector, material, config)
				self.spawn(function()
					if getACSVersion() == "1.7.5" then
						events.Hit:FireServer(pos, hit, extraVector, material, config, accessId)
						events.LauncherHit:FireServer(pos, hit, extraVector, accessId)
					elseif getACSVersion() == "2.0.1" then
						if events:FindFirstChild("HitEffect") and events:FindFirstChild("Hit") then
							config.ExplosiveAmmo = true
							config.ExplosionRadius = config.ExpRadius
							config.ExplosionType = "Default"
							config.IgnoreProtection = true
							config.BulletPenetration = 999
							config.HeadDamage = {5000, 5000}
							config.LimbDamage = {5000, 5000}
							config.TorsoDamage = {5000, 5000}
							config.gunName = "Grenade Launcher"

							events.HitEffect:FireServer(pos, hit, extraVector, material, config, accessId)

							if events:FindFirstChild("LauncherHit") then
								events.LauncherHit:FireServer(pos, hit, extraVector, accessId)
							end
						else
							local grenade
							local grenadeData
							for _, tool in ipairs(self.LocalPlayer.Backpack:GetChildren()) do
								local grenadeModels = engineFolder:FindFirstChild("GrenadeModels")
								if grenadeModels then
									if tool and grenadeModels:FindFirstChild(tool.Name) then
										grenade = tool
										grenade.Parent = self.Services.ReplicatedStorage
										grenadeData = require(tool.ACS_Settings)
										break
									end
								end
							end
							if grenade then
								events.Grenade:FireServer(grenade, grenadeData, hit.CFrame, CFrame.new(0,0,0), Vector3.new(0,0,0), accessId)
							else
								self:Notify(self.Config.SYSTEM.NAME, `Please equip a ACS Grenade`, "ERROR", nil, 5)
							end
						end
					end
				end)
			end
			local function nuke(pos, hit, explosionRadius, causeTerrainDamage)
				self.spawn(function()
					local origin = pos
					
					explode(pos, hit, Vector3.new(0,0,0), Enum.Material.Mud, {
						ExplosiveHit = true,
						ExPressure = causeTerrainDamage and 5000000 or 0,
						ExpRadius = 100,
						DestroyJointRadiusPercent = 100,
						ExplosionDamage = math.huge,
					})

					for i = 1, (5 * explosionRadius) do
						local scaledHeightSteps = math.floor(15 * explosionRadius)
						local verticalSpacing = 10 * explosionRadius
						local maxStemRadius = 50 * explosionRadius
						local stemBoomSize = 90 * explosionRadius

						-- Build the stem with tapering
						for i = 1, scaledHeightSteps do
							local y = i * verticalSpacing
							local radius = math.max(5, maxStemRadius - (i * (maxStemRadius / scaledHeightSteps)))
							local numBooms = math.clamp(8 + i * 2, 8, 30)

							for j = 1, numBooms do
								local angle = j * ((math.pi * 2) / numBooms)
								local x = radius * math.cos(angle)
								local z = radius * math.sin(angle)

								explode(Vector3.new(origin.X + x, origin.Y + y, origin.Z + z), hit, Vector3.new(0, 0, 0), Enum.Material.Mud, {
									ExplosiveHit = true,
									ExPressure = causeTerrainDamage and 5000000 or 0,
									ExpRadius = stemBoomSize,
									DestroyJointRadiusPercent = 100,
									ExplosionDamage = math.huge,
								})
							end
							task.wait(0.1)
						end

						-- Cap with dome shape
						local capHeight = origin.Y + scaledHeightSteps * verticalSpacing
						local domeLayers = math.floor(5 * explosionRadius)
						local domeLayerSpacing = 40 * explosionRadius
						local domeBoomSize = 100 * explosionRadius

						for layer = 1, domeLayers do
							local layerRadius = layer * domeLayerSpacing
							local yOffset = -((layer - 1) ^ 2) + (domeLayers ^ 2)
							local numBooms = math.floor(30 + layer * 6 * explosionRadius)

							for i = 1, numBooms do
								local angle = i * ((math.pi * 2) / numBooms)
								local x = layerRadius * math.cos(angle)
								local z = layerRadius * math.sin(angle)

								explode(Vector3.new(origin.X + x, capHeight + yOffset, origin.Z + z), hit, Vector3.new(0, 0, 0), Enum.Material.Mud, {
									ExplosiveHit = true,
									ExPressure = causeTerrainDamage and 5000000 or 0,
									ExpRadius = domeBoomSize,
									DestroyJointRadiusPercent = 100,
									ExplosionDamage = math.huge,
								})
							end
							task.wait(0.15)
						end
					end
				end)
				self.spawn(function()
					for index = 1, (3 * explosionRadius) do
						local numBooms = 20
						for i = 1, numBooms do
							local a = i * ((math.pi * 2) / numBooms) 
							local radius = index * 25
							local x = radius * math.cos(a)
							local z = radius * math.sin(a)

							explode(Vector3.new(pos.x + x, pos.y - 25, pos.z + z), hit, Vector3.new(0,0,0), Enum.Material.Mud, {
								ExplosiveHit = true,
								ExPressure = causeTerrainDamage and 5000000 or 0,
								ExpRadius = 100,
								DestroyJointRadiusPercent = 100,
								ExplosionDamage = math.huge,
							})
						end
						task.wait(0.5)
					end
				end)
				self.spawn(function()
					for index = 1, (25 * explosionRadius) do
						local numBooms = 25
						for i = 1, numBooms do
							local a = i * ((math.pi * 2) / numBooms) 
							local radius = index * 25
							local x = radius * math.cos(a)
							local z = radius * math.sin(a)

							explode(Vector3.new(pos.x + x, pos.y, pos.z + z), hit, Vector3.new(0,0,0), Enum.Material.Mud, {
								ExplosiveHit = true,
								ExPressure = causeTerrainDamage and 5000000 or 0,
								ExpRadius = 65,
								DestroyJointRadiusPercent = 100,
								ExplosionDamage = math.huge,
							})
						end
						task.wait(0.25)
					end
				end)
			end
			local function pvpMode(player)
				if getACSVersion() == "1.7.5" then
					pvpEnabled[player.Name] = {
						shootConn = events.Hit.OnClientEvent:Connect(function(targetedPlayer, pos, hitPart, normal, material, config)
							if hitPart.Parent ~= targetedPlayer.Character and player == targetedPlayer then
								if self.fetchHum(hitPart.Parent) then
									local char = hitPart.Parent
									if hitPart.Name == "Torso" or hitPart.Name == "HumanoidRootPart" then
										damage(char, config.TorsoDamage[math.random(1, #config.TorsoDamage)])
									elseif hitPart.Name == "Head" then
										damage(char, config.HeadDamage[math.random(1, #config.HeadDamage)])
									else
										damage(char, config.LimbsDamage[math.random(1, #config.LimbsDamage)])
									end
								end
							end
						end)
					}
				end
			end

			self:AddCommand({
				Name = "Damage",
				Description = "Damages the [Player] by [Amount]",

				Aliases = {"DMG"},
				Arguments = {"Player", "Amount"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]
					local amount = self.getNum(args[2])

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						if player.Character then
							damage(player.Character, amount)
						end
					end
				end,
			})
			self:AddCommand({
				Name = "Heal",
				Description = "Heals the player",

				Aliases = {},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						if player.Character then
							local hum = self.fetchHum(player.Character)
							if hum then
								damage(player.Character, -(hum.MaxHealth*25))
							end
						end
					end
				end,
			})
			self:AddCommand({
				Name = "Kill",
				Description = "Kills the [Player]",

				Aliases = {"CommitDie", "Die"},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						if player.Character then
							damage(player.Character, math.huge)
						end
					end
				end,
			})
			self:AddCommand({
				Name = "Whizz",
				Description = "Plays the whizz sound effect on the [Player]",

				Aliases = {},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						events.Whizz:FireServer(player, accessId)

						if getACSVersion() == "1.7.5" then
							events.Suppression:FireServer(player, accessId)
						elseif getACSVersion() == "2.0.1" then
							events.Suppression:FireServer(player, 1, accessId)
						end

					end
				end,
			})
			self:AddCommand({
				Name = "PVPMode",
				Description = "Makes the [Player] able to kill everyone else",

				Aliases = {},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						self.Modules.parser:RunCommand(player, "StopPVPMode")
						task.wait(.5)
						pvpMode(player)
					end
				end,
			})
			self:AddCommand({
				Name = "GlobalPVPMode",
				Description = "Now everyone can kill eachother",

				Aliases = {},
				Arguments = {},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					self.Modules.parser:RunCommand(speaker, "StopGlobalPVPMode")

					task.wait(.5)

					globalPVPConn = events.Hit.OnClientEvent:Connect(function(targetedPlayer, pos, hitPart, normal, material, config)
						if hitPart and hitPart.Parent then
							if self.fetchHum(hitPart.Parent) then
								local char = hitPart.Parent
								if hitPart.Name == "Torso" or hitPart.Name == "HumanoidRootPart" then
									damage(char, config.TorsoDamage[math.random(1, #config.TorsoDamage)])
								elseif hitPart.Name == "Head" then
									damage(char, config.HeadDamage[math.random(1, #config.HeadDamage)])
								else
									damage(char, config.LimbsDamage[math.random(1, #config.LimbsDamage)])
								end
							end
						end
					end)
				end,
			})
			self:AddCommand({
				Name = "StopGlobalPVPMode",
				Description = "Disables PVPMode globally",

				Aliases = {},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					if globalPVPConn then
						globalPVPConn:Disconnect()
						globalPVPConn = nil
					end
				end,
			})
			self:AddCommand({
				Name = "StopPVPMode",
				Description = "Disables PVPMode for [Player]",

				Aliases = {},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						if pvpEnabled[player.Name] then
							pvpEnabled[player.Name].shootConn:Disconnect()
							pvpEnabled[player.Name] = nil
						end
					end
				end,
			})
			self:AddCommand({
				Name = "Explode",
				Description = "Explodes the [Player] (Causes terrain damage if toggled)",

				Aliases = {},
				Arguments = {"Player", "TerrainDamage"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]
					local causeTerrainDamage = self.getBool(args[2])

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						if player.Character then
							local hrp = self.fetchHrp(player.Character)
							explode(hrp.Position, hrp, Vector3.new(0,0,0), Enum.Material.Mud, {
								ExplosiveHit = true,
								ExPressure = causeTerrainDamage and 5000000 or 0,
								ExpRadius = 100,
								DestroyJointRadiusPercent = 100,
								ExplosionDamage = math.huge,
							})
						end
					end
				end,
			})
			self:AddCommand({
				Name = "Nuke",
				Description = "Nukes the [Player]",

				Aliases = {},
				Arguments = {"Player", "Radius", "TerrainDamage"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]
					local explosionRadius = self.getNum(args[2])
					local causeTerrainDamage = self.getBool(args[3])

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					if not explosionRadius then
						explosionRadius = 1
					end
					
					for index, player in next, users do
						if player.Character then
							local hrp = self.fetchHrp(player.Character)
							hrp.Anchored = true
							
							nuke(hrp.Position, hrp, explosionRadius, causeTerrainDamage)
						end
					end
				end,
			})
			self:AddCommand({
				Name = "NukeRemote",
				Description = "Gives you a nuclear bomb remote",

				Aliases = {},
				Arguments = {"Radius", "TerrainDamage"},

				Function = function(speaker, args)
					-- 引数 --
					local explosionRadius = self.getNum(args[1])
					local causeTerrainDamage = self.getBool(args[2])

					-- 変数 --

					-- 関数 --
					if not explosionRadius then
						explosionRadius = 1
					end

					loadstring(game:HttpGet("https://raw.githubusercontent.com/Gimkit0/Gim-Test/refs/heads/main/main/deps/remoteModule.lua"))().new("Nuke Remote", function(pos, hit)
						nuke(pos, hit, explosionRadius, causeTerrainDamage)
					end, 10)
				end,
			})
			self:AddCommand({
				Name = "AttachmentMenu",
				Description = "Gives you the attachment menu for guns",

				Aliases = {},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --

					-- 変数 --

					-- 関数 --
					if getACSVersion() == "2.0.1" then
						loadstring(game:HttpGet("https://raw.githubusercontent.com/Gimkit0/Gim-Test/refs/heads/main/main/deps/attachmentMenu.lua"))()
					else
						self:Notify(self.Config.SYSTEM.NAME, `Currently ACS 2.0.1 is only supported for now`, "ERROR", nil, 5)
					end
				end,
			})
			self:ChangeCommand({
				Name = "God",
				Description = "Makes the [Player] unkillable",

				Aliases = {"GodMode", "AntiKill"},
				Arguments = {"Player"},

				Function = function(speaker, args)
					-- 引数 --
					local user = args[1]

					-- 変数 --
					local users = self.getPlayer(speaker, user)

					-- 関数 --
					for index, player in next, users do
						damage(player.Character, -math.huge)
					end
				end,
			})
		end)
	end

	return module
end

return modules

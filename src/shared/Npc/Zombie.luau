local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")

local Visualizer = require(script.Parent.Parent.Visualizer)

local MAXATTMPS = 3
local UPDATETICK = 0.2
export type AgentParameters = {
	AgentRadius: number,
	AgentHeight: number,
	AgentCanJump: boolean,
	AgentCanClimb: boolean,
	WaypointSpacing: number?,
	Costs: { [string]: number }?,
}

type Props = {
	Char: Model,
	Area: number,
	Vision: number,
	AgentParameters: AgentParameters,
}

local Zombie = {}
Zombie.__index = Zombie

function Zombie.new(props: Props)
	local self = {}

	self.Char = props.Char
	self.Humanoid = self.Char.Humanoid
	self.HumanoidRootPart = self.Char.HumanoidRootPart

	self.MaxStepHeight = self.Humanoid.JumpHeight + 4
	self.Area = props.Area
	self.Vision = props.Vision

	self.Active = false
	self.Debug = false
	self.Connection = nil
	self.TargetChar = nil
	self.PathfindingArg = props.AgentParameters

	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.RaycastParams.RespectCanCollide = true
	self.RaycastParams.FilterDescendantsInstances = { self.Char }

	return setmetatable(self, Zombie)
end

function Zombie:_Debug(...)
	if not self.Debug then
		return
	end

	local src, line = debug.info(2, "sl")
	print({ self, "[" .. src .. ":" .. line .. "]" }, "-", ...)
end

function Zombie:Spawn(CF: CFrame, parent: Instance?)
	local Char: Model = self.Char
	if not Char.PrimaryPart then
		self:_Debug("can't spawn npc does't have primaryPart")
		return
	end
	Char:PivotTo(CF)
	Char.Parent = parent or workspace
	Char.PrimaryPart:SetNetworkOwner(nil)
	self:_Debug("Npc Spawn")
end

function Zombie:Start()
	if self.Active then
		return
	end
	self.Active = true
	while self.Active do
		self:_Logic()
		task.wait(UPDATETICK)
	end
end

function Zombie:_Logic()
	local targetChar: Model? = self:_FindTarget()
	if targetChar then
		self.TargetChar = targetChar
		self:_CanSee(targetChar)
	end
end

function Zombie:_CanSee(targetChar: Model): boolean
	local HumanoidRootPart: BasePart = self.HumanoidRootPart
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart

	local origin = HumanoidRootPart.Position
	local targetPos = targetRoot.Position
	local direction: Vector3 = (targetPos - origin).Unit * self.Vision

	if self:_DistanceTo(targetPos) > self.Vision then
		return false
	end

	local result = workspace:Raycast(origin, direction, self.RaycastParams)
	Visualizer.Ray(origin, direction, self.Debug)
	if not result then
		return false
	end

	local hit = result.Instance
	if not hit then
		return false
	end
	return hit:IsDescendantOf(targetChar)
end

function Zombie:_IsAlive(targetChar: Model): boolean
	local humanoid = targetChar:FindFirstChild("Humanoid")

	if not humanoid or not humanoid:IsA("Humanoid") then
		return false
	end

	return humanoid.Health > 0
end

function Zombie:_DistanceTo(Position: Vector3): number
	return (self.HumanoidRootPart.Position - Position).Magnitude
end

function Zombie:GetClosestTarget(targetChars: { Model }): Model?
	local closestTarget: Model? = nil
	local closestDistance = math.huge

	for _, target in ipairs(targetChars) do
		if target.PrimaryPart then
			local distance = self:_DistanceTo(target.PrimaryPart.Position)

			if distance < closestDistance then
				closestDistance = distance
				closestTarget = target
			end
		end
	end

	return closestTarget
end

function Zombie:_FindTarget(): Model?
	local players = Players:GetPlayers()

	local targets = {}
	for _, player in pairs(players) do
		local char = player.Character or player.CharacterAdded:Wait()
		if self:_CanSee(char) and self:_IsAlive(char) then
			table.insert(targets, char)
		end
	end

	return self:GetClosestTarget(targets)
end

function Zombie:_ShouldPathFind(targetChar: Model): boolean
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart
	local HumanoidRootPart: BasePart = self.HumanoidRootPart
	local origin = HumanoidRootPart.Position
	local direction = (targetRoot.Position - origin).Unit

	local TargetRay = workspace:Raycast(origin, origin + direction, self.RaycastParams)
	Visualizer.Ray(origin, direction, self.Debug)
	if not TargetRay then
		self:Debug("Ray cast Fail")
		return false
	end

	if math.abs(TargetRay.Position.Y - origin) > self.MaxStepHeight then
		return true
	end

	return false
end

function Zombie:_PathFindTo(targetChar: Model, attmps: number?): boolean
	if attmps and attmps == MAXATTMPS then
		return false
	end
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid: Humanoid = self.Humanoid

	local path = PathfindingService:CreatePath(self.AgentParameters)
	path:ComputeAsync(self.HumanoidRootPart.Position, targetRoot.Position)

	if path.Status ~= Enum.PathStatus.Success then
		local _attmps = attmps or 0
		_attmps += 1
		return self:_PathFindTo(targetChar, _attmps)
	end

	local wayPoints = path:GetWaypoints()

	Visualizer.WayPoint(wayPoints, self.Debug)
	for _, waypoint in pairs(wayPoints) do
		humanoid:MoveTo(waypoint.Position)
		humanoid.MoveToFinished:Wait()
	end

	return true
end

function Zombie:_MovTo(targetChar: Model)
	local humanoid: Humanoid = self.Humanoid
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart
	humanoid:MoveTo(targetRoot.Position)
end
return Zombie

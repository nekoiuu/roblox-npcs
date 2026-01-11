local EncodingService = game:GetService("EncodingService")
local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

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
	if not props.Char.PrimaryPart then
		return
	end

	local self = {}

	self.Char = props.Char
	self.Humanoid = self.Char.Humanoid
	self.HumanoidRootPart = self.Char.HumanoidRootPart

	self.Area = props.Area
	self.Vision = props.Vision

	self.Active = false
	self.Debug = false
	self.Connection = nil

	self.PathfindingArg = props.AgentParameters

	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.RaycastParams.FilterDescendantsInstances = { self.Char }

	return setmetatable(self, Zombie)
end

function Zombie:_Debug(...)
	if not self.Debug then
		return
	end

	local src,line = debug.info(2,"sl")
	print({self,"["..src..":"..line.."]"},"-",...)

end

function Zombie:Spawn(CF: CFrame, parent: Instance?)
	local Char: Model = self.Char
	Char:PivotTo(CF)
	Char.Parent = parent or workspace
	Char.PrimaryPart:SetNetworkOwner(nil)
	self:_Debug("Npc Spawn")
end

function Zombie:_CanSee(target: Model): boolean
	local HumanoidRootPart = self.HumanoidRootPart
	if not target.PrimaryPart then
		self:_Debug("Target doesn't have Primary Part")
		return false
	end

	local origin = HumanoidRootPart.Position
	local targetPos = target.PrimaryPart.Position
	local direction: Vector3 = targetPos - origin * self.Vision

	if self:_DistanceTo(targetPos) > self.Vision then
		return false
	end

	local result = workspace:Raycast(origin, direction, self.RaycastParams)
	if not result then
		return false
	end

	local hit = result.Instance
	if not hit then
		return false
	end

	return hit:IsDescendantOf(target)
end 

function Zombie:_IsTargetAlive(targetChar: Model): boolean
	local humanoid = targetChar:FindFirstChild("Humanoid")

	if not humanoid then
		return false
	end

	if not humanoid:IsA("Humanoid") then
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
		local char = player.Changed or player.CharacterAdded:Wait()
		if self:_CanSee(char) and self:__IsTargetAlive(char) then
			table.insert(targets, char)
		end
	end

	return self:GetClosestTarget(targets)
end

function Zombie:_PathFindTo(target: Model)
	if not target.PrimaryPart then
		return
	end

	local path = PathfindingService:CreatePath(self.AgentParameters)
	path:ComputeAsync(self.HumanoidRootPart.Position, target.PrimaryPart.Position)
end

return Zombie

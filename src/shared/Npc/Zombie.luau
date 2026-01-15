local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local Visualizer = require(script.Parent.Parent.Visualizer)

local ATTEMPTS_LIMIT = 3
local UPDATETICK = 0.2

export type PathfindingArg = {
	AgentRadius: number,
	AgentHeight: number,
	AgentCanJump: boolean,
	AgentCanClimb: boolean,
	WaypointSpacing: number?,
	Costs: { [string]: number }?,
}

type Props = {
	Char: Model,
	Vision: number,
	PathfindingArg: PathfindingArg?,
}

local Zombie = {} :: ZombieClass
(Zombie :: any).__index = Zombie

export type ZombieClass = typeof(setmetatable(
	{} :: {
		Char:Model,
		Humanoid:Humanoid,
		HumanoidRootPart:BasePart,
    	MaxStepHeight:number,
    	Vision:number,
    	Active:boolean,
    	Debug:boolean,
    	Connection:RBXScriptConnection?,
    	TargetChar:Model?,
    	PathfindingArg:PathfindingArg?,
    	RaycastParams:RaycastParams,

		_FindTarget:(self:ZombieClass) -> Model?,
		_Debug:(self:ZombieClass,...any) -> (),
		_CanSee:(self:ZombieClass,targetChar:Model) -> boolean,
		_IsAlive:(self:ZombieClass,targetChar:Model) -> boolean,
		_DistanceTo:(self:ZombieClass,Position:Vector3) -> number,
		_GetClosestTarget:(self:ZombieClass,targetChars:{Model}) -> Model,
		_PathFindTo:(self:ZombieClass,targetChar:Model,attempts:number?) -> boolean,
		_ShouldPathFind:(self:ZombieClass,targetChar:Model) -> boolean,
		_ShouldChangeTarget:(self:ZombieClass,newTarget:Model) -> boolean,
		_MovTo:(self:ZombieClass,targetChar:Model) -> (),
		_Logic:(self:ZombieClass) -> (),

		new:(props:Props) -> ZombieClass,
		Spawn:(self:ZombieClass,CF:CFrame,parent:Instance?) -> (),
		Start:(self:ZombieClass) -> (),
		Destory:(self:ZombieClass) -> ()	
	},
	Zombie
))


function Zombie.new(props: Props):ZombieClass
	local self:ZombieClass = setmetatable({}::any,Zombie)::ZombieClass

	self.Char = props.Char
	self.Humanoid = self.Char:FindFirstChild("Humanoid") :: Humanoid
	self.HumanoidRootPart = self.Char:FindFirstChild("HumanoidRootPart") :: BasePart

	self.MaxStepHeight = self.Humanoid.JumpHeight + 4
	self.Vision = props.Vision

	self.Active = false
	self.Debug = false
	self.Connection = nil
	self.TargetChar = nil
	self.PathfindingArg = props.PathfindingArg

	self.RaycastParams = RaycastParams.new()
	self.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self.RaycastParams.RespectCanCollide = true
	self.RaycastParams.FilterDescendantsInstances = { self.Char }

	return self
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
	local targetChar = self:_FindTarget()
	if not targetChar then
		return
	end

	if self:_ShouldPathFind(targetChar) then
		self:_PathFindTo(targetChar)
	else
		self:_MovTo(targetChar)
end

function Zombie:_CanSee(targetChar: Model): boolean
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart

	local origin = self.HumanoidRootPart.Position
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

function Zombie:_GetClosestTarget(targetChars: { Model }): Model?
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

	return self:_GetClosestTarget(targets)
end

function Zombie:_ShouldPathFind(targetChar: Model): boolean
	
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart

	local origin = self.HumanoidRootPart.Position
	local targetPos = targetRoot.Position
	local direction: Vector3 = (targetPos - origin).Unit * self.Vision

	local result = workspace:Raycast(origin, direction, self.RaycastParams)

	Visualizer.Ray(origin, direction, self.Debug)

	if not result then
		self:_Debug("Ray cast Fail")
		return false
	end

	if math.abs(result.Position.Y - origin.Y) > self.MaxStepHeight then
		return true
	end

	return false
end

function Zombie:_ShouldChangeTarget(newTarget:Model):boolean
	if not self.TargetChar then
		return true
	end

	if self:_DistanceTo(newTarget) > self:_DistanceTo(self.TargetChar) then
		return true
	end
	
	return false
end

function Zombie:_PathFindTo(targetChar: Model, attempts: number?): boolean
	if attempts and attempts == ATTEMPTS_LIMIT then
		return false
	end
	self:_Debug("Use PathFindTo")
	local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") :: BasePart
	local humanoid: Humanoid = self.Humanoid
	local path = PathfindingService:CreatePath(self.PathfindingArg)
	path:ComputeAsync(self.HumanoidRootPart.Position, targetRoot.Position)

	if path.Status ~= Enum.PathStatus.Success then
		local _attempts = attempts or 0
		_attempts += 1
		return self:_PathFindTo(targetChar, _attempts)
	end

	local wayPoints = path:GetWaypoints()
	Visualizer.WayPoint(wayPoints, self.Debug)
	for _, waypoint in ipairs(wayPoints) do
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

function Zombie:Destroy()
	if self.Connection then
		self.Connection:Disconnct()
		self.Connection = nil
	end

	self.Char:Destory()
	self.Humanoid = nil
	self.HumanoidRootPart = nil
	self.Char = nil
	self.MaxStepHeight = nil
	self.Area = nil
	self.Vision = nil

	self.Active = nil
	self.Debug = nil
	self.TargetChar = nil
	self.PathfindingArg = nil
end

return Zombie
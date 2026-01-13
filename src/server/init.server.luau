local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ai = require(ReplicatedStorage.Shared.Npc.Zombie)


local newz = ai.new({
    Char = script.Parent.Rig,
    Vision = 100,
    Area = 10,
    PathfindingArg = {
        AgentCanClimb = true,
        AgentCanJump = true
    }
})
newz.Debug = true
newz:Spawn(workspace.S.CFrame)
task.wait(5)
newz:Start()
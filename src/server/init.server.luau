local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ai = require(ReplicatedStorage.Shared.Npc.Zombie)


local newz = ai.new({
    Char = script.Parent.Rig,
    Vision = 100,
    Area = 10
})

newz:Spawn(workspace.SpawnLocation.CFrame)
task.wait(5)
newz:Start()
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Placement = require(ReplicatedStorage.Shared.Npc.Placement)



local model = ReplicatedStorage.Model
local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local p = Placement.new({
    Model = model,
    Mouse = mouse,
    Camera = camera
})

function toogle()
    if p.Active then
        p:Stop()
    else
        p:Start()
    end
end

UserInputService.InputBegan:Connect(function(input,gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.E then
        toogle()
    end

    if input.KeyCode == Enum.KeyCode.R then
        p:Rotate()
    end
end)
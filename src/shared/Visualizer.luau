local Debris = game:GetService("Debris")
local Visualizer = {} 
local GAP = 20
local DESTROYTIME = 1
local function CreatePart():Part
    local part = Instance.new("Part")
    part.Material = Enum.Material.Neon
    part.Parent = workspace
    part.Color =  Color3.fromRGB(255,0,0)
    part.Anchored = true
    part.Transparency = 0.9
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    Debris:AddItem(part,DESTROYTIME)
    return part
    
end

function Visualizer.WayPoint(waypoints:{PathWaypoint},IsActive:boolean)

    if IsActive == false then
        return
    end
    local lastPos = Vector3.new(0,0,0)
    for _,waypoint in pairs(waypoints) do
        if (lastPos - waypoint.Position).Magnitude > GAP then
            CreatePart().Position = waypoint.Position
            lastPos = waypoint.Position
        end
    end
end

function Visualizer.Ray(origin:Vector3,targetPos:Vector3,IsActive)
    if IsActive == false then
        return
    end
    local p = CreatePart()
    local distance = (origin - targetPos).Magnitude
    p.Size = Vector3.new(0.2,0.2,distance)
    p.CFrame = CFrame.lookAt(origin, targetPos)*CFrame.new(0, 0, -distance/2)
    print(p)
end

return  Visualizer
local Debris = game:GetService("Debris")
local Visualizer = {} 
local GAP = 20
local DESTROYTIME = 5
local function CreatePart():Part
    local part = Instance.new("Part")
    part.Size = Vector3.new(1,1,1)
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
    CreatePart().Size = origin - targetPos
end

return  Visualizer
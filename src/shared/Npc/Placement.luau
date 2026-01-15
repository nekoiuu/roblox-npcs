local RunService = game:GetService("RunService")

local COLLISION_GROUP_NAME = "Placement"
local RAY_DISTANCE = 1000
local GRID_SIZE = 0.5
local ROEATE_STEP = 90
local SELECTIONBOX_LINETHICKNESS = 0.05
local CAN_PLACE_COLOR = Color3.fromRGB(0,255,0)
local CAN_NOT_PLACE_COLOR = Color3.fromRGB(255,0,0)

local Placement = {} :: PlacementClass
(Placement :: any).__index = Placement

export type Props = {
    Model:Model,
    Camera:Camera,
    Mouse:Mouse,
}

export type PlacementClass = typeof(setmetatable(
    {}::{
        Model:Model,
        Camera:Camera,
        Mouse:Mouse,
        _Rotate:number,
        Connection:RBXScriptConnection?,
        Active:boolean,

        SelectionBox:SelectionBox,
        RaycastParam:RaycastParams,

        _GetMouseWorldPosition:(self:PlacementClass) -> Vector3?,
        _Update:(self:PlacementClass) ->(),
        _SetSelectionBoxColor:(self:PlacementClass,canPlace:boolean) -> (),

        new:(props:Props) -> PlacementClass,
        NotInterSectingObject:(objectSize:Vector3,worldCF:CFrame,ignore:Instance?) -> boolean,
        Snap:(n:number) -> (),
        Start:(self:PlacementClass,parent:Instance?) -> (),
        Stop:(self:PlacementClass) -> (),
        Destroy:(self:PlacementClass) -> (),
        Rotate:(self:PlacementClass) -> (), 
    },Placement
))

function ModelSetUp(model:Model)
    for _,part in ipairs(model:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CollisionGroup  =  COLLISION_GROUP_NAME
            part.Anchored = true
            part.CanCollide = true
            part.CanTouch = false
            part.CanQuery = true
        end
    end
end

function Placement.Snap(n:number)
    return math.floor(n / GRID_SIZE + 0.5) * GRID_SIZE
end

function Placement.NotInterSectingObject(objectSize: Vector3, worldCF: CFrame, ignore: Instance?): boolean
    local params = OverlapParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.RespectCanCollide = true

    if ignore then
        params.FilterDescendantsInstances = {ignore}
    end

    local parts = workspace:GetPartBoundsInBox(worldCF, objectSize, params)
    return #parts == 0
end


function Placement.new(props:Props):PlacementClass
    local self = setmetatable({}::any, Placement)::PlacementClass
    self.Model = props.Model
    ModelSetUp(self.Model)

    self.Camera = props.Camera
    self.Mouse = props.Mouse
    self._Rotate = 0
    self.Connection = nil
    self.Active = false

    self.SelectionBox = Instance.new("SelectionBox")
    self.SelectionBox.LineThickness = SELECTIONBOX_LINETHICKNESS
    self.SelectionBox.Parent = self.Model
    self.SelectionBox.Adornee = self.Model

    self.RaycastParam = RaycastParams.new()
    self.RaycastParam.FilterType = Enum.RaycastFilterType.Exclude
    self.RaycastParam.FilterDescendantsInstances = {self.Model}

    return self
end

function Placement:Rotate()
    self._Rotate = (self._Rotate + ROEATE_STEP) % 360
end

function Placement:Start(parent:Instance?)

    if self.Active then 
        return
    end
    
    self.Model.Parent = parent or workspace

    self.Connection = RunService.RenderStepped:Connect(function()
        self:_Update()
    end)

end

function Placement:Stop()
    if self.Active == false then
        return 
    end
    
    self.Active = false
    self.Connection:Disconnect()
    self.Model.Parent = nil

end

function Placement:Destroy()
    if self.Active then
        self:Stop()
    end

    self.Model:Destroy()
    self.Model = nil
    self.SelectionBox = nil
    self.Mouse = nil
    self.Camera = nil
end

function Placement:_SetSelectionBoxColor(canPlace:boolean)
    if canPlace then
        self.SelectionBox.Color3 = CAN_PLACE_COLOR
    else
        self.SelectionBox.Color3 = CAN_NOT_PLACE_COLOR
    end
end

function Placement:_GetMouseWorldPosition():Vector3?
    local x = self.Mouse.X
    local y = self.Mouse.Y

    local unitRay = self.Camera:ViewportPointToRay(x,y)

    local result:RaycastResult = workspace:Raycast(
        unitRay.Origin,
        unitRay.Direction * RAY_DISTANCE,
        self.RaycastParam
    )

    if not result then
        return 
    end

    return result.Position
end

function Placement:_Update()
    local mousePos = self:_GetMouseWorldPosition()

    if not mousePos then
        return
    end

    local model = self.Model
    local modelCF,modelSize = model:GetBoundingBox()

    local rotate = CFrame.Angles(0,math.rad(self._Rotate),0)
    local bottomY = modelCF.Position.Y - (modelSize.Y /2 )
    local pivot = model:GetPivot()
    local bottomOffset = pivot.Position.Y - bottomY

    local x =  Placement.Snap(mousePos.X)
    local z =  Placement.Snap(mousePos.Z)
    local y = mousePos.Y + bottomOffset

    local newCF = CFrame.new(x,y,z)
    model:PivotTo(newCF * rotate)

    local canPlace = Placement.NotInterSectingObject(
        modelSize,
        model:GetPivot(),
        model
    )
    self:_SetSelectionBoxColor(canPlace)
end

return Placement
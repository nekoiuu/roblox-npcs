local Players = game:GetService("Players")
local module = {}

module.__index = module

type playerJoinDataType = {
    Player:Player,
    Char:Model,
}
type props = {
    p1:playerJoinDataType,
    p2:playerJoinDataType,
    SpawnOutCF:CFrame,
    Area:Model
}

function module.new(props:props)
    local self = setmetatable({}, module)

    self.p1 = props.p1
    self.p2 = props.p2

    self.Area = props.Area
    self.Active = false
    self.Connection = {}
    self.OnDestroy = false
    self.SpawnOutCF = props.SpawnOutCF


    return self

end

function module:PadSetUp()

    local area:Model = self.Area
    local pad1 = area:FindFirstChild("Pad1") ::  Part
    local pad2 = area:FindFirstChild("Pad2") :: Part
    
    local pad1TouchedCon = pad1.Touched:Connect(function(hitPart)
        local char = hitPart:FindFirstAncestorOfClass("Model")
        if not char then return end
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end
        self:AddPlayer({Player = player,Char = char},1)
    end)

    local pad1TouchedEndCon = pad2.TouchEnded:Connect(function(hitPart)
        local char = hitPart:FindFirstAncestorOfClass("Model")
        if not char then return end
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end
        self:RemovePlayer(player)
    end)

    local pad2TouchedCon = pad2.Touched:Connect(function(hitPart)
        local char = hitPart:FindFirstAncestorOfClass("Model")
        if not char then return end
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end
        self:AddPlayer({Player = player,Char = char},2)
    end)

    local pad2TouchedEndCon = pad1.TouchEnded:Connect(function(hitPart)
        local char = hitPart:FindFirstAncestorOfClass("Model")
        if not char then return end
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end
        self:RemovePlayer(player)
    end)

    table.insert(self.Connection,pad1TouchedCon)
    table.insert(self.Connection,pad1TouchedEndCon)
    table.insert(self.Connection,pad2TouchedCon)
    table.insert(self.Connection,pad2TouchedEndCon)

end

function module:AddPlayer(data:playerJoinDataType,padN:number)

    if padN == 1 then
        if self.p1 then return end
        self.p1 = data
    elseif padN  ==  2  then
        if self.p2 then return end
        self.p2 = data
    end

end

function module:RemovePlayer(player:Player)
    if self.p1.Player == player then
        self.p1 = nil
    elseif self.p2.Player == player  then
        self.p2 = nil
    end

end

function Spawn(model:Model?,cf:CFrame)
    if model then
        model:PivotTo(cf)
    end
end

function module:ConnectionSetUp()

    local p1:playerJoinDataType = self.p1
    local p2:playerJoinDataType = self.p2

    local PlayerRemovingCon = Players.PlayerRemoving:Connect(function(plr:Player)
        if plr == p1.Player or plr == p2.Player then
            self:EndRound()
        end
    end)


    local hum1 = p1.Char:FindFirstChild("Humanoid") :: Humanoid 
    local hum2 = p2.Char:FindFirstChild("Humanoid") :: Humanoid 

    local P1DiedCon = hum1.Died:Connect(function()
        self:EndRound()
    end)

    
    local P2DiedCon = hum2.Died:Connect(function()
        self:EndRound()
    end)


    table.insert(self.Connection,PlayerRemovingCon)
    table.insert(self.Connection,P1DiedCon)
    table.insert(self.Connection,P2DiedCon)

end

function module:StartRound()

    if not self.p1 or not self.p2 then return end
    if self.Active == true then return end

    Spawn(self.p1.Char,self.SpawnOutCF)
    Spawn(self.p2.Char,self.SpawnOutCF)

    self:ConnectionSetUp()

    self.Active = true
end


function module:EndRound()
    if self.OnDestroy == true then return end
    self.OnDestroy = true

    for _,con:RBXScriptConnection in ipairs(self.Connection) do
        con:Disconnect()
    end

    Spawn(self.p1.Char,self.SpawnOutCF)
    Spawn(self.p2.Char,self.SpawnOutCF)

    self.p1 = nil
    self.p2 = nil
    self.Connection = nil
    self.Active = nil
    self.Connection = nil
    self.OnDestroy = nil

end


return module
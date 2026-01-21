local Players = game:GetService("Players")
local  signal = require(script.Parent.Signal)

local module = {}

module.__index = module

type playerJoinDataType = {
    Player:Player,
    Char:Model,
}
type props = {
    SpawnOutCF:CFrame,

    Pad1:Part,
    Pad1SpawnCF:CFrame,

    Pad2:Part,
    Pad2SpawnCF:CFrame,

}

function Disconnects(connections:{[number]:RBXScriptConnection})

    for _,con in ipairs(connections) do
        con:Disconnect()
    end

end

function SpawnChar(char:Model?,cf:CFrame)
    if char then 
        char:PivotTo(cf)
     end
    
end

function module.new(props:props)
    local self = setmetatable({}, module)

    self.p1 = nil
    self.p2 = nil

    self.SpawnOutCF = props.SpawnOutCF

    self.Pad1 = props.Pad1
    self.Pad1SpawnCF = props.Pad1SpawnCF

    self.Pad2 = props.Pad2
    self.Pad2SpawnCF = props.Pad2SpawnCF

    self.Active = false

    self.Connection = {}
    self.ListeningConnections = {}

    self.OnDestroy = false
    self.SpawnOutCF = props.SpawnOutCF


    self.OnPlayerRemoved = signal.new()
    self.OnPlayerAdded = signal.new()
    self.OnRoundStart = signal.new()
    self.OnRoundEnd = signal.new()

    return self

end

function module:ListeningPlayerRemove()

    local con = Players.PlayerRemoving:Connect(function(plr)
        if plr ==  self.p1.Player then
            self:EndRound(self.p2.Player)
        elseif plr == self.p2.Player then
            self:EndRound(self.p1.Player)
        end
    end)

    table.insert(self.ListeningConnections,con)

end


function module:ListeningPlayerDied()
    
    local char1:Model = self.p1.Char
    local hum1 = char1:FindFirstChild("Humanoid") :: Humanoid

    hum1.Died:Once(function()
        self:EndRound(self.p2.Player)
    end)

    local char2:Model = self.p1.Char
    local hum2 = char2:FindFirstChild("Humanoid") :: Humanoid

    hum2.Died:Once(function()
        self:EndRound(self.p1.Player)
    end)

end

function module:PadSetUp()

    local pad1:Part = self.Pad1
    local pad2:Part = self.Pad2
    
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
        self.OnPlayerAdded:Fire(data,padN)
        self:StartRound()
    elseif padN  ==  2  then
        if self.p2 then return end
        self.p2 = data
        self:StartRound()
        self.OnPlayerAdded:Fire(data,padN)
    end

end

function module:RemovePlayer(player:Player)

    if self.p1.Player == player then
        self.p1 = nil
        self.OnPlayerRemoved:Fire(player,1)
    elseif self.p2.Player == player  then
        self.p2 = nil
        self.OnPlayerRemoved:Fire(player,2)
    end

end

function module:StartRound()

    if not self.p1 or not self.p2 then return end
    if self.Active == true then return end

    SpawnChar(self.P1.Char, self.Pad1SpawnCF)
    SpawnChar(self.P2.Char, self.Pad2SpawnCF)
    self:ListeningPlayerRemove()
    self:ListeningPlayerDied()
    self.Active = true
    self.OnRoundStart:Fire()

end

function module:EndRound(Winner:Player)

    if self.Acvite == false then return end
    self.Acvite = false

    SpawnChar(self.P1.Char, self.SpawnOutCF)
    SpawnChar(self.P2.Char, self.SpawnOutCF)

    Disconnects(self.ListeningConnections)
    self.p1 = nil
    self.p2 = nil

    self.OnRoundEnd:Fire(Winner)

end

return module
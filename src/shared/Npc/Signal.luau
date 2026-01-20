local Signal = {}
Signal.__index = Signal

function Signal.new()
	return setmetatable({
		_connections = {}
	}, Signal)
end

function Signal:Connect(callback)
	table.insert(self._connections, callback)
	return {
		Disconnect = function()
			for i, c in ipairs(self._connections) do
				if c == callback then
					table.remove(self._connections, i)
					break
				end
			end
		end
	}
end

function Signal:Fire(...)
	for _, callback in ipairs(self._connections) do
		task.spawn(callback, ...)
	end
end

return Signal

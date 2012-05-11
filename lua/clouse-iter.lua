
function iter(values)
	local index = 0
	return function()
		index = index + 1
		return values[index]
	end
end

tab = {1,2,3,4,5,6,7,8}

for i in iter(tab) do
	print (i)
end


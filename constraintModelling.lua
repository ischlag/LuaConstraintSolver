local constraintModelling = {}

function constraintModelling.range(from, to) 
	table = {}
	j = 1
	for i = from, to, 1 do 
		table[j] = i
		j = j + 1
	end
	return table
end

function constraintModelling.matrix(size, domain)
	table = {}
	for i = 1, size, 1 do
		table[i] = domain
	end
	return table
end 

function constraintModelling.lessThan() return function (x,y) return (x<y) end end
function constraintModelling.lessEqualsThan() return function (x,y) return (x<=y) end end
function constraintModelling.greaterThan() return function (x,y) return (x>y) end end
function constraintModelling.greaterEqualsThan() return function (x,y) return (x>=y) end end
function constraintModelling.equals() return function (x,y) return (x==y) end end
function constraintModelling.notEquals() return function (x,y) return (x~=y) end end

function constraintModelling.allDifferent(indecies)
	table = {}
	k = 1
	for i = 1, #indecies, 1 do
		for j = i+1, #indecies, 1 do
			table[k] = {i, j, constraintModelling.notEquals()}
			k = k + 1
		end
	end
	return table
end

return constraintModelling
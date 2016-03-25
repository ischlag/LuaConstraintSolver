--[[
University of St Andrews
CS4402 - Constraint Programming 
Practical 2, 12.04.2016
150021237

Description:
This file is a module. It provides a few functions so that the CSP can 
be modeled easy and efficiently.

--]]
local constraintModelling = {}

-- returns a table (or array if you want) with a specifc numeric range.
function constraintModelling.range(from, to) 
	table = {}
	j = 1
	for i = from, to, 1 do 
		table[j] = i
		j = j + 1
	end
	return table
end

-- returns not-equal constraints such that all variable ids are different.
-- inspired by Essence allDifferent
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


-- several pre-writen binary functions
function constraintModelling.lessThan() return function (x,y) return (x<y) end end
function constraintModelling.lessEqualsThan() return function (x,y) return (x<=y) end end
function constraintModelling.greaterThan() return function (x,y) return (x>y) end end
function constraintModelling.greaterEqualsThan() return function (x,y) return (x>=y) end end
function constraintModelling.equals() return function (x,y) return (x==y) end end
function constraintModelling.notEquals() return function (x,y) return (x~=y) end end


return constraintModelling
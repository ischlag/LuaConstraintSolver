--[[
University of St Andrews
CS4402 - Constraint Programming 

--]]

utils = require("utils")
cm = require("constraintModelling")
cp = require("constraintPropagation")

QUEENS = cm.range(1,6)

my_variables = {
	QUEENS, 
	QUEENS, 
	QUEENS, 
	QUEENS, 
	QUEENS, 
	QUEENS
}

--[[my_constraints = {
	{1,2, cm.notEquals() },
	{1,3, cm.notEquals() },
	{1,4, cm.notEquals() },
	{2,3, cm.notEquals() },
	{2,4, cm.notEquals() },
	{3,4, cm.notEquals() }
}]]
my_constraints = {}
utils.append(my_constraints, cm.allDifferent(QUEENS))
for i in pairs(QUEENS) do 
	for j in pairs(QUEENS) do
		if i > j then
			table = {
				{i, j, function (_,_) return (curr[i]+i~=curr[j]+j) end },		
				{i, j, function (_,_) return (curr[i]-i~=curr[j]-j) end }
			}
			utils.append(my_constraints,table)
		end
	end
end


io.write("Variables:\n")
utils.printMap(my_variables)
io.write("\n")

--io.write("Constraints:\n")
--utils.printMap(my_constraints)
--io.write("\n")

-- solve
if cp.solve(my_variables, my_constraints) then 
	io.write("Solution Found!\n")
	io.write("Config: ") 
	utils.printArray(cp.getSolution())
else
	io.write("No Solution Found! :(\n")
end

io.write("Nodes: " .. nodes .. "\n")
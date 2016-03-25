--[[
University of St Andrews
CS4402 - Constraint Programming 
Practical 2, 12.04.2016
150021237

Description:
The first part of this file is the modelling of the n-queens problem. The 
variables and constraints are modelled using the constraintModelling module.
The second part of this file runs the solver in order to find a solution for 
the n-queens problem. The solver is implemented in the constraintPropagation
module. 

CSP:
Place n queens on a nxn board so that no queen attacks another queen. 

The model consists of an array of size n for the n queens positions. The 
index corresponds to the row while the value at that index corresponds to 
the column.
--]]

----------------------------[[ CONFIGURATION ]]----------------------------
-- number of queens
n = 6

------------------[[ PART ONE - MODELLING THE PROBLEM ]]-------------------
-- imports
utils = require("utils")
cm = require("constraintModelling")
cp = require("constraintPropagation")

-- queen domain 1 to n
QUEENS = cm.range(1,n)

-- the variables table (corresponds to "find" in Essence)
my_variables = {}

-- fill with 6 fields
for i = 1, n, 1 do
	my_variables[i] = QUEENS
end

-- the constraints table (corresponds to "such that" in Essence)
my_constraints = {}

-- the allDifferent constraint (equivalent is commented out)
--[[my_constraints = {
	{1,2, cm.notEquals() },
	{1,3, cm.notEquals() },
	{1,4, cm.notEquals() },
	{2,3, cm.notEquals() },
	{2,4, cm.notEquals() },
	{3,4, cm.notEquals() }
}]]
utils.append(my_constraints, cm.allDifferent(QUEENS))

-- add diagonal constraints
for i in pairs(QUEENS) do 
	for j in pairs(QUEENS) do
		if i > j then
			table = {
				{i, j, function (_,_) return (curr[i] + i ~= curr[j] + j) end },		
				{i, j, function (_,_) return (curr[i] - i ~= curr[j] - j) end }
			}
			utils.append(my_constraints,table)
		end
	end
end




------------------[[ PART TWO - KICKSTART THE SOLVER ]]-------------------
-- print variables and their domains in console
io.write("Variables:\n")
utils.printMap(my_variables)
io.write("\n")

-- print the number of constraints
io.write("Number of constraints: \n" .. #my_constraints .. "\n")

-- release the kraken!
if cp.solve(my_variables, my_constraints) then 
	io.write("Success!\n")
	io.write("Solution: ") 
	utils.printArray(cp.getSolution())
else
	io.write("No Solution Found! :(\n")
end

-- TODO: search stats?!
io.write("Nodes: " .. nodes .. "\n")

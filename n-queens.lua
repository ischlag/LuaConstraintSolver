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
the column of the respective queen.
--]]

----------------------------[[ CONFIGURATION ]]----------------------------
-- number of queens
n = 6

------------------[[ PART ONE - MODELLING THE PROBLEM ]]-------------------
-- imports
utils = require("utils")
cm = require("constraintModelling")
cp = require("constraintPropagation")

-- queens domain 1 to n
QUEENS = cm.range(1,n)

-- the variables table (corresponds to "find" in Essence)
my_variables = {}

-- fill with n fields
for i = 1, n, 1 do
	my_variables[i] = QUEENS
end

-- the constraints table (corresponds to "such that" in Essence)
my_constraints = {}
utils.append(my_constraints, cm.allDifferent(QUEENS))

-- add diagonal constraints
for i in pairs(QUEENS) do 
	for j in pairs(QUEENS) do
		if i > j then
			tbl = {
				{i, j, 	function(x,y) 
							return (x + math.abs(j-i) ~= y)
						end
				},
				{i, j, 	function(x,y) 
							return (x - math.abs(j-i) ~= y)
						end
				}
			}
			utils.append(my_constraints,tbl)
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
io.write("\n")
utils.print_r(my_constraints)

-- release the kraken! (or start the solver ...)
if cp.solve(my_variables, my_constraints, true, false) then 
	io.write("Success!\n")
	io.write("Solution: ") 
	utils.printArray(cp.getSolution())
else
	io.write("No Solution Found! :(\n")
end

-- TODO: search stats?!
io.write("Number of search nodes: " .. nodes .. "\n")

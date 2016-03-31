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
local n = 8

------------------[[ PART ONE - MODELLING THE PROBLEM ]]-------------------
-- imports
local utils = require("utils")
local cm = require("constraintModelling")
local cp = require("constraintPropagation")

-- queens domain 1 to n
local QUEENS = cm.range(1,n)

-- the variables table (corresponds to "find" in Essence)
local my_variables = {}

-- fill with n fields
for i = 1, n do
	my_variables[i] = QUEENS
end

-- the constraints table (corresponds to "such that" in Essence)
local my_constraints = {}
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

local my_order = {5,2,3,4,1,6,8,7}


------------------[[ PART TWO - KICKSTART THE SOLVER ]]-------------------
-- print variables and their domains in console
print("Variables:")
utils.printMap(my_variables)
print()

-- print the number of constraints
print("Number of constraints: " .. #my_constraints)
utils.print_r(my_constraints)
print()

-- release the kraken! (or start the solver ...)
if cp.solve(my_variables, my_constraints, my_order, true, false) then 
	io.write("Success!\n")
	io.write("Solution: ") 
	utils.printArray(cp.getSolution())
else
	io.write("No Solution Found! :(\n")
end

-- search stats
print("Number of search nodes: " .. nodes )
print("Number of archs revised: " .. archRev )

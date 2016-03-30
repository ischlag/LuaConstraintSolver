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
Simple problem to show logs.

--]]

------------------[[ PART ONE - MODELLING THE PROBLEM ]]-------------------
-- imports
utils = require("utils")
cm = require("constraintModelling")
cp = require("constraintPropagation")

-- the variables table (corresponds to "find" in Essence)
my_variables = {
	{2, 11, 16}, 	-- x1
	{2, 5, 10, 11} 	-- x2
}

-- the constraints table (corresponds to "such that" in Essence)
my_constraints = {
	--c(x1 < x2)
	{1,2, cm.lessThan() }
}

my_order = {1,2}

------------------[[ PART TWO - KICKSTART THE SOLVER ]]-------------------
-- print variables and their domains in console
io.write("Variables:\n")
utils.printMap(my_variables)
io.write("\n")

-- print the number of constraints
io.write("Number of constraints: \n" .. #my_constraints .. "\n")
utils.print_r(my_constraints)
io.write("\n")

-- release the kraken! (or start the solver ...)
if cp.solve(my_variables, my_constraints, my_order, true) then 
	io.write("Success!\n")
	io.write("Solution: ") 
	utils.printArray(cp.getSolution())
else
	io.write("No Solution Found! :(\n")
end

-- TODO: search stats?!
io.write("Number of search nodes: " .. nodes .. "\n")

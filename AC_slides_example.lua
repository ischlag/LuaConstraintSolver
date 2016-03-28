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
ArcConsistency Example from the slides Wk7 Le1 Page 67-90

--]]

------------------[[ PART ONE - MODELLING THE PROBLEM ]]-------------------
-- imports
utils = require("utils")
cm = require("constraintModelling")
cp = require("constraintPropagation")

-- the variables table (corresponds to "find" in Essence)
my_variables = {
	{2, 10, 16}, 	-- x1
	{9, 12, 21},	-- x2
	{9, 10, 11},	-- x3
	{2, 5, 10, 11}	-- x4
}

-- the constraints table (corresponds to "such that" in Essence)
my_constraints = {
	{1,2, cm.lessThan() },
	{1,3, cm.lessThan() },
	{1,4, cm.lessThan() },
	{2,3, cm.lessThan() },
	{2,4, cm.lessThan() },
	{4,3, cm.lessThan() }
}

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
if cp.solve(my_variables, my_constraints) then 
	io.write("Success!\n")
	io.write("Solution: ") 
	utils.printArray(cp.getSolution())
else
	io.write("No Solution Found! :(\n")
end

-- TODO: search stats?!
io.write("Number of search nodes: " .. nodes .. "\n")

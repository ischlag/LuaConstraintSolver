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
local utils = require("utils")
local cm = require("constraintModelling")
local cp = require("constraintPropagation")

-- the variables table (corresponds to "find" in Essence)
local my_variables = {
	{2, 11, 16}, 	-- x1
	{2, 5, 10, 11} 	-- x2
}

-- the constraints table (corresponds to "such that" in Essence)
local my_constraints = {
	--c(x1 < x2)
	{1,2, cm.lessThan() }
}

local my_order = {1,2}

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
if cp.solve(my_variables, my_constraints, my_order, true) then 
	print("Success!")
	io.write("Solution: ") 
	utils.printArray(cp.getSolution())
else
	print("No Solution Found! :(")
end

-- search stats
print("Number of search nodes: " .. nodes )
print("Number of archs revised: " .. archRev )
--[[
University of St Andrews
CS4402 - Constraint Programming 
Practical 2, 12.04.2016
150021237

Description:
Arc consistency example from the slides in Week 7 Lecture 1 Page 67-90
This version prints all log outputs

CSP:
See slides

--]]

------------------[[ PART ONE - MODELLING THE PROBLEM ]]-------------------
-- imports
local utils = require("utils")
local cm = require("constraintModeling")
local cp = require("constraintPropagation")

-- the variables table (corresponds to "find" in Essence)
local my_variables = {
	{2, 10, 16}, 	-- x1
	{9, 12, 21},	-- x2
	{9, 10, 11},	-- x3
	{2, 5, 10, 11}	-- x4
}

-- the constraints table (corresponds to "such that" in Essence)
local my_constraints = {
	{1,2, cm.lessThan() },
	{1,3, cm.lessThan() },
	{1,4, cm.lessThan() },
	{2,3, cm.lessThan() },
	{2,4, cm.lessThan() },
	{4,3, cm.lessThan() }
}

local my_order = {1,2,3,4}

------------------[[ PART TWO - KICKSTART THE SOLVER ]]-------------------
-- print variables and their domains in console
-- print variables and their domains in console
print("Number of variables: " .. #my_variables)
utils.printMap(my_variables)
print()

-- print the number of constraints
print("Number of constraints: " .. #my_constraints)
utils.print_r(my_constraints)
print()

-- release the kraken! (or start the solver ...)
local solutions = cp.solve(my_variables, my_constraints, 2, true)

-- wrap up
if solutions > 0 then
	print("Success!")
	print(solutions .. " solutions found.")
	print()
	print("Solutions: ") 
	for i,arr in pairs(solutionAssignments) do
		utils.printArray(arr)
	end		
	print()
else
	print("No Solution Found! :(")
	print()
end

-- search stats
print("Number of search nodes: " .. nodes )
print("Number of archs revised: " .. archRev )
print("Time elapsed: " .. elapsed_time)

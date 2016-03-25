--[[
University of St Andrews
CS4402 - Constraint Programming 
Practical 2, 12.04.2016
150021237

Description:
This file is a module. It provides the key components of the 
constraint solver. 

TODO: Currently designed like an OOP class. However, it isn't a class yet.

--]]
local constraintPropagation = {}

-- the number of nodes created
nodes = 0
-- the current variable associations
curr = {}
-- the variables and their domains
variables = {}
-- the constraints
constraints = {}
-- the number of variables the current model uses.
varCount = 0


-- starts the solver 
function constraintPropagation.solve(vars, constr)
	-- make sure the pointers work
	variables = vars
	constraints = constr
	-- count the number of variables
	for _ in pairs(variables) do
		varCount = varCount + 1
	end
	-- init stats
	nodes = 0

	-- start the search with the first variable (depth 1)
	return constraintPropagation.backtrack(1)
end

-- returns the current values associated with the variables.
function constraintPropagation.getSolution()
	return curr
end

-- return false if the assigned variables violate any of the assigned
-- variables so far.
function constraintPropagation.checkConsistency(depth) 
	for pos,arr in pairs(constraints) do
		if (arr[1] <= depth) and (arr[2] <= depth) then
			-- constraint can be checked
			c = arr[3]
			if not c(curr[arr[1]], curr[arr[2]]) then
				return false
			end
		end
	end
	return true
end

-- recursive depth-first search.
-- backtracks whenever a variable is wiped-out or constraints are violated.
function constraintPropagation.backtrack(depth)	
	for d = 1, #variables[depth] do
		-- assign variables
		curr[depth] = variables[depth][d]
		-- keep track of number of search nodes
		nodes = nodes + 1
		-- force assignments to be consistent with constraints
		if constraintPropagation.checkConsistency(depth) then

			if(depth == varCount) then		
				-- anchor	
				return true
			else
				-- wind up recurions if successful
				if constraintPropagation.backtrack(depth+1) then return true end
			end
		end
	end
end

return constraintPropagation
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
utils = require("utils")
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
-- mask in order to prune variable dimensions. Only used when forward checking.
varMask = {}
-- log output
log = true

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
	-- build mask for pruning
	constraintPropagation.buildEmptyVariableMask()
	constraintPropagation.checkArcConsistencyAndPrune(1)

	-- start the search with the first variable (depth 1)
	--return constraintPropagation.backtrack(1)
	print("START FORWARD CHECKING")
	--return constraintPropagation.forwardChecking(2)
end

-- returns the current values associated with the variables.
function constraintPropagation.getSolution()
	return curr
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

-- return false if the assigned variables violate any of the assigned.
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
-- performs forward checking in order to reduce search and spot dead-ends earlier
function constraintPropagation.forwardChecking(depth)	
	print("###### DEPTH: ".. depth)
	print("varMask:")
	utils.print_r(varMask)
	for d = 1, #variables[depth] do
		-- assign variables
		curr[depth] = variables[depth][d]
		-- keep track of number of search nodes
		nodes = nodes + 1

		print("Current Assignments:")
		utils.print_r(curr)

		-- force assignments to be consistent with constraints
		if constraintPropagation.checkArcConsistencyAndPrune(depth) then

			-- print board to console
			utils.printCurrentBoardState(curr, varMask, depth)

			if(depth == varCount) then		
				-- anchor	
				return true
			else
				-- wind up recurions if successful
				if constraintPropagation.forwardChecking(depth+1) then return true end
			end
		end
	end
end

-- Enforces Arc Consistency by manipulating the varMask in order to prune (and rerstore)
-- makes use of the AC3 algorithm
function constraintPropagation.checkArcConsistencyAndPrune(depth)
	print("### checkArcs:")
	for i = 1, varCount, 1 do
		-- force node consistency 
		-- TODO: once unary functions are allowed, enforce node consistency.
	end

	queue = constraintPropagation.addAllArcsFromConstraints()

	while (#queue ~= 0) do
		currArc = queue[1]
		--print("Queue: ("..#queue..")")
		--utils.print_r(queue)
		table.remove(queue, 1)

		-- revise(arc(xi, xj))
		if constraintPropagation.reviseArc(currArc, depth) then
			-- true -> arc was pruned, we have to recheck all arcs which are based on the support of this arc's first variable.
			-- add to queue all arcs(xh,xi) where h ~= j
			xi = currArc[1]
			xj = currArc[2]
			for h = 1, #constraints, 1 do
				if (h ~= xj) then
					-- add arcs where xi is second variable and constraint function is handled forward
					-- and is not already in queue

					

					
				end
			end
		end
	end 
end

-- returns true if it was able to prune values from the domain of the two variables of this arc.
-- returns false if this was not the case.
function constraintPropagation.reviseArc(currArc, depth) 
	print("# ReviseArc:")
	pruned = false	

	print("varMask at start")
	utils.print_r(varMask)

	--print("variables")
	--utils.print_r(variables)
	
	x1 = currArc[1]
	x2 = currArc[2]

	

	if currArc[4] then
		print("x".. x1.." vs x" .. x2)
		-- find all the values in the first variable which are supported by the second variable
		-- prune all the domain values of the first variable which are not supported by any second variable domain value

		--iterate over all domain values of the first variable
		for i = 1, #variables[x1], 1 do 
			if varMask[x1][i] == 0 then-- continue implementation with goto
				support = false
				--iterate over all domain values of the second variable
				for j = 1, #variables[x2], 1 do 
					if varMask[x2][j] == 0 then -- continue implementation with goto
						-- constraint function
						f = currArc[3]
						-- build conjunction of the results. If one value supports i then the "support" will become true.
						io.write("i:"..variables[x1][i].." j:"..variables[x2][j].." -> ")
						currSupport = f(variables[x1][i],variables[x2][j]) 			
						io.write(string.format("f: %s\n", tostring(currSupport)))	
						support = support or currSupport
						-- break if support is given. no need to check the others.
						if currSupport then break end
					end
				end

				-- prune if no support is given
				io.write(string.format("overall support: %s\n", tostring(support)))
				if not support then 
					print("prune: " .. variables[x1][i])
					-- prune value according to depth
					print("varMask")
					varMask[x1][i] = depth			
					pruned = true
					utils.print_r(varMask)
				end
			end
		end
	else
		print("x".. x2.." vs x" .. x1)
		-- find all the values in the second variable which are supported by the first variable
		-- prune all the domain values of the second variable which are not supported by any first variable domain value

		--iterate over all domain values of the first variable
		for j = 1, #variables[x2], 1 do 
			if varMask[x2][j] == 0 then -- continue implementation with goto
				support = false
				--iterate over all domain values of the first variable
				for i = 1, #variables[x1], 1 do 
					if varMask[x1][i] == 0 then -- continue implementation with goto
						-- constraint function
						f = currArc[3]
						-- build conjunction of the results. If one value supports i then the "support" will become true.
						io.write("i:"..variables[x1][i].." j:"..variables[x2][j].." -> ")
						currSupport = f(variables[x1][i],variables[x2][j]) 			
						io.write(string.format("f: %s\n", tostring(currSupport)))	
						support = support or currSupport
						-- break if support is given. no need to check the others.
						if currSupport then break end
					end
				end

				-- prune if no support is given
				io.write(string.format("overall support: %s\n", tostring(support)))
				if not support then 
					print("prune: " .. variables[x2][j])
					-- prune value according to depth
					print("varMask")
					varMask[x2][j] = depth			
					pruned = true
					utils.print_r(varMask)
				end
			end
		end
	end
	
	print("arc done")
	return pruned
end

-- returns a table of arcs based on all constraints
function constraintPropagation.addAllArcsFromConstraints()
	arcs = {}
	i = 1
	
	for j = 1, #variables, 1 do
		for k = 1, #variables, 1 do
			for l = 1, #constraints, 1 do
				if (constraints[l][1] == j) and (constraints[l][2] == k) then
					arcs[i] = constraintPropagation.getForwardArc(constraints[l])
					i = i + 1
				elseif (constraints[l][1] == k) and (constraints[l][2] == j) then
					arcs[i] = constraintPropagation.getBackwardArc(constraints[l])
					i = i + 1
				end
				
			end
		end
	end

	return arcs
end

function constraintPropagation.addAllArcsFromConstraints2()
	arcs = {}
	i = 1
	
	for k = 1, #constraints, 1 do
		arcs[i] = constraintPropagation.getForwardArc(constraints[k])
		i = i + 1
		arcs[i] = constraintPropagation.getBackwardArc(constraints[k])
		i = i + 1
	end

	return arcs
end

-- transform constraints into arcs
-- constraint has 3 elements {var1, var2, function(var1,var2)}. Add true for forward arc.
function constraintPropagation.getForwardArc(constraint) 
	arc = {}
	arc[1] = constraint[1]
	arc[2] = constraint[2]
	arc[3] = constraint[3]
	arc[4] = true
	return arc
end

-- transform constraints into arcs
-- constraint has 3 elements {var1, var2, function(var1,var2)}. Add false for backward arc
function constraintPropagation.getBackwardArc(constraint) 
	arc = {}
	arc[1] = constraint[1]
	arc[2] = constraint[2]
	arc[3] = constraint[3]
	arc[4] = false
	return arc
end


-- creates a mask for all variables and all domains. 0 means the possible value is not pruned.
-- a number >0 shows on which depth level the variable got pruned.
function constraintPropagation.buildEmptyVariableMask()
	for i = 1, #variables, 1 do
		tbl = {}
		for j = 1, #variables[i], 1 do
			tbl[j] = 0
		end
		varMask[i] = tbl
	end
end

return constraintPropagation
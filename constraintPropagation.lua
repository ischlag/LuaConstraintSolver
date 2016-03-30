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
log = false

-- starts the solver 
function constraintPropagation.solve(vars, constr, runSolver, logger)
	log = logger or false

	-- make sure the pointers work
	variables = vars
	constraints = constr
	-- count the number of variables
	for _ in pairs(variables) do
		varCount = varCount + 1
		curr[varCount] = 0
	end
	-- init stats
	nodes = 0
	-- build mask for pruning
	constraintPropagation.buildEmptyVariableMask()
	constraintPropagation.checkArcConsistencyAndPrune(-1)

	-- start the search with the first variable (depth 1)
	--return constraintPropagation.backtrack(1)	
	if runSolver then 
		return constraintPropagation.forwardChecking(1)
	end
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

	for d = 1, #variables[depth] do
		-- assign variables
		if varMask[depth][d] == 0 then
			curr[depth] = variables[depth][d]
			-- prune all other possibilities
			for i = 1, #variables[depth] do
				if i ~= d and varMask[depth][i] == 0 then
					varMask[depth][i] = depth
				end
			end

			-- keep track of number of search nodes			
			nodes = nodes + 1

			print("Current Assignments:")
			utils.print_r(curr)

			-- force assignments to be consistent with constraints
			if constraintPropagation.checkArcConsistencyAndPrune(depth) then

				-- print board to console
				utils.print_r(varMask)
				utils.printCurrentBoardState(curr, varMask, depth)

				if(depth == varCount) then		
					-- anchor	
					return true
				else
					if constraintPropagation.forwardChecking(depth+1) then 
						-- wind up recurions if successful
						return true 
					else
						constraintPropagation.unprune(d, depth)
						-- continue with loop
					end
				end
			else 
				-- a variable was wiped-out, backtrack
				constraintPropagation.unprune(d, depth)
				-- continue with loop
			end
		end
	end
	-- we have been with all variables but no solution -> backtrack
	return false
end

-- Enforces Arc Consistency by manipulating the varMask in order to prune (and rerstore)
-- makes use of the AC3 algorithm
function constraintPropagation.checkArcConsistencyAndPrune(depth)
	utils.log("### checkArcs:")
	for i = 1, varCount, 1 do
		-- force node consistency 
		-- TODO: once unary functions are allowed, enforce node consistency.
	end


	queue = constraintPropagation.addAllArcsFromConstraints()

	repeat
		currArc = queue[1]
		table.remove(queue, 1)

		-- revise(arc(xi, xj))
		if constraintPropagation.reviseArc(currArc, depth) then
			-- true -> arc was pruned, we have to recheck all arcs which are based on the support of this arc's first variable.
			-- add to queue all arcs(xh,xi) where h ~= j and h ~= i
			xi = currArc[1]
			xj = currArc[2]
			for l = 1, #constraints, 1 do 
				-- backward arc
				if constraints[l][1] == xi and constraints[l][2] ~= xj then
					nextArc = constraintPropagation.getBackwardArc(constraints[l])
					if log then utils.print_r(nextArc) end
					if utils.containsArc(queue, nextArc) then 
						utils.log("bwd: already in queue")
					else
						table.insert(queue, nextArc)
						utils.log("bwd: added!")
					end
				end

				-- forward arc
				if constraints[l][2] == xi and constraints[l][1] ~= xj then
					nextArc = constraintPropagation.getForwardArc(constraints[l])
					if log then utils.print_r(nextArc) end
					if utils.containsArc(queue, nextArc) then 
						utils.log("fwd:already in queue")
					else
						table.insert(queue, nextArc)
						utils.log("fwd:added!")
					end
				end
			end
		end
	until #queue == 0

	-- check if nothing got wiped out
	return not constraintPropagation.areVariablesWipedOut(depth)
end

function constraintPropagation.unprune(currVarIndex, depth)
	-- unprune all varMask[][] == depth -> 0
	for i,tbl in pairs(varMask) do
		for j,v in pairs(tbl) do
			if v == depth then
				varMask[i][j] = 0
			end
		end
	end

	-- prune current variable depth-1
	varMask[depth][currVarIndex] = depth - 1
end

-- returns true if it was able to prune values from the domain of the two variables of this arc.
-- returns false if this was not the case.
function constraintPropagation.reviseArc(currArc, depth) 
	utils.log("# ReviseArc:")
	pruned = false	

	utils.log("varMask at start")
	if log then utils.print_r(varMask) end
	
	x1 = currArc[1]
	x2 = currArc[2]

	utils.log("x".. x1.." vs x" .. x2 )
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
					utils.log("i:"..variables[x1][i].." j:"..variables[x2][j].." -> ")
					currSupport = f(variables[x1][i],variables[x2][j]) 			
					utils.log(string.format("f: %s\n", tostring(currSupport)))	
					support = support or currSupport
					-- break if support is given. no need to check the others.
					if currSupport then break end
				end
			end

			-- prune if no support is given
			utils.log(string.format("overall support: %s\n", tostring(support)))
			if not support then 
				utils.log("prune: " .. variables[x1][i])
				-- prune value according to depth
				utils.log("varMask")
				varMask[x1][i] = depth			
				pruned = true
				if log then utils.print_r(varMask) end
			end
		end
	end
	
	utils.log("arc done\n")
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

function constraintPropagation.areVariablesWipedOut(depth) 
	for d,tbl in pairs(variables) do 
		-- only check variables which are not assigned yet
		if d > depth then 
			wipedout = false
			for _,v in pairs(tbl) do
				wipedout = wipedout or (v == 0) 
			end
			if wipedout then
				return true
			end
		end
	end
	return false
end

-- transform constraints into arcs
-- constraint has 3 elements {var1, var2, function(var1,var2)}. Add true for forward arc.
function constraintPropagation.getForwardArc(constraint) 
	arc = {}
	arc[1] = constraint[1]
	arc[2] = constraint[2]
	arc[3] = constraint[3]
	return arc
end

-- transform constraints into arcs
-- constraint has 3 elements {var1, var2, function(var1,var2)}. Add false for backward arc
function constraintPropagation.getBackwardArc(constraint) 
	arc = {}
	arc[1] = constraint[2]
	arc[2] = constraint[1]
	arc[3] = function (x,y) return constraint[3](y,x) end
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
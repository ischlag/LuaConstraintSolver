--[[
University of St Andrews
CS4402 - Constraint Programming 
Practical 2, 12.04.2016
150021237

Description:
This file is a module. It provides the key components of the 
constraint solver. 

--]]
local constraintPropagation = {}

--imports
local utils = require("utils")
local cm = require("constraintModeling")
---------------------------- public variables ----------------------------
-- the number of nodes created
nodes = 0
-- the number of archs revised
archRev = 0
-- time elapsed
elapsed_time = 0
-- number of solutions
solutionCount = 0
-- solution assignments
solutionAssignments = {}

------------------------ global config variables ------------------------
-- log output
log = 0
-- find all solutions
findOnlyFirstSolutions = false

--------------------------- private variables ---------------------------
-- the current variable associations
local curr = {}
-- the variables and their domains
local variables = {}
-- used up vars
local oldVars = {}
-- the constraints
local constraints = {}
-- the number of variables the current model uses.
local varCount = 0
-- mask in order to prune variable dimensions. Only used when forward checking.
local varMask = {}

----------------------------- Entry Point Function -----------------------------
-- starts the solver 
-- vars: table with variables and their domains
-- constr: table with all the constraints
-- verbose: 0->no output, 1->key steps and pruning, 2->full detail
-- findOnlyFirst: stop after first solution was found
function constraintPropagation.solve(vars, constr, verbose, findOnlyFirst)
	log = verbose
	findOnlyFirstSolutions = findOnlyFirst or false --default value hack, if not given then value will be false

	-- make sure the pointers work
	variables = vars
	constraints = constr
	local order = cm.range(1,#vars)

	-- time control
	local start_time = os.clock()

	-- count the number of variables
	for _ in pairs(variables) do
		varCount = varCount + 1
		curr[varCount] = 0
	end

	-- init stats
	nodes = 0

	-- build mask for pruning
	constraintPropagation.buildEmptyVariableMask()

	-- initial pruning
	constraintPropagation.checkArcConsistencyAndPrune(-1)

	--local solution = constraintPropagation.forwardChecking(1)
	--local solution = constraintPropagation.MAC3(order, 0)	
	local solution = constraintPropagation.forwardChecking2Way(order, {-1})
	local end_time = os.clock()
	elapsed_time = end_time - start_time

	return solutionCount
end

----------------------------- Core Functions -----------------------------
-- main recursive function implementing 2-way and forward checking
function constraintPropagation.forwardChecking2Way(varList, usedVars)
	utils.log(1,"2 Way")

	--utils.print_r(varList)
	--utils.print_r(usedVars)

	-- check assignment
	if #varList == 0 then
		--win!
		table.insert(solutionAssignments, utils.copyTable(curr))
		solutionCount = solutionCount + 1

		if findOnlyFirstSolutions then 
			utils.log(1,"win!")
			utils.printCurrentBoardState(curr, varMask, depth)
			return true
		end
		
		-- go and find other solutions
		return false
	end

	-- assign var
	local var, varList  = constraintPropagation.selectVar(varList)
	utils.log(1,"var: " .. var)

	-- assign val
	local val = constraintPropagation.selectVal(var)
	utils.log(1,"val: " .. val)

	if 1 <= log then utils.printCurrentBoardState(curr, varMask, var) end
	--utils.print_r(varMask)

	-- branch left
	if constraintPropagation.branchFCLeft(varList, var, val, usedVars) then return true end

	-- branch right
	if constraintPropagation.branchFCRight(varList, var, val, usedVars) then return true end

	return false
end

-- branch left according to 2-way branching
function constraintPropagation.branchFCLeft(varList, var, val, usedVars)
	utils.log(1,"left (depth:" .. var ..")")
	
	curr[var] = variables[var][val]
	nodes = nodes + 1

	-- prune all other possibilities
	for i = 1, #varMask[var] do
		if i ~= val and varMask[var][i] == 0 then
			varMask[var][i] = var
		end
	end	
	utils.log(1,var .. " assign " .. variables[var][val] )

	-- revise arcs
	if constraintPropagation.checkArcConsistencyAndPrune(var) then
		local vList = utils.copyTable(varList)
		local uList = utils.copyTable(usedVars)
		-- push var unto used stack
		table.insert(uList, table.remove(vList, utils.getKey(vList, var)))

		if constraintPropagation.forwardChecking2Way(vList, uList) then
			return true
		end
	end
	utils.log(1,"(left) depth: " .. var .. " arc or backtrack fail")

	--undo pruning
	utils.log(1,"undo pruning")
	constraintPropagation.unprune(val, var)
	varMask[var][val] = usedVars[#usedVars]

	--unassign
	curr[var] = 0
	
	-- print board
	if 1 <= log then utils.printCurrentBoardState(curr, varMask, var) end
	return false
end

-- branch right according to 2-way branching
function constraintPropagation.branchFCRight(varList, var, val, usedVars)	
	utils.log(1,"right (depth:" ..var..")")
	local backup = varMask[var][val]

	-- delete value
	if varMask[var][val] == 0 then
		varMask[var][val] = var
	end

	-- continue if not empty
	if utils.contains(varMask[var], 0) then
		if constraintPropagation.checkArcConsistencyAndPrune(var) then
			local vList = utils.copyTable(varList)
			--table.remove(vList, 1)
			if constraintPropagation.forwardChecking2Way(vList, usedVars) then
				return true
			end
			utils.log(1,"backtrack fail")
		end
		utils.log(1,"(right)depth: " .. var .. " arc or backtrack fail")

		-- undo pruning
		utils.log(1,"undo pruning")
		constraintPropagation.unprune(val, var)
		varMask[var][val] = usedVars[#usedVars]
	end

	-- restore value
	varMask[var][val] = backup
	return false
end

------------------------- Arc Consistency Functions  ------------------------

-- Enforces Arc Consistency by manipulating the varMask in order to prune (and rerstore)
-- makes use of the AC3 algorithm
function constraintPropagation.checkArcConsistencyAndPrune(depth)
	utils.log(2,"### checkArcs:")

	local queue
	if depth == -1 then
		queue = constraintPropagation.addAllArcsFromConstraints()
	else
		queue = constraintPropagation.addAffectedArcs(depth)
	end

	repeat
		local currArc = queue[1]
		table.remove(queue, 1)
		--print("Queue Size: " .. #queue)
		-- revise(arc(xi, xj))
		if currArc ~= Nil and constraintPropagation.reviseArc(currArc, queue, depth) then
			-- true -> arc was pruned, we have to recheck all arcs which are based on the support of this arc's first variable.
			-- add to queue all arcs(xh,xi) where h ~= j and h ~= i
			local xi = currArc[1]
			local xj = currArc[2]
			for l = 1, #constraints do 
				-- backward arc
				if constraints[l][1] == xi and constraints[l][2] ~= xj then
					local nextArc = constraintPropagation.getBackwardArc(constraints[l])
					if 2 <= log then utils.print_r(nextArc) end
					if utils.containsArc(queue, nextArc) then 
						utils.log(2,"bwd: already in queue")
					else
						table.insert(queue, nextArc)
						utils.log(2,"bwd: added!")
					end
				end

				-- forward arc
				if constraints[l][2] == xi and constraints[l][1] ~= xj then
					local nextArc = constraintPropagation.getForwardArc(constraints[l])
					if 2 <= log then utils.print_r(nextArc) end
					if utils.containsArc(queue, nextArc) then 
						utils.log(2,"fwd:already in queue")
					else
						table.insert(queue, nextArc)
						utils.log(2,"fwd:added!")
					end
				end
			end
		end
	until #queue == 0

	-- check if nothing got wiped out
	return not constraintPropagation.areVariablesWipedOut(depth)
end

-- returns true if it was able to prune values from the domain of the two variables of this arc.
-- returns false if this was not the case.
function constraintPropagation.reviseArc(currArc, queue, depth) 
	utils.log(2,"\n# ReviseArc:")
	archRev = archRev + 1
	local pruned = false	
	
	local x1 = currArc[1]
	local x2 = currArc[2]

	utils.log(2,"x".. x1.." vs x" .. x2 )
	utils.log(2,"varMask at start")
	
	if 2 <= log then utils.print_r(varMask) end
	if 2 <= log then utils.print_r(curr) end
	
	-- find all the values in the first variable which are supported by the second variable
	-- prune all the domain values of the first variable which are not supported by any second variable domain value

	--iterate over all domain values of the first variable
	for i = 1, #variables[x1] do 
		if varMask[x1][i] == 0 and curr[x1] == 0 then
			local support = false
			--iterate over all domain values of the second variable
			for j = 1, #variables[x2] do 
				if varMask[x2][j] == 0 and curr[x1] == 0 then
					-- constraint function
					f = currArc[3]
					-- build conjunction of the results. If one value supports i then the "support" will become true.
					utils.log(2,"i:"..variables[x1][i].." j:"..variables[x2][j].." -> ")
					local currSupport = f(variables[x1][i],variables[x2][j]) 			
					utils.log(2,string.format("f: %s\n", tostring(currSupport)))	
					support = support or currSupport
					-- break if support is given. no need to check the others.
					if currSupport then break end
				end
			end

			-- prune if no support is given
			utils.log(2,string.format("overall support: %s\n", tostring(support)))
			if not support then 
				utils.log(2,"prune: " .. variables[x1][i])
				
				-- prune value according to depth
				utils.log(2,"varMask")
				varMask[x1][i] = depth	

				-- add arcs which supported this depth level
				utils.append(queue, constraintPropagation.addAffectedArcs(depth))
				--utils.append(queue, constraintPropagation.addAllArcsFromConstraints())

				pruned = true
				if 2 <= log then utils.print_r(varMask) end
			end
		end
	end
	
	utils.log(2,"arc done\n")
	return pruned
end

-- returns a table of arcs based on all constraints
function constraintPropagation.addAllArcsFromConstraints()
	local arcs = {}
	i = 1
	
	for j = 1, #variables do
		for k = 1, #variables do
			for l = 1, #constraints do
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

-- return a table of arcs based on only the relevant arcs
function constraintPropagation.addAffectedArcs(depth)
	local arcs = {}
	local i = 1
	
	for j = 1, #variables do
		for k = 1, #variables do
			for l = 1, #constraints do
				if (constraints[l][1] == j) and (constraints[l][2] == k) then
					a = constraintPropagation.getForwardArc(constraints[l])
					if not utils.contains(oldVars, a[1]) and a[2] == depth then
						arcs[i] = a
						i = i + 1
					end
				elseif (constraints[l][1] == k) and (constraints[l][2] == j) then
					a = constraintPropagation.getBackwardArc(constraints[l])
					if not utils.contains(oldVars, a[1]) and a[2] == depth then
						arcs[i] = a
						i = i + 1
					end
				end				
			end
		end
	end
	return arcs
end

-- transform constraints into arcs
-- constraint has 3 elements {var1, var2, function(var1,var2)}. 
function constraintPropagation.getForwardArc(constraint) 
	local arc = {}
	arc[1] = constraint[1]
	arc[2] = constraint[2]
	arc[3] = constraint[3]
	return arc
end

-- transform constraints into arcs
-- constraint has 3 elements {var1, var2, function(var1,var2)}. 
function constraintPropagation.getBackwardArc(constraint) 
	local arc = {}
	arc[1] = constraint[2]
	arc[2] = constraint[1]
	arc[3] = function (x,y) return constraint[3](y,x) end
	return arc
end

------------------------- Helper Functions  ------------------------

-- Restores pruned variables and assignments. Call when a wipeout has occured. 
function constraintPropagation.unprune(currVarIndex, depth)
	-- unprune all varMask[][] == depth
	--print("wipeout")
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

-- return true if any of the unassigned variables doesn't contain possible future assignments
function constraintPropagation.areVariablesWipedOut(depth) 
	--utils.print_r(varMask)
	--print("are variables wiped out? depth:"..depth)
	for d,tbl in pairs(varMask) do 
		-- only check variables which are not assigned yet
		if curr[d] == 0 then
			earlyreturn = false
			for _,v in pairs(tbl) do
				if v == 0 then
					earlyreturn = true
					break
				end
			end
			if earlyreturn then break end
			--print(true)
			return true
		end
	end
	--print(false)
	return false
end

-- creates a mask for all variables and all domains. 0 means the possible value is not pruned.
-- a number >0 shows on which depth level the variable got pruned.
function constraintPropagation.buildEmptyVariableMask()
	for i = 1, #variables do
		local tbl = {}
		for j = 1, #variables[i] do
			tbl[j] = 0
		end
		varMask[i] = tbl
	end
end

-- Select the next variable with the smallest domain first
function constraintPropagation.selectVar(varList)
	-- count number of domain values for each variable
	local counts = {}
	for i = 1, #varList do
		counts[i] = 0
		for j = 1, #varMask[i] do
			if varMask[i][j] == 0 then counts[i] = counts[i] + 1 end
		end
	end

	-- find variable with least free domains
	local minId = 1
	local minValue = counts[1]
	for i = 2, #counts do 
		if counts[i] < minValue then
			minValue = counts[i]
			minId = i
		end
	end

	-- push the variable with min domains to the front
	table.insert(varList, 1, table.remove(varList, minId))

	return varList[1], varList
end

-- select the value with the least constrains on future variables
function constraintPropagation.selectVal(var)
	domainValues = {}
	for i = 1, #varMask[var] do
		if varMask[var][i] == 0 then
			table.insert(domainValues, i)
		end
	end

	-- if only one val possible, return it.
	if #domainValues == 1 then
		return domainValues[1]
	end

	-- this should never happen !
	if #domainValues == 0 then
		return -5
	end

	-- count the number of vars with the same values
	impact = {}
	for i,d in pairs(domainValues) do
		impact[i] = 0
		for varid, domain in pairs(varMask) do
			if domain[d] == 0 then
				impact[i] = impact[i] + 1
			end
		end
	end

	-- choose the value with the smallest impact
	local minId = 1
	local minValue = impact[1]
	for i = 2, #impact do 
		if impact[i] < minValue then
			minValue = impact[i]
			minId = i
		end
	end

	--[[
	print("choose val for var: " .. var)
	print("domains")
	utils.print_r(domainValues)
	print("impact")
	utils.print_r(impact)
	print("variable: " .. var)
	print("best id: " .. minId)
	]]

	return domainValues[minId]
end

-- returns the current values associated with the variables.
function constraintPropagation.getSolution()
	return curr
end

-------------------- All following functions are deprecated ----------------------

-- DEPRECATED (pure backtrack implementation is not given)
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

-- DEPRECATED (was used for pure backtrack version)
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

-- DEPRECATED (instead of FC we use now MAC3!)
-- recursive depth-first search.
-- performs forward checking in order to reduce search and spot dead-ends earlier
function constraintPropagation.forwardChecking(depth)	
	print("###### DEPTH: ".. depth)

	for d = 1, #variables[depth] do
		-- assign variables
		if varMask[depth][d] == 0 then
			curr[depth] = variables[depth][d]
			-- clear old assignments
			for i = depth + 1, #curr do
				if curr[i] ~= 0 then curr[i] = 0 end
			end
			-- prune all other possibilities
			for i = 1, #varMask[depth] do
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
				--utils.print_r(varMask)
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

-- DEPRECATED
-- MAC3 implementation for d-way branching.
function constraintPropagation.MAC3(varList, oldVar) 
	local varId, vList = constraintPropagation.getSmallestDomainVar(utils.copyTable(varList))
	local oldId = oldVar

	local depth = varCount - #vList

	for valId = 1, #varMask[varId] do
		-- assign value from domain(var)
		if varMask[varId][valId] == 0 then

			curr[varId] = variables[varId][valId]
			nodes = nodes + 1
			-- prune all other possibilities
			for i = 1, #varMask[varId] do
				if i ~= valId and varMask[varId][i] == 0 then
					varMask[varId][i] = varId
				end
			end	

			if depth == varCount then
				--win!
				print("win!")
				utils.printCurrentBoardState(curr, varMask, varId)	
				return true
			else
				if constraintPropagation.checkArcConsistencyAndPrune(varId) then
					utils.printCurrentBoardState(curr, varMask, varId)	
					if constraintPropagation.MAC3(vList, varId) then
						return true
					end
				end
			end
			
			-- undo pruning
			print("wipeout "..varId)
			constraintPropagation.unprune(valId, varId)
			
			varMask[varId][valId] = varId - 1

			-- unassign and remove from domain
			curr[varId] = 0
			
			utils.printCurrentBoardState(curr, varMask, varId)
		end
	end	
	return false	
end

-- DEPRECATED, was used with MAC3
-- returns the variable of a list with the smallest domain. Establishes a dynamic variable order.
function constraintPropagation.getSmallestDomainVar(varList) 
	local counts = {}
	for i = 1, #varList do
		counts[i] = 0
		for j = 1, #varMask[i] do
			if varMask[i][j] == 0 then counts[i] = counts[i] + 1 end
		end
	end

	local minId = 1
	local minValue = counts[1]
	for i = 2, #counts do 
		if counts[i] < minValue then
			minValue = counts[i]
			minId = i
		end
	end

	--utils.print_r(counts)
	--print("min key: " .. minId)

	return table.remove(varList, minId), varList
end


return constraintPropagation
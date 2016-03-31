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
local utils = require("utils")
-- the number of nodes created
nodes = 0
-- the number of archs revised
archRev = 0
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
-- log output
local log = false

-- starts the solver 
function constraintPropagation.solve(vars, constr, order, runSolver, logger)
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
		--return constraintPropagation.forwardChecking(1)
		return constraintPropagation.MAC3(order, 0)
		--return constraintPropagation.forwardChecking2Way(order)
	end
end

-- returns the current values associated with the variables.
function constraintPropagation.getSolution()
	return curr
end

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

-- Enforces Arc Consistency by manipulating the varMask in order to prune (and rerstore)
-- makes use of the AC3 algorithm
function constraintPropagation.checkArcConsistencyAndPrune(depth)
	utils.log("### checkArcs:")

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
					local nextArc = constraintPropagation.getForwardArc(constraints[l])
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

-- returns true if it was able to prune values from the domain of the two variables of this arc.
-- returns false if this was not the case.
function constraintPropagation.reviseArc(currArc, queue, depth) 
	utils.log("\n# ReviseArc:")
	archRev = archRev + 1
	local pruned = false	
	
	local x1 = currArc[1]
	local x2 = currArc[2]

	utils.log("x".. x1.." vs x" .. x2 )
	utils.log("varMask at start")
	
	if log then utils.print_r(varMask) end
	
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
					utils.log("i:"..variables[x1][i].." j:"..variables[x2][j].." -> ")
					local currSupport = f(variables[x1][i],variables[x2][j]) 			
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
				print("prune: " .. variables[x1][i])
				
				-- prune value according to depth
				utils.log("varMask")
				varMask[x1][i] = depth	

				-- add arcs which supported this depth level
				utils.append(queue, constraintPropagation.addAffectedArcs(depth))
				--utils.append(queue, constraintPropagation.addAllArcsFromConstraints())

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


--[[
function constraintPropagation.selectVar(varList) 
	return varList[1]
end

function constraintPropagation.selectVal(var)
	for i = 1, #varMask[var] do
		if varMask[var][i] == 0 then
			return i
		end
	end
	return -5
end

function constraintPropagation.forwardChecking2Way(varList)
	-- check assignment
	local depth = varCount - #varList
	print("2way (depth:"..depth..")")
	if depth == varCount then
		--win!
		print("win!")
		return true
	end

	-- assign var
	local var = constraintPropagation.selectVar(varList)
	print("var: " .. var)

	-- assign val
	local val = constraintPropagation.selectVal(var)
	print("val: " .. val)

	--utils.printCurrentBoardState(curr, varMask, depth)
	--utils.print_r(varMask)

	if constraintPropagation.branchFCLeft(varList, var, val) then return true end
	if constraintPropagation.branchFCRight(varList, var, val) then return true end
end

function constraintPropagation.branchFCLeft(varList, var, val)
	local depth = varCount - #varList
	print("left (depth:" ..depth..")")
	curr[var] = variables[var][val]
	-- prune all other possibilities
	for i = 1, #varMask[var] do
		if i ~= valId and varMask[var][i] == 0 then
			varMask[var][i] = var
		end
	end	
	print(var .. " assign " .. variables[var][val] )
	utils.print_r(curr)

	-- revise arcs
	if constraintPropagation.checkArcConsistencyAndPrune(depth) then
		local vList = utils.copyTable(varList)
		table.remove(vList, 1)
		if constraintPropagation.forwardChecking2Way(vList) then
			return true
		end
		print("backtrack fail")
	end
	print("(left)depth: " .. depth .. " arc or backtrack fail")

	--undo pruning
	print("undo pruning")
	constraintPropagation.unprune(val, var)
	varMask[var][val] = var - 1

	--unassign
	curr[var] = 0
	
	-- print board
	utils.printCurrentBoardState(curr, varMask, var)
	return false
end

function constraintPropagation.branchFCRight(varList, var, val)
	print("right (depth:" ..depth..")")
	local depth = varCount - #varList
	local backup = varMask[var][val]

	-- delete value
	varMask[var][val] = depth

	-- continue if not empty
	if utils.contains(varMask[var], 0) then
		if constraintPropagation.checkArcConsistencyAndPrune(depth) then
			local vList = utils.copyTable(varList)
			--table.remove(vList, 1)
			if constraintPropagation.forwardChecking2Way(vList) then
				return true
			end
			print("backtrack fail")
		end
		print("(right)depth: " .. depth .. " arc or backtrack fail")

		-- undo pruning
		print("undo pruning")
		constraintPropagation.unprune(val, var)
		varMask[var][val] = var - 1
	end

	-- restore value
	varMask[var][val] = backup
	return false
end
]]

return constraintPropagation
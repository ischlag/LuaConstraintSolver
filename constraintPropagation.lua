local constraintPropagation = {}

nodes = 0
curr = {}
variables = {}
constraints = {}
n = 0 -- number of variables

function constraintPropagation.solve(vars, constr)
	variables = vars
	constraints = constr
	nodes = 0

	for _ in pairs(variables) do
		n = n + 1
	end

	return constraintPropagation.backtrack(1)
end

function constraintPropagation.getSolution()
	return curr
end

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

function constraintPropagation.backtrack(depth)	
	for d = 1, #variables[depth] do
		curr[depth] = variables[depth][d]
		nodes = nodes + 1
		if constraintPropagation.checkConsistency(depth) then
			if(depth == n) then
				return true
			else
				if constraintPropagation.backtrack(depth+1) then return true end
			end
		end
	end
end

return constraintPropagation
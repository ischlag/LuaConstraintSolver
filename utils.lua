--[[
University of St Andrews
CS4402 - Constraint Programming 
Practical 2, 12.04.2016
150021237

Description:
This file is a module. It provides utility functions which didn't belong 
into the modeling or propagation module. 

--]]
local utils = {}

-- prints a table with its keys to the console
function utils.printMap(t)
	for pos,var in pairs(t) do 
		io.write("[" .. pos .. "] -> ")
		utils.printArray(var)
	end
end

-- prints an array to the console (no keys)
function utils.printArray(arr)
	for i=1, #arr-1 do
		io.write(arr[i] .. ", ")
	end
	io.write(arr[#arr])
	io.write("\n")
end

-- adds all the elements of t2 to the table of t1. 
function utils.append(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

-- remove from table by value
function utils.removeByValue(vList, value)
	key = utils.getKey(vList, value)
	table.remove(vList, key)
end

-- viualizes the current state of the board, including pruned variables if available
-- depth will be 0 if not defined
function utils.printCurrentBoardState(currentAssignments, variableMask, currDepth)
	local depth = currDepth or 0 -- default variable hack
	local vm = variableMask
	local curr = currentAssignments

	io.write("\n")
	local n = #variableMask
	for i = 1, n do
		for j = 1, n do
			if curr[i] == j then
				io.write("Q")
			else
				if vm[i][j] == depth then
					io.write("X")
				elseif vm[i][j] == -1 then
					io.write("-")
				elseif vm[i][j] ~= 0 then
					io.write(tostring(vm[i][j]))					
				else
					io.write(".")
				end
			end
			io.write(" ")
		end
		io.write("\n")
	end
	io.write("\n")	
end

-- print board based on solutions table
function utils.printSolutionBoard(solution, variables) 
	local n = #variables
	for i = 1, n do
		for j = 1, n do
			if solution[i] == j then
				io.write("Q")
			else
				io.write(".")
			end
			io.write(" ")
		end
		io.write("\n")
	end
	io.write("\n")	
end

-- simple log function, for different log levels
function utils.log(lvl, str)
	if lvl <= log then
		print(str)
	end
end

-- returns if table contains arc
function utils.containsArc(tbl, el)
   for i=1, #tbl do
      if (tbl[i][1] == el[1]) and (tbl[i][2] == el[2]) then 
         return true
      end
   end
   return false
end

-- returns if table contains value
function utils.contains(tbl, el)
   for i=1, #tbl do
      if tbl[i] == el then 
         return true
      end
   end
   return false
end

-- find table index based on value
function utils.getKey(tbl, value)
   for i=1, #tbl do
      if tbl[i] == value then 
         return i
      end
   end
   return Nil
end

-- shallow copy of a table
function utils.copyTable(tbl) 
	local newTbl = {}
	for p,v in pairs(tbl) do
		newTbl[p] = v
	end
	return newTbl
end

-- recursive function to print table content
-- source of this function: https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
function utils.print_r ( t )  
    local print_r_cache={}
    local function sub_print_r(t,indent)
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(t).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8))
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ")
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end

return utils
--[[
University of St Andrews
CS4402 - Constraint Programming 
Practical 2, 12.04.2016
150021237

Description:
This file is a module. It provides utility functions which didn't belong 
into the modelling or propagation module. 

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
	for i=1, #arr do
		io.write(arr[i] .. ", ")
	end
	io.write("\n")
end

-- adds all the elements of t2 to the table of t1. 
function utils.append(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end

-- viualizes the current state of the board, including pruned variables if available
-- depth will be 0 if not defined
function utils.printCurrentBoardState(currentAssignments, variableMask, currDepth)
	depth = currDepth or 0 -- default variable hack
	vm = variableMask
	curr = currentAssignments

	io.write("\n")
	n = #variableMask
	for i = 1, n, 1 do
		for j = 1, n, 1 do
			if curr[i] == j then
				io.write("Q")
			else
				if vm[i][j] == depth then
					io.write("X")
				elseif vm[i][j] ~= 0 then
					io.write("0")
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



function utils.test(t) 
		io.write("A("..t..")")
		io.read(1)
		io.write("B\n")
end


function utils.containsArc(tbl, el)
   for i=1, #tbl do
      if (tbl[i][1] == el[1]) and (tbl[i][2] == el[2]) and (tbl[i][3] == el[3]) then 
         return true
      end
   end
   return false
end


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
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

return utils
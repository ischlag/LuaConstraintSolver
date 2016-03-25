local utils = {}
function utils.printMap(t)
	for pos,var in pairs(t) do 
		io.write("[" .. pos .. "] -> ")
		utils.printArray(var)
	end
end

function utils.printArray(arr)
	for i=1, #arr do
		io.write(arr[i] .. ", ")
	end
	io.write("\n")
end

function utils.append(t1,t2)
    for i=1,#t2 do
        t1[#t1+1] = t2[i]
    end
    return t1
end


return utils
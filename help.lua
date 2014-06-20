local awful = require ("awful")
local naughty = require("naughty")
local string = string
local tostring = tostring
local io = io
local pairs = pairs
local capi = {
	mouse = mouse,
	screen = screen
}
--Here you might add your terminal (class, not a name)
local termClass = { "UXTerm", "Xterm", "XTerm","Konslole", "URxvt", "Rxvt" }

module("help")

local nf=nil
-- get client name by c.class, or c.pid
function getClientName(c)
	local cname=nil
	if (isTerminal(c.class)) then
		local temp =  tostring(awful.util.pread("pstree " ..tostring(c.pid).. " | awk -F \"---\" \'{ if(NF>3) {print $3} else {print $NF}}\'| sed -e \'$!d\' | awk -F \"-\" \'{if (NF>1) {print $2} else {print$1}}\'"))
		local cend = string.find(temp,"\n", 1, true)
		cname = string.sub (temp, 1, cend-1)		
	else
		cname = tostring(c.class)
	end
	local fname = awful.util.getdir("config") .. "/help/data/" .. cname     --here you must change path, if not working
	if awful.util.file_readable(fname) then
		local myData = readFile(fname)
		local myData = markupData (myData) 
		--nf = naughty.notify ({title = '<span weight="bold" color="#00FF00">' .. "Подсказка для:      " .. cname .. '</span>', text = myData, timeout=60,screen=capi.mouse.screen})
		nf = naughty.notify ({title = '<span weight="bold" color="#00FF00">' .. "Help for:      " .. cname .. '</span>', text = myData, timeout=60,screen=capi.mouse.screen})
	else
		--nf = naughty.notify ({title = '<span weight="bold" color="#FF0000">' .. "Файл с подсказкой для: " .. cname.. " не найден" .. '</span>' ,screen=capi.mouse.screen})
		nf = naughty.notify ({title = '<span weight="bold" color="#FF0000">' .. "Can't find help file for: " .. cname .. '</span>' ,screen=capi.mouse.screen})
	end
	
	return nf
end 

--function verify, terminal or not
function isTerminal(clientClass)
	for _,v in pairs (termClass) do
		if clientClass== v then
			return true
		end
	end
	return false
end

-- read data from file
function readFile(file)
	local fh = io.input (file)
	local myStr = fh:read("*all")
	io.close (fh)
	return myStr
end

--this function markup text
function markupData (str)
	local result,tmp = "",""
	local markData= {}
	local strLength = string.len(str)
	local curPos, curLast, maxLength = 0,0,0
	--for more convenient processing, I separated the text for the lines ( \n)
	while (curPos<strLength) 
		do
			curPos,_ = string.find (str,"\n",curPos)
			markData[#markData+1] = string.sub (str, curLast+1, curPos)
			tmp = markData[#markData]
			local posTir,_ = string.find (tmp, "-")
			if posTir then
				if (posTir>maxLength) then
					maxLength =posTir 
				end
			end
			curLast = curPos
			if curPos then
				curPos = curPos + 2
			end
	end
	local posSubKey= nil
	for k,v in  pairs (markData) do
		posSubKey,_ = string.find (v, "-")
		if posSubKey then
			v = string.gsub (v, "-", "</span>-",1)
			if (posSubKey < maxLength) then
				local increm = maxLength - posSubKey
				for  i=1,increm do  --align by center
					v = " " .. v
				end
			end
			v =  '<span font="DejaVu Sans Mono 10" weight="bold" color="#FF4500">' .. v 
		end
		if  string.find (v, "=") then
			v = string.gsub (v, "==", '<span font="DejaVu Sans Mono 10" weight="bold" color="#00FFFF">', 1)
			v = string.gsub (v, "==", '</span>',1)
		end   
        if string.find (v, "\'") then
			v = string.gsub (v, "\'\'", '<span font="DejaVu Sans Mono 10" weight="bold" color="#FFFF00">', 1)
			v = string.gsub (v, "\'\'", '</span>',1)
		end   
			result = result .. v
	end
	return result
end

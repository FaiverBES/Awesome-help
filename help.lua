local awful = require ("awful")
local naughty = require("naughty")
local string = string
local tostring = tostring
local table = table
local io = io
local pairs = pairs
local capi = {
	mouse = mouse,
	screen = screen
}

local lang="ru"          -- here change your language, don't forget create directory in 'data' folder
local maxLength = 0      --variable for max length to '-'
local nf=nil             -- index for notify

--Here you might add your terminal (class, not a name), but "X-terminal-emulator" not supported(script failed)
local termClass = { "UXTerm", "Xterm", "XTerm","Konslole", "URxvt", "Rxvt"}

module("help")

-- get client name by c.class, or c.pid
-- call from clientkey section, accept value is active client
function getClientName(c)
	local cname=nil
	if (isTerminal(c.class)) then
		local temp =  tostring(awful.util.pread("pstree " ..tostring(c.pid).. " | awk -F \"---\" \'{ if(NF>3) {print $3} else {print $NF}}\'| sed -e \'$!d\' | awk -F \"-\" \'{if (NF>1) {print $2} else {print$1}}\'"))
		local cend = string.find(temp,"\n", 1, true)
		cname = string.sub (temp, 1, cend-1)		
	elseif (tostring(c.class)=="X-terminal-emulator") then
		naughty.notify({text = tostring(c.name) })
		cname=string.gsub(c.name, "~ : ", "")
	else
		cname = tostring(c.class)
	end
	--nf=displayHelp(cname)
	return displayHelp(cname)
end

--this function call from helpwwidget in rc.lua
function displayHelp(cname)
	local fname = awful.util.getdir("config") .. "/help/data/" .. lang .. "/" .. cname     --here you must change path, if not working
	if awful.util.file_readable(fname) then
		local myData = readFile(fname)
		maxLength=0
		myData = splitStr (myData)
		myData = markupData(myData)
		--if you are using awesome 3.4 you can uncomment next line, and comment next
		nf = naughty.notify ({title = '<span weight="bold" color="#00FF00">' .. "Подсказка для:      " .. cname .. '</span>', text = myData, timeout=60,screen=capi.mouse.screen})
		--nf = naughty.notify ({title = '<span weight="bold" color="#00FF00">' .. "Help for:      " .. cname .. '</span>', text = myData, timeout=60,screen=capi.mouse.screen})
		--nf = naughty.notify ({title = "Help for:      " .. cname, text = myData, timeout=60,screen=capi.mouse.screen})
	else
		--if you are using awesome 3.4 you can uncomment next line, and comment next
		--nf = naughty.notify ({title = '<span weight="bold" color="#FF0000">' .. "Can't find help file for: " .. cname .. '</span>' ,screen=capi.mouse.screen})
		--nf = naughty.notify ({title = '<span weight="bold" color="#FF0000">' .. "Файл с подсказкой для: " .. cname.. " не найден" .. '</span>' ,screen=capi.mouse.screen})
		nf = naughty.notify ({title = "Can't find help file for: " .. cname  ,screen=capi.mouse.screen})
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

--separate text by end of line
function splitStr(str)
  local result = {}  
  local lastPos = 1
  local s, e, cap = string.find(str,"(.-)"..'\n', 1)
  while s do
    if s ~= 1 or cap ~= "" then
		result[#result+1] = cap
		alignmentPos(cap)
    end
    lastPos = e+1
    s, e, cap = string.find(str,"(.-)"..'\n', lastPos)
  end
  if lastPos <= #str then
    cap = string.sub(str,lastPos)
	result[#result+1] = cap
	alignmentPos(cap)
  end
  return result
end

--this function calculate max position of '-', for alignment text
function alignmentPos(str)
	local posTir,_ = string.find (str, "-")
	if posTir then
		if (posTir>maxLength) then
			maxLength =posTir
		end
	end
end

--this function markup text, and align text by '-'
function markupData (str)
	local result = ""
	local posCentre= nil
	for k,v in  pairs (str) do
		posCentre,_ = string.find (v, "-")
		v = replaceText(v)
		if posCentre then
			v = string.gsub (v, "-", "</span>-",1)
			if (posCentre < maxLength) then
				local addSpace = maxLength - posCentre
				for  i=1,addSpace  do  --align by center
					v = " " .. v
				end
			end
			v =  '<span font="DejaVu Sans Mono 10" weight="bold" color="#FF4500">' .. v 
			v = v .. '\n'
		end
		if  string.find (v, "==") then
			v = string.gsub (v, "==", '<span font="DejaVu Sans Mono 10" weight="bold" color="#00FFFF">', 1)
			v = string.gsub (v, "==", '</span>',1)
			v = v .. '\n'
		end   
        if string.find (v, "\'") then
			v = string.gsub (v, "\'\'", '<span font="DejaVu Sans Mono 10" weight="bold" color="#FFFF00">', 1)
			v = string.gsub (v, "\'\'", '</span>',1)
			v = v .. '\n'
		end   
			result = result .. v
	end
	return result
end

--this function replace symbol for using HTML <span>, such as < > / & etc.
function replaceText(str)
	str = string.gsub (str, "&", '&amp;')
	str = string.gsub (str, "<", '&lt;')
	str = string.gsub (str, ">", '&gt;')
	return str
end

--меню для Awesome-help
function helpMenuGenerate()
	helpItems = {}
	local configDir = awful.util.getdir ("config") 
	local helpFile = awful.util.pread ("ls -1 ".. configDir .. "/help/data/"..lang )
	local mycurPos = 0
	local mycurLast = 0
	local tmp = ""
	local helpMenuItems = {}
	local myFiles = {}
	local function genaction(fname)
		f = function() displayHelp(fname) end
		return f
	end
	while (mycurPos)
		do
			mycurPos,_ = string.find (helpFile,"\n",mycurPos)
			if mycurPos then
				tmp = string.sub (helpFile, mycurLast+1, mycurPos-1)
				helpItems[#helpItems+1] = tmp
				table.insert ( helpMenuItems, {tmp, genaction(tmp) })
				mycurLast = mycurPos
				mycurPos = mycurPos +1
			end
		end
	helpMenu=awful.menu ({items=helpMenuItems })
	return helpMenu
end

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

module("help")

-- функция получает имя запущенного приложения либо по c.class, либо опосредованно через получение c.pid
function getClientName(c)
	local cname=nil
	if c.class == "UXTerm" or c.class == "XTerm" then
		local temp =  tostring(awful.util.pread("pstree " ..tostring(c.pid).. " | awk -F \"---\" \'{ if(NF>3) {print $3} else {print $NF}}\'| sed -e \'$!d\' | awk -F \"-\" \'{if (NF>1) {print $2} else {print$1}}\'"))
		local cend = string.find(temp,"\n", 1, true)
		cname = string.sub (temp, 1, cend-1)		
	else
		cname = tostring(c.class)
	end
	local fname = "/home/faiver/.config/awesome/help/" .. cname     --заменить на свой путь до кталога(заменить username)
	if awful.util.file_readable(fname) then
		local myData = readFile(fname)
		local myData = markupData (myData) 
		naughty.notify ({title = '<span weight="bold" color="#00FF00">' .. "Подсказка для:      " .. cname .. '</span>', text = myData, timeout=15,screen=capi.mouse.screen})
	else
		naughty.notify ({title = '<span weight="bold" color="#FF0000">' .. "Файл с подсказкой для: " .. cname.. " не найден" .. '</span>' ,screen=capi.mouse.screen})
	end
	
	return cname
end 

-- функция считывает файл
function readFile(file)
	local fh = io.input (file)
	local myStr = fh:read("*all")
	io.close (fh)
	return myStr
end

--функция будет производить разметку
function markupData (str)
	local result,tmp = "",""
	local markData= {}
	local strLength = string.len(str)
	local curPos, curLast, maxLength = 0,0,0
	--разбивка переданной строки на подстроки по принципу в конце строки символ \n
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
	--выравнивание по центру (по символу -)
	local posSubKey= nil
	for k,v in  pairs (markData) do
		posSubKey,_ = string.find (v, "-")
		if posSubKey then
			v = string.gsub (v, "-", "</span>-",1)
			if (posSubKey < maxLength) then
				local increm = maxLength - posSubKey
				for  i=1,increm do
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

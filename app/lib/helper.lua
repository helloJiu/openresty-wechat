local helper = {}

function helper.starts(str, prefix)
    return string.sub(str, 1, string.len(prefix)) == prefix
end

function helper.ends(str, suffix)
    return suffix == "" or string.sub(str, -string.len(suffix)) == suffix
end


function helper.getRandomStr(n)
    local t = {
        "0","1","2","3","4","5","6","7","8","9",
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
    }    
    local s = ""
    for i =1, n do
        s = s .. t[math.random(#t)] 
    end;
    return s
end

function helper.trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function helper.parseCDATA(str)
    str = string.gsub(str, "<!%[CDATA%[", "")
    str = string.gsub(str, "]]>", "")
    return helper.trim(str)
end

function helper.success(data)
    return {
        code = 200,
        message = "ok",
        data = data
    }
end

function helper.fail(message, code)
    return {
        code = code or 400,
        message = message,
        data = {
            manual_code = code,
            manual_detail = message
        }
    }
end

return helper

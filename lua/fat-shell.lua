local I = require("inspect")
local FAT =  require("fat")

local function table_dump(name, t)
        print("Table", name)
        if t then
                for k, v in ipairs(t) do
                    print (k, v)
                end
        end
end

local function dec_add_hex(item, path)
        if type(item) == "number" then
                return string.format("%10d\t0x%08X", item, item)
        end
        return item
end

local function inspect_dump(name, t)
        print(name)
        print(I.inspect(t, { process = dec_add_hex, smartquote = 0, }))
end

fn = "./warranty-sd/shanghai_img_S"

if arg[1] then
        fn = arg[1]
end

print("Load file: " .. fn)

FAT.open(fn)

local boot = FAT.read_boot()
inspect_dump("Boot Sector", boot)
print("Dirty", FAT.is_dirty(boot))

--[[
]]
local fatents = FAT.read_fat(boot)
for i = 1, 15 do
        --print(I.inspect(fatents[i]))
        print(string.format("%2d %08X", i - 1, fatents[i].next))
end

FAT.read_dir(boot)

FAT.close()

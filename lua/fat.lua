local I = require("inspect")

local F = {
        fd = nil,
}

local FLAG_DELETE = 0xE5
local FLAG_FAT32  = 1
local SECTOR_SIZE = 512
local FSINFO_SIZE = SECTOR_SIZE * 2

local CLUST_FREE  =	0		--/* 0 means cluster is free */
local CLUST_FIRST =	2		--/* 2 is the minimum valid cluster number */
local CLUST_RSRVD =	0xfffffff6	--/* start of reserved clusters */
local CLUST_BAD   =	0xfffffff7	--/* a cluster with a defect */
local CLUST_EOFS  =	0xfffffff8	--/* start of EOF indicators */
local CLUST_EOF   =	0xffffffff	--/* standard value for last cluster */

--[[
/*
 * Masks for cluster values
 */
]]
local CLUST12_MASK = 0xfff
local CLUST16_MASK = 0xffff
local CLUST32_MASK = 0xfffffff

local FAT_USED = 1           --/* This fat chain is used in a file */

local DOSLONGNAMELEN = 256   --/* long name maximal length */
local LRFIRST        = 0x40  --/* first long name record */
local LRNOMASK       = 0x1f  --/* mask to extract long record sequence number *

function F.open(filename)
        local f, err = io.open(filename, "r")
        if nil == f then
                print("Error to open file: " .. filename .. ", " .. err)
        else
                F.fd = f
        end
end

function F.close()
        io.close(F.fd)
end

local function Bytes(buffer, offset_base, n)
        local num = 0
        local shift = 0
        local offset = offset_base + 1  -- lua array index start at 1

        if # buffer > (offset + n) then
                --print("Parse...")
                for idx = 1, n do
                        local val = string.byte(buffer, offset)
                        num = num + (val << shift)
                        --print("val " .. val .. ", num " .. num)
                        shift = shift + 8
                        offset =  offset + 1
                end
        end

        return num
end

function F.read(name, offset, size)
        if F.fd then
                print(name, "Read offset/size", offset, string.format("0x%X", offset), size)
                F.fd:seek("set", offset)
                return F.fd:read(size)
        else
                return nil
        end
end

function F.read_fsinfo(boot)
        local buffer = F.read("FSInfo", boot.FSInfo * boot.BytesPerSec, FSINFO_SIZE)

        -- TODO: Validate FSInfo

        --print("Read FSInfo...")
        local fsinfo = {
                Name = "FSInfo",
                Free = Bytes(buffer, 0x1E8, 4),
                Next = Bytes(buffer, 0x1EC, 4),
        }

        return fsinfo
end

function F.read_boot()
        local buffer = F.read("Boot", 0, SECTOR_SIZE)

        --print("Read boot sector...")
        local boot = {
                --Name = "Boot Sector",
                BytesPerSec = Bytes(buffer, 11, 2),
                SecPerClust = Bytes(buffer, 13, 1),
                ResSectors  = Bytes(buffer, 14, 2),
                NumFATs     = Bytes(buffer, 16, 1),
                RootDirEnts = Bytes(buffer, 17, 2),
                Sectors =     Bytes(buffer, 19, 2),
                Media =       Bytes(buffer, 21, 1),
                FATsmall =    Bytes(buffer, 22, 2),
                SecPerTrack = Bytes(buffer, 24, 2),
                Heads =       Bytes(buffer, 26, 2),
                HiddenSecs =  Bytes(buffer, 28, 4),
                HugeSectors = Bytes(buffer, 32, 4),
                ValidFat = -1,
        }

        boot.FATsecs = boot.FATsmall

        if boot.RootDirEnts == 0 then
                boot.flags = FLAG_FAT32
        end

        if (boot.flags & FLAG_FAT32) == FLAG_FAT32 then
                --print("Parse FAT32 info")
                boot.FATsecs = Bytes(buffer, 36, 4)
                local val    = Bytes(buffer, 40, 1)
                if (val & 0x80) == 0x80 then
                        boot.ValidFat =  val & 0x0F
                end
                boot.RootCl =  Bytes(buffer, 44, 4)
                boot.FSInfo =  Bytes(buffer, 48, 2)
                boot.Backup =  Bytes(buffer, 50, 2)

                local fsinfo = F.read_fsinfo(boot)
                boot.FSFree = fsinfo.Free
                boot.FSNext = fsinfo.Next
        end

        if boot.Sectors > 0 then
                boot.HugeSectors = 0
                boot.NumSectors = boot.Sectors
        else
                boot.NumSectors = boot.HugeSectors
        end

	boot.ClusterOffset = math.ceil((boot.RootDirEnts * 32 + boot.BytesPerSec - 1) / boot.BytesPerSec)
	    + boot.ResSectors
	    + boot.NumFATs * boot.FATsecs
            - CLUST_FIRST * boot.SecPerClust

        boot.NumClusters = math.floor((boot.NumSectors - boot.ClusterOffset) / boot.SecPerClust)

        if (boot.flags & FLAG_FAT32) == FLAG_FAT32 then
                boot.ClustMask = CLUST32_MASK
        elseif (boot.NumClusters < (CLUST_RSRVD & CLUST12_MASK)) then
                boot.ClustMask = CLUST12_MASK
        elseif (boot.NumClusters < (CLUST_RSRVD & CLUST16_MASK)) then
                boot.ClustMask = CLUST16_MASK
        else
                print("Filesystem too big (%u clusters) for non-FAT32 partition", boot.NumClusters)
        end

        if boot.ClustMask == CLUST32_MASK then
                boot.NumFatEntries = (boot.FATsecs * boot.BytesPerSec) / 4;
        elseif boot.ClustMask == CLUST16_MASK then
                boot.NumFatEntries = (boot.FATsecs * boot.BytesPerSec) / 2;
        else
                boot.NumFatEntries = (boot.FATsecs * boot.BytesPerSec) * 2 / 3;
        end

        boot.NumFatEntries = math.floor(boot.NumFatEntries)
	boot.ClusterSize = boot.BytesPerSec * boot.SecPerClust;
	boot.NumFiles = 1;
        boot.NumFree = 0;

        return boot
end

function F.is_dirty(boot)
        local dirty = nil
        local buffer = F.read("Dirty", boot.ResSectors * boot.BytesPerSec, boot.BytesPerSec)

        if boot.ClustMask == CLUST16_MASK then
                local val = Bytes(buffer, 3, 1)
                dirty = ((val & 0xc0) == 0xc0)
        elseif boot.ClustMask == CLUST32_MASK then
                local val = Bytes(buffer, 7, 1)
                dirty = ((val & 0x0c) == 0x0c)
        end

        return dirty
end

function F.read_fat(boot)
        local n = 0
        if boot.ValidFat >= 0 then
                n = boot.ValidFat
        end

        local offset = (boot.ResSectors + n * boot.FATsecs) * boot.BytesPerSec
        local size = boot.FATsecs * boot.BytesPerSec
        local buffer = F.read("FATEnts", offset, size)
        local fat_entry_offset = 4
        local idx = 0

        if boot.ClustMask == CLUST16_MASK then
                fat_entry_offset = 2
        elseif boot.ClustMask == CLUST32_MASK then
                fat_entry_offset = 4
        end

        local fatents = {
                [1] = { next = 0, },
                [2] = { next = 0, },
        }

        idx = idx + fat_entry_offset * 2
        for fidx = CLUST_FIRST + 1, boot.NumClusters do
                local entry = {
                        next = Bytes(buffer, idx, fat_entry_offset) & boot.ClustMask
                }
                table.insert(fatents, entry)
                idx = idx + fat_entry_offset
        end

        --table.sort(fatents, function(a, b) return a.next < b.next end)

        return fatents
end

local function test_bit(num, bit)
        return (1 << bit) == (num & (1 << bit))
end

local function hex_string(num)
        return string.format("0x%08X", num)
end

local function parse_long_name(short_name, buffer, idx, count)
        local name = short_name
        local items = {}
        local sections = {
                { start =  1, len = 10, },
                { start = 14, len = 12, },
                { start = 28, len =  4, },
        }
        for i = idx - 32, 1, -32 do
                for _, section in ipairs(sections) do
                        for n = i + section.start, i + section.start + section.len - 1, 2 do
                                local b1 = string.byte(buffer, n)
                                local b2 = string.byte(buffer, n + 1)
                                if b2 == 0 and b1 > 0 then
                                        table.insert(items, string.format("%c", b1))
                                end
                        end
                end

                local attr = string.byte(buffer, i)
                if test_bit(attr, 6) then break end
        end

        return table.concat(items)
end

local function tabify(name, deleted, n)
        local tabs = {}
        for i = 1, n do
                table.insert(tabs, "--")
        end

        if deleted then
                table.insert(tabs, "[DELETED]")
        end

        table.insert(tabs, name)

        return table.concat(tabs)
end

local function is_dot_dir_name(name)
        return string.byte(name, 1) == 46 -- '.' == 46
end

function F.read_dir(boot, dir_addr, depth_n)
        local offset = dir_addr
        local dir_depth = 0
        local dir_entry_size = 32
        local items = { }
        local longname_idx = 0
        local lba_cluster_base = (boot.ResSectors + boot.NumFATs * boot.FATsecs) * boot.BytesPerSec
        local cluster_size = boot.SecPerClust * boot.BytesPerSec

        -- Root dir
        if not offset then
                offset = lba_cluster_base
                print("idx\tdir?\tlong?\tcluster\t\tname")
        else
                dir_depth = depth_n
        end

        local size = 64 * dir_entry_size
        local buffer = F.read("DIRs", offset, size)

        if not buffer then
                print("Failed to read dir")
                return
        end

        for idx = 1, #buffer, dir_entry_size do
                if 0x00 == string.byte(buffer, idx) then
                        --print("End of dir list")
                        break
                end

                local attr = Bytes(buffer, idx + 11 - 1, 1)
                local is_longdir = (0x0F == (attr & 0x0F))
                if is_longdir then
                        longname_idx = longname_idx + 1
                else
                        local dir = {
                                name = string.sub(buffer, idx, idx + 11 - 1),
                                deleted = false,
                        }
                        local is_dir = test_bit(attr, 4)
                        local is_dotdot_dir = is_dot_dir_name(dir.name)

                        if FLAG_DELETE == string.byte(dir.name, 1) then
                                dir.deleted = true
                        end

                        if longname_idx > 0 then
                                dir.name = parse_long_name(dir.name, buffer, idx, count)
                        end

                        local cllow = Bytes(buffer, idx + 0x1A - 1, 2)
                        local clhig = Bytes(buffer, idx + 0x14 - 1, 2)
                        local cluster = cllow + (clhig << 16)

                        --print(is_dotdot_dir, I.inspect(dir.name))
                        if not is_dotdot_dir then
                                print(math.ceil(idx / dir_entry_size), is_dir, longname_idx, hex_string(cluster), tabify(dir.name, dir.deleted, dir_depth))
                        end

                        -- Travel sub directory
                        if is_dir and (not is_dotdot_dir) then
                                local cluster_addr = lba_cluster_base + (cluster - CLUST_FIRST) * cluster_size
                                F.read_dir(boot, cluster_addr, dir_depth + 1)
                        end

                        table.insert(items, dir)
                        longname_idx = 0
                end
        end

        return items
end

return F
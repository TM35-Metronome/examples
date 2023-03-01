local data = { data = {} }

for line in io.lines() do
    local field = "data"
    local root = data

    local i = 1
    while true do
        ::continue::

        local field_start, field_end = line:find("^%.[^.=[]*", i)
        if field_start ~= nil then
            if root[field] == nil then
                root[field] = {}
            end

            root = root[field]
            field = line:sub(field_start + 1, field_end)
            i = field_end + 1
            goto continue
        end

        local array_start, array_end = line:find("^%[%d*%]", i)
        if array_start ~= nil then
            if root[field] == nil then
                root[field] = {}
            end

            root = root[field]
            field = tonumber(line:sub(array_start + 1, array_end - 1))
            i = array_end + 1
            goto continue
        end

        local value_start, value_end = line:find("^=.*$", i)
        if value_start ~= nil then
            root[field] = line:sub(value_start + 1, value_end)
        else
            print("Error")
        end
        break
    end
end

local root = data.data

-- `root` does not contain anything lua considers an array, so we cannot do
-- `items[math.random(#items)]`. To workaround this, we construct actualy arrays for the maps we
-- wonna access random values from.
local starters = {}
for k, _ in pairs(root.starters) do
    table.insert(starters, k)
end

local pokemons = {}
for k, _ in pairs(root.pokemons) do
    table.insert(pokemons, k)
end

for _, k in pairs(starters) do
    root.starters[k] = pokemons[math.random(#pokemons)]
    print(k, root.starters[k])
end

function output(prefix, value)
    if type(value) == "table" then
        for k, v in pairs(value) do
            if type(k) == "number" then
                output(prefix .. "[" .. tostring(k) .. "]", v)
            else
                output(prefix .. "." .. k, v)
            end
        end
    else
        io.write(prefix, "=", value, "\n")
    end
end

output("", root)

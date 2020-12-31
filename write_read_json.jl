import JSON
###################
### Write data ####
###################
# dictionary to write
dict1 = Dict("param1" => 1, "param2" => 2,
            "dict" => Dict("d1" => 1., "d2" => 1., "d3" => 1.))
            
# pass data as a json string (how it shall be displayed in a file)
stringdata = JSON.json(dict1)

# write the file with the stringdata variable information
open("write_read.json", "w") do f
    write(f, stringdata)
end

###################
### Read data #####
###################
# create variable to write the information
dict2 = Dict()
open("write_read.json", "r") do f
    global dict2
    dicttxt = readall(f)  # file information to string
    dict2 = JSON.parse(dicttxt)  # parse and transform data
end

# print both dictionaries
println(dict1)
println(dict2)
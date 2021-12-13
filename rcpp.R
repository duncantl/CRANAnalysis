usesRcpp = 
function(pkg, desc = readDescription(pkg), all = TRUE)
{
   uses = lapply(c("Imports", "Depends", "LinkingTo", "Suggests"),
                 function(x) sapply(desc[[x]], `[`, 1))
   "Rcpp" %in% unlist(uses)                  
}

readDescription =
function(pkg, split = TRUE)
{
    d = tools:::.read_description(file.path(pkg, "DESCRIPTION"))
    if(split)
        tools:::.split_description(d)
    else
        d
}


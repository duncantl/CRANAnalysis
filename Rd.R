getRdInfo =
function(file, rd = parse_Rd(file))
{

    if(file.info(file)$isdir) {
        rd = list.files(file, pattern = "\\.[Rr]d$", full = TRUE)
        return(do.call(rbind, lapply(rd, getRdInfo)))
    }
    
    
    aliases = tools:::.Rd_get_metadata(rd, "alias")
    ndescription = nchar(tools:::.Rd_get_metadata(rd, "description"))
    nvalue = nchar(tools:::.Rd_get_metadata(rd, "value"))
    if(length(nvalue) == 0)
        nvalue = NA

    numConcepts = length(tools:::.Rd_get_metadata(rd, "concept"))
    numKeywords = length(tools:::.Rd_get_metadata(rd, "keyword"))

    args = tools:::.Rd_get_argument_table(rd)
    sm = summary(nchar(args[,2]))
    names(sm) = paste("argLen", names(sm), sep = ".")
    
    ans = data.frame(ndescription = ndescription, nvalue = nvalue, numAliases = length(aliases),
                     numConcepts = numConcepts, numKeywords = numKeywords, file = file)
    cbind(ans, as.list(sm))
}




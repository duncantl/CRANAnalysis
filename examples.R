fnsInExample =
function(file, rd = parse_Rd(file),
         code = tools:::.Rd_get_metadata(rd, "examples"))
{
    code2 = parse(text = code)
    k = lapply(code2, findCallsTo)
    table(unlist(lapply(k, function(x) sapply(x, function(x) as.character(x[[1]])))))
}

parseAliases =
function(x)
{
    s4 = grepl("-method$", x)
    m4 = gsub(",.*", "", x[s4])

    m42 = lapply(strsplit(gsub("-method$", "", x[s4]), ","), `[`, -1)
    names(m42) = m4
    
    s3 = grepl("\\.", x[!s4])
    m3 = data.frame(fun = gsub("\\..*", "", x[!s4][s3]),
                    class = gsub(".*\\.", "", x[!s4][s3]))

    x = x[!s4][!s3]
    list(vars = x, s4 = m42, s3 = m3)
}

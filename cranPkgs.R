getCRANPkgNames =
function(dir = "~/CRAN2/Pkgs3", removeOld = TRUE)
{
    dirs = list.files(dir, full.names = TRUE)
    info = file.info(dirs)
    dirs = dirs[info$isdir]

    ex = file.exists(file.path(dirs, "DESCRIPTION"))

    dirs = dirs[ex]

    if(removeOld)
        dirs = grep('\\.old$', dirs, value = TRUE, invert = TRUE)

    dirs
}

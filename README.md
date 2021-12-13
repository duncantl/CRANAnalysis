1# Partial Analysis of CRAN Packages

### Help Files

How do Roxygen-generated help files compare to those that are manually generated.

+ How many help files are there in a package?
+ How many packages use Roxygen?
+ Compare length of each section for oxygen versus regular Rd.
  + examples?
+ number of examples ? or simpler size of examples?
+ number of objects being documented in each file.


My hypothesis is that Roxygen is very useful for documenting parameters, title and description
but not as good for longer, multi-line/paragraph-oriented sections such as example, value.

According to a comment in the XRJulia package, the Roxygen mechanism isn't good at generating help
files for S4 classes.

Writing examples in Roxygen is problematic as there is no syntax highlighting as these are comments.
(Is there a different editing mode within @example sections?)

## 

```r
pkgs = getCRANPkgNames()
```

Within each package, determine which Rd files are Roxygen-generated and which are not:
```r
roxy = lapply(file.path(pkgs, "man"), roxygenFiles)
names(roxy) = basename(pkgs)
```

The overall number of help files within each package
```r
numHelpFiles = sapply(roxy, length)
```

Are the help files  all of the same type - Roxgyen or regular Rd - or mixed (2 types):
```r
nu = sapply(roxy, function(x) length(unique(x)))
table(nu)
```
```
    0     1     2 
   18 17514   840 
```
So  
+ 18 packages have no help pages,
+ 840 use both Rd and Roxygen.


For the packages that have only one type, how many are Roxygen (TRUE) and how many are manually created:
```r
table( sapply(roxy[nu == 1] , unique))
```
```
FALSE  TRUE 
 6586 10928 
```
So almost twice as many packages use Roxgyen.  (37.6% and 62.4%.)


The packages that have no help files are 
```
 [1] "bartMachineJARs"              "clean"                        "fontBitstreamVera"           
 [4] "fontLiberation"               "GreedyExperimentalDesignJARs" "hse"                         
 [7] "Myrrixjars"                   "openNLPdata"                  "RKEAjars"                    
[10] "RMOAjars"                     "ROI.plugin.clp"               "ROI.plugin.cplex"            
[13] "ROI.plugin.glpk"              "ROI.plugin.ipop"              "ROI.plugin.symphony"         
[16] "rsparkling"                   "RWekajars"                    "Sejong"                      
```
Many of these simply provide Java jar files.
The hse is deprecate and provides no functions, just a message to use another package.



Of those packages that use both Roxygen and manually created help files, the majority of these use Roxygen more than Rd files.
```r
table(both[,1] <= both[,2])
```
```
FALSE  TRUE 
  176   723 
```

We can see this in more detail with the actual number of files of each type for each package:
```r
both = t(sapply(roxy[nu == 2], table))
```
```r
plot(both[,1], both[,2], xlab = "Number of Rd files", ylab = "Number of Roxygen files")
abline(a = 0,  b = 1, col = "red")
```

So Roxygen is popular.
Let's look at the characteristics of the help files for Roxygen and manual content.


## Examples
We start with the examples.
We get them by package rather than file as `rooxy` is arranged by package:
```r
egs = lapply(roxy, function(x) {
                        ans = data.frame(file = names(x), roxygen = x)
						ans$example = lapply(names(x), function(f) try(capture.output(Rd2ex(f))))
						ans
						})
```

Now we combine them to a per-file basis:
```
egsAll = do.call(rbind, egs)
```


For the 121 files for which there was an error, we can get the example content directly
```
err = sapply(egsAll$example, inherits, 'try-error')
tmp = sapply(egsAll$file[err], function(f) tools:::.Rd_get_metadata(parse_Rd(f), "examples"))
egsAll$example[err] = tmp
```
The errors wewre because of the dynamic content in the Rd files about which we don't care.


Next, we compute the total number of characters in the examples for each file:
```r
egsAll$egLen = sapply(egsAll$example, function(x) sum(nchar(x)))
```


There are 213 Rd files with an examples section  with more than 10,000 characters.
72/141 of these are Roxygen files.
One example is zenplots/R/zenplot.R 
The example code is in the Roxygen comments, i.e., ##\'
This means that there is no syntax highlighting helping the author!


## Other Rd Information

We repeat some of the computations as we did this in a separate parallel sessioon:
```r
pkgs = getCRANPkgNames()
manDirs = file.path(pkgs, "man")
e = file.exists(manDirs)
rds = lapply(manDirs[e], list.files, full = TRUE, pattern = "\\.[Rr]d$")
```

We'll work by file rather than package
```r
rds2 = unlist(rds, use.names = FALSE)
```

```r
isRoxy = sapply(rds2, isRoxygen)
```
(3 minutes, 377K files)

```r
system.time({rdinfo = lapply(rds2, getRdInfo)})
```
3924 seconds (65 minutes)


Now we combine these into a single data.frame with a row per Rd file:
```r
rdinfo2 = do.call(rbind, rdinfo)
```
(Takes 2 1/2 minutes.)


```r
rdinfo2$roxygen = isRoxy
```

We'll look at each of  the numeric columns (so not file and roxygen)
and summarize the distribution of each for roxygen and maniually created file so we can compare them:
```
sm = lapply(names(rdinfo2)[-c(6, 13)], function(v) sapply(split(rdinfo2[[v]], rdinfo2$roxygen), summary))
names(sm) = names(rdinfo2)[-c(6, 13)]
```

Excluding min and max and the number of NAs, we see how many categories
the manual Rd files have more content than the Roxygen help files:
```
tmp = sapply(sm, function(x) apply(x[2:5,], 1, function(x) x[1] - x[2]))
```
```
        ndescription nvalue numAliases numConcepts numKeywords argLen.Min. argLen.1st Qu. argLen.Median argLen.Mean argLen.3rd Qu. argLen.Max.
1st Qu.         18.0     20      0.000      0.0000       0.000        2.00           3.00          3.50        4.61           5.00         8.0
Median          29.0     60      0.000      0.0000       1.000        2.00           4.50          6.50        8.57          10.25        19.0
Mean            33.5    124      0.542     -0.0303       0.731        1.27           3.05          4.95        6.48           8.17        20.4
3rd Qu.         31.0    186      0.000      0.0000       1.000        3.00           5.75          9.00       11.00          14.50        29.0
```
So for all but one category, the mean of numConcepts, the maually created content is slightly larger
than for the Roxyggen content.  But basically the number of concepts is 0 for all packages.
Also, the mean is not useful measure.

The description and value sections have about 29 and 60 characters more for the manually created files.
The content describing each parameter/argument has about 6.5 characters more for the manual files.
```r
q = lapply(split(rdinfo2$nvalue, rdinfo2$roxygen), quantile, seq(0, 1, length = 1000), na.rm = TRUE)
qqplot(q[[1]], q[[2]], main = "Length of value section", xlab = "Roxygen", ylab = "Rd")
abline(a = 0, b = 1, col = "red", lty = 2)
```

Looking at the lenggth of the examples
```r
sapply(split(egsAll$egLen, egsAll$roxygen), summary)
```
```
             FALSE       TRUE
Min.        0.0000     0.0000
1st Qu.     0.0000     0.0000
Median    266.0000   180.0000
Mean      507.4459   331.9814
3rd Qu.   590.0000   417.0000
Max.    64257.0000 42636.0000
```
So the examples tend to be longer for manually created files.



## Rd Files with no Example.

```r
nn = sapply(egsAll$example, length)
table(nn == 0)
```
```r
table(roxygen = egsAll$roxygen, hasExample = nn != 0)
       hasExample
roxygen  FALSE   TRUE
  FALSE  36013  92478
  TRUE  102747 146573
```
This shows that, overall, about 36.7% of the help files have no example
but 55.6% of Roxygen files have no example, while 28% of manually created content files have no example.

Of course, all the examples for a package could be in a single Rd file, whether it is
Roxygen-generated or not. So we have to look at this at the package level.

We get the package name:
```r
egsAll$pkg = basename(dirname(dirname(egsAll$file)))
```

And now we compute the packge-level statistics about the examples;
```r
pkg = by(egsAll, egsAll$pkg, function(x) data.frame(package = x$pkg[1], 
                                                    numHelpFiles = nrow(x),
                                                    numRoxygenFiles = sum(x$roxygen),
													exampleSize = sum(nchar(unlist(x$example))),
                                                    numWithExamples = sum(sapply(x$example, length) > 0)))
pkg2 = do.call(rbind, pkg)
pkg2$pctRoxygen = pkg2$numRoxygenFiles/pkg2$numHelpFiles
```
<!--
```r
with(pkg2, plot(numHelpFiles, numWithExamples, col = c("red", "blue")[ (pctRoxygen > .5) + 1L ], pch= "."))
```
-->


A numerical summary may be easier to see and we look at the percent of files within packages that have an example
for manually created and Roxygen created Rd files 
```r
sapply(split(pkg2$numWithExamples/pkg2$numHelpFiles,  pkg2$pctRoxygen > .5), summary)
```
```
        FALSE TRUE
Min.     0.00 0.00
1st Qu.  0.62 0.44
Median   0.88 0.71
Mean     0.77 0.66
3rd Qu.  1.00 0.92
Max.     1.00 1.00
```
So, as we saw with the individual files,  Roxygen-based packages have fewer examples.
This is a somewhat similar view as before.


Let's look at the total size of all examples in a package
```
library(ggplot2)
ggplot(pkg2[pkg2$exampleSize < 2e4,], aes(x = exampleSize, color = pctRoxygen > .5)) + geom_density() + xlab("Total size of package examples")
```

<!--
```
tmp = pkg2[ pkg2$exampleSize < 2e4, ]
plot(density(tmp$exampleSize[tmp$numRoxygenFiles >= .5], from = 0),main = "")
lines(density(tmp$exampleSize[tmp$numRoxygenFiles < .5], from = 0), col = "red")
title(c("Size (num. characters) of Package Examples", "Roxygen versus Manual Content"))
```
-->

## How Many Package have Native Code

Deal with subdirectories of src/.

```r
hasSrcDir = file.exists(file.path(pkgs, "src"))
```
```r
table(hasSrcDir)
FALSE  TRUE 
14797  4652 
```

So 76% don not have native code, and 24% do.

The number of files in each src/ directory
```r
numSrcFiles = sapply(file.path(pkgs[hasSrcDir], "src"), function(d) length(list.files(d)))
```
These may include non-code files and directories.  And we don't look at subdirectories which may
contain platform-specific code or supporting code that is compiledd separately and linked the
package's DSO.

Extensions of these files
```r
pkg.src.extensions = lapply(file.path(pkgs[hasSrcDir], "src"), function(d) tools::file_ext(list.files(d)))
names(pkg.src.extensions) = basename(pkgs[hasSrcDir])
```

```r
tt = table(unlist(pkg.src.extensions))
dsort(tt[c("cpp", "cc", "c", "cu", "cuh", "h", "hpp", "f90", "f", "f95")])
```
```
  cpp     h     c     f    cc   f90   hpp   f95    cu   cuh 
16354 11644 11279  1480  1329   761   101    78    26     3 
```
(dsort is a descending-sort function.)


```r
langs = list("C++" = c("cpp", "cc", "hpp"),
             "C" = c("c", "h"),
			 "CUDA" = c("cu", "cuh"),
			 "FORTRAN" = c("f", "f90", "f95"))

sapply(langs, function(x) sum(tt[x]))
```
```
    C++       C    CUDA FORTRAN 
  17784   22923      29    2319 
```
The .h files could be C++-specific.


So the majority of the files are C, but not by much - 53.2% versus 41% for C++.
FORTRAN is 5% and CUDA 0.06%.
And there are more .cpp/.cc files than .c files. It is treating the header files
as C that makes C look larger than C++.

How many of these packages with src/ directories have C++ files?
```r
hasCpp = sapply(pkg.src.extensions, function(x) "cpp" %in% x)
table(hasCpp)
FALSE  TRUE 
 1792  2860 
```
So the majority apparently use C++.

An obvious question is 
+ how many of the C++ files actually use C++ features and are not simply C files with a different extension.
   + how many define or use classes?  
   + how many use C++ libraries (e.g. the std library)?
   + how many use C++ syntactic conveniences?
   + how many only use Rcpp syntactic conveniences?


## Number of Packages that Use Rcpp

```r
Rcpp = sapply(pkgs, usesRcpp)
```

```r
table(Rcpp)
```
```
FALSE  TRUE 
16790  2659 
```

```r
table(sapply(pkgs[hasSrcDir], usesRcpp))
```
```
FALSE  TRUE 
 2067  2585 
```
Of the packages that have native code, 55.6% use Rcpp and 44.4% do not.


## Exports and Internal Symbols

+ How many functions are exported? unexported?




##

```r
system.time({pkgDescs =  lapply(pkgs, readDescription, FALSE)})
```

```
fields = data.frame(fieldName = unlist(sapply(pkgDescs, names)), 
                    value = unlist(pkgDescs),
                    pkg = rep(basename(pkgs), sapply(pkgDescs, length)))
```




## How Many have a configure script

```r
e = file.exists(file.path(pkgs, "configure"))
```
Only 379. And 231 have a configure.ac file, and 3 have a configure.in file.
416 have a cleanup file.

207 have a configure.win file.

How many have platform-specific code? e.g., use `.Platform$OS.type`?


## Top-level Package Files
```r
topFiles = lapply(pkgs, list.files)
dsort(table(unlist(topFiles)))
```

```r
topFiles = lapply(pkgs, function(dir) file.info(list.files(dir, all = TRUE, full = TRUE)))
files = do.call(rbind, topFiles)
files$name = basename(rownames(files))
```

```
dirs = files$name[files$isdir]
```
```
                 man                    R                 inst                 data 
               18354                18276                11386                 8437 
               build                tests            vignettes                  src 
                7930                 6990                 6952                 4297 
                demo                tools                 java                   po 
                 667                  338                  106                   97 
                exec                noweb  proj_conf_test.dSYM               README 
                  35                    6                    4                    4 
                 doc           a.out.dSYM                  dev                  etc 
                   3                    2                    2                    2 
             extdata             src-java                  blp              clients 
                   2                    2                    1                    1 
              divers                 docs             examples             Examples 
                   1                    1                    1                    1 
          fftw-3.3.8                  jri                macos                  org 
                   1                    1                    1                    1 
                orig proj_conf_test1.dSYM             testsDev 
                   1                    1                    1 
```


```
files[ !(files$name %in% c("DESCRIPTION", "NAMESPACE")), ]
```




## How Many Vignettes


```
v = file.path(pkgs, "vignettes")
v = v[file.exists(v)]
```
```
vfiles = lapply(v, function(dir) { f = list.files(dir); f[ !grepl("\\.(png|pdf|ps|eps|jpeg|jpg|gif|tiff|tif|svg|img|fig|bib|bst|dtx|sty|rdata|rda|rds|r?save|sav|xls|xlsx|docx|csv|json|yml|yaml|sh|gz|zip|pptx|key|js|py|rst|r|cpp|c|h|hpp|d|sqlite|vcf|css|graffle|dia|drawio|rpkm|mp4|db|stan|bat|dcf|bmp|oauth|dna)$", tolower(f)) ]})
names(vfiles) = basename(dirname(v))
```

```r
summary(sapply(vfiles, length))
table(sapply(vfiles, length))
plot(density(sapply(vfiles, length)))
```

So of those packages that have a vignette, 50% have 1.



Let's look at the extensions:
```r
ext = unlist(lapply(vfiles, file_ext))
dsort(table(ext))
```


```r
tmp = lapply(file.path(pkgs, "vignettes"),  list.files, all = TRUE, full = TRUE, no.. = TRUE)
fi = data.frame(ext = file_ext(unlist(tmp)),
                file = unlist(tmp))
fi$pkg = basename(dirname(dirname(unlist(fi$file))))
```


We find the file/mime-type for these extensions using the
[dqmagic package](https://github.com/daqana/dqmagic) and [libmagic](https://github.com/file/file):
<!--
Hangs on /Users/duncan/CRAN2/Pkgs3/convergEU/vignettes/une_educ_a.xls
```r
ty = by(fi, fi$ext, function(x) system(sprintf("file %s", x$file[1]), intern = TRUE))
```
-->

```r
tmp = tapply(fi$file, fi$ext, `[`, 1)
types = dqmagic::file_type(tmp)
```

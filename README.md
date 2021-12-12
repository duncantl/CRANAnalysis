
+ How many functions are exported? unexported?


### Help Files
+ How many help files are there in a package?
+ How many packages use Roxygen?
+ Compare length of each section for oxygen versus regular Rd.
  + examples?
  
+ number of examples ? or simpler size of examples?
+ number of objects being documented in each file.


My hypothesis is that Roxygen is very useful for documenting parameters, title and description
but not as good for longer, multi-line/paragraph-oriented sections such as example, value.


According to the XRJulia package, the Roxygen mechanism isn't good at generating help files for S4 classes.

## 

```r
pkgs = getCRANPkgNames()
```

```r
roxy = lapply(file.path(pkgs, "man"), roxygenFiles)
names(roxy) = basename(pkgs)
```

The overall number of help files
```r
numHelpFiles = sapply(roxy, length)
```

Whether the help files are all of the same type - Roxgyen or regular Rd - or mixed (2 types):
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



And of those packages that use both, the majority of these use Roxygen more than Rd files.
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

So 76% don't have native code, and 24 do.

```r
numSrcFiles = sapply(file.path(pkgs[hasSrcDir], "src"), function(d) length(list.files(d)))
```

Extensions
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





## Examples

```r
egs = lapply(roxy, function(x) {
                        ans = data.frame(file = names(x), roxygen = x)
						ans$example = lapply(names(x), function(f) try(capture.output(Rd2ex(f))))
						ans
						})
```


```
egsAll = do.call(rbind, egs)
```

```
err = sapply(egsAll$example, inherits, 'try-error')

tmp = sapply(egsAll$file[err], function(f) tools:::.Rd_get_metadata(parse_Rd(f), "examples"))
egsAll$example[err] = tmp
```

```r
egsAll$egLen = sapply(egsAll$example, function(x) sum(nchar(x)))
```


There are 213 Rd files with an examples section 
72/141 of these are Roxygen files.
One example is zenplots/R/zenplot.R 
The example code is in the Roxygen comments, i.e., ##\'
This means that there is no syntax highlighting helping the author!


## 


```r
pkgs = getCRANPkgNames()
manDirs = file.path(pkgs, "man")
e = file.exists(manDirs)
rds = lapply(manDirs[e], list.files, full = TRUE, pattern = "\\.[Rr]d$")
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


```r
rdinfo2 = do.call(rbind, rdinfo)
```
(Takes 2 1/2 minutes.)


```r
rdinfo2$roxygen = isRoxy
```


```
sm = lapply(names(rdinfo2)[-c(6, 13)], function(v) sapply(split(rdinfo2[[v]], rdinfo2$roxygen), summary))
names(sm) = names(rdinfo2)[-c(6, 13)]
```

Excluding min and max and the number of NAs, see how many categories
the manual Rd files have more content than the Roxygen help files:
```
tmp = sapply(sm, function(x) apply(x[2:5,], 1, function(x) x[1] - x[2]))
tmp
```
So all but one category, the mean of numConcepts. But basically this is 0 for all packages.
The mean is not a reliable number.

The description and value sections have about 29 and 60 characters more for the manual files.
The arguments have about 6.5 characters more for the manual files.

```r
q = lapply(split(rdinfo2$nvalue, rdinfo2$roxygen), quantile, seq(0, 1, length = 1000), na.rm = TRUE)
qqplot(q[[1]], q[[2]], main = "Length of value section", xlab = "Roxygen", ylab = "Rd")
abline(a = 0, b = 1, col = "red", lty = 2)
```


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
So the examples are longer for manually created files.

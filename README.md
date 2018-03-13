
FBadstats
=========

R Package for generating statistics from Facebook ads performance data. Assists with ad targeting by aggregating data across multiple ad sets or campaigns in an attractive way. Works with many kinds of column selections from Facebook Ads Manager including Campaign, Ad Set, and Ad primary views. Currently only includes the breakdown Group analyzer function `FBadGstats`.
*Disclaimer: This function and the entire `FBadstats` package are not supported or endorsed by Facebook, Inc. Only the user is responsible for its use.*

Installation
------------

First install the free (open-source) statistical software (and language) named "R" at: <http://cran.rstudio.com/>

Then download the most popular software to make using R easier, RStudio. The free version will be perfect. Scroll down and choose the appropriate installer under **Installers for Supported Platforms** at: <https://www.rstudio.com/products/rstudio/download/>

Open RStudio and you can now install the `FBadstats` package from github by entering the following in RStudio:

``` r
## This first package is to enable the install_github function
install.packages("devtools")
## Now we can always load that package with
library("devtools")
## Install FBadstats
devtools::install_github("RickPack/FBadstats")
```

Easiest use - select a file or folder
-------------------------------------

The easiest use is to call the function, navigate to your exported CSV file and then select it. The default parameters may give you all you need.

### Call the function

``` r
FBadGstats()
```

### Select your file

![Windows Explorer file-selection](README-selectCSV.png)

### Use the output

![Portion of FBadGstats output](README-example.png)

You can select a folder and process all of the .CSV files with:

``` r
FBadGstats(choosedir="YES")
```

Advanced usage - modifying parameters
-------------------------------------

### Advanced Example 1/3

``` r
## Load FBadstats
library("FBadstats")
# Show only the best performing groups and include the graphical output
FBadGstats(filerd = "example_DMA.csv", grphout = "YES", tblout = "BEST")
#> Joining, by = "DMA.REGION"
#> [1] "-------------------------------------------------------------"
#> [1] "BEST: LINK CLICKS in example_DMA.csv"
#>                    DMA.REGION rnkevent sumevent costevent sumspent
#> 1                  Wilmington        1        1      0.32     0.32
#> 2                 Gainesville        2        1      0.35     0.35
#> 3      Little Rock-Pine Bluff        3        8      0.38     3.00
#> 4                    Syracuse        4        1      0.41     0.41
#> 5                   Anchorage        5        1      0.45     0.45
#> 6                   Knoxville        6        1      0.48     0.48
#> 7                  Cincinnati        7        7      0.51     3.57
#> 8   Tampa-St. Pete (Sarasota)        8        7      0.53     3.73
#> 9        El Paso (Las Cruces)        9        1      0.54     0.54
#> 10        Richmond-Petersburg       10        5      0.58     2.88
#> 11      Tucson (Sierra Vista)       11        1      0.59     0.59
#> 12                  Milwaukee       12        2      0.66     1.31
#> 13          Waco-Temple-Bryan       13        3      0.68     2.05
#> 14                Baton Rouge       14        6      0.69     4.12
#> 15              Lafayette, LA       15        2      0.71     1.42
#> 16               Columbus, OH       16        5      0.74     3.68
#> 17                    Buffalo       17        2      0.76     1.51
#> 18 Grand Rapids-Kalmzoo-B.Crk       18        1      0.87     0.87
#> 19                 Pittsburgh       19        2      0.89     1.78
#> 20                  San Diego       20        2      0.92     1.83
#> [1] "Number of groups in all of data: 135"
#> [1] "Number of DMA REGION groups with at least one LINK CLICKS and minimum spend of $0 = 63"
#> [1] "Total amount spent: $320.47"
#> Joining, by = "AD.SET.NAME"
```

<img src="README-example1-1.png" style="display: block; margin: auto;" />

    #> [1] "-------------------------------------------------------------"
    #> [1] "BEST: LINK CLICKS in example_DMA.csv"
    #>                      AD.SET.NAME rnkevent sumevent costevent sumspent
    #> 1 ProBook_xPg_SendLane2544hotreg        1       91      1.30   118.02
    #> 2  ProBook_AllPg_75kAccSeLaneReg        2       13      1.40    18.26
    #> 3    ProBook_SendLaneB2544hotreg        3        5      1.42     7.10
    #> 4      ProBook_Pg_LkDev75k+_5562        4        8      1.60    12.79
    #> 5      ProBook_Pg_LkDev75k+_3544        5       34      1.69    57.39
    #> 6     ProBook_Pg_75kAccSeLaneReg        6       45      1.82    81.93
    #> 7        ProBook_Pg_75kSeLaneReg        7        3      2.12     6.35
    #> 8  ProBook_xPg_6txt_SendLane2544        8        4      3.76    15.03
    #> [1] "Number of groups in all of data: 11"
    #> [1] "Number of AD SET NAME groups with at least one LINK CLICKS and minimum spend of $0 = 8"
    #> [1] "Total amount spent: $320.47"

<img src="README-example1-2.png" style="display: block; margin: auto;" />

### For A/B testing, use the `filtervar` and `filtervarneg` parameters.

Here we see BOTH \[default for tblout parameter\] the top 3 and worst 3 Age / Gender groups in a comparison between where "6txt" did (parameter `filtervar` = "hotreg") and did not (parameter `filtervarneg` = "hotreg") appear in the ad set name.
At least two events (clicks) must have occurred. Otherwise, an anomalous single event for 25-34 males caused that group to appear.
"Hotreg" indicated where selected regions with a history of performing well were the only ones targeted with the advertisement.

### Advanced Example 2/3

``` r
FBadGstats(filerd = "example_PerfClk_AgeGender.csv", filtervar = 'hotreg',    printrow = 3, minevent = 2, grphout = "NO")
#> Joining, by = "AGE_GENDER"
#> [1] "-------------------------------------------------------------"
#> [1] "WORST: RESULTS in example_PerfClk_AgeGender.csv"
#>     AGE_GENDER rnkevent sumevent costevent sumspent
#> 1 35-44:female        3       40      1.91    76.27
#> 2 25-34:female        2       30      1.53    45.91
#> 3   35-44:male        1       11      0.14     1.55
#> [1] "BEST: RESULTS in example_PerfClk_AgeGender.csv"
#>     AGE_GENDER rnkevent sumevent costevent sumspent
#> 1   35-44:male        1       11      0.14     1.55
#> 2 25-34:female        2       30      1.53    45.91
#> 3 35-44:female        3       40      1.91    76.27
#> [1] "Number of groups in all of data: 6"
#> [1] "Number of AGE_GENDER groups with at least one RESULTS and minimum spend of $0 = 3"
#> [1] "Total amount spent: $125.76"
#> Joining, by = "AD.SET.NAME"
#> [1] "-------------------------------------------------------------"
#> [1] "WORST: RESULTS in example_PerfClk_AgeGender.csv"
#>                      AD.SET.NAME rnkevent sumevent costevent sumspent
#> 1    ProBook_SendLaneB2544hotreg        2        3      2.37     7.10
#> 2 ProBook_xPg_SendLane2544hotreg        1       80      1.48   118.02
#> [1] "BEST: RESULTS in example_PerfClk_AgeGender.csv"
#>                      AD.SET.NAME rnkevent sumevent costevent sumspent
#> 1 ProBook_xPg_SendLane2544hotreg        1       80      1.48   118.02
#> 2    ProBook_SendLaneB2544hotreg        2        3      2.37     7.10
#> [1] "Number of groups in all of data: 3"
#> [1] "Number of AD SET NAME groups with at least one RESULTS and minimum spend of $0 = 2"
#> [1] "Total amount spent: $125.76"
FBadGstats(filerd = "example_PerfClk_AgeGender.csv", filtervarneg = 'hotreg', printrow = 3, minevent = 2,   grphout = "NO")
#> Joining, by = "AGE_GENDER"
#> [1] "-------------------------------------------------------------"
#> [1] "WORST: RESULTS in example_PerfClk_AgeGender.csv"
#>     AGE_GENDER rnkevent sumevent costevent sumspent
#> 1 45-54:female        5       41      1.52    62.28
#> 2 25-34:female        4       41      1.39    57.11
#> 3 35-44:female        3       68      1.29    87.93
#> [1] "BEST: RESULTS in example_PerfClk_AgeGender.csv"
#>     AGE_GENDER rnkevent sumevent costevent sumspent
#> 1 18-24:female        1       10      0.84     8.42
#> 2 55-64:female        2       34      1.20    40.84
#> 3 35-44:female        3       68      1.29    87.93
#> [1] "Number of groups in all of data: 14"
#> [1] "Number of AGE_GENDER groups with at least one RESULTS and minimum spend of $0 = 5"
#> [1] "Total amount spent: $258.62"
#> Joining, by = "AD.SET.NAME"
#> [1] "-------------------------------------------------------------"
#> [1] "WORST: RESULTS in example_PerfClk_AgeGender.csv"
#>                     AD.SET.NAME rnkevent sumevent costevent sumspent
#> 1     ProBook_Pg_LkDev75k+_5562        7        6      2.13    12.79
#> 2     ProBook_Pg_LkDev75k+_3544        6       28      2.05    57.39
#> 3 ProBook_AllPg_75kAccSeLaneReg        5       11      1.67    18.37
#> [1] "BEST: RESULTS in example_PerfClk_AgeGender.csv"
#>                     AD.SET.NAME rnkevent sumevent costevent sumspent
#> 1     ProBook_Pg_LeadSendLkUKSA        1       71      0.61    42.99
#> 2  ProBook_Pg_50kLeadSendLkUKSA        2       17      1.22    20.81
#> 3 ProBook_xPg_6txt_SendLane2544        3       11      1.37    15.03
#> [1] "Number of groups in all of data: 10"
#> [1] "Number of AD SET NAME groups with at least one RESULTS and minimum spend of $0 = 7"
#> [1] "Total amount spent: $258.62"
```

### Advanced Example 3/3 (Assign FBadGstats call to a variable in order to explore the data outside of FBadGstats)

##### A list is returned so use \[\[1\]\] for breakdown groups and \[\[2\]\] for Campaign, Ad, or Ad Set, one of which being automatically detected based on the inputfile

``` r
myfbfrm <- FBadGstats(filerd = "Example_AdsView_Region.csv", filtervar = 'Teach', grphout = "NO")
#> Joining, by = "IMPRESSION.DEVICE"
#> [1] "-------------------------------------------------------------"
#> [1] "WORST: RESULTS in Example_AdsView_Region.csv"
#>    IMPRESSION.DEVICE rnkevent sumevent costevent sumspent
#> 1 Android Smartphone        3       14      0.64     9.00
#> 2             iPhone        2       11      0.51     5.61
#> 3     Android Tablet        1        1      0.09     0.09
#> [1] "BEST: RESULTS in Example_AdsView_Region.csv"
#>    IMPRESSION.DEVICE rnkevent sumevent costevent sumspent
#> 1     Android Tablet        1        1      0.09     0.09
#> 2             iPhone        2       11      0.51     5.61
#> 3 Android Smartphone        3       14      0.64     9.00
#> [1] "Number of groups in all of data: 7"
#> [1] "Number of IMPRESSION DEVICE groups with at least one RESULTS and minimum spend of $0 = 3"
#> [1] "Total amount spent: $15.23"
#> Joining, by = "AD.NAME"
#> [1] "-------------------------------------------------------------"
#> [1] "WORST: RESULTS in Example_AdsView_Region.csv"
#>                   AD.NAME rnkevent sumevent costevent sumspent
#> 1          ProBook1_Teach        2       16      0.85    13.59
#> 2 Div_Pwr_Teach100k+_AllD        1       10      0.16     1.64
#> [1] "BEST: RESULTS in Example_AdsView_Region.csv"
#>                   AD.NAME rnkevent sumevent costevent sumspent
#> 1 Div_Pwr_Teach100k+_AllD        1       10      0.16     1.64
#> 2          ProBook1_Teach        2       16      0.85    13.59
#> [1] "Number of groups in all of data: 2"
#> [1] "Number of AD NAME groups with at least one RESULTS and minimum spend of $0 = 2"
#> [1] "Total amount spent: $15.23"
## What are all of the available ad set names?
# 1. First look at the column names in the data
colnames(myfbfrm)
#>  [1] "REPORTING.STARTS"                            
#>  [2] "REPORTING.ENDS"                              
#>  [3] "AD.NAME"                                     
#>  [4] "IMPRESSION.DEVICE"                           
#>  [5] "DELIVERY"                                    
#>  [6] "AMOUNT.SPENT..USD."                          
#>  [7] "UNIQUE.CTR..LINK.CLICK.THROUGH.RATE."        
#>  [8] "RELEVANCE.SCORE"                             
#>  [9] "CTR..ALL."                                   
#> [10] "CTR..LINK.CLICK.THROUGH.RATE."               
#> [11] "VIDEO.PERCENTAGE.WATCHED"                    
#> [12] "POST.REACTIONS"                              
#> [13] "POST.COMMENTS"                               
#> [14] "POST.SHARES"                                 
#> [15] "POSITIVE.FEEDBACK"                           
#> [16] "LINK.CLICKS"                                 
#> [17] "WEBSITE.REGISTRATIONS.COMPLETED"             
#> [18] "WEBSITE.LEADS"                               
#> [19] "WEBSITE.PURCHASES"                           
#> [20] "WEBSITE.CHECKOUTS.INITIATED.CONVERSION.VALUE"
#> [21] "WEBSITE.ADDS.TO.WISHLIST"                    
#> [22] "WEBSITE.CHECKOUTS.INITIATED"                 
#> [23] "WEBSITE.SEARCHES"                            
#> [24] "VIDEO.WATCHES.AT.50."                        
#> [25] "VIDEO.WATCHES.AT.75."                        
#> [26] "REACH"                                       
#> [27] "RESULTS"                                     
#> [28] "RESULT.INDICATOR"                            
#> [29] "X3.SECOND.VIDEO.VIEWS"                       
#> [30] "VIDEO.AVERAGE.WATCH.TIME"                    
#> [31] "BUTTON.CLICKS"                               
#> [32] "BYGRPVAR"                                    
#> [33] "S1"                                          
#> [34] "V1"
# 2. Now we can use the unique function to see all of the available names and appropriately adjust the filtervar parameter
unique(myfbfrm$AD.NAME)
#> [1] "ProBook1_Teach"          "Div_Pwr_Teach100k+_AllD"
```

**Note**: See more examples by entering in RStudio:

``` r
vignette(package = "FBadstats")
```

#### Acknowledgements

Thank you to [Brian Fannin](http://pirategrunt.com/blog/), [Ari Lamstein](https://www.arilamstein.com/blog/), and [Lucia Gjeltema](http://ncdata4good.github.io/UWchallenge/recap.html) for your feedback and encouragement.

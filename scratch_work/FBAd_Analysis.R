library(devtools)



## model https://cran.r-project.org/web/packages/cowplot/vignettes/introduction.html for vignette
home <- 0

todaydt <- Sys.Date()
## for package / github usage
packvar <- 0
## adset or campaign name row
adset <- 1
## characters to filter campaign or ad set by
filtervar <- 'LEAD'
## Minimum amount spent per adset or campaign for it to appear
spentlim <- 0
## Require event to be summarized?
eventreq <- 1
## What reports do you want to see? Input (1) CTR, (2) REG, (3) VIEWS, (4) LEADS, (5) LEADFORM
showme <- 5

if (home == 1){
  setwd('C:/Users/rick2/Documents/SavvyCareerists/')
} else if (packvar != 1){
  setwd('C:/Users/Packr1/Documents/Personal/DataSci/FB')
}

## https://rpubs.com/cosmopolitanvan/facebookanalytics

filrd <-'DMA_AllAds.csv'
filrd <- 'DMA_Rick-Pack-All-Campaigns-Lifetime.csv'
filrd <-'Mar29_Apr12_DMA.csv'
filrd <-'Leads_DMA_Apr14_May4.csv'
filrd <- 'Leadfrm_20170514.csv'
filrd <- 'DMA_Last14.csv'

library(tidyverse)
library(ggplot2)
library(gridExtra)
library(cowplot)
library(devtools)
#library(tidyr)
## using 30 because lower numbers still caused showing of 10 rows
options(tibble.print_max = 30)
options(tibble.width = 300)


# [1] "Reporting.Starts"                               "Reporting.Ends"                               
# [3] "Campaign.Name"                                  "DMA.Region"                                   
# [5] "Amount.Spent.USD."                              "Amount.Spent.Today.USD."                     
# [7] "Ends"                                           "CTR.All."                                    
# [9] "CTR.Link.Click-Through.Rate."                   "Cost.per.Website.Search.USD."                
# [11] "CPC.Cost.per.Link.Click..USD."                 "Cost.per.Website.Registration.Completed.USD."
# [13] "Website.Registrations.Completed"               "Link.Clicks"                                  
# [15] "Post.Comments"                                 "Post.Reactions"                               
# [17] "Post.Shares"                                   "Website.Leads"                                
# [19] "Cost.per.Website.Lead.USD."                    "Leads..Form."                        
# [21] "Cost.per.Leads..Form..USD."                    "Cost.per.Page.Like.USD."      
dmafb <- data.frame(read_csv(filrd))

dnams       <- colnames(dmafb)
dmafb <- read.csv(filrd)
# replace missing value (NA) with 0
dmafb[is.na(dmafb)] <- 0
dmafb <- tbl_df(dmafb)
if (grepl("AD.SET",toupper(dnams))){
  adcomp <- dmafb[,grep('AD.SET',str_to_upper(dnams))] 
  } else if (grepl("CAMPAIGN",toupper(dnams))){
  adcomp <- dmafb[,grep('CAMPAIGN',str_to_upper(dnams))] }

if(adset==1){
  dmafb$Campaign.Name <- dmafb$Ad.Set.Name
}
dmafb <- dmafb %>% filter(grepl(filtervar,toupper(Campaign.Name)))
dmafb <- dmafb %>% filter(!grepl('UNI',toupper(Campaign.Name)))

if(dnams[grep('REGION',toupper(dnams))] != 'DMA.Region'){
  DMA.Region <- dmafb[,grep('REGION',str_to_upper(dnams))] 
  colnames(DMA.Region) <- 'DMA.Region'
  dmafb <- cbind(DMA.Region, dmafb)
}



missvars  <- c('Post.Shares','Post.Comments','Post.Reactions','Website.Registrations.Completed','Video.Percentage.Watched','Website.Leads')
for (j in 1:length(missvars)){
  chkvar <- missvars[j]
  if(length(dnams[grep(chkvar,dnams)]) == 0){
    chkvar<-data.frame("0")
    colnames(chkvar) <- missvars[j]
    dmafb <- cbind(chkvar, dmafb)
  }}

dnams2 <- colnames(dmafb)

dmafbgrp <- dmafb %>% group_by(`DMA.Region`)
CTRvar   <- grep('CTR..ALL.',toupper(dnams2))

dmasum <- summarize(dmafbgrp, sumspent = sum(as.numeric(`Amount.Spent..USD.`)),         sumreg = sum(as.numeric(`Website.Registrations.Completed`)),
                    sumviews = sum(as.numeric(`Leads..Form.`)),      avgctr = mean(as.numeric(`CTR..Link.Click.Through.Rate.`)),
                    avgwatch = mean(as.numeric(`Video.Percentage.Watched`)),            sumforms = sum(as.numeric(`Leads..Form.`)),
                    sumleads = sum(as.numeric(`Website.Leads`)),              sumreacts = sum(as.numeric(`Post.Comments`, `Post.Reactions`, `Post.Shares`)),
                    mncstclick = mean(as.numeric(`CPC..Cost.per.Link.Click...USD.`)) , medncstclick = median(as.numeric(`CPC..Cost.per.Link.Click...USD.`)))

dmasum$costreg   <- round(dmasum$sumspent / dmasum$sumreg, 1)
dmasum$costviews <- round(dmasum$sumspent / dmasum$sumviews, 1)
dmasum$costleads <- round(dmasum$sumspent / dmasum$sumleads, 1)
dmasum$costreacts <- round(dmasum$sumspent / dmasum$sumreacts, 1)
dmasum$costforms <-  round(dmasum$sumspent / dmasum$sumforms, 1)
# replace NAs with 0
# replace INFs with 0
dmasum <- dmasum %>% mutate_if(is.numeric,(funs(replace(., is.na(.), 0))))
dmasum <- dmasum %>% mutate_if(is.numeric,(funs(replace(., is.infinite(.), 0))))
## alter to consider reach threshold?
if (eventreq==1){
  dmasum2  <- filter(dmasum, sumspent >= spentlim & sumforms > 0)
} else {
  dmasum2  <- filter(dmasum, sumspent >= spentlim)
}


dmastat_ctravg   <- dmasum2 %>% arrange(desc(avgctr), desc(sumspent)) %>% mutate(rnkctravg = min_rank(avgctr))   %>% select(`DMA.Region`, sumspent, sumreg, sumleads, rnkctravg, avgctr)
## medians not varying
#dmastat_ctrmed   <- dmasum2 %>% arrange(desc(mednctr), desc(sumspent)) %>% mutate(rnkctrmed = min_rank(mednctr)) %>% select(`DMA.Region`, rnkctrmed, mednctr)
dmastat_reg      <- dmasum2 %>% arrange(costreg, desc(sumspent)) %>% mutate(rnkreg = min_rank(costreg))    %>% select(`DMA.Region`, rnkreg, costreg)
dmastat_view     <- dmasum2 %>% filter(sumviews > 0) %>% arrange(costviews, desc(sumspent)) %>% mutate(rnkviews = min_rank(costviews))    %>% select(`DMA.Region`, rnkviews, costviews)
dmastat_lead     <- dmasum2 %>% filter(sumleads > 0) %>% arrange(costleads, desc(sumspent)) %>% mutate(rnkleads = min_rank(costleads))    %>% select(`DMA.Region`, rnkleads, costleads)
dmastat_react    <- dmasum2 %>% arrange(costreacts, desc(sumspent)) %>% mutate(rnkreacts = min_rank(costreacts)) %>% select(`DMA.Region`, rnkreacts, costreacts)
# medians not varying
#dmastat_medclk   <- dmasum2 %>% arrange(medncstclick, desc(sumspent)) %>% mutate(rnkmdclk  = min_rank(medncstclick)) %>% select(`DMA.Region`, rnkmdclk, medncstclick)
dmastat_mnclk    <- dmasum2 %>% arrange(mncstclick,   desc(sumspent)) %>% mutate(rnkmnclk  = min_rank(mncstclick)) %>% select(`DMA.Region`, rnkmnclk, mncstclick)
dmastat_watch    <- dmasum2 %>% arrange(avgwatch,   desc(sumspent)) %>% mutate(rnkwatch  = min_rank(avgwatch)) %>% select(`DMA.Region`, rnkwatch, avgwatch)
dmastat_forms    <- dmasum2 %>% filter(sumforms > 0) %>% arrange(costforms, desc(sumspent)) %>% mutate(rnkforms  = min_rank(costforms)) %>% select(`DMA.Region`, rnkforms, costforms)

frms <- list(dmastat_ctravg, dmastat_reg, dmastat_view, dmastat_lead, dmastat_react, dmastat_mnclk, dmastat_watch, dmastat_forms)
## initialize
dmastat_all <- tbl_df(unique(dmasum2$`DMA.Region`))
colnames(dmastat_all) <- "DMA.Region"
for (i in frms){
  dmastat_all <- left_join(dmastat_all, i, by ="DMA.Region")
}

dmastat_all[is.na(dmastat_all)] <- 999

if (grepl(showme,'CTR')){
  sumctravg <- arrange(dmastat_all, rnkctravg)
  print("WORST")
  print(sumctravg[1:20,])
  
  sumctravg <- arrange(dmastat_all, desc(rnkctravg))
  print("BEST")
  print(sumctravg[1:20,])
}
if (grepl(showme,'REG')){ 
  sumregavg <- arrange(dmastat_all, desc(rnkreg))
  print("WORST")
  print(sumregavg[1:20,])
  
  sumregavg <- arrange(dmastat_all, rnkreg)
  print("BEST")
  print(sumregavg[1:20,])
}
if (grepl(showme,'VIEWS')){ 
  sumviewavg <- arrange(dmastat_all, desc(rnkviews))
  print("WORST")
  print(sumviewavg[1:20,])
  
  sumviewavg <- arrange(dmastat_all, rnkviews)
  print("BEST")
  print(sumviewavg[1:20,])
}
if (grepl(showme,'LEADS')){    
  sumleadavg <- dmastat_all %>% select(-c(rnkviews, costviews)) %>% arrange(desc(rnkleads))
  print("WORST")
  print(sumleadavg[1:20,])
  
  sumleadavg <- dmastat_all %>% select(-c(rnkviews, costviews)) %>% arrange(rnkleads)
  print("BEST")
  print(sumleadavg[1:20,])
}
if (grepl(showme,'LEADFORM') | showme==5){
  sumnam <- "Leads(form)"
  sumformsavg <- dmastat_all %>% select(-c(rnkreg, costreg, rnkwatch, avgwatch)) %>% arrange(desc(rnkforms))
  print("WORST")
  print(sumformsavg[1:20,])
  
  sumformsavg <- dmastat_all %>% select(-c(rnkreg, costreg, rnkwatch, avgwatch)) %>% arrange(costforms, DMA.Region)
  print("BEST")
  print(sumformsavg[1:20,])
  statset <- sumformsavg[1:8,]
  medtop  <- round(median(statset$costforms),1)
  medall  <- round(median(sumformsavg$costforms),1)
  
  plotforms <- ggplot(statset) + aes(x = DMA.Region, y = costforms, fill = DMA.Region) + scale_x_discrete(limits = statset$DMA.Region) + scale_y_continuous(labels = scales::dollar) +
    geom_col(show.legend=FALSE)  +  
    labs(title = paste("Facebook Ads Analysis for ", sumnam, ":  ", todaydt, sep=""),
         caption = paste("Data from ", filrd, sep="")
    )
  extrainfo <- paste("Median for (all) only considers where there was at least one ", sumnam, sep="")
  stat_tbl <- data.frame(medtop, medall, spentlim, extrainfo)
  colnames(stat_tbl) <- c("Median cost per lead form (top 8)", "Median cost per lead form (all)", "Minimum amount spent threshold", "INFO:")
  stat_tbl <- tableGrob(stat_tbl,
                        theme=ttheme_minimal(base_size=14),rows=NULL)
  colnames(stat_tbl) <- "Summary Statistics - all data"
  print(grid.arrange(plotforms, stat_tbl, as.table=TRUE,
                     heights=c(3,1)))
  #dev.off()
}
if (grepl(showme,'WATCH')){       
  sumviewavg <- arrange(dmastat_all, rnkwatch)
  print("WORST")
  print(sumviewavg[1:20,])
  
  sumviewavg <- arrange(dmastat_all, desc(rnkwatch))
  print("BEST")
  print(sumviewavg[1:20,])
}

print(paste("Number of regions in all of data: ", length(unique(dmasum$DMA.Region)), sep=""))
print(paste("Number of regions in subset with at least one ", sumnam, " and minimum spend of $", spentlim,  " = ", length(unique(dmasum2$DMA.Region)), sep=""))
print(paste("Total amount spent: $", sum(dmasum$sumspent), sep=""))

state_chloropleth(datafrm, num_colors = 2, zoom=c("north carolina","virginia"))
county_chloropleth
zip_chloropleth (county=1234, reference_map=TRUE)
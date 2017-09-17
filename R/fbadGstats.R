#' Reports statistics across ads from Facebook Ads Manager exported data.
#' @description Reports statistics for breakdown groups (e.g., Age) across
#'     ads from Facebook Ads Manager exported data.
#'  Displays the best and worst performing breakdown groups with a ranking
#'     as well as the sum total of a specified event
#'     (e.g., 'Website Registrations Completed'). Can also distplay a bar
#'     graph showing the cost per specified event for the best breakdown
#'     groups along with a summary table comparing those best performers to
#'     the data as a whole.
#' @param filerd Filename to read. Must be a CSV file.
#' @param choosedir [Windows-Only] If 'YES', prompts the user for a directory /
#'     folder in which all CSV files will be processed by fbadGstats.
#' @param sumvar Variable of focus for analysis. Can provide just a few letters
#'     as long as they do not match another column in the data. For example,
#'     could use 'REG' for 'Website Registrations Completed' (case-insensitive).
#'     Defaults to 'Link Clicks'.
#' @param filtervar Limits the analyzed data to only those of a primary group (the first column that appears in Ads Manager like Campaign Name or Ad Set Name)
#'     matching the provided string of characters (case-insensitive).
#' @param spentlim Minimum amount that must have been spent in a breakdown group (e.g., DMA Region) in order to appear in the output.
#' @param minevent Minimum number of 'events' (e.g., Link Clicks) that must have occurred in order for a breakdown group to appear in the output.
#' @param prtrow Number of breakdown groups that will appear in the output, both the best and worst will appear separately. Default = 20.
#' @param tblout Show the best, worst, or both in the output? Valid values are: BEST , WORST , BOTH
#' @param grphout Show the bar graph and summary table of price / event (e.g., Link Clicks) for the best performers vs. all of data? Valid values are: YES or NO
#' @param ctrstats If yes, prints statistics for clickthrough rate if available in data (CTR) - defaults to NO. Valid values are : YES, NO. Prioritizes CTR..LINK.CLICK.THROUGH.RATE.
#' @return Best or worst performing subgroups depending on `tblout` parameter. Also a graph with a complementary table for the best performers
#'     if grphout parameter is YES.
#' @examples
#' \dontrun{
#' ## to present a window in which one navigates to the desired CSV file, outputs LINK CLICKS summary (Performance and Clicks view suggested in Facebook Ads Manager)
#' fbadGstats()
#' ## similar but one selects a folder and all of the CSV files are processed, and the summarized performance measure is WEBSITE.LEADS.
#' fbadGstats(choosedir = "YES", sumvar = "WEBSITE.LEADS")
#' ## examine the best and worst performing Direct Marketing Areas (DMA) with respect to the results column containing 'REG' (case-insenstive, so this matches Wesbite.Registrations.Completed)
#' fbadGstats(filerd='example_DMA.csv', sumvar='REG')
#' ## see more examples with:
#' vignette(package = "fbadstats")
#' }
#' fbadGstats('example_DMA.csv', sumvar = "CLICKS", filtervar = 'Book', spentlim = 10, minevent = 2, prtrow = 3, tblout = "WORST", graphout = "NO", ctrstats = "NO")
#' @importFrom ggplot2 ggplot aes scale_x_discrete scale_y_continuous geom_col labs xlab ylab theme element_text ggplotGrob geom_text position_dodge
#' @importFrom gridExtra grid.arrange tableGrob ttheme_minimal arrangeGrob
#' @importFrom stringr str_c str_to_upper str_subset str_trim
#' @importFrom dplyr select %>% as_tibble pull filter contains quo group_by summarize mutate_if funs distinct arrange min_rank left_join inner_join mutate slice trunc_mat tbl_df
#' @importFrom xtable xtable
#' @export
fbadGstats <- function(filerd = "", choosedir = "NO", sumvar = "", filtervar = "", spentlim = 0, minevent = 0, prtrow = 20, tblout = "BOTH", grphout = "YES", ctrstats = "NO") {
   ## Reminder to clean-up code regularly with:
    # formatR::tidy_dir('R')
    # https://rpubs.com/TimSch1/64289
    # Yihui personal website https://support.rbind.io/2017/04/25/yihui-website/
    # ggplot2 two-line https://stackoverflow.com/questions/13223846/ggplot2-two-line-label-with-expression

    # default to assuming user will not use one of the two provided example CSV files
    example <- 0
    # present early in package development so may be critical
    origoptFact <- getOption("stringsAsFactors")
    options(stringsAsFactors=FALSE)

    todaydt <- Sys.Date()
    if (choosedir == "YES") {
        dirin <- choose.dir(caption = "Select a folder containing the CSV files exported from Facebook Ads Manager that you would like to process.")
        allfls0 <- list.files(dirin)
        allfls1 <- str_subset(allfls0, ".csv$")
        allfls <- str_c(dirin, "/", allfls1)
    } else {
        allfls <- filerd
    }

    for (ff in 1:length(allfls)) {
        filein <- allfls[ff]
        ## only the filename
        file_nam <- basename(filein)

        if (filein %in% c("example_PerfClk_AgeGender.csv", "example_DMA.csv")) {
            a_file_path <- system.file("extdata", filein, package = "fbadstats")
            example <- 1
        }

        sumvar <- toupper(sumvar)
        filtervar <- toupper(filtervar)
        tblout <- toupper(tblout)
        grphout <- toupper(grphout)

     # invalid parameter checks - used in testparam.R
        if (grphout == "YES" | grphout == TRUE) {
            grphoutTF <- TRUE
        } else if (grphout == "NO" | grphout == FALSE) {
            grphoutTF <- FALSE
        } else {
            stop("Invalid grphout value provided. Please specify value as YES or NO.")
        }
        if (!(tblout %in% c("BOTH", "WORST", "BEST", "NONE"))) {
            stop("Invalid tblout value provided. Please specify one of the following: BEST  WORST  BOTH  NONE")
        }

        if (spentlim < 0) {
          stop("Negative value specified for spentlim parameter.")
        }

        if (filein == "") {
            filein <- choose.files(caption = "Select a .CSV file exported from Facebook Ads Manager.")
        }



        if (example == 1) {
            dmafb <- data.frame(read.csv(a_file_path))
        } else if (length(grep(".csv", filein))) {
            dmafb <- data.frame(read.csv(filein))
        } else if (length(grep(".xls", filein))) {
            stop(".XLS file not yet supported. Please choose 'Save as .csv' in the Export menu of Facebook Ads Manager.")
        } else {
            stop("Unrecognized file format. Please ensure .csv appears in the exported file from Facebook Ads Manager.")
        }

        dnams <- toupper(colnames(dmafb))
        colnames(dmafb) <- dnams
        # Amount spent Today interferes with using select to find 'Amount Spent' total invisible(dmafb)
        if (length(grep("TODAY", dnams)) > 0) {
            dmafb <- dmafb %>% select(-contains("TODAY"))
            ## reset column names
            dnams <- colnames(dmafb)
        }
        # Cost columns interfere with identification of summary columns for which we want counts of 'events'
        if (length(grep("COST", dnams)) > 0) {
            dmafb <- dmafb %>% select(-contains("COST"))
            ## reset column names
            dnams <- colnames(dmafb)
        }
        # replace missing value (NA) with 0
        dmafb[is.na(dmafb)] <- 0
        dmafb <- as_tibble(dmafb)

        if (length(dnams[grepl("AD.SET", toupper(dnams))]) > 0) {
            adcomp <- as.character(dmafb %>% pull(grep("AD.SET", stringr::str_to_upper(dnams))))
        } else if (length(dnams[grepl("CAMPAIGN", toupper(dnams))]) > 0) {
            adcomp <- as.character(dmafb %>% pull(grep("CAMPAIGN", stringr::str_to_upper(dnams))))
        } else if (length(dnams[grepl("AD.NAME", toupper(dnams))]) > 0) {
            adcomp <- as.character(dmafb %>% pull(grep("AD.NAME", stringr::str_to_upper(dnams))))
        } else stop("File not valid. Have you modified the exported file?")

        ## add else ERROR for misgrouping

        dmafb$CAMPAIGN.NAME <- adcomp
        ## eliminated total row that appears if selected in Ads Manager
        ## then apply filtervar if specified
        dmafb <- dmafb %>% filter(!is.na(CAMPAIGN.NAME) & str_trim(CAMPAIGN.NAME) != "") %>%
          filter(grepl(filtervar, toupper(CAMPAIGN.NAME)))

        dnams <- colnames(dmafb)
        dnams2 <- toupper(colnames(dmafb))

        if (dnams2[5] == "GENDER") {
            dmafb <- dmafb %>% mutate(AGE_GENDER = str_c(AGE, ":", GENDER))
            dmafb <- dmafb %>% select(dnams[1:3], AGE_GENDER, dnams[6:length(dnams)])
        }
        if (dnams2[5] == "IMPRESSION.DEVICE") {
            dmafb <- dmafb %>% mutate(PLATFORM_DEVICE = str_c(PLATFORM, ":", IMPRESSION.DEVICE))
            dmafb <- dmafb %>% select(dnams[1:3], PLATFORM_DEVICE, dnams[6:length(dnams)])
        }
        ## This is expected to be DMA.Region or another grouping variable like Age
        dmafb$bygrpvar <- dmafb %>% pull(4)

        dmafb$S1 <- dmafb %>% select(contains("SPENT")) %>% pull(1)
        dnams <- colnames(dmafb)
        dnams2 <- toupper(colnames(dmafb))
        colnames(dmafb) <- dnams2

        ## How do I do this with a regular expression (str_subset)?
        dnams3 <- dnams2[!grepl("REGION", dnams2)]

        if (sumvar != "" & length(grep(sumvar, dnams3)) > 1) {
            errvar = str_c("For ", file_nam, ": Too many matching summarizing variables found in exported data. Pick one. Here are the first (and possibly only) two matches - please specify enough characters for
                     sumvar parameter to match only one:  ",
                dnams3[grep(sumvar, dnams3)[1]], " and ", dnams3[grep(sumvar, dnams3)[2]])
            stop(errvar)
        } else if (length(grep(sumvar, dnams3)) == 0 & sumvar != "") {
            ## need to stop recycling
            errvar <- str_c("For ", file_nam, ": sumvar parameter provided but no matching summarizing variables found in exported data. Provided sumvar was: ", sumvar, ". Available columns in data are the following (not all may be summarizable): ",
                dnams3)
            stop(errvar)
        } else if (length(grep(sumvar, dnams3)) == 1 & sumvar != "") {
            sumvar_frm <- dnams3[grep(sumvar, dnams3)]
            dmafb$V1 <- dmafb %>% select(dnams3[grep(sumvar, dnams3)]) %>% pull(1)
            sumprtvar <- gsub("^[:alnum:]", "", sumvar_frm)
            sumprtvar <- gsub("[.]", " ", sumprtvar)
        } else if (length(grep("RESULTS", dnams3)) == 1) {
            dmafb$V1 <- dmafb$RESULTS
            sumprtvar <- "RESULTS"
            sumvar <- "RESULTS"
        } else if (length(grep("LINK.CLICKS", dnams3)) == 1) {
            dmafb$V1 <- dmafb$LINK.CLICKS
            sumprtvar <- "LINK CLICKS"
            sumvar <- "LINK.CLICKS"
        } else {
            errvar <- str_c("For ", file_nam, ": Summarizing variable not found: Suggest using 'Performance and Clicks' entry in the columns drop-down menu
                      at the right of Ads Manager OR entering sumvar=xxx e.g., fbadsan(sumvar='Link Clicks')")
            stop(errvar)
        }

        if (sum(dmafb$V1, na.rm = TRUE) == 0) {
            errvar <- str_c("For ", file_nam, ": There appear to be no ", sumprtvar, "reported. No output will be generated.")
            stop(errvar)
        }

        # replace NAs with 0 replace INFs with 0
        dmafb <- dmafb %>% mutate_if(is.numeric, (funs(replace(., is.na(.), 0))))
        dmafb <- dmafb %>% mutate_if(is.numeric, (funs(replace(., is.infinite(.), 0))))

        if (ctrstats %in% c("YES", 1) & length(grep("RATE", dnams3)) >= 1) {
            if (length(grep("CTR..LINK.CLICK.THROUGH.RATE.", dnams3)) == 1) {
                noctr <- 0
                dmafb$C1 <- as.numeric(dmafb$CTR..LINK.CLICK.THROUGH.RATE.)
                ctrnam <- "CTR..LINK.CLICK.THROUGH.RATE."
            } else if (length(grep("RATE", dnams3)) == 1) {
                noctr <- 0
                dmafb$C1 <- dmafb %>% select(dnams3[grep("RATE", dnams3)]) %>% pull(1)
                ctrnam <- dnams3[grep("RATE", dnams3)]
            } else {
                noctr <- 1
            }
        } else {
            noctr <- 1
        }

        grpfunc <- function(newvar) {
            grpvar <- quo(!!newvar)
            return(grpvar)
        }
        ## The 4th column in the dnams2 vector varies depending on the file used by the user
        grpvar <- grpfunc(newvar = as.name(dnams[4]))

        sumnam <- dnams3[grep(sumvar, dnams3)]
        dmafbgrp <- dmafb %>% group_by(!!grpvar)
        CTRvar <- grep("CTR..ALL.", toupper(dnams2))

        if (noctr != 1) {
            dmasum <- summarize(dmafbgrp, sumspent = sum(as.numeric(S1)), avgctr = mean(as.numeric(C1)), sumevt = sum(as.numeric(V1)))
        } else {
            dmasum <- summarize(dmafbgrp, sumspent = sum(as.numeric(S1)), sumevt = sum(as.numeric(V1)))
        }
        dmasum$costevt <- round(dmasum$sumspent/dmasum$sumevt, 1)

        dmasum2 <- filter(dmasum, sumspent >= spentlim & sumevt > minevent)
        dmastat_evt <- dmasum2 %>% arrange(costevt, desc(sumspent)) %>% mutate(rnkevt = min_rank(costevt)) %>% select(!!grpvar, rnkevt, sumevt, costevt, sumspent)
        dmastat_all <- as_tibble(dmasum2 %>% distinct(!!grpvar), validate = FALSE)

        if (noctr != 1) {
            dmastat_ctravg <- dmasum2 %>% arrange(desc(avgctr), desc(sumspent)) %>% mutate(rnkctravg = min_rank(avgctr)) %>% select(!!grpvar, sumspent, rnkctravg, avgctr)
            frms <- list(dmastat_ctravg, dmastat_evt)

            for (i in 1:length(frms)) {
                ## indexing list did not appear to work in join
                if (i == 1) {
                  tmpfrm <- dmastat_ctravg
                }
                if (i == 2) {
                  tmpfrm <- dmastat_evt
                }
                dmastat_all <- left_join(dmastat_all, tmpfrm, by = dnams[4])
            }
        } else {
            dmastat_all <- left_join(dmastat_all, dmastat_evt, by = dnams[4])
        }

        dmastat_all[is.na(dmastat_all)] <- 999
        prtrow <- min(prtrow, nrow(dmastat_all))
        ## Keep so line-break between each processed file when multiple files selected
        print("--------------------------------------------------------------------------------------")

        if (noctr != 1) {
            if (tblout %in% c("WORST", "BOTH")) {
                sumctravg <- arrange(dmastat_all, rnkctravg)
                print(str_c("WORST: ", ctrnam, " in ", file_nam))
                print(trunc_mat(tbl_df(sumctravg[1:prtrow, ]))$table)
            }
            if (tblout %in% c("BEST", "BOTH")) {
                sumctravg <- arrange(dmastat_all, desc(rnkctravg))
                print(str_c("BEST: ", ctrnam, " in ", file_nam))
                print(trunc_mat(tbl_df(sumctravg[1:prtrow, ]))$table)
            }
        }
        if (tblout %in% c("WORST", "BOTH")) {
            sumevtavg <- arrange(dmastat_all, desc(rnkevt))
            print(str_c("WORST: ", sumprtvar, " in ", file_nam))
            print(trunc_mat(sumevtavg[1:prtrow, ])$table)
        }
        if (tblout %in% c("BEST", "BOTH")) {
            sumevtavg <- arrange(dmastat_all, rnkevt)
            print(str_c("BEST: ", sumprtvar, " in ", file_nam))
            print(trunc_mat(tbl_df(sumevtavg[1:prtrow, ]))$table)
        }
        grpvarprt <- gsub("[.]", " ", as.character(grpvar[2]))
        print(paste("Number of groups in all of data: ", length(unique(dmasum %>% pull(!!grpvar))), sep = ""))
        if (exists("sumnam")) {
            print(paste("Number of ", grpvarprt, " groups with at least one ", sumprtvar, " and minimum spend of $", spentlim, " = ", length(unique(dmasum2 %>% pull(!!grpvar))), sep = ""))
        } else {
            print(paste("Number of ", grpvarprt, " groups with minimum spend of $", sumprtvar, " = ", length(unique(dmasum2 %>% pull(!!grpvar))), sep = ""))
        }
        print(paste("Total amount spent: $", sum(dmasum$sumspent), sep = ""))

        ####################### Graph section ##

        if (grphoutTF == TRUE) {
            ## Capture the best breakdown groups in sumevtavg
            sumevtavg <- arrange(dmastat_all, rnkevt)
            statset <- sumevtavg %>% slice(1:min(prtrow, 8)) %>% filter(sumevt > 0)
            sumevtavg_gt0 <- sumevtavg %>% filter(sumevt > 0)
            medtop <- round(median(statset$costevt), 1)
            medall <- round(median(sumevtavg_gt0$costevt), 1)
            medspent <- round(median(statset$sumspent))
            plotforms <- ggplot(statset) + aes(x = (statset %>% pull(!!grpvar)), y = costevt, fill = (statset %>% pull(!!grpvar))) +
              scale_x_discrete(limits = statset %>% pull(!!grpvar)) + scale_y_continuous(labels = scales::dollar) +
                geom_col(show.legend = FALSE) + labs(title = paste("Facebook Ads Analysis for ", sumnam, ": Created on  ", todaydt, sep = ""), caption = paste("Data from ", file_nam, sep = "")) + theme(plot.title = element_text(hjust = 0.5)) +
                xlab(str_c("Best performing (lowest cost) ", grpvarprt)) + ylab(str_c("Cost per ", sumnam)) +
                geom_text(aes(label = paste0("$",costevt)), vjust = 0)
            plotformsG <- ggplotGrob(plotforms)
            extrainfo <- paste("Median cost (all) only considers where there was\nat least one ", sumnam, sep = "")
            stat_tbl <- data.frame(medtop, medall, medspent, spentlim, extrainfo)
            colnames(stat_tbl) <- c(str_c("Median cost\nper '", sumprtvar, "':\n(graphed best performers)"), str_c("Median cost\nper '", sumprtvar, "'\n for (all)"), "Median amount spent\n(graphed best performers)",
                "Minimum amount spent\nthreshold (spentlim parameter)", "INFO:")
            tt <- ttheme_minimal(base_size = 10)
            ## print without print function to avoid undesired extraneous output
            grid.arrange(grobs = list(plotforms, tableGrob(stat_tbl, theme = tt, rows = NULL)), as.table = TRUE, heights = c(3, 1))
        }
    }
    # restore stringsAsFactors option to original value
    options(stringsAsFactors=origoptFact)
}
.onAttach <- function(libname, pkgname) {
    packageStartupMessage("FB Ads Analysis tool: 'fbadGstats' - Breakdown Group analysis function")
}

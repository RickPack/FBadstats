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
#' @param filtervar Limits the analyzed data to only those of a primary group
#'     (the first column that appears in Ads Manager like Campaign Name or
#'     Ad Set Name)
#'     matching the provided string of characters (case-insensitive).
#' @param filtervarneg Same as filtervar but negates (excludes) the value.
#' @param spentlim Minimum amount spent in a breakdown group (e.g., DMA Region)
#'     in order to appear in the output.
#' @param minevent Minimum number of 'events' (e.g., Link Clicks) that must
#'     have occurred in order for a breakdown group to appear in the output.
#' @param prtrow Number of breakdown groups that will appear in the output,
#'     both the best and worst will appear separately. Default = 20.
#' @param tblout Show the best, worst, or both in the output? Valid values
#'    are: BEST , WORST , BOTH
#' @param grphout Show the bar graph and summary table of price / event
#'    (e.g., Link Clicks) for the best performers vs. all of data?
#'    Valid values are: YES or NO
#' @param ctrstats If yes, prints statistics for clickthrough rate if
#'    available in data (CTR) - defaults to NO. Valid values are : YES, NO.
#'    Prioritizes CTR..LINK.CLICK.THROUGH.RATE.
#' @return Best or worst performing subgroups depending on `tblout` parameter.
#'    Also a graph with a complementary table for the best performers
#'     if grphout parameter is YES.
#' @examples
#' \dontrun{
#' # to present a window in which one navigates to the desired CSV file,
#' # outputs LINK CLICKS summary
#' # (Performance and Clicks view suggested in Facebook Ads Manager)
#' fbadGstats()
#' # similar but one selects a folder and all of the CSV files are processed,
#' # and the summarized performance measure is WEBSITE.LEADS.
#' fbadGstats(choosedir = "YES", sumvar = "WEBSITE.LEADS")
#' # examine the best and worst performing Direct Marketing Areas (DMA) with
#' # respect to the results column containing 'REG' (case-insenstive,
#' # so this exampled matched 'Website.Registrations.Completed')
#' fbadGstats(filerd='example_DMA.csv', sumvar='REG')
#' # see more examples with:
#' vignette(package = "FBadstats")
#' fbadGstats('example_DMA.csv', sumvar = "CLICKS", filtervar = 'Book',
#'             spentlim = 10, minevent = 2, prtrow = 3, tblout = "WORST",
#'             graphout = "NO", ctrstats = "NO")
#' }
#' @importFrom stringr str_c str_to_upper str_subset str_trim
#' @importFrom dplyr select %>% as_tibble pull filter contains quo group_by
#' @importFrom dplyr summarize mutate_if funs distinct arrange min_rank
#' @importFrom dplyr left_join inner_join mutate slice trunc_mat tbl_df
#' @export
fbadGstats <- function(filerd = "", choosedir = "NO", sumvar = "",
                       filtervar = "", filtervarneg = "", spentlim = 0,
                       minevent = 0, prtrow = 20, tblout = "BOTH",
                       grphout = "YES", ctrstats = "NO") {
    # Reminder to clean-up code regularly with:
    # formatR::tidy_dir('R')
# Load data ---------------------------

    # default to assuming user will not use one of the
    # two provided example CSV files
    example <- 0
    # present early in package development so may be critical
    origoptFact <- getOption("stringsAsFactors")
    options(stringsAsFactors=FALSE)
    # print today's date on the graph later
    todaydt <- Sys.Date()
    # parameter to process all CSV files in a selected folder
    if (choosedir == "YES") {
        dirin <- choose.dir(caption = "Select a folder containing the CSV files
                                       exported from Facebook Ads Manager that
                                       you would like to process.")
        allfls0 <- list.files(dirin)
        allfls1 <- str_subset(allfls0, ".csv$")
        allfls <- str_c(dirin, "/", allfls1)
    } else {
    # otherwise, read-in only the specified file
        allfls <- filerd
    }

    for (ff in 1:length(allfls)) {
       filein <- allfls[ff]
       # capture only the filename for printing in graph caption
       file_nam <- basename(filein)

       if (filein %in% c("example_PerfClk_AgeGender.csv", "example_DMA.csv")) {
           a_file_path <- system.file("extdata", filein, package = "FBadstats")
           example <- 1
        }

        sumvar <- toupper(sumvar)
        filtervar <- toupper(filtervar)
        filtervarneg <- toupper(filtervarneg)
        tblout <- toupper(tblout)
        grphout <- toupper(grphout)
# Parameter checks -------------------------
# used in testparam.R
        if (grphout == "YES" | grphout == TRUE) {
            grphoutTF <- TRUE
        } else if (grphout == "NO" | grphout == FALSE) {
            grphoutTF <- FALSE
        } else {
            stop("Invalid grphout value provided.
                 Please specify value as YES or NO.")
        }
        if (!(tblout %in% c("BOTH", "WORST", "BEST", "NONE"))) {
            stop("Invalid tblout value provided.
                 Please specify one of the following: BEST  WORST  BOTH  NONE")
        }

        if (spentlim < 0) {
          stop("Negative value specified for spentlim parameter.")
        }

        if (filein == "") {
            filein <- choose.files(caption = "Select a .CSV file
                                   exported from Facebook Ads Manager.")
        }


# file format check ------------------------
        if (example == 1) {
            dmafb <- data.frame(read.csv(a_file_path))
        } else if (length(grep(".csv", filein))) {
            dmafb <- data.frame(read.csv(filein))
        } else if (length(grep(".xls", filein))) {
            stop(".XLS file not yet supported. Please choose 'Save as .csv'
                 in the Export menu of Facebook Ads Manager.")
        } else {
            stop("Unrecognized file format. Please ensure .csv appears in the
                 exported file from Facebook Ads Manager.")
        }
# Data munging -----------------------------
        dnams <- toupper(colnames(dmafb))
        colnames(dmafb) <- dnams
        # Amount spent Today interferes with using select to find
        # 'Amount Spent' total invisible(dmafb)
        if (length(grep("TODAY", dnams)) > 0) {
            dmafb <- dmafb %>% select(-contains("TODAY"))
            # reset column names
            dnams <- colnames(dmafb)
        }
        # Cost columns interfere with identification of summary columns
        # for which we want counts of 'events'
        if (length(grep("COST", dnams)) > 0) {
            dmafb <- dmafb %>% select(-contains("COST"))
            # reset column names
            dnams <- colnames(dmafb)
        }
        # replace missing value (NA) with 0
        dmafb[is.na(dmafb)] <- 0
        dmafb <- as_tibble(dmafb)
        # Identify whether Ad Set , Campaign, or Ad Name appears in file
        if (length(dnams[grepl("AD.SET", toupper(dnams))]) > 0) {
            adcomp <- as.character(dmafb %>%
                      pull(grep("AD.SET", stringr::str_to_upper(dnams))))
        } else if (length(dnams[grepl("CAMPAIGN", toupper(dnams))]) > 0) {
            adcomp <- as.character(dmafb %>%
                      pull(grep("CAMPAIGN", stringr::str_to_upper(dnams))))
        } else if (length(dnams[grepl("AD.NAME", toupper(dnams))]) > 0) {
            adcomp <- as.character(dmafb %>%
                      pull(grep("AD.NAME", stringr::str_to_upper(dnams))))
        } else stop("File not valid. Have you modified the exported file?")

        dmafb$CAMPAIGN.NAME <- adcomp
        # eliminate total row that appears if selected in Ads Manager
        # then apply filtervar if specified
        dmafb <- dmafb %>%
                 filter(!is.na(CAMPAIGN.NAME) &
                         str_trim(CAMPAIGN.NAME) != "") %>%
                 filter(grepl(filtervar, toupper(CAMPAIGN.NAME)))
        if (filtervarneg != ""){
          dmafb <- dmafb %>%
                 filter(!(grepl(filtervarneg, toupper(CAMPAIGN.NAME))))
        }
        dnams <- colnames(dmafb)
        dnams2 <- toupper(colnames(dmafb))
        # Recognize when multiple breakdown variables selected and combine them
        if (dnams2[5] == "GENDER") {
            dmafb <- dmafb %>% mutate(AGE_GENDER = str_c(AGE, ":", GENDER))
            dmafb <- dmafb %>% select(dnams[1:3],
                                      AGE_GENDER, dnams[6:length(dnams)])
        }
        if (dnams2[5] == "IMPRESSION.DEVICE") {
            dmafb <- dmafb %>% mutate(PLATFORM_DEVICE =
                                      str_c(PLATFORM, ":", IMPRESSION.DEVICE))
            dmafb <- dmafb %>% select(dnams[1:3], PLATFORM_DEVICE,
                                      dnams[6:length(dnams)])
        }
        # This is expected to be DMA.Region or another
        # grouping variable like Age
        dmafb$bygrpvar <- dmafb %>% pull(4)

        dmafb$S1 <- dmafb %>% select(contains("SPENT")) %>% pull(1)
        dnams <- colnames(dmafb)
        dnams2 <- toupper(colnames(dmafb))
        colnames(dmafb) <- dnams2

        dnams3 <- dnams2[!grepl("REGION", dnams2)]
# Input file checks ------------------------
        if (sumvar != "" & length(grep(sumvar, dnams3)) > 1) {
            errvar = str_c("For ", file_nam, ": Too many matching summarizing
                            variables found in exported data. Pick one. Here
                            are the first (and possibly only) two matches -
                            please specify enough characters for
                            sumvar parameter to match only one:  ",
                            dnams3[grep(sumvar, dnams3)[1]], " and ",
                            dnams3[grep(sumvar, dnams3)[2]])
            stop(errvar)
        } else if (length(grep(sumvar, dnams3)) == 0 & sumvar != "") {
            # need to stop recycling
            errvar <- str_c("For ", file_nam, ": sumvar parameter provided
                             but no matching summarizing variables found in
                             exported data. Provided sumvar was: ", sumvar, ".
                             Available columns in data are the following
                             (not all may be summarizable): ",
                             dnams3)
            stop(errvar)
# Summarized variable ----------------------
        } else if (length(grep(sumvar, dnams3)) == 1 & sumvar != "") {
            sumvar_frm <- dnams3[grep(sumvar, dnams3)]
            dmafb$V1 <- dmafb %>% select(dnams3[grep(sumvar, dnams3)]) %>%
              pull(1)
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
            errvar <- str_c("For ", file_nam, ": Summarizing variable not found:
                             Suggest using 'Performance and Clicks' entry in
                             the columns drop-down menu
                             at the right of Ads Manager OR entering sumvar=xxx
                             e.g., fbadsan(sumvar='Link Clicks')")
            stop(errvar)
        }
# Last file check --------------------------
        if (sum(dmafb$V1, na.rm = TRUE) == 0) {
            errvar <- str_c("For ", file_nam, ": There appears to be
                            no ", sumprtvar, " reported.
                            No output will be generated.
                            Might you have specified a value for the filtervar
                            or filtervarneg parameter that caused no data
                            to be selected?")
            stop(errvar)
        }

        # replace NAs with 0 replace INFs with 0
        dmafb <- dmafb %>% mutate_if(is.numeric,
                                     (funs(replace(., is.na(.), 0))))
        dmafb <- dmafb %>% mutate_if(is.numeric,
                                     (funs(replace(., is.infinite(.), 0))))
# ctrstats section -------------------------
        if (ctrstats %in% c("YES", 1) & length(grep("RATE", dnams3)) >= 1) {
            if (length(grep("CTR..LINK.CLICK.THROUGH.RATE.", dnams3)) == 1) {
                noctr <- 0
                dmafb$C1 <- as.numeric(dmafb$CTR..LINK.CLICK.THROUGH.RATE.)
                ctrnam <- "CTR..LINK.CLICK.THROUGH.RATE."
            } else if (length(grep("RATE", dnams3)) == 1) {
                noctr <- 0
                dmafb$C1 <- dmafb %>% select(dnams3[grep("RATE", dnams3)]) %>%
                  pull(1)
                ctrnam <- dnams3[grep("RATE", dnams3)]
            } else {
                noctr <- 1
            }
        } else {
            noctr <- 1
        }
# summary stats ----------------------------
        grpfunc <- function(newvar) {
            grpvar <- quo(!!newvar)
            return(grpvar)
        }
        # The 4th column in the dnams2 vector varies depending on
        # the file used by the user (e.g., Age)
        grpvar <- grpfunc(newvar = as.name(dnams[4]))

        sumnam <- dnams3[grep(sumvar, dnams3)]
        dmafbgrp <- dmafb %>% group_by(!!grpvar)
        CTRvar <- grep("CTR..ALL.", toupper(dnams2))
        # print ctr data only if requested via parameter
        if (noctr != 1) {
            dmasum <- summarize(dmafbgrp, sumspent = sum(as.numeric(S1)),
                                avgctr = mean(as.numeric(C1)),
                                sumevt = sum(as.numeric(V1)))
        } else {
            dmasum <- summarize(dmafbgrp, sumspent = sum(as.numeric(S1)),
                                sumevt = sum(as.numeric(V1)))
        }
        # cost per event - a critical metric
        dmasum$costevt <- round(dmasum$sumspent/dmasum$sumevt, 1)
        # apply spentlim and minevent parameters
        dmasum2 <- filter(dmasum, sumspent >= spentlim & sumevt > minevent)
        # if no data then terminate
        if(nrow(dmasum2)==0){
          errvar <- str_c("For ", file_nam, ": No data found.
                          No output will be generated.
                          Might you have specified a value for
                          one of the parameters
                          that caused no data to be selected?")
          stop(errvar)
        }
        dmastat_evt <- dmasum2 %>% arrange(costevt, desc(sumspent)) %>%
                       mutate(rnkevt = min_rank(costevt)) %>%
                       select(!!grpvar, rnkevt, sumevt, costevt, sumspent)
        dmastat_all <- as_tibble(dmasum2 %>% distinct(!!grpvar), validate = FALSE)

        if (noctr != 1) {
            dmastat_ctravg <- dmasum2 %>%
                               arrange(desc(avgctr), desc(sumspent)) %>%
                               mutate(rnkctravg = min_rank(avgctr)) %>%
                               select(!!grpvar, sumspent, rnkctravg, avgctr)
            frms <- list(dmastat_ctravg, dmastat_evt)

            for (i in 1:length(frms)) {
                # indexing list did not appear to work in join
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
        # Keep so line-break between each processed file when multiple files selected
        print("-------------------------------------------------------------")

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
        print(paste("Number of groups in all of data: ",
                    length(unique(dmasum %>% pull(!!grpvar))), sep = ""))
        if (exists("sumnam")) {
            print(paste("Number of ", grpvarprt, " groups with at least one ",
                        sumprtvar, " and minimum spend of $", spentlim, " = ",
                        length(unique(dmasum2 %>% pull(!!grpvar))), sep = ""))
        } else {
            print(paste("Number of ", grpvarprt,
                        " groups with minimum spend of $", sumprtvar, " = ",
                        length(unique(dmasum2 %>% pull(!!grpvar))), sep = ""))
        }
        print(paste("Total amount spent: $", sum(dmasum$sumspent), sep = ""))


# Graph section ----------------------------
        if (grphoutTF == TRUE) {
            graphads(dmastat_all, prtrow, grpvar, grpvarprt, sumnam,
                     todaydt, file_nam, spentlim, sumprtvar)
        }
    }
    # restore stringsAsFactors option to original value
    options(stringsAsFactors=origoptFact)
    # invisibly return dmafbgrp for use outside of the function
    invisible(dmafbgrp)
}
.onAttach <- function(libname, pkgname) {
    packageStartupMessage(paste0("FB Ads Analysis tool: 'fbadGstats' ",
                                 "- Breakdown Group analysis function"))
}

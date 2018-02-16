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
#'     folder in which all CSV files will be processed by FBadGstats.
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
#' @param printrow Number of breakdown groups that will appear in the output,
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
#' FBadGstats()
#' # similar but one selects a folder and all of the CSV files are processed,
#' # and the summarized performance measure is WEBSITE.LEADS.
#' FBadGstats(choosedir = "YES", sumvar = "WEBSITE.LEADS")
#' # examine the best and worst performing Direct Marketing Areas (DMA) with
#' # respect to the results column containing 'REG' (case-insenstive,
#' # so this exampled matched 'Website.Registrations.Completed')
#' FBadGstats(filerd='example_DMA.csv', sumvar='REG')
#' # see more examples with:
#' vignette(package = "FBadstats")
#' FBadGstats('example_DMA.csv', sumvar = "CLICKS", filtervar = 'Book',
#'             spentlim = 10, minevent = 2, printrow = 3, tblout = "WORST",
#'             graphout = "NO", ctrstats = "NO")
#' }
#' @importFrom stringr str_c str_to_upper str_subset str_trim
#' @importFrom dplyr select %>% as_tibble pull filter contains quo group_by
#' @importFrom dplyr summarize mutate_if funs distinct arrange min_rank
#' @importFrom dplyr left_join inner_join mutate slice trunc_mat tbl_df
#' @export
FBadGstats <- function(filerd = "", choosedir = "NO", sumvar = "",
                       filtervar = "", filtervarneg = "", spentlim = 0,
                       minevent = 0, printrow = 20, tblout = "BOTH",
                       grphout = "YES", ctrstats = "NO") {
    # Reminder to clean-up code regularly with:
    # formatR::tidy_dir('R')
# Load data ---------------------------

    # default to assuming user will not use one of the
    # two provided example CSV files
    example <- 0
    # present early in package development so may be critical
    # restores original Option at the bottom of code
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
            filein <- choose.files(caption = "Select a single .CSV file
                                   exported from Facebook Ads Manager.")
            if (length(filein) > 1){
              stop("Error: More than one file appears to have been selected.")
            }
        }
        # capture only the filename for printing in graph caption
        #  and summary tables
        file_nam <- basename(filein)


# file format check ------------------------
        if (example == 1) {
            fb_frm <- data.frame(read.csv(a_file_path))
        } else if (length(grep(".csv", filein))) {
            fb_frm <- data.frame(read.csv(filein))
        } else if (length(grep(".xls", filein))) {
            stop(".XLS file not yet supported. Please choose 'Save as .csv'
                 in the Export menu of Facebook Ads Manager.")
        } else {
            stop("Unrecognized file format. Please ensure .csv appears in the
                 exported file from Facebook Ads Manager.")
        }
# Data munging -----------------------------
        fb_frm_nams <- toupper(colnames(fb_frm))
        colnames(fb_frm) <- fb_frm_nams
        # Amount spent Today interferes with using select to find
        # 'Amount Spent' total invisible(fb_frm)
        if (length(grep("TODAY", fb_frm_nams)) > 0) {
            fb_frm <- fb_frm %>% select(-contains("TODAY"))
            # reset column names
            fb_frm_nams <- colnames(fb_frm)
        }
        # Cost columns interfere with identification of summary columns
        # for which we want counts of 'events'
        if (length(grep("COST", fb_frm_nams)) > 0) {
            fb_frm <- fb_frm %>% select(-contains("COST"))
            # reset column names
            fb_frm_nams <- colnames(fb_frm)
        }
        # replace missing value (NA) with 0
        fb_frm[is.na(fb_frm)] <- 0
        fb_frm <- as_tibble(fb_frm)
        # Identify whether Ad Set , Campaign, or Ad Name appears in file
        if (length(fb_frm_nams[grepl("AD.SET.NAME", toupper(fb_frm_nams))]) > 0) {
            adcomp <- as.character(fb_frm %>%
                      pull(grep("AD.SET.NAME", stringr::str_to_upper(fb_frm_nams))))
        } else if (length(fb_frm_nams[grepl("CAMPAIGN.NAME", toupper(fb_frm_nams))]) > 0) {
            adcomp <- as.character(fb_frm %>%
                      pull(grep("CAMPAIGN.NAME", stringr::str_to_upper(fb_frm_nams))))
        } else if (length(fb_frm_nams[grepl("AD.NAME", toupper(fb_frm_nams))]) > 0) {
            adcomp <- as.character(fb_frm %>%
                      pull(grep("AD.NAME", stringr::str_to_upper(fb_frm_nams))))
        } else stop("File not valid. Have you modified the exported file?")

        fb_frm$CAMPAIGN.NAME <- adcomp
        # eliminate total row that appears if selected in Ads Manager
        # then apply filtervar if specified
        fb_frm <- fb_frm %>%
                 filter(!is.na(CAMPAIGN.NAME) &
                         str_trim(CAMPAIGN.NAME) != "") %>%
                 filter(grepl(filtervar, toupper(CAMPAIGN.NAME)))
        if (filtervarneg != ""){
          fb_frm <- fb_frm %>%
                 filter(!(grepl(filtervarneg, toupper(CAMPAIGN.NAME))))
        }
        fb_frm_nams <- colnames(fb_frm)
        fb_frm_nams2 <- toupper(colnames(fb_frm))
        # Recognize when multiple breakdown variables selected and combine them
        if (fb_frm_nams2[5] == "GENDER") {
            fb_frm <- fb_frm %>% mutate(AGE_GENDER = str_c(AGE, ":", GENDER))
            fb_frm <- fb_frm %>% select(fb_frm_nams[1:3],
                                      AGE_GENDER, fb_frm_nams[6:length(fb_frm_nams)])
        }
        if (fb_frm_nams2[5] == "IMPRESSION.DEVICE") {
            fb_frm <- fb_frm %>% mutate(PLATFORM_DEVICE =
                                      str_c(PLATFORM, ":", IMPRESSION.DEVICE))
            fb_frm <- fb_frm %>% select(fb_frm_nams[1:3], PLATFORM_DEVICE,
                                      fb_frm_nams[6:length(fb_frm_nams)])
        }
        # This is expected to be DMA.Region or another
        # grouping variable like Age
        fb_frm$bygrpvar <- fb_frm %>% pull(4)

        fb_frm$S1 <- fb_frm %>% select(contains("SPENT")) %>% pull(1)
        fb_frm_nams <- colnames(fb_frm)
        fb_frm_nams2 <- toupper(colnames(fb_frm))
        colnames(fb_frm) <- fb_frm_nams2

        fb_frm_nams3 <- fb_frm_nams2[!grepl("REGION", fb_frm_nams2)]
# Input file checks ------------------------
        if (sumvar != "" & length(grep(sumvar, fb_frm_nams3)) > 1) {
            errvar = str_c("For ", file_nam, ": Too many matching summarizing
                            variables found in exported data. Pick one. Here
                            are the first (and possibly only) two matches -
                            please specify enough characters for
                            sumvar parameter to match only one:  ",
                            fb_frm_nams3[grep(sumvar, fb_frm_nams3)[1]], " and ",
                            fb_frm_nams3[grep(sumvar, fb_frm_nams3)[2]])
            stop(errvar)
        } else if (length(grep(sumvar, fb_frm_nams3)) == 0 & sumvar != "") {
            # need to stop recycling
            errvar <- str_c("For ", file_nam, ": sumvar parameter provided
                             but no matching summarizing variables found in
                             exported data. Provided sumvar was: ", sumvar, ".
                             Available columns in data are the following
                             (not all may be summarizable): ",
                             fb_frm_nams3)
            stop(errvar)
# Summarized variable ----------------------
        } else if (length(grep(sumvar, fb_frm_nams3)) == 1 & sumvar != "") {
            sumvar_frm <- fb_frm_nams3[grep(sumvar, fb_frm_nams3)]
            fb_frm$V1 <- fb_frm %>% select(fb_frm_nams3[grep(sumvar, fb_frm_nams3)]) %>%
              pull(1)
            sumprintvar <- gsub("^[:alnum:]", "", sumvar_frm)
            sumprintvar <- gsub("[.]", " ", sumprintvar)
        } else if (length(grep("RESULTS", fb_frm_nams3)) == 1) {
            fb_frm$V1 <- fb_frm$RESULTS
            sumprintvar <- "RESULTS"
            sumvar <- "RESULTS"
        } else if (length(grep("LINK.CLICKS", fb_frm_nams3)) == 1) {
            fb_frm$V1 <- fb_frm$LINK.CLICKS
            sumprintvar <- "LINK CLICKS"
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
        if (sum(fb_frm$V1, na.rm = TRUE) == 0) {
            errvar <- str_c("For ", file_nam, ": There appears to be
                            no ", sumprintvar, " reported.
                            No output will be generated.
                            Might you have specified a value for the filtervar
                            or filtervarneg parameter that caused no data
                            to be selected?")
            stop(errvar)
        }

        # replace NAs with 0 replace INFs with 0
        fb_frm <- fb_frm %>% mutate_if(is.numeric,
                                     (funs(replace(., is.na(.), 0))))
        fb_frm <- fb_frm %>% mutate_if(is.numeric,
                                     (funs(replace(., is.infinite(.), 0))))
# ctrstats section -------------------------
        if (ctrstats %in% c("YES", 1) & length(grep("RATE", fb_frm_nams3)) >= 1) {
            if (length(grep("CTR..LINK.CLICK.THROUGH.RATE.", fb_frm_nams3)) == 1) {
                noctr <- 0
                fb_frm$C1 <- as.numeric(fb_frm$CTR..LINK.CLICK.THROUGH.RATE.)
                ctrnam <- "CTR..LINK.CLICK.THROUGH.RATE."
            } else if (length(grep("RATE", fb_frm_nams3)) == 1) {
                noctr <- 0
                fb_frm$C1 <- fb_frm %>% select(fb_frm_nams3[grep("RATE", fb_frm_nams3)]) %>%
                  pull(1)
                ctrnam <- fb_frm_nams3[grep("RATE", fb_frm_nams3)]
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
        # The 4th column in the fb_frm_nams2 vector varies depending on
        # the file used by the user (e.g., Age)
        grpvar <- grpfunc(newvar = as.name(fb_frm_nams[4]))

        sumnam <- fb_frm_nams3[grep(sumvar, fb_frm_nams3)]
        fb_frm_grp <- fb_frm %>% group_by(!!grpvar)
        CTRvar <- grep("CTR..ALL.", toupper(fb_frm_nams2))
        # print ctr data only if requested via parameter
        if (noctr != 1) {
            summary_frm <- summarize(fb_frm_grp, sumspent = sum(as.numeric(S1)),
                                avgctr = mean(as.numeric(C1)),
                                sumevent = sum(as.numeric(V1)))
        } else {
            summary_frm <- summarize(fb_frm_grp, sumspent = sum(as.numeric(S1)),
                                sumevent = sum(as.numeric(V1)))
        }
        # cost per event - a critical metric
        summary_frm$costevent <- round(summary_frm$sumspent/summary_frm$sumevent, 2)
        # apply spentlim and minevent parameters
        summary_frm2 <- filter(summary_frm, sumspent >= spentlim & sumevent > minevent)
        # if no data then terminate
        if(nrow(summary_frm2)==0){
          errvar <- str_c("For ", file_nam, ": No data found.
                          No output will be generated.
                          Might you have specified a value for
                          one of the parameters
                          that caused no data to be selected?")
          stop(errvar)
        }
        summary_frm_event_rnk <- summary_frm2 %>% arrange(costevent, desc(sumspent)) %>%
                       mutate(rnkevent = min_rank(costevent)) %>%
                       select(!!grpvar, rnkevent, sumevent, costevent, sumspent)
        summary_frm_distinct_grp <- as_tibble(summary_frm2 %>% distinct(!!grpvar), validate = FALSE)

        if (noctr != 1) {
            summary_frm_ctravg <- summary_frm2 %>%
                               arrange(desc(avgctr), desc(sumspent)) %>%
                               mutate(rnkctravg = min_rank(avgctr)) %>%
                               select(!!grpvar, sumspent, rnkctravg, avgctr)
            frms <- list(summary_frm_ctravg, summary_frm_event_rnk)

            for (i in 1:length(frms)) {
                # indexing list did not appear to work in join
                if (i == 1) {
                  tmpfrm <- summary_frm_ctravg
                }
                if (i == 2) {
                  tmpfrm <- summary_frm_event_rnk
                }
                summary_frm_distinct_grp <- left_join(summary_frm_distinct_grp, tmpfrm, by = fb_frm_nams[4])
            }
        } else {
            summary_frm_distinct_grp <- left_join(summary_frm_distinct_grp, summary_frm_event_rnk, by = fb_frm_nams[4])
        }
        summary_frm_distinct_grp[is.na(summary_frm_distinct_grp)] <- 999
        printrow <- min(printrow, nrow(summary_frm_distinct_grp))
        # Keep so line-break between each processed file when multiple files selected
        print("-------------------------------------------------------------")

        if (noctr != 1) {
            if (tblout %in% c("WORST", "BOTH")) {
                sumctravg <- arrange(summary_frm_distinct_grp, rnkctravg)
                print(str_c("WORST: ", ctrnam, " in ", file_nam))
                print(data.frame(sumctravg[1:printrow, ]))
            }
            if (tblout %in% c("BEST", "BOTH")) {
                sumctravg <- arrange(summary_frm_distinct_grp, desc(rnkctravg))
                print(str_c("BEST: ", ctrnam, " in ", file_nam))
                print(data.frame(sumctravg[1:printrow, ]))
            }
        }
        if (tblout %in% c("WORST", "BOTH")) {
            sumeventavg <- arrange(summary_frm_distinct_grp, desc(rnkevent))
            print(str_c("WORST: ", sumprintvar, " in ", file_nam))
            print(data.frame(sumeventavg[1:printrow, ]))
        }
        if (tblout %in% c("BEST", "BOTH")) {
            sumeventavg <- arrange(summary_frm_distinct_grp, rnkevent)
            print(str_c("BEST: ", sumprintvar, " in ", file_nam))
            print(data.frame(sumeventavg[1:printrow, ]))
        }
        grpvarprint <- gsub("[.]", " ", as.character(grpvar[2]))
        print(paste("Number of groups in all of data: ",
                    length(unique(summary_frm %>% pull(!!grpvar))), sep = ""))
        if (exists("sumnam")) {
            print(paste("Number of ", grpvarprint, " groups with at least one ",
                        sumprintvar, " and minimum spend of $", spentlim, " = ",
                        length(unique(summary_frm2 %>% pull(!!grpvar))), sep = ""))
        } else {
            print(paste("Number of ", grpvarprint,
                        " groups with minimum spend of $", sumprintvar, " = ",
                        length(unique(summary_frm2 %>% pull(!!grpvar))), sep = ""))
        }
        print(paste("Total amount spent: $", sum(summary_frm$sumspent), sep = ""))


# Graph section ----------------------------
        if (grphoutTF == TRUE) {
            graphads(summary_frm_distinct_grp, printrow, grpvar, grpvarprint, sumnam,
                     todaydt, file_nam, spentlim, sumprintvar)
        }
    }
    # restore stringsAsFactors option to original value
    options(stringsAsFactors=origoptFact)
    # invisibly return fb_frm_grp for use outside of the function
    invisible(fb_frm_grp)
}
.onAttach <- function(libname, pkgname) {
    packageStartupMessage(paste0("FB Ads Analysis tool: 'FBadGstats' ",
                                 "- Breakdown Group analysis function"))
}

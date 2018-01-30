#' Generates ggplot histogram and add'l statistics for fbadGstats
#' @description More text coming.
#' @param dmastat_all post-processed data frame from fbadGstats
#' @param prtrow text
#' @param grpvar text
#' @param grpvarprt text
#' @param sumnam text
#' @param todaydt text
#' @param file_nam text
#' @param spentlim text
#' @param sumprtvar text
#'
#' @return A graph with a complementary table for the best performers
#' @importFrom ggplot2 ggplot aes scale_x_discrete scale_y_continuous geom_col
#' @importFrom ggplot2 labs xlab ylab theme element_text ggplotGrob geom_text
#' @importFrom gridExtra grid.arrange tableGrob ttheme_minimal arrangeGrob
#' @importFrom stringr str_c str_to_upper str_subset str_trim
#' @importFrom dplyr select %>% as_tibble pull filter contains quo group_by
#' @importFrom dplyr summarize mutate_if funs distinct arrange min_rank
#' @importFrom dplyr left_join inner_join mutate slice trunc_mat tbl_df
#' @export
graphads <- function(dmastat_all, prtrow, grpvar, grpvarprt, sumnam, todaydt, file_nam,
                     spentlim, sumprtvar){
  # Capture the best breakdown groups in sumevtavg
  sumevtavg <- arrange(dmastat_all, rnkevt)
  statset <- sumevtavg %>% slice(1:min(prtrow, 8)) %>% filter(sumevt > 0)
  sumevtavg_gt0 <- sumevtavg %>% filter(sumevt > 0)
  medtop <- round(median(statset$costevt), 1)
  medall <- round(median(sumevtavg_gt0$costevt), 1)
  medspent <- round(median(statset$sumspent))
  plotforms <- ggplot(statset) +
    aes(x = (statset %>% pull(!!grpvar)),
        y = costevt, size = 06,
        fill = (statset %>% pull(!!grpvar))) +
    scale_x_discrete(limits = statset %>%
                       pull(!!grpvar)) +
    scale_y_continuous(
      labels = scales::dollar) +
    geom_col(show.legend = FALSE) +
    labs(title = paste("Facebook Ads Analysis for ",
                       sumnam, ": Created on  ", todaydt,
                       sep = ""),
         caption = paste("Data from ",
                         file_nam,
                         sep = "")) +
    theme(plot.title = element_text(hjust = 0.5),
          legend.position="none",
          text = element_text(size = 08)) +
    xlab(str_c("Best performing (lowest cost) ", grpvarprt)) +
    ylab(str_c("Cost per ", sumnam)) +
    geom_text(aes(label = paste0("$",costevt,"; Spent = $",
                                 sumspent)), vjust = 0, size = 03)
  plotformsG <- ggplotGrob(plotforms)
  extrainfo <- paste("Median cost (all) only considers where there was at least one ", sumnam, sep = "")
  stat_tbl <- data.frame(medtop, medall, medspent,
                         spentlim, extrainfo)
  colnames(stat_tbl) <- c(str_c("Median cost\nper '", sumprtvar,
                                "'\n for (all)"),
                          "Median amount spent\n",
                          "(graphed best performers)",
                          "(spentlim parameter)", "INFO:")
  tt <- ttheme_minimal(base_size = 08)
  # print without print function to avoid undesired extraneous output
  grid.arrange(grobs = list(plotforms,
                            tableGrob(stat_tbl, theme = tt,
                                      rows = NULL)), as.table = TRUE,
               heights = c(3, 1))
}

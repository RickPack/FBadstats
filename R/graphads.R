#' Generates ggplot histogram and add'l statistics for fbadGstats
#' @description More text coming.
#' @param summary_frm_distinct_grp post-processed data frame from fbadGstats
#' @param printrow text
#' @param grpvar text
#' @param grpvarprint text
#' @param sumnam text
#' @param todaydt text
#' @param file_nam text
#' @param spentlim text
#' @param sumprintvar text
#' @param sum_set text
#'
#' @return A graph with a complementary table for the best performers
#' @importFrom ggplot2 ggplot aes scale_x_discrete scale_y_continuous geom_col
#' @importFrom ggplot2 labs xlab ylab theme element_text ggplotGrob geom_text
#' @importFrom ggplot2 geom_text element_blank element_rect
#' @importFrom gridExtra grid.arrange tableGrob ttheme_minimal arrangeGrob
#' @importFrom stringr str_c str_to_upper str_subset str_trim
#' @importFrom dplyr select %>% as_tibble pull filter contains quo group_by
#' @importFrom dplyr summarize mutate_if funs distinct arrange min_rank
#' @importFrom dplyr left_join inner_join mutate slice trunc_mat tbl_df
#' @export
graphads <- function(summary_frm_distinct_grp, printrow, grpvar, grpvarprint, sumnam, todaydt, file_nam,
                     spentlim, sumprintvar, sum_set)
  {
  # Capture the best breakdown groups in sumeventavg
  sumeventavg <- arrange(summary_frm_distinct_grp, rnkevent)
  # top 8 for breakdown groups
  if(sum_set == 1){
   statset <- sumeventavg %>% slice(1:min(printrow, 8)) %>% filter(sumevent > 0)
  } else {
  # top 3 for ad / ad set / campaign (potentially long names)
   statset <- sumeventavg %>% slice(1:min(printrow, 5)) %>% filter(sumevent > 0)
  }
  sumeventavg_gt0 <- sumeventavg %>% filter(sumevent > 0)
  medtop <- round(median(statset$costevent), 2)
  medall <- round(median(sumeventavg_gt0$costevent), 2)
  medspent <- round(median(statset$sumspent), 2)

  # Colors from Dr. Jenny Bryan's STAT545A course
  # https://www.stat.ubc.ca/~jenny/STAT545A/block14_colors.html
  colors <- c('chartreuse3', 'cornflowerblue', 'darkgoldenrod1', 'peachpuff3',
              'mediumorchid2', 'turquoise3', 'wheat4', 'slategray2')
  colors <- colors[1:length(unique(statset %>% pull(!!grpvar)))]
  plotforms <- ggplot(statset) +
    aes(x = (statset %>% pull(!!grpvar)),
        y = costevent, size = 06,
        fill = (statset %>% pull(!!grpvar))) +
    scale_x_discrete(limits = statset %>%
                       pull(!!grpvar)) +
    scale_y_continuous(
      labels = scales::dollar) +
    geom_col(show.legend = FALSE, fill = colors) +
    labs(title = paste("Facebook Ads Analysis for ",
                       sumnam, ": Created on  ", todaydt,
                       sep = ""),
         caption = paste("Data from ",
                         file_nam,
                         sep = "")) +
    theme(plot.title = element_text(hjust = 0.5, color = '#EEEEEE',
                                    size = 28),
          legend.position="none",
          text = element_text(size = 14, color = '#EEEEEE'),
          axis.text = element_text(size = 10, color = '#EEEEEE'),
          panel.background = element_rect(fill = '#333333'),
          plot.background = element_rect(fill = '#333333'),
          panel.grid = element_blank(),
          legend.background = element_blank(),
          legend.key = element_blank()) +
    xlab(str_c("Best performing (lowest cost) ", grpvarprint)) +
    ylab(str_c("Cost per ", sumnam)) +
    geom_text(aes(label = paste0("$", costevent, ";Spent=$",
                                 sumspent)),
              vjust = -0.3, size = 04,
              color = '#CCCCCC')
  plotformsG <- ggplotGrob(plotforms)
  extrainfo <- paste("Median cost (all) only considers where there was at least one ", sumnam, sep = "")
  stat_tbl <- data.frame(medtop, medall, medspent,
                         spentlim, extrainfo)
  colnames(stat_tbl) <- c(str_c("Median cost\nper '", sumprintvar,
                                "' for\n(graphed best performers)"),
                          str_c("Median cost\nper '", sumprintvar,
                                "' for\n(all)"),
                          "Median amount spent\namong\n(graphed best performers)",
                          "Minimum $ spent\nto appear?\n(spentlim parameter)", "INFO:")
  tt <- ttheme_minimal(base_size = 08)
  # print without print function to avoid undesired extraneous output
  grid.arrange(grobs = list(plotforms,
                            tableGrob(stat_tbl, theme = tt,
                                      rows = NULL)), as.table = TRUE,
               heights = c(3, 1))
}

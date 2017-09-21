context("error_check_parameter")

test_that("err out on invalid tablout parameter", {
  expect_error(fbadGstats(tblout="NEITHER"))
})

test_that("err out on negative spentlim parameter", {
  expect_error(fbadGstats(spentlim=-3))
})

test_that("err out on a grphout parameter other than YES, NO, TRUE, or FALSE", {
  expect_error(fbadGstats(grphout = "ONE"))
})

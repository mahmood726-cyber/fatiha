.onAttach <- function(libname, pkgname) {
  packageStartupMessage(
    "Welcome to SYNTHESIS v", utils::packageVersion("SYNTHESIS"), "
",
    "Structured Yield-Neutral Trust-weighted Heterogeneity-Integrated Statistical Inference System
",
    "------------------------------------------------------------------------------------------
",
    "DISCLAIMER: This software is a decision-support tool. It is NOT a replacement for clinical
",
    "judgment. The 'Fail-Safe' logic provides statistical guard rails, but final interpretation
",
    "of evidence requires domain expertise.
",
    "------------------------------------------------------------------------------------------"
  )
}

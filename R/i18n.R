# Internationalization Dictionary for SYNTHESIS

SYNTHESIS_I18N <- list(
  en = list(
    title = "Clinical Evidence Verification Report",
    exec_summary = "1. Executive Summary",
    core_est = "Core Estimate",
    reliability = "Reliability Score",
    divergence = "Divergence",
    impact = "Clinical Impact",
    nnt = "Number Needed to Treat (NNT)",
    fail_safe_on = "FAIL-SAFE ACTIVATED",
    fail_safe_off = "ROBUST TRAJECTORY",
    status = "Status",
    generated = "Generated"
  ),
  es = list(
    title = "Informe de Verificación de Evidencia Clínica",
    exec_summary = "1. Resumen Ejecutivo",
    core_est = "Estimación Central",
    reliability = "Puntuación de Confiabilidad",
    divergence = "Divergencia",
    impact = "Impacto Clínico",
    nnt = "Número Necesario a Tratar (NNT)",
    fail_safe_on = "MECANISMO DE SEGURIDAD ACTIVADO",
    fail_safe_off = "TRAYECTORIA ROBUSTA",
    status = "Estado",
    generated = "Generado"
  ),
  fr = list(
    title = "Rapport de Vérification des Données Cliniques",
    exec_summary = "1. Résumé Exécutif",
    core_est = "Estimation Centrale",
    reliability = "Score de Fiabilité",
    divergence = "Divergence",
    impact = "Impact Clinique",
    nnt = "Nombre de Sujets à Traiter (NST)",
    fail_safe_on = "SÉCURITÉ ACTIVÉE",
    fail_safe_off = "TRAJECTOIRE ROBUSTE",
    status = "Statut",
    generated = "Généré"
  )
)

#' Get Translated String
#' @keywords internal
get_str <- function(key, lang = "en") {
  if (is.null(SYNTHESIS_I18N[[lang]])) lang <- "en"
  val <- SYNTHESIS_I18N[[lang]][[key]]
  if (is.null(val)) val <- SYNTHESIS_I18N[["en"]][[key]]
  return(val)
}

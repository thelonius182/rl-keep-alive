options(gargle_oauth_email = "cz.teamservice@gmail.com")

# main control loop
repeat {

  # say Hello to Gmail
  # NB - don't attach the gmailr package!! Use qualified calls instead.
  #      Attaching the package completely trips up RStudio's auto-completion.
  #      There is an issue with deprecated functions throwing errors, even if an app's source code
  #      doesn't reference them. Maintainers should remove them.
  tryCatch(
    {
      gmailr::gm_auth_configure()
    },
    error = function(e1) {
      flog.error(sprintf("Gmail OAuth failed - can't report results. Msg = %s", conditionMessage(e1)),
                 name = config$log_slug)
      break
    }
  )

  if (exists("salsa_source_error")) {
    report_msg <- "Taak kon niet voltooid worden - zie 'woj_schedules.log' (Nipper >> Desktop)."
  } else {
    report_msg <- "Taak voltooid, geen bijzonderheden."
  }

  # report the result ----
  tryCatch(
    {
      task_report <- gmailr::gm_mime() |>
        # gmailr::gm_to(c(config$email_to_A, config$email_to_B)) |>
        gmailr::gm_to(config$email_to_A) |>
        gmailr::gm_from(config$email_from) |>
        gmailr::gm_subject("Keep-alive TEST") |>
        gmailr::gm_text_body(report_msg)

      rtn <- gmailr::gm_send_message(task_report)
    },
    error = function(e1) {
      flog.error(sprintf("Sending mail failed. Msg = %s", conditionMessage(e1)),
                 name = config$log_slug)
      break
    }
  )

  # ======================
  # EXIT main control loop
  # ======================
  break
}

flog.info("<<< STOP", name = config$log_slug)

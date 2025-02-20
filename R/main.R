options(gargle_oauth_email = "cz.teamservice@gmail.com")

get_ka_log_ts <- function(s1) {
  parts <- str_split(s1, " ")[[1]]
  tz_abbr <- parts[length(parts) - 1]
  s1_cleaned <- str_remove(s1, paste0(" ", tz_abbr))

  locale_before <- Sys.getlocale("LC_TIME")
  Sys.setlocale("LC_TIME", "C") # English
  result <- as.POSIXct(s1_cleaned, format = "%a %b %d %H:%M:%S %Y", tz = "Europe/Amsterdam")
  Sys.setlocale("LC_TIME", locale_before)

  return(result)
}

send_ka_mail <- function(mac, subject_msg, body_msg) {

  tryCatch(
    {
      mac_status_report <- gmailr::gm_mime() |>
        # gmailr::gm_to(c(config$email_to_A, config$email_to_B)) |>
        gmailr::gm_to(config$email_to_A) |>
        gmailr::gm_from(config$email_from) |>
        gmailr::gm_subject(sprintf("Signalering %s - %s", mac, subject_msg)) |>
        gmailr::gm_text_body(body_msg)

      rtn <- gmailr::gm_send_message(mac_status_report)
      0L
    },
    error = function(e1) {
      flog.error(sprintf("Sending mail failed. Msg = %s", conditionMessage(e1)),
                 name = config$log_slug)
      return(1L)
    }
  )
}

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

  # check if RL-scheduler UZM restarted or keep-alive script on UZM failed
  qfn_ka_log <- path_join(c(config$keep_alive_log_uzm, "ps_rlsched_bsh.log"))
  ka_log_latest <- read_lines(qfn_ka_log) |> tail(1)
  ka_log_ts_chr <- ka_log_latest |> str_split_i(pattern = ": RL-scheduler ", i = 1)
  ka_log_ts <- get_ka_log_ts(ka_log_ts_chr)
  ka_log_age_in_mins <- interval(ka_log_ts, now(tzone = "Europe/Amsterdam")) |>
    int_length() %/% 60 # integer minutes
  ka_log_rl_state <- ka_log_latest |> str_split_i(pattern = ": RL-scheduler ", i = 2)

  # send a report if something unexpected happened
  # - log should be no older than 20 minutes: the keep-alive check runs hourly at HH:30 and is checked here
  #   hourly at HH:45
  # - after a restart, check the logs why it was necessary
  if (ka_log_age_in_mins > 20) {
    wrk_body_msg <- read_file("resources/ka_mail_body_A.txt")
    snd_err <- send_ka_mail(mac = "Uitzendmac",
                            subject_msg = "status RL-scheduler onbekend",
                            body_msg = wrk_body_msg)
    flog.info("Mail was sent", name = config$log_slug)
  } else if (ka_log_rl_state == "restarted") {
    wrk_body_msg <- read_file("resources/ka_mail_body_B.txt")
    snd_err <- send_ka_mail(mac = "Uitzendmac",
                            subject_msg = "kickstart RL-scheduler uitgevoerd",
                            body_msg = wrk_body_msg)
    flog.info("Mail was sent", name = config$log_slug)
  } else {
    flog.info("All quiet", name = config$log_slug)
  }

  # ======================
  # EXIT main control loop
  # ======================
  break
}

flog.info("<<< STOP", name = config$log_slug)

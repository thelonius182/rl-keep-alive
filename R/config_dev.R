message("using DEV-config")

pacman::p_load(googledrive, googlesheets4, dplyr, tidyr, lubridate, fs, uuid, RPostgres, purrr,
               stringr, yaml, readr, rio, RMySQL, keyring, jsonlite, futile.logger, conflicted)

conflicts_prefer(dplyr::lag, dplyr::lead, dplyr::filter, lubridate::minutes, .quiet = T)

salsa_git_version <- function(qfn_repo) {

  repo <- git2r::repository(qfn_repo)
  branch <- git2r::repository_head(repo)$name
  latest_commit <- git2r::commits(repo, n = 1)[[1]]
  commit_author <- latest_commit$author$name
  commit_date <- latest_commit$author$when
  fmt_commit_date <- format(lubridate::with_tz(commit_date, tzone = "Europe/Amsterdam"), "%a %Y-%m-%d, %H:%M")

  return(list(git_branch = branch, ts = fmt_commit_date, by = commit_author, path = repo$path))
}

config <- read_yaml("config_dev.yaml")

lg_ini <- flog.appender(appender.file(config$log_file), name = config$log_slug)
git_info <- salsa_git_version(getwd())
flog.info(">>> START", name = config$log_slug)
flog.info(sprintf("git-branch: %s", git_info$git_branch), name = config$log_slug)
flog.info(sprintf("  commited: %s", git_info$ts), name = config$log_slug)
flog.info(sprintf("        by: %s", git_info$by), name = config$log_slug)
flog.info(sprintf("local repo: %s", git_info$path), name = config$log_slug)
flog.info(sprintf("  using db: %s", config$wpdb_env), name = config$log_slug)

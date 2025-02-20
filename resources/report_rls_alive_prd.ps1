# -------------------------------------------------------------------------------------------
# This is the powershell script started from Task Scheduler to run
# R-script 'report_rls_alive.R' that will report a restart of
# RL-scheduler to CZ-studio
#
# TS: pgm/script = C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
#     parms DEV = -File "C:\cz_salsa\r_proj_develop\report_rls_alive_dev.ps1"
#     parms PRD = -File "g:\R_released_projects\report_rls_alive_prd.ps1"
#     beginnen in = <leeg>
# -------------------------------------------------------------------------------------------

# Redirect Write-Host output to a file
function CS_Write-Log {
    param ([string] $message)

    # Ensure the log file exists
    if (-not (Test-Path -Path $logFilePath)) {
        New-Item -Path $logFilePath -ItemType "file" -Force | Out-Null
    }

    $message | Out-File -FilePath $logFilePath -Append
}

# define logfile
$dateString = (Get-Date).ToString("yyyyMMdd")
$logFilePath = Join-Path -Path "c:\Users\nipper\Logs" -ChildPath "report_rls_alive_task_${dateString}.log"

# report 'Started'
$currentDateTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
CS_Write-Log -message "Script started at: $currentDateTime"

# find R-home
$r_installation_path = "C:\Program Files\R"
$r_versions = Get-ChildItem -Path $r_installation_path -Directory |
              Sort-Object -Property Name -Descending
$newest_r_version = $r_versions[0].Name
$r_path = Join-Path -Path $r_installation_path -ChildPath $newest_r_version
$r_path = Join-Path -Path $r_path -ChildPath "bin"
$r_path = Join-Path -Path $r_path -ChildPath "Rscript.exe"
CS_Write-Log -message "R-home = $r_path"

# point to the R-script and run it
$script_home = "g:\R_released_projects\rl-keep-alive"
$script_path = Join-Path $script_home -ChildPath "R"
$script_path = Join-Path $script_path -ChildPath "report_rls_alive.R"
CS_Write-Log -message "running $script_path"
& $r_path $script_path
CS_Write-Log -message "job completed normally"

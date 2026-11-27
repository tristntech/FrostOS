
# ---------------------------------------------------------------------------
# FrostOS additions (appended to archiso's releng profiledef.sh by
# scripts/build-iso.sh). Later lines override earlier ones.
# ---------------------------------------------------------------------------
iso_name="frostos"
iso_label="FROSTOS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"
iso_publisher="FrostOS <https://github.com/tristntech/FrostOS>"
iso_application="FrostOS Live Medium"

file_permissions+=(
  ["/etc/gshadow"]="0:0:400"
  ["/etc/sudoers.d/10-frostos-live"]="0:0:440"
  ["/usr/share/frostos/frostos-branding"]="0:0:755"
  ["/usr/bin/frostde-session"]="0:0:755"
  ["/usr/bin/frostde-lock"]="0:0:755"
  ["/usr/bin/frostde-logout"]="0:0:755"
  ["/usr/bin/frostde-screenshot"]="0:0:755"
  ["/usr/bin/frostde-welcome"]="0:0:755"
  ["/usr/bin/frost-settings"]="0:0:755"
)

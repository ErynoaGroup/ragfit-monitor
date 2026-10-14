# Reads `go version -m <binary>` output and prints one "<module> <version> <h1-hash>" line per
# compiled dependency, using the replacement for a dep that is followed by a "=>" line.
# Line-based state machine that fails closed: any line it cannot account for, a "=>" without a
# preceding dep, or a resulting module without a version or h1 hash makes it exit 1 (no partial output).
# Exceptions, both carrying no module code of their own:
#   - whitespace-only lines (go version -m prints one after some replacement lines) are skipped;
#   - a local directory replacement ("=> ./dir (devel)") of a module below the main module path is
#     source of the main module itself (covered by the plugin's own license) and is not emitted.
#     A local replacement of any other module fails.
function flush() {
  if (pend == "") return
  split(pend, a, " ")
  if (a[2] == "" || a[2] == "(devel)" || a[3] !~ /^h1:/) { err = err "UNVERIFIABLE MODULE: " pend " (no version or h1 hash)\n" }
  else out = out pend "\n"
  pend = ""
}
BEGIN { pend = ""; out = ""; err = ""; seen_path = 0; main = "" }
/^[ \t]*$/ { next }
NR == 1 { if ($0 !~ /: go[0-9]/) err = err "UNEXPECTED HEADER: " $0 "\n"; next }
$1 == "path" || $1 == "build" { flush(); seen_path = 1; next }
$1 == "mod" { flush(); main = $2; next }
$1 == "dep" {
  flush()
  if (NF < 3 || NF > 4) { err = err "UNEXPECTED DEP LINE: " $0 "\n"; next }
  pend = $2 " " $3 " " (NF == 4 ? $4 : ""); next
}
$1 == "=>" {
  if (pend == "") { err = err "REPLACEMENT WITHOUT DEP: " $0 "\n"; next }
  if (NF < 3 || NF > 4) { err = err "UNEXPECTED REPLACEMENT LINE: " $0 "\n"; pend = ""; next }
  if (($2 ~ /^\.\.?\//) && $3 == "(devel)") {
    split(pend, a, " ")
    if (main != "" && index(a[1], main "/") == 1) { pend = ""; next }
    err = err "LOCAL REPLACEMENT OUTSIDE THE MAIN MODULE: " a[1] " => " $2 "\n"; pend = ""; next
  }
  pend = $2 " " $3 " " (NF == 4 ? $4 : ""); flush(); next
}
{ flush(); err = err "UNEXPECTED LINE: " $0 "\n" }
END {
  flush()
  if (!seen_path) err = err "NO BUILD INFO\n"
  if (err != "") { printf "%s", err > "/dev/stderr"; exit 1 }
  printf "%s", out
}

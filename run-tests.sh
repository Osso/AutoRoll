#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
cd "$project_dir"

sh -n run-tests.sh
luacheck AutoRoll.lua OptionPanel.lua SlashCommand.lua tests/*.lua
luac -p AutoRoll.lua OptionPanel.lua SlashCommand.lua tests/*.lua

wow_sim_bin=${WOW_SIM_BIN:-"$project_dir/../wow-ui-sim/target/debug/wow-sim"}
case "$wow_sim_bin" in
	/*) ;;
	*) wow_sim_bin="$project_dir/$wow_sim_bin" ;;
esac

if [ ! -f "$wow_sim_bin" ] || [ ! -x "$wow_sim_bin" ]; then
	printf '%s\n' "AutoRoll wow-sim boundary unavailable: $wow_sim_bin" >&2
	printf '%s\n' 'Set WOW_SIM_BIN to an executable wow-sim binary; no build or network fallback is used.' >&2
	exit 1
fi

sim_root=$(mktemp -d "${TMPDIR:-/tmp}/autoroll-wow-sim.XXXXXX")
cleanup() {
	rm -rf "$sim_root"
}
trap cleanup EXIT HUP INT TERM

mkdir -p "$sim_root/Interface/AddOns" "$sim_root/data"
ln -s "$project_dir" "$sim_root/Interface/AddOns/AutoRoll"
ln -s "$project_dir/../wow-ui-sim/Interface/AddOns/TestFramework" \
	"$sim_root/Interface/AddOns/TestFramework"
cp "$wow_sim_bin" "$sim_root/wow-sim"
chmod 755 "$sim_root/wow-sim"

WOW_SIM_ADDONS_PATH="$sim_root/Interface/AddOns" \
WOW_SIM_INTERFACE_PATH="$sim_root/Interface" \
XDG_DATA_HOME="$sim_root/data" \
"$sim_root/wow-sim" --no-saved-vars run-tests AutoRoll

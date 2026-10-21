#!/usr/bin/env bash
# Print the image tags for one variant directory, one per line.
# Usage: .github/tags.sh 7.4/bullseye/cli
set -euo pipefail

dir="$1"
IFS=/ read -r ver os variant <<< "$dir"
full="$(sed -n 's/^ENV PHP_VERSION //p' "$dir/Dockerfile")"

case "$ver" in
	7.4|8.0) default_debian=bullseye ;;
	8.1) default_debian=trixie ;;
	*) echo "unknown version: $ver" >&2; exit 1 ;;
esac

for v in "$full" "$ver"; do
	echo "$v-$variant-$os"
	case "$os" in
		alpine*)
			echo "$v-$variant-alpine"
			if [ "$variant" = cli ]; then
				echo "$v-$os"
				echo "$v-alpine"
			fi
			;;
		"$default_debian")
			echo "$v-$variant"
			if [ "$variant" = cli ]; then
				echo "$v-$os"
				echo "$v"
			fi
			;;
		*)
			if [ "$variant" = cli ]; then
				echo "$v-$os"
			fi
			;;
	esac
done

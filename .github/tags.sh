#!/usr/bin/env bash
# Print the image tags for one variant directory, one per line.
# Usage: .github/tags.sh 7.4/bullseye/cli
set -euo pipefail

# "latest" points at the cli image of this version on its default Debian.
latest_version=8.1

dir="$1"
IFS=/ read -r ver os variant <<< "$dir"
full="$(sed -n 's/^ENV PHP_VERSION //p' "$dir/Dockerfile")"

case "$ver" in
	5.6|7.0) default_debian=stretch ;;
	7.1|7.2) default_debian=buster ;;
	7.3|7.4|8.0) default_debian=bullseye ;;
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
				if [ "$v" = "$latest_version" ]; then
					echo latest
				fi
			fi
			;;
		*)
			if [ "$variant" = cli ]; then
				echo "$v-$os"
			fi
			;;
	esac
done

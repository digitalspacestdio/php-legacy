# php-eol-CVE-2026-109618-109619

Docker images of end-of-life PHP 7.4, 8.0 and 8.1 with the fix for CVE-2026-109618 and CVE-2026-109619.

The official [`php`](https://hub.docker.com/_/php) images on Docker Hub only cover 8.2 and later.
These images fill the gap for older versions.

> [!WARNING]
> These versions are still end-of-life.
> Only this one fix is backported.
> Other known issues after the last official release stay unfixed.
> Plan your upgrade to a supported PHP version.

## Images

```
ghcr.io/mpyw/php-eol-cve-2026-109618-109619:<tag>
```

Platforms: `linux/amd64`, `linux/arm64`.

| PHP | Debian | Alpine | Variants |
| --- | --- | --- | --- |
| 7.4.33 | bullseye | alpine3.16 | cli, fpm, apache (Debian only) |
| 8.0.30 | bullseye | alpine3.16 | cli, fpm, apache (Debian only) |
| 8.1.34 | trixie, bookworm | alpine3.22 | cli, fpm, apache (Debian only) |

Tags follow the official image naming.

| Tag example | Meaning |
| --- | --- |
| `7.4`, `7.4.33` | cli on the default Debian |
| `7.4-fpm`, `7.4-apache` | that variant on the default Debian |
| `7.4-fpm-bullseye` | that variant on that OS |
| `7.4-alpine`, `7.4-fpm-alpine` | cli or fpm on Alpine |
| `8.1-cli-bookworm` | 8.1 on the non-default Debian |

The default Debian is bullseye for 7.4 and 8.0, and trixie for 8.1.

Each release also gets an immutable tag, such as `7.4.33-cli-bullseye-v1.0.0`.
The [releases](https://github.com/mpyw/php-eol-CVE-2026-109618-109619/releases) list these tags with their digests.

> [!NOTE]
> 7.4 and 8.0 stay on bullseye and alpine3.16.
> These PHP versions need OpenSSL 1.1, and newer releases ship only OpenSSL 3.
> Both base images are past their own end of life.

## How the images are built

Each Dockerfile is the last upstream [docker-library/php](https://github.com/docker-library/php) Dockerfile for that variant.
The build changes only the source step.

1. Download the official tarball from php.net.
2. Verify it with SHA-256 and the release manager GPG keys, as upstream does.
3. Apply the fix from [`patches/`](patches).
4. Repack the tarball, so `docker-php-source extract` also gives patched sources.

The patches come from these php-src branches:

| Patch | php-src branch | Commit |
| --- | --- | --- |
| `7.4-CVE-2026-109618-109619.patch` | `PHP-7.4-CVE-2026-109618-109619` | `712e60f9ed` |
| `8.0-CVE-2026-109618-109619.patch` | `PHP-8.0-CVE-2026-109618-109619` | `82f8f31b16` |
| `8.1-CVE-2026-109618-109619.patch` | `PHP-8.1-CVE-2026-109618-109619` | `1d7dec178a` |

The `PHP_VERSION` string is not changed.
`php -v` shows the original version.
Use the image tag to tell patched images apart.

> [!NOTE]
> 8.1 on Alpine also needs the upstream fix for [GH-14834](https://github.com/php/php-src/issues/14834).
> Without it, `--with-pear` fails to install with the libxml2 in Alpine 3.22.
> Upstream docker-library applies php/php-src@67259e451d for this.
> That commit does not apply to 8.1.34 as is.
> 8.1.34 wraps the changed line in `ZEND_DIAGNOSTIC_IGNORED_START` / `END`.
> `patches/8.1-gh14834-rebased.patch` is the same change, rebased onto 8.1.34.
> The `NEWS` hunk is dropped, as upstream does.

## Building locally

The Dockerfiles read the patches from a named build context.

```sh
docker buildx build --build-context patches=./patches -t php-eol:7.4-cli 7.4/bullseye/cli
```

## License

The Dockerfiles and scripts are MIT, as in docker-library/php. See [LICENSE](LICENSE).
The files in `patches/` come from php-src and use the [PHP License 3.01](https://www.php.net/license/3_01.txt).

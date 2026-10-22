# php-legacy

Docker images of end-of-life PHP 5.6 to 8.1 with the fix for CVE-2026-109618 and CVE-2026-109619.

The official [`php`](https://hub.docker.com/_/php) images on Docker Hub only cover 8.2 and later.
These images fill the gap for older versions.

Maintained by [digitalspacestdio](https://github.com/digitalspacestdio).
Based on [mpyw/php-eol-CVE-2026-109618-109619](https://github.com/mpyw/php-eol-CVE-2026-109618-109619), which did the original backports.

> [!WARNING]
> These versions are still end-of-life.
> Only this one fix is backported.
> Other known issues after the last official release stay unfixed.
> Plan your upgrade to a supported PHP version.

> [!CAUTION]
> **The fix for 5.6 to 7.3 is an unofficial backport.**
> php-src publishes the fix only for 7.4, 8.0 and 8.1.
> This repository ports the 7.4 fix to 5.6, 7.0, 7.1, 7.2 and 7.3 by hand.
> Nobody from the PHP project has reviewed these ports.
> No public proof of concept exists, so the ports are only tested indirectly.
> See [Unofficial backports](#unofficial-backports-70-to-73) and [PHP 5.6](#php-56).

## Images

```
ghcr.io/digitalspacestdio/php-legacy:<tag>
```

```sh
docker pull ghcr.io/digitalspacestdio/php-legacy:7.4-fpm
```

Every push to `main` that passes CI updates the moving tags below.
A release adds an immutable tag per variant, such as `7.4.33-cli-bullseye-v1.0.0`.

Platforms: `linux/amd64`, `linux/arm64`.

| PHP | Debian | Alpine | Variants |
| --- | --- | --- | --- |
| 5.6.40 | stretch | alpine3.8 | cli, fpm, apache (Debian only) |
| 7.0.33 | stretch | alpine3.7 | cli, fpm, apache (Debian only) |
| 7.1.33 | buster | alpine3.10 | cli, fpm, apache (Debian only) |
| 7.2.34 | buster | alpine3.12 | cli, fpm, apache (Debian only) |
| 7.3.33 | bullseye | alpine3.15 | cli, fpm, apache (Debian only) |
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
| `latest` | 8.1 cli on trixie |

The default Debian for each version:

| PHP | Default Debian |
| --- | --- |
| 5.6, 7.0 | stretch |
| 7.1, 7.2 | buster |
| 7.3, 7.4, 8.0 | bullseye |
| 8.1 | trixie |

Each release also gets an immutable tag, such as `7.4.33-cli-bullseye-v1.0.0`.
The [releases](https://github.com/digitalspacestdio/php-legacy/releases) list these tags with their digests.
To make a release, run the `Tag and Release` workflow with a version such as `v1.0.0`.

> [!NOTE]
> 5.6 to 8.0 stay on the OS versions that docker-library used last.
> These PHP versions do not support OpenSSL 3, and newer OS releases ship only OpenSSL 3.
> All of these base images are past their own end of life.
> The Debian ones install packages from archive.debian.org.

## How the images are built

Each Dockerfile is the last upstream [docker-library/php](https://github.com/docker-library/php) Dockerfile for that variant.
The build changes only the source step.

1. Download the official tarball from php.net.
2. Verify it with SHA-256 and the release manager GPG keys, as upstream does.
3. Apply the fix from [`patches/`](patches).
4. Repack the tarball, so `docker-php-source extract` also gives patched sources.

For 7.4 to 8.1, the patches come from these php-src branches:

| Patch | php-src branch | Commit |
| --- | --- | --- |
| `7.4-CVE-2026-109618-109619.patch` | `PHP-7.4-CVE-2026-109618-109619` | `712e60f9ed` |
| `8.0-CVE-2026-109618-109619.patch` | `PHP-8.0-CVE-2026-109618-109619` | `82f8f31b16` |
| `8.1-CVE-2026-109618-109619.patch` | `PHP-8.1-CVE-2026-109618-109619` | `1d7dec178a` |

For 7.0 to 7.3, the patches are unofficial backports. See [Unofficial backports](#unofficial-backports-70-to-73).
For 5.6, the patch is a further port of the 7.0 backport. See [PHP 5.6](#php-56).

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

## What the fix changes

The upstream fix calls itself a minimal mitigation for EOL versions.
It changes some behavior on purpose.

| Change | Effect |
| --- | --- |
| Out of memory and allocation overflow errors | The process prints the fatal error to stderr and exits with code 1 at once. Shutdown functions do not run. Under FPM the worker restarts. |
| Session upload progress | Disabled. `session.upload_progress.*` has no effect. |
| New INI `max_multipart_body_parts` | Limits the parts in one `multipart/form-data` body. The default `-1` means `max_input_vars` + `max_file_uploads`. |
| Multipart part headers | Only `Content-Disposition` and `Content-Type` are kept. Duplicates are ignored. |

## Unofficial backports (7.0 to 7.3)

The 7.0 to 7.3 patches port the php-src 7.4 fix (`712e60f9ed`) by meaning, not by fuzzy patching.

- Every change in the 7.4 fix is either ported, or left out because that code does not exist in the older version.
- Code that the older versions lack is added. This covers `ZSTR_MAX_LEN`, the concat overflow checks and `zend_new_array_singleton()`.
- `zend_vm_execute.h` is regenerated from `zend_vm_def.h` with each version's own `zend_vm_gen.php`.
- `shutdown_executor()` differs a lot between versions. The state resets are placed where each version needs them.

Each port was checked against a build of the unpatched tarball, using these php-src test suites:

- `Zend/tests`
- `tests`
- `ext/session/tests`
- `ext/standard/tests/array`
- `ext/standard/tests/strings`

| Result | Details |
| --- | --- |
| New failures | 9 per version, all expected: 8 `ext/session/tests/rfc1867*` tests (upload progress is disabled), and `tests/lang/bug45392.phpt` (the fatal error now goes to stderr) |
| Same in upstream 7.4 | The same 9 tests fail on the image built from the official 7.4 fix |
| Out of memory | Each image exits with code 1 and skips shutdown functions |
| Multipart limit | `max_multipart_body_parts` limits the parts and emits a warning |
| Nested GPC arrays | Parse as before |

> [!WARNING]
> These checks show that the mitigation is in place and that nothing else broke.
> They cannot prove that the vulnerabilities are closed.

### PHP 5.6

docker-library removed 5.6 in February 2019.
The 5.6 Dockerfiles come from the last upstream commit that had them (`ea377551`, 5.6.40).
The `zts` variant is not built.

`patches/5.6-CVE-2026-109618-109619.patch` ports the 7.0 backport to the Zend Engine 2 code base. The main differences:

- Memory limit, out of memory, allocation size overflow and `String size overflow` errors call a new `zend_mm_safe_error_ex()`. It prints the fatal error to stderr and calls `_exit(1)`. 5.6 used to raise a catchable `E_ERROR` for these.
- 5.6 has no `zend_string`, so the concat overflow checks stay in `concat_function()`, `add_string_to_string()` and `add_char_to_string()`. The VM handlers call these, so `zend_vm_execute.h` is not regenerated.
- `zend_hash.c` does not change. 5.6 caps the table size in `_zend_hash_init()` and `zend_hash_do_resize()` without raising an error.
- `array_init_singleton()` uses a table of 2 slots, not 1. 5.6 allocates the bucket table lazily and treats `nTableMask == 0` as "not allocated yet", so a 1-slot table would be re-allocated on every insert.
- The executor state reset at the end of `shutdown_executor()` uses the 5.6 field types (`zval *` handlers, `zend_stack` and `zend_ptr_stack`).

The 5.6 port was checked the same way as 7.0 to 7.3, with the php-src test suites listed above run against the installed `php` binary of the patched and of an unpatched image.
The unpatched image passes all 4206 tests. The patched image fails the same 9 tests as the other backports and no others.
Out of memory exits with code 1 and skips shutdown functions, `max_multipart_body_parts` limits the parts and warns, duplicate `Content-Disposition` headers are ignored, upload progress writes nothing to the session, and nested GPC arrays parse as before.

## Building locally

The Dockerfiles read the patches from a named build context.

```sh
docker buildx build --build-context patches=./patches -t php-legacy:7.4-cli 7.4/bullseye/cli
```

## License

The Dockerfiles and scripts are MIT, as in docker-library/php. See [LICENSE](LICENSE).
The files in `patches/` come from php-src, or are derived from php-src code.
They use the [PHP License 3.01](https://www.php.net/license/3_01.txt).

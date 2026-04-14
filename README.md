qubes-example
===

A minimal reference package for Qubes OS components built with
[qubes-builderv2](https://github.com/QubesOS/qubes-builderv2). Use it as a
starting point when creating a new component, or as a reference for how the
build system expects files to be laid out.


## Repository layout

```
qubes-example-advanced/
├── .qubesbuilder               # Tells qubes-builderv2 what to build and for which targets
├── LICENSE
├── Makefile                    # install-dom0 / install-vm / build-lib / install-lib targets
├── README.dom0                 # Installed as /usr/lib/qubes/example/README on dom0
├── README.vm                   # Installed as /usr/lib/qubes/example/README in VMs
├── archlinux/                  # Arch Linux packaging (vm-archlinux distributions only)
│   └── PKGBUILD.in             # PKGBUILD template; @VERSION@ and @REL@ are substituted
├── build.cmd                   # Windows build helper script
├── clean.cmd                   # Windows clean helper script
├── data/                       # Data files installed by example-data
│   ├── example-extra.txt
│   └── example.conf
├── debian/                     # Debian packaging (VM distributions only)
│   ├── changelog
│   ├── compat
│   ├── control
│   ├── copyright
│   ├── qubes-example-advanced.install
│   ├── qubes-example-advanced-dev.install
│   ├── qubes-example-advanced-libs.install
│   ├── rules
│   └── source/
│       └── format
├── example.sh                  # Script payload installed by example-vm / example-dom0
├── libexample/                 # C library source and public header
│   ├── example.h
│   ├── example.pc.in           # pkg-config template
│   └── libexample.c
├── rel                         # Plain-text release/revision number (e.g. "1")
├── rpm_spec/
│   ├── example-dom0.spec.in    # RPM spec template for the dom0 package
│   ├── example-vm.spec.in      # RPM spec template for VM packages
│   ├── example-libs.spec.in    # RPM spec template for the shared library
│   └── example-data.spec.in    # RPM spec template for data files
├── submodule-a/                # Git submodule A (included in source archive)
├── submodule-b/                # Git submodule B (included in source archive)
├── 9FA64B92F95E706BF28E2CA6484010B5CDC576E2.sha256  # Expected SHA-256 of the downloaded GPG key
├── version                     # Plain-text upstream version (e.g. "1.0.0")
└── windows/                    # Windows packaging (vm-win10 distributions only)
    └── vs2022/
        ├── example-advanced.sln
        └── example-dummy/
            └── example-dummy.vcxproj
```


## File-by-file guide

### `.qubesbuilder`

Declares what qubes-builderv2 should build and for which host/VM targets.
Each top-level key (`host`, `vm`) maps to a set of distribution types
(`rpm`, `deb`, etc.). Under `build:` list the spec/recipe files to use.

```yaml
host:
  rpm:
    build:
    - rpm_spec/example-dom0.spec    # built for dom0 (host) RPM distributions
    - rpm_spec/example-data.spec
    create-archive: true
vm:
  rpm:
    build:
    - rpm_spec/example-vm.spec      # built for VM RPM distributions
    - rpm_spec/example-libs.spec
    - rpm_spec/example-data.spec
    create-archive: true
  deb:
    build:
    - debian                        # built for VM Debian distributions
    create-archive: true
  archlinux:
    build:
    - archlinux                     # directory containing PKGBUILD.in
  windows:
    build:
    - windows/vs2022/example-advanced.sln
    bin:
    - windows/vs2022/x64/@CONFIGURATION@/example-dummy/example-dummy.dll
    inc:
    - libexample/example.h
    lib:
    - windows/vs2022/x64/@CONFIGURATION@/example-dummy/example-dummy.lib
source:
  create-archive: true              # also create a component source tarball
  files:
  - url: https://keys.openpgp.org/vks/v1/by-fingerprint/9FA64B92F95E706BF28E2CA6484010B5CDC576E2
    sha256: 9FA64B92F95E706BF28E2CA6484010B5CDC576E2.sha256   # file containing the expected SHA-256 of the download
  modules:
  - submodule-a                     # git submodules to include in the source archive
  - submodule-b
```

The builder renders `*.spec.in` -> `*.spec` by substituting `@VERSION@`,
`@REL@`, and `@CHANGELOG@` before the spec is used. For Debian, the
`debian/changelog` is updated automatically. For Arch Linux, `PKGBUILD.in`
is rendered to `PKGBUILD` in the same way.

`create-archive: true` tells the builder to create a source tarball from
the component's git tree. When `source: files:` is also present, both the
component's own archive and the listed external files are fetched and made
available in the build environment. If `create-archive` is omitted and
`files:` is set, the external file is used as the primary source archive
(e.g. as the `.orig.tar.gz` for Debian builds) instead of a component
archive.

### `version` and `rel`

Plain-text files containing the upstream version and the package release
number respectively. The builder reads them and substitutes them into
`@VERSION@` and `@REL@` inside RPM spec templates and into the Debian
`changelog`.

### `Makefile`

Contains `install-dom0` and `install-vm` targets. Each RPM spec's `%install`
section and the Debian `rules` file call one of these with the appropriate
`DESTDIR`. Add every file you want packaged to the appropriate target here,
then list it in the corresponding spec `%files` section or `.install` file.

> **Important:** Makefile recipe lines must be indented with a **tab** character,
> not spaces. Most editors default to spaces so make sure yours inserts a real tab.
> A space-indented recipe line causes `make: *** missing separator` errors.

```makefile
install-common:
	install -m 775 -D example.sh $(DESTDIR)/usr/lib/qubes/example/example.sh

install-dom0: install-common
	install -m 664 -D README.dom0 $(DESTDIR)/usr/lib/qubes/example/README

install-vm: install-common
	install -m 664 -D README.vm $(DESTDIR)/usr/lib/qubes/example/README
```

### `rpm_spec/` - RPM packaging

Used when building for RPM-based distributions. Two spec templates are
provided: one for dom0 (host) and one for VMs.

**`rpm_spec/example-dom0.spec.in`** - dom0 package:

```spec
%global debug_package %{nil}
Name: qubes-example-dom0
Version: @VERSION@
Release: @REL@%{?dist}

Summary: Qubes Example package for dom0
License: GPLv2+
URL: https://www.qubes-os.org/

Source0: %{name}-%{version}.tar.gz

BuildRequires: make

%description
Qubes Example package for dom0.

%prep
%setup -q

#%build
#something to build?

%install
make install-dom0 DESTDIR=$RPM_BUILD_ROOT

%files
/usr/lib/qubes/example/README
/usr/lib/qubes/example/example.sh

%changelog
@CHANGELOG@
```

**`rpm_spec/example-vm.spec.in`** - VM package (identical structure, calls
`install-vm` and uses a different package name):

```spec
Name: qubes-example-vm
...
%install
make install-vm DESTDIR=$RPM_BUILD_ROOT
...
```

The `%global debug_package %{nil}` line at the top disables the automatic
generation of `-debuginfo` and `-debugsource` sub-packages. RPM generates
those by default for packages that contain compiled binaries. For
script-only packages there are no binaries, so the generated file list is
empty and the build fails with:

```
error: Empty %files file .../debugsourcefiles.list
```

Keep this line for any package that installs only scripts or data files.
Remove it if the package ever builds and installs compiled binaries (RPM
will then produce useful debug packages automatically).

An alternative for pure script or data packages is to declare the package
as architecture-independent instead:

```spec
BuildArch: noarch
```

`BuildArch: noarch` tells RPM the package contains no compiled binaries,
which also prevents the empty debugsource error and additionally ensures the
package is built once and installable on any architecture. Use this when the
package truly has no arch-specific content. Keep `%global debug_package %{nil}`
when you want to suppress debug sub-packages but still produce an arch-specific
package.

The placeholders replaced by the builder before the spec is used are:

| Placeholder    | Replaced with                           |
|----------------|-----------------------------------------|
| `@VERSION@`    | contents of `version`                   |
| `@REL@`        | contents of `rel`                       |
| `@CHANGELOG@`  | auto-generated changelog from git log   |

`Source0` must be `%{name}-%{version}.tar.gz` - the builder creates this
tarball automatically from the source tree.

Every file installed by the `%install` step must also be listed under
`%files`, otherwise the build fails with an unpackaged files error. If a
file should only be present on some architectures or conditionally included,
use RPM conditionals (`%ifarch`, `%if`) inside `%files`.

### `debian/` - Debian packaging

Used when building for Debian-based VM distributions (e.g. `vm-bookworm`,
`vm-trixie`). The key files are:

**`debian/control`** - source and binary package metadata:

```
Source: qubes-example
Section: admin
Priority: optional
Maintainer: Your Name <you@example.com>
Build-Depends: debhelper (>= 10), make
Standards-Version: 4.4.0.1
Homepage: https://www.qubes-os.org

Package: qubes-example
Architecture: all
Depends: ${misc:Depends}
Description: Qubes Example VM package
 Example component for Qubes OS.
```

**`debian/rules`** - the build and install script, typically a thin wrapper
around the Makefile:

```makefile
#!/usr/bin/make -f

export DESTDIR=$(shell pwd)/debian/tmp

%:
	dh $@

override_dh_auto_install:
	make install-vm
```

**`debian/changelog`** - version history in the standard Debian format. The
builder updates the version automatically so only an initial entry is needed:

```
qubes-example (1.0.0-1) unstable; urgency=medium

  * Initial release.

 -- Your Name <you@example.com>  Thu, 01 Jan 2026 00:00:00 +0000
```

**`debian/compat`** - debhelper compatibility level (use `10` or higher):

```
10
```

**`debian/source/format`** - Debian source format:

```
3.0 (quilt)
```

**`debian/qubes-example.install`** - lists files to include in the binary
package (paths relative to `DESTDIR`):

```
usr/lib/qubes/example/example.sh
usr/lib/qubes/example/README
```

**`debian/copyright`** - license declaration in the machine-readable DEP-5
format:

```
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: qubes-example
Source: https://www.qubes-os.org/

Files: *
Copyright: 2026 Your Name <you@example.com>
License: GPL-2+
 [license text...]
```

### `archlinux/` - Arch Linux packaging

Used when building for the `vm-archlinux` distribution. The directory
contains a single `PKGBUILD.in` template that the builder renders before
the build. The builder substitutes `@VERSION@` and `@REL@` (from the
`version` and `rel` files) to produce the final `PKGBUILD`.

**`archlinux/PKGBUILD.in`** - split-package PKGBUILD template:

```bash
# Maintainer: Qubes OS <user@qubes-os.org>

pkgbase=qubes-example-advanced
pkgname=('qubes-example-advanced' 'qubes-example-advanced-libs' 'qubes-example-advanced-libs-devel')
pkgver=@VERSION@
pkgrel=@REL@
pkgdesc="Qubes Example advanced dummy component for CI testing"
arch=('x86_64')
url="https://www.qubes-os.org/"
license=('GPL2')
makedepends=(make gcc)
_pkgnvr="${pkgbase}-${pkgver}-${pkgrel}"
source=("${_pkgnvr}.tar.gz")
sha256sums=(SKIP)

build() {
    cd "${_pkgnvr}"
    make build-lib
}

package_qubes-example-advanced() {
    pkgdesc="Qubes Example advanced - VM scripts"
    cd "${_pkgnvr}"
    make install-vm DESTDIR="$pkgdir" LIBDIR=/usr/lib USRLIBDIR=/usr/lib SYSLIBDIR=/usr/lib
    ...
}
```

Key points:
- `pkgbase` must match the component name used in `.qubesbuilder`.
- All packages in `pkgname` must share the same `arch` as `pkgbase` (set
  at the top of the PKGBUILD). Per-package `arch=('any')` overrides are
  **not** supported: the builder reads only the top-level `arch` array to
  determine expected package filenames, so a per-package override causes a
  filename mismatch and the copy-out step fails.
- The source archive name must follow the `${pkgbase}-${pkgver}-${pkgrel}.tar.gz`
  convention because the builder creates the archive with that name.
- Declare the `archlinux` build in `.qubesbuilder` under `vm:`:

```yaml
vm:
  archlinux:
    build:
    - archlinux   # path to the directory containing PKGBUILD.in
```


### `windows/` - Windows packaging

Used when building for Windows targets (e.g. `vm-win10`). The directory
contains a Visual Studio solution and project files. The builder invokes
MSBuild (or the EWDK equivalent) on the solution file listed in
`.qubesbuilder` and then copies the declared output artifacts.

**`.qubesbuilder` entries for Windows:**

```yaml
vm:
  windows:
    build:
    - windows/vs2022/example-advanced.sln   # solution file passed to MSBuild
    bin:
    - windows/vs2022/x64/@CONFIGURATION@/example-dummy/example-dummy.dll
    inc:
    - libexample/example.h
    lib:
    - windows/vs2022/x64/@CONFIGURATION@/example-dummy/example-dummy.lib
```

- `build:` - the `.sln` (or `.vcxproj`) file that MSBuild will build.
- `bin:` - DLL/EXE outputs to copy out after the build. `@CONFIGURATION@`
  is replaced by the `configuration` value declared in the distribution
  stage options (e.g. `release` or `debug`).
- `inc:` - header files to copy out (e.g. for SDK).
- `lib:` - import library (`.lib`) files to copy out.

The Windows executor is configured per-distribution in `builder.yml`:

```yaml
distributions:
  - vm-win10:
      stages:
        - build:
            configuration: release
            sign-qube: win-sign-test
            sign-key-name: "Qubes Windows Tools"
            test-sign: true
            executor:
              type: windows
              options:
                dispvm: win-builder-dvm
                user: user
                ewdk: /home/user/ewdk.iso
                threads: 2
```

Only the `build` stage is supported for Windows components; there is no
separate `prep` step. Signing uses a Windows code-signing key referenced
by `sign-key-name`.


### `README.dom0` / `README.vm`

Plain-text files installed as `/usr/lib/qubes/example/README` on the
relevant target. Replace these with whatever per-target documentation or
runtime instructions your component needs.

### `example.sh`

The example payload. Replace or extend this with the scripts, binaries, or
configuration files your component provides.


## Example: adding a new file

Suppose you want to install a new script `toto.sh` into both dom0 and VMs
(RPM and Debian).

**1. Create the file in the repository.**

```bash
cat > toto.sh << 'EOF'
#!/bin/bash
echo "toto"
EOF
chmod +x toto.sh
```

**2. Add the install rule to `Makefile`.**

```makefile
install-common:
	install -m 775 -D example.sh $(DESTDIR)/usr/lib/qubes/example/example.sh
	install -m 775 -D toto.sh   $(DESTDIR)/usr/lib/qubes/example/toto.sh
```

**3. Add the path to the RPM spec files under `%files`.**

In `rpm_spec/example-dom0.spec.in` and `rpm_spec/example-vm.spec.in`:

```spec
%files
/usr/lib/qubes/example/README
/usr/lib/qubes/example/example.sh
/usr/lib/qubes/example/toto.sh
```

**4. Add the path to the Debian install file.**

In `debian/qubes-example.install`:

```
usr/lib/qubes/example/example.sh
usr/lib/qubes/example/README
usr/lib/qubes/example/toto.sh
```

**5. Commit the changes.**

```bash
git add toto.sh Makefile rpm_spec/example-dom0.spec.in rpm_spec/example-vm.spec.in debian/qubes-example.install
git commit -m "Add toto.sh"
```

That is all that is needed at the source level. The rest is handled by
qubes-builderv2.


## Local test build with qubes-builderv2

> **Prerequisites:** Follow the setup instructions in the
> [qubes-builderv2 README](https://github.com/QubesOS/qubes-builderv2/blob/main/README.md)
> first - install dependencies, fetch submodules, and configure your executor
> (Qubes disposable VM, Docker, or Podman).

### 1. Clone qubes-builderv2

```bash
git clone https://github.com/QubesOS/qubes-builderv2
cd qubes-builderv2
git submodule update --init
```

### 2. Create `builder.yml`

Start from the example config that matches your target release
(`example-configs/qubes-os-r4.3.yml`) and narrow it down to just example-advanced.
Replace `/path/to/your/example-advanced` with the absolute path to your local clone
of this repository.

```yaml
# builder.yml
git:
  baseurl: https://github.com
  prefix: fepitre/qubes-
  branch: master
  maintainers:
  # fepitre's @qubes-os.org
  - 9FA64B92F95E706BF28E2CA6484010B5CDC576E2
  # fepitre's @invisiblethingslab.com
  - 77EEEF6D0386962AEA8CF84A9B8273F80AC219E6

executor:
  type: qubes
  options:
    dispvm: qubes-builder-dvm   # your builder disposable template

distributions:
  - host-fc41      # adjust to the Fedora version your dom0 runs
  - vm-fc42        # add RPM distributions as needed
  - vm-bookworm    # add Debian distributions as needed

components:
  - example-advanced:
      branch: main
      # Override the URL with a local path to your git clone.
      # Note: the builder fetches the latest commit of `branch` from that
      # local repo, so only committed changes are picked up. Uncommitted
      # working-tree changes are ignored so commit first, then build.
      url: /path/to/your/git/example-advanced
      # GPG fingerprint(s) used to verify signed tags for this component.
      # When omitted, the keys from the top-level git.maintainers list are used.
      # Setting this overrides those defaults for this component only.
      maintainers:
        - AABBCCDDEEFF00112233445566778899AABBCCDD
      # verification-mode controls how the builder verifies the source.
      # The default requires a signed tag on the fetched commit (most secure).
      # "less-secure-signed-commits-sufficient" accepts a signed commit instead,
      # which is useful during development when you haven't created a release tag yet.
      verification-mode: less-secure-signed-commits-sufficient

repository-publish:
  components: current-testing

stages:
  - fetch
  - prep
  - build
  - sign:
      executor:
        type: local
  - publish:
      executor:
        type: local
```

### 3. Run the build pipeline

Stages have declared dependencies that are resolved automatically:
`fetch` is always run by the CLI before anything else, and `build` has an
explicit job dependency on the `prep` artifact, so `get_jobs` pulls `prep`
in automatically. In practice, calling `build` is sufficient for a full
run from scratch:

```bash
./qb -c example-advanced package build
```

You can also list stages explicitly if you only want to run up to a certain
point:

```bash
./qb -c example-advanced package fetch
./qb -c example-advanced package prep
./qb -c example-advanced package build
```

Once the build succeeds, optionally sign and publish:

```bash
# Sign - requires a GPG key configured in builder.yml
./qb -c example-advanced package sign

# Publish to the local repository tree
./qb -c example-advanced package publish
```

Each stage is tracked via YAML artifact files under `artifacts/`. A stage is
skipped if its artifact already exists. To force sources to be re-fetched, `fetch`
must be explicitly listed in the stage, otherwise the
implicit fetch run skips the git pull:

```bash
./qb -c example-advanced package fetch build
```

To re-run build stages, delete the relevant artifact file under
`artifacts/components/example-advanced/`.

### 4. Inspect the built packages

Artifacts are laid out as described in the qubes-builderv2 README:

```bash
# Built RPMs
find artifacts/components/example-advanced -name '*.rpm'

# Built .deb packages
find artifacts/components/example-advanced -name '*.deb'

# Published repository tree
ls artifacts/repository-publish/
```

### 5. Install and verify

#### dom0

> **Warning:** dom0 is the most privileged and trusted component of Qubes OS.
> Installing packages in dom0 that have not been signed and verified through
> the official Qubes OS repository process is a security risk. Only do this
> with packages you built yourself from source you fully trust, on a machine
> you are comfortable treating as potentially compromised. **Proceed at your
> own risk.**

dom0 is isolated and cannot pull files directly from the builder qube. Copy
the built RPM from the builder qube (`work-qubesos`) to dom0 using
`qvm-run --pass-io`, then install it:

```bash
# Run in dom0
# artifacts/repository/ always contains only the latest built version.
# The build stage repopulates it on each run, so there is never more than
# one RPM file per component version.
qvm-run --pass-io work-qubesos \
    'cat ~/qubes-builderv2/artifacts/repository/host-fc41/example-advanced_*/qubes-example-dom0-*.rpm' \
    | sudo tee /tmp/qubes-example-dom0.rpm > /dev/null

sudo rpm -ivh /tmp/qubes-example-dom0.rpm

# Verify
/usr/lib/qubes/example/example.sh
/usr/lib/qubes/example/toto.sh
cat /usr/lib/qubes/example/README
```

#### VM distributions (RPM and Debian)

To test without modifying a template, install into either a freshly
started disposable VM based on the target template, or a dedicated testing
AppVM. Start the VM first, then copy the package to it with `qvm-copy-to-vm`
from the builder qube and install inside it.

**RPM-based (e.g. fedora-42):**

```bash
# Start a fresh dispvm based on fedora-42 or use a dedicated testing AppVM
# (replace 'test-fedora-42' with the actual running VM name)
qvm-copy-to-vm test-fedora-42 \
    ~/qubes-builderv2/artifacts/repository/vm-fc42/example-advanced_*/qubes-example-vm-*.rpm

# Inside the VM
sudo rpm -ivh ~/QubesIncoming/work-qubesos/qubes-example-vm-*.rpm
/usr/lib/qubes/example/example.sh
/usr/lib/qubes/example/toto.sh
cat /usr/lib/qubes/example/README
```

**Debian-based (e.g. bookworm):**

```bash
# Start a fresh dispvm based on debian-12 or use a dedicated testing AppVM
qvm-copy-to-vm test-bookworm \
    ~/qubes-builderv2/artifacts/repository/vm-bookworm/example-advanced_*/qubes-example_*.deb

# Inside the VM
sudo dpkg -i ~/QubesIncoming/work-qubesos/qubes-example_*.deb
/usr/lib/qubes/example/example.sh
/usr/lib/qubes/example/toto.sh
cat /usr/lib/qubes/example/README
```

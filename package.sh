#!/usr/bin/env bash

version=$(sed -n '1{p;q}' share/doc/sshyp/changelog | cut -c8-)
if [ -z "$2" ]; then
    revision=1
else
    revision="$2"
fi

_create_generic() {
    echo -e '\npackaging as generic...\n'
    mkdir -p output/generictemp/usr/{bin,lib/sshyp/extensions,share/{man/man1,bash-completion/completions}}
    cp -r lib/. output/generictemp/usr/lib/sshyp/
    ln -s /usr/lib/sshyp/sshyp.py output/generictemp/usr/bin/sshyp
    cp -r share output/generictemp/usr/
    cp extra/sshyp-completion.bash output/generictemp/usr/share/bash-completion/completions/sshyp
    cp extra/manpage output/generictemp/usr/share/man/man1/sshyp.1
    gzip output/generictemp/usr/share/man/man1/sshyp.1
    tar -C output/generictemp -cvJf output/sshyp-"$version".tar.xz usr/
    rm -rf output/generictemp
    sha512="$(sha512sum output/sshyp-"$version".tar.xz | awk '{print $1;}')"
    echo -e "\nsha512 sum:\n$sha512"
    echo -e "\ngeneric packaging complete\n"
} &&

_create_pkgbuild() {
    source='https://github.com/rwinkhart/sshyp/releases/download/v$pkgver/sshyp-$pkgver.tar.xz'
    echo -e '\ngenerating PKGBUILD...'
    echo "# Maintainer: Randall Winkhart <idgr at tutanota dot com>
pkgname=sshyp
pkgver="$version"
pkgrel="$revision"
pkgdesc='A light-weight, self-hosted, synchronized password manager'
url='https://github.com/rwinkhart/sshyp'
arch=('any')
license=('GPL-3.0-only')
depends=(python gnupg openssh xclip wl-clipboard)
optdepends=('bash-completion: bash completion support')
source=(\""$source"\")
sha512sums=('"$sha512"')

package() {
    tar xf sshyp-"\"\$pkgver\"".tar.xz -C "\"\${pkgdir}\""
}
" > output/PKGBUILD
    echo -e "\nPKGBUILD generated\n"
} &&

_create_apkbuild() {
    echo -e '\ngenerating APKBUILD...'
    echo "# Maintainer: Randall Winkhart <idgr@tutanota.com>
pkgname=sshyp
pkgver="$version"
pkgrel="$((revision-1))"
pkgdesc='A light-weight, self-hosted, synchronized password manager'
options=!check
url='https://github.com/rwinkhart/sshyp'
arch='noarch'
license='GPL-3.0-only'
depends='python3 gnupg openssh xclip wl-clipboard'
source=\""$source"\"

package() {
    mkdir -p "\"\$pkgdir\""
    cp -r "\"\$srcdir/usr/"\" "\"\$pkgdir\""
}

sha512sums=\"
"$sha512'  'sshyp-\"\$pkgver\".tar.xz"
\"
" > output/APKBUILD
    echo -e "\nAPKBUILD generated\n"
} &&

_create_hpkg() {
    echo -e '\npackaging for Haiku...\n'
    mkdir -p output/haikutemp/{bin,lib/sshyp/extensions,documentation/{packages/sshyp,man/man1},data/bash-completion/completions}
    echo "name			sshyp
version			"$version"-"$revision"
architecture		any
summary			\"A light-weight, self-hosted, synchronized password manager\"
description		\"sshyp is the only password-store compatible CLI password manager available for Haiku - it is also available on Linux/Android (via Termux) so that you can sync your entries across all of your devices.\"
packager		\"Randall Winkhart <idgr at tutanota dot com>\"
vendor			\"Randall Winkhart\"
licenses {
	\"GNU GPL v3\"
}
copyrights {
	\"2021-2022 Randall Winkhart\"
}
provides {
	sshyp = "$version"
	cmd:sshyp
}
requires {
	gnupg
	openssh
	python310
}
urls {
	\"https://github.com/rwinkhart/sshyp\"
}
" > output/haikutemp/.PackageInfo
    cp -r lib/. output/haikutemp/lib/sshyp/
    sed -i '1 s/.*/#!\/bin\/env\ python3.10/' output/haikutemp/lib/sshyp/sshync.py
    sed -i '1 s/.*/#!\/bin\/env\ python3.10/' output/haikutemp/lib/sshyp/sshyp.py
    ln -s /system/lib/sshyp/sshyp.py output/haikutemp/bin/sshyp
    cp -r share/doc/sshyp/. output/haikutemp/documentation/packages/sshyp/
    cp -r share/licenses/sshyp/. output/haikutemp/documentation/packages/sshyp/
    cp extra/sshyp-completion.bash output/haikutemp/data/bash-completion/completions/sshyp
    cp extra/manpage output/haikutemp/documentation/man/man1/sshyp.1
    gzip output/haikutemp/documentation/man/man1/sshyp.1
    cd output/haikutemp
    package create -b sshyp-"$version"-"$revision"_all.hpkg
    package add sshyp-"$version"-"$revision"_all.hpkg bin lib documentation data
    cd ../..
    mv output/haikutemp/sshyp-"$version"-"$revision"_all.hpkg output/
    rm -rf output/haikutemp
    echo -e "\nHaiku packaging complete\n"
} &&

_create_deb() {
    echo -e '\npackaging for Debian/Ubuntu...\n'
    mkdir -p output/debiantemp/sshyp_"$version"-"$revision"_all/{DEBIAN,usr/{lib/sshyp/extensions,bin,share/{bash-completion/completions,man/man1}}}
    echo "Package: sshyp
Version: $version
Section: utils
Architecture: all
Maintainer: Randall Winkhart <idgr at tutanota dot com>
Description: A light-weight, self-hosted, synchronized password manager
Depends: python3, gnupg, openssh-client, xclip, wl-clipboard
Suggests: bash-completion
Priority: optional
Installed-Size: 14584
" > output/debiantemp/sshyp_"$version"-"$revision"_all/DEBIAN/control
    cp -r lib/. output/debiantemp/sshyp_"$version"-"$revision"_all/usr/lib/sshyp/
    ln -s /usr/lib/sshyp/sshyp.py output/debiantemp/sshyp_"$version"-"$revision"_all/usr/bin/sshyp
    cp -r share output/debiantemp/sshyp_"$version"-"$revision"_all/usr/
    cp extra/sshyp-completion.bash output/debiantemp/sshyp_"$version"-"$revision"_all/usr/share/bash-completion/completions/sshyp
    cp extra/manpage output/debiantemp/sshyp_"$version"-"$revision"_all/usr/share/man/man1/sshyp.1
    gzip output/debiantemp/sshyp_"$version"-"$revision"_all/usr/share/man/man1/sshyp.1
    dpkg-deb --build --root-owner-group output/debiantemp/sshyp_"$version"-"$revision"_all/
    mv output/debiantemp/sshyp_"$version"-"$revision"_all.deb output/
    rm -rf output/debiantemp
    echo -e "\nDebian/Ubuntu packaging complete\n"
} &&

_create_termux() {
    echo -e '\npackaging for Termux...\n'
    mkdir -p output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/{DEBIAN,data/data/com.termux/files/usr/{lib/sshyp/extensions,bin,share/{bash-completion/completions,man/man1}}}
    echo "Package: sshyp
Version: $version
Section: utils
Architecture: all
Maintainer: Randall Winkhart <idgr at tutanota dot com>
Description: A light-weight, self-hosted, synchronized password manager
Depends: python, gnupg, openssh, termux-api, termux-am
Suggests: bash-completion
Priority: optional
Installed-Size: 14584
" > output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/DEBIAN/control
    cp -r lib/. output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/data/data/com.termux/files/usr/lib/sshyp/
    ln -s /data/data/com.termux/files/usr/lib/sshyp/sshyp.py output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/data/data/com.termux/files/usr/bin/sshyp
    cp -r share output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/data/data/com.termux/files/usr/
    cp extra/sshyp-completion.bash output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/data/data/com.termux/files/usr/share/bash-completion/completions/sshyp
    cp extra/manpage output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/data/data/com.termux/files/usr/share/man/man1/sshyp.1
    gzip output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/data/data/com.termux/files/usr/share/man/man1/sshyp.1
    dpkg-deb --build --root-owner-group output/termuxtemp/sshyp_"$version"-"$revision"_all_termux/
    mv output/termuxtemp/sshyp_"$version"-"$revision"_all_termux.deb output/
    rm -rf output/termuxtemp
    echo -e "\nTermux packaging complete\n"
} &&

_create_rpm() {
    echo -e '\npackaging for Fedora...\n'
    rm -rf ~/rpmbuild
    rpmdev-setuptree
    cp output/sshyp-"$version".tar.xz ~/rpmbuild/SOURCES
    echo "Name:           sshyp
Version:        "$version"
Release:        "$revision"
Summary:        A light-weight, self-hosted, synchronized password manager
BuildArch:      noarch
License:        GPL-3.0-only
URL:            https://github.com/rwinkhart/sshyp
Source0:        sshyp-"$version".tar.xz
Requires:       python gnupg openssh-clients wl-clipboard
Recommends:     bash-completion
%description
sshyp is a password-store compatible CLI password manager available for UNIX(-like) systems - its primary goal is to make syncing passwords and notes across devices as easy as possible via CLI.
%install
tar xf %{_sourcedir}/sshyp-"$version".tar.xz -C %{_sourcedir}
cp -r %{_sourcedir}/usr %{buildroot}
%files
/usr/bin/sshyp
/usr/lib/sshyp/sshyp.py
/usr/lib/sshyp/sshync.py
/usr/share/bash-completion/completions/sshyp
%license /usr/share/licenses/sshyp/license
%doc
/usr/share/doc/sshyp/changelog
/usr/share/man/man1/sshyp.1.gz
" > ~/rpmbuild/SPECS/sshyp.spec
rpmbuild -bb ~/rpmbuild/SPECS/sshyp.spec
mv ~/rpmbuild/RPMS/noarch/* output/
rm -rf ~/rpmbuild
echo -e "\nFedora packaging complete\n"
} &&

_create_freebsd_pkg() {
    echo -e '\npackaging for FreeBSD...'
    mkdir -p output/freebsdtemp/usr/{lib/sshyp/extensions,bin,share/man/man1,local/share/bash-completion/completions}
    echo "name: sshyp
version: \""$version"\"
abi = \"FreeBSD:13:*\";
arch = \"freebsd:13:*\";
origin: security/sshyp
comment: \"a password manager\"
desc: \"a light-weight, self-hosted, synchronized password manager\"
maintainer: <idgr at tutanota dot com>
www: https://github.com/rwinkhart/sshyp
prefix: /
\"deps\" : {
                   \"python\" : {
                      \"origin\" : \"lang/python\"
                   },
                   \"gnupg\" : {
                      \"origin\" : \"security/gnupg\"
                   },
                   \"xclip\" : {
                      \"origin\" : \"x11/xclip\"
                   },
                   \"wl-clipboard\" : {
                      \"origin\" : \"x11/wl-clipboard\"
                   },
                },
" > output/freebsdtemp/+MANIFEST
echo "/usr/bin/sshyp
/usr/lib/sshyp/sshync.py
/usr/lib/sshyp/sshyp.py
/usr/share/bash-completion/completions/sshyp
/usr/share/doc/sshyp/changelog
/usr/share/licenses/sshyp/license
/usr/share/man/man1/sshyp.1.gz
" > output/freebsdtemp/plist
cp -r lib/. output/freebsdtemp/usr/lib/sshyp/
ln -s /usr/lib/sshyp/sshyp.py output/freebsdtemp/usr/bin/sshyp
cp -r share output/freebsdtemp/usr/
cp extra/sshyp-completion.bash output/freebsdtemp/usr/local/share/bash-completion/completions/sshyp
cp extra/manpage output/freebsdtemp/usr/share/man/man1/sshyp.1
gzip output/freebsdtemp/usr/share/man/man1/sshyp.1
pkg create -m output/freebsdtemp/ -r output/freebsdtemp/ -p output/freebsdtemp/plist -o output/
rm -rf output/freebsdtemp
echo -e "\nFreeBSD packaging complete\n"
} &&

if [ "$1" == "generic" ]; then  # build scripts
    _create_generic
elif [ "$1" == "pkgbuild" ]; then
    _create_generic
    _create_pkgbuild
elif [ "$1" == "apkbuild" ]; then
    _create_generic
    _create_apkbuild
elif [ "$1" == "haiku" ]; then  # distribution packages
    _create_hpkg
elif [ "$1" == "debian" ]; then
    _create_deb
elif [ "$1" == "termux" ]; then
    _create_termux
elif [ "$1" == "fedora" ]; then
    _create_generic
    _create_rpm
elif [ "$1" == "freebsd" ]; then
    _create_freebsd_pkg
elif [ "$1" == "buildable-arch" ]; then
    _create_generic
    _create_pkgbuild
    _create_apkbuild
    if [[ $(pacman -Q dpkg) == "dpkg"* ]]; then
        _create_deb
        _create_termux
    fi
    if [[ "$(pacman -Q freebsd-pkg)" == "freebsd-pkg"* ]]; then
        _create_freebsd_pkg
    fi
else
    echo -e '\nusage: package.sh [target] <revision>\n\ntargets:\n mainline: pkgbuild apkbuild haiku fedora debian\n experimental: freebsd termux\n other: buildable-arch\n'
fi

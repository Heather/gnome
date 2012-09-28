# Copyright 1999-2012 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="4"
GCONF_DEBUG="no"

inherit gnome2 bash-completion-r1 virtualx
if [[ ${PV} = 9999 ]]; then
	inherit gnome2-live
fi

DESCRIPTION="Simple low-level configuration system"
HOMEPAGE="http://live.gnome.org/dconf"

LICENSE="LGPL-2.1+"
SLOT="0"
# TODO: coverage ?
IUSE="doc test +X"
if [[ ${PV} = 9999 ]]; then
	KEYWORDS=""
else
	KEYWORDS="~alpha ~amd64 ~arm ~ia64 ~ppc ~ppc64 ~sh ~sparc ~x86 ~x86-fbsd"
fi

RDEPEND=">=dev-libs/glib-2.33.3:2
	sys-apps/dbus
	X? ( >=dev-libs/libxml2-2.7.7:2
		x11-libs/gtk+:3 )"
DEPEND="${RDEPEND}
	dev-libs/libxslt
	sys-devel/gettext
	>=dev-util/intltool-0.50
	virtual/pkgconfig
	doc? ( >=dev-util/gtk-doc-1.15 )"

if [[ ${PV} = 9999 ]]; then
	DEPEND="${DEPEND}
		dev-util/gtk-doc-am
		>=dev-lang/vala-0.17.0:0.18"
fi

pkg_setup() {
	G2CONF="${G2CONF}
		--disable-schemas-compile
		--disable-gcov
		$(use_enable X editor)
		VALAC=$(type -P valac-0.18)" # harmless even if valac-0.18 not found
}

src_test() {
	Xemake check
}

src_install() {
	gnome2_src_install

	# GSettings backend may be one of: memory, gconf, dconf
	# Only dconf is really considered functional by upstream
	# must have it enabled over gconf if both are installed
	echo 'CONFIG_PROTECT_MASK="/etc/dconf"' >> 51dconf
	echo 'GSETTINGS_BACKEND="dconf"' >> 51dconf
	doenvd 51dconf

	# Install bash-completion file properly to the system
	rm -rv "${ED}usr/share/bash-completion" || die
	dobashcomp "${S}/bin/completion/dconf"
}

pkg_postinst() {
	gnome2_pkg_postinst
	# Kill existing dconf-service processes as recommended by upstream due to
	# possible changes in the dconf private dbus API.
	# dconf-service will be dbus-activated on next use.
	pids=$(pgrep -x dconf-service)
	if [[ $? == 0 ]]; then
		ebegin "Stopping dconf-service; it will automatically restart on demand"
		kill ${pids}
		eend $?
	fi
}

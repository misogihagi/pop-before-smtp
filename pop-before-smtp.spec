Summary: Watch log for POP/IMAP auth, notify Postfix to allow relay
Name: pop-before-smtp
Version: 1.42
Release: 1
Source: https://sourceforge.net/project/popbsmtp/pop-before-smtp-%{version}.tar.gz
#Source1: pop-before-smtp-conf.pl
URL: http://popbsmtp.sourceforge.net/
License: Freely Redistributable
Packager: Wayne Davison <wayned@users.sourceforge.net>
Group: Networking/Daemons
BuildArch: noarch
BuildRoot: /var/tmp/%{name}-buildroot

%description
Spam prevention requires preventing open relaying through email
servers. However, legit users want to be able to relay. If legit
users always stayed in one spot, they'd be easy to describe to the
daemon. However, what with roving laptops, logins from home, etc.,
legit users refuse to stay in one spot.

pop-before-smtp watches the mail log, looking for successful
pop/imap logins, and posts the originating IP address into a
database which can be checked by Postfix, to allow relaying for
people who have recently downloaded their email.

%prep
%setup -q

%build
echo Nothing to build...

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT/{etc/rc.d/init.d,usr/{sbin,man/man8}}
install pop-before-smtp $RPM_BUILD_ROOT/usr/sbin
pod2man pop-before-smtp >$RPM_BUILD_ROOT/usr/man/man8/pop-before-smtp.8 2>/dev/null
perl -i -e 'undef $/; $_ = <>; s/\n=head1.*\n=cut//s; print' $RPM_BUILD_ROOT/usr/sbin/pop-before-smtp
install pop-before-smtp-conf.pl $RPM_BUILD_ROOT/etc
#install %SOURCE1 $RPM_BUILD_ROOT/etc
install pop-before-smtp.init $RPM_BUILD_ROOT/etc/rc.d/init.d/pop-before-smtp

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root)

%doc README TODO ChangeLog pop-before-smtp-conf.pl
%doc contrib/README* contrib/getfromcpan contrib/perlmod2rpm
%doc /usr/man/man8/pop-before-smtp.8*
%attr(0755,root,root) /usr/sbin/pop-before-smtp
%attr(0644,root,root) %config(noreplace) /etc/pop-before-smtp-conf.pl
%attr(0755,root,root) /etc/rc.d/init.d/pop-before-smtp

%post
[ $1 = 1 ] || exit 0

/sbin/chkconfig --add pop-before-smtp

%preun
[ $1 = 0 ] || exit 0

/sbin/chkconfig --del pop-before-smtp

%changelog
* Wed Jun  6 2007 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.42

* Wed Mar  1 2006 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.41

* Sun Feb 19 2006 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.40

* Sat Jan  7 2006 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.39

* Wed Jul 13 2005 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.38

* Fri May 13 2005 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.37

* Thu Oct  3 2004 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.36

* Thu Mar  4 2004 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.35

* Fri Jan  6 2004 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.34

* Fri Mar 28 2003 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.33

* Sun Dec 15 2002 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.32

* Sat Aug 31 2002 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.31

* Fri Apr 12 2002 Wayne Davison <wayned@users.sourceforge.net>
- Modified for 1.30

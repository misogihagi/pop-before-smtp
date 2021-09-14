divert(-1)
#
# Copyright (c) 2000 Claus Assmann <ca+popauth@mine.informatik.uni-kiel.de>
#
# In short: you can do whatever you want with this, but don't blame me!
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# <URL: http://www.sendmail.org/~ca/email/chk-89n.html >
#
# Modified by Alain Knaff to make it compatible with SPF:
#
# The following config options are available:
#
# define(`POP_B4_SMTP_ISAUTH',`true')dnl
#
#  If this is set (to any value...), successful pop-before-smtp is
#  considered an authenticated connection for the purpose of SPF
#  (i.e. no SPF checks will be done on any mails sent from this IP, for
#  the duration of the pop-before-smtp "session")
#
VERSIONID(`$Id: popauth.m4,v 1.2 2006/01/07 16:29:38 wayned Exp $')

LOCAL_CONFIG
ifdef(`DATABASE_MAP_TYPE', `', `define(`DATABASE_MAP_TYPE', `hash')')
Kpopauth ifelse(defn(`_ARG_'), `',
		`DATABASE_MAP_TYPE -a<OK> /etc/mail/popauth',
		`_ARG_')
ifdef(`CF_LEVEL', `dnl has been introduced in 8.10
dnl this can be used to add a tag to entries in the map
dnl to restrict the access
ifdef(`POP_B4_SMTP_TAG',, `define(`POP_B4_SMTP_TAG', `POP:')')
')dnl

LOCAL_RULESETS
SIs_popauth_ok
R$*		$: $(popauth POP_B4_SMTP_TAG`'$&{client_addr} $: <?> $)
R<?> 		$@ NO
ifdef(`POP_B4_SMTP_ISAUTH', `dnl
define(`_NEED_MACRO_MAP_', 1)dnl
R$*		$: $1 $(macro {auth_authen} $@ PopAuth $)
')dnl
R$*		$@ YES


SLocal_check_rcpt
R$*		$: $1 $| $>Is_popauth_ok
R$* $| YES	$: $# OK
R$* $| NO	$: $1

SLocal_check_relay
R$*		$: $1 $| $>Is_popauth_ok
R$* $| YES	$: $# OK
R$* $| NO	$: $1


ifdef(`POP_B4_SMTP_ISAUTH', `dnl
dnl This is needed because sendmail wipes the macro environment at
dnl STARTTLS time which is *after* check_relay, but *before* the milter gets
dnl to see the macroes. So we have to set auth_authen again in check_mail
SLocal_check_mail
R$*		$: $1 $| $>Is_popauth_ok
R$* $| YES	$: $1
R$* $| NO	$: $1
')dnl


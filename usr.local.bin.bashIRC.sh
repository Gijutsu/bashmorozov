# Last Modified: Wed Jan 14 20:35:13 2015
#include <tunables/global>

/usr/local/bin/bashIRC.sh {
  #include <abstractions/base>
  #include <abstractions/bash>
  #include <abstractions/consoles>
  #include <abstractions/nameservice>

  /bin/bash ix,
  /bin/cat rix,
  /home/bashirc/ r,
  /usr/bin/curl rCx,
  /usr/bin/head rix,
  /usr/bin/mawk rix,
  /usr/bin/od rix,
  /usr/bin/tr rix,
  /usr/local/bin/bashIRC.sh r,

  profile /usr/bin/curl {
    #include <abstractions/base>
    #include <abstractions/nameservice>

    /usr/bin/curl r,
  }
}

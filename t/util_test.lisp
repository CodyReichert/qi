(in-package :qi-test)

(plan 5)

(ok (qi.util::is-tar-url? "https://github.com/CodyReichert/qi/master/master.tar.gz") "Is a tar url.")
(ok (qi.util::is-tar-url? "https://github.com/CodyReichert/qi/master/master.tgz") "Is a tar url.")
(ok (not (qi.util::is-tar-url? "https://github.com/CodyReichert/qi/master/master.bz2")) "Is not tar url.")

(ok (qi.util::is-git-url? "https://github.com/CodyReichert/qi") "Is a git url.")
(ok (qi.util::is-git-url? "https://github.com/CodyReichert/qi.git") "Is a git url.")

(ok (qi.util::is-gh-url? "https://github.com/CodyReichert/qi") "Is a github url.")

(ok (qi.util::is-hg-url? "https://bitbucket.org/tarballs_are_good/map-set.hg") "Is a mercurial url.")

(finalize)

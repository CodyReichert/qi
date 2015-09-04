Brainstorming
=============

"Pack" is an open, community-driven package manager. Anyone can add a package,
anyone can download a package.


Git(hub) Hosted Packages
------------------------
- Packages are hosted on Github.
  - Versioning enforced by git "tag".
  - Distribution by tarballs by taking advantage of Github's
    automatically tarballing of releases. (ie, user downloads and
    untars package into a project specific directory.)

- I think you could also get away with allowing any "git://" url
  (which would be way more ideal)

- Hold a "cache" of all known packages (ie, provide a tool for
  distribution that also stores the metadata about the repo)
    

Client
======

Publishing a package
--------------------
- Provide a command line tool for publishing packages:
  *steps*

### Package Verification
- Run installation tests with asdf/build on the spot.
- Other minor checks to make sure it's an available repo.


Installing a package
--------------------
- Could use/wrap qlot to get some nice quick features:
  - Allow specific versions of a package
  - Allow any "git://" urls (and a few others I think).
  - .qlfile is a simple way of declaring dependencies
- Packages should install to the local directory *by default*.



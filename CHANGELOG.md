# 0.2.0

- Allow Qi to be installed anywhere, rather than in `$HOME/.qi`
  (GH-13).

- Support pinning Git dependencies to a specific hash, tag or branch (GH-50).

- Teach `--install` how to look for a `qi.yaml` file when no arguments
  are given (GH-45).

- Teach `--install` to take multiple packages as arguments (GH-45).

- Ensure only the latest version of a package is kept in a project’s
  local `.dependencies` directory (GH-41).

- Simplify manifest packages (GH-30).

- Separate the Qi Manifest into a separate repository:
  https://github.com/CodyReichert/qi-manifest (GH-36)

- Remove `src-path` and `sys-path` as attributes of Dependency objects
  (GH-48, GH-49).

# 0.1.0

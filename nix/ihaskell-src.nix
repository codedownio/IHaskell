{ nix-gitignore }:

nix-gitignore.gitignoreSource [
  "**/*.ipynb"
  "**/*.nix"
  "**/*.yaml"
  "**/*.yml"
  "**/\.*"
  "/Dockerfile"
  "/README.md"
  "/cabal.project"
  "/flake.nix"
  "/flake.lock"
  "/images"
  "/notebooks"
  "/test"
  "/requirements.txt"
] ../.

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
  "/images"
  "/notebooks"
  "/test"
  "/requirements.txt"
] ../.

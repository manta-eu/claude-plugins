{
  pkgs,
  lib,
  config,
  ...
}:

let
  # Validate the marketplace and each plugin with the official validator of Claude Code. Fail if the repository has no
  # plugin.
  validatePlugins = pkgs.writeShellApplication {
    name = "validate-plugins";
    runtimeInputs = [ pkgs.claude-code ];
    text = ''
      cd "''${DEVENV_ROOT:-.}"
      shopt -s nullglob
      plugins=(plugins/*/.claude-plugin/plugin.json)
      if [ ''${#plugins[@]} -eq 0 ]; then
        echo "No plugins/*/.claude-plugin/plugin.json file found." >&2
        exit 1
      fi
      status=0
      for dir in . "''${plugins[@]%/.claude-plugin/plugin.json}"; do
        if claude plugin validate --strict "$dir"; then
          echo "PASS: $dir"
        else
          echo "FAIL: $dir" >&2
          status=1
        fi
      done
      exit "$status"
    '';
  };
in
{
  packages = [
    pkgs.claude-code
    pkgs.gh
    pkgs.jq
  ];

  # The same hooks run on each commit and in the GitHub workflow.
  git-hooks.hooks = {
    # Plugins
    claude-plugin-validate = {
      enable = true;
      name = "claude plugin validate";
      entry = lib.getExe validatePlugins;
      files = "^(\\.claude-plugin|plugins)/";
      pass_filenames = false;
    };

    # JSON, YAML, and Markdown
    # oxfmt formats JSON, YAML, and Markdown. The default hook checks only JavaScript and TypeScript.
    oxfmt = {
      enable = true;
      types_or = lib.mkForce [
        "json"
        "yaml"
        "markdown"
      ];
    };
    check-json.enable = true;
    check-yaml.enable = true;

    # Nix
    nixfmt.enable = true;
    statix.enable = true;
    deadnix.enable = true;

    # GitHub workflows
    actionlint.enable = true;

    # All files
    check-merge-conflicts.enable = true;
    check-case-conflicts.enable = true;
    editorconfig-checker.enable = true;
    typos.enable = true;
    ripsecrets.enable = true;
  };

  # Check only the changed files on commit, not every file on shell start.
  tasks."devenv:git-hooks:run".before = lib.mkForce [ ];

  scripts.validate-plugins = {
    description = "Validate the marketplace and each plugin with the official validator of Claude Code.";
    exec = lib.getExe validatePlugins;
  };

  # The GitHub workflow runs this script.
  scripts.run-hooks = {
    description = "Run every git hook on every file.";
    exec = ''
      cd "$DEVENV_ROOT"
      ${lib.getExe config.git-hooks.package} run --all-files
    '';
  };
}

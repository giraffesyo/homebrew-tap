# Homebrew tap

Source-built command-line tools for macOS and Linux:

```sh
brew install giraffesyo/tap/timeclock
brew install giraffesyo/tap/understudy
```

- [Timeclock](https://github.com/giraffesyo/timeclock): time tracking, timesheets, and reports. Connect with `timeclock --server https://time.example.com auth login`, or add `--device` for a remote terminal.
- [Understudy](https://github.com/giraffesyo/understudy): an Ansible-compatible automation engine. The build includes its Linux agents. Run `understudy version` or `understudy playbook site.yml`.

Homebrew downloads the tagged source, verifies its SHA-256 checksum, installs Go as a build dependency, and compiles locally. No prebuilt binaries or bottles are required. Timeclock's Bash, Zsh, and Fish completions are installed too.

Understudy's optional `ansible` and `ansible-playbook` aliases live outside the default PATH, so they do not replace an existing Ansible installation. To use them:

```sh
export PATH="$(brew --prefix understudy)/libexec/bin:$PATH"
```

Upgrade with `brew update` followed by `brew upgrade`.

## Release updates

Every six hours, the **Update releases** workflow checks each project's latest stable GitHub release. It validates tag formats and required source files, computes source-archive checksums, and opens or updates a PR on `automation/formula-updates`. It never downgrades a formula or accepts a draft/prerelease. GitHub automatically merges the PR after the macOS and Linux source-install checks pass; failed checks leave it open. Run the workflow manually to pick up a release sooner. Once merged, the new versions are available through `brew update` and `brew upgrade`.

The tap uses its own `GITHUB_TOKEN`; neither upstream repository needs a cross-repository PAT or webhook. The repository allows GitHub Actions to create pull requests and enables auto-merge. Branch protection on `main` requires `install (macos-15)` and `install (ubuntu-24.04)` from GitHub Actions, with the branch up to date before merging. The updater explicitly dispatches the test workflow, because PRs created by `GITHUB_TOKEN` do not trigger it automatically, then enables squash auto-merge for the exact update commit.

CI builds both formulae from source, runs installed-binary tests, and checks formula style and audits on macOS and Linux. Timeclock's formula tests a real HTTP request to a local fixture; its upstream suite covers interactive browser and device authorization end to end. Understudy's formula runs a local ping using both its own command and its Ansible alias.

## Local validation

```sh
python3 -m unittest discover -s scripts -v
brew style giraffesyo/tap
brew install --build-from-source giraffesyo/tap/timeclock
brew test giraffesyo/tap/timeclock
brew audit --strict giraffesyo/tap/timeclock
brew install --build-from-source giraffesyo/tap/understudy
brew test giraffesyo/tap/understudy
brew audit --strict giraffesyo/tap/understudy
```

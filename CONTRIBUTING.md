# Contributing

Thanks for helping. `master` is protected: open a pull request, and it is
squash-merged once CI is green.

A change to a workflow or script here reaches every Filagora package on its next
run, so keep inputs backwards compatible and say in the pull request what the
packages will see. `actionlint` runs on every pull request.

- Do not add private hostnames, IP addresses or personal email addresses to
  workflows, scripts or docs. CI runs a leak scan.

## Licence

This project is MIT licensed (see [LICENSE](LICENSE)). By submitting a pull request you agree
that your contribution is licensed under the same MIT License.

# reviews

A simple vibe-coded CLI tool that shows open pull requests awaiting review from your team. It queries GitHub's GraphQL API, groups PRs by author, and displays them with colored terminal output — PR age is green (<3 days), yellow (3–6 days), or red (7+ days).

Requires the [GitHub CLI](https://cli.github.com/) (`gh`) to be installed and authenticated.

## Setup

Create a `config.yaml` (see `config.example.yaml`):

```yaml
org: my-org
members:
  - alice
  - bob
  - charlie
```

- `org` — the GitHub organization to search
- `members` — GitHub usernames whose open PRs to show

Build and run:

```
cabal build
cabal run reviews
```

Use `--config` / `-c` to point to a different config file:

```
cabal run reviews -- -c team.yaml
```

## Example output

```
5 open PR(s) requiring review:

alice:
  my-org/backend #142 (today)
    Fix timeout on webhook delivery
    https://github.com/my-org/backend/pull/142
  my-org/backend #130 (5 days ago)
    Add retry logic for failed payments
    https://github.com/my-org/backend/pull/130
    Requested: bob | Approved by: charlie
bob:
  my-org/frontend #88 (3 days ago)
    Update dashboard layout
    https://github.com/my-org/frontend/pull/88
    Requested: alice, charlie
charlie:
  my-org/infra #55 (12 days ago)
    Migrate CI to new runner pool
    https://github.com/my-org/infra/pull/55
    Changes requested by: alice
```

In your terminal, this is color-coded:
- **Header** and **author names** are bold (authors in cyan)
- **PR age** is green / yellow / red based on how long the PR has been open
- **URLs** are dim blue
- **Approved by** is green, **Changes requested by** is red

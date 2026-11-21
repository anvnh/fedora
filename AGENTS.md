# Git Commit Guidelines

## Commit Permissions

- Never create a Git commit unless explicitly requested by the user.
- Never push commits unless explicitly requested.
- Never amend commits, rewrite history, or force-push without explicit permission.
- Never bypass Git hooks using `--no-verify`.

## Conventional Commits

Follow the Conventional Commits 1.0.0 specification.

Use the following format:

`<type>(<scope>): <description>`

The scope is optional.

### Allowed Types

- `feat`: Introduce a new feature.
- `fix`: Fix a bug.
- `refactor`: Restructure code without changing its behavior.
- `perf`: Improve performance.
- `docs`: Change documentation only.
- `test`: Add or modify tests.
- `style`: Change formatting without affecting behavior.
- `build`: Modify build systems or dependencies.
- `ci`: Modify CI/CD configuration.
- `chore`: Perform maintenance tasks not covered by other types.
- `revert`: Revert a previous commit.

### Commit Message Rules

- Write all commit messages in English.
- Use lowercase for the type and scope.
- Write the description in the imperative mood.
- Keep the subject line within 72 characters.
- Prefer concise descriptions, ideally within 50 characters.
- Do not capitalize the first word of the description unless it is a proper noun.
- Do not end the subject line with a period.
- Do not use emojis or decorative characters.
- Do not use vague descriptions such as "update files", "fix stuff", or "make changes".
- Do not include AI attribution unless explicitly requested.
- Describe the actual change rather than the files that were edited.
- Use a scope only when it adds useful context.

### Examples

- `feat(gnome): add Dash to Dock configuration`
- `fix(dnf): handle unavailable packages`
- `refactor(install): simplify package installation`
- `docs(readme): document installation steps`
- `chore(deps): update dependencies`

## Commit Body

For simple changes, use a single-line commit message.

For complex changes, include a body separated from the subject by a blank line.

- Explain what changed and why.
- Focus on the reasoning rather than repeating the subject.
- Wrap body lines at approximately 72 characters.

## Breaking Changes

For breaking changes:

- Add `!` immediately before the colon in the subject.
- Include a `BREAKING CHANGE:` footer explaining the impact.

Example:

`feat(config)!: remove legacy configuration support`

## Commit Workflow

When explicitly asked to create a commit:

1. Inspect the repository status using `git status --short`.
2. Review the relevant changes using `git diff` and `git diff --cached`.
3. Identify the logical purpose of the changes.
4. Check for unrelated modifications, secrets, and generated files.
5. Stage only files relevant to the requested commit.
6. Prefer explicit file paths over `git add -A` or `git add .`.
7. Run relevant tests, linters, or formatters when available.
8. Inspect the staged diff before committing.
9. Generate a Conventional Commits message based on the actual changes.
10. Create the commit only if the requested changes are ready.
11. Report the commit hash, message, and verification results.

## Safety Rules

- Never include API keys, passwords, tokens, or other secrets.
- Never include unrelated changes in a commit.
- Never discard or overwrite existing user changes.
- Never claim tests passed unless they were actually executed.
- If verification fails, report the failure instead of hiding it.
- If changes are unrelated, request permission before splitting them into multiple commits.
- Do not push automatically after committing.
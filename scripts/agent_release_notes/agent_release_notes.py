#!/usr/bin/env python3
"""Add the Observe Agent, OpenTelemetry Collector, and upstream Helm chart changes to an agent chart release.

Compares charts/agent/Chart.yaml at the release tag and at the previous agent-* tag. When appVersion
changed, the observe-agent checkout's scripts/upstream_changelog/upstream_changelog.py lists the agent
releases in between and the OpenTelemetry Collector changes they bring. When the upstream OpenTelemetry
Helm chart dependencies changed, the upstream chart releases in between are linked.

Usage:
    agent_release_notes.py --agent-repo PATH [--tag agent-X.Y.Z]   print the section as Markdown
    agent_release_notes.py --agent-repo PATH --update-release      also write it into the GitHub release
"""
import argparse
import os
import re
import subprocess
import sys

CHART = "charts/agent/Chart.yaml"
AGENT_SCRIPT = "scripts/upstream_changelog/upstream_changelog.py"
OTEL_HELM_REPO = "https://open-telemetry.github.io/opentelemetry-helm-charts"
OTEL_HELM_GIT = "https://github.com/open-telemetry/opentelemetry-helm-charts"
OTEL_HELM_RELEASES = f"{OTEL_HELM_GIT}/releases/tag"

MARK_START = "<!-- agent-changelog:start -->"
MARK_END = "<!-- agent-changelog:end -->"

# GitHub rejects release bodies over 125,000 characters; leave room for the generated notes.
GITHUB_BODY_LIMIT = 125_000
MAX_CHARS = 100_000


def vkey(version):
    return tuple(int(p) for p in version.split("."))


def parse_chart(text):
    """Return the chart version, appVersion, and the versions of its upstream OpenTelemetry chart dependencies."""
    version = re.search(r'^version:\s*"?([^"\s]+)"?', text, re.M).group(1)
    app_version = re.search(r'^appVersion:\s*"?([^"\s]+)"?', text, re.M).group(1)
    entries, cur, in_deps = [], None, False
    for line in text.splitlines():
        if re.match(r"^[^\s#]", line):
            in_deps, cur = line.startswith("dependencies:"), None
            continue
        if not in_deps:
            continue
        m = re.match(r"^\s*-\s+name:\s*(\S+)", line)
        if m:
            cur = {"name": m.group(1)}
            entries.append(cur)
            continue
        m = re.match(r'^\s+(version|repository):\s*"?([^"\s]+)', line)
        if m and cur is not None:
            cur[m.group(1)] = m.group(2)
    deps = {e["name"]: e["version"] for e in entries if e.get("repository") == OTEL_HELM_REPO and "version" in e}
    return {"version": version, "appVersion": app_version, "deps": deps}


def chart_version(tag):
    m = re.fullmatch(r"agent-(\d+\.\d+\.\d+)", tag)
    return vkey(m.group(1)) if m else None


def previous_tag(tag, tags):
    lower = [t for t in tags if chart_version(t) and chart_version(t) < chart_version(tag)]
    if not lower:
        sys.exit(f"error: no agent release before {tag}")
    return max(lower, key=chart_version)


def upstream_versions(name, tags):
    found = (re.fullmatch(re.escape(name) + r"-(\d+\.\d+\.\d+)", t) for t in tags)
    return [m.group(1) for m in found if m]


def render_helm_section(old, new, tags):
    lines = []
    for name in sorted(set(old) | set(new)):
        before, after = old.get(name), new.get(name)
        if before == after:
            continue
        if before is None:
            lines.append(f"- `{name}`: added at {after}")
        elif after is None:
            lines.append(f"- `{name}`: removed")
        else:
            versions = sorted((v for v in upstream_versions(name, tags) if vkey(before) < vkey(v) <= vkey(after)), key=vkey)
            links = ", ".join(f"[{v}]({OTEL_HELM_RELEASES}/{name}-{v})" for v in versions)
            lines.append(f"- `{name}` {before} → {after}" + (f": {links}" if links else ""))
    if not lines:
        return ""
    return ("## OpenTelemetry Helm chart changes\n\n"
            "The agent chart's dependencies on the upstream OpenTelemetry Helm charts changed:\n\n"
            + "\n".join(lines) + "\n")


def build(old, new, helm_md, agent_repo, budget):
    if old["appVersion"] == new["appVersion"]:
        agent_md = f"## Observe Agent changes\n\nThis chart release still uses Observe Agent {new['appVersion']}.\n"
    else:
        agent_md = run(sys.executable, os.path.join(agent_repo, AGENT_SCRIPT),
                       "--from", f"v{old['appVersion']}", "--to", f"v{new['appVersion']}",
                       "--agent-releases", "--max-chars", str(budget - len(helm_md) - 1), cwd=agent_repo)
    return agent_md + ("\n" + helm_md if helm_md else "")


def splice(body, section):
    block = f"{MARK_START}\n{section.strip()}\n{MARK_END}"
    if MARK_START in body and MARK_END in body:
        return body[: body.index(MARK_START)] + block + body[body.index(MARK_END) + len(MARK_END):]
    return body.rstrip("\n") + "\n\n" + block + "\n"


def run(*args, cwd=None, stdin=None):
    try:
        return subprocess.run(args, check=True, capture_output=True, text=True, input=stdin, cwd=cwd).stdout
    except FileNotFoundError:
        sys.exit(f"error: {args[0]} not found")
    except subprocess.CalledProcessError as err:
        sys.exit(f"error: {' '.join(args)} failed with exit status {err.returncode}:\n{err.stderr.strip()}")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--agent-repo", required=True, help="path to an observe-agent checkout with its tags")
    parser.add_argument("--tag", help="agent chart release tag (default: agent-<version in charts/agent/Chart.yaml>)")
    parser.add_argument("--update-release", action="store_true",
                        help="write the section into the GitHub release for --tag, replacing any earlier copy")
    args = parser.parse_args()
    agent_repo = os.path.abspath(args.agent_repo)

    os.chdir(run("git", "rev-parse", "--show-toplevel").strip())
    with open(CHART) as f:
        tag = args.tag or f"agent-{parse_chart(f.read())['version']}"
    tags = run("git", "tag", "--list", "agent-*").split()
    if tag not in tags:
        sys.exit(f"error: no tag {tag}; run `git fetch --tags` first")
    prev = previous_tag(tag, tags)
    old = parse_chart(run("git", "show", f"{prev}:{CHART}"))
    new = parse_chart(run("git", "show", f"{tag}:{CHART}"))

    upstream_tags = []
    for name in set(old["deps"]) & set(new["deps"]):
        if old["deps"][name] != new["deps"][name]:
            refs = run("git", "ls-remote", "--tags", "--refs", OTEL_HELM_GIT, f"refs/tags/{name}-*")
            upstream_tags += [line.split("refs/tags/", 1)[1] for line in refs.splitlines()]
    helm_md = render_helm_section(old["deps"], new["deps"], upstream_tags)
    print(f"{prev} -> {tag}: Observe Agent {old['appVersion']} -> {new['appVersion']}", file=sys.stderr)

    if args.update_release:
        body = run("gh", "release", "view", tag, "--json", "body", "-q", ".body")
        section = build(old, new, helm_md, agent_repo, min(MAX_CHARS, GITHUB_BODY_LIMIT - len(splice(body, ""))))
        run("gh", "release", "edit", tag, "--notes-file", "-", stdin=splice(body, section))
    else:
        section = build(old, new, helm_md, agent_repo, MAX_CHARS)
    print(section, end="")


if __name__ == "__main__":
    main()

"""Run: python3 -m unittest discover scripts/agent_release_notes"""
import os
import sys
import unittest
from unittest import mock

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import agent_release_notes as arn  # noqa: E402


def chart(version, app_version, collector, allocator="0.128.1"):
    return f"""apiVersion: v2
name: agent
description: Chart to install K8s collection stack based on Observe Agent
type: application
version: {version}
appVersion: "{app_version}"
dependencies:
  - name: opentelemetry-collector
    version: {collector}
    repository: https://open-telemetry.github.io/opentelemetry-helm-charts
    alias: cluster-events
    condition: cluster.events.enabled
  - name: opentelemetry-collector
    version: {collector}
    repository: https://open-telemetry.github.io/opentelemetry-helm-charts
    alias: node-logs-metrics
  # A comment between dependencies.
  - name: opentelemetry-target-allocator
    version: {allocator}
    repository: https://open-telemetry.github.io/opentelemetry-helm-charts
    alias: prometheus-ta
  - name: endpoint
    version: 0.1.0
    repository: file://../endpoint
maintainers:
  - name: Observe
    email: support@observeinc.com
"""


class ParseChartTest(unittest.TestCase):
    def test_reads_versions_and_upstream_dependencies(self):
        parsed = arn.parse_chart(chart("0.98.0", "2.20.0", "0.159.0"))
        self.assertEqual(parsed["version"], "0.98.0")
        self.assertEqual(parsed["appVersion"], "2.20.0")
        self.assertEqual(parsed["deps"], {"opentelemetry-collector": "0.159.0",
                                          "opentelemetry-target-allocator": "0.128.1"})


class PreviousTagTest(unittest.TestCase):
    def test_picks_the_highest_lower_chart_version(self):
        tags = ["agent-0.97.2", "agent-0.97.10", "agent-0.98.0", "agent-0.97.9", "stack-1.5.3"]
        self.assertEqual(arn.previous_tag("agent-0.98.0", tags), "agent-0.97.10")

    def test_first_release_has_none(self):
        with self.assertRaisesRegex(SystemExit, "no agent release before agent-0.1.0"):
            arn.previous_tag("agent-0.1.0", ["agent-0.1.0"])


class ReleaseRefsTest(unittest.TestCase):
    TAGS = ["agent-0.97.3", "agent-0.97.4"]

    def test_a_released_version_reads_its_tag(self):
        self.assertEqual(arn.release_refs("agent-0.97.4", self.TAGS, True), ("agent-0.97.3", "agent-0.97.4"))

    def test_an_unreleased_version_previews_head_against_the_latest_release(self):
        self.assertEqual(arn.release_refs("agent-0.98.0", self.TAGS, True), ("agent-0.97.4", "HEAD"))

    def test_an_unreleased_version_fails_outside_preview(self):
        with self.assertRaisesRegex(SystemExit, "no tag agent-0.98.0"):
            arn.release_refs("agent-0.98.0", self.TAGS, False)


class HelmSectionTest(unittest.TestCase):
    TAGS = ["opentelemetry-collector-0.150.0", "opentelemetry-collector-0.151.0", "opentelemetry-collector-0.159.0",
            "opentelemetry-collector-0.159.1", "opentelemetry-target-allocator-0.128.1"]

    def test_links_every_upstream_chart_release_in_range(self):
        out = arn.render_helm_section({"opentelemetry-collector": "0.150.0", "opentelemetry-target-allocator": "0.128.1"},
                                      {"opentelemetry-collector": "0.159.0", "opentelemetry-target-allocator": "0.128.1"},
                                      self.TAGS)
        base = "https://github.com/open-telemetry/opentelemetry-helm-charts/releases/tag"
        self.assertTrue(out.startswith("## OpenTelemetry Helm chart changes\n\n"))
        self.assertIn(f"- `opentelemetry-collector` 0.150.0 → 0.159.0: "
                      f"[0.151.0]({base}/opentelemetry-collector-0.151.0), "
                      f"[0.159.0]({base}/opentelemetry-collector-0.159.0)\n", out)
        self.assertNotIn("0.159.1", out)
        self.assertNotIn("target-allocator", out)

    def test_unchanged_dependencies_add_nothing(self):
        deps = {"opentelemetry-collector": "0.159.0"}
        self.assertEqual(arn.render_helm_section(deps, deps, self.TAGS), "")

    def test_added_and_removed_dependencies_are_listed(self):
        out = arn.render_helm_section({"opentelemetry-collector": "0.159.0"},
                                      {"opentelemetry-target-allocator": "0.128.1"}, self.TAGS)
        self.assertIn("- `opentelemetry-target-allocator`: added at 0.128.1\n", out)
        self.assertIn("- `opentelemetry-collector`: removed\n", out)


class BuildTest(unittest.TestCase):
    def test_unchanged_agent_gets_one_line(self):
        old = arn.parse_chart(chart("0.97.3", "2.19.2", "0.159.0"))
        new = arn.parse_chart(chart("0.97.4", "2.19.2", "0.159.0"))
        out = arn.build(old, new, "", "/agent", 100_000)
        self.assertEqual(out, "## Observe Agent changes\n\nThis chart release still uses Observe Agent 2.19.2.\n")

    def test_changed_agent_runs_the_agent_script_within_the_budget(self):
        old = arn.parse_chart(chart("0.97.4", "2.19.2", "0.150.0"))
        new = arn.parse_chart(chart("0.98.0", "2.20.0", "0.159.0"))
        helm = "## OpenTelemetry Helm chart changes\n\n- x\n"
        calls = []

        def fake_run(*args, cwd=None, stdin=None):
            calls.append((args, cwd))
            return "## Observe Agent changes\n\nagent and collector sections\n"

        with mock.patch.object(arn, "run", fake_run):
            out = arn.build(old, new, helm, "/agent", 10_000)
        args, cwd = calls[0]
        self.assertEqual(cwd, "/agent")
        self.assertEqual(args[1:], (os.path.join("/agent", arn.AGENT_SCRIPT), "--from", "v2.19.2", "--to", "v2.20.0",
                                    "--agent-releases", "--max-chars", str(10_000 - len(helm) - 1)))
        self.assertEqual(out, "## Observe Agent changes\n\nagent and collector sections\n\n" + helm)


class SpliceTest(unittest.TestCase):
    def test_appends_when_absent_and_replaces_when_present(self):
        once = arn.splice("## What's Changed\n* fix\n", "first")
        self.assertIn(f"{arn.MARK_START}\nfirst\n{arn.MARK_END}", once)
        twice = arn.splice(once, "second")
        self.assertNotIn("first", twice)
        self.assertEqual(twice.count(arn.MARK_START), 1)
        self.assertTrue(twice.startswith("## What's Changed\n* fix\n\n"))


if __name__ == "__main__":
    unittest.main()

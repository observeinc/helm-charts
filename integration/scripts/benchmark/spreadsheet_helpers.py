"""
This script will generate a CSV (tab separated) file that can be imported into a Google Sheet.
It's difficult to copy a formula, edit it, and paste it back in, so this was my workaround.
The formulae generated here are meant to be used in tandem with the csv raw data output from the
benchmark test.
"""

DATA_SHEET = "Raw Data"
CPU_REF = "$H$1"
MEM_REF = "$J$1"
PERCENTILE_REF = "$L$1"
NUM_NODES = 10

WORKLOADS = [
    {
        "name": "observe-agent-cluster-events",
        "num_pods": 1,
    },
    {
        "name": "observe-agent-cluster-metrics",
        "num_pods": 1,
    },
    {
        "name": "observe-agent-forwarder-agent",
        "num_pods": NUM_NODES,
    },
    {
        "name": "observe-agent-gateway",
        "num_pods": 3,
    },
    {
        "name": "observe-agent-monitor",
        "num_pods": 1,
    },
    {
        "name": "observe-agent-node-logs-metrics-agent",
        "num_pods": NUM_NODES,
    },
    {
        "name": "observe-agent-prometheus-scraper",
        "num_pods": 1,
    },
]


def letter_gen(total=50):
    alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    for c in alphabet:
        if total == 0:
            return
        yield c
        total -= 1
    for c in alphabet:
        for c2 in alphabet:
            if total == 0:
                return
            yield c + c2
            total -= 1
    if total != 0:
        raise Exception("Ran out of letters :(")


_letters = list(letter_gen(1 + 2 * sum(w["num_pods"] for w in WORKLOADS)))


def ll(num):
    return _letters[num]


def pod_offset_to_column_offset(pod_offset):
    # The first column is a timestamp, then each pod has two columns (CPU and memory)
    return 1 + pod_offset * 2


def pod_line(pod_name, row, data_column_offset, func, extra):
    cpu_col = ll(data_column_offset)
    mem_col = ll(data_column_offset + 1)
    return f"{pod_name}\t={func}('{DATA_SHEET}'!{cpu_col}$2:{cpu_col}$200{extra})\t=B{row}/{CPU_REF}\t={func}('{DATA_SHEET}'!{mem_col}$2:{mem_col}$200{extra})\t=D{row}/{MEM_REF}{"\t" * 7}"


def print_multi_pod_workload(workload, row, func, extra):
    num_pods = workload["num_pods"]
    print(
        f"{workload["name"]} (pod max)\t=MAX(B{row+1}:B{row+num_pods})\t=B{row}/{CPU_REF}\t=MAX(D{row+1}:D{row+num_pods})\t=D{row}/{MEM_REF}{"\t" * 7}"
    )
    col_offset = pod_offset_to_column_offset(workload["pod_offset"])
    for n in range(0, num_pods):
        i = n * 2
        print(pod_line(f"pod {n+1}", row + 1 + n, col_offset + i, func, extra))


def main():
    # Sort the workloads by name so they match the order of the raw output data. Keep track of the number of prior pods so we can translate to column offsets.
    workloads = sorted(WORKLOADS, key=lambda x: x["name"])
    pod_total = 0
    for w in workloads:
        w["pod_offset"] = pod_total
        pod_total += w["num_pods"]

    row = 1
    # We go through the workloads twice, once for the average (mean) and once for the p95.
    # Print the mean header
    print(
        "Name\tCPU (mean)\tCPU %\tMemory (mean)\tMemory %\t\tTotal CPU:\t0.5\tTotal Memory:\t=512*1024\tPercentile:\t0.95"
    )
    row += 1
    for workload in workloads:
        num_pods = workload["num_pods"]
        if num_pods == 1:
            print(
                pod_line(
                    workload["name"],
                    row,
                    pod_offset_to_column_offset(workload["pod_offset"]),
                    "AVERAGE",
                    "",
                )
            )
            row += 1
        else:
            print_multi_pod_workload(workload, row, "AVERAGE", "")
            row += 1 + num_pods

    # Now we leave a blank line and print the p95 header
    print("\t" * 11)
    print(f"Name\tCPU (p95)\tCPU %\tMemory (p95)\tMemory %{"\t" * 7}")
    row += 2
    for workload in workloads:
        num_pods = workload["num_pods"]
        if num_pods == 1:
            print(
                pod_line(
                    workload["name"],
                    row,
                    pod_offset_to_column_offset(workload["pod_offset"]),
                    "PERCENTILE",
                    f", {PERCENTILE_REF}",
                )
            )
            row += 1
        else:
            print_multi_pod_workload(workload, row, "PERCENTILE", f", {PERCENTILE_REF}")
            row += 1 + num_pods


if __name__ == "__main__":
    main()

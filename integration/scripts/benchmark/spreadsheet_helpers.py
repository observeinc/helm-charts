"""
This script will generate a CSV (tab separated) file that can be imported into a Google Sheet.
It's difficult to copy a formula, edit it, and paste it back in, so this was my workaround.
The formulae generated here are meant to be used in tandem with the csv raw data output from the
benchmark test.
"""

DATA_SHEET = "Low Volume Data"


def letters(total=50):
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


def ll(num):
    return list(letters(num))[-1]


def pod_lines(row_offset, letter_offset, num, func, extra):
    l = list(letters(2 * num + letter_offset))[letter_offset:]
    for n in range(0, num):
        i = n * 2
        yield f"pod {n+1}\t={func}('{DATA_SHEET}'!{l[i]}$2:{l[i]}$200{extra})\t=B{row_offset + n}/$H$1\t={func}('{DATA_SHEET}'!{l[i+1]}$2:{l[i+1]}$200{extra})\t=D{row_offset + n}/$H$2\t\t\t"


def pod_line_str(row_offset, letter_offset, num, func, extra):
    return "\n".join(list(pod_lines(row_offset, letter_offset, num, func, extra)))


def main():
    num_pods = 10
    header = f"""
Name\tCPU (mean)\tCPU %\tMemory (mean)\tMemory %\t\tTotal CPU:\t0.5
observe-agent-cluster-events\t=AVERAGE('{DATA_SHEET}'!B$2:B$200)\t=B2/$H$1\t=AVERAGE('{DATA_SHEET}'!C$2:C$200)\t=D2/$H$2\t\tTotal Memory:\t=512*1024
observe-agent-cluster-metrics\t=AVERAGE('{DATA_SHEET}'!D$2:D$200)\t=B3/$H$1\t=AVERAGE('{DATA_SHEET}'!E$2:E$200)\t=D3/$H$2\t\tPercentile:\t0.95
observe-agent-forwarder (pod max)\t=MAX(B5:B{4+num_pods})\t=B4/$H$1\t=MAX(D5:D{4+num_pods})\t=D4/$H$2\t\t\t
"""
    print(header.strip())
    row_offset = 5
    print(pod_line_str(row_offset, 5, num_pods, "AVERAGE", ""))
    row_offset += num_pods
    letter_offset = 6 + num_pods * 2
    next_chunk = f"""
observe-agent-monitor\t=AVERAGE('{DATA_SHEET}'!{ll(letter_offset)}$2:{ll(letter_offset)}$200)\t=B{row_offset}/$H$1\t=AVERAGE('{DATA_SHEET}'!{ll(letter_offset+1)}$2:{ll(letter_offset+1)}$200)\t=D{row_offset}/$H$2\t\t\t
observe-agent-node-logs-metrics (pod max)\t=MAX(B{row_offset+2}:B{row_offset+num_pods+1})\t=B{row_offset+1}/$H$1\t=MAX(D{row_offset+2}:D{row_offset+num_pods+1})\t=D{row_offset+1}/$H$2\t\t\t
"""
    print(next_chunk.strip())
    row_offset += 2
    print(pod_line_str(row_offset, 7 + num_pods * 2, num_pods, "AVERAGE", ""))
    row_offset += num_pods
    print("\t\t\t\t\t\t\t\nName\tCPU (p95)\tCPU %\tMemory (p95)\tMemory %\t\t\t")
    row_offset += 2
    next_chunk = f"""
observe-agent-cluster-events\t=PERCENTILE('{DATA_SHEET}'!B$2:B200, $H$3)\t=B{row_offset}/$H$1\t=PERCENTILE('{DATA_SHEET}'!C$2:C200, $H$3)\t=D{row_offset}/$H$2\t\t\t
observe-agent-cluster-metrics\t=PERCENTILE('{DATA_SHEET}'!D$2:D200, $H$3)\t=B{row_offset+1}/$H$1\t=PERCENTILE('{DATA_SHEET}'!E$2:E200, $H$3)\t=D{row_offset+1}/$H$2\t\t\t
observe-agent-forwarder (pod max)\t=MAX(B{row_offset+3}:B{row_offset+num_pods+2})\t=B{row_offset+2}/$H$1\t=MAX(D{row_offset+3}:D{row_offset+num_pods+2})\t=D{row_offset+2}/$H$2\t\t\t
"""
    print(next_chunk.strip())
    row_offset += 3
    print(pod_line_str(row_offset, 5, num_pods, "PERCENTILE", ", $H$3"))
    row_offset += num_pods
    letter_offset = 6 + num_pods * 2
    next_chunk = f"""
observe-agent-monitor\t=PERCENTILE('{DATA_SHEET}'!{ll(letter_offset)}$2:{ll(letter_offset)}$200, $H$3)\t=B{row_offset}/$H$1\t=PERCENTILE('{DATA_SHEET}'!{ll(letter_offset+1)}$2:{ll(letter_offset+1)}$200, $H$3)\t=D{row_offset}/$H$2\t\t\t
observe-agent-node-logs-metrics (pod max)\t=MAX(B{row_offset+2}:B{row_offset+num_pods+1})\t=B{row_offset+1}/$H$1\t=MAX(D{row_offset+2}:D{row_offset+num_pods+1})\t=D{row_offset+1}/$H$2\t\t\t
"""
    print(next_chunk.strip())
    row_offset += 2
    print(pod_line_str(row_offset, 7 + num_pods * 2, num_pods, "PERCENTILE", ", $H$3"))


if __name__ == "__main__":
    main()

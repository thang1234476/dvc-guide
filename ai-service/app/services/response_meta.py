import re
from app.services.verify import NORM
from app.services import dialog as TD, variants as TV


def cited_pids(answer, pids, by_id):
    match = re.search(r"Nguồn:\s*(.+)", answer)
    if not match:
        return []
    citation = NORM(match.group(1))
    if not citation:
        return []
    names = {}
    for pid in pids:
        names.setdefault(NORM(by_id[pid]["ten"]), []).append(pid)
    remaining, found = citation, set()
    for name in sorted(names, key=len, reverse=True):
        if not name:
            continue
        pattern = r"(?<!\w)" + re.escape(name) + r"(?!\w)"
        if re.search(pattern, remaining):
            found.update(names[name])
            remaining = re.sub(pattern, " ", remaining)
    if found:
        return [pid for pid in pids if pid in found]
    return [pid for pid in pids if citation in NORM(by_id[pid]["ten"])]


def variant_options(pids, by_id):
    result = []
    for pid in pids:
        title = by_id[pid]["ten"]
        group = [p for p in pids if NORM(by_id[p]["ten"]) == NORM(title)]
        label = title
        if len(group) > 1:
            label += " — " + TD.option_label(pid, by_id, group)
        result.append({"ma": pid, "ten": label})
    return result


def variant_options_text(options, by_id):
    return TV.options_text([], by_id).rstrip() + "\n" + "\n".join("- " + o["ten"] for o in options)

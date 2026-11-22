"""Validate W18 review data locally with jsonschema 4.x. No network required."""

import json
import re
from itertools import permutations
from pathlib import Path

from jsonschema import Draft202012Validator, FormatChecker


ROOT = Path(__file__).resolve().parent
CHAPTERS = {
    "scout_sniper": (2, "Steady Aim and Focus enhancements"),
    "patrolman": (3, "Reinforced Patrol"),
    "combat_medic": (4, "Emergency Treatment"),
    "woods_tracker": (5, "Improved HP and reduced redeployment cooldown"),
}
TOPICS = {
    "nest_privacy", "wildlife_rescue", "misinformation", "donor_transparency",
    "community_needs", "responsible_tourism", "trail_access",
}
EXACT_COORDINATE = re.compile(r"[+-]?\d{1,2}\.\d{3,}\s*[,;]\s*[+-]?\d{1,3}\.\d{3,}|\d+\s*[°º]")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def load_bank(kind):
    data = read_json(ROOT / f"{kind}.json")
    schema = read_json(ROOT / "schemas" / f"{kind}.schema.json")
    Draft202012Validator.check_schema(schema)
    Draft202012Validator(schema, format_checker=FormatChecker()).validate(data)
    return data


def index_by_id(rows):
    by_id = {row["id"]: row for row in rows}
    require(len(rows) == len(by_id), "A collection contains duplicate IDs")
    return by_id


def validate_question(question, sources):
    question_id = question["id"]
    choices = index_by_id(question["choices"])
    require(set(question["source_ids"]) <= sources.keys(), f"{question_id} has an unknown source")
    require(all(choice_id.startswith(f"{question_id}.") for choice_id in choices),
            f"{question_id} has a choice ID outside its namespace")
    require(len({choice["text"].strip().casefold() for choice in choices.values()}) == 4,
            f"{question_id} has duplicate choice text")
    return choices


def check_outreach_orders(question, choices):
    authored_choices = question["choices"]
    for stored_order in permutations(range(4)):
        # C15 saves indexes into the authored array. Resolve exactly as C19 must.
        ids_in_display_order = [authored_choices[index]["id"] for index in stored_order]
        grade_from_ids = [choices[choice_id]["grade"] for choice_id in ids_in_display_order]
        grade_from_indexes = [authored_choices[index]["grade"] for index in stored_order]
        require(grade_from_ids == grade_from_indexes and len(set(grade_from_ids)) == 4,
                f"{question['id']} loses a grade when shuffled")


def main():
    outreach = load_bank("outreach")
    records = load_bank("records")
    references = load_bank("references")
    sources = index_by_id(references["sources"])
    facts = index_by_id(references["facts"])
    require(set(references["garden_fact_candidates"].values()) <= facts.keys(), "Unknown Garden fact ID")
    cavity_id = "fact.hornbill_tree_cavity"
    campaign_fact = read_json(ROOT.parent / "w13" / "campaign.json")["fact_refs"][cavity_id]
    require(facts[cavity_id]["text"] == campaign_fact["claim"], "W18 disagrees with the W13 tree-cavity fact")
    require(campaign_fact["url"] in {sources[source_id]["url"] for source_id in facts[cavity_id]["source_ids"]},
            "W18 lost the W13 tree-cavity reference")
    used_sources = set()
    for fact in facts.values():
        require(set(fact["source_ids"]) <= sources.keys(), f"{fact['id']} has an unknown source")
        used_sources.update(fact["source_ids"])

    pr_questions = index_by_id(outreach["questions"])
    require({question["topic"] for question in pr_questions.values()} == TOPICS, "Outreach topic coverage differs")
    for question in pr_questions.values():
        choices = validate_question(question, sources)
        check_outreach_orders(question, choices)
        used_sources.update(question["source_ids"])

    records_questions = []
    chapters = index_by_id(records["chapters"])
    for ranger, (room_level, enhancement) in CHAPTERS.items():
        chapter = chapters[f"records_chapter.{ranger}"]
        require((chapter["records_room_level"], chapter["ranger_id"], chapter["perfect_clear_enhancement"])
                == (room_level, f"ranger.{ranger}", enhancement), f"{chapter['id']} has an incorrect gate or grant")
        require(len(chapter["questions"]) == 10, f"{chapter['id']} differs from the W18 revision 1 review split")
        for question in chapter["questions"]:
            choices = validate_question(question, sources)
            require(question["correct_choice_id"] in choices, f"{question['id']} has an invalid answer key")
            require(set(question["fact_ids"]) <= facts.keys(), f"{question['id']} has an unknown fact ID")
            used_sources.update(question["source_ids"])
        records_questions.extend(chapter["questions"])

    all_questions = list(pr_questions.values()) + records_questions
    index_by_id(all_questions)
    require(len({item["prompt"].strip().casefold() for item in all_questions}) == len(all_questions),
            "Duplicate question prompts")
    require(used_sources == sources.keys(), "The source register contains unused sources")

    # Catch numeric coordinates. Editorial review covers directions and identifying landmarks.
    public_copy = json.dumps([outreach, records, references["facts"]], ensure_ascii=False)
    require(EXACT_COORDINATE.search(public_copy) is None, "Possible exact coordinate in player copy")

    print(f"PASS 3 schemas, {len(pr_questions)} Outreach situations, {len(records_questions)} Records questions, "
          f"{len(chapters)} named chapter mappings, {len(facts)} facts, {len(sources)} sources")
    print("PASS unique IDs and prompts, W13 fact continuity, references and answer keys, "
          "480 Outreach choice permutations, numeric location scan")


if __name__ == "__main__":
    main()

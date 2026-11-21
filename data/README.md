# Runtime data

The tracked directories reserve the data domains listed in the [structure guide](../docs/STRUCTURE.md). When adding game records, use typed Godot Resources and stable IDs from the [data contracts](../docs/canon/DATA_CONTRACTS.md). Put trial values and deterministic test cases in `tests/fixtures/`. The C02 fixture lives in `data/stages/c02_first_contact.tres`. It references independent T01 map and route resources. Spawn and tunnel cells are nondeployable, route interiors are adjacent ground cells, and unlisted grid cells are nondeployable scenery. Wave slots contain ordered spawn groups with explicit counts, route indexes and intervals. Only populated waves contribute rest.

The demo uses D-006's 6/8 E01 counts, 3.5-second cadence and 25-second inter-wave rest. The 0.65 tiles per second and 10 Integrity per escape are trial values. D01 affects Token generation, which is outside C02.

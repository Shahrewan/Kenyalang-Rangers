# Player education banks

Runtime revision 2 serves 20 Outreach scenarios, four ten-question Records chapters and the cited offline facts archive. This milestone uses the [W18 source-checked banks](../../docs/production/W18_EDUCATION_BANKS.md) and two adapted questions from the supplied *Latest_rhinoceros_hornbill_quiz.pdf*. The references identify the original publications. Android includes these JSON files.

- Keep question, fact and chapter IDs stable for the same content. Bump `content_revision` if prompts, question order or choice order change. A saved Outreach rotation moves to a new revision at the next eligible batch. Records offers a replacement when a saved attempt belongs to an earlier revision.
- Outreach uses the existing grade-by-room payouts. Records uses the GDD trial amount of 30,000 Funds for each first correct answer. The exact four perfect-chapter Funds amounts remain pending. The first perfect chapter earns the Ranger enhancement and retains its existing save flag.
- The runtime `approved` field enables the owner-requested C31-C playtest content. Distribution sign-off and any later settlement of pending bonuses use the review process. [Decision log](../../docs/canon/DECISION_LOG.md#c31-c-late-campaign-and-education--2026-11-24)

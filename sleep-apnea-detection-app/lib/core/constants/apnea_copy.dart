/// Canonical, verbatim apnea-only caveat. The airflow-only D-BAND does not score
/// hypopneas, so every surface that shows the Apnea Index to a user or a
/// clinician carries this exact string (PRD FR-4.1 / EXPERIENCE.md §225).
/// Keep it in one place so the wording cannot drift between surfaces.
const String kApneaOnlyCaveat =
    "This is an apnea-only screen. A full sleep study also counts "
    "shallow-breathing (hypopnea) events and may score higher.";

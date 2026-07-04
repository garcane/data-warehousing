# Architecture Diagrams

Source and rendered diagrams for the warehouse. SVGs render directly on GitHub;
the `.drawio` file is editable at [diagrams.net](https://app.diagrams.net).

| File | What it shows | Format |
|------|---------------|--------|
| [`star-schema.svg`](star-schema.svg) | The Kimball star: `FACTOrderItem` + 5 dimensions, keys & measures | SVG (rendered) |
| [`star-schema.drawio`](star-schema.drawio) | Same star schema, **editable** | draw.io / diagrams.net |
| [`pipeline.svg`](pipeline.svg) | The 5‑layer ETL/ELT pipeline (Source → Reporting) | SVG (rendered) |

Narrative that goes with these diagrams:
- [`../docs/architecture.md`](../docs/architecture.md) — layers, lineage, keys
- [`../docs/dimensional-model.md`](../docs/dimensional-model.md) — grain, measures, SCD

> **Exporting to PNG:** open `star-schema.drawio` in diagrams.net →
> *File → Export as → PNG* if a raster copy is required. SVG is preferred in the
> repo because it stays crisp and diffs as text.

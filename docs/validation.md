# Validation evidence

Validated locally on 8 September 2026 with Java 21, Maven 3.9.5, Python 3 and Apache JMeter 5.6.3.

- Cucumber: 22 scenarios passed, zero failures.
- JMeter smoke: 52 HTTP samples, 0 unexpected failures; all per-sampler p95 values within the 1000 ms demo budget.
- The real JMeter InfluxDB Backend Listener emitted line-protocol metrics to a local HTTP collector. Dashboard field names were checked against those emitted metrics.
- Full GitHub Actions run [passed](https://github.com/Aliwaris1/ledgerguard-api-quality/actions/runs/34168870422): Cucumber, Docker API + InfluxDB + Grafana startup, JMeter smoke/SLO gate, and live dashboard/datasource/metrics verification all succeeded. The authoring machine has no Docker, so this complete stack was verified on the GitHub-hosted Ubuntu runner.
- Load and stress profiles are included but have not been used for a capacity benchmark. The Python fixture serializes state changes and keeps test tenants in memory.

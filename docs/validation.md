# Validation evidence

Validated locally on 8 September 2026 with Java 21, Maven 3.9.5, Python 3 and Apache JMeter 5.6.3.

- Cucumber: 22 scenarios passed, zero failures.
- JMeter smoke: 52 HTTP samples, 0 unexpected failures; all per-sampler p95 values within the 1000 ms demo budget.
- The real JMeter InfluxDB Backend Listener emitted line-protocol metrics to a local HTTP collector. Dashboard field names were checked against those emitted metrics.
- Docker is not installed on the authoring machine. Live InfluxDB storage and Grafana datasource verification are implemented in GitHub Actions; see the latest workflow result for end-to-end status.
- Load and stress profiles are included but have not been used for a capacity benchmark. The Python fixture serializes state changes and keeps test tenants in memory.

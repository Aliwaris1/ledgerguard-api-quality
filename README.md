# LedgerGuard — API integration & performance testing

A portfolio project by **Ali Waris · Test Automation Engineer**. Account funding, atomic payments, idempotency and reversals tested through real HTTP calls to a reproducible local API.

- **9 API operations** with stateful business workflows.
- **2 helper classes**: `ApiClient`, `TestContext`.
- **2 step-definition classes**: `IdentitySteps`, `WorkflowSteps`.
- **2 feature files**: `identity.feature`, `workflows.feature`.
- **22 Cucumber scenarios**, including positive and negative cases; Java 17+, REST Assured and JUnit Platform.
- JMeter 5.6.3 correlated workflows, smoke/load/stress profiles, per-endpoint p95 checks, and HTML reports.
- JMeter → InfluxDB → Grafana, with an automatically provisioned datasource and dashboard.

## Run integration tests

Requires Java 17+, Maven 3.9+, and Python 3.10+ (no Python packages required).

```bash
mvn test
# Select a category:
mvn test -Dcucumber.filter.tags="@negative"
```

The suite starts its own API on an available local port and stops it afterwards. Each scenario gets its own UUID tenant via PicoContainer; alice and bob can be used within that tenant to test ownership. Override Python with `-Dpython=/path/to/python3`. To target a separately started fixture, use `-DbaseUrl=http://127.0.0.1:8080`.

Reports: `target/cucumber.html`, `target/cucumber.json`, `target/cucumber.xml` and `target/surefire-reports/`.

## Run API, InfluxDB and Grafana

Requires Docker with Compose. Run one project stack at a time with the default ports.

```bash
docker compose up -d --build
curl http://127.0.0.1:8080/health
```

Open [Grafana](http://localhost:3001) and sign in with **demo / local-demo-only**. Open **API Quality → ledgerguard · API performance**. These are public, local-only demo credentials; the Compose ports bind to loopback.

## Run performance tests

Install [Apache JMeter 5.6.3](https://archive.apache.org/dist/jmeter/binaries/) and set `JMETER_HOME` to its extracted directory. With the Compose stack running:

```bash
export JMETER_HOME=/path/to/apache-jmeter-5.6.3
bash performance/run.sh smoke
bash performance/run.sh load
bash performance/run.sh stress
python3 observability/verify.py
```

| Profile | Users | Ramp-up | Iterations per user |
|---|---:|---:|---:|
| smoke | 2 | 2 seconds | 2 |
| load | 20 | 20 seconds | 20 |
| stress | 50 | 30 seconds | 30 |

Each iteration creates a fresh tenant, extracts its token and resource IDs, and completes a full business journey. Expected 409 responses have explicit status and error-body assertions, so correctly rejected negative cases do not count as failures. Unexpected responses and failed business assertions do count as failures.

`run.sh` creates a unique `results/` directory containing CSV samples, an HTML dashboard, JMeter logs, and SLO output. The default gate is zero unexpected failures and p95 ≤ 1000 ms **for every sampler**. Change `P95_BUDGET_MS` for your environment; these are demonstration budgets, not claimed production SLAs. A four-sample smoke percentile is only a wiring check, not a capacity estimate.

Overrides: `API_HOST`, `API_PORT`, `INFLUX_URL`, `P95_BUDGET_MS`. Direct JMeter arguments such as `-Jthreads=10 -Jloops=5` are also supported. The raw JMX is editable in JMeter GUI. Throughput panels use five-second buckets matching the backend listener's default flush interval; p95 is the mean of emitted interval percentiles, not a whole-run percentile. Use the JTL report for whole-run per-endpoint percentiles.

For a second concurrent stack, change `API_PORT`, `INFLUX_PORT`, and `GRAFANA_PORT` in the environment and set matching test/verification URLs. InfluxDB has no authentication because this stack is restricted to localhost.

## Project layout

```text
fixture/                         Stateful Python API fixture
src/test/java/dev/aliwaris/
  helpers/ApiClient.java          Transport and request configuration
  helpers/TestContext.java       Scenario state and fixture lifecycle
  steps/IdentitySteps.java        Authentication steps and lifecycle hooks
  steps/WorkflowSteps.java        Requests, correlation and assertions
  RunCucumberTest.java            JUnit Platform suite (not a helper)
src/test/resources/features/
  identity.feature               Authentication and access failures
  workflows.feature              Business journeys and negative cases
performance/                     JMX, profiles, runner and SLO gate
observability/                   Grafana provisioning, dashboard, verification
.github/workflows/quality.yml     Cucumber + full observability smoke CI
```

Read the [API contract](docs/api-contract.md) and [validation notes](docs/validation.md). The API is a local educational fixture with in-memory data; tests are integration tests against that fixture, not a third-party production system. Load/stress scripts are included; benchmark results must state the hardware, profile and target.

## Continuous integration

GitHub Actions runs Cucumber, starts the Docker stack, executes the JMeter smoke profile, then queries InfluxDB through Grafana to verify that metrics actually reached the dashboard datasource. Reports are uploaded even on failure. The workflow has read-only repository permissions and uses no account secrets.

```bash
docker compose down
# To intentionally discard retained performance metrics:
docker compose down -v
```

## References

[Cucumber Java](https://cucumber.io/docs/installation/java/) · [Cucumber state](https://cucumber.io/docs/cucumber/state/) · [JMeter backend listener](https://jmeter.apache.org/usermanual/component_reference.html#Backend_Listener) · [Grafana provisioning](https://grafana.com/docs/grafana/latest/administration/provisioning/)

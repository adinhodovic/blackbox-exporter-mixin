local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';
local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local statPanel = g.panel.stat;
local timeSeriesPanel = g.panel.timeSeries;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;
local prometheus = g.query.prometheus;

// Stat
local stOptions = statPanel.options;
local stStandardOptions = statPanel.standardOptions;
local stQueryOptions = statPanel.queryOptions;
local stPanelOptions = statPanel.panelOptions;

// Timeseries
local tsOptions = timeSeriesPanel.options;
local tsStandardOptions = timeSeriesPanel.standardOptions;
local tsQueryOptions = timeSeriesPanel.queryOptions;
local tsFieldConfig = timeSeriesPanel.fieldConfig;
local tsCustom = tsFieldConfig.defaults.custom;
local tsLegend = tsOptions.legend;

{
  grafanaDashboards+:: {

    local datasourceVariable =
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.withRegex($._config.datasourceFilterRegex) +
      datasource.generalOptions.withLabel('Data source') +
      {
        current: {
          selected: true,
          text: $._config.datasourceName,
          value: $._config.datasourceName,
        },
      },

    local clusterVariable =
      query.new(
        $._config.clusterLabel,
        'label_values(probe_success{}, cluster)' % $._config,
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort() +
      query.generalOptions.withLabel('Cluster') +
      query.refresh.onLoad() +
      query.refresh.onTime() +
      (
        if $._config.showMultiCluster
        then query.generalOptions.showOnDashboard.withLabelAndValue()
        else query.generalOptions.showOnDashboard.withNothing()
      ),

    local jobVariable =
      query.new(
        'job',
        'label_values(probe_success{%(clusterLabel)s="$cluster"}, job)' % $._config,
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Job') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local instanceVariable =
      query.new(
        'instance',
        'label_values(probe_success{%(clusterLabel)s="$cluster", job=~"$job"}, instance)' % $._config,
      ) +
      query.withDatasourceFromVariable(datasourceVariable) +
      query.withSort(1) +
      query.generalOptions.withLabel('Instance') +
      query.selectionOptions.withMulti(false) +
      query.selectionOptions.withIncludeAll(false) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    local variables = [
      datasourceVariable,
      clusterVariable,
      jobVariable,
      instanceVariable,
    ],

    local statusMapQuery = |||
      max by (instance) (
        probe_success{
          %(clusterLabel)s="$cluster",
          job=~"$job"
        }
      )
    ||| % $._config,

    local statusMapStatPanel =
      statPanel.new(
        'Status Map',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          statusMapQuery,
        ) +
        prometheus.withLegendFormat(
          '{{instance}}'
        ),
      ) +
      stOptions.withTextMode('value_and_name') +
      stOptions.text.withTitleSize(18) +
      stOptions.text.withValueSize(18) +
      stOptions.withColorMode('background') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.withUnit('short') +
      stQueryOptions.withMaxDataPoints(100) +
      stStandardOptions.withMappings(
        stStandardOptions.mapping.ValueMap.withType() +
        stStandardOptions.mapping.ValueMap.withOptions(
          {
            '0': { text: 'Down', color: 'red' },
            '1': { text: 'Up', color: 'green' },
          }
        )
      ) +
      stStandardOptions.withLinks([
        stPanelOptions.link.withTitle('Go To Probe') +
        stPanelOptions.link.withType('link') +
        stPanelOptions.link.withUrl(
          'd/' + $._config.dashboardUid + '/blackbox-exporter?var-instance=${__field.labels.instance}&var-job=${__field.labels.job}',
        ) +
        stPanelOptions.link.withTargetBlank(true),
      ]),

    local probesQuery = |||
      count(
        probe_success{
          %(clusterLabel)s="$cluster",
          job=~"$job"
        }
      )
    ||| % $._config,

    local probesStatPanel =
      statPanel.new(
        'Probes',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          probesQuery,
        )
      ) +
      stStandardOptions.withUnit('short') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0.0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.001) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local probesSuccessQuery = |||
      (
        count(
          probe_success{
            %(clusterLabel)s="$cluster",
            job=~"$job"
          } == 1
        )
        OR vector(0)
      ) /
      count(
        probe_success{
          %(clusterLabel)s="$cluster",
          job=~"$job"
        }
      )
    ||| % $._config,

    local probesSuccessStatPanel =
      statPanel.new(
        'Probes Success',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          probesSuccessQuery,
        )
      ) +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.withUnit('percentunit') +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0.0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.99) +
        stStandardOptions.threshold.step.withColor('yellow'),
        stStandardOptions.threshold.step.withValue(0.999) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local probesSSLQuery = |||
      count(
        probe_http_ssl{
          %(clusterLabel)s="$cluster",
          job=~"$job"
        } == 1
      ) /
      count(
        probe_http_version{
          %(clusterLabel)s="$cluster",
          job=~"$job"
        }
      )
    ||| % $._config,

    local probesSSLStatPanel =
      statPanel.new(
        'Probes SSL',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          probesSSLQuery,
        )
      ) +
      stStandardOptions.withUnit('percentunit') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0.0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.999) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local probeDurationQuery = |||
      avg(
        probe_duration_seconds{
          %(clusterLabel)s="$cluster",
          job=~"$job"
        }
      )
    ||| % $._config,

    local probeDurationStatPanel =
      statPanel.new(
        'Probe Average Duration',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          probeDurationQuery,
        )
      ) +
      stStandardOptions.withUnit('s') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']),

    local uptimeQuery = |||
      max by (instance) (
        probe_success{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local uptimeStatPanel =
      statPanel.new(
        'Uptime',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          uptimeQuery,
        )
      ) +
      stStandardOptions.withUnit('percentunit') +
      stOptions.withColorMode('background') +
      stOptions.reduceOptions.withCalcs(['mean']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0.0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.99) +
        stStandardOptions.threshold.step.withColor('yellow'),
        stStandardOptions.threshold.step.withValue(0.999) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local uptime30dQuery = |||
      avg_over_time(
        probe_success{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }[30d]
      )
    ||| % $._config,

    local uptime30dStatPanel =
      statPanel.new(
        'Uptime 30d',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          uptime30dQuery,
        )
      ) +
      stStandardOptions.withUnit('percentunit') +
      stOptions.withColorMode('background') +
      stOptions.reduceOptions.withCalcs(['mean']) +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0.0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(0.99) +
        stStandardOptions.threshold.step.withColor('yellow'),
        stStandardOptions.threshold.step.withValue(0.999) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local probeSuccessQuery = |||
      max by (instance) (
        probe_success{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local probeSuccessStatPanel =
      statPanel.new(
        'Probe Success',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          probeSuccessQuery,
        ) +
        prometheus.withInstant(true),
      ) +
      stStandardOptions.withUnit('short') +
      stOptions.withColorMode('background') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.withMappings(
        stStandardOptions.mapping.ValueMap.withType() +
        stStandardOptions.mapping.ValueMap.withOptions(
          {
            '0': { text: 'No', color: 'red' },
            '1': { text: 'Yes', color: 'green' },
          }
        )
      ),

    local latestResponseCodeQuery = |||
      max by (instance) (
        probe_http_status_code{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local latestResponseCodeStatPanel =
      statPanel.new(
        'Latest Response Code',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          latestResponseCodeQuery,
        ) +
        prometheus.withInstant(true),
      ) +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.withUnit('short') +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('green'),
        stStandardOptions.threshold.step.withValue(300) +
        stStandardOptions.threshold.step.withColor('blue'),
        stStandardOptions.threshold.step.withValue(400) +
        stStandardOptions.threshold.step.withColor('yellow'),
        stStandardOptions.threshold.step.withValue(500) +
        stStandardOptions.threshold.step.withColor('red'),
      ]),

    local sslQuery = |||
      max by (instance) (
        probe_http_ssl{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local sslStatPanel =
      statPanel.new(
        'SSL',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          sslQuery,
        ) +
        prometheus.withInstant(true),
      ) +
      stOptions.withColorMode('background') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.withUnit('short') +
      stStandardOptions.withMappings([
        stStandardOptions.mapping.ValueMap.withType() +
        stStandardOptions.mapping.ValueMap.withOptions(
          {
            '0': { text: 'No', color: 'red' },
            '1': { text: 'Yes', color: 'green' },
          }
        ),
      ]),

    local sslVersionQuery = |||
      max by (instance,version) (
        probe_tls_version_info{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local sslVersionStatPanel =
      statPanel.new(
        'SSL Version',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          sslVersionQuery,
        ) +
        prometheus.withInstant(true) +
        prometheus.withLegendFormat('{{version}}')
      ) +
      stOptions.withTextMode('name') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.withUnit('short') +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(1) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local redirectsQuery = |||
      max by (instance) (
        probe_http_redirects{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local redirectsStatPanel =
      statPanel.new(
        'Redirects',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          redirectsQuery,
        ) +
        prometheus.withInstant(true),
      ) +
      stOptions.withColorMode('background') +
      stOptions.reduceOptions.withCalcs(['lastNotNull']) +
      stStandardOptions.withUnit('short') +
      stStandardOptions.withMappings(
        stStandardOptions.mapping.ValueMap.withType() +
        stStandardOptions.mapping.ValueMap.withOptions(
          {
            '0': { text: 'No', color: 'green' },
            '1': { text: 'Yes', color: 'blue' },
          }
        ),
      ),

    local httpVersionQuery = |||
      max by (instance) (
        probe_http_version{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local httpVersionStatPanel =
      statPanel.new(
        'HTTP Version',
      ) +
      stStandardOptions.withUnit('short') +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          httpVersionQuery,
        ) +
        prometheus.withInstant(true) +
        prometheus.withLegendFormat('{{version}}'),
      ) +
      stOptions.reduceOptions.withCalcs(['lastNotNull']),


    local sslCertificateExpiryQuery = |||
      min by (instance) (
        probe_ssl_earliest_cert_expiry{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        } - time()
      )
    ||| % $._config,

    local sslCertificateExpiryStatPanel =
      statPanel.new(
        'SSL Certificate Expiry',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          sslCertificateExpiryQuery,
        )
      ) +
      stOptions.withColorMode('background') +
      stOptions.withGraphMode('none') +
      stStandardOptions.withUnit('dtdurations') +
      stStandardOptions.thresholds.withSteps([
        stStandardOptions.threshold.step.withValue(0.0) +
        stStandardOptions.threshold.step.withColor('red'),
        stStandardOptions.threshold.step.withValue(($._config.probeSslExpireDaysThreshold) * 24 * 3600) +
        stStandardOptions.threshold.step.withColor('green'),
      ]),

    local averageLatencyQuery = |||
      avg by (instance) (
        probe_duration_seconds{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local averageLatencyStatPanel =
      statPanel.new(
        'Average Latency',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          averageLatencyQuery,
        )
      ) +
      stStandardOptions.withUnit('s') +
      stOptions.reduceOptions.withCalcs(['mean']),

    local averageDnsLookupQuery = |||
      avg by (instance) (
        probe_dns_lookup_time_seconds{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local averageDnsLookupStatPanel =
      statPanel.new(
        'Average Latency',
      ) +
      stQueryOptions.withTargets(
        prometheus.new(
          '$datasource',
          averageDnsLookupQuery,
        )
      ) +
      stStandardOptions.withUnit('s') +
      stOptions.reduceOptions.withCalcs(['mean']),

    local probeHttpDurationQuery = |||
      sum by (instance) (
        avg by (phase,instance) (
          probe_http_duration_seconds{
            %(clusterLabel)s="$cluster",
            job=~"$job",
            instance=~"$instance"
          }
        )
      )
    ||| % $._config,
    local probeTotalDurationQuery = |||
      avg by (instance) (
        probe_duration_seconds{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      )
    ||| % $._config,

    local probeDurationTimeSeriesPanel =
      timeSeriesPanel.new(
        'Probe Duration',
      ) +
      tsQueryOptions.withTargets(
        [
          prometheus.new(
            '$datasource',
            probeHttpDurationQuery,
          ) +
          prometheus.withLegendFormat(
            'HTTP duration'
          ),
          prometheus.new(
            '$datasource',
            probeTotalDurationQuery,
          ) +
          prometheus.withLegendFormat(
            'Total probe duration'
          ),
        ]
      ) +
      tsStandardOptions.withUnit('s') +
      tsOptions.tooltip.withMode('multi') +
      tsOptions.tooltip.withSort('desc') +
      tsLegend.withShowLegend(true) +
      tsLegend.withDisplayMode('table') +
      tsLegend.withPlacement('right') +
      tsLegend.withCalcs(['mean', 'max']) +
      tsLegend.withSortBy('Mean') +
      tsLegend.withSortDesc(true) +
      tsCustom.withFillOpacity(10) +
      tsCustom.withSpanNulls(false),


    local probeHttpPhaseDurationQuery = |||
      avg(
        probe_http_duration_seconds{
          %(clusterLabel)s="$cluster",
          job=~"$job",
          instance=~"$instance"
        }
      ) by (phase)
    ||| % $._config,
    local probeIcmpPhaseDurationQuery = std.strReplace(probeHttpPhaseDurationQuery, 'probe_http_duration_seconds', 'probe_icmp_duration_seconds'),

    local probePhaseTimeSeriesPanel =
      timeSeriesPanel.new(
        'Probe Phases',
      ) +
      tsQueryOptions.withTargets(
        [
          prometheus.new(
            '$datasource',
            probeHttpPhaseDurationQuery,
          ) +
          prometheus.withLegendFormat(
            '{{ phase }}'
          ),
          prometheus.new(
            '$datasource',
            probeIcmpPhaseDurationQuery,
          ) +
          prometheus.withLegendFormat(
            '{{ phase }}'
          ),
        ]
      ) +
      tsStandardOptions.withUnit('s') +
      tsOptions.tooltip.withMode('multi') +
      tsOptions.tooltip.withSort('desc') +
      tsLegend.withShowLegend(true) +
      tsLegend.withDisplayMode('table') +
      tsLegend.withPlacement('right') +
      tsLegend.withCalcs(['mean', 'max']) +
      tsLegend.withSortBy('Mean') +
      tsLegend.withSortDesc(true) +
      tsCustom.stacking.withMode('percent') +
      tsCustom.withFillOpacity(100) +
      tsCustom.withSpanNulls(false),

    local summaryRow =
      row.new(
        title='Summary'
      ),

    local individualProbesRow =
      row.new(
        title='$instance',
      ) +
      row.withRepeat('instance'),

    'blackbox-exporter.json':
      $._config.bypassDashboardValidation +
      dashboard.new(
        'Blackbox Exporter',
      ) +
      dashboard.withDescription('A dashboard that monitors the Blackbox-exporter. It is created using the [blackbox-exporter-mixin](https://github.com/adinhodovic/blackbox-exporter-mixin) for the the (blackbox-exporter)[https://github.com/prometheus/blackbox_exporter].') +
      dashboard.withUid($._config.dashboardUid) +
      dashboard.withTags($._config.tags) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(true) +
      dashboard.time.withFrom('now-2d') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withPanels(
        [
          summaryRow +
          row.gridPos.withX(0) +
          row.gridPos.withY(0) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
          statusMapStatPanel +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(1) +
          statPanel.gridPos.withW(24) +
          statPanel.gridPos.withH(5),
        ] +
        grid.makeGrid(
          [probesStatPanel, probesSuccessStatPanel, probesSSLStatPanel, probeDurationStatPanel],
          panelWidth=6,
          panelHeight=4,
          startY=6
        ) +
        [
          individualProbesRow +
          row.gridPos.withX(0) +
          row.gridPos.withY(10) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
          uptimeStatPanel +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(11) +
          statPanel.gridPos.withW(6) +
          statPanel.gridPos.withH(4),
          uptime30dStatPanel +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(15) +
          statPanel.gridPos.withW(6) +
          statPanel.gridPos.withH(4),
        ] +
        grid.makeGrid(
          [probeSuccessStatPanel, latestResponseCodeStatPanel],
          panelWidth=3,
          panelHeight=2,
          startY=15
        ) +
        grid.makeGrid(
          [sslStatPanel, sslVersionStatPanel],
          panelWidth=3,
          panelHeight=2,
          startY=17
        ) +
        [
          sslCertificateExpiryStatPanel +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(19) +
          statPanel.gridPos.withW(6) +
          statPanel.gridPos.withH(2),
        ] +
        grid.makeGrid(
          [redirectsStatPanel, httpVersionStatPanel],
          panelWidth=3,
          panelHeight=2,
          startY=22
        ) +
        grid.makeGrid(
          [averageLatencyStatPanel, averageDnsLookupStatPanel],
          panelWidth=3,
          panelHeight=4,
          startY=25
        ) +
        [
          probeDurationTimeSeriesPanel +
          timeSeriesPanel.gridPos.withX(6) +
          timeSeriesPanel.gridPos.withY(11) +
          timeSeriesPanel.gridPos.withW(18) +
          timeSeriesPanel.gridPos.withH(10),
          probePhaseTimeSeriesPanel +
          timeSeriesPanel.gridPos.withX(6) +
          timeSeriesPanel.gridPos.withY(21) +
          timeSeriesPanel.gridPos.withW(18) +
          timeSeriesPanel.gridPos.withH(10),
        ]
      ),
  },
}

local util = import './util.libsonnet';
local mixinUtils = import 'github.com/adinhodovic/mixin-utils/utils.libsonnet';
local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;
local row = g.panel.row;
local grid = g.util.grid;

local statPanel = g.panel.stat;
local timeSeriesPanel = g.panel.timeSeries;

{
  local dashboardName = 'blackbox-exporter',
  grafanaDashboards+:: {
    ['%s.json' % dashboardName]:

      local defaultVariables = util.variables($._config);

      local variables = [
        defaultVariables.datasource,
        defaultVariables.cluster,
        defaultVariables.job,
        defaultVariables.instance,
      ];

      local defaultFilters = util.filters($._config);

      local queries = {
        // Summary
        probesCount: |||
          count(
            probe_success{
              %(default)s
            }
          )
        ||| % defaultFilters,

        probesSuccessPercent: |||
          (
            count(
              probe_success{
                %(default)s
              } == 1
            )
            OR vector(0)
          ) /
          count(
            probe_success{
              %(default)s
            }
          )
        ||| % defaultFilters,

        probesSslPercent: |||
          count(
            probe_http_ssl{
              %(default)s
            } == 1
          ) /
          count(
            probe_http_version{
              %(default)s
            }
          )
        ||| % defaultFilters,

        probeAverageDuration: |||
          avg(
            probe_duration_seconds{
              %(default)s
            }
          )
        ||| % defaultFilters,

        statusMap: |||
          max by (instance) (
            probe_success{
              %(default)s
            }
          )
        ||| % defaultFilters,

        // Per-instance
        uptime: |||
          max by (instance) (
            probe_success{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        uptime30d: |||
          avg_over_time(
            probe_success{
              %(instance)s
            }[30d]
          )
        ||| % defaultFilters,

        probeSuccess: |||
          max by (instance) (
            probe_success{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        latestResponseCode: |||
          max by (instance) (
            probe_http_status_code{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        ssl: |||
          max by (instance) (
            probe_http_ssl{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        sslVersion: |||
          max by (instance,version) (
            probe_tls_version_info{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        redirects: |||
          max by (instance) (
            probe_http_redirects{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        httpVersion: |||
          max by (instance) (
            probe_http_version{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        sslCertificateExpiry: |||
          min by (instance) (
            probe_ssl_earliest_cert_expiry{
              %(instance)s
            } - time()
          )
        ||| % defaultFilters,

        averageLatency: |||
          avg by (instance) (
            probe_duration_seconds{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        averageDnsLookup: |||
          avg by (instance) (
            probe_dns_lookup_time_seconds{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        probeHttpDuration: |||
          sum by (instance) (
            avg by (phase,instance) (
              probe_http_duration_seconds{
                %(instance)s
              }
            )
          )
        ||| % defaultFilters,

        probeTotalDuration: |||
          avg by (instance) (
            probe_duration_seconds{
              %(instance)s
            }
          )
        ||| % defaultFilters,

        probeHttpPhaseDuration: |||
          avg(
            probe_http_duration_seconds{
              %(instance)s
            }
          ) by (phase)
        ||| % defaultFilters,

        probeIcmpPhaseDuration: std.strReplace(
          self.probeHttpPhaseDuration,
          'probe_http_duration_seconds',
          'probe_icmp_duration_seconds'
        ),
      };

      local panels = {
        // Summary
        statusMapStat:
          mixinUtils.dashboards.statPanel(
            'Status Map',
            'short',
            queries.statusMap,
            description='Current up/down status for all probes. Each probe is shown as Up (green) or Down (red). Click a probe to navigate to its detail view.',
            mappings=[
              statPanel.standardOptions.mapping.ValueMap.withType() +
              statPanel.standardOptions.mapping.ValueMap.withOptions(
                {
                  '0': { text: 'Down', color: 'red' },
                  '1': { text: 'Up', color: 'green' },
                }
              ),
            ],
          ) +
          statPanel.queryOptions.withTargets(
            g.query.prometheus.new('${datasource}', queries.statusMap) +
            g.query.prometheus.withLegendFormat('{{instance}}')
          ) +
          statPanel.options.withTextMode('value_and_name') +
          statPanel.options.text.withTitleSize(18) +
          statPanel.options.text.withValueSize(18) +
          statPanel.options.withColorMode('background') +
          statPanel.queryOptions.withMaxDataPoints(100) +
          statPanel.standardOptions.withLinks([
            statPanel.panelOptions.link.withTitle('Go To Probe') +
            statPanel.panelOptions.link.withType('link') +
            statPanel.panelOptions.link.withUrl(
              'd/' + $._config.dashboardIds[dashboardName] + '/blackbox-exporter?var-instance=${__field.labels.instance}&var-job=${__field.labels.job}',
            ) +
            statPanel.panelOptions.link.withTargetBlank(true),
          ]),

        probesCountStat:
          mixinUtils.dashboards.statPanel(
            'Probes',
            'short',
            queries.probesCount,
            description='Total number of probes currently being monitored.',
            steps=[
              statPanel.standardOptions.threshold.step.withValue(0.0) +
              statPanel.standardOptions.threshold.step.withColor('red'),
              statPanel.standardOptions.threshold.step.withValue(0.001) +
              statPanel.standardOptions.threshold.step.withColor('green'),
            ],
          ),

        probesSuccessPercentStat:
          mixinUtils.dashboards.statPanel(
            'Probes Success',
            'percentunit',
            queries.probesSuccessPercent,
            description='Percentage of probes currently reporting success.',
            steps=[
              statPanel.standardOptions.threshold.step.withValue(0.0) +
              statPanel.standardOptions.threshold.step.withColor('red'),
              statPanel.standardOptions.threshold.step.withValue(0.99) +
              statPanel.standardOptions.threshold.step.withColor('yellow'),
              statPanel.standardOptions.threshold.step.withValue(0.999) +
              statPanel.standardOptions.threshold.step.withColor('green'),
            ],
          ),

        probesSslPercentStat:
          mixinUtils.dashboards.statPanel(
            'Probes SSL',
            'percentunit',
            queries.probesSslPercent,
            description='Percentage of HTTP probes using SSL/TLS.',
            steps=[
              statPanel.standardOptions.threshold.step.withValue(0.0) +
              statPanel.standardOptions.threshold.step.withColor('red'),
              statPanel.standardOptions.threshold.step.withValue(0.999) +
              statPanel.standardOptions.threshold.step.withColor('green'),
            ],
          ),

        probeAverageDurationStat:
          mixinUtils.dashboards.statPanel(
            'Probe Average Duration',
            's',
            queries.probeAverageDuration,
            description='Average probe duration across all monitored instances.',
          ),

        // Per-instance
        uptimeStat:
          mixinUtils.dashboards.statPanel(
            'Uptime',
            'percentunit',
            queries.uptime,
            description='Current probe success rate for the selected instance.',
            steps=[
              statPanel.standardOptions.threshold.step.withValue(0.0) +
              statPanel.standardOptions.threshold.step.withColor('red'),
              statPanel.standardOptions.threshold.step.withValue(0.99) +
              statPanel.standardOptions.threshold.step.withColor('yellow'),
              statPanel.standardOptions.threshold.step.withValue(0.999) +
              statPanel.standardOptions.threshold.step.withColor('green'),
            ],
          ) +
          statPanel.options.withColorMode('background') +
          statPanel.options.reduceOptions.withCalcs(['mean']),

        uptime30dStat:
          mixinUtils.dashboards.statPanel(
            'Uptime 30d',
            'percentunit',
            queries.uptime30d,
            instant=true,
            description='Average probe success rate over the last 30 days.',
            steps=[
              statPanel.standardOptions.threshold.step.withValue(0.0) +
              statPanel.standardOptions.threshold.step.withColor('red'),
              statPanel.standardOptions.threshold.step.withValue(0.99) +
              statPanel.standardOptions.threshold.step.withColor('yellow'),
              statPanel.standardOptions.threshold.step.withValue(0.999) +
              statPanel.standardOptions.threshold.step.withColor('green'),
            ],
          ) +
          statPanel.options.withColorMode('background') +
          statPanel.options.reduceOptions.withCalcs(['mean']),

        probeSuccessStat:
          mixinUtils.dashboards.statPanel(
            'Probe Success',
            'short',
            queries.probeSuccess,
            instant=true,
            description='Whether the most recent probe succeeded.',
            mappings=[
              statPanel.standardOptions.mapping.ValueMap.withType() +
              statPanel.standardOptions.mapping.ValueMap.withOptions(
                {
                  '0': { text: 'No', color: 'red' },
                  '1': { text: 'Yes', color: 'green' },
                }
              ),
            ],
          ) +
          statPanel.options.withColorMode('background'),

        latestResponseCodeStat:
          mixinUtils.dashboards.statPanel(
            'Latest Response Code',
            'short',
            queries.latestResponseCode,
            instant=true,
            description='Most recent HTTP status code returned by the probe.',
            steps=[
              statPanel.standardOptions.threshold.step.withValue(0) +
              statPanel.standardOptions.threshold.step.withColor('green'),
              statPanel.standardOptions.threshold.step.withValue(300) +
              statPanel.standardOptions.threshold.step.withColor('blue'),
              statPanel.standardOptions.threshold.step.withValue(400) +
              statPanel.standardOptions.threshold.step.withColor('yellow'),
              statPanel.standardOptions.threshold.step.withValue(500) +
              statPanel.standardOptions.threshold.step.withColor('red'),
            ],
          ),

        sslStat:
          mixinUtils.dashboards.statPanel(
            'SSL',
            'short',
            queries.ssl,
            instant=true,
            description='Whether the probe endpoint is using SSL/TLS.',
            mappings=[
              statPanel.standardOptions.mapping.ValueMap.withType() +
              statPanel.standardOptions.mapping.ValueMap.withOptions(
                {
                  '0': { text: 'No', color: 'red' },
                  '1': { text: 'Yes', color: 'green' },
                }
              ),
            ],
          ) +
          statPanel.options.withColorMode('background'),

        sslVersionStat:
          mixinUtils.dashboards.statPanel(
            'SSL Version',
            'short',
            queries.sslVersion,
            instant=true,
            description='TLS version negotiated for the probe connection.',
            steps=[
              statPanel.standardOptions.threshold.step.withValue(0) +
              statPanel.standardOptions.threshold.step.withColor('red'),
              statPanel.standardOptions.threshold.step.withValue(1) +
              statPanel.standardOptions.threshold.step.withColor('green'),
            ],
          ) +
          statPanel.queryOptions.withTargets(
            g.query.prometheus.new('${datasource}', queries.sslVersion) +
            g.query.prometheus.withInstant(true) +
            g.query.prometheus.withLegendFormat('{{version}}')
          ) +
          statPanel.options.withTextMode('name'),

        redirectsStat:
          mixinUtils.dashboards.statPanel(
            'Redirects',
            'short',
            queries.redirects,
            instant=true,
            description='Whether the probe followed any HTTP redirects.',
            mappings=[
              statPanel.standardOptions.mapping.ValueMap.withType() +
              statPanel.standardOptions.mapping.ValueMap.withOptions(
                {
                  '0': { text: 'No', color: 'green' },
                  '1': { text: 'Yes', color: 'blue' },
                }
              ),
            ],
          ) +
          statPanel.options.withColorMode('background'),

        httpVersionStat:
          mixinUtils.dashboards.statPanel(
            'HTTP Version',
            'short',
            queries.httpVersion,
            instant=true,
            description='HTTP protocol version used by the probe.',
          ) +
          statPanel.queryOptions.withTargets(
            g.query.prometheus.new('${datasource}', queries.httpVersion) +
            g.query.prometheus.withInstant(true) +
            g.query.prometheus.withLegendFormat('{{version}}')
          ),

        sslCertificateExpiryStat:
          mixinUtils.dashboards.statPanel(
            'SSL Certificate Expiry',
            'dtdurations',
            queries.sslCertificateExpiry,
            description='Time remaining until the SSL certificate expires. Red when below the configured threshold.',
            graphMode='none',
            steps=[
              statPanel.standardOptions.threshold.step.withValue(0.0) +
              statPanel.standardOptions.threshold.step.withColor('red'),
              statPanel.standardOptions.threshold.step.withValue($._config.alerts.sslCertExpiry.expireDaysThreshold * 24 * 3600) +
              statPanel.standardOptions.threshold.step.withColor('green'),
            ],
          ) +
          statPanel.options.withColorMode('background'),

        averageLatencyStat:
          mixinUtils.dashboards.statPanel(
            'Average Latency',
            's',
            queries.averageLatency,
            description='Mean probe duration for the selected instance.',
          ) +
          statPanel.options.reduceOptions.withCalcs(['mean']),

        averageDnsLookupStat:
          mixinUtils.dashboards.statPanel(
            'Average DNS Lookup',
            's',
            queries.averageDnsLookup,
            description='Mean DNS lookup time for the selected instance.',
          ) +
          statPanel.options.reduceOptions.withCalcs(['mean']),

        probeDurationTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Probe Duration',
            's',
            [
              { expr: queries.probeHttpDuration, legend: 'HTTP duration' },
              { expr: queries.probeTotalDuration, legend: 'Total probe duration' },
            ],
            description='HTTP phase duration and total probe duration over time for the selected instance.',
          ),

        probePhaseTimeSeries:
          mixinUtils.dashboards.timeSeriesPanel(
            'Probe Phases',
            's',
            [
              { expr: queries.probeHttpPhaseDuration, legend: '{{ phase }}' },
              { expr: queries.probeIcmpPhaseDuration, legend: '{{ phase }}' },
            ],
            description='Time spent in each probe phase (DNS, connect, TLS, processing, transfer) for the selected instance.',
            stack='percent',
          ),
      };

      // Set this to 0 for the flat layout, -9 for the collapsed layout
      local yOffset = if $._config.summaryRowCollapsed then -9 else 0;

      local summaryRowPanels =
        [
          panels.statusMapStat +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(1) +
          statPanel.gridPos.withW(24) +
          statPanel.gridPos.withH(5),
        ] +
        grid.makeGrid(
          [panels.probesCountStat, panels.probesSuccessPercentStat, panels.probesSslPercentStat, panels.probeAverageDurationStat],
          panelWidth=6,
          panelHeight=4,
          startY=6
        );

      local individualProbes =
        [
          row.new('$instance') +
          row.withRepeat('instance') +
          row.gridPos.withX(0) +
          row.gridPos.withY(yOffset + 10) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1),
          // Row 1: uptime pair
          panels.uptimeStat +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(yOffset + 11) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          panels.uptime30dStat +
          statPanel.gridPos.withX(3) +
          statPanel.gridPos.withY(yOffset + 11) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          // Row 2: probe status pair
          panels.probeSuccessStat +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(yOffset + 14) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          panels.latestResponseCodeStat +
          statPanel.gridPos.withX(3) +
          statPanel.gridPos.withY(yOffset + 14) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          // Row 3: ssl pair
          panels.sslStat +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(yOffset + 17) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          panels.sslVersionStat +
          statPanel.gridPos.withX(3) +
          statPanel.gridPos.withY(yOffset + 17) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          // Row 4: cert expiry + redirects pair
          panels.sslCertificateExpiryStat +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(yOffset + 20) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          panels.redirectsStat +
          statPanel.gridPos.withX(3) +
          statPanel.gridPos.withY(yOffset + 20) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          // Row 5: http version + latency pair
          panels.httpVersionStat +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(yOffset + 23) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          panels.averageLatencyStat +
          statPanel.gridPos.withX(3) +
          statPanel.gridPos.withY(yOffset + 23) +
          statPanel.gridPos.withW(3) +
          statPanel.gridPos.withH(3),
          // Row 6: dns lookup solo
          panels.averageDnsLookupStat +
          statPanel.gridPos.withX(0) +
          statPanel.gridPos.withY(yOffset + 26) +
          statPanel.gridPos.withW(6) +
          statPanel.gridPos.withH(3),
          panels.probeDurationTimeSeries +
          timeSeriesPanel.gridPos.withX(6) +
          timeSeriesPanel.gridPos.withY(yOffset + 11) +
          timeSeriesPanel.gridPos.withW(18) +
          timeSeriesPanel.gridPos.withH(9),
          panels.probePhaseTimeSeries +
          timeSeriesPanel.gridPos.withX(6) +
          timeSeriesPanel.gridPos.withY(yOffset + 20) +
          timeSeriesPanel.gridPos.withW(18) +
          timeSeriesPanel.gridPos.withH(9),
        ];

      local rows =
        [
          row.new('Summary') +
          row.gridPos.withX(0) +
          row.gridPos.withY(0) +
          row.gridPos.withW(24) +
          row.gridPos.withH(1) +
          row.withCollapsed($._config.summaryRowCollapsed) +
          (if $._config.summaryRowCollapsed then row.withPanels(summaryRowPanels) else {}),
        ] +
        (if $._config.summaryRowCollapsed then [] else summaryRowPanels) +
        individualProbes;

      mixinUtils.dashboards.bypassDashboardValidation +
      dashboard.new(
        'Blackbox Exporter',
      ) +
      dashboard.withDescription(
        'A dashboard that monitors the Blackbox Exporter. It is created using the [blackbox-exporter-mixin](https://github.com/adinhodovic/blackbox-exporter-mixin) for the [blackbox-exporter](https://github.com/prometheus/blackbox_exporter). %s' % mixinUtils.dashboards.dashboardDescriptionLink('blackbox-exporter-mixin', 'https://github.com/adinhodovic/blackbox-exporter-mixin')
      ) +
      dashboard.withUid($._config.dashboardIds[dashboardName]) +
      dashboard.withTags($._config.tags) +
      dashboard.withTimezone('utc') +
      dashboard.withEditable(false) +
      dashboard.time.withFrom('now-2d') +
      dashboard.time.withTo('now') +
      dashboard.withVariables(variables) +
      dashboard.withPanels(rows) +
      dashboard.withAnnotations(
        mixinUtils.dashboards.annotations($._config, defaultFilters)
      ),
  },
}

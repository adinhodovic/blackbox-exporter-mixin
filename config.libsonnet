{
  _config+:: {
    local this = self,
    // Bypasses grafana.com/dashboards validator
    bypassDashboardValidation: {
      __inputs: [],
      __requires: [],
    },

    // Selectors are inserted between {} in Prometheus queries.
    blackboxExporterSelector: 'job="blackbox-exporter"',

    // Default datasource name
    datasourceName: 'default',

    // Datasource instance filter regex
    datasourceFilterRegex: '',

    // Opt-in to multiCluster dashboards by overriding this and the clusterLabel.
    showMultiCluster: false,
    clusterLabel: 'cluster',

    grafanaUrl: 'https://grafana.com',
    dashboardUid: 'blackbox-exporter-j4da',
    dashboardUrl: '%s/d/%s/blackbox-exporter' % [this.grafanaUrl, this.dashboardUid],

    // The period in days to consider for the uptime evaluation
    uptimePeriodDays: 30,
    // Will alert if below the percentage for the configured uptime period
    uptimeThreshold: 99.9,
    // The period in minutes to consider for the probe to fail
    probeFailedInterval: '1m',
    // Severity for the probe failed alert
    blackboxProbeFailedSeverity: 'critical',
    // Severity for the low uptime alert
    blackboxProbeLowUptimeSeverity: 'info',
    // Enable SSL certificate expiration alerting
    // Might overlap with certmanager alerts
    probleSslCertificateExpireEnabled: true,
    // Cert-manager defaults to 3 week renewal time
    probeSslExpireDaysThreshold: 21,
    // Severity for the low uptime alert
    blackboxProbeSslCertificateExpireSeverity: 'warning',

    // UI config
    summaryRowCollapsed: false,

    tags: ['blackbox-exporter', 'blackbox-exporter-mixin'],
  },
}

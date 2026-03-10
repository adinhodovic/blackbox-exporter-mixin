{
  _config+:: {
    local this = self,

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

    dashboardIds: {
      'blackbox-exporter': 'blackbox-exporter-j4da',
    },
    dashboardUrls: {
      'blackbox-exporter': '%s/d/%s/blackbox-exporter' % [this.grafanaUrl, this.dashboardIds['blackbox-exporter']],
    },

    tags: ['blackbox-exporter', 'blackbox-exporter-mixin'],

    // Deprecated: use alerts.probeFailed.interval
    probeFailedInterval: '1m',
    // Deprecated: use alerts.probeFailed.severity
    blackboxProbeFailedSeverity: 'critical',

    // Deprecated: use alerts.probeLowUptime.periodDays
    uptimePeriodDays: 30,
    // Deprecated: use alerts.probeLowUptime.threshold
    uptimeThreshold: 99.9,
    // Deprecated: use alerts.probeLowUptime.severity
    blackboxProbeLowUptimeSeverity: 'info',

    // Deprecated: use alerts.sslCertExpiry.enabled
    probleSslCertificateExpireEnabled: true,
    // Deprecated: use alerts.sslCertExpiry.expireDaysThreshold
    probeSslExpireDaysThreshold: 21,
    // Deprecated: use alerts.sslCertExpiry.severity
    blackboxProbeSslCertificateExpireSeverity: 'warning',

    alerts: {
      enabled: true,

      probeFailed: {
        enabled: true,
        severity: this.blackboxProbeFailedSeverity,
        interval: this.probeFailedInterval,
      },

      probeLowUptime: {
        enabled: true,
        severity: this.blackboxProbeLowUptimeSeverity,
        periodDays: this.uptimePeriodDays,
        threshold: this.uptimeThreshold,
      },

      sslCertExpiry: {
        enabled: this.probleSslCertificateExpireEnabled,
        severity: this.blackboxProbeSslCertificateExpireSeverity,
        expireDaysThreshold: this.probeSslExpireDaysThreshold,
      },
    },

    annotation: {
      enabled: false,
      name: 'Custom Annotation',
      tags: [],
      datasource: '-- Grafana --',
      iconColor: 'blue',
      type: 'tags',
    },

    // UI config
    summaryRowCollapsed: false,
  },
}

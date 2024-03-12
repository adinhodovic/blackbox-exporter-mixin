{
  _config+:: {
    // Bypasses grafana.com/dashboards validator
    bypassDashboardValidation: {
      __inputs: [],
      __requires: [],
    },

    // Selectors are inserted between {} in Prometheus queries.
    blackboxExporterSelector: 'job="blackbox-exporter"',

    grafanaUrl: 'https://grafana.com',
    dashboardUid: 'blackbox-exporter-j4da',
    tags: ['blackbox-exporter', 'blackbox-exporter-mixin'],

    // The period in days to consider for the uptime evaluation
    uptimePeriodDays: 30,
    // Will alert if below the percentage for the configured uptime period
    uptimeThreshold: 99.9,
    // The period in minutes to consider for the probe to fail
    probeFailedInterval: '1m',

    //Cert-manager defaults to 3 week renewal time
    probeSslExpireDaysThreshold: '21',
  },
}

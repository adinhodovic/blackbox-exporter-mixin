{
  _config+:: {
    // Selectors are inserted between {} in Prometheus queries.
    blackboxExporterSelector: 'job="blackbox-exporter"',

    // The period in days to consider for the uptime evaluation 
    uptimePeriodDays: 30,

    // Will alert if below the percentage for the configured uptime period
    uptimeThreshold: 99.9,
  },
}

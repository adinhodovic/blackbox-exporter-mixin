{
  _config+:: {
    // Selectors are inserted between {} in Prometheus queries.
    blackboxExporterSelector: 'job="blackbox-exporter"',

    // Will alert if below the percentage below last 30d
    uptimeThreshhold30d: 99.9,
  },
}

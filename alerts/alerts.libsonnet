{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else '',
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'blackbox-exporter.rules',
        rules: std.prune([
          {
            alert: 'BlackboxProbeFailed',
            expr: |||
              probe_success{%(blackboxExporterSelector)s} == 0
            ||| % $._config,
            labels: {
              severity: $._config.blackboxProbeFailedSeverity,
            },
            annotations: {
              summary: 'Probe has failed for the past %(probeFailedInterval)s interval.' % $._config,
              description: 'The probe failed for the instance {{ $labels.instance }}.',
              dashboard_url: $._config.dashboardUrl + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
            'for': $._config.probeFailedInterval,
          },
          {
            alert: 'BlackboxLowUptime%(uptimePeriodDays)sd' % $._config,
            expr: |||
              avg_over_time(probe_success{%(blackboxExporterSelector)s}[%(uptimePeriodDays)sd]) * 100 < %(uptimeThreshold)s
            ||| % $._config,
            labels: {
              severity: $._config.blackboxProbeLowUptimeSeverity,
            },
            annotations: {
              summary: 'Probe uptime is lower than %(uptimeThreshold)g%% for the last %(uptimePeriodDays)s days.' % $._config,
              description: 'The probe has a lower uptime than %(uptimeThreshold)g%% the last %(uptimePeriodDays)s days for the instance {{ $labels.instance }}.' % $._config,
              dashboard_url: $._config.dashboardUrl + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.probleSslCertificateExpireEnabled then {
            alert: 'BlackboxSslCertificateWillExpireSoon',
            expr: |||
              probe_ssl_earliest_cert_expiry{%(blackboxExporterSelector)s} - time() < %(probeSslExpireDaysThreshold)s * 24 * 3600
            ||| % $._config,
            labels: {
              severity: $._config.blackboxProbeSslCertificateExpireSeverity,
            },
            annotations: {
              summary: 'SSL certificate will expire soon.',
              description: |||
                The SSL certificate of the instance {{ $labels.instance }} is expiring within %(probeSslExpireDaysThreshold)s days.
                Actual time left: {{ $value | humanizeDuration }}.
              ||| % $._config,
              dashboard_url: $._config.dashboardUrl + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
        ]),
      },
    ],
  },
}

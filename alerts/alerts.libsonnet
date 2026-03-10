{
  local clusterVariableQueryString = if $._config.showMultiCluster then '&var-%(clusterLabel)s={{ $labels.%(clusterLabel)s }}' % $._config else '',
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'blackbox-exporter.rules',
        rules: if $._config.alerts.enabled then std.prune([
          if $._config.alerts.probeFailed.enabled then {
            alert: 'BlackboxProbeFailed',
            expr: |||
              probe_success{%(blackboxExporterSelector)s} == 0
            ||| % $._config,
            'for': $._config.alerts.probeFailed.interval,
            labels: {
              severity: $._config.alerts.probeFailed.severity,
            },
            annotations: {
              summary: 'Probe has failed for the past %(interval)s interval.' % $._config.alerts.probeFailed,
              description: 'The probe failed for the instance {{ $labels.instance }}.',
              dashboard_url: $._config.dashboardUrls['blackbox-exporter'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.probeLowUptime.enabled then {
            alert: 'BlackboxLowUptime%(periodDays)sd' % $._config.alerts.probeLowUptime,
            expr: |||
              avg_over_time(probe_success{%(blackboxExporterSelector)s}[%(periodDays)sd]) * 100 < %(threshold)s
            ||| % (
              $._config
              {
                periodDays: $._config.alerts.probeLowUptime.periodDays,
                threshold: $._config.alerts.probeLowUptime.threshold,
              }
            ),
            labels: {
              severity: $._config.alerts.probeLowUptime.severity,
            },
            annotations: {
              summary: 'Probe uptime is lower than %(threshold)g%% for the last %(periodDays)s days.' % $._config.alerts.probeLowUptime,
              description: 'The probe has a lower uptime than %(threshold)g%% the last %(periodDays)s days for the instance {{ $labels.instance }}.' % $._config.alerts.probeLowUptime,
              dashboard_url: $._config.dashboardUrls['blackbox-exporter'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
          if $._config.alerts.sslCertExpiry.enabled then {
            alert: 'BlackboxSslCertificateWillExpireSoon',
            expr: |||
              probe_ssl_earliest_cert_expiry{%(blackboxExporterSelector)s} - time() < %(expireDaysThreshold)s * 24 * 3600
            ||| % (
              $._config
              {
                expireDaysThreshold: $._config.alerts.sslCertExpiry.expireDaysThreshold,
              }
            ),
            labels: {
              severity: $._config.alerts.sslCertExpiry.severity,
            },
            annotations: {
              summary: 'SSL certificate will expire soon.',
              description: |||
                The SSL certificate of the instance {{ $labels.instance }} is expiring within %(expireDaysThreshold)s days.
                Actual time left: {{ $value | humanizeDuration }}.
              ||| % $._config.alerts.sslCertExpiry,
              dashboard_url: $._config.dashboardUrls['blackbox-exporter'] + '?var-instance={{ $labels.instance }}' + clusterVariableQueryString,
            },
          },
        ]) else [],
      },
    ],
  },
}

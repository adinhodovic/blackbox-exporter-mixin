{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'blackbox-exporter.rules',
        rules: [
          {
            alert: 'BlackboxProbeFailed',
            expr: |||
              probe_success{%(blackboxExporterSelector)s} == 0
            ||| % $._config,
            labels: {
              severity: 'critical',
            },
            annotations: {
              summary: 'Probe has failed for the past minute.',
              description: 'The probe failed for the instance {{ $labels.instance }}.',
              dashboard_url: '%(grafanaUrl)s/d/%(dashboardUid)s/blackbox-exporter?orgId=1&refresh=5s' % $._config,
            },
            'for': '1m',
          },
          {
            alert: 'BlackboxLowUptime%(uptimePeriodDays)sd' % $._config,
            expr: |||
              avg_over_time(probe_success{%(blackboxExporterSelector)s}[%(uptimePeriodDays)sd]) * 100 < %(uptimeThreshold)s
            ||| % $._config,
            labels: {
              severity: 'info',
            },
            annotations: {
              summary: 'Probe uptime is lower than %(uptimeThreshold)g%% for the last %(uptimePeriodDays)s days.' % $._config,
              description: 'The probe has a lower uptime than %(uptimeThreshold)g%% the last %(uptimePeriodDays)s days for the instance {{ $labels.instance }}.' % $._config,
              dashboard_url: '%(grafanaUrl)s/d/%(dashboardUid)s/blackbox-exporter?orgId=1&refresh=5s' % $._config,
            },
          },
          {
            alert: 'BlackboxSslCertificateWillExpireSoon',
            // Cert-manager defaults to 3 week renewal time
            expr: |||
              probe_ssl_earliest_cert_expiry{%(blackboxExporterSelector)s} - time() < 21 * 24 * 3600
            ||| % $._config,
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'SSL certificate will expire soon.',
              description: 'The SSL certificate of the instance {{ $labels.instance }} is expiring within 3 weeks.',
              dashboard_url: '%(grafanaUrl)s/d/%(dashboardUid)s/blackbox-exporter?orgId=1&refresh=5s' % $._config,
            },
          },
        ],
      },
    ],
  },
}

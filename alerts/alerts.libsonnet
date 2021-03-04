{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'blackbox-exporter',
        rules: [
          {
            alert: 'BlackboxProbeFailed',
            expr: |||
              probe_success{%(blackboxExporterSelector)s} == 0
            ||| % $._config,
            labels: {
              severity: 'Critical',
            },
            annotations: {
              summary: 'Probe has failed for the past minute.',
              description: 'The probe failed for the instance {{ $labels.instance }}.',
            },
            'for': '1m',
          },
          {
            alert: 'BlackboxLowUptime30d',
            expr: |||
              avg_over_time(probe_success{%(blackboxExporterSelector)s}[30d]) * 100 < %(uptimeThreshhold30d)s
            ||| % $._config,
            labels: {
              severity: 'Warning',
            },
            annotations: {
              summary: 'Probe uptime is lower than %(uptimeThreshhold30d)g%% for the last 30 days.' % $._config,
              description: 'The probe has a lower uptime than %(uptimeThreshhold30d)g%% the last 30 days for the instance {{ $labels.instance }}.' % $._config,
            },
          },
          {
            alert: 'BlackboxSslCertificateWillExpireSoon',
            // Cert-manager defaults to 3 week renewal time
            expr: |||
              probe_ssl_earliest_cert_expiry{%(blackboxExporterSelector)s} - time() < 21 * 24 * 3600
            ||| % $._config,
            labels: {
              severity: 'Warning',
            },
            annotations: {
              summary: 'SSL certificate will expire soon.',
              description: 'The SSL certificate of the instance {{ $labels.instance }} is expiring within 3 weeks.',
            },
          },
        ],
      },
    ],
  },
}

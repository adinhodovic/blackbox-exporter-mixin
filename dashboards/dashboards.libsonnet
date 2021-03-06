local grafana = import 'github.com/grafana/grafonnet-lib/grafonnet/grafana.libsonnet';
local dashboard = grafana.dashboard;
local row = grafana.row;
local prometheus = grafana.prometheus;
local template = grafana.template;
local graphPanel = grafana.graphPanel;
local statPanel = grafana.statPanel;

{
  grafanaDashboards+:: {

    local prometheusTemplate =
      template.datasource(
        'datasource',
        'prometheus',
        'Prometheus',
        hide='',
      ),

    local targetTemplate =
      template.new(
        name='instance',
        label='Instance',
        datasource='$datasource',
        query='label_values(probe_success{%(blackboxExporterSelector)s}, instance)' % $._config,
        current='',
        hide='',
        refresh=1,
        multi=true,
        includeAll=false,
        sort=1
      ),

    local summaryRow =
      row.new(
        title='Summary'
      ),

    local individualProbesRow =
      row.new(
        title='$instance',
        repeat='instance'
      ),

    'blackbox-exporter.json':
      dashboard.new(
        'Blackbox Exporter',
        description='A dashboard that monitors the Blackbox-exporter. It is created using the blackbox-exporter-mixin for the the (blackbox-exporter)[https://github.com/prometheus/blackbox-exporter]',
        uid='blackbox-exporter',
        time_from='now-2d',
        time_to='now',
        timezone='utc'
      )
      .addPanel(summaryRow, gridPos={ h: 1, w: 24, x: 0, y: 0 })
      .addPanel(
        statPanel.new(
          'Probes',
          datasource='$datasource',
          reducerFunction='last',
        )
        .addTarget(prometheus.target('count(probe_http_version{%(blackboxExporterSelector)s})' % $._config, intervalFactor=1)),
        gridPos={ h: 4, w: 6, x: 0, y: 1 }
      )
      .addPanel(
        statPanel.new(
          'Probes Success Percentage',
          datasource='$datasource',
          unit='percentunit',
        )
        .addTarget(prometheus.target('count(probe_success{%(blackboxExporterSelector)s} == 1) / count(probe_http_version{%(blackboxExporterSelector)s})' % $._config, intervalFactor=1))
        .addThresholds([
          { color: 'red', value: 0 },
          { color: 'orange', value: 0.99 },
          { color: 'green', value: 0.999 },
        ]),
        gridPos={ h: 4, w: 6, x: 6, y: 1 }
      )
      .addPanel(
        statPanel.new(
          'Probes SSL Percentage',
          datasource='$datasource',
          reducerFunction='last',
          unit='percentunit',
        )
        .addTarget(prometheus.target('count(probe_http_ssl{%(blackboxExporterSelector)s} == 1) / count(probe_http_version{%(blackboxExporterSelector)s})' % $._config, intervalFactor=1))
        .addThreshold({ color: 'green', value: 0.999 }),
        gridPos={ h: 4, w: 6, x: 12, y: 1 }
      )
      .addPanel(
        statPanel.new(
          'Average Probe Duration',
          datasource='$datasource',
          reducerFunction='last',
          unit='s',
        )
        .addTarget(prometheus.target('avg(probe_duration_seconds{%(blackboxExporterSelector)s})' % $._config, intervalFactor=1)),
        gridPos={ h: 4, w: 6, x: 18, y: 1 }
      )
      .addPanel(individualProbesRow, gridPos={ h: 1, w: 24, x: 0, y: 5 })
      .addPanel(
        statPanel.new(
          'Uptime %',
          datasource='$datasource',
          reducerFunction='mean',
          unit='percentunit',
          colorMode='background'
        )
        .addTarget(prometheus.target('probe_success{%(blackboxExporterSelector)s, instance=~"$instance"}' % $._config, intervalFactor=1))
        .addThresholds([
          { color: 'red', value: 0 },
          { color: 'orange', value: 0.99 },
          { color: 'green', value: 0.999 },
        ]),
        gridPos={ h: 3, w: 3, x: 0, y: 5 }
      )
      .addPanel(
        statPanel.new(
          'Latest Response Code',
          datasource='$datasource',
          reducerFunction='last',
        )
        .addTarget(prometheus.target('probe_http_status_code{%(blackboxExporterSelector)s, instance=~"$instance"}' % $._config, intervalFactor=1, instant=true))
        .addThresholds([
          { color: 'green', value: 0 },
          { color: 'red', value: 400 },
        ]),
        gridPos={ h: 3, w: 3, x: 3, y: 5 }
      )
      .addPanel(
        statPanel.new(
          'SSL',
          datasource='$datasource',
          reducerFunction='last',
        )
        .addTarget(prometheus.target('probe_http_ssl{%(blackboxExporterSelector)s, instance=~"$instance"}' % $._config, intervalFactor=1, instant=true))
        .addThresholds([
          { color: 'red', value: 0 },
          { color: 'green', value: 1 },
        ])
        .addMapping(
          {
            value: '0',
            text: 'No',
            type: 1,
          }
        )
        .addMapping(
          {
            value: '1',
            text: 'Yes',
            type: 1,
          }
        ),
        gridPos={ h: 3, w: 3, x: 0, y: 8 }
      )
      .addPanel(
        statPanel.new(
          'SSL Version',
          datasource='$datasource',
          reducerFunction='last',
        )
        .addTarget(
          prometheus.target(
            'probe_tls_version_info{%(blackboxExporterSelector)s, instance=~"$instance"}' % $._config,
            intervalFactor=1,
            instant=true,
            legendFormat='{{version}}',
          )
        ) + { options+: { textMode: 'name' } },
        gridPos={ h: 3, w: 3, x: 3, y: 8 }
      )
      .addPanel(
        statPanel.new(
          'Redirects',
          datasource='$datasource',
          reducerFunction='last',
        )
        .addTarget(prometheus.target('probe_http_redirects{%(blackboxExporterSelector)s, instance=~"$instance"}' % $._config, intervalFactor=1, instant=true))
        .addMapping(
          {
            value: '0',
            text: 'No',
            type: 1,
          }
        )
        .addMapping(
          {
            value: '1',
            text: 'Yes',
            type: 1,
          }
        ),
        gridPos={ h: 3, w: 3, x: 0, y: 11 }
      )
      .addPanel(
        statPanel.new(
          'HTTP Version',
          datasource='$datasource',
          reducerFunction='last',
        )
        .addTarget(
          prometheus.target(
            'probe_http_version{%(blackboxExporterSelector)s, instance=~"$instance"}' % $._config,
            intervalFactor=1,
            instant=true,
          )
        ),
        gridPos={ h: 3, w: 3, x: 3, y: 11 }
      )
      .addPanel(
        statPanel.new(
          'SSL Certificate Expiry',
          datasource='$datasource',
          reducerFunction='last',
          unit='s',
          decimals=1,
          colorMode='background',
        )
        .addTarget(
          prometheus.target(
            'probe_ssl_earliest_cert_expiry{%(blackboxExporterSelector)s, instance=~"$instance"} - time()' % $._config,
            intervalFactor=1,
            instant=true,
          )
        )
        .addThresholds([
          { color: 'red', value: 0 },
          { color: 'green', value: 1814400 },
        ]),
        gridPos={ h: 3, w: 6, x: 0, y: 14 }
      )
      .addPanel(
        statPanel.new(
          'Average Latency',
          datasource='$datasource',
          unit='s',
        )
        .addTarget(prometheus.target('probe_duration_seconds{%(blackboxExporterSelector)s, instance=~"$instance"}' % $._config, intervalFactor=1)),
        gridPos={ h: 4, w: 3, x: 0, y: 17 }
      )
      .addPanel(
        statPanel.new(
          'Average DNS Lookup',
          datasource='$datasource',
          unit='s',
        )
        .addTarget(prometheus.target('probe_dns_lookup_time_seconds{%(blackboxExporterSelector)s, instance=~"$instance"}' % $._config, intervalFactor=1)),
        gridPos={ h: 4, w: 3, x: 3, y: 17 }
      )
      .addPanel(
        graphPanel.new(
          'HTTP duration',
          datasource='$datasource',
          legend_show=true,
          legend_values=true,
          legend_alignAsTable=true,
          legend_avg=true,
          legend_max=true,
          format='s',
        )
        .addTarget(
          prometheus.target(
            'sum(probe_http_duration_seconds{%(blackboxExporterSelector)s, instance=~"$instance"}) by (instance)' % $._config,
            legendFormat='{{instance}}',
          )
        ),
        gridPos={ h: 8, w: 18, x: 6, y: 5 },
      )
      .addPanel(
        graphPanel.new(
          'HTTP phase percentage',
          datasource='$datasource',
          max=100,
          legend_show=true,
          legend_values=true,
          legend_alignAsTable=true,
          legend_rightSide=true,
          legend_avg=true,
          legend_max=true,
          fill=10,
          stack=true,
          percentage=true,
          format='s',
        )
        .addTarget(
          prometheus.target(
            'sum(probe_http_duration_seconds{%(blackboxExporterSelector)s, instance=~"$instance"}) by (phase)' % $._config,
            legendFormat='{{phase}}',
          )
        ),
        gridPos={ h: 8, w: 18, x: 6, y: 13 },
      )
      + { templating+: { list+: [prometheusTemplate, targetTemplate] } },
  },
}

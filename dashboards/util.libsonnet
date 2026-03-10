local g = import 'github.com/grafana/grafonnet/gen/grafonnet-latest/main.libsonnet';

local dashboard = g.dashboard;

local variable = dashboard.variable;
local datasource = variable.datasource;
local query = variable.query;

{
  filters(config):: {
    local this = self,
    cluster: '%(clusterLabel)s="$cluster"' % config,
    job: 'job=~"$job"',
    instanceFilter: 'instance=~"$instance"',

    base: |||
      %(cluster)s,
      %(job)s
    ||| % this,

    default: |||
      %(base)s
    ||| % this,

    instance: |||
      %(default)s,
      %(instanceFilter)s
    ||| % this,
  },

  variables(config):: {
    local this = self,
    local defaultFilters = $.filters(config),

    datasource:
      datasource.new(
        'datasource',
        'prometheus',
      ) +
      datasource.withRegex(config.datasourceFilterRegex) +
      datasource.generalOptions.withLabel('Data source') +
      {
        current: {
          selected: true,
          text: config.datasourceName,
          value: config.datasourceName,
        },
      },

    cluster:
      query.new(
        config.clusterLabel,
        'label_values(probe_success{}, %(clusterLabel)s)' % config,
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort() +
      query.generalOptions.withLabel('Cluster') +
      query.refresh.onLoad() +
      query.refresh.onTime() +
      (
        if config.showMultiCluster
        then query.generalOptions.showOnDashboard.withLabelAndValue()
        else query.generalOptions.showOnDashboard.withNothing()
      ),

    job:
      query.new(
        'job',
        'label_values(probe_success{%(cluster)s}, job)' % defaultFilters,
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort(1) +
      query.generalOptions.withLabel('Job') +
      query.selectionOptions.withMulti(true) +
      query.selectionOptions.withIncludeAll(true) +
      query.refresh.onLoad() +
      query.refresh.onTime(),

    instance:
      query.new(
        'instance',
        'label_values(probe_success{%(cluster)s, %(job)s}, instance)' % defaultFilters,
      ) +
      query.withDatasourceFromVariable(this.datasource) +
      query.withSort(1) +
      query.generalOptions.withLabel('Instance') +
      query.selectionOptions.withMulti(false) +
      query.selectionOptions.withIncludeAll(false) +
      query.refresh.onLoad() +
      query.refresh.onTime(),
  },
}

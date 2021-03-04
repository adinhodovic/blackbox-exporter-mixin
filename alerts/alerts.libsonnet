{
  prometheusAlerts+:: {
    groups+: [
      {
        name: 'kubernetes-resources',
        rules: [
          {
            alert: 'KubeNodeNotReady',
            expr: 'kube_node_status_condition{condition="Ready",status="true"} == 0',
            labels: {
              severity: 'warning',
            },
            annotations: {
              summary: 'Node is not ready.',
            },
            'for': '1h',
          },
        ],
      },
    ],
  },
}

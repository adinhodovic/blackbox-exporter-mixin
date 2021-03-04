{
  prometheusRules+:: {
    groups+: [
      {
        name: 'example.rules',
        rules: [
          {
            record: 'node:node_memory_utilisation:ratio',
            expr: |||
              (node:node_memory_bytes_total:sum - node:node_memory_bytes_available:sum)
              /
              scalar(sum(node:node_memory_bytes_total:sum))
            |||,
          },
        ],
      },
    ],
  },
}

rule {
  match {
    name = "BlackboxProbeFailed"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "BlackboxLowUptime30d"
  }
  disable = ["promql/regexp"]
}

rule {
  match {
    name = "BlackboxSslCertificateWillExpireSoon"
  }
  disable = ["promql/regexp"]
}

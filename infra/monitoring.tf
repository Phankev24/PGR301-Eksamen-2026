resource "aws_cloudwatch_metric_alarm" "bedrock_latency_alarm" {
  alarm_name          = "wishifai-bedrock-high-latency-k${var.candidate_no}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "bedrock.execution.time.max"
  namespace           = "wishifai-${var.candidate_no}"
  period              = 300
  statistic           = "Maximum"
  threshold           = 12000
  alarm_description   = "Varsler dersom AWS Bedrock (LLM) bruker mer enn 12 sekunder paa aa generere gaveforslag."
  datapoints_to_alarm = 1

  treat_missing_data = "notBreaching"
}


resource "aws_cloudwatch_dashboard" "wishifai_dashboard" {
  dashboard_name = "wishifai-dashboard-${var.candidate_no}"

  dashboard_body = jsonencode({
    widgets = [
      # BUSINESS-METRIKKER
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" = "SUM(SEARCH('Namespace=\"wishifai-${var.candidate_no}\" MetricName=\"wishifai.images.analyzed.count\"', 'Sum', 60))", "id" = "e1", "label" = "Totalt antall bilder analysert" }]
          ]
          view                 = "singleValue"
          region               = var.aws_region
          title                = "Business: Totalt antall analyserte bilder"
          setPeriodToTimeRange = true
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" = "SUM(SEARCH('Namespace=\"wishifai-${var.candidate_no}\" MetricName=\"wishifai.images.analyzed.count\"', 'Sum', 60))", "id" = "e2", "label" = "Bilder analysert" }]
          ]
          view    = "bar"
          stacked = false
          region  = var.aws_region
          title   = "Business: Analyserte bilder over tid"
        }
      },

      # APPLIKASJONSMETRIKKER (LATENS & JVM)
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["wishifai-${var.candidate_no}", "bedrock.execution.time.max", { "stat" = "Maximum", "label" = "Bedrock Max Latens (ms)", "period" = 60 }],
            ["wishifai-${var.candidate_no}", "rekognition.execution.time.max", { "stat" = "Maximum", "label" = "Rekognition Max Latens (ms)", "period" = 60 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Applikasjon: AI-tjenester Latens (ms)"
          annotations = {
            horizontal = [
              {
                value = 12000
                label = "Alarm Terskel (12s)"
                color = "#d62728"
              }
            ]
          }
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" = "SUM(SEARCH('Namespace=\"wishifai-${var.candidate_no}\" MetricName=\"jvm.memory.used\" area=\"heap\"', 'Average', 60))", "id" = "e3", "label" = "JVM heap brukt (bytes)" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Applikasjon: JVM Minnebruk"
        }
      },

      # INFRASTRUKTUR-METRIKKER (ECS EXPRESS)
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 24
        height = 6
        properties = {
          metrics = [
            [{ "expression" = "SEARCH('Namespace=\"AWS/ECS\" MetricName=\"CPUUtilization\" ServiceName=\"wishifai-service-k${var.candidate_no}\"', 'Average', 300)", "id" = "e4", "label" = "CPU Utilization" }],
            [{ "expression" = "SEARCH('Namespace=\"AWS/ECS\" MetricName=\"MemoryUtilization\" ServiceName=\"wishifai-service-k${var.candidate_no}\"', 'Average', 300)", "id" = "e5", "label" = "Memory Utilization" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Infrastruktur: ECS Express CPU & Minne utnyttelse (%)"
        }
      }
    ]
  })
}
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

  dimensions = {
    exception = "None"
  }
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
            ["wishifai-${var.candidate_no}", "wishifai.images.analyzed.count", { "stat" = "Sum", "label" = "Totalt antall bilder analysert" }]
          ]
          view   = "singleValue"
          region = var.aws_region
          title  = "Business: Totalt antall analyserte bilder"
          period = 300
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
            ["wishifai-${var.candidate_no}", "wishifai.images.analyzed.count", { "stat" = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Business: Analyserte bilder over tid"
        }
      },

      # APPLIKASJONSMETRIKKER (LATENS)
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["wishifai-${var.candidate_no}", "bedrock.execution.time.max", "exception", "None", { "stat" = "Maximum", "label" = "Bedrock Max Latens (ms)" }],
            ["wishifai-${var.candidate_no}", "rekognition.execution.time.max", "exception", "None", { "stat" = "Maximum", "label" = "Rekognition Max Latens (ms)" }]
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
            [{ "expression" = "SEARCH('{wishifai-${var.candidate_no},area,id} MetricName=\"jvm.memory.used\"', 'Average', 60)", "id" = "e1", "label" = "JVM Memory Used" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Applikasjon: JVM Minnebruk"
        }
      },

      #INFRASTRUKTUR-METRIKKER (ECS EXPRESS)
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" = "SEARCH('{AWS/ECS,ClusterName,ServiceName} MetricName=\"CPUUtilization\" ServiceName=\"wishifai-service-k${var.candidate_no}\"', 'Average', 60)", "id" = "e2", "label" = "CPU Utilization" }],
            [{ "expression" = "SEARCH('{AWS/ECS,ClusterName,ServiceName} MetricName=\"MemoryUtilization\" ServiceName=\"wishifai-service-k${var.candidate_no}\"', 'Average', 60)", "id" = "e3", "label" = "Memory Utilization" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Infrastruktur: ECS Express CPU & Minne utnyttelse (%)"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          metrics = [
            [{ "expression" = "SEARCH('{AWS/ECS,ClusterName,ServiceName} MetricName=\"RunningTaskCount\" ServiceName=\"wishifai-service-k${var.candidate_no}\"', 'Average', 60)", "id" = "e4", "label" = "Running Task Count" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Infrastruktur: ECS Express Running Task Count"
        }
      }
    ]
  })
}
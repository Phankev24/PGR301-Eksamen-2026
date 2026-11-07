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
            ["wishifai-${var.candidate_no}", "wishifai.images.analyzed", { "stat" = "Sum", "period" = 60, "label" = "Totalt antall bilder analysert" }]
          ]
          view   = "singleValue"
          region = var.aws_region
          title  = "Business: Totalt antall analyserte bilder"
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
            ["wishifai-${var.candidate_no}", "wishifai.images.analyzed", { "stat" = "Sum", "period" = 60 }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Business: Analyserte bilder over tid"
        }
      },

      # ACTUATOR / MICROMETER METRIKKER
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["wishifai-${var.candidate_no}", "bedrock.execution.time.max", { "stat" = "Maximum", "period" = 60, "label" = "Bedrock Max Latens (ms)" }],
            ["wishifai-${var.candidate_no}", "rekognition.execution.time.sum", { "stat" = "Sum", "period" = 60, "label" = "Rekognition Sum Latens (ms)" }]
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
            ["wishifai-${var.candidate_no}", "jvm.memory.committed.value", "area", "heap", "id", "G1 Survivor Space", { "stat" = "Average", "period" = 60, "label" = "JVM Memory Committed" }]
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
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", aws_ecs_express_gateway_service.wishifai.service_name, { "stat" = "Average", "period" = 60 }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", aws_ecs_express_gateway_service.wishifai.service_name, { "stat" = "Average", "period" = 60 }]
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
            ["AWS/ECS", "RunningTaskCount", "ServiceName", aws_ecs_express_gateway_service.wishifai.service_name, { "stat" = "Average", "period" = 60 }]
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
job "monitoring" {
  datacenters   = [ "dc0" ]
  type = "service"

  group "victoriametrics" {
    count = 1

    constraint {
      attribute         = "${meta.monitoring}"
      value             = true
    }

    restart {
      interval          = "3m"
      attempts          = 5
      delay             = "5s"
      mode              = "fail"
    }

    reschedule {
      attempts          = 0
      interval          = "72h"
      delay             = "30s"
      delay_function    = "exponential"
      max_delay         = "10m"
      unlimited         = true
    }

    update {
      max_parallel      = 1
      min_healthy_time  = "60s"
      healthy_deadline  = "3m"
      progress_deadline = "10m"
      auto_revert       = false
      canary            = 0
    }

    migrate {
      max_parallel      = 1
      health_check      = "checks"
      min_healthy_time  = "60s"
      healthy_deadline  = "3m"
    }

    volume "victoriametrics-data" {
      type = "host"
      read_only = false
      source = "victoriametrics-data"
    }

    network {

      port "http" {
        static    = 8428
        to        = 8428
      }

      port "influx" {
        static    = 8089
        to        = 8089
      }

      port "opentsdb" {
        static    = 4242
        to        = 4242
      }

      port "graphite" {
        static    = 2003
        to        = 2003
      }
    }

    task "victoriametrics" {
      driver = "docker"

      template {
        data          = <<-EOH
        {{ key "config/monitoring/victoriametrics/prometheus.yml" }}
      EOH

        destination   = "local/config/prometheus.yml"
        change_mode   = "restart"
      }

      env {
        TZ    = "Europe/Moscow"
      }

      config {
        image         = "docker.io/victoriametrics/victoria-metrics:v1.64.0"
        force_pull    = false
        hostname      = "victoriametrics"

        ports = [
          "http",
          "influx",
          "opentsdb",
          "graphite"
        ]

        dns_servers = [
          "172.17.0.1",
          "8.8.4.4"
        ]

        args = [
          "--storageDataPath=/storage",
          "--httpListenAddr=:8428",
          "--graphiteListenAddr=:2003",
          "--opentsdbListenAddr=:4242",
          "--influxListenAddr=:8089",
          "--promscrape.config=/local/config/prometheus.yml",
          "--promscrape.configCheckInterval=5s",
          "--dedup.minScrapeInterval=10s",
          "--retentionPeriod=3"
        ]

        mount {
          type = "volume"
          target = "/storage"
          source = "victoriametrics-data"
          readonly = false
        }
      }

      resources {
        cpu       = 301
        memory    = 500
      }

      service {
        name    = "victoriametrics"
        port    = "http"

        tags = [
          "proxy-https",
          "traefik.enable=true",
          "traefik.http.routers.victoriametrics.tls=true",
          "traefik.http.routers.victoriametrics.rule=Host(`victoriametrics.rwxrwxrwx.dev`)",
          "traefik.http.services.victoriametrics.loadbalancer.server.port=${NOMAD_HOST_PORT_http}",
          "traefik.http.routers.victoriametrics.entrypoints=https",
          "traefik.http.routers.victoriametrics.middlewares=auth@file",
          "traefik.tags=host_${attr.unique.hostname}",
          "traefik.tags=node_${node.unique.name}"
        ]

        check {
          type = "http"
          path = "/health"
          interval = "5s"
          timeout = "2s"

          check_restart {
            limit   = 5
            grace   = "60s"
          }
        }
      }
    }
  }


  group "grafana" {
    count   = 1

    // constraint {
    //   attribute         = "${meta.grafana}"
    //   value             = true
    // }

    restart {
      interval          = "3m"
      attempts          = 5
      delay             = "15s"
      mode              = "fail"
    }

    reschedule {
      attempts          = 0
      interval          = "24h"
      delay             = "30s"
      delay_function    = "exponential"
      max_delay         = "10m"
      unlimited         = true
    }

    update {
      max_parallel      = 1
      min_healthy_time  = "60s"
      healthy_deadline  = "3m"
      progress_deadline = "10m"
      auto_revert       = false
      canary            = 0
    }

    migrate {
      max_parallel      = 1
      health_check      = "checks"
      min_healthy_time  = "10s"
      healthy_deadline  = "5m"
    }

    network {
      // mode    = "host"

      port "http" {
        static          = 3071
        to              = 3000
        // host_network    = "dev"
      }
    }

    task "grafana" {
      driver    = "docker"

      // template {
      //   data          = <<-EOH
      //   {{ key "config/monitoring/grafana/provisioning/dashboard.yml" }}
      // EOH

      //   destination   = "local/provisioning/dashboards/dashboard.yml"
      //   change_mode   = "signal"
      //   change_signal = "SIGHUP"
      // }

      // template {
      //   data          = <<-EOH
      //   {{ key "config/monitoring/grafana/provisioning/datasource.yml" }}
      // EOH

      //   destination   = "local/provisioning/datasources/datasource.yml"
      //   change_mode   = "signal"
      //   change_signal = "SIGHUP"
      // }

      // template {
      //   data          = <<-EOH
      //   {{ key "config/monitoring/grafana/provisioning/plugins.yml" }}
      // EOH

      //   destination   = "local/provisioning/plugins/plugins.yml"
      //   change_mode   = "signal"
      //   change_signal = "SIGHUP"
      // }

      // template {
      //   data          = <<-EOH
      //   {{ key "config/monitoring/grafana/config/main-dashboard.json" }}
      // EOH

      //   destination   = "local/config/main-dashboard.json"
      //   change_mode   = "signal"
      //   change_signal = "SIGHUP"
      // }

      // template {
      //   data          = <<-EOH
      //   {{ key "config/monitoring/grafana/provisioning/notifiers.yml" }}
      // EOH

      //   destination   = "local/provisioning/notifiers/notifiers.yml"
      //   change_mode   = "signal"
      //   change_signal = "SIGHUP"
      // }

      template {
        data          = <<-EOH
        {{ key "config/monitoring/grafana/config/grafana.ini" }}
      EOH

        destination   = "local/config/grafana.ini"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      env {
        TZ                    = "Europe/Moscow"
        GF_INSTALL_PLUGINS    = "grafana-piechart-panel,grafana-clock-panel,grafana-simple-json-datasource,natel-discrete-panel,fifemon-graphql-datasource,simpod-json-datasource"
        GF_PATHS_CONFIG       = "/local/config/grafana.ini"
        GF_PATHS_DATA         = "/var/lib/grafana"
        GF_PATHS_HOME         = "/usr/share/grafana"
        GF_PATHS_LOGS         = "/var/log/grafana"
        GF_PATHS_PLUGINS      = "/var/lib/grafana/plugins"
        GF_PATHS_PROVISIONING = "/local/provisioning"
      }

      config {
        image         = "cr.yandex/crpgf4au6prfo3nhoduj/infra/grafana:latest"
        force_pull    = false
        hostname      = "grafana"

        ports = [
          "http"
        ]

        dns_servers = [
          "172.17.0.1",
          "8.8.4.4"
        ]

        volumes = [
          "/mnt/data/grafana:/var/lib/grafana"
        ]
      }

      resources {
        cpu       = 200
        memory    = 500
      }

      service {
        name    = "grafana"
        port    = "http"

        tags = [
          "proxy-https",
          "traefik.enable=true",
          "traefik.http.routers.grafana.tls=true",
          "traefik.http.routers.grafana.rule=Host(`grafana.rwxrwxrwx.dev`)",
          "traefik.http.routers.grafana.entrypoints=https",
          "traefik.http.routers.grafana.service=grafana",
          "traefik.http.services.grafana.loadbalancer.server.port=${NOMAD_HOST_PORT_http}",
          "traefik.http.routers.grafana.priority=5",
          "traefik.http.routers.grafana-api.tls=true",
          "traefik.http.routers.grafana-api.rule=Host(`grafana.rwxrwxrwx.dev`) && (PathPrefix(`/api/datasources/proxy`))",
          "traefik.http.routers.grafana-api.entrypoints=https",
          "traefik.http.routers.grafana-api.middlewares=max-size-2mb@file",
          "traefik.http.routers.grafana-api.service=grafana-api",
          "traefik.http.services.grafana-api.loadbalancer.server.port=${NOMAD_HOST_PORT_http}",
          "traefik.http.routers.grafana-api.priority=15",
          "traefik.tags=host_${attr.unique.hostname}",
          "traefik.tags=node_${node.unique.name}"
        ]

        check {
          type        = "http"
          path        = "/api/health"
          interval    = "5s"
          timeout     = "2s"

          check_restart {
            limit   = 5
            grace   = "60s"
          }
        }
      }
    }
  }
}

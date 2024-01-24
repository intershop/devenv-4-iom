# Metrics
## Overview

IOM 5 and newer versions of IOM are providing metrics data by the _micrometer_ sub-system of _Wildfly_. This sub-system pushes metrics data to an endpoint, that has to be conform to [OpenTelemetry](https://opentelemetry.io) specification. 

## Configuration of Endpoint

The endpoint to which the metrics data are sent, is defined by the configuration property `OTEL_COLLECTOR`. The hostname, that this endpoint is using, must be reachable by the IOM server, that is operated by _devenv-4-iom_.

Using _localhost_ for hostname of this endpoint is always a wrong choise. _localhost_, as seen by IOM, is always resolved to the _pod_ that is running IOM.

If the service, that provides the endpoint, is running on your local computer, you have to determine its hostname. The easiest way to do this, is by running the `hostname` command. Please note, that the hostname may change if a VPN (Virtual Private Network) connection is established or released. In this case, the configuration of the endpoint (`OTEL_COLLECTOR`) has to be updated and IOM has to be restarted!

Example:

    OTEL_COLLECTOR="http://MyMacPro:4318/v1/metrics"

## Simple Method to access Metrics Data

If you are depeloping custom metrics or you are interested in preconfigured Wildfly metrics, you need to access the metrics sent by _micrometer_ sub-system of _Wildfly_. To do so, it's not necessary to setup a complete monitoring system. The easiest way to get access to the metrics, is to setup an _OpenTelemetry Collector_ and to configure it in a way, that metrics are written to a file.

There are many ways, how an _OpenTelemetry Collector_ can be installed. They are all described by [OpenTelemetry Documentation](https://opentelemetry.io/docs/collector/installation/). Here only one method will be shown, that is suitable for an **Linux** system running on **AMD64**. You are open to try out a different method, that better fits your needs.

Version numbers, download-URLs, etc. are directly copied from [OpenTelemetry Collector Documentation](https://opentelemetry.io/docs/collector/installation/). It's strongly recommended, that you are copying the code snippets from this documentation too. The commands shown in this chapter are intended only to show you the main steps of setup and configuration process.

### Download _OpenTelemetry Collector_

    curl --proto '=https' --tlsv1.2 -fOL https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.92.0/otelcol_0.92.0_linux_amd64.tar.gz
    tar -xvf otelcol_0.92.0_linux_amd64.tar.gz

### Configure _OpenTelemetry Collector_

Goal of the configuration is to configure the collector to receive metrics via http-protocol and to write them to a file. A full description of all configuration options is provided by [OpenTelemetry Collector Documentation](https://opentelemetry.io/docs/collector/configuration/).

Create a file `config.yaml` within the same directory, where the content of the _OpenTelemetry Collector_ package was expanded to, with follwoing content:

    receivers:
      otlp:
        protocols:
          grpc:
          http:
    processors:
      batch:
    exporters:
      file:
        path: ./out.json
    service:
      telemetry:
      pipelines:
       metrics:
          receivers: [otlp]
          processors: [batch]
          exporters: [file]

When using this configuration, the received metrics are written to the file `out.json`.

### Configure _devenv-4-iom_

Use this hostname to configure the `OTEL_COLLECTOR` variable of _devenv-4-iom_. Port and path of the URL of the endpoint are defined by the _OpenTelemetry Collector_.
Please note, that the hostname is taken from the output of the `hostname` command.

    # append the configuration to the user-specific configuration of devenv-4-iom:
    echo OTEL_COLLECTOR=\"http://$(hostname):4318/v1/metrics\" >> $PATH_TO_MY_IOM_PROJECT/devenv.user.properties

To apply the changes, IOM has to be restarted. First change to the directory holding your IOM project and run there the following commands.

    devenv-cli.sh delete iom
    devenv-cli.sh create iom

### Run OpenTelemetry Collector and access the received Metrics

The _OpenTelemetry Collector_ package contains the file `otelcol`. Change to the directory where the _OpenTelemetry Collector_ package was expanded and execute this command along with the previously created configuration:

    ./otelcol --config config.yaml

Use a second terminal to watch the content of the file `out.json`.

    tail -f out.json

---
[< Log Messages](06_log_messages.md) | [^ Index](../README.md) | [Troubleshooting >](08_troubleshooting.md)

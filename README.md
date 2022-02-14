# Overview

_devenv-4-iom_ provides all the tools that are required to configure and run an IOM development instance in your local _Kubernetes_ cluster.

The following chapters are providing a detailed view into different aspects of installation and usage of _devenv-4-iom_.
- [Installation](doc/00_installation.md)
- [First steps](doc/01_first_steps.md)
- [Configuration](doc/02_configuration.md)
- [Operation](doc/03_operations.md)
- [Development process](doc/04_development_process.md)
- [Log messages](doc/05_log_messages.md)
- [Troubleshooting](doc/06_troubleshooting.md)

If _devenv-4-iom_ is already installed and you are looking for a short overview about features, please use the integrated help. To do so, call `devenv-cli.sh` with parameter `-h` or `--help`.

    devenv-cli.sh -h
    
# Release information 2.0.0

## Compatibility

At the time of release of _devenv-4-iom_, it is compatible with the latest version of IOM. As long there is no new release of _devenv-4-iom_, it is ensured, that new releases of IOM are compatible with _devenv-4-iom_. If a new version of IOM requires an update of _devenev-4-iom_, the release notes of IOM will contain an according statement.

At the time of writing, _devenv-4-iom 2.0.0_ is compatible with all IOM versions between 3.0 and 4.0.

## New features

### Kubernetes Context is part of configuration now <!-- 73923 -->

Before _devenv-4-iom 2.0.0_, always the current default _Kubernetes_ context was used. If one was working with different _Kubernetes_ clusters, it might have happened, that operations were executed accidently on the wrong cluster. To avoid such cases, the new configuration variable `KUBERNETES_CONTEXT` was added, having the default value _docker-desktop_.

From now on _devenv-4-iom_ uses the configured _Kubernetes_ context in any case.

### Usage of SQL-hashes is configurable now <!-- 73739 -->

IOM uses hash-values of directories containing SQL-files to determine whether a database-initialization step was already performed of not. The hash-values are determined, when creating the images (IOM-product and -project image). _devenv-4-iom_ is able to overrule database-initialization settings made in the images, by defining `CUSTOM_DBMIGRATE_DIR`, `CUSTOM_SQLCONF_DIR`, `CUSTOM_JSONCONF_DIR`. Since these configurations are not affecting the hash-values stored wihin the image, the usage of SQL-hashes was switched off prior version 4 of _devenv-4-iom_, without any ability to enable it.

But there are some development use-cases in context of IOM product development, that makes it necessary to enable usage of SQL-hashes inside _devenv-4-iom_. For this reason, the new configuration variable `OMS_DB_SQLHASH` was added, which defaults to `false`.

### <!-- 70390 -->

## Migration notes

### Documentation is part of source repository now <!-- 71048 --->

Documentation of _devenv-4-iom_ prior version 2 was separately published from the tool itself in [_Intershop Knowledgebase_](https://support.intershop.com/kb/29Z730). Also the relaese information was provided by the [_Intershop Knowledgebase_](https://support.intershop.com/kb/283D59).

Documentation and release information are now part of the source repository. Current documentation will not be copied into [_Intershop Knowledgebase_](https://support.intershop.com/kb/index.php).

## Fixed Bugs


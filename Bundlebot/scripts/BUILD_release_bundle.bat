@echo off
:: FDS 6.7. and smokeview 6.7.16
::run_bundlebot -c -R release -F 5064c500c -X FDS6.7.6 -S 485e0cd19 -Y SMV6.7.16

:: FDS 6.7.7 and smokeview 6.7.18
::run_bundlebot -c -R release -F fe0d4ef38 -X FDS6.7.7 -S dce043cd7 -Y SMV6.7.18

:: FDS 6.7.9 and smokeview 6.7.21
set use_only_tags=1
run_bundlebot -c -R release -X FDS6.7.9 -Y SMV6.7.21


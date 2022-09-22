# SQQuerySuspend Threshold Control

This plugin allows control of the inbuilt VScript script execution timeout threshold. It adds the `sm_vscript_timeout_threshold` convar which defaults to 2.0s, the execution timeout can be disabled altogether with a value of 0.0 (not recommended). A SM error is also logged every time VScript execution times out.

## Why?

At its default value script execution times out after only [0.03s](https://github.com/perilouswithadollarsign/cstrike15_src/blob/master/vscript/languages/squirrel/vsquirrel/vsquirrel.cpp#L1930), and can be easily triggered in lag spikes or high intensity moments. This results in map breakage from vscripts not getting executed that were supposed to.

## Requirements

- SourceMod 1.12
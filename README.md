# Automated LiveSplit Stats Sheet project

## Overview

This project is a type of [ETL](https://en.wikipedia.org/wiki/Extract,_transform,_load) related to speedrunning and more specifically to LiveSplit files (`.lss`).

The idea is:

- `.lss` files store historical data about all the runs the runner has ever done: for each individual split, the file stores all the times ever obtained in that split, the best time ever of that split (gold split), etc.
- These files store this data in XML format, which can be parsed by many different tools.
- Using SQL to parse these files, we can create tables on a local SQL database where we store the parsed data of these files in a structured manner, and from these tables we can create many other tables to obtain useful analytics about how the runner is performing and has performed in these splits.

## How it works

## How to set it up

## How to run it

## How to add a new runner

---

## Possible improvements

# LiveSplit Analytics Database

## Table of contents

- [LiveSplit Analytics Database](#livesplit-analytics-database)
  - [Table of contents](#table-of-contents)
  - [Overview](#overview)
    - [Short description](#short-description)
    - [Motivation](#motivation)
    - [Tech stack used](#tech-stack-used)
  - [Structure of a LiveSplit file](#structure-of-a-livesplit-file)
    - [General info](#general-info)
    - [RealTime vs GameTime](#realtime-vs-gametime)
    - [AttemptHistory](#attempthistory)
    - [Segments](#segments)
  - [Project documentation](#project-documentation)
    - [Directory structure](#directory-structure)
    - [Functionalities](#functionalities)
    - [Execution flow](#execution-flow)
  - [How to use](#how-to-use)
    - [Prerequisites](#prerequisites)
    - [Initial setup](#initial-setup)
    - [Basic configuration](#basic-configuration)
    - [Extra optional configuration](#extra-optional-configuration)
    - [How to run](#how-to-run)
  - [Possible improvements](#possible-improvements)

---

## Overview

### Short description

This project is a type of [ETL](https://en.wikipedia.org/wiki/Extract,_transform,_load) related to speedrunning and more specifically to LiveSplit files (`.lss`).

In order to properly understand the structure and purpose of this project, some basic knowledge of what speedrunning and LiveSplit are is highly recommended.

### Motivation

- LiveSplit files store a ton of very useful data that, when parsed and analyzed properly, can provide interesting insights about a runner's performance over time.
- These insights can be used by runners to improve and to compare their performance with other runners.
- LiveSplit itself does not provide any built-in analytics features, so this project aims to fill that gap by extracting relevant data from LiveSplit files and storing it in an SQL database for further analysis.

### Tech stack used

- **Python 3.13**.
- **uv** for dependency management.
- **ruff** for linting.
- **SQL** with **PostgreSQL** 17.

---

## Structure of a LiveSplit file

### General info

- LiveSplit files are identified by the `.lss` file extension and they use the [`XML`](https://developer.mozilla.org/en-US/docs/Web/XML/Guides/XML_introduction) markup language internally.
- Each LS file contains both metadata about the game, category, platform, autosplitter settings, etc, and also **historical data**, which is the data this project focuses on.
- This historical data is divided into two main tags: `<AttemptHistory>` and `<Segments>`.

### RealTime vs GameTime

- LiveSplit supports two separate timing methods: **Real Time** and **Game Time**.
- **Real Time** is the actual time that passes from the moment the runner starts the run until the moment they finish it. This is the lesser used timing method as it's usually pay to win.
- **Game Time** is the time that the game itself tracks. This timing method is typically used in games that have hardware-dependent loading times, as the loading times are (usually) not counted in Game Time. Not all games support Game Time, and not all runners use it.
- With the above in mind, each time value in the LiveSplit file can have either just Real Time or both Real Time and Game Time, depending on whether the game supports it and whether the runner has enabled it.

### AttemptHistory

- `<AttemptHistory>` contains data about each individual attempt the runner has ever done.
- An **attempt** is defined as the moment the runner starts a run until the moment they either finish it or reset it on a particular split. Each `<Attempt>` tag contains:
  - The **run id**. The very first attempt has id 1.
  - The **datetime in UTC** when the attempt was started. The format used is `MM/DD/YYYY HH:mm:ss`.
  - The **datetime in UTC** when the attempt was ended. The format used is `MM/DD/YYYY HH:mm:ss`.
  - Two flags, `isStartedSynced` and `isEndedSynced`, which I don't know the exact purpose of but they seem to evaluate to False when some sort of error occurs.
  - If the attempt was completed, its final Real Time and/or Game Time.
- Example:

```xml
<AttemptHistory>
  <Attempt id="1" started="08/23/2021 12:33:14" isStartedSynced="True" ended="08/23/2021 12:37:58" isEndedSynced="True" />
  <Attempt id="2" started="08/23/2021 12:59:33" isStartedSynced="True" ended="08/23/2021 12:59:46" isEndedSynced="True" />
  <Attempt id="3" started="08/23/2021 12:59:46" isStartedSynced="True" ended="08/23/2021 12:59:46" isEndedSynced="True" />
  <Attempt id="4" started="08/23/2021 12:59:46" isStartedSynced="True" ended="08/23/2021 12:59:47" isEndedSynced="True" />
  <Attempt id="5" started="08/23/2021 13:17:45" isStartedSynced="True" ended="08/23/2021 13:17:59" isEndedSynced="True" />
  <Attempt id="6" started="08/23/2021 13:19:15" isStartedSynced="True" ended="08/23/2021 15:19:10" isEndedSynced="True">
    <RealTime>01:59:54.3680000</RealTime>
    <GameTime>01:34:32</GameTime>
  </Attempt>
  ...
</AttemptHistory>
```

### Segments

- `<Segments>` contains data about each individual split/segment the runner has ever done. A split/segment can be thought of as a small portion of the game, for example the first, second, third, ... level of the game. Each `<Segment>` tag contains:
  - The `<Name>` of the split/segment.
    - If the name starts with a `-` character, it's a normal split.
    - If it starts with `{ ... }`, it's known as a **subsplit**, which is the last split of a group of splits. For example, if a runner has splits for each level of a game, they could have a subsplit at the end of each world that groups the levels of that world.
    - If it doesn't start with either of those, the file does not use subsplits.
  - The `<Icon>` of the split/segment (if any).
  - A list of Split Time comparisons (`<SplitTimes>`), by default only one, called Personal Best. These are not times of the split itself, but rather the **total time** from the start of the run until the end of that split. This is also called the **pace** of the run up to that split. For the very first split, the split time and the segment time are the same, but for all subsequent splits they differ.
  - The best time ever obtained in that split (`<BestSegmentTime>`), known as the **gold split**. This time is available in Real Time and also in Game Time if the game supports it and it's enabled.
  - The `<SegmentHistory>` of the split/segment, which contains a list of all the times ever obtained in that segment.
    - Each `<Time>` tag inside `<SegmentHistory>` contains:
      - The **run id** of the attempt where the time was obtained.
      - The **Real Time** and/or **Game Time** obtained in that particular split on that particular attempt.
- Example:

```xml
<Segments>
  <Segment>
    <Name>-Level 1</Name>
    <Icon />
    <SplitTimes>
      <SplitTime name="Personal Best">
        <RealTime>00:05:12.3450000</RealTime>
        <GameTime>00:04:50.3330000</GameTime>
      </SplitTime>
    </SplitTimes>
    <BestSegmentTime>
      <RealTime>00:04:58.1230000</RealTime>
      <GameTime>00:04:45.6000000</GameTime>
    </BestSegmentTime>
    <SegmentHistory>
      <Time id="1">
        <RealTime>00:05:30.4560000</RealTime>
        <GameTime>00:05:10.2000000</GameTime>
      </Time>
      <Time id="2">
        <RealTime>00:05:12.3450000</RealTime>
        <GameTime>00:04:50.3330000</GameTime>
      </Time>
      ...
    </SegmentHistory>
  </Segment>
  <Segment>
    <Name>-Level 2</Name>
    ...
  </Segment>
</Segments>
```

---

## Project documentation

### Directory structure

- `config/`: Configuration files needed to run the application.
  - `config.yaml` has the configuration parameters needed to run the application.
  - `service_account_secrets.json` has the Google API service account credentials needed to import data from Google Drive and export data to Google Sheets.
  - `last_table_updates.json` is auto-generated by the application and is used to keep track of the last time each table in the DB was updated.
- `output/`: Output files generated by the application, such as a log file or exported excel files.
- `sql scripts/`:
- `src/`:
  - `auth/`:
  - `config/`:
  - `db/`:
  - `sheet/`:
  - `splits/`:
  - `main.py`:
  - `execution_modes.py`:

### Functionalities

...

### Execution flow

...

---

## How to use

### Prerequisites

In order to run this project, you need to have the following programs installed on your system:

- [Git](https://git-scm.com/install/)
- [Python 3.13](https://www.python.org/downloads/release/python-3139/)
- [uv](https://docs.astral.sh/uv/getting-started/installation/)
- [PostgreSQL 17](https://www.postgresql.org/download/)

### Initial setup

1. Clone the repository:

```bash
git clone https://github.com/JuanCruzCB/LiveSplit-Analytics-Database.git
```

2. Go into the project directory:

```bash
cd LiveSplit-Analytics-Database
```

3. Install the dependencies using `uv`:

```bash
uv sync
```

4. Create a PostgreSQL database and user for the project.

### Basic configuration

5. Inside the `config/` directory, create a copy of `config.example.yaml` and rename it to `config.yaml`.
6. Edit `config.yaml` and set the PostgreSQL connection parameters to match your database and user created in step 4:

```yaml
local_database:
  dbname: postgres
  user: postgres
  host: localhost
  password: 123
  port: 5432
```

7. Edit `config.yaml` and set your runner name and the path to your LiveSplit file:

```yaml
main_runner:
  name: runner1
  splits_file: "C:/Path/To/my splits.lss"
```

**NOTE**: The LiveSplit file can have any name, but the runner's name cannot contain commas (,), hyphens (-), empty spaces ( ), or underscores (\_).

8. Edit `config.yaml` and set the list of the names of other runners to compare to, as well as the path to the directory where their LiveSplit files are stored:

```yaml
other_runners:
  names:
    - runner2
    - runner3
  splits_folder: "C:/Path/To/Other runners splits"
```

**NOTE**: The LiveSplit files of other runners must be named following this exact pattern: `splits <runner_name>.lss`. For example, if the runner name is `Peter`, the LiveSplit file must be named `splits Peter.lss`. The same restrictions on the runner names mentioned in step 7 also apply here.

### Extra optional configuration

9. (Optional) If you want to import LiveSplit files off of Google Drive and/or export the resulting analytics to Google Sheets, follow these steps:
   1. Set up a **Google Cloud project**.
   2. Create a **service account** with the necessary permissions.
   3. Download the service account credentials JSON file.
   4. Edit `config.yaml` and set the path to the aforementioned JSON file, as well as either the Google Sheet ID or the Google Drive folder ID, or both:
   ```yaml
   google_api:
     service_account_secrets_file: "C:/Path/To/My/service_account_secrets.json" # Can be left empty
     google_sheet_id: my-google-sheet-id # Can be left empty
     google_drive_folder_id: my-google-drive-folder-id # Can be left empty
   ```

### How to run

10. To run the application, use the following command:

```bash
uv run src/main.py
```

---

## Possible improvements

...

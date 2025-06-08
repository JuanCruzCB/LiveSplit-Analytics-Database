# How this program works

- First, we download all LiveSplit files (.lss) inside Luis [RE4 LRT splits upload](https://drive.google.com/drive/u/0/folders/1-OvGMbjiemrxMaie166Cmwbu3k5WvXGh) Google Drive folder and we save them to a designated folder.
- Then we connect to the already existent local postgres database and run Luis .sql script once for each LiveSplit file that we downloaded + 1 (my own splits which are not on the Drive). For each execution of the .sql we previously replace all table names and such by the name of the runner, which is already present in the splits file.
- After that, we run some "global" queries that give us a comparison table between all the runners, and we export these tables to excel files.
- Finally, we update the public golds Google Sheet with the data of the excel files.
- **In short, this program allows us to update the Google Sheet with all the data from the splits that were uploaded on the Drive. The data on the sheet will be up-to-date as long the runners upload their splits onto the Drive.**

# How to add a new runner

1. Tell Luis to update the Main and Global .sql scripts with the new runner's tables.
2. Add the runner's name to the list **CURRENTLY_ALLOWED_RUNNERS**.
3. Add the runner's splits name to the dict comprehension **DEFAULT_UPDATES**.
4. Delete **last_table_updates.json**.
5. Download the runners splits manually the first time, and place them on the proper folder.

# Import order

1. Python standard library modules.
2. .venv dependencies.
3. Project files.

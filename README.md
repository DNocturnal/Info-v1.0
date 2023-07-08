# Info21 v1.0

Data analysis and statistics about students


## 1. Creating a database

Write a *part1.sql* script that creates the database and all the tables described above.

Also, add procedures to the script that allow you to import and export data for each table from/to a file with a *.csv* extension. \
The *csv* file separator is specified as a parameter of each procedure.

## 2. Changing data

Create a *part2.sql* script, in which, in addition to what is described below, add test queries/calls for each item.

##### 1) Write a procedure for adding P2P check


##### 2) Write a procedure for adding checking by Verter


##### 3) Write a trigger: after adding a record with the "start" status to the P2P table, change the corresponding record in the TransferredPoints table

##### 4) Write a trigger: before adding a record to the XP table, check if it is correct

### 3. Getting data

Create a *part3.sql* script, in which you should include the following procedures and functions
(consider as procedures all tasks that do not specify that they are functions).

##### 1) Write a function that returns the TransferredPoints table in a more human-readable form

##### 2) Write a function that returns a table of the following form: user name, name of the checked task, number of XP received

##### 3) Write a function that finds the peers who have not left campus for the whole day

##### 4) Calculate the change in the number of peer points of each peer using the TransferredPoints table

##### 5) Calculate the change in the number of peer points of each peer using the table returned by function-that-returns-the-transferredpoints-table

##### 6) Find the most frequently checked task for each day

##### 7) Find all peers who have completed the whole given block of tasks and the completion date of the last task

##### 8) Determine which peer each student should go to for a check.

##### 9) Determine the percentage of peers who:

##### 10) Determine the percentage of peers who have ever successfully passed a check on their birthday

##### 11) Determine all peers who did the given tasks 1 and 2, but did not do task 3

##### 12) Using recursive common table expression, output the number of preceding tasks for each task

##### 13) Find "lucky" days for checks. A day is considered "lucky" if it has at least *N* consecutive successful checks

##### 14) Find the peer with the highest amount of XP

##### 15) Determine the peers that came before the given time at least *N* times during the whole time

##### 16) Determine the peers who left the campus more than *M* times during the last *N* days

##### 17) Determine for each month the percentage of early entries

## Bonus. Part 4. Metadata

For this part of the task, you need to create a separate database, in which to create the tables, functions, procedures, and triggers needed to test the procedures.

##### 1) Create a stored procedure that, without destroying the database, destroys all those tables in the current database whose names begin with the phrase 'TableName'.

##### 2) Create a stored procedure with an output parameter that outputs a list of names and parameters of all scalar user's SQL functions in the current database. Do not output function names without parameters. The names and the list of parameters must be in one string. The output parameter returns the number of functions found.

##### 3) Create a stored procedure with output parameter, which destroys all SQL DML triggers in the current database. The output parameter returns the number of destroyed triggers.

##### 4) Create a stored procedure with an input parameter that outputs names and descriptions of object types (only stored procedures and scalar functions) that have a string specified by the procedure parameter.

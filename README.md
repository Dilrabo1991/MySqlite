# Welcome to My Sqlite

***

## Task

My SQLite for ruby Mirislomov Mirjamol and Xujamuratova Dilrabo

## Description

Using complex algorithms, using internet resources and thinking logically, we implemented the project according to the conditions
Sqlite cli work for SELECT, DELETE, INSERT, UPDATE COMMANDS <br>
Sqlite Request work for all required tasks (e.i JOIN, UPDATE) <br>
CLI separate with space separator, ```name=John``` <= don't work,  ```name = John``` <=work
<br>```name = John Rockfeller``` <= don't work
<br>```name = John_Rockfeller``` <= work

## Installation

Ruby

## Usage
CLI and Request work with following commands
```
 req = MySqliteRequest.new
 req.select(['name', 'position', 'year_start']).from("data.csv").order('asc', 'year_start').run
 -----------------------------------------------------------------------------------------------
 ins = MySqliteRequest.new
 ins.insert("newDB.csv").values(["2010", "Dilrabo","2013", "Sog'liqni saqlash", "160", "200", "Jul 7, 1991","STT kolleji"]).run
 -----------------------------------------------------------------------------------------------------
 up = MySqliteRequest.new
 up.update("newDB.csv").set({"college": "Qwasar SV"}).where("year_start", "2010").run
 -----------------------------------------------------------------------------------------------------
    del = MySqliteRequest.new
    del = del.from("newDB.csv")
    del = del.delete
    del = del.where("name", "Holmon Alp")
    del.run
 =====================================================================================================
 SELECT * FROM STUDENTS
 DELETE FROM STUDENTS WHERE name = John
```

### The Core Team


<span><i>Made at <a href='https://qwasar.io'>Qwasar SV -- Software Engineering School</a></i></span>
<span><img alt="Qwasar SV -- Software Engineering School's Logo" src='https://storage.googleapis.com/qwasar-public/qwasar-logo_50x50.png' width='20px'></span>

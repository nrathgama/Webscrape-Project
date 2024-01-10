# Webscrape-Project - Graybar.com

This project is consisting of gathering relevent information to create a vendor catalog

Beautifulsoup is a great python package that can be used to do a webscrape. However depending on the way a particular website is setup sometimes it is better to use package like Selenium which would dynamically fetch the information needed from the webscrape. 

I have used Selenium to do this particular webscrape. 

What to do with the data?

You can either save data into a CSV file and manually upload the data into SQL server, or automate the Python script to a targeted SQL table.

How can I split each column into value and UoM columns?

Please see the View I have created based on the Vendor Catalog SQL table. This SQL query is splitting every column into a Value and UoM columns as well as all the fractions, decimals, and combo into decimals.
This VIEW will help you to brush up CTE skills, CASE statements, REPLACE, CHARINDEX, PATINDEX, JOINS, CAST etc.


Graet project to get hands on knowledge on extensive SQL and Python knowledge! :)

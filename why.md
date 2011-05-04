---
layout: default
---
Traditional SQL databases are designed for situations where data storage is considered an independent task. Data is often stored without any one particular method of access in mind - it will be accessed in different ways in different situations, and often data is stored without even knowing how it will be accessed in the future.

Databases used for web applications are different. There is usually a very specific way the data is going to be accessed, in addition to a generally stronger connection between the database and the application it is being developed for, as opposed to traditional databases that are treated as more stand-alone units to be accessed by multiple applications.

Frameworks like EasyRedis allow for a more web-appropriate way of developing databases. EasyRedis can optimize how it stores its data for the specific access cases your application needs. There is also minimal external setup - just have a redis server running and the rest is handled completely through ruby code.

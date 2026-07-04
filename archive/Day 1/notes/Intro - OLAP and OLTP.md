
Data Warehouse (DW) is just a database -

OLTP:	The primary purpose of most day to day databases is (Online Transaction Processing)
	handling transactions (aka to provide read/write access to your data)
	That's exactly what OLTP is –
	Online Transaction Processing (aka transactional or traditional database)

OLAP:	is also a database (Online Analytical Processing)
	(that follows the same principles of relational databases)
	However, it is built in a different way
	OLAP is Online Analytical Processing – optimised for reporting (SELECT)


Any database is supposed to handle DML (Data Manipulation language) statements (SELECT/INSERT/UPDATE/DELETE),
aka CRUD (Create, Read, Update, Delete)
OLTP DB is optimised for write operations (INSERT/UPDATE/DELETE), whilst
OLAP DB is optimised for read operation   (SELECT)



If any DBMS is supposed to be able to handle both SELECT and INSERT/UPDATE/DELETE -

a. Which database objects allow users to significantly speed up data retrieval?
	   INDEXES
b. The thing is - with every data change in a table,
	   ALL the indexes for that table must be rebuilt
	c. That's why having lots of indexes slows down INSERT/UPDATE/DELETE operations
	d. However, all those indexes are needed for data retrieval
	   (aka read operation, SELECT, reporting)
	   Why indexes are required for SELECT operation?
	   Because running WHERE/ORDER BY on a column that does not have an index
	   will cause full table scan
e. SO, CONCLUSION:
	   The more indexes you have - the slower write operations are
	   the less indexes you have - the slower read  operations are
f. THE MOST COMMON SOLUTION:
	   Create TWO databases per project:
	   one of them is OLTP (day to day DB),
	   and the other one is OLAP (DW)
	   OLTP would handle day to day transactions, whilst
	   OLAP would be used purely for reporting and analysis
Records from OLTP would be moved to OLAP after certain period of time
	   (e.g. once order completed and return time period lapsed)

OLTP vs OLAP

OLTP (aka traditional DB)
	a. Allow read-write operations
	b. Read/write ratio: 100…10000 : 1
	c. Create only the necessary indexes
	d. Usually in the perfect 3NF (third normal form - normalisation)
	e. Redundant data is never stored
	f. Examples: online shop, bank, any day to day business operations


OLAP (aka reporting DB)
	a. Optimised mostly for reading operations (reporting)
	b. Read/write ratio: 1 000 000 000 : 1 (some DWs are even read only)
	c. Create as many indexes as possible
	d. Might be below 3NF (denormalisation)
	e. May store repeating (redundant) data e.g. some summaries which
	   normally would be calculated every time you need to retrieve those values
	f. Example: data reporting facility aka Data Warehouse



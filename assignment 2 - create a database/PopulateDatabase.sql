USE Maayan
go

INSERT INTO Publishers
SELECT distinct Publication,PublisherCountry
FROM  librarything_maayan
where Publication is not null

INSERT INTO Books
select ISBN,Title,Summary,P.PublisherID,COALESCE(Subjects,'unclassified'),Languages
from librarything_maayan L left join Publishers P
	on L.Publication = P.PublisherName

UPDATE Books
set Title= N'אומנות ההקשבה לפעימות הלב'
where ISBN = '9655450864'

INSERT INTO Authors (AuthorName,AuthorCountry,AuthorBirthDate)
select distinct Primary_Author,AuthorCountry,AuthorBirthdate
from librarything_maayan


INSERT INTO Book_Authors
select ISBN,AuthorID
from librarything_maayan join Authors
	 on AuthorName = Primary_Author

INSERT INTO Members (Email,FirstName,LastName)
values('Maayan@gmail.com','Maayan','BT'),('Mor@gmail.com','Mor','Ganon'),('Gil@gmail.com','Gil','H'),('Dor@gmail.com','Dor','Ami')

INSERT INTO Members 
values('Moria@gmail.com','Moria','Even',3,100)

select * from Items

INSERT INTO Items
select ISBN,null,1
from Books

INSERT INTO Items
select ISBN,null,1
from Books
where ISBN like '%x%' or ISBN like '%14%'

update Items
set SavedFor = 'Maayan@gmail.com'
where ItemID = 18

INSERT INTO Borrowings (ItemID,MemberEmail,BorrowingDate,DueDate)
values(1,'Mor@gmail.com','2024-02-25','2024-04-25'),
(2,'Dor@gmail.com',CONVERT(date,'25-02-2024',105),'2024-04-25'),
(3,'Gil@gmail.com',CONVERT(date,'25-02-2024',105),'2024-04-25'),
(4,'Moria@gmail.com',CONVERT(date,'31-12-2023',105),'2024-02-28')

UPDATE Items
SET BookStatus = 0
where ItemID in(1,2,3,4)

INSERT INTO Borrowings (ItemID,MemberEmail,BorrowingDate,ReturnedDate,DueDate)
values(2,'Mor@gmail.com',CONVERT(date,'20-04-2023',105),CONVERT(date,'25-05-2023',105),'2023-05-25'),
(1,'Mor@gmail.com',CONVERT(date,'26-05-2023',105),CONVERT(date,'29-05-2023',105),'2023-05-29'),
(6,'Dor@gmail.com',CONVERT(date,'20-01-2024',105),CONVERT(date,'20-02-2024',105),'2024-02-20'),
(9,'Gil@gmail.com',CONVERT(date,'23-01-2024',105),CONVERT(date,'20-02-2024',105),'2024-03-29'),
(2,'Maayan@gmail.com',CONVERT(date,'20-01-2023',105),CONVERT(date,'20-02-2023',105),'2024-03-25')

INSERT INTO Borrowings (ItemID,MemberEmail,BorrowingDate,Fine,FinePaid,DueDate)
values(12,'Maayan@gmail.com',CONVERT(date,'20-12-2023',105),50,0,'2024-02-25'),
(10,'Dor@gmail.com',CONVERT(date,'29-12-2023',105),50,0,'2024-02-25')

UPDATE Items
SET BookStatus = 0
where ItemID in(12,10)

INSERT INTO Borrowings (ItemID,MemberEmail,BorrowingDate,ReturnedDate,Fine,FinePaid,DueDate)
values(5,'Mor@gmail.com',CONVERT(date,'20-04-2022',105),CONVERT(date,'25-07-2022',105),50,1,'2022-06-25'),
(6,'Gil@gmail.com',CONVERT(date,'20-04-2023',105),CONVERT(date,'25-07-2023',105),50,1,'2023-06-25'),
(2,'Gil@gmail.com',CONVERT(date,'23-07-2023',105),CONVERT(date,'25-12-2023',105),70,0,'2023-09-23')

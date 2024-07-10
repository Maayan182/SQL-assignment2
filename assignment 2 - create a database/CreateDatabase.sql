USE master
CREATE DATABASE Maayan
go
USE Maayan
go

CREATE TABLE Publishers
(
	PublisherID int primary key identity(1,1),
	PublisherName nvarchar(30) not null,
	PublisherCountry nvarchar(30) not null
)

CREATE TABLE Books
(
	ISBN varchar(13) primary key,
	Title nvarchar(100) not null,
	BookDes text,
	PublisherID int foreign key references Publishers(PublisherID),
	Category nvarchar(30) default 'unclassified' not null,
	BookLanguage nvarchar(30)
)

CREATE TABLE Authors
(
	AuthorID int Primary key identity(1,1),
	AuthorName nvarchar(30) not null,
	AuthorBirthDate date,
	AuthorCountry nvarchar(30) not null,
)

CREATE TABLE Book_Authors
(
	ISBN varchar(13) foreign key references Books(ISBN),
	AuthorID int foreign key references Authors(AuthorID)
	constraint PK_BooksAuthors primary key (ISBN,AuthorID)

)

CREATE TABLE Members
(
	Email varchar(320) primary key,
	FirstName nvarchar(30) not null,
	LastName nvarchar(30) not null,
	NumOfBooksAllowed int default 1 not null,
	MonthlySubscription money not null default 50

)


CREATE TABLE Items
(
	ItemID int primary key identity(1,1),
	ISBN varchar(13) foreign key references Books(ISBN),
	SavedFor varchar(320) foreign key references Members(Email) default null,
	BookStatus bit default 1
)

 
CREATE TABLE Borrowings
(
	
	ItemID int foreign key references Items(ItemID) not null,
	MemberEmail varchar(320) foreign key references Members(Email) not null,
	BorrowingDate date not null default convert(date,getdate()),
	DueDate date not null default Dateadd(month,2,convert(date,getdate())),
	ReturnedDate date,
	Fine money,
	FinePaid bit default 1
)

-- שלא יהיה אפשר שאותו פריט יושאל באותו טווח זמנים פעמיים וגם שלא יהיה אפשר להשאיל פריט שלא החזירו עדיין
--סופר כמה פעמים הפריט מופיע בטבלה בטווח תאריכים שמתנגש עם הטווח שהכנסתי וכמה הוא מופיע עם תאריך השאלה של הזמנה פתוחה שהוא לפני התאריך החזרה שהכנסתי 
go
create function CheckRange(@Item int,@BorrowingDate date, @ReturnedDate date)
	returns int
	begin

	declare @Count int

	select @Count = COUNT(*)
	from Borrowings
	where ItemID = @Item AND
	(@BorrowingDate < ReturnedDate AND @ReturnedDate > BorrowingDate)  or
	(ReturnedDate is null AND ItemID = @Item AND @ReturnedDate > BorrowingDate)
		
	return @Count

end
go
-- פריט יכול להופיע בטבלת השאלות רק פעם אחת עם התנאים הנ"ל או לא בכלל
ALTER TABLE Borrowings
ADD constraint Returned CHECK(dbo.CheckRange(ItemID,BorrowingDate,ReturnedDate) <= 1)










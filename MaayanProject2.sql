use AdventureWorks2022
go
create view vCustomerWithPerson
as
select C.*,
p.BusinessEntityID,p.AdditionalContactInfo,p.Demographics,
p.EmailPromotion,p.FirstName,p.LastName,p.MiddleName,
p.ModifiedDate as PersonModifiedDate,p.NameStyle,p.PersonType,
p.rowguid as PersonRowguid,p.Suffix,p.Title  
from Sales.Customer C left join 
Person.Person P
	on(c.PersonID=P.BusinessEntityID)
go

--Q1
--Write a query that displays information about products that have not been purchased.
--Display: ProductID, ProductName, Color, ListPrice, Size
--Sort the report by ProductID
select * 
from (
	select ProductID,Name,Color,ListPrice,Size 
	from Production.Product
	EXCEPT
	select distinct p.ProductID,Name,Color,ListPrice,Size 
	from Sales.SalesOrderDetail SOD join Production.Product P
		on (SOD.ProductID = p.ProductID)) tbl
order by tbl.ProductID
go
--Q2
--Write a query that displays information about customers who have not placed any orders.
--Display: CustomerID, LastName of the customer
--Sort the report in ascending order by CustomerID
--If the customer does not have a LastName or FirstName, display "Unknown"

-- option 1
select * 
from (
	select CustomerID,ISNULL(P.LastName,'Unknown') AS LastName,ISNULL(P.LastName,'Unknown') as FirstName
	from Sales.Customer C left join Person.Person P
		ON(C.PersonID =P.BusinessEntityID)
	EXCEPT
	select distinct SOH.CustomerID,ISNULL(P.LastName,'Unknown') AS LastName,ISNULL(P.LastName,'Unknown')  as FirstName
	from Sales.SalesOrderHeader SOH	
		join	
		Sales.Customer C 
		ON (SOH.CustomerID = C.CustomerID)
		left join Person.Person P
		ON(C.PersonID =P.BusinessEntityID)
) tbl
order by tbl.CustomerID
go
--option 2 *SalesOrderHeader.CustomerID is set to not null so I know the nulls are from the join

select C.CustomerID,ISNULL(P.LastName,'Unknown') AS LastName,ISNULL(P.LastName,'Unknown')  as FirstName
from 
	Sales.Customer C 
	left join
	Sales.SalesOrderHeader SOH
	on (c.CustomerID =SOH.CustomerID)
	left join Person.Person P
	ON(C.PersonID =P.BusinessEntityID)
where SOH.CustomerID is null
order by c.CustomerID
go
--Q3

--Write a query that displays the details of the top 10 customers who have placed the most orders.
--Display: CustomerID, FirstName, LastName, and the number of orders placed by the customers
--sorted in descending order.

-- no left join this time because its only 10 lines and you can see that none of their PersonID is null. 
--if it was too many lines to check or you are worried that someone will add to SOH table a customer without PersonID filed 
--its better to do left join and isnull() like on Q2
select top 10 SOH.CustomerID,p.LastName,p.FirstName,COUNT(*) as countOrders
from Sales.SalesOrderHeader SOH join Sales.Customer C
	on(SOH.CustomerID = C.CustomerID)
	join
	Person.Person P
	on(C.PersonID =p.BusinessEntityID)
group by SOH.CustomerID,p.LastName,p.FirstName
order by countOrders desc
go
--Q4
--Write a query that displays information about employees and their roles, 
--and the number of employees in the same role as the employee.
select p.FirstName,p.LastName,e.JobTitle,e.HireDate,count(*)over(partition by e.JobTitle) as CountOfTitle
from HumanResources.Employee E join Person.Person P
	on(E.BusinessEntityID = P.BusinessEntityID)
go

--Q5
--Write a query that displays for each customer the date of the last order they placed and the date of the order before the last one.
--Display: FirstName, LastName, CustomerID, SalesOrderID, date of the last order, and the date of the order before the last one.
with CTE
as
(
select SOH.SalesOrderID,SOH.CustomerID,C.FirstName,C.LastName,
SOH.OrderDate,LAG(SOH.OrderDate,1)over(partition by SOH.CustomerID order by SOH.OrderDate) as PreviousOrderDate,
Rank()over(partition by SOH.CustomerID order by SOH.OrderDate desc) as DateRnPerCustomer
from vCustomerWithPerson C join Sales.SalesOrderHeader SOH
	on(C.CustomerID = SOH.CustomerID)
--order by SOH.CustomerID,SOH.OrderDate desc
)
select SalesOrderID,CustomerID,FirstName,LastName,OrderDate as LastOrderDate,PreviousOrderDate 
from CTE
where DateRnPerCustomer = 1
go
--Q6
--Write a query that displays the total amount of products in the most expensive order for each year, 
--and show which customers these orders belong to.
with CTE
as
(
select year(SOH.OrderDate) as 'Year',SalesOrderID,C.FirstName,C.LastName,format(SOH.SubTotal,'n1') as Total,
ROW_NUMBER()over(partition by year(SOH.OrderDate) order by SOH.SubTotal desc) as RNByTotalPerYear
from Sales.SalesOrderHeader SOH join vCustomerWithPerson C
	on(SOH.CustomerID = C.CustomerID)
)
select Year,SalesOrderID,FirstName,LastName,Total 
from CTE
where RNByTotalPerYear = 1
go
--Q7
--Display the number of orders made each month in a year using a matrix.
select Months,[2011],[2012],[2013],[2014]
from
(
select SalesOrderID,year(OrderDate) as Years,MONTH(OrderDate) AS Months
from Sales.SalesOrderHeader
)tbl
pivot(count(tbl.SalesOrderID) for Years in ([2011],[2012],[2013],[2014]))pvt
order by Months
go
--Q8
--Write a query that displays the total amount of products in orders for each month of the year 
--and also the cumulative total for each year. Pay attention to the report's appearance.

--Option 1 I dont know why I complicated it so much at first, but option 2 seems better
with CTE1
as
(
select year(OrderDate)as Years,MONTH(OrderDate)AS Months,
format(sum(SubTotal),'n2') as SumPerMonthInYear
from Sales.SalesOrderHeader
group by GROUPING sets (YEAR(OrderDate),(year(OrderDate),MONTH(OrderDate)))
),
CTE2
as
(
select distinct year(OrderDate)as Years,MONTH(OrderDate) AS Months,
format(SUM(SubTotal)over(partition by year(OrderDate),MONTH(OrderDate)),'n2') as SumPerMonthInYear ,
format(sum(SubTotal)over(partition by year(OrderDate) order by MONTH(OrderDate)), 'n2') as Cum_Sum
from Sales.SalesOrderHeader
)
select CTE1.Years,ISNULL(convert(nvarchar(6),CTE2.Months),'Total') as Months, CTE2.SumPerMonthInYear,
case
when 
CTE2.Cum_Sum is null then CTE1.SumPerMonthInYear
else CTE2.Cum_Sum
end as Cum_Sum
from CTE1 left join CTE2
 on(CTE1.Years = CTE2.Years and CTE1.Months = CTE2.Months)
 order by CTE1.Years,case 
	when 
	CTE1.Months is null then 13
	else CTE1.Months 
	end
go
-- Option 2: when finshing option 1 I realized its better to use subquery/CTE in order to use both grouping sets function and windows function
--in the same time and that the cumulating sum can be relying on the sum per month in year
select Years,
isnull(convert (nvarchar(6),Months),'Total') as Months,
SumPerMonthInYear,
sum(SumPerMonthInYear)over(partition by Years order by Years,
	case 
		when 
		Months is null then 13
		else Months 
		end) as Cum_Sum
from
(
select year(OrderDate)as Years,MONTH(OrderDate)AS Months,
case when MONTH(OrderDate) is not null then sum(SubTotal)
end as SumPerMonthInYear
from Sales.SalesOrderHeader
group by GROUPING sets (YEAR(OrderDate),(year(OrderDate),MONTH(OrderDate)))
)tbl
go
--Q9
--Write a query that displays employees by their order of joining in each department, 
--from the newest employee to the oldest employee.
--Display columns: Department name, employee number, full name, hire date, tenure in months,
--full name and hire date of the employee hired before them, 
--and the number of days between the hire date of the employee and the employee hired before them.
with CTE
as
(
	select Name as department,EDH.BusinessEntityID,p.FirstName+' '+p.LastName as FullName,EDH.StartDate,
	datediff(MM,EDH.StartDate,GETDATE()) as Seniority,
	lag(EDH.BusinessEntityID)over(partition by EDH.DepartmentID order by StartDate) as PreviuosEmpBusinessEntityID
	from HumanResources.EmployeeDepartmentHistory EDH join HumanResources.Department D
		on(EDH.DepartmentID = D.DepartmentID)
		join Person.Person P
		on (p.BusinessEntityID =EDH.BusinessEntityID)
	where EDH.EndDate is null
-- in my understanding when you are asked to display the workers in each department ordered from senior to junior its only who is currently in the department
)
select this.department,this.BusinessEntityID,this.FullName,this.StartDate,this.Seniority,
pre.FullName AS preFullName,pre.StartDate as PreHireDate,DATEDIFF(dd,pre.StartDate,this.StartDate) as DAYDIFF
from 
CTE this left join CTE pre
 on(this.PreviuosEmpBusinessEntityID = pre.BusinessEntityID)
 order by this.department,this.StartDate desc
go
 --Q10
--Write a query that displays details of employees who work in the same department and were hired on the same date.
--List the employees for each combination of hire date and department number, sorted by dates in descending order.

 -- this is what I belive they meant in the assignment (based on the picture).
 --but they asked to show deatiles just for whoever hire date is the same as someone else within the department 
 --so I dont think its correct like that.(beacuse it shows evreyone)
select StartDate,DepartmentID,
stuff((
 select ','+cast(p.BusinessEntityID as nvarchar(30)) +' '+p.FirstName+' '+P.LastName
 from 
 HumanResources.EmployeeDepartmentHistory EDH
	join person.Person P
	on (P.BusinessEntityID= EDH.BusinessEntityID)
	where EDH.EndDate is null and 
	 EDH.StartDate = EDH2.StartDate
for xml path('')),1,1,'') as TeamEmployees
from HumanResources.EmployeeDepartmentHistory EDH2
where EndDate is null
group by DepartmentID,StartDate
order by StartDate desc
go
-- so I can add this HAVING to show what I want:

select StartDate,DepartmentID,
stuff((
 select ','+cast(p.BusinessEntityID as nvarchar(30)) +' '+p.FirstName+' '+P.LastName
 from 
 HumanResources.EmployeeDepartmentHistory EDH
	join person.Person P
	on (P.BusinessEntityID= EDH.BusinessEntityID)
	where EDH.EndDate is null and 
	 EDH.StartDate = EDH2.StartDate
for xml path('')),1,1,'') as TeamEmployees
from HumanResources.EmployeeDepartmentHistory EDH2
where EndDate is null
group by DepartmentID,StartDate
having COUNT(*) > 1
order by StartDate desc




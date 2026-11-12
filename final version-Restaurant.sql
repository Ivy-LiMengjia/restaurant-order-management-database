drop table if exists Restaurant.Payments
drop table if exists Restaurant.OrderItems
drop table if exists Restaurant.Orders
drop table if exists Restaurant.Reservations
drop table if exists Restaurant.MenuItemsIngredients
drop table if exists Restaurant.MenuItems
drop table if exists Restaurant.Ingredients
drop table if exists Restaurant.MenuCategory
drop table if exists Restaurant.Staff
drop table if exists Restaurant.[Tables]
drop table if exists Restaurant.Customer

go

create Table Restaurant.Customer (
CustomerID int identity primary key,
FirstName varchar(100) not null,
LastName varchar(100) not null,
Phone varchar(50),
Email varchar(100) 
)

create Table Restaurant.[Tables] (
TableNumber int primary key
)

create table Restaurant.Staff (
StaffID int identity primary key,
FirstName varchar(100) not null,
LastName varchar(100) not null,
[Role] varchar(100) not null,
HireDate date
)

create table Restaurant.MenuCategory (
CategoryID int identity primary key,
[Name] varchar (100) not null
)

create table Restaurant.Ingredients (
IngredientsID int identity primary key,
[Name] varchar(100) not null,
Stock decimal(10,2) not null
)

create table Restaurant.MenuItems(
MenuItemID int identity primary key,
[Name] varchar (100) not null,
Price decimal(10,2) not null,
[Description] varchar(500),
CategoryID int not null,
constraint fk_Menu_Category foreign key (CategoryID) references Restaurant.MenuCategory (CategoryID) 
)

create table Restaurant.MenuItemsIngredients (
MenuItemID int not null,
IngredientsID int not null,
Quantity decimal(10,2) not null,
primary key (MenuItemID, IngredientsID),
constraint fk_Menu_Items foreign key (MenuItemID) references Restaurant.MenuItems (MenuItemID),
constraint fk_Ingredients foreign key (IngredientsID) references Restaurant.Ingredients(IngredientsID)  
)

create table Restaurant.Reservations(
ReservationID int identity primary key,
TableNumber int not null,
CustomerID int not null,
ReservationDate Date not null,
ReservationTime Time not  null,
constraint fk_R_Table foreign key (TableNumber) references Restaurant.[Tables] (TableNumber),
constraint fk_R_Customer foreign key (CustomerID) references Restaurant.Customer (CustomerID),
)

create table Restaurant.Orders (
OrderID int primary key,
CustomerID int not null,
StaffID int not null,
TableNumber int not null,
[Status] varchar(100),
OrderType varchar(100),
TotalCost decimal(20,2) not null,
OrderDate Date not null,
SpecialRequests varchar(500) ,
constraint chk_order_status CHECK ([Status] IN ('placed', 'in preparation', 'served', 'completed', 'cancelled')),
constraint chk_order_type CHECK (OrderType IN ('dine-in', 'takeaway')),
constraint fk_O_Customer foreign key (CustomerID) references Restaurant.Customer (CustomerID),
constraint fk_O_Table foreign key (TableNumber) references Restaurant.[Tables] (TableNumber),
constraint fk_O_Staff foreign key (StaffID) references Restaurant.Staff(StaffID)
)

create table Restaurant.OrderItems(
OrderID int not null,
MenuItemID int not null,
Quantity int not null,
Price decimal (10,2),
primary key (OrderID, MenuItemID),
constraint fk_Order foreign key (OrderID) references Restaurant.Orders (OrderID),
constraint fk_M_O foreign key (MenuItemID) references Restaurant.MenuItems (MenuItemID),
constraint ck_quantity check (Quantity>0) 
)

create table Restaurant.Payments (
BillID int identity primary key,
OrderID int not null,
PaymentMethod varchar (100),
PaymentStatus varchar (100),
Amount decimal(20,2),
constraint fk_P_Order foreign key (OrderID) references Restaurant.Orders (OrderID),
constraint ck_amount check (Amount>0) 
)

--select * from Restaurant.[Restaurant Order Management]

-- 7. Insert Payments data

insert into Restaurant.Customer(Email, Phone, LastName, FirstName)
select distinct Customer_Email as Email, customer_phone as Phone, 
LTRIM(RTRIM(SUBSTRING(Customer_Name, 1, CHARINDEX(' ', Customer_Name) - 1))) as LastName, 
LTRIM(RTRIM(SUBSTRING(Customer_Name, CHARINDEX(' ', Customer_Name) + 1, LEN(Customer_Name)))) as FirstName 
from Restaurant.[Restaurant Order Management]

insert into Restaurant.Tables(TableNumber)
select distinct Table_Number as TableNumber from Restaurant.[Restaurant Order Management]
union
select distinct Reservation_Table_Number from Restaurant.[Restaurant Order Management]

insert into Restaurant.Staff(LastName, FirstName, Role)
select distinct LTRIM(RTRIM(SUBSTRING(Staff_Name, 1, CHARINDEX(' ', Staff_Name) - 1))) as LastName,
LTRIM(RTRIM(SUBSTRING(Staff_Name, CHARINDEX(' ', Staff_Name) + 1, LEN(Staff_Name)))) as FirstName,
Staff_Role as Role
from Restaurant.[Restaurant Order Management]

insert into Restaurant.MenuCategory(Name)
select distinct Menu_Category from Restaurant.[Restaurant Order Management]

insert into Restaurant.MenuItems(Name, Price, CategoryID)
select distinct Menu_Item, Menu_Item_Price, mc.CategoryID 
from Restaurant.[Restaurant Order Management] rom
join Restaurant.MenuCategory mc on rom.Menu_Category = mc.Name

insert into Restaurant.Reservations(ReservationDate, ReservationTime, TableNumber, CustomerID)
select Reservation_Date, Reservation_Time, Reservation_Table_Number, c.CustomerID 
from Restaurant.[Restaurant Order Management] rom
join Restaurant.Customer c on c.Email = rom.Customer_Email

insert into Restaurant.Orders(OrderID, OrderDate, TableNumber, SpecialRequests, CustomerID, TotalCost, StaffID)
select distinct Order_ID, Order_Date, Table_Number, Special_Requests, c.CustomerID, Total_Cost, s.StaffID
from Restaurant.[Restaurant Order Management] rom 
join Restaurant.Customer c on c.Email = rom.Customer_Email 
join Restaurant.Staff s on s.LastName + ' ' + s.FirstName = rom.Staff_Name and s.Role = rom.Staff_Role

insert into Restaurant.Payments(OrderID, Amount, PaymentStatus)
select distinct Order_ID, Payment_Amount, Payment_Status from Restaurant.[Restaurant Order Management]

insert into Restaurant.OrderItems
select rom.order_id as OrderID, mi.MenuItemID as MenuItemID, 
count(distinct rom.Menu_Item) as Quantity,
mi.Price as Price
from Restaurant.[Restaurant Order Management] as rom
join Restaurant.MenuItems mi on mi.Name = rom.Menu_Item
group by rom.Order_ID,rom.Menu_Item, mi.MenuItemID, mi.Price
order by rom.order_id

---retrieve all orders placed by a specific customer
select
    c.CustomerID, c.FirstName, c.LastName,
    o.OrderID, o.OrderDate, o.TotalCost
from Restaurant.Customer c
join Restaurant.Orders o on c.CustomerID = o.CustomerID
where c.CustomerID = 1
order by o.OrderDate desc;

---retrieve all reservation made for a specific date
select r.ReservationID, r.CustomerID, r.ReservationDate, r.ReservationTime, r.TableNumber
from Restaurant.Reservations r
where r.ReservationDate='2024-10-02'
order by r.ReservationTime


---find all available tables for a specific date and time
select
    t.TableNumber
from Restaurant.[Tables] t
where t.TableNumber not in (
    select r.TableNumber
    from Restaurant.Reservations r
    where r.ReservationDate = '2024-10-02'
      and r.ReservationTime = '19:00:00'
)

---calculate the total number of orders and total amount spent by each customer ordered by spending in descending
select c.CustomerID, c.FirstName, c.LastName,
count(o.OrderID) as TotalOrders,
cast(sum(o.TotalCost) as decimal(10,2)) as TotalSpent
from Restaurant.Customer c
join Restaurant.Orders o on o.CustomerID=c.CustomerID
group by c.CustomerID, c.FirstName, c.LastName
order by TotalSpent desc


---identify top5 best-selling menu items based on total quantity sold and total sales amount
select top 5
    mi.[Name] as MenuItem,
    sum(oi.Quantity) as TotalSold
from Restaurant.OrderItems oi
join Restaurant.MenuItems mi
    on oi.MenuItemID = mi.MenuItemID
group by mi.[Name]
order by TotalSold desc


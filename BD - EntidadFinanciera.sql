create database EntidadFinanciera
go

use EntidadFinanciera
go

create table Cliente
(
CI int primary key,
Nombre varchar(20) not null,
Apellido varchar (20) not null
)


create table Telefono 
(
Numero int not null,
CI int foreign key references Cliente (ci),
primary key (numero, ci)
)


Create table Tarjeta
(
NroT int identity (1,1) primary key,
CI int not null foreign key references Cliente (ci),
FechaVencimiento smalldatetime not null,
Personalizada bit not null,
)


Create table TCredito
(
NroT int primary key references Tarjeta (NroT),
Categoria varchar (20) not null,
Limite int not null
)


Create table TDebito
(
NroT int primary key references Tarjeta (NroT),
Saldo float not null,
CantCuentas int not null
)


Create table Compra
(
IDCompra int identity (1,1) primary key,
NroT int references Tarjeta (NroT),
FechaCompra smalldatetime not null,
Importe float not null
)

set language spanish
-- ***CARGA DE LOS DATOS DE PRUEBA***

insert cliente values (3125541,'Luis', 'Martínez'),
(4525298,'Roberto', 'Perez'), (4147852,'Miguel', 'Lopez'), 
(3214562,'Carlos', 'Santos'), (4952678,'Daniela', 'Gil'),
(3698521,'Gabriela', 'Flores'), (3759842,'Lucia', 'Hernandez'),
(2412369,'Carolina', 'Hernandez'), (2798465,'Daniela', 'Blanco'),
(4699123,'Nicolas', 'Prieto'), (5222444, 'John', 'Smith')


insert telefono values (98211456, 3125541), (98258741, 4525298), (97214950, 4147852), 
(97888521, 3214562), (98787522, 4952678), (99112469, 3698521), (99585747, 3759842), 
(97014943, 2412369), (98021274, 2798465), (99878441, 4699123), (98777888, 5222444)  

insert tarjeta values (3125541, '12/10/2021', 1), (4525298, '11/07/2019', 0), 
(4147852, '09/05/2018', 1), (3214562, '01/09/2023', 0), (4952678, '17/02/2022', 1), 
(3698521, '29/06/2023', 1), (3759842, '03/12/2015', 0), (2412369, '30/11/2018', 1), 
(2798465, '05/01/2015', 0), (4699123, '22/09/2014', 1), (5222444,'30/12/2017', 1), (5222444, '05/01/2020', 0)

insert TCredito values (1, 'Oro', 50000), (2, 'Clasica', 25000), (3, 'Clasica', 27000), (4, 'Plata', 32000), 
(5, 'Platinium', 65000)

insert TDebito values (6,45500, 2), (7, 12000, 3), (8, 22320, 1), (9, 39000, 4),
(10, 85000, 3), (11, 62000, 2), (12, 52000, 2)

insert Compra values (1, '01/05/2019', 4500), (2, '02/011/2018', 20000), (3, '25/12/2018', 10000), 
(4, '15/03/2019', 15520), (5, '08/04/2019', 32100), (6, '24/05/2016', 990), 
(7, '06/11/2018', 2250), (8, '19/04/2018', 6630), (9, '11/09/2015', 20000), 
(10, '31/12/2018', 12900), (1, '22/01/2019', 8000), (2, '11/08/2018', 2200), (3, '25/11/2018', 780), 
(4, '09/12/2018', 9000), (5, '30/03/2019', 3320), (6, '04/06/2018', 5430), (7, '11/09/2018', 1200), 
(8, '17/10/2018', 520), (9, '10/04/2017', 5500), (10, '20/07/2018', 3500)

--mas datos de prueba 
insert Compra values (1, '03/05/2019', 990), (2, '23/11/2018', 2000), (3, '10/09/2018', 700), (3, '31/12/2018', 1020),
(5, '03/05/2019', 3200), (7, '01/02/2019', 220), (9, '22/07/2018', 2000), (10, '14/02/2019', 7880), 
(10, '20/04/2019', 6630), (5, '11/11/2018', 1500)

----------------------------
--tarjeta de credito para John Smith (ya tiene dos de debito, todas sin compras)

insert Tarjeta values (5222444, '02/03/2021', 1)
insert TCredito values (13, 'Platinium', 60000)
go

-----------------------------------





create proc sp_BuscoCliente
@ci int

as
begin
select cliente.*, telefono.Numero 
from cliente
join Telefono
on cliente.ci = telefono.ci
where cliente.ci = @ci
end
go

-------------------------------------------
------ABM CLIENTE AGREGAR--------------------------
--------------------------------------------

CREATE PROC sp_AgregarCliente

@ci int,
@nom varchar (20),
@apell varchar (20),
@numtelf int

as

begin
	if exists (select * from cliente where ci = @ci)
		return 0; -- si ya existe cliente retorna 0

	declare @error int
	begin tran

		insert Cliente (ci, nombre, apellido) values (@ci, @nom, @apell)
		set @error = @@error

		
		insert Telefono (numero, ci) values (@numtelf, @ci)
		set @error = @@error
		
		if (@error = 0) -- si no hay error, finaliza transacion y retorna 1
			begin
				commit tran 
				return 1
			end
		else -- si hay error, no realiza transaccion y retorna -1
			begin
				rollback tran
				return -1
			end
end
go




----------------------------------------
-- ABM CLIENTE ELIMINAR --------------------------
------------------------------------------

create proc sp_BajaCliente

@ci int
as

begin
	if exists (select * from compra where NroT in (select NroT from Tarjeta where @ci = ci))
		return 0 -- si hay compras , devuelve 0

	if exists (select * from tarjeta where ci = @ci) --verifico si hay tarjetas		
	
	--si existen tarjetas entonces puedo empezar a eliminar
	declare @error int
	begin tran	
		
		delete from tcredito where NroT in (select NroT from tarjeta where CI = @ci)
		if @@error <> 0
		begin 
			rollback tran
			return -1
		end

		delete from TDebito where NroT in (select NroT from tarjeta where CI = @ci)
		if @@error <> 0
		begin 
			rollback tran
			return -1
		end

		delete from tarjeta where ci = @ci
		if @@error <> 0
		begin 
			rollback tran
			return -2
		end

		delete from telefono where ci = @ci and Numero in (select Numero from telefono where @ci = ci)
		if @@error <> 0
		begin 
			rollback tran
			return -3
		end

		delete from cliente where ci = @ci
		if @@error <> 0
		begin 
			rollback tran
			return -4
		end		
	commit tran
	return 1
end
go


----------------------------------------
-- ABM CLIENTE MODIFICAR --------------------------
------------------------------------------

create proc sp_ModificarCliente

@ci int,
@nom varchar (20),
@apell varchar (20),
@numtelf int

as


begin
	if not exists (select * from cliente where ci = @ci)
		return 0 
	
	declare @error int
	begin tran
		update Cliente set nombre = @nom, apellido = @apell where ci = @ci
		set @error = @@error

		update Telefono set numero = @numtelf where ci = @ci
		set @error = @@error

		if (@error = 0)
			begin
				commit tran
				return 1
			end
		else 
			begin
				rollback tran
				return -1
			end
end
go





-----------------------------------------------
-------AGREGAR TARJETA CREDITO-----------------
-----------------------------------------------

create proc sp_AgregarTarjetaCredito
@ci int,
@fechaVen smalldatetime,
@per bit,
@cat varchar (20),
@lim int

as

begin

if not exists (select * from cliente where ci = @ci)
	return 0

	declare @error int
	begin tran  
		insert Tarjeta (CI, FechaVencimiento, Personalizada) values (@ci, @fechaVen, @per)
		set @error = @@error
		
		declare @identity int
		set @identity = @@IDENTITY

		insert TCredito (NroT, Categoria, Limite) values (@identity, @cat, @lim)
		set @error = @@error

	if (@error = 0)
			begin
				commit tran
				return 1
			end
		else 
			begin
				rollback tran
				return -1
			end
end
go




---------------------------------------
------AGREGAR TARJETA DEBITO-----------
----------------------------------------

create proc sp_AgregarTarjetaDebito
@ced int,
@fechaVen smalldatetime,
@per bit,
@sal float,
@cantc int

as

begin

if not exists (select * from cliente where ci = @ced)
	return 0
	
	declare @error int

	begin tran  
		insert Tarjeta (CI, FechaVencimiento, Personalizada) values (@ced, @fechaVen, @per)
		set @error = @@error
		
		declare @identity int
		set @identity = @@IDENTITY --el identity toma el nrotarjeta recien generado para poder pasarselo a tdebito

		insert TDebito(NroT, Saldo, CantCuentas) values (@identity, @sal, @cantc)
		set @error = @@error

	if (@error = 0)
			begin
				commit tran
				return 1
			end
		else 
			begin
				rollback tran
				return -1
			end
end
go


---------------------------------------
------LISTAR CLIENTES-----------
--------------------------------------


create proc sp_ListarClientes
as

begin
	select cliente.*, Telefono.numero
	from Cliente
	join Telefono
	on cliente.ci = Telefono.CI
end

go




-------------------------------------------
--------AGREGAR COMPRA---------------------
-------------------------------------------

create proc sp_RealizarCompra
@nrotarjeta int,
@fechacompra smalldatetime,
@importe float

as

begin
	if not exists (select * from tarjeta where nrot = @nrotarjeta)
	return 0
	
		begin
			if (@importe >= (select saldo from tdebito where NroT = @nrotarjeta))
				return -1
			else if (@importe >= (select limite from tcredito where NroT = @nrotarjeta))
				return -2
			else
				declare @error int 
				begin tran 

					insert compra values (@nrotarjeta, @fechacompra, @importe)
					set @error = @@error

					if (@error = 0)
						begin
							commit tran
							return 1
						end
					else
						begin
							rollback tran
							return -3
						end			
		end
	
end

go




----------------------------------------------
--------LISTAR COMPRAS X CLIENTE--------------
----------------------------------------------

create proc sp_ListarComprasXCliente
@ci int

as

begin 
	select compra.*
	from Compra
	join tarjeta
	on compra.NroT = tarjeta.NroT
	where tarjeta.ci = @ci
end

go



create proc sp_ListarTarjetasCreditoVencidas
as
begin 
	select *  
	from Tarjeta 
	join TCredito 
	on tarjeta.NroT = Tcredito.nrot
	where FechaVencimiento < GETDATE() 
end
go


create proc sp_ListarTarjetasDebitoVencidas
as
begin 
	select *  
	from Tarjeta 
	join TDebito 
	on tarjeta.NroT = TDebito.NroT
	where FechaVencimiento < GETDATE() 
end
go

create proc sp_ListarTarjetaCredito
@ci int
as

begin
	select *
	from tarjeta
	join TCredito
	on tarjeta.NroT = TCredito.NroT
	where tarjeta.ci = @ci
end

go



create proc sp_ListarTarjetaDebito
@ci int

as

begin
	select *
	from tarjeta
	join TDebito
	on tarjeta.NroT = TDebito.NroT
	where tarjeta.ci = @ci
end

go




--DML
CREATE TABLE CATEGORIA (
    id_categoria INTEGER PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL
);

CREATE TABLE PRODUCTO (
    id_producto INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock INTEGER NOT NULL,
    id_categoria INTEGER,
    FOREIGN KEY(id_categoria) REFERENCES CATEGORIA(id_categoria)
);

CREATE TABLE CLIENTE (
    id_cliente INTEGER PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    ciudad VARCHAR(50),
    nivel VARCHAR(20)
);

CREATE TABLE METODO_PAGO (
    id_metodo INTEGER PRIMARY KEY,
    nombre VARCHAR(50)
);

CREATE TABLE ORDEN (
    id_orden INTEGER PRIMARY KEY,
    fecha DATE NOT NULL,
    total DECIMAL(10,2),
    id_cliente INTEGER,
    id_metodo INTEGER,
    FOREIGN KEY(id_cliente) REFERENCES CLIENTE(id_cliente),
    FOREIGN KEY(id_metodo) REFERENCES METODO_PAGO(id_metodo)
);

CREATE TABLE DETALLE_ORDEN (
    id_detalle INTEGER PRIMARY KEY,
    id_orden INTEGER,
    id_producto INTEGER,
    cantidad INTEGER,
    precio_unitario DECIMAL(10,2),
    FOREIGN KEY(id_orden) REFERENCES ORDEN(id_orden),
    FOREIGN KEY(id_producto) REFERENCES PRODUCTO(id_producto)
);

CREATE TABLE ENVIO (
    id_envio INTEGER PRIMARY KEY,
    id_orden INTEGER,
    paqueteria VARCHAR(50),
    estatus VARCHAR(20),
    FOREIGN KEY(id_orden) REFERENCES ORDEN(id_orden)
);

CREATE TABLE RESENA (
    id_resena INTEGER PRIMARY KEY,
    id_producto INTEGER,
    id_cliente INTEGER,
    calificacion INTEGER,
    comentario TEXT,
    FOREIGN KEY(id_producto) REFERENCES PRODUCTO(id_producto),
    FOREIGN KEY(id_cliente) REFERENCES CLIENTE(id_cliente)
);

--DDL
INSERT INTO CATEGORIA VALUES (1, 'Laptops'), (2, 'Smartphones'), (3, 'Accesorios');
INSERT INTO PRODUCTO VALUES (1, 'Laptop Dell', 1000, 50, 1), (2, 'MacBook Pro', 2000, 30, 1), (3, 'Lenovo Thinkpad', 900, 20, 1), (4, 'iPhone 13', 800, 100, 2), (5, 'Samsung S21', 750, 80, 2), (6, 'Mouse', 20, 200, 3), (7, 'Teclado', 50, 150, 3);
INSERT INTO CLIENTE VALUES (1, 'Juan Perez', 'juan@mail.com', 'CDMX', 'VIP'), (2, 'Ana Gomez', 'ana@mail.com', 'Monterrey', 'Regular'), (3, 'Carlos Ruiz', 'carlos@mail.com', 'Guadalajara', 'VIP');
INSERT INTO METODO_PAGO VALUES (1, 'Tarjeta'), (2, 'PayPal');
INSERT INTO ORDEN VALUES (1, '2025-01-01', 3900, 1, 1), (2, '2025-01-02', 800, 2, 2);
INSERT INTO DETALLE_ORDEN VALUES (1, 1, 1, 1, 1000), (2, 1, 2, 1, 2000), (3, 1, 3, 1, 900), (4, 2, 4, 1, 800);
INSERT INTO ENVIO VALUES (1, 1, 'DHL', 'Entregado'), (2, 2, 'FedEx', 'En Camino');
INSERT INTO RESENA VALUES (1, 1, 1, 5, 'Excelente');

--CONSULTAS SOLICITADAS
-- 1. Selección (sigma): Obtener productos con precio mayor a 500
SELECT * FROM PRODUCTO 
WHERE precio > 500;

-- 2. Proyección (pi): Mostrar solo los correos electrónicos de los clientes
SELECT email 
FROM CLIENTE;

-- 3. Unión (U): Lista unificada de clientes de CDMX y Monterrey
SELECT nombre FROM CLIENTE WHERE ciudad = 'CDMX'
UNION
SELECT nombre FROM CLIENTE WHERE ciudad = 'Monterrey';

-- 4. Diferencia (-): Productos que existen en catálogo pero NO tienen reseñas
-- (Equivalente en Álgebra Relacional: PRODUCTO - PRODUCTOS_RESEÑADOS)
SELECT id_producto, nombre 
FROM PRODUCTO
EXCEPT
SELECT P.id_producto, P.nombre 
FROM PRODUCTO P
JOIN RESENA R ON P.id_producto = R.id_producto;

-- 5. Intersección (∩): Clientes que han comprado Y tamibén han dejado reseña
SELECT id_cliente, nombre 
FROM CLIENTE 
WHERE id_cliente IN (SELECT id_cliente FROM ORDEN)
INTERSECT
SELECT id_cliente, nombre 
FROM CLIENTE 
WHERE id_cliente IN (SELECT id_cliente FROM RESENA);

-- 6. Reunión Natural (Inner Join): Detalle de orden mostrando nombres de productos
SELECT O.id_orden, P.nombre AS Producto, D.cantidad, D.precio_unitario
FROM DETALLE_ORDEN D
JOIN PRODUCTO P ON D.id_producto = P.id_producto
JOIN ORDEN O ON D.id_orden = O.id_orden;

-- 7. Left Outer Join: Mostrar TODOS los clientes y sus órdenes (incluso si son NULL)
SELECT C.nombre, O.id_orden, O.total
FROM CLIENTE C
LEFT JOIN ORDEN O ON C.id_cliente = O.id_cliente;

-- 8. Reunión de 3 Tablas: Quién compró, cuánto pagó y qué paquetería se usó
SELECT C.nombre, O.total, E.paqueteria
FROM CLIENTE C
JOIN ORDEN O ON C.id_cliente = O.id_cliente
JOIN ENVIO E ON O.id_orden = E.id_orden;

-- 9. Auto-Reunión (Self Join): Pares de productos diferentes que tienen el mismo precio
SELECT A.nombre AS Producto1, B.nombre AS Producto2, A.precio
FROM PRODUCTO A
JOIN PRODUCTO B ON A.precio = B.precio
WHERE A.id_producto < B.id_producto;

-- 10. Join con Agregación Implícita (Right Join simulado/Join simple): Totales por método de pago
SELECT MP.nombre AS Metodo, O.id_orden, O.total
FROM METODO_PAGO MP
JOIN ORDEN O ON MP.id_metodo = O.id_metodo;

-- 11. Count: Cuántas órdenes ha realizado cada cliente
SELECT C.nombre, COUNT(O.id_orden) AS Total_Ordenes
FROM CLIENTE C
LEFT JOIN ORDEN O ON C.id_cliente = O.id_cliente
GROUP BY C.id_cliente, C.nombre;

-- 12. Average: Precio promedio de los productos por categoría
SELECT C.nombre AS Categoria, AVG(P.precio) AS Precio_Promedio
FROM PRODUCTO P
JOIN CATEGORIA C ON P.id_categoria = C.id_categoria
GROUP BY C.nombre;

-- 13. Sum: Total de dinero ingresado desglosado por método de pago
SELECT MP.nombre, SUM(O.total) AS Total_Ingresos
FROM ORDEN O
JOIN METODO_PAGO MP ON O.id_metodo = MP.id_metodo
GROUP BY MP.nombre;

-- 14. Max: El producto más caro comprado en cada orden individual
SELECT id_orden, MAX(precio_unitario) AS Precio_Maximo_Item
FROM DETALLE_ORDEN
GROUP BY id_orden;

-- 15. Having: Categorías que tienen más de 2 productos registrados
SELECT id_categoria, COUNT(*) AS Cantidad_Productos
FROM PRODUCTO
GROUP BY id_categoria
HAVING COUNT(*) > 2;

-- 16. División: Clientes que han comprado TODOS los productos de la categoría 'Laptops' (id 1)
-- Lógica: No existe una Laptop que el cliente NO haya comprado.
SELECT C.nombre
FROM CLIENTE C
WHERE NOT EXISTS (
    SELECT P.id_producto
    FROM PRODUCTO P
    WHERE P.id_categoria = 1 -- Laptops
    EXCEPT
    SELECT D.id_producto
    FROM DETALLE_ORDEN D
    JOIN ORDEN O ON D.id_orden = O.id_orden
    WHERE O.id_cliente = C.id_cliente
);

-- 17. División: Clientes que han utilizado TODOS los métodos de pago disponibles
SELECT C.nombre
FROM CLIENTE C
WHERE NOT EXISTS (
    SELECT MP.id_metodo
    FROM METODO_PAGO MP
    EXCEPT
    SELECT O.id_metodo
    FROM ORDEN O
    WHERE O.id_cliente = C.id_cliente
);

-- 18. División: Órdenes que contienen TODOS los productos con stock bajo (< 30)
SELECT O.id_orden
FROM ORDEN O
WHERE NOT EXISTS (
    SELECT P.id_producto
    FROM PRODUCTO P
    WHERE P.stock < 30
    EXCEPT
    SELECT D.id_producto
    FROM DETALLE_ORDEN D
    WHERE D.id_orden = O.id_orden
);

-- 19. Universal: Categorías donde TODOS sus productos cuestan más de 500
-- Lógica: Seleccionar categoría donde NO EXISTE un producto barato.
SELECT C.nombre
FROM CATEGORIA C
WHERE NOT EXISTS (
    SELECT 1
    FROM PRODUCTO P
    WHERE P.id_categoria = C.id_categoria
    AND P.precio <= 500
);

-- 20. Universal: Clientes cuyas órdenes han sido TODAS enviadas por 'DHL'
-- Lógica: Seleccionar cliente donde NO EXISTE una orden con paquetería diferente a DHL.
SELECT C.nombre
FROM CLIENTE C
WHERE EXISTS (SELECT 1 FROM ORDEN WHERE id_cliente = C.id_cliente) -- Asegurar que tenga órdenes
AND NOT EXISTS (
    SELECT 1
    FROM ORDEN O
    JOIN ENVIO E ON O.id_orden = E.id_orden
    WHERE O.id_cliente = C.id_cliente
    AND E.paqueteria != 'DHL'
);
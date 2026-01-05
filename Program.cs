using System;
using System.Data;
using System.Threading;
using Npgsql;

namespace ProyectoIntegradorBD
{
    class Program
    {
        static string connectionString = "Host=db;Username=postgres;Password=postgres;Database=tienda_db";
        static NpgsqlConnection conexion;

        static void Main(string[] args)
        {
            Console.WriteLine("Iniciando aplicacion... Esperando a PostgreSQL...");
            EsperarBaseDeDatos();

            conexion = new NpgsqlConnection(connectionString);
            conexion.Open();

            LimpiarBaseDeDatos();

            InicializarBaseDeDatos();
            EjecutarConsultas();

            conexion.Close();
            Thread.Sleep(Timeout.Infinite);
        }

        static void EsperarBaseDeDatos()
        {
            int intentos = 0;
            while (intentos < 30)
            {
                try
                {
                    using (var conn = new NpgsqlConnection(connectionString))
                    {
                        conn.Open();
                        return; 
                    }
                }
                catch
                {
                    Thread.Sleep(2000); 
                    intentos++;
                    Console.Write(".");
                }
            }
            throw new Exception("No se pudo conectar a PostgreSQL despues de varios intentos.");
        }

        static void LimpiarBaseDeDatos()
        {
            string sql = @"
                DROP TABLE IF EXISTS RESENA;
                DROP TABLE IF EXISTS ENVIO;
                DROP TABLE IF EXISTS DETALLE_ORDEN;
                DROP TABLE IF EXISTS ORDEN;
                DROP TABLE IF EXISTS METODO_PAGO;
                DROP TABLE IF EXISTS CLIENTE;
                DROP TABLE IF EXISTS PRODUCTO;
                DROP TABLE IF EXISTS CATEGORIA;
            ";
            using (var cmd = new NpgsqlCommand(sql, conexion)) { cmd.ExecuteNonQuery(); }
        }

        static void InicializarBaseDeDatos()
        {
            string ddl = @"
                CREATE TABLE CATEGORIA (id_categoria INTEGER PRIMARY KEY, nombre VARCHAR(50));
                CREATE TABLE PRODUCTO (id_producto INTEGER PRIMARY KEY, nombre VARCHAR(100), precio DECIMAL(10,2), stock INTEGER, id_categoria INTEGER);
                CREATE TABLE CLIENTE (id_cliente INTEGER PRIMARY KEY, nombre VARCHAR(100), email VARCHAR(100), ciudad VARCHAR(50), nivel VARCHAR(20));
                CREATE TABLE METODO_PAGO (id_metodo INTEGER PRIMARY KEY, nombre VARCHAR(50));
                CREATE TABLE ORDEN (id_orden INTEGER PRIMARY KEY, fecha DATE, total DECIMAL(10,2), id_cliente INTEGER, id_metodo INTEGER);
                CREATE TABLE DETALLE_ORDEN (id_detalle INTEGER PRIMARY KEY, id_orden INTEGER, id_producto INTEGER, cantidad INTEGER, precio_unitario DECIMAL(10,2));
                CREATE TABLE ENVIO (id_envio INTEGER PRIMARY KEY, id_orden INTEGER, paqueteria VARCHAR(50), estatus VARCHAR(20));
                CREATE TABLE RESENA (id_resena INTEGER PRIMARY KEY, id_producto INTEGER, id_cliente INTEGER, calificacion INTEGER, comentario TEXT);
            ";

            string dml = @"
                INSERT INTO CATEGORIA VALUES (1, 'Laptops'), (2, 'Smartphones'), (3, 'Accesorios');
                INSERT INTO PRODUCTO VALUES (1, 'Laptop Dell', 1000, 50, 1), (2, 'MacBook Pro', 2000, 30, 1), (3, 'Lenovo Thinkpad', 900, 20, 1), (4, 'iPhone 13', 800, 100, 2), (5, 'Samsung S21', 750, 80, 2), (6, 'Mouse', 20, 200, 3), (7, 'Teclado', 50, 150, 3);
                INSERT INTO CLIENTE VALUES (1, 'Juan Perez', 'juan@mail.com', 'CDMX', 'VIP'), (2, 'Ana Gomez', 'ana@mail.com', 'Monterrey', 'Regular'), (3, 'Carlos Ruiz', 'carlos@mail.com', 'Guadalajara', 'VIP');
                INSERT INTO METODO_PAGO VALUES (1, 'Tarjeta'), (2, 'PayPal');
                INSERT INTO ORDEN VALUES (1, '2025-01-01', 3900, 1, 1), (2, '2025-01-02', 800, 2, 2);
                INSERT INTO DETALLE_ORDEN VALUES (1, 1, 1, 1, 1000), (2, 1, 2, 1, 2000), (3, 1, 3, 1, 900), (4, 2, 4, 1, 800);
                INSERT INTO ENVIO VALUES (1, 1, 'DHL', 'Entregado'), (2, 2, 'FedEx', 'En Camino');
                INSERT INTO RESENA VALUES (1, 1, 1, 5, 'Excelente');
            ";

            using (var cmd = new NpgsqlCommand(ddl, conexion)) { cmd.ExecuteNonQuery(); }
            using (var cmd = new NpgsqlCommand(dml, conexion)) { cmd.ExecuteNonQuery(); }
        }

        static void EjecutarConsultas()
        {
            string[] titulos = {
                "1. Seleccion (Precio > 500)",
                "2. Proyeccion (Emails)",
                "3. Union (CDMX U Monterrey)",
                "4. Diferencia (Productos sin resena)",
                "5. Interseccion (Clientes que compraron y reseñaron)",
                "6. Inner Join (Detalle con Nombres)",
                "7. Left Join (Clientes y Ordenes)",
                "8. Join 3 Tablas (Cliente-Envio-Orden)",
                "9. Self Join (Mismo precio)",
                "10. Join con Metodo Pago",
                "11. Count Ordenes por Cliente",
                "12. Promedio Precio por Categoria",
                "13. Suma Total por Metodo",
                "14. Max Precio en Orden",
                "15. Having (Categorias > 2 prod)",
                "16. DIVISION: Clientes compraron TODAS las Laptops",
                "17. DIVISION: Clientes usaron TODOS los metodos",
                "18. DIVISION: Ordenes con productos stock bajo",
                "19. UNIVERSAL: Cat donde todo producto > 500",
                "20. UNIVERSAL: Clientes con puro DHL"
            };

            string[] queries = {
                "SELECT * FROM PRODUCTO WHERE precio > 500",
                "SELECT email FROM CLIENTE",
                "SELECT nombre FROM CLIENTE WHERE ciudad = 'CDMX' UNION SELECT nombre FROM CLIENTE WHERE ciudad = 'Monterrey'",
                "SELECT id_producto, nombre FROM PRODUCTO EXCEPT SELECT P.id_producto, P.nombre FROM PRODUCTO P JOIN RESENA R ON P.id_producto = R.id_producto",
                "SELECT C.nombre FROM CLIENTE C WHERE C.id_cliente IN (SELECT id_cliente FROM ORDEN) INTERSECT SELECT C.nombre FROM CLIENTE C WHERE C.id_cliente IN (SELECT id_cliente FROM RESENA)",
                "SELECT P.nombre, D.cantidad, D.precio_unitario FROM DETALLE_ORDEN D JOIN PRODUCTO P ON D.id_producto = P.id_producto",
                "SELECT C.nombre, O.id_orden FROM CLIENTE C LEFT JOIN ORDEN O ON C.id_cliente = O.id_cliente",
                "SELECT C.nombre, E.paqueteria FROM CLIENTE C JOIN ORDEN O ON C.id_cliente = O.id_cliente JOIN ENVIO E ON O.id_orden = E.id_orden",
                "SELECT A.nombre, B.nombre, A.precio FROM PRODUCTO A, PRODUCTO B WHERE A.precio = B.precio AND A.id_producto < B.id_producto",
                "SELECT M.nombre, O.total FROM METODO_PAGO M JOIN ORDEN O ON M.id_metodo = O.id_metodo",
                "SELECT id_cliente, COUNT(*) as NumOrdenes FROM ORDEN GROUP BY id_cliente",
                "SELECT id_categoria, AVG(precio) as Promedio FROM PRODUCTO GROUP BY id_categoria",
                "SELECT id_metodo, SUM(total) as Ingresos FROM ORDEN GROUP BY id_metodo",
                "SELECT id_orden, MAX(precio_unitario) as MasCaro FROM DETALLE_ORDEN GROUP BY id_orden",
                "SELECT id_categoria, COUNT(*) FROM PRODUCTO GROUP BY id_categoria HAVING COUNT(*) > 2",
                "SELECT C.nombre FROM CLIENTE C WHERE NOT EXISTS (SELECT P.id_producto FROM PRODUCTO P WHERE P.id_categoria = 1 EXCEPT SELECT D.id_producto FROM DETALLE_ORDEN D JOIN ORDEN O ON D.id_orden = O.id_orden WHERE O.id_cliente = C.id_cliente)",
                "SELECT nombre FROM CLIENTE C WHERE NOT EXISTS (SELECT id_metodo FROM METODO_PAGO EXCEPT SELECT O.id_metodo FROM ORDEN O WHERE O.id_cliente = C.id_cliente)",
                "SELECT id_orden FROM ORDEN O WHERE NOT EXISTS (SELECT id_producto FROM PRODUCTO WHERE stock < 30 EXCEPT SELECT id_producto FROM DETALLE_ORDEN D WHERE D.id_orden = O.id_orden)",
                "SELECT id_categoria FROM CATEGORIA C WHERE NOT EXISTS (SELECT * FROM PRODUCTO P WHERE P.id_categoria = C.id_categoria AND P.precio <= 500)",
                "SELECT nombre FROM CLIENTE C WHERE NOT EXISTS (SELECT * FROM ORDEN O JOIN ENVIO E ON O.id_orden = E.id_orden WHERE O.id_cliente = C.id_cliente AND E.paqueteria != 'DHL')"
            };

            for (int i = 0; i < queries.Length; i++)
            {
                Console.WriteLine($"\n--- {titulos[i]} ---");
                Console.WriteLine(queries[i]);
                Console.WriteLine("--------------------------------------------------");

                try
                {
                    using (var cmd = new NpgsqlCommand(queries[i], conexion))
                    using (NpgsqlDataReader rdr = cmd.ExecuteReader())
                    {
                        for (int k = 0; k < rdr.FieldCount; k++) Console.Write($"{rdr.GetName(k)}\t");
                        Console.WriteLine("\n");

                        while (rdr.Read())
                        {
                            for (int k = 0; k < rdr.FieldCount; k++) Console.Write($"{rdr[k]}\t");
                            Console.WriteLine();
                        }
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("Error: " + ex.Message);
                }
            }
        }
    }
}
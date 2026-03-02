# Lo que quiere el Sr. Tito -- en palabras simples (v4)

> **Fecha:** 2026-03-02 (actualizado 2026-03-02 v4 -- decisiones finales incorporadas)

El Sr. Tito tiene una floreria (Amatista) y su problema principal es que **pierde plata porque no controla bien sus flores**. Esto es lo que necesita:

---

## 1. Saber el estado de sus flores en tiempo real ("Control de Camara")

Las flores son perecibles. Duran maximo 5 dias en camara. Hoy, la empleada dice "esta bien, esta bien" pero no hay forma de comprobarlo. Quiere un **semaforo automatico por dias exactos**:

- **Verde (dias 1-3)**: flor optima, se vende normal.
- **Amarillo (dia 4)**: cuidado, hay que moverla rapido.
- **Rojo (dias 5-7)**: ya no sirve para cliente normal. Solo para **funebres** (el velatorio dura un dia y se bota, no hay reclamo). Despues de eso, se descarta.
- **Negro / descarte (dia 8+)**: se bota.

El sistema debe mostrar **lo mas viejo primero** (FIFO visual) para que siempre se use antes lo que esta por vencer.

Ademas, cada insumo tiene un **codigo** y puede comprarse en **paquetes** (ej: caja de 100 tallos). El sistema registra "compre 1 caja de 100 rosas" y el stock sube en 100, no en 1.

**Dato importante confirmado:** Yolanda ingresa stock de **ambas formas** -- con Orden de Compra previa y tambien por entrada manual directa. Ambas fluyen al inventario y crean el lote con su fecha de entrada.

**Dato critico:** En una misma compra, las flores suelen venir de fechas distintas (ej: 6 rosas con 1 dia de corte + 6 rosas con 3 dias de corte). Esto pasa **varias veces por semana**. El sistema debe permitir registrar **multiples lotes** de una misma compra, cada uno con su fecha real.

---

## 2. Comprar con inteligencia, no a ciegas

Yolanda (la encargada de compras) va los martes, jueves y sabado al mayorista. La noche anterior llama para reservar flores frescas. Pero **no sabe con certeza que pedir** porque no tiene informacion del sistema.

Quiere una pantalla que le diga todo junto:
- "Te faltan 20 rosas rojas" (stock bajo)
- "Los claveles ya mermaron" (perecibles fuera de uso)
- "Las rosas amarillas se estan vendiendo mucho" (alta rotacion -- pide mas)
- "El pompom esta estancado" (baja rotacion -- no compres mas)

Y desde ahi misma, con un click, generar la **orden de compra pre-llenada** para enviarla al proveedor.

---

## 3. Que un arreglo floral descuente sus ingredientes (Receta / BOM)

Hoy un "producto" es un arreglo terminado. Pero ese arreglo esta hecho de **ingredientes individuales**: 5 rosas rojas + 3 follajes + 1 base. Cuando el arreglista termina de armar y marca "listo" en el sistema, **se descuentan automaticamente** cada ingrediente del stock. Eso hoy no pasa.

Hay dos tipos de insumo en el sistema:
- **Organico** (rosa, girasol, clavel, follaje): perecible, con semaforo de frescura.
- **No organico** (cinta, base, adorno, papel, maceta): duradero, sin caducidad.

**Flujo de la receta (confirmado):**
- La receta de un arreglo se define **directamente desde el formulario de crear/editar el producto** (no en una pantalla separada).
- Un arreglo puede crearse primero sin receta (para flujo rapido). La receta se puede agregar despues.
- **REGLA IMPORTANTE:** Si un arreglo no tiene receta definida, el sistema NO lo deja agregar a una venta. Mensaje claro: "Define la receta de este producto antes de venderlo."
- Los arreglos que ya existen en el sistema hoy siguen funcionando -- solo les falta que alguien les defina la receta cuando sea necesario.

Cada producto final tiene una **receta default** permanente: "El Ramo Primavera lleva 5 rosas rojas + 3 follajes + 1 envoltorio". Esa receta nunca cambia.

Si un cliente pide una variacion ("quiero 3 rojas y 2 blancas en vez de 5 rojas"), eso es una **personalizacion del pedido**:
- Se anota en ese pedido especifico sin tocar la receta base del producto.
- La vendedora puede escribir una **nota libre** para el arreglista (ej: "usar moño azul marino exactamente").
- Al armar, el arreglista descuenta los ingredientes ajustados, no los del default.

---

## 4. Tres niveles de precio

- **Persona natural**: precio normal (ej: rosa a S/7).
- **Corporativo**: precio especial para **empresas con RUC** que compran 5+ unidades (ej: rosa a S/3-4). Este precio esta fijo en el sistema y no se le da a cualquiera que pida descuento.
- **Con recargo de personalizacion**: cuando un cliente pide una variacion de la receta, se agrega un cargo extra. Este cargo **no es el costo exacto de los insumos** -- es un cargo por el servicio de personalizacion que la vendedora define. El sistema muestra el costo estimado de los cambios como referencia para que la vendedora sepa cuanto cobrar.

Ademas, **descuentos por cantidad** configurables: si alguien compra mas de X unidades, se aplica automaticamente un descuento Y%.

**Diferencia clave:** El precio corporativo lo tiene la empresa por ser empresa (con RUC). El descuento por cantidad lo puede tener cualquiera que compre en cantidad. El recargo de personalizacion es cuando el cliente pide algo diferente al arreglo estandar.

---

## 5. Cotizaciones formales y profesionales

Quiere generar una cotizacion bonita con:
- Logo Amatista
- Datos del cliente (nombre, empresa, RUC si aplica)
- Productos con precios
- Condiciones comerciales (notas, forma de pago)
- Fecha de emision y fecha de validez

Y que se pueda **enviar por correo al cliente** directo desde el sistema. El Sr. Tito (gerencia) da el **"check" de aprobacion** antes de que se envie.

---

## 6. Vender a empresas (corporativo)

Hay un mercado sin explotar: empresas en Miraflores, San Isidro que necesitan flores para:
- Funebres (consumen mucho -- es el dia del velatorio y se bota)
- Cumpleanos de ejecutivos y empleados
- Aniversarios de empresa
- Dia de la Madre, Dia del Secretario
- Regalos a proveedores

Quiere un flujo de: encontrar empresa → enviar catalogo → cotizar con precio corporativo → cerrar venta.

---

## 7. Campanas de temporada

Cuando es San Valentin o Dia de la Madre, ciertos productos entran en descuento. Quiere una seccion donde se defina: "estos 15 productos tienen 20% de descuento del 1 al 14 de febrero" y ese descuento se aplique **automaticamente** en el POS y en las cotizaciones.

---

## En una frase

> El Sr. Tito quiere **saber el estado real de sus flores** (semaforo por dias, lo mas viejo primero, multi-lote cuando las flores vienen de fechas distintas), **comprar solo lo necesario** (lista inteligente con orden de compra generada desde el sistema), **que el sistema sepa que un arreglo consume ingredientes** (receta que se define en el formulario del producto, que bloquea la venta si no esta definida, y que descuenta stock al producir), **vender a empresas con precios especiales** (corporativo vs natural, mas recargo cuando el cliente personaliza el arreglo) y **tener campanas de descuento por temporada**.

---

## Dato tecnico importante

Hoy el sistema **NO descuenta stock al vender**. El negocio opera "produce bajo pedido": se vende primero, se arma despues. El descuento de ingredientes (cuando se implemente) ocurrira cuando el arreglista marca el pedido como "listo" en el Kanban de produccion, no al momento de la venta.

Ya existen piezas utiles que se reutilizan (no se empieza de cero): sistema de lotes con FIFO, alertas de stock bajo, rotacion ABC, modulo de compras completo, Kanban de produccion, PDF de ventas, envio de email para comprobantes.

**Los insumos organicos ya tienen `requiere_lote=True`** en la base de datos -- la trazabilidad de lotes ya funciona para ellos. Solo hay que agregar `fecha_entrada` y `estado_frescura` al lote para que el semaforo funcione.

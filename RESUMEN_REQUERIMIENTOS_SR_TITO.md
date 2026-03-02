# Lo que quiere el Sr. Tito — en palabras simples

El Sr. Tito tiene una floristería (Amatista) y su problema principal es que **pierde plata porque no controla bien sus flores**. Esto es lo que necesita:

---

## 1. Saber el estado de sus flores en tiempo real

Las flores son perecibles. Duran máximo 5 días en cámara. Hoy, la chica que trabaja ahí dice "está bien, está bien" pero no hay forma de comprobarlo. Quiere un **semáforo automático**:
- **Verde** (1-3 días): flor óptima, se vende normal.
- **Amarillo** (4 días): cuidado, hay que moverla rápido.
- **Rojo** (5+ días): ya no sirve para cliente normal. Solo para **fúnebres** (porque el muertito está un día y se bota, no hay reclamo). Después de eso, se descarta.

## 2. Comprar con inteligencia, no a ciegas

Yolanda (la encargada de compras) va los martes, jueves y sábado al mayorista. La noche anterior llama para reservar flores frescas. Pero **no sabe con certeza qué pedir** porque no tiene información del sistema. Entonces pide de más (y se merma) o pide de menos (y le falta). Quiere que el sistema le diga: "te faltan 20 rosas rojas, 10 girasoles, los claveles están estancados no compres más".

## 3. Que un arreglo floral descuente sus ingredientes

Hoy un "producto" es un arreglo terminado. Pero un arreglo está hecho de **ítems individuales**: 5 rosas rojas + 3 follajes + 1 base. Cuando se vende ese arreglo, el sistema debería **descontar automáticamente** cada ingrediente del stock. Eso hoy no pasa.

## 4. Personalización de arreglos

Un cliente puede decir: "quiero ese arreglo pero con 2 rosas rojas y 2 rosadas en vez de 4 rojas". Eso es un **arreglo personalizado** y tiene otro precio (más caro que el estándar). El sistema debe soportar eso.

## 5. Tres tipos de precio

- **Persona natural**: precio normal (rosa a S/7).
- **Corporativo**: precio especial para empresas con RUC que compran 5+ unidades (rosa a S/3-4). Este precio está "seteado" y no se le da a cualquiera.
- **Personalizado**: precio calculado según los ingredientes que el cliente eligió.
- Además, **descuentos por cantidad** configurables (si compras más de X, te bajan Y%).

## 6. Cotizaciones formales y profesionales

Quiere poder generar una cotización bonita con logo, datos del cliente, productos, condiciones comerciales y enviarla por correo. Para que cuando llamen a una empresa digan: "Somos Amatista, le mandamos nuestra cotización". Que la gerencia le dé un "check" de aprobación antes de enviar.

## 7. Vender a empresas (corporativo)

Hay un mercado gigante sin explotar: empresas cercanas (Miraflores, San Isidro) que necesitan flores para:
- **Fúnebres** (consumen mucho)
- Cumpleaños de ejecutivos y empleados
- Aniversarios de empresa
- Día de la Madre, Día de la Secretaria
- Regalos a sus proveedores

Quiere un flujo de: encontrar empresa → enviar catálogo → cotizar → cerrar venta. Un mini-CRM.

## 8. Campañas de temporada

Cuando es San Valentín o Día de la Madre, ciertos productos entran en descuento. Quiere una sección donde marque: "estos 15 productos tienen 20% de descuento del 1 al 14 de febrero" y que eso se aplique automáticamente en el POS.

---

## En una frase

> El Sr. Tito quiere **dejar de perder flores por no saber su estado**, **comprar solo lo necesario**, **que el sistema sepa que un arreglo consume ingredientes**, **vender a empresas con precios especiales** y **tener campañas de descuento por temporada**.

Todo gira alrededor de un concepto central: **las flores son perecibles y cada día que pasa valen menos**, entonces necesita un sistema que le diga la verdad sobre su inventario, no lo que "la chica dice que está bien".

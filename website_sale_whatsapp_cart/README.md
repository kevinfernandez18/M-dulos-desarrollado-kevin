# Website Sale Cart WhatsApp Sender (Odoo 17 Community)

## Qué hace
Este addon agrega un botón en `/shop/cart` para abrir WhatsApp con el contenido del carrito y enviarlo a un número fijo configurable por sitio web.

## Instalación
1. Copiar el módulo `website_sale_whatsapp_cart` dentro de tu ruta de addons.
2. Reiniciar Odoo.
3. Activar modo desarrollador (opcional).
4. Ir a **Apps** y actualizar la lista de aplicaciones.
5. Instalar **Website Sale Cart WhatsApp Sender**.

## Configuración
1. Ir a **Sitio web → Configuración → Ajustes**.
2. Seleccionar el website correspondiente (si manejas multi-website).
3. En el bloque **WhatsApp para carrito**, completar **WhatsApp Sales Number**.
   - Se permite `+51XXXXXXXXX` o `51XXXXXXXXX`.
   - El módulo normaliza a solo dígitos para construir `wa.me`.

## Uso
1. Ir a `/shop/cart` con productos en el carrito.
2. Clic en **Enviar carrito por WhatsApp**.
3. Se abrirá: `https://wa.me/<PHONE>?text=<ENCODED_TEXT>`

## Casos borde implementados
- Carrito vacío: se muestra aviso **Carrito vacío.** y no se genera enlace.
- Número no configurado: no abre WhatsApp y muestra aviso **Configure el número de WhatsApp en Ajustes**.

## Checklist de pruebas manuales
- [ ] Configurar número con formato `+51999999999` y guardar.
- [ ] Verificar que el botón aparece en `/shop/cart` cuando hay líneas.
- [ ] Verificar que abre `wa.me` con teléfono normalizado (solo dígitos).
- [ ] Confirmar que el mensaje incluye: saludo, líneas, total, moneda y URL del carrito.
- [ ] Cambiar visualización de impuestos del website y verificar que precios/subtotales/total respetan la vista con/sin impuestos.
- [ ] Dejar el número vacío y verificar que aparece el aviso de configuración.
- [ ] Vaciar carrito y verificar aviso **Carrito vacío.**
- [ ] En multi-website, configurar diferentes números por website y validar comportamiento independiente.

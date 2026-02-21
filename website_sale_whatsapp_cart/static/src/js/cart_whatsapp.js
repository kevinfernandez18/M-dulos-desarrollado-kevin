/** @odoo-module **/

import publicWidget from "@web/legacy/js/public/public_widget";

publicWidget.registry.CartWhatsappWarning = publicWidget.Widget.extend({
    selector: ".o_cart_whatsapp_missing_config",
    events: {
        click: "_onClick",
    },

    _onClick(ev) {
        ev.preventDefault();
        const message = ev.currentTarget.dataset.whatsappWarning || "Configure el número de WhatsApp en Ajustes";
        window.alert(message);
    },
});

import logging
from urllib.parse import quote_plus

from odoo import _, models
from odoo.http import request
from odoo.tools.misc import format_amount

_logger = logging.getLogger(__name__)


class SaleOrder(models.Model):
    _inherit = "sale.order"

    def _is_tax_included_display(self):
        self.ensure_one()
        website = self.website_id
        return website.show_line_subtotals_tax_selection == "tax_included"

    def _get_whatsapp_cart_message(self):
        self.ensure_one()
        if not self.order_line:
            return _("Hola, mi carrito está vacío.")

        show_tax_included = self._is_tax_included_display()
        currency = self.currency_id

        lines = [_("Hola, quiero consultar este carrito:"), ""]
        lines.append(_("Productos:"))

        for line in self.order_line:
            unit_price = line.price_reduce_taxinc if show_tax_included else line.price_reduce_taxexcl
            subtotal = line.price_total if show_tax_included else line.price_subtotal
            lines.append(
                _("- %(name)s | Cant: %(qty)s | P.Unit: %(unit)s | Subtotal: %(subtotal)s")
                % {
                    "name": line.product_id.display_name,
                    "qty": line.product_uom_qty,
                    "unit": format_amount(self.env, unit_price, currency),
                    "subtotal": format_amount(self.env, subtotal, currency),
                }
            )

        total = self.amount_total if show_tax_included else self.amount_untaxed
        lines.extend(
            [
                "",
                _("Total: %(total)s") % {"total": format_amount(self.env, total, currency)},
                _("Moneda: %(currency)s") % {"currency": currency.name},
            ]
        )

        if request and request.httprequest:
            lines.append(_("Carrito: %(url)s") % {"url": request.httprequest.url})

        return "\n".join(lines)

    def _get_whatsapp_wa_link(self):
        self.ensure_one()
        phone = self.website_id._get_whatsapp_sales_phone_digits()
        if not phone:
            _logger.info("WhatsApp cart link requested without configured phone for website %s", self.website_id.id)
            return ""
        text = quote_plus(self._get_whatsapp_cart_message())
        return f"https://wa.me/{phone}?text={text}"

    def _whatsapp_phone_configured(self):
        self.ensure_one()
        return bool(self.website_id._get_whatsapp_sales_phone_digits())

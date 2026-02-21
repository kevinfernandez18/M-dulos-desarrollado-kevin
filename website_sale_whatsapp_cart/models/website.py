import re

from odoo import fields, models


class Website(models.Model):
    _inherit = "website"

    whatsapp_sales_phone = fields.Char(
        string="WhatsApp Sales Number",
        help="Fixed WhatsApp destination used by the cart button.",
    )

    def _get_whatsapp_sales_phone_digits(self):
        """Return a wa.me-compatible phone (digits only)."""
        self.ensure_one()
        return re.sub(r"\D", "", self.whatsapp_sales_phone or "")

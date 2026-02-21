import re

from odoo import _, api, fields, models
from odoo.exceptions import ValidationError


class ResConfigSettings(models.TransientModel):
    _inherit = "res.config.settings"

    whatsapp_sales_phone = fields.Char(
        string="WhatsApp Sales Number",
        related="website_id.whatsapp_sales_phone",
        readonly=False,
        help="Fixed WhatsApp number that will receive cart messages. Use +51XXXXXXXXX or 51XXXXXXXXX.",
    )

    @api.constrains("whatsapp_sales_phone")
    def _check_whatsapp_sales_phone(self):
        for rec in self:
            if not rec.whatsapp_sales_phone:
                continue
            digits = re.sub(r"\D", "", rec.whatsapp_sales_phone)
            if not digits:
                raise ValidationError(_("The WhatsApp number must contain digits."))
            rec.whatsapp_sales_phone = digits

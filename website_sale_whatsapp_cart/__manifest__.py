{
    "name": "Website Sale Cart WhatsApp Sender",
    "summary": "Send eCommerce cart content to a fixed WhatsApp number.",
    "version": "17.0.1.0.0",
    "category": "Website/eCommerce",
    "author": "Custom",
    "license": "LGPL-3",
    "depends": ["website_sale"],
    "data": [
        "views/res_config_settings_views.xml",
        "views/website_sale_cart_templates.xml",
    ],
    "assets": {
        "web.assets_frontend": [
            "website_sale_whatsapp_cart/static/src/js/cart_whatsapp.js",
        ],
    },
    "installable": True,
    "application": False,
}

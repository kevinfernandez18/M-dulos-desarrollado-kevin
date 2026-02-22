{
    "name": "Executive Dashboard",
    "version": "19.0.1.0.0",
    "summary": "Panel ejecutivo para dueños y gerentes",
    "category": "Accounting",
    "author": "Custom",
    "license": "LGPL-3",
    "depends": ["account", "sale", "web"],
    "data": [
        "security/security.xml",
        "security/ir.model.access.csv",
        "views/executive_dashboard_views.xml",
    ],
    "assets": {
        "web.assets_backend": [
            "executive_dashboard/static/src/css/executive_dashboard.css",
        ],
    },
    "installable": True,
    "application": True,
}

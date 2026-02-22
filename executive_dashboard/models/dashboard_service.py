from datetime import date, timedelta

from odoo import _, api, fields, models
from odoo.tools import format_amount


class ExecutiveDashboard(models.TransientModel):
    _name = "executive.dashboard"
    _description = "Executive Dashboard"

    period_type = fields.Selection(
        [
            ("today", "Hoy"),
            ("month", "Este mes"),
            ("year", "Este año"),
            ("custom", "Rango personalizado"),
        ],
        default="today",
        required=True,
    )
    date_from = fields.Date(string="Desde")
    date_to = fields.Date(string="Hasta")
    company_id = fields.Many2one("res.company", required=True, default=lambda self: self.env.company)
    currency_id = fields.Many2one(related="company_id.currency_id")

    sales_amount = fields.Monetary(string="Ventas")
    sales_count = fields.Integer(string="# Documentos")
    avg_ticket = fields.Monetary(string="Ticket Promedio")

    ar_pending = fields.Monetary(string="CXC Pendiente")
    ar_overdue = fields.Monetary(string="CXC Vencido")
    ar_due = fields.Monetary(string="CXC Por Vencer")

    ap_pending = fields.Monetary(string="CXP Pendiente")
    ap_overdue = fields.Monetary(string="CXP Vencido")
    ap_due = fields.Monetary(string="CXP Por Vencer")

    cash_bank_balance = fields.Monetary(string="Caja y Bancos")

    income_amount = fields.Monetary(string="Ingresos")
    cogs_amount = fields.Monetary(string="COGS")
    expense_amount = fields.Monetary(string="Gastos")
    gross_profit = fields.Monetary(string="Utilidad Bruta")
    net_profit = fields.Monetary(string="Utilidad Neta")

    sales_amount_prev = fields.Monetary(string="Ventas período anterior")
    net_profit_prev = fields.Monetary(string="Utilidad neta período anterior")

    overdue_ar_count = fields.Integer(string="Facturas CXC Vencidas")
    overdue_ap_count = fields.Integer(string="Facturas CXP Vencidas")
    critical_stock_count = fields.Integer(string="Productos con stock crítico")
    show_stock_alert = fields.Boolean(string="Mostrar alerta de stock")

    top_products_html = fields.Html(sanitize=False)
    bottom_products_html = fields.Html(sanitize=False)
    chart_sales_daily_html = fields.Html(sanitize=False)
    chart_net_daily_html = fields.Html(sanitize=False)
    chart_income_expense_monthly_html = fields.Html(sanitize=False)
    chart_ar_aging_html = fields.Html(sanitize=False)

    @api.model
    def default_get(self, fields_list):
        vals = super().default_get(fields_list)
        start, end = self._get_period_range(vals.get("period_type", "today"), vals.get("date_from"), vals.get("date_to"))
        vals.update({"date_from": start, "date_to": end})
        return vals

    @api.onchange("period_type", "date_from", "date_to", "company_id")
    def _onchange_period(self):
        for rec in self:
            if rec.period_type != "custom":
                rec.date_from, rec.date_to = rec._get_period_range(rec.period_type)
            rec._compute_dashboard_values()

    def action_refresh(self):
        self._compute_dashboard_values()
        return {
            "type": "ir.actions.act_window",
            "name": _("Executive Dashboard"),
            "res_model": "executive.dashboard",
            "res_id": self.id,
            "view_mode": "form",
            "target": "current",
        }

    def _compute_dashboard_values(self):
        self.ensure_one()
        date_from, date_to = self._get_period_range(self.period_type, self.date_from, self.date_to)
        prev_from, prev_to = self._get_previous_range(date_from, date_to)

        self._compute_sales(date_from, date_to, prev_from, prev_to)
        self._compute_receivable_payable(date_from, date_to)
        self._compute_cash_bank(date_to)
        self._compute_pnl(date_from, date_to, prev_from, prev_to)
        self._compute_alerts()
        self._compute_product_rankings(date_from, date_to)
        self._compute_charts(date_from, date_to)

    def _base_move_domain(self):
        self.ensure_one()
        return [("state", "=", "posted"), ("company_id", "=", self.company_id.id)]

    def _compute_sales(self, date_from, date_to, prev_from, prev_to):
        self.ensure_one()
        domain = self._base_move_domain() + [
            ("move_type", "=", "out_invoice"),
            ("invoice_date", ">=", date_from),
            ("invoice_date", "<=", date_to),
        ]
        grouped = self.env["account.move"].read_group(domain, ["amount_total_signed:sum", "id:count"], [])
        data = grouped[0] if grouped else {}
        sales_amount = data.get("amount_total_signed_sum", 0.0)
        sales_count = data.get("id_count", 0)

        prev_domain = self._base_move_domain() + [
            ("move_type", "=", "out_invoice"),
            ("invoice_date", ">=", prev_from),
            ("invoice_date", "<=", prev_to),
        ]
        prev_group = self.env["account.move"].read_group(prev_domain, ["amount_total_signed:sum"], [])

        self.sales_amount = sales_amount
        self.sales_count = sales_count
        self.avg_ticket = sales_amount / sales_count if sales_count else 0.0
        self.sales_amount_prev = prev_group[0].get("amount_total_signed_sum", 0.0) if prev_group else 0.0

    def _compute_receivable_payable(self, date_from, date_to):
        self.ensure_one()
        today = fields.Date.context_today(self)

        def _compute_for_types(move_types):
            base_domain = self._base_move_domain() + [
                ("move_type", "in", move_types),
                ("invoice_date", ">=", date_from),
                ("invoice_date", "<=", date_to),
                ("payment_state", "in", ["not_paid", "partial"]),
            ]
            pending = self.env["account.move"].read_group(base_domain, ["amount_residual_signed:sum"], [])
            overdue = self.env["account.move"].read_group(
                base_domain + [("invoice_date_due", "<", today)], ["amount_residual_signed:sum"], []
            )
            due = self.env["account.move"].read_group(
                base_domain + [("invoice_date_due", ">=", today)], ["amount_residual_signed:sum"], []
            )
            return (
                pending[0].get("amount_residual_signed_sum", 0.0) if pending else 0.0,
                overdue[0].get("amount_residual_signed_sum", 0.0) if overdue else 0.0,
                due[0].get("amount_residual_signed_sum", 0.0) if due else 0.0,
            )

        self.ar_pending, self.ar_overdue, self.ar_due = _compute_for_types(["out_invoice", "out_refund"])
        self.ap_pending, self.ap_overdue, self.ap_due = _compute_for_types(["in_invoice", "in_refund"])

    def _compute_cash_bank(self, date_to):
        self.ensure_one()
        domain = [
            ("company_id", "=", self.company_id.id),
            ("parent_state", "=", "posted"),
            ("date", "<=", date_to),
            ("account_id.account_type", "=", "asset_cash"),
        ]
        grouped = self.env["account.move.line"].read_group(domain, ["balance:sum"], [])
        self.cash_bank_balance = grouped[0].get("balance_sum", 0.0) if grouped else 0.0

    def _compute_pnl(self, date_from, date_to, prev_from, prev_to):
        self.ensure_one()

        def _calc_range(start, end):
            domain = [
                ("company_id", "=", self.company_id.id),
                ("parent_state", "=", "posted"),
                ("date", ">=", start),
                ("date", "<=", end),
                ("account_id.account_type", "in", ["income", "income_other", "expense", "expense_depreciation", "expense_direct_cost"]),
            ]
            groups = self.env["account.move.line"].read_group(domain, ["balance:sum"], ["account_id.account_type"])
            totals = {g["account_id.account_type"]: g.get("balance_sum", 0.0) for g in groups}
            income = -(totals.get("income", 0.0) + totals.get("income_other", 0.0))
            cogs = totals.get("expense_direct_cost", 0.0)
            expense = totals.get("expense", 0.0) + totals.get("expense_depreciation", 0.0)
            gross = income - cogs
            net = gross - expense
            return income, cogs, expense, gross, net

        income, cogs, expense, gross, net = _calc_range(date_from, date_to)
        self.income_amount = income
        self.cogs_amount = cogs
        self.expense_amount = expense
        self.gross_profit = gross
        self.net_profit = net

        _, _, _, _, prev_net = _calc_range(prev_from, prev_to)
        self.net_profit_prev = prev_net

    def _compute_alerts(self):
        self.ensure_one()
        today = fields.Date.context_today(self)

        ar_domain = self._base_move_domain() + [
            ("move_type", "in", ["out_invoice", "out_refund"]),
            ("payment_state", "in", ["not_paid", "partial"]),
            ("invoice_date_due", "<", today),
        ]
        ap_domain = self._base_move_domain() + [
            ("move_type", "in", ["in_invoice", "in_refund"]),
            ("payment_state", "in", ["not_paid", "partial"]),
            ("invoice_date_due", "<", today),
        ]
        self.overdue_ar_count = self.env["account.move"].search_count(ar_domain)
        self.overdue_ap_count = self.env["account.move"].search_count(ap_domain)

        stock_installed = bool(self.env["ir.module.module"].sudo().search_count([("name", "=", "stock"), ("state", "=", "installed")]))
        self.show_stock_alert = stock_installed
        if stock_installed:
            self.critical_stock_count = self.env["product.product"].search_count(
                [("sale_ok", "=", True), ("qty_available", "<=", 0), ("company_id", "in", [False, self.company_id.id])]
            )
        else:
            self.critical_stock_count = 0

    def _compute_product_rankings(self, date_from, date_to):
        self.ensure_one()
        cr = self.env.cr
        query = """
            SELECT
                pp.id,
                pt.name,
                COALESCE(SUM(aml.price_subtotal), 0.0) AS amount,
                COALESCE(SUM(aml.quantity), 0.0) AS qty
            FROM product_product pp
            JOIN product_template pt ON pt.id = pp.product_tmpl_id
            LEFT JOIN account_move_line aml
                ON aml.product_id = pp.id
                AND aml.company_id = %s
                AND aml.display_type IS NULL
                AND aml.parent_state = 'posted'
                AND aml.date >= %s
                AND aml.date <= %s
            LEFT JOIN account_move am ON am.id = aml.move_id AND am.move_type = 'out_invoice'
            WHERE pt.sale_ok = TRUE
            GROUP BY pp.id, pt.name
        """
        cr.execute(query, (self.company_id.id, date_from, date_to))
        rows = cr.dictfetchall()

        ranked_desc = sorted(rows, key=lambda r: r["amount"], reverse=True)[:5]
        ranked_asc = sorted(rows, key=lambda r: r["amount"])[:5]

        self.top_products_html = self._render_product_table(ranked_desc)
        self.bottom_products_html = self._render_product_table(ranked_asc)

    def _compute_charts(self, date_from, date_to):
        self.ensure_one()
        self.chart_sales_daily_html = self._chart_sales_daily(date_from, date_to)
        self.chart_net_daily_html = self._chart_net_daily(date_from, date_to)
        self.chart_income_expense_monthly_html = self._chart_income_expense_monthly(date_to)
        self.chart_ar_aging_html = self._chart_ar_aging()

    def _render_product_table(self, rows):
        headers = "<tr><th>Producto</th><th>Monto</th><th>Cantidad</th></tr>"
        body = "".join(
            f"<tr><td>{r['name']}</td><td>{format_amount(self.env, r['amount'], self.currency_id)}</td><td>{r['qty']:.2f}</td></tr>"
            for r in rows
        )
        return f"<table class='table table-sm table-striped'>{headers}{body}</table>"

    def _chart_sales_daily(self, date_from, date_to):
        start = max(date_from, date_to - timedelta(days=29))
        rows = self.env["account.move"].read_group(
            self._base_move_domain()
            + [("move_type", "=", "out_invoice"), ("invoice_date", ">=", start), ("invoice_date", "<=", date_to)],
            ["amount_total_signed:sum"],
            ["invoice_date:day"],
            orderby="invoice_date:day",
        )
        data = [(r["invoice_date:day"], r.get("amount_total_signed_sum", 0.0)) for r in rows]
        return self._render_bars(data, "Ventas por día (30 días)")

    def _chart_net_daily(self, date_from, date_to):
        start = max(date_from, date_to - timedelta(days=29))
        rows = self.env["account.move.line"].read_group(
            [
                ("company_id", "=", self.company_id.id),
                ("parent_state", "=", "posted"),
                ("date", ">=", start),
                ("date", "<=", date_to),
                ("account_id.account_type", "in", ["income", "income_other", "expense", "expense_depreciation", "expense_direct_cost"]),
            ],
            ["balance:sum"],
            ["date:day", "account_id.account_type"],
            orderby="date:day",
        )
        by_day = {}
        for r in rows:
            day = r["date:day"]
            t = r["account_id.account_type"]
            by_day.setdefault(day, {"income": 0.0, "cogs": 0.0, "expense": 0.0})
            val = r.get("balance_sum", 0.0)
            if t in ("income", "income_other"):
                by_day[day]["income"] += -val
            elif t == "expense_direct_cost":
                by_day[day]["cogs"] += val
            else:
                by_day[day]["expense"] += val
        data = []
        for day, vals in sorted(by_day.items()):
            data.append((day, vals["income"] - vals["cogs"] - vals["expense"]))
        return self._render_bars(data, "Utilidad neta por día (30 días)")

    def _chart_income_expense_monthly(self, date_to):
        start = date_to.replace(day=1) - timedelta(days=365)
        rows = self.env["account.move.line"].read_group(
            [
                ("company_id", "=", self.company_id.id),
                ("parent_state", "=", "posted"),
                ("date", ">=", start),
                ("date", "<=", date_to),
                ("account_id.account_type", "in", ["income", "income_other", "expense", "expense_depreciation"]),
            ],
            ["balance:sum"],
            ["date:month", "account_id.account_type"],
            orderby="date:month",
        )
        monthly = {}
        for r in rows:
            month = r["date:month"]
            t = r["account_id.account_type"]
            monthly.setdefault(month, {"income": 0.0, "expense": 0.0})
            amount = r.get("balance_sum", 0.0)
            if t in ("income", "income_other"):
                monthly[month]["income"] += -amount
            else:
                monthly[month]["expense"] += amount
        data = [(m, v["income"] - v["expense"]) for m, v in sorted(monthly.items())]
        return self._render_bars(data, "Ingresos vs Gastos por mes (12 meses)")

    def _chart_ar_aging(self):
        self.ensure_one()
        today = fields.Date.context_today(self)
        buckets = [(0, 30), (31, 60), (61, 90), (91, 9999)]
        values = []
        for low, high in buckets:
            min_due = today - timedelta(days=high)
            max_due = today - timedelta(days=low)
            domain = self._base_move_domain() + [
                ("move_type", "in", ["out_invoice", "out_refund"]),
                ("payment_state", "in", ["not_paid", "partial"]),
                ("invoice_date_due", ">=", min_due),
                ("invoice_date_due", "<=", max_due),
            ]
            grouped = self.env["account.move"].read_group(domain, ["amount_residual_signed:sum"], [])
            amount = grouped[0].get("amount_residual_signed_sum", 0.0) if grouped else 0.0
            label = f"{low}-{high if high < 9999 else '+'}"
            values.append((label, amount))
        return self._render_bars(values, "Antigüedad CXC")

    def _render_bars(self, rows, title):
        if not rows:
            return f"<h5>{title}</h5><p>Sin datos para el período.</p>"
        max_val = max(abs(v) for _, v in rows) or 1
        bars = ""
        for label, value in rows:
            width = int((abs(value) / max_val) * 100)
            bars += (
                "<div class='ed-bar-row'>"
                f"<span class='ed-label'>{label}</span>"
                f"<div class='ed-bar'><span style='width:{width}%;'></span></div>"
                f"<span class='ed-value'>{format_amount(self.env, value, self.currency_id)}</span>"
                "</div>"
            )
        return f"<h5>{title}</h5><div class='ed-bars'>{bars}</div>"

    @api.model
    def _get_period_range(self, period_type, date_from=None, date_to=None):
        today = fields.Date.context_today(self)
        if period_type == "today":
            return today, today
        if period_type == "month":
            start = today.replace(day=1)
            return start, today
        if period_type == "year":
            start = today.replace(month=1, day=1)
            return start, today
        if period_type == "custom" and date_from and date_to:
            return date_from, date_to
        return today, today

    @api.model
    def _get_previous_range(self, current_from, current_to):
        days = (current_to - current_from).days + 1
        prev_to = current_from - timedelta(days=1)
        prev_from = prev_to - timedelta(days=days - 1)
        return prev_from, prev_to

    def _prepare_action(self, name, model, domain):
        self.ensure_one()
        return {
            "name": name,
            "type": "ir.actions.act_window",
            "res_model": model,
            "view_mode": "list,form",
            "domain": domain,
            "context": {"search_default_company_id": self.company_id.id},
        }

    def action_view_overdue_receivables(self):
        today = fields.Date.context_today(self)
        domain = self._base_move_domain() + [
            ("move_type", "in", ["out_invoice", "out_refund"]),
            ("payment_state", "in", ["not_paid", "partial"]),
            ("invoice_date_due", "<", today),
        ]
        return self._prepare_action(_("Cobranza vencida"), "account.move", domain)

    def action_view_overdue_payables(self):
        today = fields.Date.context_today(self)
        domain = self._base_move_domain() + [
            ("move_type", "in", ["in_invoice", "in_refund"]),
            ("payment_state", "in", ["not_paid", "partial"]),
            ("invoice_date_due", "<", today),
        ]
        return self._prepare_action(_("Pagos vencidos"), "account.move", domain)

    def action_view_payments(self):
        return self._prepare_action(
            _("Pagos"),
            "account.payment",
            [("company_id", "=", self.company_id.id)],
        )

    def action_view_sales_period(self):
        date_from, date_to = self._get_period_range(self.period_type, self.date_from, self.date_to)
        domain = self._base_move_domain() + [
            ("move_type", "=", "out_invoice"),
            ("invoice_date", ">=", date_from),
            ("invoice_date", "<=", date_to),
        ]
        return self._prepare_action(_("Facturación del período"), "account.move", domain)

    def action_view_pnl_detail(self):
        date_from, date_to = self._get_period_range(self.period_type, self.date_from, self.date_to)
        domain = [
            ("company_id", "=", self.company_id.id),
            ("parent_state", "=", "posted"),
            ("date", ">=", date_from),
            ("date", "<=", date_to),
            ("account_id.account_type", "in", ["income", "income_other", "expense", "expense_depreciation", "expense_direct_cost"]),
        ]
        return self._prepare_action(_("P&L detallado"), "account.move.line", domain)

    def _sales_products_domain(self, date_from, date_to):
        return [
            ("company_id", "=", self.company_id.id),
            ("parent_state", "=", "posted"),
            ("move_id.move_type", "=", "out_invoice"),
            ("display_type", "=", False),
            ("date", ">=", date_from),
            ("date", "<=", date_to),
        ]

    def action_view_top_products(self):
        date_from, date_to = self._get_period_range(self.period_type, self.date_from, self.date_to)
        return self._prepare_action(_("Top productos"), "account.move.line", self._sales_products_domain(date_from, date_to))

    def action_view_bottom_products(self):
        date_from, date_to = self._get_period_range(self.period_type, self.date_from, self.date_to)
        return self._prepare_action(_("Bottom productos"), "account.move.line", self._sales_products_domain(date_from, date_to))

    def action_view_products_no_sales(self):
        date_from, date_to = self._get_period_range(self.period_type, self.date_from, self.date_to)
        sold_products = self.env["account.move.line"].search(self._sales_products_domain(date_from, date_to)).mapped("product_id").ids
        domain = [("sale_ok", "=", True), ("id", "not in", sold_products), ("company_id", "in", [False, self.company_id.id])]
        return self._prepare_action(_("Productos sin ventas"), "product.product", domain)
